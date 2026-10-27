using Assets.Code;
using UnityEngine;

namespace Assets.Interface;

public interface IResourceStorageBase
{
	void Deposit(ref ResourceAmount resources);

	int SpaceAvailable(int resourceID);

	Vector3 DropOffLocation(int resourceID);
}
