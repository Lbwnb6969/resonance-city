using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Interface;
using UnityEngine;

public class MerchantOrdersManager : MonoBehaviour
{
	[Serializable]
	public class OrderEntry
	{
		public const int TYPE_BUY = 0;

		public const int TYPE_SELL = 1;

		public int type;

		public int resourceID;

		public int amount;
	}

	[Serializable]
	public class MerchantOrdersManagerSaveData : SaveClass<MerchantOrdersManager, MerchantOrdersManagerSaveData>
	{
		public SerializableDictionary<SerializableGuid, OrderEntry[]> orders = new SerializableDictionary<SerializableGuid, OrderEntry[]>();

		public override MerchantOrdersManagerSaveData Pack(MerchantOrdersManager obj)
		{
			foreach (KeyValuePair<Guid, ArrayExt<OrderEntry>> order in obj.orders)
			{
				OrderEntry[] array = new OrderEntry[order.Value.Count];
				Array.Copy(order.Value.data, 0, array, 0, order.Value.Count);
				orders.Add(order.Key, array);
			}
			return this;
		}

		public override MerchantOrdersManager Unpack(MerchantOrdersManager obj)
		{
			obj.orders.Clear();
			foreach (KeyValuePair<SerializableGuid, OrderEntry[]> order in orders)
			{
				ArrayExt<OrderEntry> arrayExt = new ArrayExt<OrderEntry>(32);
				for (int i = 0; i < order.Value.Length; i++)
				{
					arrayExt.Add(order.Value[i]);
				}
				obj.orders.Add(order.Key, arrayExt);
			}
			return obj;
		}
	}

	public static MerchantOrdersManager inst;

	public Dictionary<Guid, ArrayExt<OrderEntry>> orders = new Dictionary<Guid, ArrayExt<OrderEntry>>();

	private void Awake()
	{
		inst = this;
	}

	public void Reset()
	{
		orders.Clear();
	}

	public OrderEntry AddNewOrder(Guid guid)
	{
		OrderEntry orderEntry = new OrderEntry();
		if (!orders.ContainsKey(guid))
		{
			orders.Add(guid, new ArrayExt<OrderEntry>(32));
		}
		orders[guid].Add(orderEntry);
		return orderEntry;
	}

	public OrderEntry GetOrderEntry(Guid guid, int orderIdx)
	{
		return orders[guid].data[orderIdx];
	}

	public void RemoveOrderEntry(Guid guid, int orderIdx)
	{
		orders[guid].RemoveAt(orderIdx);
	}

	public void DoAutomatedOrders(IMerchant merchant, Guid dGuid)
	{
		if (!orders.TryGetValue(dGuid, out var value))
		{
			return;
		}
		Dock currentDock = merchant.GetCurrentDock();
		Vector3 pos = currentDock.bi.Center();
		int landmass = currentDock.bi.LandMass();
		ResourceAmount resourceAmount = new ResourceAmount();
		ResourceAmount hold = merchant.GetHold();
		IResourceStorage loadingStorageComponent = currentDock.loadingStorageComponent;
		ResourceAmount buyFromPrice = merchant.GetBuyFromPrice();
		ResourceAmount sellToPrice = merchant.GetSellToPrice();
		LandmassOwner landMassOwner = currentDock.bi.GetLandMassOwner();
		for (int i = 0; i < value.Count; i++)
		{
			OrderEntry orderEntry = value.data[i];
			int num = loadingStorageComponent.StoredPublicResources(orderEntry.resourceID);
			if (orderEntry.type == 0)
			{
				if (num < orderEntry.amount)
				{
					int num2 = buyFromPrice.Get(orderEntry.resourceID);
					int num3 = Mathff.Min(landMassOwner.Gold / num2, orderEntry.amount - num);
					landMassOwner.Gold -= num2 * num3;
					ResourceStatistics.AddConsumption(landmass, "trading", 4, num2 * num3);
					ResourceStatistics.AddProduction(landmass, "trading", orderEntry.resourceID, orderEntry.amount);
					do
					{
						int num4 = Mathff.Min(num3, 30);
						num3 -= num4;
						FreeResourceManager.inst.AddOrMakeAutoStackFor(orderEntry.resourceID, num4, pos);
					}
					while (num3 > 0);
				}
			}
			else if (orderEntry.type == 1 && num > orderEntry.amount)
			{
				int num5 = num - orderEntry.amount;
				landMassOwner.Gold += num5 * sellToPrice.Get(orderEntry.resourceID);
				hold.Add(orderEntry.resourceID, num5);
				ResourceStatistics.AddProduction(landmass, "trading", 4, num5 * sellToPrice.Get(orderEntry.resourceID));
				ResourceStatistics.AddConsumption(landmass, "trading", orderEntry.resourceID, num5);
				resourceAmount.Clear();
				resourceAmount.Add(orderEntry.resourceID, num5);
				loadingStorageComponent.RemoveResources(resourceAmount);
			}
		}
	}
}
