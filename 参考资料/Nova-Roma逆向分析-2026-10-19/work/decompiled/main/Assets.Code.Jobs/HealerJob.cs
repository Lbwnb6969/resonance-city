using System;
using System.Collections.Generic;
using I2.Loc;
using UnityEngine;

namespace Assets.Code.Jobs;

internal class HealerJob : Job
{
	private enum Status
	{
		FindSicko,
		Travel,
		Heal,
		Wait
	}

	[Serializable]
	public class HealerJobSaveData : SaveClass<HealerJob, HealerJobSaveData>
	{
		public override HealerJobSaveData Pack(HealerJob obj)
		{
			return this;
		}

		public override HealerJob Unpack(HealerJob obj)
		{
			return obj;
		}
	}

	private static List<HealerJob> healers = new List<HealerJob>();

	private static int posFrameID = 0;

	private static int sickoFrameID = 0;

	private Status status;

	private FrameUpdater posUpdate;

	private FrameUpdater sickoUpdate;

	private Villager sicko;

	private float waitTime;

	public HealerJob(IEmployer e)
		: base(e)
	{
		healers.Add(this);
		posUpdate = new FrameUpdater(ref posFrameID, 30);
		sickoUpdate = new FrameUpdater(ref sickoFrameID, 5);
		meshType = VillagerSystem.MeshType.Healer;
	}

	public override void OnJobRemoved()
	{
		ReleasePatient();
		healers.Remove(this);
		base.OnJobRemoved();
	}

	private static HealerJob AlreadyTargeted(Villager v)
	{
		for (int i = 0; i < healers.Count; i++)
		{
			if (healers[i].sicko == v)
			{
				return healers[i];
			}
		}
		return null;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		switch (status)
		{
		case Status.FindSicko:
			text += ScriptLocalization.jobHealerDescriptionSearching;
			break;
		case Status.Travel:
			text += ScriptLocalization.jobHealerDescriptionTraveling;
			break;
		case Status.Heal:
			text += ScriptLocalization.jobHealerDescriptionHealing;
			break;
		}
		return text;
	}

	public override void OnEmployeeQuit()
	{
		ReleasePatient();
		base.OnEmployeeQuit();
	}

	public static void AssignPatient(Villager patient)
	{
		if (!patient.sick || patient.paralyzed)
		{
			return;
		}
		HealerJob healerJob = null;
		float num = float.MaxValue;
		for (int i = 0; i < healers.Count; i++)
		{
			if (healers[i].employer.LandMass() == patient.landMass && !(healers[i].Employee == null) && !(healers[i].sicko != null))
			{
				float num2 = Mathff.DistSqrdXZ(healers[i].Employee.Pos, patient.Pos);
				if (num2 < num)
				{
					healerJob = healers[i];
					num = num2;
				}
			}
		}
		if (healerJob != null)
		{
			healerJob.sicko = patient;
			patient.needsDoctor = false;
		}
	}

	private void ReleasePatient()
	{
		if (sicko != null && sicko.sick)
		{
			sicko.needsDoctor = true;
		}
		sicko = null;
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		sickoUpdate.Update();
		posUpdate.Update();
		switch (status)
		{
		case Status.FindSicko:
			if (sicko != null)
			{
				status = Status.Travel;
				villager.MoveToDeferred(sicko.Pos);
			}
			break;
		case Status.Travel:
			if (sicko == null || !sicko.enabled || sicko.paralyzed || !sicko.sick)
			{
				TransitionToFindSick();
				break;
			}
			if (posUpdate.Trigger())
			{
				villager.MoveToDeferred(sicko.Pos);
			}
			if (Mathff.DistSqrdXZ(villager.Pos, sicko.Pos) < 0.05f)
			{
				sicko.HealSickness();
				TransitionToWait();
				sicko = null;
			}
			break;
		case Status.Wait:
		{
			waitTime -= dt;
			if (!(waitTime < 0f))
			{
				break;
			}
			TransitionToFindSick();
			Vector3 pos = villager.Pos;
			int num = (int)Mathff.Clamp(pos.x - 5f, 0f, World.inst.GridWidth - 1);
			int num2 = (int)Mathff.Clamp(pos.x + 5f, 0f, World.inst.GridWidth - 1);
			int num3 = (int)Mathff.Clamp(pos.z - 5f, 0f, World.inst.GridHeight - 1);
			int num4 = (int)Mathff.Clamp(pos.z + 5f, 0f, World.inst.GridHeight - 1);
			for (int i = num3; i <= num4; i++)
			{
				Villager villager2;
				HealerJob healerJob;
				for (int j = num; j <= num2; j++)
				{
					ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(j, i);
					for (int k = 0; k < villagersAt.Count; k++)
					{
						villager2 = villagersAt.data[k];
						if (!villager2.sick || villager2.paralyzed)
						{
							continue;
						}
						bool flag = true;
						healerJob = AlreadyTargeted(villager2);
						if (healerJob != null && healerJob.Employee != null && Mathff.DistSqrdXZ(healerJob.Employee.Pos, villager2.Pos) < Mathff.DistSqrdXZ(pos, villager2.Pos))
						{
							flag = false;
						}
						if (!flag)
						{
							continue;
						}
						goto IL_026e;
					}
				}
				continue;
				IL_026e:
				if (healerJob != null)
				{
					healerJob.sicko = null;
				}
				sicko = villager2;
				break;
			}
			break;
		}
		}
		base.UpdateWithEmployee(dt);
	}

	private void TransitionToWait()
	{
		status = Status.Wait;
		waitTime = 0.25f;
	}

	private void TransitionToFindSick()
	{
		sicko = null;
		status = Status.FindSicko;
		Employee.MoveToDeferred(employer.GetPositionForPerson(Employee));
	}
}
