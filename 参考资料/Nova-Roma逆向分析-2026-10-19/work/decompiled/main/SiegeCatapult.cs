using System;
using System.Collections.Generic;
using Assets;
using UnityEngine;

public class SiegeCatapult : Tickable, IProjectileHitable, ISelectable, IMoveTarget, IUnitControllable
{
	private enum Status
	{
		Seeking,
		Attacking,
		BeingCarried,
		Dead
	}

	public float soldierMaxDistance;

	public Transform[] wheels;

	public Transform[] soldierPositions;

	[NonSerialized]
	public Transform[] footSoldiers;

	public Catapult catapultPrefab;

	public GameObject footSoldierPrefab;

	[NonSerialized]
	public Catapult catapult;

	[NonSerialized]
	public ArmyWages armyWages;

	public ObjectHighlighter highlighter;

	public string generalName = string.Empty;

	public MeshRenderer baseMesh;

	private UnitIGUI unitGUI;

	public Mesh flagMesh;

	private HealthBar healthBar;

	[NonSerialized]
	public float life;

	public float maxLife = 400f;

	private static List<GameObject> toDestroy = new List<GameObject>();

	private static int rubbleHash = "rubble".GetHashCode();

	private static int pathHash = "path".GetHashCode();

	private static int cemeteryHash = "cemetery".GetHashCode();

	private Status status;

	public float Speed = 2f;

	[NonSerialized]
	public Vector3 lastPos;

	private Vector3 lastVel;

	public ParticleSystem wake;

	private IMoveTarget moveTarget;

	private FrameUpdater pathUpdater;

	private static int frameID = 0;

	public GamePath deferredPath = new GamePath();

	private bool arrived;

	private bool forceUpdatePath;

	public ArrayExt<Vector3> path = new ArrayExt<Vector3>(32);

	public int pathIdx;

	private float totalTime;

	private bool doShowPath;

	private float origEmissionRate;

	private bool lastPathBlocked;

	private float speedMul = 1f;

	private int teamId;

	private Vector3 blockDir;

	private float blockingTime;

	public Guid guid = Guid.NewGuid();

	bool IMoveTarget.IsStationary()
	{
		return false;
	}

	int IUnitControllable.GetFormationIdx()
	{
		return 1;
	}

	int IUnitControllable.GetSlotsOccupied()
	{
		return 1;
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
		if (dmgSource == DamageSource.Melee)
		{
			blockingTime = 0.5f;
			blockDir = (sourcePos - transform.position).normalized;
		}
		if (StreamerEffects.Flag_StrongerEnemies && teamId != 0)
		{
			dmg /= 2f;
		}
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(attackerTeamID);
		if (landmassOwnerByTeamId != null && landmassOwnerByTeamId.hazardPay)
		{
			dmg *= (float)landmassOwnerByTeamId.hazardPayMultiplier;
		}
		life -= dmg;
		if (life <= 0f)
		{
			status = Status.Dead;
			EffectsMan.inst.BuildPuff.CreateAndPlay(transform.position);
			EffectsMan.inst.WoodHitEffect.CreateAndPlay(transform.position);
			Release();
		}
		return HitSfxResult.None;
	}

	private void Start()
	{
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Combine(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	public void Init(int tId)
	{
		teamId = tId;
		armyWages = GetComponent<ArmyWages>();
		if (armyWages != null)
		{
			armyWages.missedWageFunc = Disband;
			armyWages.teamId = tId;
		}
		catapult = UnityEngine.Object.Instantiate(catapultPrefab);
		catapult.transform.SetParent(gameObject.transform, worldPositionStays: false);
		catapult.transform.localPosition = Vector3.zero;
		catapult.transform.localRotation = Quaternion.identity;
		catapult.manned = false;
		catapult.autoRotate = false;
		catapult.teamID = tId;
		if (unitGUI == null)
		{
			unitGUI = UnityEngine.Object.Instantiate(Player.inst.unitIGUIprefab).GetComponent<UnitIGUI>();
		}
		unitGUI.Init(tId, flagMesh);
		generalName = "";
	}

	private void UpdateMaterials()
	{
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(teamId);
		if (!(landmassOwnerByTeamId != null))
		{
			return;
		}
		if (footSoldiers != null)
		{
			for (int i = 0; i < footSoldiers.Length; i++)
			{
				footSoldiers[i].GetComponent<MeshRenderer>().material = World.inst.liverySets[landmassOwnerByTeamId.bannerIdx].armyMaterial;
			}
		}
		baseMesh.material = World.inst.liverySets[landmassOwnerByTeamId.bannerIdx].armyMaterial;
		for (int j = 0; j < wheels.Length; j++)
		{
			wheels[j].gameObject.GetComponent<MeshRenderer>().material = World.inst.liverySets[landmassOwnerByTeamId.bannerIdx].armyMaterial;
		}
	}

	private void UpdateBanners()
	{
		if ((bool)unitGUI)
		{
			unitGUI.UpdateMaterial(teamId);
		}
		UpdateMaterials();
	}

	public bool IsDead()
	{
		return status == Status.Dead;
	}

	public void Release()
	{
		highlighter.Release();
		SiegeCatapultSystem.siegeCatapults.RemoveSwap(this);
		UnityEngine.Object.Destroy(gameObject);
	}

	public void Disband()
	{
		if (!IsBeingCarried())
		{
			Transform[] array = footSoldiers;
			for (int i = 0; i < array.Length; i++)
			{
				Vector3 position = array[i].position;
				Player.inst.AddVillager(position);
			}
			Release();
		}
	}

	public static int CountCatapults(int teamId)
	{
		int num = 0;
		for (int i = 0; i < SiegeCatapultSystem.siegeCatapults.Count; i++)
		{
			if (SiegeCatapultSystem.siegeCatapults.data[i].teamId == teamId)
			{
				num++;
			}
		}
		return num;
	}

	public static void ResetCatapults()
	{
		for (int i = 0; i < SiegeCatapultSystem.siegeCatapults.Count; i++)
		{
			toDestroy.Add(SiegeCatapultSystem.siegeCatapults.data[i].gameObject);
		}
		SiegeCatapultSystem.siegeCatapults.Clear();
		for (int j = 0; j < toDestroy.Count; j++)
		{
			UnityEngine.Object.Destroy(toDestroy[j]);
		}
		toDestroy.Clear();
	}

	public override void OnEnableInternal()
	{
		pathUpdater = new FrameUpdater(ref frameID, 30);
		healthBar = UnityEngine.Object.Instantiate(Player.inst.healthBarPrefab);
		origEmissionRate = wake.emission.rateOverTime.constant;
		List<MeshRenderer> list = new List<MeshRenderer>(transform.GetComponentsInChildren<MeshRenderer>());
		footSoldiers = new Transform[soldierPositions.Length];
		for (int i = 0; i < soldierPositions.Length; i++)
		{
			footSoldiers[i] = UnityEngine.Object.Instantiate(footSoldierPrefab).transform;
			footSoldiers[i].position = soldierPositions[i].position;
			footSoldiers[i].localRotation = Quaternion.identity;
			list.Add(footSoldiers[i].GetComponent<MeshRenderer>());
		}
		highlighter = ObjectHighlighter.SetupOutlines(gameObject, list, null);
		if (life == 0f)
		{
			life = maxLife;
		}
		UpdateMaterials();
		SiegeCatapultSystem.siegeCatapults.Add(this);
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		for (int i = 0; i < footSoldiers.Length; i++)
		{
			if (footSoldiers[i] != null)
			{
				UnityEngine.Object.Destroy(footSoldiers[i].gameObject);
			}
		}
		highlighter.Release();
		if ((bool)healthBar)
		{
			UnityEngine.Object.Destroy(healthBar.gameObject);
		}
		SiegeCatapultSystem.siegeCatapults.RemoveSwap(this);
	}

	public void OnDestroy()
	{
		if ((bool)unitGUI)
		{
			UnityEngine.Object.Destroy(unitGUI.gameObject);
		}
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Remove(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	public bool ShouldIgnoreAutoTarget(Building b)
	{
		if (ShouldIgnore(b))
		{
			return true;
		}
		if (b.categoryHash == World.castleblockHash || b.categoryHash == World.gateHash || b.categoryHash == World.projectileTopperHash || b.uniqueNameHash == World.keepHash || b.uniqueNameHash == World.chamberOfWarHash || b.uniqueNameHash == World.archerSchoolHash || b.uniqueNameHash == World.barracksHash || b.uniqueNameHash == World.siegeWorkshopHash)
		{
			return false;
		}
		return true;
	}

	public bool ShouldIgnore(Building b)
	{
		if (b.categoryHash != rubbleHash && b.categoryHash != pathHash && b.categoryHash != cemeteryHash && !b.SubStructure && !b.IsDestroyed())
		{
			return World.inst.RelationBetween(b.TeamID(), TeamID()) != World.Relations.Enemy;
		}
		return true;
	}

	public bool TargetValid()
	{
		if (moveTarget == null || moveTarget.Equals(null))
		{
			return false;
		}
		if (moveTarget is IProjectileHitable && (moveTarget as IProjectileHitable).IsInvalid())
		{
			return false;
		}
		return true;
	}

	public override void Tick(float dt, int currFrame)
	{
		Vector3 vector = base.transform.position;
		bool isVisible = baseMesh.isVisible;
		switch (status)
		{
		case Status.Seeking:
			pathUpdater.Update();
			if (pathUpdater.Trigger() || forceUpdatePath)
			{
				forceUpdatePath = false;
				if (TargetValid())
				{
					Vector3 start = vector;
					deferredPath.start = start;
					deferredPath.teamId = TeamID();
					Vector3 pos = moveTarget.GetPos();
					deferredPath.end = pos;
					deferredPath.pathType = GamePath.PathType.MilitaryPathPostBlock;
					if (Mathff.DistSqrdXZ(deferredPath.start, deferredPath.end) > 0.25f)
					{
						World.inst.threadedPather.RequestPath(deferredPath);
					}
					else
					{
						arrived = true;
					}
				}
			}
			if (TargetValid() && deferredPath.TryConsume(ref path))
			{
				Vector3 vector2 = Vector3.zero;
				if (path.Count > 0)
				{
					vector2 = path.data[0];
				}
				World.inst.TrimPathForBlockedCells(ref path, PathCell.GetBlocksFootPathForArmies, TeamID());
				pathIdx = 0;
				if (path.Count > 0)
				{
					arrived = false;
					TransitionToSeeking();
					lastPathBlocked = false;
					if (doShowPath && TeamID() == 0)
					{
						CommandPathMarker obj = EffectsMan.inst.PathMarker.Create(Vector3.zero) as CommandPathMarker;
						obj.ShowPath(path, World.inst.RelationBetween(moveTarget.TeamID(), teamId) == World.Relations.Enemy);
						obj.Play();
						doShowPath = false;
					}
				}
				else
				{
					lastPathBlocked = true;
					Vector3 vector3 = vector2 - vector;
					vector3.Normalize();
					Vector3 vector4 = new Vector3((float)(int)vector.x + 0.5f, 0f, (float)(int)vector.z + 0.5f);
					for (int i = 1; i < catapult.range; i++)
					{
						Cell cellDataClamped = World.inst.GetCellDataClamped(vector4 + vector3 * i);
						if (cellDataClamped.OccupyingStructure.Count > 0 && !ShouldIgnore(cellDataClamped.OccupyingStructure[0]))
						{
							catapult.SetTarget(cellDataClamped.OccupyingStructure[0]);
							break;
						}
					}
				}
			}
			if (!arrived && path.Count > 0)
			{
				Vector3 vector5 = path.data[pathIdx];
				Vector3 zero = Vector3.zero;
				float num = Speed * dt * speedMul;
				while (num > 0f)
				{
					vector5 = path.data[pathIdx];
					if (Mathff.MoveTowards(vector, vector5, num, out var actualAmt, out var newPos))
					{
						pathIdx++;
					}
					vector = newPos;
					num -= actualAmt;
					if (pathIdx == path.Count)
					{
						arrived = true;
						break;
					}
				}
				if (isVisible)
				{
					for (int j = 0; j < wheels.Length; j++)
					{
						wheels[j].Rotate(num / 0.05f * 57.29578f, 0f, 0f);
					}
				}
				base.transform.SetPositionAndRotation(vector, Quaternion.RotateTowards(base.transform.rotation, Quaternion.LookRotation(zero), 240f * dt));
			}
			if (catapult.TargetInRange())
			{
				path.Clear();
				arrived = true;
				status = Status.Attacking;
			}
			else if ((arrived || ((moveTarget == null || moveTarget.Equals(null)) && path.Count == 0)) && deferredPath.status == GamePath.Status.Uninitialized && !catapult.IsTargetValid())
			{
				Building building = Catapult.FindTarget(catapult, ShouldIgnoreAutoTarget, lastPos);
				if (building != null)
				{
					catapult.manned = true;
					catapult.SetTarget(building);
					status = Status.Attacking;
				}
			}
			break;
		case Status.Attacking:
			if (catapult.IsTargetValid())
			{
				Quaternion to = Quaternion.LookRotation((catapult.target.GetPos() - base.transform.position).xz().normalized);
				base.transform.rotation = Quaternion.RotateTowards(base.transform.rotation, to, 240f * Time.deltaTime);
				break;
			}
			moveTarget = null;
			catapult.SetTarget(null);
			catapult.manned = false;
			TransitionToSeeking();
			break;
		case Status.Dead:
			UnitSystem.inst.DestroyUnit(this);
			break;
		}
		ParticleSystem.EmissionModule emission = wake.emission;
		emission.rateOverTime = (arrived ? 0f : origEmissionRate);
		unitGUI.transform.position = vector;
		float num2 = 0f;
		if (status != Status.Dead && status != Status.BeingCarried)
		{
			Cell cellData = World.inst.GetCellData(vector);
			if ((cellData != null && cellData.Type == TerrainType.Water && !cellData.StructureCompareCategory(World.pathHash)) || status == Status.BeingCarried)
			{
				speedMul = 0.75f;
				if (!wake.isStopped)
				{
					wake.Stop();
				}
				num2 = ((!cellData.deepWater) ? (-0.2f) : (-0.4f));
			}
			else
			{
				speedMul = 1f;
				if (wake.isStopped)
				{
					wake.Play();
				}
			}
			if (isVisible)
			{
				Vector3 position = vector;
				position.y = num2;
				base.transform.position = position;
			}
		}
		healthBar.life = life / maxLife;
		healthBar.SetPos(vector + new Vector3(0f, 2f, 0f));
		lastVel = (vector - lastPos) / dt;
		lastPos = vector;
		if (footSoldiers != null)
		{
			if (!isVisible)
			{
				for (int k = 0; k < footSoldiers.Length; k++)
				{
					footSoldiers[k].gameObject.SetActive(value: false);
				}
			}
			else
			{
				Vector3 forward = base.transform.forward;
				float radians = 0f - Mathf.Atan2(forward.z, forward.x);
				Quaternion quat = Quaternion.identity;
				for (int l = 0; l < footSoldiers.Length; l++)
				{
					if (status != Status.BeingCarried)
					{
						footSoldiers[l].gameObject.SetActive(value: true);
					}
					float num3 = 0f;
					float num4 = 1f;
					float num5 = 1f;
					Transform obj2 = footSoldiers[l];
					Transform transform = soldierPositions[l];
					float num6 = 5f;
					float num7 = 0.03f;
					Vector3 position2 = obj2.position;
					Cell cellDataClamped2 = World.inst.GetCellDataClamped(position2);
					if (cellDataClamped2 != null && cellDataClamped2.Type == TerrainType.Water && cellDataClamped2.StructureGetCategoryHash() != pathHash)
					{
						num3 = -0.4f;
						num4 = 0.35f;
						num5 = 0.5f;
					}
					Vector3 vector6 = transform.position - position2;
					vector6.y = 0f;
					Vector3 position3 = ((!(vector6.magnitude > soldierMaxDistance)) ? Vector3.Lerp(position2, transform.position, dt * 3f) : (transform.position + vector6.normalized * (0f - soldierMaxDistance)));
					position3.y = position2.y;
					position3.y = Mathff.Lerp(b: Player.inst.walkBounce.Evaluate(totalTime), a: position3.y, T: Mathff.Min(dt * 30f, 1f)) * num7 * num4;
					position3.y += num2;
					Mathff.SetRotationY(ref quat, radians);
					obj2.SetPositionAndRotation(position3, quat);
					totalTime += dt * num6 * num5;
					if (totalTime > 1f)
					{
						totalTime = 0f;
					}
				}
			}
		}
		blockingTime -= dt;
	}

	private void TransitionToSeeking()
	{
		if (status != Status.Seeking)
		{
			arrived = false;
			status = Status.Seeking;
		}
	}

	public static void AddInView(Plane[] planes, ref List<ISelectable> objs)
	{
		for (int i = 0; i < SiegeCatapultSystem.siegeCatapults.Count; i++)
		{
			if (GeometryUtility.TestPlanesAABB(planes, SiegeCatapultSystem.siegeCatapults.data[i].GetComponentInChildren<Renderer>().bounds))
			{
				objs.Add(SiegeCatapultSystem.siegeCatapults.data[i]);
			}
		}
	}

	public bool IntersectsRay(Ray ray, out float hitDist)
	{
		hitDist = float.MaxValue;
		float num = 0.45f;
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
		if (status != Status.Dead)
		{
			return status != Status.BeingCarried;
		}
		return false;
	}

	int IUnitControllable.GetUnitType()
	{
		return 2;
	}

	public int TeamID()
	{
		return teamId;
	}

	public Vector3 GetPos()
	{
		return lastPos;
	}

	public int GetMoveType()
	{
		return 0;
	}

	public int GetAttackType()
	{
		return 1;
	}

	public int GetLOS()
	{
		return 10;
	}

	public void MoveTo(IMoveTarget target)
	{
		IsBeingCarried();
		if (!lastPathBlocked || moveTarget != target || status != Status.Attacking)
		{
			moveTarget = target;
			forceUpdatePath = true;
			doShowPath = true;
			IMoveTarget target2 = null;
			bool manned = false;
			if (target is IProjectileHitable && World.inst.RelationBetween(teamId, target.TeamID()) == World.Relations.Enemy && ((target is Building b && !ShouldIgnore(b)) || !(target is Building)))
			{
				target2 = target;
				manned = true;
			}
			catapult.SetTarget(target2);
			catapult.manned = manned;
			TransitionToSeeking();
		}
	}

	public IMoveTarget GetMoveTarget()
	{
		return moveTarget;
	}

	public UnitType GetUnitType()
	{
		return UnitType.SiegeWeapon;
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
		return blockingTime > 0f;
	}

	public Vector3 GetToNextCell()
	{
		if (blockingTime > 0f)
		{
			return blockDir;
		}
		return transform.forward;
	}

	public void OnUnitTargetsUs(IUnitControllable u)
	{
	}

	public void OnUnitStoppedTargetingUs(IUnitControllable u)
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
			status = Status.BeingCarried;
			for (int i = 0; i < footSoldiers.Length; i++)
			{
				footSoldiers[i].gameObject.SetActive(value: false);
			}
			if (!wake.isStopped)
			{
				wake.Stop();
			}
			return true;
		}
		return false;
	}

	public void StopBeingCarried()
	{
		for (int i = 0; i < footSoldiers.Length; i++)
		{
			footSoldiers[i].gameObject.SetActive(value: true);
		}
		TransitionToSeeking();
	}

	public int CarryCount()
	{
		return 0;
	}

	public IUnitControllable GetCarried(int i)
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

	public bool PendingCarry(IUnitControllable u)
	{
		return false;
	}

	public bool IsPendingLoadTargets()
	{
		return false;
	}

	public void DoUnload(IUnitControllable u)
	{
	}

	public float CurrHealth()
	{
		return life;
	}

	public float MaxHealth()
	{
		return maxLife;
	}

	public void NotifyOtherUnitDeath(IUnitControllable u)
	{
		if (moveTarget == u)
		{
			moveTarget = null;
		}
		if (catapult.target == u)
		{
			catapult.SetTarget(null);
		}
	}

	public void DestroyUnit()
	{
		status = Status.Dead;
		SiegeCatapultSystem.siegeCatapults.RemoveSwap(this);
		UnityEngine.Object.Destroy(gameObject);
	}

	public Guid GetGuid()
	{
		return guid;
	}
}
