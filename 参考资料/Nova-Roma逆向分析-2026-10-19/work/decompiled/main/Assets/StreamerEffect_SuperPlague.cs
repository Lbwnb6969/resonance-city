using UnityEngine;

namespace Assets;

public class StreamerEffect_SuperPlague : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "SuperPlague";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\superplague");
		Timer.Duration = 10f;
		Player.inst.PlagueStartSuper();
	}

	public override void OnEnd()
	{
	}
}
