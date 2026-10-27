using UnityEngine;

namespace Assets;

public class StreamerEffect_ResourceGiftCharcoal : StreamerEffect_ResourceGift
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.GetPlayerTotalResource(3) < 500;
	}

	public new static string GetTermSegment()
	{
		return "ResourceGiftCharcoal";
	}

	protected override int ResType()
	{
		return 3;
	}

	public override void OnStart()
	{
		base.OnStart();
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\resourcegiftcharcoal");
	}
}
