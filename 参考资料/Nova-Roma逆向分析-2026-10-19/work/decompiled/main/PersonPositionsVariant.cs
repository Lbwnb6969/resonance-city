using System;

[Serializable]
public struct PersonPositionsVariant
{
	public SerializableVector3[] positions;

	public SerializableQuaternion[] rotations;
}
