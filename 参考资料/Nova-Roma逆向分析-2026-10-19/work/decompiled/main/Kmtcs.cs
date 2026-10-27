using UnityEngine;

public static class Kmtcs
{
	public static Quaternion IntegrateRotation(Quaternion Rot, ref Vector3 AngVel, Vector3 Torque, float dt)
	{
		Quaternion quaternion = new Quaternion(AngVel.x, AngVel.y, AngVel.z, 0f) * Rot;
		AngVel.x += Torque.x * dt;
		AngVel.y += Torque.y * dt;
		AngVel.z += Torque.z * dt;
		return Mathff.Normalized(new Quaternion(Rot.x + 0.5f * dt * quaternion.x, Rot.y + 0.5f * dt * quaternion.y, Rot.z + 0.5f * dt * quaternion.z, Rot.w + 0.5f * dt * quaternion.w));
	}

	public static Vector3 IntegratePos(Vector3 Pos, ref Vector3 Velocity, Vector3 Accel, float dt)
	{
		Velocity += Accel * dt;
		return Pos + Velocity * dt;
	}

	public static Vector3 IntegratePosClamped(Vector3 Pos, ref Vector3 Velocity, Vector3 Accel, float dt, float MaxSpeed)
	{
		Velocity.x += Accel.x * dt;
		Velocity.y += Accel.y * dt;
		Velocity.z += Accel.z * dt;
		Velocity = Vector3.ClampMagnitude(Velocity, MaxSpeed);
		return new Vector3(Pos.x + Velocity.x * dt, Pos.y + Velocity.y * dt, Pos.z + Velocity.z * dt);
	}
}
