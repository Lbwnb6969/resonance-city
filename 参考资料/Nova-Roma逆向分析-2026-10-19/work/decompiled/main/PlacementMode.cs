using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Code.Interface;
using Code;
using FMODUnity;
using UnityEngine;
using UnityEngine.Events;

public class PlacementMode
{
	public class BuildingPRS
	{
		public Vector3 pos;

		public Quaternion rot;

		public Vector3 size;
	}

	private List<Vector3> path = new List<Vector3>(64);

	private List<Vector3> prevPath = new List<Vector3>(64);

	private BuildingPRS prevBuildingPRS;

	internal Building[] buildingMap;

	internal List<Building> buildings = new List<Building>(32);

	internal Dictionary<int, float> cellHighestDamY = new Dictionary<int, float>();

	internal Dictionary<int, float> cellLowestDamY = new Dictionary<int, float>();

	private HashSet<int> pathCellsScratch = new HashSet<int>();

	private readonly List<Vector3> pathSortScratch = new List<Vector3>(64);

	private readonly List<int> pathOrderScratch = new List<int>(64);

	private Comparison<int> pathOrderComparison;

	private List<PlacementValidationResult> canPlace = new List<PlacementValidationResult>(32);

	private List<bool> canAfford = new List<bool>(32);

	public ResourceAmount cost = new ResourceAmount();

	internal BuildBuildingData lastBuildInfo;

	internal Building lastBuilding;

	private Vector3 lastBuildingsPlacementPosition;

	private Quaternion lastOffsetRotation;

	private Vector3 lastOffsetPosition;

	private bool stackablePlacement;

	private bool damPlacement;

	private bool hitWaterSurface;

	private float waterSurfaceHitY;

	private readonly HashSet<int> modifiedPreviewIndices = new HashSet<int>();

	private readonly HashSet<int> previewIndicesScratch = new HashSet<int>();

	private readonly List<int> previewIndicesToRemove = new List<int>();

	private float arrowScaleMod;

	private float totalTime;

	private static readonly RaycastHit[] surfaceHits = new RaycastHit[16];

	private readonly Dictionary<Vector3, bool> damSelectableCache = new Dictionary<Vector3, bool>();

	private static int terrainLayerMask = -1;

	public UnityAction<Building> OnBuildingPlacing;

	private float damReplaceThreshold = 20f;

	private bool damReplacementFixed;

	private Vector2 damReplaceMouseDownPoint;

	private Dictionary<int, float> scratchMeshPoints = new Dictionary<int, float>(9);

	private List<int> scratchMeshIndices = new List<int>();

	private List<float> scratchMeshHeights = new List<float>();

	private bool secondClick;

	public ResourceAmount extraCost = new ResourceAmount();

	private ResourceAmount tempTotal = new ResourceAmount();

	public Cell waitToPlace_LastPlacedCell;

	protected Cell lastCell;

	public Building placementRelatedBuilding;

	private Cell[] scratchNeighbors4 = new Cell[4];

	public static float MIN_DIFF_TO_SNAP_MIN_HEIGHT = 0.15f;

	private int aqueductHash = "aqueduct".GetHashCode();

	private int castlestairsHash = "castlestairs".GetHashCode();

	private List<AdjacentMesh> adjacentMeshScratch = new List<AdjacentMesh>();

	private bool attemptedDrag;

	private Vector3 point1;

	private Vector3 point2;

	private Vector3 tempPoint;

	private Vector3[] directions4 = new Vector3[4]
	{
		new Vector3(0f, 0f, 1f),
		new Vector3(1f, 0f, 1f).normalized,
		new Vector3(1f, 0f, 0f),
		new Vector3(1f, 0f, -1f).normalized
	};

	private Vector3[] offsets = new Vector3[9]
	{
		new Vector3(0f, 0f, 0f),
		new Vector3(1f, 0f, 0f),
		new Vector3(-1f, 0f, 0f),
		new Vector3(0f, 0f, 1f),
		new Vector3(0f, 0f, -1f),
		new Vector3(1f, 0f, 1f),
		new Vector3(1f, 0f, -1f),
		new Vector3(-1f, 0f, 1f),
		new Vector3(-1f, 0f, -1f)
	};

	private int pathHash = "path".GetHashCode();

	private Vector3 mouseDownCursorPos;

	private Cell mouseDownCell;

	private Building mouseDownPlacementRelatedBuilding;

	public Building heldPrefab;

	private int landmass = -1;

	public bool isDragging => attemptedDrag;

	private int ComparePathOrder(int a, int b)
	{
		int num = pathSortScratch[a].y.CompareTo(pathSortScratch[b].y);
		if (num == 0)
		{
			return a.CompareTo(b);
		}
		return num;
	}

	public void Setup()
	{
		int num = World.inst.GridWidth * World.inst.GridHeight;
		if (buildingMap == null || buildingMap.Length != num)
		{
			buildingMap = new Building[num];
		}
	}

	public Building SetCursorObject(Building buildingPrefab, bool notFirstPlacement)
	{
		if (buildingPrefab != null)
		{
			if ((bool)heldPrefab)
			{
				AbortPlacement(refund: true);
			}
			heldPrefab = buildingPrefab;
			heldPrefab.SetUpHashes();
			CreativeUI.inst.SetBrushNone();
			World.inst.SetGrassEnabled(e: false);
			Building building = InstantiateFromPrefab(buildingPrefab);
			buildings.Clear();
			canPlace.Clear();
			canAfford.Clear();
			buildings.Add(building);
			canPlace.Add(PlacementValidationResult.Valid);
			canAfford.Add(item: false);
			stackablePlacement = buildingPrefab.Stackable;
			damPlacement = buildingPrefab.uniqueNameHash == World.damHash;
			landmass = Player.inst.FocusedLandMass;
			if (!notFirstPlacement)
			{
				RuntimeManager.PlayOneShot(GameUI.inst.soundOnSelectBuilding);
			}
			else
			{
				building.transform.position = lastBuildingsPlacementPosition;
				Transform child = building.transform.GetChild(0);
				child.position = lastOffsetPosition;
				child.rotation = lastOffsetRotation;
			}
			if (heldPrefab.uniqueNameHash == World.quarryHash)
			{
				World.inst.ShowResourceGroupTooltipUIs(2);
			}
			else if (heldPrefab.uniqueNameHash == World.marbleQuarryHash)
			{
				World.inst.ShowResourceGroupTooltipUIs(14);
			}
			else if (heldPrefab.uniqueNameHash == World.ironMineHash)
			{
				World.inst.ShowResourceGroupTooltipUIs(5);
			}
			else if (heldPrefab.UniqueNameHash() == World.fishinghutHash)
			{
				World.inst.ShowFishResourceGroupTooltips();
			}
			UpdateTerrainTexture();
			BuildInfoFloating.inst.SetVisibility(v: false);
			return building;
		}
		return null;
	}

	public void PopulatePath(Cell newCell)
	{
		World.inst.pather.FindPathRaw(mouseDownCell.Center2D, newCell.Center2D, ref path, blocksPath, pathCost, 0);
		if (path.Count > 0)
		{
			path.Insert(0, mouseDownCell.Center3D);
		}
		for (int i = 0; i < path.Count; i++)
		{
			path[i] = new Vector3(path[i].x, 0f, path[i].z);
		}
	}

	private void PopulateRectangle(Cell newCell)
	{
		int num = ((mouseDownCell.x <= newCell.x) ? 1 : (-1));
		int num2 = ((mouseDownCell.z <= newCell.z) ? 1 : (-1));
		for (int i = mouseDownCell.z; (num2 > 0) ? (i <= newCell.z) : (i >= newCell.z); i += num2 * (int)heldPrefab.size.z)
		{
			for (int j = mouseDownCell.x; (num > 0) ? (j <= newCell.x) : (j >= newCell.x); j += num * (int)heldPrefab.size.x)
			{
				path.Add(new Vector3((float)j + 0.5f, 0f, (float)i + 0.5f));
			}
		}
	}

	private void PopulateLine(Cell newCell, ref Vector3 dir, ref bool isDiagonal)
	{
		int num = -1;
		float num2 = float.MaxValue;
		Ray ray = PointingSystem.GetRay();
		ref float y;
		ref float x;
		float z2;
		float y2;
		for (int i = 0; i < 4; i++)
		{
			Mathff.ClosestPointsOnTwoLines(out point1, out point2, mouseDownCell.Center3D, directions4[i], Cam.inst.CamPos, ray.direction);
			float num3 = Mathff.DistSqrd(point1, point2);
			if (num3 < num2)
			{
				num = i;
				num2 = num3;
				x = ref tempPoint.x;
				y = ref tempPoint.y;
				ref float z = ref tempPoint.z;
				float x2 = point1.x;
				y2 = point1.y;
				z2 = point1.z;
				x = x2;
				y = y2;
				z = z2;
			}
		}
		Cell cellData = World.inst.GetCellData(tempPoint);
		if (cellData == null)
		{
			return;
		}
		y = ref tempPoint.x;
		x = ref tempPoint.y;
		ref float z3 = ref tempPoint.z;
		z2 = (float)mouseDownCell.x + 0.5f;
		y2 = (float)mouseDownCell.z + 0.5f;
		y = z2;
		x = 0f;
		z3 = y2;
		dir = cellData.Center2D - tempPoint;
		isDiagonal = num % 2 != 0;
		float num4 = (isDiagonal ? 1.4142135f : 1f);
		int num5 = Mathf.RoundToInt(dir.magnitude / num4);
		dir.Normalize();
		for (int j = 0; j <= num5; j++)
		{
			Cell cellData2 = World.inst.GetCellData(tempPoint + dir * ((float)j * num4));
			if (cellData2 != null)
			{
				path.Add(cellData2.Center2D);
			}
		}
	}

	private void PopulateLineFillDown(Cell newCell, ref Vector3 dir, ref bool isDiagonal)
	{
		int num = -1;
		Vector3 zero = Vector3.zero;
		float num2 = float.MaxValue;
		Ray ray = PointingSystem.GetRay();
		for (int i = 0; i < 4; i++)
		{
			Mathff.ClosestPointsOnTwoLines(out point1, out point2, mouseDownCursorPos, directions4[i], Cam.inst.CamPos, ray.direction);
			float num3 = Mathff.DistSqrd(point1, point2);
			if (num3 < num2)
			{
				num = i;
				num2 = num3;
				zero = point1;
			}
		}
		float num4 = float.MinValue;
		Vector3 vector = zero.xz() - mouseDownCell.Center2D;
		isDiagonal = num % 2 != 0;
		float num5 = (isDiagonal ? 1.4142135f : 1f);
		int num6 = Mathf.FloorToInt(vector.magnitude / num5);
		vector.Normalize();
		for (int j = 0; j <= num6; j++)
		{
			Cell cellData = World.inst.GetCellData(mouseDownCell.Center2D + vector * ((float)j * num5));
			if (cellData != null)
			{
				float cellCenterSurfaceHeight = GetCellCenterSurfaceHeight(cellData);
				cellCenterSurfaceHeight = SnapToVerticalGrid(cellCenterSurfaceHeight);
				float num7 = SnapToVerticalGrid(DynamicWater.inst.WaterHeight(cellData) + 0.1f);
				if (hitWaterSurface)
				{
					num7 = Mathf.Max(num7, SnapToVerticalGrid(waterSurfaceHitY + 0.1f));
				}
				cellCenterSurfaceHeight = Mathf.Max(cellCenterSurfaceHeight, num7);
				if (cellCenterSurfaceHeight > num4)
				{
					num4 = cellCenterSurfaceHeight;
				}
			}
		}
		float a = num4;
		float b = SnapToVerticalGrid(mouseDownCursorPos.y);
		a = Mathf.Max(a, b);
		Vector3 blockPosition = new Vector3(mouseDownCell.x, a, mouseDownCell.z);
		float num8 = a + 5f;
		while (!IsDamBlockSelectable(blockPosition) && blockPosition.y < num8)
		{
			a = (blockPosition.y = a + 0.5f);
		}
		Vector3 vector2 = mouseDownCell.Center2D + new Vector3(0f, a, 0f);
		if (World.inst.GetCellData(zero) == null)
		{
			return;
		}
		dir = zero.xz() - vector2.xz();
		isDiagonal = num % 2 != 0;
		float num9 = (isDiagonal ? 1.4142135f : 1f);
		int num10 = Mathf.RoundToInt(dir.magnitude / num9);
		dir.Normalize();
		for (int k = 0; k <= num10; k++)
		{
			Cell cellData2 = World.inst.GetCellData(vector2 + dir * ((float)k * num9));
			if (cellData2 == null)
			{
				continue;
			}
			float cellCenterSurfaceHeight2 = GetCellCenterSurfaceHeight(cellData2);
			cellCenterSurfaceHeight2 = SnapToVerticalGrid(cellCenterSurfaceHeight2);
			Building building = cellData2.HighestStructureWithUniqueHash(World.damHash);
			if (building != null)
			{
				cellCenterSurfaceHeight2 = building.transform.position.y + (float)building.StackHeight * 0.25f;
			}
			for (float num11 = a; num11 >= cellCenterSurfaceHeight2; num11 -= 0.5f)
			{
				Vector3 blockPosition2 = new Vector3(cellData2.x, num11, cellData2.z);
				if (!IsDamBlockSelectable(blockPosition2))
				{
					break;
				}
				path.Add(cellData2.Center2D + new Vector3(0f, num11, 0f));
			}
		}
	}

	private bool IsModeAutoDrag()
	{
		return heldPrefab.dragPlacementMode == Building.DragPlacementMode.Line;
	}

	public virtual void Update()
	{
		damSelectableCache.Clear();
		totalTime += Time.unscaledDeltaTime;
		if (Vector2.Distance(damReplaceMouseDownPoint, Input.mousePosition) > damReplaceThreshold)
		{
			damReplacementFixed = false;
		}
		cost.Clear();
		if (waitToPlace_LastPlacedCell != null)
		{
			Cell cellData = World.inst.GetCellData(GameUI.inst.GridPointerIntersection());
			if (cellData != null && cellData != waitToPlace_LastPlacedCell)
			{
				StageLastBuiltBuilding();
			}
			return;
		}
		if (buildings.Count > 0 && heldPrefab != null)
		{
			int focusedLandMass = Player.inst.FocusedLandMass;
			if (landmass != focusedLandMass)
			{
				if (focusedLandMass != -1)
				{
					landmass = focusedLandMass;
					UpdateTerrainTexture();
				}
				for (int i = 0; i < buildings.Count; i++)
				{
					if (i < canAfford.Count)
					{
						canAfford[i] = false;
					}
				}
			}
			if (heldPrefab.uniqueNameHash == World.castellumaquaeHash || heldPrefab.uniqueNameHash == World.waterTowerHash || heldPrefab.uniqueNameHash == World.bathReservoirHash || heldPrefab.uniqueNameHash == World.waterOutletHash || heldPrefab.uniqueNameHash == World.ironOreMillHash)
			{
				ShowWaterBuildingMarkers(focusedLandMass);
			}
			Building building = buildings[0];
			ResourceAmount resourceAmount = building.GetCost(Player.inst.FocusedLandMass);
			Vector3 cursorPos = GetCursorPos();
			cursorPos = ClampPosForCursorObj(cursorPos, building);
			Cell cellData2 = World.inst.GetCellData(cursorPos);
			if (!damPlacement)
			{
				cursorPos.y = TerrainGen.inst.GetGroundHeight((float)cellData2.x + 0.5f, (float)cellData2.z + 0.5f);
			}
			if (path.Count == 1)
			{
				prevBuildingPRS = new BuildingPRS
				{
					pos = path[0],
					size = building.size,
					rot = building.transform.GetChild(0).rotation
				};
			}
			else
			{
				prevBuildingPRS = null;
			}
			prevPath.Clear();
			for (int j = 0; j < path.Count; j++)
			{
				prevPath.Add(path[j]);
			}
			if (!GameUI.inst.dragConfirm)
			{
				path.Clear();
			}
			float heightOverride = -1f;
			Vector3 dir = Vector3.zero;
			bool isDiagonal = false;
			if (mouseDownCell != null && mouseDownCell != cellData2 && !GameUI.inst.dragConfirm)
			{
				if (PointingSystem.GetPointer().GetPrimaryDownThisFrame())
				{
					attemptedDrag = true;
				}
				switch (heldPrefab.dragPlacementMode)
				{
				case Building.DragPlacementMode.Path:
					PopulatePath(cellData2);
					break;
				case Building.DragPlacementMode.Rectangle:
					PopulateRectangle(cellData2);
					break;
				case Building.DragPlacementMode.Line:
					PopulateLine(cellData2, ref dir, ref isDiagonal);
					break;
				case Building.DragPlacementMode.LineFillDown:
					PopulateLineFillDown(cellData2, ref dir, ref isDiagonal);
					break;
				}
			}
			if (path.Count == 0 && heldPrefab.dragPlacementMode == Building.DragPlacementMode.LineFillDown)
			{
				_ = Vector3.zero;
				float cellCenterSurfaceHeight = GetCellCenterSurfaceHeight(cellData2);
				float b = SnapToVerticalGrid(cellCenterSurfaceHeight);
				if (mouseDownCell == null)
				{
					if (placementRelatedBuilding != null)
					{
						b = SnapToVerticalGrid(cursorPos.y);
					}
				}
				else if (mouseDownPlacementRelatedBuilding != null)
				{
					b = SnapToVerticalGrid(mouseDownCursorPos.y);
				}
				float a = SnapToVerticalGrid(DynamicWater.inst.WaterHeight(cellData2) + 0.1f);
				if (hitWaterSurface)
				{
					a = Mathf.Max(a, SnapToVerticalGrid(waterSurfaceHitY + 0.1f));
				}
				b = Mathf.Max(a, b);
				float num = SnapToVerticalGrid(cellCenterSurfaceHeight);
				Building building2 = cellData2.HighestStructureWithUniqueHash(World.damHash);
				if (building2 != null)
				{
					num = SnapToVerticalGrid(building2.transform.position.y + (float)building2.StackHeight * 0.25f);
					b = Mathf.Max(b, num);
				}
				for (float num2 = b; num2 >= num; num2 -= 0.5f)
				{
					Vector3 blockPosition = new Vector3(cellData2.x, num2, cellData2.z);
					if (!IsDamBlockSelectable(blockPosition))
					{
						break;
					}
					path.Add(cellData2.Center2D + new Vector3(0f, num2, 0f));
				}
			}
			if (path.Count == 0)
			{
				float num3 = SnapToVerticalGrid(GetCellCenterSurfaceHeight(cellData2));
				if (damPlacement)
				{
					Vector3 blockPosition2 = new Vector3(cellData2.x, num3, cellData2.z);
					float num4 = num3 + 5f;
					while (!IsDamBlockSelectable(blockPosition2) && blockPosition2.y < num4)
					{
						num3 = (blockPosition2.y = num3 + 0.5f);
					}
				}
				path.Add(new Vector3(cellData2.Center2D.x, num3, cellData2.Center2D.z));
			}
			pathSortScratch.Clear();
			pathSortScratch.AddRange(path);
			pathOrderScratch.Clear();
			for (int k = 0; k < path.Count; k++)
			{
				pathOrderScratch.Add(k);
			}
			pathOrderScratch.Sort(ComparePathOrder);
			for (int l = 0; l < path.Count; l++)
			{
				path[l] = pathSortScratch[pathOrderScratch[l]];
			}
			int num5 = 144;
			pathCellsScratch.Clear();
			int num6 = path.Count;
			for (int m = 0; m < path.Count; m++)
			{
				int item = (int)path[m].x + (int)path[m].z * 10000;
				if (!pathCellsScratch.Contains(item))
				{
					if (pathCellsScratch.Count >= num5)
					{
						num6 = m;
						break;
					}
					pathCellsScratch.Add(item);
				}
			}
			if (num6 < path.Count)
			{
				path.RemoveRange(num6, path.Count - num6);
			}
			List<Cell> toUpdateBlockStack = new List<Cell>(buildings.Count);
			previewIndicesScratch.Clear();
			if (cellData2 != lastCell)
			{
				ClearTerrainPreview();
				for (int n = 0; n < buildings.Count; n++)
				{
					buildings[n].ForEachTileInBounds((int x, int z, Cell item2) =>
					{
						toUpdateBlockStack.Add(item2);
					});
				}
			}
			for (int num7 = 0; num7 < buildings.Count; num7++)
			{
				buildings[num7].ForEachTileInBounds((int x, int z, Cell cell3) =>
				{
					buildingMap[cell3.index] = null;
					for (int num21 = 0; num21 < cell3.OccupyingStructure.Count; num21++)
					{
						cell3.OccupyingStructure[num21].ResetSnapPointCovers();
					}
					BlockBuilding.MarkBlockStackAndNeighborsDirty(cell3);
				});
			}
			IOverlayUser component = heldPrefab.GetComponent<IOverlayUser>();
			bool flag = component != null && component.OverlayWhenPlacing && !HappinessUI.inst.overlayOn;
			for (int num8 = buildings.Count - 1; num8 >= path.Count; num8--)
			{
				Cell cell = buildings[num8].GetCell();
				UnityEngine.Object.Destroy(buildings[num8].gameObject);
				buildings.RemoveAt(num8);
				canPlace.RemoveAt(num8);
				canAfford.RemoveAt(num8);
				BlockBuilding.MarkBlockStackAndNeighborsDirty(cell);
			}
			bool flag2 = building.categoryHash == World.forumHash;
			GameUI.inst.DamPlannerCursorModeActive();
			ResourceAmount costAmt = building.GetCost(Player.inst.FocusedLandMass);
			bool flag3 = false;
			Vector3 pointerIntersection = default;
			int i2 = 0;
			while (i2 < path.Count)
			{
				if (i2 >= buildings.Count)
				{
					if (!flag3)
					{
						pointerIntersection = GameUI.inst.GridPointerIntersection();
						flag3 = true;
					}
					buildings.Add(InstantiateFromPrefab(heldPrefab, pointerIntersection));
					canAfford.Add(CanAffordBuilding(costAmt));
					canPlace.Add(PlacementValidationResult.Valid);
				}
				else
				{
					canAfford[i2] = CanAffordBuilding(costAmt);
				}
				if (i2 == 0 && !damPlacement)
				{
					heightOverride = World.inst.FindClosestNeighborHeight((int)path[i2].x, (int)path[i2].z, buildings[i2]);
					if (building.categoryHash == World.forumHash)
					{
						Cell cellData3 = World.inst.GetCellData((int)path[i2].x, (int)path[i2].z);
						for (int num9 = 0; num9 < cellData3.OccupyingStructure.Count; num9++)
						{
							if (cellData3.OccupyingStructure[num9].categoryHash == World.forumHash)
							{
								heightOverride = cellData3.OccupyingStructure[num9].GetPos().y;
								break;
							}
						}
					}
				}
				if (damPlacement)
				{
					buildings[i2].transform.position = new Vector3((int)path[i2].x, path[i2].y, (int)path[i2].z);
				}
				else
				{
					if (i2 > 0)
					{
						Transform offset = buildings[0].GetOffset();
						Transform offset2 = buildings[i2].GetOffset();
						offset2.localPosition = offset.localPosition;
						offset2.localRotation = offset.localRotation;
					}
					UpdateBuildingAtPosition(buildings[i2], (int)path[i2].x, (int)path[i2].z, heightOverride);
				}
				canPlace[i2] = World.inst.CanPlace(buildings[i2]);
				if (damPlacement && canPlace[i2] == PlacementValidationResult.Valid && !IsDamBlockSelectable(buildings[i2].transform.position))
				{
					canPlace[i2] = PlacementValidationResult.DamBlockBuried;
				}
				BlockBuilding.MarkBlockStackAndNeighborsDirty(buildings[i2].GetCell());
				if (cellData2 != lastCell)
				{
					TryRotateBuildingObjAuto(buildings[i2]);
					if (flag2)
					{
						Vector3 localPosition = buildings[i2].transform.GetChild(0).localPosition;
						localPosition.y = 0.01f;
						buildings[i2].transform.GetChild(0).localPosition = localPosition;
					}
					if (lastCell != null)
					{
						BlockBuilding.MarkBlockStackAndNeighborsDirty(lastCell);
					}
				}
				TerrainGen.inst.peekUnderDynamicWater = false;
				int num10 = 0;
				if (num10 < buildings.Count)
				{
					float exactWaterAmount = DynamicWater.inst.GetExactWaterAmount(buildings[num10].transform.position);
					TerrainGen.inst.peekUnderDynamicWater = exactWaterAmount > 0f;
				}
				if (!building.entireDragMustBeValid)
				{
					buildings[i2].SetValid(canAfford[i2] && canPlace[i2] == PlacementValidationResult.Valid);
				}
				buildings[i2].highlight.SetOutlineImmediate((canAfford[i2] && canPlace[i2] == PlacementValidationResult.Valid) ? 1 : 2);
				if (canAfford[i2] && canPlace[i2] == PlacementValidationResult.Valid)
				{
					cost += resourceAmount;
					buildings[i2].ForEachTileInBounds((int x, int z, Cell cell3) =>
					{
						buildingMap[cell3.index] = buildings[i2];
					});
					if (buildings[i2].placementBehavior == Building.PlacementBehavior.FlattenWithNeighbors)
					{
						UpdateTerrainPreviewForBuilding(buildings[i2], buildings[i2].transform.position.y);
					}
				}
				int num11 = i2 + 1;
				i2 = num11;
			}
			if (cellData2 != lastCell)
			{
				if (building.categoryHash == World.houseCategoryHash)
				{
					TerrainGen.inst.ClearOverlay(updateToo: false);
					ArrayExt<RadiusBonus> radiusBonuses = Player.inst.RadiusBonuses;
					for (int num12 = 0; num12 < radiusBonuses.Count; num12++)
					{
						RadiusBonus radiusBonus = radiusBonuses.data[num12];
						if (radiusBonus.Happiness < 0)
						{
							radiusBonus.DrawIndividual();
						}
					}
					if (building.uniqueNameHash == World.villarusticaHash)
					{
						building.GetComponent<RadiusBonusBuildingProduction>().DrawIndividual();
					}
					TerrainGen.inst.UpdateOverlayTextures();
					TerrainGen.inst.FadeOverlay(1f);
				}
				else if (flag)
				{
					buildings[0].GetComponent<IOverlayUser>()?.DrawOverlay(buildings[0].Center());
				}
			}
			if (building.entireDragMustBeValid)
			{
				bool flag4 = true;
				for (int num13 = 0; num13 < buildings.Count; num13++)
				{
					if (canPlace[num13] != PlacementValidationResult.Valid || !canAfford[num13])
					{
						flag4 = false;
						break;
					}
				}
				for (int num14 = 0; num14 < buildings.Count; num14++)
				{
					buildings[num14].SetValid(flag4);
				}
				if (!flag4)
				{
					cost.Clear();
				}
			}
			if (buildings.Count != canPlace.Count || buildings.Count != canAfford.Count)
			{
				Debug.LogError("Placement Mode: Buildings.Count != (CanPlace,CanAfford)");
			}
			cellHighestDamY.Clear();
			cellLowestDamY.Clear();
			if (damPlacement)
			{
				for (int num15 = 0; num15 < buildings.Count; num15++)
				{
					Cell cell2 = buildings[num15].GetCell();
					if (cell2 != null)
					{
						float y = buildings[num15].transform.position.y;
						int index = cell2.index;
						if (!cellHighestDamY.TryGetValue(index, out var value) || y > value)
						{
							cellHighestDamY[index] = y;
						}
						if (!cellLowestDamY.TryGetValue(index, out var value2) || y < value2)
						{
							cellLowestDamY[index] = y;
						}
					}
				}
			}
			for (int num16 = 0; num16 < buildings.Count; num16++)
			{
				if (canAfford[num16] && canPlace[num16] == PlacementValidationResult.Valid)
				{
					UpdateCellRotations(buildings[num16]);
				}
				else
				{
					buildings[num16].GetComponents(adjacentMeshScratch);
					for (int num17 = 0; num17 < adjacentMeshScratch.Count; num17++)
					{
						adjacentMeshScratch[num17].TrySetMesh(AdjacentMesh.AdjacentType.Default);
					}
				}
				if (buildings[num16] is BlockBuilding blockBuilding && blockBuilding != null)
				{
					blockBuilding.UpdateBlock();
				}
			}
			for (int num18 = 0; num18 < toUpdateBlockStack.Count; num18++)
			{
				if (toUpdateBlockStack[num18] != null)
				{
					BlockBuilding.MarkBlockStackAndNeighborsDirty(toUpdateBlockStack[num18]);
				}
			}
			UpdateLastRotations();
			if (!damPlacement)
			{
				for (int num19 = 0; num19 < buildings.Count; num19++)
				{
					buildings[num19].BroadcastMessage("OnUpdateTransform", SendMessageOptions.DontRequireReceiver);
				}
			}
			if (heldPrefab.uniqueNameHash == World.stoneBridgeHash || heldPrefab.uniqueNameHash == World.woodBridgeHash)
			{
				Cell endCell = null;
				bool validPath = true;
				if (mouseDownCell != null)
				{
					validPath = Bridge.SimulateBridge(mouseDownCell, dir, isDiagonal, out endCell);
				}
				Bridge.LayoutBridge(buildings, endCell, isDiagonal, validPath);
			}
			DrawArrowsForDamPlacement();
			Color[] terrainPixelsPreview = TerrainGen.inst.terrainPixelsPreview;
			if (previewIndicesScratch.Count > 0)
			{
				previewIndicesToRemove.Clear();
				if (modifiedPreviewIndices.Count > 0)
				{
					foreach (int modifiedPreviewIndex in modifiedPreviewIndices)
					{
						if (!previewIndicesScratch.Contains(modifiedPreviewIndex))
						{
							Color color = terrainPixelsPreview[modifiedPreviewIndex];
							color.r = 0f;
							terrainPixelsPreview[modifiedPreviewIndex] = color;
							previewIndicesToRemove.Add(modifiedPreviewIndex);
						}
					}
					if (previewIndicesToRemove.Count > 0)
					{
						for (int num20 = 0; num20 < previewIndicesToRemove.Count; num20++)
						{
							modifiedPreviewIndices.Remove(previewIndicesToRemove[num20]);
						}
						previewIndicesToRemove.Clear();
					}
				}
				foreach (int item2 in previewIndicesScratch)
				{
					modifiedPreviewIndices.Add(item2);
				}
				previewIndicesScratch.Clear();
				if (modifiedPreviewIndices.Count > 0)
				{
					ApplyTerrainPreview();
				}
			}
			else if (modifiedPreviewIndices.Count > 0)
			{
				ClearTerrainPreview();
			}
			lastCell = cellData2;
		}
		if ((buildings.Count == 0 || heldPrefab == null) && modifiedPreviewIndices.Count > 0)
		{
			ClearTerrainPreview();
		}
	}

	public void DrawArrowsForDamPlacement()
	{
		if (PointingSystem.GetPointer().GetPrimaryDownThisFrame())
		{
			arrowScaleMod = 1f;
		}
		else
		{
			arrowScaleMod -= Time.unscaledDeltaTime * 0.66f;
		}
		arrowScaleMod = Mathff.Clamp01(arrowScaleMod);
		if (damPlacement && buildings.Count <= 2 && Player.inst.CountBuildingsForLandMassOwner(Player.inst.PlayerLandmassOwner, World.damHash) < 10)
		{
			float y = 0.35f;
			Vector3 s = new Vector3(0.4f, 0.4f, 0.4f) * Mathf.Sqrt(arrowScaleMod);
			float num = Mathf.Sin(totalTime * 3f) * 0.05f;
			int num2 = (int)path[0].x;
			int num3 = (int)path[0].z;
			Vector3 pos = World.inst.GetCellData(num2, num3 + 1).Center3D + new Vector3(0f, y, num);
			Graphics.DrawMesh(GameUI.inst.arrowMesh, Matrix4x4.TRS(pos, Quaternion.Euler(90f, 0f, 0f), s), GameUI.inst.arrowMaterial, 0, Cam.inst.cam, 0, null, castShadows: false);
			pos = World.inst.GetCellData(num2, num3 - 1).Center3D + new Vector3(0f, y, 0f - num);
			Graphics.DrawMesh(GameUI.inst.arrowMesh, Matrix4x4.TRS(pos, Quaternion.Euler(90f, 180f, 0f), s), GameUI.inst.arrowMaterial, 0, Cam.inst.cam, 0, null, castShadows: false);
			pos = World.inst.GetCellData(num2 + 1, num3).Center3D + new Vector3(num, y, 0f);
			Graphics.DrawMesh(GameUI.inst.arrowMesh, Matrix4x4.TRS(pos, Quaternion.Euler(90f, 90f, 0f), s), GameUI.inst.arrowMaterial, 0, Cam.inst.cam, 0, null, castShadows: false);
			pos = World.inst.GetCellData(num2 - 1, num3).Center3D + new Vector3(0f - num, y, 0f);
			Graphics.DrawMesh(GameUI.inst.arrowMesh, Matrix4x4.TRS(pos, Quaternion.Euler(90f, 270f, 0f), s), GameUI.inst.arrowMaterial, 0, Cam.inst.cam, 0, null, castShadows: false);
		}
	}

	public float SnapToVerticalGrid(float height)
	{
		return Mathf.Round((height - 0.001f) * 2f) / 2f;
	}

	private float GetSurfaceHeightWithCliffs(float x, float z)
	{
		if (terrainLayerMask == -1)
		{
			terrainLayerMask = LayerMask.GetMask("Terrain");
		}
		Vector3 origin = new Vector3(x, 100f, z);
		TerrainResource terrainResource = World.inst.GetCellDataClamped((int)x, (int)z).terrainResource;
		int num = Physics.RaycastNonAlloc(origin, Vector3.down, surfaceHits, 150f, terrainLayerMask);
		float num2 = float.NegativeInfinity;
		for (int i = 0; i < num; i++)
		{
			TerrainResource componentInParent = surfaceHits[i].collider.GetComponentInParent<TerrainResource>();
			if ((!(componentInParent != null) || !(componentInParent != terrainResource)) && surfaceHits[i].point.y > num2)
			{
				num2 = surfaceHits[i].point.y;
			}
		}
		if (num2 > float.NegativeInfinity)
		{
			return num2;
		}
		return TerrainGen.inst.GetGroundHeight(x, z);
	}

	private float GetCellCenterSurfaceHeight(Cell c)
	{
		return GetSurfaceHeightWithCliffs(c.Center2D.x, c.Center2D.z);
	}

	private bool IsDamBlockSelectable(Vector3 blockPosition)
	{
		if (!damSelectableCache.TryGetValue(blockPosition, out var value))
		{
			value = (damSelectableCache[blockPosition] = ComputeDamBlockSelectable(blockPosition));
		}
		return value;
	}

	private bool ComputeDamBlockSelectable(Vector3 blockPosition, float blockHeight = 0.5f)
	{
		if (IsInsideCliff(blockPosition))
		{
			return false;
		}
		float num = blockPosition.y + blockHeight;
		float num2 = blockPosition.y + blockHeight * 0.5f;
		float surfaceHeightWithCliffs = GetSurfaceHeightWithCliffs(blockPosition.x + 0.5f, blockPosition.z + 0.5f);
		if (num > surfaceHeightWithCliffs)
		{
			return true;
		}
		float surfaceHeightWithCliffs2 = GetSurfaceHeightWithCliffs(blockPosition.x + 0.5f, blockPosition.z + 1f);
		if (num2 > surfaceHeightWithCliffs2)
		{
			return true;
		}
		float surfaceHeightWithCliffs3 = GetSurfaceHeightWithCliffs(blockPosition.x + 0.5f, blockPosition.z);
		if (num2 > surfaceHeightWithCliffs3)
		{
			return true;
		}
		float surfaceHeightWithCliffs4 = GetSurfaceHeightWithCliffs(blockPosition.x + 1f, blockPosition.z + 0.5f);
		if (num2 > surfaceHeightWithCliffs4)
		{
			return true;
		}
		float surfaceHeightWithCliffs5 = GetSurfaceHeightWithCliffs(blockPosition.x, blockPosition.z + 0.5f);
		if (num2 > surfaceHeightWithCliffs5)
		{
			return true;
		}
		return false;
	}

	private bool IsInsideCliff(Vector3 position)
	{
		if (terrainLayerMask == -1)
		{
			terrainLayerMask = LayerMask.GetMask("Terrain");
		}
		if (Physics.Raycast(new Vector3(position.x + 0.5f, position.y + 10f, position.z + 0.5f), Vector3.down, out var hitInfo, 15f, terrainLayerMask))
		{
			TerrainGen.inst.GetGroundHeight(position.x + 0.5f, position.z + 0.5f);
			if (hitInfo.point.y > position.y + 0.5f)
			{
				return true;
			}
		}
		return false;
	}

	public virtual bool AcceptPlacement()
	{
		TerrainGen.inst.peekUnderDynamicWater = false;
		ClearTerrainPreview();
		if (waitToPlace_LastPlacedCell != null)
		{
			return false;
		}
		if (IsModeAutoDrag() && !secondClick && buildings.Count <= 1 && !attemptedDrag)
		{
			secondClick = true;
			return false;
		}
		secondClick = false;
		if (attemptedDrag && (heldPrefab.dragPlacementMode == Building.DragPlacementMode.None || buildings.Count == 1))
		{
			mouseDownCell = null;
			attemptedDrag = false;
			return false;
		}
		bool flag = false;
		for (int i = 0; i < buildings.Count; i++)
		{
			buildings[i].ForEachTileInBounds((int x, int z, Cell cell3) =>
			{
				buildingMap[cell3.index] = null;
			});
		}
		Cell cell = null;
		Cell cell2 = null;
		PlacementValidationResult placementValidationResult = CanPlace();
		bool flag2 = true;
		bool flag3 = false;
		bool flag4 = false;
		for (int num = 0; num < canAfford.Count; num++)
		{
			flag3 |= canAfford[num];
			flag4 |= !canAfford[num];
		}
		if ((flag4 && heldPrefab.entireDragMustBeValid) || !flag3)
		{
			flag2 = false;
		}
		if ((placementValidationResult == PlacementValidationResult.Valid) & flag2)
		{
			lastBuildingsPlacementPosition = buildings[0].transform.position;
			Transform child = buildings[0].transform.GetChild(0);
			lastOffsetRotation = child.rotation;
			lastOffsetPosition = child.position;
			bool flag5 = heldPrefab.CategoryName == World.forumName;
			List<Building> list = new List<Building>();
			for (int num2 = 0; num2 < buildings.Count; num2++)
			{
				Building building = buildings[num2];
				buildings[num2].GetCell();
				if (canPlace[num2] == PlacementValidationResult.Valid && canAfford[num2])
				{
					list.Add(building);
					if (OnBuildingPlacing != null)
					{
						OnBuildingPlacing(building);
					}
					if (building.uniqueNameHash == World.romanOutpostHash || building.uniqueNameHash == World.romanOutpostHashNewIsland)
					{
						int landMassIdx = World.inst.GetCellDataClamped(building.Center()).landMassIdx;
						Player.inst.PlayerLandmassOwner.TakeOwnership(landMassIdx);
						if (building.uniqueNameHash == World.keepHash && Player.inst.Buildings.Count <= 0)
						{
							Player.inst.keep = building.GetComponent<Keep>();
						}
					}
					if (flag5)
					{
						Vector3 localPosition = building.transform.GetChild(0).localPosition;
						localPosition.y = 0f;
						building.transform.GetChild(0).localPosition = localPosition;
					}
					cell = World.inst.Place(building);
					if (cell2 == null)
					{
						cell2 = cell;
					}
					int landMassIdx2 = building.GetCell().landMassIdx;
					LandmassOwner landmassOwner = World.GetLandmassOwner(landMassIdx2);
					int num3 = building.GetCost(landMassIdx2).Get(4);
					if (num3 > 0)
					{
						landmassOwner.Gold -= num3;
						ResourceStatistics.AddConsumption(landMassIdx2, "construction", 4, num3);
						building.ConstructionForeman.AddBuildResource(4, num3);
					}
					flag = true;
					if ((building.CategoryHash() == World.forumHash || building.CategoryHash() == World.bathCategoryHash) && building.doBuildAnimation && GetMeshTerrainHeightForBuilding(building, ref scratchMeshIndices, ref scratchMeshHeights))
					{
						EditTerrainProject.CreateNewEmptyProject().Init(scratchMeshIndices.ToArray(), scratchMeshHeights.ToArray(), (int)building.size.x * (int)building.size.z, tightRails: true, showFences: false, 1, zonesUnderBuildings: true);
					}
				}
				else
				{
					UnityEngine.Object.Destroy(building.gameObject);
				}
			}
		}
		else
		{
			for (int num4 = 1; num4 < buildings.Count; num4++)
			{
				UnityEngine.Object.Destroy(buildings[num4].gameObject);
			}
		}
		if (flag)
		{
			RuntimeManager.PlayOneShot(heldPrefab.onBuildingPlacedEvent, cell2.Center3D);
			Reset();
			ClearHeldPrefab();
			if (CanPlaceAgain())
			{
				if (lastBuilding is BlockBuilding)
				{
					damReplaceMouseDownPoint = Input.mousePosition;
					damReplacementFixed = true;
				}
				if (lastBuilding.CategoryName == "castleblock" || GamepadControl.inst.isControllerActive)
				{
					StageLastBuiltBuilding();
				}
				else
				{
					waitToPlace_LastPlacedCell = World.inst.GetCellData(lastBuildingsPlacementPosition);
				}
			}
			else
			{
				TerrainGen.inst.StopTerritoryTexture();
				ConsoleCursorMenu.inst.SetConsoleMode();
				GameUI.inst.AbortCursorObjPlacement();
			}
		}
		else
		{
			mouseDownCell = null;
			attemptedDrag = false;
			if (buildings.Count > 1)
			{
				buildings.RemoveRange(1, buildings.Count - 1);
				canPlace.RemoveRange(1, canPlace.Count - 1);
				canAfford.RemoveRange(1, canAfford.Count - 1);
				UpdateLastRotations();
			}
			if (placementValidationResult == PlacementValidationResult.OutsideOfTerritory)
			{
				TerrainGen.inst.PulseTerritory();
			}
		}
		return flag;
	}

	private void TryAddTerrainEdit(ref Dictionary<int, float> entries, int meshX, int meshZ, float height, int gridWidth)
	{
		int key = meshZ * (gridWidth * 2 + 1) + meshX;
		if (!entries.ContainsKey(key))
		{
			entries.Add(key, height);
		}
		else if (entries[key] > height)
		{
			entries[key] = height;
		}
	}

	private bool GetMeshTerrainHeightForBuilding(Building currB, ref List<int> indices, ref List<float> heights)
	{
		scratchMeshPoints.Clear();
		Cell cell = currB.GetCell();
		float y = currB.GetPos().y;
		Cell cellData = World.inst.GetCellData(cell.x, cell.z);
		cellData.StructureFindByCategory(currB.CategoryHash());
		int gridWidth = World.inst.GridWidth;
		int num = cellData.index % gridWidth;
		int num2 = cellData.index / gridWidth;
		int num3 = num * 2 + 1;
		int num4 = num2 * 2 + 1;
		float num5 = y;
		for (int i = 0; i < World.inst.cardinalOffsets.Length; i++)
		{
			Vector3 vector = World.inst.cardinalOffsets[i];
			Building building = World.inst.GetCellData(cellData.x + (int)vector.x, cellData.z + (int)vector.z).StructureFindByCategory(currB.CategoryHash());
			num5 = y;
			if (building != null && building.GetPos().y < y)
			{
				num5 = building.GetPos().y;
			}
			switch (i)
			{
			case 0:
				TryAddTerrainEdit(ref scratchMeshPoints, num3 + 1, num4 + 1, num5, gridWidth);
				TryAddTerrainEdit(ref scratchMeshPoints, num3 + 1, num4, num5, gridWidth);
				TryAddTerrainEdit(ref scratchMeshPoints, num3 + 1, num4 - 1, num5, gridWidth);
				break;
			case 1:
				TryAddTerrainEdit(ref scratchMeshPoints, num3 - 1, num4 + 1, num5, gridWidth);
				TryAddTerrainEdit(ref scratchMeshPoints, num3 - 1, num4, num5, gridWidth);
				TryAddTerrainEdit(ref scratchMeshPoints, num3 - 1, num4 - 1, num5, gridWidth);
				break;
			case 2:
				TryAddTerrainEdit(ref scratchMeshPoints, num3 + 1, num4 + 1, num5, gridWidth);
				TryAddTerrainEdit(ref scratchMeshPoints, num3, num4 + 1, num5, gridWidth);
				TryAddTerrainEdit(ref scratchMeshPoints, num3 - 1, num4 + 1, num5, gridWidth);
				break;
			case 3:
				TryAddTerrainEdit(ref scratchMeshPoints, num3 + 1, num4 - 1, num5, gridWidth);
				TryAddTerrainEdit(ref scratchMeshPoints, num3, num4 - 1, num5, gridWidth);
				TryAddTerrainEdit(ref scratchMeshPoints, num3 - 1, num4 - 1, num5, gridWidth);
				break;
			}
		}
		TryAddTerrainEdit(ref scratchMeshPoints, num3, num4, y, gridWidth);
		indices.Clear();
		heights.Clear();
		foreach (KeyValuePair<int, float> scratchMeshPoint in scratchMeshPoints)
		{
			float num6 = TerrainGen.inst.heightCache[scratchMeshPoint.Key];
			if (!(Mathf.Abs(scratchMeshPoint.Value - num6) < 0.001f))
			{
				indices.Add(scratchMeshPoint.Key);
				heights.Add(scratchMeshPoint.Value);
			}
		}
		return indices.Count > 0;
	}

	private bool CanAffordBuilding(ResourceAmount costAmt)
	{
		if (landmass == -1)
		{
			return false;
		}
		if (GameUI.inst.DamPlannerCursorModeActive())
		{
			return true;
		}
		bool flag = false;
		tempTotal.CopyFrom(Player.inst.resourcesPerLandmass[landmass]);
		tempTotal.Subtract(in cost);
		tempTotal.Subtract(in extraCost);
		for (int i = 0; i < costAmt.resources.Count; i++)
		{
			int amount = costAmt.resources[i].Amount;
			if (tempTotal.Get(costAmt.resources[i].resourceID) - amount < 0 && amount > 0)
			{
				flag = true;
			}
		}
		return !flag;
	}

	public virtual PlacementValidationResult CanPlace()
	{
		PlacementValidationResult result = PlacementValidationResult.Valid;
		bool flag = false;
		bool flag2 = false;
		for (int i = 0; i < canPlace.Count; i++)
		{
			PlacementValidationResult placementValidationResult = canPlace[i];
			flag |= placementValidationResult == PlacementValidationResult.Valid;
			flag2 |= placementValidationResult != PlacementValidationResult.Valid;
			if (placementValidationResult != PlacementValidationResult.Valid)
			{
				result = placementValidationResult;
			}
		}
		if (flag2 && heldPrefab.entireDragMustBeValid)
		{
			for (int j = 0; j < buildings.Count; j++)
			{
				buildings[j].SetValid(valid: false);
			}
			return result;
		}
		if (flag)
		{
			return PlacementValidationResult.Valid;
		}
		return result;
	}

	public bool CanPlaceAgain()
	{
		if (lastBuilding != null && !lastBuilding.Equals(null) && lastBuilding.UniqueName != "chamberofwar")
		{
			return lastBuilding.UniqueName != "romanoutpost";
		}
		return false;
	}

	public void Reset()
	{
		mouseDownCell = null;
		attemptedDrag = false;
		secondClick = false;
	}

	private Vector3 ClampPosForCursorObj(Vector3 newPos, Building CursorObj)
	{
		newPos.x = Mathf.Clamp(newPos.x, 1f, (float)World.inst.GridWidth - (CursorObj.GetBounds().x + 1f));
		newPos.z = Mathf.Clamp(newPos.z, 1f, (float)World.inst.GridHeight - (CursorObj.GetBounds().z + 1f));
		return newPos;
	}

	private Vector3 GetCursorPos()
	{
		Vector3 zero = Vector3.zero;
		Ray ray = PointingSystem.GetRay();
		placementRelatedBuilding = null;
		hitWaterSurface = false;
		if (Vector3.Dot(Vector3.down, ray.direction.normalized) > 0f)
		{
			bool flag = Physics.Raycast(ray, out var hitInfo);
			DynamicWater.WaterRaycastHit waterRaycastHit = DynamicWater.inst.RaycastWater(ray, 100f);
			bool num = flag || waterRaycastHit.hit;
			bool flag2 = waterRaycastHit.hit && waterRaycastHit.distance < hitInfo.distance && Mathff.Dot(waterRaycastHit.normal, Vector3.up) > 0.9f;
			if (num)
			{
				if (flag2)
				{
					hitWaterSurface = true;
					waterSurfaceHitY = waterRaycastHit.point.y;
					float groundHeight = TerrainGen.inst.GetGroundHeight(waterRaycastHit.point.x, waterRaycastHit.point.z);
					if (Mathf.Abs(waterSurfaceHitY - groundHeight) < 0.1f)
					{
						hitWaterSurface = false;
					}
					return waterRaycastHit.point;
				}
				if (stackablePlacement && !damPlacement)
				{
					BuildingCollider component = hitInfo.collider.GetComponent<BuildingCollider>();
					if ((bool)component)
					{
						Building building = component.Building as Building;
						if (building != null)
						{
							zero = building.Center();
							zero.y = TerrainGen.inst.GetGroundHeight(zero.x, zero.z);
							return zero;
						}
					}
				}
				if (damPlacement)
				{
					if (damReplacementFixed)
					{
						return zero;
					}
					BuildingCollider component2 = hitInfo.collider.GetComponent<BuildingCollider>();
					if ((bool)component2)
					{
						Building building2 = component2.Building as Building;
						if (building2 != null)
						{
							placementRelatedBuilding = building2;
							return building2.Center() + new Vector3(hitInfo.normal.x * 1f, hitInfo.normal.y * 0.5f, hitInfo.normal.z * 1f);
						}
					}
				}
			}
			return GameUI.inst.GridPointerIntersection();
		}
		return Vector3.zero;
	}

	public int PlacementCount()
	{
		return buildings.Count;
	}

	public bool TryRotateBuildingObjAuto(Building b)
	{
		if (b == null)
		{
			return false;
		}
		Vector3 currPos = b.transform.position;
		if (b.uniqueNameHash == World.fishinghutHash)
		{
			World.inst.ToGridCoord(currPos, out var x, out var z);
			Cell cardinalAdjacentType = World.inst.GetCardinalAdjacentType(x, z, TerrainType.Water);
			if (cardinalAdjacentType != null && World.inst.GetCellDataClamped(x, z).Type != TerrainType.Water)
			{
				Vector3 forward = cardinalAdjacentType.Position - currPos;
				forward.y = 0f;
				b.transform.GetChild(0).transform.rotation = Quaternion.LookRotation(forward);
			}
			return true;
		}
		if (b.uniqueNameHash == World.dockHash || b.uniqueNameHash == World.transportShipPortHash)
		{
			if (b.PlacementValidaton != null)
			{
				Quaternion rotation = b.transform.GetChild(0).transform.rotation;
				bool flag = false;
				for (int i = 0; i < World.inst.cardinalOffsets.Length; i++)
				{
					b.transform.GetChild(0).transform.rotation = Quaternion.LookRotation(World.inst.cardinalOffsets[i]);
					PlacementValidationResult result = PlacementValidationResult.MustBeOnFlatLand;
					b.PlacementValidaton(ref result);
					if (result == PlacementValidationResult.Valid)
					{
						flag = true;
						break;
					}
				}
				if (!flag)
				{
					b.transform.GetChild(0).transform.rotation = rotation;
				}
			}
		}
		else
		{
			if (b.categoryHash == World.quarryHash)
			{
				int rID = -1;
				if (b.uniqueNameHash == World.quarryHash)
				{
					rID = 2;
				}
				else if (b.uniqueNameHash == World.marbleQuarryHash)
				{
					rID = 14;
				}
				World.inst.ToGridCoord(currPos, out var x2, out var z2);
				Cell cardinalAdjacentResource = World.inst.GetCardinalAdjacentResource(x2, z2, rID);
				if (cardinalAdjacentResource != null)
				{
					Vector3 forward2 = cardinalAdjacentResource.Position - currPos;
					forward2.y = 0f;
					b.transform.GetChild(0).transform.rotation = Quaternion.LookRotation(forward2) * Quaternion.AngleAxis(-90f, new Vector3(0f, 1f, 0f));
				}
				return true;
			}
			if (b.uniqueNameHash == World.ironMineHash)
			{
				World.inst.ToGridCoord(currPos, out var x3, out var z3);
				Cell cardinalAdjacentResource2 = World.inst.GetCardinalAdjacentResource(x3, z3, 5);
				if (cardinalAdjacentResource2 != null)
				{
					Vector3 forward3 = cardinalAdjacentResource2.Position - currPos;
					forward3.y = 0f;
					b.transform.GetChild(0).transform.rotation = Quaternion.LookRotation(forward3);
				}
				return true;
			}
			if (b.TryGetComponent<Market>(out var component))
			{
				component.AlignWithRoad();
				return true;
			}
			if (b.autoRotateToFaceRoad)
			{
				Cell roadCell = null;
				b.ForEachTileInBounds((int num, int num2, Cell cell2) =>
				{
					World.inst.GetNeighborCells(World.inst.GetCellDataClamped(currPos), ref scratchNeighbors4);
					for (int j = 0; j < scratchNeighbors4.Length; j++)
					{
						if (scratchNeighbors4[j] != null && scratchNeighbors4[j].StructureCompareCategory(World.pathHash))
						{
							roadCell = scratchNeighbors4[j];
							break;
						}
					}
				});
				if (roadCell != null)
				{
					Vector3 input = roadCell.Position - currPos;
					if (input.xz().magnitude < 1.3f)
					{
						Quaternion rotation2 = Quaternion.LookRotation(input.xz());
						b.transform.GetChild(0).rotation = rotation2;
						if (b.uniqueNameHash == World.statueSmallArchHash || b.uniqueNameHash == World.statueArchHash)
						{
							b.transform.GetChild(0).Rotate(Vector3.up, 90f);
						}
					}
				}
				return true;
			}
			if (b.categoryHash == World.gateHash)
			{
				Cell[] array = new Cell[4];
				Cell cell = b.GetCell();
				World.inst.GetNeighborCells(cell, ref array);
				if (cell != null && cell.BottomStructure != null && World.IsLandRoad(cell.BottomStructure))
				{
					if ((array[0] != null && array[0].BottomStructure != null && World.IsLandRoad(array[0].BottomStructure)) || (array[2] != null && array[2].BottomStructure != null && World.IsLandRoad(array[2].BottomStructure)))
					{
						b.transform.GetChild(0).eulerAngles = new Vector3(0f, 90f, 0f);
					}
					if ((array[1] != null && array[1].BottomStructure != null && World.IsLandRoad(array[1].BottomStructure)) || (array[3] != null && array[3].BottomStructure != null && World.IsLandRoad(array[3].BottomStructure)))
					{
						b.transform.GetChild(0).eulerAngles = new Vector3(0f, 0f, 0f);
					}
				}
				if ((array[0] != null && array[0].BottomStructure != null && array[0].BottomStructure.categoryHash == World.castleblockHash) || (array[2] != null && array[2].BottomStructure != null && array[2].BottomStructure.categoryHash == World.castleblockHash))
				{
					b.transform.GetChild(0).eulerAngles = new Vector3(0f, 0f, 0f);
				}
				if ((array[1] != null && array[1].BottomStructure != null && array[1].BottomStructure.categoryHash == World.castleblockHash) || (array[3] != null && array[3].BottomStructure != null && array[3].BottomStructure.categoryHash == World.castleblockHash))
				{
					b.transform.GetChild(0).eulerAngles = new Vector3(0f, 90f, 0f);
				}
				return true;
			}
		}
		return false;
	}

	public bool StackRuleExceptions(Building b, Cell newCell)
	{
		bool flag = World.IsLandRoad(b);
		if ((!flag || !newCell.StructureCompareCategoryNameAll(World.gateHash)) && (!flag || !newCell.StructureCompareUniqueNameAll(World.aqueductHash)) && (!flag || !newCell.StructureCompareUniqueNameAll(World.castlestairsHash)) && b.uniqueNameHash != World.archerTowerHash && (b.uniqueNameHash != World.aqueductHash || !newCell.BottomStructureIsCategory(World.castleblockHash)) && (b.uniqueNameHash != World.castleblockHash || !newCell.StructureCompareUniqueNameAll(World.woodcastleblockHash)) && (b.uniqueNameHash != World.castleblockHash || !newCell.TopStructureIs(World.woodcastleblockHash) || !newCell.BottomStructureIs(World.aqueductHash)) && (b.uniqueNameHash != World.gateHash || !newCell.StructureCompareUniqueNameAll(World.woodengateHash)) && (b.uniqueNameHash != World.aqueductHash || !newCell.StructureCompareCategoryNameAll(World.gateHash)))
		{
			if (b.categoryHash == World.gateHash)
			{
				return newCell.StructureCompareCategoryAll(World.castleblockHash);
			}
			return false;
		}
		return true;
	}

	public void UpdateTerrainTexture()
	{
		if (heldPrefab.uniqueNameHash == World.stoneBridgeHash || heldPrefab.uniqueNameHash == World.woodBridgeHash)
		{
			TerrainGen.inst.StartTerritoryTexture(1, landmass);
		}
		else if (heldPrefab.uniqueNameHash == World.quarryHash)
		{
			TerrainGen.inst.StartTerritoryTexture(2, landmass);
		}
		else if (heldPrefab.uniqueNameHash == World.marbleQuarryHash)
		{
			TerrainGen.inst.StartTerritoryTexture(8, landmass);
		}
		else if (heldPrefab.uniqueNameHash == World.ironMineHash)
		{
			TerrainGen.inst.StartTerritoryTexture(4, landmass);
		}
		else if (heldPrefab.uniqueNameHash == World.dockHash || heldPrefab.uniqueNameHash == World.transportShipPortHash)
		{
			TerrainGen.inst.StartTerritoryTexture(3, landmass);
		}
		else if (heldPrefab.uniqueNameHash == World.fishinghutHash)
		{
			TerrainGen.inst.StartTerritoryTexture(9, landmass);
		}
		else if (heldPrefab.uniqueNameHash == World.claypitHash)
		{
			TerrainGen.inst.StartTerritoryTexture(7, landmass);
		}
		else if (!heldPrefab.ignoreRoadCoverageForPlacement)
		{
			TerrainGen.inst.StartTerritoryTexture(6, landmass);
		}
		else
		{
			TerrainGen.inst.StopTerritoryTexture();
		}
	}

	private void UpdateBuildingAtPosition(Building b, int cx, int cz, float heightOverride = -1f)
	{
		Vector3 position = new Vector3(cx, 0f, cz);
		float seaLevel = Water.inst.transform.position.y + 0.03f;
		if (b.placementBehavior == Building.PlacementBehavior.FlattenWithNeighbors)
		{
			position.y = heightOverride;
		}
		else
		{
			if (b.allowPlacementOnForum)
			{
				bool isAtleastOneForum = false;
				float targetY = 0f;
				b.ForEachTileInBounds((int x, int z, Cell cell) =>
				{
					for (int i = 0; i < cell.OccupyingStructure.Count; i++)
					{
						Building building2 = cell.OccupyingStructure[i];
						if (building2.categoryHash == World.forumHash)
						{
							isAtleastOneForum = true;
							Vector3 pos = building2.GetPos();
							if (targetY < pos.y)
							{
								targetY = pos.y;
							}
						}
					}
				});
				if (isAtleastOneForum)
				{
					position.y = targetY;
					b.transform.position = position;
					return;
				}
			}
			int count = 0;
			float avgY = 0f;
			float minHeight = 1000f;
			float maxHeight = -1000f;
			bool adjacentWater = false;
			b.ForEachTileInBounds((int x, int z, Cell cell) =>
			{
				if (cell.Type != TerrainType.Water)
				{
					int num4 = DynamicWater.MapIndexWorldToMesh(cell.index, World.inst.GridWidth);
					for (int i = -1; i <= 1; i++)
					{
						for (int j = -1; j <= 1; j++)
						{
							int index = num4 + j + (World.inst.GridWidth * 2 + 1) * i;
							float vertYUnsafe = TerrainGen.inst.GetVertYUnsafe(index);
							if (vertYUnsafe < minHeight)
							{
								minHeight = vertYUnsafe;
							}
							if (vertYUnsafe > maxHeight)
							{
								maxHeight = vertYUnsafe;
							}
							avgY += vertYUnsafe;
							count++;
						}
					}
					if (!adjacentWater)
					{
						adjacentWater |= DynamicWater.inst.simplifiedWaterGrid[z * World.inst.GridWidth + (x + 1)] > 0f;
					}
					if (!adjacentWater)
					{
						adjacentWater |= DynamicWater.inst.simplifiedWaterGrid[z * World.inst.GridWidth + (x - 1)] > 0f;
					}
					if (!adjacentWater)
					{
						adjacentWater |= DynamicWater.inst.simplifiedWaterGrid[(z + 1) * World.inst.GridWidth + x] > 0f;
					}
					if (!adjacentWater)
					{
						adjacentWater |= DynamicWater.inst.simplifiedWaterGrid[(z - 1) * World.inst.GridWidth + x] > 0f;
					}
				}
				else
				{
					avgY += seaLevel;
					count++;
				}
			});
			avgY /= count;
			if (b.categoryHash == World.castleblockHash)
			{
				position.y = ((avgY - minHeight < MIN_DIFF_TO_SNAP_MIN_HEIGHT) ? avgY : minHeight);
			}
			else
			{
				position.y = (adjacentWater ? (maxHeight + 0.03f) : Mathf.Max(seaLevel, avgY));
			}
		}
		float num = 0f;
		bool flag = false;
		float y = position.y;
		Cell cellData = World.inst.GetCellData(cx, cz);
		if ((bool)cellData.TopStructure && !StackRuleExceptions(b, cellData))
		{
			for (int num2 = 0; num2 < cellData.OccupyingStructure.Count; num2++)
			{
				Building building = cellData.OccupyingStructure[num2];
				if (building.Stackable)
				{
					if (!flag)
					{
						y = building.transform.position.y;
						flag = true;
					}
					num += (float)building.StackHeight * 0.25f;
				}
			}
		}
		if (flag)
		{
			position.y = y + num;
		}
		for (int num3 = 0; num3 < cellData.OccupyingStructure.Count; num3++)
		{
			if (b.CanSnapInside(cellData.OccupyingStructure[num3]))
			{
				b.SnapInside(cellData.OccupyingStructure[num3]);
			}
		}
		b.transform.position = position;
	}

	private void UpdateCellRotations(Building b)
	{
		b.GetComponents(adjacentMeshScratch);
		for (int i = 0; i < adjacentMeshScratch.Count; i++)
		{
			adjacentMeshScratch[i].UpdateRotation();
		}
		if (b.categoryHash == pathHash)
		{
			Road component = b.GetComponent<Road>();
			if (component != null)
			{
				component.UpdateTerrainRotation();
			}
		}
		if (b.uniqueNameHash == castlestairsHash)
		{
			CastleStairs component2 = b.GetComponent<CastleStairs>();
			if (component2 != null)
			{
				component2.UpdateRotation();
			}
		}
	}

	public bool TestRoadConnection(Cell c)
	{
		for (int i = 0; i < buildings.Count; i++)
		{
			if (Road.ConnectsToRoad(buildings[i]) && buildings[i].GetCell() == c)
			{
				return true;
			}
		}
		return false;
	}

	public bool TestAqueductConnection(Cell c)
	{
		for (int i = 0; i < buildings.Count; i++)
		{
			if (buildings[i].GetComponent<IWaterSystemUser>() != null && buildings[i].GetCell() == c)
			{
				return true;
			}
		}
		return false;
	}

	public void StageLastBuiltBuilding()
	{
		waitToPlace_LastPlacedCell = null;
		GameUI.inst.OnBuild(lastBuilding, notFirstPlacement: true);
	}

	public void CancelWaitToPlace()
	{
		waitToPlace_LastPlacedCell = null;
		TerrainGen.inst.StopTerritoryTexture();
	}

	private void UpdateLastRotations()
	{
		if (prevBuildingPRS != null)
		{
			UpdateNeighborRotations(prevBuildingPRS);
			return;
		}
		int i = 0;
		for (int count = prevPath.Count; i < count; i++)
		{
			Vector3 vector = prevPath[i];
			int j = 0;
			for (int num = offsets.Length; j < num; j++)
			{
				Vector3 vector2 = offsets[j];
				Cell cellDataClamped = World.inst.GetCellDataClamped((int)(vector.x + vector2.x), (int)(vector.z + vector2.z));
				for (int k = 0; k < cellDataClamped.OccupyingStructure.Count; k++)
				{
					UpdateCellRotations(cellDataClamped.OccupyingStructure[k]);
				}
			}
		}
	}

	public void UpdateNeighborRotations(BuildingPRS prevPath)
	{
		Vector3 vector = World.inst.SnapToGrid2D(prevPath.pos);
		int num = Mathf.RoundToInt(prevPath.size.x);
		int num2 = Mathf.RoundToInt(prevPath.size.z);
		for (int i = -1; i < num + 1; i++)
		{
			for (int j = -1; j < num2 + 1; j++)
			{
				Vector3 vector2 = new Vector3(i, 0f, j);
				if ((int)prevPath.size.x != (int)prevPath.size.z)
				{
					vector2 = prevPath.rot * vector2;
				}
				int x = Mathf.RoundToInt(vector.x + vector2.x);
				int z = Mathf.RoundToInt(vector.z + vector2.z);
				Cell cellData = World.inst.GetCellData(x, z);
				if (cellData != null)
				{
					for (int k = 0; k < cellData.OccupyingStructure.Count; k++)
					{
						UpdateCellRotations(cellData.OccupyingStructure[k]);
					}
				}
			}
		}
	}

	private int pathCost(PathCell pc, int teamId)
	{
		Cell cellData = World.inst.GetCellData(pc);
		if ((heldPrefab.categoryHash == pathHash || heldPrefab.categoryHash == aqueductHash) && cellData.OccupyingStructure.Count > 0)
		{
			if (cellData.OccupyingStructure[0].categoryHash == pathHash || cellData.OccupyingStructure[0].categoryHash == aqueductHash || cellData.OccupyingStructure[0].categoryHash == World.gateHash)
			{
				return 0;
			}
			return 30;
		}
		if (cellData.Type == TerrainType.Obstruction || cellData.Type == TerrainType.WolfDen || cellData.Type == TerrainType.Water)
		{
			return 500;
		}
		return 1;
	}

	private bool blocksPath(PathCell c, int teamId)
	{
		return false;
	}

	internal void DidRotate()
	{
		if (HappinessUI.inst.overlayOn)
		{
			return;
		}
		Building building = buildings[0];
		IOverlayUser component = heldPrefab.GetComponent<IOverlayUser>();
		if (component != null && component.OverlayWhenPlacing)
		{
			_ = !HappinessUI.inst.overlayOn;
		}
		else
			_ = 0;
		if (building != null && building.categoryHash == World.houseCategoryHash)
		{
			TerrainGen.inst.ClearOverlay(updateToo: false);
			ArrayExt<RadiusBonus> radiusBonuses = Player.inst.RadiusBonuses;
			for (int i = 0; i < radiusBonuses.Count; i++)
			{
				RadiusBonus radiusBonus = radiusBonuses.data[i];
				if (radiusBonus.Happiness < 0)
				{
					radiusBonus.DrawIndividual();
				}
			}
			if (building.uniqueNameHash == World.villarusticaHash)
			{
				building.GetComponent<RadiusBonusBuildingProduction>().DrawIndividual();
			}
			TerrainGen.inst.UpdateOverlayTextures();
			TerrainGen.inst.FadeOverlay(1f);
			return;
		}
		for (int j = 0; j < buildings.Count; j++)
		{
			component = buildings[j].GetComponent<IOverlayUser>();
			if (component != null && component.OverlayWhenPlacing)
			{
				component.DrawOverlay(buildings[j].Center());
			}
		}
	}

	public virtual void AbortPlacement(bool refund)
	{
		TerrainGen.inst.peekUnderDynamicWater = false;
		ClearTerrainPreview();
		if (heldPrefab != null || waitToPlace_LastPlacedCell != null)
		{
			Reset();
			List<Cell> cellsToUpdate = new List<Cell>();
			for (int i = 0; i < buildings.Count; i++)
			{
				if (!(buildings[i] == null))
				{
					buildings[i].ForEachTileInBounds((int x, int z, Cell cell) =>
					{
						buildingMap[cell.index] = null;
						cellsToUpdate.Add(cell);
					});
					UnityEngine.Object.Destroy(buildings[i].gameObject);
				}
			}
			buildings.Clear();
			cellHighestDamY.Clear();
			cellLowestDamY.Clear();
			for (int num = 0; num < cellsToUpdate.Count; num++)
			{
				if (cellsToUpdate[num] != null)
				{
					BlockBuilding.MarkBlockStackAndNeighborsDirty(cellsToUpdate[num]);
				}
			}
			UpdateLastRotations();
			if (!World.inst.inFirstPlacementPhase)
			{
				World.inst.HideResourceTooltipUIs();
			}
			TerrainGen.inst.ClearOverlay(updateToo: true);
		}
		ClearHeldPrefab();
		extraCost.Clear();
		World.inst.SetGrassEnabled(e: true);
		CancelWaitToPlace();
	}

	private void ClearHeldPrefab()
	{
		heldPrefab = null;
		buildings.Clear();
		canPlace.Clear();
		canAfford.Clear();
		path.Clear();
		prevBuildingPRS = null;
	}

	private void ShowWaterBuildingMarkers(int landMass)
	{
		HeightMarker.ShowLandmassWaterBuildings(landMass);
		if (buildings.Count > 0 && buildings[0] != null)
		{
			AqueductBuilding component = buildings[0].GetComponent<AqueductBuilding>();
			if (component != null)
			{
				HeightMarker.Show(component);
			}
		}
	}

	public void TryHandlePrimaryDown()
	{
		if (heldPrefab != null && !secondClick)
		{
			Vector3 worldPos = ClampPosForCursorObj(GetCursorPos(), buildings[0]);
			mouseDownCell = World.inst.GetCellData(worldPos);
			mouseDownCursorPos = worldPos;
			mouseDownPlacementRelatedBuilding = placementRelatedBuilding;
		}
	}

	public bool IsPlacing()
	{
		if (!(heldPrefab != null))
		{
			return waitToPlace_LastPlacedCell != null;
		}
		return true;
	}

	public ResourceAmount GetPlacementCost()
	{
		return cost;
	}

	public ResourceAmount GetTotalPotentialCost(int landmass)
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		for (int i = 0; i < buildings.Count; i++)
		{
			resourceAmount.Add(buildings[i].GetCost(landmass));
		}
		return resourceAmount;
	}

	public bool IsOneNotAffordable()
	{
		for (int i = 0; i < canAfford.Count; i++)
		{
			if (!canAfford[i])
			{
				return true;
			}
		}
		return false;
	}

	public bool IsOneAffordable()
	{
		for (int i = 0; i < canAfford.Count; i++)
		{
			if (canAfford[i])
			{
				return true;
			}
		}
		return false;
	}

	public PlacementValidationResult GetInvalidPlacementResult()
	{
		PlacementValidationResult result = PlacementValidationResult.Valid;
		for (int i = 0; i < canPlace.Count; i++)
		{
			if (canPlace[i] != PlacementValidationResult.Valid)
			{
				result = canPlace[i];
			}
		}
		return result;
	}

	public Building GetHoverBuilding()
	{
		if (buildings.Count <= 0)
		{
			return null;
		}
		return buildings[0];
	}

	public Building InstantiateFromPrefab(Building building)
	{
		return InstantiateFromPrefab(building, GameUI.inst.GridPointerIntersection());
	}

	public Building InstantiateFromPrefab(Building building, Vector3 pointerIntersection)
	{
		Building building2 = UnityEngine.Object.Instantiate(building);
		building2.transform.parent = Player.inst.buildingContainer.transform;
		building2.transform.position = ClampPosForCursorObj(pointerIntersection, building2);
		building2.Init();
		building2.isPreviewBuilding = building2.uniqueNameHash == World.damHash;
		return building2;
	}

	private void UpdateTerrainPreviewForBuilding(Building b, float targetHeight)
	{
		if (b.placementBehavior == Building.PlacementBehavior.FlattenWithNeighbors)
		{
			Color[] terrainPixelsPreview = TerrainGen.inst.terrainPixelsPreview;
			_ = World.inst.GridWidth;
			scratchMeshHeights.Clear();
			scratchMeshIndices.Clear();
			GetMeshTerrainHeightForBuilding(b, ref scratchMeshIndices, ref scratchMeshHeights);
			for (int i = 0; i < scratchMeshIndices.Count; i++)
			{
				int num = scratchMeshIndices[i];
				float num2 = scratchMeshHeights[i];
				float vertYUnsafe = TerrainGen.inst.GetVertYUnsafe(num);
				Color color = terrainPixelsPreview[num];
				color.r = num2 - vertYUnsafe;
				terrainPixelsPreview[num] = color;
				previewIndicesScratch.Add(num);
			}
		}
	}

	private void ApplyTerrainPreview()
	{
		if (modifiedPreviewIndices.Count != 0)
		{
			TerrainGen.inst.terrainHeightMapPreview.SetPixels(TerrainGen.inst.terrainPixelsPreview);
			TerrainGen.inst.terrainHeightMapPreview.Apply();
		}
	}

	private void ClearTerrainPreview()
	{
		if (modifiedPreviewIndices.Count == 0)
		{
			return;
		}
		foreach (int modifiedPreviewIndex in modifiedPreviewIndices)
		{
			if (modifiedPreviewIndex >= 0 && modifiedPreviewIndex < TerrainGen.inst.terrainPixelsPreview.Length)
			{
				TerrainGen.inst.terrainPixelsPreview[modifiedPreviewIndex].r = 0f;
			}
		}
		TerrainGen.inst.terrainHeightMapPreview.SetPixels(TerrainGen.inst.terrainPixelsPreview);
		TerrainGen.inst.terrainHeightMapPreview.Apply();
		modifiedPreviewIndices.Clear();
		previewIndicesScratch.Clear();
		previewIndicesToRemove.Clear();
	}
}
