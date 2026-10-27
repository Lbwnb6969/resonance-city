using System;
using System.Collections.Generic;
using Assets;
using UnityEngine;

public class SiegeMonster : MonoBehaviour, IProjectileHitable, ISelectable, IMoveTarget, IMoveableUnit
{
	private enum Status
	{
		Seeking,
		Attacking,
		BeingCarried,
		Dying,
		Dead
	}

	[Serializable]
	public class SiegeMonsterSaveData : SaveClass<SiegeMonster, SiegeMonsterSaveData>
	{
		[Serializable]
		private struct OgreData
		{
			public float life;

			public SerializableVector3 position;

			public Guid guid;
		}

		private List<OgreData> savedMonsters = new List<OgreData>();

		public override SiegeMonsterSaveData Pack(SiegeMonster obj)
		{
			for (int i = 0; i < monsters.Count; i++)
			{
				OgreData item = new OgreData
				{
					life = monsters.data[i].life,
					guid = monsters.data[i].GetGuid(),
					position = monsters.data[i].transform.position
				};
				savedMonsters.Add(item);
			}
			return this;
		}

		public override SiegeMonster Unpack(SiegeMonster obj)
		{
			for (int i = 0; i < savedMonsters.Count; i++)
			{
				GameObject gameObject = UnityEngine.Object.Instantiate(RaiderSystem.inst.ogrePrefab);
				gameObject.transform.position = savedMonsters[i].position;
				gameObject.GetComponent<SiegeMonster>().life = savedMonsters[i].life;
				gameObject.GetComponent<SiegeMonster>().guid = savedMonsters[i].guid;
			}
			return null;
		}
	}

	public ObjectHighlighter highlighter;

	private HealthBar healthBar;

	public ogreanimcontroller animController;

	private float damageFlashTime;

	[NonSerialized]
	public float life;

	public float maxLife = 400f;

	private float deathTimer = 5f;

	private static int rubbleHash = "rubble".GetHashCode();

	private static int keepHash = "keep".GetHashCode();

	private static int pathHash = "path".GetHashCode();

	private static int dockHash = "dock".GetHashCode();

	private static int outpostHash = "outpost".GetHashCode();

	private static int cemeteryHash = "cemetery".GetHashCode();

	private static int farmHash = "farm".GetHashCode();

	private static int orchardHash = "orchard".GetHashCode();

	private Status status;

	public float Speed = 0.5f;

	public float targetSyncDist = 1.5f;

	public bool debugDrawPath;

	[NonSerialized]
	public Vector3 lastPos;

	private Vector3 lastVel;

	public ParticleSystem wake;

	private Cell lastCell;

	private IMoveTarget moveTarget;

	private FrameUpdater pathUpdater;

	private static int frameID = 0;

	private GamePath deferredPath = new GamePath();

	private bool arrived;

	private bool forceUpdatePath;

	private ArrayExt<Vector3> path = new ArrayExt<Vector3>(32);

	private int pathIdx;

	private float blockingTime;

	private Vector3 blockDir;

	public SkinnedMeshRenderer mesh;

	private float speedMul = 1f;

	public Transform handBone;

	public Transform leftFoot;

	public Transform rightFoot;

	private IProjectileHitable attackTarget;

	private static readonly int castleblockHash = "castleblock".GetHashCode();

	private static readonly int gateHash = "gate".GetHashCode();

	public static ArrayExt<SiegeMonster> monsters = new ArrayExt<SiegeMonster>(32);

	private Guid guid = Guid.NewGuid();

	bool IMoveTarget.IsStationary()
	{
		return false;
	}

	public bool IsInvalid()
	{
		if (!IsDead())
		{
			return status == Status.BeingCarried;
		}
		return true;
	}

	float IProjectileHitable.GetRadius()
	{
		return 1f;
	}

	Vector3 IProjectileHitable.GetPosition()
	{
		return transform.position;
	}

	public Vector3 GetPredictedPosition(float time)
	{
		return transform.position;
	}

	Vector3 IProjectileHitable.GetVelocity()
	{
		return lastVel;
	}

	HitSfxResult IProjectileHitable.TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int attackerTeamID)
	{
		if (StreamerEffects.Flag_StrongerEnemies && TeamID() != 0)
		{
			dmg /= 2f;
		}
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(attackerTeamID);
		if (landmassOwnerByTeamId != null && landmassOwnerByTeamId.hazardPay)
		{
			dmg *= (float)landmassOwnerByTeamId.hazardPayMultiplier;
		}
		damageFlashTime = (0.03f + dmg * 0.01f) * TimeManager.inst.GetSpeedUpPercent();
		life -= dmg;
		if (life <= 0f)
		{
			animController.TransitionToDying();
			status = Status.Dying;
			monsters.RemoveSwap(this);
			OrdersManager.inst.UnitKilled(this, attackerTeamID);
			OrdersManager.inst.RemoveUnit(this);
			SfxSystem.inst.PlayFromBankIfVisibleOneShot("OgreDeath", transform.position);
		}
		else
		{
			SfxSystem.inst.PlayFromBankIfVisibleOneShot("OgreHitByArrow", transform.position);
		}
		return HitSfxResult.None;
	}

	private void Start()
	{
		pathUpdater = new FrameUpdater(ref frameID, 30);
		List<SkinnedMeshRenderer> list = new List<SkinnedMeshRenderer>();
		SkinnedMeshRenderer component = transform.GetChild(0).GetChild(1).GetComponent<SkinnedMeshRenderer>();
		if ((bool)component)
		{
			list.Add(component);
		}
		highlighter = ObjectHighlighter.SetupOutlines(gameObject, null, list);
		if (life == 0f)
		{
			life = maxLife;
		}
		monsters.Add(this);
	}

	public bool IsDead()
	{
		if (status != Status.Dying)
		{
			return status == Status.Dead;
		}
		return true;
	}

	public static void ResetOgres()
	{
		int num;
		for (num = 0; num < monsters.Count; num++)
		{
			UnityEngine.Object.Destroy(monsters.data[num].gameObject);
			num--;
		}
		monsters.Clear();
	}

	public static void AddInView(Plane[] planes, ref List<ISelectable> objs)
	{
		for (int i = 0; i < monsters.Count; i++)
		{
			SiegeMonster siegeMonster = monsters.data[i];
			if (GeometryUtility.TestPlanesAABB(planes, siegeMonster.GetComponentInChildren<Renderer>().bounds))
			{
				objs.Add(siegeMonster.GetComponent<ISelectable>());
			}
		}
	}

	private void OnEnable()
	{
		healthBar = UnityEngine.Object.Instantiate(Player.inst.healthBarPrefab);
		OrdersManager.inst.AddUnit(this);
	}

	private void OnDisable()
	{
		OrdersManager.inst.RemoveUnit(this);
		monsters.RemoveSwap(this);
		if ((bool)healthBar)
		{
			UnityEngine.Object.Destroy(healthBar.gameObject);
		}
	}

	public static bool ShouldIgnore(Building b)
	{
		if (b.categoryHash != rubbleHash && (b.uniqueNameHash != keepHash || (Player.inst.difficulty == Player.Difficulty.Survival && b.TeamID() == 0)) && (b.categoryHash != pathHash || b.uniqueNameHash == World.drawBridgeHash) && b.categoryHash != cemeteryHash && b.uniqueNameHash != dockHash && b.uniqueNameHash != outpostHash && b.uniqueNameHash != farmHash && b.uniqueNameHash != orchardHash && !b.SubStructure)
		{
			return b.IsDestroyed();
		}
		return true;
	}

	private bool MoveTargetInvalid()
	{
		if (moveTarget != null)
		{
			return moveTarget.Equals(null);
		}
		return true;
	}

	private void Update()
	{
		Vector3 vector = transform.position;
		if (status == Status.Seeking)
		{
			pathUpdater.Update();
			if (pathUpdater.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				if (moveTarget != null && !moveTarget.Equals(null))
				{
					Vector3 position = transform.position;
					deferredPath.start = position;
					deferredPath.teamId = TeamID();
					Vector3 pos = moveTarget.GetPos();
					pos = OrdersManager.inst.GetUnoccupiedDestination(pos, this, PathCell.GetBlocksFootPathForOgres, 1, ignoreWallConnectivity: true);
					deferredPath.end = pos;
					deferredPath.pathType = GamePath.PathType.OgrePathPostBlock;
					if (Mathff.DistSqrdXZ(deferredPath.start, deferredPath.end) > 0.25f)
					{
						World.inst.threadedPather.RequestPath(deferredPath);
					}
				}
			}
			if (deferredPath.TryConsume(ref path))
			{
				World.inst.TrimPathForBlockedCells(ref path, PathCell.GetBlocksFootPathForOgres, TeamID());
				arrived = false;
				pathIdx = 0;
				if (path.Count <= 0)
				{
					TryTransitionToAttacking();
				}
			}
			if (deferredPath.status == GamePath.Status.Uninitialized && Mathff.DistSqrdXZ(vector, GetDestPos()) < 0.0625f)
			{
				if (!arrived)
				{
					RaiderSystem.inst.OnOgreArrived(this);
				}
				arrived = true;
			}
			if (arrived)
			{
				animController.fwdVel -= Time.deltaTime * 1.25f;
				animController.fwdVel = Mathf.Max(animController.fwdVel, 0f);
				TryTransitionToAttacking();
			}
		}
		if (debugDrawPath)
		{
			for (int i = 0; i < path.Count; i++)
			{
				DebugEx.DrawCircle(path.data[i], 0.25f, Color.red, new Vector3(0f, 1f, 0f), new Vector3(1f, 0f, 0f), 6f, 0.1f);
			}
		}
		float deltaTime = Time.deltaTime;
		switch (status)
		{
		case Status.Seeking:
		{
			if (arrived || path.Count <= 0)
			{
				break;
			}
			Vector3 vector2 = path.data[pathIdx];
			Vector3 toNext = Vector3.zero;
			if (ArmySystem.ProcessBlocking(vector2, vector, this, ref toNext, 0.5f))
			{
				blockingTime = 0.5f;
				blockDir = toNext;
				animController.fwdVel = 0f;
				Vector3 normalized = (vector2 - vector).xz().normalized;
				transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(normalized), 240f * Time.deltaTime);
				TryTransitionToAttacking();
			}
			else
			{
				float num = Speed * deltaTime * speedMul;
				animController.fwdVel = Speed * speedMul;
				Vector3 vector3 = vector2 - vector;
				float magnitude = vector3.magnitude;
				if (magnitude <= num || magnitude == 0f)
				{
					vector = vector2;
					pathIdx++;
					if (pathIdx == path.Count)
					{
						arrived = true;
					}
					else if (pathIdx < path.Count)
					{
						vector = Vector3.MoveTowards(vector, path.data[pathIdx], num - magnitude);
					}
				}
				else
				{
					vector += vector3 / magnitude * num;
				}
				Vector3 forward = (vector - transform.position).xz();
				float magnitude2 = forward.magnitude;
				if (magnitude2 > 0f)
				{
					forward /= magnitude2;
					transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(forward), 240f * Time.deltaTime);
				}
			}
			Cell cellData = World.inst.GetCellData(vector);
			if (cellData != null && cellData.TopStructure != null && cellData.TopStructure.UniqueName == World.aqueductName)
			{
				BuildingCollapseManager.inst.Collapse(cellData.TopStructure, doRubble: true, doAnimation: false);
				EffectsMan.inst.BuildingCollapseExplode.CreateAndPlay(cellData.Center2D);
			}
			break;
		}
		case Status.Attacking:
			if (attackTarget == null || attackTarget.Equals(null))
			{
				TransitionToSeeking();
			}
			else if (!(attackTarget is Building))
			{
				float normalizedTime = animController.anim.GetCurrentAnimatorStateInfo(0).normalizedTime;
				normalizedTime = (float)(-(int)normalizedTime) + normalizedTime;
				if (normalizedTime < 0.3f && Mathff.DistSqrdXZ(attackTarget.GetPosition(), GetPos()) > 1.25f)
				{
					attackTarget = null;
				}
			}
			break;
		case Status.Dying:
			deathTimer -= Time.deltaTime;
			if (deathTimer <= 0f)
			{
				OrdersManager.inst.DestroyUnit(this);
			}
			break;
		}
		float b = 0f;
		if (status != Status.Dead && status != Status.Dying && status != Status.BeingCarried)
		{
			Cell cellData2 = World.inst.GetCellData(transform.localPosition);
			if (cellData2 != null && cellData2.Type == TerrainType.Water && !cellData2.StructureCompareCategory(World.pathHash))
			{
				speedMul = 0.75f;
				if (wake.isStopped)
				{
					wake.Play();
				}
				b = ((!cellData2.deepWater) ? (-0.2f) : (-0.4f));
			}
			else
			{
				speedMul = 1f;
				if (!wake.isStopped)
				{
					wake.Stop();
				}
			}
		}
		Vector3 localPosition = transform.GetChild(0).transform.localPosition;
		localPosition.y = Mathf.Lerp(localPosition.y, b, deltaTime * 10f);
		transform.GetChild(0).transform.localPosition = localPosition;
		if (damageFlashTime > 0f)
		{
			damageFlashTime -= deltaTime;
			if (damageFlashTime <= 0f)
			{
				mesh.material.SetFloat("_DamageAlpha", 0f);
			}
			else
			{
				mesh.material.SetFloat("_DamageAlpha", 1f);
			}
		}
		healthBar.life = life / maxLife;
		healthBar.SetPos(transform.position + new Vector3(0f, 2f, 0f));
		if (status != Status.BeingCarried)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(transform.position);
			if (cellDataClamped != lastCell && cellDataClamped != null)
			{
				World.inst.treeSystem.FellAllTrees(cellDataClamped);
			}
			lastCell = cellDataClamped;
		}
		lastVel = (transform.position - lastPos) / deltaTime;
		lastPos = transform.position;
		blockingTime -= deltaTime;
	}

	private void Hit()
	{
		Vector3 position = handBone.transform.position;
		if (attackTarget != null && !attackTarget.Equals(null))
		{
			Vector3 sourcePos = Vector3.Lerp(transform.position, attackTarget.GetPosition(), 0.5f);
			sourcePos.y = position.y;
			HitSfxResult hitSfxResult = ((!(attackTarget is Building)) ? attackTarget.TakeProjectileDamage(20f, DamageType.AOE, DamageSource.Melee, sourcePos, Vector3.zero, 1) : attackTarget.TakeProjectileDamage(1f, DamageType.Standard, DamageSource.Melee, sourcePos, Vector3.zero, 1));
			OneOffEffect oneOffEffect = EffectsMan.inst.WallHitEffect.Create(position);
			switch (hitSfxResult)
			{
			case HitSfxResult.Wood:
				SfxSystem.inst.PlayFromBankIfVisible("OgreStrikeWood", transform.position);
				oneOffEffect = EffectsMan.inst.WoodHitEffect.Create(position);
				break;
			case HitSfxResult.Stone:
				SfxSystem.inst.PlayFromBankIfVisible("OgreStrikeStone", transform.position);
				break;
			}
			oneOffEffect.transform.rotation = Quaternion.LookRotation(-transform.forward);
			oneOffEffect.Play();
		}
	}

	private void TransitionToSeeking()
	{
		if (status != Status.Seeking)
		{
			arrived = false;
			attackTarget = null;
			status = Status.Seeking;
			animController.TransitionToWalking();
		}
	}

	private void TransitionToBeingCarried()
	{
		status = Status.BeingCarried;
		animController.TransitionToWalking();
		animController.fwdVel = 0f;
	}

	private Building GetTopMostCastlePiece(Cell cell)
	{
		for (int num = cell.OccupyingStructure.Count - 1; num >= 0; num--)
		{
			Building building = cell.OccupyingStructure[num];
			if (building.categoryHash == castleblockHash || building.categoryHash == gateHash)
			{
				return building;
			}
		}
		return null;
	}

	private void TryTransitionToAttacking()
	{
		if (status == Status.Attacking)
		{
			return;
		}
		attackTarget = null;
		Vector3 position = transform.position;
		Cell[] array = new Cell[4];
		World.inst.GetNeighborCells(World.inst.GetCellDataClamped(position), ref array);
		for (int i = 0; i < array.Length; i++)
		{
			if (array[i] != null)
			{
				Building topMostCastlePiece = GetTopMostCastlePiece(array[i]);
				if ((bool)topMostCastlePiece)
				{
					attackTarget = topMostCastlePiece;
				}
			}
		}
		if (attackTarget == null)
		{
			for (int j = 0; j < array.Length; j++)
			{
				if (array[j] == null)
				{
					continue;
				}
				List<Building> occupyingStructure = array[j].OccupyingStructure;
				int num = 0;
				while (num < occupyingStructure.Count)
				{
					if (ShouldIgnore(occupyingStructure[num]))
					{
						num++;
						continue;
					}
					goto IL_00a3;
				}
				continue;
				IL_00a3:
				attackTarget = occupyingStructure[num];
				if (occupyingStructure[num].uniqueNameHash == World.drawBridgeHash)
				{
					break;
				}
			}
		}
		if (attackTarget == null)
		{
			Building topMostCastlePiece2 = GetTopMostCastlePiece(World.inst.GetCellDataClamped(position));
			if ((bool)topMostCastlePiece2)
			{
				attackTarget = topMostCastlePiece2;
			}
		}
		if (attackTarget == null)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(position);
			for (int k = 0; k < cellDataClamped.OccupyingStructure.Count; k++)
			{
				if (!ShouldIgnore(cellDataClamped.OccupyingStructure[k]))
				{
					attackTarget = cellDataClamped.OccupyingStructure[k];
					break;
				}
			}
		}
		int num2 = (int)Mathff.Clamp(position.x - 1f, 0f, World.inst.GridWidth - 1);
		int num3 = (int)Mathff.Clamp(position.x + 1f, 0f, World.inst.GridWidth - 1);
		int num4 = (int)Mathff.Clamp(position.z - 1f, 0f, World.inst.GridHeight - 1);
		int num5 = (int)Mathff.Clamp(position.z + 1f, 0f, World.inst.GridHeight - 1);
		for (int l = num4; l <= num5; l++)
		{
			for (int m = num2; m <= num3; m++)
			{
				IMoveableUnit moveableUnit = OrdersManager.inst.FindUnitAt(m, l);
				if (moveableUnit != null && moveableUnit.TeamID() != 1)
				{
					attackTarget = moveableUnit as IProjectileHitable;
					if (Vector3.Dot(blockDir, moveableUnit.GetPos() - position) > 0f)
					{
						goto end_IL_0266;
					}
				}
			}
			continue;
			end_IL_0266:
			break;
		}
		if (attackTarget != null)
		{
			Vector3 input = transform.position - attackTarget.GetPosition();
			input = Mathff.GetPrimaryAxis(input.xz());
			status = Status.Attacking;
			animController.TransitionToAttacking(World.inst.GetCellDataClamped(transform.position).Center2D, Quaternion.LookRotation(-input), 0.5f);
		}
	}

	private void Step()
	{
		Vector3 pos = ((rightFoot.position.y > leftFoot.position.y) ? rightFoot.position : leftFoot.position);
		EffectsMan.inst.GroundImpactEffect.CreateAndPlay(pos);
		SfxSystem.inst.PlayFromBankIfVisible("OgreFootstep", transform.position);
	}

	public static void AddHighlights(Ray ray, ref List<ISelectable> highlightedObjs)
	{
		float num = 0.9f;
		for (int i = 0; i < monsters.Count; i++)
		{
			if (Mathff.RaySphereIntersect(ray, monsters.data[i].transform.position + new Vector3(0f, num * 0.4f, 0f), num))
			{
				highlightedObjs.Add(monsters.data[i]);
				break;
			}
		}
	}

	public bool IntersectsRay(Ray ray, out float hitDist)
	{
		hitDist = float.MaxValue;
		float num = 0.9f;
		Vector3 vector = transform.position + new Vector3(0f, num * 0.4f, 0f);
		if (Mathff.RaySphereIntersect(ray, vector, num))
		{
			hitDist = Mathff.Dist(ray.origin, vector) - num;
			return true;
		}
		return false;
	}

	public void SetHighlightImmediate(int colorIdx)
	{
		highlighter.SetOutlineImmediate(colorIdx);
	}

	public void OnSelected()
	{
	}

	public bool InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		Vector3 position = transform.position;
		if ((float)minx <= position.x && position.x <= (float)maxx && (float)minz <= position.z)
		{
			return position.z <= (float)maxz;
		}
		return false;
	}

	public bool ExclusiveSelect()
	{
		return false;
	}

	public bool ValidToSelect()
	{
		if (status != Status.Dead && status != Status.Dying)
		{
			return status != Status.BeingCarried;
		}
		return false;
	}

	public int TeamID()
	{
		return 1;
	}

	public Vector3 GetPos()
	{
		return lastPos;
	}

	public MoveType GetMoveType()
	{
		return MoveType.Land;
	}

	public AttackType GetAttackType()
	{
		return AttackType.Melee;
	}

	public int GetLOS()
	{
		return 10;
	}

	public void MoveTo(IMoveTarget target)
	{
		moveTarget = target;
		forceUpdatePath = true;
	}

	public IMoveTarget GetMoveTarget()
	{
		return moveTarget;
	}

	public void SetPos(Vector3 pos)
	{
		transform.position = pos;
	}

	public Vector3 GetDestPos()
	{
		if (status == Status.Seeking && path.Count > 0)
		{
			return path.data[path.Count - 1];
		}
		return transform.position;
	}

	public bool IsBlockingCell()
	{
		if (!(blockingTime > 0f))
		{
			return status == Status.Attacking;
		}
		return true;
	}

	public Vector3 GetToNextCell()
	{
		if (blockingTime > 0f)
		{
			return blockDir;
		}
		return transform.forward;
	}

	public void OnUnitTargetsUs(IMoveableUnit u)
	{
	}

	public void OnUnitStoppedTargetingUs(IMoveableUnit u)
	{
	}

	public bool CanAttack()
	{
		return true;
	}

	public bool CanCarry()
	{
		return false;
	}

	public bool CanBeCarried()
	{
		return true;
	}

	public bool TryBeCarried()
	{
		if (!IsDead())
		{
			TransitionToBeingCarried();
			return true;
		}
		return false;
	}

	public void StopBeingCarried()
	{
		TransitionToSeeking();
	}

	public UnitType GetUnitType()
	{
		return UnitType.SiegeWeapon;
	}

	public int CarryCount()
	{
		return 0;
	}

	public IMoveableUnit GetCarried(int i)
	{
		return null;
	}

	public int GetRemainingCapacity()
	{
		return 0;
	}

	public bool IsBeingCarried()
	{
		return status == Status.BeingCarried;
	}

	public bool PendingCarry(IMoveableUnit u)
	{
		return false;
	}

	public bool IsFullCapacity()
	{
		return false;
	}

	public bool IsPendingLoadTargets()
	{
		return false;
	}

	public void DoUnload(IMoveableUnit u)
	{
	}

	public void NotifyOtherUnitDeath(IMoveableUnit u)
	{
		if (moveTarget == u)
		{
			moveTarget = null;
		}
	}

	public float CurrHealth()
	{
		return life;
	}

	public float MaxHealth()
	{
		return maxLife;
	}

	public void Disband()
	{
	}

	public void DestroyUnit()
	{
		UnityEngine.Object.Destroy(gameObject);
	}

	public Guid GetGuid()
	{
		return guid;
	}

	public int FormationIdx()
	{
		return 0;
	}
}
