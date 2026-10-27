using UnityEngine;

public class IdleJob : Job
{
	public enum IdleBehavior
	{
		Idle,
		Wander,
		Celebrate,
		Bathing,
		Looking,
		IdleLooking
	}

	public IdleBehavior behavior;

	private Timer boredTime = new Timer(SRand.Range(599f, 1000f));

	private Timer posUpdateTime = new Timer(SRand.Range(6f, 15f));

	private Timer idleLookUpdateTime = new Timer(SRand.Range(5f, 8f));

	private Quaternion targetRot;

	private Vector3 nextPos;

	private Vector3 oldPos;

	private float totalTime = float.MaxValue;

	private float magnitudeMul = 0.1f;

	private float bounceSpeed = 2f;

	private int bounceAmount;

	private bool arrived;

	private float wMaxX = 0.2f;

	private float wMaxZ = 0.2f;

	public IdleJob(IEmployer e, IdleBehavior behavior)
		: base(e)
	{
		idleJob = true;
		ManualFreetime = true;
		SetBehavior(behavior);
	}

	public override string GetDescription()
	{
		return base.GetDescription();
	}

	public override void OnEmployeeAssigned()
	{
		nextPos = employer.GetPositionForPerson(Employee).position;
		posUpdateTime.ForceExpire();
		boredTime.Reset();
		base.OnEmployeeAssigned();
	}

	public override void OnEmployeeQuit()
	{
		arrived = false;
		Employee.instancesRef.data[(int)Employee.MeshType].bodyColors.data[Employee.s][Employee.idx] = Employee.bodyColor;
		base.OnEmployeeQuit();
	}

	public void SetBehavior(IdleBehavior b)
	{
		if (Employee != null && behavior == IdleBehavior.Celebrate && b == IdleBehavior.Idle)
		{
			Employee.Offset = Vector3.zero;
		}
		totalTime = float.MaxValue;
		behavior = b;
	}

	public void SetWanderSettings(float maxX, float maxZ)
	{
		wMaxX = maxX;
		wMaxZ = maxZ;
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		if (!arrived && Mathff.DistSqrdXZ(nextPos, villager.Pos) < 0.001f && villager.travelPath.Count == 0)
		{
			arrived = true;
			if (behavior == IdleBehavior.Bathing)
			{
				Employee.instancesRef.data[(int)Employee.MeshType].bodyColors.data[Employee.s][Employee.idx] = Employee.headColor;
			}
		}
		if (arrived)
		{
			if (boredTime.Update(dt))
			{
				boredTime.Duration = SRand.Range(35f, 65f);
				ReleaseEmployee();
				return;
			}
			switch (behavior)
			{
			case IdleBehavior.Wander:
			case IdleBehavior.Bathing:
				if (totalTime <= 1f)
				{
					totalTime += dt * 0.66f;
					Vector3 forward = nextPos - oldPos;
					Quaternion rot = ((forward.sqrMagnitude > 0.0001f) ? Quaternion.Lerp(villager.Rot, Quaternion.LookRotation(forward), totalTime) : villager.Rot);
					villager.Rot = rot;
					villager.Pos = Vector3.Lerp(oldPos, nextPos, totalTime);
				}
				else if (posUpdateTime.Update(dt))
				{
					posUpdateTime.Duration = SRand.Range(0.5f, 4f);
					nextPos = employer.GetPositionForPerson(villager).position;
					nextPos += new Vector3(SRand.Range(0f - wMaxX, wMaxX), 0f, SRand.Range(0f - wMaxZ, wMaxZ));
					totalTime = 0f;
					oldPos = villager.Pos;
				}
				break;
			case IdleBehavior.Celebrate:
				if (bounceAmount < 2)
				{
					if (totalTime >= 1f)
					{
						totalTime = 0f;
						bounceAmount++;
					}
					totalTime = Mathff.Clamp01(totalTime + dt * bounceSpeed);
					float b = Player.inst.walkBounce.Evaluate(totalTime) * 1f * magnitudeMul;
					Vector3 offset = villager.Offset;
					offset.y = Mathff.Lerp(offset.y, b, totalTime);
					villager.Offset = offset;
					villager.UpdateTRS();
				}
				else if (posUpdateTime.Update(dt))
				{
					posUpdateTime.Duration = SRand.Range(3f, 16f);
					totalTime = 0f;
					bounceAmount = 0;
				}
				break;
			case IdleBehavior.Looking:
				if (totalTime <= 1f)
				{
					totalTime += dt;
					float t = Mathf.Clamp01(totalTime * 0.33f);
					float angle = Mathff.Lerp(villager.Rot.y, nextPos.y, t);
					villager.Rot = Quaternion.AngleAxis(angle, Vector3.up);
				}
				else if (posUpdateTime.Update(dt))
				{
					posUpdateTime.Duration = SRand.Range(5f, 8f);
					nextPos.y = SRand.Range(0, 360);
					totalTime = 0f;
				}
				break;
			case IdleBehavior.IdleLooking:
				if (totalTime <= 1f)
				{
					totalTime += dt * 0.25f;
					villager.Rot = Quaternion.Lerp(villager.Rot, targetRot, totalTime);
				}
				else if (idleLookUpdateTime.Update(dt))
				{
					idleLookUpdateTime.Duration = SRand.Range(5f, 8f);
					totalTime = 0f;
					targetRot = villager.Rot * Quaternion.Euler(Vector3.up * SRand.Range(-25, 25));
				}
				break;
			}
		}
		base.UpdateWithEmployee(dt);
	}
}
