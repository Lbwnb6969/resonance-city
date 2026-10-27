using System;
using System.Runtime.CompilerServices;
using UnityEngine;

[Serializable]
public class MinMax
{
	public float Min;

	public float Max;

	public MinMax(float min, float max)
	{
		Min = min;
		Max = max;
	}

	public float Clamp(float val)
	{
		return Mathf.Clamp(val, Min, Max);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public float Rand()
	{
		return SRand.Range(Min, Max);
	}

	public float Lerp(float t)
	{
		return Mathf.Lerp(Min, Max, t);
	}

	public float GetT(float val)
	{
		return Mathff.Clamp01((val - Min) / (Max - Min));
	}
}
