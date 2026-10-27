using System;
using UnityEngine;

public class ArrowHailEffect : MonoBehaviour
{
	public ParticleSystem ps;

	public Transform xform;

	private float targetDist;

	private float emitSound;

	private void Start()
	{
		xform = transform;
	}

	public float SetTarget(Vector3 target, Vector3 targetVel)
	{
		target += new Vector3(0f, 1.5f, 0f);
		targetDist = Mathf.Sqrt(Mathff.Sqr(target.x - xform.position.x) + Mathff.Sqr(target.z - xform.position.z));
		float x = transform.rotation.eulerAngles.x;
		float num = CalcInitVel(targetDist, transform.position.y, x, Mathf.Abs(Physics.gravity.y * ps.main.gravityModifierMultiplier));
		float num2 = targetDist / (num * Mathf.Cos(x * (MathF.PI / 180f)));
		Vector3 vector = target + targetVel * num2;
		targetDist = Mathf.Sqrt(Mathff.Sqr(vector.x - xform.position.x) + Mathff.Sqr(vector.z - xform.position.z));
		num = CalcInitVel(targetDist, transform.position.y, x, Mathf.Abs(Physics.gravity.y * ps.main.gravityModifierMultiplier));
		float num3 = Mathf.Atan2(target.x - xform.position.x, target.z - xform.position.z);
		transform.rotation = Quaternion.Euler(-45f, num3 * 57.29578f, 0f);
		return targetDist / (num * Mathf.Cos(x * (MathF.PI / 180f)));
	}

	private static float CalcInitVel(float targetDist, float yDelta, float launchAngle, float gravity)
	{
		float num = targetDist * Mathf.Sqrt(gravity) * (1f / Mathf.Cos(launchAngle));
		float num2 = Mathf.Sqrt(Mathf.Abs(2f * targetDist * Mathf.Abs(Mathf.Tan(launchAngle)) + 2f * yDelta));
		return Mathf.Abs(num / num2);
	}

	public void SetEmissionRate(float r)
	{
		ParticleSystem.EmissionModule emission = ps.emission;
		emission.rateOverTime = r;
	}

	private void LateUpdate()
	{
		if (ps.IsAlive() && ps.isEmitting && ps.emission.rateOverTime.constant > 0f)
		{
			float num = CalcInitVel(targetDist, transform.position.y, transform.rotation.eulerAngles.x, Mathf.Abs(Physics.gravity.y * ps.main.gravityModifierMultiplier));
			ParticleSystem.MainModule main = ps.main;
			main.startSpeed = num;
			emitSound -= Time.deltaTime;
			if (emitSound <= 0f)
			{
				emitSound = 1f / ps.emission.rateOverTime.constant;
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("arrowshoot", transform.position);
			}
		}
	}
}
