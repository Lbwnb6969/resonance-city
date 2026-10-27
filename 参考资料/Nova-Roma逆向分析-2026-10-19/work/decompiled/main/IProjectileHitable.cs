using UnityEngine;

public interface IProjectileHitable
{
	float GetRadius();

	Vector3 GetPosition();

	Vector3 GetVelocity();

	Vector3 GetPredictedPosition(float time);

	HitSfxResult TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int attackerTeamID);

	bool IsInvalid();
}
