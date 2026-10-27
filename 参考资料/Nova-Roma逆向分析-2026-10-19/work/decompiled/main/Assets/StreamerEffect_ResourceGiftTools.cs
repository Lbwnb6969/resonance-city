using UnityEngine;

namespace Assets;

public class StreamerEffect_ResourceGiftTools : StreamerEffect_ResourceGift
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.GetPlayerTotalResource(6) < 500;
	}

	public new static string GetTermSegment()
	{
		return "ResourceGiftTools";
	}

	protected override int ResType()
	{
		return 6;
	}

	public override void OnStart()
	{
		base.OnStart();
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\resourcegifttools");
	}
}
