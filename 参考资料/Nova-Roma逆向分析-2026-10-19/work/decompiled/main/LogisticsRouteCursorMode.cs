using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class LogisticsRouteCursorMode : LogisticCursor
{
	internal LogisticsVehicle currVehicle;

	private int errorType = -1;

	private const int ERROR_NONE = -1;

	private const int ERROR_NOT_SHARED_TYPES = 1;

	private const int ERROR_NO_ROUTES = 3;

	private ISelectableBuilding prevHoveredBuilding;

	public override void Init()
	{
		base.Init();
		LogisticsUI.inst.SetVisibility(v: true);
		WorldMask.inst.Activate(Masking);
		SetGameUIVisibility(v: false);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		if (clickedBuilding != null && (currVehicle == null || !GameUI.inst.IsHighlighted(currVehicle.GetComponent<ISelectable>())))
		{
			GameUI.inst.ReturnToDefaultCursorMode();
			return false;
		}
		return true;
	}

	public override void Shutdown()
	{
		base.Shutdown();
		SetGameUIVisibility(v: true);
		WorldMask.inst.Deactivate();
		LogisticsUI.inst.SetVisibility(v: false);
		currVehicle = null;
		prevHoveredBuilding = null;
		LogisticArrow.HideArrows();
		LogisticsManager.inst.UpdateButtonVisbilityForArrows(isVisible: false, null);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (GameUI.inst.GetHighlightedBuilding() as Building == null)
		{
			errorType = -1;
		}
		if (!(currVehicle != null))
		{
			return;
		}
		LogisticsManager.inst.TryAnimateArrowsForLogisticVehicle(currVehicle);
		ISelectableBuilding highlightedBuilding = GameUI.inst.GetHighlightedBuilding();
		if (IsValidBuilding(highlightedBuilding))
		{
			LogisticsManager.inst.TryAnimateArrowsForLogistic(LogisticsManager.inst.GetLogisticsForBuilding(highlightedBuilding as Building));
			if (prevHoveredBuilding != highlightedBuilding)
			{
				doForcedUpdate = true;
			}
			TrySetupTooltipForBuilding(highlightedBuilding as Building);
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(highlightedBuilding as Building);
			for (int i = 0; i < logisticsForBuilding.sourceBuildings.Count; i++)
			{
				TrySetupTooltipForBuilding(logisticsForBuilding.sourceBuildings[i]);
			}
			prevHoveredBuilding = highlightedBuilding;
		}
		else if (prevHoveredBuilding != null)
		{
			doForcedUpdate = true;
			prevHoveredBuilding = null;
		}
		currVehicle.GetComponent<ISelectable>().SetHighlightImmediate(1);
		UpdateArrowColorsForVehicle(currVehicle);
		LogisticsManager.inst.UpdateButtonVisbilityForArrows(isVisible: true, currVehicle);
		LogisticVehicleTracker.inst.TrackLogisticStorageForVehicles(currVehicle);
		for (int j = 0; j < currVehicle.routes.Count; j++)
		{
			LogisticsManager.LogisticsForStorage logisticsForBuilding2 = LogisticsManager.inst.GetLogisticsForBuilding(currVehicle.routes[j].targetBuilding);
			TrySetupTooltipForBuilding(logisticsForBuilding2.targetBuilding);
			for (int k = 0; k < logisticsForBuilding2.sourceBuildings.Count; k++)
			{
				TrySetupTooltipForBuilding(logisticsForBuilding2.sourceBuildings[k]);
			}
		}
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
			return false;
		}
		if ((resourceStorage = building.GetComponent<IResourceStorage>()) == null || resourceStorage.Equals(null))
		{
			return false;
		}
		if (currVehicle != null && LogisticsManager.inst.GetLogisticsForBuilding(building).sourceBuildings.Count == 0)
		{
			errorType = 3;
		}
		return errorType == -1;
	}

	public override void PopulateMasking()
	{
		base.PopulateMasking();
		int focusedLandMassIdxLastValid = Player.inst.FocusedLandMassIdxLastValid;
		if (currVehicle != null)
		{
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(focusedLandMassIdxLastValid);
			for (int i = 0; i < buildingListForLandMass.Count; i++)
			{
				if (IsValidBuilding(buildingListForLandMass.data[i]) && LogisticsManager.inst.GetLogisticsForBuilding(buildingListForLandMass.data[i]).sourceBuildings.Count > 0)
				{
					normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(buildingListForLandMass.data[i].gameObject));
				}
			}
			normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(currVehicle.gameObject));
		}
		if (prevHoveredBuilding != null)
		{
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(prevHoveredBuilding as Building);
			for (int j = 0; j < logisticsForBuilding.sourceBuildings.Count; j++)
			{
				normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(logisticsForBuilding.sourceBuildings[j].gameObject));
			}
			normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(logisticsForBuilding.targetBuilding.gameObject));
		}
	}

	public string GetError()
	{
		return errorType switch
		{
			1 => LocalizationManager.GetTranslation("workerui_logistics_wrongtypes"), 
			3 => LocalizationManager.GetTranslation("transportui_error_noroutes"), 
			_ => null, 
		};
	}

	private bool IsValidBuilding(ISelectableBuilding b)
	{
		if (b == null || b.Equals(null))
		{
			return false;
		}
		if (!(b as MonoBehaviour).TryGetComponent<Stockpile>(out var _))
		{
			return false;
		}
		if (LogisticsManager.inst.GetLogisticsForBuilding(b as Building).sourceBuildings.Count == 0)
		{
			return false;
		}
		return true;
	}
}
