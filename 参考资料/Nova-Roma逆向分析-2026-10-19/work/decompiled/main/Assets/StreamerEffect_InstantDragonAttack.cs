using UnityEngine;

namespace Assets;

public class StreamerEffect_InstantDragonAttack : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "InstantDragonAttack";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\instantdragonattack");
		Timer.Duration = 10f;
		DragonSpawn.inst.SpawnMamaDragon();
	}

	public override void OnEnd()
	{
	}
}
