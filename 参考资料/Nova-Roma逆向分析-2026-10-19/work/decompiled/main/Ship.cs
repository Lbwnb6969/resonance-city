using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Ship : ShipBase, ISelectable, IMerchant, ILogisticTransport
{
	public enum LogisticsOrderType
	{
		Building,
		Position
	}

	[Serializable]
	public class LogisticsOrder
	{
		public ResourceAmount loadFromStart;

		private Guid endBuildingGuid;

		public SerializableVector3 endPosition;

		public LogisticsOrderType endType;

		public ResourceAmount unloadAtEnd = new ResourceAmount();

		[NonSerialized]
		private Building building;

		public float lastTransactionAmt;

		public int want;

		public Vector3 GetEnd()
		{
			if (endType != LogisticsOrderType.Position)
			{
				return Player.inst.GetBuilding(endBuildingGuid).Center();
			}
			return World.inst.GetCellData(endPosition).Center2D;
		}

		public void SetEnd(Vector3 p)
		{
			endPosition = p;
			endType = LogisticsOrderType.Position;
			building = null;
			endBuildingGuid = Guid.Empty;
		}

		public void SetEnd(Building b)
		{
			endBuildingGuid = b.guid;
			endType = LogisticsOrderType.Building;
			building = b;
		}

		internal Building GetBuilding()
		{
			if (building == null)
			{
				building = Player.inst.GetBuilding(endBuildingGuid);
			}
			return building;
		}
	}

	[Serializable]
	public class PortOrder
	{
		public Guid buildingGuid;

		public ResourceAmount toLoad;

		public ResourceAmount toUnload;
	}

	[Serializable]
	public new class ShipData
	{
		public List<PortOrder> orders = new List<PortOrder>();

		public int orderIdx;

		public ResourceAmount hold;

		public Behavior behavior;

		public bool paused;

		public string name = "";

		public List<LogisticsOrder> logisticsOrders = new List<LogisticsOrder>();

		public int logisticsIdx;

		public int routeEveryYears;

		public int routeCurrentYear;
	}

	public enum Behavior
	{
		Repeat,
		Stop
	}

	public Stockpile stockpile;

	private static List<Cell> visited = new List<Cell>();

	private static List<Cell> openSet = new List<Cell>();

	private static List<Cell> candidates = new List<Cell>();

	public List<LogisticsOrder> logisticsOrders = new List<LogisticsOrder>();

	public List<PortOrder> orders = new List<PortOrder>();

	public int orderIdx;

	public int logisticsIdx;

	public ResourceAmount hold;

	public Behavior behavior;

	public int routeEveryYears;

	public int routeCurrentYear;

	private bool paused;

	[NonSerialized]
	public string shipName = "";

	private EventHandler<SeasonEventData> seasonEventHandler;

	private bool isPlayerSetPaused;

	private float delayTimer = 5f;

	private Cell prevDockCell;

	[NonSerialized]
	public bool forceRepath;

	private bool firstUpdate = true;

	public MeshRenderer shipMesh;

	private static int dockHash = "dock".GetHashCode();

	public bool Paused => paused;

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
		GameUI.inst.ClearUIForClick();
		if (teamID == 0)
		{
			SfxSystem.inst.PlayFromBank("TransportShipSelect", GetPos());
		}
		else if (type == ShipType.PlayerMerchant)
		{
			MerchantUI.inst.SelectMerchant(GetComponent<IMerchant>());
			SfxSystem.inst.PlayFromBank("MerchantBoatSelect", GetPos());
		}
		GameUI.inst.ClearCellSelected();
	}

	public bool InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		return false;
	}

	public int TeamID()
	{
		return teamID;
	}

	private void Awake()
	{
		SetPause(p: true);
		seasonEventHandler = Broadcast.SeasonEvent.Listen(OnSeasonChange);
	}

	public bool ValidForOrder(Cell curr)
	{
		if (curr.Type == TerrainType.Water)
		{
			return curr.OccupyingStructure.Count == 0;
		}
		return false;
	}

	private void TryDefaultInitOrders()
	{
		if (logisticsOrders.Count > 0)
		{
			return;
		}
		Vector3 position = transform.position;
		Vector3 vector = transform.position + transform.right * 1f;
		float num = 0f;
		candidates.Clear();
		visited.Clear();
		openSet.Clear();
		openSet.Add(World.inst.GetCellDataClamped(position));
		while (openSet.Count > 0)
		{
			Cell cell = openSet[0];
			openSet.RemoveAt(0);
			if (ValidForOrder(cell) && !visited.Contains(cell))
			{
				float num2 = Mathff.DistSqrdXZ(cell.Center2D, position);
				if (ShipSystem.inst.GetShipsAt(cell.x, cell.z).Count > 0)
				{
					num2 *= 0.5f;
				}
				if (num2 <= 16f)
				{
					if (num2 > num)
					{
						num = num2;
						vector = cell.Center2D;
					}
					openSet.Add(World.inst.GetCellDataClamped(cell.x + 1, cell.z));
					openSet.Add(World.inst.GetCellDataClamped(cell.x - 1, cell.z));
					openSet.Add(World.inst.GetCellDataClamped(cell.x, cell.z + 1));
					openSet.Add(World.inst.GetCellDataClamped(cell.x, cell.z - 1));
					candidates.Add(cell);
				}
			}
			visited.Add(cell);
		}
		Vector3 vector2 = transform.position + transform.right * -1f;
		num = 0f;
		for (int i = 0; i < candidates.Count; i++)
		{
			Cell cell2 = candidates[i];
			if (cell2.Type == TerrainType.Water && cell2.OccupyingStructure.Count <= 0)
			{
				float num3 = Mathff.DistSqrdXZ(cell2.Center2D, vector);
				if (num < num3)
				{
					num = num3;
					vector2 = cell2.Center2D;
				}
			}
		}
		LogisticsOrder logisticsOrder = new LogisticsOrder();
		logisticsOrder.endPosition = vector;
		logisticsOrder.endType = LogisticsOrderType.Position;
		logisticsOrders.Add(logisticsOrder);
		logisticsOrder = new LogisticsOrder();
		logisticsOrder.endPosition = vector2;
		logisticsOrder.endType = LogisticsOrderType.Position;
		logisticsOrders.Add(logisticsOrder);
	}

	public static bool IsSellOrder(LogisticsOrder order, ShipBase ship)
	{
		Building building = order.GetBuilding();
		if (building != null)
		{
			bool flag = ship.teamID != building.TeamID();
			return (ship.type == ShipType.PlayerMerchant) & flag;
		}
		return false;
	}

	public ShipData GetShipData()
	{
		return new ShipData
		{
			orderIdx = orderIdx,
			orders = orders,
			hold = hold,
			behavior = behavior,
			paused = paused,
			name = shipName,
			logisticsOrders = logisticsOrders,
			logisticsIdx = logisticsIdx,
			routeEveryYears = routeEveryYears,
			routeCurrentYear = routeCurrentYear
		};
	}

	public void SetFromShipData(ShipData data)
	{
		paused = data.paused;
		behavior = data.behavior;
		orders = data.orders;
		orderIdx = data.orderIdx;
		hold = data.hold;
		shipName = data.name;
		logisticsIdx = data.logisticsIdx;
		logisticsOrders = data.logisticsOrders;
		routeEveryYears = data.routeEveryYears;
		routeCurrentYear = data.routeCurrentYear;
		if (logisticsOrders == null)
		{
			logisticsOrders = new List<LogisticsOrder>();
		}
		AddToHold(ref data.hold);
	}

	public void AddToHold(ref ResourceAmount amt)
	{
		stockpile.Deposit(ref amt);
	}

	public void RemoveFromHold(ResourceAmount amt)
	{
		hold -= amt;
		((IResourceStorage)stockpile).RemoveResources(amt);
	}

	private void OnSeasonChange(object sender, SeasonEventData seasonEvent)
	{
		if (routeEveryYears == 0 || !seasonEvent.SeasonDefinition.markNewYear)
		{
			return;
		}
		routeCurrentYear++;
		if (routeCurrentYear >= routeEveryYears)
		{
			if (Paused && !isPlayerSetPaused)
			{
				SetPause(p: false);
			}
			routeCurrentYear = 0;
		}
	}

	private void OnDestroy()
	{
		Broadcast.SeasonEvent.Unlisten(seasonEventHandler);
	}

	private void OnClickedButton()
	{
		if (teamID == 0)
		{
			GameUI.inst.shipLogisticsUI.SetSelectedTransport(this);
			GameUI.inst.shipLogisticsUI.SetVisible(v: true);
			SfxSystem.inst.PlayFromBank("TransportShipSelect", GetPos());
		}
		else if (type == ShipType.PlayerMerchant)
		{
			MerchantUI.inst.SelectMerchant(GetComponent<IMerchant>());
			SfxSystem.inst.PlayFromBank("MerchantBoatSelect", GetPos());
		}
		Cam.inst.SetDesiredTrackingPos(transform.position);
		if (Cam.inst.desiredDist > 15f)
		{
			Cam.inst.desiredDist = 15f;
		}
	}

	private LogisticsOrder GetCurrentOrder()
	{
		if (logisticsOrders.Count > 0)
		{
			logisticsIdx = Mathff.Clamp(logisticsIdx, 0, logisticsOrders.Count - 1);
			return logisticsOrders[logisticsIdx];
		}
		return null;
	}

	private void NextOrder()
	{
		logisticsIdx++;
		if (logisticsIdx >= logisticsOrders.Count)
		{
			logisticsIdx = 0;
			if (routeEveryYears != 0)
			{
				SetPause(p: true);
				return;
			}
		}
		MoveToOrder(GetCurrentOrder());
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (firstUpdate)
		{
			TryDefaultInitOrders();
			if (!paused)
			{
				MoveToOrder(GetCurrentOrder());
			}
			firstUpdate = false;
		}
		ValidateOrders();
		if (!paused)
		{
			if (forceRepath)
			{
				MoveToOrder(GetCurrentOrder());
				forceRepath = false;
			}
			if (logisticsOrders.Count > 0 && arrived)
			{
				if (GetCurrentOrder().endType == LogisticsOrderType.Position)
				{
					NextOrder();
				}
				else
				{
					LogisticsOrder currentOrder = GetCurrentOrder();
					Building building = currentOrder.GetBuilding();
					if (MerchantUI.inst.ship != this || building.TeamID() != 0)
					{
						delayTimer -= dt;
					}
					if (delayTimer < 0f)
					{
						delayTimer = 3f;
						if (building != null)
						{
							IResourceStorage loadingStorageComponent = building.GetComponent<Dock>().loadingStorageComponent;
							int maxHold = GetMaxHold();
							int num = 0;
							ResourceAmount unloadAtEnd = currentOrder.unloadAtEnd;
							ResourceAmount resourceAmount = new ResourceAmount();
							ResourceAmount resources = new ResourceAmount();
							for (int i = 0; i < unloadAtEnd.resources.Count; i++)
							{
								int resourceID = unloadAtEnd.resources[i].resourceID;
								int num2 = unloadAtEnd.Get(resourceID);
								if (num2 > 0)
								{
									int num3 = hold.Get(resourceID);
									int num4 = ((num3 < num2) ? num3 : num2);
									int num5 = num4;
									if (loadingStorageComponent.AcceptsType(resourceID))
									{
										int a = loadingStorageComponent.MaxStorageFor(resourceID) - loadingStorageComponent.StoredPublicResources(resourceID);
										num5 = Mathff.Max(0, Mathff.Min(a, num5));
										resources.Set(resourceID, num5);
										num5 = num4 - num5;
										resourceAmount.Set(resourceID, num5 + resources.Get(resourceID));
									}
									FreeResourceManager.inst.AddOrMakeAutoStackFor(resourceID, num5, loadingStorageComponent.DropOffLocation(resourceID));
								}
								num += hold.Get(resourceID) - resourceAmount.Get(resourceID);
							}
							ResourceStatistics.AddProduction(building.LandMass(), "trading", resourceAmount);
							RemoveFromHold(resourceAmount);
							loadingStorageComponent.Deposit(ref resources);
							if (IsSellOrder(currentOrder, this))
							{
								if (building.TeamID() != 0)
								{
									AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(building.LandMass());
									if (kingdomByLandmass != null)
									{
										kingdomByLandmass.GetTradeIntentionOfForeignTeamID(teamID).ConsiderBuyingFrom(currentOrder, this);
									}
								}
							}
							else
							{
								ResourceAmount resourceAmount2 = new ResourceAmount();
								for (int j = 0; j < currentOrder.loadFromStart.resources.Count; j++)
								{
									Resource resource = currentOrder.loadFromStart.resources[j];
									if (!loadingStorageComponent.AcceptsType(resource.resourceID))
									{
										continue;
									}
									int num6 = resource.Amount - hold.Get(resource.resourceID);
									if (num6 > 0 && num < maxHold)
									{
										num6 = ((loadingStorageComponent.StoredPublicResources(resource.resourceID) < num6) ? loadingStorageComponent.StoredPublicResources(resource.resourceID) : num6);
										if (num6 + num > maxHold)
										{
											num6 = maxHold - num;
											resourceAmount2.Set(resource.resourceID, num6);
											break;
										}
										num += num6;
										resourceAmount2.Set(resource.resourceID, num6);
									}
								}
								ResourceStatistics.AddProduction(building.LandMass(), "trading", resourceAmount2);
								AddToHold(resourceAmount2);
								loadingStorageComponent.RemoveResources(resourceAmount2);
							}
						}
						NextOrder();
					}
				}
			}
		}
		if (pathFailed && prevDockCell != null)
		{
			MoveToOrder(GetCurrentOrder(), prevDockCell);
		}
		if (logisticsOrders.Count == 0 || pathFailed)
		{
			issueButton.gameObject.SetActive(value: true);
		}
		if (logisticsOrders.Count > 0 && paused)
		{
			issueButton.gameObject.SetActive(value: true);
		}
		else
		{
			issueButton.gameObject.SetActive(value: false);
		}
		if (World.GetLandmassOwnerByTeamId(TeamID()).HasUpgrade(Player.UpgradeType.StrongerSails))
		{
			dynamics.accel = 4.66f;
		}
		else
		{
			dynamics.accel = 3f;
		}
	}

	private void MoveToOrder(LogisticsOrder currOrder, Cell failedCell = null)
	{
		if (currOrder == null)
		{
			return;
		}
		if (currOrder.endType == LogisticsOrderType.Building)
		{
			Building building = currOrder.GetBuilding();
			if (building.uniqueNameHash == dockHash)
			{
				Dock component = building.GetComponent<Dock>();
				prevDockCell = ShipBase.GetDockCell(this, component.dockPositions, component.dockPositionPenalties, failedCell);
				MoveTo(prevDockCell, displayPath: false);
			}
		}
		else
		{
			failedCell = null;
			MoveTo(World.inst.GetCellDataClamped(currOrder.GetEnd()), displayPath: false);
		}
	}

	public void ClearOrders()
	{
		logisticsOrders.Clear();
	}

	public void SetPause(bool p)
	{
		paused = p;
		if (paused)
		{
			arrived = true;
			return;
		}
		delayTimer = 0f;
		if (logisticsIdx >= logisticsOrders.Count)
		{
			logisticsIdx = 0;
		}
		MoveToOrder(GetCurrentOrder());
		forceRepath = true;
	}

	public Dock GetCurrentDock()
	{
		LogisticsOrder currentOrder = GetCurrentOrder();
		if (currentOrder != null && currentOrder.endType == LogisticsOrderType.Building)
		{
			return currentOrder.GetBuilding().GetComponent<Dock>();
		}
		return null;
	}

	public void AddToHold(ResourceAmount amt)
	{
		hold.Add(in amt);
		AddToHold(ref amt);
	}

	public ResourceAmount GetBuyFromPrice()
	{
		return GetCurrentOrder().unloadAtEnd;
	}

	public ResourceAmount GetSellToPrice()
	{
		return new ResourceAmount();
	}

	public ResourceAmount GetHold()
	{
		return hold;
	}

	public int GetMaxHold()
	{
		return 0;
	}

	public Player.UpgradeType GetSpecialUpgrade()
	{
		return Player.UpgradeType.None;
	}

	public bool GetPathFailed()
	{
		return pathFailed;
	}

	public bool IsWaiting()
	{
		if (arrived)
		{
			return delayTimer > 0f;
		}
		return false;
	}

	List<LogisticsOrder> ILogisticTransport.GetOrders()
	{
		return logisticsOrders;
	}

	string ILogisticTransport.GetErrorText()
	{
		if (type == ShipType.PlayerMerchant)
		{
			return "Use an envoy to open foreign docks for trading before a merchant can dock.";
		}
		if (type == ShipType.Transport)
		{
			return "Only merchants can dock at foreign ports.";
		}
		return "";
	}

	bool ILogisticTransport.isErrorVisible()
	{
		return ShipLogisticsUI.inst.cursorMode.currError != DockRouteCursorMode.Error.None;
	}

	bool ILogisticTransport.isPaused()
	{
		return Paused;
	}

	void ILogisticTransport.SetPaused(bool paused)
	{
		SetPause(paused);
		isPlayerSetPaused = paused;
	}

	Behavior ILogisticTransport.GetLogisiticBehavior()
	{
		return behavior;
	}

	void ILogisticTransport.SetLogisiticBehavior(Behavior behavior)
	{
		this.behavior = behavior;
	}

	void ILogisticTransport.SetMaxYear(int maxYear)
	{
		if (maxYear != routeEveryYears)
		{
			routeEveryYears = maxYear;
			routeCurrentYear = 0;
		}
	}

	int ILogisticTransport.GetMaxCycle()
	{
		return routeEveryYears;
	}

	string ILogisticTransport.GetTransportName()
	{
		if (string.IsNullOrEmpty(shipName))
		{
			if (type == ShipType.Transport)
			{
				return "ScriptLocalization.Building_transportship_FriendlyName";
			}
			if (type == ShipType.PlayerMerchant)
			{
				return ScriptLocalization.MerchantShip;
			}
			return "";
		}
		return shipName;
	}

	void ILogisticTransport.SetTransportName(string name)
	{
		shipName = name;
	}

	string ILogisticTransport.GetDescription()
	{
		return "ShipUIDescription";
	}

	void ILogisticTransport.SetOutlineImmediate(int i)
	{
		highlighter.SetOutlineImmediate(i);
	}

	bool ILogisticTransport.ValidForDocking(Building b)
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
		if (type == ShipType.Transport)
		{
			return landmassOwner == Player.inst.PlayerLandmassOwner;
		}
		if (type == ShipType.PlayerMerchant)
		{
			bool flag = Player.inst.DocksOpen(Player.inst.PlayerLandmassOwner, landmassOwner);
			return (landmassOwner == Player.inst.PlayerLandmassOwner) | flag;
		}
		return false;
	}

	public void ValidateOrders()
	{
		for (int i = 0; i < logisticsOrders.Count; i++)
		{
			LogisticsOrder logisticsOrder = logisticsOrders[i];
			if (logisticsOrder.endType == LogisticsOrderType.Building && logisticsOrder.GetBuilding() == null)
			{
				logisticsOrder.endType = LogisticsOrderType.Position;
				moveTarget = World.inst.GetCellDataClamped(logisticsOrder.endPosition);
			}
		}
	}
}
