using UnityEngine;

namespace Assets;

public class StreamerEffect_NormalPlague : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "NormalPlague";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\plague");
		Timer.Duration = 10f;
		Player.inst.PlagueStartNormal();
	}

	public override void OnEnd()
	{
	}
}
