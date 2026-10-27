using UnityEngine;

public class LegionConstraint
{
	public static bool ApplyConstraint(float springConstant, float springBreakThreshold, ref LegionCell cell1, ref LegionCell cell2, float length)
	{
		Vector3 vector = cell2.position - cell1.position;
		vector.y = 0f;
		float magnitude = vector.magnitude;
		float num = magnitude - length;
		if (magnitude != 0f)
		{
			cell1.acceleration += vector.normalized * num * 0.5f * springConstant;
			cell2.acceleration += -vector.normalized * num * 0.5f * springConstant;
			if (Mathf.Abs(num) > springBreakThreshold)
			{
				return true;
			}
		}
		return false;
	}

	public static bool ApplyConstraint(float springConstant, float springBreakThreshold, ref LegionCell cell1, ref LegionCell cell2, bool cell1IsLeader, bool cell2IsLeader, float length)
	{
		Vector3 vector = cell2.position - cell1.position;
		vector.y = 0f;
		float magnitude = vector.magnitude;
		float num = magnitude - length;
		if (magnitude != 0f)
		{
			float num2;
			if (cell1IsLeader)
			{
				num2 = 0f;
			}
			else
			{
				num2 = (cell2IsLeader ? 1f : 0.5f);
			}
			float num3;
			if (cell2IsLeader)
			{
				num3 = 0f;
			}
			else
			{
				num3 = (cell1IsLeader ? 1f : 0.5f);
			}
			cell1.acceleration += vector.normalized * num * num2 * springConstant;
			cell2.acceleration += -vector.normalized * num * num3 * springConstant;
			if (Mathf.Abs(num) > springBreakThreshold)
			{
				return true;
			}
		}
		return false;
	}

	public static bool ApplyConstraintToPosition(float springConstant, float springBreakThreshold, ref LegionCell cell, Vector3 position, float length)
	{
		Vector3 vector = position - cell.position;
		vector.y = 0f;
		float magnitude = vector.magnitude;
		float num = magnitude - length;
		if (magnitude != 0f)
		{
			cell.acceleration += vector.normalized * num * springConstant;
			if (Mathf.Abs(num) > springBreakThreshold)
			{
				return true;
			}
		}
		return false;
	}
}
