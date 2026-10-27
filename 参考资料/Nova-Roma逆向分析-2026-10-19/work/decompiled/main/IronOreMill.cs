using System;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class IronOreMill : AqueductBuilding, IOutputInfo, IResourceProviderContainer, IResourceStorage, IResourceStorageBase, IProductionInfo, IWorkerUIDisplay
{
	public Transform wheel;

	public Transform[] pounders;

	public Transform[] pounderEffectPos;

	public GameObject[] aqueductEnds;

	public float waterNeedHumanUnits = 20f;

	private float[] pounderTime;

	private EventHandler<OnBuildingOpenClose> openCloseHandler;

	public Sprite resultIcon;

	public AnimationCurve pounderAnim;

	public float wheelSpeed = 1f;

	public float pounderOffset = 0.1f;

	public float pounderSpeed = 1f;

	public float animMagnitude = 1f;

	public float pounderYOffset;

	public float pounderEffectTime = 0.1f;

	private bool isFlowing;

	public ParticleSystem[] flowFX;

	public Transform[] flowSamplers;

	private BuildingProductionUI.CustomProductionItem[] customResultItem = new BuildingProductionUI.CustomProductionItem[1];

	public YieldProducer yieldProducer;

	public GraphicalResourceStack stack;

	protected CullingGroup cullingGroup;

	protected BoundingSphere[] spheres = new BoundingSphere[1];

	public ResourceAmount cost;

	public ResourceAmount resourcesStored = new ResourceAmount();

	public ResourceAmount resourceStorageMax;

	private float timeWithNoPrereqs;

	[FreeResourceType]
	public int[] typesToGather;

	protected int[] gatherTypeOrder;

	protected ArrayExt<int> typesAvailableToCollect = new ArrayExt<int>(5);

	private WaterError waterError;

	public int gatherers = 2;

	public int deliverers = 1;

	private void Awake()
	{
		pounderTime = new float[pounders.Length];
		for (int i = 0; i < pounders.Length; i++)
		{
			pounderTime[i] = (float)i * pounderOffset;
		}
		customResultItem[0] = new BuildingProductionUI.CustomProductionItem
		{
			maxStorage = stack.MaxCapacity(),
			icon = resultIcon,
			locTerm = "Iron",
			hideConsumption = false,
			amount = yieldProducer.Yield
		};
		ApplyWaterDemand();
	}

	private void ApplyWaterDemand()
	{
		ApplyWaterDemand(b == null || b.IsOpen());
	}

	private void ApplyWaterDemand(bool isOpen)
	{
		float num = (isOpen ? waterNeedHumanUnits : 0f);
		SetSolverDemand(num, num);
	}

	private void OnOpenClose(object sender, OnBuildingOpenClose data)
	{
		if (!(data.targetBuilding != b))
		{
			ApplyWaterDemand(data.open);
		}
	}

	public override float GetCurrentWaterConsumption()
	{
		return Mathff.Min(waterFlow, waterNeedHumanUnits);
	}

	public override float GetWaterDemandTotal()
	{
		return waterNeedHumanUnits;
	}

	public override void ConnectLine(AqueductLine line)
	{
		Vector3 pos = line.waypoints[0];
		if (Mathff.DistSqrd(line.waypoints[0], b.Center()) > Mathff.DistSqrd(line.waypoints[^1], b.Center()))
		{
			pos = line.waypoints[^1];
		}
		Vector3 portPosition = GetPortPosition(pos);
		for (int i = 0; i < aqueductEnds.Length; i++)
		{
			if (Mathff.DistSqrdXZ(aqueductEnds[i].transform.position, portPosition) > 0.040000003f)
			{
				aqueductEnds[i].SetActive(value: false);
			}
			else
			{
				aqueductEnds[i].SetActive(value: true);
			}
		}
		base.ConnectLine(line);
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
		if (!isFlowing)
		{
			return 0;
		}
		return yieldProducer.Yield;
	}

	public bool ShowResultStorage()
	{
		return true;
	}

	public int GetInputMaxStorage(int rID)
	{
		return resourceStorageMax.Get(rID);
	}

	public int GetOutputMaxStorage(int rID)
	{
		if (rID != stack.resourceID)
		{
			return 0;
		}
		return stack.MaxCapacity();
	}

	public BuildingProductionUI.CustomProductionItem[] GetCustomCost()
	{
		return null;
	}

	public BuildingProductionUI.CustomProductionItem[] GetCustomResult()
	{
		if (isFlowing)
		{
			return null;
		}
		customResultItem[0].currentStorage = stack.Count();
		return customResultItem;
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

	public int GetOutputStorage(int rID)
	{
		if (rID == stack.resourceID)
		{
			return stack.Count();
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
		if (resourceID != stack.resourceID)
		{
			return 0;
		}
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
			int num = Yield;
			int num2 = stack.MaxCapacity();
			int num3 = stack.Count();
			if (num > 0 && num3 < num2)
			{
				ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), stack.resourceID, num);
				num = Mathf.Min(num, num2 - num3);
				ResourceStatistics.AddProduction(b.LandMass(), b.UniqueName, type, num);
				stack.Add(num);
			}
			ResourceStatistics.AddConsumption(b.LandMass(), b.UniqueName, cost);
		}
		CheckProductionPipeline();
	}

	string IOutputInfo.GetError()
	{
		string errorString = AqueductBuilding.GetErrorString(waterError);
		if (!string.IsNullOrEmpty(errorString))
		{
			return errorString;
		}
		if (stack.Count() >= stack.MaxCapacity())
		{
			return string.Format(ScriptLocalization.workerui_error_internalstoragefull, ResourceAmount.ResourceIcon(stack.resourceID));
		}
		if (b.thought.visible)
		{
			for (int i = 0; i < cost.resources.Count; i++)
			{
				int resourceID = cost.resources[i].resourceID;
				if (resourcesStored.Get(resourceID) < cost.Get(resourceID))
				{
					return string.Format(ScriptLocalization.workerui_error_noresourceavailable, ResourceAmount.ResourceIcon(resourceID));
				}
			}
		}
		return null;
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b.IsBuilt())
		{
			ApplyWaterDemand();
		}
		bool flag = false;
		if (b.IsBuilt() && b.IsOpen())
		{
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
			else if (waterError != WaterError.None)
			{
				b.thought.thought = GetThoughtBubbleFor(waterError);
				b.thought.visible = true;
			}
			else
			{
				b.thought.visible = false;
			}
			Home.BuildGatherTypeOrder(LandMass(), typesAvailableToCollect, ref gatherTypeOrder, resourcesStored, resourceStorageMax, typesToGather);
			isFlowing = true;
			flag = resourcesStored.Get(5) > 0;
			for (int i = 0; i < flowSamplers.Length; i++)
			{
				Vector3 position = flowSamplers[i].position;
				if (DynamicWater.inst.simplifiedWaterFlowMagnitude[(int)position.z * World.inst.GridWidth + (int)position.x] <= 0f)
				{
					isFlowing = false;
				}
			}
			if (!isFlowing && AqueductBuilding.WaterHasArrived(waterFlow, waterNeedHumanUnits))
			{
				isFlowing = true;
			}
			if (isFlowing & flag)
			{
				if (aqueductEnds[0].activeSelf)
				{
					wheel.Rotate(0f, 0f, dt * wheelSpeed);
					if (!flowFX[0].isPlaying)
					{
						flowFX[0].Play();
					}
				}
				else
				{
					wheel.Rotate(0f, 0f, dt * (0f - wheelSpeed));
					if (!flowFX[1].isPlaying)
					{
						flowFX[1].Play();
					}
				}
				if (b.WorkersAllocated > 0 && b.AreWorkersNear(1))
				{
					for (int j = 0; j < pounders.Length; j++)
					{
						Vector3 localPosition = pounders[j].localPosition;
						localPosition.y = pounderYOffset + pounderAnim.Evaluate(pounderTime[j]) * animMagnitude;
						pounders[j].localPosition = localPosition;
						if (pounderTime[j] < pounderEffectTime && pounderTime[j] + dt >= pounderEffectTime)
						{
							EffectsMan.inst.WallHitSmallEffect.CreateAndPlay(pounderEffectPos[j].position);
						}
						pounderTime[j] += dt * pounderSpeed;
						if (pounderTime[j] >= 1f)
						{
							pounderTime[j] = 0f;
						}
					}
				}
			}
			CheckProductionPipeline();
			base.Tick(dt, currFrame);
		}
		if (isFlowing && flag)
		{
			return;
		}
		for (int k = 0; k < flowFX.Length; k++)
		{
			if (flowFX[k].isPlaying)
			{
				flowFX[k].Stop();
			}
		}
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		ResourceStorageHelper.Deposit(resourcesStored, resourceStorageMax, yieldProducer, ref resources, b.Center());
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		return null;
	}

	public void CheckProductionPipeline()
	{
		yieldProducer.PauseYield = stack.Count() + yieldProducer.Yield > stack.MaxCapacity() || !resourcesStored.HasCost(cost) || !isFlowing;
	}

	private void OnBuilt()
	{
		waterError = UpdateWaterErrorState();
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	private void OnFinishedLoad()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
		ApplyWaterDemand();
	}

	public override void OnEnableInternal()
	{
		yieldProducer.OnYieldResources += OnYieldResources;
		if (gatherTypeOrder == null)
		{
			gatherTypeOrder = new int[typesToGather.Length];
		}
		b = GetComponent<Building>();
		resourceStorageMax.Set(stack.resourceID, stack.MaxCapacity() / yieldProducer.Yield);
		if (openCloseHandler == null)
		{
			openCloseHandler = Broadcast.BuildingOpenClose.Listen(b.uniqueNameHash, OnOpenClose);
		}
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
		if (openCloseHandler != null)
		{
			Broadcast.BuildingOpenClose.Unlisten(b.uniqueNameHash, openCloseHandler);
			openCloseHandler = null;
		}
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

	public override void UpdateWaterFlow()
	{
		base.UpdateWaterFlow();
		waterError = UpdateWaterErrorState();
	}

	internal void InitGatherJob(FreeResourceGathererJob j)
	{
		j.searchUpdate.SetFrameSpread(20);
		j.typeOrder = gatherTypeOrder;
		j.filterPrimary = JobFilter;
	}

	private bool JobFilter(IResourceProvider x, int type)
	{
		if (x is GraphicalResourceStack graphicalResourceStack && (graphicalResourceStack.b == null || graphicalResourceStack.b.uniqueNameHash != b.uniqueNameHash))
		{
			if (x.GetType() != typeof(Stockpile) && x.GetType() != typeof(Dock))
			{
				return !(graphicalResourceStack.owner is ResourceStackAuto);
			}
			return false;
		}
		return false;
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
		for (int k = num; k < b.jobs.Count; k++)
		{
			if (!b.VerifyJobIs(k, typeof(Job)))
			{
				b.SetAndAddJob(k, new Job(b));
			}
		}
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
