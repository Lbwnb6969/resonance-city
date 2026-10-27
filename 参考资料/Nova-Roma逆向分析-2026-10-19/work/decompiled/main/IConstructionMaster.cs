using Assets.Code;
using UnityEngine;

public interface IConstructionMaster
{
	Vector3 GetPosition(int clientIndex);

	ResourceAmount GetTrueCost(int clientIndex);

	string GetFriendlyName(int clientIndex);

	float BuildTimeAtMaxStaff(int clientIndex);

	void GetBoundingFootprint(int clientIndex, out int minX, out int minZ, out int maxX, out int maxZ);

	TransformData GetPositionForBuilder(int clientIndex, int builderIndex);

	int LandMass(int clientIndex);
}
