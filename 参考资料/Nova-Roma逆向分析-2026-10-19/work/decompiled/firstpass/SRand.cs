using System;
using System.Runtime.CompilerServices;
using UnityEngine;

public static class SRand
{
	public static System.Random srand = new System.Random();

	public static float value => UnityEngine.Random.value;

	public static Vector3 insideUnitSquareXZ => new Vector3(Range(-0.49f, 0.49f), 0f, Range(-0.49f, 0.49f));

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int Range(int min, int max)
	{
		return UnityEngine.Random.Range(min, max);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static float Range(float min, float max)
	{
		return UnityEngine.Random.Range(min, max);
	}

	public static void SetSeed(int seed)
	{
		UnityEngine.Random.InitState(seed);
	}

	public static UnityEngine.Random.State GetState()
	{
		return UnityEngine.Random.state;
	}

	public static void SetState(UnityEngine.Random.State state)
	{
		UnityEngine.Random.state = state;
	}

	public static bool CoinFlip()
	{
		return Range(0, 2) == 0;
	}
}
