using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class JoustingArena : Tickable, IOutputInfo, IResourceStorageBase
{
	public enum Status
	{
		Idle,
		RoundingBend,
		Charging,
		GoingToRest,
		Resting,
		GoingToJoust
	}

	[Serializable]
	public class JoustingArenaSaveData : SaveClass<JoustingArena, JoustingArenaSaveData>
	{
		private ResourceAmount storedResources;

		public override JoustingArenaSaveData Pack(JoustingArena obj)
		{
			storedResources = obj.resourcesStored;
			return this;
		}

		public override JoustingArena Unpack(JoustingArena obj)
		{
			obj.resourcesStored = storedResources;
			return obj;
		}
	}

	private Building b;

	private ResourceAmount resourcesStored;

	public ResourceAmount resourceStorageMax;

	private RadiusBonus radiusBonus;

	private bool consumedArmaments;

	private bool consumedWheat;

	private bool consumedApples;

	private Timer consumeTimer = new Timer(20f);

	private int resourcesPerConsume = 1;

	public int baseHappiness = 5;

	private int skillBonusHappiness = 2;

	private float timeWithNoPrereqs;

	public Transform jousterLeft;

	public Transform jousterRight;

	[SerializeField]
	private Status status = Status.Resting;

	private float totalTime;

	private float magnitudeMul = 0.8f;

	private float bounceSpeedMul = 1f;

	private float bounceSpeed = 2f;

	private float bounceMagnitude = 0.03f;

	public Transform[] waypoints;

	private int L;

	private int R = 2;

	public float jousterSpeed = 1f;

	public float chargeSpeedMod = 1f;

	public float rotatingSpeed = 135f;

	private float T;

	public AnimationCurve speedCurve;

	public string GetError()
	{
		if (timeWithNoPrereqs > 120f)
		{
			string text = "";
			if (!consumedApples && !consumedWheat)
			{
				text += "ScriptLocalization.TavernNoFood";
			}
			return text;
		}
		return null;
	}

	public string GetExplanation(OutputTileUI outputTile)
	{
		string text = "";
		if (consumedArmaments)
		{
			text = text + ScriptLocalization.ResourceHappiness.Replace("{0}", ResourceAmount.ResourceIcon(7)).Replace("{1}", baseHappiness.ToString()) + Environment.NewLine;
		}
		if (consumedWheat)
		{
			text = text + ScriptLocalization.ResourceHappiness.Replace("{0}", ResourceAmount.ResourceIcon(0)).Replace("{1}", baseHappiness.ToString()) + Environment.NewLine;
		}
		if (consumedApples)
		{
			text = text + ScriptLocalization.ResourceHappiness.Replace("{0}", ResourceAmount.ResourceIcon(9)).Replace("{1}", baseHappiness.ToString()) + Environment.NewLine;
		}
		text += Environment.NewLine;
		float num = SeasonManager.inst.TimeInYear() / consumeTimer.Duration;
		text = text + ScriptLocalization.ExplanationConsumesResource.Replace("{0}", ResourceAmount.ResourceIcon(7)).Replace("{1}", ((int)num * resourcesPerConsume).ToString()) + Environment.NewLine;
		text = text + ScriptLocalization.ExplanationConsumesResource.Replace("{0}", ResourceAmount.ResourceIcon(0)).Replace("{1}", ((int)num * resourcesPerConsume).ToString()) + Environment.NewLine;
		text = text + ScriptLocalization.ExplanationConsumesResource.Replace("{0}", ResourceAmount.ResourceIcon(9)).Replace("{1}", ((int)num * resourcesPerConsume).ToString()) + Environment.NewLine;
		return text + "\n" + ResourceAmount.ExplainAmounts(resourcesStored, resourceStorageMax);
	}

	public string GetTitle()
	{
		return string.Format("ScriptLocalization.TavernTitle", GetHappiness());
	}

	public void Deposit(ref ResourceAmount resources)
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		resourceAmount.Add(7, resources.Get(7));
		resourceAmount.Add(0, resources.Get(0));
		resourceAmount.Add(9, resources.Get(9));
		ResourceStatistics.AddConsumption(LandMass(), "joustingarena", resourceAmount);
		resourcesStored.Add(in resources);
		resources.Clear();
	}

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	int IResourceStorageBase.SpaceAvailable(int t)
	{
		return resourceStorageMax.Get(t) - resourcesStored.Get(t);
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceID)
	{
		return b.Center() + Vector3.right;
	}

	public override void OnEnableInternal()
	{
		radiusBonus = GetComponent<RadiusBonus>();
		radiusBonus.happinessFunc = GetHappiness;
	}

	private void OnInit()
	{
		timeWithNoPrereqs = 0f;
		b = GetComponent<Building>();
		int workersForFullYield = b.WorkersForFullYield;
		for (int i = 0; i < b.attractionPositions.Length / 2; i++)
		{
			int num = SRand.Range(workersForFullYield, b.personPositions.Length - 1);
			Vector3 position = b.personPositions[workersForFullYield + i].position;
			b.personPositions[workersForFullYield + i].position = b.personPositions[num].position;
			b.personPositions[num].position = position;
		}
	}

	private int GetWaypoint(int index)
	{
		return index switch
		{
			-1 => 3, 
			4 => 0, 
			_ => index, 
		};
	}

	public override void Tick(float dt, int currFrame)
	{
		if (jousterRight.gameObject.activeSelf && jousterLeft.gameObject.activeSelf)
		{
			float num = 0f;
			totalTime += dt * bounceSpeed * bounceSpeedMul;
			if (totalTime > 1f)
			{
				totalTime = 0f;
			}
			num += Player.inst.walkBounce.Evaluate(totalTime) * bounceMagnitude * magnitudeMul;
			float y = Mathff.Lerp(jousterLeft.localPosition.y, num, Mathff.Min(dt * 30f, 1f));
			jousterLeft.localPosition = new Vector3(jousterLeft.localPosition.x, y, jousterLeft.localPosition.z);
			jousterRight.localPosition = new Vector3(jousterRight.localPosition.x, y, jousterRight.localPosition.z);
		}
		if (b.IsBuilt() && b.IsOpen())
		{
			if (resourcesStored.Get(7) - resourcesPerConsume > 0 && (resourcesStored.Get(0) - resourcesPerConsume > 0 || resourcesStored.Get(9) - resourcesPerConsume > 0))
			{
				timeWithNoPrereqs = 0f;
			}
			else
			{
				timeWithNoPrereqs += dt;
			}
			if (consumeTimer.Update(dt))
			{
				TryConsumeResources();
			}
			if (!consumedArmaments && (!consumedWheat || !consumedApples))
			{
				TryConsumeResources();
			}
		}
		if (L > 3)
		{
			L = 0;
		}
		if (R > 3)
		{
			R = 0;
		}
		switch (status)
		{
		case Status.Idle:
			if (timeWithNoPrereqs < 30f && b.IsBuilt() && b.IsOpen())
			{
				if ((L == 1 && R == 3) || (L == 3 && R == 1))
				{
					status = Status.Charging;
				}
				else
				{
					status = Status.RoundingBend;
				}
			}
			else
			{
				status = Status.GoingToRest;
			}
			break;
		case Status.RoundingBend:
			RotateTowardsWayPoint(GetWaypoint(L + 1), GetWaypoint(R + 1), rotatingSpeed);
			if (MoveToWayPoint(L, R, jousterSpeed * 0.3f))
			{
				L++;
				R++;
				status = Status.Idle;
			}
			break;
		case Status.Charging:
			if (RotateTowardsWayPoint(L, R, rotatingSpeed))
			{
				T += Time.deltaTime * chargeSpeedMod;
				jousterLeft.localPosition = Vector3.Lerp(waypoints[GetWaypoint(L - 1)].localPosition, waypoints[L].localPosition, speedCurve.Evaluate(T));
				jousterRight.localPosition = Vector3.Lerp(waypoints[GetWaypoint(R - 1)].localPosition, waypoints[R].localPosition, speedCurve.Evaluate(T));
				if (T >= 1f)
				{
					L++;
					R++;
					status = Status.RoundingBend;
					T = 0f;
				}
			}
			break;
		case Status.Resting:
			if (timeWithNoPrereqs < 30f && b.IsBuilt() && b.IsOpen())
			{
				jousterLeft.gameObject.SetActive(value: true);
				jousterRight.gameObject.SetActive(value: true);
				status = Status.GoingToJoust;
				UpdateAttractionJobs();
			}
			break;
		case Status.GoingToRest:
			RotateTowardsWayPoint(4, 5, rotatingSpeed);
			if (MoveToWayPoint(4, 5, jousterSpeed))
			{
				jousterLeft.localRotation = Quaternion.Euler(0f, 180f, 0f);
				jousterRight.localRotation = Quaternion.Euler(0f, 180f, 0f);
				jousterLeft.gameObject.SetActive(value: false);
				jousterRight.gameObject.SetActive(value: false);
				status = Status.Resting;
				UpdateAttractionJobs();
			}
			break;
		case Status.GoingToJoust:
			RotateTowardsWayPoint(0, 2, rotatingSpeed);
			if (MoveToWayPoint(0, 2, jousterSpeed))
			{
				status = Status.Idle;
				L = 1;
				R = 3;
			}
			break;
		}
	}

	private bool MoveToWayPoint(int leftWayPoint, int rightWayPoint, float speed)
	{
		bool flag = Mathff.MoveTowards(jousterLeft.localPosition, waypoints[leftWayPoint].localPosition, Time.deltaTime * speed, out var actualAmt, out var newPos);
		bool flag2 = Mathff.MoveTowards(jousterRight.localPosition, waypoints[rightWayPoint].localPosition, Time.deltaTime * speed, out actualAmt, out var newPos2);
		jousterLeft.localPosition = newPos;
		jousterRight.localPosition = newPos2;
		return flag & flag2;
	}

	private bool RotateTowardsWayPoint(int leftWayPoint, int rightWayPoint, float rotSpeed)
	{
		Vector3 forward = waypoints[leftWayPoint].localPosition - jousterLeft.localPosition;
		forward.y = 0f;
		Vector3 forward2 = waypoints[rightWayPoint].localPosition - jousterRight.localPosition;
		forward2.y = 0f;
		bool flag = true;
		bool flag2 = true;
		if (forward.magnitude > 0f)
		{
			Quaternion quaternion = Quaternion.LookRotation(forward);
			jousterLeft.localRotation = Quaternion.RotateTowards(jousterLeft.localRotation, quaternion, Time.deltaTime * rotSpeed);
			flag = jousterLeft.localRotation == quaternion;
		}
		if (forward2.magnitude > 0f)
		{
			Quaternion quaternion2 = Quaternion.LookRotation(forward2);
			jousterRight.localRotation = Quaternion.RotateTowards(jousterRight.localRotation, quaternion2, Time.deltaTime * rotSpeed);
			flag2 = jousterRight.localRotation == quaternion2;
		}
		return flag & flag2;
	}

	private bool JobFilter(IResourceProvider x, int type)
	{
		return true;
	}

	private void OnBuilt()
	{
		consumedArmaments = false;
		consumedWheat = false;
		consumedApples = false;
		resourcesStored.Set(7, 5);
		resourcesStored.Set(0, 5);
		resourcesStored.Set(9, 5);
		jousterLeft.gameObject.SetActive(value: true);
		jousterRight.gameObject.SetActive(value: true);
	}

	private void ConfigureFRG(int t, int idx)
	{
		List<Job> jobs = GetComponent<Building>().jobs;
		if (!b.VerifyJobIs(idx, typeof(FreeResourceGathererJob)))
		{
			b.SetAndAddJob(idx, new FreeResourceGathererJob(b, _consumeOnPickup: true));
		}
		(jobs[idx] as FreeResourceGathererJob).Configure(t, JobFilter);
	}

	private void OnAddJobs(Building b)
	{
		ConfigureFRG(7, 0);
		ConfigureFRG(7, 1);
		ConfigureFRG(7, 2);
		ConfigureFRG(0, 3);
		ConfigureFRG(0, 4);
		ConfigureFRG(9, 5);
		ConfigureFRG(9, 6);
	}

	public void UpdateAttractionJobs()
	{
		if (status != Status.Resting)
		{
			for (int i = 0; i < b.attractionPositions.Length; i++)
			{
				if (!b.VerifyJobIs(i, typeof(IdleJob)))
				{
					b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.Celebrate));
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

	private void TryConsumeResources()
	{
		consumedArmaments = false;
		if (resourcesStored.Get(7) - resourcesPerConsume >= 0 && b.IsOpen() && b.GetWorkerPercent() >= 0f)
		{
			resourcesStored.Add(7, -resourcesPerConsume);
			consumedArmaments = true;
		}
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
	}

	public int GetHappiness()
	{
		if (!HappinessModifierSystem.inst.TryGetHappinessModifier(209, out var mod))
		{
			return 0;
		}
		if (!consumedArmaments && !consumedWheat && !consumedApples)
		{
			return mod.negativeHappiness;
		}
		int num = mod.positiveHappiness;
		if (consumedArmaments)
		{
			num += HappinessModifierSystem.inst.GetPositiveHappiness(107);
		}
		if (consumedWheat)
		{
			num += HappinessModifierSystem.inst.GetPositiveHappiness(100);
		}
		if (consumedApples)
		{
			num += HappinessModifierSystem.inst.GetPositiveHappiness(106);
		}
		if (b.DoSkillBonus())
		{
			num += skillBonusHappiness;
		}
		return (int)((float)num * b.GetWorkerPercent());
	}
}
