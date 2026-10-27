using System;
using System.Collections.Generic;
using UnityEngine;

public class UnitSystem : MonoBehaviour
{
	[Serializable]
	public struct UnitData
	{
		public int id;

		public string name;

		public Sprite icon;
	}

	public delegate void MoveToNotify(IUnitControllable unit, IMoveTarget target);

	public delegate void DestroyNotify(IUnitControllable unit);

	public delegate void KillNotify(IUnitControllable unit, int killerTeamID);

	private class MoveOrder
	{
		public IUnitControllable unit;

		public IMoveTarget target;
	}

	public delegate bool ClosestEnemyFilter(IUnitControllable unit);

	[Serializable]
	public class UnitSystemSaveData : SaveClass<UnitSystem, UnitSystemSaveData>
	{
		[Serializable]
		private class MoveOrderData
		{
			public Guid unitGuid;

			public Guid guidTarget;

			public int cellTargetX = -1;

			public int cellTargetZ = -1;
		}

		private List<MoveOrderData> moveOrders = new List<MoveOrderData>();

		public override UnitSystemSaveData Pack(UnitSystem obj)
		{
			for (int i = 0; i < obj.moveOrders.Count; i++)
			{
				MoveOrderData moveOrderData = new MoveOrderData();
				moveOrderData.unitGuid = obj.moveOrders.data[i].unit.GetGuid();
				if (obj.moveOrders.data[i].target is IMoveableUnit)
				{
					moveOrderData.guidTarget = (obj.moveOrders.data[i].target as IMoveableUnit).GetGuid();
				}
				if (obj.moveOrders.data[i].target is Building)
				{
					moveOrderData.guidTarget = (obj.moveOrders.data[i].target as Building).guid;
				}
				if (obj.moveOrders.data[i].target is Cell)
				{
					moveOrderData.cellTargetX = (obj.moveOrders.data[i].target as Cell).x;
					moveOrderData.cellTargetZ = (obj.moveOrders.data[i].target as Cell).z;
				}
				moveOrders.Add(moveOrderData);
			}
			return this;
		}

		public override UnitSystem Unpack(UnitSystem obj)
		{
			if (moveOrders != null)
			{
				for (int i = 0; i < moveOrders.Count; i++)
				{
					IMoveTarget moveTarget = null;
					IUnitControllable unitControllable = obj.FindUnitByGuid(moveOrders[i].unitGuid);
					if (unitControllable == null)
					{
						continue;
					}
					if (moveOrders[i].guidTarget == Guid.Empty)
					{
						moveTarget = World.inst.GetCellData(moveOrders[i].cellTargetX, moveOrders[i].cellTargetZ);
					}
					else
					{
						moveTarget = obj.FindUnitByGuid(moveOrders[i].guidTarget) as IMoveTarget;
						if (moveTarget == null)
						{
							moveTarget = Player.inst.GetBuilding(moveOrders[i].guidTarget);
						}
					}
					if (moveTarget != null)
					{
						obj.MoveTo(unitControllable, moveTarget);
					}
				}
			}
			return obj;
		}
	}

	public static UnitSystem inst;

	public List<UnitData> unitData = new List<UnitData>(32);

	public Dictionary<int, UnitData> unitDataMap = new Dictionary<int, UnitData>(32);

	public MoveToNotify OnUnitMoveTo;

	private ArrayExt<MoveOrder> moveOrders = new ArrayExt<MoveOrder>(128);

	public ArrayExt<LegionUnit> legionUnits = new ArrayExt<LegionUnit>(256);

	public ArrayExt<IUnitControllable>[] unitsByTeamID = new ArrayExt<IUnitControllable>[6];

	private ArrayExt<IUnitControllable> units = new ArrayExt<IUnitControllable>(128);

	public Torch torchPrefab;

	private List<LegionUnit> toDestroy = new List<LegionUnit>();

	private int frameCount;

	public event DestroyNotify OnUnitRemoved;

	public event KillNotify OnUnitKilled;

	public LegionUnit GetLegionUnitByGroupID(int id)
	{
		for (int i = 0; i < legionUnits.Count; i++)
		{
			if (legionUnits.data[i].GetGroupID() == id)
			{
				return legionUnits.data[i];
			}
		}
		return null;
	}

	public LegionUnit GetLegionUnitByGuid(Guid guid)
	{
		for (int i = 0; i < legionUnits.Count; i++)
		{
			if (legionUnits.data[i].GetGuid() == guid)
			{
				return legionUnits.data[i];
			}
		}
		return null;
	}

	public UnitData GetUnitDataByType(int type)
	{
		for (int i = 0; i < inst.unitData.Count; i++)
		{
			UnitData result = inst.unitData[i];
			if (result.id == type)
			{
				return result;
			}
		}
		return default;
	}

	public void TryAddUnit(int id, out LegionUnit unit)
	{
		unit = new LegionUnit(id);
		legionUnits.Add(unit);
		unitsByTeamID[unit.TeamID()].Add(unit);
		TryAddUnit(unit);
	}

	public void GetUnitTypeInView(Plane[] planes, int type, int teamID, ref ArrayExt<IUnitControllable> units)
	{
		for (int i = 0; i < legionUnits.Count; i++)
		{
			LegionUnit legionUnit = legionUnits.data[i];
			LegionGroup legionGroup = legionUnit.GetGroup();
			if (legionUnit.ValidToSelect() && legionGroup.inUse != 0 && legionGroup.type == type && UnitControlSystem.inst.IsUnitControllableByTeam(legionUnit, teamID) && legionUnit.TestPlanesAABB(planes) && !units.Contains(legionUnit))
			{
				units.Add(legionUnit);
			}
		}
	}

	public void AddHighlights(int minx, int minz, int maxx, int maxz, ref List<ISelectable> highlightedObjs)
	{
		int i = 0;
		for (int count = legionUnits.Count; i < count; i++)
		{
			LegionUnit legionUnit = legionUnits.data[i];
			if (legionUnit.ValidToSelect() && legionUnit.InsideSelectionBounds(minx, minz, maxx, maxz) && !highlightedObjs.Contains(legionUnit))
			{
				highlightedObjs.Add(legionUnit);
			}
		}
	}

	public IUnitControllable FindUnitByGuid(Guid guid)
	{
		for (int i = 0; i < units.Count; i++)
		{
			if (units.data[i].GetGuid() == guid)
			{
				return units.data[i];
			}
		}
		return null;
	}

	public bool GetHighlight(out float minDist, out ISelectable selectable)
	{
		bool result = false;
		minDist = float.MaxValue;
		ISelectable selectable2 = null;
		Ray ray = PointingSystem.GetRay();
		for (int i = 0; i < legionUnits.Count; i++)
		{
			LegionUnit legionUnit = legionUnits.data[i];
			if (legionUnit.ValidToSelect())
			{
				float hitDist = float.MaxValue;
				if (legionUnit.IntersectsRay(ray, out hitDist) && hitDist < minDist)
				{
					minDist = hitDist;
					selectable2 = legionUnit;
					result = true;
				}
			}
		}
		selectable = selectable2;
		return result;
	}

	private void Awake()
	{
		inst = this;
		for (int i = 0; i < unitData.Count; i++)
		{
			unitDataMap.TryAdd(unitData[i].id, unitData[i]);
		}
		for (int j = 0; j < unitsByTeamID.Length; j++)
		{
			unitsByTeamID[j] = new ArrayExt<IUnitControllable>(10);
		}
	}

	private unsafe void Update()
	{
		float deltaTime = Time.deltaTime;
		frameCount++;
		for (int i = 0; i < legionUnits.Count; i++)
		{
			legionUnits.data[i].Tick(deltaTime, frameCount);
			LegionGroup legionGroup = LegionSystem.Inst.groups[legionUnits.data[i].GetGroupID()];
			if (!(legionGroup.deadTime >= 2f))
			{
				continue;
			}
			if (legionGroup.team == 0)
			{
				for (int j = 0; j < legionGroup.numCells; j++)
				{
					LegionCell legionCell = LegionSystem.Inst.legionCells[legionGroup.cells[j]];
					for (int k = 0; k < LegionSystem.Inst.soldierCount; k++)
					{
						int index = legionCell.id * LegionSystem.Inst.soldierCount + k;
						Vector3 vector = LegionSystem.Inst.soldierPositions[index];
						new DeadVillager(_rot: LegionSystem.Inst.soldierRotations[index], _pos: vector + new Vector3(0f, -0.05f, 0f), _useLadyMesh: false).CopyDataFromUnit();
					}
				}
			}
			toDestroy.Add(legionUnits.data[i]);
		}
		for (int l = 0; l < toDestroy.Count; l++)
		{
			MoveTo(toDestroy[l], null);
			NotifyUnitKilled(toDestroy[l], toDestroy[l].GetGroup().killerID);
			DestroyUnit(toDestroy[l]);
		}
		toDestroy.Clear();
	}

	public bool TryAddUnit(IUnitControllable unit)
	{
		if (units.Contains(unit))
		{
			return false;
		}
		units.Add(unit);
		return true;
	}

	public void RemoveUnit(IUnitControllable unit)
	{
		units.RemoveSwap(unit);
		OnUnitRemoved?.Invoke(unit);
	}

	private MoveOrder RemoveMoveOrder(int at)
	{
		if (at != -1)
		{
			MoveOrder result = moveOrders.data[at];
			moveOrders.RemoveAt(at);
			return result;
		}
		return null;
	}

	private int IndexOfMoveOrder(IUnitControllable u)
	{
		for (int i = 0; i < moveOrders.Count; i++)
		{
			if (moveOrders.data[i].unit == u)
			{
				return i;
			}
		}
		return -1;
	}

	public void MoveTo(IUnitControllable unit, IMoveTarget moveTarget)
	{
		int num = IndexOfMoveOrder(unit);
		if (num == -1 || (moveTarget != null && !moveTarget.Equals(null) && !moveTarget.IsStationary()) || moveOrders.data[num].target != moveTarget)
		{
			if (TryRemoveMoveOrder(unit, out var order) && order.target is IUnitControllable unitControllable)
			{
				unitControllable.OnUnitStoppedTargetingUs(unit);
			}
			unit.MoveTo(moveTarget);
			OnUnitMoveTo?.Invoke(unit, moveTarget);
			if (moveTarget is IUnitControllable unitControllable2)
			{
				unitControllable2.OnUnitTargetsUs(unit);
			}
			moveOrders.Add(new MoveOrder
			{
				unit = unit,
				target = moveTarget
			});
		}
	}

	private bool TryRemoveMoveOrder(IUnitControllable u, out MoveOrder order)
	{
		order = null;
		for (int i = 0; i < moveOrders.Count; i++)
		{
			MoveOrder moveOrder = moveOrders.data[i];
			if (object.Equals(moveOrder.unit, u))
			{
				order = moveOrder;
				moveOrders.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	public void Reset()
	{
		moveOrders.Clear();
		for (int i = 0; i < legionUnits.Count; i++)
		{
			toDestroy.Add(legionUnits.data[i]);
		}
		for (int j = 0; j < toDestroy.Count; j++)
		{
			DestroyUnit(toDestroy[j]);
		}
		toDestroy.Clear();
		for (int k = 0; k < unitsByTeamID.Length; k++)
		{
			unitsByTeamID[k].Clear();
		}
		units.Clear();
	}

	public void DestroyUnit(IUnitControllable unit)
	{
		TryRemoveMoveOrder(unit, out var _);
		UnitControlSystem.inst.TryRemoveFromSelection(unit);
		if (unit is LegionUnit item)
		{
			legionUnits.RemoveSwap(item);
		}
		unitsByTeamID[unit.TeamID()].RemoveSwap(unit);
		RemoveUnit(unit);
		unit.DestroyUnit();
	}

	public void NotifyUnitKilled(IUnitControllable unit, int killerTeamID)
	{
		OnUnitKilled?.Invoke(unit, killerTeamID);
		for (int i = 0; i < units.Count; i++)
		{
			if (units.data[i] != unit)
			{
				units.data[i].NotifyOtherUnitDeath(unit);
			}
		}
	}

	public IUnitControllable ClosestEnemyUnit(Vector3 pos, float radius, int teamId, ClosestEnemyFilter enemyFilter = null)
	{
		float num = float.MaxValue;
		IUnitControllable result = null;
		float num2 = radius * radius;
		for (int i = 0; i < unitsByTeamID.Length; i++)
		{
			if (World.inst.RelationBetween(teamId, i) != World.Relations.Enemy)
			{
				continue;
			}
			IUnitControllable[] data = unitsByTeamID[i].data;
			int j = 0;
			for (int count = unitsByTeamID[i].Count; j < count; j++)
			{
				IUnitControllable unitControllable = data[j];
				if (unitControllable.CarryCount() > 0)
				{
					bool flag = false;
					for (int k = 0; k < unitControllable.CarryCount(); k++)
					{
						if (unitControllable.GetCarried(k) is ArmySystem.Army { armyType: not ArmySystem.ArmyType.Envoy })
						{
							flag = true;
						}
					}
					if (!flag)
					{
						continue;
					}
				}
				if (!unitControllable.IsBeingCarried() && (enemyFilter == null || enemyFilter(unitControllable)))
				{
					float num3 = Mathff.DistSqrdXZ(data[j].GetPos(), pos);
					if (num3 < num2 && num3 < num)
					{
						result = data[j];
						num = num3;
					}
				}
			}
		}
		return result;
	}
}
