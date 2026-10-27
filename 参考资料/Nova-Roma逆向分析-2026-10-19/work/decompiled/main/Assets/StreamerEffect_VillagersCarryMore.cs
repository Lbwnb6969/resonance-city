using UnityEngine;

namespace Assets;

public class StreamerEffect_VillagersCarryMore : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "VillagersCarryMore";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\villagerscarrymore");
		Timer.Duration = 90f;
		StreamerEffects.Flag_VillagersCarryMore = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_VillagersCarryMore = false;
	}
}
