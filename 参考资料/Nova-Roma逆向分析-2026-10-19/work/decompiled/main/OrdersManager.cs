using System;
using System.Collections.Generic;
using UnityEngine;

public class OrdersManager : MonoBehaviour
{
	private class MoveOrder
	{
		public IMoveableUnit unit;

		public IMoveTarget target;
	}

	public delegate bool ClosestEnemyFilter(IMoveableUnit unit);

	public delegate void notifyDelegate(IMoveableUnit u);

	public delegate void moveToNotifyDelegate(IMoveableUnit mover, IMoveTarget target);

	public delegate void notifyKilledDelegate(IMoveableUnit u, int killerTeamID);

	private struct MoveOrderReissue
	{
		public IMoveableUnit unit;

		public Cell target;
	}

	[Serializable]
	public class OrdersManagerSaveData : SaveClass<OrdersManager, OrdersManagerSaveData>
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

		public override OrdersManagerSaveData Pack(OrdersManager obj)
		{
			for (int i = 0; i < obj.moveOrders.Count; i++)
			{
				MoveOrderData moveOrderData = new MoveOrderData();
				moveOrderData.unitGuid = obj.moveOrders[i].unit.GetGuid();
				if (obj.moveOrders[i].target is IMoveableUnit)
				{
					moveOrderData.guidTarget = (obj.moveOrders[i].target as IMoveableUnit).GetGuid();
				}
				if (obj.moveOrders[i].target is Building)
				{
					moveOrderData.guidTarget = (obj.moveOrders[i].target as Building).guid;
				}
				if (obj.moveOrders[i].target is Cell)
				{
					moveOrderData.cellTargetX = (obj.moveOrders[i].target as Cell).x;
					moveOrderData.cellTargetZ = (obj.moveOrders[i].target as Cell).z;
				}
				moveOrders.Add(moveOrderData);
			}
			return this;
		}

		public override OrdersManager Unpack(OrdersManager obj)
		{
			for (int i = 0; i < moveOrders.Count; i++)
			{
				IMoveTarget moveTarget = null;
				IMoveableUnit moveableUnit = obj.FindArmyByGuid(moveOrders[i].unitGuid);
				if (moveableUnit == null)
				{
					continue;
				}
				if (moveOrders[i].guidTarget == Guid.Empty)
				{
					moveTarget = World.inst.GetCellData(moveOrders[i].cellTargetX, moveOrders[i].cellTargetZ);
				}
				else
				{
					moveTarget = obj.FindArmyByGuid(moveOrders[i].guidTarget) as IMoveTarget;
					if (moveTarget == null)
					{
						moveTarget = Player.inst.GetBuilding(moveOrders[i].guidTarget);
					}
				}
				if (moveTarget != null)
				{
					obj.MoveTo(moveableUnit, moveTarget);
				}
			}
			return obj;
		}
	}

	public static OrdersManager inst;

	private ArrayExt<IMoveableUnit>[] unitDestGrid;

	private ArrayExt<IMoveableUnit>[] unitPosGrid;

	private ArrayExt<int> clearDestIdx = new ArrayExt<int>(100);

	private ArrayExt<int> clearPosIdx = new ArrayExt<int>(100);

	[NonSerialized]
	public List<IMoveableUnit> units = new List<IMoveableUnit>();

	internal ArrayExt<IMoveableUnit>[] unitsByTeamID = new ArrayExt<IMoveableUnit>[5];

	internal ArrayExt<IMoveableUnit>[] envoysByTeamID = new ArrayExt<IMoveableUnit>[5];

	private float[] minDist = new float[3];

	private IMoveableUnit[] closestUnit = new IMoveableUnit[3];

	private List<MoveOrder> moveOrders = new List<MoveOrder>();

	private bool[] scratchVisited;

	private int gridWidth;

	private int gridHeight;

	private List<PathCell> potentialCells = new List<PathCell>();

	private ArrayExt<PathCell> openSet = new ArrayExt<PathCell>(50);

	private List<IMoveableUnit> unitTracker = new List<IMoveableUnit>();

	public event notifyDelegate OnUnitDestroyed;

	public event moveToNotifyDelegate OnUnitMoveTo;

	public event notifyKilledDelegate OnUnitKilled;

	public event notifyDelegate OnUnitAdded;

	public event notifyDelegate OnUnitRemoved;

	public void Reset()
	{
	}

	public int TroopsOnLandmass(int teamId, int lmIdx)
	{
		Debug.LogError("DEPRECATED");
		int num = 0;
		ArrayExt<IMoveableUnit> arrayExt = unitsByTeamID[teamId];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			IMoveableUnit moveableUnit = arrayExt.data[i];
			if (moveableUnit.CanCarry())
			{
				bool flag = false;
				for (int j = 0; j < moveableUnit.CarryCount(); j++)
				{
					if (moveableUnit.GetCarried(j) is ArmySystem.Army { armyType: not ArmySystem.ArmyType.Envoy })
					{
						flag = true;
					}
				}
				if (!flag)
				{
					continue;
				}
			}
			if (!(moveableUnit is SeedShip))
			{
				int landMassIdx = World.inst.GetCellDataClamped(moveableUnit.GetPos()).landMassIdx;
				if (lmIdx == landMassIdx)
				{
					num++;
				}
			}
		}
		return num;
	}

	public void InitListeners()
	{
	}

	private void Start()
	{
		inst = this;
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (!obj.added)
		{
			RemoveMoveOrderForTarget(obj.targetBuilding);
		}
	}

	private void RemoveMoveOrderForTarget(IMoveTarget target)
	{
		Debug.LogError("DEPRECATED");
		List<MoveOrderReissue> list = new List<MoveOrderReissue>();
		for (int i = 0; i < moveOrders.Count; i++)
		{
			if (moveOrders[i].target != target)
			{
				continue;
			}
			if (target is Building)
			{
				if (moveOrders[i].unit.GetAttackType() == AttackType.Melee)
				{
					list.Add(new MoveOrderReissue
					{
						unit = moveOrders[i].unit,
						target = World.inst.GetCellDataClamped(target.GetPos())
					});
				}
				else if (moveOrders[i].unit.GetAttackType() == AttackType.Ranged)
				{
					list.Add(new MoveOrderReissue
					{
						unit = moveOrders[i].unit,
						target = World.inst.GetCellDataClamped(moveOrders[i].unit.GetPos())
					});
				}
			}
			moveOrders.RemoveAt(i);
			i--;
		}
		for (int j = 0; j < list.Count; j++)
		{
			inst.MoveTo(list[j].unit, list[j].target);
		}
	}

	private void Update()
	{
	}

	private void UpdateDestGridFor(IMoveableUnit u, int x, int z)
	{
		int i = 0;
		for (int count = clearDestIdx.Count; i < count; i++)
		{
			unitDestGrid[clearDestIdx.data[i]].RemoveSwap(u);
		}
		int num = z * gridWidth + x;
		if (num >= 0 && num < unitDestGrid.Length)
		{
			unitDestGrid[num].Clear();
			unitDestGrid[num].Add(u);
			clearDestIdx.Add(num);
		}
	}

	public IMoveableUnit FindUnitAt(int x, int z, MoveType moveType)
	{
		Debug.LogError("DEPRECATED");
		IMoveableUnit result = null;
		ArrayExt<IMoveableUnit> arrayExt = unitPosGrid[z * World.inst.GridWidth + x];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			if (!arrayExt.data[i].IsBeingCarried() && arrayExt.data[i].GetMoveType() == moveType)
			{
				result = arrayExt.data[i];
				break;
			}
		}
		return result;
	}

	public IMoveableUnit FindUnitAt(int x, int z)
	{
		Debug.LogError("DEPRECATED");
		IMoveableUnit result = null;
		ArrayExt<IMoveableUnit> arrayExt = unitPosGrid[z * World.inst.GridWidth + x];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			if (!arrayExt.data[i].IsBeingCarried())
			{
				result = arrayExt.data[i];
				break;
			}
		}
		return result;
	}

	public static bool OnlyShipsEnemyFilter(IMoveableUnit unit)
	{
		if (unit as ShipBase != null)
		{
			if (unit.CarryCount() > 0)
			{
				bool result = false;
				for (int i = 0; i < unit.CarryCount(); i++)
				{
					if (unit.GetCarried(i) is ArmySystem.Army { armyType: not ArmySystem.ArmyType.Envoy })
					{
						result = true;
					}
				}
				return result;
			}
			return true;
		}
		return false;
	}

	public IMoveableUnit ClosestEnemyUnit(Vector3 pos, float radius, int teamId, ClosestEnemyFilter enemyFilter = null)
	{
		Debug.LogError("DEPRECATED");
		float num = float.MaxValue;
		IMoveableUnit result = null;
		float num2 = radius * radius;
		for (int i = 0; i < unitsByTeamID.Length; i++)
		{
			if (World.inst.RelationBetween(teamId, i) != World.Relations.Enemy)
			{
				continue;
			}
			IMoveableUnit[] data = unitsByTeamID[i].data;
			int j = 0;
			for (int count = unitsByTeamID[i].Count; j < count; j++)
			{
				IMoveableUnit moveableUnit = data[j];
				if (moveableUnit.CarryCount() > 0)
				{
					bool flag = false;
					for (int k = 0; k < moveableUnit.CarryCount(); k++)
					{
						if (moveableUnit.GetCarried(k) is ArmySystem.Army { armyType: not ArmySystem.ArmyType.Envoy })
						{
							flag = true;
						}
					}
					if (!flag)
					{
						continue;
					}
				}
				if (!moveableUnit.IsBeingCarried() && (enemyFilter == null || enemyFilter(moveableUnit)))
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

	public IMoveableUnit ClosestEnemyUnitRanked(Vector3 pos, float radiusMin, float radiusMax, int teamId)
	{
		Debug.LogError("DEPRECATED");
		for (int i = 0; i < closestUnit.Length; i++)
		{
			closestUnit[i] = null;
		}
		for (int j = 0; j < minDist.Length; j++)
		{
			minDist[j] = float.MaxValue;
		}
		float num = radiusMax * radiusMax;
		float num2 = radiusMin * radiusMin;
		for (int k = 0; k < unitsByTeamID.Length; k++)
		{
			if (World.inst.RelationBetween(teamId, k) != World.Relations.Enemy)
			{
				continue;
			}
			IMoveableUnit[] data = unitsByTeamID[k].data;
			int l = 0;
			for (int count = unitsByTeamID[k].Count; l < count; l++)
			{
				IMoveableUnit moveableUnit = data[l];
				if (moveableUnit.IsBeingCarried() || moveableUnit is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy })
				{
					continue;
				}
				if (moveableUnit.CanCarry())
				{
					bool flag = true;
					for (int m = 0; m < moveableUnit.CarryCount(); m++)
					{
						if (!(moveableUnit.GetCarried(m) is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy }))
						{
							flag = false;
							break;
						}
					}
					if (flag)
					{
						continue;
					}
				}
				float num3 = Mathff.DistSqrdXZ(data[l].GetPos(), pos);
				int unitType = (int)data[l].GetUnitType();
				if (num3 >= num2 && num3 < num && num3 < minDist[unitType])
				{
					closestUnit[unitType] = data[l];
					minDist[unitType] = num3;
				}
			}
		}
		if (closestUnit[0] != null)
		{
			return closestUnit[0];
		}
		if (closestUnit[1] != null)
		{
			return closestUnit[1];
		}
		if (closestUnit[2] != null)
		{
			return closestUnit[2];
		}
		return null;
	}

	public IMoveableUnit FindUnitDestinedFor(int x, int z, IMoveableUnit owner)
	{
		Debug.LogError("DEPRECATED");
		IMoveableUnit result = null;
		ArrayExt<IMoveableUnit> arrayExt = unitDestGrid[z * World.inst.GridWidth + x];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			if (arrayExt.data[i].GetMoveType() == owner.GetMoveType() && arrayExt.data[i] != owner)
			{
				result = arrayExt.data[i];
			}
		}
		return result;
	}

	private MoveOrder RemoveMoveOrder(IMoveableUnit u)
	{
		for (int i = 0; i < moveOrders.Count; i++)
		{
			if (moveOrders[i].unit == u)
			{
				MoveOrder result = moveOrders[i];
				moveOrders.RemoveAt(i);
				return result;
			}
		}
		return null;
	}

	public void MoveTo(IMoveableUnit moveableUnit, IMoveTarget moveTarget)
	{
		Debug.LogError("DEPRECATED");
		MoveOrder moveOrder = RemoveMoveOrder(moveableUnit);
		if (moveOrder != null && moveOrder.target is IMoveableUnit moveableUnit2)
		{
			moveableUnit2.OnUnitStoppedTargetingUs(moveableUnit);
		}
		moveableUnit.MoveTo(moveTarget);
		OnUnitMoveTo?.Invoke(moveableUnit, moveTarget);
		if (moveTarget is IMoveableUnit)
		{
			(moveTarget as IMoveableUnit).OnUnitTargetsUs(moveableUnit);
		}
		moveOrders.Add(new MoveOrder
		{
			unit = moveableUnit,
			target = moveTarget
		});
	}

	public void DestroyUnit(IMoveableUnit unit)
	{
		Debug.LogError("DEPRECATED");
		NotifyUnitDeath(unit);
		OnUnitDestroyed(unit);
		unit.DestroyUnit();
		RemoveUnit(unit);
	}

	private void NotifyUnitDeath(IMoveableUnit unit)
	{
		Debug.LogError("DEPRECATED");
		for (int i = 0; i < units.Count; i++)
		{
			if (units[i] != unit)
			{
				units[i].NotifyOtherUnitDeath(unit);
			}
		}
		if (unit is IMoveTarget)
		{
			RemoveMoveOrderForTarget(unit as IMoveTarget);
		}
	}

	public void UnitKilled(IMoveableUnit unit, int killerTeamId)
	{
		Debug.LogError("DEPRECATED");
		NotifyUnitDeath(unit);
		OnUnitKilled(unit, killerTeamId);
	}

	public void Init(int w, int h)
	{
	}

	public Vector3 GetUnoccupiedDestination(Vector3 pos, IMoveableUnit owner, Pathfinder.blocksPathTest blockFunc, int teamId, bool ignoreWallConnectivity = false)
	{
		Debug.LogError("DEPRECATED");
		potentialCells.Clear();
		unitTracker.Clear();
		PathCell pathCellClamped = World.inst.GetPathCellClamped(pos);
		MoveType moveType = owner.GetMoveType();
		openSet.Clear();
		openSet.Add(pathCellClamped);
		Array.Clear(scratchVisited, 0, scratchVisited.Length);
		while (openSet.Count > 0)
		{
			PathCell pathCell = openSet.data[0];
			openSet.RemoveAt(0);
			int num = pathCell.z * gridWidth + pathCell.x;
			if (!scratchVisited[num])
			{
				bool flag = false;
				IMoveableUnit moveableUnit = FindUnitDestinedFor(pathCell.x, pathCell.z, owner);
				if (moveableUnit != null)
				{
					float num2 = Mathff.DistSqrdXZ(owner.GetPos(), pathCell.Center);
					float num3 = Mathff.DistSqrdXZ(moveableUnit.GetPos(), pathCell.Center);
					flag = !(num2 < num3);
				}
				else
				{
					IMoveableUnit moveableUnit2 = FindUnitAt(pathCell.x, pathCell.z, moveType);
					if (moveableUnit2 != null && moveableUnit2 != owner && !moveableUnit2.IsBeingCarried())
					{
						moveableUnit = moveableUnit2;
						flag = true;
					}
				}
				if (flag || blockFunc(pathCell, teamId))
				{
					AddForUnoccupiedFlood(pathCell, pathCell.x, pathCell.z + 1, ignoreWallConnectivity);
					AddForUnoccupiedFlood(pathCell, pathCell.x, pathCell.z - 1, ignoreWallConnectivity);
					AddForUnoccupiedFlood(pathCell, pathCell.x + 1, pathCell.z, ignoreWallConnectivity);
					AddForUnoccupiedFlood(pathCell, pathCell.x - 1, pathCell.z, ignoreWallConnectivity);
				}
				else
				{
					unitTracker.Add(moveableUnit);
					potentialCells.Add(pathCell);
					if (potentialCells.Count > 4)
					{
						break;
					}
				}
			}
			scratchVisited[num] = true;
		}
		Vector3 pos2 = owner.GetPos();
		PathCell pathCell2 = null;
		float num4 = float.MaxValue;
		IMoveableUnit moveableUnit3 = null;
		float num5 = 2.0163999f;
		while (pathCell2 == null && potentialCells.Count > 0)
		{
			for (int i = 0; i < potentialCells.Count; i++)
			{
				if (Mathff.DistSqrdXZ(pos, potentialCells[i].Center) < num5)
				{
					float num6 = Mathff.DistSqrdXZ(pos2, potentialCells[i].Center);
					if (num6 < num4)
					{
						num4 = num6;
						pathCell2 = potentialCells[i];
						moveableUnit3 = unitTracker[i];
					}
				}
			}
			num5 += 2.0163999f;
		}
		if (pathCell2 != null)
		{
			UpdateDestGridFor(owner, pathCell2.x, pathCell2.z);
			if (moveableUnit3 != null)
			{
				IMoveTarget moveTarget = moveableUnit3.GetMoveTarget();
				IProjectileHitable projectileHitable = moveTarget as IProjectileHitable;
				if (moveTarget != null && !moveTarget.Equals(null) && (projectileHitable == null || (projectileHitable != null && !projectileHitable.IsInvalid())) && !moveableUnit3.IsBeingCarried())
				{
					moveableUnit3.MoveTo(moveTarget);
				}
			}
			return World.GetCellHeightPos(World.inst.GetCellData(pathCell2));
		}
		return pos;
	}

	private void AddForUnoccupiedFlood(PathCell currCell, int x, int z, bool ignoreWallConnectivity)
	{
		PathCell pathCell = World.inst.GetPathCell(x, z);
		if (pathCell != null && ((currCell.isUpperGridBlocked == pathCell.isUpperGridBlocked || pathCell.isStairs || currCell.isStairs) | ignoreWallConnectivity))
		{
			openSet.Add(pathCell);
		}
	}

	public void AddUnit(IMoveableUnit moveableUnit)
	{
		Debug.LogError("DEPRECATED");
		units.Add(moveableUnit);
		bool flag = false;
		if (moveableUnit is ArmySystem.Army && (moveableUnit as ArmySystem.Army).armyType == ArmySystem.ArmyType.Envoy)
		{
			flag = true;
		}
		if (!flag)
		{
			unitsByTeamID[moveableUnit.TeamID()].Add(moveableUnit);
		}
		else
		{
			envoysByTeamID[moveableUnit.TeamID()].Add(moveableUnit);
		}
		OnUnitAdded?.Invoke(moveableUnit);
	}

	public void RemoveUnit(IMoveableUnit moveableUnit)
	{
		Debug.LogError("DEPRECATED");
		units.Remove(moveableUnit);
		unitsByTeamID[moveableUnit.TeamID()].RemoveSwap(moveableUnit);
		envoysByTeamID[moveableUnit.TeamID()].RemoveSwap(moveableUnit);
		RemoveMoveOrder(moveableUnit);
		OnUnitRemoved?.Invoke(moveableUnit);
	}

	public IMoveableUnit FindArmyByGuid(Guid guid)
	{
		Debug.LogError("DEPRECATED");
		for (int i = 0; i < units.Count; i++)
		{
			if (units[i].GetGuid() == guid)
			{
				return units[i];
			}
		}
		return null;
	}
}
