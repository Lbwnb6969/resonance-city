using UnityEngine;

namespace Assets;

public class StreamerEffect_BetterCropYield : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "BetterCropYield";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\cropyield");
		Timer.Duration = 60f;
		StreamerEffects.Flag_BetterCropYield = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_BetterCropYield = false;
	}
}
