using System;
using System.Collections.Generic;
using Assets.Code;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class MerchantShip : ShipBase, ISelectable, IMerchant
{
	[Serializable]
	public struct VisualResourceEntry
	{
		public int id;

		public GameObject obj;
	}

	public enum Status
	{
		SailingToDock,
		Waiting,
		Leaving,
		Done
	}

	[Serializable]
	public new class ShipData
	{
		public ResourceAmount hold;

		public Status status;

		public Guid dockID;

		public float waitTime;

		public Player.UpgradeType upgrade;

		public ResourceAmount sellToPrice;

		public ResourceAmount buyFromPrice;

		public SerializableDictionary<int, int> soldItems;
	}

	[SerializeField]
	private VisualResourceEntry[] visualEntries;

	[NonSerialized]
	public Dictionary<int, int> itemsSold = new Dictionary<int, int>();

	[NonSerialized]
	public Status status;

	public Player.UpgradeType specialUpgrade;

	private Guid dockID;

	public EventInstance eAmb;

	[NonSerialized]
	public ResourceAmount sellToPrice = new ResourceAmount();

	[NonSerialized]
	public ResourceAmount buyFromPrice = new ResourceAmount();

	private bool isHoldVisualsDirty;

	private ResourceAmount hold = new ResourceAmount();

	private static int dockHash = "dock".GetHashCode();

	public bool isTargetPlayerDock;

	private float waitTimer;

	public ResourceAmount Hold => hold;

	private void Start()
	{
		eAmb = RuntimeManager.CreateInstance("event:/SFX ASITP/Ambiences/ambSpot_ship_chatter_lp");
		eAmb.start();
		eAmb.release();
	}

	private void OnDestroy()
	{
		if (eAmb.isValid())
		{
			eAmb.stop(STOP_MODE.IMMEDIATE);
		}
	}

	public void StartSailing(Building dock)
	{
		isTargetPlayerDock = Player.inst.LandMassIsAPlayerLandMass(dock.LandMass());
		dockID = dock.guid;
		Dock component = dock.GetComponent<Dock>();
		Cell dockCell = ShipBase.GetDockCell(this, component.dockPositions, component.dockPositionPenalties);
		MoveTo(dockCell);
		status = Status.SailingToDock;
		ResourceAmount resourceAmount = new ResourceAmount();
		Player.inst.CountResources(dock.LandMass(), resourceAmount);
		for (int i = 0; i < 5; i++)
		{
			int num = 0;
			int num2 = int.MaxValue;
			for (int j = 0; j < resourceAmount.resources.Count; j++)
			{
				int resourceID = resourceAmount.resources[j].resourceID;
				if (resourceID != 4 && resourceID != 17 && num2 > resourceAmount.Get(resourceID))
				{
					num2 = resourceAmount.Get(resourceID);
					num = resourceID;
				}
			}
			float num3 = SRand.Range(0.5f, 1f);
			if (FreeResourceSystem.inst.resourceDefMap.TryGetValue(num, out var value) && value.isSecondary)
			{
				num3 = SRand.Range(0.2f, 0.4f);
			}
			float v = (float)Player.inst.Workers.Count * num3;
			hold.Add(num, (int)Mathff.Clamp(v, 25f, 1000f));
			resourceAmount.Set(num, 9999);
		}
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		for (int k = 0; k < resourceDefs.Count; k++)
		{
			int iD = resourceDefs[k].ID;
			if (iD != 4 && iD != 17 && (float)SRand.Range(0, 100) < Mathff.Min(40f + (float)Player.inst.Workers.Count * 0.3f, 75f))
			{
				float num4 = SRand.Range(0.15f, 0.3f);
				if (FreeResourceSystem.inst.resourceDefMap.TryGetValue(iD, out var value2) && value2.isSecondary)
				{
					num4 *= 0.4f;
				}
				float v2 = (float)Player.inst.Workers.Count * num4;
				hold.Add(iD, (int)Mathff.Clamp(v2, 0f, 1000f));
			}
		}
		buyFromPrice.Set(0, SRand.Range(1, 3));
		buyFromPrice.Set(9, SRand.Range(1, 4));
		buyFromPrice.Set(12, SRand.Range(2, 4));
		buyFromPrice.Set(18, SRand.Range(1, 5));
		buyFromPrice.Set(11, SRand.Range(3, 5));
		buyFromPrice.Set(8, SRand.Range(4, 6));
		buyFromPrice.Set(10, SRand.Range(6, 9));
		buyFromPrice.Set(20, SRand.Range(6, 9));
		buyFromPrice.Set(1, SRand.Range(1, 3));
		buyFromPrice.Set(2, SRand.Range(1, 4));
		buyFromPrice.Set(14, SRand.Range(2, 5));
		buyFromPrice.Set(5, SRand.Range(2, 6));
		buyFromPrice.Set(15, SRand.Range(2, 5));
		buyFromPrice.Set(3, SRand.Range(1, 4));
		buyFromPrice.Set(16, SRand.Range(3, 6));
		buyFromPrice.Set(13, SRand.Range(4, 9));
		buyFromPrice.Set(19, SRand.Range(5, 10));
		buyFromPrice.Set(7, SRand.Range(8, 14));
		buyFromPrice.Set(6, SRand.Range(8, 14));
		sellToPrice.Set(0, SRand.Range(1, buyFromPrice.Get(0)));
		sellToPrice.Set(9, SRand.Range(1, buyFromPrice.Get(9)));
		sellToPrice.Set(12, SRand.Range(1, buyFromPrice.Get(12)));
		sellToPrice.Set(18, SRand.Range(1, buyFromPrice.Get(18)));
		sellToPrice.Set(11, SRand.Range(2, buyFromPrice.Get(11)));
		sellToPrice.Set(8, SRand.Range(3, buyFromPrice.Get(8)));
		sellToPrice.Set(10, SRand.Range(4, buyFromPrice.Get(10)));
		sellToPrice.Set(20, SRand.Range(4, buyFromPrice.Get(20)));
		sellToPrice.Set(1, SRand.Range(1, buyFromPrice.Get(1)));
		sellToPrice.Set(2, SRand.Range(1, buyFromPrice.Get(2)));
		sellToPrice.Set(14, SRand.Range(1, buyFromPrice.Get(14)));
		sellToPrice.Set(5, SRand.Range(1, buyFromPrice.Get(5)));
		sellToPrice.Set(15, SRand.Range(1, buyFromPrice.Get(15)));
		sellToPrice.Set(3, SRand.Range(1, buyFromPrice.Get(3)));
		sellToPrice.Set(16, SRand.Range(2, buyFromPrice.Get(16)));
		sellToPrice.Set(13, SRand.Range(3, buyFromPrice.Get(13)));
		sellToPrice.Set(19, SRand.Range(4, buyFromPrice.Get(19)));
		sellToPrice.Set(7, SRand.Range(5, buyFromPrice.Get(7)));
		sellToPrice.Set(6, SRand.Range(5, buyFromPrice.Get(6)));
		int num5 = SRand.Range(0, 100);
		specialUpgrade = Player.UpgradeType.None;
		if (num5 < 15)
		{
			List<Player.UpgradeType> list = new List<Player.UpgradeType>();
			for (int l = 1; l < 8; l++)
			{
				if (!dock.GetLandMassOwner().HasUpgrade((Player.UpgradeType)l) && l <= 6)
				{
					list.Add((Player.UpgradeType)l);
				}
			}
			if (list.Count > 0)
			{
				specialUpgrade = list[SRand.Range(0, list.Count)];
			}
		}
		isHoldVisualsDirty = true;
	}

	public ShipData GetShipData()
	{
		return new ShipData
		{
			status = status,
			dockID = dockID,
			hold = hold,
			waitTime = waitTimer,
			upgrade = specialUpgrade,
			sellToPrice = sellToPrice,
			buyFromPrice = buyFromPrice,
			soldItems = new SerializableDictionary<int, int>(itemsSold)
		};
	}

	public void SetFromShipData(ShipData data)
	{
		status = data.status;
		dockID = data.dockID;
		specialUpgrade = data.upgrade;
		waitTimer = data.waitTime;
		sellToPrice = data.sellToPrice;
		buyFromPrice = data.buyFromPrice;
		if (data.soldItems != null)
		{
			itemsSold.Clear();
			foreach (KeyValuePair<int, int> soldItem in data.soldItems)
			{
				itemsSold.Add(soldItem.Key, soldItem.Value);
			}
		}
		Init(-2);
		AddToHold(data.hold);
		if (status == Status.Leaving)
		{
			Leave();
			return;
		}
		Dock currentDock = GetCurrentDock();
		MoveTo(ShipBase.GetDockCell(this, currentDock.dockPositions, currentDock.dockPositionPenalties));
		isTargetPlayerDock = Player.inst.LandMassIsAPlayerLandMass(currentDock.GetComponent<Building>().LandMass());
	}

	public void AddToHold(ResourceAmount amt)
	{
		hold.Add(in amt);
		isHoldVisualsDirty = true;
	}

	public void RemoveFromHold(ResourceAmount amt)
	{
		hold.Subtract(in amt);
		isHoldVisualsDirty = true;
	}

	public Dock GetCurrentDock()
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(dockHash);
		for (int i = 0; i < buildingList.Count; i++)
		{
			if (buildingList.data[i].guid == dockID)
			{
				return buildingList.data[i].GetComponent<Dock>();
			}
		}
		return null;
	}

	private void Select()
	{
		GameUI.inst.ClearUIForClick();
		MerchantUI.inst.SelectMerchant(GetComponent<IMerchant>());
		SfxSystem.inst.PlayFromBank("MerchantBoatSelect", GetPos());
		GameUI.inst.ClearCellSelected();
	}

	private void OnClickedButton()
	{
		issueButton.gameObject.SetActive(value: false);
		Select();
		Cam.inst.SetDesiredTrackingPos(transform.position);
		if (Cam.inst.desiredDist > 15f)
		{
			Cam.inst.desiredDist = 15f;
		}
	}

	public void Leave()
	{
		Vector3 worldPos = new Vector3(1f, TerrainGen.waterHeightTestThresold, 1f);
		World.inst.GetRandomPositionOnEdge(ref worldPos);
		MoveTo(World.inst.GetCellData(worldPos));
		status = Status.Leaving;
		issueButton.gameObject.SetActive(value: false);
		if (isTargetPlayerDock)
		{
			GameUI.inst.merchantNotification.OnShipDeparture();
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		Dock currentDock = GetCurrentDock();
		if (status != Status.Leaving && (currentDock == null || !currentDock.GetComponent<Building>().IsOpen() || currentDock.disallowForeignMerchants))
		{
			MerchantUI.inst.SetVisibility(visible: false);
			Leave();
		}
		switch (status)
		{
		case Status.SailingToDock:
			if (arrived)
			{
				int num = currentDock.GetComponent<Building>().LandMass();
				if (isTargetPlayerDock)
				{
					issueButton.gameObject.SetActive(value: true);
					string text = ((World.inst.NumLandMasses == 1) ? "" : (Player.inst.LandMassNames[num] + ": "));
					NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "MerchantArrive" + num, new NotificationUI.NotificationMessage
					{
						single = text + LocalizationManager.GetTranslation("LogMerchantArrived")
					}, NotificationStatus.Neutral, -1f, this, title: false, num);
					RuntimeManager.PlayOneShot("event:/SFX ASITP/MerchantDock", GetPos());
					GameUI.inst.merchantNotification.OnShipArrival();
				}
				else
				{
					AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(num);
					if (kingdomByLandmass != null)
					{
						kingdomByLandmass.SellGoodsToForeignMerchant(this);
						kingdomByLandmass.BuyGoodsFromForeignMerchant(this, currentDock);
					}
				}
				status = Status.Waiting;
				waitTimer = 75f;
				MerchantOrdersManager.inst.DoAutomatedOrders(this, currentDock.bi.guid);
			}
			else if (pathFailed)
			{
				Leave();
			}
			break;
		case Status.Waiting:
			if (!MerchantUI.inst.IsVisible() || !isTargetPlayerDock)
			{
				if (waitTimer > 250f && waitTimer - dt <= 25f && isTargetPlayerDock && currentDock != null)
				{
					int num2 = currentDock.bi.LandMass();
					string text2 = ((World.inst.NumLandMasses == 1) ? "" : (Player.inst.LandMassNames[num2] + ": "));
					NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "MerchantDepart" + num2, new NotificationUI.NotificationMessage
					{
						single = text2 + LocalizationManager.GetTranslation("LogMerchantDeparting")
					}, NotificationStatus.Neutral, -1f, this, title: false, num2);
				}
				waitTimer -= dt;
				if (waitTimer < 0f)
				{
					Leave();
				}
			}
			break;
		case Status.Leaving:
			if (arrived)
			{
				status = Status.Done;
			}
			break;
		}
		if (isHoldVisualsDirty)
		{
			isHoldVisualsDirty = false;
			for (int i = 0; i < visualEntries.Length; i++)
			{
				Util.SetActive(visualEntries[i].obj, hold.Get(visualEntries[i].id) > 0);
			}
		}
		eAmb.set3DAttributes(transform.position.To3DAttributes());
	}

	public bool ExclusiveSelect()
	{
		return true;
	}

	public bool ValidToSelect()
	{
		return true;
	}

	public void SetHighlightImmediate(int colorIdx)
	{
		highlighter.SetOutlineImmediate(colorIdx);
	}

	public void OnSelected()
	{
		Select();
	}

	public bool InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		return false;
	}

	public int TeamID()
	{
		return teamID;
	}

	public ResourceAmount GetBuyFromPrice()
	{
		return buyFromPrice;
	}

	public ResourceAmount GetSellToPrice()
	{
		return sellToPrice;
	}

	public ResourceAmount GetHold()
	{
		return hold;
	}

	public Player.UpgradeType GetSpecialUpgrade()
	{
		return specialUpgrade;
	}

	public bool GetPathFailed()
	{
		return pathFailed;
	}

	public bool IsWaiting()
	{
		return status == Status.Waiting;
	}
}
