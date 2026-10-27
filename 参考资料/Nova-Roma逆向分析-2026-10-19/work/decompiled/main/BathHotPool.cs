using System;
using Assets.Code;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class BathHotPool : BathPool, IResourceStorageBase, IOutputInfo
{
	[Serializable]
	public class BathHotPoolSaveData : SaveClass<BathHotPool, BathHotPoolSaveData>
	{
		public int currCharcoalStorage;

		public float consumptionTime = float.MaxValue;

		public override BathHotPoolSaveData Pack(BathHotPool obj)
		{
			currCharcoalStorage = obj.currCharcoalStorage;
			consumptionTime = obj.consumptionTime;
			return this;
		}

		public override BathHotPool Unpack(BathHotPool obj)
		{
			obj.currCharcoalStorage = Mathff.Max(0, currCharcoalStorage);
			obj.consumptionTime = consumptionTime;
			return obj;
		}
	}

	public ParticleSystem steamFX;

	public GameObject waterObj;

	[NonSerialized]
	public DynamicMesh dMesh;

	public int maxCharcoalStorage = 5;

	public int consumeAmt = 1;

	public int currCharcoalStorage;

	[NonSerialized]
	public float consumptionTime = float.MaxValue;

	public bool HasCharcoal()
	{
		return currCharcoalStorage >= consumeAmt;
	}

	public void ConsumeCharcoal()
	{
		if (HasCharcoal())
		{
			currCharcoalStorage -= consumeAmt;
			consumptionTime = 0f;
			ResourceStatistics.AddConsumption(b.LandMass(), "Bathhouse", 3, consumeAmt);
		}
	}

	public bool IsHeated()
	{
		return BathManager.inst.bathCells[b.GetCell().index].pGroup.isHeated;
	}

	protected override void AwakeInternal()
	{
		dMesh = GetComponent<DynamicMesh>();
	}

	public override void OnBuildingPlacement(bool undo)
	{
		base.OnBuildingPlacement(undo);
		if (!undo)
		{
			if (LoadSave.Loading && b.IsBuilt())
			{
				dMesh.OnAdded();
			}
		}
		else if (b.IsBuilt())
		{
			dMesh.OnRemoved();
		}
	}

	public override void OnBuilt()
	{
		base.OnBuilt();
		dMesh.OnAdded();
	}

	public override void OnAddJobs()
	{
		base.OnAddJobs();
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				FreeResourceGathererJob freeResourceGathererJob = new FreeResourceGathererJob(b, _consumeOnPickup: true);
				freeResourceGathererJob.initialConstraintType = 3;
				b.SetAndAddJob(i, freeResourceGathererJob);
			}
		}
	}

	public override void TryEnableIdleJobs()
	{
		if (!isIdleJobsEnabled && hasWater && IsHeated())
		{
			for (int i = 0; i < b.attractionJobs.Count; i++)
			{
				b.attractionJobs[i].ManualAssignment = false;
			}
			isIdleJobsEnabled = true;
		}
		else
		{
			if (!isIdleJobsEnabled || (hasWater && IsHeated()))
			{
				return;
			}
			for (int j = 0; j < b.attractionJobs.Count; j++)
			{
				Job job = b.attractionJobs[j];
				job.ManualAssignment = true;
				if (job.HasEmployee())
				{
					job.ReleaseEmployee();
				}
			}
			isIdleJobsEnabled = false;
		}
	}

	public override void UpdateWater(bool doWater)
	{
		base.UpdateWater(doWater);
		Util.SetActive(waterObj, doWater);
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		int num = Mathff.Min(maxCharcoalStorage - currCharcoalStorage, resources.Get(3));
		if (num > 0)
		{
			currCharcoalStorage += num;
			resources.Add(3, -num);
		}
	}

	int IResourceStorageBase.SpaceAvailable(int resourceID)
	{
		if (resourceID != 3)
		{
			return 0;
		}
		return maxCharcoalStorage - currCharcoalStorage;
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	string IOutputInfo.GetError()
	{
		if (!hasWater)
		{
			return ScriptLocalization.workerui_outputinfoui_error_bathpool_nowater;
		}
		BathManager.BathCell bathCell = BathManager.inst.bathCells[b.GetCell().index];
		if (b.GetWorkerPercent() < 1f)
		{
			return ScriptLocalization.NeedsFullStaff;
		}
		if (bathCell.pGroup != null && consumptionTime <= 0f && !bathCell.pGroup.isHeated)
		{
			return ScriptLocalization.workerui_outputinfoui_error_bathhotpool_waitburn;
		}
		return string.Empty;
	}
}
