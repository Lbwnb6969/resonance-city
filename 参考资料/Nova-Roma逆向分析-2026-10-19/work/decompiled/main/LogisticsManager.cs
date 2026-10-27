using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets.Interface;
using UnityEngine;

public class LogisticsManager : MonoBehaviour
{
	public class LogisticsForStorage
	{
		public Dictionary<int, bool> isActive;

		public Dictionary<int, int> requestAmt;

		public Building targetBuilding;

		public List<Building> sourceBuildings = new List<Building>();

		public bool HasRequest()
		{
			foreach (KeyValuePair<int, int> item in requestAmt)
			{
				if (item.Value > 0)
				{
					return true;
				}
			}
			return false;
		}
	}

	[Serializable]
	public class LogisticsManagerSaveData : SaveClass<LogisticsManager, LogisticsManagerSaveData>
	{
		[Serializable]
		public class LogisticsForStorageData
		{
			public SerializableDictionary<int, int> requestAmt;

			public Guid targetBuildingGuid;

			public Guid[] sourceBuildingGuids;
		}

		[Serializable]
		public class CartData
		{
			public SerializableVector3 pos;

			public SerializableQuaternion rot;

			public LogisticsVehicle.LogisticsVehicleSaveData vehicleSaveData;
		}

		private LogisticsForStorageData[] data;

		public CartData[] carts;

		public override LogisticsManagerSaveData Pack(LogisticsManager d)
		{
			int num = 0;
			data = new LogisticsForStorageData[d.logistics.Count];
			foreach (KeyValuePair<Guid, LogisticsForStorage> logistic in d.logistics)
			{
				LogisticsForStorageData logisticsForStorageData = new LogisticsForStorageData();
				logisticsForStorageData.requestAmt = new SerializableDictionary<int, int>(logistic.Value.requestAmt);
				logisticsForStorageData.targetBuildingGuid = logistic.Value.targetBuilding.guid;
				logisticsForStorageData.sourceBuildingGuids = new Guid[logistic.Value.sourceBuildings.Count];
				for (int i = 0; i < logistic.Value.sourceBuildings.Count; i++)
				{
					logisticsForStorageData.sourceBuildingGuids[i] = logistic.Value.sourceBuildings[i].guid;
				}
				data[num++] = logisticsForStorageData;
			}
			carts = new CartData[d.logisticCarts.Count];
			for (int j = 0; j < d.logisticCarts.Count; j++)
			{
				LogisticCart logisticCart = d.logisticCarts.data[j];
				carts[j] = new CartData();
				carts[j].pos = logisticCart.transform.position;
				carts[j].rot = logisticCart.transform.rotation;
				carts[j].vehicleSaveData = new LogisticsVehicle.LogisticsVehicleSaveData().Pack(logisticCart.vehicle);
			}
			return this;
		}

		public override LogisticsManager Unpack(LogisticsManager d)
		{
			if (data != null)
			{
				for (int i = 0; i < data.Length; i++)
				{
					LogisticsForStorage logisticsForStorage = new LogisticsForStorage();
					logisticsForStorage.requestAmt = data[i].requestAmt;
					logisticsForStorage.targetBuilding = Player.inst.GetBuilding(data[i].targetBuildingGuid);
					if (logisticsForStorage.targetBuilding == null)
					{
						continue;
					}
					for (int j = 0; j < data[i].sourceBuildingGuids.Length; j++)
					{
						Building building = Player.inst.GetBuilding(data[i].sourceBuildingGuids[j]);
						if (building != null)
						{
							logisticsForStorage.sourceBuildings.Add(building);
						}
					}
					d.logistics.Add(logisticsForStorage.targetBuilding.guid, logisticsForStorage);
				}
			}
			if (carts != null)
			{
				for (int k = 0; k < carts.Length; k++)
				{
					CartData cartData = carts[k];
					LogisticCart logisticCart = UnityEngine.Object.Instantiate(d.cartPrefab, cartData.pos, cartData.rot, d.cartContainerT);
					cartData.vehicleSaveData.Unpack(logisticCart.vehicle);
				}
			}
			return d;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
		}
	}

	public static LogisticsManager inst;

	public static List<LogisticsVehicle> vehicles = new List<LogisticsVehicle>(512);

	public LogisticCart cartPrefab;

	private Transform cartContainerT;

	public LogisticArrow cartActiveRouteArrow;

	public Dictionary<Guid, LogisticsForStorage> logistics = new Dictionary<Guid, LogisticsForStorage>();

	public ArrayExt<LogisticCart> logisticCarts = new ArrayExt<LogisticCart>(128);

	public Color unassignedRouteColor = new Color(0f, 1f, 0f, 0.2f);

	public Color assignedRouteColor = new Color(0f, 1f, 0f, 0.2f);

	public Color activeRouteColor = new Color(0f, 1f, 0f, 0.2f);

	public Color disabledRouteColor = new Color(0.5f, 0.5f, 0.5f, 0.2f);

	private List<LogisticCart> deferredRemoval = new List<LogisticCart>();

	private EventHandler<OnBuildingAddRemove> eventHandler;

	public Dictionary<Building, LogisticsRouteCanvasUI> logisticBtns = new Dictionary<Building, LogisticsRouteCanvasUI>(128);

	private ArrayExtRef<Building> scratchToRemove = new ArrayExtRef<Building>(32);

	public bool AnyRoutesOnLandmass(int lm)
	{
		foreach (KeyValuePair<Guid, LogisticsForStorage> logistic in logistics)
		{
			if (logistic.Value.targetBuilding.LandMass() == lm && logistic.Value.sourceBuildings.Count > 0)
			{
				return true;
			}
		}
		return false;
	}

	public bool AnyRoutesBetweenDocks(int lm)
	{
		foreach (KeyValuePair<Guid, LogisticsForStorage> logistic in logistics)
		{
			if (logistic.Value.targetBuilding.uniqueNameHash == World.dockHash)
			{
				for (int i = 0; i < logistic.Value.sourceBuildings.Count; i++)
				{
					if (logistic.Value.sourceBuildings[i].uniqueNameHash == World.dockHash)
					{
						return true;
					}
				}
			}
			if (logistic.Value.targetBuilding.uniqueNameHash != World.transportShipPortHash)
			{
				continue;
			}
			for (int j = 0; j < logistic.Value.sourceBuildings.Count; j++)
			{
				if (logistic.Value.sourceBuildings[j].uniqueNameHash == World.transportShipPortHash)
				{
					return true;
				}
			}
		}
		return false;
	}

	public static bool ValidSourceBuildingForVehicle(LogisticsVehicle vehicle, int landmass, Building source)
	{
		if (!vehicle.isShip || !TransportShip.IsValidShipLogisticBuilding(source))
		{
			if (!vehicle.isShip)
			{
				return source.LandMass() == landmass;
			}
			return false;
		}
		return true;
	}

	private void Awake()
	{
		inst = this;
		LogisticArrow.Setup();
		LogisticsRouteCanvasUI.Setup();
		cartPrefab = Resources.Load<LogisticCart>("LogisticCart");
		cartContainerT = new GameObject().transform;
		cartContainerT.name = "Logistic Cart Container";
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.added)
		{
			return;
		}
		Guid guid = obj.targetBuilding.guid;
		logistics.Remove(guid);
		foreach (KeyValuePair<Guid, LogisticsForStorage> logistic in logistics)
		{
			for (int i = 0; i < logistic.Value.sourceBuildings.Count; i++)
			{
				if (logistic.Value.sourceBuildings[i].guid == guid)
				{
					logistic.Value.sourceBuildings.RemoveAt(i);
					break;
				}
			}
		}
		for (int j = 0; j < logisticCarts.Count; j++)
		{
			logisticCarts.data[j].GetComponent<LogisticsVehicle>().TryRemoveRoutes(obj.targetBuilding);
		}
		for (int k = 0; k < ShipSystem.inst.ships.Count; k++)
		{
			ShipBase shipBase = ShipSystem.inst.ships.data[k];
			if (shipBase.type == ShipBase.ShipType.Transport)
			{
				shipBase.GetComponent<LogisticsVehicle>().TryRemoveRoutes(obj.targetBuilding);
			}
		}
	}

	public void Reset()
	{
		if (eventHandler != null)
		{
			Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
		}
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		logistics.Clear();
		for (int i = 0; i < logisticCarts.Count; i++)
		{
			deferredRemoval.Add(logisticCarts.data[i]);
		}
		logisticCarts.Clear();
		for (int j = 0; j < deferredRemoval.Count; j++)
		{
			UnityEngine.Object.Destroy(deferredRemoval[j].gameObject);
		}
		deferredRemoval.Clear();
	}

	private void LateUpdate()
	{
		for (int i = 0; i < LogisticArrow.deferShutdown.Count; i++)
		{
			LogisticArrow.deferShutdown.data[i].Shutdown();
		}
		LogisticArrow.deferShutdown.Clear();
	}

	public LogisticsVehicle GetLogisticVehicleByGuid(Guid targetGuid)
	{
		for (int i = 0; i < logisticCarts.Count; i++)
		{
			LogisticsVehicle component = logisticCarts.data[i].GetComponent<LogisticsVehicle>();
			if (component.guid == targetGuid)
			{
				return component;
			}
		}
		for (int j = 0; j < ShipSystem.inst.ships.Count; j++)
		{
			ShipBase shipBase = ShipSystem.inst.ships.data[j];
			if (shipBase.type == ShipBase.ShipType.Transport)
			{
				LogisticsVehicle component2 = shipBase.GetComponent<LogisticsVehicle>();
				if (component2.guid == targetGuid)
				{
					return component2;
				}
			}
		}
		return null;
	}

	public LogisticsForStorage GetLogisticsForBuilding(Building b)
	{
		if (b == null)
		{
			return null;
		}
		LogisticsForStorage value = null;
		if (logistics.TryGetValue(b.guid, out value))
		{
			return value;
		}
		value = new LogisticsForStorage
		{
			requestAmt = new Dictionary<int, int>(),
			isActive = new Dictionary<int, bool>(),
			targetBuilding = b
		};
		IResourceStorage component = b.GetComponent<IResourceStorage>();
		if (component != null)
		{
			int num = 0;
			List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
			for (int i = 0; i < resourceDefs.Count; i++)
			{
				if (component.AcceptsType(resourceDefs[i].ID))
				{
					num++;
				}
			}
			int num2 = 25;
			int num3 = 250;
			if (component is Stockpile stockpile)
			{
				num3 = stockpile.maxStackCount * stockpile.resourceGrid.Length;
				num2 = stockpile.maxStackCount;
			}
			for (int j = 0; j < resourceDefs.Count; j++)
			{
				if (component.AcceptsType(resourceDefs[j].ID))
				{
					int a = num3 / num / num2 * num2;
					value.requestAmt.Add(resourceDefs[j].ID, Mathff.Max(a, num2));
				}
			}
			logistics.Add(b.guid, value);
		}
		return value;
	}

	public bool TryAddSourceToLogistic(LogisticsForStorage tLogistic, Building newSource)
	{
		if (tLogistic.sourceBuildings.Contains(newSource))
		{
			return false;
		}
		tLogistic.sourceBuildings.Add(newSource);
		UpdateLogisticVehicleRoutes(tLogistic.targetBuilding, newSource, isAdding: true);
		return true;
	}

	public void RemoveSourceFromBuilding(Building b, int idx)
	{
		LogisticsForStorage logisticsForBuilding = GetLogisticsForBuilding(b);
		Building sourceBuilding = logisticsForBuilding.sourceBuildings[idx];
		for (int i = 0; i < logisticCarts.Count; i++)
		{
			LogisticsVehicle vehicle = logisticCarts.data[i].vehicle;
			if (vehicle.HasRouteFor(b, sourceBuilding, out var idx2))
			{
				vehicle.RemoveRoute(idx2);
			}
		}
		Building source = logisticsForBuilding.sourceBuildings[idx];
		logisticsForBuilding.sourceBuildings.RemoveAt(idx);
		UpdateLogisticVehicleRoutes(logisticsForBuilding.targetBuilding, source, isAdding: false);
	}

	private void UpdateLogisticVehicleRoutes(Building target, Building source, bool isAdding)
	{
		for (int i = 0; i < vehicles.Count; i++)
		{
			LogisticsVehicle logisticsVehicle = vehicles[i];
			for (int j = 0; j < logisticsVehicle.routes.Count; j++)
			{
				if (!(logisticsVehicle.routes[j].targetBuilding != target))
				{
					int idx;
					if (isAdding)
					{
						logisticsVehicle.TryAddRoute(target, source);
					}
					else if (logisticsVehicle.HasRouteFor(target, source, out idx))
					{
						logisticsVehicle.RemoveRoute(idx);
					}
					break;
				}
			}
		}
	}

	private void Update()
	{
	}

	public void AnimateArrowsForAllLogistics()
	{
		foreach (KeyValuePair<Guid, LogisticsForStorage> logistic in logistics)
		{
			TryAnimateArrowsForLogistic(logistic.Value);
		}
	}

	public void TryAnimateArrowsForLogisticVehicle(LogisticsVehicle vehicle)
	{
		List<LogisticRoute> routes = vehicle.routes;
		for (int i = 0; i < routes.Count; i++)
		{
			LogisticsForStorage logisticsForBuilding = GetLogisticsForBuilding(routes[i].targetBuilding);
			for (int j = 0; j < logisticsForBuilding.sourceBuildings.Count; j++)
			{
				LogisticArrow.GetLogisticArrow(logisticsForBuilding.targetBuilding, logisticsForBuilding.sourceBuildings[j]);
			}
		}
	}

	public void TryAnimateArrowsForLogistic(LogisticsForStorage logistic)
	{
		if (logistic != null)
		{
			for (int i = 0; i < logistic.sourceBuildings.Count; i++)
			{
				LogisticArrow.GetLogisticArrow(logistic.targetBuilding, logistic.sourceBuildings[i]);
			}
		}
	}

	public void AnimateArrows(LogisticsForStorage logistic)
	{
		if (logistic == null)
		{
			return;
		}
		for (int num = LogisticArrow.active.Count - 1; num >= 0; num--)
		{
			LogisticArrow logisticArrow = LogisticArrow.active.data[num];
			int num2 = 0;
			while (true)
			{
				if (num2 < logistic.sourceBuildings.Count)
				{
					if (!(logisticArrow.targetBuilding != logistic.targetBuilding) && !(logisticArrow.sourceBuilding != logistic.sourceBuildings[num2]))
					{
						break;
					}
					num2++;
					continue;
				}
				logisticArrow.Shutdown();
				break;
			}
		}
		for (int i = 0; i < logistic.sourceBuildings.Count; i++)
		{
			Building building = logistic.sourceBuildings[i];
			int num3 = 0;
			while (true)
			{
				if (num3 < LogisticArrow.active.Count)
				{
					LogisticArrow logisticArrow2 = LogisticArrow.active.data[num3];
					if (logisticArrow2.targetBuilding == logistic.targetBuilding && logisticArrow2.sourceBuilding == building)
					{
						break;
					}
					num3++;
					continue;
				}
				LogisticArrow.GetLogisticArrow(logistic.targetBuilding, building);
				break;
			}
		}
	}

	public void UpdateButtonVisbilityForArrows(bool isVisible, LogisticsVehicle vehicle)
	{
		if (!isVisible || vehicle == null)
		{
			foreach (KeyValuePair<Building, LogisticsRouteCanvasUI> logisticBtn in logisticBtns)
			{
				logisticBtn.Value.Shutdown();
			}
			logisticBtns.Clear();
			return;
		}
		foreach (KeyValuePair<Building, LogisticsRouteCanvasUI> logisticBtn2 in logisticBtns)
		{
			bool flag = false;
			foreach (KeyValuePair<Guid, LogisticsForStorage> logistic in logistics)
			{
				if (logistic.Value.targetBuilding == logisticBtn2.Key)
				{
					flag = true;
					break;
				}
			}
			if (!flag)
			{
				scratchToRemove.Add(logisticBtn2.Key);
			}
		}
		for (int i = 0; i < scratchToRemove.Count; i++)
		{
			Building key = scratchToRemove.data[i];
			logisticBtns[key].Shutdown();
			logisticBtns.Remove(key);
		}
		scratchToRemove.ClearFast();
		foreach (KeyValuePair<Guid, LogisticsForStorage> logistic2 in logistics)
		{
			if (logistic2.Value.sourceBuildings.Count <= 0)
			{
				continue;
			}
			bool flag2 = false;
			for (int j = 0; j < logistic2.Value.sourceBuildings.Count; j++)
			{
				if (!logisticBtns.TryGetValue(logistic2.Value.targetBuilding, out var value))
				{
					if ((!vehicle.isShip && logistic2.Value.targetBuilding.LandMass() != logistic2.Value.sourceBuildings[j].LandMass()) || (vehicle.isShip && (logistic2.Value.targetBuilding.uniqueNameHash != World.dockHash || logistic2.Value.sourceBuildings[j].uniqueNameHash != World.dockHash)))
					{
						continue;
					}
					value = LogisticsRouteCanvasUI.GetLogisticButtonForBuilding(logistic2.Value.targetBuilding);
					logisticBtns.Add(logistic2.Value.targetBuilding, value);
				}
				int idx;
				if (vehicle.TryGetCurrentRoute(out var logisticRoute) && logisticRoute.sourceBuilding == logistic2.Value.sourceBuildings[j] && logisticRoute.targetBuilding == logistic2.Value.targetBuilding)
				{
					flag2 = true;
				}
				else if (vehicle.HasRouteFor(logistic2.Value.targetBuilding, logistic2.Value.sourceBuildings[j], out idx))
				{
					flag2 = true;
				}
				Util.SetActive(value.addBtn.gameObject, !flag2);
				Util.SetActive(value.removeBtn.gameObject, flag2);
			}
		}
	}
}
