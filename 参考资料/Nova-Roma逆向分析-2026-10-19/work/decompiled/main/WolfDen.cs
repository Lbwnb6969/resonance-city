using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using UnityEngine;

public class WolfDen : Tickable, IMoveTarget
{
	public class WolfData : InstanceSystemBehaviour.Owner, IProjectileHitable
	{
		public Vector3 origPos;

		public Vector3 pos;

		public Vector3 attackVec;

		public Vector3 subTileOffset;

		public float rot;

		public Status status;

		public float currAttackTime;

		public float speed;

		public float cooldownTime;

		public float villagerCooldownTime;

		public float life;

		public float deathTimer;

		public float animTime;

		public int lastKillTeamID = -1;

		public Vector3 GetPosition()
		{
			return pos;
		}

		public Vector3 GetPredictedPosition(float time)
		{
			return pos;
		}

		public float GetRadius()
		{
			return 0.25f;
		}

		public Vector3 GetVelocity()
		{
			return Vector3.zero;
		}

		public bool IsInvalid()
		{
			return status == Status.Dying;
		}

		public HitSfxResult TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int teamID)
		{
			lastKillTeamID = teamID;
			life -= dmg;
			return HitSfxResult.None;
		}
	}

	public enum Status
	{
		Wander,
		Chase,
		Attack,
		Dying
	}

	[Serializable]
	public class WolfDenSaveData : SaveClass<WolfDen, WolfDenSaveData>
	{
		public int x;

		public int z;

		public int wolfCount;

		[OptionalField(VersionAdded = 2)]
		public Guid guid;

		public override WolfDenSaveData Pack(WolfDen obj)
		{
			x = (int)obj.transform.position.x;
			z = (int)obj.transform.position.z;
			wolfCount = obj.WolfCount();
			guid = obj.guid;
			return this;
		}

		public override WolfDen Unpack(WolfDen obj)
		{
			obj.SetWolfCount(wolfCount);
			obj.guid = guid;
			return obj;
		}
	}

	private static int frameUpdateID = 0;

	private FrameUpdater targetUpdate;

	[NonSerialized]
	public Guid guid = Guid.NewGuid();

	private ArrayExt<Vector3> wanderPositions;

	private static Vector3[] wanderPositionTemplate = new Vector3[9]
	{
		new Vector3(-1f, 0f, 1f),
		new Vector3(1f, 0f, 0f),
		new Vector3(-1f, 0f, -1f),
		new Vector3(1f, 0f, -1f),
		new Vector3(-1f, 0f, 0f),
		new Vector3(1f, 0f, 1f),
		new Vector3(0f, 0f, -1f),
		new Vector3(0f, 0f, 1f),
		new Vector3(0f, 0f, 0f)
	};

	public float wolfSpeed = 1f;

	public float chaseRadius = 2.5f;

	public static ArrayExt<WolfData> wolves = new ArrayExt<WolfData>(100);

	private int lastKillTeamID = -1;

	[NonSerialized]
	public ArrayExt<WolfData> wolfData = new ArrayExt<WolfData>(5);

	private float coolDownTimeVillagerKill = 150f;

	public float coolDownTimeUnitAttack = 0.5f;

	private const float maxLife = 6.25f;

	public static List<WolfDen> wolfDens = new List<WolfDen>();

	public AnimationCurve attackAnim;

	private bool firstUpdate = true;

	public float rotSpeed = 90f;

	public float attackTime = 0.25f;

	private float bounceMagnitude = 0.05f;

	private float wolfSpawnTime;

	private int wanderPosIdx;

	private Vector3 wanderPos;

	private List<WolfData> deferredRemoval = new List<WolfData>();

	private static int foresterHash = "forester".GetHashCode();

	private IProjectileHitable target;

	private float cooldown;

	public float cooldownTime = 5f;

	public static int territory = 2;

	public Vector3 GetPredictedPosition(float time)
	{
		return GetPos();
	}

	bool IMoveTarget.IsStationary()
	{
		return true;
	}

	public WolfDen()
	{
		targetUpdate = new FrameUpdater(ref frameUpdateID, 20);
	}

	public int WolfCount()
	{
		return wolfData.Count;
	}

	public void SetWolfCount(int numWolves)
	{
		for (int i = 0; i < wolfData.Count; i++)
		{
			WolfSystem.inst.ReleaseInstance(wolfData.data[i]);
			wolves.RemoveSwap(wolfData.data[i]);
		}
		wolfData.Clear();
		for (int j = 0; j < numWolves; j++)
		{
			AddWolf();
		}
	}

	public void AddWolf()
	{
		WolfData wolfData = new WolfData();
		wolfData.origPos = new Vector3(SRand.Range(0f, 1f), 0f, SRand.Range(0f, 1f));
		wolfData.rot = 0f;
		wolfData.status = Status.Wander;
		wolfData.speed = 1f + SRand.Range(0f, 0.3f);
		wolfData.subTileOffset = new Vector3(SRand.Range(0f, 1f), 0f, SRand.Range(0f, 1f));
		wolfData.life = 6.25f;
		wolfData.deathTimer = 1f;
		wolfData.animTime = SRand.Range(0f, 1f);
		wolves.Add(wolfData);
		this.wolfData.Add(wolfData);
		wolfData.pos = transform.position + wolfData.origPos;
		WolfSystem.inst.AddInstance(wolfData, wolfData.pos, Quaternion.identity, Vector3.one);
	}

	public static WolfData ClosestWolf(Vector3 pos)
	{
		WolfDen wolfDen = null;
		float num = float.MaxValue;
		for (int i = 0; i < wolfDens.Count; i++)
		{
			float num2 = Mathff.DistSqrdXZ(wolfDens[i].transform.position, pos);
			if (num2 < num)
			{
				num = num2;
				wolfDen = wolfDens[i];
			}
		}
		if (wolfDen != null)
		{
			WolfData result = null;
			num = float.MaxValue;
			for (int j = 0; j < wolfDen.wolfData.Count; j++)
			{
				WolfData wolfData = wolfDen.wolfData.data[j];
				if (!wolfData.IsInvalid())
				{
					float num3 = Mathff.DistSqrdXZ(wolfData.pos, pos);
					if (num3 < num)
					{
						num = num3;
						result = wolfData;
					}
				}
			}
			return result;
		}
		return null;
	}

	public static WolfDen GetWolfDen(Guid guid)
	{
		for (int i = 0; i < wolfDens.Count; i++)
		{
			if (wolfDens[i].guid == guid)
			{
				return wolfDens[i];
			}
		}
		return null;
	}

	public static int GetWolfDenCountPerLandmass(int lm)
	{
		int num = 0;
		for (int i = 0; i < wolfDens.Count; i++)
		{
			WolfDen wolfDen = wolfDens[i];
			if (World.inst.GetCellData((int)wolfDen.transform.position.x, (int)wolfDen.transform.position.z).landMassIdx == lm)
			{
				num++;
			}
		}
		return num;
	}

	public override void OnEnableInternal()
	{
		wolfDens.Add(this);
		base.OnEnableInternal();
	}

	public override void OnDisableInternal()
	{
		Vector3 s = transform.position + new Vector3(0.5f, 0f, 0.5f);
		World.inst.ForEachTileTouchingRadius(s, territory, (int x, int z, Cell c) =>
		{
			if (c != null)
			{
				c.wolfTerritory = false;
			}
		});
		wolfDens.Remove(this);
		for (int num = 0; num < wolfData.Count; num++)
		{
			WolfSystem.inst.ReleaseInstance(wolfData.data[num]);
			wolves.RemoveSwap(wolfData.data[num]);
		}
		wolfData.Clear();
		base.OnDisableInternal();
	}

	private void ChangeStatus(int i, Status newStatus)
	{
		if (newStatus != wolfData.data[i].status)
		{
			if (newStatus == Status.Attack)
			{
				wolfData.data[i].currAttackTime = 0f;
			}
			if (newStatus == Status.Dying)
			{
				EffectsMan.inst.GibsEffect.CreateAndPlay(wolfData.data[i].pos);
			}
		}
		wolfData.data[i].status = newStatus;
	}

	private float AngleFacingPosition(Vector3 pos, Vector3 target)
	{
		float x = target.x - pos.x;
		return 0f - Mathf.Atan2(target.z - pos.z, x) + 1.5707f;
	}

	public override void Tick(float dt, int currFrame)
	{
		if (firstUpdate)
		{
			int num = (int)transform.position.z * World.inst.GridHeight + (int)transform.position.x;
			transform.GetChild(0).localRotation = Quaternion.Euler(0f, num % 4 * 90, 0f);
			wanderPos = transform.position;
			Vector3 vector = transform.position + new Vector3(0.5f, 0f, 0.5f);
			World.inst.ForEachTileTouchingRadius(vector, territory, (int x, int z, Cell c) =>
			{
				c.wolfTerritory = true;
			});
			wanderPositions = new ArrayExt<Vector3>(wanderPositionTemplate.Length);
			for (int num2 = 0; num2 < wanderPositionTemplate.Length; num2++)
			{
				Vector3 vector2 = vector + wanderPositionTemplate[num2];
				Cell cellData = World.inst.GetCellData(vector2);
				if (cellData != null && cellData.Type != TerrainType.Water)
				{
					wanderPositions.Add(vector2);
				}
			}
			wanderPosIdx = SRand.Range(0, wanderPositions.Count);
			firstUpdate = false;
		}
		int num3 = 0;
		if (WolfCount() < 12)
		{
			wolfSpawnTime += dt;
			if (wolfSpawnTime > 800f)
			{
				AddWolf();
				wolfSpawnTime = 0f;
			}
		}
		targetUpdate.Update();
		if (targetUpdate.Trigger())
		{
			target = AcquireTarget();
		}
		if (target == null || target.Equals(null) || target.IsInvalid())
		{
			target = null;
		}
		if (target == null || (target != null && Mathff.DistSqrdXZ(target.GetPosition(), transform.position) > (float)(territory * territory)))
		{
			target = null;
			for (int num4 = 0; num4 < this.wolfData.Count; num4++)
			{
				ChangeStatus(num4, Status.Wander);
			}
		}
		Matrix4x4[][] data = WolfSystem.inst.silos.data;
		Vector3 zero = Vector3.zero;
		Vector3 one = Vector3.one;
		float num5 = dt * wolfSpeed * 0.33f;
		_ = rotSpeed;
		float num6 = dt * (1f / 120f);
		int num7 = 0;
		Vector3 next = default;
		for (int num8 = this.wolfData.Count; num7 < num8; num7++)
		{
			WolfData wolfData = this.wolfData.data[num7];
			lastKillTeamID = wolfData.lastKillTeamID;
			if (wolfData.life <= 0f)
			{
				ChangeStatus(num7, Status.Dying);
			}
			switch (wolfData.status)
			{
			case Status.Wander:
			{
				num3++;
				Vector3 subTileOffset = this.wolfData.data[num7].subTileOffset;
				next.x = wanderPos.x + subTileOffset.x;
				next.y = wanderPos.y + subTileOffset.y;
				next.z = wanderPos.z + subTileOffset.z;
				if (Mathff.MoveTowards(wolfData.pos, next, num5 * this.wolfData.data[num7].speed, out var _, out wolfData.pos))
				{
					GetNewWanderPos();
				}
				else
				{
					wolfData.rot = AngleFacingPosition(wolfData.pos, next);
				}
				wolfData.cooldownTime -= dt;
				wolfData.villagerCooldownTime -= dt;
				if (wolfData.cooldownTime <= 0f && target != null)
				{
					bool flag = true;
					if (target is Villager && wolfData.villagerCooldownTime > 0f)
					{
						flag = false;
					}
					if (flag)
					{
						ChangeStatus(num7, Status.Chase);
					}
				}
				wolfData.life += num6;
				if (wolfData.life > 6.25f)
				{
					wolfData.life = 6.25f;
				}
				break;
			}
			case Status.Chase:
			{
				float num11 = MoveToward(num7, target.GetPosition(), dt * wolfSpeed);
				wolfData.rot = AngleFacingPosition(wolfData.pos, target.GetPosition());
				if (num11 < 0.3f)
				{
					ChangeStatus(num7, Status.Attack);
				}
				break;
			}
			case Status.Attack:
				wolfData.rot = AngleFacingPosition(wolfData.pos, target.GetPosition());
				wolfData.attackVec = target.GetPosition() - wolfData.pos;
				wolfData.attackVec.Normalize();
				wolfData.attackVec *= 0.1f;
				wolfData.attackVec *= attackAnim.Evaluate(Mathff.Clamp01(wolfData.currAttackTime));
				if (wolfData.currAttackTime > 1f)
				{
					if (target is Villager)
					{
						Villager villager = target as Villager;
						int teamId = World.GetLandmassOwner(villager.landMass).teamId;
						Broadcast.WolfKillVillagerEvent.Broadcast(new OnWolfKillVillager
						{
							eventPosition = villager.Pos,
							teamID = teamId
						});
						Player.inst.DestroyPerson(villager, leaveBehindBody: false);
						EffectsMan.inst.GibsEffect.CreateAndPlay(villager.Pos + new Vector3(0f, 0f, 0f));
						for (int num9 = 0; num9 < this.wolfData.Count; num9++)
						{
							this.wolfData.data[num9].villagerCooldownTime = coolDownTimeVillagerKill;
						}
						wolfData.cooldownTime = coolDownTimeUnitAttack;
					}
					else
					{
						target.TakeProjectileDamage(1f, DamageType.Standard, DamageSource.Melee, wolfData.pos, wolfData.attackVec, -1);
						wolfData.cooldownTime = 0f;
					}
					target = null;
					for (int num10 = 0; num10 < this.wolfData.Count; num10++)
					{
						ChangeStatus(num10, Status.Wander);
					}
				}
				wolfData.currAttackTime += dt / attackTime;
				break;
			case Status.Dying:
				deferredRemoval.Add(this.wolfData.data[num7]);
				break;
			}
			zero.x = wolfData.pos.x + wolfData.attackVec.x;
			zero.y = wolfData.pos.y + wolfData.attackVec.y + Player.inst.walkBounce.Evaluate(wolfData.animTime) * bounceMagnitude;
			zero.z = wolfData.pos.z + wolfData.attackVec.z;
			wolfData.animTime += dt * 5f;
			if (wolfData.animTime >= 1f)
			{
				wolfData.animTime = 0f;
			}
			Mathff.SetTRS(ref data[wolfData.s][wolfData.idx], zero, Mathff.QuatFromYRot(wolfData.rot), one);
		}
		for (int num12 = 0; num12 < deferredRemoval.Count; num12++)
		{
			WolfSystem.inst.ReleaseInstance(deferredRemoval[num12]);
			this.wolfData.RemoveSwap(deferredRemoval[num12]);
		}
		deferredRemoval.Clear();
		if (this.wolfData.Count == 0)
		{
			UnityEngine.Object.Destroy(gameObject);
			World.inst.AddEmptyCave((int)transform.position.x, (int)transform.position.z);
			int landMassIdx = World.inst.GetCellData((int)transform.position.x, (int)transform.position.z).landMassIdx;
			World.inst.WolfDenCleared(landMassIdx, lastKillTeamID);
		}
	}

	private float MoveToward(int i, Vector3 pos, float amt)
	{
		wolfData.data[i].pos = Mathff.MoveTowards(wolfData.data[i].pos, pos, amt);
		Vector3 a = pos - wolfData.data[i].pos;
		a.y = 0f;
		return Mathff.MagnitudeXZ(a);
	}

	private void GetNewWanderPos()
	{
		wanderPosIdx++;
		Vector3 vector = wanderPositions.data[wanderPosIdx % wanderPositions.Count];
		wanderPos = new Vector3((int)vector.x, 0f, (int)vector.z);
		for (int i = 0; i < wolfData.Count; i++)
		{
			WolfData obj = wolfData.data[i];
			obj.subTileOffset.x = SRand.Range(0f, 1f);
			obj.subTileOffset.y = 0f;
			obj.subTileOffset.z = SRand.Range(0f, 1f);
		}
	}

	private IProjectileHitable AcquireTarget()
	{
		Vector3 position = transform.position;
		IMoveableUnit moveableUnit = OrdersManager.inst.ClosestEnemyUnit(position, territory * 2, -1);
		if (moveableUnit != null)
		{
			return moveableUnit as IProjectileHitable;
		}
		int num = Mathff.Clamp((int)position.x - territory, 0, World.inst.GridWidth - 1);
		int num2 = Mathff.Clamp((int)position.z - territory, 0, World.inst.GridHeight - 1);
		int num3 = Mathff.Clamp((int)position.x + territory, 0, World.inst.GridWidth - 1);
		int num4 = Mathff.Clamp((int)position.z + territory, 0, World.inst.GridHeight - 1);
		int landMassIdx = World.inst.GetCellData((int)transform.position.x, (int)transform.position.z).landMassIdx;
		int num5 = World.inst.GetVillagersForLandMass(landMassIdx).Count;
		if ((!Player.inst.LandMassIsAPlayerLandMass(landMassIdx)) ? (num5 >= 50) : (num5 >= 10))
		{
			float num6 = float.MaxValue;
			IProjectileHitable result = null;
			for (int i = num2; i <= num4; i++)
			{
				for (int j = num; j <= num3; j++)
				{
					ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(j, i);
					for (int k = 0; k < villagersAt.Count; k++)
					{
						if (!villagersAt.data[k].paralyzed && (villagersAt.data[k].job == null || !(villagersAt.data[k].job.employer is Building) || (villagersAt.data[k].job.employer as Building).uniqueNameHash != foresterHash))
						{
							float num7 = Mathff.DistSqrdXZ(villagersAt.data[k].Pos, position);
							if (num7 < num6)
							{
								result = villagersAt.data[k];
								num6 = num7;
							}
						}
					}
				}
			}
			return result;
		}
		return null;
	}

	public Vector3 GetPos()
	{
		return transform.position;
	}

	public int TeamID()
	{
		return -1;
	}
}
