using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Interface;
using I2.Loc;

public class DeliveryJob : Job
{
	private enum Status
	{
		Searching,
		GoingToResource,
		TakingToDropoff,
		TimeOff
	}

	[Serializable]
	public class DeliveryJobSaveData : JobSaveData<DeliveryJob, DeliveryJobSaveData>
	{
		private bool hasResource;

		private int typeToRemove;

		public override DeliveryJobSaveData Pack(DeliveryJob j)
		{
			hasResource = j.status == Status.TakingToDropoff;
			typeToRemove = j.typeToRemove;
			return base.Pack(j);
		}

		public override DeliveryJob Unpack(DeliveryJob j)
		{
			base.Unpack(j);
			if (hasResource)
			{
				j.forceUpdatePath = true;
				j.status = Status.TakingToDropoff;
				j.typeToRemove = typeToRemove;
			}
			return j;
		}
	}

	private Status status;

	private static int updateID;

	private static int searchUpdateID;

	public IResourceProvider provider;

	[NonSerialized]
	public int claimed;

	[NonSerialized]
	public int typeToRemove = -1;

	private IResourceStorage dropOffTarget;

	private bool forceUpdatePath = true;

	private FrameUpdater pathUpdate;

	private FrameUpdater searchUpdate;

	public int bonusMultiplier = 3;

	[NonSerialized]
	public bool forceSearch;

	public DeliveryJob(IEmployer e, IResourceProvider _provider = null)
		: base(e)
	{
		pathUpdate = new FrameUpdater(ref updateID, 30);
		searchUpdate = new FrameUpdater(ref searchUpdateID, 30);
		provider = _provider;
		ManualFreetime = true;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		if (status != Status.TimeOff)
		{
			if (typeToRemove != -1)
			{
				switch (status)
				{
				case Status.Searching:
					text += string.Format(ScriptLocalization.jobDescriptionSearching, ResourceAmount.ResourceIcon(typeToRemove));
					break;
				case Status.GoingToResource:
					text += string.Format(ScriptLocalization.jobDescriptionFetching, ResourceAmount.ResourceIcon(typeToRemove));
					break;
				case Status.TakingToDropoff:
					text += string.Format(ScriptLocalization.jobDescriptionReturning, ResourceAmount.ResourceIcon(typeToRemove));
					break;
				}
			}
			else
			{
				text += ScriptLocalization.jobDescriptionWaiting;
			}
		}
		return text;
	}

	public override void OnEmployeeAssigned()
	{
		meshType = VillagerSystem.MeshType.HandCart;
		Employee.carryBonus = bonusMultiplier;
		base.OnEmployeeAssigned();
	}

	public override void OnEmployeeQuit()
	{
		if (provider != null)
		{
			provider.ReleaseClaim(claimed, Employee);
		}
		claimed = 0;
		Employee.DropResources();
		Employee.carryBonus = 0;
		base.OnEmployeeQuit();
	}

	public override void UpdateWithEmployee(float dt)
	{
		pathUpdate.Update();
		searchUpdate.Update();
		switch (status)
		{
		case Status.Searching:
			if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
			}
			else
			{
				if (!searchUpdate.Trigger() && !forceSearch)
				{
					break;
				}
				forceSearch = false;
				List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
				for (int j = 0; j < resourceDefs.Count; j++)
				{
					FreeResourceSystem.ResourceDef resourceDef = resourceDefs[j];
					int num = 0;
					if (provider.Available(resourceDef.ID))
					{
						num = -100;
					}
					if (num >= 0)
					{
						continue;
					}
					int count = Mathff.Min(-num, Employee.GetCarryCapacity(j));
					claimed = provider.MakeClaim(j, count, Employee);
					if (claimed > 0)
					{
						IResourceStorage resourceStorage = FreeResourceManager.inst.FindClosestBuilidngAccepting(resourceDef.ID, claimed, employer.LandMass(), provider.ResourcePosition(j));
						if (resourceStorage != null && !resourceStorage.Equals(null))
						{
							typeToRemove = j;
							status = Status.GoingToResource;
							forceUpdatePath = true;
						}
						else
						{
							provider.ReleaseClaim(j, Employee);
							claimed = 0;
						}
					}
					break;
				}
			}
			break;
		case Status.GoingToResource:
			if (!employer.DuringWorkHours())
			{
				provider.ReleaseClaim(typeToRemove, Employee);
				claimed = 0;
				status = Status.TimeOff;
			}
			else if (Mathff.DistSqrd(Employee.Pos, provider.ResourcePosition(typeToRemove)) < 0.010000001f)
			{
				provider.ReleaseClaim(typeToRemove, Employee);
				dropOffTarget = FreeResourceManager.inst.FindClosestBuilidngAccepting(typeToRemove, claimed, employer.LandMass(), Employee.Pos);
				if (dropOffTarget != null && !dropOffTarget.Equals(null))
				{
					status = Status.TakingToDropoff;
					forceUpdatePath = true;
					for (int i = 0; i < claimed; i++)
					{
						FreeResource resource = provider.ProvideResource(typeToRemove);
						Employee.PickupResource(resource, i == 0);
					}
					if (Employee.CarryingCount() == 0)
					{
						status = Status.Searching;
					}
				}
				else
				{
					status = Status.Searching;
				}
				claimed = 0;
			}
			else if (pathUpdate.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				Employee.MoveToDeferred(provider.ResourcePosition(typeToRemove));
			}
			break;
		case Status.TakingToDropoff:
			if (dropOffTarget == null || dropOffTarget.Equals(null))
			{
				dropOffTarget = FreeResourceManager.inst.FindClosestBuilidngAccepting(typeToRemove, claimed, employer.LandMass(), Employee.Pos);
				if (dropOffTarget == null || dropOffTarget.Equals(null))
				{
					Employee.DropResources();
					status = Status.Searching;
					break;
				}
			}
			if (Mathff.DistSqrdXZ(Employee.Pos, dropOffTarget.DropOffLocation(typeToRemove)) < 0.010000001f)
			{
				ResourceAmount resources = ResourceAmount.Make(Employee.GetCarriedType(), Employee.GetCarriedResourceAmount());
				dropOffTarget.Deposit(ref resources);
				FreeResourceManager.inst.AutoDropRemainder(resources, Employee.Pos);
				Employee.DestroyHeldResources();
				status = Status.Searching;
				typeToRemove = -1;
				Employee.MoveToDeferred(employer.GetPositionForPerson(Employee));
			}
			else if (pathUpdate.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				Employee.MoveToDeferred(dropOffTarget.DropOffLocation(typeToRemove));
			}
			break;
		case Status.TimeOff:
			if (searchUpdate.Trigger())
			{
				if (employer.DuringWorkHours())
				{
					Employee.FreeTime(_freeTime: false);
					status = Status.Searching;
				}
				else
				{
					Employee.FreeTime(_freeTime: true);
				}
			}
			break;
		}
		base.UpdateWithEmployee(dt);
	}
}
