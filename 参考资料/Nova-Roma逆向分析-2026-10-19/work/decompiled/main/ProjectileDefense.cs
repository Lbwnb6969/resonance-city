using System;
using Assets;
using UnityEngine;

public class ProjectileDefense : MonoBehaviour
{
	public Projectile projectilePrefab;

	private static int updateFrameCount;

	private int updateFrame;

	private int frameSpread = 30;

	public float TrackingRange = 4f;

	public float AttackRange = 2f;

	public float AttackTime = 2f;

	private float attackTimer;

	public Building b;

	[NonSerialized]
	public IProjectileHitable attackTarget;

	[NonSerialized]
	public IProjectileHitable trackingTarget;

	[NonSerialized]
	public bool suppressFiring;

	private int frameCount;

	public Transform overrideFireTransform;

	private void Start()
	{
		updateFrame = updateFrameCount++;
		updateFrame %= frameSpread;
	}

	public static IProjectileHitable GetTarget(Vector3 pos, float rangeMin, float range, int teamID, UnitSystem.ClosestEnemyFilter enemyFilter = null)
	{
		if (DragonSpawn.inst.currentDragons.Count > 0)
		{
			Dragon dragon = DragonSpawn.inst.ClosestDragon(pos);
			if ((bool)dragon && TestRange(dragon.transform.position, pos, range))
			{
				return dragon;
			}
		}
		IUnitControllable unitControllable = UnitSystem.inst.ClosestEnemyUnit(pos, range, teamID, enemyFilter);
		if (unitControllable != null && TestRange(unitControllable.GetPos(), pos, range))
		{
			return unitControllable as IProjectileHitable;
		}
		IProjectileHitable projectileHitable = WolfDen.ClosestWolf(pos);
		if (projectileHitable != null && TestRange(projectileHitable.GetPosition(), pos, range))
		{
			return projectileHitable;
		}
		return null;
	}

	public static bool TestRange(Vector3 targetPos, Vector3 pos, float range)
	{
		return Mathff.DistSqrdXZ(targetPos, pos) < range * range;
	}

	private void Update()
	{
		if (!b.IsBuilt() || b.GetWorkerPercent() <= 0f)
		{
			return;
		}
		frameCount++;
		if (frameCount % frameSpread == updateFrame)
		{
			trackingTarget = GetTarget(b.Center(), 0f, TrackingRange, b.TeamID());
		}
		float num = Time.deltaTime;
		if (StreamerEffects.Flag_FasterAttackSpeed)
		{
			num *= 2f;
		}
		attackTimer = Mathf.Max(0f, attackTimer - num);
		if (!(attackTimer <= 0f) || trackingTarget == null || trackingTarget.Equals(null) || trackingTarget.IsInvalid() || suppressFiring)
		{
			return;
		}
		attackTarget = GetTarget(b.Center(), 0f, AttackRange, b.TeamID());
		if (attackTarget != null)
		{
			trackingTarget = attackTarget;
			attackTimer = AttackTime;
			SendMessage("FireProjectile", SendMessageOptions.DontRequireReceiver);
			Transform start = transform;
			if ((bool)overrideFireTransform)
			{
				start = overrideFireTransform;
			}
			ProjectileSystem.inst.FireProjectile(start, attackTarget, projectilePrefab, b.TeamID());
		}
	}
}
