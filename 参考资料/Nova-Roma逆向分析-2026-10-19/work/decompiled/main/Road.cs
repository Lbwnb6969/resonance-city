using System;
using System.Collections.Generic;
using UnityEngine;

public class Road : MonoBehaviour, IWorkerUIDisplay
{
	[Serializable]
	public class RoadSaveData : SaveClass<Road, RoadSaveData>
	{
		public override RoadSaveData Pack(Road w)
		{
			return this;
		}

		public override Road Unpack(Road w)
		{
			if (w.b.IsBuilt())
			{
				w.OnBuilt();
			}
			return w;
		}
	}

	public bool isBridge;

	private Building b;

	private AdjacentMesh adjMesh;

	private List<float> vertHeights = new List<float>();

	public bool ShowCustomButton()
	{
		return false;
	}

	public bool CustomButtonInteractable()
	{
		return false;
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public string CustomButtonTitle()
	{
		return "";
	}

	public string CustomButtonText()
	{
		return "";
	}

	public Sprite CustomButtonImage()
	{
		return null;
	}

	public void CustomButtonClicked()
	{
	}

	private void Start()
	{
		b = GetComponent<Building>();
		adjMesh = GetComponent<AdjacentMesh>();
	}

	public void PlacementValidation(ref PlacementValidationResult result)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		if (isBridge)
		{
			if (cellDataClamped.BottomStructureIs(World.woodBridgeHash) && b.uniqueNameHash == World.stoneBridgeHash)
			{
				result = PlacementValidationResult.Valid;
			}
			if (cellDataClamped.Type != TerrainType.Water)
			{
				result = PlacementValidationResult.BridgeNotInWater;
			}
			else if (cellDataClamped.SubStructureCompareUniqueNameAll(World.pierHash))
			{
				result = PlacementValidationResult.ExistingStructure;
			}
			return;
		}
		if (result == PlacementValidationResult.ExistingStructure)
		{
			if (cellDataClamped.BottomStructure != null && World.IsLandRoad(cellDataClamped.BottomStructure) && b.uniqueNameHash != cellDataClamped.BottomStructure.uniqueNameHash)
			{
				result = PlacementValidationResult.Valid;
			}
			if (cellDataClamped.StructureFindByCategory(World.gateHash) != null && !World.IsLandRoad(cellDataClamped.BottomStructure))
			{
				result = PlacementValidationResult.Valid;
			}
		}
		if (b.categoryHash == World.pathHash && cellDataClamped.StructureCompareUniqueNameAll(World.castlestairsHash))
		{
			result = PlacementValidationResult.Valid;
		}
		if (cellDataClamped.Type != TerrainType.None)
		{
			result = PlacementValidationResult.RoadNotOnLand;
		}
	}

	private void OnInit()
	{
		if (b == null)
		{
			b = GetComponent<Building>();
		}
		b.PlacementValidaton = PlacementValidation;
		if (adjMesh == null)
		{
			adjMesh = GetComponent<AdjacentMesh>();
		}
		adjMesh.shouldConnect = ShouldConnect;
		adjMesh.shouldRefresh = ShouldRefresh;
	}

	private void OnBuilt()
	{
		if (b == null)
		{
			b = GetComponent<Building>();
		}
		TerrainGen.inst.SetRoadTile(GetComponent<Building>().GetCell(), isWood: true, isStone: false);
		GetComponentInChildren<MeshRenderer>().enabled = false;
	}

	private void OnFinishedLoad()
	{
		if (GetComponent<Building>().IsBuilt())
		{
			TerrainGen.inst.SetRoadTile(GetComponent<Building>().GetCell(), isWood: true, isStone: false);
			GetComponentInChildren<MeshRenderer>().enabled = false;
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		RoadBasic.ApplyRoadCoverage(GetComponent<Building>(), undo);
	}

	public void UpdateMaxHeights()
	{
	}

	public void UpdateTerrain()
	{
	}

	public void UpdateTerrainRotation()
	{
	}

	private void OnDisable()
	{
		if (b == null)
		{
			b = GetComponent<Building>();
		}
		TerrainGen.inst.SetRoadTile(b.GetCell(), isWood: false, isStone: false);
	}

	public static bool ConnectsToRoad(Building b)
	{
		if (b.categoryHash != World.pathHash && b.categoryHash != World.gateHash && b.uniqueNameHash != World.townsquareHash)
		{
			return b.categoryHash == World.parkHash;
		}
		return true;
	}

	public static bool ShouldConnect(Cell c)
	{
		if (c != null)
		{
			for (int i = 0; i < c.OccupyingStructure.Count; i++)
			{
				if (ConnectsToRoad(c.OccupyingStructure[i]))
				{
					return true;
				}
			}
			if (GameUI.inst.CurrPlacementMode.TestRoadConnection(c))
			{
				return true;
			}
		}
		return false;
	}

	public static bool ShouldRefresh(Building b, Cell c)
	{
		if (c.StructureCompareCategoryNameAll(World.pathHash))
		{
			return !c.StructureCompareUniqueNameAll(World.drawBridgeHash);
		}
		return false;
	}
}
