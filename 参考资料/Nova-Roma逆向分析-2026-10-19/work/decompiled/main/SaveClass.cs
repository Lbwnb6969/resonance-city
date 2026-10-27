using System;

[Serializable]
public abstract class SaveClass<T, TS>
{
	public abstract TS Pack(T obj);

	public abstract T Unpack(T obj);
}
