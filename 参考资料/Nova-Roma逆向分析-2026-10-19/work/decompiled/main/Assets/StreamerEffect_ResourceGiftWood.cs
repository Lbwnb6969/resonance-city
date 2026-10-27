using UnityEngine;

namespace Assets;

public class StreamerEffect_ResourceGiftWood : StreamerEffect_ResourceGift
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.GetPlayerTotalResource(1) < 500;
	}

	public new static string GetTermSegment()
	{
		return "ResourceGiftWood";
	}

	protected override int ResType()
	{
		return 1;
	}

	public override void OnStart()
	{
		base.OnStart();
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\resourcegiftwood");
	}
}
