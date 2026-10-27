using UnityEngine;

namespace Assets;

public class StreamerEffect_InstantVikingAttack : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		return RaiderSystem.inst.AllowSpawningVikings();
	}

	public new static string GetTermSegment()
	{
		return "InstantVikingAttack";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\instantvikingattack");
		Timer.Duration = 10f;
		RaiderSystem.inst.SetupRaid();
	}

	public override void OnEnd()
	{
	}
}
