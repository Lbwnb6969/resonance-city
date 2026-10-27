using UnityEngine;

namespace Assets;

public class StreamerEffect_TreeDoubleYield : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "TreeDoubleYield";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\fastchop");
		Timer.Duration = 45f;
		StreamerEffects.Flag_TreeDoubleYield = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_TreeDoubleYield = false;
	}
}
