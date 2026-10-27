using System;
using Assets.Code;
using Assets.Interface;
using UnityEngine;

public class Winery : ProductionBuilding, IResourceStorage, IResourceStorageBase, IProductionInfo, IEmployer
{
	[Serializable]
	public class WinerySaveData : SaveClass<Winery, WinerySaveData>
	{
		private int internalGrapes;

		private int internalPottery;

		private int stackCount;

		public override WinerySaveData Pack(Winery obj)
		{
			internalGrapes = obj.resourcesStored.Get(12);
			internalPottery = obj.resourcesStored.Get(16);
			stackCount = obj.stack.Count();
			return this;
		}

		public override Winery Unpack(Winery obj)
		{
			obj.resourcesStored.Set(12, internalGrapes);
			obj.resourcesStored.Set(16, internalPottery);
			obj.stack.Add(stackCount);
			return obj;
		}
	}

	public GameObject smashedGrapes;

	public Transform[] grapeTargetPos;

	public Transform[] idlePos;

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (b.IsBuilt() && b.IsOpen())
		{
			bool flag = resourcesStored.Get(12) > 0;
			if (flag != smashedGrapes.activeSelf)
			{
				smashedGrapes.SetActive(flag);
				SetJobStatus(flag ? 1 : 3);
			}
		}
	}

	private void SetJobStatus(int status)
	{
		for (int i = deliverers + gatherers; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is GrapeSmasherJob grapeSmasherJob)
			{
				grapeSmasherJob.SetStatus(status);
			}
		}
	}

	protected override void OnAddJobsInternal(ref int idx)
	{
		base.OnAddJobsInternal(ref idx);
		for (int i = 0; i < 2; i++)
		{
			if (!b.VerifyJobIs(idx, typeof(GrapeSmasherJob)))
			{
				b.SetAndAddJob(idx, new GrapeSmasherJob(this, idlePos[i], grapeTargetPos[i]));
			}
			idx++;
		}
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		ResourceStorageHelper.Deposit(resourcesStored, resourceStorageMax, null, ref resources, b.Center());
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		return null;
	}

	Vector3 IEmployer.GetPosition()
	{
		return b.GetPosition();
	}

	TransformData IEmployer.GetPositionForPerson(Villager p)
	{
		if (!(p.job is GrapeSmasherJob grapeSmasherJob))
		{
			return b.GetPositionForPerson(p);
		}
		switch (grapeSmasherJob.GetStatus())
		{
		case 0:
		case 3:
			return new TransformData
			{
				position = grapeSmasherJob.idleT.position,
				rotation = grapeSmasherJob.idleT.rotation
			};
		case 1:
		case 2:
			return new TransformData
			{
				position = grapeSmasherJob.targetT.position,
				rotation = grapeSmasherJob.targetT.rotation
			};
		default:
			return new TransformData
			{
				position = b.GetPosition()
			};
		}
	}

	bool IEmployer.IsOpen()
	{
		return b.IsOpen();
	}

	void IEmployer.OnAssigned(Villager p)
	{
		b.OnAssigned(p);
	}

	void IEmployer.OnUnAssigned(Villager p)
	{
		b.OnUnAssigned(p);
	}

	void IEmployer.OnJobRemoved(Job j)
	{
		b.OnJobRemoved(j);
	}

	string IEmployer.GetUsedSkill()
	{
		return ((IEmployer)b).GetUsedSkill();
	}

	int IEmployer.GetJobCategory()
	{
		return b.GetJobCategory();
	}

	bool IEmployer.DuringWorkHours(float buffer)
	{
		return b.DuringWorkHours(buffer);
	}

	public float GetStartHour()
	{
		return b.GetStartHour();
	}

	public float GetEndHour()
	{
		return b.GetEndHour();
	}
}
