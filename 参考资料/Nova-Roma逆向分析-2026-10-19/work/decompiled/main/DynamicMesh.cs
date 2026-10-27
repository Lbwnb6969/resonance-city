using System;
using System.Collections.Generic;
using UnityEngine;

public class DynamicMesh : MonoBehaviour
{
	public delegate bool ValidBuilding(Building b);

	public int type;

	public BoxCollider bCollider;

	public bool doBespokeHighlight = true;

	[NonSerialized]
	public DynamicMeshObject dMeshObject;

	[NonSerialized]
	public Building b;

	public RectangleFinder.ValidCell validCell;

	public ValidBuilding validBuilding;

	public static bool[] isValid;

	public static bool[] hasVisited;

	public static ArrayExt<Cell> openset = new ArrayExt<Cell>(32);

	public static Dictionary<int, DynamicMeshGroup> mGroupData = null;

	public static Dictionary<int, DynamicMeshSize> mSizeData = null;

	public static int BathLibrary = 0;

	public static int BathPalaestra = 1;

	public static int BathHotPool = 2;

	public static int _1x1 = 0;

	public static int _1x2 = 1;

	public static int _1x3 = 2;

	public static int _2x2 = 3;

	public static int _2x3 = 4;

	public static int objPoolCount = 0;

	public static ArrayExt<DynamicMeshObject> objPool = new ArrayExt<DynamicMeshObject>(64);

	private static GameObject objContainer;

	private static ArrayExt<RectangleFinder.RectangleCoordinates> tempRects = new ArrayExt<RectangleFinder.RectangleCoordinates>(32);

	public GameObject placeHolderMesh;

	private int prevSessionID = -1;

	private static List<DynamicMesh> tempDynamicMeshes = new List<DynamicMesh>(32);

	public static void Reset()
	{
		if (objContainer == null)
		{
			objContainer = new GameObject("Dynamic Mesh Objects");
		}
		for (int num = objPool.Count - 1; num >= 0; num--)
		{
			objPool.data[num].Shutdown();
		}
		int num2 = World.inst.GridWidth * World.inst.GridHeight;
		if (hasVisited == null || hasVisited.Length != num2)
		{
			hasVisited = new bool[num2];
		}
		if (isValid == null || isValid.Length != num2)
		{
			isValid = new bool[num2];
		}
		if (mSizeData == null)
		{
			mSizeData = new Dictionary<int, DynamicMeshSize>(DynamicMeshEntry.SizeOptions.Count)
			{
				{
					_1x1,
					new DynamicMeshSize
					{
						sizeX = 1,
						sizeZ = 1,
						area = 1,
						id = _1x1
					}
				},
				{
					_1x2,
					new DynamicMeshSize
					{
						sizeX = 1,
						sizeZ = 2,
						area = 2,
						id = _1x2
					}
				},
				{
					_1x3,
					new DynamicMeshSize
					{
						sizeX = 1,
						sizeZ = 3,
						area = 3,
						id = _1x3
					}
				},
				{
					_2x2,
					new DynamicMeshSize
					{
						sizeX = 2,
						sizeZ = 2,
						area = 4,
						id = _2x2
					}
				},
				{
					_2x3,
					new DynamicMeshSize
					{
						sizeX = 2,
						sizeZ = 3,
						area = 6,
						id = _2x3
					}
				}
			};
		}
		if (mGroupData != null)
		{
			return;
		}
		DynamicMeshGroup[] array = Resources.LoadAll<DynamicMeshGroup>("DynamicMesh");
		mGroupData = new Dictionary<int, DynamicMeshGroup>(array.Length);
		for (int i = 0; i < array.Length; i++)
		{
			if (mGroupData.ContainsKey(array[i].type))
			{
				Debug.Log($"Duplicate Dynamic Mesh Group {array[i].type}");
				continue;
			}
			DynamicMeshGroup dynamicMeshGroup = UnityEngine.Object.Instantiate(array[i]);
			dynamicMeshGroup.Init();
			mGroupData.Add(array[i].type, dynamicMeshGroup);
		}
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		validCell = DefaultCellCheck;
		validBuilding = DefaultBuildingCheck;
	}

	private bool DefaultCellCheck(int x, int z)
	{
		Cell cellData = World.inst.GetCellData(x, z);
		if (cellData == null)
		{
			return false;
		}
		return cellData.StructureFind(b.uniqueNameHash);
	}

	private bool DefaultBuildingCheck(Building targetB)
	{
		if (targetB != null && targetB.IsBuilt())
		{
			return b.uniqueNameHash == targetB.uniqueNameHash;
		}
		return false;
	}

	public void OnRemoved()
	{
		if (!b.IsBuilt())
		{
			return;
		}
		Util.Memset(hasVisited, 0);
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		if (dMeshObject != (object)null)
		{
			dMeshObject.Shutdown();
		}
		dMeshObject = null;
		int num = Mathff.Clamp(minX - 1, 0, World.inst.GridWidth - 1);
		int num2 = Mathff.Clamp(minZ - 1, 0, World.inst.GridHeight - 1);
		int num3 = Mathff.Clamp(maxX + 1, 0, World.inst.GridWidth - 1);
		int num4 = Mathff.Clamp(maxZ + 1, 0, World.inst.GridHeight - 1);
		for (int i = num; i <= num3; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				if (i == minX - 1 || i == maxX + 1 || j == minZ - 1 || j == maxZ + 1)
				{
					Cell cellData = World.inst.GetCellData(i, j);
					if (cellData != null)
					{
						openset.ClearFast();
						Util.Memset(isValid, 0);
						FloodFill(cellData);
					}
				}
			}
		}
	}

	public void OnAdded()
	{
		openset.ClearFast();
		Util.Memset(hasVisited, 0);
		Util.Memset(isValid, 0);
		Cell cell = b.GetCell();
		FloodFill(cell);
	}

	public void FloodFill(Cell tempC)
	{
		if ((bool)placeHolderMesh)
		{
			placeHolderMesh.SetActive(value: false);
		}
		openset.Add(tempC);
		int num = int.MaxValue;
		int num2 = int.MinValue;
		int num3 = int.MaxValue;
		int num4 = int.MinValue;
		tempRects.ClearFast();
		int area = GetLargestSupportedArea(type).area;
		int num5 = 0;
		while (openset.Count > 0)
		{
			Cell cell = openset.PopLast();
			if (cell == null)
			{
				continue;
			}
			int index = cell.index;
			if (hasVisited[index])
			{
				continue;
			}
			hasVisited[index] = true;
			bool flag = false;
			for (int i = 0; i < cell.OccupyingStructure.Count; i++)
			{
				Building building = cell.OccupyingStructure[i];
				if (!validBuilding(building))
				{
					continue;
				}
				flag = (isValid[index] = true);
				DynamicMesh component = building.GetComponent<DynamicMesh>();
				if (component == null || component.dMeshObject == (object)null || component.dMeshObject.rCoords == null)
				{
					break;
				}
				if (component.dMeshObject.rCoords.area >= area)
				{
					isValid[index] = false;
					break;
				}
				DynamicMeshObject dynamicMeshObject = component.dMeshObject;
				int num6 = 0;
				while (true)
				{
					if (num6 < tempRects.Count)
					{
						if (tempRects.data[i].IsSame(dynamicMeshObject.rCoords))
						{
							break;
						}
						num6++;
						continue;
					}
					int j;
					for (j = 0; j < tempRects.Count; j++)
					{
						if (tempRects.data[i].area < dynamicMeshObject.rCoords.area)
						{
							break;
						}
					}
					tempRects.Insert(j, dynamicMeshObject.rCoords);
					break;
				}
				break;
			}
			if (flag)
			{
				if (num > cell.x)
				{
					num = cell.x;
				}
				if (num2 < cell.x)
				{
					num2 = cell.x;
				}
				if (num3 > cell.z)
				{
					num3 = cell.z;
				}
				if (num4 < cell.z)
				{
					num4 = cell.z;
				}
				num5++;
				TryAddAdjacentCells(openset, cell);
			}
		}
		if (num5 == 0)
		{
			return;
		}
		DynamicMeshGroup dynamicMeshGroup = mGroupData[type];
		List<RectangleFinder.RectangleCoordinates> list = RectangleFinder.FindLargestRectangles(num, num2, num3, num4, dynamicMeshGroup.sizes, isValid);
		bool flag2 = false;
		for (int k = 0; k < tempRects.Count; k++)
		{
			RectangleFinder.RectangleCoordinates rectangleCoordinates = tempRects.data[k];
			RectangleFinder.RectangleCoordinates rectangleCoordinates2 = null;
			for (int l = 0; l < list.Count; l++)
			{
				if (rectangleCoordinates.IsIntersecting(list[l]))
				{
					if (rectangleCoordinates.IsSameSize(list[l]))
					{
						rectangleCoordinates2 = list[l];
					}
					if (list[l].area > rectangleCoordinates.area)
					{
						rectangleCoordinates2 = null;
						break;
					}
				}
			}
			if (rectangleCoordinates2 == null)
			{
				continue;
			}
			flag2 = true;
			for (int m = rectangleCoordinates.lowerX; m < rectangleCoordinates.upperX; m++)
			{
				for (int n = rectangleCoordinates.lowerZ; n < rectangleCoordinates.upperZ; n++)
				{
					isValid[m + n * World.inst.GridWidth] = false;
				}
			}
			for (int num7 = list.Count - 1; num7 >= 0; num7--)
			{
				if (rectangleCoordinates.IsIntersecting(list[num7]))
				{
					list.RemoveAt(num7);
				}
			}
		}
		if (flag2)
		{
			list = RectangleFinder.FindLargestRectangles(num, num2, num3, num4, dynamicMeshGroup.sizes, isValid);
		}
		for (int num8 = 0; num8 < list.Count; num8++)
		{
			RectangleFinder.RectangleCoordinates rectangleCoordinates3 = list[num8];
			if (rectangleCoordinates3 == null)
			{
				continue;
			}
			int id = _1x1;
			bool isRotated = false;
			for (int num9 = 0; num9 < dynamicMeshGroup.sizes.Length; num9++)
			{
				DynamicMeshSize dynamicMeshSize = dynamicMeshGroup.sizes[num9];
				if (dynamicMeshSize.IsSameSize(rectangleCoordinates3.sizeX, rectangleCoordinates3.sizeZ, out isRotated))
				{
					id = dynamicMeshSize.id;
					break;
				}
			}
			if (!TryReleaseDynamicMeshObjects(rectangleCoordinates3))
			{
				continue;
			}
			DynamicMeshObject meshObject = GetMeshObject();
			meshObject.rCoords = rectangleCoordinates3;
			List<DynamicMeshEntry> list2 = dynamicMeshGroup.entryGroups[id];
			DynamicMeshEntry dynamicMeshEntry = list2[SRand.Range(0, list2.Count)];
			meshObject.SetMesh(dynamicMeshEntry.mesh);
			Vector3 vector = default;
			vector.x = (float)(rectangleCoordinates3.lowerX + rectangleCoordinates3.upperX) * 0.5f;
			vector.z = (float)(rectangleCoordinates3.lowerZ + rectangleCoordinates3.upperZ) * 0.5f;
			vector.y = TerrainGen.inst.GetInterpolatedHeight(vector);
			meshObject.transform.position = vector;
			if (isRotated)
			{
				meshObject.transform.Rotate(new Vector3(0f, 90f, 0f), Space.Self);
			}
			for (int num10 = rectangleCoordinates3.lowerX; num10 < rectangleCoordinates3.upperX; num10++)
			{
				for (int num11 = rectangleCoordinates3.lowerZ; num11 < rectangleCoordinates3.upperZ; num11++)
				{
					Cell cellData = World.inst.GetCellData(num10, num11);
					if (cellData == null)
					{
						continue;
					}
					for (int num12 = 0; num12 < cellData.OccupyingStructure.Count; num12++)
					{
						DynamicMesh component2 = cellData.OccupyingStructure[num12].GetComponent<DynamicMesh>();
						if (component2 != null && component2.type == type)
						{
							component2.dMeshObject = meshObject;
							meshObject.targetMeshes.Add(component2);
						}
					}
				}
			}
			meshObject.CalculateColliders();
			if (IntegrityUI.inst.overlayOn)
			{
				meshObject.TrySetIntegrityVisuals();
			}
		}
	}

	private DynamicMeshObject GetMeshObject()
	{
		DynamicMeshObject dynamicMeshObject;
		if (objPoolCount == objPool.Count)
		{
			GameObject gameObject = new GameObject($"DynamicMeshObj ({objPoolCount})");
			gameObject.transform.parent = objContainer.transform;
			dynamicMeshObject = gameObject.AddComponent<DynamicMeshObject>();
			dynamicMeshObject.mFilter = gameObject.AddComponent<MeshFilter>();
			dynamicMeshObject.mRenderer = gameObject.AddComponent<MeshRenderer>();
			dynamicMeshObject.mRenderer.sharedMaterial = World.inst.romeUnimaterial;
			objPool.Add(dynamicMeshObject);
			dynamicMeshObject.idxIntoPool = objPool.Count - 1;
			objPoolCount++;
		}
		else
		{
			dynamicMeshObject = objPool.GetNew();
			dynamicMeshObject.idxIntoPool = objPool.Count - 1;
		}
		dynamicMeshObject.Init();
		return dynamicMeshObject;
	}

	private void TryAddAdjacentCells(ArrayExt<Cell> openset, Cell c)
	{
		int gridWidth = World.inst.GridWidth;
		int num = gridWidth * World.inst.GridHeight;
		int num2 = c.x + 1 + gridWidth * c.z;
		if (num2 >= 0 && num2 < num)
		{
			openset.Add(World.inst.GetCellDataUnsafe(num2));
		}
		num2 = c.x - 1 + gridWidth * c.z;
		if (num2 >= 0 && num2 < num)
		{
			openset.Add(World.inst.GetCellDataUnsafe(num2));
		}
		num2 = c.x + gridWidth * (c.z - 1);
		if (num2 >= 0 && num2 < num)
		{
			openset.Add(World.inst.GetCellDataUnsafe(num2));
		}
		num2 = c.x + gridWidth * (c.z + 1);
		if (num2 >= 0 && num2 < num)
		{
			openset.Add(World.inst.GetCellDataUnsafe(num2));
		}
	}

	private bool TryReleaseDynamicMeshObjects(RectangleFinder.RectangleCoordinates currCoords)
	{
		tempDynamicMeshes.Clear();
		bool flag = false;
		for (int i = currCoords.lowerX; i < currCoords.upperX; i++)
		{
			for (int j = currCoords.lowerZ; j < currCoords.upperZ; j++)
			{
				Cell cellData = World.inst.GetCellData(i, j);
				if (cellData == null)
				{
					continue;
				}
				for (int k = 0; k < cellData.OccupyingStructure.Count; k++)
				{
					DynamicMesh component = cellData.OccupyingStructure[k].GetComponent<DynamicMesh>();
					if (component != null && component.type == type)
					{
						tempDynamicMeshes.Add(component);
						if ((!flag && component.dMeshObject == (object)null) || (component.dMeshObject != (object)null && !component.dMeshObject.IsRectangleIdentical(currCoords)))
						{
							flag = true;
						}
					}
				}
			}
		}
		if (flag)
		{
			for (int l = 0; l < tempDynamicMeshes.Count; l++)
			{
				DynamicMesh dynamicMesh = tempDynamicMeshes[l];
				if (dynamicMesh.dMeshObject != (object)null)
				{
					dynamicMesh.dMeshObject.Shutdown();
				}
				dynamicMesh.dMeshObject = null;
			}
		}
		return flag;
	}

	public DynamicMeshSize GetLargestSupportedArea(int type)
	{
		int num = 0;
		DynamicMeshSize result = null;
		foreach (KeyValuePair<int, List<DynamicMeshEntry>> entryGroup in mGroupData[type].entryGroups)
		{
			DynamicMeshSize dynamicMeshSize = mSizeData[entryGroup.Key];
			if (dynamicMeshSize.area >= num)
			{
				result = dynamicMeshSize;
				num = dynamicMeshSize.area;
			}
		}
		return result;
	}
}
