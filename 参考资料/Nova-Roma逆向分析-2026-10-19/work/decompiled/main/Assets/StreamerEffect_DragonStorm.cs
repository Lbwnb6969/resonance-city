using UnityEngine;

namespace Assets;

public class StreamerEffect_DragonStorm : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "DragonStorm";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\dragonstorm");
		Timer.Duration = 30f;
		TimerText.enabled = false;
		int num = Player.inst.TotalWorkers() / 50 + 5;
		for (int i = 0; i < num; i++)
		{
			if (SRand.Range(0, 4) == 0)
			{
				DragonSpawn.inst.SpawnMamaDragon();
			}
			else
			{
				DragonSpawn.inst.SpawnBabyDragon();
			}
		}
	}

	public override void OnEnd()
	{
	}
}
