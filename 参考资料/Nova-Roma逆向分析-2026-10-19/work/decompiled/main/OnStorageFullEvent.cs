using System;

public class OnStorageFullEvent : EventArgs
{
	public enum StorageFullType
	{
		Quarry,
		Forester
	}

	public Building b;
}
