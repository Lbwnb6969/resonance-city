using UnityEngine;

public class ArrowDamage : Tickable
{
	public delegate float rangeFunc();

	public delegate float dpsFunc();

	public ArrowHailEffect arrowHail;

	private ArcherTower archerTower;

	private static int updateFrameCount;

	private int updateFrame;

	private int frameSpread = 30;

	private float origEmission;

	public Building b;

	private IProjectileHitable attackTarget;

	private float targetSwitchTime;

	public rangeFunc GetMaxRange;

	public dpsFunc EffectiveDPS;

	public bool ignoreWorkerChecks;

	private bool workersNear;

	private bool firstUpdate;

	private const int workersFrameSpread = 5;

	private int workersUpdateFrame = SRand.srand.Next(0, 5);

	private Timer hitTimer = new Timer(0.25f);

	private void Start()
	{
		updateFrame = updateFrameCount++;
		updateFrame %= frameSpread;
		ParticleSystem.EmissionModule emission = arrowHail.ps.emission;
		origEmission = emission.rateOverTime.constant;
		emission.rateOverTime = 0f;
		arrowHail.ps.Play();
		archerTower = GetComponent<ArcherTower>();
	}

	public override void Tick(float dt, int currFrame)
	{
		if (!b.IsBuilt())
		{
			return;
		}
		bool flag = false;
		if (currFrame % frameSpread == updateFrame)
		{
			IProjectileHitable projectileHitable = ProjectileDefense.GetTarget(b.Center(), 0f, 15f, b.TeamID(), (IUnitControllable unit) => archerTower.CanHit(unit.GetPos()));
			if (archerTower != null && projectileHitable != null)
			{
				Vector3 predictedPosition = projectileHitable.GetPredictedPosition(1f);
				if (!archerTower.CanHit(predictedPosition))
				{
					projectileHitable = null;
				}
			}
			flag = false;
			if (projectileHitable != null && (attackTarget == null || attackTarget.Equals(null) || (projectileHitable != attackTarget && Mathff.DistSqrdXZ(projectileHitable.GetPredictedPosition(0.5f), attackTarget.GetPredictedPosition(0.5f)) > 2.25f)))
			{
				flag = true;
			}
			attackTarget = projectileHitable;
		}
		if (currFrame % 5 == workersUpdateFrame || firstUpdate)
		{
			workersNear = b.AreWorkersNear(b.jobs.Count);
		}
		float num = b.GetWorkerPercent() * (float)(workersNear ? 1 : 0);
		if (attackTarget != null && !attackTarget.Equals(null) && !attackTarget.IsInvalid() && (num > 0f || ignoreWorkerChecks))
		{
			if (archerTower != null)
			{
				Vector3 predictedPosition2 = attackTarget.GetPredictedPosition(1f);
				if (!archerTower.CanHit(predictedPosition2))
				{
					attackTarget = null;
					ParticleSystem.EmissionModule emission = arrowHail.ps.emission;
					emission.rateOverTime = 0f;
					return;
				}
			}
			ParticleSystem.EmissionModule emission2 = arrowHail.ps.emission;
			emission2.rateOverTime = origEmission;
			float num2 = arrowHail.SetTarget(attackTarget.GetPredictedPosition(1f), attackTarget.GetVelocity());
			if (flag)
			{
				targetSwitchTime = num2;
			}
			targetSwitchTime -= dt;
			if (!(targetSwitchTime <= 0f) || !hitTimer.Update(dt))
			{
				return;
			}
			float num3 = EffectiveDPS() * hitTimer.Duration;
			if (attackTarget is ArmySystem.Army)
			{
				num3 *= 2f;
			}
			int num4 = 0;
			Cell cell = b.GetCell();
			CellProductionInfluence cellProductionInfluenceDataClamped = World.inst.GetCellProductionInfluenceDataClamped(cell.x, cell.z);
			for (int num5 = 0; num5 < cellProductionInfluenceDataClamped.radiusBonusesBuilding.Count; num5++)
			{
				if (cellProductionInfluenceDataClamped.radiusBonusesBuilding[num5].GetBonus() > num4)
				{
					num4 = cellProductionInfluenceDataClamped.radiusBonusesBuilding[num5].GetBonus();
				}
			}
			num3 *= 1f + (float)num4 / 100f;
			attackTarget.TakeProjectileDamage(num3, DamageType.Standard, DamageSource.Ranged, b.Center(), attackTarget.GetPosition() - b.Center(), b.TeamID());
		}
		else
		{
			ParticleSystem.EmissionModule emission3 = arrowHail.ps.emission;
			emission3.rateOverTime = 0f;
		}
	}
}
