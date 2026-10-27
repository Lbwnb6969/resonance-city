using System;
using System.Collections.Generic;
using Code;
using UnityEngine;

public class Bridge : MonoBehaviour, IWorkerUIDisplay
{
	[Serializable]
	public class BridgeSaveData : SaveClass<Bridge, BridgeSaveData>
	{
		public SerializableGuid groupGuid;

		public SerializableVector3[] bridgePath;

		public int bridgePathIdx;

		public SerializableVector3 offsetPos;

		public SerializableQuaternion offsetRot;

		public SerializableVector3 meshPos;

		public SerializableQuaternion meshRot;

		public bool isDiagonal;

		public bool isEndPiece;

		public override BridgeSaveData Pack(Bridge obj)
		{
			groupGuid = obj.groupGuid;
			bridgePath = new SerializableVector3[obj.bridgePath.Count];
			for (int i = 0; i < obj.bridgePath.Count; i++)
			{
				bridgePath[i] = obj.bridgePath.data[i];
			}
			bridgePathIdx = obj.bridgePathIdx;
			offsetPos = obj.offset.localPosition;
			offsetRot = obj.offset.localRotation;
			meshPos = obj.meshT.localPosition;
			meshRot = obj.meshT.localRotation;
			isDiagonal = obj.isBridgeDiagonal;
			isEndPiece = obj.isEndPiece;
			return this;
		}

		public override Bridge Unpack(Bridge obj)
		{
			if (groupGuid.guid != string.Empty)
			{
				obj.groupGuid = groupGuid;
			}
			if (bridgePath != null)
			{
				obj.bridgePath.ClearFast();
				for (int i = 0; i < bridgePath.Length; i++)
				{
					obj.bridgePath.Add(bridgePath[i]);
				}
			}
			obj.bridgePathIdx = bridgePathIdx;
			obj.offset.localPosition = offsetPos;
			obj.offset.localRotation = offsetRot;
			obj.meshT.localPosition = meshPos;
			obj.meshT.localRotation = meshRot;
			obj.isBridgeDiagonal = isDiagonal;
			obj.isEndPiece = isEndPiece;
			Mesh straightMesh = obj.straightMesh;
			if (isDiagonal)
			{
				straightMesh = ((!obj.isEndPiece) ? obj.diagonalMesh : obj.endDiagonalMesh);
			}
			else
			{
				straightMesh = ((!obj.isEndPiece) ? obj.straightMesh : obj.endStraightMesh);
			}
			obj.meshFilter.sharedMesh = straightMesh;
			obj.RecalcWalkPlane();
			obj.UpdateFoundation(isDiagonal, bridgePathIdx == 0);
			obj.RebuildBridgeHeights();
			return obj;
		}
	}

	private Building b;

	[SerializeField]
	private Transform edgeT;

	[SerializeField]
	public Transform walkPlaneT;

	[SerializeField]
	private Transform diagonalEdgeT;

	[SerializeField]
	private Transform[] straightFoundationEdge;

	[SerializeField]
	private Transform[] diagonalFoundationEdge;

	[SerializeField]
	private Transform[] foundationEdges;

	[SerializeField]
	private Transform meshT;

	[SerializeField]
	private Transform offset;

	[SerializeField]
	private MeshFilter meshFilter;

	[SerializeField]
	private Mesh straightMesh;

	[SerializeField]
	private Mesh diagonalMesh;

	[SerializeField]
	private Mesh endStraightMesh;

	[SerializeField]
	private Mesh endDiagonalMesh;

	private Vector2Int[] trackedBridgeVerts = new Vector2Int[3];

	private bool heightsApplied;

	private Vector2Int cachedDirection = Vector2Int.zero;

	private bool directionCached;

	public bool isEndPiece;

	public bool isValidPiece = true;

	private bool isBridgePathComplete = true;

	private bool isBridgeToSteep;

	private bool isBridgeOverOcean;

	public bool isBridgeDiagonal;

	public ArrayExt<Vector3> bridgePath = new ArrayExt<Vector3>(32);

	public int bridgePathIdx = -1;

	public Guid groupGuid = Guid.Empty;

	public static float stoneYOffset = 0.2f;

	public static float woodYOffset = 0.2f;

	public static float endAngleOffset = -5f;

	public static float maxSteepnessAngle = 12f;

	public static float foundationScaleMod = 1.45f;

	public static float intersectingMaxHeight = 0.3f;

	public const int MaxBridgeDistFromWater = 4;

	public static float EndPieceHeightOffset = 0.05f;

	private Cell[] scratchCells = new Cell[12];

	private static Cell[] scratchCellsStatic = new Cell[12];

	private static List<Guid> scratchGuidGroups = new List<Guid>(8);

	private static FloodFillCrawler fCrawler = new FloodFillCrawler();

	private static Vector3 tempPos;

	private static Vector3 diagonalTempPos;

	private static Vector3 diagonalTempDir;

	private static ArrayExt<Vector3> tempBridgePaths = new ArrayExt<Vector3>(32);

	private static bool tempIsDiagonal = false;

	internal Plane walkPlane;

	private const int MAX_STEPS = 64;

	private static Cell testCell;

	private void OnInit()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
		heightsApplied = false;
		directionCached = false;
	}

	private void OnDestroy()
	{
		RemoveBridgeHeights();
	}

	private void OnBuilt()
	{
		RebuildBridgeHeights();
	}

	private void OnBuildingPlacement(bool undo)
	{
		Cell cell = b.GetCell();
		if (!undo && !LoadSave.Loading && isEndPiece)
		{
			TerrainGen.inst.SetAverageTileHeight(cell.x, cell.z, 0.8f, (isBridgeDiagonal ? diagonalEdgeT.position.y : edgeT.position.y) - EndPieceHeightOffset);
		}
		int sx = cell.x;
		int sz = cell.z;
		World.inst.ForEachTile(sx - 4, sz - 4, sx + 4, sz + 4, (int x, int z, Cell cell2) =>
		{
			int num = 1;
			if ((x - sx) * (x - sx) + (z - sz) * (z - sz) <= num || cell2.Type != TerrainType.Water)
			{
				cell2.AddRoadCoverage((!undo) ? 1 : (-1));
			}
		});
		if (b != null && b.IsBuilt())
		{
			RebuildBridgeHeights();
		}
	}

	private void OnBuildingCollapse()
	{
		RemoveBridgeHeights();
		for (int i = -1; i <= 1; i += 2)
		{
			int num = bridgePathIdx + i;
			if (num > 0 && num < bridgePath.Count)
			{
				Building building = World.inst.GetCellData(bridgePath.data[num]).StructureFind(b.uniqueNameHash);
				Bridge bridge = ((building != null) ? building.GetComponent<Bridge>() : null);
				if (bridge != null)
				{
					building.TakeDamage(999f, bridge.offset.position, "Destroyed Neighboring Bridge - I2");
				}
			}
		}
	}

	private void OnPlayerPlacement()
	{
		bridgePath.ClearFast();
		bridgePath.AddRange(tempBridgePaths);
		isBridgeDiagonal = tempIsDiagonal;
		if (b != null && b.IsBuilt())
		{
			RebuildBridgeHeights();
		}
	}

	private void RebuildBridgeHeights()
	{
		if (TerrainGen.inst == null)
		{
			return;
		}
		RemoveBridgeHeights();
		if (isValidPiece && !(b == null) && b.IsBuilt())
		{
			directionCached = false;
			Vector2Int bridgeDirection = GetBridgeDirection();
			if (!(bridgeDirection == Vector2Int.zero))
			{
				Vector2Int centerVertex = GetCenterVertex();
				Vector2Int vector2Int = new Vector2Int(centerVertex.x + bridgeDirection.x, centerVertex.y + bridgeDirection.y);
				Vector2Int vector2Int2 = new Vector2Int(centerVertex.x - bridgeDirection.x, centerVertex.y - bridgeDirection.y);
				ApplyBridgeVertex(centerVertex);
				ApplyBridgeVertex(vector2Int);
				ApplyBridgeVertex(vector2Int2);
				trackedBridgeVerts[0] = centerVertex;
				trackedBridgeVerts[1] = vector2Int;
				trackedBridgeVerts[2] = vector2Int2;
				cachedDirection = bridgeDirection;
				directionCached = true;
				heightsApplied = true;
			}
		}
	}

	private void RemoveBridgeHeights()
	{
		if (!heightsApplied)
		{
			return;
		}
		Vector2Int bridgeDirection = GetBridgeDirection();
		ClearBridgeVertex(trackedBridgeVerts[0]);
		if (bridgeDirection != Vector2Int.zero)
		{
			if (!HasBridgeNeighbor(bridgeDirection))
			{
				ClearBridgeVertex(trackedBridgeVerts[1]);
			}
			Vector2Int direction = new Vector2Int(-bridgeDirection.x, -bridgeDirection.y);
			if (!HasBridgeNeighbor(direction))
			{
				ClearBridgeVertex(trackedBridgeVerts[2]);
			}
		}
		else
		{
			ClearBridgeVertex(trackedBridgeVerts[1]);
			ClearBridgeVertex(trackedBridgeVerts[2]);
		}
		heightsApplied = false;
		cachedDirection = Vector2Int.zero;
		directionCached = false;
		trackedBridgeVerts[0] = Vector2Int.zero;
		trackedBridgeVerts[1] = Vector2Int.zero;
		trackedBridgeVerts[2] = Vector2Int.zero;
	}

	private Vector2Int GetCenterVertex()
	{
		Cell cell = b.GetCell();
		return new Vector2Int(cell.x * 2 + 1, cell.z * 2 + 1);
	}

	private void ApplyBridgeVertex(Vector2Int meshCoord)
	{
		float num = SampleWalkHeight(meshCoord);
		if (num != float.MinValue)
		{
			TerrainGen.inst.SetBridgeHeight(meshCoord.x, meshCoord.y, num);
		}
	}

	private void ClearBridgeVertex(Vector2Int meshCoord)
	{
		TerrainGen.inst.ClearBridgeHeight(meshCoord.x, meshCoord.y);
	}

	private float SampleWalkHeight(Vector2Int meshCoord)
	{
		if (walkPlane.normal == Vector3.zero)
		{
			RecalcWalkPlane();
		}
		Vector3 origin = new Vector3((float)meshCoord.x * 0.5f, 500f, (float)meshCoord.y * 0.5f);
		Ray ray = new Ray(origin, Vector3.down);
		if (!walkPlane.Raycast(ray, out var enter))
		{
			return float.MinValue;
		}
		return ray.GetPoint(enter).y;
	}

	private Vector2Int GetBridgeDirection()
	{
		if (directionCached && cachedDirection != Vector2Int.zero)
		{
			return cachedDirection;
		}
		cachedDirection = CalculateBridgeDirection();
		directionCached = true;
		return cachedDirection;
	}

	private Vector2Int CalculateBridgeDirection()
	{
		Vector2Int vector2Int = Vector2Int.zero;
		if (bridgePath != null && bridgePath.Count > 0 && bridgePathIdx >= 0 && bridgePathIdx < bridgePath.Count)
		{
			Vector3 vector = bridgePath.data[bridgePathIdx];
			Vector3 zero = Vector3.zero;
			if (bridgePathIdx > 0)
			{
				zero += vector - bridgePath.data[bridgePathIdx - 1];
			}
			if (bridgePathIdx < bridgePath.Count - 1)
			{
				zero += bridgePath.data[bridgePathIdx + 1] - vector;
			}
			zero.y = 0f;
			if (zero.sqrMagnitude > 0.0001f)
			{
				vector2Int = new Vector2Int((Mathf.Abs(zero.x) > 0.01f) ? ((zero.x > 0f) ? 1 : (-1)) : 0, (Mathf.Abs(zero.z) > 0.01f) ? ((zero.z > 0f) ? 1 : (-1)) : 0);
			}
		}
		if (vector2Int == Vector2Int.zero)
		{
			Vector3 forward = offset.forward;
			vector2Int = new Vector2Int((Mathf.Abs(forward.x) > 0.01f) ? ((forward.x > 0f) ? 1 : (-1)) : 0, (Mathf.Abs(forward.z) > 0.01f) ? ((forward.z > 0f) ? 1 : (-1)) : 0);
		}
		if (!isBridgeDiagonal)
		{
			if (Mathf.Abs(vector2Int.x) >= Mathf.Abs(vector2Int.y))
			{
				vector2Int.y = 0;
			}
			else
			{
				vector2Int.x = 0;
			}
		}
		else
		{
			if (vector2Int.x == 0 && vector2Int.y != 0)
			{
				vector2Int.x = ((vector2Int.y > 0) ? 1 : (-1));
			}
			if (vector2Int.y == 0 && vector2Int.x != 0)
			{
				vector2Int.y = ((vector2Int.x > 0) ? 1 : (-1));
			}
		}
		vector2Int.x = Mathf.Clamp(vector2Int.x, -1, 1);
		vector2Int.y = Mathf.Clamp(vector2Int.y, -1, 1);
		return vector2Int;
	}

	private bool HasBridgeNeighbor(Vector2Int direction)
	{
		if (direction == Vector2Int.zero)
		{
			return false;
		}
		Cell cell = b.GetCell();
		int x = cell.x + direction.x;
		int z = cell.z + direction.y;
		Cell cellData = World.inst.GetCellData(x, z);
		if (cellData == null)
		{
			return false;
		}
		Building building = cellData.StructureFind(b.uniqueNameHash);
		if (building == null || !building.IsBuilt())
		{
			return false;
		}
		Bridge component = building.GetComponent<Bridge>();
		if (component == null)
		{
			return false;
		}
		Vector2Int bridgeDirection = component.GetBridgeDirection();
		if (bridgeDirection == Vector2Int.zero)
		{
			return false;
		}
		if (bridgeDirection == direction)
		{
			return true;
		}
		if (bridgeDirection == new Vector2Int(-direction.x, -direction.y))
		{
			return true;
		}
		return false;
	}

	private void PlacementValidation(ref PlacementValidationResult result)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		int num = cellDataClamped.x + cellDataClamped.z * World.inst.GridWidth;
		if (result == PlacementValidationResult.CannotBuildOnDynamicWater)
		{
			result = PlacementValidationResult.Valid;
		}
		if (!isValidPiece || !isBridgePathComplete)
		{
			result = PlacementValidationResult.MustBuildBridgeOverWater;
		}
		if (!(Water.inst.distanceDynamicWaterTextureFinished.GetPixel(cellDataClamped.x, cellDataClamped.z).r < 4f))
		{
			result = PlacementValidationResult.TooFarFromWater;
		}
		if (isBridgeToSteep)
		{
			result = PlacementValidationResult.BridgeIsTooSteep;
		}
		if (isEndPiece && DynamicWater.inst.simplifiedWaterGrid[num] > 0f)
		{
			result = PlacementValidationResult.EndsOfBridgeMustBeClearLand;
		}
		if (result == PlacementValidationResult.ExistingStructure)
		{
			bool flag = true;
			for (int i = 0; i < cellDataClamped.OccupyingStructure.Count; i++)
			{
				Building building = cellDataClamped.OccupyingStructure[i];
				if (!World.IsLandRoad(building) && (building.uniqueNameHash != World.woodBridgeHash || b.uniqueNameHash != World.stoneBridgeHash))
				{
					flag = false;
					break;
				}
			}
			if (flag)
			{
				result = PlacementValidationResult.Valid;
			}
		}
		if (isBridgeOverOcean)
		{
			result = PlacementValidationResult.BridgeCannotBuildOverOcean;
		}
		scratchGuidGroups.Clear();
		for (int j = 0; j < bridgePath.Count; j++)
		{
			Building building2 = World.inst.GetCellData(bridgePath.data[j]).StructureFind(World.woodBridgeHash);
			if (building2 != null)
			{
				Guid item = building2.GetComponent<Bridge>().groupGuid;
				if (!scratchGuidGroups.Contains(item))
				{
					scratchGuidGroups.Add(item);
				}
			}
		}
		World.inst.GetNeighborCells(cellDataClamped, ref scratchCells);
		for (int k = 0; k < 4; k++)
		{
			Cell cell = scratchCells[k];
			if (cell == null)
			{
				continue;
			}
			for (int l = 0; l < cell.OccupyingStructure.Count; l++)
			{
				Building building3 = cell.OccupyingStructure[l];
				if (building3 != null && (building3.uniqueNameHash == World.stoneBridgeHash || building3.uniqueNameHash == World.woodBridgeHash))
				{
					Guid guid = building3.GetComponent<Bridge>().groupGuid;
					if (guid != groupGuid && !scratchGuidGroups.Contains(guid))
					{
						result = PlacementValidationResult.BridgeIsTooCloseToAnotherBridge;
						break;
					}
				}
			}
		}
	}

	public static void LayoutBridge(List<Building> buildings, Cell endCell, bool isDiagonal = false, bool validPath = true)
	{
		if (buildings.Count < 2)
		{
			if (buildings.Count == 1)
			{
				Bridge component = buildings[0].GetComponent<Bridge>();
				Cell cell = component.b.GetCell();
				GetMeshHeightsOfCell(cell.x, cell.z, out var min, out var max, out var _);
				Vector3 center2D = cell.Center2D;
				center2D.y = Mathff.Lerp(min, max, 0.5f) + 0.25f;
				component.offset.position = center2D;
				component.offset.rotation = Quaternion.identity;
				component.meshFilter.sharedMesh = component.straightMesh;
				component.meshT.localRotation = Quaternion.identity;
				component.meshT.localPosition = new Vector3(-0f, -0.6f, 0f);
				component.isValidPiece = endCell != null;
				component.isEndPiece = true;
				component.isBridgePathComplete = false;
				component.isBridgeOverOcean = false;
				component.isBridgeToSteep = false;
				component.bridgePathIdx = 0;
				component.RecalcWalkPlane();
			}
			return;
		}
		float num = (isDiagonal ? 1.4142135f : 1f);
		Bridge component2 = buildings[0].GetComponent<Bridge>();
		Bridge component3 = buildings[buildings.Count - 1].GetComponent<Bridge>();
		Cell cell2 = component2.b.GetCell();
		Vector3 center2D2 = cell2.Center2D;
		GetMeshHeightsOfCell(cell2.x, cell2.z, out var min2, out var max2, out var avg2);
		center2D2.y = max2;
		Cell cell3 = component3.b.GetCell();
		Vector3 vector = cell3.Center2D;
		GetMeshHeightsOfCell(cell3.x, cell3.z, out min2, out max2, out avg2);
		vector.y = max2;
		int num2 = buildings.Count - 1;
		bool flag = false;
		if (endCell != null)
		{
			int num3 = Mathf.FloorToInt((endCell.Center2D - new Vector3(center2D2.x, 0f, center2D2.z)).magnitude / num);
			if (buildings.Count - 1 < num3)
			{
				Vector3 center2D3 = endCell.Center2D;
				GetMeshHeightsOfCell(endCell.x, endCell.z, out min2, out max2, out avg2);
				center2D3.y = avg2;
				vector = center2D3;
				num2 = num3;
			}
			else
			{
				flag = true;
			}
		}
		float num4 = ((buildings[0].uniqueNameHash == World.stoneBridgeHash) ? stoneYOffset : woodYOffset);
		center2D2.y += num4;
		vector.y += num4;
		Vector3 input = vector - center2D2;
		Vector3 input2 = input;
		input2.y = 0f;
		input2.NonAllocateNormalize();
		input.NonAllocateNormalize();
		bool flag2 = Vector3.Angle(input, input2) > maxSteepnessAngle;
		_ = center2D2.y;
		_ = vector.y;
		bool flag3 = false;
		float num5 = float.MinValue;
		bool flag4 = false;
		for (int i = 0; i <= num2; i++)
		{
			ref float x = ref tempPos.x;
			ref float y = ref tempPos.y;
			ref float z = ref tempPos.z;
			float num6 = input2.x * ((float)i * num);
			float num7 = input2.z * ((float)i * num);
			x = num6;
			y = 0f;
			z = num7;
			float num8 = center2D2.y + Vector3.Project(tempPos, input).y;
			y = ref tempPos.x;
			ref float z2 = ref tempPos.z;
			num7 = tempPos.x + center2D2.x;
			num6 = tempPos.z + center2D2.z;
			y = num7;
			z2 = num6;
			tempPos.y = TerrainGen.inst.GetInterpolatedHeight(tempPos);
			Cell cellData = World.inst.GetCellData(tempPos);
			float num9 = tempPos.y - num8;
			if (num9 > 0f && num9 > num5)
			{
				num5 = num9;
				flag4 = true;
			}
			if (cellData.landMassIdx == -1)
			{
				flag3 = true;
			}
		}
		if (flag4)
		{
			center2D2.y += Mathff.Clamp(num5, 0f, intersectingMaxHeight);
			vector.y += Mathff.Clamp(num5, 0f, intersectingMaxHeight);
		}
		Guid guid = Guid.NewGuid();
		tempBridgePaths.ClearFast();
		tempIsDiagonal = isDiagonal;
		for (int j = 0; j < buildings.Count; j++)
		{
			ref float y = ref tempPos.x;
			ref float x = ref tempPos.y;
			ref float z3 = ref tempPos.z;
			float num6 = input2.x * ((float)j * num);
			float num7 = input2.z * ((float)j * num);
			y = num6;
			x = 0f;
			z3 = num7;
			tempPos.y = center2D2.y + Vector3.Project(tempPos, input).y;
			x = ref tempPos.x;
			ref float z4 = ref tempPos.z;
			num7 = center2D2.x + tempPos.x;
			num6 = center2D2.z + tempPos.z;
			x = num7;
			z4 = num6;
			tempBridgePaths.Add(new Vector3((int)tempPos.x, 0f, (int)tempPos.z));
			Bridge component4 = buildings[j].GetComponent<Bridge>();
			Cell cell4 = component4.b.GetCell();
			component4.isValidPiece = validPath && endCell != null;
			component4.isBridgePathComplete = flag;
			component4.isBridgeToSteep = flag2;
			component4.isBridgeOverOcean = flag3;
			component4.isEndPiece = j == 0 || j == buildings.Count - 1;
			component4.groupGuid = guid;
			component4.bridgePathIdx = j;
			component4.offset.position = tempPos;
			component4.offset.rotation = Quaternion.LookRotation(input);
			Mesh mesh = component4.straightMesh;
			if (isDiagonal)
			{
				mesh = ((!component4.isEndPiece) ? component4.diagonalMesh : component4.endDiagonalMesh);
			}
			else
			{
				mesh = ((!component4.isEndPiece) ? component4.straightMesh : component4.endStraightMesh);
			}
			component4.meshFilter.sharedMesh = mesh;
			component4.meshT.localRotation = Quaternion.identity;
			component4.meshT.localPosition = new Vector3(0f, -0.6f, 0f);
			if (buildings.Count > 1 && (j == 0 || j == num2) && component4.isValidPiece && !component4.isBridgeToSteep && !component4.isBridgeOverOcean)
			{
				Vector3 vector2 = (isDiagonal ? component4.diagonalEdgeT.position : component4.edgeT.position);
				Vector3 axis = (isDiagonal ? component4.diagonalEdgeT.forward : component4.edgeT.forward);
				Vector3 vector3 = new Vector3(tempPos.x + axis.z * num, 0f, tempPos.z + (0f - axis.x) * num);
				GetMeshHeightsOfCell(cell4.x, cell4.z, out min2, out max2, out avg2);
				vector3.y = Mathff.Lerp(min2, max2, 0.85f);
				float angle = 0f - Vector3.Angle((vector3 - vector2).normalized, component4.offset.up) + 90f;
				component4.meshT.RotateAround(vector2, axis, angle);
			}
			component4.RecalcWalkPlane();
			component4.UpdateFoundation(isDiagonal, j == 0);
		}
		for (int k = 0; k < buildings.Count; k++)
		{
			Bridge component5 = buildings[k].GetComponent<Bridge>();
			component5.RotateBridge((k == 0) ? null : World.inst.GetCellDataClamped(buildings[k - 1].GetPos()), (k == buildings.Count - 1) ? null : World.inst.GetCellDataClamped(buildings[k + 1].GetPos()), isDiagonal);
			component5.bridgePath.ClearFast();
			component5.bridgePath.AddRange(tempBridgePaths);
		}
	}

	private void RecalcWalkPlane()
	{
		walkPlane = new Plane(walkPlaneT.up, walkPlaneT.position);
	}

	private void UpdateFoundation(bool isDiagonal, bool isStart)
	{
		int num = ((!isStart) ? 1 : 2);
		for (int i = 0; i < num; i++)
		{
			Transform transform = (isDiagonal ? diagonalFoundationEdge[i] : straightFoundationEdge[i]);
			foundationEdges[i].localRotation = transform.localRotation;
			Vector3 position = transform.position;
			Vector3 forward = transform.forward;
			forward.x *= 0.5f;
			forward.z *= 0.5f;
			forward.y *= 0.5f;
			float num2 = Mathff.Min(TerrainGen.inst.GetInterpolatedHeight(position + forward), TerrainGen.inst.GetInterpolatedHeight(position - forward));
			float num3 = position.y - num2;
			if (num3 > 0f)
			{
				num3 = Mathff.Max(0.25f, num3);
				Vector3 localScale = foundationEdges[i].localScale;
				localScale.y = num3 * foundationScaleMod + 0.1f;
				foundationEdges[i].localScale = localScale;
				foundationEdges[i].position = position;
				Util.SetActive(foundationEdges[i].gameObject, active: true);
			}
			else
			{
				Util.SetActive(foundationEdges[i].gameObject, active: false);
			}
		}
		for (int j = num; j < 2; j++)
		{
			Util.SetActive(foundationEdges[j].gameObject, active: false);
		}
	}

	private void RotateBridge(Cell prev, Cell next, bool isDiagonal)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.GetPos());
		offset.Rotate(Vector3.up, 0f - offset.eulerAngles.y, Space.Self);
		if (cellDataClamped == null)
		{
			return;
		}
		if (!isDiagonal)
		{
			World.inst.GetNeighborCells(cellDataClamped, ref scratchCells);
			bool flag = scratchCells[1] == prev || scratchCells[1] == next;
			bool flag2 = scratchCells[3] == prev || scratchCells[3] == next;
			bool flag3 = scratchCells[0] == prev || scratchCells[0] == next;
			bool num = scratchCells[2] == prev || scratchCells[2] == next;
			int num2 = 0;
			if (flag)
			{
				num2++;
			}
			if (flag2)
			{
				num2++;
			}
			if (flag3)
			{
				num2++;
			}
			if (num)
			{
				num2++;
			}
			if (num2 == 1)
			{
				if (flag)
				{
					offset.Rotate(Vector3.up, 90f, Space.Self);
				}
				if (flag3)
				{
					offset.Rotate(Vector3.up, 180f, Space.Self);
				}
				if (flag2)
				{
					offset.Rotate(Vector3.up, 270f, Space.Self);
				}
			}
			else if (flag & flag2)
			{
				offset.Rotate(Vector3.up, 90f, Space.Self);
			}
			return;
		}
		World.inst.GetNeighborDiagonalCells(cellDataClamped, ref scratchCells);
		bool flag4 = scratchCells[0] == prev || scratchCells[0] == next;
		bool flag5 = scratchCells[1] == prev || scratchCells[1] == next;
		bool flag6 = scratchCells[2] == prev || scratchCells[2] == next;
		bool flag7 = scratchCells[3] == prev || scratchCells[3] == next;
		int num3 = 0;
		if (flag5)
		{
			num3++;
		}
		if (flag4)
		{
			num3++;
		}
		if (flag7)
		{
			num3++;
		}
		if (flag6)
		{
			num3++;
		}
		if (num3 == 1)
		{
			if (flag4)
			{
				offset.Rotate(Vector3.up, 90f, Space.Self);
			}
			else if (flag7)
			{
				offset.Rotate(Vector3.up, 180f, Space.Self);
			}
			else if (flag6)
			{
				offset.Rotate(Vector3.up, 270f, Space.Self);
			}
		}
		else if (flag4 & flag6)
		{
			offset.Rotate(Vector3.up, 90f, Space.Self);
		}
	}

	public static bool SimulateBridge(Cell startCell, Vector3 direction, bool isDiagonal, out Cell endCell)
	{
		Vector3 center2D = startCell.Center2D;
		float num = (isDiagonal ? 1.4142135f : 1f);
		bool flag = true;
		endCell = null;
		bool result = true;
		for (int i = 1; i < 64; i++)
		{
			ref float x = ref tempPos.x;
			ref float z = ref tempPos.z;
			float num2 = center2D.x + direction.x * ((float)i * num);
			float num3 = center2D.z + direction.z * ((float)i * num);
			x = num2;
			z = num3;
			Cell cellData = World.inst.GetCellData(tempPos);
			if (cellData != null)
			{
				if (!IsValid(cellData))
				{
					flag = false;
				}
				else if (IsCellWater(cellData))
				{
					endCell = cellData;
				}
			}
			bool flag2 = false;
			if (isDiagonal && endCell == null)
			{
				x = ref diagonalTempPos.x;
				ref float z2 = ref diagonalTempPos.z;
				num3 = center2D.x + direction.x * (((float)i - 0.5f) * num);
				num2 = center2D.z + direction.z * (((float)i - 0.5f) * num);
				x = num3;
				z2 = num2;
				x = ref diagonalTempDir.x;
				ref float z3 = ref diagonalTempDir.z;
				num2 = direction.z;
				num3 = 0f - direction.x;
				x = num2;
				z3 = num3;
				x = ref tempPos.x;
				ref float z4 = ref tempPos.z;
				num3 = diagonalTempPos.x + diagonalTempDir.x * 0.5f;
				num2 = diagonalTempPos.z + diagonalTempDir.z * 0.5f;
				x = num3;
				z4 = num2;
				bool flag3 = IsCellWater(World.inst.GetCellData(tempPos));
				if (!flag3)
				{
					x = ref tempPos.x;
					ref float z5 = ref tempPos.z;
					num2 = diagonalTempPos.x + (0f - diagonalTempDir.x) * 0.5f;
					num3 = diagonalTempPos.z + (0f - diagonalTempDir.z) * 0.5f;
					x = num2;
					z5 = num3;
					flag3 = IsCellWater(World.inst.GetCellData(tempPos));
				}
				if (flag3)
				{
					flag2 = true;
					endCell = cellData;
				}
			}
			if (endCell != null && ((endCell != cellData) | flag2))
			{
				testCell = cellData;
				fCrawler.Reset();
				fCrawler.cellsPerFrame = 32;
				fCrawler.Tick(center2D, IsOnSameSide);
				if (fCrawler.finishedCrawl || !fCrawler.exitedEarly)
				{
					endCell = cellData;
					flag = false;
				}
				else
				{
					flag = false;
					endCell = cellData;
					result = false;
				}
			}
			if (!flag)
			{
				break;
			}
		}
		return result;
	}

	private static bool IsCellWater(Cell c)
	{
		return DynamicWater.inst.simplifiedWaterGrid[c.x + c.z * World.inst.GridWidth] > 0f;
	}

	private static bool IsValid(Cell c)
	{
		if (c.landMassIdx == -1 || c.Type != TerrainType.None)
		{
			return false;
		}
		if (!(DynamicWater.inst.simplifiedWaterGrid[c.x + c.z * World.inst.GridWidth] > 0f))
		{
			return Water.inst.distanceDynamicWaterTextureFinished.GetPixel(c.x, c.z).r < 4f;
		}
		return true;
	}

	private static bool IsOnSameSide(Cell cell, ref List<Cell> openSet)
	{
		if (cell == null)
		{
			return true;
		}
		if (cell == testCell)
		{
			return false;
		}
		World.inst.GetNeighborCells(cell, ref scratchCellsStatic);
		for (int i = 0; i < 4; i++)
		{
			Cell cell2 = scratchCellsStatic[i];
			int num = cell2.x + cell2.z * World.inst.GridWidth;
			if (DynamicWater.inst.simplifiedWaterGrid[num] < 0f && cell2.Type == TerrainType.None && Water.inst.distanceDynamicWaterTextureFinished.GetPixel(cell2.x, cell2.z).r < 4f)
			{
				openSet.Add(cell2);
			}
		}
		return true;
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return false;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}

	private static bool GetMeshHeightsOfCell(int cellX, int cellZ, out float min, out float max, out float avg)
	{
		float num = 0f;
		max = float.MinValue;
		min = float.MaxValue;
		avg = 0f;
		if (cellX >= World.inst.GridWidth || cellZ >= World.inst.GridHeight)
		{
			return false;
		}
		int num2 = cellX * 2;
		int num3 = cellZ * 2;
		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				float vertY = TerrainGen.inst.GetVertY(num2 + i, num3 + j);
				num += vertY;
				if (vertY < min)
				{
					min = vertY;
				}
				if (vertY > max)
				{
					max = vertY;
				}
				float x = (float)cellX + 0.5f * (float)i;
				float z = (float)cellZ + 0.5f * (float)j;
				DebugEx.DrawSphere(new Vector3(x, vertY, z), 0.05f, Color.green);
			}
		}
		avg = num / 9f;
		return true;
	}
}
