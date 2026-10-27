using System.IO;
using Sirenix.Serialization;

public static class SaveSerializer
{
	private const byte ODIN_MARKER = 79;

	private static SerializationContext CreateSerializationContext()
	{
		return new SerializationContext
		{
			Config = 
			{
				SerializationPolicy = SerializationPolicies.Everything
			}
		};
	}

	private static DeserializationContext CreateDeserializationContext()
	{
		return new DeserializationContext
		{
			Config = 
			{
				SerializationPolicy = SerializationPolicies.Everything
			}
		};
	}

	public static void SerializeToStream<T>(T data, Stream stream)
	{
		stream.WriteByte(79);
		SerializationUtility.SerializeValue(data, stream, DataFormat.Binary, CreateSerializationContext());
	}

	public static T DeserializeFromStream<T>(Stream stream)
	{
		if (!stream.CanSeek)
		{
			using (MemoryStream memoryStream = new MemoryStream())
			{
				stream.CopyTo(memoryStream);
				memoryStream.Position = 0L;
				return DeserializeFromStream<T>(memoryStream);
			}
		}
		if (stream.ReadByte() == 79)
		{
			return SerializationUtility.DeserializeValue<T>(stream, DataFormat.Binary, CreateDeserializationContext());
		}
		throw new LegacyFormatException("Save file for " + typeof(T).Name + " is in legacy BinaryFormatter format. Run the Steam migration tool to convert it before loading.");
	}

	public static byte[] SerializeToBytes<T>(T data)
	{
		using MemoryStream memoryStream = new MemoryStream();
		memoryStream.WriteByte(79);
		SerializationUtility.SerializeValue(data, memoryStream, DataFormat.Binary, CreateSerializationContext());
		return memoryStream.ToArray();
	}

	public static T DeserializeFromBytes<T>(byte[] bytes)
	{
		if (bytes != null && bytes.Length != 0 && bytes[0] == 79)
		{
			using (MemoryStream memoryStream = new MemoryStream(bytes))
			{
				memoryStream.Position = 1L;
				return SerializationUtility.DeserializeValue<T>(memoryStream, DataFormat.Binary, CreateDeserializationContext());
			}
		}
		throw new LegacyFormatException("Save data for " + typeof(T).Name + " is in legacy BinaryFormatter format. Run the Steam migration tool to convert it before loading.");
	}

	public static T DeepCopy<T>(T other)
	{
		return SerializationUtility.DeserializeValue<T>(SerializationUtility.SerializeValue(other, DataFormat.Binary, CreateSerializationContext()), DataFormat.Binary, CreateDeserializationContext());
	}
}
