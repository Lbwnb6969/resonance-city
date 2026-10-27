using UnityEngine;

public class AudioEffectManager : MonoBehaviour
{
	public static float globalLowPassFrequency = 22000f;

	public float test;

	[Range(0f, 1f)]
	public float globalLowPassFrequencyPercentTarget = 1f;

	public float globalLowPassFrequencyPercent = 1f;

	public int lowPassFloorFrequency = 6000;

	public static AudioEffectManager inst;

	private void Start()
	{
		inst = this;
	}

	private void Update()
	{
		if (globalLowPassFrequencyPercentTarget < globalLowPassFrequencyPercent)
		{
			globalLowPassFrequencyPercent = globalLowPassFrequencyPercentTarget;
		}
		globalLowPassFrequencyPercent = Mathf.MoveTowards(globalLowPassFrequencyPercent, globalLowPassFrequencyPercentTarget, Time.unscaledDeltaTime * 2f);
		globalLowPassFrequency = Mathff.Linear01ToLogRange(globalLowPassFrequencyPercent, 20f, 22000f);
		if (AmbientSfx.inst.lowPassFilter != null)
		{
			AmbientSfx.inst.lowPassFilter.cutoffFrequency = globalLowPassFrequency;
		}
		test = globalLowPassFrequency;
	}

	public static void SetLowpassFrequency(int frequency)
	{
		if (!(inst == null))
		{
			inst.globalLowPassFrequencyPercentTarget = Mathff.LogToLinear01Range(frequency, 20f, 22000f);
		}
	}

	public static void ResetLowpass()
	{
		SetLowpassFrequency(22000);
	}

	public static void ActivateLowpass()
	{
		SetLowpassFrequency(inst.lowPassFloorFrequency);
	}
}
