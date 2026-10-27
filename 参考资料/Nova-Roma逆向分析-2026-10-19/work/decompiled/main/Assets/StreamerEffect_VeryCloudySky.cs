using UnityEngine;

namespace Assets;

public class StreamerEffect_VeryCloudySky : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "VeryCloudySky";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\verycloudysky");
		Timer.Duration = 45f;
		StreamerEffects.Flag_VeryCloudySky = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_VeryCloudySky = false;
	}
}
