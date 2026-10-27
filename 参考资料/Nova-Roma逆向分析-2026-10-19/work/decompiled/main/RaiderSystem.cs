using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class RaiderSystem : MonoBehaviour, ICamTrackable
{
	public class UnitData
	{
		public Vector3 spawnCell;

		public Objective objective;

		public IUnitControllable unit;

		internal List<Objective> ignoreList = new List<Objective>();

		public bool ShouldIgnore(Objective o)
		{
			return ignoreList.Contains(o);
		}

		public void UpdateAndVerifyObjective(bool ogresActive, List<Objective> objectives)
		{
			if (objective != null && objective.IsComplete())
			{
				objective = null;
				TryAssignObjective(objectives);
			}
			if (objective != null)
			{
				bool flag = false;
				Vector3 pos = unit.GetPos();
				int landMassIdx = World.inst.GetCellDataClamped(pos).landMassIdx;
				int landMassIdx2 = World.inst.GetCellDataClamped(objective.targetCellX, objective.targetCellZ).landMassIdx;
				if (!unit.CanCarry() && landMassIdx != landMassIdx2 && landMassIdx != -1)
				{
					flag = true;
				}
				if (unit is ArmySystem.Army && (objective.type == ObjectiveType.StartFire || objective.type == ObjectiveType.StealResources) && (unit as ArmySystem.Army).pathBlocked && Mathff.DistSqrdXZ(unit.GetDestPos(), objective.GetTarget().GetPos()) > 1.1f && !ogresActive)
				{
					flag = true;
				}
				if (flag)
				{
					ignoreList.Add(objective);
					objective = null;
					TryAssignObjective(objectives);
				}
			}
		}

		public bool CanComplete(Objective objective)
		{
			IUnitControllable carried = unit;
			if (carried.CanCarry() && carried.CarryCount() > 0)
			{
				carried = carried.GetCarried(0);
			}
			UnitData unitDataFor = inst.GetUnitDataFor(carried);
			if (unitDataFor.ignoreList.Count >= 30 || unitDataFor.ShouldIgnore(objective))
			{
				return false;
			}
			Vector3 pos = unitDataFor.unit.GetPos();
			int landMassIdx = World.inst.GetCellDataClamped(pos).landMassIdx;
			Cell cellDataClamped = World.inst.GetCellDataClamped(objective.targetCellX, objective.targetCellZ);
			int landMassIdx2 = cellDataClamped.landMassIdx;
			if (!unit.CanCarry() && landMassIdx != landMassIdx2 && landMassIdx != -1)
			{
				return false;
			}
			if (carried is SiegeMonster)
			{
				return objective.type == ObjectiveType.OgreToBuilding;
			}
			if (carried is ArmySystem.Army)
			{
				ArmySystem.Army army = carried as ArmySystem.Army;
				if (army.armyType == ArmySystem.ArmyType.Default && objective.type == ObjectiveType.StartFire)
				{
					return true;
				}
				if (army.armyType == ArmySystem.ArmyType.Thief && objective.type == ObjectiveType.StealResources && army.stolenResourceAmount <= 0 && cellDataClamped.OccupyingStructure.Count > 0)
				{
					Building building = cellDataClamped.OccupyingStructure[0];
					if ((bool)building.GetComponent<Temple>() && World.GetLandmassOwner(building.LandMass()).Gold > 0)
					{
						return true;
					}
				}
			}
			return false;
		}

		public void TryAssignObjective(List<Objective> objectives)
		{
			if (objective != null || (unit.CanCarry() && unit.CarryCount() == 0) || ignoreList.Count >= 30)
			{
				return;
			}
			for (int i = 0; i < objectives.Count; i++)
			{
				if (!objectives[i].IsComplete() && !ShouldIgnore(objectives[i]) && CanComplete(objectives[i]))
				{
					objective = objectives[i];
				}
			}
		}
	}

	public delegate void raidNotify();

	public class SpawnInfo
	{
		[Serializable]
		public enum RaidState
		{
			WaitingToSpawnBoat,
			SailingToLanding,
			GoingToTarget,
			ReturningToBoat,
			SailingToExit,
			WaitingOnOgre,
			ArmyWait,
			WaitForLandingToClear
		}

		public Vector3 armyTarget;

		public Timer pathTimer = new Timer(0.3f);

		public bool ogre;

		public Cell startCell;

		public int squadSize = 5;

		public float spawnDelay;

		public bool ignoreStartOffset;

		public RaidState state;

		public SpawnInfo(Cell start)
		{
			startCell = start;
		}
	}

	public enum ObjectiveType
	{
		StartFire,
		StealResources,
		NumObjectives,
		OgreToBuilding
	}

	[Serializable]
	public class Objective
	{
		public ObjectiveType type;

		public int targetCellX;

		public int targetCellZ;

		public bool completed;

		public SerializableVector3 landing;

		public Guid guid = Guid.NewGuid();

		public void Complete()
		{
			if (completed)
			{
				return;
			}
			completed = true;
			if (DifficultyManager.inst.currOption.invasionIntensityChoice != 4)
			{
				if (type == ObjectiveType.StartFire)
				{
					inst.escalationPoints -= 0.15f;
				}
				else if (type == ObjectiveType.StealResources)
				{
					inst.escalationPoints -= 0.15f;
				}
				else if (type == ObjectiveType.OgreToBuilding)
				{
					inst.escalationPoints -= 0.33f;
				}
				if (inst.escalationPoints < 0f)
				{
					inst.escalationPoints = 0f;
				}
			}
		}

		public bool IsComplete()
		{
			if (!completed)
			{
				Cell cellData = World.inst.GetCellData(targetCellX, targetCellZ);
				if (type == ObjectiveType.StartFire || type == ObjectiveType.StealResources)
				{
					bool flag = cellData.busyObj is Fire;
					if (DifficultyManager.inst.currOption.invasionIntensityChoice >= 2)
					{
						flag = false;
					}
					if (flag || (cellData.OccupyingStructure.Count > 0 && cellData.BottomStructure.uniqueNameHash == World.rubbleHash) || cellData.OccupyingStructure.Count <= 0)
					{
						Complete();
					}
				}
				else if (type == ObjectiveType.OgreToBuilding && (cellData.OccupyingStructure.Count <= 0 || (cellData.OccupyingStructure.Count > 0 && cellData.BottomStructure.uniqueNameHash == World.rubbleHash)))
				{
					Complete();
				}
				if (completed)
				{
					int landMassIdx = World.inst.GetCellDataClamped(targetCellX, targetCellZ).landMassIdx;
					int num = 3;
					if (type == ObjectiveType.OgreToBuilding)
					{
						num = 7;
					}
					Player.inst.AddHappinessMod("vikingattack", 95f, -num, LocalizationManager.GetTranslation("HappinessUIInvasionTrauma"), landMassIdx, addition: true, 0, -35);
					AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(landMassIdx);
					if (kingdomByLandmass != null)
					{
						kingdomByLandmass.VikingsDidDamage();
					}
				}
			}
			return completed;
		}

		public IMoveTarget GetTarget()
		{
			Cell cellData = World.inst.GetCellData(targetCellX, targetCellZ);
			if (cellData.OccupyingStructure.Count > 0)
			{
				return cellData.OccupyingStructure[0];
			}
			return cellData;
		}
	}

	private class ObjectiveSet
	{
		public List<Objective> startFire = new List<Objective>();

		public List<Objective> stealResources = new List<Objective>();

		public int landmassIdx;

		public List<Cell> landings;
	}

	[Serializable]
	public class RaiderSystemSaveData2 : SaveClass<RaiderSystem, RaiderSystemSaveData2>
	{
		[Serializable]
		private struct UnitDataSave
		{
			public Guid guid;

			public int objectiveIdx;

			public SerializableVector3 spawnCell;

			[OptionalField(VersionAdded = 2)]
			public Guid objectiveGuid;
		}

		public int yearsUntilNextAttack;

		public int totalYearsUntilNextAttack;

		public int yearsUntilNextSkirmish;

		public float escalationPoints;

		public int maxShips;

		private List<Objective> objectives = new List<Objective>();

		private List<UnitDataSave> unitData = new List<UnitDataSave>();

		public override RaiderSystemSaveData2 Pack(RaiderSystem d)
		{
			yearsUntilNextAttack = d.yearsUntilNextAttack;
			totalYearsUntilNextAttack = d.totalYearsUntilNextAttack;
			escalationPoints = d.escalationPoints;
			yearsUntilNextSkirmish = d.yearsUntilNextSkirmish;
			maxShips = d.maxShips;
			objectives = d.objectives;
			for (int i = 0; i < d.unitData.Count; i++)
			{
				UnitDataSave item = new UnitDataSave
				{
					guid = d.unitData[i].unit.GetGuid()
				};
				if (d.unitData[i].objective != null)
				{
					item.objectiveGuid = d.unitData[i].objective.guid;
				}
				else
				{
					item.objectiveGuid = Guid.Empty;
				}
				item.spawnCell = d.unitData[i].spawnCell;
				unitData.Add(item);
			}
			return this;
		}

		public override RaiderSystem Unpack(RaiderSystem d)
		{
			d.escalationPoints = escalationPoints;
			d.yearsUntilNextAttack = yearsUntilNextAttack;
			d.totalYearsUntilNextAttack = totalYearsUntilNextAttack;
			if (d.totalYearsUntilNextAttack == 0)
			{
				d.totalYearsUntilNextAttack = yearsUntilNextAttack + 1;
			}
			d.yearsUntilNextSkirmish = yearsUntilNextSkirmish;
			d.maxShips = maxShips;
			if (d.maxShips == -1)
			{
				d.maxShips = Player.inst.TotalWorkers() / 100;
			}
			d.objectives = objectives;
			if (d.objectives == null)
			{
				d.objectives = new List<Objective>();
			}
			for (int i = 0; i < d.objectives.Count; i++)
			{
				if (d.objectives[i] == null)
				{
					d.objectives.RemoveAt(i);
					i--;
				}
			}
			for (int j = 0; j < this.unitData.Count; j++)
			{
				UnitData unitData = new UnitData();
				if (this.unitData[j].objectiveGuid != Guid.Empty)
				{
					unitData.objective = d.GetObjectiveByGuid(this.unitData[j].objectiveGuid);
				}
				unitData.spawnCell = this.unitData[j].spawnCell;
				IUnitControllable unitControllable = UnitSystem.inst.FindUnitByGuid(this.unitData[j].guid);
				if (unitControllable != null)
				{
					unitData.unit = unitControllable;
					d.unitData.Add(unitData);
				}
			}
			return d;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			maxShips = -1;
		}
	}

	[NonSerialized]
	public UnitData lastTracked;

	[NonSerialized]
	public bool spawnSiegeWeapons;

	public GameObject ogreTransportShipPrefab;

	public GameObject ogrePrefab;

	public GameObject siegeCatapultPrefab;

	public static RaiderSystem inst;

	private List<IUnitControllable> scratchUnload = new List<IUnitControllable>();

	private List<UnitData> deferredRemoval = new List<UnitData>();

	private int castleblockHash = "castleblock".GetHashCode();

	private int gateHash = "gate".GetHashCode();

	private int granaryHash = "granary".GetHashCode();

	private int stockpileHash = "largestockpile".GetHashCode();

	private int treasureRoomHash = "throneroom".GetHashCode();

	private bool[] visited;

	[NonSerialized]
	public List<UnitData> unitData = new List<UnitData>();

	private int unitsUncarried;

	private int frameAccum;

	private bool wasRaidInProgress;

	public int yearsUntilNextAttack;

	public int yearsUntilNextSkirmish;

	public int totalYearsUntilNextAttack;

	public int MinAttackYearSpan = 7;

	public int MaxAttackYearSpan = 9;

	public raidNotify OnRaidStarted;

	private int maxShips;

	[NonSerialized]
	public static int vikingSpawnStartPopulation = 75;

	private List<Objective> objectives = new List<Objective>();

	private float escalationPoints;

	public float prevTotalPoints;

	public void TrackNext()
	{
		TrackIncr(1);
	}

	public void TrackPrev()
	{
		TrackIncr(-1);
	}

	public void TrackNearest()
	{
		lastTracked = null;
		Vector3 trackingPos = Cam.inst.TrackingPos;
		float num = float.MaxValue;
		for (int i = 0; i < this.unitData.Count; i++)
		{
			UnitData unitData = this.unitData[i];
			if (!unitData.unit.IsBeingCarried())
			{
				float num2 = Mathff.DistSqrdXZ(trackingPos, unitData.unit.GetPos());
				if (num2 < num)
				{
					num = num2;
					lastTracked = unitData;
				}
			}
		}
	}

	public void TrackIncr(int dir)
	{
		for (int i = 0; i < unitData.Count; i++)
		{
			if (unitData[i] != lastTracked)
			{
				continue;
			}
			int num = i;
			int num2 = num;
			do
			{
				num += dir;
				if (num >= unitData.Count)
				{
					num = 0;
				}
				if (num < 0)
				{
					num = unitData.Count - 1;
				}
			}
			while (unitData[num].unit.IsBeingCarried() && num2 != num);
			if (num >= 0 && num <= unitData.Count)
			{
				lastTracked = unitData[num];
				return;
			}
		}
		lastTracked = null;
	}

	Vector3 ICamTrackable.GetDesiredTrackingPos()
	{
		if (lastTracked == null && unitData.Count > 0)
		{
			lastTracked = unitData[0];
		}
		if (lastTracked != null)
		{
			return lastTracked.unit.GetPos();
		}
		if (Player.inst.keep != null)
		{
			return Player.inst.keep.transform.position;
		}
		Cam.inst.ClearTrack();
		return Cam.inst.TrackingPos;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		UnitSystem.inst.OnUnitRemoved += OnUnitDestroyed;
		UnitSystem.inst.OnUnitKilled += OnUnitKilled;
		ShipSystem.inst.onShipArrived += Inst_onShipArrived;
	}

	private void Inst_onShipArrived(ShipBase b)
	{
		if (b.teamID != 1)
		{
			return;
		}
		IUnitControllable component = b.GetComponent<IUnitControllable>();
		if (component == null)
		{
			return;
		}
		UnitData unitDataFor = GetUnitDataFor(component);
		if (unitDataFor == null)
		{
			return;
		}
		int num = -1;
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.GetPos());
		for (int i = -1; i <= 1; i++)
		{
			for (int j = -1; j <= 1; j++)
			{
				Cell cellDataClamped2 = World.inst.GetCellDataClamped(cellDataClamped.x + j, cellDataClamped.z + i);
				if (cellDataClamped2.landMassIdx != -1)
				{
					num = cellDataClamped2.landMassIdx;
					break;
				}
			}
		}
		scratchUnload.Clear();
		for (int k = 0; k < unitDataFor.unit.CarryCount(); k++)
		{
			IUnitControllable carried = unitDataFor.unit.GetCarried(k);
			UnitData unitDataFor2 = GetUnitDataFor(carried);
			if (unitDataFor2.objective != null && World.inst.GetCellDataClamped(unitDataFor2.objective.GetTarget().GetPos()).landMassIdx == num)
			{
				scratchUnload.Add(carried);
			}
		}
		for (int l = 0; l < scratchUnload.Count; l++)
		{
			unitDataFor.unit.DoUnload(scratchUnload[l]);
			unitDataFor.objective = null;
		}
	}

	public UnitData GetUnitDataFor(IUnitControllable unit)
	{
		for (int i = 0; i < unitData.Count; i++)
		{
			if (unitData[i].unit == unit)
			{
				return unitData[i];
			}
		}
		return null;
	}

	public void OnPerformedTheft(IMoveableUnit unit)
	{
	}

	public void OnPerformedTheft(IUnitControllable unit)
	{
		UnitData unitDataFor = GetUnitDataFor(unit);
		if (unitDataFor != null && unitDataFor.objective.type == ObjectiveType.StealResources)
		{
			unitDataFor.objective.Complete();
		}
	}

	public void OnPerformedFire(IUnitControllable unit)
	{
		UnitData unitDataFor = GetUnitDataFor(unit);
		if (unitDataFor != null && unitDataFor.objective.type == ObjectiveType.StartFire)
		{
			unitDataFor.objective.Complete();
		}
	}

	public void OnOgreArrived(IMoveableUnit unit)
	{
		for (int i = 0; i < objectives.Count; i++)
		{
			if (objectives[i].type == ObjectiveType.OgreToBuilding)
			{
				Vector3 pos = unit.GetPos();
				int num = (int)pos.x;
				int num2 = (int)pos.z;
				int num3 = Mathf.Abs(num - objectives[i].targetCellX);
				int num4 = Mathf.Abs(num2 - objectives[i].targetCellZ);
				if (num3 <= 1 && num4 <= 1)
				{
					objectives[i].Complete();
				}
			}
		}
	}

	private void OnUnitDestroyed(IUnitControllable unit)
	{
		for (int i = 0; i < unitData.Count; i++)
		{
			if (unitData[i].unit == unit)
			{
				if (unitData[i] == lastTracked)
				{
					lastTracked = null;
				}
				unitData.RemoveAt(i);
				break;
			}
		}
	}

	private void OnUnitKilled(IUnitControllable unit, int attackerTeamID)
	{
		if (unit.TeamID() == 1)
		{
			float num = 0f;
			if (unit is LegionUnit)
			{
				num += 0.125f;
			}
			if (unit is SiegeMonster)
			{
				num += 0.25f;
			}
			if (unit.CanCarry() && unit.CarryCount() > 0)
			{
				num += 0.25f;
			}
			num *= 1f + (float)(DifficultyManager.inst.currOption.invasionIntensityChoice - 1) * 0.1f;
			escalationPoints += num;
			Cell cellDataClamped = World.inst.GetCellDataClamped(unit.GetPos());
			if (cellDataClamped != null && cellDataClamped.landMassIdx != -1)
			{
				Player.inst.AddHappinessMod("unitkilled", 95f, 5, LocalizationManager.GetTranslation("happinessmod_playerkilledlegion"), cellDataClamped.landMassIdx, addition: true, 25);
			}
		}
	}

	public void Reset()
	{
		lastTracked = null;
		maxShips = 0;
		escalationPoints = 0f;
		yearsUntilNextAttack = 0;
		totalYearsUntilNextAttack = 1;
		yearsUntilNextSkirmish = 0;
		unitsUncarried = 0;
		visited = null;
		for (int i = 0; i < unitData.Count; i++)
		{
			if (!unitData[i].unit.IsBeingCarried())
			{
				deferredRemoval.Add(unitData[i]);
			}
		}
		unitData.Clear();
		for (int j = 0; j < deferredRemoval.Count; j++)
		{
			UnitSystem.inst.DestroyUnit(deferredRemoval[j].unit);
		}
		deferredRemoval.Clear();
		objectives.Clear();
	}

	public bool IsRaidInProgress()
	{
		for (int i = 0; i < unitData.Count; i++)
		{
			if (unitData[i].objective != null || (unitData[i].unit.CanBeCarried() && !unitData[i].unit.IsBeingCarried()))
			{
				return true;
			}
		}
		return false;
	}

	public bool IsRaidInProgressAtLandmass(int landmass)
	{
		bool result = false;
		for (int i = 0; i < unitData.Count; i++)
		{
			ArmySystem.Army army = unitData[i].unit as ArmySystem.Army;
			SiegeMonster siegeMonster = unitData[i].unit as SiegeMonster;
			if (((army != null && !army.IsInvalid()) || (siegeMonster != null && !siegeMonster.IsInvalid())) && World.inst.GetCellDataClamped(unitData[i].unit.GetPos()).landMassIdx == landmass)
			{
				result = true;
			}
		}
		return result;
	}

	private void PopulatePotentialTargets(Vector3 start, int landmass, ref List<Building> targets)
	{
		int hashCode = "path".GetHashCode();
		if (visited == null)
		{
			visited = new bool[World.inst.GridWidth * World.inst.GridHeight];
		}
		Array.Clear(visited, 0, visited.Length);
		targets.Clear();
		ArrayExt<Cell> arrayExt = new ArrayExt<Cell>(1000);
		arrayExt.Add(World.inst.GetCellData(start));
		Vector3[] array = new Vector3[4]
		{
			new Vector3(1f, 0f, 0f),
			new Vector3(-1f, 0f, 0f),
			new Vector3(0f, 0f, 1f),
			new Vector3(0f, 0f, -1f)
		};
		while (arrayExt.Count > 0)
		{
			Cell cell = arrayExt.data[arrayExt.Count - 1];
			arrayExt.RemoveAtSwap(arrayExt.Count - 1);
			for (int i = 0; i < 4; i++)
			{
				int num = cell.x + (int)array[i].x;
				int num2 = cell.z + (int)array[i].z;
				int num3 = num2 * World.inst.GridWidth + num;
				Cell cellData = World.inst.GetCellData(num, num2);
				if (cellData == null || visited[num3])
				{
					continue;
				}
				if (!PathCell.GetBlocksFootPathForArmies(World.inst.GetPathCell(cellData), 1))
				{
					if (cellData.Type != TerrainType.Obstruction && cellData.Type != TerrainType.Water)
					{
						arrayExt.Add(cellData);
						if (cellData.OccupyingStructure.Count > 0 && cellData.OccupyingStructure[0].categoryHash != hashCode && cellData.OccupyingStructure[0].categoryHash != World.cemeteryHash && cellData.OccupyingStructure[0].uniqueNameHash != World.rubbleHash)
						{
							targets.Add(cellData.OccupyingStructure[0]);
						}
					}
				}
				else if (cellData.OccupyingStructure.Count > 0 && (cellData.OccupyingStructure[0].categoryHash == castleblockHash || cellData.OccupyingStructure[0].uniqueNameHash == World.keepHash))
				{
					targets.Add(cellData.OccupyingStructure[0]);
				}
				visited[num3] = true;
			}
		}
	}

	private IUnitControllable GetNearestOpenTransportFor(IUnitControllable toLoad)
	{
		Vector3 pos = toLoad.GetPos();
		IUnitControllable unitControllable = null;
		float num = float.MaxValue;
		for (int i = 0; i < unitData.Count; i++)
		{
			if (unitData[i].unit.CanCarry() && (unitData[i].unit.GetRemainingCapacity() == toLoad.GetSlotsOccupied() || unitData[i].unit.PendingCarry(toLoad)) && unitData[i].objective == null)
			{
				Vector3 pos2 = unitData[i].unit.GetPos();
				float num2 = Mathff.DistSqrdXZ(pos, pos2);
				if (num2 < num)
				{
					num = num2;
					unitControllable = unitData[i].unit;
				}
			}
		}
		if (unitControllable == null)
		{
			num = float.MaxValue;
			for (int j = 0; j < unitData.Count; j++)
			{
				if (unitData[j].unit.CanCarry() && (unitData[j].unit.GetRemainingCapacity() >= toLoad.GetSlotsOccupied() || unitData[j].unit.PendingCarry(toLoad)) && unitData[j].objective == null)
				{
					Vector3 pos3 = unitData[j].unit.GetPos();
					float num3 = Mathff.DistSqrdXZ(pos, pos3);
					if (num3 < num)
					{
						num = num3;
						unitControllable = unitData[j].unit;
					}
				}
			}
		}
		return unitControllable;
	}

	private bool IsOgreActiveWithinRadius(Vector3 pos, float radius)
	{
		return false;
	}

	private void Update()
	{
		frameAccum++;
		if (frameAccum > 10)
		{
			frameAccum = 0;
			unitsUncarried = 0;
			int num = 0;
			for (int i = 0; i < unitData.Count; i++)
			{
				if (unitData[i].unit.CanBeCarried())
				{
					unitsUncarried += ((!unitData[i].unit.IsBeingCarried()) ? unitData[i].unit.GetSlotsOccupied() : 0);
				}
				if (unitData[i].unit.CanCarry() && unitData[i].objective == null)
				{
					num += unitData[i].unit.GetRemainingCapacity();
				}
			}
			for (int j = 0; j < unitData.Count; j++)
			{
				if (unitData[j].unit.CanCarry())
				{
					if (unitData[j].unit.CarryCount() > 0 && unitData[j].objective == null)
					{
						UnitData unitDataFor = GetUnitDataFor(unitData[j].unit.GetCarried(0));
						unitData[j].objective = unitDataFor.objective;
					}
					else if (unitData[j].unit.CarryCount() == 0)
					{
						unitData[j].objective = null;
					}
				}
				else
				{
					unitData[j].TryAssignObjective(objectives);
				}
				if (unitData[j].unit.IsBeingCarried())
				{
					continue;
				}
				if (unitData[j].objective != null)
				{
					if (unitData[j].unit.CanCarry())
					{
						SerializableVector3 landing = unitData[j].objective.landing;
						Debug.DrawLine(unitData[j].unit.GetPos() + new Vector3(0f, 1f, 0f), landing + new Vector3(0f, 1f, 0f), Color.yellow);
						UnitSystem.inst.MoveTo(unitData[j].unit, World.inst.GetCellData(landing));
						if (unitData[j].unit is UnitTransportShip { failedLastUnload: not false })
						{
							UnitData unitDataFor2 = GetUnitDataFor(unitData[j].unit.GetCarried(0));
							unitDataFor2.ignoreList.Add(unitDataFor2.objective);
							unitDataFor2.objective = null;
							unitData[j].objective = null;
						}
					}
					else
					{
						UnitSystem.inst.MoveTo(unitData[j].unit, unitData[j].objective.GetTarget());
					}
					bool ogresActive = IsOgreActiveWithinRadius(unitData[j].unit.GetPos(), 20f);
					unitData[j].UpdateAndVerifyObjective(ogresActive, objectives);
				}
				else if (unitData[j].unit.CanCarry())
				{
					if (!unitData[j].unit.IsPendingLoadTargets() && (unitData[j].unit.GetRemainingCapacity() <= 0 || num - unitData[j].unit.GetRemainingCapacity() >= unitsUncarried || unitsUncarried == 0))
					{
						num -= unitData[j].unit.GetRemainingCapacity();
						Cell cellDataClamped = World.inst.GetCellDataClamped(unitData[j].spawnCell);
						UnitSystem.inst.MoveTo(unitData[j].unit, cellDataClamped);
						if (Mathff.DistSqrdXZ(unitData[j].unit.GetPos(), cellDataClamped.Center2D) < 1f)
						{
							deferredRemoval.Add(unitData[j]);
						}
					}
				}
				else
				{
					IMoveTarget moveTarget = unitData[j].unit.GetMoveTarget();
					if (!(moveTarget is TroopTransportShip))
					{
						moveTarget = GetNearestOpenTransportFor(unitData[j].unit) as IMoveTarget;
					}
					if (moveTarget != null)
					{
						UnitSystem.inst.MoveTo(unitData[j].unit, moveTarget);
					}
				}
			}
			int num2 = 0;
			for (int k = 0; k < deferredRemoval.Count; k++)
			{
				int num3 = deferredRemoval[k].unit.CarryCount();
				for (int l = 0; l < num3; l++)
				{
					IUnitControllable carried = deferredRemoval[k].unit.GetCarried(l);
					if (!(carried is ArmySystem.Army))
					{
						continue;
					}
					ArmySystem.Army army = carried as ArmySystem.Army;
					for (int m = 0; m < army.units.Count; m++)
					{
						ArmySystem.Unit unit = army.units.data[m];
						if (unit.type == ArmySystem.Unit.Type.Kidnapper && unit.kidnapCompleted && Player.inst.LandMassIsAPlayerLandMass(unit.kidnapLandmass))
						{
							num2++;
						}
					}
				}
				UnitSystem.inst.DestroyUnit(deferredRemoval[k].unit);
			}
			deferredRemoval.Clear();
		}
		bool flag = IsRaidInProgress();
		if (wasRaidInProgress && !flag)
		{
			MilestoneManager.inst.TrySurviveInvasionMilestone();
		}
		wasRaidInProgress = flag;
	}

	public void ResetTimer()
	{
		yearsUntilNextAttack = totalYearsUntilNextAttack;
	}

	public void OnNewYear()
	{
		if (AllowSpawningVikings() && DifficultyManager.inst.currOption.isInvasionsEnabled)
		{
			if (yearsUntilNextAttack <= 0)
			{
				SetupRaid();
				yearsUntilNextAttack = SRand.Range(DifficultyManager.inst.currOption.minInvasionFrequency, DifficultyManager.inst.currOption.maxInvasionFrequency);
				totalYearsUntilNextAttack = yearsUntilNextAttack;
			}
			else
			{
				yearsUntilNextAttack--;
			}
		}
	}

	public static List<Cell> GetLandings(int targetLandmass, int minVillagers = 50)
	{
		List<Cell> list = new List<Cell>();
		Cell[] array = new Cell[4];
		ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[targetLandmass];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			Cell cell = arrayExt.data[i];
			if (!cell.buildingAccess || cell.Type == TerrainType.Obstruction)
			{
				continue;
			}
			bool flag = false;
			World.inst.GetNeighborCells(cell, ref array);
			foreach (Cell cell2 in array)
			{
				if (cell2 != null && cell2.Type == TerrainType.Water && !PathCell.GetBlocksWaterPath(World.inst.GetPathCell(cell2), 1))
				{
					flag = true;
					break;
				}
			}
			if (flag)
			{
				list.Add(cell);
			}
		}
		return list;
	}

	private int GetFirstArrivalYear()
	{
		return DifficultyManager.inst.currOption.invasionStartYear;
	}

	public bool AllowSpawningVikings()
	{
		int count = Player.inst.Workers.Count;
		if (SeasonManager.inst.CurrentYear() >= GetFirstArrivalYear() && count > vikingSpawnStartPopulation)
		{
			return Creative.inst.IsCreativeOptionOn(5);
		}
		return false;
	}

	private void ClearUnassignedObjectives()
	{
		for (int i = 0; i < objectives.Count; i++)
		{
			bool flag = false;
			for (int j = 0; j < unitData.Count; j++)
			{
				if (objectives[i] == unitData[j].objective)
				{
					flag = true;
					break;
				}
			}
			if (!flag)
			{
				objectives.RemoveAt(i);
				i--;
			}
		}
	}

	public int CalculateRaidPoints()
	{
		int invasionIntensityChoice = DifficultyManager.inst.currOption.invasionIntensityChoice;
		float num = 0f;
		int num2 = Player.inst.Workers.Count;
		float num3 = 12f;
		while (num2 > 0)
		{
			num += (float)Mathff.Clamp(num2, 0, 450) / num3;
			num2 -= 450;
			num3 += 8f;
		}
		float num4 = 0f;
		float num5 = 6f;
		if (invasionIntensityChoice == 2)
		{
			num5 = 4f;
		}
		if (invasionIntensityChoice == 3)
		{
			num5 = 2f;
		}
		if (invasionIntensityChoice == 4)
		{
			num5 = 1f;
		}
		int num6 = SeasonManager.inst.CurrentYear();
		if (DifficultyManager.inst.difficulty == 4)
		{
			num4 += (float)num6 / num5;
		}
		else
		{
			float num7 = num5;
			while (num6 > 0)
			{
				num4 += (float)Mathff.Clamp(num6, 0, 100) / num7;
				num6 -= 100;
				num7 += 4f;
			}
		}
		int num8 = (int)(num4 + num + escalationPoints / (float)Mathf.Max(1, 5 - invasionIntensityChoice));
		prevTotalPoints = num8;
		float num9 = 0.1f;
		if (invasionIntensityChoice == 2)
		{
			num9 = 0.2f;
		}
		if (invasionIntensityChoice == 3)
		{
			num9 = 0.3f;
		}
		if (invasionIntensityChoice == 4)
		{
			num9 = 1f;
		}
		if ((float)num8 > (float)Player.inst.Workers.Count * num9)
		{
			num8 = (int)((float)Player.inst.Workers.Count * num9);
		}
		int max = 400;
		if (invasionIntensityChoice == 2)
		{
			max = 600;
		}
		if (invasionIntensityChoice == 3)
		{
			max = 900;
		}
		if (invasionIntensityChoice == 4)
		{
			max = 1200;
		}
		return Mathff.Clamp(num8, 3, max);
	}

	public void SetupRaid()
	{
		OnRaidStarted?.Invoke();
		int invasionIntensityChoice = DifficultyManager.inst.currOption.invasionIntensityChoice;
		if (invasionIntensityChoice >= 0 && invasionIntensityChoice <= 2)
		{
			maxShips += 1 + AIBrainsContainer.inst.transform.childCount;
		}
		else
		{
			switch (invasionIntensityChoice)
			{
			case 3:
				maxShips += 2 * (1 + AIBrainsContainer.inst.transform.childCount);
				break;
			case 4:
				maxShips = 999;
				break;
			}
		}
		if (maxShips >= 4)
		{
			maxShips = 999;
		}
		ClearUnassignedObjectives();
		List<Objective> list = new List<Objective>();
		int num = CalculateRaidPoints();
		if (num <= 60)
		{
			MusicSystem.inst.StartSmallInvasionMusic();
		}
		else
		{
			MusicSystem.inst.StartLargeInvasionMusic();
		}
		List<ObjectiveType> list2 = new List<ObjectiveType>();
		for (int i = 0; i < 7; i++)
		{
			list2.Add(ObjectiveType.StartFire);
		}
		if (num >= 10)
		{
			list2.Add(ObjectiveType.StealResources);
		}
		int startingPoints = num;
		while (num > 0)
		{
			int index = SRand.Range(0, list2.Count);
			ObjectiveType objectiveType = list2[index];
			int num2 = 0;
			switch (objectiveType)
			{
			case ObjectiveType.StartFire:
				num2 = 1;
				break;
			case ObjectiveType.StealResources:
				num2 = 4;
				break;
			}
			num -= num2;
			list.Add(new Objective
			{
				type = objectiveType,
				targetCellX = -1,
				targetCellZ = -1
			});
		}
		new List<Objective>();
		int num3 = 0;
		List<int> list3 = new List<int>();
		List<List<Cell>> list4 = new List<List<Cell>>();
		for (int j = 0; j < World.inst.NumLandMasses; j++)
		{
			int count = World.inst.GetVillagersForLandMass(j).Count;
			if (count > 0)
			{
				List<Cell> landings = GetLandings(j);
				if (landings.Count > 0)
				{
					list4.Add(landings);
					list3.Add(j);
				}
			}
			num3 += count;
		}
		bool flag = DifficultyManager.inst.currOption.invasionIntensityChoice >= 3;
		if (flag && num3 > 100)
		{
			_ = 1;
		}
		else if (!flag)
		{
			if (num3 > 275)
			{
				_ = 1;
			}
			else if (num3 > 150)
			{
				_ = SeasonManager.inst.CurrentYear() > 70;
			}
			else
				_ = 0;
		}
		else
			_ = 0;
		int totalBoats = 0;
		int count2 = Player.inst.Workers.Count;
		List<ObjectiveSet> list5 = new List<ObjectiveSet>();
		int num4 = 0;
		for (int k = 0; k < list3.Count; k++)
		{
			float num5 = (float)World.inst.GetVillagersForLandMass(list3[k]).Count / (float)count2;
			if (DifficultyManager.inst.currOption.invasionIntensityChoice == 4)
			{
				num5 = 1f / (float)list3.Count;
			}
			int num6 = Mathff.Max(1, Mathf.FloorToInt((float)list.Count * num5));
			int num7 = num6;
			if (num6 >= 10)
			{
				int num8 = SRand.Range(0, 100);
				if (num8 >= 0 && num8 < 25)
				{
					num7 = (int)((float)num6 * 0.33f);
				}
				else if (num8 >= 25 && num8 < 50)
				{
					num7 = (int)((float)num6 * 0.5f);
				}
			}
			ObjectiveSet objectiveSet = null;
			for (int l = 0; l < num6; l++)
			{
				if (num4 >= list.Count)
				{
					break;
				}
				if (objectiveSet == null || l == num7)
				{
					objectiveSet = new ObjectiveSet();
					objectiveSet.landmassIdx = list3[k];
					objectiveSet.landings = list4[k];
					list5.Add(objectiveSet);
				}
				if (list[num4].type == ObjectiveType.StartFire)
				{
					objectiveSet.startFire.Add(list[num4]);
				}
				if (list[num4].type == ObjectiveType.StealResources)
				{
					objectiveSet.stealResources.Add(list[num4]);
				}
				num4++;
			}
		}
		Cell obj = World.inst.rimCells[SRand.Range(0, World.inst.rimCells.Length - 1)];
		int num9 = 0;
		Vector3 normalized = (obj.Center2D - World.inst.GridCenter()).normalized;
		for (int m = 0; m < list5.Count; m++)
		{
			int landmassIdx = list5[m].landmassIdx;
			Vector3 worldPos = World.inst.GridCenter() + Quaternion.AngleAxis(num9, new Vector3(0f, 1f, 0f)) * normalized * World.inst.GridWidth * 1.41f;
			num9 += 200;
			Cell cellDataClamped = World.inst.GetCellDataClamped(worldPos);
			List<Cell> landings2 = list5[m].landings;
			Cell cell = RemoveBestLanding(landings2, cellDataClamped.Center2D);
			List<Building> targets = new List<Building>();
			PopulatePotentialTargets(cell.Center2D, landmassIdx, ref targets);
			if (targets.Count > 0)
			{
				List<Objective> list6 = new List<Objective>();
				List<Objective> list7 = new List<Objective>();
				PopulateFireObjectives(list5[m], list7, targets, landings2);
				PopulateTheftObjectives(list5[m], list6, targets, landings2);
				SpawnBoatsForObjectives(list7, ref totalBoats, cellDataClamped, cell, landings2, startingPoints);
				SpawnBoatsForObjectives(list6, ref totalBoats, cellDataClamped, cell, landings2, startingPoints);
			}
		}
		for (int n = 0; n < list.Count; n++)
		{
			objectives.Add(list[n]);
		}
		for (int num10 = 0; num10 < objectives.Count; num10++)
		{
			if (objectives[num10].targetCellX == -1 && objectives[num10].targetCellZ == -1)
			{
				objectives.RemoveAt(num10);
				num10--;
			}
		}
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_invasion_horn");
	}

	private void SpawnBoatsForObjectives(List<Objective> attackObjectives, ref int totalBoats, Cell spawnCell, Cell landing, List<Cell> landings, int startingPoints)
	{
		int num = 0;
		IUnitControllable unitControllable = null;
		int num2 = 0;
		for (int i = 0; i < attackObjectives.Count; i += 4)
		{
			if (totalBoats >= maxShips)
			{
				break;
			}
			Vector3 vector = spawnCell.Center2D - World.inst.GridCenter();
			vector.Normalize();
			Vector3 vector2 = new Vector3(vector.z, 0f, 0f - vector.x);
			int num3 = 1;
			int num4 = SRand.Range(0, 100);
			if (startingPoints > 20)
			{
				num3 = ((num4 > 70) ? 1 : 2);
			}
			if (startingPoints > 100)
			{
				num3 = ((num4 <= 70) ? 3 : ((num4 <= 70 || num4 > 90) ? 1 : 2));
			}
			if (unitControllable == null || unitControllable.GetRemainingCapacity() < num3)
			{
				RemoveNearestLanding(landings, landing.Center2D);
				unitControllable = SpawnVikingBoat(spawnCell.Center2D + vector * 10f + vector2 * num * 2f);
				num2 = 0;
				num++;
				totalBoats++;
			}
			LegionUnit legionUnit = LegionSystem.Inst.TrySpawn(0, World.inst.GridCenter(), 1, num3);
			if (legionUnit != null)
			{
				UnitData unitData = new UnitData();
				unitData.unit = legionUnit;
				unitData.objective = attackObjectives[i];
				this.unitData.Add(unitData);
				if (unitControllable is UnitTransportShip unitTransportShip)
				{
					unitTransportShip.TryForceLoad(legionUnit);
				}
				GetUnitDataFor(unitControllable).objective = attackObjectives[i];
				num2++;
			}
		}
	}

	private void PopulateTheftObjectives(ObjectiveSet objectiveSet, List<Objective> theftObjectives, List<Building> targets, List<Cell> landings)
	{
		int num = 0;
		for (int i = 0; i < objectiveSet.stealResources.Count; i++)
		{
			Objective objective = objectiveSet.stealResources[i];
			Building building = null;
			int num2 = num;
			do
			{
				if (targets[num].categoryHash == World.templeHash)
				{
					building = targets[num];
				}
				num++;
				if (num >= targets.Count)
				{
					num = 0;
				}
			}
			while (num2 != num && building == null);
			if (building == null)
			{
				building = Player.inst.GetBuildingListForLandMass(objectiveSet.landmassIdx, treasureRoomHash).RandomElement();
			}
			if (building != null && (bool)building.GetComponent<Temple>() && Player.inst.PlayerLandmassOwner.Gold > 0)
			{
				objective.landing = RemoveNearestLanding(landings, building.cachedPos).Center2D;
				objective.targetCellX = (int)building.transform.position.x;
				objective.targetCellZ = (int)building.transform.position.z;
				theftObjectives.Add(objective);
			}
		}
	}

	private void PopulateFireObjectives(ObjectiveSet objectiveSet, List<Objective> startFireObjectives, List<Building> targets, List<Cell> landings)
	{
		int num = 0;
		for (int i = 0; i < objectiveSet.startFire.Count; i++)
		{
			Objective objective = objectiveSet.startFire[i];
			Building building = null;
			int num2 = num;
			do
			{
				if (DifficultyManager.inst.difficulty == 4)
				{
					building = targets[num];
				}
				else if (targets[num].uniqueNameHash == World.farmHash || targets[num].uniqueNameHash == World.orchardHash || targets[num].categoryHash == World.stockpileHash || targets[num].categoryHash == World.houseCategoryHash || targets[num].uniqueNameHash == World.woodcastleblockHash || targets[num].categoryHash == World.granaryCategoryHash || targets[num].categoryHash == World.warehouseHash)
				{
					building = targets[num];
				}
				num++;
				if (num >= targets.Count)
				{
					num = 0;
				}
			}
			while (num2 != num && building == null);
			if (building == null)
			{
				ArrayExt<ArrayExt<Building>> buildingArrays = new ArrayExt<ArrayExt<Building>>(5);
				Player.inst.GetBuildingListsByCategoryForLandMass(objectiveSet.landmassIdx, World.houseCategoryHash, ref buildingArrays);
				int num3 = 0;
				int num4 = 0;
				for (; i < buildingArrays.Count; i++)
				{
					num3 += buildingArrays.data[num4].Count;
				}
				int num5 = 0;
				int num6 = SRand.Range(0, num3);
				for (int j = 0; j < buildingArrays.Count; j++)
				{
					if (num6 >= num5 && num6 < num5 + buildingArrays.data[j].Count)
					{
						building = buildingArrays.data[j].data[num6 - num5];
						break;
					}
					num5 += buildingArrays.data[j].Count;
				}
			}
			if (building != null)
			{
				objective.landing = RemoveNearestLanding(landings, building.cachedPos).Center2D;
				objective.targetCellX = (int)building.transform.position.x;
				objective.targetCellZ = (int)building.transform.position.z;
				startFireObjectives.Add(objective);
			}
		}
	}

	private void AddDestroyBuildingObjectivesIfNecessary(Cell landing, Building target, List<Objective> destroyBuildingObjectives)
	{
		ArrayExt<Vector3> path = new ArrayExt<Vector3>(32);
		World.inst.FindPath(landing, target.GetCell(), ref path, PathCell.NoBlock, PathCell.GetBlocksFootPathForArmies, PathCell.GetMilitaryFootPathCost, 1, doDiagonal: false);
		World.inst.TrimPathForBlockedCells(ref path, PathCell.GetBlocksFootPathForArmies, 1);
		Vector3 worldPos = landing.Center2D;
		if (path.Count > 0)
		{
			worldPos = path.data[path.Count - 1];
		}
		Cell cell = null;
		Cell[] array = new Cell[4];
		World.inst.GetNeighborCells(World.inst.GetCellDataClamped(worldPos), ref array);
		for (int i = 0; i < array.Length; i++)
		{
			if (array[i] != null && (array[i].StructureCompareCategoryNameAll(castleblockHash) || array[i].StructureCompareCategoryNameAll(gateHash)))
			{
				cell = array[i];
			}
		}
		if (cell != null)
		{
			destroyBuildingObjectives.Add(new Objective
			{
				type = ObjectiveType.OgreToBuilding,
				targetCellX = (int)target.transform.position.x,
				targetCellZ = (int)target.transform.position.z,
				landing = landing.Center2D
			});
		}
	}

	private IUnitControllable SpawnVikingBoat(Vector3 pos)
	{
		return SpawnBoat(pos, ShipSystem.inst.raiderTransportShip);
	}

	public IUnitControllable SpawnBoatRaw(Vector3 pos, UnitTransportShip prefab)
	{
		ShipBase component = UnityEngine.Object.Instantiate(prefab).GetComponent<ShipBase>();
		component.Init(1);
		component.SetPos(pos);
		component.transform.rotation = Quaternion.LookRotation(World.inst.GridCenter() - pos);
		return component.GetComponent<IUnitControllable>();
	}

	private IUnitControllable SpawnBoat(Vector3 pos, UnitTransportShip prefab)
	{
		Vector3 pos2 = pos;
		pos2 += (pos - World.inst.GridCenter()).normalized * 10f;
		pos2 += transform.right * SRand.value * 2f + transform.forward * SRand.value * 2f;
		IUnitControllable unitControllable = SpawnBoatRaw(pos2, prefab);
		UnitData item = new UnitData
		{
			unit = unitControllable
		};
		unitData.Add(item);
		return unitControllable;
	}

	public IUnitControllable SpawnOgre(Vector3 pos, bool untracked = false)
	{
		GameObject gameObject = UnityEngine.Object.Instantiate(ogrePrefab);
		gameObject.transform.position = pos;
		if (!untracked)
		{
			unitData.Add(new UnitData
			{
				unit = gameObject.GetComponent<IUnitControllable>()
			});
		}
		return gameObject.GetComponent<IUnitControllable>();
	}

	private void GetSpawnStrength(out int spawnWait, out int requestArmies, out int squadSize)
	{
		int num = 0;
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			num += Player.inst.resourcesPerLandmass[i].Get(2);
		}
		spawnWait = -1;
		requestArmies = 0;
		squadSize = 16;
		int count = Player.inst.Workers.Count;
		bool flag = Player.inst.difficulty >= Player.Difficulty.Hard;
		if (count > vikingSpawnStartPopulation && count <= 60 && num > 10)
		{
			requestArmies = ((!flag) ? 1 : 2);
			squadSize = (flag ? 7 : 5);
		}
		else if (count > 60 && count <= 150)
		{
			requestArmies = (flag ? 4 : 2);
			squadSize = (flag ? 9 : 7);
		}
		else if (count > 150 && count <= 300)
		{
			requestArmies = (flag ? 9 : 5);
			squadSize = (flag ? 12 : 9);
		}
		else if (count > 300 && count < 500)
		{
			requestArmies = (flag ? 10 : 7);
			squadSize = (flag ? 14 : 11);
		}
		else if (count > 500)
		{
			requestArmies = (flag ? 12 : 9);
			squadSize = 16;
		}
		spawnWait = (flag ? 9 : 11);
	}

	private Cell RemoveNearestLanding(List<Cell> landings, Vector3 pos)
	{
		int num = 2500;
		Cell cell = null;
		float num2 = float.MaxValue;
		for (int i = 0; i < landings.Count; i++)
		{
			float num3 = Mathff.DistSqrdXZ(landings[i].Center2D, pos);
			if (landings[i].OccupyingStructure.Count > 0)
			{
				num3 += (float)num;
			}
			num3 += (float)(landings[i].Danger * num);
			if (num3 < num2)
			{
				num2 = num3;
				cell = landings[i];
			}
		}
		if (cell != null)
		{
			landings.Remove(cell);
		}
		return cell;
	}

	private Cell RemoveBestLanding(List<Cell> landings, Vector3 pos)
	{
		Cell cell = null;
		float num = float.MaxValue;
		for (int i = 0; i < landings.Count; i++)
		{
			float num2 = Mathff.DistSqrdXZ(landings[i].Center2D, pos);
			if (PathCell.GetBlocksFootPathForArmies(World.inst.GetPathCell(landings[i]), 1))
			{
				num2 *= 100f;
			}
			else if (landings[i].OccupyingStructure.Count > 0)
			{
				num2 *= 5f;
			}
			if (num2 < num)
			{
				num = num2;
				cell = landings[i];
			}
		}
		if (cell != null)
		{
			landings.Remove(cell);
		}
		return cell;
	}

	private Objective GetObjectiveByGuid(Guid guid)
	{
		for (int i = 0; i < objectives.Count; i++)
		{
			if (objectives[i].guid == guid)
			{
				return objectives[i];
			}
		}
		return null;
	}

	internal bool IsTargetedForBurning(Building target)
	{
		for (int i = 0; i < objectives.Count; i++)
		{
			if (objectives[i].type == ObjectiveType.StartFire && objectives[i].GetTarget() == target)
			{
				return true;
			}
		}
		return false;
	}
}
