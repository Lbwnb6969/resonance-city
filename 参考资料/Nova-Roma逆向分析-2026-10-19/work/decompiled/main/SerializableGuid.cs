using System;

[Serializable]
public struct SerializableGuid : IComparable, IComparable<SerializableGuid>, IEquatable<SerializableGuid>
{
	public string guid;

	private SerializableGuid(string guid)
	{
		this.guid = guid;
	}

	public static implicit operator SerializableGuid(Guid guid)
	{
		return new SerializableGuid(guid.ToString());
	}

	public static implicit operator Guid(SerializableGuid serializableGuid)
	{
		if (serializableGuid.guid == null)
		{
			return Guid.Empty;
		}
		return new Guid(serializableGuid.guid);
	}

	public int CompareTo(object value)
	{
		if (value == null)
		{
			return 1;
		}
		if (!(value is SerializableGuid))
		{
			throw new ArgumentException("Must be SerializableGuid");
		}
		if (!(((SerializableGuid)value).guid == guid))
		{
			return 1;
		}
		return 0;
	}

	public int CompareTo(SerializableGuid other)
	{
		if (!(other.guid == guid))
		{
			return 1;
		}
		return 0;
	}

	public bool Equals(SerializableGuid other)
	{
		return guid == other.guid;
	}

	public override bool Equals(object obj)
	{
		return base.Equals(obj);
	}

	public override int GetHashCode()
	{
		if (guid == null)
		{
			return 0;
		}
		return guid.GetHashCode();
	}

	public override string ToString()
	{
		if (guid == null)
		{
			return string.Empty;
		}
		return new Guid(guid).ToString();
	}
}
