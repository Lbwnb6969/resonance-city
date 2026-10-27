using System;
using Assets;
using Assets.Code;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class SaltEvaporationPool : ExtractionBuilding, IResourceStorage, IResourceStorageBase
{
	[Serializable]
	public class SaltEvaporationPoolSaveData : SaveClass<SaltEvaporationPool, SaltEvaporationPoolSaveData>
	{
		private int stackCount;

		private float startHeight;

		private int internalTools;

		public override SaltEvaporationPoolSaveData Pack(SaltEvaporationPool obj)
		{
			stackCount = obj.stack.Count();
			startHeight = obj.startHeight;
			internalTools = obj.resourcesStored.Get(6);
			return this;
		}

		public override SaltEvaporationPool Unpack(SaltEvaporationPool obj)
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

	public Transform[] saltPiles;

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
		validationResult = PlacementValidationResult.DockNearWater;
		World.inst.SnapToGrid2DR(transform.position);
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ - 1; i <= maxZ + 1; i++)
		{
			for (int j = minX - 1; j <= maxX + 1; j++)
			{
				if (World.inst.GetCellData(j, i).Type == TerrainType.Water)
				{
					validationResult = PlacementValidationResult.Valid;
				}
			}
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b.IsBuilt() && b.IsOpen())
		{
			CheckProductionPipeline();
			float yieldProgress = yieldProducer.GetYieldProgress();
			for (int i = 0; i < saltPiles.Length; i++)
			{
				Vector3 localPosition = saltPiles[i].localPosition;
				localPosition.y = Mathff.Lerp(-0.1f, 0.02f, yieldProgress);
				saltPiles[i].transform.localPosition = localPosition;
				Util.SetActive(saltPiles[i], active: true);
			}
		}
	}

	private void OnInit()
	{
		customProductionItems[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = productionIcon,
			type = BuildingProductionUI.CustomProductionItem.CustomType.Infinite,
			locTerm = "custom_production_cost_saltwater"
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

	private void OnAddJobs(Building b)
	{
		if (!b.VerifyJobIs(0, typeof(DeliveryJob)))
		{
			b.SetAndAddJob(0, new DeliveryJob(b, stack));
		}
		InitDeliveryJob(b.jobs[0] as DeliveryJob);
		for (int i = 1; i < b.jobs.Count; i++)
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
		for (int i = 0; i < saltPiles.Length; i++)
		{
			saltPiles[i].transform.localRotation = Quaternion.Euler(0f, SRand.Range(0, 180), 0f);
		}
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
		yieldProducer.PauseYield = (halted = stack.Count() >= stack.MaxCapacity());
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
		if (stack.Count() >= stack.MaxCapacity())
		{
			return string.Format(ScriptLocalization.workerui_error_internalstoragefull, "<sprite name=icon_salt>");
		}
		return null;
	}
}
