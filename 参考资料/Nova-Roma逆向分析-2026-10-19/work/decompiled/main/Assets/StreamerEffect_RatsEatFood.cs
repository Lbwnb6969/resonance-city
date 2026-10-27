using UnityEngine;

namespace Assets;

public class StreamerEffect_RatsEatFood : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		if (!Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("largegranary", mustBeBuilt: true))
		{
			return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("smallgranary", mustBeBuilt: true);
		}
		return true;
	}

	public new static string GetTermSegment()
	{
		return "RatsEatFood";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\ratseatfood");
		Timer.Duration = 10f;
		TimerText.enabled = false;
	}

	public override void OnEnd()
	{
	}
}
