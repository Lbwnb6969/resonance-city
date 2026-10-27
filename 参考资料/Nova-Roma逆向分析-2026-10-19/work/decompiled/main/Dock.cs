using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using I2.Loc;
using UnityEngine;

public class Dock : Tickable, IOutputInfo, IWorkerUIDisplay
{
	[Serializable]
	public class DockSaveData : SaveClass<Dock, DockSaveData>
	{
		private bool disallowForeignMerchants;

		private bool isDesignatedTradingPost;

		public override DockSaveData Pack(Dock s)
		{
			disallowForeignMerchants = s.disallowForeignMerchants;
			isDesignatedTradingPost = s.isDesignatedTradingPost;
			return this;
		}

		public override Dock Unpack(Dock s)
		{
			s.disallowForeignMerchants = disallowForeignMerchants;
			s.isDesignatedTradingPost = isDesignatedTradingPost;
			if (s.isDesignatedTradingPost)
			{
				isAnyPlayerDockTradingPost = true;
			}
			return s;
		}
	}

	public static bool isAnyPlayerDockTradingPost = false;

	private bool isDesignatedTradingPost;

	public Transform landMarker1;

	public Transform landMarker2;

	public Transform dockMarker1;

	public Transform dockMarker2;

	public static float MAX_HEIGHT_FROM_OCEAN = 0.35f;

	public Stockpile loadingStorageComponent;

	[NonSerialized]
	public bool disallowForeignMerchants;

	public List<Cell> dockPositions = new List<Cell>();

	public List<int> dockPositionPenalties = new List<int>();

	[NonSerialized]
	public Building bi;

	private bool noValidPositions;

	public bool IsTradingPost()
	{
		return isDesignatedTradingPost;
	}

	public void SetTradingPost(bool val)
	{
		if (val)
		{
			ArrayExt<Building> buildingListForLandMassOwner = Player.inst.GetBuildingListForLandMassOwner(Player.inst.PlayerLandmassOwner, World.dockHash);
			for (int i = 0; i < buildingListForLandMassOwner.Count; i++)
			{
				Building building = buildingListForLandMassOwner.data[i];
				if (building != this)
				{
					building.GetComponent<Dock>().SetTradingPost(val: false);
				}
			}
			isAnyPlayerDockTradingPost = true;
		}
		else if (isDesignatedTradingPost)
		{
			isAnyPlayerDockTradingPost = false;
		}
		isDesignatedTradingPost = val;
	}

	public string GetError()
	{
		if (noValidPositions)
		{
			return ScriptLocalization.DockNoPositionsError;
		}
		return null;
	}

	private void Start()
	{
		GetComponent<Building>().PlacementValidaton = PlacementValidation;
	}

	public Vector3 GetUnloadPosition()
	{
		return landMarker1.transform.position;
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(landMarker1.position);
		Cell cellDataClamped2 = World.inst.GetCellDataClamped(landMarker2.position);
		Cell cellDataClamped3 = World.inst.GetCellDataClamped(dockMarker1.position);
		Cell cellDataClamped4 = World.inst.GetCellDataClamped(dockMarker2.position);
		if (bi.transform.position.y > MAX_HEIGHT_FROM_OCEAN)
		{
			validationResult = PlacementValidationResult.DockIsTooSteep;
		}
		int num = 0;
		if (cellDataClamped3.Type == TerrainType.Water)
		{
			num++;
		}
		if (cellDataClamped4.Type == TerrainType.Water)
		{
			num++;
		}
		if (num == 0)
		{
			validationResult = PlacementValidationResult.DockNearWater;
		}
		else if (validationResult == PlacementValidationResult.MustBeOnFlatLand && cellDataClamped.Type == TerrainType.None && cellDataClamped2.Type == TerrainType.None && cellDataClamped3.Type != TerrainType.Obstruction && cellDataClamped4.Type != TerrainType.Obstruction)
		{
			validationResult = PlacementValidationResult.Valid;
		}
	}

	private bool jobFilter(IResourceProvider x, int type)
	{
		MonoBehaviour monoBehaviour = x as MonoBehaviour;
		if (monoBehaviour != null && (bool)monoBehaviour.GetComponent<Dock>())
		{
			return false;
		}
		return true;
	}

	private static bool ShouldAddDockPosition(Cell c)
	{
		return c.Type == TerrainType.Water;
	}

	private void OnBuilt()
	{
		bi.customName = PersonProfile.GetDockName(bi.FriendlyName);
	}

	public static void FillDockPositions(Building b, List<Cell> dockPositions)
	{
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minX - 1; i <= maxX + 1; i++)
		{
			Cell cellData = World.inst.GetCellData(i, minZ - 1);
			if (ShouldAddDockPosition(cellData) && !dockPositions.Contains(cellData))
			{
				dockPositions.Add(cellData);
			}
			cellData = World.inst.GetCellData(i, maxZ + 1);
			if (ShouldAddDockPosition(cellData) && !dockPositions.Contains(cellData))
			{
				dockPositions.Add(cellData);
			}
		}
		for (int j = minZ - 1; j <= maxZ + 1; j++)
		{
			Cell cellData2 = World.inst.GetCellData(minX - 1, j);
			if (ShouldAddDockPosition(cellData2) && !dockPositions.Contains(cellData2))
			{
				dockPositions.Add(cellData2);
			}
			cellData2 = World.inst.GetCellData(maxX + 1, j);
			if (ShouldAddDockPosition(cellData2) && !dockPositions.Contains(cellData2))
			{
				dockPositions.Add(cellData2);
			}
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		Building component = GetComponent<Building>();
		FillDockPositions(component, dockPositions);
		component.thought.pos = component.Center();
		ResourceAmount resourceAmount = new ResourceAmount();
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		for (int i = 0; i < resourceDefs.Count; i++)
		{
			resourceAmount.Set(resourceDefs[i].ID, 50);
		}
		loadingStorageComponent.DesiredResources = resourceAmount;
	}

	public override void OnEnableInternal()
	{
		bi = GetComponent<Building>();
		base.OnEnableInternal();
	}

	public override void Tick(float dt, int currFrame)
	{
		if (!bi.IsBuilt())
		{
			return;
		}
		int num = 0;
		for (int i = 0; i < dockPositions.Count; i++)
		{
			LandmassOwner landmassOwner = World.GetLandmassOwner(bi.LandMass());
			if (!PathCell.GetBlocksWaterPath(World.inst.GetPathCell(dockPositions[i]), landmassOwner.teamId))
			{
				num++;
			}
		}
		noValidPositions = num <= 0;
		if (num <= 0)
		{
			bi.thought.offset.x = bi.size.x * 0.5f;
			bi.thought.offset.z = bi.size.z * 0.5f;
			bi.thought.offset.y = 0.5f;
			bi.thought.thought = ThoughtBubbleSystem.Thought.GeneralError;
			bi.thought.visible = true;
		}
		else if (bi.thought.thought == ThoughtBubbleSystem.Thought.GeneralError)
		{
			bi.thought.visible = false;
		}
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
