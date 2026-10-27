using System;
using System.Collections.Generic;
using UnityEngine;

public class JobSystem : MonoBehaviour
{
	[Serializable]
	public class JobCategory
	{
		public class WorkHourGroup
		{
			public float startHour;

			public float endHour;

			public ArrayExtRef<EmployerOpenJobs> employerOpenJobs;
		}

		public class EmployerOpenJobs
		{
			public IEmployer employer;

			public ArrayExtRef<Job> openJobs;
		}

		public int id;

		public string name;

		public Color color;

		public bool isCombatJob;

		public bool isManualJob;

		public bool isMaxInfinite;

		[NonSerialized]
		public bool[] isOpen;

		[NonSerialized]
		public bool[] isCustomJobsAvailableEnabled;

		[NonSerialized]
		public int[] customJobsAvailable;

		[NonSerialized]
		public int[] jobsClosed;

		[NonSerialized]
		public int[] jobsAvailable;

		[NonSerialized]
		public int[] jobsFilled;

		[NonSerialized]
		public ArrayExtRef<WorkHourGroup>[] workHourOpenJobs;

		[NonSerialized]
		public ArrayExt<ArrayExtRef<Job>> jobs;

		[NonSerialized]
		public int defaultPriority;

		[NonSerialized]
		public int defaultPriorityIdx;

		[NonSerialized]
		public int[] priorityIdx;

		public bool TryAddEmptyJob(IEmployer employer, Job job)
		{
			if (employer == null || employer.Equals(null))
			{
				return false;
			}
			int num = employer.LandMass();
			float startHour = employer.GetStartHour();
			float endHour = employer.GetEndHour();
			ArrayExtRef<WorkHourGroup> arrayExtRef = workHourOpenJobs[num];
			int i;
			for (i = 0; i < arrayExtRef.Count; i++)
			{
				WorkHourGroup workHourGroup = arrayExtRef.data[i];
				if (workHourGroup.startHour == startHour && workHourGroup.endHour == endHour)
				{
					break;
				}
			}
			if (i == arrayExtRef.Count)
			{
				WorkHourGroup item = new WorkHourGroup
				{
					startHour = startHour,
					endHour = endHour,
					employerOpenJobs = new ArrayExtRef<EmployerOpenJobs>(1024)
				};
				arrayExtRef.Add(item);
			}
			WorkHourGroup workHourGroup2 = arrayExtRef.data[i];
			for (int j = 0; j < workHourGroup2.employerOpenJobs.Count; j++)
			{
				EmployerOpenJobs employerOpenJobs = workHourGroup2.employerOpenJobs.data[j];
				if (employerOpenJobs.employer == employer)
				{
					if (employerOpenJobs.openJobs.Contains(job))
					{
						return false;
					}
					employerOpenJobs.openJobs.Add(job);
					return true;
				}
			}
			EmployerOpenJobs employerOpenJobs2 = new EmployerOpenJobs
			{
				employer = employer,
				openJobs = new ArrayExtRef<Job>(2024)
			};
			employerOpenJobs2.openJobs.Add(job);
			workHourGroup2.employerOpenJobs.Add(employerOpenJobs2);
			return true;
		}

		public bool TryRemoveEmptyJob(IEmployer employer, Job job)
		{
			if (employer == null || employer.Equals(null))
			{
				return false;
			}
			int num = employer.LandMass();
			float startHour = employer.GetStartHour();
			float endHour = employer.GetEndHour();
			ArrayExtRef<WorkHourGroup> arrayExtRef = workHourOpenJobs[num];
			int i;
			for (i = 0; i < arrayExtRef.Count; i++)
			{
				WorkHourGroup workHourGroup = arrayExtRef.data[i];
				if (workHourGroup.startHour == startHour && workHourGroup.endHour == endHour)
				{
					break;
				}
			}
			if (i == arrayExtRef.Count)
			{
				return false;
			}
			WorkHourGroup workHourGroup2 = arrayExtRef.data[i];
			for (int j = 0; j < workHourGroup2.employerOpenJobs.Count; j++)
			{
				EmployerOpenJobs employerOpenJobs = workHourGroup2.employerOpenJobs.data[j];
				if (employerOpenJobs.employer == employer)
				{
					int num2 = employerOpenJobs.openJobs.IndexOf(job);
					if (num2 == -1)
					{
						return false;
					}
					employerOpenJobs.openJobs.RemoveAt(num2);
					if (employerOpenJobs.openJobs.Count == 0)
					{
						workHourGroup2.employerOpenJobs.RemoveAt(j);
					}
					return true;
				}
			}
			return false;
		}
	}

	public delegate void OnJobCategoryAdded(JobCategory jobCategory);

	[Serializable]
	public class JobSystemSaveData : SaveClass<JobSystem, JobSystemSaveData>
	{
		[Serializable]
		private struct JobCategoryWrapper
		{
			public bool[] isOpen;

			public bool[] isCustomJobsAvailableEnabled;

			public int[] customJobsAvailable;

			public int[] priorityIdx;
		}

		private List<object> cellJobs = new List<object>();

		private SerializableDictionary<int, JobCategoryWrapper> jobCategoriesWrapperMap;

		public override JobSystemSaveData Pack(JobSystem j)
		{
			int numLandMasses = World.inst.NumLandMasses;
			if (jobCategoriesMap.TryGetValue(21, out var value))
			{
				for (int i = 0; i < numLandMasses && i < value.jobs.Count; i++)
				{
					for (int k = 0; k < value.jobs.data[i].Count; k++)
					{
						if (value.jobs.data[i].data[k] is ClearCutterJob { cellToChop: not null } clearCutterJob)
						{
							cellJobs.Add(new SaveEntry
							{
								key = "ClearCutterJob",
								data = new ClearCutterJob.ClearCutterJobSaveData().Pack(clearCutterJob)
							});
						}
					}
				}
			}
			jobCategoriesWrapperMap = new SerializableDictionary<int, JobCategoryWrapper>();
			foreach (KeyValuePair<int, JobCategory> item in jobCategoriesMap)
			{
				int num = Mathf.Min(numLandMasses, item.Value.isOpen.Length);
				JobCategoryWrapper value2 = new JobCategoryWrapper
				{
					isOpen = new bool[num],
					isCustomJobsAvailableEnabled = new bool[num],
					customJobsAvailable = new int[num],
					priorityIdx = new int[num]
				};
				for (int l = 0; l < num; l++)
				{
					value2.isOpen[l] = item.Value.isOpen[l];
					value2.isCustomJobsAvailableEnabled[l] = item.Value.isCustomJobsAvailableEnabled[l];
					value2.customJobsAvailable[l] = item.Value.customJobsAvailable[l];
					value2.priorityIdx[l] = item.Value.priorityIdx[l];
				}
				jobCategoriesWrapperMap.Add(item.Key, value2);
			}
			return this;
		}

		public override JobSystem Unpack(JobSystem j)
		{
			for (int i = 0; i < cellJobs.Count; i++)
			{
				object obj = cellJobs[i];
				if (obj is SaveEntry saveEntry)
				{
					obj = saveEntry.data;
				}
				if (obj is ClearCutterJob.ClearCutterJobSaveData clearCutterJobSaveData)
				{
					Job j2 = clearCutterJobSaveData.Unpack(new ClearCutterJob(World.inst.GetCellData(clearCutterJobSaveData.x, clearCutterJobSaveData.z)));
					j.AddNewJob(0, j2, 21);
				}
			}
			if (jobCategoriesWrapperMap != null)
			{
				foreach (KeyValuePair<int, JobCategoryWrapper> item in jobCategoriesWrapperMap)
				{
					if (jobCategoriesMap.TryGetValue(item.Key, out var value))
					{
						for (int k = 0; k < World.inst.NumLandMasses && k < item.Value.isOpen.Length; k++)
						{
							value.isOpen[k] = item.Value.isOpen[k];
							value.isCustomJobsAvailableEnabled[k] = item.Value.isCustomJobsAvailableEnabled[k];
							value.customJobsAvailable[k] = item.Value.customJobsAvailable[k];
							value.priorityIdx[k] = item.Value.priorityIdx[k];
						}
					}
				}
			}
			for (int l = 0; l < World.inst.NumLandMasses; l++)
			{
				inst.UpdatePriority(l);
			}
			return j;
		}
	}

	public static JobSystem inst;

	public static Dictionary<int, JobCategory> jobCategoriesMap = new Dictionary<int, JobCategory>();

	public static ArrayExt<JobCategory> jobCategories = new ArrayExt<JobCategory>(64);

	public static ArrayExt<ArrayExt<JobCategory>> priorityJobCategories = new ArrayExt<ArrayExt<JobCategory>>(64);

	public OnJobCategoryAdded onJobCategoryAdded;

	public const int INITIAL_LANDMASS_COUNT = 8;

	private Timer assignmentTimer = new Timer(0.1f);

	internal int loadTickDelay = 1;

	private bool lockRemoval;

	private List<Job> deferredRemoval = new List<Job>();

	private ArrayExt<Job> toRemove = new ArrayExt<Job>(64);

	private int prevOpenJobIdx;

	private void Awake()
	{
		inst = this;
		priorityJobCategories = new ArrayExt<ArrayExt<JobCategory>>(8);
		for (int i = 0; i < 8; i++)
		{
			priorityJobCategories.Add(new ArrayExt<JobCategory>(64));
		}
		JobCategories jobCategories = Resources.Load<JobCategories>("JobCategories");
		for (int j = 0; j < jobCategories.jobCategories.Count; j++)
		{
			AddJobCategory(jobCategories.jobCategories[j]);
		}
	}

	public void SetLandmassCount(int numLandmasses)
	{
		if (numLandmasses == priorityJobCategories.Count)
		{
			return;
		}
		priorityJobCategories = new ArrayExt<ArrayExt<JobCategory>>(numLandmasses);
		for (int i = 0; i < numLandmasses; i++)
		{
			priorityJobCategories.Add(new ArrayExt<JobCategory>(64));
		}
		for (int j = 0; j < jobCategories.Count; j++)
		{
			JobCategory jobCategory = jobCategories.data[j];
			ArrayExt<ArrayExtRef<Job>> jobs = jobCategory.jobs;
			for (int k = numLandmasses; k < jobs.Count; k++)
			{
			}
			jobCategory.jobs = new ArrayExt<ArrayExtRef<Job>>(numLandmasses);
			for (int l = 0; l < numLandmasses; l++)
			{
				jobCategory.jobs.Add((l < jobs.Count) ? jobs.data[l] : new ArrayExtRef<Job>(100));
			}
			jobCategory.isOpen = new bool[numLandmasses];
			jobCategory.jobsClosed = new int[numLandmasses];
			jobCategory.jobsAvailable = new int[numLandmasses];
			jobCategory.jobsFilled = new int[numLandmasses];
			jobCategory.isCustomJobsAvailableEnabled = new bool[numLandmasses];
			jobCategory.customJobsAvailable = new int[numLandmasses];
			jobCategory.priorityIdx = new int[numLandmasses];
			jobCategory.workHourOpenJobs = new ArrayExtRef<JobCategory.WorkHourGroup>[numLandmasses];
			for (int m = 0; m < numLandmasses; m++)
			{
				jobCategory.isOpen[m] = true;
				jobCategory.priorityIdx[m] = jobCategory.defaultPriorityIdx;
				jobCategory.workHourOpenJobs[m] = new ArrayExtRef<JobCategory.WorkHourGroup>(1024);
			}
		}
		for (int n = 0; n < numLandmasses; n++)
		{
			UpdatePriority(n);
		}
	}

	public void Reset()
	{
		toRemove.ClearFast();
		if (jobCategoriesMap.TryGetValue(21, out var value))
		{
			for (int i = 0; i < value.jobs.Count; i++)
			{
				for (int j = 0; j < value.jobs.data[i].Count; j++)
				{
					if (value.jobs.data[i].data[j] is ClearCutterJob)
					{
						toRemove.Add(value.jobs.data[i].data[j]);
					}
				}
			}
		}
		for (int k = 0; k < toRemove.Count; k++)
		{
			RemoveJob(toRemove.data[k]);
		}
		for (int l = 0; l < jobCategories.Count; l++)
		{
			value = jobCategories.data[l];
			for (int m = 0; m < value.jobs.Count; m++)
			{
				value.isOpen[m] = true;
				value.jobsClosed[m] = 0;
				value.jobsAvailable[m] = 0;
				value.jobsFilled[m] = 0;
				value.isCustomJobsAvailableEnabled[m] = false;
				value.customJobsAvailable[m] = 0;
				value.priorityIdx[m] = value.defaultPriorityIdx;
				value.jobs.data[m].ClearFast();
				value.workHourOpenJobs[m].Clear();
			}
		}
		for (int n = 0; n < priorityJobCategories.Count; n++)
		{
			UpdatePriority(n);
		}
	}

	public void AddJobCategory(JobCategory jCategory, int priority = -1)
	{
		if (!jobCategoriesMap.ContainsKey(jCategory.id))
		{
			jobCategoriesMap.Add(jCategory.id, jCategory);
			int count = priorityJobCategories.Count;
			jCategory.jobs = new ArrayExt<ArrayExtRef<Job>>(count);
			jCategory.isOpen = new bool[count];
			jCategory.jobsClosed = new int[count];
			jCategory.jobsAvailable = new int[count];
			jCategory.jobsFilled = new int[count];
			jCategory.isCustomJobsAvailableEnabled = new bool[count];
			jCategory.customJobsAvailable = new int[count];
			jCategory.priorityIdx = new int[count];
			for (int i = 0; i < count; i++)
			{
				jCategory.jobs.Add(new ArrayExtRef<Job>(100));
			}
			jCategory.defaultPriority = ((priority == -1) ? (10 * jobCategories.Count) : priority);
			if (jCategory.id == 37)
			{
				jCategory.defaultPriority = int.MaxValue;
			}
			int num = jobCategories.Count;
			for (int j = 0; j < jobCategories.Count; j++)
			{
				JobCategory jobCategory = jobCategories.data[j];
				if (jCategory.defaultPriority < jobCategory.defaultPriority)
				{
					num = j;
					break;
				}
			}
			jCategory.defaultPriorityIdx = num;
			jobCategories.Insert(num, jCategory);
			for (int k = 0; k < count; k++)
			{
				jCategory.isOpen[k] = true;
				jCategory.jobsClosed[k] = 0;
				jCategory.jobsAvailable[k] = 0;
				jCategory.jobsFilled[k] = 0;
				jCategory.isCustomJobsAvailableEnabled[k] = false;
				jCategory.customJobsAvailable[k] = 0;
				jCategory.priorityIdx[k] = num;
				priorityJobCategories.data[k].Insert(num, jCategory);
			}
			onJobCategoryAdded?.Invoke(jCategory);
		}
		else
		{
			Debug.LogError("Duplicate Job Category");
		}
	}

	private void Update()
	{
		if (LoadSave.Loading || MapEditorController.IsEditing)
		{
			return;
		}
		if (loadTickDelay > 0)
		{
			loadTickDelay--;
			return;
		}
		float deltaTime = Time.deltaTime;
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		bool flag = false;
		bool flag2 = assignmentTimer.Update(unscaledDeltaTime);
		bool flag3 = RaiderSystem.inst.IsRaidInProgress() || DragonSpawn.inst.currentDragons.Count > 0;
		lockRemoval = true;
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			bool flag4 = i == Player.inst.FocusedLandMass;
			bool flag5 = Player.inst.HostilesOnLandmass(i).Count > 0;
			int num = -1;
			for (int j = 0; j < priorityJobCategories.data[i].Count; j++)
			{
				JobCategory jobCategory = priorityJobCategories.data[i].data[j];
				int num2 = 0;
				int num3 = 0;
				int num4 = 0;
				int num5 = 0;
				for (int k = 0; k < jobCategory.jobs.data[i].Count; k++)
				{
					Job job = jobCategory.jobs.data[i].data[k];
					job.UpdateAlways(deltaTime);
					if (jobCategory.isOpen[i])
					{
						if (num == -1)
						{
							bool flag6 = !job.HasEmployee();
							bool flag7 = jobCategory.isCustomJobsAvailableEnabled[i];
							if (!flag7 || (flag7 && num5 < jobCategory.customJobsAvailable[i]))
							{
								job.UpdateAssignment(deltaTime);
							}
							if (flag7 && num5 >= jobCategory.customJobsAvailable[i] && job.HasEmployee())
							{
								job.ReleaseEmployee();
							}
							if (flag6 && job.HasEmployee())
							{
								DecreeUI.inst.UpdateCategoryWithChange(i, jobCategory.id, positive: true);
							}
							if (!job.ManualAssignment && job.employer.IsOpen() && !job.HasEmployee() && job.passesWageReq && (!flag7 || (flag7 && num5 < jobCategory.customJobsAvailable[i])))
							{
								num = j;
							}
							if (job.employer.IsOpen() && !job.ManualAssignment)
							{
								num5++;
							}
						}
					}
					else if (!flag && !job.ManualAssignment && job.HasEmployee())
					{
						job.ReleaseEmployee();
						flag = true;
						if (flag4)
						{
							DecreeUI.inst.UpdateCategoryWithChange(i, jobCategory.id, positive: false);
						}
					}
					if (job.HasEmployee())
					{
						job.UpdateWithEmployee(deltaTime);
					}
					if (job.HasEmployee())
					{
						num2++;
					}
					if (!job.employer.IsOpen() || (jobCategory.id == 1 && job.ManualAssignment && !job.doHideIfManual))
					{
						num4++;
					}
					else if (!job.doHideIfManual || !job.ManualAssignment)
					{
						num3++;
					}
				}
				jobCategory.jobsFilled[i] = num2;
				jobCategory.jobsAvailable[i] = num3;
				jobCategory.jobsClosed[i] = num4;
			}
			if (!flag2 || num == -1 || World.inst.AvailableWorkersOnLandMass(i, includeIdleJobs: false) != 0)
			{
				continue;
			}
			bool flag8 = false;
			for (int num6 = priorityJobCategories.data[i].Count - 1; num6 > num; num6--)
			{
				JobCategory jobCategory2 = priorityJobCategories.data[i].data[num6];
				if (!(flag5 | flag3) || !jobCategory2.isCombatJob)
				{
					for (int num7 = jobCategory2.jobs.data[i].Count - 1; num7 >= 0; num7--)
					{
						Job job2 = jobCategory2.jobs.data[i].data[num7];
						if (job2.HasEmployee() && !job2.ManualAssignment && (jobCategory2.id != 37 || job2.Employee.job == job2))
						{
							job2.Employee.QuitJob();
							job2.Employee = null;
							if (flag4 && (bool)DecreeUI.inst)
							{
								DecreeUI.inst.UpdateCategoryWithChange(i, jobCategory2.id, positive: false);
							}
							flag8 = true;
							break;
						}
					}
					if (flag8)
					{
						break;
					}
				}
			}
		}
		for (int l = 0; l < jobCategories.Count; l++)
		{
			JobCategory jobCategory3 = jobCategories.data[l];
			for (int m = 0; m < World.inst.NumLandMasses; m++)
			{
				int n = 0;
				for (int count = jobCategory3.jobs.data[m].Count; n < count; n++)
				{
					jobCategory3.jobs.data[m].data[n].UpdateOpenClosed();
				}
			}
		}
		lockRemoval = false;
		int num8 = 0;
		for (int count2 = deferredRemoval.Count; num8 < count2; num8++)
		{
			RemoveJob(deferredRemoval[num8]);
		}
		deferredRemoval.Clear();
	}

	public Job AddNewJob(IEmployer owner)
	{
		Job job = new Job(owner);
		AddNewJob(job);
		return job;
	}

	public void AddNewJob(Job j)
	{
		int num = j.employer.LandMass();
		j.jobCategory = j.employer.GetJobCategory();
		if (jobCategoriesMap.TryGetValue(j.employer.GetJobCategory(), out var value))
		{
			value.jobs.data[num].Add(j);
		}
		j.OnJobAdded();
	}

	public void AddNewJob(Job j, int jobCategory)
	{
		j.jobCategory = jobCategory;
		int num = j.employer.LandMass();
		if (jobCategoriesMap.TryGetValue(jobCategory, out var value))
		{
			value.jobs.data[num].Add(j);
		}
		j.OnJobAdded();
	}

	public void AddNewJob(int idx, Job j, int jobCategory)
	{
		j.jobCategory = jobCategory;
		int num = j.employer.LandMass();
		if (jobCategoriesMap.TryGetValue(jobCategory, out var value))
		{
			value.jobs.data[num].Insert(idx, j);
		}
		j.OnJobAdded();
	}

	public void RemoveJob(Job job, bool updatePlacement = true)
	{
		if (job.employer != null)
		{
			int jobCategory = job.jobCategory;
			int num = job.employer.LandMass();
			job.BeforeJobRemoved();
			if (job.Employee != null && !GameState.IsQuitting)
			{
				job.ReleaseEmployee(updatePlacement);
			}
			job.OnJobRemoved();
			job.employer.OnJobRemoved(job);
			job.Employee = null;
			job.employer = null;
			if (jobCategoriesMap.TryGetValue(jobCategory, out var value))
			{
				value.jobs.data[num].Remove(job);
			}
		}
	}

	public void RemoveJobDeferred(Job job)
	{
		deferredRemoval.Add(job);
	}

	public void ClearAllJobs()
	{
		for (int i = 0; i < jobCategories.Count; i++)
		{
			JobCategory jobCategory = jobCategories.data[i];
			for (int j = 0; j < jobCategory.jobs.Count; j++)
			{
				ArrayExtRef<Job> arrayExtRef = jobCategory.jobs.data[j];
				for (int k = 0; k < arrayExtRef.Count; k++)
				{
					Job job = arrayExtRef.data[k];
					if (job.Employee != null)
					{
						job.ReleaseEmployee(updatePlacement: false);
					}
					job.OnJobRemoved();
					job.Employee = null;
				}
				jobCategory.jobs.data[j].ClearFast();
			}
		}
		deferredRemoval.Clear();
	}

	public bool TryFreeUpWorkers(ref List<Villager> workers, int amtToFree, int landmass, int[] doIgnore = null)
	{
		int num = 0;
		for (int num2 = priorityJobCategories.data[landmass].Count - 1; num2 >= 0; num2--)
		{
			JobCategory jobCategory = priorityJobCategories.data[landmass].data[num2];
			if (doIgnore != null)
			{
				int num3 = 0;
				while (num3 < doIgnore.Length)
				{
					if (doIgnore[num3] != jobCategory.id)
					{
						num3++;
						continue;
					}
					goto IL_00c6;
				}
			}
			for (int num4 = jobCategory.jobs.data[landmass].Count - 1; num4 >= 0; num4--)
			{
				Job job = jobCategory.jobs.data[landmass].data[num4];
				if (job.HasEmployee() && job.Employee.job == job)
				{
					Villager employee = job.Employee;
					employee.QuitJob();
					workers.Add(employee);
					num++;
					if (num >= amtToFree)
					{
						goto end_IL_00ca;
					}
				}
			}
			continue;
			end_IL_00ca:
			break;
			IL_00c6:;
		}
		return num > 0;
	}

	public void UpdatePriority(int landmass)
	{
		if (landmass == -1)
		{
			return;
		}
		priorityJobCategories.data[landmass].ClearFast();
		for (int i = 0; i < jobCategories.Count; i++)
		{
			JobCategory jobCategory = jobCategories.data[i];
			int index = priorityJobCategories.data[landmass].Count;
			for (int j = 0; j < priorityJobCategories.data[landmass].Count; j++)
			{
				JobCategory jobCategory2 = priorityJobCategories.data[landmass].data[j];
				if (jobCategory.id != 37 && (jobCategory2.id == 37 || jobCategory.priorityIdx[landmass] < jobCategory2.priorityIdx[landmass]))
				{
					index = j;
					break;
				}
			}
			priorityJobCategories.data[landmass].Insert(index, jobCategory);
		}
	}

	public void RemoveCellJobs()
	{
	}

	public void SetCategoryOpen(int landmass, int jobCategoryID, bool isOpen)
	{
		if (jobCategoriesMap.TryGetValue(jobCategoryID, out var value))
		{
			value.isOpen[landmass] = isOpen;
		}
	}

	public bool IsCategoryOpen(int landmass, int jobCategoryID)
	{
		if (jobCategoriesMap.TryGetValue(jobCategoryID, out var value))
		{
			return value.isOpen[landmass];
		}
		return false;
	}

	public Job FindIdleJob(int landmass, Vector3 pos, int radius)
	{
		if (jobCategoriesMap.TryGetValue(37, out var value))
		{
			float num = radius * radius;
			ArrayExtRef<JobCategory.WorkHourGroup> arrayExtRef = value.workHourOpenJobs[landmass];
			for (int i = 0; i < arrayExtRef.Count; i++)
			{
				JobCategory.WorkHourGroup workHourGroup = arrayExtRef.data[i];
				if (!DayNightManager.inst.NowIsBetween(workHourGroup.startHour, workHourGroup.endHour))
				{
					continue;
				}
				for (int j = 0; j < workHourGroup.employerOpenJobs.Count; j++)
				{
					JobCategory.EmployerOpenJobs employerOpenJobs = workHourGroup.employerOpenJobs.data[j];
					if (!employerOpenJobs.employer.IsOpen() || Mathff.DistSqrdXZ(employerOpenJobs.employer.GetPosition(), pos) > num)
					{
						continue;
					}
					ArrayExtRef<Job> openJobs = employerOpenJobs.openJobs;
					for (int k = 0; k < openJobs.Count; k++)
					{
						if (!openJobs.data[k].ManualAssignment)
						{
							return openJobs.data[k];
						}
					}
				}
			}
		}
		return null;
	}

	public Job FindClosestPlaguedJob(int landmass, Vector3 pos)
	{
		Job result = null;
		float num = float.MaxValue;
		ArrayExtRef<JobCategory.WorkHourGroup> arrayExtRef = jobCategoriesMap[64].workHourOpenJobs[landmass];
		for (int i = 0; i < arrayExtRef.Count; i++)
		{
			ArrayExtRef<JobCategory.EmployerOpenJobs> employerOpenJobs = arrayExtRef.data[i].employerOpenJobs;
			for (int j = 0; j < employerOpenJobs.Count; j++)
			{
				JobCategory.EmployerOpenJobs employerOpenJobs2 = employerOpenJobs.data[j];
				if (employerOpenJobs2.employer.IsOpen())
				{
					float num2 = Mathff.DistSqrdXZ(employerOpenJobs2.employer.GetPosition(), pos);
					if (num2 < num)
					{
						num = num2;
						result = employerOpenJobs2.openJobs.data[0];
					}
				}
			}
		}
		return result;
	}

	internal Job FindOpenJob(int landMass, Vector3 pos, int radius, int jobCategory, bool duringWorkhours = false)
	{
		if (jobCategoriesMap.TryGetValue(jobCategory, out var value))
		{
			float num = radius * radius;
			ArrayExtRef<Job> arrayExtRef = value.jobs.data[landMass];
			int count = arrayExtRef.Count;
			IEmployer employer = null;
			int i = 0;
			for (int num2 = count; i < num2; i++)
			{
				int num3 = (prevOpenJobIdx + i) % count;
				Job job = arrayExtRef.data[num3];
				if (job.HasEmployee() || employer == job.employer)
				{
					continue;
				}
				if (duringWorkhours && !job.employer.DuringWorkHours())
				{
					employer = job.employer;
					continue;
				}
				if (Mathff.DistSqrdXZ(job.employer.GetPosition(), pos) <= num)
				{
					prevOpenJobIdx = num3;
					return job;
				}
				employer = job.employer;
			}
		}
		return null;
	}
}
