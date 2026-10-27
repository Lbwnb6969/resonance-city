using UnityEngine;

namespace Assets;

public class StreamerEffect_BetterCharcoalMakers : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		if (Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("charcoalmaker", mustBeBuilt: true))
		{
			return Player.inst.GetPlayerTotalResource(3) < 500;
		}
		return false;
	}

	public new static string GetTermSegment()
	{
		return "BetterCharcoalMakers";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\bettercharcoal");
		Timer.Duration = 60f;
		StreamerEffects.Flag_BetterCharcoalMakers = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_BetterCharcoalMakers = false;
	}
}
