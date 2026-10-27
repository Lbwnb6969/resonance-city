using System;
using System.Collections.Generic;
using UnityEngine;

public class AIUnitControlSystem : ICamTrackable
{
	public delegate void notifyObjectiveDelegate(Objective u);

	public class UnitData
	{
		private Objective _objective;

		public IMoveableUnit unit;

		private List<Objective> ignoreList = new List<Objective>();

		public Objective objective => _objective;

		public void SetObjective(Objective o, AIUnitControlSystem system)
		{
			if (_objective != null)
			{
				_objective.unitsAssigned.Remove(this);
				if (unit is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy } army)
				{
					army.general.GetComponent<Envoy>().issueButton.gameObject.SetActive(value: false);
				}
				system.OnObjectiveUnassigned?.Invoke(_objective);
			}
			_objective = o;
			if (_objective != null)
			{
				if (objective.exclusive && unit.CanBeCarried() && _objective.unitsAssigned.Count != 0)
				{
					_ = 0;
				}
				_objective.unitsAssigned.Add(this);
			}
		}

		public bool ShouldIgnore(Objective o)
		{
			return ignoreList.Contains(o);
		}

		public bool CanComplete(Objective objective)
		{
			if (ignoreList.Count >= 30 || ShouldIgnore(objective))
			{
				return false;
			}
			IMoveableUnit moveableUnit = objective.GetTarget() as IMoveableUnit;
			if (moveableUnit != null && moveableUnit.IsBeingCarried())
			{
				return false;
			}
			Cell cellDataClamped = World.inst.GetCellDataClamped(objective.target.GetPos());
			if (unit is SiegeCatapult && (objective.type == ObjectiveType.DestroyBuilding || objective.type == ObjectiveType.DestroyUnit))
			{
				if (moveableUnit != null && moveableUnit.GetMoveType() != MoveType.Land)
				{
					return false;
				}
				return true;
			}
			if (unit is ArmySystem.Army)
			{
				ArmySystem.Army army = unit as ArmySystem.Army;
				if (army.armyType == ArmySystem.ArmyType.Archer && (objective.type == ObjectiveType.DestroyBuilding || objective.type == ObjectiveType.DestroyUnit))
				{
					if (moveableUnit != null && moveableUnit.GetMoveType() != MoveType.Land)
					{
						return false;
					}
					return true;
				}
				if (army.armyType == ArmySystem.ArmyType.Default && (objective.type == ObjectiveType.StartFire || objective.type == ObjectiveType.DestroyBuilding || objective.type == ObjectiveType.DestroyUnit))
				{
					if (moveableUnit != null && moveableUnit.GetMoveType() != MoveType.Land)
					{
						return false;
					}
					return true;
				}
				if (army.armyType == ArmySystem.ArmyType.Thief && objective.type == ObjectiveType.StealResources && army.stolenResourceAmount <= 0)
				{
					if (cellDataClamped.OccupyingStructure.Count > 0)
					{
						Building building = cellDataClamped.OccupyingStructure[0];
						if ((bool)building.GetComponent<ThroneRoom>() && World.GetLandmassOwner(building.LandMass()).Gold > 0)
						{
							return true;
						}
					}
				}
				else if (army.armyType == ArmySystem.ArmyType.Envoy)
				{
					if (objective.type == ObjectiveType.MoveToBuilding || objective.type == ObjectiveType.WaitForComplete)
					{
						return true;
					}
					if (objective.type == ObjectiveType.GiveGift && !army.general.GetComponent<Envoy>().giftAmount.IsNone())
					{
						return true;
					}
					if (objective.type == ObjectiveType.PickUpGift && army.general.GetComponent<Envoy>().giftAmount.IsNone())
					{
						return true;
					}
				}
			}
			return false;
		}

		public void TryAssignObjective(List<Objective> objectives, AIUnitControlSystem sys)
		{
			if (objective != null)
			{
				if (!unit.CanCarry() && !CanComplete(objective))
				{
					SetObjective(null, sys);
					if (!unit.IsBeingCarried())
					{
						OrdersManager.inst.MoveTo(unit, World.inst.GetCellDataClamped(unit.GetPos()));
					}
				}
				if (!unit.CanCarry())
				{
					return;
				}
				bool flag = false;
				for (int i = 0; i < unit.CarryCount(); i++)
				{
					IMoveableUnit carried = unit.GetCarried(i);
					if (sys.GetUnitDataFor(carried).objective != null)
					{
						flag = true;
						break;
					}
				}
				if (!flag)
				{
					SetObjective(null, sys);
				}
			}
			else
			{
				if (unit.CanCarry() && unit.CarryCount() == 0)
				{
					return;
				}
				if (unit.CanCarry() && unit.CarryCount() > 0)
				{
					for (int j = 0; j < unit.CarryCount(); j++)
					{
						IMoveableUnit carried2 = unit.GetCarried(j);
						UnitData unitDataFor = sys.GetUnitDataFor(carried2);
						if (unitDataFor.objective != null)
						{
							SetObjective(unitDataFor.objective, sys);
							if (unitDataFor.unit is ArmySystem.Army { armyType: not ArmySystem.ArmyType.Envoy })
							{
								break;
							}
						}
					}
				}
				else
				{
					if (ignoreList.Count >= 30)
					{
						return;
					}
					for (int k = 0; k < objectives.Count; k++)
					{
						if (objectives[k].dependency == null && !objectives[k].IsComplete() && !ShouldIgnore(objectives[k]) && CanComplete(objectives[k]) && (unit.CanCarry() || !objectives[k].exclusive || objectives[k].unitsAssigned.Count <= 0))
						{
							SetObjective(objectives[k], sys);
							Objective item = objectives[k];
							objectives.RemoveAt(k);
							objectives.Add(item);
							break;
						}
					}
				}
			}
		}
	}

	public enum ObjectiveType
	{
		StartFire,
		StealResources,
		DestroyBuilding,
		DestroyUnit,
		MoveToBuilding,
		GiveGift,
		WaitForComplete,
		OgreToBuilding,
		PickUpGift
	}

	public delegate bool testUnit(IMoveableUnit u);

	[Serializable]
	public class Objective
	{
		public enum FailType
		{
			None,
			NoUnits,
			NoShips
		}

		public ObjectiveType type;

		public Objective next;

		public Objective dependency;

		public IMoveTarget target;

		public int priority;

		public bool completed;

		public SerializableVector3 landing;

		public List<UnitData> unitsAssigned = new List<UnitData>();

		public bool exclusive;

		public Guid guid = Guid.NewGuid();

		public float time = float.MaxValue;

		public void Complete()
		{
			if (!completed)
			{
				completed = true;
			}
		}

		public bool IsComplete()
		{
			if (!completed)
			{
				if (target == null || target.Equals(null))
				{
					Complete();
				}
				else if (type == ObjectiveType.StartFire || type == ObjectiveType.StealResources)
				{
					Cell cellData = World.inst.GetCellData(target.GetPos());
					if (cellData.busyObj is Fire || (cellData.OccupyingStructure.Count > 0 && cellData.BottomStructure.uniqueNameHash == rubbleHash) || cellData.OccupyingStructure.Count <= 0)
					{
						Complete();
					}
				}
				else if (type == ObjectiveType.DestroyBuilding)
				{
					Cell cellData2 = World.inst.GetCellData(target.GetPos());
					if ((cellData2.OccupyingStructure.Count > 0 && cellData2.BottomStructure.uniqueNameHash == rubbleHash) || cellData2.OccupyingStructure.Count <= 0)
					{
						Complete();
					}
				}
				else if (type == ObjectiveType.OgreToBuilding)
				{
					Cell cellData3 = World.inst.GetCellData(target.GetPos());
					if (cellData3.OccupyingStructure.Count <= 0 || (cellData3.OccupyingStructure.Count > 0 && cellData3.BottomStructure.uniqueNameHash == rubbleHash))
					{
						Complete();
					}
				}
				else if (type == ObjectiveType.MoveToBuilding || type == ObjectiveType.GiveGift || type == ObjectiveType.PickUpGift)
				{
					Building bottomStructure = World.inst.GetCellData(target.GetPos()).BottomStructure;
					for (int i = 0; i < unitsAssigned.Count; i++)
					{
						Vector3 a = bottomStructure.Center();
						Vector3 pos = unitsAssigned[i].unit.GetPos();
						if (Mathff.DistSqrdXZ(a, pos) < Mathff.MagnitudeSqrdXZ(bottomStructure.size) + 0.25f && !unitsAssigned[i].unit.IsBeingCarried() && !unitsAssigned[i].unit.CanCarry())
						{
							if (type == ObjectiveType.MoveToBuilding || type == ObjectiveType.GiveGift)
							{
								Complete();
							}
							else if (type == ObjectiveType.PickUpGift && !(unitsAssigned[i].unit as ArmySystem.Army).general.GetComponent<Envoy>().giftAmount.IsNone())
							{
								Complete();
							}
						}
					}
				}
				else if (type != ObjectiveType.WaitForComplete && type == ObjectiveType.DestroyUnit && target is IMoveableUnit moveableUnit && !moveableUnit.Equals(null) && moveableUnit.CurrHealth() <= 0f)
				{
					Complete();
				}
				if (completed && target != null && !target.Equals(null))
				{
					AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(World.inst.GetCellData(target.GetPos()).landMassIdx);
					if (kingdomByLandmass != null && kingdomByLandmass.globalThreatLevel < 1)
					{
						kingdomByLandmass.globalThreatLevel = 1;
					}
				}
			}
			return completed;
		}

		public IMoveTarget GetTarget()
		{
			return target;
		}
	}

	[Serializable]
	public class AIUnitControlSystemData : SaveClass<AIUnitControlSystem, AIUnitControlSystemData>
	{
		[Serializable]
		private struct UnitDataSave
		{
			public Guid guid;

			public Guid objectiveGuid;
		}

		[Serializable]
		private enum TargetType
		{
			Invalid,
			Unit,
			Building,
			WolfDen
		}

		[Serializable]
		private struct ObjectiveSaveData
		{
			public ObjectiveType type;

			public Guid next;

			public Guid dependency;

			public TargetType targetType;

			public Guid targetGuid;

			public int priority;

			public bool completed;

			public bool exclusive;

			public Guid guid;

			public float time;
		}

		private List<ObjectiveSaveData> objectives = new List<ObjectiveSaveData>();

		private List<UnitDataSave> unitData = new List<UnitDataSave>();

		public override AIUnitControlSystemData Pack(AIUnitControlSystem d)
		{
			for (int i = 0; i < d.objectives.Count; i++)
			{
				Objective objective = d.objectives[i];
				ObjectiveSaveData item = new ObjectiveSaveData
				{
					type = objective.type
				};
				if (objective.dependency != null)
				{
					item.dependency = objective.dependency.guid;
				}
				else
				{
					item.dependency = Guid.Empty;
				}
				if (objective.next != null)
				{
					item.next = objective.next.guid;
				}
				else
				{
					item.next = Guid.Empty;
				}
				item.targetType = TargetType.Invalid;
				item.targetGuid = Guid.Empty;
				if (objective.target is Building)
				{
					item.targetType = TargetType.Building;
					item.targetGuid = (objective.target as Building).guid;
				}
				else if (objective.target is IMoveableUnit)
				{
					item.targetType = TargetType.Unit;
					item.targetGuid = (objective.target as IMoveableUnit).GetGuid();
				}
				else if (objective.target is WolfDen)
				{
					item.targetType = TargetType.WolfDen;
					item.targetGuid = (objective.target as WolfDen).guid;
				}
				else
				{
					Debug.LogError("MISSING TARGET TYPE IN SAVE DATA");
				}
				item.priority = objective.priority;
				item.completed = objective.completed;
				item.exclusive = objective.exclusive;
				item.guid = objective.guid;
				item.time = objective.time;
				objectives.Add(item);
			}
			for (int j = 0; j < d.unitData.Count; j++)
			{
				UnitDataSave item2 = new UnitDataSave
				{
					guid = d.unitData[j].unit.GetGuid()
				};
				if (d.unitData[j].objective != null)
				{
					item2.objectiveGuid = d.unitData[j].objective.guid;
				}
				else
				{
					item2.objectiveGuid = Guid.Empty;
				}
				unitData.Add(item2);
			}
			return this;
		}

		public override AIUnitControlSystem Unpack(AIUnitControlSystem d)
		{
			d.objectives = new List<Objective>();
			for (int i = 0; i < objectives.Count; i++)
			{
				ObjectiveSaveData objectiveSaveData = objectives[i];
				Objective objective = new Objective();
				objective.type = objectiveSaveData.type;
				if (objectiveSaveData.targetType == TargetType.Unit)
				{
					IMoveableUnit moveableUnit = OrdersManager.inst.FindArmyByGuid(objectiveSaveData.targetGuid);
					objective.target = moveableUnit as IMoveTarget;
				}
				else if (objectiveSaveData.targetType == TargetType.Building)
				{
					Building building = Player.inst.GetBuilding(objectiveSaveData.targetGuid);
					objective.target = building;
				}
				else if (objectiveSaveData.targetType == TargetType.WolfDen)
				{
					WolfDen wolfDen = WolfDen.GetWolfDen(objectiveSaveData.targetGuid);
					objective.target = wolfDen;
				}
				objective.priority = objectiveSaveData.priority;
				objective.completed = objectiveSaveData.completed;
				objective.exclusive = objectiveSaveData.exclusive;
				objective.guid = objectiveSaveData.guid;
				objective.time = objectiveSaveData.time;
				if (objectiveSaveData.targetType == TargetType.Invalid)
				{
					Debug.LogError("Invalid target type on load");
				}
				else
				{
					d.objectives.Add(objective);
				}
			}
			for (int j = 0; j < objectives.Count; j++)
			{
				Objective objectiveByGuid = d.GetObjectiveByGuid(objectives[j].guid);
				if (objectives[j].next != Guid.Empty)
				{
					objectiveByGuid.next = d.GetObjectiveByGuid(objectives[j].next);
				}
				if (objectives[j].dependency != Guid.Empty)
				{
					objectiveByGuid.dependency = d.GetObjectiveByGuid(objectives[j].dependency);
				}
			}
			for (int k = 0; k < d.objectives.Count; k++)
			{
				d.objectivesPriorityList[d.objectives[k].priority].Add(d.objectives[k]);
			}
			for (int l = 0; l < this.unitData.Count; l++)
			{
				UnitData unitData = new UnitData();
				IMoveableUnit moveableUnit2 = OrdersManager.inst.FindArmyByGuid(this.unitData[l].guid);
				if (moveableUnit2 != null)
				{
					unitData.unit = moveableUnit2;
					d.unitData.Add(unitData);
				}
				if (this.unitData[l].objectiveGuid != Guid.Empty)
				{
					unitData.SetObjective(d.GetObjectiveByGuid(this.unitData[l].objectiveGuid), d);
				}
			}
			return d;
		}
	}

	[NonSerialized]
	public UnitData lastTracked;

	private int teamId;

	private List<IMoveableUnit> scratchUnload = new List<IMoveableUnit>();

	private List<UnitData> deferredRemoval = new List<UnitData>();

	private ArrayExt<GameObject> markedTargets = new ArrayExt<GameObject>(10);

	private int castleblockHash = "castleblock".GetHashCode();

	private int gateHash = "gate".GetHashCode();

	private ArrayExt<Vector3> scratchTargets = new ArrayExt<Vector3>(100);

	[NonSerialized]
	public List<UnitData> unitData = new List<UnitData>();

	private int frameAccum;

	private int lmUpdateIdx;

	private bool firstUpdate = true;

	[NonSerialized]
	public bool noOpenTransports;

	private int debugTeamId;

	private static List<Vector3> scratchPath = new List<Vector3>();

	private ArrayExt<ArrayExt<Cell>> landings = new ArrayExt<ArrayExt<Cell>>(10);

	private static int rubbleHash = "rubble".GetHashCode();

	private List<Objective> objectives = new List<Objective>();

	private List<Objective>[] objectivesPriorityList = new List<Objective>[3];

	public event notifyObjectiveDelegate OnObjectiveCompleted;

	public event notifyObjectiveDelegate OnObjectiveRemoved;

	public event notifyObjectiveDelegate OnObjectiveUnassigned;

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
		return Player.inst.keep.transform.position;
	}

	public void Init(int tId)
	{
		teamId = tId;
		InitPriorityList();
		OrdersManager.inst.OnUnitDestroyed += OnUnitDestroyed;
		OrdersManager.inst.OnUnitKilled += OnUnitKilled;
		OrdersManager.inst.OnUnitAdded += OnUnitAdded;
		OrdersManager.inst.OnUnitRemoved += OnUnitDestroyed;
		ShipSystem.inst.onShipArrived += Inst_onShipArrived;
	}

	private void Inst_onShipArrived(ShipBase b)
	{
		IMoveableUnit component = b.GetComponent<IMoveableUnit>();
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
			IMoveableUnit carried = unitDataFor.unit.GetCarried(k);
			UnitData unitDataFor2 = GetUnitDataFor(carried);
			bool flag = true;
			if (unitDataFor2.objective != null)
			{
				if (World.inst.GetCellDataClamped(unitDataFor2.objective.GetTarget().GetPos()).landMassIdx != num)
				{
					flag = false;
				}
			}
			else
			{
				AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(teamId);
				if (num != kingdomFromTeamId.Layout.LandMass)
				{
					flag = false;
				}
			}
			if (flag)
			{
				scratchUnload.Add(carried);
			}
		}
		for (int l = 0; l < scratchUnload.Count; l++)
		{
			unitDataFor.unit.DoUnload(scratchUnload[l]);
			unitDataFor.SetObjective(null, this);
		}
	}

	public void Shutdown()
	{
		Reset();
		OrdersManager.inst.OnUnitDestroyed -= OnUnitDestroyed;
		OrdersManager.inst.OnUnitKilled -= OnUnitKilled;
		OrdersManager.inst.OnUnitAdded -= OnUnitAdded;
		OrdersManager.inst.OnUnitRemoved -= OnUnitDestroyed;
		ShipSystem.inst.onShipArrived -= Inst_onShipArrived;
	}

	public UnitData GetUnitDataFor(IMoveableUnit unit)
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
		UnitData unitDataFor = GetUnitDataFor(unit);
		if (unitDataFor.objective != null)
		{
			unitDataFor.objective.Complete();
		}
	}

	internal Objective GetObjective(ObjectiveType t, IMoveTarget moveTarget)
	{
		for (int i = 0; i < objectives.Count; i++)
		{
			if (objectives[i].type == t && objectives[i].target == moveTarget)
			{
				return objectives[i];
			}
		}
		return null;
	}

	private void OnUnitAdded(IMoveableUnit newUnit)
	{
		if (newUnit.TeamID() == teamId)
		{
			unitData.Add(new UnitData
			{
				unit = newUnit
			});
		}
	}

	private void OnUnitDestroyed(IMoveableUnit unit)
	{
		for (int i = 0; i < unitData.Count; i++)
		{
			if (unitData[i].unit == unit)
			{
				if (unitData[i] == lastTracked)
				{
					lastTracked = null;
				}
				unitData[i].SetObjective(null, this);
				unitData.RemoveAt(i);
				break;
			}
		}
	}

	private void OnUnitKilled(IMoveableUnit unit, int attackerTeamID)
	{
	}

	public void Reset()
	{
		lmUpdateIdx = 0;
		landings.Clear();
		lastTracked = null;
		markedTargets.Clear();
		for (int i = 0; i < unitData.Count; i++)
		{
			deferredRemoval.Add(unitData[i]);
		}
		unitData.Clear();
		for (int j = 0; j < deferredRemoval.Count; j++)
		{
			OrdersManager.inst.DestroyUnit(deferredRemoval[j].unit);
		}
		deferredRemoval.Clear();
		objectives.Clear();
		InitPriorityList();
	}

	public void MarkTarget(GameObject v)
	{
		markedTargets.Add(v);
	}

	public bool IsTargetMarked(GameObject v)
	{
		return markedTargets.Contains(v);
	}

	public void RemoveMark(GameObject v)
	{
		markedTargets.RemoveSwap(v);
	}

	private IMoveableUnit GetNearestOpenTransportFor(IMoveableUnit toLoad)
	{
		bool flag = false;
		if (toLoad is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy })
		{
			flag = true;
		}
		Vector3 pos = toLoad.GetPos();
		IMoveableUnit result = null;
		float num = float.MaxValue;
		for (int i = 0; i < unitData.Count; i++)
		{
			IMoveableUnit unit = unitData[i].unit;
			if (!unit.CanCarry() || unit.IsFullCapacity())
			{
				continue;
			}
			bool flag2 = false;
			for (int j = 0; j < unit.CarryCount(); j++)
			{
				if (unit.GetCarried(j) is ArmySystem.Army army2 && ((army2.armyType == ArmySystem.ArmyType.Envoy && !flag) || ((army2.armyType != ArmySystem.ArmyType.Envoy) & flag)))
				{
					flag2 = true;
					break;
				}
			}
			if (!flag2)
			{
				Vector3 pos2 = unit.GetPos();
				float num2 = Mathff.DistSqrdXZ(pos, pos2);
				if (num2 < num)
				{
					num = num2;
					result = unit;
				}
			}
		}
		return result;
	}

	private void ValidateObjective()
	{
		for (int i = 0; i < unitData.Count; i++)
		{
			if (unitData[i].objective != null)
			{
				if (!unitData[i].objective.unitsAssigned.Contains(unitData[i]))
				{
					_ = 0;
				}
				if (!objectives.Contains(unitData[i].objective))
				{
					_ = 0;
				}
			}
		}
	}

	public UnitData GetClosestUnassignedUnit(Objective o)
	{
		UnitData result = null;
		float num = float.MaxValue;
		Vector3 pos = o.GetTarget().GetPos();
		for (int i = 0; i < unitData.Count; i++)
		{
			if (unitData[i].objective == null && unitData[i].CanComplete(o))
			{
				float num2 = Mathff.DistSqrdXZ(unitData[i].unit.GetPos(), pos);
				if (num2 < num)
				{
					num = num2;
					result = unitData[i];
				}
			}
		}
		return result;
	}

	public UnitData GetClosestUnitLowerPriority(Objective o)
	{
		UnitData result = null;
		float num = float.MaxValue;
		Vector3 pos = o.GetTarget().GetPos();
		int priority = o.priority;
		for (int i = 0; i < unitData.Count; i++)
		{
			if ((unitData[i].objective == null || unitData[i].objective.priority < priority) && unitData[i].CanComplete(o))
			{
				float num2 = Mathff.DistSqrdXZ(unitData[i].unit.GetPos(), pos);
				if (num2 < num)
				{
					num = num2;
					result = unitData[i];
				}
			}
		}
		return result;
	}

	public int ActiveObjectives()
	{
		return objectives.Count;
	}

	public void Update()
	{
		if (firstUpdate)
		{
			for (int i = 0; i < World.inst.NumLandMasses; i++)
			{
				UpdateLandings(i);
			}
			firstUpdate = false;
		}
		if (debugTeamId == teamId)
		{
			for (int j = 0; j < World.inst.NumLandMasses; j++)
			{
				ArrayExt<Cell> arrayExt = GetLandings(j);
				for (int k = 0; k < arrayExt.Count; k++)
				{
					DebugEx.DrawSphere(arrayExt.data[k].Center2D, 0.5f, Color.red);
				}
			}
		}
		for (int l = 0; l < markedTargets.Count; l++)
		{
			if (markedTargets.data[l] == null || !markedTargets.data[l].gameObject.activeSelf)
			{
				markedTargets.RemoveAtSwap(l);
				l--;
			}
		}
		float deltaTime = Time.deltaTime;
		for (int m = 0; m < objectives.Count; m++)
		{
			if (objectives[m].time != float.MaxValue)
			{
				objectives[m].time -= deltaTime;
				if (objectives[m].time < 0f)
				{
					OnObjectiveRemoved?.Invoke(objectives[m]);
					RemoveObjective(objectives[m]);
					m = 0;
					continue;
				}
			}
			if (objectives[m].IsComplete())
			{
				OnObjectiveCompleted?.Invoke(objectives[m]);
				Objective next = objectives[m].next;
				if (objectives[m].next != null)
				{
					objectives[m].next.dependency = null;
					objectives[m].next = null;
				}
				if (objectives[m].exclusive && next != null)
				{
					objectives[m].unitsAssigned[0].SetObjective(next, this);
				}
				while (objectives[m].unitsAssigned.Count > 0)
				{
					objectives[m].unitsAssigned[0].SetObjective(null, this);
				}
				objectivesPriorityList[objectives[m].priority].Remove(objectives[m]);
				objectives.RemoveAt(m);
				m--;
			}
		}
		frameAccum++;
		if (frameAccum <= 10)
		{
			return;
		}
		AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(teamId);
		frameAccum = 0;
		noOpenTransports = false;
		UpdateLandings(lmUpdateIdx);
		lmUpdateIdx++;
		if (lmUpdateIdx >= World.inst.NumLandMasses)
		{
			lmUpdateIdx = 0;
		}
		for (int num = objectivesPriorityList.Length - 1; num >= 0; num--)
		{
			List<Objective> list = objectivesPriorityList[num];
			for (int n = 0; n < list.Count; n++)
			{
				if (list[n].dependency == null && list[n].unitsAssigned.Count == 0)
				{
					UnitData unitData = GetClosestUnassignedUnit(list[n]);
					if (unitData == null)
					{
						unitData = GetClosestUnitLowerPriority(list[n]);
					}
					unitData?.SetObjective(list[n], this);
				}
			}
		}
		for (int num2 = 0; num2 < this.unitData.Count; num2++)
		{
			IMoveableUnit unit = this.unitData[num2].unit;
			this.unitData[num2].TryAssignObjective(objectives, this);
			if (unit.IsBeingCarried())
			{
				continue;
			}
			if (unit.CanCarry() && unit.CarryCount() == 0)
			{
				this.unitData[num2].SetObjective(null, this);
			}
			if (this.unitData[num2].objective != null)
			{
				Vector3 pos = this.unitData[num2].objective.GetTarget().GetPos();
				int landMassIdx = World.inst.GetCellDataClamped(pos).landMassIdx;
				if (this.unitData[num2].unit.CanCarry())
				{
					if (landMassIdx == -1)
					{
						continue;
					}
					bool flag = false;
					bool flag2 = false;
					if (!this.unitData[num2].unit.IsFullCapacity())
					{
						for (int num3 = 0; num3 < unit.CarryCount(); num3++)
						{
							if (unit.GetCarried(num3) is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy })
							{
								flag = true;
								break;
							}
						}
						if (!flag)
						{
							for (int num4 = 0; num4 < this.unitData.Count; num4++)
							{
								if (!this.unitData[num4].unit.CanCarry() && !this.unitData[num4].unit.IsBeingCarried() && this.unitData[num4].objective != null)
								{
									int landMassIdx2 = World.inst.GetCellDataClamped(this.unitData[num4].unit.GetPos()).landMassIdx;
									int landMassIdx3 = World.inst.GetCellDataClamped(this.unitData[num4].objective.GetTarget().GetPos()).landMassIdx;
									if (landMassIdx2 == kingdomFromTeamId.Layout.LandMass && landMassIdx3 != landMassIdx2)
									{
										flag2 = true;
									}
								}
							}
						}
					}
					if (!flag2)
					{
						if (this.unitData[num2].objective.type == ObjectiveType.GiveGift || this.unitData[num2].objective.type == ObjectiveType.PickUpGift || this.unitData[num2].objective.type == ObjectiveType.MoveToBuilding)
						{
							OrdersManager.inst.MoveTo(this.unitData[num2].unit, World.inst.GetCellDataClamped(pos));
							continue;
						}
						Cell nearestLanding = GetNearestLanding(landings.data[landMassIdx], pos);
						OrdersManager.inst.MoveTo(this.unitData[num2].unit, nearestLanding);
					}
					continue;
				}
				Vector3 pos2 = unit.GetPos();
				int landMassIdx4 = World.inst.GetCellDataClamped(pos2).landMassIdx;
				if (landMassIdx != landMassIdx4)
				{
					IMoveableUnit nearestOpenTransportFor = GetNearestOpenTransportFor(unit);
					if (nearestOpenTransportFor != null)
					{
						OrdersManager.inst.MoveTo(unit, nearestOpenTransportFor as IMoveTarget);
						continue;
					}
					OrdersManager.inst.MoveTo(unit, World.inst.GetCellDataClamped(unit.GetPos()));
					noOpenTransports = true;
				}
				else
				{
					Debug.DrawLine(unit.GetPos() + new Vector3(0f, 0.5f, 0f), this.unitData[num2].objective.GetTarget().GetPos() + new Vector3(0f, 0.5f, 0f), Color.yellow);
					OrdersManager.inst.MoveTo(unit, this.unitData[num2].objective.GetTarget());
				}
				continue;
			}
			if (this.unitData[num2].unit.CanCarry())
			{
				if (!this.unitData[num2].unit.IsPendingLoadTargets())
				{
					Cell cellDataClamped = World.inst.GetCellDataClamped(kingdomFromTeamId.Layout.KingdomStart);
					Cell cellDataClamped2 = World.inst.GetCellDataClamped(this.unitData[num2].unit.GetPos());
					if (!kingdomFromTeamId.LandmassOwner.OwnsLandMass(cellDataClamped2.landMassIdx))
					{
						OrdersManager.inst.MoveTo(this.unitData[num2].unit, cellDataClamped);
					}
				}
				continue;
			}
			Vector3 pos3 = unit.GetPos();
			if (World.GetLandmassOwner(World.inst.GetCellDataClamped(pos3).landMassIdx) != World.GetLandmassOwnerByTeamId(unit.TeamID()))
			{
				IMoveTarget moveTarget = this.unitData[num2].unit.GetMoveTarget();
				if (!(moveTarget is TroopTransportShip))
				{
					moveTarget = GetNearestOpenTransportFor(this.unitData[num2].unit) as IMoveTarget;
				}
				if (moveTarget != null)
				{
					OrdersManager.inst.MoveTo(this.unitData[num2].unit, moveTarget);
				}
				else
				{
					noOpenTransports = true;
				}
			}
		}
		for (int num5 = 0; num5 < deferredRemoval.Count; num5++)
		{
			OrdersManager.inst.DestroyUnit(deferredRemoval[num5].unit);
		}
		deferredRemoval.Clear();
	}

	public void OnNewYear()
	{
	}

	public ArrayExt<Cell> GetLandings(int landmass)
	{
		return landings.data[landmass];
	}

	public void UpdateLandings(int lm)
	{
		while (landings.Count < World.inst.NumLandMasses)
		{
			landings.Add(new ArrayExt<Cell>(25));
		}
		GetLandings(lm, teamId, landings.data[lm]);
	}

	public static void GetLandings(int targetLandmass, int teamId, ArrayExt<Cell> validLandings, int minVillagers = 50)
	{
		validLandings.ClearFast();
		if (Player.inst.keep == null)
		{
			return;
		}
		Cell[] array = new Cell[4];
		ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[targetLandmass];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			Cell cell = arrayExt.data[i];
			if (!cell.buildingAccess || cell.Type == TerrainType.Obstruction || cell.deepWater)
			{
				continue;
			}
			bool flag = false;
			World.inst.GetNeighborCells(cell, ref array);
			foreach (Cell cell2 in array)
			{
				if (cell2 != null && cell2.partOfOcean && !PathCell.GetBlocksWaterPath(World.inst.GetPathCell(cell2), teamId))
				{
					flag = true;
					break;
				}
			}
			if (flag)
			{
				validLandings.Add(cell);
			}
		}
	}

	public Cell GetNearestLanding(ArrayExt<Cell> landings, Vector3 pos)
	{
		Cell result = null;
		float num = float.MaxValue;
		for (int i = 0; i < landings.Count; i++)
		{
			float num2 = Mathff.DistSqrdXZ(landings.data[i].Center2D, pos);
			if (landings.data[i].OccupyingStructure.Count > 0)
			{
				num2 += 10000f;
			}
			num2 += (float)(landings.data[i].Danger * 10000);
			if (num2 < num)
			{
				num = num2;
				result = landings.data[i];
			}
		}
		return result;
	}

	public void AddObjective(Objective o)
	{
		objectives.Add(o);
		objectivesPriorityList[o.priority].Add(o);
	}

	public void AddObjectiveAsDependency(Objective child, Objective parent)
	{
		AddObjective(child);
		child.dependency = parent;
		parent.next = child;
	}

	public void RemoveObjective(Objective o)
	{
		Objective objective = o;
		while (objective != null)
		{
			objectives.Remove(objective);
			objectivesPriorityList[objective.priority].Remove(objective);
			while (objective.unitsAssigned.Count > 0)
			{
				objective.unitsAssigned[0].SetObjective(null, this);
			}
			Objective objective2 = objective;
			objective = objective.next;
			objective2.next = null;
			objective2.dependency = null;
		}
	}

	private void InitPriorityList()
	{
		for (int i = 0; i < objectivesPriorityList.Length; i++)
		{
			objectivesPriorityList[i] = new List<Objective>();
		}
	}

	public Objective GetObjectiveByGuid(Guid guid)
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
}
