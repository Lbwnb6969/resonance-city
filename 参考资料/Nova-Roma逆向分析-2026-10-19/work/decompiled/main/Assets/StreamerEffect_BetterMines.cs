using UnityEngine;

namespace Assets;

public class StreamerEffect_BetterMines : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		if (Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("ironmine", mustBeBuilt: true))
		{
			return Player.inst.GetPlayerTotalResource(5) < 500;
		}
		return false;
	}

	public new static string GetTermSegment()
	{
		return "BetterMines";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\betteriron");
		Timer.Duration = 60f;
		StreamerEffects.Flag_BetterMines = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_BetterMines = false;
	}
}
