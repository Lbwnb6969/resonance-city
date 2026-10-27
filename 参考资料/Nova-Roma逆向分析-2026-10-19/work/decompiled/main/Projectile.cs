using System;
using UnityEngine;

public class Projectile : PooledObject
{
	private enum State
	{
		InFlight,
		Hit
	}

	public IProjectileHitable target;

	public float attackDamage = 1f;

	public float hitRadius = 1f;

	[NonSerialized]
	public float initVel;

	private Vector3 lastDir;

	[NonSerialized]
	public Vector3 initPos;

	private float time;

	public int teamID;

	private State state;

	public override void Init()
	{
		state = State.InFlight;
		time = 0f;
		base.Init();
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		if (state != State.InFlight)
		{
			_ = 1;
			return;
		}
		time += deltaTime;
		if (time > 20f)
		{
			Release();
		}
		transform.position += lastDir * initVel * deltaTime;
		transform.rotation = Quaternion.LookRotation(lastDir, new Vector3(0f, 1f, 0f));
		if (target == null || target.Equals(null) || target.IsInvalid())
		{
			return;
		}
		Vector3 position = transform.position;
		Vector3 incomingVel = target.GetPosition() - position;
		float num = incomingVel.x * incomingVel.x + incomingVel.y * incomingVel.y + incomingVel.z * incomingVel.z;
		incomingVel /= Mathf.Sqrt(num);
		lastDir = incomingVel;
		if (num < hitRadius * hitRadius)
		{
			float num2 = attackDamage;
			LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(teamID);
			if (landmassOwnerByTeamId != null)
			{
				num2 *= (landmassOwnerByTeamId.HasUpgrade(Player.UpgradeType.ArmorPiercingBallistas) ? 1.33f : 1f);
			}
			target.TakeProjectileDamage(num2, DamageType.Standard, DamageSource.Ranged, transform.position, incomingVel, teamID);
			Release();
		}
	}

	public void Setup(Vector3 pos, float speed, IProjectileHitable t)
	{
		target = t;
		initPos = pos;
		initVel = speed;
		target = t;
		transform.position = initPos;
		Vector3 forward = target.GetPosition() - pos;
		transform.rotation = Quaternion.LookRotation(forward, new Vector3(0f, 1f, 0f));
		lastDir = forward;
	}
}
