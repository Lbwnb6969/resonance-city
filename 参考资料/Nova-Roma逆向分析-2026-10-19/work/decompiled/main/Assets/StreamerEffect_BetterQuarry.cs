using UnityEngine;

namespace Assets;

public class StreamerEffect_BetterQuarry : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		if (Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("quarry", mustBeBuilt: true))
		{
			return Player.inst.GetPlayerTotalResource(2) < 500;
		}
		return false;
	}

	public new static string GetTermSegment()
	{
		return "BetterQuarry";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\betterquarry");
		Timer.Duration = 60f;
		StreamerEffects.Flag_BetterQuarry = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_BetterQuarry = false;
	}
}
