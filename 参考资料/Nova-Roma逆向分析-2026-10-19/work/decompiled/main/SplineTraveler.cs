using System;
using UnityEngine;

[Serializable]
public class SplineTraveler<T> where T : class
{
	private int controlPoint;

	private double t;

	[NonSerialized]
	private CatmullRomSpline<T> s;

	public SplineTraveler(CatmullRomSpline<T> spline)
	{
		s = spline;
		Reset();
	}

	public CatmullRomSpline<T> GetSpline()
	{
		return s;
	}

	public void Reset()
	{
		t = 0.0;
		controlPoint = 1;
	}

	public Vector3 GetPosition()
	{
		return s.GetPosition(controlPoint, (float)t);
	}

	public Vector3 GetForward()
	{
		return (s.GetPosition(controlPoint, (float)t + 0.001f) - s.GetPosition(controlPoint, (float)t)).normalized;
	}

	public void SetTime(double time)
	{
		t = time;
	}

	public double GetTime()
	{
		return t;
	}

	public float GetTotalTime()
	{
		return (float)controlPoint / (float)s.LastUsefulControlPointIndex() + (float)((double)(1f / (float)s.LastUsefulControlPointIndex()) * t);
	}

	public void SetControlPoint(int cPoint)
	{
		controlPoint = cPoint;
	}

	public int GetControlPoint()
	{
		return controlPoint;
	}

	public SplineControlPoint<T> GetLastControlPoint()
	{
		return s.GetControlPoint(s.LastUsefulControlPointIndex());
	}

	public Vector3 Travel(double distance, double step = 0.01)
	{
		double num = 0.0;
		Vector3 vector = s.GetPosition(controlPoint, (float)t);
		while (num < distance)
		{
			t += step;
			if (t > 1.0)
			{
				t--;
				controlPoint++;
			}
			if (controlPoint >= s.LastUsefulControlPointIndex())
			{
				controlPoint = s.LastUsefulControlPointIndex() - 1;
				t = 1.0;
				return s.GetPosition(controlPoint, (float)t);
			}
			Vector3 position = s.GetPosition(controlPoint, (float)t);
			float num2 = Vector3.Distance(vector, position);
			num += (double)num2;
			if (num >= distance)
			{
				double num3 = num - distance;
				t -= num3 / (double)num2 * step;
				position = s.GetPosition(controlPoint, (float)t);
			}
			vector = position;
		}
		return vector;
	}

	public double TravelDist(double distance, double step = 0.01)
	{
		double num = 0.0;
		Vector3 a = s.GetPosition(controlPoint, (float)t);
		int num2 = 0;
		while (num < distance)
		{
			t += step;
			if (t > 1.0)
			{
				t--;
				controlPoint++;
			}
			if (controlPoint >= s.LastUsefulControlPointIndex())
			{
				controlPoint = s.LastUsefulControlPointIndex() - 1;
				t = 1.0;
				return num;
			}
			Vector3 position = s.GetPosition(controlPoint, (float)t);
			num += (double)Vector3.Distance(a, position);
			a = position;
			num2++;
		}
		return num;
	}

	public SplineControlPoint<T> NextControlPoint()
	{
		return s.GetControlPoint(controlPoint + 1);
	}

	public bool AtEnd()
	{
		if (controlPoint == s.LastUsefulControlPointIndex() - 1)
		{
			return t == 1.0;
		}
		return false;
	}
}
