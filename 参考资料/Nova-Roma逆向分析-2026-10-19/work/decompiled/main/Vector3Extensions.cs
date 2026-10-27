using UnityEngine;

public static class Vector3Extensions
{
	public static Vector3 xy(this Vector3 input)
	{
		return new Vector3(input.x, input.y, 0f);
	}

	public static Vector2 xy2D(this Vector3 input)
	{
		return new Vector2(input.x, input.y);
	}

	public static Vector3 yz(this Vector3 input)
	{
		return new Vector3(0f, input.y, input.z);
	}

	public static Vector3 xz(this Vector3 input)
	{
		return new Vector3(input.x, 0f, input.z);
	}

	public static Vector3 xz2D(this Vector3 input)
	{
		return new Vector3(input.x, input.z, 0f);
	}

	public static Vector3 xv(this Vector3 input)
	{
		return new Vector3(input.x, 0f, 0f);
	}

	public static Vector3 yv(this Vector3 input)
	{
		return new Vector3(0f, input.y, 0f);
	}

	public static Vector3 zv(this Vector3 input)
	{
		return new Vector3(0f, 0f, input.z);
	}

	public static bool IsNan(this Vector3 input)
	{
		if (!float.IsNaN(input.x) && !float.IsNaN(input.y))
		{
			return float.IsNaN(input.z);
		}
		return true;
	}

	public static void NonAllocateNormalize(this ref Vector3 input)
	{
		float magnitude = input.magnitude;
		if ((double)magnitude > 9.999999747378752E-06)
		{
			input.x /= magnitude;
			input.y /= magnitude;
			input.z /= magnitude;
		}
		else
		{
			input.x = 0f;
			input.y = 0f;
			input.z = 0f;
		}
	}

	public static void NonAllocateAdd(this ref Vector3 input, Vector3 target)
	{
		input.x += target.x;
		input.y += target.y;
		input.z += target.z;
	}

	public static void NonAllocateSubtract(this ref Vector3 input, Vector3 target)
	{
		input.x -= target.x;
		input.y -= target.y;
		input.z -= target.z;
	}

	public static void NonAllocateMultiply(this ref Vector3 input, Vector3 target)
	{
		input.x *= target.x;
		input.y *= target.y;
		input.z *= target.z;
	}

	public static void NonAllocateMultiply(this ref Vector3 input, float val)
	{
		input.x *= val;
		input.y *= val;
		input.z *= val;
	}

	public static void NonAllocateDivide(this ref Vector3 input, float val)
	{
		input.x /= val;
		input.y /= val;
		input.z /= val;
	}
}
