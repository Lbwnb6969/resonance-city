using System.Collections.Generic;
using UnityEngine;

public static class WaterFlowDiagnostics
{
	public static bool Enabled;

	private static readonly Dictionary<Object, float> removedPerStep = new Dictionary<Object, float>();

	private static readonly Dictionary<Object, float> addedPerStep = new Dictionary<Object, float>();

	private static float logTimer;

	private const float LOG_INTERVAL = 2f;

	public static void ReportRemoved(Object tap, float perStepHuman)
	{
		if (Enabled && !(tap == null))
		{
			removedPerStep[tap] = perStepHuman;
		}
	}

	public static void ReportAdded(Object outlet, float perStepHuman)
	{
		if (Enabled && !(outlet == null))
		{
			addedPerStep[outlet] = perStepHuman;
		}
	}

	public static void Tick(float dt)
	{
		if (!Enabled)
		{
			return;
		}
		logTimer += dt;
		if (logTimer < 2f)
		{
			return;
		}
		logTimer = 0f;
		float num = 0f;
		foreach (float value in removedPerStep.Values)
		{
			num += value;
		}
		float num2 = 0f;
		foreach (float value2 in addedPerStep.Values)
		{
			num2 += value2;
		}
		float num3 = ((num > 0f) ? (num2 / num) : 0f);
		Debug.Log($"[WaterConservation] taps remove {num:F1}/step, outlets add {num2:F1}/step, ratio {num3:F3} " + $"({removedPerStep.Count} taps, {addedPerStep.Count} outlets)");
	}

	public static void Clear()
	{
		removedPerStep.Clear();
		addedPerStep.Clear();
		logTimer = 0f;
	}
}
