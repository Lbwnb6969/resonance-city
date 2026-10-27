using UnityEngine;

public class GrapeSmasherJob : Job
{
	private int currStatus;

	public Transform idleT;

	public Transform targetT;

	public const int STATUS_IDLE = 0;

	public const int STATUS_MOVE_TO_GRAPES = 1;

	public const int STATUS_STOMP_GRAPES = 2;

	public const int STATUS_MOVE_TO_IDLE = 3;

	private float currJumpTime;

	private float targetJumpTime;

	public int GetStatus()
	{
		return currStatus;
	}

	public GrapeSmasherJob(IEmployer e, Transform idle, Transform target)
		: base(e)
	{
		idleT = idle;
		targetT = target;
	}

	public void SetStatus(int status)
	{
		switch (status)
		{
		case 3:
			if (HasEmployee())
			{
				Employee.MoveToDeferred(idleT.position, Quaternion.Euler(idleT.forward));
				Employee.Offset = Vector3.zero;
			}
			break;
		case 1:
			if (HasEmployee())
			{
				Employee.MoveToDeferred(targetT.position, Quaternion.Euler(targetT.forward));
			}
			currJumpTime = 0f;
			targetJumpTime = SRand.Range(0.1f, 2f);
			break;
		}
		currStatus = status;
	}

	public override void OnEmployeeAssigned()
	{
		base.OnEmployeeAssigned();
		if (currStatus == 3 || currStatus == 0)
		{
			Employee.MoveToDeferred(idleT.position, idleT.rotation);
		}
		else if (currStatus == 1 || currStatus == 2)
		{
			Employee.MoveToDeferred(targetT.position, targetT.rotation);
		}
	}

	public override void UpdateWithEmployee(float dt)
	{
		base.UpdateWithEmployee(dt);
		Vector3 pos = Employee.Pos;
		switch (currStatus)
		{
		case 1:
			if (Mathff.DistSqrd(pos, targetT.position) < 0.1f)
			{
				SetStatus(2);
			}
			break;
		case 2:
			if (Mathff.DistSqrd(pos, targetT.position) > 0.1f)
			{
				break;
			}
			currJumpTime += dt;
			if (currJumpTime >= targetJumpTime)
			{
				float num = (currJumpTime - targetJumpTime) * 2f;
				if (num > 1f)
				{
					currJumpTime = 0f;
					targetJumpTime = SRand.Range(0.1f, 2f);
					break;
				}
				Vector3 offset = Employee.Offset;
				offset.y = Mathff.Lerp(offset.y, Player.inst.walkBounce.Evaluate(num) * 0.1f, num);
				Employee.Offset = offset;
				Employee.UpdateTRS();
			}
			break;
		case 3:
			if (Mathff.DistSqrdXZ(pos, idleT.position) < 0.1f)
			{
				SetStatus(0);
			}
			break;
		case 0:
			break;
		}
	}
}
