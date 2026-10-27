using System;
using System.Collections.Generic;
using System.Globalization;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.Serialization;
using Assets.Code.Jobs;
using I2.Loc;
using UnityEngine;

public class Job
{
	[Serializable]
	public class JobSaveData<T, S> : SaveClass<T, S> where T : Job where S : JobSaveData<T, S>
	{
		private Guid employee = Guid.Empty;

		[OptionalField(VersionAdded = 2)]
		private bool manual;

		[OptionalField(VersionAdded = 3)]
		private bool paid;

		private VillagerSystem.MeshType meshType;

		[OptionalField(VersionAdded = 4)]
		private bool doHideIfManual;

		public override S Pack(T obj)
		{
			meshType = obj.meshType;
			manual = obj.ManualAssignment;
			doHideIfManual = obj.doHideIfManual;
			if (obj.employee != null)
			{
				employee = obj.employee.guid;
			}
			return (S)this;
		}

		public override T Unpack(T obj)
		{
			obj.ManualAssignment = manual;
			obj.meshType = meshType;
			obj.doHideIfManual = doHideIfManual;
			if (employee != Guid.Empty)
			{
				Villager worker = Player.inst.GetWorker(employee);
				if (worker != null)
				{
					obj.AssignEmployee(worker);
				}
			}
			return obj;
		}
	}

	[Serializable]
	public class GenericJobSaveData : JobSaveData<Job, GenericJobSaveData>
	{
		public override GenericJobSaveData Pack(Job j)
		{
			return base.Pack(j);
		}

		public override Job Unpack(Job j)
		{
			return base.Unpack(j);
		}
	}

	public static int frameID;

	public bool ManualAssignment;

	public bool ManualFreetime;

	public bool doHideIfManual;

	public IEmployer employer;

	private Villager employee;

	private bool assigned;

	public bool idleJob;

	protected FrameUpdater updater;

	internal VillagerSystem.MeshType meshType;

	public int jobCategory;

	protected bool assignedCheck;

	[NonSerialized]
	public bool passesWageReq = true;

	public Villager Employee
	{
		get
		{
			return employee;
		}
		set
		{
			employee = value;
			assigned = employee != null;
		}
	}

	public Job(IEmployer e)
	{
		employer = e;
		updater = new FrameUpdater(ref frameID, 30);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public bool HasEmployee()
	{
		return assigned;
	}

	public virtual void OnEmployeeAssigned()
	{
		Employee.MeshType = meshType;
		assignedCheck = true;
		if (JobSystem.jobCategoriesMap.TryGetValue(jobCategory, out var value))
		{
			value.TryRemoveEmptyJob(employer, this);
		}
	}

	public virtual void OnEmployeeQuit()
	{
		Employee.MeshType = VillagerSystem.MeshType.Default;
		assignedCheck = false;
		if (JobSystem.jobCategoriesMap.TryGetValue(jobCategory, out var value))
		{
			value.TryAddEmptyJob(employer, this);
		}
	}

	public virtual void OnJobAdded()
	{
		if (JobSystem.jobCategoriesMap.TryGetValue(jobCategory, out var value))
		{
			value.TryAddEmptyJob(employer, this);
		}
	}

	public virtual void OnJobRemoved()
	{
		if (JobSystem.jobCategoriesMap.TryGetValue(jobCategory, out var value))
		{
			value.TryRemoveEmptyJob(employer, this);
		}
	}

	public virtual void BeforeJobRemoved()
	{
	}

	public virtual string GetDescription()
	{
		string text = string.Empty;
		if (employer != null)
		{
			if (employer is MonoBehaviour monoBehaviour)
			{
				Building component = monoBehaviour.GetComponent<Building>();
				if (component != null)
				{
					text = ((!idleJob) ? (text + string.Format(LocalizationManager.GetTranslation("personui_job_title"), component.FriendlyName) + Environment.NewLine) : (text + string.Format(LocalizationManager.GetTranslation("personui_idlejob_desc"), component.FriendlyName) + Environment.NewLine));
				}
			}
			if (employer is EditTerrainProject)
			{
				text = text + string.Format(LocalizationManager.GetTranslation("personui_job_title"), ScriptLocalization.unlockkey_terrainengineering_title) + Environment.NewLine;
			}
		}
		if (Employee != null && Employee.currentFreeTimeRoutine is SleepAtHome sleepAtHome && sleepAtHome.IsActive())
		{
			text += (Employee.IsTraveling() ? ScriptLocalization.jobDescriptionTimeOff_headtobed : ScriptLocalization.jobDescriptionTimeOff_sleeping);
		}
		return text;
	}

	public void UpdateOpenClosed()
	{
		if (!employer.IsOpen() && assigned)
		{
			ReleaseEmployee();
		}
	}

	public void DebugJobUpdate()
	{
	}

	public virtual void UpdateAlways(float dt)
	{
	}

	public virtual void UpdateWithEmployee(float dt)
	{
		if (ManualFreetime)
		{
			return;
		}
		updater.Update();
		if (updater.Trigger())
		{
			if (!employer.DuringWorkHours())
			{
				employee.FreeTime(_freeTime: true);
			}
			else
			{
				employee.FreeTime(_freeTime: false);
			}
		}
	}

	public void UpdateAssignment(float dt)
	{
		if (!passesWageReq || !employer.IsOpen() || ManualAssignment || assigned || (idleJob && employer is Building building && !building.DuringWorkHours(0f)))
		{
			return;
		}
		Villager villager = null;
		int idx = employer.LandMass();
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(idx);
		Vector3 position = employer.GetPosition();
		string usedSkill = employer.GetUsedSkill();
		if (usedSkill.Length > 0 && !idleJob)
		{
			int hashCode = usedSkill.GetHashCode();
			float num = float.MaxValue;
			int i = 0;
			for (int count = villagersForLandMass.Count; i < count; i++)
			{
				Villager villager2 = villagersForLandMass.data[i];
				if (villager2.job == null && !villager2.sick)
				{
					Vector3 a = villager2.Pos;
					if (villager2.Residence != null)
					{
						a = villager2.Residence.GetPosition();
					}
					float num2 = Mathff.DistXZ(a, position);
					float t = villager2.FindSkill(hashCode);
					num2 *= Mathf.Lerp(1f, 0.75f, t);
					if (num2 < num)
					{
						num = num2;
						villager = villager2;
					}
				}
			}
		}
		else
		{
			float num3 = 99980000f;
			if (idleJob)
			{
				num3 = 400f;
			}
			float num4 = float.MaxValue;
			int j = 0;
			for (int count2 = villagersForLandMass.Count; j < count2; j++)
			{
				Villager villager3 = villagersForLandMass.data[j];
				if (villager3.job == null && !villager3.sick)
				{
					Vector3 a2 = villager3.Pos;
					if (villager3.Residence != null)
					{
						a2 = villager3.Residence.GetPosition();
					}
					float num5 = Mathff.DistSqrdXZ(a2, position);
					if (num5 < num4 && num5 < num3)
					{
						num4 = num5;
						villager = villager3;
					}
				}
			}
		}
		if (villager != null)
		{
			AssignEmployee(villager);
		}
	}

	public void ShadowAssignEmployee(Villager bestWorker)
	{
		Employee = bestWorker;
		employee.ResetCommute();
		OnEmployeeAssigned();
		employee.MoveToDeferred(employer.GetPositionForPerson(employee));
	}

	public void ReleaseEmployee(bool updatePlacement = true)
	{
		if (employee.job == this)
		{
			employee.QuitJob(updatePlacement);
		}
		else
		{
			((LeisureActivity)employee.currentFreeTimeRoutine).End();
		}
	}

	public void AssignEmployee(Villager bestWorker)
	{
		Employee = bestWorker;
		if (bestWorker.job != null)
		{
			bestWorker.QuitJob(updateplacement: false);
			_ = 0;
		}
		employee.job = this;
		if (this is FreeResourceGathererJob freeResourceGathererJob)
		{
			employee.consumeOnPickup = freeResourceGathererJob.ConsumeOnPickup;
		}
		if (this is DeliveryJob)
		{
			employee.consumeOnPickup = false;
		}
		employee.ResetCommute();
		employer.OnAssigned(employee);
		OnEmployeeAssigned();
		employee.MoveToDeferred(employer.GetPositionForPerson(employee));
	}

	public static List<object> PackJobList(List<Job> jobs)
	{
		List<object> list = new List<object>(jobs.Count);
		int i = 0;
		for (int count = jobs.Count; i < count; i++)
		{
			Job job = jobs[i];
			Type type = job.GetType();
			bool flag = false;
			if (type != typeof(Job))
			{
				if (!World.inst.jobTypeMap.TryGetValue(type, out var value))
				{
					Type[] nestedTypes = type.GetNestedTypes();
					int num = 0;
					for (int j = 0; j < nestedTypes.Length; j++)
					{
						if (Util.IsSubclassOfJobSaveClass(nestedTypes[j]))
						{
							num++;
						}
					}
					int num2 = 0;
					value = new Type[num];
					for (int k = 0; k < nestedTypes.Length; k++)
					{
						if (Util.IsSubclassOfJobSaveClass(nestedTypes[k]))
						{
							value[num2++] = nestedTypes[k];
						}
					}
					World.inst.jobTypeMap.Add(type, value);
				}
				foreach (Type obj in value)
				{
					flag = true;
					object arg = Util.CreateInstance(obj);
					object data = Util.GetPackMethod(obj)(arg, new object[1] { job });
					list.Add(new SaveEntry
					{
						key = type.Name,
						data = data
					});
				}
			}
			if (!flag)
			{
				list.Add(new SaveEntry
				{
					key = "Job",
					data = new GenericJobSaveData().Pack(job)
				});
			}
		}
		return list;
	}

	public static void UnpackJobList(List<object> jobsData, IEmployer employer, List<Job> unpackedJobsContainer)
	{
		object[] args = new object[1] { employer };
		object[] array = new object[1];
		for (int i = 0; i < jobsData.Count; i++)
		{
			object obj;
			string text;
			if (jobsData[i] is SaveEntry saveEntry)
			{
				if (saveEntry.data == null)
				{
					Debug.LogWarning("Skipping job '" + saveEntry.key + "' — type not found (mod removed?)");
					continue;
				}
				obj = saveEntry.data;
				text = saveEntry.key;
			}
			else
			{
				obj = jobsData[i];
				if (obj == null)
				{
					Debug.LogWarning("Skipping null job entry in legacy save");
					continue;
				}
				text = null;
			}
			Type type = obj.GetType();
			Type declaringType = type.DeclaringType;
			if (declaringType == null)
			{
				Debug.LogWarning("Skipping job '" + (text ?? type.Name) + "' — no declaring type");
				continue;
			}
			Job job = Activator.CreateInstance(declaringType, BindingFlags.Instance | BindingFlags.Public | BindingFlags.CreateInstance | BindingFlags.OptionalParamBinding, null, args, CultureInfo.CurrentCulture) as Job;
			JobSystem.inst.AddNewJob(job);
			unpackedJobsContainer.Add(job);
			array[0] = job;
			Util.GetUnpackMethod(type)(obj, array);
		}
	}
}
