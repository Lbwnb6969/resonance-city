using System;
using Assets.Code.Interface;
using I2.Loc;
using UnityEngine;

namespace Assets.Code.Jobs;

internal class BuilderJob : Job
{
	private enum Status
	{
		Searching,
		GoingToResource,
		TakingToDropoff,
		GoingToBuilding,
		Building,
		TimeOff
	}

	[Serializable]
	public class BuilderJobSaveData : JobSaveData<BuilderJob, BuilderJobSaveData>
	{
		private bool hasResource;

		private int claimed;

		private int claimedType;

		public override BuilderJobSaveData Pack(BuilderJob j)
		{
			hasResource = j.status == Status.TakingToDropoff;
			claimed = j.claimed;
			claimedType = j.seekingType;
			return base.Pack(j);
		}

		public override BuilderJob Unpack(BuilderJob j)
		{
			base.Unpack(j);
			if (j.Employee != null && hasResource)
			{
				j.forceUpdate = true;
				j.status = Status.TakingToDropoff;
				j.claimed = claimed;
				j.seekingType = claimedType;
				j.builderEmployer.PromiseResources(claimedType, j.claimed, j.Employee);
			}
			return j;
		}
	}

	private int seekingType;

	private IResourceProvider resourceProvider;

	private int claimed;

	private Vector3 dropoffPosition;

	private IBuilderEmployer builderEmployer;

	private static int posUpdateframeID;

	private Status status;

	private Timer searchUpdate = new Timer(3f);

	private FrameUpdater posUpdate;

	private bool forceUpdate;

	private Timer finalCheckUpdate = new Timer(5f);

	private Timer moveUpdate = new Timer(0.4f);

	private Vector3 workPos;

	public BuilderJob(IBuilderEmployer e)
		: base(e)
	{
		posUpdate = new FrameUpdater(ref posUpdateframeID, 45);
		ManualFreetime = true;
		builderEmployer = e;
		meshType = VillagerSystem.MeshType.Builder;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		switch (status)
		{
		case Status.Searching:
			text += string.Format(ScriptLocalization.jobDescriptionSearching, ResourceAmount.ResourceIcon(seekingType));
			break;
		case Status.GoingToResource:
			text += string.Format(ScriptLocalization.jobDescriptionFetching, ResourceAmount.ResourceIcon(seekingType));
			break;
		case Status.TakingToDropoff:
			text += string.Format(ScriptLocalization.jobDescriptionReturning, ResourceAmount.ResourceIcon(seekingType));
			break;
		case Status.GoingToBuilding:
		case Status.Building:
			text += string.Format(ScriptLocalization.jobDescriptionBuilding, "hack", builderEmployer.FriendlyName());
			break;
		}
		return text;
	}

	public override void OnEmployeeAssigned()
	{
		status = Status.Searching;
		searchUpdate.ForceExpire();
		meshType = VillagerSystem.MeshType.HandCart;
		Employee.carryBonus = 3;
		base.OnEmployeeAssigned();
	}

	private bool JobFilter(IResourceProvider x, int type)
	{
		if (x.GetType() == typeof(Mason))
		{
			return false;
		}
		return true;
	}

	public override void UpdateWithEmployee(float dt)
	{
		posUpdate.Update();
		switch (status)
		{
		case Status.Searching:
		{
			if (!searchUpdate.Update(dt))
			{
				break;
			}
			if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
				break;
			}
			builderEmployer.GetNextResourceNeededToFinishConstruction(out seekingType, out var amount);
			if (amount > 0)
			{
				resourceProvider = FreeResourceManager.inst.FindClosestResourceProviderFor(consumer: true, seekingType, Employee.Pos, employer.LandMass(), JobFilter);
				if (resourceProvider != null)
				{
					int count = Mathf.Min(amount, Employee.GetCarryCapacity(seekingType));
					claimed = resourceProvider.MakeClaim(seekingType, count, Employee);
					if (claimed > 0)
					{
						builderEmployer.PromiseResources(seekingType, claimed, Employee);
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
				status = Status.GoingToBuilding;
				dropoffPosition = builderEmployer.GetPositionForPerson(Employee).position;
				Employee.MoveToDeferred(dropoffPosition);
			}
			break;
		}
		case Status.GoingToResource:
			if (resourceProvider == null || resourceProvider.Equals(null))
			{
				builderEmployer.EndPromise(Employee);
				status = Status.Searching;
				break;
			}
			if (Mathff.DistSqrd(Employee.Pos, resourceProvider.ResourcePosition(seekingType)) < 0.010000001f)
			{
				resourceProvider.ReleaseClaim(seekingType, Employee);
				for (int i = 0; i < claimed; i++)
				{
					FreeResource resource = resourceProvider.ProvideResource(seekingType);
					Employee.PickupResource(resource, i == 0);
				}
				resourceProvider = null;
				status = Status.TakingToDropoff;
				forceUpdate = true;
				return;
			}
			if (posUpdate.Trigger() || forceUpdate)
			{
				forceUpdate = false;
				Employee.MoveToDeferred(resourceProvider.ResourcePosition(seekingType));
			}
			break;
		case Status.TakingToDropoff:
			if (Vector3.Distance(Employee.Pos, dropoffPosition) < 0.2f)
			{
				builderEmployer.AddBuildResource(Employee.GetCarriedType(), Employee.GetCarriedResourceAmount());
				Employee.DestroyHeldResources();
				builderEmployer.EndPromise(Employee);
				if (builderEmployer.HasEnoughToBuild())
				{
					status = Status.GoingToBuilding;
					return;
				}
				searchUpdate.ForceExpire();
				status = Status.Searching;
				return;
			}
			if (posUpdate.Trigger() || forceUpdate)
			{
				forceUpdate = false;
				dropoffPosition = builderEmployer.GetPositionForPerson(Employee).position;
				Employee.MoveToDeferred(dropoffPosition);
			}
			break;
		case Status.GoingToBuilding:
			if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
			}
			else if (!TryInterruptToGetMissingResources(dt) && Mathff.DistSqrd(Employee.Pos, dropoffPosition) < 0.25f)
			{
				moveUpdate.ForceExpire();
				status = Status.Building;
				meshType = VillagerSystem.MeshType.Default;
				Employee.MeshType = meshType;
			}
			break;
		case Status.Building:
			if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
			}
			else
			{
				if (TryInterruptToGetMissingResources(dt))
				{
					break;
				}
				builderEmployer.UpdateBuildProgress();
				if (moveUpdate.Update(dt))
				{
					moveUpdate.Duration = SRand.Range(0.5f, 1f);
					if (SRand.Range(0, 100) > 50)
					{
						builderEmployer.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
						float x = SRand.Range(minX, (float)maxX + 1f);
						float z = SRand.Range(minZ, (float)maxZ + 1f);
						workPos = new Vector3(x, TerrainGen.inst.GetGroundHeight(x, z), z);
					}
				}
				Employee.Pos = Vector3.MoveTowards(Employee.Pos, workPos, 1f * dt);
			}
			break;
		case Status.TimeOff:
			if (searchUpdate.Update(dt))
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

	private bool TryInterruptToGetMissingResources(float dt)
	{
		if (finalCheckUpdate.Update(dt))
		{
			builderEmployer.GetNextResourceNeededToFinishConstruction(out var _, out var amount);
			if (amount > 0)
			{
				status = Status.Searching;
				return true;
			}
		}
		return false;
	}

	public override void OnEmployeeQuit()
	{
		Employee.carryBonus = 0;
		Employee.DropResources();
		builderEmployer.EndPromise(Employee);
		if (resourceProvider != null)
		{
			resourceProvider.ReleaseClaim(seekingType, Employee);
			resourceProvider = null;
		}
		base.OnEmployeeQuit();
	}
}
