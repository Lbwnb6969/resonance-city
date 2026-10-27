using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Barracks : Tickable, IOutputInfo, IResourceStorageBase, IWorkerUIDisplay
{
	public enum TypeToMake
	{
		Footmen,
		Archers,
		Envoy,
		Settler,
		Catapult
	}

	[Serializable]
	public class BarracksSaveData : SaveClass<Barracks, BarracksSaveData>
	{
		public int pendingTraining;

		public bool training;

		public float trainPercent;

		public ResourceAmount resourcesStored;

		[OptionalField(VersionAdded = 3)]
		public List<ConscriptedJob.ConscriptedJobSaveData> NewTrainees;

		[OptionalField(VersionAdded = 4)]
		public int peopleCredits;

		[OptionalField(VersionAdded = 4)]
		public int peopleTrained;

		[OptionalField(VersionAdded = 4)]
		public int peopleInBarracks;

		public ConscriptedJob.ConscriptedJobSaveData CurrentTrainee;

		public List<ConscriptedJob.ConscriptedJobSaveData> ConscriptedJobs = new List<ConscriptedJob.ConscriptedJobSaveData>();

		[OptionalField(VersionAdded = 2)]
		public bool waitingForTrainingResources;

		[OptionalField(VersionAdded = 4)]
		public bool skipAddJob;

		[OptionalField(VersionAdded = 5)]
		public string prevGeneralName;

		[OptionalField(VersionAdded = 5)]
		public ArmySystem.ArmyBehavior prevRecuperatedBehavior;

		public override BarracksSaveData Pack(Barracks obj)
		{
			pendingTraining = obj.pendingTraining;
			training = obj.training;
			trainPercent = obj.trainPercent;
			resourcesStored = obj.resourcesStored;
			waitingForTrainingResources = obj.waitingForTrainingResources;
			peopleInBarracks = obj.peopleInBarracks;
			peopleCredits = obj.peopleCredits;
			peopleTrained = obj.peopleTrained;
			prevGeneralName = obj.prevGeneralName;
			prevRecuperatedBehavior = obj.prevRecuperatedBehavior;
			if (obj.NewTrainees != null)
			{
				NewTrainees = new List<ConscriptedJob.ConscriptedJobSaveData>(obj.NewTrainees.Count);
				for (int i = 0; i < obj.NewTrainees.Count; i++)
				{
					NewTrainees.Add(new ConscriptedJob.ConscriptedJobSaveData().Pack(obj.NewTrainees.data[i]));
				}
			}
			return this;
		}

		public override Barracks Unpack(Barracks obj)
		{
			obj.pendingTraining = pendingTraining;
			obj.training = training;
			obj.trainPercent = trainPercent;
			obj.resourcesStored = resourcesStored;
			obj.waitingForTrainingResources = waitingForTrainingResources;
			obj.peopleInBarracks = peopleInBarracks;
			obj.peopleCredits = peopleCredits;
			obj.peopleTrained = peopleTrained;
			obj.prevGeneralName = prevGeneralName;
			obj.prevRecuperatedBehavior = prevRecuperatedBehavior;
			if (NewTrainees != null)
			{
				obj.NewTrainees = new ArrayExt<ConscriptedJob>(obj.peopleInSquad);
				for (int i = 0; i < NewTrainees.Count && i < obj.peopleInSquad; i++)
				{
					ConscriptedJob conscriptedJob = new ConscriptedJob(obj.GetComponent<Building>());
					NewTrainees[i].Unpack(conscriptedJob);
					JobSystem.inst.AddNewJob(conscriptedJob, 13);
					obj.NewTrainees.Add(conscriptedJob);
				}
			}
			return obj;
		}
	}

	internal int pendingTraining;

	[HideInInspector]
	public bool training;

	[HideInInspector]
	public float trainPercent;

	[HideInInspector]
	public int peopleTrained;

	[HideInInspector]
	public int peopleInBarracks;

	internal bool disabled;

	private bool waitingForTrainingResources = true;

	public float TimeToTrainSolider = 5f;

	private int maxHoused = 16;

	private int rows = 4;

	private int unitGoldCost;

	public ResourceAmount unitResourcesCost;

	[HideInInspector]
	public int[] gatherTypeOrder;

	private ResourceAmount unitCost;

	public ResourceAmount resourceStorageMax;

	public ResourceAmount resourcesStored;

	public int peopleCredits;

	public Transform trainRectMin;

	public Transform trainRectMax;

	public Transform spawnPoint;

	public Transform spawnWalk;

	private ResourceAmount compositeResourceAmount = new ResourceAmount();

	private Building b;

	public Transform hiddenTrainingPoint;

	public Mesh soldierMesh;

	public Material soldierMaterial;

	public Vector3[] formationVectors;

	public Vector3[] positionVectors;

	public Matrix4x4[] positionMatrixs;

	public int peopleInSquad = 17;

	private ArrayExt<ConscriptedJob> NewTrainees;

	public TypeToMake typeToMake;

	public string trainButtonTerm;

	private ResourceAmount resourcesSpent = new ResourceAmount();

	public static int UnitLimit = 60;

	private List<Cell> armyCells = new List<Cell>();

	private Cell[] scratchNeighbors = new Cell[4];

	private ArmySystem.ArmyBehavior prevRecuperatedBehavior = ArmySystem.ArmyBehavior.Attack;

	private string prevGeneralName;

	public ResourceAmount GetUnitCost()
	{
		return unitCost;
	}

	public void Awake()
	{
		b = GetComponent<Building>();
		unitGoldCost = unitResourcesCost.Get(4);
		unitResourcesCost.Set(4, 0);
		unitCost.Set(4, unitGoldCost * peopleInSquad);
		int num = 0;
		for (int i = 0; i < unitResourcesCost.resources.Count; i++)
		{
			Resource resource = unitResourcesCost.resources[i];
			if (resource.Amount > 0 && resource.resourceID != 4)
			{
				unitCost.Set(resource.resourceID, resource.Amount * peopleInSquad);
				num++;
			}
		}
		gatherTypeOrder = new int[num];
		int num2 = 0;
		for (int j = 0; j < unitResourcesCost.resources.Count; j++)
		{
			if (unitResourcesCost.resources[j].Amount > 0 && unitResourcesCost.resources[j].resourceID != 4)
			{
				gatherTypeOrder[num2] = unitResourcesCost.resources[j].resourceID;
				num2++;
			}
		}
	}

	private void Start()
	{
		positionMatrixs = new Matrix4x4[maxHoused];
	}

	public override void OnEnableInternal()
	{
		if (NewTrainees == null)
		{
			NewTrainees = new ArrayExt<ConscriptedJob>(peopleInSquad);
		}
		base.OnEnableInternal();
	}

	private void OnBuilt()
	{
		SetupBarracks();
	}

	private void SetupBarracks()
	{
		int num = Mathf.CeilToInt((float)maxHoused / (float)rows);
		formationVectors = new Vector3[rows * num];
		positionVectors = new Vector3[rows * num];
		Transform child = b.transform.GetChild(0);
		Vector3 vector = child.InverseTransformPoint(trainRectMin.position);
		Vector3 vector2 = child.InverseTransformPoint(trainRectMax.position) - vector;
		for (int i = 0; i < rows; i++)
		{
			for (int j = 0; j < num; j++)
			{
				Vector3 vector3 = new Vector3((float)i / (float)rows * vector2.x, 0f, (float)j / (float)num * vector2.z);
				formationVectors[i * rows + j] = child.rotation * (vector + vector3) + child.position;
				positionVectors[i * rows + j] = ((i * rows + j < (int)(trainPercent * (float)peopleInSquad)) ? formationVectors[i * rows + j] : hiddenTrainingPoint.position);
			}
		}
	}

	public void OnAddJobs()
	{
		int jobInitIdx = b.jobInitIdx;
		int num = gatherTypeOrder.Length;
		if (num > 0)
		{
			num = Mathff.Clamp(num, 3, 5);
		}
		for (int i = jobInitIdx; i < jobInitIdx + num; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b, _consumeOnPickup: true));
			}
			FreeResourceGathererJob obj = b.jobs[i] as FreeResourceGathererJob;
			obj.typeOrder = gatherTypeOrder;
			obj.filterPrimary = JobFilter;
			obj.dropoffTargetOverride = this;
			b.jobInitIdx++;
		}
		while (NewTrainees.Count < peopleInSquad)
		{
			ConscriptedJob conscriptedJob = new ConscriptedJob(b);
			JobSystem.inst.AddNewJob(conscriptedJob, 13);
			NewTrainees.Add(conscriptedJob);
			conscriptedJob.ManualAssignment = true;
		}
	}

	private bool JobFilter(IResourceProvider x, int type)
	{
		if (x.GetType() == typeof(Keep))
		{
			return false;
		}
		return true;
	}

	public bool CanStartTraining()
	{
		if (b.IsBuilt())
		{
			if (World.inst.GetVillagersForLandMass(LandMass()).Count < peopleInSquad)
			{
				return false;
			}
			for (int i = 0; i < gatherTypeOrder.Length; i++)
			{
				int num = gatherTypeOrder[i];
				if (unitResourcesCost.Get(num) > 0 && num != 4 && Player.inst.resourcesPerLandmass[LandMass()].Get(num) + resourcesStored.Get(num) < peopleInSquad)
				{
					return false;
				}
			}
		}
		else if (!b.IsBuilt())
		{
			return false;
		}
		return true;
	}

	public void AddTraining()
	{
		if (CanStartTraining())
		{
			pendingTraining++;
		}
	}

	public void CancelTraining()
	{
		if (pendingTraining > 0)
		{
			pendingTraining--;
		}
		if (pendingTraining != 0)
		{
			return;
		}
		if (NewTrainees != null)
		{
			for (int i = 0; i < NewTrainees.Count; i++)
			{
				if (NewTrainees.data[i].Employee != null)
				{
					NewTrainees.data[i].Employee.QuitJob();
				}
			}
		}
		if (training)
		{
			World.GetLandmassOwner(LandMass()).Gold += resourcesSpent.Get(4);
			resourcesStored.Add(in resourcesSpent);
		}
		for (int j = 0; j < peopleTrained + peopleInBarracks; j++)
		{
			Player.inst.AddVillager(hiddenTrainingPoint.position);
		}
		ResetTrainingVariables();
	}

	public void StartTraining()
	{
		trainPercent = 0f;
		training = true;
		waitingForTrainingResources = true;
		for (int i = 0; i < NewTrainees.Count; i++)
		{
			NewTrainees.data[i].ManualAssignment = false;
		}
	}

	public float SquadPercent()
	{
		return ((float)peopleTrained + trainPercent) / (float)peopleInSquad;
	}

	public string GetStoredResources()
	{
		compositeResourceAmount = resourcesStored;
		return compositeResourceAmount.ToString();
	}

	public static bool AtLimit(TypeToMake typeToMake, int teamID)
	{
		bool result = false;
		if (typeToMake == TypeToMake.Footmen)
		{
			result = ArmySystem.inst.UnitCount(teamID, ArmySystem.ArmyType.Default) >= UnitLimit;
		}
		if (typeToMake == TypeToMake.Archers)
		{
			result = ArmySystem.inst.UnitCount(teamID, ArmySystem.ArmyType.Archer) >= UnitLimit;
		}
		if (typeToMake == TypeToMake.Envoy)
		{
			result = ArmySystem.inst.UnitCount(teamID, ArmySystem.ArmyType.Envoy) >= UnitLimit;
		}
		if (typeToMake == TypeToMake.Settler)
		{
			result = ArmySystem.inst.UnitCount(teamID, ArmySystem.ArmyType.Settler) >= UnitLimit;
		}
		if (typeToMake == TypeToMake.Catapult)
		{
			int num = 0;
			for (int i = 0; i < SiegeCatapultSystem.siegeCatapults.Count; i++)
			{
				if (SiegeCatapultSystem.siegeCatapults.data[i].TeamID() == teamID)
				{
					num++;
				}
			}
			result = num >= UnitLimit;
		}
		return result;
	}

	public override void Tick(float dt, int currFrame)
	{
		if (training)
		{
			if (waitingForTrainingResources && World.GetLandmassOwner(LandMass()).Gold >= unitGoldCost && resourcesStored >= unitResourcesCost)
			{
				World.GetLandmassOwner(LandMass()).Gold -= unitGoldCost;
				resourcesStored.TrySubtract(unitResourcesCost);
				ResourceStatistics.AddConsumption(LandMass(), "barracks", 7, unitResourcesCost.Get(7));
				resourcesSpent.Add(in unitResourcesCost);
				resourcesSpent.Add(4, unitGoldCost);
				waitingForTrainingResources = false;
			}
			if (!waitingForTrainingResources)
			{
				for (int i = 0; i < NewTrainees.Count; i++)
				{
					if (NewTrainees.data[i].Employee != null && Vector3.Distance(NewTrainees.data[i].Employee.Pos, transform.position) < 4f)
					{
						peopleInBarracks++;
						Player.inst.DestroyPerson(NewTrainees.data[i].Employee, leaveBehindBody: false);
						NewTrainees.data[i].ManualAssignment = true;
					}
				}
				int num = peopleInSquad - peopleTrained;
				int num2 = Mathf.Min(peopleCredits, num);
				peopleTrained += num2;
				peopleCredits -= num2;
				num = peopleInSquad - peopleTrained;
				int num3 = 0;
				for (int j = 0; j < NewTrainees.Count; j++)
				{
					if (!NewTrainees.data[j].ManualAssignment)
					{
						num3++;
					}
					if (num3 > num)
					{
						if (NewTrainees.data[j].Employee != null)
						{
							NewTrainees.data[j].Employee.QuitJob();
						}
						NewTrainees.data[j].ManualAssignment = true;
					}
				}
				if (peopleInBarracks < 0)
				{
					peopleInBarracks = 0;
				}
				if (peopleInBarracks > 0)
				{
					trainPercent = Mathf.MoveTowards(trainPercent, 1f, Time.deltaTime / TimeToTrainSolider * b.GetWorkerPercent() * (float)((!StreamerEffects.Flag_BetterBarracksTraining) ? 1 : 2));
				}
				if (trainPercent >= 1f)
				{
					peopleTrained++;
					peopleInBarracks--;
					waitingForTrainingResources = true;
					trainPercent = 0f;
				}
				if (peopleTrained >= peopleInSquad)
				{
					IMoveableUnit moveableUnit = null;
					ArmySystem.ArmyType armyType = ArmySystem.ArmyType.Default;
					if (typeToMake == TypeToMake.Footmen)
					{
						armyType = ArmySystem.ArmyType.Default;
					}
					else if (typeToMake == TypeToMake.Archers)
					{
						armyType = ArmySystem.ArmyType.Archer;
					}
					if (typeToMake == TypeToMake.Envoy)
					{
						armyType = ArmySystem.ArmyType.Envoy;
					}
					if (typeToMake == TypeToMake.Settler)
					{
						armyType = ArmySystem.ArmyType.Settler;
					}
					moveableUnit = ArmySystem.inst.MakeArmy(spawnPoint.position, b.TeamID(), armyType, addUnits: true);
					if (armyType == ArmySystem.ArmyType.Default || armyType == ArmySystem.ArmyType.Archer)
					{
						(moveableUnit as ArmySystem.Army).armyBehavior = prevRecuperatedBehavior;
						prevRecuperatedBehavior = ArmySystem.ArmyBehavior.Attack;
					}
					if (prevGeneralName != null)
					{
						(moveableUnit as ArmySystem.Army).generalName = prevGeneralName;
						prevGeneralName = null;
					}
					EffectsMan.inst.BuildPuff.CreateAndPlay(spawnPoint.position);
					EffectsMan.inst.HealthEffect.CreateAndPlay(spawnPoint.position);
					Cell cellDataClamped = World.inst.GetCellDataClamped(FindOpenSpace(spawnWalk.transform.position));
					moveableUnit.SetPos(cellDataClamped.Center2D);
					OrdersManager.inst.MoveTo(moveableUnit, cellDataClamped);
					peopleTrained -= peopleInSquad;
					ResetTrainingVariables();
					SfxSystem.inst.PlayFromBankIfVisibleOneShot("Soldier_Training_Complete", b.cachedPos);
					resourcesSpent.Clear();
				}
			}
		}
		else if (pendingTraining > 0)
		{
			if (!AtLimit(typeToMake, b.TeamID()))
			{
				pendingTraining--;
				StartTraining();
			}
			else
			{
				pendingTraining = 0;
			}
		}
		if (b == null)
		{
			b = GetComponent<Building>();
		}
		b.WorkersAllocated = 0;
		for (int k = 0; k < b.jobs.Count; k++)
		{
			if (b.jobs[k] != null && b.jobs[k].Employee != null)
			{
				b.WorkersAllocated++;
			}
		}
	}

	private Vector3 FindOpenSpace(Vector3 start)
	{
		armyCells.Clear();
		for (int i = 0; i < ArmySystem.inst.ArmyCount(); i++)
		{
			armyCells.Add(World.inst.GetCellData(ArmySystem.inst.GetAmry(i).GetPos()));
		}
		Dictionary<Cell, bool> dictionary = new Dictionary<Cell, bool>();
		List<Cell> list = new List<Cell>(100);
		list.Add(World.inst.GetCellData(start));
		while (list.Count > 0)
		{
			Cell cell = list[0];
			list.RemoveAt(0);
			dictionary.Add(cell, value: true);
			if ((cell.OccupyingStructure.Count == 0 || (bool)cell.StructureFindByCategory(World.pathHash)) && cell.Type == TerrainType.None && !armyCells.Contains(cell))
			{
				return cell.Center2D;
			}
			World.inst.GetNeighborCells(cell, ref scratchNeighbors);
			for (int j = 0; j < scratchNeighbors.Length; j++)
			{
				if (scratchNeighbors[j] != null && !dictionary.ContainsKey(scratchNeighbors[j]) && !list.Contains(scratchNeighbors[j]))
				{
					list.Add(scratchNeighbors[j]);
				}
			}
		}
		return start;
	}

	private void LateUpdate()
	{
		if (!b.IsBuilt())
		{
			return;
		}
		for (int i = 0; i < maxHoused; i++)
		{
			if (i < peopleTrained)
			{
				positionVectors[i] = Mathff.MoveTowards(positionVectors[i], formationVectors[i], Time.deltaTime * 1.025f);
				Mathff.SetTR(ref positionMatrixs[i], positionVectors[i], Quaternion.identity);
			}
			else
			{
				positionVectors[i] = hiddenTrainingPoint.position;
				Mathff.SetTR(ref positionMatrixs[i], positionVectors[i], Quaternion.identity);
			}
			positionMatrixs[i].m33 = (b.IsVisibleForFog() ? 1f : 0f);
		}
		if (Settings.inst.supportsInstancing)
		{
			Graphics.DrawMeshInstanced(soldierMesh, 0, soldierMaterial, positionMatrixs);
			return;
		}
		for (int j = 0; j < positionMatrixs.Length; j++)
		{
			Graphics.DrawMesh(soldierMesh, positionMatrixs[j], soldierMaterial, 0);
		}
	}

	private void ResetTrainingVariables()
	{
		for (int i = 0; i < NewTrainees.Count; i++)
		{
			if (NewTrainees.data[i].Employee != null)
			{
				NewTrainees.data[i].Employee.QuitJob();
			}
			NewTrainees.data[i].ManualAssignment = true;
		}
		peopleTrained = 0;
		peopleInBarracks = 0;
		peopleCredits = 0;
		resourcesSpent.Clear();
		training = false;
		trainPercent = 0f;
	}

	public string GetStatus()
	{
		if (training)
		{
			if (trainPercent < 1f && !waitingForTrainingResources)
			{
				return ScriptLocalization.Training;
			}
			if (World.GetLandmassOwner(LandMass()).Gold < unitGoldCost)
			{
				return "ScriptLocalization.BarracksLackingGold";
			}
			bool flag = false;
			for (int i = 0; i < unitResourcesCost.resources.Count; i++)
			{
				Resource resource = unitResourcesCost.resources[i];
				if (resourcesStored.Get(resource.resourceID) < resource.Amount && resource.Amount != 0)
				{
					flag = true;
					break;
				}
			}
			if (flag)
			{
				return "ScriptLocalization.BarracksFindingTrainingSupplies";
			}
			return "ScriptLocalization.BarracksWaitingForArrival";
		}
		return "";
	}

	public string GetTitle()
	{
		return null;
	}

	public string GetNum()
	{
		return null;
	}

	public string GetExplanation(OutputTileUI outputTile)
	{
		return ResourceAmount.ExplainAmounts(resourcesStored, resourceStorageMax);
	}

	public string GetUnit()
	{
		return null;
	}

	public string GetError()
	{
		if (b.GetWorkerPercent() <= 0f)
		{
			return "ScriptLocalization.BarracksNoStaff";
		}
		return null;
	}

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	public void Deposit(ref ResourceAmount resources)
	{
		resourcesStored.Add(in resources);
		resources.Clear();
	}

	public int SpaceAvailable(int resourceID)
	{
		return resourceStorageMax.Get(resourceID) - resourcesStored.Get(resourceID);
	}

	public Vector3 DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	private void OnDemolished()
	{
		CancelTraining();
	}

	private void OnFinishedLoad()
	{
		b = GetComponent<Building>();
		if (!b.IsBuilt())
		{
			return;
		}
		SetupBarracks();
		if (NewTrainees == null)
		{
			NewTrainees = new ArrayExt<ConscriptedJob>(peopleInSquad);
		}
		if (NewTrainees.Count == 0)
		{
			for (int i = 0; i < peopleInSquad; i++)
			{
				ConscriptedJob conscriptedJob = new ConscriptedJob(b);
				JobSystem.inst.AddNewJob(conscriptedJob, 13);
				NewTrainees.Add(conscriptedJob);
				conscriptedJob.ManualAssignment = true;
			}
		}
	}

	public void ReclaimSoldiers(ArmySystem.Army army)
	{
		prevRecuperatedBehavior = army.armyBehavior;
		prevGeneralName = army.generalName;
		int num = army.units.Count + 1;
		peopleCredits += num;
		pendingTraining++;
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
