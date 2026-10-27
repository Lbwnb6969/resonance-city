using System;
using System.Collections.Generic;

public static class Extensions
{
	public static float Remap(this float value, float fromLow1, float fromHigh1, float toLow2, float toHigh2)
	{
		return toLow2 + (value - fromLow1) * (toHigh2 - toLow2) / (fromHigh1 - fromLow1);
	}

	public static bool IndexInBounds(this int value, Array collection)
	{
		return InBounds(value, collection.Length);
	}

	public static bool IndexInBounds(this int value, List<object> collection)
	{
		return InBounds(value, collection.Count);
	}

	private static bool InBounds(int value, int length)
	{
		if (value >= 0)
		{
			return value < length;
		}
		return false;
	}

	public static bool IsNull(this object value)
	{
		return value == null;
	}

	public static int Random0toN(this int value)
	{
		return SRand.Range(0, value);
	}
}
