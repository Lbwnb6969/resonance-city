using UnityEngine;

namespace Assets;

public class StreamerEffect_ResourceGiftIron : StreamerEffect_ResourceGift
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.GetPlayerTotalResource(5) < 500;
	}

	public new static string GetTermSegment()
	{
		return "ResourceGiftIron";
	}

	protected override int ResType()
	{
		return 5;
	}

	public override void OnStart()
	{
		base.OnStart();
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\resourcegiftiron");
	}
}
