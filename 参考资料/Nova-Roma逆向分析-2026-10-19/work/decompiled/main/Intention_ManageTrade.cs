using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using UnityEngine;

public class Intention_ManageTrade : AIIntentionBase
{
	[Serializable]
	public class ManagTradeSaveData : SaveClass<Intention_ManageTrade, ManagTradeSaveData>
	{
		private Dictionary<int, int> priceMod;

		private Guid merchantShipGuid;

		public override ManagTradeSaveData Pack(Intention_ManageTrade v)
		{
			if (v.merchantShip != null)
			{
				merchantShipGuid = v.merchantShip.guid;
			}
			return this;
		}

		public override Intention_ManageTrade Unpack(Intention_ManageTrade v)
		{
			ArrayExt<ShipBase> ships = ShipSystem.inst.ships;
			for (int i = 0; i < ships.Count; i++)
			{
				if (ships.data[i].guid == merchantShipGuid)
				{
					v.merchantShip = ships.data[i] as Ship;
				}
			}
			return v;
		}
	}

	private Intention_BuildPreplannedBuilding buildMerchantShip;

	private int teamID;

	private Building Dock;

	public int foreignTeamId;

	public Ship merchantShip;

	private bool merchantNeedsUpdating;

	private IMoveTarget moveTarget;

	private Timer OrderTimer = new Timer(30f);

	private ResourceAmount currentOrderAmt = new ResourceAmount();

	private ResourceAmount previousOrderAmt = new ResourceAmount();

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Building traderDock;

	public void Init(int _foreignTeamId)
	{
		foreignTeamId = _foreignTeamId;
		teamID = LandmassOwner.teamId;
		OrderTimer.ForceExpire();
		Dock = Player.inst.GetBuildingListForLandMass(LandMass, World.dockHash).First();
		Player inst = Player.inst;
		inst.OnDocksOpenForTrade = (Player.OnDockUpdate)Delegate.Combine(inst.OnDocksOpenForTrade, new Player.OnDockUpdate(OnDocksOpenForTrade));
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
	}

	private void OnDestroy()
	{
		Player inst = Player.inst;
		inst.OnDocksOpenForTrade = (Player.OnDockUpdate)Delegate.Remove(inst.OnDocksOpenForTrade, new Player.OnDockUpdate(OnDocksOpenForTrade));
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	private void OnDocksOpenForTrade(LandmassOwner a, LandmassOwner b, bool isOpen)
	{
		if (!isOpen && merchantShip != null && ((a == LandmassOwner && b.teamId == foreignTeamId) || (b == LandmassOwner && a.teamId == foreignTeamId)))
		{
			EffectsMan.inst.BuildPuff.CreateAndPlay(merchantShip.transform.position);
			UnityEngine.Object.Destroy(merchantShip.gameObject);
			merchantShip = null;
		}
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (merchantShip != null && !obj.added && obj.targetBuilding.categoryHash == World.dockHash && obj.targetBuilding.TeamID() == teamID)
		{
			merchantShip.ClearOrders();
			merchantShip.logisticsIdx = 0;
			if (merchantShip.moveTarget != moveTarget)
			{
				merchantShip.MoveTo(GetSafeHomeTarget());
			}
		}
	}

	public void RefreshMerchantOrders()
	{
		merchantNeedsUpdating = true;
	}

	public void LowerPriceMod()
	{
		ResourceAmount payCosts = World.GetLandmassOwnerByTeamId(foreignTeamId).GetPayCosts(LandmassOwner.teamId);
		bool flag = true;
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int i = 0;
		for (int count = resourceDefs.Count; i < count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			if (resourceDef.ID != 4 && payCosts.Get(resourceDef.ID) > 1 && ((SRand.Range(0, 10) > 8) & flag))
			{
				payCosts.Add(resourceDef.ID, -1);
				flag = false;
			}
		}
		World.GetLandmassOwnerByTeamId(foreignTeamId).SetPayCosts(LandmassOwner.teamId, payCosts);
	}

	private void SetupOrdersForDock(Building b, Ship ourMerchant)
	{
		int teamId = LandmassOwner.teamId;
		if (Player.inst.DocksOpen(LandmassOwner, World.GetLandmassOwnerByTeamId(b.TeamID())))
		{
			Ship.LogisticsOrder logisticsOrder = new Ship.LogisticsOrder();
			if (b.TeamID() == teamId)
			{
				logisticsOrder.loadFromStart = currentOrderAmt;
			}
			else
			{
				logisticsOrder.unloadAtEnd = LandmassOwner.GetPayCosts(b.TeamID());
			}
			logisticsOrder.SetEnd(b);
			ourMerchant.logisticsOrders.Add(logisticsOrder);
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (!Player.inst.DocksOpen(LandmassOwner, World.GetLandmassOwnerByTeamId(foreignTeamId)))
		{
			return;
		}
		if (Dock == null)
		{
			Dock = Player.inst.GetBuildingListForLandMass(LandMass, World.dockHash).First();
		}
		if (Dock != null)
		{
			bool flag = false;
			if (OrderTimer.Update(dt))
			{
				for (int i = 0; i < Kingdom.CurrentResources.resources.Count; i++)
				{
					Resource resource = Kingdom.CurrentResources.resources[i];
					if (resource.resourceID != 4 && resource.Amount > 200)
					{
						currentOrderAmt.Set(resource.resourceID, 10);
					}
				}
				if (previousOrderAmt != currentOrderAmt)
				{
					flag = true;
				}
				previousOrderAmt = currentOrderAmt;
			}
			if (merchantShip == null)
			{
				if (buildMerchantShip == null && !IsBeingBuilt(World.playerMerchantShipHash))
				{
					buildMerchantShip = AddSubIntention<Intention_BuildPreplannedBuilding>("build merchant");
					buildMerchantShip.unZone = true;
					buildMerchantShip.InitClosest("playermerchant", Layout.KingdomStart);
				}
			}
			else if ((merchantNeedsUpdating || NeedToRedoOrders(merchantShip.logisticsOrders)) | flag)
			{
				merchantShip.ClearOrders();
				merchantShip.logisticsIdx = 0;
				traderDock = null;
				ArrayExt<Building> buildingListForLandMassOwner = Player.inst.GetBuildingListForLandMassOwner(World.GetLandmassOwnerByTeamId(foreignTeamId), World.dockHash);
				for (int j = 0; j < buildingListForLandMassOwner.Count; j++)
				{
					Building building = buildingListForLandMassOwner.data[j];
					if (building.IsBuilt() && building.IsOpen() && !building.GetComponent<Dock>().disallowForeignMerchants)
					{
						traderDock = building;
					}
				}
				if (traderDock != null)
				{
					SetupOrdersForDock(Dock, merchantShip);
					SetupOrdersForDock(traderDock, merchantShip);
					if (merchantShip.Paused)
					{
						merchantShip.SetPause(p: false);
					}
					merchantNeedsUpdating = false;
				}
				else
				{
					if (merchantShip.moveTarget != moveTarget)
					{
						merchantShip.MoveTo(GetSafeHomeTarget());
					}
					if (merchantShip.arrived && !merchantShip.Paused)
					{
						merchantShip.SetPause(p: true);
					}
				}
			}
			if (traderDock != null && traderDock.GetComponent<Dock>().disallowForeignMerchants)
			{
				merchantNeedsUpdating = true;
			}
		}
		if (!KillAndNullFinishedIntention(ref buildMerchantShip) || !(merchantShip == null))
		{
			return;
		}
		ArrayExt<ShipBase> ships = ShipSystem.inst.ships;
		for (int k = 0; k < ships.Count; k++)
		{
			if (ships.data[k].teamID == teamID && ships.data[k].type == ShipBase.ShipType.PlayerMerchant && !Kingdom.IsMerchantShipAssigned(ships.data[k] as Ship))
			{
				merchantShip = ships.data[k] as Ship;
				merchantNeedsUpdating = true;
				break;
			}
		}
	}

	internal bool NeedToRedoOrders(List<Ship.LogisticsOrder> orders)
	{
		if (orders.Count < 2)
		{
			return true;
		}
		for (int i = 0; i < orders.Count; i++)
		{
			if (orders[i].endType == Ship.LogisticsOrderType.Position)
			{
				return true;
			}
		}
		return false;
	}

	internal IMoveTarget GetSafeHomeTarget()
	{
		Cell result = World.inst.GetCellData(Layout.KingdomStart);
		if (Dock != null)
		{
			Cell prevCell = null;
			Dock component = Dock.GetComponent<Dock>();
			result = ShipBase.GetDockCell(merchantShip, component.dockPositions, component.dockPositionPenalties, prevCell);
		}
		moveTarget = result;
		return result;
	}

	internal void ConsiderBuyingFrom(Ship.LogisticsOrder currOrder, Ship ship)
	{
		ResourceAmount currentResources = Kingdom.CurrentResources;
		int num = (int)((float)currentResources.Get(4) * 0.25f);
		ResourceAmount amt = new ResourceAmount();
		bool flag = false;
		int want = -1;
		int num2 = 0;
		for (int i = 0; i < ship.hold.resources.Count; i++)
		{
			if (num <= 0)
			{
				break;
			}
			int resourceID = ship.hold.resources[i].resourceID;
			if (resourceID != 4 && Kingdom.AtLowResourcesExtended(resourceID))
			{
				int num3 = currentResources.Get(resourceID);
				int num4 = num3 + SRand.Range(5, 55);
				int num5 = ship.hold.Get(resourceID);
				if (num5 <= 0)
				{
					want = resourceID;
				}
				int num6 = LandmassOwner.GetPayCosts(ship.TeamID()).Get(resourceID);
				int num7 = Mathff.Min(num5, num4 - num3);
				if (num6 > 0)
				{
					num7 = Mathff.Min(Mathff.Min(num5, num4 - num3), num / num6);
				}
				if (num7 == 0 && num5 > 0)
				{
					flag = true;
				}
				if (num7 > 0)
				{
					amt.Set(resourceID, num7);
					int num8 = num7 * num6;
					num -= num8;
					num2 += num8;
				}
			}
		}
		if (num2 > 0)
		{
			int num9 = 0;
			for (int j = 0; j < amt.resources.Count; j++)
			{
				ResourceTextStackManager.inst.ShowResourceAmount(this, ship.GetPos() + new Vector3(0f, (float)num9 * 0.25f, 0f), amt.resources[j].resourceID, amt.resources[j].Amount);
				num9++;
			}
		}
		ship.RemoveFromHold(amt);
		World.GetLandmassOwnerByTeamId(ship.TeamID()).Gold += num2;
		currOrder.GetBuilding().GetComponent<Dock>().loadingStorageComponent.Deposit(ref amt);
		LandmassOwner.Gold -= num2;
		if (ship.TeamID() == 0)
		{
			currOrder.want = -1;
			if (num2 > 0)
			{
				currOrder.lastTransactionAmt = num2;
				ResourceStatistics.AddProduction(Player.inst.PlayerLandmassOwner.ownedLandMasses.data[0], "trade", 4, num2);
			}
			else if (flag)
			{
				currOrder.lastTransactionAmt = -1f;
			}
			else
			{
				currOrder.lastTransactionAmt = -2f;
				currOrder.want = want;
			}
			if (ShipLogisticsUI.inst != null && ShipLogisticsUI.inst.gameObject.activeSelf)
			{
				ShipLogisticsUI.inst.RefreshMerchantStatusForOrder(currOrder);
			}
		}
	}
}
