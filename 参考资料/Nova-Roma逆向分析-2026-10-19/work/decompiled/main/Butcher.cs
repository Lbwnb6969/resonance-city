using System;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using UnityEngine;

public class Butcher : ProductionBuilding, IResourceStorage, IResourceStorageBase, IProductionInfo
{
	[Serializable]
	public class ButcherSaveData : SaveClass<Butcher, ButcherSaveData>
	{
		private int internalMeat;

		private int internalTools;

		private int stackCount;

		public override ButcherSaveData Pack(Butcher obj)
		{
			internalMeat = obj.resourcesStored.Get(10);
			internalTools = obj.resourcesStored.Get(6);
			stackCount = obj.stack.Count();
			return this;
		}

		public override Butcher Unpack(Butcher obj)
		{
			obj.resourcesStored.Set(10, internalMeat);
			obj.resourcesStored.Set(6, internalTools);
			obj.stack.Add(stackCount);
			return obj;
		}
	}

	private void Awake()
	{
		GetComponent<YieldProducer>().OnUsedTool += YieldProducer_OnUsedTool;
	}

	private bool providerFilter(IResourceProvider x, int type)
	{
		if (x is GraphicalResourceStack graphicalResourceStack)
		{
			if (graphicalResourceStack.b != null && (graphicalResourceStack.b.uniqueNameHash == World.butcherHash || graphicalResourceStack.b.categoryHash == World.granaryHash || graphicalResourceStack.b.categoryHash == World.marketHash))
			{
				return false;
			}
			if (x is MonoBehaviour monoBehaviour && (bool)monoBehaviour.GetComponent<ResourceStackAuto>())
			{
				return false;
			}
		}
		return true;
	}

	protected override void OnAddJobsInternal(ref int idx)
	{
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is FreeResourceGathererJob freeResourceGathererJob)
			{
				freeResourceGathererJob.filterPrimary = providerFilter;
				freeResourceGathererJob.searchUpdate.SetFrameSpread(20);
			}
		}
		base.OnAddJobsInternal(ref idx);
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
}
