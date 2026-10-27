using UnityEngine;

namespace Assets;

public class StreamerEffect_FasterAttackSpeed : StreamerEffect
{
	private EdgeTrigger edgeTrigger = new EdgeTrigger();

	public new static bool PrereqSatisfied()
	{
		if (ArmySystem.inst.GetPlayerArmies() <= 0 && !Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("archer", mustBeBuilt: false))
		{
			return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("ballista", mustBeBuilt: false);
		}
		return true;
	}

	public new static string GetTermSegment()
	{
		return "FasterAttackSpeed";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\fasterattackspeed");
		TimerText.enabled = false;
		Timer.Enabled = false;
		StreamerEffects.Flag_FasterAttackSpeed = true;
	}

	public override void OnUpdate()
	{
		if (edgeTrigger.CheckFalling(RaiderSystem.inst.IsRaidInProgress()))
		{
			Done();
		}
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_FasterAttackSpeed = false;
	}
}
