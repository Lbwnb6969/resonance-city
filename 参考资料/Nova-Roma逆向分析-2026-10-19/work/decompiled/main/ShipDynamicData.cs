using System;
using UnityEngine;

[Serializable]
public class ShipDynamicData
{
	public float accel = 4f;

	public float drag = 2f;

	public float repel = 5f;

	public float push = 4f;

	public float rotAccel = 1f;

	public float arrivalRad = 0.475f;

	public float repelDist = 2f;

	[NonSerialized]
	public Vector3 Pos;

	[NonSerialized]
	public Vector3 velocity;

	[NonSerialized]
	public Vector3 rotVel;

	[NonSerialized]
	public float radMul;

	[NonSerialized]
	public bool isMoving;

	public bool doShipToShipCollision = true;

	private Vector3 fwd = Vector3.forward;

	public static bool GetClosestPointToBlockedCell(Vector3 pos, out Vector3 outPos, int teamId)
	{
		outPos.x = 0f;
		outPos.y = 0f;
		outPos.z = 0f;
		PathCell pathCellClamped = World.inst.GetPathCellClamped(pos);
		if (PathCell.GetBlocksWaterPath(pathCellClamped, teamId))
		{
			int num = pathCellClamped.x - 1;
			int num2 = pathCellClamped.z - 1;
			int num3 = pathCellClamped.x + 1;
			int num4 = pathCellClamped.z + 1;
			float num5 = float.MaxValue;
			for (int i = num; i <= num3; i++)
			{
				for (int j = num2; j <= num4; j++)
				{
					pathCellClamped = World.inst.GetPathCellClamped(i, j);
					if (!PathCell.GetBlocksWaterPath(pathCellClamped, teamId))
					{
						Vector3 vector = pos;
						vector.x = Mathff.Clamp(vector.x, (float)pathCellClamped.x + 0.01f, (float)(pathCellClamped.x + 1) - 0.01f);
						vector.z = Mathff.Clamp(vector.z, (float)pathCellClamped.z + 0.01f, (float)(pathCellClamped.z + 1) - 0.01f);
						float num6 = Mathff.DistSqrdXZ(vector, pos);
						if (num6 < num5)
						{
							num5 = num6;
							outPos = vector;
						}
					}
				}
			}
			return num5 != float.MaxValue;
		}
		return false;
	}

	public bool ArrivedAt(Vector3 targetPos)
	{
		return Mathff.DistSqrdXZ(targetPos, Pos) < arrivalRad * arrivalRad;
	}

	public bool MoveUpdate(float timeStep, Vector3 targetPos, int teamId, Transform shipXform)
	{
		float b = 0.1f;
		float num = Mathf.Clamp(timeStep, 0f, 0.5f);
		Quaternion quaternion = shipXform.rotation;
		Vector3 vector = default;
		Vector3 vector2 = default;
		Vector3 vector3 = default;
		Vector3 vector4 = default;
		Vector3 lhs = default;
		while (num > 0f)
		{
			float num2 = Mathf.Min(num, b);
			num -= num2;
			vector.x = targetPos.x - Pos.x;
			vector.y = 0f;
			vector.z = targetPos.z - Pos.z;
			vector.Normalize();
			vector2.x = vector.x * accel;
			vector2.y = 0f;
			vector2.z = vector.z * accel;
			if (doShipToShipCollision)
			{
				float num3 = repelDist * radMul;
				int num4 = (int)Mathf.Clamp(Pos.x - num3, 0f, World.inst.GridWidth - 1);
				int num5 = (int)Mathf.Clamp(Pos.z - num3, 0f, World.inst.GridHeight - 1);
				int num6 = (int)Mathf.Clamp(Pos.x + num3, 0f, World.inst.GridWidth - 1);
				int num7 = (int)Mathf.Clamp(Pos.z + num3, 0f, World.inst.GridHeight - 1);
				for (int i = num5; i <= num7; i++)
				{
					for (int j = num4; j <= num6; j++)
					{
						ArrayExt<ShipBase> shipsAt = ShipSystem.inst.GetShipsAt(j, i);
						int k = 0;
						for (int count = shipsAt.Count; k < count; k++)
						{
							ShipDynamicData dynamics = shipsAt.data[k].dynamics;
							if (dynamics == this || !dynamics.isMoving)
							{
								continue;
							}
							float x = dynamics.Pos.x;
							float z = dynamics.Pos.z;
							vector3.x = x - Pos.x;
							vector3.y = 0f;
							vector3.z = z - Pos.z;
							float num8 = Mathff.MagnitudeSqrdXZ(vector3);
							if (num8 < 0.0001f)
							{
								continue;
							}
							float num9 = dynamics.repelDist * dynamics.radMul;
							if (!(num8 > num3 * num3 + num9 * num9))
							{
								float num10 = Mathf.Sqrt(num8);
								vector3.x /= num10;
								vector3.y /= num10;
								vector3.z /= num10;
								float num11 = Mathff.Clamp01((num3 + num9 - num10) / (num3 + num9));
								float v = Vector3.Dot(vector, vector3);
								num11 *= Mathff.Clamp01(v);
								vector4.x = dynamics.Pos.x - Pos.x;
								vector4.y = 0f;
								vector4.z = dynamics.Pos.z - Pos.z;
								vector4.Normalize();
								float num12 = Vector3.Dot(vector, velocity);
								lhs.x = vector.x * num12;
								lhs.y = vector.y * num12;
								lhs.z = vector.z * num12;
								if (Vector3.Dot(lhs, vector4) > 0f)
								{
									Vector3 vector5 = vector4 * Vector3.Dot(lhs, vector4);
									float num13 = Mathff.Clamp01(Vector3.Dot(vector, dynamics.velocity.normalized));
									vector5 *= num13;
									vector2 += -vector5 * 4f * num11;
								}
							}
						}
					}
				}
			}
			Pos.x += velocity.x * num2;
			Pos.z += velocity.z * num2;
			Vector3 rhs = quaternion * fwd;
			float num14 = num2 * (float)((Vector3.Dot(vector, rhs) > 0.4f) ? 1 : 0);
			velocity.x += vector2.x * num14;
			velocity.z += vector2.z * num14;
			float num15 = drag * num2;
			velocity.x += (0f - velocity.x) * num15;
			velocity.z += (0f - velocity.z) * num15;
			if (vector != Vector3.zero)
			{
				quaternion = Quaternion.Lerp(quaternion, Quaternion.LookRotation(vector), num2 * rotAccel);
			}
		}
		if (GetClosestPointToBlockedCell(Pos, out var outPos, teamId))
		{
			Pos = outPos;
		}
		Pos.y = -0.31f;
		shipXform.SetPositionAndRotation(Pos, quaternion);
		if (ArrivedAt(targetPos))
		{
			return true;
		}
		return false;
	}
}
