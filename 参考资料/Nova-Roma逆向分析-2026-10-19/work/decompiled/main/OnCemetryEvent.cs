using System;
using UnityEngine;

public class OnCemetryEvent : EventArgs
{
	public enum CemeteryEventType
	{
		CemeteryFull,
		DeadBodyPlague,
		NormalDeath
	}

	public CemeteryEventType eventType;

	public Vector3 eventPosition;
}
