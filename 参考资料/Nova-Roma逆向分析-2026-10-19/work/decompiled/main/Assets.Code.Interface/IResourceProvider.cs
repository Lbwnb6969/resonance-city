using UnityEngine;

namespace Assets.Code.Interface;

public interface IResourceProvider
{
	int LandMass();

	object GetOwner();

	Vector3 ResourcePosition(int resourceID);

	Vector3 CachingCenter();

	bool Available(int resourceID);

	bool ValidToPickupToStoreElsewhere();

	FreeResource ProvideResource(int resourceID);

	bool ProvidesType(int resourceID);

	bool ConsiderAsPrimary(int resourceID);

	int MakeClaim(int resourceID, int count, Villager claimer);

	void ReleaseClaim(int resourceID, Villager claimer);
}
