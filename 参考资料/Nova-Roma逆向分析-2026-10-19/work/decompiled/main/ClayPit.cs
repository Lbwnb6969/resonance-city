using System;
using Assets;
using Assets.Code;
using Assets.Code.Jobs;
using Assets.Interface;
using Code;
using I2.Loc;
using UnityEngine;

public class ClayPit : ExtractionBuilding, IResourceStorage, IResourceStorageBase
{
	[Serializable]
	public class ClayPitSaveData : SaveClass<ClayPit, ClayPitSaveData>
	{
		private int stackCount;

		private float startHeight;

		private int internalTools;

		public override ClayPitSaveData Pack(ClayPit obj)
		{
			stackCount = obj.stack.Count();
			startHeight = obj.startHeight;
			internalTools = obj.resourcesStored.Get(6);
			return this;
		}

		public override ClayPit Unpack(ClayPit obj)
		{
			obj.startHeight = startHeight;
			obj.stack.Add(stackCount);
			obj.resourcesStored.Set(6, internalTools);
			return obj;
		}
	}

	private ResourceAmount resourcesStored = new ResourceAmount();

	private bool halted;

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	public YieldProducer yieldProducer;

	private float startHeight;

	public float terrainDrop = 0.25f;

	private const int frameSpread = 20;

	private int updateFrame = SRand.srand.Next(0, 20);

	private PlacementValidationResult result;

	protected override void Awake()
	{
		base.Awake();
		yieldProducer = GetComponent<YieldProducer>();
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
	}

	protected override void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		if (validationResult != PlacementValidationResult.Valid)
		{
			return;
		}
		validationResult = PlacementValidationResult.TooFarFromWater;
		Vector3 vector = World.inst.SnapToGrid2DR(transform.position);
		int num = (int)Mathff.Clamp(vector.x - 2f, 0f, World.inst.GridWidth);
		int num2 = (int)Mathff.Clamp(vector.x + 3f, 0f, World.inst.GridWidth - 1);
		int num3 = (int)Mathff.Clamp(vector.z - 2f, 0f, World.inst.GridHeight);
		int num4 = (int)Mathff.Clamp(vector.z + 3f, 0f, World.inst.GridHeight - 1);
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num; j <= num2; j++)
			{
				float r = Water.inst.distanceDynamicWaterTextureFinished.GetPixel(j, i).r;
				float num5 = DynamicWater.inst.simplifiedWaterGrid[j + i * World.inst.GridWidth];
				if ((j == (int)vector.x || j == (int)vector.x + 1) && (i == (int)vector.z || i == (int)vector.z + 1))
				{
					if (num5 > 0f)
					{
						validationResult = PlacementValidationResult.CannotBuildOnWater;
						return;
					}
					if (r < 4f)
					{
						validationResult = PlacementValidationResult.Valid;
					}
				}
				else if (World.inst.GetCellData(j, i).Type == TerrainType.Water)
				{
					validationResult = PlacementValidationResult.Valid;
				}
			}
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (currFrame % 20 == updateFrame && b.IsBuilt() && b.IsOpen())
		{
			CheckProductionPipeline();
			if (result != PlacementValidationResult.Valid)
			{
				b.thought.thought = ThoughtBubbleSystem.Thought.GeneralError;
				b.thought.visible = true;
			}
			else
			{
				b.thought.visible = false;
			}
		}
	}

	private void OnInit()
	{
		customProductionItems[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = productionIcon,
			type = BuildingProductionUI.CustomProductionItem.CustomType.Infinite,
			locTerm = "custom_production_cost_terrainclay"
		};
		resourceStorageMax.Set(stack.resourceID, stack.MaxCapacity());
		cullingGroup = new CullingGroup();
		cullingGroup.onStateChanged = stack.StateChangedMethod;
		cullingGroup.SetBoundingSpheres(spheres);
		cullingGroup.SetBoundingSphereCount(1);
		cullingGroup.targetCamera = Cam.inst.cam;
	}

	private void OnPlayerPlacement()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	private void OnFinishedLoad()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	private void OnBuilt()
	{
		TerrainGen.inst.MakeSquareDepression((int)b.transform.position.x, (int)b.transform.position.z, 1, 1, 1, terrainDrop);
	}

	private void InitGatherJob(FreeResourceGathererJob j)
	{
		j.searchUpdate.SetFrameSpread(30);
		j.Configure(6, null);
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
		for (int i = 2; i < b.jobs.Count; i++)
		{
			if (!b.VerifyJobIs(i, typeof(Job)))
			{
				b.SetAndAddJob(i, new Job(b));
			}
		}
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
		CheckProductionPipeline();
	}

	public void CheckProductionPipeline()
	{
		result = PlacementValidationResult.Valid;
		PlacementValidation(ref result);
		yieldProducer.PauseYield = (halted = stack.Count() >= stack.MaxCapacity() || result != PlacementValidationResult.Valid);
	}

	private void OnBuildingPlacement(bool undo)
	{
		startHeight = TerrainGen.inst.GetTileHeight(b.GetCell());
		if (undo)
		{
			TerrainGen.inst.UpdateTerrainDeformations();
		}
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
		return customProductionItems;
	}

	public override float GetProgress()
	{
		return yieldProducer.GetYieldProgress();
	}

	public override int GetTotalBonus()
	{
		return 0;
	}

	public override string GetCustomText()
	{
		return null;
	}

	public override string GetError()
	{
		if (result != PlacementValidationResult.Valid)
		{
			return ScriptLocalization.PVRTooFarFromWater;
		}
		if (stack.Count() >= stack.MaxCapacity())
		{
			return string.Format(ScriptLocalization.workerui_error_internalstoragefull, "<sprite name=icon_clay>");
		}
		return null;
	}
}
