using System;
using System.Collections.Generic;
using Assets.Code.Interface;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

namespace Assets.Code.Jobs;

internal class FreeResourceGathererJob : Job
{
	public enum Status
	{
		Searching,
		GoingToResource,
		TakingToDropoff,
		TimeOff
	}

	[Serializable]
	public class FreeResourceGathererJobSaveData : JobSaveData<FreeResourceGathererJob, FreeResourceGathererJobSaveData>
	{
		private bool hasResource;

		private int claimedType;

		private bool consumeOnPickup;

		private float bonusCarryCapacity;

		public override FreeResourceGathererJobSaveData Pack(FreeResourceGathererJob j)
		{
			hasResource = j.status == Status.TakingToDropoff;
			claimedType = j.seekingType;
			consumeOnPickup = j.consumeOnPickup;
			bonusCarryCapacity = j.bonusCarryCapacity;
			return base.Pack(j);
		}

		public override FreeResourceGathererJob Unpack(FreeResourceGathererJob j)
		{
			base.Unpack(j);
			j.bonusCarryCapacity = (int)bonusCarryCapacity;
			if ((float)j.bonusCarryCapacity < 1f)
			{
				j.bonusCarryCapacity = 1;
			}
			if (hasResource)
			{
				j.forceUpdatePath = true;
				j.status = Status.TakingToDropoff;
				j.seekingType = claimedType;
			}
			j.consumeOnPickup = consumeOnPickup;
			return j;
		}
	}

	public bool consumer = true;

	private int seekingType;

	[NonSerialized]
	public int initialConstraintType = -1;

	private IResourceProvider resourceProvider;

	private int claimed;

	private IResourceStorageBase dropoffTarget;

	private Vector3 dropoffPosition;

	internal FrameUpdater pathUpdate;

	internal FrameUpdater searchUpdate;

	internal FrameUpdater timeOffUpdate;

	private static int updateID;

	private static int searchUpdateID;

	private static int timeOffUpdateID;

	private Stockpile stockpile;

	private Status status;

	private bool forceSearchUpdate;

	public int bonusCarryCapacity;

	private bool consumeOnPickup;

	public FreeResourceManager.providerFilter filterPrimary;

	public FreeResourceManager.providerFilter filterAlternate;

	[NonSerialized]
	public float searchRadius = 35f;

	private List<IResourceProvider> scratchProviders = new List<IResourceProvider>();

	private List<int> scratchTypes = new List<int>();

	private bool forceUpdatePath;

	[NonSerialized]
	public int[] typeOrder;

	private Timer checkClosestResourceTimer = new Timer(6f);

	public IResourceStorageBase dropoffTargetOverride;

	public bool ConsumeOnPickup => consumeOnPickup;

	public FreeResourceGathererJob(IEmployer e, bool _consumeOnPickup = false)
		: base(e)
	{
		consumeOnPickup = _consumeOnPickup;
		filterPrimary = defaultFilter;
		ManualFreetime = true;
		pathUpdate = new FrameUpdater(ref updateID, 45);
		searchUpdate = new FrameUpdater(ref searchUpdateID, 90);
		timeOffUpdate = new FrameUpdater(ref timeOffUpdateID, 5);
		stockpile = (e as MonoBehaviour)?.GetComponent<Stockpile>();
	}

	public void Configure(int t, FreeResourceManager.providerFilter f)
	{
		initialConstraintType = t;
		filterPrimary = f;
	}

	public Status GetStatus()
	{
		return status;
	}

	public override string GetDescription()
	{
		string text = base.GetDescription();
		int num = initialConstraintType;
		if (resourceProvider == null && typeOrder != null && typeOrder.Length != 0)
		{
			num = typeOrder[0];
		}
		else if (resourceProvider != null)
		{
			num = seekingType;
		}
		if (num != -1)
		{
			switch (status)
			{
			case Status.Searching:
				text = ((!(stockpile != null) || stockpile.allowCitizensToDeposit) ? (text + string.Format(ScriptLocalization.jobDescriptionSearching, ResourceAmount.ResourceIcon(num))) : (text + LocalizationManager.GetTranslation("personui_freeresourcegather_logisticsonly")));
				break;
			case Status.GoingToResource:
				text += string.Format(ScriptLocalization.jobDescriptionFetching, ResourceAmount.ResourceIcon(num));
				break;
			case Status.TakingToDropoff:
				text += string.Format(ScriptLocalization.jobDescriptionReturning, ResourceAmount.ResourceIcon(Employee.GetCarriedType()));
				break;
			}
		}
		return text;
	}

	public override void OnEmployeeAssigned()
	{
		status = Status.Searching;
		checkClosestResourceTimer.Reset();
		checkClosestResourceTimer.Enabled = true;
		base.OnEmployeeAssigned();
	}

	private bool defaultFilter(IResourceProvider x, int type)
	{
		if (x.GetType() != typeof(Keep) && x.GetType() != typeof(Market))
		{
			return x.GetType() != typeof(Mason);
		}
		return false;
	}

	private IResourceStorageBase GetEmployerStorage()
	{
		if (dropoffTargetOverride != null)
		{
			return dropoffTargetOverride;
		}
		if (employer is MonoBehaviour monoBehaviour)
		{
			IResourceStorageBase component = monoBehaviour.GetComponent<IResourceStorageBase>();
			if (component != null)
			{
				return component;
			}
		}
		return null;
	}

	private void AddPotentialProvidersFor(int t, IResourceStorageBase storage)
	{
		if (t != -1 && storage.SpaceAvailable(t) > 0)
		{
			IResourceProvider resourceProvider = FreeResourceManager.inst.FindClosestResourceProviderFor(consumer, t, Employee.Pos, employer.LandMass(), filterPrimary, searchRadius);
			if (resourceProvider == null && filterAlternate != null)
			{
				resourceProvider = FreeResourceManager.inst.FindClosestResourceProviderFor(consumer, t, Employee.Pos, employer.LandMass(), filterAlternate, searchRadius);
			}
			if (resourceProvider != null)
			{
				scratchProviders.Add(resourceProvider);
				scratchTypes.Add(t);
			}
		}
	}

	public IResourceProvider SearchForResource(int constraint, ref int typeFound, ref int count)
	{
		IResourceStorageBase employerStorage = GetEmployerStorage();
		scratchProviders.Clear();
		scratchTypes.Clear();
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			int iD = FreeResourceSystem.inst.resourceDefs[i].ID;
			if (iD != 4 && (constraint == -1 || iD == constraint))
			{
				AddPotentialProvidersFor(iD, employerStorage);
			}
		}
		typeFound = -1;
		IResourceProvider result = null;
		int num = -1;
		if (scratchProviders.Count > 0)
		{
			num = SRand.Range(0, scratchProviders.Count);
		}
		if (num != -1)
		{
			result = scratchProviders[num];
			typeFound = scratchTypes[num];
			count = employerStorage.SpaceAvailable(typeFound);
		}
		return result;
	}

	public IResourceProvider SearchForResourceOrdered(ref int typeFound, ref int count)
	{
		IResourceStorageBase employerStorage = GetEmployerStorage();
		scratchProviders.Clear();
		scratchTypes.Clear();
		typeFound = -1;
		for (int i = 0; i < typeOrder.Length; i++)
		{
			int t = typeOrder[i];
			AddPotentialProvidersFor(t, employerStorage);
			if (scratchProviders.Count > 0 && SRand.Range(0, 100) < 50)
			{
				int index = SRand.Range(0, scratchProviders.Count);
				typeFound = scratchTypes[index];
				count = employerStorage.SpaceAvailable(typeFound);
				return scratchProviders[index];
			}
		}
		if (scratchProviders.Count > 0)
		{
			int index2 = SRand.Range(0, scratchProviders.Count);
			typeFound = scratchTypes[index2];
			count = employerStorage.SpaceAvailable(typeFound);
			return scratchProviders[index2];
		}
		return null;
	}

	public void DropOff()
	{
		status = Status.TakingToDropoff;
		forceUpdatePath = true;
	}

	private void CancelClaim()
	{
		resourceProvider.ReleaseClaim(seekingType, Employee);
		claimed = 0;
		resourceProvider = null;
		dropoffTarget = null;
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		if (dt > 0f)
		{
			searchUpdate.Update();
			pathUpdate.Update();
			timeOffUpdate.Update();
		}
		switch (status)
		{
		case Status.Searching:
			if (timeOffUpdate.Trigger() && !employer.DuringWorkHours())
			{
				status = Status.TimeOff;
			}
			else
			{
				if ((stockpile != null && !stockpile.allowCitizensToDeposit) || (!searchUpdate.Trigger() && !forceSearchUpdate))
				{
					break;
				}
				Employee.carryBonus = bonusCarryCapacity;
				forceSearchUpdate = false;
				int typeFound2 = -1;
				int count2 = 0;
				IResourceProvider resourceProvider2;
				if (villager.CarryingCount() > 0)
				{
					resourceProvider2 = SearchForResource(seekingType, ref typeFound2, ref count2);
				}
				else
				{
					resourceProvider2 = ((typeOrder == null) ? SearchForResource(initialConstraintType, ref typeFound2, ref count2) : SearchForResourceOrdered(ref typeFound2, ref count2));
				}
				if ((resourceProvider2 == null && villager.CarryingCount() > 0) || (resourceProvider2 != null && villager.CarryingCount() >= count2))
				{
					DropOff();
				}
				else
				{
					if (resourceProvider2 == null)
					{
						break;
					}
					seekingType = typeFound2;
					if (villager.CarryingCount() > 0 && Vector3.Distance(villager.Pos, resourceProvider2.ResourcePosition(seekingType)) > Vector3.Distance(villager.Pos, employer.GetPositionForPerson(villager).position))
					{
						DropOff();
						break;
					}
					claimed = resourceProvider2.MakeClaim(seekingType, Mathf.Min(count2, villager.GetRemainingCapacity(seekingType)), villager);
					if (claimed > 0)
					{
						status = Status.GoingToResource;
						this.resourceProvider = resourceProvider2;
					}
					else
					{
						this.resourceProvider = null;
					}
				}
			}
			break;
		case Status.GoingToResource:
		{
			if (this.resourceProvider == null || this.resourceProvider.Equals(null) || (stockpile != null && !stockpile.allowCitizensToDeposit))
			{
				villager.MoveToDeferred(employer.GetPositionForPerson(villager));
				status = Status.Searching;
				break;
			}
			float num = Mathff.DistSqrd(villager.Pos, this.resourceProvider.ResourcePosition(seekingType));
			if (!employer.DuringWorkHours())
			{
				status = Status.TimeOff;
				CancelClaim();
				break;
			}
			if (checkClosestResourceTimer.Update(dt))
			{
				checkClosestResourceTimer.Enabled = false;
				int count = 0;
				int typeFound = -1;
				IResourceProvider resourceProvider = SearchForResource(seekingType, ref typeFound, ref count);
				if (resourceProvider != null && count >= claimed && typeFound == seekingType)
				{
					float num2 = Vector3.Distance(villager.Pos, this.resourceProvider.ResourcePosition(seekingType));
					if (Vector3.Distance(villager.Pos, resourceProvider.ResourcePosition(seekingType)) < num2 - 2f)
					{
						status = Status.Searching;
						forceSearchUpdate = true;
						CancelClaim();
						break;
					}
				}
			}
			if (num < 0.010000001f)
			{
				this.resourceProvider.ReleaseClaim(seekingType, villager);
				for (int i = 0; i < claimed; i++)
				{
					FreeResource freeResource = this.resourceProvider.ProvideResource(seekingType);
					if (freeResource != null)
					{
						villager.PickupResource(freeResource, i == 0);
					}
				}
				this.resourceProvider = null;
				claimed = 0;
				dropoffTarget = null;
				checkClosestResourceTimer.Reset();
				checkClosestResourceTimer.Enabled = true;
				if (villager.GetRemainingCapacity(seekingType) > 0)
				{
					status = Status.Searching;
					forceSearchUpdate = true;
				}
				else
				{
					DropOff();
				}
				return;
			}
			if (pathUpdate.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				Vector3 newPos = this.resourceProvider.ResourcePosition(seekingType);
				villager.MoveToDeferred(newPos);
			}
			break;
		}
		case Status.TakingToDropoff:
			if (stockpile != null && !stockpile.allowCitizensToDeposit)
			{
				villager.DropResources();
				villager.MoveToDeferred(employer.GetPositionForPerson(villager));
				status = Status.Searching;
				break;
			}
			if (dropoffTarget != null && Mathff.DistSqrd(villager.Pos, dropoffPosition) < 0.010000001f)
			{
				ResourceAmount resources = ResourceAmount.Make(villager.GetCarriedType(), villager.GetCarriedResourceAmount());
				dropoffTarget.Deposit(ref resources);
				FreeResourceManager.inst.AutoDropRemainder(resources, Employee.Pos);
				villager.DestroyHeldResources();
				status = Status.Searching;
				forceSearchUpdate = true;
				villager.MoveToDeferred(employer.GetPositionForPerson(villager));
			}
			if (pathUpdate.Trigger() || forceUpdatePath)
			{
				if (dropoffTarget == null || forceUpdatePath)
				{
					dropoffTarget = GetEmployerStorage();
					dropoffPosition = dropoffTarget.DropOffLocation(seekingType);
				}
				forceUpdatePath = false;
				villager.MoveToDeferred(dropoffPosition);
			}
			break;
		case Status.TimeOff:
			if (searchUpdate.Trigger())
			{
				if (employer.DuringWorkHours())
				{
					villager.FreeTime(_freeTime: false);
					status = Status.Searching;
					forceSearchUpdate = true;
				}
				else
				{
					villager.FreeTime(_freeTime: true);
				}
			}
			break;
		}
		base.UpdateWithEmployee(dt);
	}

	public override void OnEmployeeQuit()
	{
		Employee.carryBonus = 0;
		Employee.DropResources();
		if (resourceProvider != null)
		{
			resourceProvider.ReleaseClaim(seekingType, Employee);
			resourceProvider = null;
		}
		dropoffTarget = null;
		claimed = 0;
		base.OnEmployeeQuit();
	}
}
