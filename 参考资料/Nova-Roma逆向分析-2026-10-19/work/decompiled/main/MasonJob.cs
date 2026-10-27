using Assets;
using Assets.Code;
using Assets.Code.Interface;
using I2.Loc;
using UnityEngine;

public class MasonJob : Job
{
	public enum Status
	{
		Idle,
		SearchingForResource,
		GoingToResource,
		GoingToDropoff,
		Repairing,
		TimeOff
	}

	private static int posFrameID;

	private FrameUpdater posUpdate;

	private bool forceUpdate;

	public Status status;

	public Mason mason;

	public Building damagedBuilding;

	internal int seekingType;

	internal IResourceProvider resourceProvider;

	private int claimed;

	private Timer SearchUpdate = new Timer(3f);

	private Vector3 dropoffPosition;

	public MasonJob(IEmployer e, Mason m)
		: base(e)
	{
		posUpdate = new FrameUpdater(ref posFrameID, 45);
		mason = m;
		ManualFreetime = true;
	}

	public Status GetStatus()
	{
		return status;
	}

	public void SetStatus(Status s)
	{
		if (s == Status.Idle)
		{
			ResetWorker();
			Employee.MoveToDeferred(employer.GetPositionForPerson(Employee));
		}
		if (s == Status.TimeOff)
		{
			ResetWorker();
		}
		status = s;
	}

	private bool JobFilter(IResourceProvider x, int type)
	{
		if (x.GetType() == typeof(Mason))
		{
			return false;
		}
		return true;
	}

	public override void OnEmployeeAssigned()
	{
		meshType = VillagerSystem.MeshType.HandCart;
		Employee.carryBonus = 3;
		base.OnEmployeeAssigned();
	}

	public override void OnEmployeeQuit()
	{
		Employee.carryBonus = 0;
		base.OnEmployeeQuit();
		ResetWorker();
	}

	public override void OnJobRemoved()
	{
		base.OnJobRemoved();
	}

	public override void UpdateAlways(float dt)
	{
		base.UpdateAlways(dt);
	}

	public override void UpdateWithEmployee(float dt)
	{
		base.UpdateWithEmployee(dt);
		posUpdate.Update();
		damagedBuilding = mason.damagedBuilding;
		switch (status)
		{
		case Status.Idle:
			if (damagedBuilding != null)
			{
				SearchUpdate.ForceExpire();
				SetStatus(Status.SearchingForResource);
			}
			else if (!employer.DuringWorkHours())
			{
				SetStatus(Status.TimeOff);
			}
			break;
		case Status.SearchingForResource:
			if (damagedBuilding == null)
			{
				SetStatus(Status.Idle);
			}
			else
			{
				if (!SearchUpdate.Update(dt))
				{
					break;
				}
				if (!employer.DuringWorkHours())
				{
					SetStatus(Status.TimeOff);
					break;
				}
				int num = 0;
				for (int j = 0; j < FreeResourceSystem.inst.resourceDefs.Count; j++)
				{
					FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[j];
					if (resourceDef.ID != 4)
					{
						num = mason.ResourcesNeededToFinishRepair(resourceDef.ID);
						if (num > 0)
						{
							seekingType = resourceDef.ID;
							break;
						}
					}
				}
				if (num > 0)
				{
					resourceProvider = FreeResourceManager.inst.FindClosestResourceProviderFor(consumer: true, seekingType, Employee.Pos, employer.LandMass(), JobFilter, 30f);
					if (resourceProvider != null && !resourceProvider.Equals(null))
					{
						int count = Mathf.Min(num, Employee.GetCarryCapacity(seekingType));
						claimed = resourceProvider.MakeClaim(seekingType, count, Employee);
						if (claimed > 0)
						{
							mason.PromiseResources(seekingType, claimed, Employee);
							status = Status.GoingToResource;
						}
						else
						{
							resourceProvider = null;
						}
					}
				}
				else
				{
					status = Status.GoingToDropoff;
				}
			}
			break;
		case Status.GoingToResource:
			if (damagedBuilding == null)
			{
				SetStatus(Status.Idle);
			}
			else if (!employer.DuringWorkHours())
			{
				ResetWorker();
				SetStatus(Status.TimeOff);
			}
			else if (resourceProvider == null || resourceProvider.Equals(null))
			{
				(employer as MonoBehaviour).GetComponent<Building>();
				mason.EndPromise(Employee);
				SetStatus(Status.SearchingForResource);
				claimed = 0;
			}
			else if (Vector3.Distance(Employee.Pos, resourceProvider.ResourcePosition(seekingType)) < 0.1f)
			{
				resourceProvider.ReleaseClaim(seekingType, Employee);
				for (int i = 0; i < claimed; i++)
				{
					FreeResource resource = resourceProvider.ProvideResource(seekingType);
					Employee.PickupResource(resource, i == 0);
				}
				resourceProvider = null;
				SetStatus(Status.GoingToDropoff);
				forceUpdate = true;
			}
			else if (posUpdate.Trigger() || forceUpdate)
			{
				forceUpdate = false;
				Employee.MoveToDeferred(resourceProvider.ResourcePosition(seekingType));
			}
			break;
		case Status.GoingToDropoff:
			if (damagedBuilding == null)
			{
				SetStatus(Status.Idle);
				break;
			}
			if (!employer.DuringWorkHours())
			{
				ResetWorker();
				SetStatus(Status.TimeOff);
				break;
			}
			if (posUpdate.Trigger() || forceUpdate)
			{
				forceUpdate = false;
				dropoffPosition = damagedBuilding.GetPos();
				Employee.MoveToDeferred(dropoffPosition);
			}
			(employer as MonoBehaviour).GetComponent<Building>();
			if (Mathff.DistSqrd(Employee.Pos, dropoffPosition) < 0.040000003f)
			{
				mason.AddRepairResource(Employee.GetCarriedType(), Employee.GetCarriedResourceAmount());
				Employee.DestroyHeldResources();
				mason.EndPromise(Employee);
				if (mason.HasEnoughToRepair())
				{
					mason.FinishRepair();
				}
				SearchUpdate.ForceExpire();
				SetStatus(Status.SearchingForResource);
			}
			break;
		case Status.TimeOff:
			if (SearchUpdate.Update(dt))
			{
				if (employer.DuringWorkHours())
				{
					Employee.FreeTime(_freeTime: false);
					SetStatus(Status.Idle);
				}
				else
				{
					Employee.FreeTime(_freeTime: true);
				}
			}
			break;
		case Status.Repairing:
			break;
		}
	}

	public void ResetWorker()
	{
		Employee.DropResources();
		mason.EndPromise(Employee);
		if (resourceProvider != null && !resourceProvider.Equals(null))
		{
			resourceProvider.ReleaseClaim(seekingType, Employee);
			resourceProvider = null;
		}
		claimed = 0;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		switch (status)
		{
		case Status.Idle:
			text += ScriptLocalization.Idle;
			break;
		case Status.SearchingForResource:
			text += string.Format(ScriptLocalization.jobDescriptionSearching, ResourceAmount.ResourceIcon(seekingType));
			break;
		case Status.GoingToResource:
			text += string.Format(ScriptLocalization.jobDescriptionFetching, ResourceAmount.ResourceIcon(seekingType));
			break;
		case Status.GoingToDropoff:
			text += string.Format(ScriptLocalization.jobDescriptionReturning, ResourceAmount.ResourceIcon(seekingType));
			break;
		}
		return text;
	}
}
