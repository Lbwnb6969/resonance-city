using Assets;
using I2.Loc;
using UnityEngine;

public class LogisticsViewMode : LogisticCursor
{
	public enum State
	{
		None,
		HoveringVehicle,
		HoveringBuilding
	}

	private State currState;

	private LogisticsVehicle currHoveredVehicle;

	private Building currHighlightedBuilding;

	private Building currSelectedBuilding;

	public override void Init()
	{
		base.Init();
		WorldMask.inst.Activate(Masking);
		IslandInfoContainer.inst.SetOverlayTitleText(LocalizationManager.GetTranslation("islandui_logisticviewoverlay"));
		GameUI.inst.ClearCellSelected();
	}

	public override void Shutdown()
	{
		base.Shutdown();
		WorldMask.inst.Deactivate();
		currHighlightedBuilding = null;
		currSelectedBuilding = null;
		currHoveredVehicle = null;
		currState = State.None;
		LogisticArrow.HideArrows();
	}

	private void SetState(State state, LogisticsVehicle vehicle, Building highlightB, Building selectedB)
	{
		if (currState != state && currState == State.HoveringVehicle)
		{
			for (int i = 0; i < LogisticArrow.active.Count; i++)
			{
				LogisticArrow.active.data[i].SetColor(LogisticArrow.unassignedRouteColor);
			}
		}
		doForcedUpdate |= state != currState || currHighlightedBuilding != highlightB || currSelectedBuilding != selectedB || currHoveredVehicle != vehicle;
		currHighlightedBuilding = highlightB;
		currSelectedBuilding = selectedB;
		currHoveredVehicle = vehicle;
		currState = state;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		MarkerDrawer.inst.Clear();
		State state = State.None;
		LogisticsVehicle logisticHighlight = GetLogisticHighlight(out var _);
		Building building = GameUI.inst.GetHighlightedBuilding() as Building;
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (logisticHighlight != null)
		{
			state = State.HoveringVehicle;
			building = null;
		}
		else if (building != null)
		{
			if (IsValidBuilding(building))
			{
				state = State.HoveringBuilding;
			}
			else
			{
				building = null;
			}
		}
		SetState(state, logisticHighlight, building, buildingSelected);
		switch (currState)
		{
		case State.None:
		{
			for (int l = 0; l < LogisticsManager.vehicles.Count; l++)
			{
				AddMarkerForVehicle(LogisticsManager.vehicles[l]);
			}
			break;
		}
		case State.HoveringVehicle:
		{
			LogisticsManager.inst.TryAnimateArrowsForLogisticVehicle(logisticHighlight);
			UpdateArrowColorsForVehicle(logisticHighlight);
			logisticHighlight.GetComponent<ISelectable>().SetHighlightImmediate(0);
			AddMarkerForVehicle(logisticHighlight);
			for (int m = 0; m < logisticHighlight.routes.Count; m++)
			{
				LogisticRoute logisticRoute = logisticHighlight.routes[m];
				logisticRoute.targetBuilding.SetOutlineImmediate(0);
				logisticRoute.sourceBuilding.SetOutlineImmediate(0);
				TrySetupTooltipForBuilding(logisticRoute.targetBuilding);
				TrySetupTooltipForBuilding(logisticRoute.sourceBuilding);
			}
			break;
		}
		case State.HoveringBuilding:
		{
			Building building2 = GameUI.inst.GetHighlightedBuilding() as Building;
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(building2);
			LogisticsManager.inst.TryAnimateArrowsForLogistic(logisticsForBuilding);
			TrySetupTooltipForBuilding(building2);
			for (int i = 0; i < logisticsForBuilding.sourceBuildings.Count; i++)
			{
				TrySetupTooltipForBuilding(logisticsForBuilding.sourceBuildings[i]);
			}
			LogisticVehicleTracker.inst.TrackCartsForLogisticStorage(logisticsForBuilding);
			for (int j = 0; j < LogisticsManager.vehicles.Count; j++)
			{
				LogisticsVehicle logisticsVehicle = LogisticsManager.vehicles[j];
				for (int k = 0; k < logisticsVehicle.routes.Count; k++)
				{
					if (!(logisticsVehicle.routes[k].targetBuilding != building2))
					{
						logisticsVehicle.GetComponent<ISelectable>().SetHighlightImmediate(0);
						AddMarkerForVehicle(logisticsVehicle);
						break;
					}
				}
			}
			break;
		}
		}
		if (currSelectedBuilding != null)
		{
			LogisticsManager.LogisticsForStorage logisticsForBuilding2 = LogisticsManager.inst.GetLogisticsForBuilding(currSelectedBuilding);
			LogisticsManager.inst.TryAnimateArrowsForLogistic(logisticsForBuilding2);
			TrySetupTooltipForBuilding(currSelectedBuilding);
			for (int n = 0; n < logisticsForBuilding2.sourceBuildings.Count; n++)
			{
				TrySetupTooltipForBuilding(logisticsForBuilding2.sourceBuildings[n]);
			}
		}
		MarkerDrawer.inst.Draw(15f);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		if (currHoveredVehicle != null)
		{
			currHoveredVehicle.GetComponent<ISelectable>().OnSelected();
		}
		else if (IsValidBuilding(GameUI.inst.GetHighlightedBuilding()))
		{
			GameUI.inst.SetSelectedBuildingNew(clickedBuilding);
			WorkerUI.inst.storageTabUI.logisticsToggle.isOn = true;
		}
		return true;
	}

	public override bool DoSecondaryClick()
	{
		if (WorkerUI.inst.Visible)
		{
			WorkerUI.inst.SetVisible(v: false);
			GameUI.inst.ClearCellSelected();
			return true;
		}
		return false;
	}

	private LogisticsVehicle GetLogisticHighlight(out float minDist)
	{
		Vector3 vector = GameUI.inst.GridPointerIntersection();
		Ray ray = PointingSystem.GetRay();
		int num = (int)Mathff.Clamp(vector.x - 3f, 0f, World.inst.GridWidth - 1);
		int num2 = (int)Mathff.Clamp(vector.x + 3f, 0f, World.inst.GridWidth - 1);
		int num3 = (int)Mathff.Clamp(vector.z - 3f, 0f, World.inst.GridHeight - 1);
		int num4 = (int)Mathff.Clamp(vector.z + 3f, 0f, World.inst.GridHeight - 1);
		LogisticsVehicle result = null;
		minDist = float.MaxValue;
		for (int i = 0; i < LogisticsManager.inst.logisticCarts.Count; i++)
		{
			LogisticCart logisticCart = LogisticsManager.inst.logisticCarts.data[i];
			Vector3 pos = logisticCart.GetPos();
			if (pos.x >= (float)num && pos.x <= (float)num2 && pos.z >= (float)num3 && pos.z <= (float)num4)
			{
				float hitDist = 0f;
				if (logisticCart.IntersectsRay(ray, out hitDist) && hitDist < minDist)
				{
					minDist = hitDist;
					result = logisticCart.vehicle;
				}
			}
		}
		for (int j = 0; j < ShipSystem.inst.ships.Count; j++)
		{
			ShipBase shipBase = ShipSystem.inst.ships.data[j];
			if (shipBase.type != ShipBase.ShipType.Transport)
			{
				continue;
			}
			TransportShip transportShip = shipBase as TransportShip;
			Vector3 pos2 = transportShip.GetPos();
			if (pos2.x >= (float)num && pos2.x <= (float)num2 && pos2.z >= (float)num3 && pos2.z <= (float)num4)
			{
				float hitDist2 = 0f;
				if (shipBase.IntersectsRay(ray, out hitDist2) && hitDist2 < minDist)
				{
					minDist = hitDist2;
					result = transportShip.vehicle;
				}
			}
		}
		return result;
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
		return true;
	}

	public override bool ShowBuildingHighlight(ISelectableBuilding b)
	{
		if (IsValidBuilding(b))
		{
			return currHoveredVehicle == null;
		}
		return false;
	}

	public override void PopulateMasking()
	{
		for (int i = 0; i < LogisticsManager.inst.logisticCarts.Count; i++)
		{
			LogisticCart logisticCart = LogisticsManager.inst.logisticCarts.data[i];
			for (int j = 0; j < logisticCart.mRenderers.Count; j++)
			{
				normal.Add(logisticCart.mRenderers[j]);
			}
		}
		for (int k = 0; k < ShipSystem.inst.ships.Count; k++)
		{
			ShipBase shipBase = ShipSystem.inst.ships.data[k];
			if (shipBase.type == ShipBase.ShipType.Transport)
			{
				for (int l = 0; l < shipBase.meshRenderersNeedingOutline.Count; l++)
				{
					normal.Add(shipBase.meshRenderersNeedingOutline[l]);
				}
			}
		}
		int focusedLandMass = Player.inst.FocusedLandMass;
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(focusedLandMass);
		for (int m = 0; m < buildingListForLandMass.Count; m++)
		{
			if (IsValidBuilding(buildingListForLandMass.data[m]) && LogisticsManager.inst.GetLogisticsForBuilding(buildingListForLandMass.data[m]).sourceBuildings.Count > 0)
			{
				normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(buildingListForLandMass.data[m].gameObject));
			}
		}
		if (currHoveredVehicle != null)
		{
			for (int n = 0; n < currHoveredVehicle.routes.Count; n++)
			{
				normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(currHoveredVehicle.routes[n].sourceBuilding.gameObject));
			}
		}
		if (currSelectedBuilding != null)
		{
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(currSelectedBuilding);
			for (int num = 0; num < logisticsForBuilding.sourceBuildings.Count; num++)
			{
				normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(logisticsForBuilding.sourceBuildings[num].gameObject));
			}
		}
		if (currHighlightedBuilding != null)
		{
			LogisticsManager.LogisticsForStorage logisticsForBuilding2 = LogisticsManager.inst.GetLogisticsForBuilding(currHighlightedBuilding);
			for (int num2 = 0; num2 < logisticsForBuilding2.sourceBuildings.Count; num2++)
			{
				normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(logisticsForBuilding2.sourceBuildings[num2].gameObject));
			}
			normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(logisticsForBuilding2.targetBuilding.gameObject));
		}
		base.PopulateMasking();
	}
}
