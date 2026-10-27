using UnityEngine;

namespace Assets;

public class StreamerEffect_BetterBlacksmiths : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("blacksmith", mustBeBuilt: true);
	}

	public new static string GetTermSegment()
	{
		return "BetterBlacksmiths";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\betterblacksmith");
		Timer.Duration = 60f;
		StreamerEffects.Flag_BetterBlacksmiths = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_BetterBlacksmiths = false;
	}
}
