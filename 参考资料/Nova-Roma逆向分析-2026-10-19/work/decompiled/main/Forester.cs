using System;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Forester : Tickable, IOutputInfo, IResourceProviderContainer, IOverlayUser, IResourceStorage, IResourceStorageBase, IProductionInfo, IWorkerUIDisplay
{
	[Serializable]
	public class ForesterSaveData : SaveClass<Forester, ForesterSaveData>
	{
		private int wood;

		private int toolUsage;

		private int currYearHarvest;

		private int prevYearHarvest;

		public override ForesterSaveData Pack(Forester obj)
		{
			toolUsage = obj.toolUsage;
			wood = obj.stack.Count();
			currYearHarvest = obj.currYearHarvest;
			prevYearHarvest = obj.prevYearHarvest;
			return this;
		}

		public override Forester Unpack(Forester obj)
		{
			obj.toolUsage = toolUsage;
			obj.stack.Add(wood);
			obj.currYearHarvest = currYearHarvest;
			obj.prevYearHarvest = prevYearHarvest;
			return obj;
		}
	}

	public Sprite productionIcon;

	public GraphicalResourceStack stack;

	public ResourceAmount resourceStorageMax;

	private ResourceAmount resourcesStored = new ResourceAmount();

	private ResourceAmount yieldResult = new ResourceAmount();

	private BuildingProductionUI.CustomProductionItem[] customProductionItems = new BuildingProductionUI.CustomProductionItem[1];

	public bool halted;

	internal int toolUsage;

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	private EventHandler<OnBuildingAddRemove> addRemoveListenEventHandler;

	private EventHandler<SeasonEventData> onSeasonEventHandler;

	private int currYearHarvest;

	private int prevYearHarvest;

	public int Radius = 3;

	private Building b;

	public bool OverlayWhenPlacing => true;

	public bool OverlayWhenSelected => true;

	private void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
	}

	private void OnDestroy()
	{
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
		Broadcast.BuildingAddRemove.UnlistenAny(addRemoveListenEventHandler);
		Broadcast.SeasonEvent.Unlisten(onSeasonEventHandler);
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		bool touchingExisting = false;
		World.inst.ForEachTileTouchingRadius(b.Center(), Radius, (int subx, int subz, Cell c) =>
		{
			if ((bool)c.BottomStructure && c.BottomStructure.uniqueNameHash == World.foresterHash)
			{
				touchingExisting = true;
			}
		});
		if (touchingExisting)
		{
			validationResult = PlacementValidationResult.ForesterTooCloseToForester;
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
			type = BuildingProductionUI.CustomProductionItem.CustomType.Infinite,
			locTerm = "TileInfoForest",
			hideBottom = true
		};
		resourceStorageMax.Set(stack.resourceID, stack.MaxCapacity());
		cullingGroup = new CullingGroup();
		cullingGroup.onStateChanged = stack.StateChangedMethod;
		cullingGroup.SetBoundingSpheres(spheres);
		cullingGroup.SetBoundingSphereCount(1);
		cullingGroup.targetCamera = Cam.inst.cam;
		onSeasonEventHandler = Broadcast.SeasonEvent.Listen(OnSeasonChanged);
	}

	private void OnSeasonChanged(object sender, SeasonEventData obj)
	{
		if (obj.SeasonDefinition.markNewYear)
		{
			prevYearHarvest = currYearHarvest;
			currYearHarvest = 0;
		}
	}

	private void OnBuilt()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
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
		if (!b.VerifyJobIs(0, typeof(WoodCutterJob)))
		{
			b.SetAndAddJob(0, new WoodCutterJob(b));
		}
		if (!b.VerifyJobIs(1, typeof(TreePlanterJob)))
		{
			b.SetAndAddJob(1, new TreePlanterJob(b));
		}
		if (!b.VerifyJobIs(2, typeof(FreeResourceGathererJob)))
		{
			b.SetAndAddJob(2, new FreeResourceGathererJob(b, _consumeOnPickup: true));
		}
		((FreeResourceGathererJob)b.jobs[2]).Configure(6, null);
		if (!b.VerifyJobIs(3, typeof(DeliveryJob)))
		{
			b.SetAndAddJob(3, new DeliveryJob(b, stack));
		}
		((DeliveryJob)b.jobs[3]).provider = stack;
	}

	public void CheckProductionPipeline()
	{
		halted = stack.Count() >= stack.MaxCapacity();
	}

	public void AddToWoodPile(int num)
	{
		stack.Add(num);
		currYearHarvest += num;
	}

	public bool InZone(Cell cell)
	{
		return World.inst.TileTouchingRadius(cell.x, cell.z, b.Center(), Radius);
	}

	private void TryApplyToolBonus()
	{
		if (resourcesStored.TrySubtract(6, 1))
		{
			toolUsage += 10;
			ResourceStatistics.AddConsumption(LandMass(), World.foresterName, 6, 1);
		}
	}

	public void DoToolUsage()
	{
		toolUsage--;
		if (toolUsage <= 0)
		{
			TryApplyToolBonus();
		}
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		for (int i = 0; i < resources.resources.Count; i++)
		{
			Resource resource = resources.resources[i];
			int amount = resource.Amount;
			if (amount <= 0)
			{
				continue;
			}
			resource.Amount = 0;
			int num = Mathff.Max(0, resourceStorageMax.Get(resource.resourceID) - resourcesStored.Get(resource.resourceID));
			if (amount > num)
			{
				FreeResourceManager.inst.AddOrMakeAutoStackFor(resource.resourceID, amount - num, b.Center());
				if (num == 0)
				{
					continue;
				}
			}
			int num2 = Mathff.Min(num, amount);
			resourcesStored.Add(resource.resourceID, num2);
			if (num2 > 0 && resource.resourceID == 6 && toolUsage <= 0)
			{
				TryApplyToolBonus();
			}
		}
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
		if (rID != 1)
		{
			return 0;
		}
		return 1;
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
		return customProductionItems;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomResult()
	{
		return null;
	}

	float IProductionInfo.GetProgress()
	{
		if (!(b.jobs[0] is WoodCutterJob woodCutterJob))
		{
			return 0f;
		}
		return woodCutterJob.GetChoppingProgress();
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		string text = string.Format(ScriptLocalization.workerui_productionui_customtext_currentyear, currYearHarvest) + Environment.NewLine + string.Format(ScriptLocalization.workerui_productionui_customtext_previousyear, prevYearHarvest);
		if (toolUsage > 0)
		{
			text = text + Environment.NewLine + string.Format(ScriptLocalization.workerui_productionui_customtext_chopbonus, "<color=green><b>+25%</b></color>");
		}
		return text;
	}

	string IOutputInfo.GetError()
	{
		if (stack.Count() >= stack.MaxCapacity())
		{
			return ScriptLocalization.ForesterProductionHalted;
		}
		return null;
	}

	public void DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.RedrawOverlayCircle(origin, Radius, new Color(0.3f, 0.3f, 1f, 0.2f));
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
