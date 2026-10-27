using System;
using System.Collections.Generic;
using UnityEngine;

public class MountainPlacer : MonoBehaviour
{
	[Serializable]
	public class Group
	{
		public List<Transform> items = new List<Transform>();
	}

	[Serializable]
	public struct SubMountain
	{
		public MountainPlacer[] prefabs;

		public Transform target;
	}

	[Serializable]
	public class EditorData
	{
		public float offset = 7f;

		public float samples = 16f;

		[Range(0f, 180f)]
		public float offsetAngle;

		public int yMin = -10;

		public int yMax = 10;
	}

	public Transform BoundingPointsContainer;

	public Transform TerrainModifiersContainer;

	public Transform RocksContainer;

	public Transform ResourceGroupsContainer;

	public Transform BoundingSphereContainer;

	public Transform SubtractiveSphereContainer;

	public Transform EdgeDetector;

	public List<SubMountain> subMountains;

	public List<Group> groups = new List<Group>();

	public MinMax numGroupsOn;

	[NonSerialized]
	public List<MountainPlacerResource> mResourceGroups;

	public EditorData eData;

	public bool doShiftToShore;

	public bool doShiftForward = true;

	public bool doShiftBackward = true;

	public bool doSubtraction;

	private int landmass = -1;

	public static bool DEBUG_DRAW = false;

	public Vector3 center = Vector3.zero;

	public float radius;

	private Vector3[] directions = new Vector3[8]
	{
		new Vector3(1f, 0f, 0f),
		new Vector3(-1f, 0f, 0f),
		new Vector3(0f, 0f, 1f),
		new Vector3(0f, 0f, -1f),
		new Vector3(1f, 0f, 1f),
		new Vector3(-1f, 0f, 1f),
		new Vector3(-1f, 0f, -1f),
		new Vector3(1f, 0f, -1f)
	};

	private Cell[] scratch4Cells = new Cell[4];

	public static float MESH_TO_TERRAIN_THRESHOLD = 0.1f;

	private static List<MountainPlacerResource> scratchResources = new List<MountainPlacerResource>();

	private static List<(MountainPlacerResource mpr, MountainPlacerResource.ResourceVariant variant)> scratchFits = new List<(MountainPlacerResource, MountainPlacerResource.ResourceVariant)>();

	private void LiftTerrain(MountainPlacerTerrainModifier child, int lmIdx)
	{
		Bounds bounds = child.GetComponent<MeshRenderer>().bounds;
		int num = (int)Mathff.Clamp(bounds.min.x, 1f, World.inst.GridWidth - 1);
		int num2 = (int)Mathff.Clamp(bounds.max.x, 1f, World.inst.GridWidth - 1);
		int num3 = (int)Mathff.Clamp(bounds.min.z, 1f, World.inst.GridHeight - 1);
		int num4 = (int)Mathff.Clamp(bounds.max.z, 1f, World.inst.GridHeight - 1);
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num; j <= num2; j++)
			{
				Ray ray = new Ray(new Vector3((float)j + 0.5f, 100f, (float)i + 0.5f), new Vector3(0f, -1f, 0f));
				if (!child.GetComponent<Collider>().Raycast(ray, out var hitInfo, 100f))
				{
					continue;
				}
				float y = hitInfo.point.y;
				float tileHeight = TerrainGen.inst.GetTileHeight(World.inst.GetCellData(j, i));
				Cell cellData = World.inst.GetCellData(j, i);
				if (tileHeight < y && y > TerrainGen.waterHeightTestThresold && (child.Type != 2 || cellData.landMassIdx != -1))
				{
					TerrainGen.inst.SetTileHeight(World.inst.GetCellData(j, i), y);
					cellData.landMassIdx = lmIdx;
					cellData.Type = TerrainType.None;
					if (child.Type == 1)
					{
						TerrainGen.inst.modifiedTerrain[j + i * World.inst.GridWidth] = true;
					}
				}
			}
		}
	}

	public bool Overlaps(Vector3 c, float r)
	{
		if (BoundingSphereContainer == null)
		{
			return false;
		}
		for (int i = 0; i < BoundingSphereContainer.childCount; i++)
		{
			Transform child = BoundingSphereContainer.GetChild(i);
			if (Mathff.DistSqrd(c, child.position) < (r + child.localScale.x / 2f) * (r + child.localScale.x / 2f))
			{
				return true;
			}
		}
		return false;
	}

	private Cell traceLineToFindWater(Cell a, Cell b)
	{
		int num = a.x;
		int num2 = a.z;
		int x = b.x;
		int z = b.z;
		int num3 = Mathf.Abs(x - num);
		int num4 = ((num < x) ? 1 : (-1));
		int num5 = Mathf.Abs(z - num2);
		int num6 = ((num2 < z) ? 1 : (-1));
		int num7 = num3 - num5;
		if (num3 + num5 != 0)
		{
			Mathf.Sqrt((float)num3 * (float)num3 + (float)num5 * (float)num5);
		}
		while (true)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(num, num2);
			if (cellDataClamped.Type == TerrainType.Water && cellDataClamped.partOfOcean)
			{
				return cellDataClamped;
			}
			int num8 = num7;
			if (2 * num8 >= -num3)
			{
				if (num == x)
				{
					break;
				}
				num7 -= num5;
				num += num4;
			}
			if (2 * num8 <= num5)
			{
				if (num2 == z)
				{
					break;
				}
				num7 += num3;
				num2 += num6;
			}
		}
		return null;
	}

	public bool Init(Vector3 pos, Quaternion rot, int lmIdx)
	{
		transform.position = pos;
		transform.rotation = rot;
		landmass = lmIdx;
		if (groups.Count > 0)
		{
			for (int num = groups.Count - (int)numGroupsOn.Rand(); num > 0; num--)
			{
				int num2 = SRand.Range(0, groups.Count);
				for (int i = 0; i < groups.Count; i++)
				{
					int index = (num2 + i) % groups.Count;
					if (!groups[index].items[0].gameObject.activeInHierarchy)
					{
						continue;
					}
					for (int j = 0; j < groups[index].items.Count; j++)
					{
						if (groups[index].items[j] != null)
						{
							groups[index].items[j].gameObject.SetActive(value: false);
						}
					}
					break;
				}
			}
		}
		for (int k = 0; k < RocksContainer.childCount; k++)
		{
			Transform child = RocksContainer.GetChild(k);
			child.gameObject.layer = LayerMask.NameToLayer("Terrain");
			child.gameObject.AddComponent<WaterDisplacementMesh>();
			MountainPlacerItem component = child.GetComponent<MountainPlacerItem>();
			if (!(component == null) && component.appearanceProbability < 1f && SRand.value < component.appearanceProbability)
			{
				child.gameObject.SetActive(value: false);
			}
		}
		CalculateBounds(ref center, ref radius);
		if (BoundingPointsContainer != null)
		{
			int num3 = 3;
			int num4 = World.inst.GridWidth - 4;
			int num5 = 3;
			int num6 = World.inst.GridHeight - 4;
			for (int l = 0; l < BoundingPointsContainer.childCount; l++)
			{
				Vector3 position = BoundingPointsContainer.GetChild(l).position;
				if (position.x < (float)num3 || position.x > (float)num4 || position.z < (float)num5 || position.z > (float)num6)
				{
					UnityEngine.Object.DestroyImmediate(gameObject);
					return false;
				}
			}
			for (int m = 0; m < TerrainGen.inst.mountainRocks.Count; m++)
			{
				MountainPlacer component2 = TerrainGen.inst.mountainRocks[m].GetComponent<MountainPlacer>();
				if (component2.landmass == landmass || component2.BoundingPointsContainer == null)
				{
					continue;
				}
				Vector2[] array = new Vector2[component2.BoundingPointsContainer.childCount];
				for (int n = 0; n < array.Length; n++)
				{
					Vector3 position2 = component2.BoundingPointsContainer.GetChild(n).position;
					array[n] = new Vector2(position2.x, position2.z);
				}
				for (int num7 = 0; num7 < BoundingPointsContainer.childCount; num7++)
				{
					Vector3 position3 = BoundingPointsContainer.GetChild(num7).position;
					if (Mathff.PointInPolygon(array, new Vector2(position3.x, position3.z)))
					{
						UnityEngine.Object.DestroyImmediate(gameObject);
						return false;
					}
				}
			}
		}
		for (int num8 = 0; num8 < TerrainModifiersContainer.childCount; num8++)
		{
			MountainPlacerTerrainModifier component3 = TerrainModifiersContainer.GetChild(num8).GetComponent<MountainPlacerTerrainModifier>();
			if (!(component3 == null) && component3.gameObject.activeInHierarchy)
			{
				LiftTerrain(component3, lmIdx);
				UnityEngine.Object.Destroy(component3.gameObject);
			}
		}
		for (int num9 = 0; num9 < RocksContainer.childCount; num9++)
		{
			Transform child2 = RocksContainer.GetChild(num9);
			if (!child2.gameObject.activeInHierarchy)
			{
				continue;
			}
			MountainPlacerItem component4 = child2.GetComponent<MountainPlacerItem>();
			if (component4 == null)
			{
				continue;
			}
			MeshRenderer component5 = child2.GetComponent<MeshRenderer>();
			if (component4.placementType == MountainPlacerItem.PlacementType.Drop)
			{
				float num10 = float.MaxValue;
				Bounds localBounds = component5.localBounds;
				Vector3[] array2 = new Vector3[8]
				{
					localBounds.center + new Vector3(0f - localBounds.size.x, 0f - localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
					localBounds.center + new Vector3(localBounds.size.x, 0f - localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
					localBounds.center + new Vector3(localBounds.size.x, 0f - localBounds.size.y, localBounds.size.z) * 0.5f,
					localBounds.center + new Vector3(0f - localBounds.size.x, 0f - localBounds.size.y, localBounds.size.z) * 0.5f,
					localBounds.center + new Vector3(0f - localBounds.size.x, localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
					localBounds.center + new Vector3(localBounds.size.x, localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
					localBounds.center + new Vector3(localBounds.size.x, localBounds.size.y, localBounds.size.z) * 0.5f,
					localBounds.center + new Vector3(0f - localBounds.size.x, localBounds.size.y, localBounds.size.z) * 0.5f
				};
				for (int num11 = 0; num11 < array2.Length; num11++)
				{
					array2[num11] = child2.transform.TransformPoint(array2[num11] * 0.8f);
					float groundHeight = TerrainGen.inst.GetGroundHeight(array2[num11].x, array2[num11].z);
					if (groundHeight < num10)
					{
						num10 = groundHeight;
					}
				}
				Vector3 position4 = child2.transform.position;
				position4.y = num10;
				child2.position = position4;
				float num12 = SRand.Range(0.9f, 1.1f);
				float num13 = SRand.Range(0.9f, 1.1f);
				float num14 = SRand.Range(0.9f, 1.1f);
				Vector3 localScale = child2.localScale;
				child2.localScale = new Vector3(localScale.x * num12, localScale.y * num13, localScale.z * num14);
			}
			if (component4.rotate180X && SRand.Range(0, 100) > 50)
			{
				component4.transform.Rotate(new Vector3(180f, 0f, 0f), Space.Self);
			}
			if (component4.rotate180Y && SRand.Range(0, 100) > 50)
			{
				component4.transform.Rotate(new Vector3(0f, 180f, 0f), Space.Self);
			}
			if (component4.rotate180Z && SRand.Range(0, 100) > 50)
			{
				component4.transform.Rotate(new Vector3(0f, 0f, 180f), Space.Self);
			}
			Vector3 localScale2 = child2.localScale;
			float num15 = component4.scaleMod.Rand();
			child2.localScale = new Vector3(localScale2.x * num15, localScale2.y * num15, localScale2.z * num15);
		}
		for (int num16 = 0; num16 < subMountains.Count; num16++)
		{
			SubMountain subMountain = subMountains[num16];
			if (subMountain.prefabs.Length != 0)
			{
				MountainPlacer mountainPlacer = UnityEngine.Object.Instantiate(subMountain.prefabs[SRand.Range(0, subMountain.prefabs.Length)], TerrainGen.inst.mountainContainer, worldPositionStays: false);
				if (mountainPlacer.Init(subMountain.target.position, subMountain.target.rotation, lmIdx))
				{
					TerrainGen.inst.mountainRocks.Add(mountainPlacer.gameObject);
				}
			}
		}
		for (int num17 = 0; num17 < transform.childCount; num17++)
		{
			MountainPlacerWater component6 = transform.GetChild(num17).GetComponent<MountainPlacerWater>();
			if (component6 != null)
			{
				component6.AddWaterPositions(lmIdx);
			}
		}
		if (ResourceGroupsContainer != null)
		{
			mResourceGroups = new List<MountainPlacerResource>(ResourceGroupsContainer.childCount);
			for (int num18 = 0; num18 < ResourceGroupsContainer.childCount; num18++)
			{
				MountainPlacerResource component7 = ResourceGroupsContainer.GetChild(num18).GetComponent<MountainPlacerResource>();
				if (component7 != null && component7.gameObject.activeInHierarchy)
				{
					mResourceGroups.Add(component7);
				}
			}
		}
		return true;
	}

	public bool ShiftToShore(Vector3 dir, ref Vector3 mPos)
	{
		Vector3 forward = dir;
		if (EdgeDetector != null)
		{
			transform.position = mPos;
			transform.rotation = Quaternion.LookRotation(forward);
			Cell cellData = World.inst.GetCellData(EdgeDetector.position);
			if (cellData == null)
			{
				return false;
			}
			if (cellData.Type != TerrainType.Water)
			{
				if (!doShiftForward)
				{
					return true;
				}
				Vector3 vector = -forward.normalized;
				for (int i = 1; i < 10; i++)
				{
					Vector3 vector2 = EdgeDetector.position + vector * i;
					int num = (int)vector2.x;
					int num2 = (int)vector2.z;
					if (num < 1 || num > World.inst.GridWidth - 1 || num2 < 1 || num2 > World.inst.GridHeight - 1)
					{
						break;
					}
					cellData = World.inst.GetCellData(num, num2);
					if (cellData.Type == TerrainType.Water)
					{
						mPos += vector * i;
						return true;
					}
				}
			}
			else
			{
				if (!doShiftBackward)
				{
					return true;
				}
				Vector3 normalized = forward.normalized;
				for (int j = 1; j < 10; j++)
				{
					Vector3 vector3 = EdgeDetector.position + normalized * j;
					int num3 = (int)vector3.x;
					int num4 = (int)vector3.z;
					if (num3 < 1 || num3 > World.inst.GridWidth - 1 || num4 < 1 || num4 > World.inst.GridHeight - 1)
					{
						break;
					}
					cellData = World.inst.GetCellData(num3, num4);
					if (cellData.Type != TerrainType.Water)
					{
						mPos += normalized * (j - 1);
						return true;
					}
				}
			}
			return false;
		}
		return true;
	}

	public void SubtractTerrain()
	{
		if (!doSubtraction)
		{
			return;
		}
		int gridWidth = World.inst.GridWidth;
		if (!(SubtractiveSphereContainer != null))
		{
			return;
		}
		for (int i = 0; i < SubtractiveSphereContainer.childCount; i++)
		{
			Transform child = SubtractiveSphereContainer.GetChild(i);
			float num = child.localScale.x / 2f;
			Vector3 position = child.position;
			position.y = 0f;
			int num2 = (int)Mathff.Clamp(position.x - num, 1f, World.inst.GridWidth - 1);
			int num3 = (int)Mathff.Clamp(position.x + num, 1f, World.inst.GridWidth - 1);
			int num4 = (int)Mathff.Clamp(position.z - num, 1f, World.inst.GridHeight - 1);
			int num5 = (int)Mathff.Clamp(position.z + num, 1f, World.inst.GridHeight - 1);
			for (int j = num2; j < num3; j++)
			{
				for (int k = num4; k < num5; k++)
				{
					Cell cellData = World.inst.GetCellData(j, k);
					if (cellData.landMassIdx != -1 && !TerrainGen.inst.modifiedTerrain[j + k * gridWidth] && Mathff.Dist(cellData.Center2D, position) <= num)
					{
						TerrainGen.inst.SetWaterTile(j, k, modifyHeight: false);
						TerrainGen.inst.SetTileHeight(cellData, -4f);
					}
				}
			}
		}
	}

	public void CalculateBounds(ref Vector3 center, ref float radius, bool includeTerrainModifiers = false)
	{
		int num = 0;
		float num2 = 0f;
		List<Vector3> list = new List<Vector3>();
		float num3 = float.MaxValue;
		for (int i = 0; i < RocksContainer.childCount; i++)
		{
			Transform child = RocksContainer.GetChild(i);
			if (!child.gameObject.activeInHierarchy)
			{
				continue;
			}
			MountainPlacerItem component = child.GetComponent<MountainPlacerItem>();
			if (component == null || component.placementType == MountainPlacerItem.PlacementType.Drop)
			{
				continue;
			}
			Bounds localBounds = child.GetComponent<MeshRenderer>().localBounds;
			Vector3[] array = new Vector3[8]
			{
				localBounds.center + new Vector3(0f - localBounds.size.x, 0f - localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
				localBounds.center + new Vector3(localBounds.size.x, 0f - localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
				localBounds.center + new Vector3(localBounds.size.x, 0f - localBounds.size.y, localBounds.size.z) * 0.5f,
				localBounds.center + new Vector3(0f - localBounds.size.x, 0f - localBounds.size.y, localBounds.size.z) * 0.5f,
				localBounds.center + new Vector3(0f - localBounds.size.x, localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
				localBounds.center + new Vector3(localBounds.size.x, localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
				localBounds.center + new Vector3(localBounds.size.x, localBounds.size.y, localBounds.size.z) * 0.5f,
				localBounds.center + new Vector3(0f - localBounds.size.x, localBounds.size.y, localBounds.size.z) * 0.5f
			};
			for (int j = 0; j < array.Length; j++)
			{
				array[j] = child.transform.TransformPoint(array[j] * 0.8f);
				float groundHeight = TerrainGen.inst.GetGroundHeight(array[j].x, array[j].z);
				if (groundHeight < num3)
				{
					num3 = groundHeight;
				}
				num2 += groundHeight;
				list.Add(array[j]);
				center += array[j];
				num++;
			}
		}
		if (includeTerrainModifiers)
		{
			for (int k = 0; k < TerrainModifiersContainer.childCount; k++)
			{
				Transform child2 = TerrainModifiersContainer.GetChild(k);
				if (!child2.gameObject.activeInHierarchy)
				{
					continue;
				}
				Bounds localBounds2 = child2.GetComponent<MeshRenderer>().localBounds;
				Vector3[] array2 = new Vector3[8]
				{
					localBounds2.center + new Vector3(0f - localBounds2.size.x, 0f - localBounds2.size.y, 0f - localBounds2.size.z) * 0.5f,
					localBounds2.center + new Vector3(localBounds2.size.x, 0f - localBounds2.size.y, 0f - localBounds2.size.z) * 0.5f,
					localBounds2.center + new Vector3(localBounds2.size.x, 0f - localBounds2.size.y, localBounds2.size.z) * 0.5f,
					localBounds2.center + new Vector3(0f - localBounds2.size.x, 0f - localBounds2.size.y, localBounds2.size.z) * 0.5f,
					localBounds2.center + new Vector3(0f - localBounds2.size.x, localBounds2.size.y, 0f - localBounds2.size.z) * 0.5f,
					localBounds2.center + new Vector3(localBounds2.size.x, localBounds2.size.y, 0f - localBounds2.size.z) * 0.5f,
					localBounds2.center + new Vector3(localBounds2.size.x, localBounds2.size.y, localBounds2.size.z) * 0.5f,
					localBounds2.center + new Vector3(0f - localBounds2.size.x, localBounds2.size.y, localBounds2.size.z) * 0.5f
				};
				for (int l = 0; l < array2.Length; l++)
				{
					array2[l] = child2.transform.TransformPoint(array2[l] * 0.8f);
					float groundHeight2 = TerrainGen.inst.GetGroundHeight(array2[l].x, array2[l].z);
					if (groundHeight2 < num3)
					{
						num3 = groundHeight2;
					}
					num2 += groundHeight2;
					list.Add(array2[l]);
					center += array2[l];
					num++;
				}
			}
		}
		if (num <= 0)
		{
			return;
		}
		center /= (float)num;
		for (int m = 0; m < list.Count; m++)
		{
			float num4 = Mathff.Dist(center, list[m]);
			if (num4 > radius)
			{
				radius = num4;
			}
		}
	}

	public bool Init(Vector3 pos, int lmIdx)
	{
		pos.y = 0f;
		Quaternion rot = Quaternion.AngleAxis((float)SRand.Range(0, 4) * 90f / 4f, new Vector3(0f, 1f, 0f));
		Cell cell = null;
		float num = float.MaxValue;
		Cell cellDataClamped = World.inst.GetCellDataClamped(pos);
		for (int i = 0; i < directions.Length; i++)
		{
			Cell cellDataClamped2 = World.inst.GetCellDataClamped(pos + directions[i] * 100f);
			Cell cell2 = traceLineToFindWater(cellDataClamped, cellDataClamped2);
			if (cell2 != null)
			{
				float num2 = Mathff.DistSqrd(cellDataClamped.Position, cell2.Position);
				if (num2 < num)
				{
					num = num2;
					cell = cell2;
				}
			}
		}
		if (cell != null)
		{
			rot = Quaternion.LookRotation((cell.Center2D - cellDataClamped.Center2D).normalized);
		}
		return Init(pos, rot, lmIdx);
	}

	public void ProcessMountainCells()
	{
		Ray ray = new Ray
		{
			direction = Vector3.down
		};
		Vector3 vector = new Vector3(0f, 100f, 0f);
		for (int i = 0; i < RocksContainer.childCount; i++)
		{
			Transform child = RocksContainer.GetChild(i);
			if (!child.gameObject.activeInHierarchy)
			{
				continue;
			}
			Collider component = child.GetComponent<Collider>();
			Bounds bounds = child.GetComponent<MeshRenderer>().bounds;
			int num = Mathff.Clamp((int)bounds.min.x, 1, World.inst.GridWidth - 2);
			int num2 = Mathff.Clamp((int)bounds.max.x, 1, World.inst.GridWidth - 2);
			int num3 = Mathff.Clamp((int)bounds.min.z, 1, World.inst.GridHeight - 2);
			int num4 = Mathff.Clamp((int)bounds.max.z, 1, World.inst.GridHeight - 2);
			for (int j = num3; j <= num4; j++)
			{
				for (int k = num; k <= num2; k++)
				{
					bool flag = false;
					Cell cellData = World.inst.GetCellData(k, j);
					for (int l = 0; l < 3; l++)
					{
						for (int m = 0; m < 3; m++)
						{
							vector.x = 0.2f + (float)k + (float)l * 0.3f;
							vector.z = 0.2f + (float)j + (float)m * 0.3f;
							ray.origin = vector;
							if (component.Raycast(ray, out var hitInfo, 100f))
							{
								float interpolatedHeight = TerrainGen.inst.GetInterpolatedHeight(vector);
								float y = hitInfo.point.y;
								if (y > interpolatedHeight && y - interpolatedHeight > MESH_TO_TERRAIN_THRESHOLD)
								{
									cellData.Type = TerrainType.Obstruction;
									cellData.landMassIdx = landmass;
									flag = true;
								}
							}
							if (flag)
							{
								break;
							}
						}
						if (flag)
						{
							break;
						}
					}
				}
			}
		}
	}

	public static void PlaceResources(List<GameObject> mountains, int centerStart)
	{
		int[] resourcePriorityOrder = MountainPlacerResource.ResourcePriorityOrder;
		Dictionary<int, List<MountainPlacerResource>> dictionary = new Dictionary<int, List<MountainPlacerResource>>();
		Dictionary<int, List<Vector3>[]> dictionary2 = new Dictionary<int, List<Vector3>[]>();
		for (int i = 0; i < mountains.Count; i++)
		{
			MountainPlacer component = mountains[i].GetComponent<MountainPlacer>();
			if (!dictionary.TryGetValue(component.landmass, out var value))
			{
				value = (dictionary[component.landmass] = new List<MountainPlacerResource>());
				List<Vector3>[] array = (dictionary2[component.landmass] = new List<Vector3>[resourcePriorityOrder.Length]);
				List<Vector3>[] array3 = array;
				for (int j = 0; j < resourcePriorityOrder.Length; j++)
				{
					array3[j] = new List<Vector3>();
				}
			}
			if (component.mResourceGroups != null && component.mResourceGroups.Count != 0)
			{
				value.AddRange(component.mResourceGroups);
			}
		}
		for (int k = centerStart; k < mountains.Count; k++)
		{
			MountainPlacer component2 = mountains[k].GetComponent<MountainPlacer>();
			List<MountainPlacerResource> allGroups = dictionary[component2.landmass];
			List<Vector3>[] array4 = dictionary2[component2.landmass];
			if (component2.mResourceGroups == null || component2.mResourceGroups.Count == 0)
			{
				continue;
			}
			scratchResources.Clear();
			scratchResources.AddRange(component2.mResourceGroups);
			for (int l = 0; l < resourcePriorityOrder.Length; l++)
			{
				if (array4[l].Count < Mathf.Min(1, MountainPlacerResource.GetDesired(resourcePriorityOrder[l])) && !TryPlaceResourceRandom(scratchResources, allGroups, resourcePriorityOrder[l], array4[l], ignoreVariantAny: true) && scratchResources.Count > 0)
				{
					TryPlaceResourceRandom(scratchResources, allGroups, resourcePriorityOrder[l], array4[l]);
				}
			}
		}
		int num = Mathf.Max(MountainPlacerResource.DesiredStone, MountainPlacerResource.DesiredMarble, MountainPlacerResource.DesiredIron);
		foreach (KeyValuePair<int, List<MountainPlacerResource>> item in dictionary)
		{
			List<Vector3>[] array5 = dictionary2[item.Key];
			for (int m = 0; m < num; m++)
			{
				for (int n = 0; n < resourcePriorityOrder.Length; n++)
				{
					if (array5[n].Count < MountainPlacerResource.GetDesired(resourcePriorityOrder[n]))
					{
						TryPlaceResourceRandom(item.Value, item.Value, resourcePriorityOrder[n], array5[n]);
					}
				}
			}
		}
	}

	private static bool TryPlaceResourceRandom(List<MountainPlacerResource> candidates, List<MountainPlacerResource> allGroups, int rID, List<Vector3> sameTypePos, bool ignoreVariantAny = false)
	{
		while (candidates.Count > 0)
		{
			scratchFits.Clear();
			for (int i = 0; i < candidates.Count; i++)
			{
				MountainPlacerResource mountainPlacerResource = candidates[i];
				if (HasVariant(mountainPlacerResource, rID, out var rVariant) || (!ignoreVariantAny && HasVariant(mountainPlacerResource, -1, out rVariant)))
				{
					scratchFits.Add((mountainPlacerResource, rVariant));
				}
			}
			if (scratchFits.Count == 0)
			{
				return false;
			}
			var (item, rVariant2) = scratchFits[SRand.Range(0, scratchFits.Count)];
			candidates.Remove(item);
			allGroups.Remove(item);
			if (MountainPlacerResource.TryPlaceResource(rVariant2, rID))
			{
				sameTypePos.Add(rVariant2.resourcePos[0].position);
				return true;
			}
		}
		return false;
	}

	private static bool HasVariant(MountainPlacerResource mpr, int resourceID, out MountainPlacerResource.ResourceVariant rVariant)
	{
		if (mpr.resourcVariantDict.TryGetValue(resourceID, out rVariant))
		{
			return rVariant.resourcePos.Length != 0;
		}
		return false;
	}
}
