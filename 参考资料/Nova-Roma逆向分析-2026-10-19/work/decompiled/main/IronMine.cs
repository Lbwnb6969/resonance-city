using System;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class IronMine : Tickable, IResourceProviderContainer, IResourceStorage, IResourceStorageBase, IProductionInfo, IOutputInfo, IWorkerUIDisplay
{
	[Serializable]
	public class IronMineSaveData : SaveClass<IronMine, IronMineSaveData>
	{
		private int iron;

		private int toolUsage;

		private int wood;

		public override IronMineSaveData Pack(IronMine obj)
		{
			toolUsage = obj.toolUsage;
			wood = obj.resourcesStored.Get(1);
			iron = obj.stack.Count();
			return this;
		}

		public override IronMine Unpack(IronMine obj)
		{
			obj.toolUsage = toolUsage;
			obj.stack.Add(iron);
			obj.resourcesStored.Set(1, wood);
			return obj;
		}
	}

	public Sprite productionIcon;

	public Transform wheel;

	public ResourceAmount resourceStorageMax;

	public ResourceAmount resourcesStored;

	private BuildingProductionUI.CustomProductionItem[] customProductionItems = new BuildingProductionUI.CustomProductionItem[1];

	private bool halted;

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	public GraphicalResourceStack stack;

	public YieldProducer yieldProducer;

	private Building b;

	private int toolUsage;

	public static int toolUsesBeforeBreaking = 20;

	[SerializeField]
	private ParticleSystem smokePSystem;

	private EventHandler<OnTechnologyTreeUnlock> unlockEventHandler;

	private TerrainResource tResource;

	public float terrainDrop = 0.25f;

	private void Awake()
	{
		b = GetComponent<Building>();
		yieldProducer = GetComponent<YieldProducer>();
		yieldProducer.OnYieldResources += OnYieldResources;
		yieldProducer.OnUsedTool += YieldProducer_OnUsedTool;
		b.PlacementValidaton = PlacementValidation;
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

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		if (World.inst.GetCardinalAdjacentResource(cellDataClamped.x, cellDataClamped.z, 5) == null)
		{
			if (World.inst.HasCardinalAdjacentBuriedResource(cellDataClamped.x, cellDataClamped.z, 5))
			{
				validationResult = PlacementValidationResult.ResourceDepositBuried;
			}
			else if (World.inst.HasCardinalAdjacentCoveredResource(cellDataClamped.x, cellDataClamped.z, 5))
			{
				validationResult = PlacementValidationResult.ResourceDepositCovered;
			}
			else
			{
				validationResult = PlacementValidationResult.IronMineMustBeAdjacentToIron;
			}
		}
		else if (!FacingRock())
		{
			Cell cellData = World.inst.GetCellData(transform.GetChild(0).position + transform.GetChild(0).forward);
			if (cellData != null && cellData.HasTerrainResourceType(5) && !cellData.HasAccessibleTerrainResourceType(5))
			{
				validationResult = ((cellData.Type != TerrainType.Obstruction) ? PlacementValidationResult.ResourceDepositBuried : PlacementValidationResult.ResourceDepositCovered);
			}
			else
			{
				validationResult = PlacementValidationResult.IronMineMustFaceRock;
			}
		}
	}

	private void OnTechnologyTreeUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		if (!(b == null) && b.IsBuilt() && data.unlockKey == "unlockkey_thermalfracturing")
		{
			OnAddJobs(b);
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b.IsBuilt() && b.IsOpen())
		{
			CheckProductionPipeline();
		}
	}

	private void OnInit()
	{
		customProductionItems[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = productionIcon,
			type = BuildingProductionUI.CustomProductionItem.CustomType.TerrainResource,
			locTerm = "custom_production_cost_terrainiron"
		};
		resourceStorageMax.Set(stack.resourceID, stack.MaxCapacity());
		resourceStorageMax.Set(6, 2);
		resourceStorageMax.Set(1, 4);
		cullingGroup = new CullingGroup();
		cullingGroup.onStateChanged = stack.StateChangedMethod;
		cullingGroup.SetBoundingSpheres(spheres);
		cullingGroup.SetBoundingSphereCount(1);
		cullingGroup.targetCamera = Cam.inst.cam;
		b.visibilityChanged += OnVisibilityChanged;
		unlockEventHandler = Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyTreeUnlock);
	}

	public void OnVisibilityChanged(bool v)
	{
	}

	private void OnBuilt()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
		TerrainGen.inst.MakeSquareDepression((int)b.Center().x, (int)b.Center().z, 0, 0, 1, terrainDrop / 2f);
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			tResource = TerrainResource.GetClosestTerrainResource(yieldProducer.YieldType, b);
		}
	}

	private void OnFinishedLoad()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	private void OnDemolished()
	{
		if (stack.Count() > 0)
		{
			FreeResourceManager.inst.GetAutoStackFor(stack.resourceID, stack.Count(), b.GetCell().Position);
		}
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
		if (TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_thermalfracturing"))
		{
			if (!b.VerifyJobIs(2, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(2, new FreeResourceGathererJob(b, _consumeOnPickup: true));
			}
			FreeResourceGathererJob obj = b.jobs[2] as FreeResourceGathererJob;
			obj.searchUpdate.SetFrameSpread(30);
			obj.Configure(1, null);
		}
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

	private bool YieldProducer_OnUsedTool()
	{
		if (resourcesStored.TrySubtract(6, 1))
		{
			ResourceStatistics.AddConsumption(b.LandMass(), b.UniqueName, 6, 1);
			return true;
		}
		return false;
	}

	private void OnYieldResources(int type, int Yield)
	{
		int num = Yield;
		int num2 = stack.MaxCapacity();
		int num3 = stack.Count();
		if (num > 0 && num3 < num2)
		{
			if (b.TeamID() == 0 && TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_thermalfracturing"))
			{
				if (resourcesStored.TrySubtract(1, 1))
				{
					ResourceStatistics.AddConsumption(b.LandMass(), b.UniqueName, 1, 1);
					num += Mathf.CeilToInt((float)num * 0.25f);
					smokePSystem.Play();
				}
				else
				{
					smokePSystem.Stop();
				}
			}
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

	public bool FacingRock()
	{
		return World.inst.GetCellData(transform.GetChild(0).position + transform.GetChild(0).forward)?.HasAccessibleTerrainResourceType(5) ?? false;
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

	public int LandMass()
	{
		return b.LandMass();
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		FreeResourceManager.inst.AddResourceProviderChecked(stack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(stack);
	}

	ResourceAmount IProductionInfo.GetCost()
	{
		return null;
	}

	int IProductionInfo.GetResult(int rID)
	{
		if (rID != yieldProducer.YieldType)
		{
			return 0;
		}
		return yieldProducer.Yield;
	}

	bool IProductionInfo.ShowResultStorage()
	{
		return true;
	}

	int IProductionInfo.GetOutputStorage(int rID)
	{
		if (rID != stack.resourceID)
		{
			return 0;
		}
		return stack.Count();
	}

	public int GetOutputMaxStorage(int rID)
	{
		return resourceStorageMax.Get(rID);
	}

	public int GetInputStorage(int rID)
	{
		return 0;
	}

	public int GetInputMaxStorage(int rID)
	{
		return 0;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomCost()
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

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomResult()
	{
		return null;
	}

	float IProductionInfo.GetProgress()
	{
		return yieldProducer.GetYieldProgress();
	}

	int IProductionInfo.GetTotalBonus()
	{
		if (!TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_thermalfracturing") || resourcesStored.Get(1) <= 0)
		{
			return 0;
		}
		return Mathf.CeilToInt((float)yieldProducer.Yield * 0.25f);
	}

	string IProductionInfo.GetCustomText()
	{
		if (TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_thermalfracturing"))
		{
			string text = $"<sprite name=icon_wood> {resourcesStored.Get(1)} / {resourceStorageMax.Get(1)}";
			if (resourcesStored.Get(1) > 0)
			{
				text = text + Environment.NewLine + string.Format(ScriptLocalization.workerui_productionui_customtext_ironminebonus, Mathf.CeilToInt((float)yieldProducer.Yield * 0.25f));
			}
			return text;
		}
		return null;
	}

	public string GetError()
	{
		if (tResource == null)
		{
			return ScriptLocalization.IronMineResourceRemoved;
		}
		if (halted)
		{
			return ScriptLocalization.IronMineHalted;
		}
		return null;
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
