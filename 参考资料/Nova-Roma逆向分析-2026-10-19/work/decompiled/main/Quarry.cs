using System;
using Assets;
using Assets.Code;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Quarry : ExtractionBuilding, IResourceStorage, IResourceStorageBase
{
	public enum QuarryType
	{
		Stone,
		Marble
	}

	[Serializable]
	public class QuarrySaveData : SaveClass<Quarry, QuarrySaveData>
	{
		private int stone;

		private int internalTools;

		public override QuarrySaveData Pack(Quarry obj)
		{
			internalTools = obj.resourcesStored.Get(6);
			stone = obj.stack.Count();
			return this;
		}

		public override Quarry Unpack(Quarry obj)
		{
			obj.resourcesStored.Set(6, internalTools);
			obj.stack.Add(stone);
			return obj;
		}
	}

	private ResourceAmount resourcesStored = new ResourceAmount();

	private bool isVisible = true;

	private bool halted;

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	private EventHandler<OnTechnologyTreeUnlock> unlockEventHandler;

	public YieldProducer yieldProducer;

	private Animation anim;

	public MeshRenderer Stone;

	public Mesh end;

	public Mesh mid;

	public Mesh center;

	public MeshFilter meshFilter;

	private bool isAdvancedQuarryUnlocked;

	private TerrainResource tResource;

	public QuarryType type;

	protected override void Awake()
	{
		base.Awake();
		yieldProducer = GetComponent<YieldProducer>();
		anim = GetComponent<Animation>();
		yieldProducer.OnYieldResources += OnYieldResources;
		yieldProducer.OnUsedTool += YieldProducer_OnUsedTool;
	}

	private bool YieldProducer_OnUsedTool()
	{
		if (resourcesStored.TrySubtract(6, 1))
		{
			ResourceStatistics.AddConsumption(b.LandMass(), b.UniqueName, 6, 1);
			return true;
		}
		return false;
	}

	private void OnDestroy()
	{
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
		b.visibilityChanged -= OnVisibilityChanged;
		Broadcast.TechnologyTreeUnlockEvent.Unlisten(unlockEventHandler);
	}

	protected override void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		int rID = ((type == QuarryType.Marble) ? 14 : 2);
		if (World.inst.GetCardinalAdjacentResource(cellDataClamped.x, cellDataClamped.z, rID) == null)
		{
			if (World.inst.HasCardinalAdjacentBuriedResource(cellDataClamped.x, cellDataClamped.z, rID))
			{
				validationResult = PlacementValidationResult.ResourceDepositBuried;
			}
			else if (World.inst.HasCardinalAdjacentCoveredResource(cellDataClamped.x, cellDataClamped.z, rID))
			{
				validationResult = PlacementValidationResult.ResourceDepositCovered;
			}
			else
			{
				validationResult = ((type == QuarryType.Marble) ? PlacementValidationResult.QuarryMustBeAdjacentToMarble : PlacementValidationResult.QuarryMustBeAdjacentToStone);
			}
		}
		else if (!FacingRock())
		{
			Cell cellData = World.inst.GetCellData(transform.GetChild(0).position + transform.GetChild(0).right);
			if (cellData != null && cellData.HasTerrainResourceType(rID) && !cellData.HasAccessibleTerrainResourceType(rID))
			{
				validationResult = ((cellData.Type != TerrainType.Obstruction) ? PlacementValidationResult.ResourceDepositBuried : PlacementValidationResult.ResourceDepositCovered);
			}
			else
			{
				validationResult = PlacementValidationResult.QuarryMustFaceRock;
			}
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (!b.IsBuilt() || !b.IsOpen())
		{
			return;
		}
		if (isVisible)
		{
			if (b.GetWorkerPercent() > 0f && tResource != null)
			{
				anim["MineStone"].time = yieldProducer.GetYieldProgress();
			}
			else
			{
				anim["MineStone"].time = 0f;
			}
		}
		CheckProductionPipeline();
	}

	private void OnInit()
	{
		string locTerm = "";
		if (type == QuarryType.Stone)
		{
			locTerm = "custom_production_cost_terrainstone";
		}
		else if (type == QuarryType.Marble)
		{
			locTerm = "custom_production_cost_terrainmarble";
		}
		customProductionItems[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = productionIcon,
			type = BuildingProductionUI.CustomProductionItem.CustomType.TerrainResource,
			locTerm = locTerm
		};
		resourceStorageMax.Set(stack.resourceID, stack.MaxCapacity());
		resourceStorageMax.Set(6, 2);
		cullingGroup = new CullingGroup();
		cullingGroup.onStateChanged = stack.StateChangedMethod;
		cullingGroup.SetBoundingSpheres(spheres);
		cullingGroup.SetBoundingSphereCount(1);
		cullingGroup.targetCamera = Cam.inst.cam;
		Stone.enabled = false;
		b.visibilityChanged += OnVisibilityChanged;
	}

	public void OnVisibilityChanged(bool v)
	{
		Stone.enabled = v;
		isVisible = v;
	}

	private void OnBuilt()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
		SetupAnim();
	}

	private void OnFinishedLoad()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
		SetupAnim();
	}

	private void OnAddJobs(Building b)
	{
		if (!b.VerifyJobIs(0, typeof(FreeResourceGathererJob)))
		{
			b.SetAndAddJob(0, new FreeResourceGathererJob(b, _consumeOnPickup: true));
		}
		InitGatherJob(b.jobs[0] as FreeResourceGathererJob);
		if (!b.VerifyJobIs(1, typeof(DeliveryJob)))
		{
			b.SetAndAddJob(1, new DeliveryJob(b, stack));
		}
		InitDeliveryJob(b.jobs[1] as DeliveryJob);
	}

	private void InitGatherJob(FreeResourceGathererJob j)
	{
		j.searchUpdate.SetFrameSpread(30);
		j.Configure(6, null);
	}

	private void InitDeliveryJob(DeliveryJob j)
	{
		j.provider = stack;
	}

	private void OnYieldResources(int type, int Yield)
	{
		int num = Yield;
		int num2 = stack.MaxCapacity();
		int num3 = stack.Count();
		if (num > 0 && num3 < num2)
		{
			ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), stack.resourceID, num);
			num = Mathf.Min(num, num2 - num3);
			ResourceStatistics.AddProduction(LandMass(), b.UniqueName, type, num);
			stack.Add(num);
		}
		if (!DifficultyManager.inst.currOption.unlimitedResources && tResource != null && tResource.AddHarvested(Yield))
		{
			tResource = null;
		}
		CheckProductionPipeline();
	}

	public void CheckProductionPipeline()
	{
		yieldProducer.PauseYield = (halted = stack.Count() >= stack.MaxCapacity() || tResource == null);
	}

	private void OnBuildingPlacement(bool undo)
	{
		UpdateMesh();
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		Cell cell = null;
		for (int i = minZ - 1; i <= maxZ + 1; i++)
		{
			for (int j = minX - 1; j <= maxX + 1; j++)
			{
				cell = World.inst.GetCellDataClamped(j, i);
				for (int k = 0; k < cell.OccupyingStructure.Count; k++)
				{
					Building building = cell.OccupyingStructure[k];
					if (building.categoryHash == World.quarryHash)
					{
						building.GetComponent<Quarry>().UpdateMesh();
					}
				}
			}
		}
		if (!undo)
		{
			tResource = TerrainResource.GetClosestTerrainResource(yieldProducer.YieldType, b);
			if (TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_advancedquarry"))
			{
				isAdvancedQuarryUnlocked = true;
			}
			else
			{
				unlockEventHandler = Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyTreeUnlock);
			}
		}
	}

	private void OnTechnologyTreeUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		if (data.unlockKey == "unlockkey_advancedquarry")
		{
			isAdvancedQuarryUnlocked = true;
			Broadcast.TechnologyTreeUnlockEvent.Unlisten(unlockEventHandler);
		}
	}

	private void SetupAnim()
	{
		Stone.enabled = b.IsVisibleForFog();
		Animation component = GetComponent<Animation>();
		component.Play("MineStone");
		component["MineStone"].speed = 0f;
		component.wrapMode = WrapMode.Once;
	}

	public bool FacingRock()
	{
		Cell cellData = World.inst.GetCellData(transform.GetChild(0).position + transform.GetChild(0).right);
		if (cellData != null)
		{
			if (type == QuarryType.Stone)
			{
				return cellData.HasAccessibleTerrainResourceType(2);
			}
			if (type == QuarryType.Marble)
			{
				return cellData.HasAccessibleTerrainResourceType(14);
			}
		}
		return false;
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		ResourceStorageHelper.Deposit(resourcesStored, resourceStorageMax, yieldProducer, ref resources, b.Center());
	}

	int IResourceStorageBase.SpaceAvailable(int resourceID)
	{
		return resourceStorageMax.Get(resourceID) - resourcesStored.Get(resourceID);
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	int IResourceStorage.MaxStorageFor(int resourceID)
	{
		return resourceStorageMax.Get(resourceID);
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		if (resourceID != stack.resourceID)
		{
			return 0;
		}
		return stack.AvailableAmount();
	}

	bool IResourceStorage.AcceptsType(int resourceID)
	{
		return false;
	}

	bool IResourceStorage.StoresTypePublic(int resourceID)
	{
		return resourceID == stack.resourceID;
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		stack.Remove(amount.Get(stack.resourceID));
	}

	public override int GetResult(int rID)
	{
		if (rID != yieldProducer.YieldType)
		{
			return 0;
		}
		return yieldProducer.Yield;
	}

	public override bool ShowResultStorage()
	{
		return true;
	}

	public override BuildingProductionUI.CustomProductionItem[] GetCustomCost()
	{
		if (DifficultyManager.inst.currOption.unlimitedResources)
		{
			customProductionItems[0].maxStorage = int.MaxValue;
		}
		else if (tResource == null)
		{
			customProductionItems[0].maxStorage = 0;
		}
		else
		{
			customProductionItems[0].maxStorage = tResource.GetRemainingResources();
		}
		return customProductionItems;
	}

	public override float GetProgress()
	{
		return yieldProducer.GetYieldProgress();
	}

	public override int GetTotalBonus()
	{
		if (!isAdvancedQuarryUnlocked)
		{
			return 0;
		}
		return 1;
	}

	public override string GetCustomText()
	{
		if (!isAdvancedQuarryUnlocked)
		{
			return null;
		}
		return string.Format(ScriptLocalization.workerui_productionui_customtext_quarrybonus, 1);
	}

	public override string GetError()
	{
		if (tResource == null)
		{
			return ScriptLocalization.QuarryResourceRemoved;
		}
		if (halted)
		{
			return ScriptLocalization.QuarryProductionHalted;
		}
		return null;
	}

	private void UpdateMesh()
	{
		GetAdjacencyInfo(out var north, out var south, out var east, out var west, out var _, out var _, out var _, out var _, out var num);
		if (num <= 1)
		{
			meshFilter.mesh = end;
		}
		if (num > 1 && num <= 3 && ((north & south) || (east & west)))
		{
			meshFilter.mesh = mid;
		}
		else
		{
			meshFilter.mesh = end;
		}
	}

	private bool ShouldConnect(int x, int z)
	{
		if (World.inst.GetCellDataClamped(x, z).StructureCompareCategory(World.quarryHash))
		{
			return true;
		}
		return false;
	}

	private void GetAdjacencyInfo(out bool north, out bool south, out bool east, out bool west, out bool northNorth, out bool southSouth, out bool eastEast, out bool westWest, out int count)
	{
		World.inst.ToGridCoord(transform.position, out var x, out var z);
		northNorth = ShouldConnect(x + 2, z);
		eastEast = ShouldConnect(x, z + 2);
		southSouth = ShouldConnect(x - 2, z);
		westWest = ShouldConnect(x, z - 2);
		north = ShouldConnect(x + 1, z);
		south = ShouldConnect(x - 1, z);
		east = ShouldConnect(x, z + 1);
		west = ShouldConnect(x, z - 1);
		count = 0;
		if (north)
		{
			count++;
		}
		if (south)
		{
			count++;
		}
		if (east)
		{
			count++;
		}
		if (west)
		{
			count++;
		}
		if (northNorth)
		{
			count++;
		}
		if (southSouth)
		{
			count++;
		}
		if (eastEast)
		{
			count++;
		}
		if (westWest)
		{
			count++;
		}
	}
}
