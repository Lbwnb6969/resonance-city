using UnityEngine;

namespace Assets;

public class StreamerEffect_DragonSmite : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "DragonSmite";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\plague");
		for (int i = 0; i < DragonSpawn.inst.currentDragons.Count; i++)
		{
			Dragon dragon = DragonSpawn.inst.currentDragons.data[i];
			Weather.inst.LightningStrike(dragon.transform.position, doFire: false, smallstrike: true);
			dragon.TakeDamage(dragon.MaxHP());
		}
	}

	public override void OnEnd()
	{
	}
}
