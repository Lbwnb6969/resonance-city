using System.Collections.Generic;
using UnityEngine;

public class AdjacentMesh : MonoBehaviour
{
	public delegate bool ShouldConnect(Cell c);

	public delegate bool ShouldRefresh(Building b, Cell c);

	public delegate void OnRotationUpdate(AdjacentType adjType);

	public enum AdjacentType
	{
		StraightSingle,
		StraightDeadEnd,
		StraightStraight,
		StraightCorner,
		StraightThreeWay,
		StraightFourWay,
		DiagonalBendLeft,
		DiagonalBendRight,
		DiagonalDeadEnd,
		DiagonalStraight,
		DiagonalOneStraightTwo,
		DiagonalTwoStraightOne,
		DiagonalCorner,
		DiagonalThreeWay,
		DiagonalFourWay,
		Full,
		FullThreeWayLeft,
		FullThreeWayRight,
		FullThreeCorner,
		FullThreeFilled,
		FullFourOne,
		FullFourTwo,
		FullFourThree,
		FullFourDiagonal,
		Default,
		NumOfMeshes
	}

	public ShouldConnect shouldConnect;

	public ShouldRefresh shouldRefresh;

	public OnRotationUpdate onRotationUpdate;

	private Building b;

	private Transform offset;

	public MeshFilter meshFilter;

	private bool doRandom180;

	public bool doDefaultOnly;

	public bool doDiagonals;

	public bool doFull;

	public bool fillMissingWithFull;

	private bool isObject;

	public Object[] adjMeshes = new Object[25];

	private Object currMesh;

	public AdjacentType currAdjType;

	private List<AdjacentMesh> adjacentMeshScratch = new List<AdjacentMesh>();

	public float rotOffset;

	private bool debug;

	private void Awake()
	{
		if (shouldConnect == null)
		{
			shouldConnect = DefaultShouldConnect;
		}
		if (shouldRefresh == null)
		{
			shouldRefresh = DefaultShouldRefresh;
		}
		doRandom180 = SRand.Range(0, 100) > 50;
		b = GetComponent<Building>();
		offset = transform.GetChild(0);
	}

	private void OnInit()
	{
		TrySetMesh(AdjacentType.Default);
	}

	private void OnBuild()
	{
		RefreshSurroundingRotation(b);
	}

	private void OnAdjacentAddRemovedBuilding(bool undo)
	{
		RefreshSurroundingRotation(b);
	}

	public void RefreshSurroundingRotation(Building b)
	{
		Cell cell = b.GetCell();
		if (cell == null)
		{
			return;
		}
		World.inst.ToGridCoord(cell.Center2D, out var x, out var z);
		int num = Mathf.Max(x - 1, 0);
		int num2 = Mathf.Max(z - 1, 0);
		int num3 = Mathf.Min(x + 1, World.inst.GridWidth - 1);
		int num4 = Mathf.Min(z + 1, World.inst.GridHeight - 1);
		for (int i = num; i <= num3; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				Cell cellData = World.inst.GetCellData(i, j);
				if (shouldRefresh == null || !shouldRefresh(b, cellData))
				{
					continue;
				}
				for (int k = 0; k < cellData.OccupyingStructure.Count; k++)
				{
					cellData.OccupyingStructure[k].GetComponents(adjacentMeshScratch);
					for (int l = 0; l < adjacentMeshScratch.Count; l++)
					{
						adjacentMeshScratch[l].UpdateRotation();
					}
				}
			}
		}
	}

	public static void RefreshSurroundingRoads(Building b)
	{
		Cell cell = b.GetCell();
		if (cell == null)
		{
			return;
		}
		World.inst.ToGridCoord(cell.Center2D, out var x, out var z);
		int num = Mathf.Max(x - 1, 0);
		int num2 = Mathf.Max(z - 1, 0);
		int num3 = Mathf.Min(x + 1, World.inst.GridWidth - 1);
		int num4 = Mathf.Min(z + 1, World.inst.GridHeight - 1);
		for (int i = num; i <= num3; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				Cell cellData = World.inst.GetCellData(i, j);
				if (!Road.ShouldRefresh(b, cellData))
				{
					continue;
				}
				for (int k = 0; k < cellData.OccupyingStructure.Count; k++)
				{
					AdjacentMesh component = cellData.OccupyingStructure[k].GetComponent<AdjacentMesh>();
					if ((bool)component)
					{
						component.UpdateRotation();
					}
				}
			}
		}
	}

	private bool DefaultShouldConnect(Cell c)
	{
		if (c == null)
		{
			return false;
		}
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (c.OccupyingStructure[i].categoryHash == b.categoryHash)
			{
				return true;
			}
		}
		return false;
	}

	private static bool DefaultShouldRefresh(Building b, Cell c)
	{
		return c.StructureCompareCategoryNameAll(b.categoryHash);
	}

	public void TrySetMesh(AdjacentType type)
	{
		Object obj = adjMeshes[(int)type];
		if (obj == null && fillMissingWithFull)
		{
			obj = adjMeshes[15];
		}
		bool flag = true;
		if (isObject && currMesh.name != obj.name)
		{
			flag = false;
		}
		else if (!isObject && currMesh != obj)
		{
			flag = false;
		}
		if (flag)
		{
			return;
		}
		if (currMesh is SelflayingMeshGroup selflayingMeshGroup)
		{
			Object.Destroy(selflayingMeshGroup.gameObject);
		}
		currAdjType = type;
		if (obj is Mesh mesh)
		{
			currMesh = obj;
			isObject = false;
			meshFilter.mesh = mesh;
			return;
		}
		meshFilter.mesh = null;
		if (obj != null)
		{
			isObject = true;
			Object obj2 = Object.Instantiate(obj, transform.GetChild(0), instantiateInWorldSpace: false);
			obj2.name = obj.name;
			currMesh = (obj2 as GameObject).GetComponent<SelflayingMeshGroup>();
			(currMesh as SelflayingMeshGroup).Lay();
		}
	}

	private void GetAdjacencyInfo(int x, int z, out bool north, out bool south, out bool east, out bool west, out bool northEast, out bool northWest, out bool southEast, out bool southWest, out int count)
	{
		northEast = shouldConnect(World.inst.GetCellDataClamped(x + 1, z + 1));
		northWest = shouldConnect(World.inst.GetCellDataClamped(x - 1, z + 1));
		southEast = shouldConnect(World.inst.GetCellDataClamped(x + 1, z - 1));
		southWest = shouldConnect(World.inst.GetCellDataClamped(x - 1, z - 1));
		north = shouldConnect(World.inst.GetCellDataClamped(x, z + 1));
		south = shouldConnect(World.inst.GetCellDataClamped(x, z - 1));
		east = shouldConnect(World.inst.GetCellDataClamped(x + 1, z));
		west = shouldConnect(World.inst.GetCellDataClamped(x - 1, z));
		count = 0;
		if (north)
		{
			count++;
		}
		if (south)
		{
			count++;
		}
		if (east)
		{
			count++;
		}
		if (west)
		{
			count++;
		}
	}

	public void UpdateRotation()
	{
		UpdateRotationForRoad();
		UpdateLay();
		b.UpdateShaderHeight();
		onRotationUpdate?.Invoke(currAdjType);
	}

	private void ResetRotation()
	{
		meshFilter.transform.rotation = Quaternion.Euler(0f, rotOffset, 0f);
		if (currMesh is SelflayingMeshGroup selflayingMeshGroup)
		{
			selflayingMeshGroup.gameObject.transform.rotation = Quaternion.Euler(0f, rotOffset, 0f);
		}
	}

	private void RotatePiece(float degrees)
	{
		meshFilter.transform.Rotate(Vector3.up, degrees, Space.Self);
		if (currMesh is SelflayingMeshGroup selflayingMeshGroup)
		{
			selflayingMeshGroup.gameObject.transform.Rotate(Vector3.up, degrees, Space.Self);
		}
	}

	private void UpdateLay()
	{
		if (currMesh is SelflayingMeshGroup selflayingMeshGroup)
		{
			selflayingMeshGroup.Lay();
		}
	}

	private void UpdateRotationForRoad()
	{
		if (doDefaultOnly)
		{
			TrySetMesh(AdjacentType.Default);
			return;
		}
		ResetRotation();
		Cell cell = b.GetCell();
		if (cell == null)
		{
			return;
		}
		GetAdjacencyInfo(cell.x, cell.z, out var north, out var south, out var east, out var west, out var northEast, out var northWest, out var southEast, out var southWest, out var count);
		if (doDiagonals)
		{
			if (north)
			{
				northEast = (northWest = false);
			}
			if (south)
			{
				southEast = (southWest = false);
			}
			if (east)
			{
				northEast = (southEast = false);
			}
			if (west)
			{
				southWest = (northWest = false);
			}
		}
		bool num = doDiagonals && (northEast | northWest | southEast | southWest);
		int num2 = 0;
		if (north)
		{
			num2++;
		}
		if (south)
		{
			num2++;
		}
		if (east)
		{
			num2++;
		}
		if (west)
		{
			num2++;
		}
		int num3 = 0;
		if (northEast)
		{
			num3++;
		}
		if (northWest)
		{
			num3++;
		}
		if (southEast)
		{
			num3++;
		}
		if (southWest)
		{
			num3++;
		}
		if (!num)
		{
			switch (num2)
			{
			case 0:
				TrySetMesh(AdjacentType.StraightSingle);
				break;
			case 1:
				TrySetMesh(AdjacentType.StraightDeadEnd);
				if (north)
				{
					RotatePiece(90f);
				}
				if (east)
				{
					RotatePiece(180f);
				}
				if (south)
				{
					RotatePiece(270f);
				}
				break;
			case 2:
				if ((north & south) || (east & west))
				{
					TrySetMesh(AdjacentType.StraightStraight);
					if (north & south)
					{
						RotatePiece(90f);
					}
					break;
				}
				TrySetMesh(AdjacentType.StraightCorner);
				if (west & north)
				{
					RotatePiece(90f);
				}
				if (north & east)
				{
					RotatePiece(180f);
				}
				if (east & south)
				{
					RotatePiece(270f);
				}
				break;
			case 3:
				TrySetMesh(AdjacentType.StraightThreeWay);
				if (!east)
				{
					RotatePiece(90f);
				}
				if (!south)
				{
					RotatePiece(180f);
				}
				if (!west)
				{
					RotatePiece(270f);
				}
				break;
			case 4:
				TrySetMesh(AdjacentType.StraightFourWay);
				break;
			}
			if (doFull)
			{
				switch (count)
				{
				case 2:
					if ((north & east & northEast) || (east & south & southEast) || (south & west & southWest) || (north & west & northWest))
					{
						TrySetMesh(AdjacentType.FullThreeCorner);
					}
					break;
				case 3:
					if (east & south & west)
					{
						if (southEast & southWest)
						{
							TrySetMesh(AdjacentType.FullThreeFilled);
						}
						else if (southEast)
						{
							TrySetMesh(AdjacentType.FullThreeWayLeft);
						}
						else if (southWest)
						{
							TrySetMesh(AdjacentType.FullThreeWayRight);
						}
					}
					else if (north & east & south)
					{
						if (northEast & southEast)
						{
							TrySetMesh(AdjacentType.FullThreeFilled);
						}
						else if (northEast)
						{
							TrySetMesh(AdjacentType.FullThreeWayLeft);
						}
						else if (southEast)
						{
							TrySetMesh(AdjacentType.FullThreeWayRight);
						}
					}
					else if (west & north & east)
					{
						if (northWest & northEast)
						{
							TrySetMesh(AdjacentType.FullThreeFilled);
						}
						else if (northWest)
						{
							TrySetMesh(AdjacentType.FullThreeWayLeft);
						}
						else if (northEast)
						{
							TrySetMesh(AdjacentType.FullThreeWayRight);
						}
					}
					else if (south & west & north)
					{
						if (southWest & northWest)
						{
							TrySetMesh(AdjacentType.FullThreeFilled);
						}
						else if (southWest)
						{
							TrySetMesh(AdjacentType.FullThreeWayLeft);
						}
						else if (northWest)
						{
							TrySetMesh(AdjacentType.FullThreeWayRight);
						}
					}
					break;
				case 4:
				{
					if (southEast & southWest & northWest & northEast)
					{
						TrySetMesh(AdjacentType.Full);
						break;
					}
					int num4 = 0;
					if (northWest)
					{
						num4++;
					}
					if (northEast)
					{
						num4++;
					}
					if (southEast)
					{
						num4++;
					}
					if (southWest)
					{
						num4++;
					}
					switch (num4)
					{
					case 1:
						TrySetMesh(AdjacentType.FullFourOne);
						if (southEast)
						{
							RotatePiece(90f);
						}
						else if (southWest)
						{
							RotatePiece(180f);
						}
						else if (northWest)
						{
							RotatePiece(270f);
						}
						break;
					case 2:
						if ((northWest & southEast) || (northEast & southWest))
						{
							TrySetMesh(AdjacentType.FullFourDiagonal);
							if (northWest & southEast)
							{
								RotatePiece(90f);
							}
							break;
						}
						TrySetMesh(AdjacentType.FullFourTwo);
						if (northWest & southWest)
						{
							RotatePiece(270f);
						}
						else if (southWest & southEast)
						{
							RotatePiece(180f);
						}
						else if (northEast & southEast)
						{
							RotatePiece(90f);
						}
						break;
					case 3:
						TrySetMesh(AdjacentType.FullFourThree);
						if (!northWest)
						{
							RotatePiece(90f);
						}
						else if (!northEast)
						{
							RotatePiece(180f);
						}
						else if (!southEast)
						{
							RotatePiece(270f);
						}
						break;
					}
					break;
				}
				}
			}
		}
		else
		{
			if (num3 == 1)
			{
				switch (num2)
				{
				case 1:
				{
					bool flag = false;
					if (north && southEast)
					{
						flag = true;
					}
					if (east)
					{
						RotatePiece(90f);
						if (southWest)
						{
							flag = true;
						}
					}
					if (south)
					{
						RotatePiece(180f);
						if (northWest)
						{
							flag = true;
						}
					}
					if (west)
					{
						RotatePiece(270f);
						if (northEast)
						{
							flag = true;
						}
					}
					if (flag)
					{
						RotatePiece(180f);
						TrySetMesh(AdjacentType.DiagonalBendLeft);
					}
					else
					{
						TrySetMesh(AdjacentType.DiagonalBendRight);
					}
					break;
				}
				case 2:
					TrySetMesh(AdjacentType.DiagonalOneStraightTwo);
					if (southEast)
					{
						RotatePiece(90f);
					}
					if (southWest)
					{
						RotatePiece(180f);
					}
					if (northWest)
					{
						RotatePiece(270f);
					}
					break;
				default:
					TrySetMesh(AdjacentType.DiagonalDeadEnd);
					if (northEast)
					{
						RotatePiece(90f);
					}
					else if (southEast)
					{
						RotatePiece(180f);
					}
					else if (southWest)
					{
						RotatePiece(270f);
					}
					break;
				}
			}
			if (num3 == 2)
			{
				if ((northEast & southWest) || (northWest & southEast))
				{
					TrySetMesh(AdjacentType.DiagonalStraight);
					if (northEast & southWest)
					{
						RotatePiece(90f);
					}
				}
				else if (num2 == 1)
				{
					TrySetMesh(AdjacentType.DiagonalTwoStraightOne);
					if (east)
					{
						RotatePiece(90f);
					}
					else if (south)
					{
						RotatePiece(180f);
					}
					else if (west)
					{
						RotatePiece(270f);
					}
				}
				else
				{
					TrySetMesh(AdjacentType.DiagonalCorner);
					if (southWest & northWest)
					{
						RotatePiece(90f);
					}
					else if (northWest & northEast)
					{
						RotatePiece(180f);
					}
					else if (northEast & southEast)
					{
						RotatePiece(270f);
					}
				}
			}
			if (num3 == 3)
			{
				TrySetMesh(AdjacentType.DiagonalThreeWay);
				if (!northEast)
				{
					RotatePiece(90f);
				}
				else if (!southEast)
				{
					RotatePiece(180f);
				}
				else if (!southWest)
				{
					RotatePiece(270f);
				}
			}
			if (num3 == 4)
			{
				TrySetMesh(AdjacentType.DiagonalFourWay);
			}
		}
		debug = true;
	}
}
