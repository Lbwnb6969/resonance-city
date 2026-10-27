using Drawing;
using UnityEngine;

public class HermiteSpline
{
	public ArrayExt<Vector3> points = new ArrayExt<Vector3>(128);

	public ArrayExt<Vector3> directions = new ArrayExt<Vector3>(128);

	public void Reset()
	{
		points.ClearFast();
		directions.ClearFast();
	}

	public bool IsValid()
	{
		if (points.Count > 2)
		{
			return points.Count == directions.Count;
		}
		return false;
	}

	public static Vector3 Hermite(Vector3 p0, Vector3 t0, Vector3 p1, Vector3 t1, float t)
	{
		float num = t * t;
		float num2 = num * t;
		float num3 = 2f * num2 - 3f * num + 1f;
		float num4 = -2f * num2 + 3f * num;
		float num5 = num2 - 2f * num + t;
		float num6 = num2 - num;
		return num3 * p0 + num4 * p1 + num5 * t0 + num6 * t1;
	}

	public Vector3 GetPosition(double t)
	{
		t = Mathff.Clamp01(t);
		int num = points.Count - 1;
		int num2 = Mathff.Min(Mathf.FloorToInt((float)(t * (double)num)), num - 1);
		float t2 = (float)(t * (double)num - (double)num2);
		Vector3 p = points.data[num2];
		Vector3 p2 = points.data[num2 + 1];
		Vector3 t3 = directions.data[num2];
		Vector3 t4 = directions.data[num2 + 1];
		return Hermite(p, t3, p2, t4, t2);
	}

	public Vector3 GetForward(double t)
	{
		t = Mathff.Min((float)t, 0.999f);
		return (GetPosition(t + 0.0010000000474974513) - GetPosition(t)).normalized;
	}

	public Vector3 Travel(ref double t, double distance, double step = 0.001)
	{
		double num = 0.0;
		Vector3 vector = GetPosition(t);
		while (num < distance)
		{
			t = Mathff.Clamp01(t + step);
			if (t >= 1.0)
			{
				return GetPosition(t);
			}
			Vector3 position = GetPosition(t);
			float num2 = Vector3.Distance(vector, position);
			num += (double)num2;
			if (num >= distance)
			{
				double num3 = num - distance;
				t -= num3 / (double)num2 * step;
				position = GetPosition(t);
			}
			vector = position;
		}
		return vector;
	}

	public float GetDistanceRemaining(double t, double maxDistance, double step = 0.009999999776482582)
	{
		double num = 0.0;
		Vector3 a = GetPosition(t);
		while (num < maxDistance)
		{
			if (t >= 1.0)
			{
				return (float)num;
			}
			t = Mathff.Clamp01(t + step);
			Vector3 position = GetPosition(t);
			num += (double)Vector3.Distance(a, position);
			a = position;
		}
		return (float)num;
	}

	public void DebugDraw()
	{
		if (!IsValid())
		{
			return;
		}
		for (int i = 0; i < points.Count; i++)
		{
			Draw.WireSphere(points.data[i], 0.3f, Color.black);
			Draw.Line(points.data[i], points.data[i] + directions.data[i], Color.green);
		}
		Vector3 a = points.data[0];
		for (float num = 0f; num < 1f; num += 0.01f)
		{
			Vector3 position = GetPosition(num);
			if (num > 0f)
			{
				Draw.Line(a, position, Color.red);
			}
			a = position;
		}
	}
}
