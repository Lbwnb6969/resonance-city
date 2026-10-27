using UnityEngine;

namespace Assets;

public class StreamerEffect_LightningStorm : StreamerEffect
{
	private Timer lightningTimer = new Timer(1f);

	public new static bool PrereqSatisfied()
	{
		return Player.inst.TotalWorkers() > Weather.MinPopulationLightning;
	}

	public new static string GetTermSegment()
	{
		return "LightningStorm";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\lightningstorm");
		Timer.Duration = 20 + Player.inst.Workers.Count / 500;
		TimerText.enabled = true;
		lightningTimer.ForceExpire();
		StreamerEffects.Flag_LightningStorm = true;
	}

	public override void OnUpdate()
	{
		base.OnUpdate();
		if (lightningTimer.Update(Time.deltaTime))
		{
			lightningTimer.Duration = 1f + SRand.Range(0f, 1f);
			if (SRand.Range(0, 100) > 75)
			{
				Vector3 strikePos = new Vector3(SRand.value * (float)World.inst.GridWidth, 10f, SRand.value * (float)World.inst.GridHeight);
				Weather.inst.LightningStrike(strikePos);
			}
			else if (Player.inst.Buildings.Count > 0)
			{
				Vector3 strikePos2 = Player.inst.Buildings.RandomElement().Center();
				Weather.inst.LightningStrike(strikePos2);
			}
		}
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_LightningStorm = false;
	}
}
