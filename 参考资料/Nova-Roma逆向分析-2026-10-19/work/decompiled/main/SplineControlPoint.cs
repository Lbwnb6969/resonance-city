using System;
using UnityEngine;

[Serializable]
public class SplineControlPoint<T> where T : class
{
	public T data;

	public SerializableVector3 pos;

	public SplineControlPoint(Vector3 pos, T customData = null)
	{
		this.pos = pos;
		data = customData;
	}
}
