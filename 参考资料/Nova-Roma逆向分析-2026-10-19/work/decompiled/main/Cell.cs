using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Cell : IEmployer, IMoveTarget, ICellXZ
{
	public enum StructureType
	{
		SubStructure,
		SurfaceStructure,
		Both
	}

	[Serializable]
	public class CellSaveData
	{
		public int landmass;

		public TerrainType type;

		public bool isPartOfOcean;

		public void CopyFrom(Cell cell)
		{
			landmass = cell.landMassIdx;
			type = cell.originalType;
			isPartOfOcean = cell.partOfOcean;
		}

		public void CopyTo(ref Cell cell)
		{
			cell.landMassIdx = landmass;
			cell.Type = type;
			cell.partOfOcean = isPartOfOcean;
		}
	}

	public List<Building> OccupyingStructure = new List<Building>();

	public List<Building> SubStructure = new List<Building>();

	[NonSerialized]
	public object busyObj;

	public TerrainType Type;

	private TerrainType originalType;

	public int index;

	public int x;

	public int z;

	private int RoadCoverage;

	public int Danger;

	public int IrrigationCoverage;

	public int landMassIdx = -1;

	public bool wolfTerritory;

	public bool buildingAccess;

	public bool partOfOcean;

	public bool saltWater;

	public bool deepWater;

	public float speedModifier = 1f;

	public TerrainResource terrainResource;

	public int X
	{
		get
		{
			return x;
		}
		set
		{
			x = value;
		}
	}

	public int Z
	{
		get
		{
			return z;
		}
		set
		{
			z = value;
		}
	}

	public Vector3 Position => new Vector3(x, TerrainGen.inst.GetGroundHeight(x, z), z);

	public Vector3 Center2D => new Vector3((float)x + 0.5f, 0f, (float)z + 0.5f);

	public Vector3 Center3D => new Vector3((float)x + 0.5f, TerrainGen.inst.GetGroundHeight((float)x + 0.5f, (float)z + 0.5f), (float)z + 0.5f);

	public bool Busy => busyObj != null;

	public Building BottomStructure
	{
		get
		{
			if (OccupyingStructure.Count <= 0)
			{
				return null;
			}
			return OccupyingStructure[0];
		}
	}

	public Building TopStructure
	{
		get
		{
			if (OccupyingStructure.Count <= 0)
			{
				return null;
			}
			return OccupyingStructure[OccupyingStructure.Count - 1];
		}
	}

	public Building BottomSubStructure
	{
		get
		{
			if (SubStructure.Count <= 0)
			{
				return null;
			}
			return SubStructure[0];
		}
	}

	public Building TopSubStructure
	{
		get
		{
			if (SubStructure.Count <= 0)
			{
				return null;
			}
			return SubStructure[SubStructure.Count - 1];
		}
	}

	public Building TopMostStructure
	{
		get
		{
			if (OccupyingStructure.Count <= 0)
			{
				if (SubStructure.Count <= 0)
				{
					return null;
				}
				return SubStructure[SubStructure.Count - 1];
			}
			return OccupyingStructure[OccupyingStructure.Count - 1];
		}
	}

	bool IMoveTarget.IsStationary()
	{
		return true;
	}

	Vector3 IMoveTarget.GetPredictedPosition(float time)
	{
		return Center3D;
	}

	Vector3 IMoveTarget.GetPos()
	{
		return Center3D;
	}

	int IMoveTarget.TeamID()
	{
		return -2;
	}

	Vector3 IEmployer.GetPosition()
	{
		return Center3D;
	}

	TransformData IEmployer.GetPositionForPerson(Villager p)
	{
		return new TransformData
		{
			position = Center3D
		};
	}

	bool IEmployer.IsOpen()
	{
		return true;
	}

	void IEmployer.OnAssigned(Villager p)
	{
	}

	void IEmployer.OnUnAssigned(Villager p)
	{
	}

	void IEmployer.OnJobRemoved(Job j)
	{
	}

	string IEmployer.GetUsedSkill()
	{
		return "";
	}

	int IEmployer.LandMass()
	{
		return landMassIdx;
	}

	public int GetJobCategory()
	{
		return 0;
	}

	public bool DuringWorkHours(float buffer)
	{
		return true;
	}

	public float GetStartHour()
	{
		return -1f;
	}

	public float GetEndHour()
	{
		return -1f;
	}

	public Cell(int _x, int _z, int _index)
	{
		index = _index;
		x = _x;
		z = _z;
		buildingAccess = false;
		partOfOcean = false;
	}

	internal void Reset()
	{
		OccupyingStructure.Clear();
		SubStructure.Clear();
		busyObj = null;
		Type = TerrainType.None;
		originalType = TerrainType.None;
		RoadCoverage = 0;
		Danger = 0;
		IrrigationCoverage = 0;
		landMassIdx = -1;
		wolfTerritory = false;
		buildingAccess = false;
		partOfOcean = false;
		saltWater = false;
		deepWater = false;
		speedModifier = 1f;
		terrainResource = null;
	}

	public int GetRoadCoverage()
	{
		return RoadCoverage;
	}

	public void AddRoadCoverage(int amt)
	{
		RoadCoverage += amt;
		TerrainGen.inst.dirtyTerritoryCells.Add(this);
	}

	public int GetFertility()
	{
		return TerrainGen.inst.Fertility[index];
	}

	public bool HasTerrainResourceType(int rID)
	{
		if (terrainResource != null)
		{
			return terrainResource.resourceID == rID;
		}
		return false;
	}

	public bool HasAccessibleTerrainResourceType(int rID)
	{
		if (terrainResource == null || terrainResource.resourceID != rID)
		{
			return false;
		}
		if (Type != TerrainType.Obstruction)
		{
			return false;
		}
		for (int i = 0; i < OccupyingStructure.Count; i++)
		{
			Building building = OccupyingStructure[i];
			if (building.uniqueNameHash == World.damHash || building.uniqueNameHash == World.spilloverHash)
			{
				return false;
			}
		}
		return true;
	}

	public bool IsCellClear()
	{
		if (World.inst.treeSystem.ItemAmountIncludeAnimatingTrees(this) == 0 && World.inst.rockScatterSystem.ItemAmountIncludeAnimatingTrees(this) == 0 && World.inst.coppiceTreeSystem.ItemAmountIncludeAnimatingTrees(this) == 0)
		{
			return true;
		}
		return false;
	}

	public void ClearCell(bool yesTrees = true, bool yesRocks = true)
	{
		if (yesTrees)
		{
			World.inst.coppiceTreeSystem.DeleteTreesAt(this);
			World.inst.treeSystem.DeleteTreesAt(this);
		}
		if (yesRocks)
		{
			World.inst.rockScatterSystem.DeleteTreesAt(this);
		}
	}

	public void RemoveBusy(object o)
	{
		busyObj = null;
	}

	public void AddBusy(object o)
	{
		busyObj = o;
	}

	public Building FindHighestOccupyingStructureOfCategory(int category)
	{
		for (int num = OccupyingStructure.Count - 1; num >= 0; num--)
		{
			if (OccupyingStructure[num].categoryHash == category)
			{
				return OccupyingStructure[num];
			}
		}
		return null;
	}

	public Building LowestStructureWithUniqueHash(int hash)
	{
		for (int i = 0; i < SubStructure.Count; i++)
		{
			if (SubStructure[i].uniqueNameHash == hash)
			{
				return SubStructure[i];
			}
		}
		for (int j = 0; j < OccupyingStructure.Count; j++)
		{
			if (OccupyingStructure[j].uniqueNameHash == hash)
			{
				return OccupyingStructure[j];
			}
		}
		return null;
	}

	public Building HighestStructureWithUniqueHash(int hash)
	{
		for (int num = OccupyingStructure.Count - 1; num >= 0; num--)
		{
			if (OccupyingStructure[num].uniqueNameHash == hash)
			{
				return OccupyingStructure[num];
			}
		}
		for (int num2 = SubStructure.Count - 1; num2 >= 0; num2--)
		{
			if (SubStructure[num2].uniqueNameHash == hash)
			{
				return SubStructure[num2];
			}
		}
		return null;
	}

	public Building GetTopMostCastlePiece()
	{
		for (int num = OccupyingStructure.Count - 1; num >= 0; num--)
		{
			Building building = OccupyingStructure[num];
			if (building.categoryHash == World.castleblockHash || building.categoryHash == World.gateHash)
			{
				return building;
			}
		}
		return null;
	}

	public Building FindHighestNotFireImmune()
	{
		for (int num = OccupyingStructure.Count - 1; num >= 0; num--)
		{
			if (OccupyingStructure[num] != null && !World.IsImmuneToFire(OccupyingStructure[num]))
			{
				return OccupyingStructure[num];
			}
		}
		return null;
	}

	public Building GetBuildingAbove(Building b)
	{
		bool flag = false;
		for (int i = 0; i < OccupyingStructure.Count; i++)
		{
			if (flag)
			{
				return OccupyingStructure[i];
			}
			if (OccupyingStructure[i] == b)
			{
				flag = true;
			}
		}
		return null;
	}

	public Building GetBuildingBelow(Building b)
	{
		bool flag = false;
		for (int num = OccupyingStructure.Count - 1; num >= 0; num--)
		{
			if (flag)
			{
				return OccupyingStructure[num];
			}
			if (OccupyingStructure[num] == b)
			{
				flag = true;
			}
		}
		return null;
	}

	public Building StructureFind<T>()
	{
		for (int i = 0; i < SubStructure.Count; i++)
		{
			if (!(SubStructure[i] == null) && SubStructure[i].GetComponent<T>() != null)
			{
				return SubStructure[i];
			}
		}
		for (int j = 0; j < OccupyingStructure.Count; j++)
		{
			if (!(OccupyingStructure[j] == null) && OccupyingStructure[j].GetComponent<T>() != null)
			{
				return OccupyingStructure[j];
			}
		}
		return null;
	}

	public Building StructureFind(int hash)
	{
		for (int i = 0; i < SubStructure.Count; i++)
		{
			if (SubStructure[i].uniqueNameHash == hash)
			{
				return SubStructure[i];
			}
		}
		for (int j = 0; j < OccupyingStructure.Count; j++)
		{
			if (OccupyingStructure[j].uniqueNameHash == hash)
			{
				return OccupyingStructure[j];
			}
		}
		return null;
	}

	public Building StructureFindByCategory(int categoryHash)
	{
		for (int i = 0; i < SubStructure.Count; i++)
		{
			if (SubStructure[i].categoryHash == categoryHash)
			{
				return SubStructure[i];
			}
		}
		for (int j = 0; j < OccupyingStructure.Count; j++)
		{
			if (OccupyingStructure[j].categoryHash == categoryHash)
			{
				return OccupyingStructure[j];
			}
		}
		return null;
	}

	public int CurrentStackHeight()
	{
		int num = 0;
		int i = 0;
		for (int count = OccupyingStructure.Count; i < count; i++)
		{
			Building building = OccupyingStructure[i];
			if (building.Stackable)
			{
				num += building.StackHeight;
			}
		}
		return num;
	}

	public bool BottomStructureIs<T>()
	{
		if (OccupyingStructure.Count > 0)
		{
			return OccupyingStructure[0].GetComponent<T>() != null;
		}
		return false;
	}

	public bool BottomStructureIs(int uniqueNameHash)
	{
		if (OccupyingStructure.Count > 0)
		{
			return OccupyingStructure[0].uniqueNameHash == uniqueNameHash;
		}
		return false;
	}

	public bool BottomStructureIsCategory(int categoryNameHash)
	{
		if (OccupyingStructure.Count > 0)
		{
			return OccupyingStructure[0].categoryHash == categoryNameHash;
		}
		return false;
	}

	internal bool HasAnyWater()
	{
		if (Type != TerrainType.Water)
		{
			return DynamicWater.inst.simplifiedWaterGrid[index] > 0f;
		}
		return true;
	}

	public bool TopStructureIs(int uniqueNameHash)
	{
		if (OccupyingStructure.Count > 0)
		{
			return OccupyingStructure[OccupyingStructure.Count - 1].uniqueNameHash == uniqueNameHash;
		}
		return false;
	}

	public bool TopStructureIs<T>()
	{
		if (OccupyingStructure.Count > 0)
		{
			return OccupyingStructure[OccupyingStructure.Count - 1].GetComponent<T>() != null;
		}
		return false;
	}

	public bool TopStructureCategoryIs(int categoryHash)
	{
		if (OccupyingStructure.Count > 0)
		{
			return OccupyingStructure[OccupyingStructure.Count - 1].categoryHash == categoryHash;
		}
		return false;
	}

	public bool TopStructureIs(int[] uniqueNames)
	{
		if (OccupyingStructure.Count <= 0 || OccupyingStructure[OccupyingStructure.Count - 1] == null)
		{
			return false;
		}
		Building building = OccupyingStructure[OccupyingStructure.Count - 1];
		for (int i = 0; i < uniqueNames.Length; i++)
		{
			if (uniqueNames[i] == building.uniqueNameHash)
			{
				return true;
			}
		}
		return false;
	}

	public bool TopSubStructureIs(int[] uniqueNames)
	{
		if (SubStructure.Count <= 0 || SubStructure[SubStructure.Count - 1] == null)
		{
			return false;
		}
		Building building = SubStructure[SubStructure.Count - 1];
		for (int i = 0; i < uniqueNames.Length; i++)
		{
			if (uniqueNames[i] == building.uniqueNameHash)
			{
				return true;
			}
		}
		return false;
	}

	public bool TopMostStructureIs(int[] uniqueNames)
	{
		if (!TopStructureIs(uniqueNames))
		{
			return TopSubStructureIs(uniqueNames);
		}
		return true;
	}

	public int StructureGetUniqueNameHash()
	{
		if (OccupyingStructure.Count <= 0)
		{
			return -1;
		}
		return OccupyingStructure[0].uniqueNameHash;
	}

	public int StructureGetCategoryHash()
	{
		if (OccupyingStructure.Count <= 0)
		{
			return -1;
		}
		return OccupyingStructure[0].categoryHash;
	}

	public bool StructureMatch(bool acsending, StructureType type, params int[] uniqueNameHashes)
	{
		int num = 0;
		IEnumerable<Building> enumerable;
		switch (type)
		{
		case StructureType.SubStructure:
			enumerable = SubStructure;
			num = SubStructure.Count;
			break;
		case StructureType.SurfaceStructure:
			enumerable = OccupyingStructure;
			num = OccupyingStructure.Count;
			break;
		default:
			enumerable = SubStructure.Concat(OccupyingStructure);
			num = SubStructure.Count + OccupyingStructure.Count;
			break;
		}
		if (acsending)
		{
			return StructureMatchImpl(enumerable, num, uniqueNameHashes);
		}
		return StructureMatchImpl(enumerable.Reverse(), num, uniqueNameHashes);
	}

	private bool StructureMatchImpl(IEnumerable<Building> buildings, int count, int[] uniqueNameHashes)
	{
		if (uniqueNameHashes.Length > count)
		{
			return false;
		}
		using (IEnumerator<Building> enumerator = buildings.GetEnumerator())
		{
			for (int i = 0; i < uniqueNameHashes.Length; i++)
			{
				if (enumerator.MoveNext())
				{
					if (enumerator.Current.uniqueNameHash != uniqueNameHashes[i])
					{
						return false;
					}
					continue;
				}
				return false;
			}
		}
		return true;
	}

	public bool StructureCompareUniqueNameAll(int uniqueNameHash)
	{
		for (int i = 0; i < OccupyingStructure.Count; i++)
		{
			if (OccupyingStructure[i].uniqueNameHash == uniqueNameHash)
			{
				return true;
			}
		}
		return false;
	}

	public bool SubStructureCompareUniqueNameAll(int uniqueNameHash)
	{
		for (int i = 0; i < SubStructure.Count; i++)
		{
			if (SubStructure[i].uniqueNameHash == uniqueNameHash)
			{
				return true;
			}
		}
		return false;
	}

	public bool StructureCompareCategoryNameAll(int categoryNameHash)
	{
		for (int i = 0; i < OccupyingStructure.Count; i++)
		{
			if (OccupyingStructure[i].categoryHash == categoryNameHash)
			{
				return true;
			}
		}
		return false;
	}

	public bool StructureCompareCategory(int hash)
	{
		if (OccupyingStructure.Count > 0)
		{
			return OccupyingStructure[0].categoryHash == hash;
		}
		return false;
	}

	public void StorePostGenerationType()
	{
		originalType = Type;
	}

	public static void BakeSpeedModifierForCell(Cell c)
	{
		bool flag = false;
		float num = 0.8f;
		if (c.OccupyingStructure.Count > 0)
		{
			num = 1.1f;
			Building building = c.OccupyingStructure[0];
			if (building.categoryHash == World.pathHash && building.IsBuilt())
			{
				if (building.uniqueNameHash != World.stoneRoadHash && building.uniqueNameHash != World.stoneBridgeHash)
				{
					num = ((building.uniqueNameHash != World.roadHash && building.uniqueNameHash != World.woodBridgeHash) ? 1.25f : 1.5f);
				}
				else
				{
					num = 1.9f;
				}
				flag = true;
			}
			else if (building.categoryHash == World.stockpileHash || building.categoryHash == World.castleblockHash || building.categoryHash == World.gateHash || building.uniqueNameHash == World.dockHash || building.uniqueNameHash == World.transportShipPortHash || building.uniqueNameHash == World.fishinghutHash)
			{
				num = 1.9f;
				flag = true;
			}
			else if (building.categoryHash == World.forumHash)
			{
				num = 1.75f;
				flag = true;
			}
			else if (building.categoryHash == World.farmHash)
			{
				num = 1.4f;
			}
		}
		if (c.HasAnyWater() && !flag)
		{
			num = 0.3f;
		}
		c.speedModifier = num;
	}

	public int GetEffectiveFertility()
	{
		return Mathf.Clamp(GetFertility() + ((IrrigationCoverage > 0) ? 1 : 0), 0, 3);
	}

	internal bool StructureCompareCategoryAll(int hash)
	{
		for (int i = 0; i < OccupyingStructure.Count; i++)
		{
			if (OccupyingStructure[i].categoryHash == hash)
			{
				return true;
			}
		}
		return false;
	}
}
