using System;
using UnityEngine;

namespace Assets;

public class StreamerEffect_FreeBuilding : StreamerEffect
{
	private EventHandler<OnBuildingAddRemove> eventHandler;

	public new static string GetTermSegment()
	{
		return "FreeBuilding";
	}

	public override void OnStart()
	{
		Icon.sprite = Resources.Load<Sprite>("StreamerEffectIcons\\freebuilding");
		Timer = null;
		TimerText.enabled = false;
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(OnBuildingAddRemove);
		StreamerEffects.Flag_FreeBuilding = true;
	}

	public override void OnEnd()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
		StreamerEffects.Flag_FreeBuilding = false;
	}

	public void OnBuildingAddRemove(object b, OnBuildingAddRemove eventData)
	{
		if (eventData.added)
		{
			Done();
		}
	}
}
