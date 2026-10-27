using UnityEngine;

namespace Assets;

public class StreamerEffect_ChopFaster : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "FastChopping";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\fastchop");
		Timer.Duration = 60f;
		StreamerEffects.Flag_ChopFaster = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_ChopFaster = false;
	}
}
