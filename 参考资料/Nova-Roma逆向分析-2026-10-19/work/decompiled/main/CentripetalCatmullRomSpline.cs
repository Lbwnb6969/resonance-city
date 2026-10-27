using System.Collections.Generic;
using Drawing;
using UnityEngine;

public class CentripetalCatmullRomSpline
{
	public List<Vector3> controlPoints = new List<Vector3>(128);

	public List<Vector3> splinePoints = new List<Vector3>(128);

	public int resolution = 8;

	public bool isLooped = true;

	public float alpha = 0.5f;

	public void Reset()
	{
		controlPoints.Clear();
		splinePoints.Clear();
	}

	public void GenerateSplinePoints()
	{
		splinePoints.Clear();
		if (controlPoints.Count == 0)
		{
			return;
		}
		int num = controlPoints.Count;
		if (!isLooped)
		{
			if (controlPoints.Count < 4)
			{
				return;
			}
			num -= 3;
		}
		for (int i = 0; i < num - 1; i++)
		{
			Vector3 p;
			Vector3 vector;
			Vector3 p2;
			Vector3 p3;
			if (!isLooped)
			{
				p = controlPoints[WrapIndex(i)];
				vector = controlPoints[WrapIndex(i + 1)];
				p2 = controlPoints[WrapIndex(i + 2)];
				p3 = controlPoints[WrapIndex(i + 3)];
			}
			else
			{
				p = controlPoints[WrapIndex(i - 1)];
				vector = controlPoints[WrapIndex(i)];
				p2 = controlPoints[WrapIndex(i + 1)];
				p3 = controlPoints[WrapIndex(i + 2)];
			}
			if (!isLooped)
			{
				for (int j = 0; j < resolution; j++)
				{
					float t = (float)j / ((float)resolution - 1f);
					splinePoints.Add(GetCatmullRomPoint(t, p, vector, p2, p3));
				}
				continue;
			}
			splinePoints.Add(vector);
			for (int k = 1; k < resolution - 1; k++)
			{
				float t2 = (float)k / ((float)resolution - 1f);
				splinePoints.Add(GetCatmullRomPoint(t2, p, vector, p2, p3));
			}
		}
		if (isLooped)
		{
			List<Vector3> list = splinePoints;
			List<Vector3> list2 = controlPoints;
			list.Add(list2[list2.Count - 1]);
		}
	}

	public void DebugDraw()
	{
		if (splinePoints.Count >= 2)
		{
			for (int i = 1; i < splinePoints.Count; i++)
			{
				Draw.ingame.Line(splinePoints[i - 1], splinePoints[i]);
			}
		}
	}

	private int WrapIndex(int idx)
	{
		return (idx + controlPoints.Count) % controlPoints.Count;
	}

	private Vector3 GetCatmullRomPoint(float t, Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3)
	{
		float knotInterval = GetKnotInterval(p0, p1);
		float num = GetKnotInterval(p1, p2) + knotInterval;
		float b = GetKnotInterval(p2, p3) + num;
		float u = Mathf.LerpUnclamped(knotInterval, num, t);
		Vector3 c = Remap(0f, knotInterval, p0, p1, u);
		Vector3 vector = Remap(knotInterval, num, p1, p2, u);
		Vector3 d = Remap(num, b, p2, p3, u);
		Vector3 c2 = Remap(0f, num, c, vector, u);
		Vector3 d2 = Remap(knotInterval, b, vector, d, u);
		return Remap(knotInterval, num, c2, d2, u);
	}

	private Vector3 Remap(float a, float b, Vector3 c, Vector3 d, float u)
	{
		if (b - a == 0f)
		{
			return c;
		}
		return Vector3.LerpUnclamped(c, d, (u - a) / (b - a));
	}

	private float GetKnotInterval(Vector3 a, Vector3 b)
	{
		return Mathf.Pow(Vector3.SqrMagnitude(a - b), 0.5f * alpha);
	}
}
