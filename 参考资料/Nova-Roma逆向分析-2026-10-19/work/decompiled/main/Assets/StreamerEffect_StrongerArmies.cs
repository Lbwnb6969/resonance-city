using UnityEngine;

namespace Assets;

public class StreamerEffect_StrongerArmies : StreamerEffect
{
	private EdgeTrigger edgeTrigger = new EdgeTrigger();

	public new static bool PrereqSatisfied()
	{
		return ArmySystem.inst.GetPlayerArmies() > 0;
	}

	public new static string GetTermSegment()
	{
		return "StrongerArmies";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\strongerarmies");
		TimerText.enabled = false;
		Timer.Enabled = false;
		StreamerEffects.Flag_StrongerArmies = true;
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
		StreamerEffects.Flag_StrongerArmies = false;
	}
}
