using UnityEngine;

namespace Assets;

public class StreamerEffect_BetterBarracksTraining : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("barracks", mustBeBuilt: true);
	}

	public new static string GetTermSegment()
	{
		return "BetterBarracksTraining";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\betterbarracks");
		Timer.Duration = 60f;
		StreamerEffects.Flag_BetterBarracksTraining = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_BetterBarracksTraining = false;
	}
}
