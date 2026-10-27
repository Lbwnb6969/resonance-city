using System;

public class EventBroadcast<T>
{
	private OnActionRaiser<T> BroadcastRegistry = new OnActionRaiser<T>();

	public EventHandler<T> Listen(OnActionListener<T> listener)
	{
		return ListenForAction(BroadcastRegistry, listener);
	}

	public void Unlisten(EventHandler<T> eventHandler)
	{
		UnlistenForAction(BroadcastRegistry, eventHandler);
	}

	public void Broadcast(T data)
	{
		BroadcastRegistry.Invoke(data);
	}

	public void Clear()
	{
		BroadcastRegistry.ClearAll();
	}

	public static EventHandler<TActionData> ListenForAction<TActionData>(OnActionRaiser<TActionData> eventRegistry, OnActionListener<TActionData> listener)
	{
		EventHandler<TActionData> eventHandler = listener.Invoke;
		eventRegistry.OnAction += eventHandler;
		return eventHandler;
	}

	public static void UnlistenForAction<TActionData>(OnActionRaiser<TActionData> eventRegistry, EventHandler<TActionData> eventHandler)
	{
		eventRegistry.OnAction -= eventHandler;
	}
}
