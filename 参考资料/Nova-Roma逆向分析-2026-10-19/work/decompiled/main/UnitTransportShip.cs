using System;
using System.Collections.Generic;
using UnityEngine;

public class UnitTransportShip : ShipBase, ISelectable, IUnitControllable, IMoveTarget
{
	[Serializable]
	public struct UnitSlotData
	{
		public int unitType;
	}

	public class Oar : InstanceSystemBehaviour.Owner
	{
		public bool isMirrored;

		public Vector3 relPos;

		public Quaternion relRot;

		public Vector3 relScale;

		public float timeOffset;
	}

	public struct MoveToAvg : IMoveTarget
	{
		public IMoveTarget m1;

		public IMoveTarget m2;

		public Vector3 GetPredictedPosition(float time)
		{
			return GetPos();
		}

		bool IMoveTarget.IsStationary()
		{
			return false;
		}

		public Vector3 GetPos()
		{
			Vector3 vector = Vector3.Lerp(m1.GetPos(), m2.GetPos(), 0.5f);
			if (World.inst.GetCellDataClamped(vector).Type != TerrainType.Obstruction)
			{
				return vector;
			}
			return m2.GetPos();
		}

		public int TeamID()
		{
			return m1.TeamID();
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

	[Serializable]
	public new class ShipData
	{
		public List<Guid> loadTarget = new List<Guid>();
	}

	private UnitIGUI unitUI;

	[SerializeField]
	private List<UnitSlotData> slotsData = new List<UnitSlotData>();

	private Dictionary<int, UnitSlotData> slotsMap = new Dictionary<int, UnitSlotData>();

	public int maxUnitsCarryable = 3;

	private List<IUnitControllable> scratchUnloaded = new List<IUnitControllable>();

	private bool doUnload;

	private Vector3 unloadTargetPos;

	private ArrayExt<IUnitControllable> pendingloadTarget = new ArrayExt<IUnitControllable>(3);

	public ArrayExt<IUnitControllable> loadTarget = new ArrayExt<IUnitControllable>(3);

	public IUnitControllable[] carriedUnitInSlot;

	[NonSerialized]
	public bool[] isSlotLocked;

	public VillagerPropsManager propsManager;

	public List<Transform> bakedOars = new List<Transform>(48);

	[NonSerialized]
	public ArrayExt<Oar> instanceOars;

	public float yRadius = 45f;

	public float zRadius = 45f;

	public float speed = 2f;

	public float speedInterpolationRate = 1f;

	private float currTime;

	private float currSpeed;

	public Transform splashL;

	public Transform splashR;

	public float splashTime;

	public float unitUIAdjustZ = -1.49f;

	public float unitUIAdjustY = 0.1f;

	public bool CanSettle;

	private bool wasMeshVisible = true;

	public GameObject shields;

	internal bool failedLastUnload;

	private ArrayExt<Cell> scratchOpenSet = new ArrayExt<Cell>(25);

	private ArrayExt<Cell> scratchClosedSet = new ArrayExt<Cell>(25);

	private ArrayExt<Cell> scratchPotentialUnload = new ArrayExt<Cell>(25);

	private bool destroyingAllLoaded;

	public int SearchRadius;

	bool IMoveTarget.IsStationary()
	{
		return false;
	}

	int IUnitControllable.GetSlotsOccupied()
	{
		return -1;
	}

	int IUnitControllable.GetFormationIdx()
	{
		return 0;
	}

	public UnitSlotData GetSlotData(int type)
	{
		return slotsMap[type];
	}

	private int[] GetEmptySlots(int amt)
	{
		int num = 0;
		int[] array = new int[amt];
		for (int i = 0; i < carriedUnitInSlot.Length; i++)
		{
			if (carriedUnitInSlot[i] == null)
			{
				array[num++] = i;
			}
			if (num == amt)
			{
				return array;
			}
		}
		return null;
	}

	public bool IsUnitLocked(IUnitControllable unit)
	{
		for (int i = 0; i < carriedUnitInSlot.Length; i++)
		{
			if (carriedUnitInSlot[i] == unit)
			{
				return isSlotLocked[i];
			}
		}
		return false;
	}

	public void ToggleUnitLock(IUnitControllable unit)
	{
		for (int i = 0; i < carriedUnitInSlot.Length; i++)
		{
			if (carriedUnitInSlot[i] == unit)
			{
				isSlotLocked[i] = !isSlotLocked[i];
			}
		}
	}

	private void Awake()
	{
		isSlotLocked = new bool[maxUnitsCarryable];
		carriedUnitInSlot = new IUnitControllable[maxUnitsCarryable];
		for (int i = 0; i < slotsData.Count; i++)
		{
			UnitSlotData value = slotsData[i];
			slotsMap.TryAdd(value.unitType, value);
		}
		propsManager.HideProps();
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Combine(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
		UnitSystem.inst.OnUnitRemoved += OnUnitRemoved;
	}

	private void OnDestroy()
	{
		if (unitUI != null)
		{
			UnityEngine.Object.Destroy(unitUI.gameObject);
		}
		unitUI = null;
		for (int i = 0; i < instanceOars.Count; i++)
		{
			OarInstanceSystem.inst.ReleaseInstance(instanceOars.data[i]);
		}
		instanceOars.Clear();
		UnitSystem.inst.OnUnitRemoved -= OnUnitRemoved;
		if (!GameState.IsQuitting)
		{
			UnitSystem.inst.RemoveUnit(this);
		}
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Remove(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	public void UpdateBanners()
	{
		Mesh flagMesh = LegionSystem.Inst.GetLegionDef(0, TeamID()).flagMesh;
		if ((bool)unitUI)
		{
			unitUI.Init(TeamID(), flagMesh);
		}
		UpdateMaterial();
	}

	public override void Init(int tId)
	{
		base.Init(tId);
		unitUI = UnityEngine.Object.Instantiate(Player.inst.unitIGUIprefab).GetComponent<UnitIGUI>();
		Mesh flagMesh = LegionSystem.Inst.GetLegionDef(0, tId).flagMesh;
		unitUI.Init(tId, flagMesh, 0);
		UnitSystem.inst.TryAddUnit(this);
		instanceOars = new ArrayExt<Oar>(bakedOars.Count * 2);
		for (int num = bakedOars.Count - 1; num >= 0; num--)
		{
			Oar item = InitOar(bakedOars[num], isMirrored: false);
			instanceOars.Add(item);
		}
		for (int num2 = bakedOars.Count - 1; num2 >= 0; num2--)
		{
			Oar item2 = InitOar(bakedOars[num2], isMirrored: true);
			UnityEngine.Object.Destroy(bakedOars[num2].gameObject);
			instanceOars.Add(item2);
		}
		bakedOars.Clear();
	}

	private Oar InitOar(Transform baked, bool isMirrored)
	{
		Oar oar = new Oar();
		oar.isMirrored = isMirrored;
		if (isMirrored)
		{
			Vector3 localPosition = baked.localPosition;
			localPosition.x *= -1f;
			oar.relPos = localPosition;
			oar.relRot = Quaternion.Inverse(baked.localRotation);
			Vector3 localScale = baked.localScale;
			localScale.x *= -1f;
			localScale.z *= -1f;
			oar.relScale = localScale;
		}
		else
		{
			oar.relPos = baked.localPosition;
			oar.relRot = baked.localRotation;
			oar.relScale = baked.localScale;
		}
		oar.timeOffset = SRand.Range(0f, 0.05f);
		Vector3 initPos = transform.TransformPoint(oar.relPos);
		Quaternion initRot = transform.rotation * oar.relRot;
		OarInstanceSystem.inst.AddInstance(oar, initPos, initRot, oar.relScale);
		return oar;
	}

	public void Settle(Building outpost)
	{
		outpost.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		minX = Mathff.Clamp(minX - 1, 0, World.inst.GridWidth - 1);
		maxX = Mathff.Clamp(maxX + 1, 0, World.inst.GridWidth - 1);
		minZ = Mathff.Clamp(minZ - 1, 0, World.inst.GridHeight - 1);
		maxZ = Mathff.Clamp(maxZ + 1, 0, World.inst.GridHeight - 1);
		Vector3 vector = outpost.GetPos();
		Vector3 vector2 = vector;
		float num = 0f;
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j < maxX; j++)
			{
				float num2 = Mathff.DistSqrdXZ(vector, new Vector3(j, 0f, i));
				if (num2 > num)
				{
					num = num2;
					vector2 = World.inst.GetCellData(j, i).Center3D;
				}
			}
		}
		int num3 = Mathff.Min(48, 48 - World.inst.GetVillagersForLandMass(outpost.LandMass()).Count);
		for (int k = 0; k < num3; k++)
		{
			Villager villager = Villager.CreateVillager();
			Player.inst.Workers.Add(villager);
			Player.inst.Homeless.Add(villager);
			villager.TeleportTo(vector2 + SRand.insideUnitSquareXZ * 0.5f);
		}
		UnitSystem.inst.DestroyUnit(loadTarget.data[0]);
		Disband();
	}

	private void UpdateSettling()
	{
		if (SearchRadius <= 0)
		{
			return;
		}
		bool flag = false;
		if (loadTarget.Count > 0 && loadTarget.data[0] is LegionUnit)
		{
			Vector3 center3D = World.inst.GetCellDataClamped(GetPos()).Center3D;
			int num = (int)Mathff.Clamp(center3D.x - (float)SearchRadius, 0f, World.inst.GridWidth - 1);
			int num2 = (int)Mathff.Clamp(center3D.x + (float)SearchRadius, 0f, World.inst.GridWidth - 1);
			int num3 = (int)Mathff.Clamp(center3D.z - (float)SearchRadius, 0f, World.inst.GridHeight - 1);
			int num4 = (int)Mathff.Clamp(center3D.z + (float)SearchRadius, 0f, World.inst.GridHeight - 1);
			int num5 = SearchRadius * SearchRadius;
			for (int i = num3; i <= num4; i++)
			{
				for (int j = num; j < num2; j++)
				{
					if ((center3D.x - (float)j) * (center3D.x - (float)j) + (center3D.z - (float)i) * (center3D.z - (float)i) <= (float)num5)
					{
						Cell cellData = World.inst.GetCellData(j, i);
						if (cellData.Type != TerrainType.Water && World.GetLandmassOwner(cellData.landMassIdx) == null)
						{
							flag = true;
							break;
						}
					}
				}
			}
		}
		if (!flag && CanSettle && GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			Outpost outpost = GameUI.inst.CurrPlacementMode.buildings[0]?.GetComponent<Outpost>();
			if (outpost != null && outpost.seedShip == this)
			{
				GameUI.inst.CurrPlacementMode.AbortPlacement(refund: false);
			}
		}
		CanSettle = flag;
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		bool flag = false;
		for (int i = 0; i < meshes.Length; i++)
		{
			if (meshes[i].isVisible)
			{
				flag = true;
				break;
			}
		}
		UpdateSettling();
		if (flag)
		{
			Quaternion rotation = transform.rotation;
			float next = 0f;
			if (dynamics.isMoving)
			{
				next = dynamics.velocity.magnitude * speed;
			}
			Mathff.MoveTowards(currSpeed, next, dt * speedInterpolationRate, out var _, out currSpeed);
			currTime += Time.deltaTime * currSpeed;
			float num = Mathf.Sin(currTime * speed * MathF.PI * -2f);
			float num2 = Mathf.Sin((currTime + Time.deltaTime) * speed * MathF.PI * -2f);
			if (num > splashTime && num2 <= splashTime)
			{
				EffectsMan.inst.OarSplash.CreateAndPlay(splashR.position, transform.rotation);
				EffectsMan.inst.OarSplash.CreateAndPlay(splashL.position, transform.rotation);
				DebugEx.DrawSphere(transform.position, 3f, Color.red);
			}
			for (int j = 0; j < instanceOars.Count; j++)
			{
				Oar oar = instanceOars.data[j];
				float num3 = currTime + oar.timeOffset;
				float num4 = Mathf.Sin(num3 * speed * MathF.PI * -2f);
				float num5 = Mathf.Cos(num3 * speed * MathF.PI * -2f);
				float y = num4 * (oar.isMirrored ? (0f - yRadius) : yRadius);
				float z = num5 * (oar.isMirrored ? (0f - zRadius) : zRadius);
				Vector3 vector = transform.TransformPoint(oar.relPos);
				Quaternion q = rotation * (Quaternion.Euler(0f, y, z) * oar.relRot);
				OarInstanceSystem.inst.silos.data[oar.s][oar.idx].SetTRS(vector, q, oar.relScale);
			}
		}
		else if (wasMeshVisible)
		{
			Vector3 zero = Vector3.zero;
			for (int k = 0; k < instanceOars.Count; k++)
			{
				Oar oar2 = instanceOars.data[k];
				Mathff.SetTS(ref OarInstanceSystem.inst.silos.data[oar2.s][oar2.idx], zero, zero);
			}
		}
		unitUI.transform.position = transform.position + transform.forward * unitUIAdjustZ + new Vector3(0f, unitUIAdjustY, 0f);
		unitUI.healthBar.life = life / maxLife;
		unitUI.healthBar.SetPos(dynamics.Pos + new Vector3(0f, 2f, 0f));
		if (pendingloadTarget.Count > 0)
		{
			Vector3 forward = transform.forward;
			Vector3 a = GetPos();
			Vector3 a2 = GetPos() + forward;
			Vector3 a3 = GetPos() - forward;
			float num6 = 3.0625f;
			for (int l = 0; l < pendingloadTarget.Count; l++)
			{
				Vector3 b = pendingloadTarget.data[l].GetPos();
				if (!(Mathff.DistSqrdXZ(a, b) < num6) && !(Mathff.DistSqrdXZ(a2, b) < num6) && !(Mathff.DistSqrdXZ(a3, b) < num6))
				{
					continue;
				}
				IUnitControllable unitControllable = pendingloadTarget.data[l];
				if (unitControllable.TryBeCarried())
				{
					AddLoadTarget(unitControllable);
				}
				pendingloadTarget.RemoveAtSwap(l);
				if (pendingloadTarget.Count == 0)
				{
					if (UnitControlSystem.inst.IsUnitControllableByTeam(unitControllable, TeamID()) && UnitControlSystem.inst.GetSelectionCount() == 1 && UnitControlSystem.inst.IsSelected(unitControllable))
					{
						UnitControlSystem.inst.ExclusiveSelect(this);
					}
				}
				else
				{
					TryMoveToUnitToLoad(pendingloadTarget.Last() as IMoveTarget);
				}
			}
		}
		UpdateUnitPositions();
		if (arrived && doUnload)
		{
			TryFinishUnload();
		}
		wasMeshVisible = flag;
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

	int IUnitControllable.GetUnitType()
	{
		return 3;
	}

	public int GetUnitAttackType()
	{
		return -1;
	}

	public int TeamID()
	{
		return teamID;
	}

	public int GetAttackType()
	{
		return -1;
	}

	public int GetLOS()
	{
		return 8;
	}

	int IUnitControllable.GetMoveType()
	{
		return 1;
	}

	public void MoveTo(IMoveTarget target)
	{
		if (pendingloadTarget.Count > 0 && target is Cell)
		{
			_ = 0;
		}
		if (target is IUnitControllable unitControllable && unitControllable.CanBeCarried())
		{
			TryQueueForLoad(unitControllable);
		}
		MoveTo(target, true);
		failedLastUnload = false;
		doUnload = false;
		if (target != null && !(target is MoveToAvg))
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(target.GetPos());
			if ((cellDataClamped.Type != TerrainType.Water || cellDataClamped.StructureCompareCategoryNameAll(World.pathHash)) && loadTarget.Count > 0)
			{
				unloadTargetPos = cellDataClamped.Center2D;
				doUnload = true;
			}
		}
	}

	public void Disband()
	{
		EffectsMan.inst.BuildPuff.CreateAndPlay(transform.position + new Vector3(0f, 0.25f, 0f));
		SfxSystem.inst.PlayFromBank("DestroyTransportShip", transform.position);
		unloadTargetPos = World.inst.GetCellDataClamped(transform.position).Center3D;
		TryFinishUnload();
		UnitSystem.inst.DestroyUnit(this);
	}

	IMoveTarget IUnitControllable.GetMoveTarget()
	{
		return moveTarget;
	}

	public void DoUnload(IUnitControllable u)
	{
		if (arrived)
		{
			TryUnloadAt(u);
		}
	}

	public int GetUnitType()
	{
		return 3;
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

	public bool IsPendingLoadTargets()
	{
		return pendingloadTarget.Count > 0;
	}

	public bool IsBeingCarried()
	{
		return false;
	}

	public bool PendingCarry(IUnitControllable u)
	{
		return pendingloadTarget.Contains(u);
	}

	public int GetRemainingCapacity()
	{
		int num = 0;
		for (int i = 0; i < pendingloadTarget.Count; i++)
		{
			num += pendingloadTarget.data[i].GetSlotsOccupied();
		}
		for (int j = 0; j < loadTarget.Count; j++)
		{
			num += loadTarget.data[j].GetSlotsOccupied();
		}
		return maxUnitsCarryable - num;
	}

	public int CarryCount()
	{
		return loadTarget.Count;
	}

	public IUnitControllable GetCarried(int i)
	{
		return loadTarget.data[i];
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

	private bool TryQueueForLoad(IUnitControllable unit)
	{
		if (unit.TeamID() == TeamID() && !PendingCarry(unit) && !loadTarget.Contains(unit))
		{
			if (GetRemainingCapacity() < unit.GetSlotsOccupied())
			{
				return false;
			}
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
		UnitSystem.inst.MoveTo(this, new MoveToAvg
		{
			m1 = this,
			m2 = moveTarget
		});
	}

	public void OnUnitTargetsUs(IUnitControllable unit)
	{
		IMoveTarget moveTarget = unit as IMoveTarget;
		if (moveTarget.TeamID() == teamID && unit.CanBeCarried() && TryQueueForLoad(unit))
		{
			TryMoveToUnitToLoad(moveTarget);
		}
	}

	public void OnUnitStoppedTargetingUs(IUnitControllable u)
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
				UnitSystem.inst.MoveTo(this, null);
			}
		}
	}

	void IUnitControllable.NotifyOtherUnitDeath(IUnitControllable u)
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

	private void UpdateLoadedVisuals()
	{
		if ((bool)shields)
		{
			bool active = false;
			for (int i = 0; i < loadTarget.Count; i++)
			{
				if (loadTarget.data[i] is LegionUnit)
				{
					active = true;
				}
			}
			Util.SetActive(shields, active);
		}
		if (loadTarget.Count > 0)
		{
			int propType = 2;
			switch (loadTarget.data[0].GetUnitType())
			{
			case 0:
				propType = 1;
				break;
			case 4:
				propType = 2;
				break;
			}
			propsManager.SetPropType(propType);
			propsManager.ShowProps();
		}
		else
		{
			propsManager.HideProps();
		}
	}

	private void AddLoadTarget(IUnitControllable unit)
	{
		loadTarget.Add(unit);
		int[] emptySlots = GetEmptySlots(unit.GetSlotsOccupied());
		foreach (int num in emptySlots)
		{
			carriedUnitInSlot[num] = unit;
			isSlotLocked[num] = false;
		}
		UpdateLoadedVisuals();
	}

	private bool RemoveLoadTarget(IUnitControllable unit)
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
		IUnitControllable unitControllable = loadTarget.data[idx];
		for (int i = 0; i < carriedUnitInSlot.Length; i++)
		{
			if (carriedUnitInSlot[i] == unitControllable)
			{
				carriedUnitInSlot[i] = null;
				isSlotLocked[i] = false;
			}
		}
		loadTarget.RemoveAtSwap(idx);
		UpdateLoadedVisuals();
	}

	public bool TryForceLoad(IUnitControllable unit)
	{
		if (TryQueueForLoad(unit) && unit.TryBeCarried())
		{
			AddLoadTarget(unit);
			pendingloadTarget.RemoveSwap(unit);
			return true;
		}
		return false;
	}

	private void OnUnitRemoved(IUnitControllable u)
	{
		((IUnitControllable)this).NotifyOtherUnitDeath(u);
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
			if (UnitControlSystem.inst.IsUnitControllableByTeam(this, 0) && UnitControlSystem.inst.IsSelected(this))
			{
				for (int i = 0; i < scratchUnloaded.Count; i++)
				{
					UnitControlSystem.inst.TryAddToSelection(scratchUnloaded[i]);
				}
				UnitControlSystem.inst.TryRemoveFromSelection(this);
			}
		}
		scratchUnloaded.Clear();
	}

	private unsafe void TryUnloadAt()
	{
		failedLastUnload = false;
		int num = 0;
		for (int i = 0; i < loadTarget.Count; i++)
		{
			IUnitControllable unitControllable = loadTarget.data[i];
			GetValidUnloadCells(unitControllable);
			if (IsUnitLocked(unitControllable))
			{
				if (doUnload && scratchPotentialUnload.Count > 0)
				{
					doUnload = false;
				}
				continue;
			}
			if (scratchPotentialUnload.Count <= 0)
			{
				break;
			}
			doUnload = false;
			unitControllable.StopBeingCarried();
			if (unitControllable is LegionUnit legionUnit)
			{
				LegionGroup legionGroup = legionUnit.GetGroup();
				for (int j = 0; j < legionGroup.numCells; j++)
				{
					Cell cell = scratchPotentialUnload.data[num % scratchPotentialUnload.Count];
					num = (num + 1) % scratchPotentialUnload.Count;
					LegionSystem.Inst.SetPositionForCell(legionGroup.cells[j], cell.Center3D, legionGroup);
				}
			}
			else
			{
				Cell cell2 = scratchPotentialUnload.data[num % scratchPotentialUnload.Count];
				num = (num + 1) % scratchPotentialUnload.Count;
				unitControllable.SetPos(cell2.Center2D);
			}
			if (moveTarget != null && !moveTarget.Equals(null))
			{
				UnitSystem.inst.MoveTo(unitControllable, moveTarget);
			}
			else
			{
				UnitSystem.inst.MoveTo(unitControllable, World.inst.GetCellData(unloadTargetPos));
			}
			scratchUnloaded.Add(unitControllable);
			RemoveLoadTarget(i);
			i--;
		}
		if (doUnload)
		{
			failedLastUnload = true;
		}
	}

	private void TryAddToOpenSet(Cell cell)
	{
		scratchOpenSet.Add(cell);
	}

	private void GetValidUnloadCells(IUnitControllable u)
	{
		scratchPotentialUnload.Clear();
		Vector3 vector = GetPos();
		int num = (int)vector.x;
		int num2 = (int)vector.z;
		scratchOpenSet.Add(World.inst.GetCellDataClamped(vector));
		while (scratchOpenSet.Count > 0)
		{
			Cell cell = scratchOpenSet.data[0];
			scratchOpenSet.RemoveAt(0);
			if (scratchClosedSet.Contains(cell))
			{
				continue;
			}
			bool blocksFootPathForArmies = PathCell.GetBlocksFootPathForArmies(World.inst.GetPathCell(cell), _teamID);
			if (!blocksFootPathForArmies && cell.Type != TerrainType.Water)
			{
				float num3 = Mathff.DistSqrdXZ(cell.Center2D, vector);
				int num4 = 0;
				while (true)
				{
					if (num4 < scratchPotentialUnload.Count)
					{
						if (!(Mathff.DistSqrdXZ(scratchPotentialUnload.data[num4].Center2D, vector) <= num3))
						{
							scratchPotentialUnload.Insert(num4, cell);
							break;
						}
						num4++;
						continue;
					}
					scratchPotentialUnload.Add(cell);
					break;
				}
			}
			scratchClosedSet.Add(cell);
			if (blocksFootPathForArmies && cell.Type != TerrainType.Water)
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

	private unsafe void TryUnloadAt(IUnitControllable u)
	{
		failedLastUnload = false;
		if (!loadTarget.Contains(u))
		{
			return;
		}
		GetValidUnloadCells(u);
		if (scratchPotentialUnload.Count > 0)
		{
			int num = 0;
			doUnload = false;
			RemoveLoadTarget(u);
			u.StopBeingCarried();
			if (u is LegionUnit legionUnit)
			{
				LegionGroup legionGroup = legionUnit.GetGroup();
				for (int i = 0; i < legionGroup.numCells; i++)
				{
					Cell cell = scratchPotentialUnload.data[num % scratchPotentialUnload.Count];
					num = (num + 1) % scratchPotentialUnload.Count;
					LegionCell value = LegionSystem.Inst.legionCells[legionGroup.cells[i]];
					value.position = cell.Center2D;
					LegionSystem.Inst.legionCells[legionGroup.cells[i]] = value;
				}
			}
			else
			{
				u.SetPos(scratchPotentialUnload.First().Center2D);
			}
			UnitSystem.inst.MoveTo(u, World.inst.GetCellData(unloadTargetPos));
		}
		if (doUnload)
		{
			failedLastUnload = true;
		}
	}

	private void UpdateUnitPositions()
	{
	}

	public void OnTakeDamage(float dmg)
	{
	}

	private void DestroyLoadedUnits()
	{
		destroyingAllLoaded = true;
		for (int i = 0; i < loadTarget.Count; i++)
		{
			UnitSystem.inst.DestroyUnit(loadTarget.data[i]);
		}
		loadTarget.Clear();
		destroyingAllLoaded = false;
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
			IUnitControllable unitControllable = UnitSystem.inst.FindUnitByGuid(data.loadTarget[i]);
			if (unitControllable != null)
			{
				TryForceLoad(unitControllable);
			}
		}
	}
}
