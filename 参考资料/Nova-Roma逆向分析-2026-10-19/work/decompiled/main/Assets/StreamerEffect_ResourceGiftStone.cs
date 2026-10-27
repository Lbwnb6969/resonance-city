using UnityEngine;

namespace Assets;

public class StreamerEffect_ResourceGiftStone : StreamerEffect_ResourceGift
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.GetPlayerTotalResource(2) < 500;
	}

	public new static string GetTermSegment()
	{
		return "ResourceGiftStone";
	}

	protected override int ResType()
	{
		return 2;
	}

	public override void OnStart()
	{
		base.OnStart();
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\resourcegiftstone");
	}
}
