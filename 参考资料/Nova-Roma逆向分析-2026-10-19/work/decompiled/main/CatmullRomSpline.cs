using System;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class CatmullRomSpline<T> where T : class
{
	public List<SplineControlPoint<T>> controlPointsList = new List<SplineControlPoint<T>>();

	private SplineTraveler<T> internalSplineTraveler;

	public bool isLooping = true;

	private List<Vector3> newPoints = new List<Vector3>(5);

	public CatmullRomSpline(bool looping)
	{
		isLooping = false;
		internalSplineTraveler = new SplineTraveler<T>(this);
	}

	public void ClearControlPoints()
	{
		controlPointsList.Clear();
	}

	public void AddControlPoint(Vector3 pos, T data = null, int At = -1)
	{
		if (At != -1)
		{
			controlPointsList.Insert(At, new SplineControlPoint<T>(pos, data));
		}
		else
		{
			controlPointsList.Add(new SplineControlPoint<T>(pos, data));
		}
	}

	public int FindControlPointIndex(SplineControlPoint<T> controlPoint)
	{
		return controlPointsList.FindIndex((SplineControlPoint<T> ptn) => controlPoint == ptn);
	}

	public bool Valid()
	{
		return controlPointsList.Count >= 4;
	}

	public int LastUsefulControlPointIndex()
	{
		return controlPointsList.Count - 2;
	}

	public SplineControlPoint<T> GetControlPoint(int index)
	{
		return controlPointsList[index];
	}

	public void SplitSplineIntoLengthSegments(int startControlPoint, float length)
	{
		newPoints.Clear();
		internalSplineTraveler.SetControlPoint(startControlPoint);
		internalSplineTraveler.SetTime(0.0);
		while (true)
		{
			Vector3 item = internalSplineTraveler.Travel(length);
			if (internalSplineTraveler.AtEnd() || internalSplineTraveler.GetControlPoint() != startControlPoint)
			{
				break;
			}
			newPoints.Add(item);
		}
		if (newPoints.Count > 0)
		{
			newPoints.RemoveAt(newPoints.Count - 1);
		}
		foreach (Vector3 newPoint in newPoints)
		{
			startControlPoint++;
			AddControlPoint(newPoint, null, startControlPoint);
		}
	}

	public void DisplayCatmullRomSpline(int pos)
	{
		Vector3 p = controlPointsList[ClampListPos(pos - 1)].pos;
		Vector3 p2 = controlPointsList[pos].pos;
		Vector3 vector = controlPointsList[ClampListPos(pos + 1)].pos;
		Vector3 p3 = controlPointsList[ClampListPos(pos + 2)].pos;
		Vector3 vector2 = Vector3.zero;
		for (float num = 0f; num < 1f; num += 0.01f)
		{
			Vector3 vector3 = ReturnCatmullRom(num, p, p2, vector, p3);
			if (num == 0f)
			{
				vector2 = vector3;
				continue;
			}
			Gizmos.DrawLine(vector2, vector3);
			vector2 = vector3;
		}
		Gizmos.DrawLine(vector2, vector);
	}

	public Vector3 GetPosition(int pos, float t)
	{
		Vector3 p = controlPointsList[ClampListPos(pos - 1)].pos;
		Vector3 p2 = controlPointsList[pos].pos;
		Vector3 p3 = controlPointsList[ClampListPos(pos + 1)].pos;
		Vector3 p4 = controlPointsList[ClampListPos(pos + 2)].pos;
		return ReturnCatmullRom(t, p, p2, p3, p4);
	}

	private int ClampListPos(int pos)
	{
		if (pos < 0)
		{
			return pos + controlPointsList.Count;
		}
		if (pos > controlPointsList.Count - 1)
		{
			return pos - controlPointsList.Count;
		}
		return pos;
	}

	public Vector3 ReturnCatmullRom(float t, Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3)
	{
		Vector3 vector = 0.5f * (2f * p1);
		Vector3 vector2 = 0.5f * (p2 - p0);
		Vector3 vector3 = 0.5f * (2f * p0 - 5f * p1 + 4f * p2 - p3);
		Vector3 vector4 = 0.5f * (-p0 + 3f * p1 - 3f * p2 + p3);
		return vector + vector2 * t + vector3 * (t * t) + vector4 * (t * t * t);
	}

	public float RoughDistanceToEnd(SplineTraveler<object> traveler, float maxCheckDistance)
	{
		internalSplineTraveler.SetControlPoint(traveler.GetControlPoint());
		internalSplineTraveler.SetTime(traveler.GetTime());
		return (float)internalSplineTraveler.TravelDist(maxCheckDistance, 0.1);
	}

	public void DrawGizmo()
	{
		Gizmos.color = Color.black;
		for (int i = 0; i < controlPointsList.Count; i++)
		{
			Gizmos.DrawWireSphere(controlPointsList[i].pos, 0.3f);
		}
		for (int j = 0; j < controlPointsList.Count; j++)
		{
			if ((j != 0 && j != controlPointsList.Count - 2 && j != controlPointsList.Count - 1) || isLooping)
			{
				DisplayCatmullRomSpline(j);
			}
		}
	}
}
