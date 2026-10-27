using UnityEngine;

namespace Assets;

public class StreamerEffect_FeedEveryoneInstantly : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "FeedEveryoneInstantly";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\feedeveryoneinstantly");
		Timer.Duration = 10f;
		Player.inst.FeedAllForFree();
	}

	public override void OnEnd()
	{
	}
}
