using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using Assets.Code;
using I2.Loc;
using UnityEngine;
using UnityEngine.Rendering;

public class ArmySystem : MonoBehaviour
{
	public enum MoveStatus
	{
		NotComplete,
		Complete,
		Failed
	}

	public enum ArmyType
	{
		Default,
		Thief,
		Archer,
		Envoy,
		Settler,
		Elite
	}

	public enum ArmyBehavior
	{
		Hold,
		Attack,
		Pursue
	}

	public class Army : IProjectileHitable, ISelectable, IMoveTarget, IMoveableUnit, ICamTrackable
	{
		public enum GeneralStatus
		{
			Following,
			AttackingUnit,
			FallingDeath,
			Dying
		}

		public ArmyDef armyDef;

		internal Vector3 toNext;

		public bool playerDidDamage;

		[NonSerialized]
		public int teamId;

		[NonSerialized]
		public Transform general;

		internal General generalComponent;

		[NonSerialized]
		public bool pathBlocked;

		[NonSerialized]
		public bool pathBlockedImmediate;

		[NonSerialized]
		public float attackRange;

		[NonSerialized]
		public float generalTotalTime;

		[NonSerialized]
		public float generalAngle;

		[NonSerialized]
		public float generalLife;

		[NonSerialized]
		public string generalName;

		[NonSerialized]
		public GeneralStatus generalStatus;

		[NonSerialized]
		public float stateTime;

		[NonSerialized]
		public float generalAttackTime;

		[NonSerialized]
		public float speed = 1.75f;

		[NonSerialized]
		public Guid guid = Guid.NewGuid();

		[NonSerialized]
		public Vector3 fwd;

		[NonSerialized]
		public Vector3 right;

		[NonSerialized]
		public bool locked;

		[NonSerialized]
		public float speedMod = 1f;

		[NonSerialized]
		public bool doShowPath;

		[NonSerialized]
		public IMoveTarget moveTarget;

		[NonSerialized]
		public IMoveTarget playerSetMoveTarget;

		[NonSerialized]
		public Timer moveTimer = new Timer(1.25f);

		[NonSerialized]
		public GamePath deferredPath = new GamePath();

		[NonSerialized]
		public ArmyType armyType;

		[NonSerialized]
		public int stolenResourceAmount;

		[NonSerialized]
		public int stolenResourceType = -1;

		[NonSerialized]
		public ResourceText resourceText;

		[NonSerialized]
		public bool moving;

		[NonSerialized]
		public bool tryRecooperate;

		[NonSerialized]
		public Vector3 fallVel;

		[NonSerialized]
		public float burnTimer;

		[NonSerialized]
		public ArmyBehavior armyBehavior;

		[NonSerialized]
		public ArrayExt<Unit> units = new ArrayExt<Unit>(10);

		[NonSerialized]
		public ArrayExt<Vector3> path = new ArrayExt<Vector3>(32);

		[NonSerialized]
		public int pathIdx;

		[NonSerialized]
		public ArrayExt<Villager> nearbyVillagers = new ArrayExt<Villager>(50);

		public bool villagerCacheFresh;

		[NonSerialized]
		public ArrayExt<Building> nearbyBuildings = new ArrayExt<Building>(9);

		public bool buildingCacheFresh;

		private Cell[] scratchNeighbors = new Cell[8];

		[NonSerialized]
		public ArrayExt<Army> neighborGroups = new ArrayExt<Army>(20);

		[NonSerialized]
		public ArrayExt<IProjectileHitable> adjacentEnemies = new ArrayExt<IProjectileHitable>(9);

		[NonSerialized]
		public Vector3 tilePos;

		[NonSerialized]
		public Vector3 generalPos;

		[NonSerialized]
		public MoveStatus moveStatus = MoveStatus.Complete;

		[NonSerialized]
		public float meleeRange = 1.5f;

		[NonSerialized]
		public int lastAttackerTeamID = -1;

		[NonSerialized]
		public int squadSize;

		[NonSerialized]
		public Vector3[] tilePosOffsets;

		[NonSerialized]
		public bool blocking;

		[NonSerialized]
		public IProjectileHitable attackTarget;

		[NonSerialized]
		public bool isAutoTargeting;

		bool IMoveTarget.IsStationary()
		{
			return false;
		}

		public override bool Equals(object obj)
		{
			if (obj == null && general == null)
			{
				return true;
			}
			return base.Equals(obj);
		}

		public MoveType GetMoveType()
		{
			return MoveType.Land;
		}

		public UnitType GetUnitType()
		{
			return UnitType.Army;
		}

		public AttackType GetAttackType()
		{
			if (armyType == ArmyType.Archer)
			{
				return AttackType.Ranged;
			}
			return AttackType.Melee;
		}

		public int GetLOS()
		{
			if (armyType == ArmyType.Envoy)
			{
				return 13;
			}
			return 9;
		}

		public bool IsBlockingCell()
		{
			if (!pathBlockedImmediate && !blocking)
			{
				return adjacentEnemies.Count > 0;
			}
			return true;
		}

		public Vector3 GetToNextCell()
		{
			if (Mathff.MagnitudeSqrdXZ(toNext) > 0f)
			{
				return toNext;
			}
			if (attackTarget != null && !attackTarget.Equals(null))
			{
				Vector3 result = attackTarget.GetPosition() - generalPos;
				result.Normalize();
				return result;
			}
			return toNext;
		}

		public int TeamID()
		{
			return teamId;
		}

		void IMoveableUnit.MoveTo(IMoveTarget target)
		{
			if (tryRecooperate)
			{
				return;
			}
			if (target is Building)
			{
				Building building = target as Building;
				if (building.categoryHash == World.pathHash || building.uniqueNameHash == World.rubbleHash)
				{
					target = building.GetCell();
				}
			}
			moveTarget = target;
			moveStatus = MoveStatus.NotComplete;
			if (!LoadSave.Loading)
			{
				doShowPath = true;
			}
			inst.SetArmyFacing(this, target.GetPos());
			inst.UpdatePathing(this);
		}

		IMoveTarget IMoveableUnit.GetMoveTarget()
		{
			return moveTarget;
		}

		public int FormationIdx()
		{
			if (armyType == ArmyType.Archer)
			{
				return 1;
			}
			return 0;
		}

		void IMoveableUnit.NotifyOtherUnitDeath(IMoveableUnit u)
		{
			if (moveTarget == u)
			{
				moveTarget = null;
			}
		}

		bool IMoveableUnit.IsFullCapacity()
		{
			return false;
		}

		bool IMoveableUnit.CanCarry()
		{
			return false;
		}

		bool IMoveableUnit.IsPendingLoadTargets()
		{
			return false;
		}

		bool IMoveableUnit.PendingCarry(IMoveableUnit u)
		{
			return false;
		}

		bool IMoveableUnit.IsBeingCarried()
		{
			return locked;
		}

		int IMoveableUnit.GetRemainingCapacity()
		{
			return 0;
		}

		int IMoveableUnit.CarryCount()
		{
			return 0;
		}

		IMoveableUnit IMoveableUnit.GetCarried(int i)
		{
			return null;
		}

		void IMoveableUnit.DoUnload(IMoveableUnit u)
		{
		}

		void IMoveableUnit.OnUnitTargetsUs(IMoveableUnit u)
		{
		}

		void IMoveableUnit.OnUnitStoppedTargetingUs(IMoveableUnit u)
		{
		}

		Guid IMoveableUnit.GetGuid()
		{
			return guid;
		}

		public Vector3 GetDestPos()
		{
			if (deferredPath.status == GamePath.Status.Finding)
			{
				return deferredPath.end;
			}
			if (path.Count <= 0)
			{
				return tilePos;
			}
			return path.data[path.Count - 1];
		}

		public Vector3 GetPos()
		{
			return generalPos;
		}

		public void SetPos(Vector3 pos)
		{
			inst.SetGeneralPos(this, pos);
			int i = 0;
			for (int count = units.Count; i < count; i++)
			{
				units.data[i].targetPos = pos + tilePosOffsets[i % squadSize] + new Vector3(SRand.Range(-0.05f, 0.05f), 0f, SRand.Range(0.05f, 0.05f));
			}
		}

		public bool TryBeCarried()
		{
			if (inst.IsAlive(this))
			{
				inst.LockArmy(this);
				return true;
			}
			return false;
		}

		public void StopBeingCarried()
		{
			inst.UnlockArmy(this);
		}

		public bool CanBeCarried()
		{
			return true;
		}

		public bool CanAttack()
		{
			if (armyType != ArmyType.Settler)
			{
				return armyType != ArmyType.Envoy;
			}
			return false;
		}

		public bool ExclusiveSelect()
		{
			return false;
		}

		public bool ValidToSelect()
		{
			if (!locked)
			{
				return inst.IsAlive(this);
			}
			return false;
		}

		void ISelectable.SetHighlightImmediate(int colorIdx)
		{
			if (armyType == ArmyType.Envoy && colorIdx == 2)
			{
				colorIdx = 0;
			}
			if (armyType == ArmyType.Envoy && general.GetComponent<Envoy>().issueButton.highlighter != null)
			{
				general.GetComponent<Envoy>().issueButton.highlighter.SetOutlineImmediate(colorIdx);
			}
			generalComponent.generalHighlight.SetOutlineImmediate(colorIdx);
		}

		void ISelectable.OnSelected()
		{
			if (armyType == ArmyType.Default)
			{
				SfxSystem.inst.PlayFromBank("ArmyGeneralSelect", general.position);
			}
			if (armyType == ArmyType.Archer)
			{
				SfxSystem.inst.PlayFromBank("ArcherUnitSelect", general.position);
			}
			if (armyType == ArmyType.Envoy)
			{
				SfxSystem.inst.PlayFromBank("EnvoySelect", general.position);
				general.GetComponent<Envoy>().OnSelected();
			}
		}

		bool ISelectable.InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
		{
			Vector3 vector = generalPos;
			if ((float)minx <= vector.x && vector.x <= (float)maxx && (float)minz <= vector.z)
			{
				return vector.z <= (float)maxz;
			}
			return false;
		}

		public bool IsInvalid()
		{
			if (inst.IsAlive(this))
			{
				return locked;
			}
			return true;
		}

		float IProjectileHitable.GetRadius()
		{
			return 0.5f;
		}

		Vector3 IProjectileHitable.GetPosition()
		{
			return generalPos;
		}

		Vector3 IProjectileHitable.GetVelocity()
		{
			return Vector3.zero;
		}

		public Vector3 GetPredictedPosition(float time)
		{
			return generalPos;
		}

		HitSfxResult IProjectileHitable.TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int teamID)
		{
			if (teamID == 0)
			{
				playerDidDamage = true;
			}
			if (units.Count > 0)
			{
				switch (dmgType)
				{
				case DamageType.Standard:
					((IProjectileHitable)units.RandomElement()).TakeProjectileDamage(dmg, DamageType.Standard, dmgSource, sourcePos, incomingVel, teamID);
					break;
				case DamageType.AOE:
				{
					float num = dmg;
					for (int i = 0; i < units.Count; i++)
					{
						float life = units.data[i].life;
						float num2 = num - life;
						if (num2 <= 0f)
						{
							units.data[i].TakeProjectileDamage(num, DamageType.Standard, dmgSource, sourcePos, incomingVel, teamID);
							break;
						}
						units.data[i].TakeProjectileDamage(life, DamageType.Standard, dmgSource, sourcePos, incomingVel, teamID);
						num = num2;
					}
					break;
				}
				}
			}
			else
			{
				TakeGeneralDamage(dmg, teamID);
			}
			return HitSfxResult.None;
		}

		public void TakeGeneralDamage(float dmg, int attackerTeamID)
		{
			if (StreamerEffects.Flag_StrongerEnemies && teamId == 1)
			{
				dmg /= 2f;
			}
			if (StreamerEffects.Flag_StrongerArmies && teamId == 0)
			{
				dmg /= 2f;
			}
			LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(attackerTeamID);
			if (landmassOwnerByTeamId != null && landmassOwnerByTeamId.hazardPay)
			{
				dmg *= (float)landmassOwnerByTeamId.hazardPayMultiplier;
			}
			generalLife -= dmg;
			lastAttackerTeamID = attackerTeamID;
		}

		public float CurrHealth()
		{
			int armyHealth = 0;
			int armyHealthMax = 0;
			inst.CalculateMinMaxHealth(this, ref armyHealth, ref armyHealthMax);
			return armyHealth;
		}

		public float MaxHealth()
		{
			int armyHealth = 0;
			int armyHealthMax = 0;
			inst.CalculateMinMaxHealth(this, ref armyHealth, ref armyHealthMax);
			return armyHealthMax;
		}

		public void Disband()
		{
			for (int i = 0; i < units.Count; i++)
			{
				Vector3 pos = units.data[i].pos;
				if (armyType != ArmyType.Settler && armyType != ArmyType.Envoy && SRand.Range(0, 100) > 50)
				{
					FreeResourceManager.inst.GetAutoStackFor(7, 1, pos);
				}
				Player.inst.AddVillager(pos);
			}
			inst.ReleaseArmy(this);
		}

		public void DestroyUnit()
		{
			inst.ReleaseArmy(this);
		}

		public void Recooperate()
		{
			tryRecooperate = true;
			inst.TryRecooperate(this);
			inst.UpdatePathing(this);
		}

		public ArrayExt<Villager> GetNearbyVillagers()
		{
			if (!villagerCacheFresh)
			{
				villagerCacheFresh = true;
				nearbyVillagers.Clear();
				int num = (int)Mathff.Clamp(tilePos.x - 1f, 0f, World.inst.GridWidth - 1);
				int num2 = (int)Mathff.Clamp(tilePos.z - 1f, 0f, World.inst.GridHeight - 1);
				int num3 = (int)Mathff.Clamp(tilePos.x + 1f, 0f, World.inst.GridWidth - 1);
				int num4 = (int)Mathff.Clamp(tilePos.z + 1f, 0f, World.inst.GridHeight - 1);
				for (int i = num; i <= num3; i++)
				{
					for (int j = num2; j <= num4; j++)
					{
						ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(i, j);
						int k = 0;
						for (int count = villagersAt.Count; k < count; k++)
						{
							Villager villager = villagersAt.data[k];
							if (villager.cell == null)
							{
								continue;
							}
							bool flag = false;
							for (int l = 0; l < villager.cell.OccupyingStructure.Count; l++)
							{
								Building building = villager.cell.OccupyingStructure[l];
								int uniqueNameHash = building.uniqueNameHash;
								int categoryHash = building.categoryHash;
								if (uniqueNameHash == World.castleblockHash || uniqueNameHash == World.woodcastleblockHash || categoryHash == World.gateHash)
								{
									flag = true;
									break;
								}
							}
							if (!flag && !inst.markedVillagers.Contains(villager))
							{
								nearbyVillagers.Add(villager);
								break;
							}
						}
					}
				}
			}
			return nearbyVillagers;
		}

		public ArrayExt<Building> GetNearbyBuildings()
		{
			if (!buildingCacheFresh)
			{
				buildingCacheFresh = true;
				nearbyBuildings.Clear();
				Cell cellData = World.inst.GetCellData(generalPos);
				if (cellData != null)
				{
					for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
					{
						Building building = cellData.OccupyingStructure[i];
						if (!ShouldIgnoreViking(building))
						{
							nearbyBuildings.Add(building);
						}
					}
					World.inst.GetNeighborCellsExtended(cellData, ref scratchNeighbors);
					int j = 0;
					for (int num = scratchNeighbors.Length; j < num; j++)
					{
						if (scratchNeighbors[j] == null)
						{
							continue;
						}
						List<Building> occupyingStructure = scratchNeighbors[j].OccupyingStructure;
						for (int k = 0; k < occupyingStructure.Count; k++)
						{
							if (!ShouldIgnoreViking(occupyingStructure[k]))
							{
								nearbyBuildings.Add(occupyingStructure[k]);
							}
						}
					}
				}
			}
			return nearbyBuildings;
		}

		private bool ShouldIgnoreViking(Building b)
		{
			if (b.uniqueNameHash == World.keepHash && Player.inst.difficulty != Player.Difficulty.Survival && b.TeamID() == 0)
			{
				return true;
			}
			if (b.categoryHash != World.rubbleHash && b.categoryHash != World.pathHash && b.categoryHash != World.cemeteryHash && b.uniqueNameHash != World.outpostHash && !b.SubStructure)
			{
				return b.IsDestroyed();
			}
			return true;
		}

		public bool IntersectsRay(Ray ray, out float hitDist)
		{
			hitDist = float.MaxValue;
			float num = 0.5f;
			Vector3 position = general.position;
			if (Mathff.RaySphereIntersect(ray, position, num) || Mathff.RaySphereIntersect(ray, position + new Vector3(0f, num, 0f), num * 0.9f) || Mathff.RaySphereIntersect(ray, position + new Vector3(0f, num * 0.9f * 2f, 0f), num * 0.8f) || Mathff.RaySphereIntersect(ray, position + new Vector3(0f, num * 0.8f * 3f, 0f), num * 0.7f))
			{
				hitDist = Mathff.Dist(position, ray.origin) - num;
				return true;
			}
			return false;
		}

		public Vector3 GetDesiredTrackingPos()
		{
			return generalPos;
		}
	}

	public class Unit : IProjectileHitable
	{
		public enum Status
		{
			Following,
			Attacking,
			Dying,
			QuickDying,
			Kidnapping
		}

		public enum Type
		{
			Footman,
			Kidnapper
		}

		public Quaternion weaponRot;

		public Quaternion rot;

		public Vector3 pos;

		public Vector3 targetPos;

		public Vector3 velocity;

		public float currHeight;

		public Type type;

		public Status status;

		public float reactTime;

		public float totalTime;

		public Army army;

		public float stateTime;

		public float life;

		public bool inUse;

		public bool visible = true;

		public Villager kidnapTarget;

		public bool kidnapCompleted;

		public int kidnapLandmass;

		public bool IsInvalid()
		{
			if (status != Status.Dying && status != Status.QuickDying && !(life <= 0f))
			{
				return army == null;
			}
			return true;
		}

		public float GetRadius()
		{
			return 0.3f;
		}

		public Vector3 GetPosition()
		{
			return pos;
		}

		public Vector3 GetVelocity()
		{
			return velocity;
		}

		public Vector3 GetPredictedPosition(float time)
		{
			return pos + velocity * time;
		}

		public HitSfxResult TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int attackerTeamID)
		{
			if (attackerTeamID == 0)
			{
				army.playerDidDamage = true;
			}
			if (StreamerEffects.Flag_StrongerEnemies && army.teamId == 1)
			{
				dmg /= 2f;
			}
			if (StreamerEffects.Flag_StrongerArmies && army.teamId == 0)
			{
				dmg /= 2f;
			}
			LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(attackerTeamID);
			if (landmassOwnerByTeamId != null && landmassOwnerByTeamId.hazardPay)
			{
				dmg *= (float)landmassOwnerByTeamId.hazardPayMultiplier;
			}
			if (life > 0f && life - dmg <= 0f)
			{
				if (landmassOwnerByTeamId != null && SRand.Range(0, 100) < 15)
				{
					for (int i = 0; i < landmassOwnerByTeamId.ownedLandMasses.Count; i++)
					{
						Player.inst.AddHappinessMod("combatvictory", SeasonManager.inst.TimeInYear(), 1, ScriptLocalization.ProudOfTroopsInCombat, landmassOwnerByTeamId.ownedLandMasses.data[i], addition: true, 10);
					}
				}
				LandmassOwner landmassOwnerByTeamId2 = World.GetLandmassOwnerByTeamId(army.teamId);
				if (landmassOwnerByTeamId2 != null && SRand.Range(0, 100) < 25)
				{
					for (int j = 0; j < landmassOwnerByTeamId2.ownedLandMasses.Count; j++)
					{
						Player.inst.AddHappinessMod("combatdeath", SeasonManager.inst.TimeInYear(), -1, "I2.Loc.ScriptLocalization.SaddenedByCombatDeaths", landmassOwnerByTeamId2.ownedLandMasses.data[j], addition: true, 0, -30);
					}
				}
			}
			life -= dmg;
			return HitSfxResult.None;
		}
	}

	[Serializable]
	public class ArmyDef
	{
		public Transform generalPrefab;

		public Vector3 weaponLocalOffset;

		public Mesh mesh;

		public Mesh weaponMesh;

		public float unitLife;

		public float generalLife;

		public ArmyType type;
	}

	[Serializable]
	public class UnitCategory
	{
		[NonSerialized]
		public Unit[] units = new Unit[1023];

		[NonSerialized]
		public Matrix4x4[] matrices = new Matrix4x4[1023];

		[NonSerialized]
		public Matrix4x4[] weapons = new Matrix4x4[1023];

		public Vector3 weaponLocalOffset;

		public Mesh mesh;

		public Mesh weaponMesh;

		public Material mat;

		public Material unlitMat;

		public float life;

		public float generalLife;

		[NonSerialized]
		public ArmyType type;

		[NonSerialized]
		public int teamId;

		[NonSerialized]
		public ArmyDef armyDef;
	}

	[Serializable]
	private struct ArmySaveData
	{
		public int teamId;

		public SerializableVector3 generalPos;

		public SerializableVector3 fwd;

		public SerializableVector3 right;

		public float generalLife;

		public float generalAngle;

		[OptionalField(VersionAdded = 2)]
		public string generalName;

		[OptionalField(VersionAdded = 3)]
		public Guid guid;

		[OptionalField(VersionAdded = 3)]
		public bool locked;

		[OptionalField(VersionAdded = 3)]
		public SerializableVector3 moveTarget;

		[OptionalField(VersionAdded = 3)]
		public ArmyType at;

		[OptionalField(VersionAdded = 3)]
		public int unitCategory;

		[OptionalField(VersionAdded = 4)]
		public ArmyBehavior behavior;

		[OptionalField(VersionAdded = 4)]
		public SerializableVector3 playerSetMoveTarget;
	}

	[Serializable]
	public class UnitSystemSaveData : SaveClass<ArmySystem, UnitSystemSaveData>
	{
		[Serializable]
		private struct UnitSaveData
		{
			public SerializableVector3 position;

			public SerializableQuaternion quat;

			public Guid armyId;

			public int categoryNumber;

			public Unit.Type type;

			[OptionalField(VersionAdded = 2)]
			public Guid villagerId;

			public float life;

			public Guid kidnapTargetGuid;

			public bool kidnapCompleted;
		}

		[Serializable]
		private struct EnvoySave
		{
			public Guid guid;

			public ResourceAmount gift;
		}

		private List<UnitSaveData> units = new List<UnitSaveData>();

		private List<ArmySaveData> armies = new List<ArmySaveData>();

		private EnvoySave[] envoies;

		public override UnitSystemSaveData Pack(ArmySystem d)
		{
			int num = 0;
			for (int i = 0; i < d.armies.Count; i++)
			{
				Army army = d.armies.data[i];
				if (army.generalStatus == Army.GeneralStatus.FallingDeath)
				{
					continue;
				}
				ArmySaveData item = new ArmySaveData
				{
					teamId = army.teamId,
					fwd = army.fwd,
					right = army.right,
					generalPos = army.general.position,
					generalLife = army.generalLife,
					generalName = army.generalName,
					generalAngle = army.generalAngle,
					guid = army.guid,
					at = army.armyType,
					moveTarget = ((army.path.Count > 0) ? army.path.data[army.path.Count - 1] : army.tilePos),
					behavior = army.armyBehavior
				};
				if (army.playerSetMoveTarget != null && !army.playerSetMoveTarget.Equals(null))
				{
					item.playerSetMoveTarget = army.playerSetMoveTarget.GetPos();
				}
				else
				{
					item.playerSetMoveTarget = default;
				}
				if (item.at == ArmyType.Envoy)
				{
					num++;
				}
				armies.Add(item);
				for (int j = 0; j < army.units.Count; j++)
				{
					Unit unit = army.units.data[j];
					UnitSaveData item2 = new UnitSaveData
					{
						position = unit.pos,
						quat = unit.rot,
						life = unit.life,
						kidnapCompleted = unit.kidnapCompleted
					};
					if (unit.kidnapTarget != null)
					{
						item2.kidnapTargetGuid = unit.kidnapTarget.guid;
					}
					else
					{
						item2.kidnapTargetGuid = Guid.Empty;
					}
					item2.type = unit.type;
					item2.armyId = army.guid;
					units.Add(item2);
				}
			}
			envoies = new EnvoySave[num];
			int num2 = 0;
			for (int k = 0; k < d.armies.Count; k++)
			{
				Army army2 = d.armies.data[k];
				if (army2.armyType == ArmyType.Envoy)
				{
					EnvoySave envoySave = new EnvoySave
					{
						guid = army2.guid,
						gift = army2.general.GetComponent<Envoy>().giftAmount
					};
					envoies[num2] = envoySave;
					num2++;
				}
			}
			return this;
		}

		public override ArmySystem Unpack(ArmySystem d)
		{
			Vector3 zero = Vector3.zero;
			for (int i = 0; i < armies.Count; i++)
			{
				ArmySaveData armySaveData = armies[i];
				if (!Mathff.IsNaN(armySaveData.generalPos))
				{
					if (armySaveData.teamId == 1 && armySaveData.unitCategory == 0)
					{
						armySaveData.unitCategory = 1;
					}
					Army army = inst.MakeArmy(armySaveData.generalPos, armySaveData.teamId, armySaveData.at, addUnits: false);
					army.generalLife = armySaveData.generalLife;
					army.generalAngle = armySaveData.generalAngle;
					army.generalName = armySaveData.generalName;
					if (army.generalName == string.Empty)
					{
						army.generalName = "";
					}
					army.fwd = armySaveData.fwd;
					army.right = armySaveData.right;
					army.guid = armySaveData.guid;
					army.armyBehavior = armySaveData.behavior;
					if (armySaveData.playerSetMoveTarget == zero)
					{
						army.playerSetMoveTarget = null;
					}
					else
					{
						army.playerSetMoveTarget = World.inst.GetCellData(armySaveData.playerSetMoveTarget);
					}
				}
			}
			Army army2 = null;
			for (int j = 0; j < units.Count; j++)
			{
				UnitSaveData unitSaveData = units[j];
				Army army3 = inst.FindArmyByGuid(unitSaveData.armyId);
				if (army3 == null)
				{
					continue;
				}
				if (army3.units.Count > 16)
				{
					if (army2 == null || army2.units.Count > 16)
					{
						int num = (int)unitSaveData.position.x;
						int num2 = (int)unitSaveData.position.z;
						army2 = inst.MakeArmy(new Vector3(num, 0f, num2), army3.teamId, ArmyType.Default, addUnits: false);
					}
					army3 = army2;
				}
				UnitCategory category = inst.GetCategory(army3.armyType, army3.teamId);
				Unit unitFromCategory = inst.GetUnitFromCategory(category);
				inst.AddUnit(unitFromCategory, army3);
				unitFromCategory.type = unitSaveData.type;
				unitFromCategory.life = unitSaveData.life;
				unitFromCategory.kidnapCompleted = unitSaveData.kidnapCompleted;
				unitFromCategory.pos = unitSaveData.position;
				if (unitFromCategory.pos.x < -100f)
				{
					unitFromCategory.pos.x = -100f;
				}
				if (unitFromCategory.pos.x >= (float)(World.inst.GridWidth + 100))
				{
					unitFromCategory.pos.x = World.inst.GridWidth + 100;
				}
				if (unitFromCategory.pos.z < -100f)
				{
					unitFromCategory.pos.z = -100f;
				}
				if (unitFromCategory.pos.z >= (float)(World.inst.GridHeight + 100))
				{
					unitFromCategory.pos.z = World.inst.GridHeight + 100;
				}
				unitFromCategory.rot = unitSaveData.quat;
				unitFromCategory.kidnapTarget = Player.inst.GetWorker(unitSaveData.kidnapTargetGuid);
				if (unitFromCategory.kidnapTarget != null)
				{
					unitFromCategory.kidnapTarget.paralyzed = true;
				}
			}
			if (envoies != null)
			{
				for (int k = 0; k < envoies.Length; k++)
				{
					Army army4 = d.FindArmyByGuid(envoies[k].guid);
					if (army4 != null)
					{
						army4.general.GetComponent<Envoy>().giftAmount = envoies[k].gift;
					}
				}
			}
			return d;
		}
	}

	public float dropShadowHeight = 0.03f;

	private Vector3[] tilePosOffsets16 = new Vector3[16];

	private Vector3[] tilePosOffsets9 = new Vector3[9];

	private Vector3[] tilePosOffsets4 = new Vector3[4];

	public GameObject torchPrefab;

	[NonSerialized]
	public static ArmySystem inst;

	public ArrayExt<Army> armies = new ArrayExt<Army>(100);

	public List<ArmyDef> playerArmySet;

	public List<ArmyDef> vikingArmySet;

	private List<UnitCategory> unitCategoriesGen = new List<UnitCategory>();

	public float accel = 10f;

	public float drag = 1f;

	public float dragInteg = 0.1f;

	public float separationForce = 10f;

	public AnimationCurve attackCurve;

	public float generalBounceSpeed = 5f;

	public float generalBounceMagnitude = 0.03f;

	private bool[] scratchVisited;

	private ArrayExt<Cell> openSet = new ArrayExt<Cell>(50);

	private ArrayExt<TroopTransportShip> scratchShips = new ArrayExt<TroopTransportShip>(5);

	public AnimationCurve generalAttackLungeHeight;

	public float attackLungeScaleGeneral = 0.25f;

	private static int barracksHash = "barracks".GetHashCode();

	private static int archerSchoolHash = "archerschool".GetHashCode();

	public static float burnMaxTime = 25f;

	private int woodCastleblockHash = "woodcastleblock".GetHashCode();

	private int castleblockHash = "castleblock".GetHashCode();

	private int gateHash = "gate".GetHashCode();

	public List<Villager> markedVillagers = new List<Villager>();

	private ArrayExt<Villager> availableVillagers = new ArrayExt<Villager>(1000);

	private float unitSeparationRad = 0.22f;

	internal int loadTickDelay = 1;

	private void ResetUnit(Unit unit)
	{
		unit.rot = Quaternion.identity;
		unit.weaponRot = Quaternion.identity;
		unit.totalTime = SRand.Range(0f, 1f);
		unit.life = 5f;
		unit.status = Unit.Status.Following;
		unit.kidnapCompleted = false;
		unit.kidnapTarget = null;
	}

	public void CalculateMinMaxHealth(Army army, ref int armyHealth, ref int armyHealthMax)
	{
		armyHealth = 0;
		armyHealthMax = 0;
		armyHealthMax += (int)army.armyDef.unitLife * army.squadSize;
		for (int i = 0; i < army.units.Count; i++)
		{
			armyHealth += (int)Mathff.Clamp(army.units.data[i].life, 0f, army.armyDef.unitLife);
		}
		armyHealth += (int)Mathff.Clamp(army.generalLife, 0f, 50f);
		armyHealthMax += (int)army.armyDef.generalLife;
	}

	private void Start()
	{
		inst = this;
		int[] array = new int[16]
		{
			13, 6, 7, 14, 5, 0, 1, 8, 4, 3,
			2, 9, 12, 11, 10, 15
		};
		int[] array2 = new int[9] { 8, 1, 5, 4, 0, 2, 7, 3, 6 };
		int num = 0;
		for (int i = 0; i < 4; i++)
		{
			for (int j = 0; j < 4; j++)
			{
				tilePosOffsets16[array[num++]] = new Vector3(-0.5f + (float)i / 3f, 0f, -0.5f + (float)j / 3f) * 0.85f;
			}
		}
		num = 0;
		for (int k = 0; k < 3; k++)
		{
			for (int l = 0; l < 3; l++)
			{
				tilePosOffsets9[array2[num++]] = new Vector3(-0.5f + (float)k / 2f, 0f, -0.5f + (float)l / 2f) * 0.5f;
			}
		}
		tilePosOffsets4[0] = new Vector3(0.3f, 0f, 0f);
		tilePosOffsets4[1] = new Vector3(-0.3f, 0f, 0f);
		tilePosOffsets4[2] = new Vector3(0f, 0f, 0.3f);
		tilePosOffsets4[3] = new Vector3(0f, 0f, -0.3f);
		InitCategoriesGen();
	}

	internal void UpdateMaterialFor(int teamId, Material armyMaterial, Material unlitArmyMaterial)
	{
		for (int i = 0; i < unitCategoriesGen.Count; i++)
		{
			if (unitCategoriesGen[i].teamId == teamId)
			{
				unitCategoriesGen[i].mat = armyMaterial;
				unitCategoriesGen[i].unlitMat = unlitArmyMaterial;
			}
		}
		for (int j = 0; j < armies.Count; j++)
		{
			General generalComponent = armies.data[j].generalComponent;
			generalComponent.unitUI.UpdateMaterial(armies.data[j].teamId);
			generalComponent.UpdateMaterial(armies.data[j].teamId);
		}
	}

	public Army MakeArmy(Vector3 pos, int teamId, ArmyType at, bool addUnits)
	{
		Army army = new Army();
		army.armyType = at;
		army.generalName = "";
		army.teamId = teamId;
		if (army.armyType == ArmyType.Envoy)
		{
			army.squadSize = 4;
			army.tilePosOffsets = tilePosOffsets4;
		}
		else if (army.armyType == ArmyType.Archer || army.armyType == ArmyType.Elite)
		{
			army.squadSize = 9;
			army.tilePosOffsets = tilePosOffsets9;
		}
		else
		{
			army.squadSize = 16;
			army.tilePosOffsets = tilePosOffsets16;
		}
		if (at == ArmyType.Archer)
		{
			army.meleeRange = 0.5f;
		}
		if (at == ArmyType.Default && teamId == 0)
		{
			army.armyBehavior = ArmyBehavior.Attack;
		}
		if (at == ArmyType.Archer && teamId == 0)
		{
			army.armyBehavior = ArmyBehavior.Hold;
		}
		ArmyDef armyDef = null;
		if (teamId == 1)
		{
			army.speed = 0.8f;
			if (at == ArmyType.Thief)
			{
				army.speed = 1.2f;
			}
			for (int i = 0; i < vikingArmySet.Count; i++)
			{
				if (vikingArmySet[i].type == at)
				{
					armyDef = vikingArmySet[i];
					break;
				}
			}
		}
		else
		{
			for (int j = 0; j < playerArmySet.Count; j++)
			{
				if (playerArmySet[j].type == at)
				{
					armyDef = playerArmySet[j];
					break;
				}
			}
		}
		army.general = UnityEngine.Object.Instantiate(armyDef.generalPrefab);
		army.generalLife = armyDef.generalLife;
		army.armyDef = armyDef;
		army.generalComponent = army.general.GetComponent<General>();
		army.generalComponent.army = army;
		army.general.position = pos;
		army.generalPos = pos;
		army.tilePos = World.inst.GetCellDataClamped(pos).Center3D;
		if (addUnits)
		{
			UnitCategory category = GetCategory(at, teamId);
			for (int k = 0; k < army.squadSize; k++)
			{
				Unit unitFromCategory = GetUnitFromCategory(category);
				if (unitFromCategory != null)
				{
					AddUnit(unitFromCategory, army);
				}
				else
				{
					Debug.LogError("null unit");
				}
			}
		}
		army.fwd = new Vector3(0f, 0f, 1f);
		army.right = new Vector3(1f, 0f, 0f);
		OrdersManager.inst.AddUnit(army);
		((IMoveableUnit)army).MoveTo((IMoveTarget)World.inst.GetCellDataClamped(pos));
		PlayMoveSoundEffect(army);
		armies.Add(army);
		return army;
	}

	public void ReleaseArmy(Army army)
	{
		if ((bool)army.resourceText)
		{
			army.resourceText.Release();
			army.resourceText = null;
		}
		OrdersManager.inst.RemoveUnit(army);
		int num;
		for (num = 0; num < army.units.Count; num++)
		{
			ReleaseUnit(army.units.data[num]);
			num--;
		}
		army.nearbyBuildings.Clear();
		army.nearbyVillagers.Clear();
		army.neighborGroups.Clear();
		army.units.Clear();
		if ((bool)army.general)
		{
			UnityEngine.Object.Destroy(army.general.gameObject);
			army.general = null;
		}
		army.generalStatus = Army.GeneralStatus.Dying;
		army.stolenResourceType = -1;
		army.stolenResourceAmount = 0;
		armies.RemoveSwap(army);
	}

	private UnitCategory GetCategory(ArmyType at, int teamId)
	{
		for (int i = 0; i < unitCategoriesGen.Count; i++)
		{
			if (unitCategoriesGen[i].type == at && unitCategoriesGen[i].teamId == teamId)
			{
				return unitCategoriesGen[i];
			}
		}
		return null;
	}

	public Unit GetUnitFromCategory(UnitCategory cat)
	{
		for (int i = 0; i < cat.units.Length; i++)
		{
			if (!cat.units[i].inUse)
			{
				cat.units[i].inUse = true;
				ResetUnit(cat.units[i]);
				cat.units[i].life = cat.life;
				return cat.units[i];
			}
		}
		return null;
	}

	public int ArmyCount()
	{
		return armies.Count;
	}

	public int GetPlayerArmies()
	{
		return ArmyCount(0);
	}

	public int ArmyCount(int teamId)
	{
		int num = 0;
		for (int i = 0; i < armies.Count; i++)
		{
			if (armies.data[i].teamId == teamId && armies.data[i].armyType != ArmyType.Envoy)
			{
				num++;
			}
		}
		return num;
	}

	public int UnitCount(int teamId)
	{
		int num = 0;
		for (int i = 0; i < armies.Count; i++)
		{
			if (armies.data[i].teamId == teamId)
			{
				num++;
			}
		}
		return num;
	}

	public int UnitCount(int teamId, ArmyType at)
	{
		int num = 0;
		for (int i = 0; i < armies.Count; i++)
		{
			if (armies.data[i].teamId == teamId && armies.data[i].armyType == at)
			{
				num++;
			}
		}
		return num;
	}

	public Army GetAmry(int idx)
	{
		return armies.data[idx];
	}

	public void LockArmy(Army army)
	{
		army.locked = true;
		army.moving = false;
	}

	public void UnlockArmy(Army army)
	{
		army.locked = false;
	}

	public bool IsLocked(Army army)
	{
		return army.locked;
	}

	private void AddUnit(Unit unit, Army army, bool keepWorldPos = false)
	{
		unit.army = army;
		if (!keepWorldPos)
		{
			unit.pos = (unit.targetPos = army.generalPos);
		}
		army.units.Add(unit);
	}

	public void ReleaseUnit(Unit unit)
	{
		unit.army.units.RemoveSwap(unit);
		unit.army = null;
		unit.inUse = false;
		if (unit.kidnapTarget != null)
		{
			if (unit.kidnapCompleted)
			{
				Cell cellDataClamped = World.inst.GetCellDataClamped(unit.pos);
				if (unit.life > 0f || cellDataClamped.landMassIdx == -1)
				{
					Player.inst.DestroyPerson(unit.kidnapTarget, leaveBehindBody: false);
				}
				else
				{
					Player.inst.ReturnPerson(unit.kidnapTarget, unit.pos);
				}
			}
			markedVillagers.Remove(unit.kidnapTarget);
		}
		unit.kidnapTarget = null;
	}

	private void InitCategoriesGen()
	{
		for (int i = 0; i < playerArmySet.Count; i++)
		{
			ArmyDef armyDef = playerArmySet[i];
			for (int j = 0; j < 4; j++)
			{
				UnitCategory unitCategory = new UnitCategory();
				unitCategory.weaponLocalOffset = armyDef.weaponLocalOffset;
				unitCategory.mesh = armyDef.mesh;
				unitCategory.weaponMesh = armyDef.weaponMesh;
				unitCategory.life = armyDef.unitLife;
				unitCategory.generalLife = armyDef.generalLife;
				int num = j;
				if (j >= 1)
				{
					num++;
				}
				unitCategory.teamId = num;
				unitCategory.armyDef = armyDef;
				unitCategory.type = armyDef.type;
				unitCategoriesGen.Add(unitCategory);
			}
		}
		for (int k = 0; k < vikingArmySet.Count; k++)
		{
			ArmyDef armyDef2 = vikingArmySet[k];
			UnitCategory unitCategory2 = new UnitCategory();
			unitCategory2.weaponLocalOffset = armyDef2.weaponLocalOffset;
			unitCategory2.mesh = armyDef2.mesh;
			unitCategory2.weaponMesh = armyDef2.weaponMesh;
			unitCategory2.life = armyDef2.unitLife;
			unitCategory2.generalLife = armyDef2.generalLife;
			unitCategory2.teamId = 1;
			unitCategory2.armyDef = armyDef2;
			unitCategory2.type = armyDef2.type;
			unitCategory2.mat = World.inst.liverySets[0].armyMaterial;
			unitCategoriesGen.Add(unitCategory2);
		}
		for (int l = 0; l < unitCategoriesGen.Count; l++)
		{
			for (int m = 0; m < 1023; m++)
			{
				unitCategoriesGen[l].units[m] = new Unit();
				unitCategoriesGen[l].units[m].pos = new Vector3(SRand.Range(5f, 15f), 0f, SRand.Range(5f, 15f));
				ResetUnit(unitCategoriesGen[l].units[m]);
			}
		}
	}

	private void UpdateUnitFollowPos(Unit unit)
	{
		Vector3 worldPos = unit.army.generalPos;
		if (unit.army.pathIdx < unit.army.path.Count && unit.army.path.Count > 0)
		{
			worldPos = unit.army.path.data[unit.army.pathIdx];
		}
		Vector3 center3D = World.inst.GetCellDataClamped(worldPos).Center3D;
		int i = 0;
		for (int count = unit.army.units.Count; i < count; i++)
		{
			if (unit.army.units.data[i] == unit)
			{
				unit.targetPos = center3D + unit.army.tilePosOffsets[i % unit.army.squadSize] + new Vector3(SRand.Range(-0.05f, 0.05f), 0f, SRand.Range(0.05f, 0.05f));
				Vector3 vector = unit.targetPos - unit.pos;
				float radians = 0f - Mathf.Atan2(vector.z, vector.x);
				Mathff.SetRotationY(ref unit.rot, radians);
				break;
			}
		}
	}

	private void UpdateUnitsTargetPos(Army group)
	{
		Vector3 vector = group.generalPos;
		if (group.pathIdx < group.path.Count && group.path.Count > 0)
		{
			vector = group.path.data[group.pathIdx];
		}
		if (group.blocking)
		{
			vector = group.tilePos;
		}
		if (vector.y < group.generalPos.y)
		{
			vector = group.generalPos;
		}
		else
		{
			vector.y = group.generalPos.y;
		}
		float num = 1f;
		if (vector.y > 0.01f)
		{
			num = 0.65f;
		}
		int i = 0;
		for (int count = group.units.Count; i < count; i++)
		{
			Unit obj = group.units.data[i];
			Vector3 vector2 = group.tilePosOffsets[i % group.squadSize];
			obj.targetPos.x = vector.x + vector2.x * num;
			obj.targetPos.y = vector.y + vector2.y * num;
			obj.targetPos.z = vector.z + vector2.z * num;
		}
	}

	public static bool MovementBlockTest(PathCell pc, int teamId)
	{
		Cell cellData = World.inst.GetCellData(pc);
		bool flag = cellData.OccupyingStructure.Count > 0;
		for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
		{
			if (cellData.OccupyingStructure[i].troopsCanWalkOn)
			{
				return false;
			}
		}
		if (flag && World.inst.RelationBetween(cellData.OccupyingStructure[0].TeamID(), teamId) == World.Relations.Enemy)
		{
			return false;
		}
		return flag;
	}

	public static bool MovementBlockTestEnvoy(PathCell pc, int teamId)
	{
		Cell cellData = World.inst.GetCellData(pc);
		bool result = cellData.OccupyingStructure.Count > 0;
		for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
		{
			if (cellData.OccupyingStructure[i].troopsCanWalkOn)
			{
				return false;
			}
		}
		return result;
	}

	private void UpdatePathing(Army army)
	{
		army.moving = false;
		if (!IsAlive(army))
		{
			return;
		}
		Vector3 pos = army.GetPos();
		bool flag = army.moveTarget != null && !army.moveTarget.Equals(null);
		if (flag)
		{
			pos = army.moveTarget.GetPos();
			Cell cellData = World.inst.GetCellData(pos);
			if (cellData != null)
			{
				pos.y = World.GetCellHeightPos(cellData).y;
			}
		}
		bool flag2 = flag && World.inst.RelationBetween(army.moveTarget.TeamID(), army.teamId) == World.Relations.Enemy;
		Vector3 vector = new Vector3((float)(int)army.generalPos.x + 0.5f, army.generalPos.y, (float)(int)army.generalPos.z + 0.5f);
		Vector3 vector2 = pos;
		if (!(Mathff.DistSqrdXZ(vector2, vector) > army.attackRange * army.attackRange) && flag2)
		{
			return;
		}
		if (flag2 && army.attackRange > 0f)
		{
			Vector3 normalized = (vector.xz() - vector2.xz()).normalized;
			vector2 += normalized * army.attackRange;
			vector2.x = (float)(int)vector2.x + 0.5f;
			vector2.z = (float)(int)vector2.z + 0.5f;
		}
		Vector3 vector3 = ((army.armyType != ArmyType.Envoy) ? OrdersManager.inst.GetUnoccupiedDestination(vector2, army, MovementBlockTest, army.teamId) : OrdersManager.inst.GetUnoccupiedDestination(vector2, army, MovementBlockTestEnvoy, army.teamId));
		if ((flag && army.teamId != 0 && army.teamId != army.moveTarget.TeamID() && army.moveTarget is Building && army.GetPos().y <= 0f) & flag2)
		{
			vector3.y = 0f;
		}
		if (Mathff.DistSqrd(vector, vector3) > 0.0025000002f)
		{
			army.deferredPath.teamId = army.teamId;
			army.deferredPath.start = vector;
			army.deferredPath.end = vector3;
			if (army.armyType == ArmyType.Envoy)
			{
				army.deferredPath.pathType = GamePath.PathType.EnvoyPathPostBlock;
			}
			else
			{
				army.deferredPath.pathType = GamePath.PathType.MilitaryPathPostBlock;
			}
			World.inst.threadedPather.RequestPath(army.deferredPath);
			army.moving = true;
		}
		else
		{
			army.pathIdx = 0;
			army.pathBlocked = false;
			army.pathBlockedImmediate = false;
			army.path.Clear();
			army.moveStatus = MoveStatus.Complete;
		}
		SetStatus(army, Army.GeneralStatus.Following);
	}

	private void SetArmyFacing(Army army, Vector3 newPos)
	{
		Vector3 v = army.tilePos - newPos;
		if (v.magnitude > 0f)
		{
			army.fwd = Mathff.GetPrimaryAxis(v);
			army.fwd.y = 0f;
			army.fwd.Normalize();
			army.right = new Vector3(Mathf.Abs(army.fwd.z), 0f, 0f - Mathf.Abs(army.fwd.x));
		}
		else
		{
			Vector3 fwd = army.fwd;
			army.fwd = army.right;
			army.right = fwd;
		}
	}

	private void SetStatus(Army army, Army.GeneralStatus newStatus)
	{
		if (newStatus == army.generalStatus)
		{
			return;
		}
		army.stateTime = 0f;
		army.generalStatus = newStatus;
		if (newStatus != Army.GeneralStatus.Dying && newStatus != Army.GeneralStatus.FallingDeath)
		{
			return;
		}
		if (newStatus == Army.GeneralStatus.Dying)
		{
			EffectsMan.inst.GibsEffect.CreateAndPlay(army.general.position);
		}
		OrdersManager.inst.UnitKilled(army, army.lastAttackerTeamID);
		OrdersManager.inst.RemoveUnit(army);
		Cell cellDataClamped = World.inst.GetCellDataClamped(army.generalPos);
		if (army.stolenResourceAmount > 0 && cellDataClamped.landMassIdx != -1)
		{
			if (army.stolenResourceType == 4)
			{
				ResourceTextStackManager.inst.ShowResourceAmount(army, army.generalPos, 4, army.stolenResourceAmount);
				army.general.GetComponent<ThiefSack>().SetStolenVisibility(show: false);
				World.GetLandmassOwner(cellDataClamped.landMassIdx).Gold += army.stolenResourceAmount;
			}
			if ((bool)army.resourceText)
			{
				army.resourceText.Release();
				army.resourceText = null;
			}
		}
	}

	public void SetGeneralPos(Army army, Vector3 position)
	{
		if (army.generalLife > 0f)
		{
			army.general.transform.position = position;
			army.generalPos = position;
		}
	}

	public void AddHighlights(int minX, int minZ, int maxX, int maxZ, ref List<ISelectable> objs)
	{
		int i = 0;
		for (int count = armies.Count; i < count; i++)
		{
			Army army = armies.data[i];
			if (army.ValidToSelect() && ((ISelectable)army).InsideSelectionBounds(minX, minZ, maxX, maxZ))
			{
				objs.Add(army);
			}
		}
	}

	public ISelectable GetHighlight(out float minDist)
	{
		minDist = float.MaxValue;
		ISelectable result = null;
		Ray ray = PointingSystem.GetRay();
		int i = 0;
		for (int count = armies.Count; i < count; i++)
		{
			Army army = armies.data[i];
			if (army.ValidToSelect())
			{
				float hitDist = float.MaxValue;
				if (army.IntersectsRay(ray, out hitDist) && hitDist < minDist)
				{
					minDist = hitDist;
					result = army;
				}
			}
		}
		return result;
	}

	public void AddInView(Plane[] planes, ref List<ISelectable> objs)
	{
		int i = 0;
		for (int count = armies.Count; i < count; i++)
		{
			Army army = armies.data[i];
			if (GeometryUtility.TestPlanesAABB(planes, army.general.GetComponentInChildren<Renderer>().bounds))
			{
				objs.Add(army);
			}
		}
	}

	public void QuickDeath(Unit unit)
	{
		SetStatus(unit, Unit.Status.QuickDying);
	}

	private bool SetStatus(Unit unit, Unit.Status newStatus)
	{
		if ((newStatus == Unit.Status.Dying && unit.status == Unit.Status.QuickDying) || (newStatus == Unit.Status.QuickDying && unit.status == Unit.Status.Dying))
		{
			return false;
		}
		if (newStatus != unit.status)
		{
			if (unit.status == Unit.Status.Attacking && newStatus == Unit.Status.Following)
			{
				UpdateUnitFollowPos(unit);
				unit.weaponRot = Quaternion.Euler(0f, 0f, 0f);
			}
			if (unit.status == Unit.Status.Kidnapping && !unit.kidnapCompleted)
			{
				if (unit.kidnapTarget != null)
				{
					markedVillagers.Remove(unit.kidnapTarget);
				}
				unit.kidnapTarget = null;
			}
			if (newStatus == Unit.Status.Attacking)
			{
				unit.reactTime = SRand.Range(0.25f, 0.6f);
			}
			if (newStatus == Unit.Status.Dying)
			{
				EffectsMan.inst.GibsEffect.CreateAndPlay(unit.pos);
			}
			unit.status = newStatus;
			unit.stateTime = 0f;
			return true;
		}
		return false;
	}

	private bool MoveGeneralTo(Army army, Vector3 targetPos, float dt, float arrivalRad = 0.05f)
	{
		Vector3 vector = army.general.position;
		Vector3 dir = targetPos - vector;
		RotateGeneralToFaceDir(army, dir, dt);
		float num = arrivalRad * arrivalRad;
		bool flag = dir.x * dir.x + dir.y * dir.y + dir.z * dir.z < num;
		if (!flag)
		{
			vector = Mathff.MoveTowards(vector, targetPos, dt * army.speed);
		}
		float num2 = Player.inst.walkBounce.Evaluate(army.generalTotalTime);
		vector.y = targetPos.y;
		float yAdjust = 0f;
		float magnitudeMul = 1f;
		float bounceSpeedMul = 1f;
		Villager.GetYAdjust(World.inst.GetCellDataClamped(vector), ref yAdjust, ref magnitudeMul, ref bounceSpeedMul);
		army.generalTotalTime += dt * generalBounceSpeed * bounceSpeedMul;
		if (army.generalTotalTime > 1f)
		{
			army.generalTotalTime = 0f;
		}
		yAdjust += num2 * generalBounceMagnitude * magnitudeMul;
		vector.y += yAdjust;
		army.general.position = vector;
		return flag;
	}

	public void OnAnyBuildingBuilt(Building building)
	{
		if (building.uniqueNameHash == World.troopTransportShipHash || building.uniqueNameHash == World.transportShipHash || building.uniqueNameHash == World.playerMerchantShipHash)
		{
			return;
		}
		Cell cell = building.GetCell();
		int i = 0;
		for (int count = armies.Count; i < count; i++)
		{
			Army army = armies.data[i];
			if (World.inst.GetCellData(army.generalPos) == cell && !army.moving && !army.IsInvalid())
			{
				army.pathIdx = 0;
				army.moveStatus = MoveStatus.NotComplete;
				army.moving = true;
				army.moveTarget = cell;
				army.path.Add(World.GetCellHeightPos(cell));
			}
		}
		Cell startCell = null;
		building.ForEachTileInBounds((int x, int z, Cell c) =>
		{
			if (c.Type == TerrainType.Water || c.SubStructureCompareUniqueNameAll(World.pierHash))
			{
				startCell = c;
			}
		});
		if (startCell == null)
		{
			return;
		}
		for (int num = 0; num < ShipSystem.inst.ships.Count; num++)
		{
			TroopTransportShip ship = ShipSystem.inst.ships.data[num].GetComponent<TroopTransportShip>();
			if (ship == null)
			{
				continue;
			}
			Cell shipCell = World.inst.GetCellData(ship.GetPos());
			bool movedShip = false;
			building.ForEachTileInBounds((int x, int z, Cell c) =>
			{
				if (c == shipCell && !movedShip)
				{
					scratchShips.Add(ship);
					movedShip = true;
				}
			});
		}
		if (scratchShips.Count <= 0)
		{
			return;
		}
		Cell cell2 = null;
		if (scratchVisited == null || scratchVisited.Length != World.inst.GridWidth * World.inst.GridHeight)
		{
			scratchVisited = new bool[World.inst.GridWidth * World.inst.GridHeight];
		}
		for (int num2 = 0; num2 < scratchVisited.Length; num2++)
		{
			scratchVisited[num2] = false;
		}
		openSet.Clear();
		openSet.Add(startCell);
		int gridWidth = World.inst.GridWidth;
		while (openSet.Count > 0)
		{
			Cell cell3 = openSet.data[0];
			openSet.RemoveAtSwap(0);
			if (!scratchVisited[cell3.z * gridWidth + cell3.x])
			{
				if (cell3.deepWater)
				{
					cell2 = cell3;
					break;
				}
				if (cell3.Type == TerrainType.Water || cell3.SubStructureCompareUniqueNameAll(World.pierHash))
				{
					openSet.Add(World.inst.GetCellDataClamped(cell3.x + 1, cell3.z));
					openSet.Add(World.inst.GetCellDataClamped(cell3.x, cell3.z + 1));
					openSet.Add(World.inst.GetCellDataClamped(cell3.x - 1, cell3.z));
					openSet.Add(World.inst.GetCellDataClamped(cell3.x, cell3.z - 1));
				}
				scratchVisited[cell3.z * gridWidth + cell3.x] = true;
			}
		}
		if (cell2 != null)
		{
			for (int num3 = 0; num3 < scratchShips.Count; num3++)
			{
				scratchShips.data[num3].SetPos(cell2.Center3D);
			}
		}
		scratchShips.Clear();
	}

	private bool MoveTo(Army group, Vector3 targetPos, float dt)
	{
		float num = 0.0001f;
		if (targetPos.y >= group.generalPos.y)
		{
			Vector3 vector = targetPos;
			vector.y = group.generalPos.y;
			group.generalPos = Mathff.MoveTowards(group.generalPos, vector, group.speed * dt);
			Vector3 vector2 = vector - group.generalPos;
			if (vector2.x * vector2.x + vector2.z * vector2.z < num)
			{
				group.generalPos = Mathff.MoveTowards(group.generalPos, targetPos, group.speed * dt);
				if (Mathff.Abs(group.generalPos.y - targetPos.y) < 0.01f)
				{
					return true;
				}
			}
		}
		else
		{
			Vector3 generalPos = group.generalPos;
			generalPos.y = targetPos.y;
			group.generalPos = Vector3.MoveTowards(group.generalPos, generalPos, group.speed * dt);
			if (Mathff.Abs(group.generalPos.y - targetPos.y) < 0.01f)
			{
				group.generalPos = Vector3.MoveTowards(group.generalPos, targetPos, group.speed * dt);
				Vector3 vector3 = targetPos - group.generalPos;
				if (vector3.x * vector3.x + vector3.z * vector3.z < num)
				{
					return true;
				}
			}
		}
		return false;
	}

	private bool MoveTo(Unit unit, Vector3 targetPos, float dt, float arrivalRad)
	{
		Vector3 rhs = targetPos;
		rhs.x -= unit.pos.x;
		rhs.y -= unit.pos.y;
		rhs.z -= unit.pos.z;
		float num = rhs.x * rhs.x + rhs.z * rhs.z;
		if (num > 0.040000003f)
		{
			float radians = 0f - Mathf.Atan2(rhs.z, rhs.x);
			Mathff.SetRotationY(ref unit.rot, radians);
		}
		if (num > arrivalRad * arrivalRad)
		{
			float num2 = Mathf.Sqrt(num);
			float num3 = 1f;
			Vector3 lhs = unit.army.generalPos - unit.pos;
			float num4 = lhs.x * lhs.x + lhs.z * lhs.z;
			if (Vector3.Dot(lhs, rhs) > 0f && num4 > 4f)
			{
				num3 = 10f;
			}
			float num5 = dt * accel * unit.army.speed * unit.army.speedMod * num3;
			unit.velocity.x += rhs.x / num2 * num5;
			unit.velocity.z += rhs.z / num2 * num5;
			return false;
		}
		return true;
	}

	private bool GeneralAttack(Army army, Vector3 targetPos, float dt)
	{
		bool result = false;
		army.generalAttackTime += dt;
		targetPos.y = army.generalPos.y;
		float num = army.tilePos.x - 0.2f;
		float num2 = army.tilePos.z - 0.2f;
		float num3 = army.tilePos.x + 0.2f;
		float num4 = army.tilePos.z + 0.2f;
		if (targetPos.x > num3)
		{
			targetPos.x = num3;
		}
		if (targetPos.z > num4)
		{
			targetPos.z = num4;
		}
		if (targetPos.x < num)
		{
			targetPos.x = num;
		}
		if (targetPos.z < num2)
		{
			targetPos.z = num2;
		}
		if (MoveGeneralTo(army, targetPos, dt))
		{
			RotateGeneralToFaceDir(army, targetPos - army.general.position, dt * 5f);
			army.generalAttackTime += dt;
			if (army.generalAttackTime > 1f)
			{
				army.generalAttackTime = 0f;
				result = true;
			}
			army.general.GetChild(0).localRotation = Quaternion.Euler(0f, 0f, Mathf.Lerp(45f, -135f, attackCurve.Evaluate(army.generalAttackTime)));
		}
		else
		{
			RotateGeneralToFaceDir(army, targetPos - army.general.position, dt * 3f);
		}
		return result;
	}

	private void RotateGeneralToFaceDir(Army army, Vector3 dir, float dt)
	{
		if (dir.x * dir.x + dir.z * dir.z > 0.0001f)
		{
			float target = (0f - Mathf.Atan2(dir.z, dir.x)) * 57.29579f;
			army.generalAngle = Mathf.MoveTowardsAngle(army.generalAngle, target, dt * 180f);
			army.general.transform.rotation = Quaternion.Euler(0f, army.generalAngle, 0f);
		}
	}

	public static bool TrimPathForBlockedCells(Vector3 startPos, ref ArrayExt<Vector3> path, int teamId, IMoveTarget moveTarget, Pathfinder.blocksPathTest bt)
	{
		if (path.Count > 0)
		{
			PathCell pathCell = World.inst.GetPathCell(startPos);
			bool flag = false;
			if (!pathCell.isUpperGridBlocked && startPos.y > 0.01f)
			{
				flag = true;
			}
			bool flag2 = flag;
			for (int i = 0; i < path.Count; i++)
			{
				PathCell pathCell2 = World.inst.GetPathCell(path.data[i]);
				if (pathCell2.isStairs && path.data[i].y > 0.01f)
				{
					if (!flag2)
					{
						flag = !flag;
					}
					flag2 = true;
				}
				else
				{
					flag2 = false;
				}
				if (!bt(pathCell2, teamId) || (flag && !pathCell2.isUpperGridBlocked && pathCell2.Type == TerrainType.None))
				{
					continue;
				}
				path.RemoveRange(i, path.Count - i);
				Cell cellData = World.inst.GetCellData(pathCell2);
				for (int j = 0; j < cellData.OccupyingStructure.Count; j++)
				{
					if (cellData.OccupyingStructure[j] == moveTarget)
					{
						return false;
					}
				}
				return true;
			}
		}
		return false;
	}

	private bool TryRecooperate(Army army)
	{
		int hash = barracksHash;
		if (army.armyType == ArmyType.Archer)
		{
			hash = archerSchoolHash;
		}
		int landMassIdx = World.inst.GetCellDataClamped(army.generalPos).landMassIdx;
		if (World.GetLandmassOwner(landMassIdx).teamId != army.teamId)
		{
			return false;
		}
		Building building = null;
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(landMassIdx, hash);
		float num = float.MaxValue;
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			float num2 = Mathff.DistSqrdXZ(buildingListForLandMass.data[i].Center(), army.generalPos);
			if (num2 < num)
			{
				num = num2;
				building = buildingListForLandMass.data[i];
			}
		}
		if (building != null)
		{
			if (army.moveTarget == building && army.moveStatus == MoveStatus.Complete)
			{
				building.GetComponent<Barracks>().ReclaimSoldiers(army);
				return true;
			}
			army.moveTarget = building;
			army.moveStatus = MoveStatus.NotComplete;
		}
		else
		{
			army.tryRecooperate = false;
			army.moveTarget = null;
		}
		return false;
	}

	private Vector3 GetGeneralMoveTarget(Army army)
	{
		if (army.path.Count > 0)
		{
			return army.generalPos;
		}
		Vector3 tilePos = army.tilePos;
		tilePos.y = army.generalPos.y;
		return tilePos;
	}

	private bool UpdateGeneral(Army army, float dt)
	{
		if (army.generalLife <= 0f)
		{
			SetStatus(army, Army.GeneralStatus.Dying);
		}
		if (IsAlive(army) && army.locked)
		{
			return true;
		}
		bool flag = false;
		army.attackTarget = null;
		if (IsAlive(army) && army.CanAttack())
		{
			if (army.moveTarget is Building && World.inst.RelationBetween(army.teamId, army.moveTarget.TeamID()) == World.Relations.Enemy && army.GetNearbyBuildings().Contains(army.moveTarget as Building))
			{
				army.attackTarget = army.moveTarget as IProjectileHitable;
			}
			if (army.attackTarget == null)
			{
				float num = float.MaxValue;
				for (int i = 0; i < army.adjacentEnemies.Count; i++)
				{
					IProjectileHitable projectileHitable = army.adjacentEnemies.data[i];
					if (projectileHitable.IsInvalid())
					{
						continue;
					}
					float num2 = Mathff.DistSqrdXZ(projectileHitable.GetPosition(), army.generalPos);
					if (num2 < num)
					{
						num = num2;
						army.attackTarget = projectileHitable;
						if (army.attackTarget == army.moveTarget)
						{
							break;
						}
					}
				}
				if ((!army.isAutoTargeting && army.moveStatus == MoveStatus.Complete) || army.isAutoTargeting)
				{
					int num3 = 0;
					if (army.armyBehavior == ArmyBehavior.Attack)
					{
						num3 = 10;
					}
					if (army.armyBehavior == ArmyBehavior.Pursue)
					{
						num3 = 99;
					}
					if (num3 > 0)
					{
						IMoveableUnit moveableUnit = OrdersManager.inst.ClosestEnemyUnit(army.generalPos, num3, army.teamId, EnemyFilter);
						if (moveableUnit != null && !moveableUnit.Equals(null))
						{
							int landMassIdx = World.inst.GetCellDataClamped(moveableUnit.GetPos()).landMassIdx;
							int landMassIdx2 = World.inst.GetCellDataClamped(army.generalPos).landMassIdx;
							if (landMassIdx == landMassIdx2 && moveableUnit is IMoveTarget moveTarget && army.moveTarget != moveTarget)
							{
								OrdersManager.inst.MoveTo(army, moveTarget);
								army.isAutoTargeting = true;
							}
						}
					}
				}
			}
			if (army.attackTarget == null && army.IsBlockingCell())
			{
				LandmassOwner landmassOwner = World.GetLandmassOwner(World.inst.GetCellDataClamped(army.tilePos).landMassIdx);
				if (landmassOwner != null && World.inst.RelationBetween(army.teamId, landmassOwner.teamId) == World.Relations.Enemy)
				{
					ArrayExt<Building> nearbyBuildings = army.GetNearbyBuildings();
					float num4 = -1f;
					for (int j = 0; j < nearbyBuildings.Count; j++)
					{
						float num5 = Vector3.Dot(army.toNext, (nearbyBuildings.data[j].Center() - army.generalPos).normalized);
						if (num5 > num4 && num5 > 0.8f)
						{
							num4 = num5;
							army.attackTarget = nearbyBuildings.data[j];
						}
					}
				}
			}
			float num6 = 1.21f;
			if (army.attackTarget == null)
			{
				WolfDen.WolfData wolfData = WolfDen.ClosestWolf(army.general.transform.position);
				if (wolfData != null && Mathff.DistSqrdXZ(army.generalPos, wolfData.GetPosition()) < num6)
				{
					army.attackTarget = wolfData;
				}
			}
			if (army.attackTarget == null && (army.moveTarget == null || army.moveTarget.Equals(null)) && army.playerSetMoveTarget != null && !army.playerSetMoveTarget.Equals(null) && army.armyBehavior != ArmyBehavior.Hold)
			{
				if (army.moveStatus == MoveStatus.Complete && army.moveTarget != army.playerSetMoveTarget)
				{
					((IMoveableUnit)army).MoveTo(army.playerSetMoveTarget);
				}
				else if (army.moveStatus == MoveStatus.Failed)
				{
					army.playerSetMoveTarget = null;
				}
			}
			if (army.attackTarget != null)
			{
				flag = true;
				if (GeneralAttack(army, army.attackTarget.GetPosition(), dt))
				{
					float dmg = 3f;
					if (army.attackTarget is Building)
					{
						dmg = 0.0175f;
					}
					army.attackTarget.TakeProjectileDamage(dmg, DamageType.Standard, DamageSource.Melee, army.generalPos, Vector3.zero, army.teamId);
				}
			}
		}
		army.stateTime += dt;
		switch (army.generalStatus)
		{
		case Army.GeneralStatus.Following:
		{
			if (army.tryRecooperate && TryRecooperate(army))
			{
				return false;
			}
			if (army.moveTimer.Update(dt))
			{
				UpdatePathing(army);
			}
			if (army.path.Count <= 0 || army.pathIdx >= army.path.Count || Mathf.Abs(army.path.data[army.pathIdx].y - army.generalPos.y) <= 0.01f)
			{
				if (army.deferredPath.TryConsume(ref army.path))
				{
					Vector3 vector = ((army.path.Count > 0) ? army.path.data[0] : army.generalPos);
					if (army.armyType == ArmyType.Envoy)
					{
						army.pathBlocked = TrimPathForBlockedCells(army.generalPos, ref army.path, army.teamId, army.moveTarget, PathCell.GetBlocksFootPathForEnvoys);
					}
					else
					{
						army.pathBlocked = TrimPathForBlockedCells(army.generalPos, ref army.path, army.teamId, army.moveTarget, PathCell.GetBlocksFootPathForArmies);
					}
					army.pathBlockedImmediate = army.pathBlocked && army.path.Count == 0;
					if (army.pathBlockedImmediate)
					{
						army.toNext = (vector - army.tilePos).normalized;
					}
					if (army.doShowPath && army.TeamID() == 0 && army.moveTarget != null && !army.moveTarget.Equals(null))
					{
						CommandPathMarker obj = EffectsMan.inst.PathMarker.Create(Vector3.zero) as CommandPathMarker;
						obj.ShowPath(army.path, World.inst.RelationBetween(army.moveTarget.TeamID(), army.teamId) == World.Relations.Enemy);
						obj.Play();
						army.doShowPath = false;
					}
					army.pathIdx = 0;
					if (army.path.Count > 0)
					{
						army.moveStatus = MoveStatus.NotComplete;
					}
					else if (army.path.Count == 0 && !army.pathBlocked)
					{
						army.moveStatus = MoveStatus.Complete;
					}
					else
					{
						army.moveStatus = MoveStatus.Failed;
					}
				}
			}
			else
			{
				army.deferredPath.Reset();
			}
			UpdateUnitsTargetPos(army);
			if (!flag)
			{
				MoveGeneralTo(army, GetGeneralMoveTarget(army), dt * army.speedMod);
			}
			if (army.armyType == ArmyType.Default)
			{
				army.burnTimer -= dt;
				if ((army.burnTimer < 0f || army.teamId == 1) && TryBurningBuilding(army))
				{
					army.burnTimer = burnMaxTime;
				}
			}
			army.generalLife += dt * 0.05f;
			float generalLife = army.armyDef.generalLife;
			if (army.generalLife > generalLife)
			{
				army.generalLife = generalLife;
			}
			break;
		}
		case Army.GeneralStatus.Dying:
			army.general.Rotate(30f * dt, 0f, 0f);
			if (army.stateTime > 3f)
			{
				return false;
			}
			break;
		case Army.GeneralStatus.FallingDeath:
		{
			LockArmy(army);
			army.fallVel += new Vector3(0f, 1f, 0f) * dt;
			for (int k = 0; k < army.units.Count; k++)
			{
				army.units.data[k].pos -= army.fallVel * dt;
			}
			army.general.transform.position -= army.fallVel * dt;
			army.generalPos -= army.fallVel * dt;
			if (army.general.transform.position.y <= 0f)
			{
				for (int l = 0; l < army.units.Count; l++)
				{
					EffectsMan.inst.GibsEffect.CreateAndPlay(army.units.data[l].pos);
				}
				EffectsMan.inst.GibsEffect.CreateAndPlay(army.general.position);
				return false;
			}
			break;
		}
		}
		return true;
	}

	public static bool EnemyFilter(IMoveableUnit unit)
	{
		return !unit.CanCarry();
	}

	public void FallDeathAt(Cell cell)
	{
		int i = 0;
		for (int count = armies.Count; i < count; i++)
		{
			Army army = armies.data[i];
			Cell cellData = World.inst.GetCellData(army.generalPos);
			if (cell == cellData && army.generalPos.y > 0.1f)
			{
				SetStatus(army, Army.GeneralStatus.FallingDeath);
			}
		}
	}

	public bool IsAlive(Army army)
	{
		if (army.generalStatus != Army.GeneralStatus.Dying)
		{
			return army.generalStatus != Army.GeneralStatus.FallingDeath;
		}
		return false;
	}

	public static bool ProcessBlocking(Vector3 nextPos, Vector3 startPos, IMoveableUnit unit, ref Vector3 toNext, float lookAhead = 0.71f)
	{
		toNext = (nextPos - startPos).normalized;
		Vector3 vector = startPos + toNext * lookAhead;
		int num = (int)startPos.x;
		int num2 = (int)startPos.z;
		vector.x = Mathff.Clamp(vector.x, (float)num - 0.01f, (float)num + 1.01f);
		vector.z = Mathff.Clamp(vector.z, (float)num2 - 0.01f, (float)num2 + 1.01f);
		IMoveableUnit moveableUnit = OrdersManager.inst.FindUnitAt((int)vector.x, (int)vector.z, unit.GetMoveType());
		IProjectileHitable projectileHitable = moveableUnit as IProjectileHitable;
		if (moveableUnit != null && !projectileHitable.IsInvalid() && moveableUnit != unit)
		{
			if (!moveableUnit.CanAttack() || !unit.CanAttack())
			{
				return false;
			}
			Vector3 rhs = new Vector3((float)(int)vector.x + 0.5f, 0f, (float)(int)vector.z + 0.5f) - startPos;
			rhs.Normalize();
			if (World.inst.RelationBetween(moveableUnit.TeamID(), unit.TeamID()) == World.Relations.Enemy || (moveableUnit.IsBlockingCell() && Vector3.Dot(moveableUnit.GetToNextCell(), rhs) > -0.1f))
			{
				return true;
			}
		}
		return false;
	}

	private void UpdateGroup(Army army, float dt)
	{
		_ = army.blocking;
		army.blocking = false;
		if (!army.locked)
		{
			army.adjacentEnemies.ClearFast();
			int num = (int)Mathff.Clamp(army.tilePos.x - 1f, 0f, World.inst.GridWidth - 1);
			int num2 = (int)Mathff.Clamp(army.tilePos.z - 1f, 0f, World.inst.GridHeight - 1);
			int num3 = (int)Mathff.Clamp(army.tilePos.x + 1f, 0f, World.inst.GridWidth - 1);
			int num4 = (int)Mathff.Clamp(army.tilePos.z + 1f, 0f, World.inst.GridHeight - 1);
			for (int i = num; i <= num3; i++)
			{
				for (int j = num2; j <= num4; j++)
				{
					IMoveableUnit moveableUnit = OrdersManager.inst.FindUnitAt(i, j, army.GetMoveType());
					if (moveableUnit != null && TargetGroupInRange(army, moveableUnit))
					{
						IProjectileHitable projectileHitable = moveableUnit as IProjectileHitable;
						if (!projectileHitable.IsInvalid() && !(moveableUnit is Army { armyType: ArmyType.Envoy }) && World.inst.RelationBetween(moveableUnit.TeamID(), army.teamId) == World.Relations.Enemy)
						{
							army.adjacentEnemies.Add(projectileHitable);
						}
					}
				}
			}
			army.speedMod = 1f;
			if (army.tryRecooperate)
			{
				army.speedMod = 2f;
			}
			float speedModifier = World.inst.GetCellDataClamped(army.generalPos).speedModifier;
			army.speedMod *= speedModifier;
			if (army.path.Count > 0 && army.pathIdx < army.path.Count)
			{
				Vector3 targetPos = army.path.data[army.pathIdx];
				if (ProcessBlocking(army.path.data[army.pathIdx], army.tilePos, army, ref army.toNext))
				{
					army.blocking = true;
					targetPos = army.tilePos;
				}
				if (army.teamId == 1 && army.adjacentEnemies.Count > 0)
				{
					army.blocking = true;
					targetPos = army.tilePos;
				}
				if (MoveTo(army, targetPos, dt * army.speedMod) && !army.blocking)
				{
					army.pathIdx++;
					if (army.pathIdx >= army.path.Count)
					{
						army.moveStatus = MoveStatus.Complete;
					}
					UpdateUnitsTargetPos(army);
				}
			}
			else
			{
				MoveTo(army, GetGeneralMoveTarget(army), dt * army.speedMod);
			}
			if (army.stolenResourceAmount <= 0 && army.armyType == ArmyType.Thief && army.moveTarget is Building)
			{
				Building building = army.moveTarget as Building;
				if (army.GetNearbyBuildings().Contains(building) && (bool)building.GetComponent<ThroneRoom>())
				{
					int num5 = 100;
					if (Player.inst.difficulty == Player.Difficulty.Survival)
					{
						num5 = 200;
					}
					LandmassOwner landmassOwner = World.GetLandmassOwner(building.LandMass());
					int num6 = ((landmassOwner.Gold - num5 > 0) ? num5 : landmassOwner.Gold);
					if (num6 > 0)
					{
						landmassOwner.Gold -= num6;
						army.stolenResourceAmount += num6;
						army.stolenResourceType = 4;
						army.resourceText = GameUI.inst.ResourceText.Create(ResourceAmount.Make(4, num6).ToString());
						ResourceTextStackManager.inst.ShowResourceAmount(building, building.Center(), 4, -num6);
						army.general.GetComponent<ThiefSack>().SetStolenVisibility(show: true);
						RaiderSystem.inst.OnPerformedTheft(army);
						SfxSystem.inst.PlayFromBankIfVisibleOneShot("BuildingSelectThroneRoom", army.generalPos);
						SfxSystem.inst.PlayFromBankIfVisibleOneShot("vikingbattlecry", army.generalPos);
					}
				}
			}
		}
		if (army.resourceText != null)
		{
			army.resourceText.transform.position = army.generalPos + new Vector3(0f, 2f, 0f);
		}
		army.tilePos = World.inst.GetCellData(army.generalPos)?.Center3D ?? army.generalPos;
	}

	private bool TargetGroupInRange(Army myGroup, IMoveableUnit targetGroup)
	{
		if (Mathf.Abs(myGroup.generalPos.y - targetGroup.GetPos().y) < 0.21f)
		{
			float num = myGroup.meleeRange * myGroup.meleeRange;
			float num2 = Mathff.DistSqrdXZ(targetGroup.GetPos(), myGroup.tilePos);
			if (num2 < num && num2 < 2.25f)
			{
				return true;
			}
		}
		return false;
	}

	private void TryAttacking(Unit unit)
	{
		Army army = unit.army;
		if (army.attackTarget != null && !army.attackTarget.Equals(null))
		{
			SetStatus(unit, Unit.Status.Attacking);
		}
	}

	private void TryKidnapping(Unit unit)
	{
		unit.kidnapCompleted = false;
		ArrayExt<Villager> nearbyVillagers = unit.army.GetNearbyVillagers();
		if (nearbyVillagers.Count > 0)
		{
			int num = nearbyVillagers.RandomIdx();
			unit.kidnapTarget = nearbyVillagers.data[num];
			markedVillagers.Add(unit.kidnapTarget);
			int i = 0;
			for (int count = armies.Count; i < count; i++)
			{
				_ = armies.data[i];
				nearbyVillagers.RemoveSwap(unit.kidnapTarget);
			}
			SetStatus(unit, Unit.Status.Kidnapping);
		}
	}

	private void UpdateUnitState(Unit unit, float dt, float maxLife)
	{
		if (unit.status != Unit.Status.Dying && unit.army.locked)
		{
			return;
		}
		switch (unit.status)
		{
		case Unit.Status.Following:
			unit.stateTime += dt;
			unit.reactTime -= dt;
			if (unit.reactTime <= 0f)
			{
				MoveTo(unit, unit.targetPos, dt, 0.05f);
			}
			if (unit.army.CanAttack())
			{
				TryAttacking(unit);
			}
			if (unit.type == Unit.Type.Kidnapper && !unit.kidnapCompleted)
			{
				TryKidnapping(unit);
			}
			break;
		case Unit.Status.Kidnapping:
			if (unit.kidnapTarget == null || Mathff.DistSqrdXZ(unit.kidnapTarget.Pos, unit.pos) > Mathff.Sqr(1.5f))
			{
				SetStatus(unit, Unit.Status.Following);
			}
			else if (MoveTo(unit, unit.kidnapTarget.Pos, dt * 2f, 0.05f))
			{
				Player.inst.AbductPerson(unit.kidnapTarget);
				unit.kidnapCompleted = true;
				unit.kidnapLandmass = World.inst.GetCellDataClamped(unit.pos).landMassIdx;
				SetStatus(unit, Unit.Status.Following);
				if (SRand.Range(0, 2) == 0)
				{
					SfxSystem.inst.PlayFromBankIfVisibleOneShot("VillagerKidnapMale", unit.pos);
				}
				else
				{
					SfxSystem.inst.PlayFromBankIfVisibleOneShot("VillagerKidnapFemale", unit.pos);
				}
			}
			break;
		case Unit.Status.Attacking:
		{
			IProjectileHitable attackTarget = unit.army.attackTarget;
			if (attackTarget == null || attackTarget.Equals(null) || attackTarget.IsInvalid())
			{
				SetStatus(unit, Unit.Status.Following);
				break;
			}
			unit.reactTime -= dt;
			if (!(unit.reactTime < 0f))
			{
				break;
			}
			MoveTo(unit, attackTarget.GetPosition(), dt, unitSeparationRad + 0.03f);
			float num = dt * 2f;
			if (StreamerEffects.Flag_FasterAttackSpeed && unit.army.teamId == 0)
			{
				num *= 2f;
			}
			unit.stateTime += num;
			if (unit.stateTime > 1f)
			{
				unit.stateTime = 0f;
				if (SRand.Range(0, 100) > 25)
				{
					float num2 = 0.5f;
					if (unit.army.armyType == ArmyType.Elite)
					{
						num2 = 1f;
					}
					IProjectileHitable projectileHitable = attackTarget;
					if (attackTarget is Building building)
					{
						num2 *= 0.005f;
						if (building.categoryHash == World.projectileTopperHash)
						{
							projectileHitable = building.GetCell().OccupyingStructure[0];
						}
					}
					projectileHitable.TakeProjectileDamage(num2, DamageType.Standard, DamageSource.Melee, unit.army.generalPos, Vector3.zero, unit.army.teamId);
					if (SRand.Range(0, 100) > 50)
					{
						SfxSystem.inst.PlayFromBankIfVisibleOneShot("Soldier_SwordImpact_Random", attackTarget.GetPosition());
					}
				}
				unit.reactTime = SRand.Range(0.25f, 0.3f);
			}
			unit.weaponRot = Quaternion.Euler(0f, 0f, Mathf.Lerp(45f, -135f, attackCurve.Evaluate(unit.stateTime)));
			break;
		}
		case Unit.Status.QuickDying:
			MakeCorpse(unit);
			ReleaseUnit(unit);
			break;
		case Unit.Status.Dying:
			MakeCorpse(unit);
			ReleaseUnit(unit);
			break;
		}
		if (unit.status == Unit.Status.Following && unit.life > 0f && unit.army.teamId != 1)
		{
			unit.life += dt * 0.05f;
			if (unit.life > maxLife)
			{
				unit.life = maxLife;
			}
		}
	}

	private void MakeCorpse(Unit u)
	{
		if (u.army.teamId != 1 && SRand.Range(0, 100) < 30 && World.inst.GetCellDataClamped(u.pos).landMassIdx != -1)
		{
			new DeadVillager(u.pos + new Vector3(0f, -0.05f, 0f), Quaternion.Euler(0f, SRand.Range(0, 360), 0f), _useLadyMesh: false).CopyDataFromUnit();
		}
	}

	private void PopulateNeighborGroups(Army group)
	{
		group.neighborGroups.ClearFast();
		int num = (int)Mathff.Clamp(group.generalPos.x - 0f, 0f, World.inst.GridWidth);
		int num2 = (int)Mathff.Clamp(group.generalPos.x + 0f, 0f, World.inst.GridWidth);
		int num3 = (int)Mathff.Clamp(group.generalPos.z - 0f, 0f, World.inst.GridWidth);
		int num4 = (int)Mathff.Clamp(group.generalPos.z + 0f, 0f, World.inst.GridWidth);
		int i = 0;
		for (int count = armies.Count; i < count; i++)
		{
			Army army = armies.data[i];
			int num5 = (int)army.generalPos.x;
			int num6 = (int)army.generalPos.z;
			if (num <= num5 && num5 <= num2 && num3 <= num6 && num6 <= num4)
			{
				group.neighborGroups.Add(army);
			}
		}
	}

	private bool TryBurningBuilding(Army group)
	{
		ArrayExt<Building> nearbyBuildings = group.GetNearbyBuildings();
		if (nearbyBuildings.Count > 0)
		{
			IMoveTarget moveTarget = group.moveTarget;
			if (moveTarget is Building && World.inst.RelationBetween(group.moveTarget.TeamID(), group.teamId) == World.Relations.Enemy)
			{
				Building building = moveTarget as Building;
				if ((bool)building && nearbyBuildings.Contains(building) && !building.GetCell().Busy && !World.IsImmuneToFire(building))
				{
					nearbyBuildings.RemoveSwap(building);
					Cell cell = building.GetCell();
					Fire fire = FireManager.inst.StartFireAt(cell);
					if (fire != null)
					{
						if (!cell.StructureCompareCategoryNameAll("castleblock".GetHashCode()))
						{
							fire.PostModifyBurnout(0.66f);
						}
						SfxSystem.inst.PlayFromBankIfVisibleOneShot("Viking_Torch_Throw", group.generalPos);
						return true;
					}
				}
			}
		}
		return false;
	}

	private void ApplySoftRepel(Unit unit, float dt)
	{
		float num = unitSeparationRad;
		float num2 = num * num;
		float num3 = 1f / num;
		Vector3 pos = unit.pos;
		float num4 = separationForce * dt;
		int i = 0;
		for (int count = unit.army.neighborGroups.Count; i < count; i++)
		{
			Army army = unit.army.neighborGroups.data[i];
			int j = 0;
			for (int count2 = army.units.Count; j < count2; j++)
			{
				Unit unit2 = army.units.data[j];
				float num5 = pos.x - unit2.pos.x;
				float num6 = pos.z - unit2.pos.z;
				float num7 = num5 * num5 + num6 * num6;
				if (!(num7 > num2))
				{
					float num8 = (float)Math.Sqrt(num7);
					num8 += 0.001f;
					float num9 = num5 / num8;
					float num10 = num6 / num8;
					float num11 = (num - num8) * num3 * num4;
					float num12 = num9 * num11;
					float num13 = num10 * num11;
					unit.velocity.x += num12;
					unit.velocity.z += num13;
					unit2.velocity.x -= num12;
					unit2.velocity.z -= num13;
				}
			}
		}
	}

	public Army FindArmyByGuid(Guid id)
	{
		int i = 0;
		for (int count = armies.Count; i < count; i++)
		{
			Army army = armies.data[i];
			if (army.guid == id)
			{
				return army;
			}
		}
		return null;
	}

	public void Reset()
	{
		markedVillagers.Clear();
		int num;
		for (num = 0; num < armies.Count; num++)
		{
			ReleaseArmy(armies.data[num]);
			num--;
		}
	}

	private void Update()
	{
		if (loadTickDelay > 0)
		{
			loadTickDelay--;
			return;
		}
		float deltaTime = Time.deltaTime;
		deltaTime = Mathf.Clamp(deltaTime, 0f, 0.06666f);
		for (int i = 0; i < armies.Count; i++)
		{
			Army army = armies.data[i];
			army.nearbyBuildings.Clear();
			army.buildingCacheFresh = false;
			army.nearbyVillagers.Clear();
			army.villagerCacheFresh = false;
			UpdateGroup(army, deltaTime);
			PopulateNeighborGroups(army);
			if (!UpdateGeneral(army, deltaTime))
			{
				OrdersManager.inst.DestroyUnit(army);
				i--;
			}
		}
		float t = Mathff.Clamp01((Cam.inst.dist - 10f) / 50f);
		float value = Mathff.Lerp(1f, 1.6f, t);
		float value2 = Mathff.Lerp(1f, 1.5f, t);
		int num = -1;
		for (int j = 0; j < unitCategoriesGen.Count; j++)
		{
			if (unitCategoriesGen[j].teamId != num)
			{
				if (unitCategoriesGen[j].mat != null)
				{
					unitCategoriesGen[j].mat.SetFloat("_camScale", value);
					unitCategoriesGen[j].mat.SetFloat("_colorMul", value2);
				}
				if (unitCategoriesGen[j].unlitMat != null)
				{
					unitCategoriesGen[j].unlitMat.SetFloat("_camScale", value);
					unitCategoriesGen[j].unlitMat.SetFloat("_colorMul", value2);
				}
				num = unitCategoriesGen[j].teamId;
			}
		}
	}

	private void LateUpdate()
	{
		for (int i = 0; i < unitCategoriesGen.Count; i++)
		{
			UnitCategory unitCategory = unitCategoriesGen[i];
			if (unitCategory.mat == null)
			{
				continue;
			}
			int j = 0;
			for (int num = unitCategoriesGen[i].matrices.Length; j < num; j++)
			{
				if (unitCategory.units[j].inUse && unitCategory.units[j].visible)
				{
					Mathff.SetTR(ref unitCategory.matrices[j], unitCategory.units[j].pos, unitCategory.units[j].rot);
					Vector3 vector = unitCategory.units[j].rot * unitCategory.weaponLocalOffset;
					Mathff.SetTR(ref unitCategory.weapons[j], unitCategory.units[j].pos + vector, unitCategory.units[j].rot * unitCategory.units[j].weaponRot);
				}
				else
				{
					unitCategory.weapons[j].m33 = 0f;
					unitCategory.matrices[j].m33 = 0f;
				}
			}
			if (Settings.inst.supportsInstancing)
			{
				Graphics.DrawMeshInstanced(unitCategory.mesh, 0, unitCategory.mat, unitCategory.matrices);
				Graphics.DrawMeshInstanced(unitCategory.weaponMesh, 0, unitCategory.mat, unitCategory.weapons);
				continue;
			}
			for (int k = 0; k < unitCategory.matrices.Length; k++)
			{
				Graphics.DrawMesh(unitCategory.mesh, unitCategory.matrices[k], unitCategory.mat, 0);
			}
			for (int l = 0; l < unitCategory.weapons.Length; l++)
			{
				Graphics.DrawMesh(unitCategory.weaponMesh, unitCategory.weapons[l], unitCategory.mat, 0);
			}
		}
	}

	public void DrawWithCommandBuffer(CommandBuffer buffer, Material mat, int pass)
	{
		for (int i = 0; i < unitCategoriesGen.Count; i++)
		{
			UnitCategory unitCategory = unitCategoriesGen[i];
			if (unitCategory.mat == null)
			{
				continue;
			}
			if (Settings.inst.supportsInstancing)
			{
				buffer.DrawMeshInstanced(unitCategory.mesh, 0, unitCategory.mat, pass, unitCategory.matrices);
				buffer.DrawMeshInstanced(unitCategory.weaponMesh, 0, unitCategory.mat, pass, unitCategory.weapons);
				continue;
			}
			for (int j = 0; j < unitCategory.matrices.Length; j++)
			{
				buffer.DrawMesh(unitCategory.mesh, unitCategory.matrices[j], unitCategory.mat, 0, pass);
			}
			for (int k = 0; k < unitCategory.weapons.Length; k++)
			{
				buffer.DrawMesh(unitCategory.weaponMesh, unitCategory.weapons[k], unitCategory.mat, 0, pass);
			}
		}
	}

	public void PlayMoveSoundEffect(IMoveableUnit unit)
	{
		if (unit != null && unit.TeamID() == 0 && !LoadSave.Loading && unit is Army army && !army.Equals(null))
		{
			if (army.armyType == ArmyType.Default)
			{
				SfxSystem.inst.PlayFromBank("ArmyGeneralMove", army.general.position);
			}
			if (army.armyType == ArmyType.Archer)
			{
				SfxSystem.inst.PlayFromBank("ArcherUnitAcknowledge", army.general.position);
			}
			if (army.armyType == ArmyType.Envoy)
			{
				SfxSystem.inst.PlayFromBank("EnvoyAcknowledge", army.general.position);
			}
		}
	}
}
