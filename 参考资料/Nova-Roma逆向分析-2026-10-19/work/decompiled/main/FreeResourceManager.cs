using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Interface;
using UnityEngine;

public class FreeResourceManager : MonoBehaviour
{
	public class ResourceRegionCache
	{
		public int x;

		public int z;

		public Dictionary<int, ResourceProviderRegistry> providerRegistry = new Dictionary<int, ResourceProviderRegistry>();

		public ResourceRegionCache()
		{
			List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
			for (int i = 0; i < resourceDefs.Count; i++)
			{
				ResourceProviderRegistry value = new ResourceProviderRegistry
				{
					resourceID = resourceDefs[i].ID
				};
				providerRegistry.Add(resourceDefs[i].ID, value);
			}
		}

		public void Add(IResourceProvider resource)
		{
			List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
			for (int i = 0; i < resourceDefs.Count; i++)
			{
				if (resource.ProvidesType(resourceDefs[i].ID))
				{
					providerRegistry[resourceDefs[i].ID].resources.Add(resource);
				}
			}
		}

		public void Remove(IResourceProvider resource)
		{
			List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
			for (int i = 0; i < resourceDefs.Count; i++)
			{
				if (resource.ProvidesType(resourceDefs[i].ID))
				{
					providerRegistry[resourceDefs[i].ID].resources.RemoveSwap(resource);
				}
			}
		}
	}

	public class LandMassRegistry
	{
		public Dictionary<int, ResourceProviderRegistry> providerRegistry = new Dictionary<int, ResourceProviderRegistry>();

		public Dictionary<int, ResourceStorageRegistry> storageRegistry = new Dictionary<int, ResourceStorageRegistry>();

		public ArrayExtRef<IResourceStorage> storages = new ArrayExtRef<IResourceStorage>(50);

		public LandMassRegistry()
		{
			List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
			int i = 0;
			for (int count = resourceDefs.Count; i < count; i++)
			{
				FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
				ResourceProviderRegistry value = new ResourceProviderRegistry
				{
					resourceID = resourceDef.ID
				};
				providerRegistry.Add(resourceDef.ID, value);
				ResourceStorageRegistry value2 = new ResourceStorageRegistry
				{
					resourceID = resourceDef.ID
				};
				storageRegistry.Add(resourceDef.ID, value2);
			}
		}

		public void Add(IResourceProvider resource)
		{
			foreach (KeyValuePair<int, ResourceProviderRegistry> item in providerRegistry)
			{
				if (resource.ProvidesType(item.Value.resourceID))
				{
					item.Value.resources.Add(resource);
				}
			}
		}

		public void Remove(IResourceProvider resource)
		{
			foreach (KeyValuePair<int, ResourceProviderRegistry> item in providerRegistry)
			{
				if (resource.ProvidesType(item.Value.resourceID))
				{
					item.Value.resources.RemoveSwap(resource);
				}
			}
		}

		public void Add(IResourceStorage storage)
		{
			foreach (KeyValuePair<int, ResourceStorageRegistry> item in storageRegistry)
			{
				if (storage.StoresTypePublic(item.Value.resourceID))
				{
					item.Value.resources.Add(storage);
				}
			}
			storages.Add(storage);
		}

		public void Remove(IResourceStorage storage)
		{
			foreach (KeyValuePair<int, ResourceStorageRegistry> item in storageRegistry)
			{
				if (storage.StoresTypePublic(item.Value.resourceID))
				{
					item.Value.resources.RemoveSwap(storage);
				}
			}
			storages.RemoveSwap(storage);
		}
	}

	public class ResourceProviderRegistry
	{
		[NonSerialized]
		public int resourceID;

		[NonSerialized]
		public ArrayExtRef<IResourceProvider> resources = new ArrayExtRef<IResourceProvider>(200);
	}

	public class ResourceStorageRegistry
	{
		[NonSerialized]
		public int resourceID;

		[NonSerialized]
		public ArrayExtRef<IResourceStorage> resources = new ArrayExtRef<IResourceStorage>(200);
	}

	public class ResourceProviderCell
	{
		public struct Bucket
		{
			public ArrayExtRef<IResourceProvider> bucket;
		}

		[NonSerialized]
		public ArrayExtRef<Dictionary<int, Bucket>> bucketContainers;

		private void InitContainer()
		{
			bucketContainers = new ArrayExtRef<Dictionary<int, Bucket>>(11);
			for (int i = 0; i < 11; i++)
			{
				bucketContainers.Add(new Dictionary<int, Bucket>(FreeResourceSystem.inst.resourceDefs.Count));
				for (int j = 0; j < FreeResourceSystem.inst.resourceDefs.Count; j++)
				{
					FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[j];
					if (resourceDef.ID == 4)
					{
						bucketContainers.data[i][resourceDef.ID] = default;
						continue;
					}
					bucketContainers.data[i][resourceDef.ID] = new Bucket
					{
						bucket = new ArrayExtRef<IResourceProvider>(5)
					};
				}
			}
		}

		public IResourceProvider GetClosestProviderOfType(bool consumer, int type, providerFilter filter)
		{
			if (bucketContainers != null)
			{
				for (int i = 0; i < bucketContainers.Count; i++)
				{
					ArrayExtRef<IResourceProvider> bucket = bucketContainers.data[i][type].bucket;
					IResourceProvider[] data = bucket.data;
					int j = 0;
					for (int count = bucket.Count; j < count; j++)
					{
						IResourceProvider resourceProvider = data[j];
						if ((consumer || resourceProvider.ValidToPickupToStoreElsewhere()) && resourceProvider.Available(type) && (filter == null || filter(resourceProvider, type)))
						{
							return resourceProvider;
						}
					}
				}
			}
			return null;
		}

		public void AddProvider(IResourceProvider provider, int type, int bucketIdx)
		{
			if (bucketContainers == null)
			{
				InitContainer();
			}
			bucketContainers.data[bucketIdx][type].bucket.Add(provider);
		}

		public void RemoveProvider(IResourceProvider provider, int type, int bucketIdx)
		{
			bucketContainers.data[bucketIdx][type].bucket.RemoveSwap(provider);
		}
	}

	public delegate bool providerFilter(IResourceProvider x, int type);

	public delegate float CustomScore(IResourceProvider provider, int type, Villager villager);

	[Serializable]
	public class FreeResourceManagerSaveData : SaveClass<FreeResourceManager, FreeResourceManagerSaveData>
	{
		private List<FreeResource.FreeResourceSaveData> orphanedResources;

		private List<GraphicalResourceStack.GraphicalResourceStackSaveData> orphanedStacks;

		public override FreeResourceManagerSaveData Pack(FreeResourceManager f)
		{
			orphanedResources = new List<FreeResource.FreeResourceSaveData>();
			for (int i = 0; i < FreeResource.freeResources.Count; i++)
			{
				FreeResource freeResource = FreeResource.freeResources.data[i];
				if (freeResource != null && freeResource.Holder == null)
				{
					FreeResource.FreeResourceSaveData item = new FreeResource.FreeResourceSaveData().Pack(freeResource);
					orphanedResources.Add(item);
				}
			}
			orphanedStacks = new List<GraphicalResourceStack.GraphicalResourceStackSaveData>();
			for (int j = 0; j < ResourceStackAuto.stacks.Count; j++)
			{
				GraphicalResourceStack graphicalResourceStack = ResourceStackAuto.stacks.data[j];
				GraphicalResourceStack.GraphicalResourceStackSaveData item2 = new GraphicalResourceStack.GraphicalResourceStackSaveData().Pack(graphicalResourceStack.GetComponent<GraphicalResourceStack>());
				orphanedStacks.Add(item2);
			}
			return this;
		}

		public override FreeResourceManager Unpack(FreeResourceManager f)
		{
			foreach (FreeResource.FreeResourceSaveData orphanedResource in orphanedResources)
			{
				int landMassIdx = World.inst.GetCellDataClamped(orphanedResource.position).landMassIdx;
				if (landMassIdx >= 0 && landMassIdx < World.inst.NumLandMasses)
				{
					FreeResource freeResource = FreeResourceSystem.inst.AddFreeResource(orphanedResource.resourceID, orphanedResource.position, landMassIdx);
					orphanedResource.Unpack(freeResource);
					freeResource.Holder = null;
				}
			}
			if (orphanedStacks != null)
			{
				foreach (GraphicalResourceStack.GraphicalResourceStackSaveData orphanedStack in orphanedStacks)
				{
					if (orphanedStack.count > 1)
					{
						f.GetAutoStackFor(orphanedStack.resourceID, orphanedStack.count, orphanedStack.pos).transform.position = orphanedStack.pos;
					}
				}
			}
			return f;
		}
	}

	private ResourceRegionCache[,] resourceRegion;

	[NonSerialized]
	public ArrayExt<LandMassRegistry> landMassRegistry = new ArrayExt<LandMassRegistry>(10);

	private LandMassRegistry emptyLandMassRegistry;

	public ResourceProviderCell[] providerCells;

	public static int maxCount = 0;

	public static FreeResourceManager inst;

	internal ArrayExtRef<ResourceStackAuto> autoStackInitList = new ArrayExtRef<ResourceStackAuto>(100);

	internal ArrayExtRef<ResourceStackAuto> autoStackUpdateList = new ArrayExtRef<ResourceStackAuto>(100);

	private int regionResolution = 5;

	private bool reseting;

	private List<int> providesTypes = new List<int>();

	private const int CHECK_RADIUS = 10;

	private const int CHECK_RADIUS_SQUARED = 100;

	private List<ResourceStackAuto> toDestroy = new List<ResourceStackAuto>();

	private static bool doOnce = true;

	public ResourceProviderCell GetProviderCell(int x, int z)
	{
		if (providerCells != null)
		{
			int num = z * World.inst.GridWidth + x;
			if (x >= 0 && x < World.inst.GridWidth && z >= 0 && z < World.inst.GridHeight)
			{
				return providerCells[num];
			}
		}
		return null;
	}

	public GameObject GetAutoStackFor(int resourceID, int count, Vector3 pos)
	{
		if (FreeResourceSystem.inst.resourceDefMap.TryGetValue(resourceID, out var value))
		{
			Stack component = value.autoResourceStackPrefab.GetComponent<Stack>();
			component.InitCount = count;
			component.xStackSize = value.xStackSize;
			component.zStackSize = value.zStackSize;
			component.maxStackCount = Mathff.Max(count, 30);
			GameObject gameObject = UnityEngine.Object.Instantiate(value.autoResourceStackPrefab);
			gameObject.transform.position = pos;
			gameObject.gameObject.SetActive(value: true);
			gameObject.GetComponent<ResourceStackAuto>().timeExpire = value.timeExpire;
			return gameObject;
		}
		return null;
	}

	public void AddOrMakeAutoStackFor(int t, int count, Vector3 pos)
	{
		if (count <= 0)
		{
			return;
		}
		Cell cell = World.inst.GetCellDataClamped(pos);
		if (cell.landMassIdx == -1)
		{
			Cell cell2 = World.inst.FindMatchingSurroundingCell(cell, testOrigin: false, 2, (Cell cell3) => cell3.landMassIdx != -1);
			if (cell2 == null)
			{
				Debug.LogError("aborting dropping in -1 landmass");
				return;
			}
			cell = cell2;
			pos = cell.Center3D;
		}
		pos.y = TerrainGen.inst.GetInterpolatedHeight(pos);
		int x = cell.x;
		int num = cell.z * World.inst.GridWidth + x;
		List<ResourceStackAuto> list = ResourceStackAuto.stackGrid[num];
		if (list != null)
		{
			for (int num2 = 0; num2 < list.Count; num2++)
			{
				if (list[num2].stack.resourceID == t)
				{
					count -= list[num2].stack.Add(count);
					list[num2].timeCreated = Time.time;
					if (count <= 0)
					{
						return;
					}
				}
			}
		}
		GetAutoStackFor(t, count, pos);
	}

	public void AutoDropRemainder(ResourceAmount amount, Vector3 pos)
	{
		Cell cell = World.inst.FindMatchingSurroundingCell(World.inst.GetCellDataClamped(pos), testOrigin: true, 2, (Cell cell2) => cell2.landMassIdx != -1);
		if (cell != null)
		{
			pos = cell.Center3D;
		}
		for (int num = 0; num < amount.resources.Count; num++)
		{
			AddOrMakeAutoStackFor(amount.resources[num].resourceID, amount.resources[num].Amount, pos);
		}
	}

	private void Start()
	{
		inst = this;
		emptyLandMassRegistry = new LandMassRegistry();
	}

	public void Reset()
	{
		reseting = true;
		resourceRegion = null;
		providerCells = null;
		for (int i = 0; i < ResourceStackAuto.stacks.Count; i++)
		{
			UnityEngine.Object.Destroy(ResourceStackAuto.stacks.data[i].gameObject);
		}
		ResourceStackAuto.stacks.Clear();
		autoStackInitList.Clear();
		autoStackUpdateList.Clear();
		for (int j = 0; j < landMassRegistry.Count; j++)
		{
			foreach (KeyValuePair<int, ResourceProviderRegistry> item in landMassRegistry.data[j].providerRegistry)
			{
				item.Value.resources.Clear();
			}
			foreach (KeyValuePair<int, ResourceStorageRegistry> item2 in landMassRegistry.data[j].storageRegistry)
			{
				item2.Value.resources.Clear();
			}
			landMassRegistry.data[j].storages.Clear();
		}
		while (FreeResource.freeResources.Count > 0)
		{
			FreeResource.freeResources.data[0].Shutdown();
		}
		reseting = false;
	}

	public void AddResourceProviderChecked(IResourceProvider resource)
	{
		if (!Contains(resource))
		{
			AddResourceProvider(resource);
		}
	}

	public void AddResourceProvider(IResourceProvider resource)
	{
		int num = resource.LandMass();
		while (landMassRegistry.Count <= num)
		{
			landMassRegistry.Add(new LandMassRegistry());
		}
		landMassRegistry.data[num].Add(resource);
		Vector3 vector = resource.CachingCenter();
		if (resourceRegion == null)
		{
			int num2 = World.inst.GridWidth / regionResolution + 1;
			int num3 = World.inst.GridHeight / regionResolution + 1;
			resourceRegion = new ResourceRegionCache[num2, num3];
			for (int i = 0; i < num3; i++)
			{
				for (int j = 0; j < num2; j++)
				{
					ResourceRegionCache resourceRegionCache = new ResourceRegionCache();
					resourceRegionCache.x = j;
					resourceRegionCache.z = i;
					resourceRegion[j, i] = resourceRegionCache;
				}
			}
		}
		int num4 = (int)(vector.x / (float)regionResolution);
		int num5 = (int)(vector.z / (float)regionResolution);
		resourceRegion[num4, num5].Add(resource);
		if (providerCells == null)
		{
			Cell[] cellsData = World.inst.GetCellsData();
			providerCells = new ResourceProviderCell[World.inst.GridWidth * World.inst.GridHeight];
			for (int k = 0; k < providerCells.Length; k++)
			{
				if (!cellsData[k].deepWater)
				{
					providerCells[k] = new ResourceProviderCell();
				}
			}
		}
		providesTypes.Clear();
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int l = 0;
		for (int count = resourceDefs.Count; l < count; l++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[l];
			if (resource.ProvidesType(resourceDef.ID))
			{
				providesTypes.Add(resourceDef.ID);
			}
		}
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		int num6 = (int)Mathf.Max(vector.x - 10f, 0f);
		int num7 = (int)Mathf.Max(vector.z - 10f, 0f);
		int num8 = (int)Mathf.Min(vector.x + 10f, gridWidth - 1);
		int num9 = (int)Mathf.Min(vector.z + 10f, gridHeight - 1);
		for (int m = num7; m <= num9; m++)
		{
			int num10 = m * gridWidth;
			for (int n = num6; n <= num8; n++)
			{
				Cell cellData = World.inst.GetCellData(n, m);
				if (cellData != null && !cellData.deepWater)
				{
					int bucketIdx = Mathff.Max(Mathff.Abs((int)vector.x - cellData.x), Mathff.Abs((int)vector.z - m));
					int num11 = num10 + cellData.x;
					for (int num12 = 0; num12 < providesTypes.Count; num12++)
					{
						providerCells[num11].AddProvider(resource, providesTypes[num12], bucketIdx);
					}
				}
			}
		}
	}

	public void RemoveResourceProvider(IResourceProvider resource)
	{
		int num = resource.LandMass();
		landMassRegistry.data[num].Remove(resource);
		Vector3 vector = resource.CachingCenter();
		if (resourceRegion != null)
		{
			int num2 = (int)(vector.x / (float)regionResolution);
			int num3 = (int)(vector.z / (float)regionResolution);
			resourceRegion[num2, num3].Remove(resource);
		}
		if (reseting)
		{
			return;
		}
		providesTypes.Clear();
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int i = 0;
		for (int count = resourceDefs.Count; i < count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			if (resource.ProvidesType(resourceDef.ID))
			{
				providesTypes.Add(resourceDef.ID);
			}
		}
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		int num4 = (int)Mathf.Max(vector.x - 10f, 0f);
		int num5 = (int)Mathf.Max(vector.z - 10f, 0f);
		int num6 = (int)Mathf.Min(vector.x + 10f, gridWidth - 1);
		int num7 = (int)Mathf.Min(vector.z + 10f, gridHeight - 1);
		for (int j = num5; j <= num7; j++)
		{
			int num8 = j * gridWidth;
			for (int k = num4; k <= num6; k++)
			{
				Cell cellData = World.inst.GetCellData(k, j);
				if (cellData != null && !cellData.deepWater)
				{
					int bucketIdx = Mathff.Max(Mathff.Abs((int)vector.x - cellData.x), Mathff.Abs((int)vector.z - j));
					int num9 = num8 + cellData.x;
					for (int l = 0; l < providesTypes.Count; l++)
					{
						providerCells[num9].RemoveProvider(resource, providesTypes[l], bucketIdx);
					}
				}
			}
		}
	}

	public ArrayExtRef<IResourceProvider> GetResourceListFor(int resourceID, int landMass)
	{
		if (landMass >= 0 && landMass < landMassRegistry.Count)
		{
			return landMassRegistry.data[landMass].providerRegistry[resourceID].resources;
		}
		return emptyLandMassRegistry.providerRegistry[resourceID].resources;
	}

	public ArrayExtRef<IResourceStorage> GetResourceStorageListFor(int resourceID, int landMass)
	{
		if (landMass >= 0 && landMass < landMassRegistry.Count)
		{
			return landMassRegistry.data[landMass].storageRegistry[resourceID].resources;
		}
		return emptyLandMassRegistry.storageRegistry[resourceID].resources;
	}

	public ArrayExtRef<IResourceStorage> GetResourceStorageListFor(int landMass)
	{
		if (landMass >= 0 && landMass < landMassRegistry.Count)
		{
			return landMassRegistry.data[landMass].storages;
		}
		return emptyLandMassRegistry.storages;
	}

	public int RemovePhysicalResources(int resourceID, int amountToRemove, int landMass)
	{
		int num = 0;
		int num2 = amountToRemove;
		ArrayExtRef<IResourceStorage> resourceStorageListFor = GetResourceStorageListFor(resourceID, landMass);
		for (int i = 0; i < resourceStorageListFor.Count; i++)
		{
			if (num2 <= 0)
			{
				break;
			}
			IResourceStorage resourceStorage = resourceStorageListFor.data[i];
			int num3 = resourceStorage.StoredPublicResources(resourceID);
			if (num3 > 0)
			{
				int num4 = Mathf.Min(num3, num2);
				ResourceAmount resourceAmount = new ResourceAmount();
				resourceAmount.Set(resourceID, num4);
				resourceStorage.RemoveResources(resourceAmount);
				num2 -= num4;
				num += num4;
			}
		}
		List<GraphicalResourceStack> list = new List<GraphicalResourceStack>();
		for (int j = 0; j < ResourceStackAuto.stacks.Count; j++)
		{
			if (num2 <= 0)
			{
				break;
			}
			GraphicalResourceStack graphicalResourceStack = ResourceStackAuto.stacks.data[j];
			if (graphicalResourceStack != null && graphicalResourceStack.resourceID == resourceID && World.inst.GetCellDataClamped(graphicalResourceStack.transform.position).landMassIdx == landMass)
			{
				int num5 = graphicalResourceStack.Count();
				if (num5 <= num2)
				{
					num2 -= num5;
					num += num5;
					list.Add(graphicalResourceStack);
				}
				else
				{
					graphicalResourceStack.Remove(num2);
					num += num2;
					num2 = 0;
				}
			}
		}
		foreach (GraphicalResourceStack item in list)
		{
			((ResourceStackAuto)item.owner).Unhook();
			UnityEngine.Object.Destroy(item.gameObject);
		}
		List<FreeResource> list2 = new List<FreeResource>();
		for (int k = 0; k < FreeResource.freeResources.Count; k++)
		{
			if (num2 <= 0)
			{
				break;
			}
			FreeResource freeResource = FreeResource.freeResources.data[k];
			if (freeResource != null && !freeResource.Equals(null) && freeResource.resourceID == resourceID && freeResource.landMassIdx == landMass && freeResource.Holder == null)
			{
				list2.Add(freeResource);
				num2--;
				num++;
			}
		}
		foreach (FreeResource item2 in list2)
		{
			item2.Shutdown();
		}
		return num;
	}

	private void Update()
	{
		for (int i = 0; i < autoStackInitList.Count; i++)
		{
			autoStackInitList.data[i].Init();
		}
		autoStackInitList.Clear();
		float time = Time.time;
		int j = 0;
		for (int count = autoStackUpdateList.Count; j < count; j++)
		{
			ResourceStackAuto resourceStackAuto = autoStackUpdateList.data[j];
			if (resourceStackAuto.deleteOnEmpty && resourceStackAuto.stack.inited && resourceStackAuto.stack.Count() == 0)
			{
				toDestroy.Add(resourceStackAuto);
			}
			else if (time - resourceStackAuto.timeCreated > 120f && resourceStackAuto.timeExpire)
			{
				ResourceTextStackManager.inst.ShowResourceAmount(resourceStackAuto, resourceStackAuto.transform.position, resourceStackAuto.stack.resourceID, -resourceStackAuto.stack.AvailableAmount());
				ResourceStatistics.AddConsumption(resourceStackAuto.LandMass(), "rot", resourceStackAuto.stack.resourceID, resourceStackAuto.stack.AvailableAmount());
				toDestroy.Add(resourceStackAuto);
			}
		}
		for (int k = 0; k < toDestroy.Count; k++)
		{
			ResourceStackAuto resourceStackAuto2 = toDestroy[k];
			resourceStackAuto2.Unhook();
			UnityEngine.Object.Destroy(resourceStackAuto2.gameObject);
		}
		toDestroy.Clear();
	}

	public IResourceProvider FindClosestResourceProviderFor(bool consumer, int type, Vector3 pos, int landmass, providerFilter filter, float maxRadius = 9999f, bool debug = false)
	{
		if (type == -1)
		{
			return null;
		}
		ResourceProviderCell providerCell = GetProviderCell((int)pos.x, (int)pos.z);
		if (providerCell != null)
		{
			IResourceProvider closestProviderOfType = providerCell.GetClosestProviderOfType(consumer, type, filter);
			if (closestProviderOfType != null && closestProviderOfType.LandMass() == landmass)
			{
				return closestProviderOfType;
			}
		}
		float num = maxRadius * maxRadius;
		IResourceProvider resourceProvider = null;
		float num2 = float.MaxValue;
		if (resourceRegion != null)
		{
			int num3 = World.inst.GridWidth / regionResolution + 1;
			int num4 = World.inst.GridHeight / regionResolution + 1;
			int num5 = Mathff.Max(num3, num4) * 2;
			int num6 = (int)maxRadius / regionResolution + 1;
			int num7 = (int)(pos.x / (float)regionResolution);
			int num8 = (int)(pos.z / (float)regionResolution);
			for (int i = 10 / regionResolution; i <= num5 && i <= num6; i++)
			{
				int num9 = num7 - i;
				int num10 = num8 - i;
				int num11 = num7 + i;
				int num12 = num8 + i;
				for (int j = num10; j <= num12; j++)
				{
					if (j < 0)
					{
						continue;
					}
					if (j >= num4)
					{
						break;
					}
					for (int k = num9; k <= num11; k++)
					{
						if (k < 0)
						{
							continue;
						}
						if (k >= num3)
						{
							break;
						}
						if (k != num9 && j != num10 && k != num11 && j != num12)
						{
							continue;
						}
						ArrayExtRef<IResourceProvider> resources = resourceRegion[k, j].providerRegistry[type].resources;
						int l = 0;
						for (int count = resources.Count; l < count; l++)
						{
							IResourceProvider resourceProvider2 = resources.data[l];
							if (resourceProvider2.LandMass() == landmass && (consumer || resourceProvider2.ValidToPickupToStoreElsewhere()))
							{
								float num13 = Mathff.DistSqrdXZ(resourceProvider2.ResourcePosition(type), pos);
								if (num13 < num2 && num13 < num && resourceProvider2.Available(type) && (filter == null || filter(resourceProvider2, type)))
								{
									num2 = num13;
									resourceProvider = resourceProvider2;
								}
							}
						}
					}
				}
				if (resourceProvider != null)
				{
					if (debug)
					{
						Debug.DrawLine(pos, resourceProvider.ResourcePosition(type), Color.red, 5f);
					}
					return resourceProvider;
				}
			}
		}
		return resourceProvider;
	}

	public IResourceProvider FindResourceProviderCustomScore(int type, Villager villager, int landMass, providerFilter filter, CustomScore scoreFunction)
	{
		IResourceProvider result = null;
		float num = float.MaxValue;
		ArrayExtRef<IResourceProvider> resourceListFor = GetResourceListFor(type, landMass);
		int i = 0;
		for (int count = resourceListFor.Count; i < count; i++)
		{
			IResourceProvider resourceProvider = resourceListFor.data[i];
			if (resourceProvider.Available(type) && (filter == null || filter(resourceProvider, type)))
			{
				float num2 = scoreFunction(resourceProvider, type, villager);
				if (num2 < num)
				{
					num = num2;
					result = resourceProvider;
				}
			}
		}
		return result;
	}

	public void AddResourceStorage(IResourceStorage storage)
	{
		int num = storage.LandMass();
		while (landMassRegistry.Count <= num)
		{
			landMassRegistry.Add(new LandMassRegistry());
		}
		landMassRegistry.data[num].Add(storage);
	}

	public void RemoveResourceStorage(IResourceStorage storage)
	{
		landMassRegistry.data[storage.LandMass()].Remove(storage);
	}

	public IResourceStorage FindClosestBuilidngAccepting(int rtype, int ramount, int landMass, Vector3 loc, float maxRadius = 30f)
	{
		float num = maxRadius * maxRadius;
		IResourceStorage result = null;
		float num2 = float.MaxValue;
		ArrayExtRef<IResourceStorage> resourceStorageListFor = GetResourceStorageListFor(rtype, landMass);
		for (int i = 0; i < 2; i++)
		{
			int j = 0;
			for (int count = resourceStorageListFor.Count; j < count; j++)
			{
				IResourceStorage resourceStorage = resourceStorageListFor.data[j];
				if (!resourceStorage.AcceptsType(rtype))
				{
					continue;
				}
				int num3 = resourceStorage.SpaceAvailable(rtype);
				if (num3 < ramount)
				{
					continue;
				}
				if (i == 0)
				{
					float num4 = resourceStorage.MaxStorageFor(rtype);
					if ((float)num3 / num4 > 0.75f)
					{
						continue;
					}
				}
				Building component = (resourceStorage as MonoBehaviour).GetComponent<Building>();
				Stockpile component2 = component.GetComponent<Stockpile>();
				if (component.IsBuilt() && (!(component2 != null) || component2.allowCitizensToDeposit))
				{
					float num5 = Mathff.DistSqrdXZ(loc, resourceStorage.DropOffLocation(rtype));
					if (num5 < num2 && num5 < num)
					{
						num2 = num5;
						result = resourceStorage;
					}
				}
			}
		}
		return result;
	}

	public bool Contains(IResourceProvider provider)
	{
		int num = provider.LandMass();
		if (num >= 0 && num < landMassRegistry.Count)
		{
			foreach (KeyValuePair<int, ResourceProviderRegistry> item in landMassRegistry.data[num].providerRegistry)
			{
				if (provider.ProvidesType(item.Value.resourceID) && item.Value.resources.Contains(provider))
				{
					return true;
				}
			}
		}
		return false;
	}
}
