using System;
using UnityEngine;

[Serializable]
public struct SerializableQuaternion(float rX, float rY, float rZ, float rW)
{
	public float x = rX;

	public float y = rY;

	public float z = rZ;

	public float w = rW;

	public override string ToString()
	{
		return $"[{x}, {y}, {z}, {w}]";
	}

	public static implicit operator Quaternion(SerializableQuaternion rValue)
	{
		return new Quaternion(rValue.x, rValue.y, rValue.z, rValue.w);
	}

	public static implicit operator SerializableQuaternion(Quaternion rValue)
	{
		return new SerializableQuaternion(rValue.x, rValue.y, rValue.z, rValue.w);
	}
}
