using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using I2.Loc;
using UnityEngine;

public class ProductionBuilding : Tickable, IOutputInfo, IResourceProviderContainer, IWorkerUIDisplay
{
	public string statsID = string.Empty;

	public YieldProducer yieldProducer;

	public GraphicalResourceStack stack;

	protected CullingGroup cullingGroup;

	protected BoundingSphere[] spheres = new BoundingSphere[1];

	public ResourceAmount cost;

	public ResourceAmount resourcesStored = new ResourceAmount();

	public ResourceAmount resourceStorageMax;

	private float timeWithNoPrereqs;

	protected Building b;

	[FreeResourceType]
	public int[] typesToGather;

	protected int[] gatherTypeOrder;

	protected ArrayExt<int> typesAvailableToCollect = new ArrayExt<int>(5);

	public int gatherers = 2;

	public int deliverers = 1;

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

	public ResourceAmount GetCost()
	{
		return cost;
	}

	public int GetResult(int rID)
	{
		if (rID != yieldProducer.YieldType)
		{
			return 0;
		}
		return yieldProducer.Yield;
	}

	public bool ShowResultStorage()
	{
		return true;
	}

	public int GetOutputStorage(int rID)
	{
		if (rID != stack.resourceID)
		{
			return 0;
		}
		return stack.Count();
	}

	public int GetOutputMaxStorage(int rID)
	{
		if (rID != stack.resourceID)
		{
			return 0;
		}
		return stack.MaxCapacity();
	}

	public int GetInputMaxStorage(int rID)
	{
		return resourceStorageMax.Get(rID);
	}

	public BuildingProductionUI.CustomProductionItem[] GetCustomCost()
	{
		return null;
	}

	public BuildingProductionUI.CustomProductionItem[] GetCustomResult()
	{
		return null;
	}

	public float GetProgress()
	{
		return yieldProducer.GetYieldProgress();
	}

	public int GetInputStorage(int rID)
	{
		for (int i = 0; i < resourcesStored.resources.Count; i++)
		{
			if (rID == resourcesStored.resources[i].resourceID)
			{
				return resourcesStored.resources[i].Amount;
			}
		}
		return 0;
	}

	public int SpaceAvailable(int resourceID)
	{
		return resourceStorageMax.Get(resourceID) - resourcesStored.Get(resourceID);
	}

	public Vector3 DropOffLocation(int t)
	{
		return b.Center();
	}

	public int MaxStorageFor(int resourceID)
	{
		return resourceStorageMax.Get(resourceID);
	}

	public bool StoresTypePublic(int resourceID)
	{
		return resourceID == stack.resourceID;
	}

	public int StoredPublicResources(int resourceID)
	{
		return stack.AvailableAmount();
	}

	public void RemoveResources(ResourceAmount amount)
	{
		stack.Remove(amount.Get(stack.resourceID));
	}

	public bool AcceptsType(int resourceID)
	{
		return false;
	}

	protected void OnYieldResources(int type, int Yield)
	{
		if (resourcesStored.TrySubtract(cost))
		{
			if (statsID == string.Empty)
			{
				statsID = b.UniqueName;
			}
			int num = Yield;
			int num2 = stack.MaxCapacity();
			int num3 = stack.Count();
			if (num > 0 && num3 < num2)
			{
				ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), stack.resourceID, num);
				num = Mathf.Min(num, num2 - num3);
				ResourceStatistics.AddProduction(b.LandMass(), statsID, type, num);
				stack.Add(num);
			}
			ResourceStatistics.AddConsumption(b.LandMass(), statsID, cost);
		}
		CheckProductionPipeline();
	}

	string IOutputInfo.GetError()
	{
		if (stack.Count() >= stack.MaxCapacity())
		{
			return string.Format(ScriptLocalization.workerui_error_internalstoragefull, ResourceAmount.ResourceIcon(stack.resourceID));
		}
		if (b.thought.visible)
		{
			for (int i = 0; i < cost.resources.Count; i++)
			{
				int resourceID = cost.resources[i].resourceID;
				if (resourcesStored.Get(resourceID) <= 0 && cost.Get(resourceID) > 0)
				{
					return string.Format(ScriptLocalization.workerui_error_noresourceavailable, ResourceAmount.ResourceIcon(resourceID));
				}
				if (resourcesStored.Get(resourceID) <= cost.Get(resourceID))
				{
					return string.Format(LocalizationManager.GetTranslation("workerui_error_notenoughresourceavailable"), ResourceAmount.ResourceIcon(resourceID));
				}
			}
		}
		return null;
	}

	public override void Tick(float dt, int currFrame)
	{
		if (!b.IsBuilt() || !b.IsOpen())
		{
			return;
		}
		if (!resourcesStored.CanSubtract(cost))
		{
			if (b.DuringWorkHours(0f))
			{
				timeWithNoPrereqs += dt;
			}
		}
		else
		{
			timeWithNoPrereqs = 0f;
		}
		if (timeWithNoPrereqs > 30f)
		{
			b.thought.thought = ThoughtBubbleSystem.Thought.GeneralError;
			b.thought.visible = true;
		}
		else if (b.thought.thought != ThoughtBubbleSystem.Thought.Tired)
		{
			b.thought.visible = false;
		}
		Home.BuildGatherTypeOrder(LandMass(), typesAvailableToCollect, ref gatherTypeOrder, resourcesStored, resourceStorageMax, typesToGather);
		CheckProductionPipeline();
		base.Tick(dt, currFrame);
	}

	public void CheckProductionPipeline()
	{
		yieldProducer.PauseYield = stack.Count() + yieldProducer.Yield > stack.MaxCapacity() || !resourcesStored.HasCost(cost);
	}

	private void OnBuilt()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	private void OnFinishedLoad()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	public override void OnEnableInternal()
	{
		yieldProducer = GetComponent<YieldProducer>();
		yieldProducer.OnYieldResources += OnYieldResources;
		if (gatherTypeOrder == null)
		{
			gatherTypeOrder = new int[typesToGather.Length];
		}
		b = GetComponent<Building>();
		resourceStorageMax.Set(stack.resourceID, stack.MaxCapacity());
		cullingGroup = new CullingGroup();
		cullingGroup.onStateChanged = stack.StateChangedMethod;
		cullingGroup.SetBoundingSpheres(spheres);
		cullingGroup.SetBoundingSphereCount(1);
		cullingGroup.targetCamera = Cam.inst.cam;
		base.OnEnableInternal();
	}

	public override void OnDisableInternal()
	{
		yieldProducer.OnYieldResources -= OnYieldResources;
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
		base.OnDisableInternal();
	}

	private void OnDemolished()
	{
		Vector3 position = b.GetCell().Position;
		for (int i = 0; i < resourcesStored.resources.Count; i++)
		{
			Resource resource = resourcesStored.resources[i];
			if (resource.Amount > 0)
			{
				FreeResourceManager.inst.GetAutoStackFor(resource.resourceID, resource.Amount, position);
			}
		}
		if (stack.Count() > 0)
		{
			FreeResourceManager.inst.GetAutoStackFor(stack.resourceID, stack.Count(), position);
		}
	}

	protected void InitDeliveryJob(DeliveryJob j)
	{
		j.provider = stack;
	}

	internal void InitGatherJob(FreeResourceGathererJob j)
	{
		j.searchUpdate.SetFrameSpread(30);
		j.typeOrder = gatherTypeOrder;
	}

	private void OnAddJobs(Building b)
	{
		int num = 0;
		for (int i = 0; i < gatherers; i++)
		{
			if (!b.VerifyJobIs(num, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(num, new FreeResourceGathererJob(b, _consumeOnPickup: true));
			}
			InitGatherJob(b.jobs[num] as FreeResourceGathererJob);
			num++;
		}
		for (int j = 0; j < deliverers; j++)
		{
			if (!b.VerifyJobIs(num, typeof(DeliveryJob)))
			{
				b.SetAndAddJob(num, new DeliveryJob(b, stack));
			}
			InitDeliveryJob(b.jobs[num] as DeliveryJob);
			num++;
		}
		OnAddJobsInternal(ref num);
		for (int k = num; k < b.jobs.Count; k++)
		{
			if (!b.VerifyJobIs(k, typeof(Job)))
			{
				b.SetAndAddJob(k, new Job(b));
			}
		}
	}

	protected virtual void OnAddJobsInternal(ref int idx)
	{
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
