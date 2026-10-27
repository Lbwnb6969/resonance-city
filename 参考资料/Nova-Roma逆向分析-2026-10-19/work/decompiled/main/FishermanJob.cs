using UnityEngine;

public class FishermanJob : Job
{
	public enum Status
	{
		Fishing,
		WaitingToLoad,
		Away
	}

	public FishingShip fishingShip;

	public Building b;

	public Villager villager;

	private Transform anchor;

	public Status status = Status.Away;

	public FishermanJob(IEmployer e, FishingShip fishingShip, Transform anchor)
		: base(e)
	{
		this.fishingShip = fishingShip;
		b = (employer as MonoBehaviour).GetComponent<Building>();
		this.anchor = anchor;
	}

	public override void OnEmployeeAssigned()
	{
		base.OnEmployeeAssigned();
		villager = Employee;
		status = Status.Away;
	}

	public override void OnEmployeeQuit()
	{
		base.OnEmployeeQuit();
		villager.Offset = Vector3.zero;
		villager.lockMovement = false;
		villager = null;
		status = Status.Away;
	}

	public override void UpdateWithEmployee(float dt)
	{
		base.UpdateWithEmployee(dt);
		if (status != Status.Fishing)
		{
			bool flag = !b.DuringWorkHours(1f) || b.isDemolishing;
			if (flag && !villager.freeTime)
			{
				villager.FreeTime(_freeTime: true);
			}
			else if (!flag && villager.freeTime)
			{
				villager.FreeTime(_freeTime: false);
			}
			if (!flag && !b.isDemolishing)
			{
				status = Status.WaitingToLoad;
			}
			else
			{
				status = Status.Away;
			}
		}
		else
		{
			Vector3 offset = anchor.position - villager.Pos;
			villager.Offset = offset;
			villager.Rot = anchor.rotation;
		}
	}

	public void BoardFishingShip()
	{
		status = Status.Fishing;
		villager.lockMovement = true;
	}

	public void UnboardFishingShip()
	{
		status = Status.Away;
		villager.Offset = Vector3.zero;
		villager.lockMovement = false;
	}

	public bool IsFisherReadyForBoarding()
	{
		if (!b.DuringWorkHours(0f) || b.isDemolishing)
		{
			return false;
		}
		if (status != Status.Fishing && !villager.IsTraveling() && !villager.freeTime && Mathff.Dist(villager.Pos, employer.GetPositionForPerson(villager).position) < 0.1f)
		{
			return true;
		}
		return false;
	}
}
