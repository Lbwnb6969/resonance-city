using System;
using System.Collections;
using System.Collections.Generic;
using Assets.Code;
using Assets.Interface;
using UnityEngine;

public class LogisticsVehicle : Tickable
{
	public enum Error
	{
		None,
		AlreadyFulfilled,
		NoResourcesAtSupplier,
		NoRoomAtDestination,
		Valid,
		BuildingNotBuilt
	}

	public delegate void requestPath(Vector3 pos);

	[Serializable]
	public class LogisticsVehicleSaveData : SaveClass<LogisticsVehicle, LogisticsVehicleSaveData>
	{
		[Serializable]
		public class RouteData
		{
			public Guid target;

			public Guid source;
		}

		public Guid guid;

		public int routeIdx;

		public int status;

		public ResourceAmount stored;

		public RouteData[] routes;

		public override LogisticsVehicleSaveData Pack(LogisticsVehicle obj)
		{
			guid = obj.guid;
			routeIdx = obj.routeIdx;
			status = obj.GetStatus();
			stored = obj.currStorage;
			routes = new RouteData[obj.routes.Count];
			for (int i = 0; i < obj.routes.Count; i++)
			{
				routes[i] = new RouteData();
				routes[i].source = obj.routes[i].sourceBuilding.guid;
				routes[i].target = obj.routes[i].targetBuilding.guid;
			}
			return this;
		}

		public override LogisticsVehicle Unpack(LogisticsVehicle obj)
		{
			obj.guid = ((guid == Guid.Empty) ? Guid.NewGuid() : guid);
			obj.routeIdx = routeIdx;
			if (stored != null)
			{
				obj.currStorage = stored;
			}
			obj.RefreshVisualStorage();
			for (int i = 0; i < routes.Length; i++)
			{
				obj.AddRoute(Player.inst.GetBuilding(routes[i].target), Player.inst.GetBuilding(routes[i].source));
			}
			obj.SetStatus(status);
			return obj;
		}
	}

	public Guid guid;

	public string titleTerm;

	internal ResourceAmount currStorage = new ResourceAmount();

	public bool isShip;

	private int status;

	public const int STATUS_PAUSED = -1;

	public const int STATUS_IDLE = 0;

	public const int STATUS_CHECK_STORAGE = 1;

	public const int STATUS_HEAD_TO_PICKUP = 2;

	public const int STATUS_PICKUP = 3;

	public const int STATUS_HEAD_TO_DROPOFF = 4;

	public const int STATUS_DROPOFF = 5;

	public List<LogisticRoute> routes = new List<LogisticRoute>();

	internal int routeIdx = -1;

	private int maxStorage = 50;

	internal Error lastError;

	private Dictionary<int, GraphicalResourceStack> stacks = new Dictionary<int, GraphicalResourceStack>();

	public GameObject transportCartStackPrefab;

	public bool isDeferDroppingStorage;

	public requestPath RequestPathTo;

	public int GetStatus()
	{
		return status;
	}

	private void Awake()
	{
		guid = Guid.NewGuid();
	}

	private void Start()
	{
		maxStorage = transportCartStackPrefab.GetComponent<GraphicalResourceStack>().maxStackCount;
	}

	public bool TryGetCurrentRoute(out LogisticRoute logisticRoute)
	{
		logisticRoute = default;
		if (routeIdx == -1)
		{
			return false;
		}
		logisticRoute = routes[routeIdx];
		return true;
	}

	public void SetRouteIndex(int idx, bool doStatusChange = true)
	{
		if (idx != routeIdx)
		{
			routeIdx = ((idx == -1) ? (-1) : (idx % routes.Count));
			DropStorage();
			if (doStatusChange)
			{
				SetStatus((routeIdx != -1) ? 1 : 0);
			}
		}
	}

	public void NextRoute()
	{
		SetRouteIndex(routeIdx + 1);
	}

	public bool TryAddRoute(Building storageB, Building sourceB)
	{
		if (HasRouteFor(storageB, sourceB, out var _) || !LogisticsManager.ValidSourceBuildingForVehicle(this, storageB.LandMass(), sourceB))
		{
			return false;
		}
		AddRoute(storageB, sourceB);
		return true;
	}

	public void AddRoute(Building storageB, Building sourceB)
	{
		if (storageB == null || sourceB == null || storageB == sourceB)
		{
			Debug.LogError("Add Route Has Bad Data!");
			return;
		}
		routes.Add(new LogisticRoute
		{
			targetBuilding = storageB,
			sourceBuilding = sourceB
		});
	}

	public bool TryRemoveRoute(Building storageB, Building sourceB)
	{
		if (!HasRouteFor(storageB, sourceB, out var num))
		{
			return false;
		}
		RemoveRoute(num);
		return true;
	}

	public bool TryRemoveRoutes(Building storage)
	{
		for (int i = 0; i < routes.Count; i++)
		{
			if (routes[i].targetBuilding == storage || routes[i].sourceBuilding == storage)
			{
				RemoveRoute(i);
				i--;
			}
		}
		return true;
	}

	public void RemoveRoute(int idx)
	{
		routes.RemoveAt(idx);
		if (idx == routeIdx)
		{
			SetRouteIndex((idx == 0) ? (-1) : (routeIdx % routes.Count));
		}
		else if (idx < routeIdx)
		{
			SetRouteIndex(Mathff.Min(-1, routeIdx - 1));
		}
	}

	public bool HasRouteFor(Building storageBuilding, Building sourceBuilding, out int idx)
	{
		idx = -1;
		for (int i = 0; i < routes.Count; i++)
		{
			if (routes[i].targetBuilding == storageBuilding && routes[i].sourceBuilding == sourceBuilding)
			{
				idx = i;
				return true;
			}
		}
		return false;
	}

	public bool HasRouteFor(Building storageBuilding)
	{
		for (int i = 0; i < routes.Count; i++)
		{
			if (routes[i].targetBuilding == storageBuilding)
			{
				return true;
			}
		}
		return false;
	}

	private Vector3 GetEdgePos(Building b)
	{
		float magnitude = b.size.xz().magnitude;
		Vector3 vector = (transform.position - b.Center()).xz();
		vector.Normalize();
		return b.Center() + vector * magnitude * 0.5f;
	}

	public void SetStatus(int s)
	{
		status = s;
		switch (s)
		{
		case 2:
			RequestPathTo(GetEdgePos(routes[routeIdx].sourceBuilding));
			break;
		case 4:
			RequestPathTo(GetEdgePos(routes[routeIdx].targetBuilding));
			break;
		}
	}

	private IEnumerable<(int, int, IResourceStorage)> InternalCollection(LogisticRoute route)
	{
		lastError = Error.None;
		IResourceStorage targetStorage = route.targetBuilding.GetComponent<IResourceStorage>();
		LogisticsManager.LogisticsForStorage targetLogistic = LogisticsManager.inst.GetLogisticsForBuilding(route.targetBuilding);
		IResourceStorage sourceStorage = route.sourceBuilding.GetComponent<IResourceStorage>();
		if (route.targetBuilding.GetComponent<Stockpile>() != null)
		{
			LogisticsManager.inst.GetLogisticsForBuilding(route.sourceBuilding);
		}
		if (route.targetBuilding.IsBuilt() && route.sourceBuilding.IsBuilt())
		{
			List<FreeResourceSystem.ResourceDef> rDefs = FreeResourceSystem.inst.resourceDefs;
			for (int i = 0; i < rDefs.Count; i++)
			{
				FreeResourceSystem.ResourceDef resourceDef = rDefs[i];
				if (!targetStorage.AcceptsType(resourceDef.ID) || !targetLogistic.requestAmt.TryGetValue(resourceDef.ID, out var value) || value <= 0 || !sourceStorage.StoresTypePublic(resourceDef.ID))
				{
					continue;
				}
				int num = targetStorage.SpaceAvailable(resourceDef.ID);
				int num2 = targetStorage.StoredPublicResources(resourceDef.ID);
				int num3 = targetLogistic.requestAmt[resourceDef.ID];
				if (num2 >= num3 && lastError != Error.Valid)
				{
					lastError = Error.AlreadyFulfilled;
					continue;
				}
				int num4 = sourceStorage.StoredPublicResources(resourceDef.ID);
				int b = Mathff.Min(Mathff.Max(0, num3 - num2), Mathff.Min(num, num4));
				b = Mathff.Min(Mathff.Max(0, maxStorage - currStorage.Get(resourceDef.ID)), b);
				if (currStorage.Get(resourceDef.ID) + b > 0)
				{
					lastError = Error.Valid;
					yield return (resourceDef.ID, b, sourceStorage);
				}
				else if (lastError != Error.Valid)
				{
					if (num4 <= 0)
					{
						lastError = Error.NoResourcesAtSupplier;
					}
					else if (num <= 0)
					{
						lastError = Error.NoRoomAtDestination;
					}
				}
			}
		}
		else
		{
			lastError = Error.BuildingNotBuilt;
		}
	}

	public bool GetCollectionForRoute(LogisticRoute route)
	{
		IEnumerator enumerator = InternalCollection(route).GetEnumerator();
		bool result = false;
		while (enumerator.MoveNext())
		{
			(int, int, IResourceStorage) tuple = ((int, int, IResourceStorage))enumerator.Current;
			if (isShip)
			{
				ResourceStatistics.AddConsumption(tuple.Item3.LandMass(), "shipping", tuple.Item1, tuple.Item2);
			}
			currStorage.Add(tuple.Item1, tuple.Item2);
			ResourceAmount resourceAmount = new ResourceAmount();
			resourceAmount.Set(tuple.Item1, tuple.Item2);
			tuple.Item3.RemoveResources(resourceAmount);
			result = true;
		}
		RefreshVisualStorage();
		return result;
	}

	public void RefreshVisualStorage()
	{
		foreach (KeyValuePair<int, GraphicalResourceStack> stack in stacks)
		{
			stack.Value.Set(0);
		}
		for (int i = 0; i < currStorage.resources.Count; i++)
		{
			int resourceID = currStorage.resources[i].resourceID;
			if (!stacks.TryGetValue(resourceID, out var value))
			{
				value = UnityEngine.Object.Instantiate(transportCartStackPrefab).GetComponent<GraphicalResourceStack>();
				if (FreeResourceSystem.inst.resourceDefMap.TryGetValue(resourceID, out var value2))
				{
					value.spacing = value2.autoStackSpacing;
					value.rowAlternateRotation = value2.autoStackAlterateRows;
					value.HeightMultiplier = value2.autoStackHeightMul;
				}
				value.resourceID = resourceID;
				value.Init();
				stacks.Add(resourceID, value);
			}
			value.Set(currStorage.resources[i].Amount);
		}
	}

	public bool IsCollectionPossible(LogisticRoute route)
	{
		IEnumerator enumerator = InternalCollection(route).GetEnumerator();
		if (enumerator.MoveNext())
		{
			return true;
		}
		return false;
	}

	private void DropStorage()
	{
		if (isShip)
		{
			isDeferDroppingStorage = true;
			return;
		}
		for (int i = 0; i < currStorage.resources.Count; i++)
		{
			Resource resource = currStorage.resources[i];
			if (resource.Amount > 0)
			{
				FreeResourceManager.inst.AddOrMakeAutoStackFor(resource.resourceID, resource.Amount, transform.position);
				resource.Amount = 0;
			}
		}
		RefreshVisualStorage();
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		switch (status)
		{
		case 0:
			if (routes.Count > 0)
			{
				SetRouteIndex(0);
			}
			break;
		case 1:
			if (currFrame % 120 == 0)
			{
				if (IsCollectionPossible(routes[routeIdx]))
				{
					RequestPathTo(GetEdgePos(routes[routeIdx].sourceBuilding));
					SetStatus(2);
				}
				else
				{
					NextRoute();
				}
			}
			break;
		case 3:
			if (GetCollectionForRoute(routes[routeIdx]))
			{
				SetStatus(4);
				RequestPathTo(GetEdgePos(routes[routeIdx].targetBuilding));
			}
			else
			{
				NextRoute();
			}
			break;
		case 5:
		{
			IResourceStorage component = routes[routeIdx].targetBuilding.GetComponent<IResourceStorage>();
			if (isShip)
			{
				ResourceStatistics.AddProduction(component.LandMass(), "shipping", currStorage);
			}
			component.Deposit(ref currStorage);
			for (int i = 0; i < currStorage.resources.Count; i++)
			{
				Resource resource = currStorage.resources[i];
				if (resource.Amount > 0)
				{
					FreeResourceManager.inst.AddOrMakeAutoStackFor(resource.resourceID, resource.Amount, routes[routeIdx].targetBuilding.Center());
				}
			}
			currStorage.Clear();
			RefreshVisualStorage();
			for (int j = 1; j < routes.Count; j++)
			{
				int index = (routeIdx + j) % routes.Count;
				if (IsCollectionPossible(routes[index]))
				{
					SetRouteIndex(index, doStatusChange: false);
					SetStatus(2);
					return;
				}
			}
			NextRoute();
			break;
		}
		case -1:
		case 2:
		case 4:
			break;
		}
	}

	public void UpdateStacks(Vector3 pos, Quaternion rot)
	{
		foreach (KeyValuePair<int, GraphicalResourceStack> stack in stacks)
		{
			stack.Value.transform.SetPositionAndRotation(pos, rot);
		}
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		LogisticsManager.vehicles.Add(this);
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		if (GameState.IsQuitting)
		{
			return;
		}
		foreach (KeyValuePair<int, GraphicalResourceStack> stack in stacks)
		{
			UnityEngine.Object.Destroy(stack.Value.gameObject);
		}
		stacks.Clear();
		LogisticsManager.vehicles.Remove(this);
	}
}
