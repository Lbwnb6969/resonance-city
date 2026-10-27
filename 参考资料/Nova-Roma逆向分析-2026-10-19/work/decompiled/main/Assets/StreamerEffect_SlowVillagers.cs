using UnityEngine;

namespace Assets;

public class StreamerEffect_SlowVillagers : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "SlowVillagers";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\slowvillagers");
		Timer.Duration = 45f;
		StreamerEffects.Flag_SlowVillagers = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_SlowVillagers = false;
	}
}
