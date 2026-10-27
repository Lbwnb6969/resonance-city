using System;
using UnityEngine;

[Serializable]
public struct SerializableVector3(float rX, float rY, float rZ)
{
	public float x = rX;

	public float y = rY;

	public float z = rZ;

	public override string ToString()
	{
		return $"[{x}, {y}, {z}]";
	}

	public static implicit operator Vector3(SerializableVector3 rValue)
	{
		return new Vector3(rValue.x, rValue.y, rValue.z);
	}

	public static implicit operator SerializableVector3(Vector3 rValue)
	{
		return new SerializableVector3(rValue.x, rValue.y, rValue.z);
	}
}
