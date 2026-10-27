using UnityEngine;

namespace Assets;

public class StreamerEffect_GrandFestival : StreamerEffect
{
	public new static bool PrereqSatisfied()
	{
		return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("townsquare", mustBeBuilt: true);
	}

	public new static string GetTermSegment()
	{
		return "GrandFestival";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\grandfestival");
		Timer.Duration = 10f;
		TimerText.enabled = false;
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("townsquare");
		for (int i = 0; i < buildingList.Count; i++)
		{
			buildingList.data[i].GetComponent<TownSquare>().BeginFestival();
		}
	}

	public override void OnEnd()
	{
	}
}
