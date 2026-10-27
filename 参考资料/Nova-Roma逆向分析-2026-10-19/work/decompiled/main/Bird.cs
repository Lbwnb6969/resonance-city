using System;
using UnityEngine;

public class Bird : MonoBehaviour
{
	private enum State
	{
		Flying,
		Landing
	}

	public SkinnedMeshRenderer meshRenderer;

	private BlendShapeAnim anim = new BlendShapeAnim();

	private State state;

	private float FlyingTime = 3f;

	private float Duration;

	private float LandingTime = -999f;

	private Vector3 LandingPos;

	private Vector3 velocity;

	private Vector3 rotVel;

	private EventHandler<SeasonEventData> seasonChangeEvent;

	private SeasonDefinition _lastSeasonDefinition;

	internal Vector3 CurrLoc;

	internal Vector3 NextLoc;

	private Quaternion CurrRot;

	private Quaternion NextRot;

	private float timeStep = 0.1f;

	private float totalTime;

	public void Init()
	{
		Reset();
		anim.Init(4, meshRenderer);
	}

	public void Reset()
	{
		Fly();
		if (SRand.Range(0, 100) > 50)
		{
			Duration *= 0.5f;
		}
		totalTime = SRand.value * timeStep;
	}

	public void SetPosition(Vector3 P)
	{
		transform.position = P;
		CurrLoc = (NextLoc = P);
	}

	private void Land()
	{
		state = State.Landing;
		LandingPos = new Vector3(transform.position.x + 3f, 0f, transform.position.z + 3f);
		TerrainGen.inst.GetGroundHeight(ref LandingPos);
		_ = transform.position;
		TreeSystem.TreeData treeData = default;
		if (float.MaxValue < float.MaxValue)
		{
			Vector3 vector = treeData.scale * 0.15f;
			LandingPos = treeData.pos + new Vector3(SRand.Range(0f - vector.x, vector.x), SRand.Range(0f - vector.y, vector.y), SRand.Range(0f - vector.z, vector.z));
		}
		LandingTime = Time.time;
		Duration = SRand.Range(15, 20);
	}

	private void Fly()
	{
		state = State.Flying;
		FlyingTime = Time.time;
		Duration = SRand.Range(18, 25);
	}

	private void CalcFlyingForces(float dt, Bird[] birds, BirdSystem sys, Transform Bounds, ref Vector3 Accel)
	{
		Vector3 nextLoc = NextLoc;
		_ = transform.forward;
		Vector3 normalized = velocity.normalized;
		int num = 0;
		float repelRadius = sys.repelRadius;
		float num2 = repelRadius * repelRadius;
		float alignRadius = sys.alignRadius;
		float num3 = alignRadius * alignRadius;
		float attractRadius = sys.attractRadius;
		float num4 = attractRadius * attractRadius;
		for (int i = 0; i < birds.Length; i++)
		{
			if (birds[i] == this || birds[i].state == State.Landing)
			{
				continue;
			}
			Vector3 vector = birds[i].NextLoc - nextLoc;
			float num5 = vector.x * vector.x + vector.y * vector.y + vector.z * vector.z;
			if (!(num5 > num3) || !(num5 > num2) || !(num5 > num4))
			{
				if (num > 20)
				{
					break;
				}
				num++;
				float num6 = Mathf.Sqrt(num5) + 0.001f;
				Vector3 vector2 = vector / num6;
				if (num6 < sys.attractRadius)
				{
					float num7 = Mathff.Clamp01((attractRadius - num6) / attractRadius);
					Accel += vector2 * (dt * sys.attract * num7);
				}
				float num8 = Mathff.Clamp01(1f - num6 / repelRadius);
				Vector3 vector3 = normalized - Mathff.Clamp01(Vector3.Dot(vector2, normalized)) * vector2;
				if (vector3 == Vector3.zero)
				{
					vector3 = transform.right;
				}
				vector3.Normalize();
				Accel += vector3 * (dt * num8 * sys.repel);
				Accel += -vector2 * (dt * num8 * sys.repel);
				float num9 = Mathff.Clamp01(alignRadius - num6);
				num9 *= Mathf.Clamp01(Vector3.Dot(normalized, vector2));
				Accel += birds[i].velocity * (dt * num9 * sys.align);
			}
		}
		float num10 = Mathff.Clamp01(1f - (nextLoc.y - TerrainGen.inst.GetInterpolatedHeight(nextLoc)) / 4f);
		Accel.y += 1f * (dt * num10 * 20f);
		Vector3 vector4 = World.inst.GridCenter() - nextLoc;
		vector4.Normalize();
		Accel.x += vector4.x;
		Accel.z += vector4.z;
		if (!Mathff.BoxContains(Bounds, nextLoc))
		{
			Vector3 vector5 = Mathff.ClosestPointOnBox(Bounds, nextLoc) - nextLoc;
			Accel += Vector3.ClampMagnitude(vector5, 10f) * 10f;
			Vector3 vector6 = -vector5.normalized;
			Vector3 vector7 = vector6 * Mathff.Clamp01(Vector3.Dot(velocity, vector6));
			Accel += -vector7 * (dt * 10f);
		}
		else
		{
			float num11 = 0.5f;
			Vector3 vector8 = Mathff.ClosestPointOnBox(Bounds, nextLoc) - nextLoc;
			float magnitude = vector8.magnitude;
			if (magnitude > 0f)
			{
				vector8 /= magnitude;
			}
			else
			{
				vector8 = Vector3.zero;
			}
			if (magnitude < num11)
			{
				float num12 = 1f - magnitude / num11;
				Vector3 vector9 = normalized - Mathff.Clamp01(Vector3.Dot(normalized, -vector8)) * -vector8;
				vector9.Normalize();
				Accel += vector9 * (20f * num12);
				Vector3 vector10 = vector8 * Mathff.Clamp01(Vector3.Dot(velocity, vector8));
				Accel += -vector10 * (dt * 10f * num12);
			}
		}
		Accel += -velocity * (sys.drag * dt);
	}

	private void CalcLandingForces(float dt, Bird[] birds, BirdSystem sys, Transform Bounds, ref Vector3 Accel)
	{
		Vector3 position = transform.position;
		_ = transform.forward;
		Vector3 vector = LandingPos - position;
		float magnitude = vector.magnitude;
		vector /= magnitude;
		float num = Mathf.Clamp(magnitude, 0f, 2f);
		Accel += vector * num;
		Accel += -velocity * (sys.drag * dt * 10f);
	}

	public void OnEnable()
	{
		seasonChangeEvent = Broadcast.SeasonEvent.Listen(OnSeasonChange);
	}

	public void OnDisable()
	{
		Broadcast.SeasonEvent.Unlisten(seasonChangeEvent);
	}

	private void OnSeasonChange(object sender, SeasonEventData data)
	{
		_lastSeasonDefinition = data.SeasonDefinition;
	}

	private void FixedBirdUpdate(float dt, Bird[] birds, BirdSystem sys, Transform Bounds)
	{
		if (_lastSeasonDefinition == null && SeasonManager.inst != null)
		{
			_lastSeasonDefinition = SeasonManager.GetCurrentSeason();
		}
		Vector3 vector = NextRot * Vector3.forward;
		CurrLoc = NextLoc;
		CurrRot = NextRot;
		Vector3 Accel = new Vector3(0f, 0f, 0f);
		switch (state)
		{
		case State.Flying:
			CalcFlyingForces(dt, birds, sys, Bounds, ref Accel);
			break;
		case State.Landing:
			CalcLandingForces(dt, birds, sys, Bounds, ref Accel);
			if (IsScared())
			{
				Fly();
			}
			if (Time.time - LandingTime > Duration)
			{
				Fly();
			}
			break;
		}
		NextLoc = Kmtcs.IntegratePosClamped(NextLoc, ref velocity, Accel, dt, sys.maxSpeed);
		Vector3 zero = Vector3.zero;
		Vector3 rhs = new Vector3(0f, 1f, 0f);
		Vector3 normalized = Vector3.Cross(Vector3.Cross(vector, rhs), vector).normalized;
		Vector3 vector2 = Vector3.Cross(transform.up, normalized);
		zero.x += vector2.x * sys.unroll;
		zero.y += vector2.y * sys.unroll;
		zero.z += vector2.z * sys.unroll;
		Vector3 vector3 = Vector3.Cross(transform.forward, velocity);
		zero.x += vector3.x * sys.rotAlign;
		zero.y += vector3.y * sys.rotAlign;
		zero.z += vector3.z * sys.rotAlign;
		zero += -rotVel * (dt * sys.rotDrag);
		NextRot = Kmtcs.IntegrateRotation(NextRot, ref rotVel, zero, dt);
	}

	public void UpdateBird(float dt, Bird[] birds, BirdSystem sys, Transform Bounds)
	{
		totalTime += dt;
		if (totalTime > timeStep)
		{
			FixedBirdUpdate(timeStep, birds, sys, Bounds);
			totalTime %= timeStep;
		}
		float t = Mathf.Clamp01(totalTime / timeStep);
		transform.SetPositionAndRotation(Vector3.Lerp(CurrLoc, NextLoc, t), Quaternion.Slerp(CurrRot, NextRot, t));
		float value = (sys.maxSpeed - velocity.magnitude) / sys.maxSpeed;
		value = Mathf.Clamp(value, 0.6f, 1f);
		anim.Update(dt * value * 10f);
		if (state == State.Landing && (LandingPos - transform.position).sqrMagnitude < 0.122499995f)
		{
			anim.playToIndex = 0;
		}
		else
		{
			anim.playToIndex = -1;
		}
	}

	private bool IsScared()
	{
		_ = transform.position;
		World.inst.ToGridCoord(LandingPos, out var x, out var z);
		x = Mathf.Clamp(x, 2, World.inst.GridWidth - 2);
		z = Mathf.Clamp(z, 2, World.inst.GridHeight - 2);
		return (byte)(0u | (World.inst.GetCellDataUnsafe(x, z).Busy ? 1u : 0u) | (World.inst.GetCellDataUnsafe(x + 1, z).Busy ? 1u : 0u) | (World.inst.GetCellDataUnsafe(x, z + 1).Busy ? 1u : 0u) | (World.inst.GetCellDataUnsafe(x + 1, z + 1).Busy ? 1u : 0u) | (World.inst.GetCellDataUnsafe(x - 1, z).Busy ? 1u : 0u) | (World.inst.GetCellDataUnsafe(x, z - 1).Busy ? 1u : 0u) | (World.inst.GetCellDataUnsafe(x - 1, z - 1).Busy ? 1u : 0u) | (World.inst.GetCellDataUnsafe(x - 1, z + 1).Busy ? 1u : 0u) | (World.inst.GetCellDataUnsafe(x + 1, z - 1).Busy ? 1u : 0u)) != 0;
	}
}
