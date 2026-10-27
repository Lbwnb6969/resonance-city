using System;
using Assets.Code;
using Assets.Interface;
using UnityEngine;

public class TransportShip : ShipBase, ISelectable
{
	[Serializable]
	public new class ShipData
	{
		public LogisticsVehicle.LogisticsVehicleSaveData vehicleData;
	}

	public LogisticsVehicle vehicle;

	public ShipData GetShipData()
	{
		return new ShipData
		{
			vehicleData = new LogisticsVehicle.LogisticsVehicleSaveData().Pack(vehicle)
		};
	}

	public void SetFromShipData(ShipData data)
	{
		data.vehicleData.Unpack(vehicle);
	}

	private void Awake()
	{
		vehicle.RequestPathTo = RequestPathTo;
	}

	public void RequestPathTo(Vector3 pos)
	{
		MoveTo(World.inst.GetCellData(pos), displayPath: false);
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		Util.SetActive(issueButton.gameObject, vehicle.routes.Count == 0 && !(GameUI.inst.currCursorMode is LogisticsRouteCursorMode));
		if (arrived && moveTarget != null && vehicle.isDeferDroppingStorage)
		{
			Cell cell = World.inst.FindMatchingSurroundingCell(World.inst.GetCellData(moveTarget.GetPos()), testOrigin: false, 2, (Cell cell2) => cell2.landMassIdx != -1);
			if (cell != null)
			{
				for (int num = 0; num < vehicle.currStorage.resources.Count; num++)
				{
					Resource resource = vehicle.currStorage.resources[num];
					if (vehicle.TryGetCurrentRoute(out var logisticRoute))
					{
						logisticRoute.targetBuilding.GetComponent<IResourceStorage>();
						LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(logisticRoute.targetBuilding);
						if (logisticsForBuilding != null && logisticsForBuilding.requestAmt.TryGetValue(resource.resourceID, out var value) && value > 0)
						{
							continue;
						}
					}
					FreeResourceManager.inst.AddOrMakeAutoStackFor(resource.resourceID, resource.Amount, cell.Center3D);
					vehicle.currStorage.Add(resource.resourceID, -resource.Amount);
				}
				vehicle.isDeferDroppingStorage = false;
			}
		}
		switch (vehicle.GetStatus())
		{
		case 2:
			if (arrived)
			{
				vehicle.SetStatus(3);
			}
			break;
		case 4:
			if (arrived)
			{
				vehicle.SetStatus(5);
			}
			break;
		case 0:
			if (dynamics.isMoving)
			{
				arrived = false;
				path.Clear();
				pathIdx = 0;
				moveTarget = null;
			}
			break;
		case 1:
		case 3:
			break;
		}
	}

	Vector3 ISelectable.GetPos()
	{
		return GetPos();
	}

	bool ISelectable.ExclusiveSelect()
	{
		return true;
	}

	bool ISelectable.ValidToSelect()
	{
		return true;
	}

	void ISelectable.SetHighlightImmediate(int colorIdx)
	{
		highlighter.SetOutlineImmediate(colorIdx);
	}

	void ISelectable.OnSelected()
	{
		GameUI.inst.ClearCellSelected();
		GameUI.inst.ClearUIForClick();
		GameUI.inst.routeLogisticsCursorMode.currVehicle = vehicle;
		GameUI.inst.SetCursorModeLogisticsRoute();
	}

	bool ISelectable.InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		return false;
	}

	int ISelectable.TeamID()
	{
		return teamID;
	}

	internal float GetPathPercentComplete()
	{
		if (vehicle.TryGetCurrentRoute(out var logisticRoute))
		{
			if (vehicle.GetStatus() == 2 || vehicle.GetStatus() == 3)
			{
				return Mathff.DistXZ(logisticRoute.targetBuilding.GetPos(), GetPos()) / Mathff.DistXZ(logisticRoute.sourceBuilding.GetPos(), logisticRoute.targetBuilding.GetPos());
			}
			return Mathff.DistXZ(logisticRoute.sourceBuilding.GetPos(), GetPos()) / Mathff.DistXZ(logisticRoute.sourceBuilding.GetPos(), logisticRoute.targetBuilding.GetPos());
		}
		return 0f;
	}

	public static bool IsValidShipLogisticBuilding(Building b)
	{
		if (b.uniqueNameHash != World.dockHash)
		{
			return b.uniqueNameHash == World.transportShipPortHash;
		}
		return true;
	}
}
