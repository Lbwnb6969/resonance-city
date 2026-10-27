using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Theater : Tickable, IOutputInfo, IResourceStorageBase, IWorkerUIDisplay
{
	[Serializable]
	public class TheaterSaveData : SaveClass<Theater, TheaterSaveData>
	{
		private ResourceAmount storedResources;

		public override TheaterSaveData Pack(Theater obj)
		{
			storedResources = obj.resourcesStored;
			return this;
		}

		public override Theater Unpack(Theater obj)
		{
			obj.resourcesStored = storedResources;
			return obj;
		}
	}

	private Building b;

	private Animator animator;

	private ResourceAmount resourcesStored = new ResourceAmount();

	public ResourceAmount resourceStorageMax;

	private RadiusBonus radiusBonus;

	public int baseHappiness = 5;

	private int skillBonusHappiness = 2;

	private Timer consumeTimer = new Timer(20f);

	private int resourcesPerConsume = 1;

	private bool consumedWheat;

	private bool consumedApples;

	private bool consumedFish;

	private bool consumedPork;

	public MeshRenderer[] animPersons;

	public GameObject animContainer;

	public EventHandler<OnBuildingOpenClose> onBuildingOpenCloseEvent;

	private bool isAnimationVisible;

	private bool isAttractionJobsEnabled;

	private void Awake()
	{
		b = GetComponent<Building>();
		animator = GetComponent<Animator>();
	}

	private void OnDestroy()
	{
		if (onBuildingOpenCloseEvent != null)
		{
			Broadcast.BuildingOpenClose.Unlisten(b.uniqueNameHash, onBuildingOpenCloseEvent);
		}
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		radiusBonus = GetComponent<RadiusBonus>();
	}

	private void OnInit()
	{
		b = GetComponent<Building>();
		for (int i = 0; i < animPersons.Length; i++)
		{
			Color color = VillagerSystem.inst.headColors[SRand.Range(0, VillagerSystem.inst.headColors.Length)];
			Color color2 = VillagerSystem.inst.bodyColors[SRand.Range(0, VillagerSystem.inst.bodyColors.Length)];
			Color color3 = VillagerSystem.inst.bodyColors[SRand.Range(0, VillagerSystem.inst.hairColors.Length)];
			animPersons[i].material.SetVector("_BodyColor", color2);
			animPersons[i].material.SetVector("_HeadColor", color);
			animPersons[i].material.SetVector("_HairColor", color3);
		}
		Util.SetActive(animContainer, active: false);
		onBuildingOpenCloseEvent = Broadcast.BuildingOpenClose.Listen(b.uniqueNameHash, OnOpenClose);
		Building building = b;
		building.onJobAssignmentUpdated = (Building.OnJobAssignmentUpdated)Delegate.Combine(building.onJobAssignmentUpdated, new Building.OnJobAssignmentUpdated(OnJobAssignmentUpdated));
	}

	private void OnOpenClose(object sender, OnBuildingOpenClose data)
	{
		if (data.targetBuilding == b)
		{
			UpdateAnimationState(b.IsBuilt(), data.open);
		}
	}

	private void UpdateAnimationState(bool isBuilt, bool isOpen)
	{
		bool active = (isBuilt & isOpen) && b.DuringWorkHours(0f);
		if (isAnimationVisible && b.GetWorkerPercent() == 0f)
		{
			active = false;
		}
		isAnimationVisible = active;
		Util.SetActive(animContainer, active);
		Util.SetEnabled(animator, active);
	}

	private void OnAnimationCompleted()
	{
		if (isAnimationVisible && b.GetWorkerPercent() < 1f)
		{
			isAnimationVisible = false;
			Util.SetActive(animContainer, active: false);
			Util.SetEnabled(animator, active: false);
		}
	}

	public string GetError()
	{
		return null;
	}

	public string GetExplanation(OutputTileUI outputTile)
	{
		string text = "";
		if (consumedWheat)
		{
			text = text + ScriptLocalization.ResourceHappiness.Replace("{0}", ResourceAmount.ResourceIcon(0)).Replace("{1}", 1.ToString()) + Environment.NewLine;
		}
		if (consumedApples)
		{
			text = text + ScriptLocalization.ResourceHappiness.Replace("{0}", ResourceAmount.ResourceIcon(9)).Replace("{1}", 1.ToString()) + Environment.NewLine;
		}
		if (consumedFish)
		{
			text = text + ScriptLocalization.ResourceHappiness.Replace("{0}", ResourceAmount.ResourceIcon(8)).Replace("{1}", 1.ToString()) + Environment.NewLine;
		}
		if (consumedPork)
		{
			text = text + ScriptLocalization.ResourceHappiness.Replace("{0}", ResourceAmount.ResourceIcon(10)).Replace("{1}", 1.ToString()) + Environment.NewLine;
		}
		if (b.DoSkillBonus())
		{
			text = text + string.Format(ScriptLocalization.MasterPerformer, skillBonusHappiness) + Environment.NewLine;
		}
		text += Environment.NewLine;
		float num = SeasonManager.inst.TimeInYear() / consumeTimer.Duration;
		text = text + ScriptLocalization.ExplanationConsumesResource.Replace("{0}", ResourceAmount.ResourceIcon(0)).Replace("{1}", ((int)num * resourcesPerConsume).ToString()) + Environment.NewLine;
		text = text + ScriptLocalization.ExplanationConsumesResource.Replace("{0}", ResourceAmount.ResourceIcon(9)).Replace("{1}", ((int)num * resourcesPerConsume).ToString()) + Environment.NewLine;
		text = text + ScriptLocalization.ExplanationConsumesResource.Replace("{0}", ResourceAmount.ResourceIcon(8)).Replace("{1}", ((int)num * resourcesPerConsume).ToString()) + Environment.NewLine;
		text = text + ScriptLocalization.ExplanationConsumesResource.Replace("{0}", ResourceAmount.ResourceIcon(10)).Replace("{1}", ((int)num * resourcesPerConsume).ToString()) + Environment.NewLine;
		return text + "\n" + ResourceAmount.ExplainAmounts(resourcesStored, resourceStorageMax);
	}

	public void Deposit(ref ResourceAmount resources)
	{
		LandMass();
		ResourceAmount resourceAmount = new ResourceAmount();
		resourceAmount.Add(0, resources.Get(0));
		resourceAmount.Add(9, resources.Get(9));
		resourceAmount.Add(8, resources.Get(8));
		resourceAmount.Add(10, resources.Get(10));
		ResourceStatistics.AddConsumption(LandMass(), "theater", resourceAmount);
		resourcesStored.Add(in resources);
		resources.Clear();
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

	public override void Tick(float dt, int currFrame)
	{
		if ((isAnimationVisible && !b.DuringWorkHours(0f)) || (!isAnimationVisible && b.DuringWorkHours(0f)))
		{
			UpdateAnimationState(b.IsBuilt(), b.IsOpen());
		}
	}

	private bool MoveWorkersToStage(bool ignorePerformer = false)
	{
		return true;
	}

	private bool MoveToPosition(GameObject worker, Vector3 targetPos)
	{
		return false;
	}

	private bool JobFilter(IResourceProvider x, int type)
	{
		return true;
	}

	private void ConfigureFRG(int t, int idx)
	{
		List<Job> jobs = b.jobs;
		if (!b.VerifyJobIs(idx, typeof(FreeResourceGathererJob)))
		{
			b.SetAndAddJob(idx, new FreeResourceGathererJob(b, _consumeOnPickup: true));
		}
		(jobs[idx] as FreeResourceGathererJob).Configure(t, JobFilter);
	}

	private void OnBuilt()
	{
		consumedWheat = false;
		consumedApples = false;
		consumedFish = false;
		consumedPork = false;
		resourcesStored.Set(0, 5);
		resourcesStored.Set(9, 5);
		UpdateAnimationState(isBuilt: true, b.IsOpen());
	}

	public void OnCelebratePerformance()
	{
		for (int i = 0; i < b.attractionJobs.Count; i++)
		{
			((IdleJob)b.attractionJobs[i])?.SetBehavior(IdleJob.IdleBehavior.Celebrate);
		}
	}

	public void OnPerformanceConcluded()
	{
		for (int i = 0; i < b.attractionJobs.Count; i++)
		{
			((IdleJob)b.attractionJobs[i])?.SetBehavior(IdleJob.IdleBehavior.Idle);
		}
	}

	private void OnFinishedLoad()
	{
		UpdateAnimationState(b.IsBuilt(), b.IsOpen());
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(Job)))
			{
				b.SetAndAddJob(i, new Job(b));
			}
		}
		for (int j = 0; j < b.attractionPositions.Length; j++)
		{
			if (!b.VerifyJobIs(j, typeof(IdleJob)))
			{
				IdleJob idleJob = new IdleJob(b, IdleJob.IdleBehavior.Idle);
				idleJob.ManualAssignment = true;
				b.SetAndAddJob(j, idleJob);
			}
		}
		isAttractionJobsEnabled = false;
		OnJobAssignmentUpdated(null, isAssigned: false);
	}

	private void OnJobAssignmentUpdated(Villager v, bool isAssigned)
	{
		if (v != null && v.job.idleJob)
		{
			return;
		}
		UpdateAnimationState(b.IsBuilt(), b.IsOpen());
		if (!isAttractionJobsEnabled && b.GetWorkerPercent() >= 1f)
		{
			for (int i = 0; i < b.attractionJobs.Count; i++)
			{
				b.attractionJobs[i].ManualAssignment = false;
			}
			isAttractionJobsEnabled = true;
		}
		else
		{
			if (!isAttractionJobsEnabled || !(b.GetWorkerPercent() < 1f))
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
			isAttractionJobsEnabled = false;
		}
	}

	public void UpdateAttractionJobs()
	{
	}

	private void TryConsumeResources()
	{
		consumedWheat = false;
		if (resourcesStored.Get(0) - resourcesPerConsume >= 0 && b.IsOpen() && b.GetWorkerPercent() >= 0f)
		{
			resourcesStored.Add(0, -resourcesPerConsume);
			consumedWheat = true;
		}
		consumedApples = false;
		if (resourcesStored.Get(9) - resourcesPerConsume >= 0 && b.IsOpen() && b.GetWorkerPercent() >= 0f)
		{
			resourcesStored.Add(9, -resourcesPerConsume);
			consumedApples = true;
		}
		consumedFish = false;
		if (resourcesStored.Get(8) - resourcesPerConsume >= 0 && b.IsOpen() && b.GetWorkerPercent() >= 0f)
		{
			resourcesStored.Add(8, -resourcesPerConsume);
			consumedFish = true;
		}
		consumedPork = false;
		if (resourcesStored.Get(10) - resourcesPerConsume >= 0 && b.IsOpen() && b.GetWorkerPercent() >= 0f)
		{
			resourcesStored.Add(10, -resourcesPerConsume);
			consumedPork = true;
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
