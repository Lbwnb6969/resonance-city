using System;
using Assets.Code.Interface;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

namespace Assets.Code.Jobs;

public class HarvesterJob : Job
{
	public enum Status
	{
		Planting,
		PickingUpHay,
		BringToStorage,
		BackToField,
		WaitForSummer,
		GoingToResource,
		WaitForStorageToOpen,
		TimeOff
	}

	[Serializable]
	public class HarvesterJobSaveData : JobSaveData<HarvesterJob, HarvesterJobSaveData>
	{
		private Guid dropOff = Guid.Empty;

		private int type;

		private Status oldStatus;

		public override HarvesterJobSaveData Pack(HarvesterJob j)
		{
			type = j.freeResourceType;
			oldStatus = j.oldStatus;
			if (j.status == Status.BringToStorage)
			{
				MonoBehaviour monoBehaviour = (MonoBehaviour)j.targetDropoff;
				if (monoBehaviour != null && monoBehaviour.GetComponent<Building>() != null)
				{
					dropOff = monoBehaviour.GetComponent<Building>().guid;
				}
			}
			return base.Pack(j);
		}

		public override HarvesterJob Unpack(HarvesterJob j)
		{
			base.Unpack(j);
			if (j.Employee == null)
			{
				return j;
			}
			j.oldStatus = oldStatus;
			j.freeResourceType = type;
			if (j.Employee.CarryingCount() > 0)
			{
				j.status = Status.BringToStorage;
				if (dropOff != Guid.Empty)
				{
					Building building = Player.inst.GetBuilding(dropOff);
					if ((bool)building && building.GetComponent<IResourceStorage>() != null)
					{
						j.targetDropoff = building.GetComponent<IResourceStorage>();
						j.Employee.MoveToDeferred(j.targetDropoff.DropOffLocation(j.freeResourceType));
					}
				}
			}
			return j;
		}
	}

	private Status status = Status.PickingUpHay;

	private FrameUpdater pathUpdate;

	private static int updateID;

	private Timer posUpdate = new Timer(1f);

	private Timer lookForStorageTimer = new Timer(1f);

	private float lookForStorageWaitMin = 0.5f;

	private float lookForStorageWaitMax = 1.5f;

	private IResourceStorage targetDropoff;

	private float totalTime;

	private int claimed;

	private EventHandler<SeasonEventData> seasonChangeEvent;

	private SeasonDefinition _lastSeasonDefinition;

	public int freeResourceType;

	private IResourceProvider resourceProvider;

	private bool forcePathUpdate;

	private Vector3 workPos;

	private Vector3 oldPos;

	private Vector3 up = new Vector3(0f, 1f, 0f);

	private Status oldStatus;

	private bool hasFailedToFindStorage;

	public HarvesterJob(IEmployer e)
		: base(e)
	{
		pathUpdate = new FrameUpdater(ref updateID, 45);
		totalTime = SRand.value * 1000f;
		ManualFreetime = true;
		meshType = VillagerSystem.MeshType.Farmer;
	}

	public Status GetStatus()
	{
		return status;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		switch (status)
		{
		case Status.Planting:
			text += string.Format(ScriptLocalization.jobHarvesterDescriptionPlanting, ResourceAmount.ResourceIcon(freeResourceType));
			break;
		case Status.PickingUpHay:
			text += string.Format(ScriptLocalization.jobDescriptionCollecting, ResourceAmount.ResourceIcon(freeResourceType));
			break;
		case Status.BringToStorage:
			text += string.Format(ScriptLocalization.jobDescriptionReturning, ResourceAmount.ResourceIcon(freeResourceType));
			break;
		case Status.BackToField:
			text += string.Format(ScriptLocalization.jobHarvesterDescriptionTraveling, ResourceAmount.ResourceIcon(freeResourceType));
			break;
		case Status.WaitForSummer:
			text += ScriptLocalization.jobHarvesterDescriptionWaitingSummer;
			break;
		case Status.GoingToResource:
			text += string.Format(ScriptLocalization.jobDescriptionFetching, ResourceAmount.ResourceIcon(freeResourceType));
			break;
		case Status.WaitForStorageToOpen:
			text += (hasFailedToFindStorage ? ScriptLocalization.jobHarvesterDescriptionFailedToFindStorage : ScriptLocalization.jobHarvesterDescriptionWaitingStorage);
			break;
		}
		return text;
	}

	public override void OnJobAdded()
	{
		base.OnJobAdded();
		seasonChangeEvent = Broadcast.SeasonEvent.Listen(OnSeasonChange);
		_lastSeasonDefinition = SeasonManager.GetCurrentSeason();
	}

	public override void OnJobRemoved()
	{
		base.OnJobRemoved();
		Broadcast.SeasonEvent.Unlisten(seasonChangeEvent);
	}

	private void OnSeasonChange(object sender, SeasonEventData data)
	{
		_lastSeasonDefinition = data.SeasonDefinition;
	}

	public override void OnEmployeeAssigned()
	{
		status = Status.PickingUpHay;
		base.OnEmployeeAssigned();
	}

	private void ExpireResources()
	{
		int carriedResourceAmount = Employee.GetCarriedResourceAmount();
		ResourceStatistics.AddConsumption(employer.LandMass(), "rot", freeResourceType, carriedResourceAmount);
		ResourceTextStackManager.inst.ShowResourceAmount(this, Employee.Pos, freeResourceType, -carriedResourceAmount);
		Employee.DestroyResources();
	}

	private void UpdateBobbleAnim(Villager employee, float dt)
	{
		if (posUpdate.Update(dt))
		{
			posUpdate.Duration = SRand.Range(0.5f, 4f);
			workPos = employer.GetPositionForPerson(employee).position;
			workPos += new Vector3(SRand.Range(-0.2f, 0.2f), 0f, SRand.Range(-0.2f, 0.2f));
			totalTime = 0f;
			oldPos = employee.Pos;
			employee.Rot = Quaternion.LookRotation(workPos - oldPos, up);
			if (SeasonManager.GetCurrentSeason().id == 3 && (employer as Building).uniqueNameHash == World.farmHash)
			{
				EffectsMan.inst.ThrowSeedsEffect.CreateAndPlayVisibilityCheck(employee.Pos + new Vector3(0f, 0.25f, 0f), employee.Rot);
			}
		}
		float t = Mathf.Clamp01(totalTime * 0.66f);
		employee.Pos = Vector3.Lerp(oldPos, workPos, Mathf.SmoothStep(0f, 1f, t));
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		pathUpdate.Update();
		totalTime += dt;
		switch (status)
		{
		case Status.Planting:
			if (!MaybeTimeToGoHome())
			{
				UpdateBobbleAnim(villager, dt);
			}
			break;
		case Status.PickingUpHay:
		{
			this.resourceProvider = null;
			float num = float.MaxValue;
			TransformData positionForPerson = employer.GetPositionForPerson(villager);
			IResourceProvider resourceProvider = FreeResourceManager.inst.FindClosestResourceProviderFor(consumer: false, freeResourceType, positionForPerson.position, employer.LandMass(), JobFilterPrimary);
			if (resourceProvider != null)
			{
				float num2 = Mathff.DistSqrdXZ(resourceProvider.ResourcePosition(freeResourceType), positionForPerson.position);
				if (num2 < 25f && num2 < num)
				{
					num = num2;
					this.resourceProvider = resourceProvider;
				}
			}
			if (this.resourceProvider != null)
			{
				claimed = this.resourceProvider.MakeClaim(freeResourceType, villager.GetCarryCapacity(freeResourceType), villager);
				if (claimed > 0)
				{
					villager.MoveToDeferred(this.resourceProvider.ResourcePosition(freeResourceType));
					status = Status.GoingToResource;
					forcePathUpdate = true;
				}
			}
			else
			{
				villager.MoveToDeferred(employer.GetPositionForPerson(villager));
				status = Status.BackToField;
			}
			break;
		}
		case Status.GoingToResource:
			if (this.resourceProvider == null || this.resourceProvider.Equals(null))
			{
				status = Status.PickingUpHay;
			}
			else if (Mathff.DistSqrdXZ(villager.Pos, this.resourceProvider.ResourcePosition(freeResourceType)) < 0.010000001f)
			{
				this.resourceProvider.ReleaseClaim(freeResourceType, villager);
				if (this.resourceProvider.Available(freeResourceType))
				{
					for (int i = 0; i < claimed; i++)
					{
						villager.PickupResource(this.resourceProvider.ProvideResource(freeResourceType), i == 0);
					}
				}
				if (villager.GetCarriedResourceAmount() > 0)
				{
					WaitForStorageToOpen();
				}
				else
				{
					villager.MoveToDeferred(employer.GetPositionForPerson(villager));
					status = Status.BackToField;
				}
				posUpdate.ForceExpire();
			}
			else if (pathUpdate.Trigger() || forcePathUpdate)
			{
				forcePathUpdate = false;
				villager.MoveToDeferred(this.resourceProvider.ResourcePosition(freeResourceType));
			}
			break;
		case Status.WaitForStorageToOpen:
			if (lookForStorageTimer.Update(Time.deltaTime))
			{
				IResourceStorage resourceStorage = FreeResourceManager.inst.FindClosestBuilidngAccepting(freeResourceType, claimed, employer.LandMass(), employer.GetPositionForPerson(villager).position);
				if (resourceStorage != null)
				{
					targetDropoff = resourceStorage;
					villager.MoveToDeferred(targetDropoff.DropOffLocation(freeResourceType));
					status = Status.BringToStorage;
					hasFailedToFindStorage = false;
					break;
				}
				hasFailedToFindStorage = true;
				lookForStorageTimer.Duration = SRand.Range(lookForStorageWaitMin, lookForStorageWaitMax);
			}
			if (_lastSeasonDefinition.id == 3)
			{
				ExpireResources();
				villager.MoveToDeferred(employer.GetPositionForPerson(villager));
				status = Status.BackToField;
			}
			if (MaybeTimeToGoHome())
			{
				Employee.DropResources();
				oldStatus = Status.BackToField;
			}
			break;
		case Status.BringToStorage:
		{
			if (targetDropoff == null || targetDropoff.Equals(null) || targetDropoff.SpaceAvailable(freeResourceType) < claimed)
			{
				WaitForStorageToOpen();
				break;
			}
			Vector3 a = targetDropoff.DropOffLocation(freeResourceType);
			Vector3 pos = villager.Pos;
			if (Mathff.DistSqrdXZ(a, pos) < 0.010000001f)
			{
				ResourceAmount resources = ResourceAmount.Make(villager.GetCarriedType(), villager.GetCarriedResourceAmount());
				targetDropoff.Deposit(ref resources);
				FreeResourceManager.inst.AutoDropRemainder(resources, Employee.Pos);
				villager.DestroyHeldResources();
				targetDropoff = null;
				villager.MoveToDeferred(employer.GetPositionForPerson(villager));
				status = Status.PickingUpHay;
				break;
			}
			if (villager.travelPath.Count == 0)
			{
				villager.MoveToDeferred(targetDropoff.DropOffLocation(freeResourceType));
			}
			if (_lastSeasonDefinition.id == 3 && SeasonManager.inst.seasonElapsedTime < _lastSeasonDefinition.duration * 0.85f)
			{
				ExpireResources();
				villager.MoveToDeferred(employer.GetPositionForPerson(villager));
				status = Status.BackToField;
			}
			break;
		}
		case Status.BackToField:
			if (Mathff.DistSqrd(employer.GetPositionForPerson(villager).position, villager.Pos) < 0.010000001f)
			{
				if (_lastSeasonDefinition.id == 3 || _lastSeasonDefinition.id == 0)
				{
					status = Status.Planting;
				}
				else
				{
					status = Status.WaitForSummer;
				}
				posUpdate.ForceExpire();
			}
			if (!MaybeTimeToGoHome())
			{
			}
			break;
		case Status.WaitForSummer:
			UpdateBobbleAnim(villager, dt);
			if (_lastSeasonDefinition.id == 3)
			{
				status = Status.Planting;
			}
			if (!MaybeTimeToGoHome())
			{
			}
			break;
		case Status.TimeOff:
			if (employer.DuringWorkHours())
			{
				Employee.FreeTime(_freeTime: false);
				totalTime = 0f;
				status = oldStatus;
				if (status == Status.Planting || status == Status.WaitForSummer)
				{
					status = Status.BackToField;
				}
			}
			else
			{
				Employee.FreeTime(_freeTime: true);
			}
			break;
		}
		base.UpdateWithEmployee(dt);
	}

	public bool MaybeTimeToGoHome()
	{
		if (!employer.DuringWorkHours())
		{
			oldStatus = status;
			status = Status.TimeOff;
			return true;
		}
		return false;
	}

	public void Harvest()
	{
		status = Status.PickingUpHay;
		if (resourceProvider != null && !resourceProvider.Equals(null) && Employee != null)
		{
			resourceProvider.ReleaseClaim(freeResourceType, Employee);
		}
	}

	private bool JobFilterPrimary(IResourceProvider x, int type)
	{
		if (x.GetType() == typeof(Market))
		{
			return false;
		}
		if (x is Keep || x is Baker || x is Outpost || x is Stockpile || x is ProduceStand)
		{
			return false;
		}
		return true;
	}

	public override void OnEmployeeQuit()
	{
		Employee.DropResources();
		if (status == Status.GoingToResource)
		{
			resourceProvider.ReleaseClaim(freeResourceType, Employee);
		}
		base.OnEmployeeQuit();
	}

	public bool HasFailedToFindStorage()
	{
		return hasFailedToFindStorage;
	}

	private void WaitForStorageToOpen()
	{
		status = Status.WaitForStorageToOpen;
		hasFailedToFindStorage = false;
		lookForStorageTimer.ForceExpire();
	}
}
