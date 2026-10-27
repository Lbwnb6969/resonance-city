using UnityEngine;

namespace Assets;

public class StreamerEffect_PlagueCure : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "PlagueCure";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\plague");
		Player.inst.CurePlague();
	}

	public override void OnEnd()
	{
	}
}
