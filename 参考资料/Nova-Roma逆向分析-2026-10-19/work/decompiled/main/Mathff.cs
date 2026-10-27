using System;
using System.Runtime.CompilerServices;
using UnityEngine;

public static class Mathff
{
	public delegate bool TraceEvaluate(int x, int z);

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Dot(Vector3 a, Vector3 b)
	{
		return a.x * b.x + a.y * b.y + a.z * b.z;
	}

	public static float UnwindAngle(float angle)
	{
		while (angle >= 360f)
		{
			angle -= 360f;
		}
		while (angle <= -360f)
		{
			angle += 360f;
		}
		return angle;
	}

	public static float MoveTowardsAngle(float start, float target, float amt)
	{
		if (target - start < MathF.PI)
		{
			start += amt;
			if (start > target)
			{
				start = target;
			}
		}
		else
		{
			start -= amt;
			if (start < target - MathF.PI * 2f)
			{
				start = target - MathF.PI * 2f;
			}
		}
		return start;
	}

	public static Quaternion QuatFromYRot(float y)
	{
		Quaternion result = default;
		float w = Mathf.Cos(y * 0.5f);
		float y2 = Mathf.Sin(y * 0.5f);
		result.w = w;
		result.x = 0f;
		result.y = y2;
		result.z = 0f;
		return result;
	}

	public static Vector3 NearestPointOnLine(Vector3 linePnt, Vector3 lineDir, Vector3 pnt, bool clamped)
	{
		lineDir.Normalize();
		float num = Vector3.Dot(pnt - linePnt, lineDir);
		if (clamped)
		{
			num = Mathf.Clamp01(num);
		}
		return linePnt + lineDir * num;
	}

	public static Quaternion QuatFromEulers(float x, float y, float z)
	{
		Quaternion result = default;
		float num = Mathf.Cos(y / 2f);
		float num2 = Mathf.Sin(y / 2f);
		float num3 = Mathf.Cos(x / 2f);
		float num4 = Mathf.Sin(x / 2f);
		float num5 = Mathf.Cos(z / 2f);
		float num6 = Mathf.Sin(z / 2f);
		float num7 = num * num3;
		float num8 = num2 * num4;
		result.w = num7 * num5 - num8 * num6;
		result.x = num7 * num6 + num8 * num5;
		result.y = num2 * num3 * num5 + num * num4 * num6;
		result.z = num * num4 * num5 - num2 * num3 * num6;
		return result;
	}

	public static float EaseInCirc(float a, float b, float t)
	{
		t = Clamp01(t);
		return a + (Mathf.Sqrt(1f - t * t) - 1f) * (b - a);
	}

	public static bool PointInPolygon(Vector2[] verts, Vector2 test)
	{
		bool flag = false;
		int num = 0;
		int num2 = verts.Length - 1;
		while (num < verts.Length)
		{
			if (verts[num].y > test.y != verts[num2].y > test.y && test.x < (verts[num2].x - verts[num].x) * (test.y - verts[num].y) / (verts[num2].y - verts[num].y) + verts[num].x)
			{
				flag = !flag;
			}
			num2 = num++;
		}
		return flag;
	}

	public static bool PointInPolygon(Vector3[] verts, Vector3 test)
	{
		bool flag = false;
		int num = 0;
		int num2 = verts.Length - 1;
		while (num < verts.Length)
		{
			if (verts[num].z > test.z != verts[num2].z > test.z && test.x < (verts[num2].x - verts[num].x) * (test.z - verts[num].z) / (verts[num2].z - verts[num].z) + verts[num].x)
			{
				flag = !flag;
			}
			num2 = num++;
		}
		return flag;
	}

	public static Vector3 ProjectOntoPlane(Vector3 p0, Vector3 N, Vector3 u)
	{
		Vector3 rhs = u - p0;
		Vector3 vector = N * Vector3.Dot(N, rhs);
		return u - vector;
	}

	public static bool IsNaN(Vector3 a)
	{
		if (!float.IsNaN(a.x) && !float.IsNaN(a.y))
		{
			return float.IsNaN(a.z);
		}
		return true;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Abs(float a)
	{
		if (!(a < 0f))
		{
			return a;
		}
		return 0f - a;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int Abs(int a)
	{
		if (a >= 0)
		{
			return a;
		}
		return -a;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int Min(int a, int b)
	{
		if (a <= b)
		{
			return a;
		}
		return b;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Min(float a, float b)
	{
		if (!(a > b))
		{
			return a;
		}
		return b;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Lerp(float a, float b, float T)
	{
		return a + (b - a) * T;
	}

	public static Vector3 MoveTowards(Vector3 curr, Vector3 next, float amt)
	{
		float num = next.x - curr.x;
		float num2 = next.y - curr.y;
		float num3 = next.z - curr.z;
		float num4 = num * num + num2 * num2 + num3 * num3;
		if (num4 > amt * amt)
		{
			float num5 = Mathf.Sqrt(num4);
			return new Vector3(curr.x + num / num5 * amt, curr.y + num2 / num5 * amt, curr.z + num3 / num5 * amt);
		}
		return next;
	}

	public static bool MoveTowards(Vector3 curr, Vector3 next, float amt, out float actualAmt, out Vector3 newPos)
	{
		float num = next.x - curr.x;
		float num2 = next.y - curr.y;
		float num3 = next.z - curr.z;
		float num4 = num * num + num2 * num2 + num3 * num3;
		if (num4 > amt * amt)
		{
			actualAmt = amt;
			float num5 = Mathf.Sqrt(num4);
			newPos.x = curr.x + num / num5 * amt;
			newPos.y = curr.y + num2 / num5 * amt;
			newPos.z = curr.z + num3 / num5 * amt;
			return false;
		}
		actualAmt = Mathf.Sqrt(num4);
		newPos = next;
		return true;
	}

	public static bool MoveTowards(float curr, float next, float amt, out float actualAmt, out float newPos)
	{
		float num = next - curr;
		float num2 = num * num;
		if (num2 > amt * amt)
		{
			actualAmt = amt;
			float num3 = Mathf.Sqrt(num2);
			newPos = curr + num / num3 * amt;
			return false;
		}
		actualAmt = Mathf.Sqrt(num2);
		newPos = next;
		return true;
	}

	public static void SetTR(ref Matrix4x4 mat, Vector3 pos, Quaternion rot)
	{
		float x = rot.x;
		float y = rot.y;
		float z = rot.z;
		float w = rot.w;
		float num = 2f * y;
		float num2 = 2f * z;
		float num3 = 2f * x;
		mat.m00 = 1f - num * y - num2 * z;
		mat.m01 = num3 * y - num2 * w;
		mat.m02 = num3 * z + num * w;
		mat.m10 = num3 * y + num2 * w;
		mat.m11 = 1f - num3 * x - num2 * z;
		mat.m12 = num * z - num3 * w;
		mat.m20 = num3 * z - num * w;
		mat.m21 = num * z + num3 * w;
		mat.m22 = 1f - num3 * x - num * y;
		mat.m03 = pos.x;
		mat.m13 = pos.y;
		mat.m23 = pos.z;
		mat.m33 = 1f;
	}

	public static void SetTRS(ref Matrix4x4 mat, Vector3 pos, Quaternion rot, Vector3 scale, float w = 1f)
	{
		float x = rot.x;
		float y = rot.y;
		float z = rot.z;
		float w2 = rot.w;
		float num = 2f * y;
		float num2 = 2f * z;
		float num3 = 2f * x;
		mat.m00 = (1f - num * y - num2 * z) * scale.x;
		mat.m01 = (num3 * y - num2 * w2) * scale.y;
		mat.m02 = (num3 * z + num * w2) * scale.z;
		mat.m10 = (num3 * y + num2 * w2) * scale.x;
		mat.m11 = (1f - num3 * x - num2 * z) * scale.y;
		mat.m12 = (num * z - num3 * w2) * scale.z;
		mat.m20 = (num3 * z - num * w2) * scale.x;
		mat.m21 = (num * z + num3 * w2) * scale.y;
		mat.m22 = (1f - num3 * x - num * y) * scale.z;
		mat.m03 = pos.x;
		mat.m13 = pos.y;
		mat.m23 = pos.z;
		mat.m33 = w;
	}

	public static void SetTRS(ref Matrix4x4 mat, float x, float y, float z, Quaternion rot, Vector3 scale, float w = 1f)
	{
		float x2 = rot.x;
		float y2 = rot.y;
		float z2 = rot.z;
		float w2 = rot.w;
		float num = 2f * y2;
		float num2 = 2f * z2;
		float num3 = 2f * x2;
		mat.m00 = (1f - num * y2 - num2 * z2) * scale.x;
		mat.m01 = (num3 * y2 - num2 * w2) * scale.y;
		mat.m02 = (num3 * z2 + num * w2) * scale.z;
		mat.m10 = (num3 * y2 + num2 * w2) * scale.x;
		mat.m11 = (1f - num3 * x2 - num2 * z2) * scale.y;
		mat.m12 = (num * z2 - num3 * w2) * scale.z;
		mat.m20 = (num3 * z2 - num * w2) * scale.x;
		mat.m21 = (num * z2 + num3 * w2) * scale.y;
		mat.m22 = (1f - num3 * x2 - num * y2) * scale.z;
		mat.m03 = x;
		mat.m13 = y;
		mat.m23 = z;
		mat.m33 = w;
	}

	public static void SetRS(ref Matrix4x4 mat, Quaternion rot, Vector3 scale)
	{
		float x = rot.x;
		float y = rot.y;
		float z = rot.z;
		float w = rot.w;
		mat.m00 = (1f - 2f * y * y - 2f * z * z) * scale.x;
		mat.m01 = (2f * x * y - 2f * z * w) * scale.y;
		mat.m02 = (2f * x * z + 2f * y * w) * scale.z;
		mat.m10 = (2f * x * y + 2f * z * w) * scale.x;
		mat.m11 = (1f - 2f * x * x - 2f * z * z) * scale.y;
		mat.m12 = (2f * y * z - 2f * x * w) * scale.z;
		mat.m20 = (2f * x * z - 2f * y * w) * scale.x;
		mat.m21 = (2f * y * z + 2f * x * w) * scale.y;
		mat.m22 = (1f - 2f * x * x - 2f * y * y) * scale.z;
		mat.m33 = 1f;
	}

	public static void UpdateS(ref Matrix4x4 mat, Vector3 scale)
	{
		mat.m00 = scale.x;
		mat.m01 = 0f;
		mat.m02 = 0f;
		mat.m10 = 0f;
		mat.m11 = scale.y;
		mat.m12 = 0f;
		mat.m20 = 0f;
		mat.m21 = 0f;
		mat.m22 = scale.z;
		mat.m33 = 1f;
	}

	public static void UpdateS(ref Matrix4x4 mat, float scale)
	{
		mat.m00 = scale;
		mat.m01 = 0f;
		mat.m02 = 0f;
		mat.m10 = 0f;
		mat.m11 = scale;
		mat.m12 = 0f;
		mat.m20 = 0f;
		mat.m21 = 0f;
		mat.m22 = scale;
		mat.m33 = 1f;
	}

	public static void SetTS(ref Matrix4x4 mat, Vector3 pos, Vector3 scale)
	{
		mat.m00 = scale.x;
		mat.m01 = 0f;
		mat.m02 = 0f;
		mat.m10 = 0f;
		mat.m11 = scale.y;
		mat.m12 = 0f;
		mat.m20 = 0f;
		mat.m21 = 0f;
		mat.m22 = scale.z;
		mat.m03 = pos.x;
		mat.m13 = pos.y;
		mat.m23 = pos.z;
		mat.m33 = 1f;
	}

	public static void SetT(ref Matrix4x4 mat, Vector3 pos)
	{
		mat.m00 = 1f;
		mat.m01 = 0f;
		mat.m02 = 0f;
		mat.m10 = 0f;
		mat.m11 = 1f;
		mat.m12 = 0f;
		mat.m20 = 0f;
		mat.m21 = 0f;
		mat.m22 = 1f;
		mat.m03 = pos.x;
		mat.m13 = pos.y;
		mat.m23 = pos.z;
		mat.m33 = 1f;
	}

	public static void SetRotationY(ref Quaternion quat, float radians)
	{
		float y = Mathf.Sin(radians / 2f);
		float w = Mathf.Cos(radians / 2f);
		quat.w = w;
		quat.x = 0f;
		quat.y = y;
		quat.z = 0f;
	}

	public static Vector2 WorldPosToScreen(Vector3 worldpoint, RectTransform CanvasRect)
	{
		if (Camera.main == null)
		{
			return default;
		}
		Vector2 vector = Camera.main.WorldToViewportPoint(worldpoint);
		return new Vector2(vector.x * CanvasRect.sizeDelta.x - CanvasRect.sizeDelta.x * 0.5f, vector.y * CanvasRect.sizeDelta.y - CanvasRect.sizeDelta.y * 0.5f);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Sqr(float a)
	{
		return a * a;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float DistSqrd(float a, float b)
	{
		return (a - b) * (a - b);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float MagnitudeSqrdXZ(Vector3 a)
	{
		return a.x * a.x + a.z * a.z;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Magnitude(Vector3 a)
	{
		return Mathf.Sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float MagnitudeXZ(Vector3 a)
	{
		return Mathf.Sqrt(a.x * a.x + a.z * a.z);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float DistSqrd(Vector3 a, Vector3 b)
	{
		return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) + (a.z - b.z) * (a.z - b.z);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float DistSqrdXZ(Vector3 a, Vector3 b)
	{
		return (a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float DistXZ(Vector3 a, Vector3 b)
	{
		return Mathf.Sqrt((a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z));
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float DistXZ(float fx, float fz, float gx, float gz)
	{
		return Mathf.Sqrt((fx - gx) * (fx - gx) + (fz - gz) * (fz - gz));
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float DistSqrdXZ(float ax, float az, float bx, float bz)
	{
		return (ax - bx) * (ax - bx) + (az - bz) * (az - bz);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Dist(Vector3 a, Vector3 b)
	{
		return Mathf.Sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) + (a.z - b.z) * (a.z - b.z));
	}

	public static bool RaySphereIntersect(Ray r, Vector3 center, float radius, out float hitDist)
	{
		hitDist = float.MaxValue;
		Vector3 vector = r.origin - center;
		float num = 2f * (r.direction.x * vector.x + r.direction.y * vector.y + r.direction.z * vector.z);
		float num2 = Vector3.Dot(vector, vector) - radius * radius;
		float num3 = num * num - 4f * num2;
		if (num3 > 0f)
		{
			float num4 = 0f - num - Mathf.Sqrt(num3);
			if ((double)num4 > 0.0)
			{
				hitDist = num4 / 2f;
			}
			else
			{
				num4 = 0f - num + Mathf.Sqrt(num3);
				hitDist = num4 / 2f;
			}
			return true;
		}
		return false;
	}

	public static bool RaySphereIntersect(Ray r, Vector3 center, float radius)
	{
		Vector3 vector = r.origin - center;
		float num = 2f * (r.direction.x * vector.x + r.direction.y * vector.y + r.direction.z * vector.z);
		float num2 = Vector3.Dot(vector, vector) - radius * radius;
		if (num * num - 4f * num2 > 0f)
		{
			return true;
		}
		return false;
	}

	public static bool RayCylinderIntersect(Vector3 ro, Vector3 rd, Vector3 pa, Vector3 pb, float ra, ref float T, ref Vector3 outPos)
	{
		Vector3 vector = pb - pa;
		Vector3 vector2 = ro - pa;
		float num = Vector3.Dot(vector, vector);
		float num2 = Vector3.Dot(vector, rd);
		float num3 = Vector3.Dot(vector, vector2);
		float num4 = num - num2 * num2;
		float num5 = num * Vector3.Dot(vector2, rd) - num3 * num2;
		float num6 = num * Vector3.Dot(vector2, vector2) - num3 * num3 - ra * ra * num;
		float num7 = num5 * num5 - num4 * num6;
		if ((double)num7 < 0.0)
		{
			return false;
		}
		num7 = Mathf.Sqrt(num7);
		float num8 = (0f - num5 - num7) / num4;
		float num9 = num3 + num8 * num2;
		if ((double)num9 > 0.0 && num9 < num)
		{
			T = num8;
			outPos = (vector2 + num8 * rd - vector * num9 / num) / ra;
			return true;
		}
		num8 = (((num9 < 0f) ? 0f : num) - num3) / num2;
		if (Abs(num5 + num4 * num8) < num7)
		{
			T = num8;
			outPos = vector * Mathf.Sign(num9) / num;
			return true;
		}
		return false;
	}

	public static Vector3 ClosestPointOnSegment(Vector3 A, Vector3 B, Vector3 P)
	{
		Vector3 vector = B - A;
		float value = Vector3.Dot(P - A, vector) / Vector3.Dot(vector, vector);
		value = Mathf.Clamp01(value);
		return A + vector * value;
	}

	public static bool ClosestPointsOnTwoLines(out Vector3 closestPointLine1, out Vector3 closestPointLine2, Vector3 linePoint1, Vector3 lineVec1, Vector3 linePoint2, Vector3 lineVec2)
	{
		closestPointLine1 = Vector3.zero;
		closestPointLine2 = Vector3.zero;
		float num = Vector3.Dot(lineVec1, lineVec1);
		float num2 = Vector3.Dot(lineVec1, lineVec2);
		float num3 = Vector3.Dot(lineVec2, lineVec2);
		float num4 = num * num3 - num2 * num2;
		if (num4 != 0f)
		{
			Vector3 rhs = linePoint1 - linePoint2;
			float num5 = Vector3.Dot(lineVec1, rhs);
			float num6 = Vector3.Dot(lineVec2, rhs);
			float num7 = (num2 * num6 - num5 * num3) / num4;
			float num8 = (num * num6 - num5 * num2) / num4;
			closestPointLine1 = linePoint1 + lineVec1 * num7;
			closestPointLine2 = linePoint2 + lineVec2 * num8;
			return true;
		}
		return false;
	}

	public static bool TraceXZTransformBorder(Transform t, TraceEvaluate func)
	{
		Vector3 position = t.position;
		Quaternion rotation = t.rotation;
		Vector3 localScale = t.localScale;
		localScale.x /= 2f;
		localScale.z /= 2f;
		Vector3[] array = new Vector3[4]
		{
			position + rotation * new Vector3(0f - localScale.x, 0f, 0f - localScale.z),
			position + rotation * new Vector3(0f - localScale.x, 0f, localScale.z),
			position + rotation * new Vector3(localScale.x, 0f, localScale.z),
			position + rotation * new Vector3(localScale.x, 0f, 0f - localScale.z)
		};
		for (int i = 0; i < array.Length; i++)
		{
			int num = (i + 1) % array.Length;
			Vector3 newPos = array[i];
			Vector3 next = array[num];
			float actualAmt;
			do
			{
				if (!func((int)newPos.x, (int)newPos.z))
				{
					return false;
				}
			}
			while (!MoveTowards(newPos, next, 1f, out actualAmt, out newPos));
		}
		return true;
	}

	public static Vector3 HermiteSpline(Vector3 A, Vector3 B, Vector3 C, Vector3 D, float t)
	{
		float num = t * t * t;
		float num2 = t * t;
		return A * (2f * num - 3f * num2 + 1f) + B * (num - 2f * num2 + t) + C * (-2f * num + 3f * num2) + D * (num - num2);
	}

	public static Vector3 GetPrimaryAxis(Vector3 v)
	{
		float num = Mathf.Abs(v.x);
		float num2 = Mathf.Abs(v.y);
		float num3 = Mathf.Abs(v.z);
		if (num > num2 && num > num3)
		{
			return new Vector3((v.x > 0f) ? 1 : (-1), 0f, 0f);
		}
		if (num2 > num && num2 > num3)
		{
			return new Vector3(0f, (v.y > 0f) ? 1 : (-1), 0f);
		}
		return new Vector3(0f, 0f, (v.z > 0f) ? 1 : (-1));
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int Max(int a, int b)
	{
		if (a > b)
		{
			return a;
		}
		return b;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Max(float a, float b)
	{
		if (a > b)
		{
			return a;
		}
		return b;
	}

	public static void ToAngleAxis(Vector3 a, Vector3 b, out float angle, out Vector3 axis)
	{
		float num = Vector3.Dot(a, b);
		Vector3 vector = Vector3.Cross(a, b);
		float magnitude = vector.magnitude;
		if (magnitude <= 0.01f)
		{
			if (num > 0f)
			{
				angle = 0f;
				axis = Vector3.up;
			}
			else
			{
				angle = MathF.PI;
				Vector3 lhs = Vector3.Cross(a, Vector3.up);
				axis = Vector3.Cross(lhs, a);
			}
		}
		else
		{
			axis = vector / magnitude;
			angle = Mathf.Asin(axis.magnitude);
			if (num < 0f)
			{
				angle = MathF.PI - angle;
			}
		}
	}

	public static Quaternion Normalized(Quaternion q)
	{
		float num = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w;
		if (num >= 0.0001f)
		{
			float num2 = 1f / Mathf.Sqrt(num);
			q.x *= num2;
			q.y *= num2;
			q.z *= num2;
			q.w *= num2;
			return q;
		}
		return Quaternion.identity;
	}

	public static bool BoxContainsXZ(Matrix4x4 box, Vector3 Loc)
	{
		Vector3 vector = box.inverse.MultiplyPoint(Loc);
		float num = 0.5f;
		if (vector.x > num || vector.x < 0f - num)
		{
			return false;
		}
		if (vector.z > num || vector.z < 0f - num)
		{
			return false;
		}
		return true;
	}

	public static bool BoxContains(Transform box, Vector3 Loc)
	{
		Vector3 vector = box.InverseTransformPoint(Loc);
		float num = 0.5f;
		if (vector.x > num || vector.x < 0f - num)
		{
			return false;
		}
		if (vector.y > num || vector.y < 0f - num)
		{
			return false;
		}
		if (vector.z > num || vector.z < 0f - num)
		{
			return false;
		}
		return true;
	}

	public static bool BoxContains(Vector3 min, Vector3 max, Vector3 Loc)
	{
		if (Loc.x > max.x)
		{
			return false;
		}
		if (Loc.y > max.y)
		{
			return false;
		}
		if (Loc.z > max.z)
		{
			return false;
		}
		if (Loc.x < min.x)
		{
			return false;
		}
		if (Loc.y < min.y)
		{
			return false;
		}
		if (Loc.z < min.z)
		{
			return false;
		}
		return true;
	}

	public static Vector3 ClosestPointOnBoxXZ(Vector3 min, Vector3 max, Vector3 Loc)
	{
		Vector3 result = Loc;
		if (BoxContains(min, max, Loc))
		{
			float num = Abs(max.x - result.x);
			float num2 = Abs(min.x - result.x);
			float num3 = Min(num, num2);
			float num4 = Abs(max.z - result.z);
			float num5 = Abs(min.z - result.z);
			float num6 = Min(num4, num5);
			if (num3 <= num6)
			{
				result.x = ((num < num2) ? max.x : min.x);
			}
			else if (num6 <= num3)
			{
				result.z = ((num4 < num5) ? max.z : min.z);
			}
		}
		else
		{
			result.x = Clamp(result.x, min.x, max.x);
			result.z = Clamp(result.z, min.z, max.z);
		}
		return result;
	}

	public static Vector3 ClosestPointOnBox(Transform box, Vector3 Loc)
	{
		Vector3 position = box.InverseTransformPoint(Loc);
		float num = 0.5f;
		if (BoxContains(box, Loc))
		{
			float num2 = Mathf.Abs(num - position.x);
			float num3 = Mathf.Abs(0f - num - position.x);
			float num4 = Mathf.Min(num2, num3);
			float num5 = Mathf.Abs(num - position.y);
			float num6 = Mathf.Abs(0f - num - position.y);
			float num7 = Mathf.Min(num5, num6);
			float num8 = Mathf.Abs(num - position.z);
			float num9 = Mathf.Abs(0f - num - position.z);
			float num10 = Mathf.Min(num8, num9);
			if (num4 <= num7 && num4 <= num10)
			{
				position.x = ((num2 < num3) ? num : (0f - num));
			}
			else if (num7 <= num4 && num7 <= num10)
			{
				position.y = ((num5 < num6) ? num : (0f - num));
			}
			else if (num10 <= num4 && num10 <= num7)
			{
				position.z = ((num8 < num9) ? num : (0f - num));
			}
		}
		else
		{
			position.x = Clamp(position.x, 0f - num, num);
			position.y = Clamp(position.y, 0f - num, num);
			position.z = Clamp(position.z, 0f - num, num);
		}
		return box.TransformPoint(position);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int Clamp(int v, int min, int max)
	{
		if (v <= max)
		{
			if (v >= min)
			{
				return v;
			}
			return min;
		}
		return max;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Clamp(float v, float min, float max)
	{
		if (!(v > max))
		{
			if (!(v < min))
			{
				return v;
			}
			return min;
		}
		return max;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Clamp01(float v)
	{
		if (!(v > 1f))
		{
			if (!(v < 0f))
			{
				return v;
			}
			return 0f;
		}
		return 1f;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static double Clamp01(double v)
	{
		if (!(v > 1.0))
		{
			if (!(v < 0.0))
			{
				return v;
			}
			return 0.0;
		}
		return 1.0;
	}

	public static int LineSegmentIntersection2D(float p0_x, float p0_y, float p1_x, float p1_y, float p2_x, float p2_y, float p3_x, float p3_y, ref float i_x, ref float i_y)
	{
		float num = p1_x - p0_x;
		float num2 = p1_y - p0_y;
		float num3 = p3_x - p2_x;
		float num4 = p3_y - p2_y;
		float num5 = ((0f - num2) * (p0_x - p2_x) + num * (p0_y - p2_y)) / ((0f - num3) * num2 + num * num4);
		float num6 = (num3 * (p0_y - p2_y) - num4 * (p0_x - p2_x)) / ((0f - num3) * num2 + num * num4);
		if (num5 >= 0f && num5 <= 1f && num6 >= 0f && num6 <= 1f)
		{
			i_x = p0_x + num6 * num;
			i_y = p0_y + num6 * num2;
			return 1;
		}
		return 0;
	}

	public static bool SegmentsCoincidentXZ(Vector3 a0, Vector3 a1, Vector3 b0, Vector3 b1, float toleranceXZ, float minOverlap, float parallelDotThreshold, out Vector3 overlapStartOnA, out Vector3 overlapEndOnA)
	{
		overlapStartOnA = Vector3.zero;
		overlapEndOnA = Vector3.zero;
		Vector2 vector = new Vector2(a0.x, a0.z);
		Vector2 vector2 = new Vector2(a1.x, a1.z);
		Vector2 vector3 = new Vector2(b0.x, b0.z);
		Vector2 vector4 = new Vector2(b1.x, b1.z);
		Vector2 vector5 = vector2 - vector;
		Vector2 vector6 = vector4 - vector3;
		float magnitude = vector5.magnitude;
		float magnitude2 = vector6.magnitude;
		if (magnitude < 0.0001f || magnitude2 < 0.0001f)
		{
			return false;
		}
		Vector2 vector7 = vector5 / magnitude;
		Vector2 rhs = vector6 / magnitude2;
		if (Mathf.Abs(Vector2.Dot(vector7, rhs)) < parallelDotThreshold)
		{
			return false;
		}
		Vector2 rhs2 = new Vector2(0f - vector7.y, vector7.x);
		float num = Mathf.Abs(Vector2.Dot(vector3 - vector, rhs2));
		float num2 = Mathf.Abs(Vector2.Dot(vector4 - vector, rhs2));
		if (num > toleranceXZ || num2 > toleranceXZ)
		{
			return false;
		}
		float a2 = Vector2.Dot(vector3 - vector, vector7);
		float b2 = Vector2.Dot(vector4 - vector, vector7);
		float a3 = Mathf.Min(a2, b2);
		float a4 = Mathf.Max(a2, b2);
		float num3 = Mathf.Max(a3, 0f);
		float num4 = Mathf.Min(a4, magnitude);
		if (num4 - num3 <= minOverlap)
		{
			return false;
		}
		overlapStartOnA = Vector3.Lerp(a0, a1, num3 / magnitude);
		overlapEndOnA = Vector3.Lerp(a0, a1, num4 / magnitude);
		return true;
	}

	public static int GetIntersectionInRect(Rect rect, Vector2 origin, Vector2 target, ref float xPos, ref float yPos)
	{
		xPos = 0f;
		yPos = 0f;
		if (LineSegmentIntersection2D(origin.x + rect.xMin, origin.y + rect.yMin, origin.x + rect.xMin, origin.y + rect.yMax, origin.x, origin.y, target.x, target.y, ref xPos, ref yPos) == 1)
		{
			return 1;
		}
		if (LineSegmentIntersection2D(origin.x + rect.xMin, origin.y + rect.yMin, origin.x + rect.xMax, origin.y + rect.yMin, origin.x, origin.y, target.x, target.y, ref xPos, ref yPos) == 1)
		{
			return 1;
		}
		if (LineSegmentIntersection2D(origin.x + rect.xMax, origin.y + rect.yMin, origin.x + rect.xMax, origin.y + rect.yMax, origin.x, origin.y, target.x, target.y, ref xPos, ref yPos) == 1)
		{
			return 1;
		}
		if (LineSegmentIntersection2D(origin.x + rect.xMin, origin.y + rect.yMax, origin.x + rect.xMax, origin.y + rect.yMax, origin.x, origin.y, target.x, target.y, ref xPos, ref yPos) == 1)
		{
			return 1;
		}
		return 0;
	}

	public static float Linear01ToLogRange(float value, float min, float max)
	{
		if (min == 0f)
		{
			min = 1E-06f;
		}
		return min * Mathf.Pow(max / min, value);
	}

	public static float LogToLinear01Range(float value, float min, float max)
	{
		if (min == 0f)
		{
			min = 1E-06f;
		}
		return Mathf.InverseLerp((float)Math.Log(min), (float)Math.Log(max), (float)Math.Log(value));
	}
}
