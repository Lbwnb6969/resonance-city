using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets.Code;
using Assets.Code.Jobs;
using Assets.Interface;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class RomanBarracks : Tickable, IResourceStorageBase, IWorkerUIDisplay, IEmployer, IOutputInfo
{
	[Serializable]
	public class RomanBarracksSaveData : SaveClass<RomanBarracks, RomanBarracksSaveData>
	{
		public ConscriptedJob.ConscriptedJobSaveData[] cJobsData;

		public SerializableGuid occupyUnitGuid;

		public ResourceAmount currStorage = new ResourceAmount();

		private int occupyingUnitId = -1;

		private int lastVeterancy;

		private float currTrainingTime;

		private bool isRecruiting;

		public override RomanBarracksSaveData Pack(RomanBarracks obj)
		{
			cJobsData = new ConscriptedJob.ConscriptedJobSaveData[obj.cJobs.Count];
			for (int i = 0; i < obj.cJobs.Count; i++)
			{
				cJobsData[i] = new ConscriptedJob.ConscriptedJobSaveData().Pack(obj.cJobs.data[i]);
			}
			if (obj.occupyingUnit != null)
			{
				occupyUnitGuid = obj.occupyingUnit.GetGuid();
			}
			currStorage.Add(in obj.currStorage);
			lastVeterancy = obj.lastVeterancy;
			currTrainingTime = obj.currTrainingTime;
			isRecruiting = obj.isRecruiting;
			return this;
		}

		public override RomanBarracks Unpack(RomanBarracks obj)
		{
			if (cJobsData != null)
			{
				for (int i = 0; i < cJobsData.Length && i < obj.cJobs.Count; i++)
				{
					cJobsData[i].Unpack(obj.cJobs.data[i]);
				}
			}
			obj.deferAttachOccupyingUnitGuid = occupyUnitGuid;
			obj.currStorage.Add(in currStorage);
			obj.lastVeterancy = lastVeterancy;
			obj.currTrainingTime = currTrainingTime;
			obj.isRecruiting = isRecruiting;
			return obj;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			occupyUnitGuid = Guid.Empty;
			currStorage = new ResourceAmount();
		}
	}

	private Building b;

	private WagePayer wagePayer;

	public int requiredRecruits = 48;

	private ArrayExt<ConscriptedJob> cJobs;

	[SerializeField]
	private List<Transform> cIdlePositions;

	[SerializeField]
	private int legionWages = 5;

	[SerializeField]
	private int defaultWages = 2;

	public ResourceAmount recruitCost;

	[NonSerialized]
	public ResourceAmount currStorage = new ResourceAmount();

	public int recruitUnitType;

	private bool isRecruiting;

	[SerializeField]
	private bool doTraining = true;

	private float currTrainingTime;

	[SerializeField]
	private float maxTrainingTime = 15f;

	private LegionUnit occupyingUnit;

	private FloodFillCrawler floodFill = new FloodFillCrawler();

	private static int frameSpread = 20;

	private int updateFrame = SRand.srand.Next(0, frameSpread);

	private Guid deferAttachOccupyingUnitGuid = Guid.Empty;

	public GameObject rallyPoint;

	private ArrayExt<Cell> spawnCandidates = new ArrayExt<Cell>(10);

	private int lastVeterancy;

	internal bool deferRecooperate;

	private static List<Villager> scratchRecruits = new List<Villager>(128);

	private static int[] doSkipJobCategories = new int[4] { 29, 13, 5, 6 };

	private float prevVal;

	private float prevTVal;

	private float prevRVal;

	public bool IsRecruiting()
	{
		return isRecruiting;
	}

	public float GetTrainingTime()
	{
		if (!doTraining)
		{
			return 0f;
		}
		return currTrainingTime;
	}

	public bool IsOccupied()
	{
		return occupyingUnit != null;
	}

	public LegionUnit GetOccupyingUnit()
	{
		return occupyingUnit;
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		wagePayer = GetComponent<WagePayer>();
		if (wagePayer != null)
		{
			wagePayer.wageAmount = defaultWages;
		}
		cJobs = new ArrayExt<ConscriptedJob>(requiredRecruits);
	}

	private void Start()
	{
		UnitSystem.inst.OnUnitRemoved += OnUnitRemoved;
	}

	private void OnDestroy()
	{
		UnitSystem.inst.OnUnitRemoved -= OnUnitRemoved;
	}

	private void OnUnitRemoved(IUnitControllable unit)
	{
		if (unit == occupyingUnit)
		{
			occupyingUnit = null;
			isRecruiting = false;
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (!undo || LoadSave.Loading)
		{
			return;
		}
		if (IsOccupied())
		{
			occupyingUnit.Disband();
		}
		else
		{
			if (!isRecruiting)
			{
				return;
			}
			World.GetLandmassOwner(b.LandMass()).Gold += recruitCost.Get(4);
			for (int i = 0; i < currStorage.resources.Count; i++)
			{
				Resource resource = currStorage.resources[i];
				if (resource.resourceID != 4 && resource.Amount > 0)
				{
					FreeResourceManager.inst.GetAutoStackFor(resource.resourceID, resource.Amount, b.Center());
				}
			}
			currStorage.Clear();
		}
	}

	private void TryApplyGladiatorSchoolBonus()
	{
		if (recruitUnitType == 4)
		{
			return;
		}
		bool flag = false;
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(b.LandMass(), "gladiatorschool".GetHashCode());
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			GladiatorSchool component = buildingListForLandMass.data[i].GetComponent<GladiatorSchool>();
			if (!component.TrainingBonusAvailable())
			{
				continue;
			}
			Vector3 s = buildingListForLandMass.data[i].Center().xz();
			b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
			for (int j = minZ; j <= maxZ; j++)
			{
				for (int k = minX; k <= maxX; k++)
				{
					if (World.inst.TileTouchingRadius(World.inst.GetCellDataClamped(k, j), s, component.Radius))
					{
						flag = true;
					}
				}
			}
			break;
		}
		if (flag && occupyingUnit != null)
		{
			LegionGroup value = LegionSystem.Inst.groups[occupyingUnit.GetGroupID()];
			if (value.morale <= 0)
			{
				value.morale = 1;
			}
			LegionSystem.Inst.groups[occupyingUnit.GetGroupID()] = value;
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (deferAttachOccupyingUnitGuid != Guid.Empty)
		{
			occupyingUnit = UnitSystem.inst.GetLegionUnitByGuid(deferAttachOccupyingUnitGuid);
			occupyingUnit.ownerBarracks = this;
			deferAttachOccupyingUnitGuid = Guid.Empty;
		}
		if (deferRecooperate)
		{
			deferRecooperate = false;
			Recooperate();
		}
		if (!IsOccupied() && isRecruiting)
		{
			bool flag = TryGetRequiredRecruits();
			bool flag2 = currStorage.HasCost(recruitCost);
			if (!(flag & flag2) || !IsRecruitsHere())
			{
				return;
			}
			currTrainingTime += dt;
			if (((!doTraining || !(currTrainingTime >= maxTrainingTime)) && doTraining) || LegionSystem.Inst.IsAtMaxUnits())
			{
				return;
			}
			Vector3 vector = b.Center();
			if ((bool)rallyPoint)
			{
				vector = rallyPoint.transform.position;
			}
			floodFill.Reset();
			floodFill.cellsPerFrame = 100;
			spawnCandidates.Clear();
			floodFill.Tick(vector, delegate(Cell c, ref List<Cell> openSet)
			{
				if (PathCell.GetMilitaryFootPathCost(World.inst.GetPathCell(c), b.TeamID()) < PathCell.buildingFootpathCost)
				{
					spawnCandidates.Add(c);
				}
				floodFill.AddAllCardinalToOpenSet(c);
				return true;
			});
			int teamId = b.TeamID();
			int num = 0;
			for (int num2 = 0; num2 < spawnCandidates.Count; num2++)
			{
				int num3 = 0;
				Cell cell = spawnCandidates.data[num2];
				if (PathCell.GetMilitaryFootPathCost(World.inst.GetPathCell(cell.x - 1, cell.z), teamId) < PathCell.buildingFootpathCost)
				{
					num3++;
				}
				if (PathCell.GetMilitaryFootPathCost(World.inst.GetPathCell(cell.x + 1, cell.z), teamId) < PathCell.buildingFootpathCost)
				{
					num3++;
				}
				if (PathCell.GetMilitaryFootPathCost(World.inst.GetPathCell(cell.x, cell.z - 1), teamId) < PathCell.buildingFootpathCost)
				{
					num3++;
				}
				if (PathCell.GetMilitaryFootPathCost(World.inst.GetPathCell(cell.x, cell.z + 1), teamId) < PathCell.buildingFootpathCost)
				{
					num3++;
				}
				if (num3 > num)
				{
					num = num3;
					vector = cell.Center3D;
					if (num >= 2)
					{
						break;
					}
				}
			}
			int numCells = requiredRecruits / 16;
			occupyingUnit = LegionSystem.Inst.TrySpawn(recruitUnitType, vector, b.TeamID(), numCells);
			occupyingUnit.ownerBarracks = this;
			LegionGroup value = occupyingUnit.GetGroup();
			value.morale = lastVeterancy;
			LegionSystem.Inst.groups[value.id] = value;
			lastVeterancy = 0;
			TryApplyGladiatorSchoolBonus();
			RuntimeManager.PlayOneShot("event:/OldSFX/armyGeneralSelect", vector);
			for (int num4 = 0; num4 < cJobs.Count; num4++)
			{
				ConscriptedJob conscriptedJob = cJobs.data[num4];
				if (conscriptedJob.HasEmployee())
				{
					Villager employee = conscriptedJob.Employee;
					Player.inst.RemovePersonFromWorld(employee);
				}
			}
			if (wagePayer != null)
			{
				wagePayer.wageAmount = defaultWages + legionWages;
			}
			isRecruiting = false;
			currStorage.Clear();
		}
		else if (IsOccupied())
		{
			if (wagePayer != null)
			{
				wagePayer.wageAmount = defaultWages + legionWages;
			}
			if (occupyingUnit.IsDead())
			{
				occupyingUnit = null;
			}
			else if (currFrame % frameSpread == updateFrame)
			{
				TryApplyGladiatorSchoolBonus();
			}
		}
		else if (!IsOccupied() && wagePayer != null)
		{
			wagePayer.wageAmount = defaultWages;
		}
	}

	private unsafe void Recooperate()
	{
		LegionUnit legionUnit = GetOccupyingUnit();
		LegionGroup legionGroup = legionUnit.GetGroup();
		float num = (float)legionGroup.numCells / (float)legionGroup.origNumCells;
		lastVeterancy = legionGroup.morale;
		scratchRecruits.Clear();
		for (int i = 0; i < legionGroup.numCells; i++)
		{
			LegionCell legionCell = LegionSystem.Inst.legionCells[legionGroup.cells[i]];
			for (int j = 0; j < LegionSystem.Inst.soldierCount; j++)
			{
				int index = legionCell.id * LegionSystem.Inst.soldierCount + j;
				Vector3 newPos = LegionSystem.Inst.soldierPositions[index];
				Villager villager = Villager.CreateVillager();
				Player.inst.Workers.Add(villager);
				Player.inst.Homeless.Add(villager);
				villager.TeleportTo(newPos);
				scratchRecruits.Add(villager);
			}
		}
		for (int k = 0; k < scratchRecruits.Count; k++)
		{
			for (int l = 0; l < cJobs.Count; l++)
			{
				if (!cJobs.data[l].HasEmployee())
				{
					cJobs.data[l].AssignEmployee(scratchRecruits[k]);
					break;
				}
			}
		}
		currStorage.Add(7, scratchRecruits.Count);
		scratchRecruits.Clear();
		LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
		int num2 = recruitCost.Get(4);
		landmassOwner.Gold -= (int)((float)num2 * (1f - num));
		currStorage.Add(4, num2);
		currTrainingTime = maxTrainingTime * num;
		occupyingUnit = null;
		UnitSystem.inst.DestroyUnit(legionUnit);
		isRecruiting = true;
	}

	public void TryStartRecruitment()
	{
		if (CanRecruit())
		{
			isRecruiting = true;
			TryGetRequiredRecruits();
			LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
			int num = recruitCost.Get(4);
			landmassOwner.Gold -= num;
			currStorage.Add(4, num);
			ResourceStatistics.AddConsumption(b.LandMass(), b.UniqueName, 4, num);
			currTrainingTime = 0f;
		}
	}

	public void TryCancelRecruitment()
	{
		if (!isRecruiting)
		{
			return;
		}
		LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
		int num = recruitCost.Get(4);
		landmassOwner.Gold += num;
		currStorage.Add(4, -num);
		for (int i = 0; i < cJobs.Count; i++)
		{
			ConscriptedJob conscriptedJob = cJobs.data[i];
			if (conscriptedJob.HasEmployee())
			{
				conscriptedJob.Employee.QuitJob();
			}
		}
		isRecruiting = false;
	}

	private bool TryGetRequiredRecruits()
	{
		int num = 0;
		for (int i = 0; i < cJobs.Count; i++)
		{
			if (cJobs.data[i].HasEmployee())
			{
				num++;
			}
		}
		if (requiredRecruits - num <= 0)
		{
			return true;
		}
		scratchRecruits.Clear();
		if (!JobSystem.inst.TryFreeUpWorkers(ref scratchRecruits, requiredRecruits, b.LandMass(), doSkipJobCategories))
		{
			return false;
		}
		int num2 = 0;
		for (int num3 = scratchRecruits.Count - 1; num3 >= 0; num3--)
		{
			Villager bestWorker = scratchRecruits[num3];
			for (int j = 0; j < cJobs.Count; j++)
			{
				if (!cJobs.data[j].HasEmployee())
				{
					cJobs.data[j].AssignEmployee(bestWorker);
					num2++;
					break;
				}
			}
		}
		return requiredRecruits - (num + num2) <= 0;
	}

	public bool CanRecruit()
	{
		if (IsOccupied() || isRecruiting)
		{
			return false;
		}
		if (b.uniqueNameHash != World.romanOutpostHash && b.GetWorkerPercent() <= 0f)
		{
			return false;
		}
		if (!HasCostForRecruitment())
		{
			return false;
		}
		return true;
	}

	public bool HasCostForRecruitment()
	{
		if (Player.inst.TotalWorkersForLandMass(b.LandMass()) < requiredRecruits)
		{
			return false;
		}
		if (currStorage.Get(7) < recruitCost.Get(7))
		{
			return false;
		}
		if (World.GetLandmassOwner(b.LandMass()).Gold < recruitCost.Get(4))
		{
			return false;
		}
		return true;
	}

	private void OnAddJobs()
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				FreeResourceGathererJob freeResourceGathererJob = new FreeResourceGathererJob(b, _consumeOnPickup: true);
				freeResourceGathererJob.Configure(7, null);
				b.SetAndAddJob(i, freeResourceGathererJob);
			}
		}
		while (cJobs.Count < requiredRecruits)
		{
			TransformData transformData = new TransformData
			{
				position = cIdlePositions[cJobs.Count].position,
				rotation = cIdlePositions[cJobs.Count].rotation
			};
			ConscriptedJob conscriptedJob = new ConscriptedJob(this);
			conscriptedJob.ManualAssignment = true;
			conscriptedJob.ManualFreetime = true;
			JobSystem.inst.AddNewJob(conscriptedJob, 13);
			cJobs.Add(conscriptedJob);
		}
	}

	private bool IsRecruitsHere()
	{
		for (int i = 0; i < cJobs.Count; i++)
		{
			ConscriptedJob conscriptedJob = cJobs.data[i];
			if (!conscriptedJob.HasEmployee() || conscriptedJob.status == 0)
			{
				return false;
			}
		}
		return true;
	}

	public float GetRecruitProgress()
	{
		float num = Mathff.Clamp01((float)GetRecruitCount(doCheckForArrived: true) / (float)requiredRecruits);
		float num2 = currTrainingTime / maxTrainingTime;
		float num3 = 0f;
		num3 = ((!doTraining) ? num : (num * 0.75f + num2 * 0.25f));
		if (prevVal > num3)
		{
			Debug.Log("Somehow progress depleted?");
		}
		prevVal = num3;
		prevTVal = num2;
		prevRVal = num;
		return num3;
	}

	public int GetRecruitCount(bool doCheckForArrived = false)
	{
		int num = 0;
		for (int i = 0; i < cJobs.Count; i++)
		{
			if (cJobs.data[i].HasEmployee() && (!doCheckForArrived || cJobs.data[i].status != 0))
			{
				num++;
			}
		}
		return num;
	}

	public bool TryDisband()
	{
		if (occupyingUnit == null || !IsOccupied())
		{
			return false;
		}
		occupyingUnit.Disband();
		occupyingUnit = null;
		return true;
	}

	public bool TryFocus()
	{
		if (occupyingUnit == null || !IsOccupied())
		{
			return false;
		}
		Cam.inst.SetDesiredTrackingPos(occupyingUnit.GetPos());
		return true;
	}

	private void OnDemolished()
	{
		FreeResourceManager.inst.AddOrMakeAutoStackFor(7, currStorage.Get(7), b.Center());
	}

	public void Deposit(ref ResourceAmount resources)
	{
		int num = Mathff.Min(SpaceAvailable(7), resources.Get(7));
		ResourceStatistics.AddConsumption(b.LandMass(), b.UniqueName, 7, num);
		currStorage.Add(7, num);
		resources.Add(7, -num);
	}

	public int SpaceAvailable(int resourceID)
	{
		if (resourceID != 7)
		{
			return 0;
		}
		return recruitCost.Get(resourceID) - currStorage.Get(resourceID);
	}

	public Vector3 DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public Vector3 GetPosition()
	{
		return b.Center();
	}

	public TransformData GetPositionForPerson(Villager p)
	{
		for (int i = 0; i < cJobs.Count; i++)
		{
			if (cJobs.data[i].HasEmployee() && cJobs.data[i].Employee == p)
			{
				return new TransformData
				{
					position = cIdlePositions[i].position,
					rotation = cIdlePositions[i].rotation
				};
			}
		}
		return default;
	}

	public bool IsOpen()
	{
		return true;
	}

	public void OnAssigned(Villager p)
	{
	}

	public void OnUnAssigned(Villager p)
	{
	}

	public void OnJobRemoved(Job j)
	{
	}

	public string GetUsedSkill()
	{
		return "I2.Infantry";
	}

	public int LandMass()
	{
		return b.LandMass();
	}

	public int GetJobCategory()
	{
		return 13;
	}

	public bool DuringWorkHours(float buffer = 0f)
	{
		return false;
	}

	public float GetStartHour()
	{
		return -1f;
	}

	public float GetEndHour()
	{
		return -1f;
	}

	public string GetError()
	{
		if (!IsOccupied())
		{
			if (LegionSystem.Inst.IsAtMaxUnits())
			{
				return LocalizationManager.GetTranslation("workerui_barracks_atlegionlimits");
			}
			if (currStorage.Get(7) < recruitCost.Get(7))
			{
				return LocalizationManager.GetTranslation("workerui_barracks_noarmaments");
			}
		}
		return "";
	}
}
