using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Tavern : Tickable, IOutputInfo, IResourceStorageBase, IWorkerUIDisplay
{
	[Serializable]
	public class TavernSaveData : SaveClass<Tavern, TavernSaveData>
	{
		private int[] resources;

		public override TavernSaveData Pack(Tavern obj)
		{
			resources = new int[obj.gatherTypes.Length];
			for (int i = 0; i < obj.gatherTypes.Length; i++)
			{
				resources[i] = obj.resourcesStored.Get(obj.gatherTypes[i]);
			}
			return this;
		}

		public override Tavern Unpack(Tavern obj)
		{
			if (resources != null && resources.Length == obj.gatherTypes.Length)
			{
				for (int i = 0; i < resources.Length; i++)
				{
					obj.resourcesStored.Set(obj.gatherTypes[i], resources[i]);
				}
			}
			return obj;
		}
	}

	private ArrayExt<int> typesAvailableToCollect = new ArrayExt<int>(5);

	[FreeResourceType]
	public int[] gatherTypes = new int[5] { 9, 11, 12, 8, 10 };

	private int[] gatherTypeOrder;

	public Stack[] resourceStacks;

	private ResourceAmount resourceStorageMax;

	private ResourceAmount resourcesStored = new ResourceAmount();

	private ResourceAmount tempConsumption = new ResourceAmount();

	private float timeWithNoPrereqs;

	private Building b;

	private RadiusBonus radBonus;

	private Timer foodTimer = new Timer(20f);

	private int foodPerEat = 1;

	private bool openForAttraction;

	private const int frameSpread = 10;

	private int updateFrame = SRand.srand.Next(0, 10);

	private int consumeIdx;

	public int GetMaxResourceAmount(int rID)
	{
		return resourceStorageMax.Get(rID);
	}

	public int GetStoredResourceAmount(int rID)
	{
		return resourcesStored.Get(rID);
	}

	private void Start()
	{
		resourceStorageMax = new ResourceAmount();
		for (int i = 0; i < gatherTypes.Length; i++)
		{
			int num = 0;
			for (int j = 0; j < resourceStacks.Length; j++)
			{
				if (resourceStacks[j].resourceID == gatherTypes[i])
				{
					num += resourceStacks[j].stackContainer.childCount;
				}
			}
			resourceStorageMax.Set(gatherTypes[i], num);
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		Building building = b.GetCell().StructureFindByCategory(b.snapBuildingTarget.GetHashCode());
		if (building != null)
		{
			if (!undo)
			{
				b.SnapInside(building);
			}
			else if (building != null)
			{
				building.ResetSnapPointCovers();
			}
		}
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		tempConsumption.Clear();
		for (int i = 0; i < resourceStorageMax.resources.Count; i++)
		{
			int resourceID = resourceStorageMax.resources[i].resourceID;
			tempConsumption.Add(resourceID, resources.Get(resourceID));
		}
		ResourceStatistics.AddConsumption(LandMass(), "tavern", tempConsumption);
		resourcesStored.Add(in resources);
		resources.Clear();
		RefreshVisualStacks();
	}

	private void RefreshVisualStacks()
	{
		for (int i = 0; i < gatherTypes.Length; i++)
		{
			int num = resourcesStored.Get(gatherTypes[i]);
			for (int j = 0; j < resourceStacks.Length; j++)
			{
				if (resourceStacks[j].resourceID == gatherTypes[i])
				{
					int num2 = Mathf.Min(num, resourceStacks[j].maxStackCount);
					resourceStacks[j].Set(num2);
					num -= num2;
					if (num <= 0)
					{
						break;
					}
				}
			}
		}
	}

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	int IResourceStorageBase.SpaceAvailable(int resourceID)
	{
		return resourceStorageMax.Get(resourceID) - resourcesStored.Get(resourceID);
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	string IOutputInfo.GetError()
	{
		if (timeWithNoPrereqs > 60f)
		{
			return ScriptLocalization.workerui_tavernui_noresources_error;
		}
		return null;
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		radBonus = GetComponent<RadiusBonus>();
		radBonus.happinessFunc = GetHappiness;
		radBonus.maxHappinessFunc = GetMaxHappiness;
		timeWithNoPrereqs = 0f;
		b = GetComponent<Building>();
	}

	private void OnAddJobs(Building b)
	{
		if (gatherTypeOrder == null)
		{
			gatherTypeOrder = new int[gatherTypes.Length];
		}
		List<Job> jobs = GetComponent<Building>().jobs;
		for (int i = 0; i < 2; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b, _consumeOnPickup: true));
			}
			(jobs[i] as FreeResourceGathererJob).typeOrder = gatherTypeOrder;
			(jobs[i] as FreeResourceGathererJob).searchRadius = 30f;
		}
	}

	public int GetHappiness()
	{
		float num = 0f;
		bool flag = false;
		for (int i = 0; i < gatherTypes.Length; i++)
		{
			if (resourcesStored.Get(gatherTypes[i]) > 0)
			{
				num++;
				if (gatherTypes[i] == 13 && b.TeamID() == 0 && TechnologyTree.inst.isFineWineUnlocked)
				{
					flag = true;
				}
			}
		}
		num /= (float)gatherTypes.Length;
		int num2 = radBonus.Happiness;
		if (flag)
		{
			num2 += 3;
		}
		return Mathf.CeilToInt((float)num2 * num * b.GetWorkerPercent());
	}

	public int GetMaxHappiness()
	{
		int num = radBonus.Happiness;
		if (b.TeamID() == 0 && TechnologyTree.inst.isFineWineUnlocked)
		{
			for (int i = 0; i < gatherTypes.Length; i++)
			{
				if (gatherTypes[i] == 13)
				{
					num += 3;
					break;
				}
			}
		}
		return num;
	}

	public override void Tick(float dt, int currFrame)
	{
		if (updateFrame != currFrame % 10)
		{
			return;
		}
		if (b.IsBuilt() && b.IsOpen())
		{
			Home.BuildGatherTypeOrder(LandMass(), typesAvailableToCollect, ref gatherTypeOrder, resourcesStored, resourceStorageMax, gatherTypes);
			bool flag = false;
			for (int i = 0; i < gatherTypes.Length; i++)
			{
				if (resourcesStored.Get(gatherTypes[i]) - foodPerEat >= 0)
				{
					flag = true;
					break;
				}
			}
			if (flag)
			{
				timeWithNoPrereqs = 0f;
			}
			else
			{
				timeWithNoPrereqs += dt;
			}
			if (foodTimer.Update(dt))
			{
				TryConsume();
			}
		}
		if (openForAttraction && timeWithNoPrereqs >= 30f)
		{
			openForAttraction = false;
			UpdateAttractionJobs();
		}
		else if (b.IsBuilt() && !openForAttraction && timeWithNoPrereqs < 30f)
		{
			openForAttraction = true;
			UpdateAttractionJobs();
		}
	}

	public void UpdateAttractionJobs()
	{
		if (openForAttraction)
		{
			for (int i = 0; i < b.attractionPositions.Length; i++)
			{
				if (!b.VerifyJobIs(i, typeof(IdleJob)))
				{
					b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.Idle));
				}
			}
		}
		else
		{
			for (int j = 0; j < b.attractionJobs.Count; j++)
			{
				JobSystem.inst.RemoveJob(b.attractionJobs[j]);
			}
			b.attractionJobs.Clear();
		}
	}

	private void TryConsume()
	{
		if (resourcesStored.Get(gatherTypes[consumeIdx]) - foodPerEat > 0 && b.IsOpen() && b.GetWorkerPercent() > 0f)
		{
			resourcesStored.Add(gatherTypes[consumeIdx], -foodPerEat);
		}
		consumeIdx++;
		if (consumeIdx >= gatherTypes.Length)
		{
			consumeIdx = 0;
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
