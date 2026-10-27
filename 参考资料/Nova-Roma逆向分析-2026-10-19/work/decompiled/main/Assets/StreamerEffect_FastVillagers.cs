using UnityEngine;

namespace Assets;

public class StreamerEffect_FastVillagers : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "FastVillagers";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\fastvillagers");
		Timer.Duration = 90f;
		StreamerEffects.Flag_FastVillagers = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_FastVillagers = false;
	}
}
