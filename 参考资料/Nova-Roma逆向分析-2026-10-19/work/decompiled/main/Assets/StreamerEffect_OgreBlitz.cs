using UnityEngine;

namespace Assets;

public class StreamerEffect_OgreBlitz : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		if (RaiderSystem.inst.AllowSpawningVikings())
		{
			return Player.inst.TotalWorkers() > 100;
		}
		return false;
	}

	public new static string GetTermSegment()
	{
		return "OgreBlitz";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\ogreblitz");
		Timer.Duration = 10f;
	}

	public override void OnEnd()
	{
	}
}
