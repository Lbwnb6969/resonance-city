using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using Unity.Collections;
using UnityEngine;

public class LegionUnit : ISelectable, IUnitControllable, IMoveTarget, IProjectileHitable
{
	internal RomanBarracks ownerBarracks;

	private UnitIGUI unitUI;

	[NonSerialized]
	public ObjectHighlighter highlight;

	private int groupID;

	private IMoveTarget mTarget;

	public bool isPlayerMoveTo;

	private ResourceText rText;

	private int stolenGold;

	private int teamOfStolenGold = -1;

	private bool hasThrownInitialTorches;

	private static int frameSpread = 20;

	private int updateFrame = updateFrameCount++ % frameSpread;

	private static int updateFrameCount = 0;

	private int[] lastAttackTargets;

	private bool lastflipOffset;

	private EventInstance eFightAmb;

	private float dmgTimer;

	internal int lastMorale;

	private Vector3 lastPos;

	bool IMoveTarget.IsStationary()
	{
		return false;
	}

	int IUnitControllable.GetFormationIdx()
	{
		if (GetGroup().type == 5)
		{
			return 1;
		}
		return 0;
	}

	int IUnitControllable.GetSlotsOccupied()
	{
		return GetGroup().numCells;
	}

	public override int GetHashCode()
	{
		return GetGroup().id;
	}

	public override bool Equals(object obj)
	{
		if (obj == null)
		{
			LegionGroup legionGroup = GetGroup();
			if (legionGroup.inUse != 0)
			{
				return legionGroup.dead == 1;
			}
			return true;
		}
		return base.Equals(obj);
	}

	public LegionUnit(int id)
	{
		groupID = id;
		unitUI = UnityEngine.Object.Instantiate(Player.inst.unitIGUIprefab).GetComponent<UnitIGUI>();
		LegionGroup legionGroup = GetGroup();
		Mesh flagMesh = LegionSystem.Inst.GetLegionDef(legionGroup.type, legionGroup.team).flagMesh;
		unitUI.Init(legionGroup.team, flagMesh, legionGroup.numCells);
		lastAttackTargets = new int[legionGroup.numCells];
		for (int i = 0; i < lastAttackTargets.Length; i++)
		{
			lastAttackTargets[i] = -1;
		}
		List<MeshRenderer> list = new List<MeshRenderer>
		{
			unitUI.flag.GetComponent<MeshRenderer>(),
			unitUI.flagPole.GetComponent<MeshRenderer>()
		};
		for (int j = 0; j < unitUI.selectors.Count; j++)
		{
			list.Add(unitUI.selectors[j].GetComponent<MeshRenderer>());
		}
		highlight = ObjectHighlighter.SetupOutlines(unitUI.gameObject, list, null);
	}

	public int GetGroupID()
	{
		return groupID;
	}

	public LegionGroup GetGroup()
	{
		return LegionSystem.Inst.groups[groupID];
	}

	public unsafe void Tick(float dt, int frameCount)
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		_ = LegionSystem.Inst.legionCells[legionGroup.leaderCellId];
		Vector3 zero = Vector3.zero;
		if (legionGroup.numCells > 0)
		{
			for (int i = 0; i < legionGroup.numCells; i++)
			{
				Vector3 position = LegionSystem.Inst.legionCells[legionGroup.cells[i]].position;
				zero += position;
			}
			zero /= (float)legionGroup.numCells;
			lastPos = zero;
		}
		else
		{
			zero = lastPos;
		}
		Quaternion rotation = Quaternion.LookRotation(legionGroup.facing);
		lastflipOffset = legionGroup.flipOffset;
		if (lastMorale != legionGroup.morale)
		{
			OneOffEffect oneOffEffect = EffectsMan.inst.LevelUp.Create(zero);
			oneOffEffect.Color = Color.yellow;
			oneOffEffect.Play();
		}
		lastMorale = legionGroup.morale;
		unitUI.SetMorale(legionGroup.morale);
		unitUI.transform.position = zero;
		unitUI.UpdateActive(legionGroup.isBeingCarried == 0);
		unitUI.healthBar.visible = legionGroup.isBeingCarried == 0;
		unitUI.healthBar.life = legionGroup.pep / (float)legionGroup.origNumCells;
		unitUI.healthBar.SetPos(zero + new Vector3(0f, 1.4f, 0f));
		Vector3 position2 = lastPos;
		int num = 0;
		for (num = 0; num < legionGroup.numCells; num++)
		{
			Vector3 position3 = LegionSystem.Inst.legionCells[legionGroup.cells[num]].position;
			unitUI.selectors[num].SetPositionAndRotation(position3 + new Vector3(0f, 0.1f, 0f), rotation);
		}
		if (legionGroup.numCells > 0)
		{
			position2 = LegionSystem.Inst.legionCells[legionGroup.cells[0]].position;
		}
		for (; num < unitUI.selectors.Count; num++)
		{
			unitUI.selectors[num].SetPositionAndRotation(position2 + new Vector3(0f, 0.1f, 0f), rotation);
		}
		if (legionGroup.dead == 1)
		{
			unitUI.flagPole.transform.Rotate(new Vector3(90f * dt, 0f, 0f));
		}
		int num2 = 0;
		num2 += ((legionGroup.heightAdvantageBonus > 0f) ? 1 : 0);
		num2 += ((legionGroup.flankBonus > 0f) ? 1 : 0);
		unitUI.healthBar.SetAttackBonusCount(num2);
		if (rText != null)
		{
			rText.transform.position = zero + new Vector3(0f, 2f, 0f);
		}
		if (mTarget == null || mTarget.Equals(null))
		{
			mTarget = null;
		}
		if (mTarget != null && !mTarget.Equals(null))
		{
			bool flag = World.inst.RelationBetween(TeamID(), mTarget.TeamID()) == World.Relations.Enemy;
			if ((mTarget is LegionUnit) & flag)
			{
				for (int j = 0; j < legionGroup.numCells; j++)
				{
					LegionCell legionCell = LegionSystem.Inst.legionCells[legionGroup.cells[j]];
					int spearTargetCellId = legionCell.spearTargetCellId;
					if (spearTargetCellId != -1 && lastAttackTargets[j] == -1)
					{
						Vector3 vector = LegionSystem.Inst.legionCells[spearTargetCellId].position - legionCell.position;
						vector.Normalize();
						OneOffEffect oneOffEffect2 = EffectsMan.inst.SpearThrowEffect.Create(legionCell.position + vector * 0.75f);
						LegionCell legionCell2 = LegionSystem.Inst.legionCells[spearTargetCellId];
						oneOffEffect2.GetComponentInChildren<ArrowHailEffect>().SetTarget(legionCell2.position + vector * 0.5f, legionCell2.velocity);
						oneOffEffect2.Play();
					}
					lastAttackTargets[j] = spearTargetCellId;
				}
			}
			dmgTimer += dt;
			if (dmgTimer > 0.5f)
			{
				TryApplyDamageToBuildingAndUnits();
				dmgTimer = 0f;
			}
			if (legionGroup.team != 1 && (mTarget is UnitControlSystem.StaticPosMoveTarget || mTarget is Cell || mTarget is Building))
			{
				Building building = null;
				if (mTarget is UnitControlSystem.StaticPosMoveTarget staticPosMoveTarget)
				{
					building = World.inst.GetCellDataClamped(staticPosMoveTarget.GetPos()).TopStructure;
				}
				else if (mTarget is Cell cell)
				{
					building = cell.TopStructure;
				}
				else if (mTarget is Building building2)
				{
					building = building2;
				}
				if (building != null)
				{
					RomanBarracks component = building.GetComponent<RomanBarracks>();
					if (component != null && component.GetOccupyingUnit() == this)
					{
						NativeArray<LegionCell> legionCells = LegionSystem.Inst.legionCells;
						float num3 = 0.43560004f;
						bool flag2 = false;
						building.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
						minX = Mathff.Clamp(minX - 1, 0, World.inst.GridWidth - 1);
						maxX = Mathff.Clamp(maxX + 1, 0, World.inst.GridWidth - 1);
						minZ = Mathff.Clamp(minZ - 1, 0, World.inst.GridHeight - 1);
						maxZ = Mathff.Clamp(maxZ + 1, 0, World.inst.GridHeight - 1);
						for (int k = minZ; k <= maxZ; k++)
						{
							for (int l = minX; l <= maxX; l++)
							{
								Vector3 a = new Vector3((float)l + 0.5f, 0f, (float)k + 0.5f);
								int num4 = 0;
								while (num4 < legionGroup.numCells)
								{
									if (!(Mathff.DistSqrdXZ(a, legionCells[legionGroup.cells[num4]].position) < num3))
									{
										num4++;
										continue;
									}
									goto IL_0664;
								}
							}
							continue;
							IL_0664:
							flag2 = true;
							break;
						}
						if (flag2 && (legionGroup.numCells < legionGroup.origNumCells || legionGroup.pep < (float)legionGroup.numCells))
						{
							component.deferRecooperate = true;
						}
					}
				}
			}
			Building building3 = mTarget as Building;
			if (((object)building3 != null) & flag)
			{
				NativeArray<LegionCell> legionCells2 = LegionSystem.Inst.legionCells;
				bool flag3 = false;
				bool flag4 = false;
				float num5 = 0.0625f;
				float num6 = 1f;
				building3.GetBoundingFootprint(out var minX2, out var minZ2, out var maxX2, out var maxZ2);
				minX2 = Mathff.Clamp(minX2 - 2, 0, World.inst.GridWidth - 1);
				maxX2 = Mathff.Clamp(maxX2 + 2, 0, World.inst.GridWidth - 1);
				minZ2 = Mathff.Clamp(minZ2 - 2, 0, World.inst.GridHeight - 1);
				maxZ2 = Mathff.Clamp(maxZ2 + 2, 0, World.inst.GridHeight - 1);
				for (int m = minZ2; m <= maxZ2; m++)
				{
					for (int n = minX2; n <= maxX2; n++)
					{
						Vector3 a2 = new Vector3((float)n + 0.5f, 0f, (float)m + 0.5f);
						int num7 = 0;
						while (num7 < legionGroup.numCells)
						{
							if (!(Mathff.DistSqrdXZ(a2, legionCells2[legionGroup.cells[num7]].position) < num5))
							{
								if (Mathff.DistSqrdXZ(a2, legionCells2[legionGroup.cells[num7]].position) < num6)
								{
									flag4 = true;
								}
								num7++;
								continue;
							}
							goto IL_07c2;
						}
					}
					continue;
					IL_07c2:
					flag3 = true;
					break;
				}
				if (flag3 && TeamID() == 1)
				{
					RaiderSystem.UnitData unitDataFor = RaiderSystem.inst.GetUnitDataFor(this);
					if (unitDataFor != null && unitDataFor.objective != null && !unitDataFor.objective.completed)
					{
						switch (unitDataFor.objective.type)
						{
						case RaiderSystem.ObjectiveType.StartFire:
						{
							Cell cell2 = building3.GetCell();
							FireManager.inst.StartFireAt(cell2);
							RaiderSystem.inst.OnPerformedFire(this);
							ThrowTorchesAtBuilding(cell2.Center3D);
							SfxSystem.inst.PlayFromBankIfVisibleOneShot("Viking_Torch_Throw", GetPos());
							break;
						}
						case RaiderSystem.ObjectiveType.StealResources:
						{
							LandmassOwner landmassOwner = World.GetLandmassOwner(building3.TeamID());
							if (landmassOwner != null)
							{
								int num8 = Mathff.Min(landmassOwner.Gold, 100);
								if (num8 > 0)
								{
									landmassOwner.Gold -= num8;
									teamOfStolenGold = landmassOwner.teamId;
									stolenGold = num8;
									rText = GameUI.inst.ResourceText.Create(ResourceAmount.Make(4, num8).ToString());
									ResourceTextStackManager.inst.ShowResourceAmount(building3, building3.Center(), 4, -num8);
									RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_select_taxoffice", building3.Center());
								}
								RaiderSystem.inst.OnPerformedTheft(this);
							}
							break;
						}
						}
					}
				}
				else if (flag4)
				{
					RaiderSystem.UnitData unitDataFor2 = RaiderSystem.inst.GetUnitDataFor(this);
					if (unitDataFor2 != null && unitDataFor2.objective != null && !unitDataFor2.objective.completed && unitDataFor2.objective.type == RaiderSystem.ObjectiveType.StartFire && !hasThrownInitialTorches)
					{
						Cell cellData = World.inst.GetCellData(unitDataFor2.objective.targetCellX, unitDataFor2.objective.targetCellZ);
						if (cellData != null)
						{
							ThrowTorchesAtBuilding(cellData.Center3D);
							hasThrownInitialTorches = true;
						}
					}
				}
			}
			if (frameCount % frameSpread == updateFrame && Mathff.DistSqrdXZ(GetPos(), mTarget.GetPos()) > 0.5f)
			{
				MoveTo(mTarget);
			}
		}
		PLAYBACK_STATE state2;
		if (legionGroup.AttackTargetId != -1)
		{
			PLAYBACK_STATE state;
			if (!eFightAmb.isValid())
			{
				eFightAmb = RuntimeManager.CreateInstance("event:/SFX ASITP/sfx_combat_lp");
				eFightAmb.start();
				eFightAmb.release();
			}
			else if (eFightAmb.getPlaybackState(out state) == RESULT.OK && state != PLAYBACK_STATE.PLAYING)
			{
				eFightAmb.start();
			}
			eFightAmb.set3DAttributes(GetPos().To3DAttributes());
		}
		else if (eFightAmb.isValid() && eFightAmb.getPlaybackState(out state2) == RESULT.OK && state2 == PLAYBACK_STATE.PLAYING)
		{
			eFightAmb.stop(STOP_MODE.ALLOWFADEOUT);
		}
	}

	private unsafe void TryApplyDamageToBuildingAndUnits()
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		for (int i = 0; i < legionGroup.numCells; i++)
		{
			LegionCell legionCell = LegionSystem.Inst.legionCells[legionGroup.cells[i]];
			if (legionCell.attackBuildingX != -1)
			{
				Cell cellData = World.inst.GetCellData(legionCell.attackBuildingX, legionCell.attackBuildingZ);
				for (int j = 0; j < cellData.OccupyingStructure.Count; j++)
				{
					if (!DamProjectManager.inst.IsCellPartOfProject(cellData.OccupyingStructure[j].GetCell(), out var _) && cellData.OccupyingStructure[j].categoryHash != World.pathHash)
					{
						cellData.OccupyingStructure[j].TakeProjectileDamage(LegionSystem.Inst.DamageToBuilding, DamageType.Standard, DamageSource.Melee, legionCell.position, Vector3.zero, legionGroup.team);
					}
				}
			}
			if (legionCell.attackingCellId != -1 && legionGroup.dead == 0)
			{
				Vector3 pos = Vector3.Lerp(LegionSystem.Inst.legionCells[legionCell.attackingCellId].position, legionCell.position, 0.25f) + (SRand.insideUnitSquareXZ * 0.5f + new Vector3(0f, -0.2f, 0f));
				EffectsMan.inst.GibsEffect.CreateAndPlay(pos);
			}
		}
	}

	private unsafe void ThrowTorchesAtBuilding(Vector3 pos)
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		Vector3 ePos = pos;
		for (int i = 0; i < legionGroup.numCells; i++)
		{
			ref float x = ref ePos.x;
			ref float z = ref ePos.z;
			float num = pos.x + SRand.Range(-0.2f, 0.2f);
			float num2 = pos.z + SRand.Range(-0.2f, 0.2f);
			x = num;
			z = num2;
			Torch.Create(LegionSystem.Inst.legionCells[legionGroup.cells[i]].position, ePos, doVariance: true);
		}
	}

	public bool IsDead()
	{
		return LegionSystem.Inst.groups[groupID].dead == 1;
	}

	public unsafe void SetPos(Vector3 pos)
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		for (int i = 0; i < legionGroup.numCells; i++)
		{
			LegionCell value = LegionSystem.Inst.legionCells[legionGroup.cells[i]];
			value.position = pos;
			LegionSystem.Inst.legionCells[legionGroup.cells[i]] = value;
		}
	}

	public Vector3 GetPos()
	{
		return LegionSystem.Inst.legionCells[LegionSystem.Inst.groups[groupID].leaderCellId].position;
	}

	public Vector3 GetDestPos()
	{
		return LegionSystem.Inst.groups[groupID].desiredPosition;
	}

	public Vector3 GetToNextCell()
	{
		return Vector3.zero;
	}

	public bool IsBlockingCell()
	{
		return false;
	}

	public int GetLOS()
	{
		return 0;
	}

	public int GetAttackType()
	{
		return 0;
	}

	public void OnUnitTargetsUs(IUnitControllable u)
	{
	}

	public void OnUnitStoppedTargetingUs(IUnitControllable u)
	{
	}

	public void NotifyOtherUnitDeath(IUnitControllable u)
	{
	}

	public void DestroyUnit()
	{
		if (unitUI != null)
		{
			UnityEngine.Object.Destroy(unitUI.gameObject);
		}
		unitUI = null;
		highlight.Release();
		highlight = null;
		if (rText != null)
		{
			rText.Release();
			rText = null;
		}
		LegionGroup legionGroup = GetGroup();
		if (stolenGold > 0 && teamOfStolenGold != -1 && legionGroup.dead == 1)
		{
			World.GetLandmassOwner(teamOfStolenGold).Gold += stolenGold;
			if (teamOfStolenGold == 0)
			{
				ResourceTextStackManager.inst.ShowResourceAmount(this, GetPos(), 4, stolenGold);
			}
		}
		if (eFightAmb.isValid())
		{
			eFightAmb.stop(STOP_MODE.IMMEDIATE);
		}
		LegionSystem.Inst.ReleaseGroup(groupID);
	}

	public bool CanAttack()
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		if (legionGroup.dead == 0 && legionGroup.isBeingCarried == 0)
		{
			return legionGroup.inUse == 1;
		}
		return false;
	}

	public bool CanCarry()
	{
		return false;
	}

	public bool CanBeCarried()
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		if (legionGroup.dead == 0 && legionGroup.isBeingCarried == 0)
		{
			return legionGroup.inUse == 1;
		}
		return false;
	}

	public bool TryBeCarried()
	{
		LegionGroup value = LegionSystem.Inst.groups[groupID];
		if (value.isBeingCarried == 1 || value.dead == 1 || value.inUse == 0)
		{
			return false;
		}
		value.isBeingCarried = 1;
		LegionSystem.Inst.groups[groupID] = value;
		if (rText != null)
		{
			rText.Release();
			rText = null;
		}
		mTarget = null;
		return true;
	}

	public void StopBeingCarried()
	{
		LegionGroup value = LegionSystem.Inst.groups[groupID];
		value.isBeingCarried = 0;
		LegionSystem.Inst.groups[groupID] = value;
	}

	public bool IsBeingCarried()
	{
		return LegionSystem.Inst.groups[groupID].isBeingCarried == 1;
	}

	public bool IsPendingLoadTargets()
	{
		return false;
	}

	public int GetRemainingCapacity()
	{
		return 0;
	}

	public int CarryCount()
	{
		return 0;
	}

	public IUnitControllable GetCarried(int i)
	{
		return null;
	}

	public float CurrHealth()
	{
		return LegionSystem.Inst.groups[groupID].pep;
	}

	public float MaxHealth()
	{
		return LegionSystem.Inst.groups[groupID].origNumCells;
	}

	public unsafe void Disband()
	{
		LegionGroup legionGroup = GetGroup();
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
			}
		}
		UnitSystem.inst.DestroyUnit(this);
	}

	public bool PendingCarry(IUnitControllable toLoad)
	{
		return false;
	}

	public Guid GetGuid()
	{
		return LegionSystem.Inst.groups[groupID].guid;
	}

	public void DoUnload(IUnitControllable u)
	{
	}

	public bool ExclusiveSelect()
	{
		return false;
	}

	public bool ValidToSelect()
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		if (legionGroup.inUse == 1 && legionGroup.dead == 0)
		{
			return legionGroup.isBeingCarried == 0;
		}
		return false;
	}

	public void SetHighlightImmediate(int colorIdx)
	{
		highlight.SetOutlineImmediate(colorIdx);
	}

	public void OnSelected()
	{
	}

	public unsafe bool InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		for (int i = 0; i < legionGroup.numCells; i++)
		{
			LegionCell legionCell = LegionSystem.Inst.legionCells[legionGroup.cells[i]];
			if (legionCell.position.x > (float)minx && legionCell.position.x < (float)(maxx + 1) && legionCell.position.z > (float)minz && legionCell.position.z < (float)(maxz + 1))
			{
				return true;
			}
		}
		return false;
	}

	public unsafe bool IntersectsRay(Ray ray, out float hitDist)
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		bool result = false;
		float num = float.MaxValue;
		for (int i = 0; i < legionGroup.numCells; i++)
		{
			if (Mathff.RaySphereIntersect(ray, LegionSystem.Inst.legionCells[legionGroup.cells[i]].position, 1f, out var hitDist2) && hitDist2 < num)
			{
				result = true;
				num = hitDist2;
			}
		}
		hitDist = num;
		return result;
	}

	public unsafe bool TestPlanesAABB(Plane[] planes)
	{
		LegionGroup legionGroup = LegionSystem.Inst.groups[groupID];
		for (int i = 0; i < legionGroup.numCells; i++)
		{
			Bounds bounds = new Bounds(LegionSystem.Inst.legionCells[legionGroup.cells[i]].position, Vector3.one);
			if (GeometryUtility.TestPlanesAABB(planes, bounds))
			{
				return true;
			}
		}
		return false;
	}

	public int GetUnitType()
	{
		return LegionSystem.Inst.groups[groupID].type;
	}

	public int TeamID()
	{
		return LegionSystem.Inst.groups[groupID].team;
	}

	public int GetMoveType()
	{
		return 0;
	}

	public unsafe void MoveTo(IMoveTarget target)
	{
		LegionGroup value = LegionSystem.Inst.groups[groupID];
		mTarget = target;
		if (value.isBeingCarried == 1 || value.dead == 1)
		{
			return;
		}
		float num = Vector3.Distance(target.GetPos(), GetPos());
		float time = Mathff.Clamp(Mathff.Lerp(0f, 2f, num / 4f), 0f, 2f);
		if (target is Cell || target is UnitControlSystem.StaticPosMoveTarget || target is Building)
		{
			value.AttackTargetId = -1;
			for (int i = 0; i < value.numCells; i++)
			{
				LegionCell value2 = LegionSystem.Inst.legionCells[value.cells[i]];
				value2.attackingCellId = -1;
				value2.spearTargetCellId = -1;
				LegionSystem.Inst.legionCells[value.cells[i]] = value2;
			}
		}
		value.recuperating = 0;
		if (target is Building building && building.GetComponent<RomanBarracks>()?.GetOccupyingUnit() == this)
		{
			value.recuperating = 1;
		}
		value.movingToPosition = true;
		value.desiredPosition = target.GetPredictedPosition(time);
		if (Mathff.DistSqrd(LegionSystem.Inst.legionCells[value.leaderCellId].position, value.desiredPosition) > 0.010000001f)
		{
			value.needsPathing = true;
		}
		else
		{
			LegionSystem.Inst.nextPositions[value.id] = new LegionSystem.JobPathNode
			{
				waypoint = value.desiredPosition,
				lastNode = true,
				index = 0
			};
		}
		LegionSystem.Inst.groups[groupID] = value;
	}

	public IMoveTarget GetMoveTarget()
	{
		return mTarget;
	}

	public float GetRadius()
	{
		return 1f;
	}

	public Vector3 GetPosition()
	{
		return GetPos();
	}

	public Vector3 GetVelocity()
	{
		return Vector3.zero;
	}

	public Vector3 GetPredictedPosition(float time)
	{
		LegionGroup legionGroup = GetGroup();
		LegionCell legionCell = LegionSystem.Inst.legionCells[legionGroup.leaderCellId];
		return legionCell.position + legionCell.velocity * time;
	}

	public HitSfxResult TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int attackerTeamID)
	{
		LegionGroup attackTarget = GetGroup();
		LegionSystem.TakeDamage(attackTarget, LegionSystem.Inst.legionCells[attackTarget.leaderCellId], dmg / 25f, LegionSystem.Inst.legionCells, LegionSystem.Inst.groups, attackerTeamID);
		Vector3 pos = LegionSystem.Inst.legionCells[attackTarget.leaderCellId].position + (SRand.insideUnitSquareXZ + new Vector3(0f, 0f, 0f));
		EffectsMan.inst.GibsEffect.CreateAndPlay(pos);
		return HitSfxResult.None;
	}

	public bool IsInvalid()
	{
		LegionGroup legionGroup = GetGroup();
		if (legionGroup.inUse != 0)
		{
			return legionGroup.dead == 1;
		}
		return true;
	}
}
