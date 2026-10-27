using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Code.Jobs;
using UnityEngine;

public class ConstructionForeman : IBuilderEmployer, IEmployer
{
	public struct ConstructionSummary
	{
		public List<Job> jobs;

		public List<ClearCutterJob> clearLandJobs;

		public float resourceProgress;

		public float constructionProgress;

		public bool constructionPaused;

		public int workersAssigned;

		public ResourceAmount notCollected;

		public ResourceAmount collected;

		public float workerPercent;

		public string friendlyName;

		public int totalWorkers;

		public void Summarize(ConstructionForeman[] w)
		{
			if (jobs == null)
			{
				jobs = new List<Job>();
			}
			jobs.Clear();
			if (clearLandJobs == null)
			{
				clearLandJobs = new List<ClearCutterJob>();
			}
			clearLandJobs.Clear();
			resourceProgress = 0f;
			constructionProgress = 0f;
			constructionPaused = false;
			workersAssigned = 0;
			notCollected = new ResourceAmount();
			collected = new ResourceAmount();
			workerPercent = 0f;
			friendlyName = string.Empty;
			if (w.Length != 0)
			{
				friendlyName = w[0].FriendlyName();
				foreach (ConstructionForeman constructionForeman in w)
				{
					jobs.AddRange(constructionForeman.jobs);
					clearLandJobs.AddRange(constructionForeman.clearLandJobs);
					resourceProgress += constructionForeman.resourceProgress;
					constructionProgress += constructionForeman.constructionProgress;
					constructionPaused |= constructionForeman.constructionPaused;
					workersAssigned += constructionForeman.WorkersAssigned;
					notCollected += constructionForeman.ResourcesNotCollected();
					collected += constructionForeman.GetCollectedResources();
					workerPercent += constructionForeman.GetWorkerPercent();
					totalWorkers += constructionForeman.CurrentJobCount();
				}
				resourceProgress /= w.Length;
				constructionProgress /= w.Length;
				workerPercent /= w.Length;
			}
		}

		public void Summarize(ConstructionForeman w)
		{
			jobs = w.jobs;
			clearLandJobs = w.clearLandJobs;
			resourceProgress = w.resourceProgress;
			constructionProgress = w.constructionProgress;
			constructionPaused = w.constructionPaused;
			workersAssigned = w.WorkersAssigned;
			notCollected = w.ResourcesNotCollected();
			collected = w.GetCollectedResources();
			workerPercent = w.GetWorkerPercent();
			totalWorkers = w.CurrentJobCount();
			friendlyName = w.FriendlyName();
		}
	}

	[Serializable]
	public class ConstructionForemanSaveData : SaveClass<ConstructionForeman, ConstructionForemanSaveData>
	{
		private float constructionProgress;

		private bool constructionPaused;

		private ResourceAmount CollectedForBuild;

		private int WorkersForFullYield;

		private int clientIndex;

		public List<object> jobs = new List<object>();

		public override ConstructionForemanSaveData Pack(ConstructionForeman w)
		{
			constructionProgress = w.constructionProgress;
			constructionPaused = w.constructionPaused;
			CollectedForBuild = w.CollectedForBuild;
			WorkersForFullYield = w.MaxBuilders;
			clientIndex = w.clientIndex;
			jobs = Job.PackJobList(w.jobs);
			return this;
		}

		public override ConstructionForeman Unpack(ConstructionForeman w)
		{
			w.constructionProgress = constructionProgress;
			w.constructionPaused = constructionPaused;
			w.CollectedForBuild = CollectedForBuild;
			w.MaxBuilders = WorkersForFullYield;
			w.clientIndex = clientIndex;
			for (int i = 0; i < w.jobs.Count; i++)
			{
				if (w.jobs[i] != null)
				{
					JobSystem.inst.RemoveJob(w.jobs[i]);
				}
			}
			w.jobs.Clear();
			Job.UnpackJobList(jobs, w, w.jobs);
			w.ValidateResourceProgress();
			return w;
		}
	}

	[NonSerialized]
	public List<Job> jobs = new List<Job>();

	[NonSerialized]
	public List<ClearCutterJob> clearLandJobs = new List<ClearCutterJob>();

	private ResourceAmount CollectedForBuild = new ResourceAmount();

	private ResourceAmount TotalPromisedBuildResources = new ResourceAmount();

	private List<PromisedBuildResource> PromisedBuildResources = new List<PromisedBuildResource>();

	private int WorkersAssigned;

	private bool doHideIfManual;

	private int MaxBuilders;

	private float resourceProgress;

	private float constructionProgress;

	private bool constructionPaused = true;

	private IConstructionMaster constructionMaster;

	private int clientIndex;

	public int GetWorkersAssigned => WorkersAssigned;

	public bool ConstructionPaused
	{
		get
		{
			return constructionPaused;
		}
		set
		{
			constructionPaused = value;
			if (value)
			{
				for (int i = 0; i < jobs.Count; i++)
				{
					Job job = jobs[i];
					job.ManualAssignment = true;
					Villager employee = job.Employee;
					if (employee != null)
					{
						employee.QuitJob();
					}
				}
			}
			else
			{
				for (int j = 0; j < jobs.Count; j++)
				{
					jobs[j].ManualAssignment = false;
				}
			}
		}
	}

	public float ConstructionProgress
	{
		get
		{
			return constructionProgress;
		}
		set
		{
			constructionProgress = value;
		}
	}

	public float ResourceProgress
	{
		get
		{
			return resourceProgress;
		}
		set
		{
			resourceProgress = value;
		}
	}

	public void Init(IConstructionMaster constructionMaster, int maxBuilders, int clientIndex, bool doHideIfManualJob = false)
	{
		this.constructionMaster = constructionMaster;
		MaxBuilders = maxBuilders;
		this.clientIndex = clientIndex;
		Reset();
		doHideIfManual = doHideIfManualJob;
	}

	public void Reset()
	{
		WorkersAssigned = 0;
		resourceProgress = 0f;
		constructionProgress = 0f;
		ConstructionPaused = true;
		CollectedForBuild = new ResourceAmount();
		TotalPromisedBuildResources = new ResourceAmount();
		PromisedBuildResources.Clear();
	}

	public string FriendlyName()
	{
		return constructionMaster.GetFriendlyName(clientIndex);
	}

	public ResourceAmount GetCollectedResources()
	{
		return CollectedForBuild;
	}

	public ResourceAmount GetTotalPromisedBuildResources()
	{
		return TotalPromisedBuildResources;
	}

	public void PromiseResources(int _resourceID, int num, Villager villager)
	{
		PromisedBuildResources.Add(new PromisedBuildResource
		{
			resourceID = _resourceID,
			amount = num,
			promiser = villager
		});
		TotalPromisedBuildResources.Add(_resourceID, num);
	}

	public void EndPromise(Villager villager)
	{
		for (int i = 0; i < PromisedBuildResources.Count; i++)
		{
			if (villager == PromisedBuildResources[i].promiser)
			{
				TotalPromisedBuildResources.Add(PromisedBuildResources[i].resourceID, -PromisedBuildResources[i].amount);
				PromisedBuildResources.RemoveAt(i);
				i--;
			}
		}
	}

	public void GetNextResourceNeededToFinishConstruction(out int type, out int amount)
	{
		type = -1;
		amount = 0;
		ResourceAmount trueCost = constructionMaster.GetTrueCost(clientIndex);
		for (int i = 0; i < trueCost.resources.Count; i++)
		{
			Resource resource = trueCost.resources[i];
			int num = resource.Amount - (TotalPromisedBuildResources.Get(resource.resourceID) + CollectedForBuild.Get(resource.resourceID));
			if (resource.resourceID != 4 && num > 0)
			{
				type = resource.resourceID;
				amount = num;
				break;
			}
		}
	}

	public void AddBuildResource(ResourceAmount amount)
	{
		CollectedForBuild.Add(in amount);
		ResourceStatistics.AddConsumption(LandMass(), "construction", amount);
		ValidateResourceProgress();
	}

	public void AddBuildResource(int resourceID, int amount)
	{
		CollectedForBuild.Add(resourceID, amount);
		ResourceStatistics.AddConsumption(LandMass(), "construction", resourceID, amount);
		ValidateResourceProgress();
	}

	private void ValidateResourceProgress()
	{
		ResourceAmount trueCost = constructionMaster.GetTrueCost(clientIndex);
		ResourceAmount collectedForBuild = CollectedForBuild;
		int num = 0;
		resourceProgress = 0f;
		for (int i = 0; i < trueCost.resources.Count; i++)
		{
			int resourceID = trueCost.resources[i].resourceID;
			if (resourceID != 4)
			{
				resourceProgress += (float)collectedForBuild.Get(resourceID) / (float)trueCost.resources[i].Amount;
				num++;
			}
		}
		if (num > 0)
		{
			resourceProgress /= num;
		}
		else
		{
			resourceProgress = 1f;
		}
	}

	public bool HasEnoughToBuild()
	{
		ResourceAmount trueCost = constructionMaster.GetTrueCost(clientIndex);
		for (int i = 0; i < trueCost.resources.Count; i++)
		{
			Resource resource = trueCost.resources[i];
			if (resource.Amount > TotalPromisedBuildResources.Get(resource.resourceID) + CollectedForBuild.Get(resource.resourceID))
			{
				return false;
			}
		}
		return true;
	}

	public void UpdateBuildProgress()
	{
		ValidateResourceProgress();
		constructionProgress += Time.deltaTime / constructionMaster.BuildTimeAtMaxStaff(clientIndex) * (1f / (float)jobs.Count);
		constructionProgress = Mathff.Clamp01(Mathf.Min(resourceProgress, constructionProgress));
	}

	public void GetBoundingFootprint(out int minX, out int minZ, out int maxX, out int maxZ)
	{
		constructionMaster.GetBoundingFootprint(clientIndex, out minX, out minZ, out maxX, out maxZ);
	}

	public Vector3 GetPosition()
	{
		return constructionMaster.GetPosition(clientIndex);
	}

	public ResourceAmount ResourcesNotCollected()
	{
		return constructionMaster.GetTrueCost(clientIndex) - CollectedForBuild;
	}

	public void ConsumeOutstandingCostFromWorld()
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		ResourceAmount trueCost = constructionMaster.GetTrueCost(clientIndex);
		for (int i = 0; i < trueCost.resources.Count; i++)
		{
			Resource resource = trueCost.resources[i];
			if (resource.resourceID != 4)
			{
				int num = resource.Amount - CollectedForBuild.Get(resource.resourceID) - TotalPromisedBuildResources.Get(resource.resourceID);
				if (num > 0)
				{
					resourceAmount.Set(resource.resourceID, num);
				}
			}
		}
		for (int j = 0; j < resourceAmount.resources.Count; j++)
		{
			Resource resource2 = resourceAmount.resources[j];
			FreeResourceManager.inst.RemovePhysicalResources(resource2.resourceID, resource2.Amount, LandMass());
			AddBuildResource(resource2.resourceID, resource2.Amount);
		}
	}

	public void GetLandState(out bool isLandClear, out bool isTerrainWorkClear)
	{
		isLandClear = true;
		isTerrainWorkClear = true;
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				Cell cellData = World.inst.GetCellData(j, i);
				if (!cellData.IsCellClear())
				{
					isLandClear = false;
				}
				isTerrainWorkClear &= !cellData.StructureCompareCategoryAll(World.editTerrainZoneHash);
			}
		}
	}

	public void TryAddClearLandJobs(int max)
	{
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				Cell cellData = World.inst.GetCellData(j, i);
				if (cellData.IsCellClear())
				{
					continue;
				}
				if (clearLandJobs.Count >= max)
				{
					return;
				}
				if (cellData.Busy)
				{
					if (!(cellData.busyObj is ClearCutterJob { jobCategory: not 1 } clearCutterJob))
					{
						continue;
					}
					JobSystem.inst.RemoveJob(clearCutterJob);
				}
				ClearCutterJob clearCutterJob2 = new ClearCutterJob(this);
				clearCutterJob2.StartClearingAt(cellData);
				clearLandJobs.Add(clearCutterJob2);
				JobSystem.inst.AddNewJob(clearCutterJob2, 1);
			}
		}
	}

	public void AddJobs()
	{
		for (int i = jobs.Count; i < MaxBuilders; i++)
		{
			BuilderJob builderJob = new BuilderJob(this);
			builderJob.ManualAssignment = constructionPaused;
			builderJob.doHideIfManual = doHideIfManual;
			JobSystem.inst.AddNewJob(builderJob, 1);
			jobs.Add(builderJob);
		}
	}

	public void AddJobsWithManualAssignment()
	{
		for (int i = jobs.Count; i < MaxBuilders; i++)
		{
			BuilderJob builderJob = new BuilderJob(this);
			builderJob.ManualAssignment = true;
			builderJob.doHideIfManual = doHideIfManual;
			JobSystem.inst.AddNewJob(builderJob, 1);
			jobs.Add(builderJob);
		}
	}

	public void RemoveJobs()
	{
		ArrayExt<Job> arrayExt = new ArrayExt<Job>(clearLandJobs.Count);
		for (int i = 0; i < clearLandJobs.Count; i++)
		{
			if (clearLandJobs[i] != null)
			{
				arrayExt.Add(clearLandJobs[i]);
			}
		}
		clearLandJobs.Clear();
		for (int j = 0; j < arrayExt.Count; j++)
		{
			JobSystem.inst.RemoveJob(arrayExt.data[j]);
		}
		arrayExt.Clear();
		for (int k = 0; k < jobs.Count; k++)
		{
			if (jobs[k] != null)
			{
				JobSystem.inst.RemoveJob(jobs[k]);
			}
		}
		jobs.Clear();
	}

	public int CurrentJobCount()
	{
		return jobs.Count + clearLandJobs.Count;
	}

	public float GetWorkerPercent()
	{
		if (MaxBuilders != 0)
		{
			return (float)WorkersAssigned / (float)MaxBuilders;
		}
		return 1f;
	}

	public TransformData GetPositionForPerson(Villager p)
	{
		if (p.job is ClearCutterJob clearCutterJob)
		{
			return new TransformData
			{
				position = clearCutterJob.cellToChop.Center3D
			};
		}
		int num = -1;
		for (int i = 0; i < jobs.Count; i++)
		{
			if (jobs[i].HasEmployee() && jobs[i].Employee.guid == p.guid)
			{
				num = i;
				break;
			}
		}
		if (num == -1)
		{
			num = 0;
		}
		return constructionMaster.GetPositionForBuilder(clientIndex, num);
	}

	public void OnAssigned(Villager p)
	{
		WorkersAssigned++;
		p.SetWorkPosition(GetPositionForPerson(p));
	}

	public void OnUnAssigned(Villager p)
	{
		WorkersAssigned--;
	}

	public void OnJobRemoved(Job j)
	{
		if (j is ClearCutterJob item)
		{
			clearLandJobs.Remove(item);
		}
	}

	public int LandMass()
	{
		return constructionMaster.LandMass(clientIndex);
	}

	public bool IsOpen()
	{
		return true;
	}

	public string GetUsedSkill()
	{
		return "";
	}

	public int GetJobCategory()
	{
		return 1;
	}

	public bool DuringWorkHours(float buffer)
	{
		return true;
	}

	public float GetStartHour()
	{
		return -1f;
	}

	public float GetEndHour()
	{
		return -1f;
	}
}
