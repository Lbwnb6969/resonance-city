using UnityEngine;

namespace Assets;

public class StreamerEffect_ResourceGiftArmament : StreamerEffect_ResourceGift
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.GetPlayerTotalResource(7) < 500;
	}

	public new static string GetTermSegment()
	{
		return "ResourceGiftArmament";
	}

	protected override int ResType()
	{
		return 7;
	}

	public override void OnStart()
	{
		base.OnStart();
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\resourcegiftarmament");
	}
}
