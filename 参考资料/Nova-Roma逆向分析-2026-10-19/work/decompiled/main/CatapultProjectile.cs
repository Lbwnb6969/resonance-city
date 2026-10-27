using UnityEngine;

public class CatapultProjectile : PooledObject
{
	private int teamID;

	private IProjectileHitable target;

	private Vector3 targetPos;

	public float airSpeed = 5f;

	private float unitDamage = 25f;

	private float buildingDamage = 0.25f;

	public CatapultProjectile Create(Vector3 pos, Quaternion rot, IProjectileHitable target, int teamId)
	{
		CatapultProjectile catapultProjectile = Alloc(pos, rot) as CatapultProjectile;
		catapultProjectile.target = target;
		if (target is Building)
		{
			(target as Building).GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
			catapultProjectile.targetPos = new Vector3(SRand.Range((float)minX + 0.25f, (float)maxX - 0.25f), 0f, SRand.Range((float)minZ + 0.25f, (float)maxZ - 0.25f));
		}
		else
		{
			catapultProjectile.targetPos = target.GetPosition();
		}
		catapultProjectile.teamID = teamId;
		return catapultProjectile;
	}

	public override void Init()
	{
		base.Init();
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (target != null && !target.Equals(null) && !target.IsInvalid())
		{
			Vector3 position = transform.position;
			Vector3 vector = targetPos - position;
			vector.Normalize();
			position += vector * airSpeed * dt;
			transform.position = position;
			bool flag = target as Building != null;
			if (Mathff.DistSqrd(position, flag ? targetPos : target.GetPosition()) < 0.25f)
			{
				switch (target.TakeProjectileDamage(flag ? buildingDamage : unitDamage, DamageType.AOE, DamageSource.Ranged, position, vector * airSpeed * dt, teamID))
				{
				case HitSfxResult.Stone:
				{
					SfxSystem.inst.PlayFromBankIfVisible("CatapultHitStone", transform.position);
					OneOffEffect oneOffEffect2 = EffectsMan.inst.WallHitEffect.Create(position);
					oneOffEffect2.transform.rotation = Quaternion.LookRotation(-vector);
					oneOffEffect2.Play();
					EffectsMan.inst.BuildPuff.CreateAndPlay(position);
					break;
				}
				case HitSfxResult.Wood:
				{
					SfxSystem.inst.PlayFromBankIfVisible("CatapultHitWood", transform.position);
					OneOffEffect oneOffEffect = EffectsMan.inst.WoodHitEffect.Create(position);
					oneOffEffect.transform.rotation = Quaternion.LookRotation(-vector);
					oneOffEffect.Play();
					EffectsMan.inst.BuildPuff.CreateAndPlay(position);
					break;
				}
				}
				target = null;
			}
			if (Mathff.DistSqrd(position, targetPos) < 0.25f)
			{
				target = null;
			}
		}
		else
		{
			Release();
		}
	}
}
