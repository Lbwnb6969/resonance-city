using Assets.Code;

namespace Assets.Interface;

public interface IResourceStorage : IResourceStorageBase
{
	int MaxStorageFor(int resourceID);

	int StoredPublicResources(int resourceID);

	bool AcceptsType(int resourceID);

	bool StoresTypePublic(int resourceID);

	void RemoveResources(ResourceAmount amount);

	int LandMass();
}
