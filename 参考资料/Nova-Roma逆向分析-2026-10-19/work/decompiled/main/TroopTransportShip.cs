using System;
using System.Collections.Generic;
using UnityEngine;

public class TroopTransportShip : ShipBase, ISelectable, IMoveableUnit, IMoveTarget
{
	[Serializable]
	public new class ShipData
	{
		public List<Guid> loadTarget = new List<Guid>();
	}

	public struct MoveToAvg : IMoveTarget
	{
		public IMoveTarget m1;

		public IMoveTarget m2;

		public Vector3 GetPos()
		{
			return Vector3.Lerp(m1.GetPos(), m2.GetPos(), 0.5f);
		}

		public Vector3 GetPredictedPosition(float time)
		{
			return GetPos();
		}

		public int TeamID()
		{
			return m1.TeamID();
		}

		bool IMoveTarget.IsStationary()
		{
			return false;
		}

		public override bool Equals(object obj)
		{
			if (obj == null && (m1 == null || m1.Equals(null) || m2 == null || m2.Equals(null)))
			{
				return true;
			}
			return base.Equals(obj);
		}
	}

	private HealthBar healthBar;

	public int maxUnitsCarryable = 3;

	private bool doUnload;

	private Vector3 unloadTargetPos;

	private ArrayExt<IMoveableUnit> pendingloadTarget = new ArrayExt<IMoveableUnit>(3);

	public ArrayExt<bool> lockLoadTarget = new ArrayExt<bool>(3);

	public ArrayExt<IMoveableUnit> loadTarget = new ArrayExt<IMoveableUnit>(3);

	private Timer notifyTimer = new Timer(1f);

	private UnitIGUI unitGUI;

	public Mesh flagMesh;

	private List<IMoveableUnit> scratchUnloaded = new List<IMoveableUnit>();

	private ArrayExt<Cell> scratchOpenSet = new ArrayExt<Cell>(25);

	private ArrayExt<Cell> scratchClosedSet = new ArrayExt<Cell>(25);

	private ArrayExt<Cell> scratchPotentialUnload = new ArrayExt<Cell>(25);

	public Transform smallSlots;

	public Transform[] primarySlot;

	public Transform[] bigSlots;

	private bool destroyingAllLoaded;

	bool IMoveTarget.IsStationary()
	{
		return false;
	}

	public Vector3 GetDestPos()
	{
		if (!arrived)
		{
			if (deferredPath.status != GamePath.Status.Uninitialized)
			{
				return deferredPath.end;
			}
			if (path.Count > 0)
			{
				return path.data[path.Count - 1];
			}
		}
		return GetPos();
	}

	public bool IsBlockingCell()
	{
		return false;
	}

	public Vector3 GetToNextCell()
	{
		return transform.forward;
	}

	public int TeamID()
	{
		return teamID;
	}

	public AttackType GetAttackType()
	{
		return AttackType.Melee;
	}

	public int GetLOS()
	{
		return 8;
	}

	MoveType IMoveableUnit.GetMoveType()
	{
		return MoveType.Water;
	}

	void IMoveableUnit.MoveTo(IMoveTarget target)
	{
		if (target is IMoveableUnit moveableUnit && moveableUnit.CanBeCarried())
		{
			TryQueueForLoad(moveableUnit);
		}
		MoveTo(target);
		doUnload = false;
		Cell cellDataClamped = World.inst.GetCellDataClamped(target.GetPos());
		if ((cellDataClamped.Type != TerrainType.Water || cellDataClamped.StructureCompareCategoryNameAll(World.pathHash)) && loadTarget.Count > 0)
		{
			unloadTargetPos = cellDataClamped.Center2D;
			doUnload = true;
		}
	}

	public void Disband()
	{
		EffectsMan.inst.BuildPuff.CreateAndPlay(transform.position);
		SfxSystem.inst.PlayFromBank("DestroyTransportShip", transform.position);
		unloadTargetPos = World.inst.GetCellDataClamped(transform.position).Center2D;
		TryFinishUnload();
		OrdersManager.inst.DestroyUnit(this);
	}

	IMoveTarget IMoveableUnit.GetMoveTarget()
	{
		return moveTarget;
	}

	public void DoUnload(IMoveableUnit u)
	{
		if (arrived)
		{
			TryUnloadAt(u);
		}
	}

	public UnitType GetUnitType()
	{
		return UnitType.Ship;
	}

	public bool CanAttack()
	{
		return false;
	}

	public bool CanCarry()
	{
		return true;
	}

	public bool CanBeCarried()
	{
		return false;
	}

	public bool TryBeCarried()
	{
		return false;
	}

	public void StopBeingCarried()
	{
	}

	public bool IsFullCapacity()
	{
		return loadTarget.Count >= maxUnitsCarryable;
	}

	public bool IsPendingLoadTargets()
	{
		return pendingloadTarget.Count > 0;
	}

	public bool IsBeingCarried()
	{
		return false;
	}

	public bool PendingCarry(IMoveableUnit u)
	{
		return pendingloadTarget.Contains(u);
	}

	public int GetRemainingCapacity()
	{
		return maxUnitsCarryable - (pendingloadTarget.Count + loadTarget.Count);
	}

	public int CarryCount()
	{
		return loadTarget.Count;
	}

	public IMoveableUnit GetCarried(int i)
	{
		return loadTarget.data[i];
	}

	public int FormationIdx()
	{
		return 0;
	}

	public Guid GetGuid()
	{
		return guid;
	}

	public float CurrHealth()
	{
		return life;
	}

	public float MaxHealth()
	{
		return maxLife;
	}

	public void DestroyUnit()
	{
		DestroyLoadedUnits();
		if (this != null)
		{
			UnityEngine.Object.Destroy(gameObject);
		}
	}

	public ShipData GetShipData()
	{
		ShipData shipData = new ShipData();
		for (int i = 0; i < loadTarget.Count; i++)
		{
			shipData.loadTarget.Add(loadTarget.data[i].GetGuid());
		}
		return shipData;
	}

	public void SetFromShipData(ShipData data)
	{
		for (int i = 0; i < data.loadTarget.Count; i++)
		{
			IMoveableUnit moveableUnit = OrdersManager.inst.FindArmyByGuid(data.loadTarget[i]);
			if (moveableUnit != null)
			{
				TryForceLoad(moveableUnit);
			}
		}
	}

	private bool TryQueueForLoad(IMoveableUnit unit)
	{
		if (unit.TeamID() == TeamID() && !PendingCarry(unit) && !loadTarget.Contains(unit) && pendingloadTarget.Count + loadTarget.Count < maxUnitsCarryable)
		{
			pendingloadTarget.Add(unit);
			return true;
		}
		return false;
	}

	private Cell traceLineToFindWater(Cell a, Cell b)
	{
		int num = a.x;
		int num2 = a.z;
		int x = b.x;
		int z = b.z;
		int num3 = Mathf.Abs(x - num);
		int num4 = ((num < x) ? 1 : (-1));
		int num5 = Mathf.Abs(z - num2);
		int num6 = ((num2 < z) ? 1 : (-1));
		int num7 = num3 - num5;
		if (num3 + num5 != 0)
		{
			Mathf.Sqrt((float)num3 * (float)num3 + (float)num5 * (float)num5);
		}
		while (true)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(num, num2);
			if (cellDataClamped.Type == TerrainType.Water)
			{
				return cellDataClamped;
			}
			DebugEx.DrawCircleXZ(new Vector3(num, 0.2f, num2) + new Vector3(0.5f, 0f, 0.5f), 0.5f, Color.red, 4f, 100f);
			int num8 = num7;
			if (2 * num8 >= -num3)
			{
				if (num == x)
				{
					break;
				}
				num7 -= num5;
				num += num4;
			}
			if (2 * num8 <= num5)
			{
				if (num2 == z)
				{
					break;
				}
				num7 += num3;
				num2 += num6;
			}
		}
		return null;
	}

	private void TryMoveToUnitToLoad(IMoveTarget moveTarget)
	{
		MoveTo(new MoveToAvg
		{
			m1 = this,
			m2 = moveTarget
		}, displayPath: false);
	}

	public void OnUnitTargetsUs(IMoveableUnit unit)
	{
		IMoveTarget moveTarget = unit as IMoveTarget;
		if (moveTarget.TeamID() == teamID && unit.CanBeCarried() && TryQueueForLoad(unit))
		{
			TryMoveToUnitToLoad(moveTarget);
		}
	}

	public void OnUnitStoppedTargetingUs(IMoveableUnit u)
	{
		if (pendingloadTarget.Contains(u))
		{
			pendingloadTarget.RemoveSwap(u);
			if (pendingloadTarget.Count > 0)
			{
				TryMoveToUnitToLoad(pendingloadTarget.Last() as IMoveTarget);
			}
			else
			{
				MoveTo(World.inst.GetCellDataClamped(GetPos()));
			}
		}
	}

	void IMoveableUnit.NotifyOtherUnitDeath(IMoveableUnit u)
	{
		pendingloadTarget.RemoveSwap(u);
		if (!destroyingAllLoaded)
		{
			RemoveLoadTarget(u);
		}
	}

	bool ISelectable.ExclusiveSelect()
	{
		return false;
	}

	bool ISelectable.ValidToSelect()
	{
		return state == State.Sailing;
	}

	void ISelectable.SetHighlightImmediate(int colorIdx)
	{
		highlighter.SetOutlineImmediate(colorIdx);
	}

	void ISelectable.OnSelected()
	{
	}

	bool ISelectable.InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		int num = (int)GetPos().x;
		int num2 = (int)GetPos().z;
		if (minx <= num && num <= maxx && minz <= num2)
		{
			return num2 <= maxz;
		}
		return false;
	}

	private void AddLoadTarget(IMoveableUnit unit)
	{
		loadTarget.Add(unit);
		lockLoadTarget.Add(item: false);
	}

	private bool RemoveLoadTarget(IMoveableUnit unit)
	{
		for (int i = 0; i < loadTarget.Count; i++)
		{
			if (object.Equals(loadTarget.data[i], unit))
			{
				RemoveLoadTarget(i);
				return true;
			}
		}
		return false;
	}

	private void RemoveLoadTarget(int idx)
	{
		loadTarget.RemoveAtSwap(idx);
		lockLoadTarget.RemoveAtSwap(idx);
	}

	public void TryForceLoad(IMoveableUnit unit)
	{
		if (TryQueueForLoad(unit) && unit.TryBeCarried())
		{
			AddLoadTarget(unit);
			if (unit.TeamID() == 0 && unit is ArmySystem.Army army)
			{
				army.playerSetMoveTarget = null;
			}
			pendingloadTarget.RemoveSwap(unit);
		}
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		healthBar = UnityEngine.Object.Instantiate(Player.inst.healthBarPrefab);
		Util.SetActive(healthBar.gameObject, active: true);
		OrdersManager.inst.OnUnitRemoved += Inst_OnUnitRemoved;
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Combine(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
		if (unitGUI == null)
		{
			unitGUI = UnityEngine.Object.Instantiate(Player.inst.unitIGUIprefab).GetComponent<UnitIGUI>();
		}
	}

	private void Inst_OnUnitRemoved(IMoveableUnit u)
	{
		((IMoveableUnit)this).NotifyOtherUnitDeath(u);
	}

	public void UpdateBanners()
	{
		if ((bool)unitGUI)
		{
			unitGUI.Init(TeamID(), flagMesh);
		}
		UpdateMaterial();
	}

	public override void Init(int tId)
	{
		base.Init(tId);
		if (unitGUI == null)
		{
			unitGUI = UnityEngine.Object.Instantiate(Player.inst.unitIGUIprefab).GetComponent<UnitIGUI>();
		}
		unitGUI.Init(TeamID(), flagMesh);
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (healthBar != null)
		{
			healthBar.life = life / maxLife;
			healthBar.SetPos(dynamics.Pos + new Vector3(0f, 2f, 0f));
		}
		dynamics.repelDist = 2.5f;
		if (teamID == 1)
		{
			dynamics.accel = 3f;
		}
		else
		{
			dynamics.accel = 6f;
		}
		unitGUI.UpdateActive(loadTarget.Count == 0);
		unitGUI.transform.position = transform.position;
		if (pendingloadTarget.Count > 0)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(GetPos());
			for (int i = 0; i < pendingloadTarget.Count; i++)
			{
				if (Mathff.DistSqrd(cellDataClamped.Center2D, pendingloadTarget.data[i].GetPos()) < 3.0625f)
				{
					if (pendingloadTarget.data[i].TryBeCarried())
					{
						SfxSystem.inst.PlayFromBank("VikingShipClose", transform.position);
						AddLoadTarget(pendingloadTarget.data[i]);
					}
					if (pendingloadTarget.Count == 1 && TeamID() == 0 && GameUI.inst.IsSelected(pendingloadTarget.data[0] as ISelectable))
					{
						GameUI.inst.RemoveFromSelection(pendingloadTarget.data[0] as ISelectable);
						GameUI.inst.TrySelect(this);
					}
					pendingloadTarget.RemoveAtSwap(i);
					if (pendingloadTarget.Count > 0)
					{
						TryMoveToUnitToLoad(pendingloadTarget.Last() as IMoveTarget);
					}
				}
			}
		}
		if (notifyTimer.Update(dt))
		{
			for (int j = 0; j < loadTarget.Count; j++)
			{
				if (!(loadTarget.data[j] is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy, teamId: not 0 } army))
				{
					continue;
				}
				AIUnitControlSystem.UnitData unitDataFor = AIBrainsContainer.inst.GetKingdomFromTeamId(army.teamId).unitControl.GetUnitDataFor(army);
				if (unitDataFor.objective != null)
				{
					Vector3 worldPos = unitDataFor.objective.GetTarget().GetPos();
					if (World.GetLandmassOwner(World.inst.GetCellDataClamped(worldPos).landMassIdx) == Player.inst.PlayerLandmassOwner)
					{
						GameUI.inst.diplomacyNotificationUI.NotifyEnroute(army.general.GetComponent<Envoy>());
					}
				}
			}
		}
		UpdateArmyPosition();
		if (arrived && doUnload)
		{
			TryFinishUnload();
		}
	}

	private void TryFinishUnload()
	{
		TryUnloadAt();
		if (!doUnload && scratchUnloaded.Count > 0)
		{
			SfxSystem.inst.PlayFromBankIfVisible("VikingShipOpen", transform.position);
			if (TeamID() == 1)
			{
				SfxSystem.inst.PlayFromBankIfVisible("vikingbattlecry", transform.position);
			}
			if (GameUI.inst.IsSelected(this) && TeamID() == 0 && meshes[0].isVisible)
			{
				GameUI.inst.RemoveFromSelection(this);
				for (int i = 0; i < scratchUnloaded.Count; i++)
				{
					GameUI.inst.TrySelect(scratchUnloaded[i] as ISelectable);
				}
			}
		}
		scratchUnloaded.Clear();
	}

	private void TryUnloadAt()
	{
		for (int i = 0; i < loadTarget.Count; i++)
		{
			GetValidUnloadCells(loadTarget.data[i]);
			Cell cell = null;
			float num = float.MaxValue;
			for (int j = 0; j < scratchPotentialUnload.Count; j++)
			{
				Cell cell2 = scratchPotentialUnload.data[j];
				float num2 = Mathff.DistSqrdXZ(dynamics.Pos, cell2.Center2D);
				if (num2 < num)
				{
					num = num2;
					cell = cell2;
				}
			}
			if (lockLoadTarget.data[i])
			{
				if (doUnload && cell != null)
				{
					doUnload = false;
				}
				continue;
			}
			if (cell != null)
			{
				doUnload = false;
				scratchPotentialUnload.RemoveSwap(cell);
				loadTarget.data[i].StopBeingCarried();
				loadTarget.data[i].SetPos(cell.Center2D);
				if (moveTarget != null && !moveTarget.Equals(null))
				{
					OrdersManager.inst.MoveTo(loadTarget.data[i], moveTarget);
				}
				else
				{
					OrdersManager.inst.MoveTo(loadTarget.data[i], World.inst.GetCellData(unloadTargetPos));
				}
				if (loadTarget.data[i].TeamID() == 0 && loadTarget.data[i] is ArmySystem.Army army)
				{
					army.playerSetMoveTarget = World.inst.GetCellData(unloadTargetPos);
				}
				scratchUnloaded.Add(loadTarget.data[i]);
				RemoveLoadTarget(i);
				i--;
				continue;
			}
			break;
		}
	}

	private void TryAddToOpenSet(Cell cell)
	{
		if (!PathCell.GetBlocksFootPathForArmies(World.inst.GetPathCell(cell), _teamID))
		{
			scratchOpenSet.Add(cell);
		}
	}

	private void GetValidUnloadCells(IMoveableUnit u)
	{
		scratchPotentialUnload.Clear();
		Vector3 worldPos = GetPos();
		int num = (int)worldPos.x;
		int num2 = (int)worldPos.z;
		scratchOpenSet.Add(World.inst.GetCellDataClamped(worldPos));
		while (scratchOpenSet.Count > 0)
		{
			Cell cell = scratchOpenSet.data[0];
			scratchOpenSet.RemoveAt(0);
			if (scratchClosedSet.Contains(cell))
			{
				continue;
			}
			bool flag = PathCell.GetBlocksFootPathForArmies(World.inst.GetPathCell(cell), _teamID);
			if (u is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy })
			{
				flag = PathCell.GetBlocksFootPathForEnvoys(World.inst.GetPathCell(cell), _teamID);
			}
			if (!flag)
			{
				scratchPotentialUnload.Add(cell);
			}
			scratchClosedSet.Add(cell);
			if (flag && cell.Type != TerrainType.Water)
			{
				continue;
			}
			if (Mathf.Abs(cell.x - num) <= 2)
			{
				if (cell.x + 1 < World.inst.GridWidth)
				{
					TryAddToOpenSet(World.inst.GetCellDataClamped(cell.x + 1, cell.z));
				}
				if (cell.x - 1 >= 0)
				{
					TryAddToOpenSet(World.inst.GetCellDataClamped(cell.x - 1, cell.z));
				}
			}
			if (Mathf.Abs(cell.z - num2) <= 2)
			{
				if (cell.z + 1 < World.inst.GridHeight)
				{
					TryAddToOpenSet(World.inst.GetCellDataClamped(cell.x, cell.z + 1));
				}
				if (cell.z - 1 >= 0)
				{
					TryAddToOpenSet(World.inst.GetCellDataClamped(cell.x, cell.z - 1));
				}
			}
		}
		scratchClosedSet.Clear();
		scratchOpenSet.Clear();
	}

	private void TryUnloadAt(IMoveableUnit u)
	{
		if (!loadTarget.Contains(u))
		{
			return;
		}
		GetValidUnloadCells(u);
		Cell cell = null;
		float num = float.MaxValue;
		for (int i = 0; i < scratchPotentialUnload.Count; i++)
		{
			Cell cell2 = scratchPotentialUnload.data[i];
			float num2 = Mathff.DistSqrdXZ(dynamics.Pos, cell2.Center2D);
			if (num2 < num)
			{
				num = num2;
				cell = cell2;
			}
		}
		if (cell != null)
		{
			doUnload = false;
			RemoveLoadTarget(u);
			u.StopBeingCarried();
			u.SetPos(cell.Center2D);
			if (u.TeamID() == 0 && u is ArmySystem.Army army)
			{
				army.playerSetMoveTarget = cell;
			}
			OrdersManager.inst.MoveTo(u, World.inst.GetCellData(unloadTargetPos));
		}
	}

	private void UpdateArmyPosition()
	{
		int v = 0;
		int i = 0;
		for (int num = loadTarget.Count; i < num; i++)
		{
			if (loadTarget.data[i] is ArmySystem.Army army)
			{
				for (int j = 0; j < army.units.Count; j++)
				{
					ArmySystem.Unit unit = army.units.data[j];
					Transform child = smallSlots.GetChild(v++);
					v = Mathff.Clamp(v, 0, smallSlots.transform.childCount - 1);
					unit.pos = child.position;
					if (unit.life > 0f)
					{
						unit.rot = child.rotation;
					}
				}
				ArmySystem.inst.SetGeneralPos(army, primarySlot[i].position);
				continue;
			}
			SiegeMonster siegeMonster = loadTarget.data[i] as SiegeMonster;
			if (siegeMonster != null)
			{
				siegeMonster.transform.SetPositionAndRotation(bigSlots[i].position - new Vector3(0f, 0.5f, 0f), transform.rotation);
				continue;
			}
			SiegeCatapult siegeCatapult = loadTarget.data[i] as SiegeCatapult;
			if (siegeCatapult != null)
			{
				siegeCatapult.transform.SetPositionAndRotation(bigSlots[i].position, transform.rotation);
				continue;
			}
			Envoy envoy = loadTarget.data[i] as Envoy;
			if (envoy != null)
			{
				envoy.transform.SetPositionAndRotation(bigSlots[i].position, transform.rotation);
			}
		}
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		if (healthBar != null)
		{
			UnityEngine.Object.Destroy(healthBar.gameObject);
		}
		OrdersManager.inst.OnUnitRemoved -= Inst_OnUnitRemoved;
		OrdersManager.inst.RemoveUnit(this);
		if ((bool)unitGUI)
		{
			UnityEngine.Object.Destroy(unitGUI.gameObject);
		}
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Remove(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	public void OnTakeDamage(float dmg)
	{
	}

	private void DestroyLoadedUnits()
	{
		destroyingAllLoaded = true;
		for (int i = 0; i < loadTarget.Count; i++)
		{
			OrdersManager.inst.DestroyUnit(loadTarget.data[i]);
		}
		loadTarget.Clear();
		destroyingAllLoaded = false;
	}
}
