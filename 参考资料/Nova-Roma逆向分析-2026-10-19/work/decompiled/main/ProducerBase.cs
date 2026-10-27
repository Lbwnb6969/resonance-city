using System;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Interface;
using UnityEngine;

public class ProducerBase : Tickable, IResourceProviderContainer, IResourceStorage, IResourceStorageBase
{
	public GraphicalResourceStack resourceStack;

	protected bool halted;

	public Building b;

	protected TerrainResource terrainResource;

	[SerializeField]
	protected YieldProducer yieldProducer;

	private float timeHalted;

	public string productionPipelineBlockedMsg = "";

	protected void OnInit()
	{
		resourceStack.Clear();
		Init();
		yieldProducer.OnYieldResources += OnYieldResources;
	}

	public void OnBuildingPlacement(bool undo)
	{
		if (!DifficultyManager.inst.currOption.unlimitedResources)
		{
			GetClosestResourceTracker();
		}
	}

	public void GetClosestResourceTracker()
	{
		Cell[] array = new Cell[4];
		World.inst.GetNeighborCells(b.GetCell(), ref array);
		for (int i = 0; i < array.Length; i++)
		{
			TerrainResource terrainResource = array[i].terrainResource;
			if (terrainResource != null && terrainResource.resourceID == yieldProducer.YieldType)
			{
				Vector3 position = terrainResource.transform.position;
				position.y = 0f;
				Vector3 vector = b.Center();
				vector.y = 0f;
				Vector3 lhs = position - vector;
				float num = 0f;
				if (b.uniqueNameHash == World.ironMineHash)
				{
					num = Vector3.Dot(lhs, -b.transform.GetChild(0).transform.forward);
				}
				else if (b.uniqueNameHash == World.quarryHash)
				{
					num = Vector3.Dot(lhs, b.transform.GetChild(0).transform.right);
				}
				if (num > 0f)
				{
					this.terrainResource = terrainResource;
					break;
				}
			}
		}
	}

	public virtual void Init()
	{
	}

	public int LandMass()
	{
		return b.LandMass();
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		FreeResourceManager.inst.AddResourceProviderChecked(resourceStack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(resourceStack);
	}

	public virtual void Deposit(ref ResourceAmount resources)
	{
	}

	public virtual int SpaceAvailable(int resourceID)
	{
		return 0;
	}

	public int StoredPublicResources(int resourceID)
	{
		if (resourceID != resourceStack.resourceID)
		{
			return 0;
		}
		return resourceStack.AvailableAmount();
	}

	public bool AcceptsType(int resourceID)
	{
		return false;
	}

	public bool StoresTypePublic(int resourceID)
	{
		return resourceID == resourceStack.resourceID;
	}

	public Vector3 DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	public void RemoveResources(ResourceAmount amount)
	{
		resourceStack.Remove(amount.Get(resourceStack.resourceID));
	}

	private void OnBuilt()
	{
		halted = false;
		timeHalted = 0f;
		Built();
	}

	public virtual void Built()
	{
	}

	public override void Tick(float dt, int currFrame)
	{
		CheckProductionPipeline(dt);
	}

	public void CheckProductionPipeline(float dt)
	{
		bool flag = resourceStack.Count() >= resourceStack.MaxCapacity();
		if (flag && halted && (bool)Player.inst.keep && productionPipelineBlockedMsg.Length > 0)
		{
			Player.inst.keep.SetAdvisorMessage(productionPipelineBlockedMsg);
		}
		if (flag)
		{
			if (timeHalted < 10f && timeHalted + dt >= 10f)
			{
				Broadcast.StorageFullEvent.Broadcast(new OnStorageFullEvent
				{
					b = b
				});
			}
			timeHalted += dt;
		}
		else
		{
			timeHalted = 0f;
		}
		halted = flag;
		yieldProducer.PauseYield = flag;
	}

	public virtual bool ConsumePrereqs()
	{
		return true;
	}

	private void OnYieldResources(int type, int Yield)
	{
		if (!ConsumePrereqs())
		{
			return;
		}
		if (terrainResource == null && !DifficultyManager.inst.currOption.unlimitedResources)
		{
			GetClosestResourceTracker();
		}
		if (!DifficultyManager.inst.currOption.unlimitedResources && terrainResource != null && terrainResource.AddHarvested(Yield))
		{
			terrainResource = null;
		}
		int num = Yield;
		if (num > 0 && num > 0 && resourceStack.Count() < resourceStack.MaxCapacity())
		{
			if (type == 2 && StreamerEffects.Flag_BetterQuarry)
			{
				num *= 2;
			}
			if (type == 5 && StreamerEffects.Flag_BetterMines)
			{
				num *= 2;
			}
			num = Math.Min(num, resourceStack.MaxCapacity() - resourceStack.Count());
			ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), type, num);
			ResourceStatistics.AddProduction(LandMass(), b.UniqueName, type, num);
			resourceStack.Add(num);
		}
	}

	private void OnDemolished()
	{
		if (resourceStack.Count() > 0)
		{
			FreeResourceManager.inst.GetAutoStackFor(resourceStack.resourceID, resourceStack.Count(), b.GetCell().Position);
		}
	}

	public int MaxStorageFor(int resourceID)
	{
		return resourceStack.maxStackCount;
	}
}
