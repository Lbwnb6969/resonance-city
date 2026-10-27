using UnityEngine;

namespace Assets;

public class StreamerEffect_BuildingCostsReduced : StreamerEffect
{
	public new static string GetTermSegment()
	{
		return "BuildingCostsReduced";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\buildingcostsreduced");
		Timer.Duration = 60f;
		StreamerEffects.Flag_BuildingCostsReduced = true;
	}

	public override void OnEnd()
	{
		StreamerEffects.Flag_BuildingCostsReduced = false;
	}
}
