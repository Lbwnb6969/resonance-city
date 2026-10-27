using System;
using UnityEngine;

[Serializable]
public class BuildingDescriptionDamPlanning
{
	public string uniqueName;

	public int uniqueNameHash;

	public SerializableVector3 position;

	public DamBlockState savedState;

	public BuildingDescriptionDamPlanning(Building building)
	{
		uniqueName = building.UniqueName;
		uniqueNameHash = building.uniqueNameHash;
		position = building.Center();
		savedState = new DamBlockState(building);
	}

	public override bool Equals(object obj)
	{
		if (obj == null || !(obj is BuildingDescriptionDamPlanning))
		{
			return false;
		}
		if (uniqueNameHash == ((BuildingDescriptionDamPlanning)obj).uniqueNameHash)
		{
			if (uniqueNameHash == World.spilloverHash)
			{
				Vector3 vector = ((BuildingDescriptionDamPlanning)obj).position;
				if (position.x == vector.x)
				{
					return position.z == vector.z;
				}
				return false;
			}
			return (Vector3)position == (Vector3)((BuildingDescriptionDamPlanning)obj).position;
		}
		return false;
	}
}
