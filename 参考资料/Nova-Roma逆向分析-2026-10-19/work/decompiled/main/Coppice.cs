using System;
using Assets.Code;
using I2.Loc;
using UnityEngine;

public class Coppice : Tickable, IProductionInfo, IOutputInfo, IWorkerUIDisplay
{
	public Sprite costIcon;

	public Sprite resultIcon;

	public Building b;

	public GameObject stump;

	private int chopCount;

	private bool didFirstGrowth;

	private float currDelay;

	private BuildingProductionUI.CustomProductionItem[] customCosts = new BuildingProductionUI.CustomProductionItem[1];

	private BuildingProductionUI.CustomProductionItem[] customResults = new BuildingProductionUI.CustomProductionItem[1];

	private EventHandler<OnBuildingAddRemove> addRemoveListenEventHandler;

	private EventHandler<OnBuildingOpenClose> openCloseListenEventHandler;

	private EventHandler<OnBuildingBuilt> buildListenEventHandler;

	private float growBonus = 1f;

	private float growDelay = 75f;

	private void OnInit()
	{
		customCosts[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = costIcon,
			locTerm = "custom_production_cost_stump",
			hideBottom = true,
			hideConsumption = true
		};
		customResults[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = resultIcon,
			locTerm = "custom_production_result_tree",
			maxStorage = 1
		};
		addRemoveListenEventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		openCloseListenEventHandler = Broadcast.BuildingOpenClose.ListenAny(BuildingOpenClose);
		buildListenEventHandler = Broadcast.BuildingBuilt.ListenAny(BuildingBuilt);
	}

	private void OnDestroy()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(addRemoveListenEventHandler);
		Broadcast.BuildingOpenClose.UnlistenAny(openCloseListenEventHandler);
		Broadcast.BuildingBuilt.UnlistenAny(buildListenEventHandler);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		RefreshBonuses(obj.targetBuilding);
	}

	private void BuildingOpenClose(object sender, OnBuildingOpenClose obj)
	{
		RefreshBonuses(obj.targetBuilding);
	}

	private void BuildingBuilt(object sender, OnBuildingBuilt obj)
	{
		RefreshBonuses(obj.targetBuilding);
	}

	private void OnFinishedLoad()
	{
		UpdateNearForester();
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			UpdateNearForester();
		}
	}

	private void UpdateNearForester()
	{
		growBonus = 1f;
		Cell cell = b.GetCell();
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(b.LandMass(), World.foresterHash);
		if (buildingListForLandMass == null)
		{
			return;
		}
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			Building building = buildingListForLandMass.data[i];
			if (building.IsBuilt() && building.IsOpen() && building.GetComponent<Forester>().InZone(cell))
			{
				growBonus = 1.5f;
				break;
			}
		}
	}

	private void RefreshBonuses(Building b)
	{
		if (b.uniqueNameHash == World.foresterHash)
		{
			UpdateNearForester();
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (!b.IsBuilt())
		{
			return;
		}
		Cell cell = b.GetCell();
		if (chopCount == 0 && cell.IsCellClear())
		{
			if (!didFirstGrowth)
			{
				World.inst.treeSystem.GrowTree(cell, b.Center());
				didFirstGrowth = true;
			}
			else
			{
				chopCount++;
				stump.SetActive(value: true);
				currDelay = growDelay;
			}
		}
		if (chopCount >= 1 && World.inst.coppiceTreeSystem.ItemAmountIncludeAnimatingTrees(b.GetCell()) <= 0)
		{
			currDelay -= dt * growBonus;
			if (currDelay < 0f)
			{
				World.inst.coppiceTreeSystem.GrowTree(cell, b.Center());
				currDelay = growDelay;
			}
		}
	}

	ResourceAmount IProductionInfo.GetCost()
	{
		return null;
	}

	int IProductionInfo.GetResult(int rID)
	{
		return 0;
	}

	bool IProductionInfo.ShowResultStorage()
	{
		return true;
	}

	int IProductionInfo.GetInputStorage(int rID)
	{
		return 0;
	}

	int IProductionInfo.GetInputMaxStorage(int rID)
	{
		return 0;
	}

	int IProductionInfo.GetOutputStorage(int rID)
	{
		return 0;
	}

	int IProductionInfo.GetOutputMaxStorage(int rID)
	{
		return 0;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomCost()
	{
		return customCosts;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomResult()
	{
		customResults[0].currentStorage = ((chopCount == 0) ? World.inst.treeSystem.ItemAmount(b.GetCell()) : World.inst.coppiceTreeSystem.ItemAmount(b.GetCell()));
		return customResults;
	}

	float IProductionInfo.GetProgress()
	{
		return World.inst.coppiceTreeSystem.GetAnimTreeProgress(b.GetCell());
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		if (growBonus > 1f)
		{
			return ScriptLocalization.workerui_coppice_regrowth_bonus;
		}
		return ScriptLocalization.workerui_coppice_regrowth_desc;
	}

	public string GetError()
	{
		return null;
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return false;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
