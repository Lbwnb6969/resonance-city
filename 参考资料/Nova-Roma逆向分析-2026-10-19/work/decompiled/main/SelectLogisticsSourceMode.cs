using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class SelectLogisticsSourceMode : LogisticCursor
{
	internal LogisticsManager.LogisticsForStorage currLogistic;

	private int errorType = -1;

	private const int ERROR_NONE = -1;

	private const int ERROR_NOT_SHARED_TYPES = 1;

	private const int ERROR_WRONG_LANDMASS = 2;

	private const int ERROR_NOT_VALID_BUILDING = 3;

	private const int ERROR_ALREADY_SOURCED = 4;

	public override void Init()
	{
		base.Init();
		WorldMask.inst.Activate(Masking);
		SetGameUIVisibility(v: false);
	}

	public override void Shutdown()
	{
		base.Shutdown();
		WorldMask.inst.Deactivate();
		SetGameUIVisibility(v: true);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		LogisticsManager.inst.TryAnimateArrowsForLogistic(currLogistic);
		if (currLogistic != null)
		{
			for (int i = 0; i < currLogistic.sourceBuildings.Count; i++)
			{
				currLogistic.sourceBuildings[i].SetOutlineImmediate(0);
				TrySetupTooltipForBuilding(currLogistic.sourceBuildings[i]);
			}
			TrySetupTooltipForBuilding(currLogistic.targetBuilding);
			currLogistic.targetBuilding.SetOutlineImmediate(1);
		}
		ISelectableBuilding highlightedBuilding = GameUI.inst.GetHighlightedBuilding();
		if (highlightedBuilding as Building == null)
		{
			errorType = -1;
		}
		else if (errorType != -1)
		{
			if (errorType != 3)
			{
				highlightedBuilding.SetOutlineImmediate(2);
			}
		}
		else if (currLogistic != null)
		{
			TrySetupTooltipForBuilding(highlightedBuilding as Building);
		}
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		Building building = clickedBuilding as Building;
		if (building == null)
		{
			return true;
		}
		if (currLogistic != null)
		{
			if (errorType == -1)
			{
				IResourceStorage component = building.GetComponent<IResourceStorage>();
				IResourceStorage component2 = currLogistic.targetBuilding.GetComponent<IResourceStorage>();
				if (component == null || component.Equals(null) || ExcludeSource(building) || building == currLogistic.targetBuilding || currLogistic.sourceBuildings.Contains(building) || !SharesResourceTypes(component, component2))
				{
					return true;
				}
				LogisticsManager.inst.TryAddSourceToLogistic(currLogistic, building);
				BuildingLogisticsUI.inst.RefreshVisuals();
			}
			else if (errorType == 4)
			{
				int num = -1;
				for (int i = 0; i < currLogistic.sourceBuildings.Count; i++)
				{
					if (!(currLogistic.sourceBuildings[i] != building))
					{
						num = i;
						break;
					}
				}
				if (num != -1)
				{
					LogisticsManager.inst.RemoveSourceFromBuilding(currLogistic.targetBuilding, num);
					BuildingLogisticsUI.inst.RefreshVisuals();
				}
			}
		}
		return true;
	}

	public override bool DoSecondaryClick()
	{
		GameUI.inst.ReturnToDefaultCursorMode();
		return true;
	}

	public override bool ShowBuildingHighlight(ISelectableBuilding b)
	{
		Building building = b as Building;
		IResourceStorage resourceStorage = null;
		errorType = -1;
		if (building == null)
		{
			errorType = 3;
			return false;
		}
		if ((resourceStorage = building.GetComponent<IResourceStorage>()) == null || resourceStorage.Equals(null))
		{
			errorType = 3;
			return false;
		}
		if (currLogistic != null)
		{
			IResourceStorage component = currLogistic.targetBuilding.GetComponent<IResourceStorage>();
			if (!SharesResourceTypes(component, resourceStorage))
			{
				errorType = 1;
			}
			if (currLogistic.targetBuilding.LandMass() != building.LandMass() && (!TransportShip.IsValidShipLogisticBuilding(building) || !TransportShip.IsValidShipLogisticBuilding(currLogistic.targetBuilding)))
			{
				errorType = 2;
			}
			if (currLogistic.sourceBuildings.Contains(building))
			{
				errorType = 4;
				return false;
			}
		}
		return errorType == -1;
	}

	public void HighlightBuildingList(ArrayExt<Building> bList, IResourceStorage targetStorage)
	{
		for (int i = 0; i < bList.Count; i++)
		{
			IResourceStorage resourceStorage = null;
			if ((resourceStorage = bList.data[i].GetComponent<IResourceStorage>()) != null && !resourceStorage.Equals(null) && SharesResourceTypes(targetStorage, resourceStorage) && bList.data[i] != currLogistic.targetBuilding)
			{
				highlight.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(bList.data[i].gameObject));
			}
		}
	}

	public override void PopulateMasking()
	{
		base.PopulateMasking();
		if (currLogistic == null)
		{
			return;
		}
		IResourceStorage component = currLogistic.targetBuilding.GetComponent<IResourceStorage>();
		HighlightBuildingList(Player.inst.GetBuildingListForLandMass(currLogistic.targetBuilding.LandMass()), component);
		if (currLogistic.targetBuilding.uniqueNameHash == World.dockHash)
		{
			for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
			{
				int landMass = Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i];
				HighlightBuildingList(Player.inst.GetBuildingListForLandMass(landMass, World.dockHash), component);
			}
		}
		if (currLogistic.targetBuilding.uniqueNameHash == World.transportShipPortHash)
		{
			for (int j = 0; j < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; j++)
			{
				int landMass2 = Player.inst.PlayerLandmassOwner.ownedLandMasses.data[j];
				HighlightBuildingList(Player.inst.GetBuildingListForLandMass(landMass2, World.transportShipPortHash), component);
			}
		}
		normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(currLogistic.targetBuilding.gameObject));
	}

	public string GetError()
	{
		switch (errorType)
		{
		case 2:
			if (!TransportShip.IsValidShipLogisticBuilding(currLogistic.targetBuilding))
			{
				return LocalizationManager.GetTranslation("workerui_logistics_wronglandmass");
			}
			return LocalizationManager.GetTranslation("workerui_logistics_needdock");
		case 1:
			return LocalizationManager.GetTranslation("workerui_logistics_wrongtypes");
		default:
			return null;
		}
	}

	private bool ExcludeSource(Building b)
	{
		if (b == null)
		{
			return true;
		}
		return false;
	}

	public bool SharesResourceTypes(IResourceStorage r1, IResourceStorage r2)
	{
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			if (r1.StoresTypePublic(resourceDef.ID) && r2.StoresTypePublic(resourceDef.ID))
			{
				return true;
			}
		}
		return false;
	}
}
