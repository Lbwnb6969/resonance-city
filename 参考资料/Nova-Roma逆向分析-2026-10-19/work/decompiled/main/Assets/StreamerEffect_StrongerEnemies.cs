using UnityEngine;

namespace Assets;

public class StreamerEffect_StrongerEnemies : StreamerEffect
{
	private EdgeTrigger edgeTrigger = new EdgeTrigger();

	public new static bool PrereqSatisfied()
	{
		if (Player.inst.difficulty != Player.Difficulty.Easy)
		{
			if (!DragonSpawn.inst.AllowSpawning())
			{
				return RaiderSystem.inst.AllowSpawningVikings();
			}
			return true;
		}
		return false;
	}

	public new static string GetTermSegment()
	{
		return "StrongerEnemies";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\strongerenemies");
		TimerText.enabled = false;
		Timer.Enabled = false;
		StreamerEffects.Flag_StrongerEnemies = true;
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
		StreamerEffects.Flag_StrongerEnemies = false;
	}
}
