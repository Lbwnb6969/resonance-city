using System;
using Drawing;
using UnityEngine;

public static class DebugEx
{
	public static void DrawArrow(Vector3 start, Vector3 end, Color color, float duration = -1f)
	{
		if (Application.isEditor)
		{
			Debug.DrawLine(start, end, color, duration);
			float magnitude = (end - start).magnitude;
			Vector3 normalized = (end - start).normalized;
			Vector3 normalized2 = Vector3.Cross(normalized, Vector3.up).normalized;
			float num = magnitude * 0.1f;
			Debug.DrawLine(end, end - normalized * num + normalized2 * num, color, duration);
			Debug.DrawLine(end, end - normalized * num - normalized2 * num, color, duration);
		}
	}

	public static void DrawEllipse(Transform t, float radiusX, float radiusZ, Color color, int segments = 16, float duration = -1f)
	{
		Vector3[] array = new Vector3[segments + 1];
		for (int i = 0; i <= segments; i++)
		{
			float f = (float)i / (float)segments * 2f * MathF.PI;
			array[i].x = radiusX * Mathf.Cos(f);
			array[i].y = 0f;
			array[i].z = radiusZ * Mathf.Sin(f);
		}
		for (int j = 0; j < segments; j++)
		{
			Debug.DrawLine(t.TransformPoint(array[j]), t.TransformPoint(array[j + 1]), color, duration);
		}
	}

	public static void DrawEllipse(Vector3 origin, float radiusX, float radiusZ, Color color, int segments = 16)
	{
		Vector3[] array = new Vector3[segments + 1];
		for (int i = 0; i <= segments; i++)
		{
			float f = (float)i / (float)segments * 2f * MathF.PI;
			array[i].x = radiusX * Mathf.Cos(f) + origin.x;
			array[i].y = origin.y;
			array[i].z = radiusZ * Mathf.Sin(f) + origin.z;
		}
		for (int j = 0; j < segments; j++)
		{
			Draw.Line(array[j], array[j + 1], color);
		}
	}

	public static void DrawBoxInfinite(Vector3 min, Vector3 max, Color color)
	{
		if (Application.isEditor)
		{
			Debug.DrawLine(min, min.xz() + max.yv(), color, float.MaxValue);
			Debug.DrawLine(min, min.yz() + max.xv(), color, float.MaxValue);
			Debug.DrawLine(min, min.xy() + max.zv(), color, float.MaxValue);
			Debug.DrawLine(max, max.xz() + min.yv(), color, float.MaxValue);
			Debug.DrawLine(max, max.yz() + min.xv(), color, float.MaxValue);
			Debug.DrawLine(max, max.xy() + min.zv(), color, float.MaxValue);
		}
	}

	public static void DrawBox(Vector3 min, Vector3 max, Color color, float duration = 0f)
	{
		if (Application.isEditor)
		{
			Debug.DrawLine(min, min.xz() + max.yv(), color, duration);
			Debug.DrawLine(min, min.yz() + max.xv(), color, duration);
			Debug.DrawLine(min, min.xy() + max.zv(), color, duration);
			Debug.DrawLine(max, max.xz() + min.yv(), color, duration);
			Debug.DrawLine(max, max.yz() + min.xv(), color, duration);
			Debug.DrawLine(max, max.xy() + min.zv(), color, duration);
		}
	}

	public static void DrawBox(Vector3 min, Vector3 max)
	{
		DrawBox(min, max, Color.red);
	}

	public static void DrawBoxXZ(Vector3 min, Vector3 max, Color color, float duration = -1f)
	{
		Debug.DrawLine(min, new Vector3(max.x, min.y, min.z), color, duration);
		Debug.DrawLine(min, new Vector3(min.x, min.y, max.z), color, duration);
		Debug.DrawLine(max, new Vector3(min.x, min.y, max.z), color, duration);
		Debug.DrawLine(max, new Vector3(max.x, min.y, min.z), color, duration);
	}

	public static void DrawBoxXZ(float minX, float maxX, float minZ, float maxZ, float y, Color color, float duration = -1f)
	{
		Vector3 start = new Vector3(minX, y, minZ);
		Vector3 start2 = new Vector3(maxX, y, maxZ);
		Debug.DrawLine(start, new Vector3(start2.x, start.y, start.z), color, duration);
		Debug.DrawLine(start, new Vector3(start.x, start.y, start2.z), color, duration);
		Debug.DrawLine(start2, new Vector3(start.x, start.y, start2.z), color, duration);
		Debug.DrawLine(start2, new Vector3(start2.x, start.y, start.z), color, duration);
	}

	public static void DrawCircleXZ(Vector3 Loc, float radius, Color color, float segments = 16f, float duration = -1f)
	{
		DrawCircle(Loc, radius, color, new Vector3(0f, 1f, 0f), new Vector3(1f, 0f, 0f), segments, duration);
	}

	public static void DrawCircle(Vector3 Loc, float Radius, Color color, Vector3 up, Vector3 fwd, float segments = 16f, float duration = -1f)
	{
		if (Application.isEditor)
		{
			for (int i = 0; (float)i < segments; i++)
			{
				float angle = (float)i / segments * 360f;
				float angle2 = (float)(i + 1) / segments * 360f;
				Vector3 vector = Quaternion.AngleAxis(angle, up) * fwd;
				Vector3 vector2 = Quaternion.AngleAxis(angle2, up) * fwd;
				Vector3 start = Loc + vector * Radius;
				Vector3 end = Loc + vector2 * Radius;
				Debug.DrawLine(start, end, color, duration);
			}
		}
	}

	public static void DrawSphere(Vector3 Loc, float Radius, Color color, float segments = 16f, float duration = -1f)
	{
		if (Application.isEditor)
		{
			DrawCircle(Loc, Radius, color, Vector3.up, Vector3.forward, segments, duration);
			DrawCircle(Loc, Radius, color, Vector3.forward, Vector3.right, segments, duration);
			DrawCircle(Loc, Radius, color, Vector3.up, Vector3.right, segments, duration);
		}
	}
}
