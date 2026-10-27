using System;
using System.Collections.Generic;

public class BuildingBroadcast<T>
{
	private Dictionary<int, OnActionRaiser<T>> BroadcastRegistry = new Dictionary<int, OnActionRaiser<T>>();

	public EventHandler<T> Listen(int uniqueBuildingHash, OnActionListener<T> listener)
	{
		return ListenForBuildingAction(BroadcastRegistry, uniqueBuildingHash, listener);
	}

	public EventHandler<T> ListenAny(OnActionListener<T> listener)
	{
		return ListenForBuildingAction(BroadcastRegistry, -1, listener);
	}

	public void Unlisten(int uniqueBuildingHash, EventHandler<T> eventHandler)
	{
		UnlistenForBuildingAction(BroadcastRegistry, uniqueBuildingHash, eventHandler);
	}

	public void UnlistenAny(EventHandler<T> eventHandler)
	{
		UnlistenForBuildingAction(BroadcastRegistry, -1, eventHandler);
	}

	public void Broadcast(Building b, T data)
	{
		BroadcastBuildingAction(BroadcastRegistry, b.uniqueNameHash, data);
	}

	public void Clear()
	{
		foreach (KeyValuePair<int, OnActionRaiser<T>> item in BroadcastRegistry)
		{
			item.Value.ClearAll();
		}
		BroadcastRegistry.Clear();
	}

	public static EventHandler<TActionData> ListenForBuildingAction<TActionData>(Dictionary<int, OnActionRaiser<TActionData>> eventDictionary, int uniqueBuildingHash, OnActionListener<TActionData> listener)
	{
		if (!eventDictionary.ContainsKey(uniqueBuildingHash))
		{
			eventDictionary[uniqueBuildingHash] = new OnActionRaiser<TActionData>();
		}
		EventHandler<TActionData> eventHandler = listener.Invoke;
		eventDictionary[uniqueBuildingHash].OnAction += eventHandler;
		return eventHandler;
	}

	public static void UnlistenForBuildingAction<TActionData>(Dictionary<int, OnActionRaiser<TActionData>> eventDictionary, int uniqueBuildingHash, EventHandler<TActionData> eventHandler)
	{
		if (eventDictionary.ContainsKey(uniqueBuildingHash))
		{
			eventDictionary[uniqueBuildingHash].OnAction -= eventHandler;
			if (eventDictionary[uniqueBuildingHash].IsEmpty())
			{
				eventDictionary.Remove(uniqueBuildingHash);
			}
		}
	}

	public static void BroadcastBuildingAction<T>(Dictionary<int, OnActionRaiser<T>> eventDictionary, int uniqueNameHash, T action)
	{
		if (eventDictionary.ContainsKey(uniqueNameHash))
		{
			eventDictionary[uniqueNameHash].Invoke(action);
		}
		if (eventDictionary.ContainsKey(-1))
		{
			eventDictionary[-1].Invoke(action);
		}
	}
}
