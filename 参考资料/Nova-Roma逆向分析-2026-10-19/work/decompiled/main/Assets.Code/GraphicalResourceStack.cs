using System;
using System.Runtime.CompilerServices;
using Assets.Code.Interface;
using UnityEngine;

namespace Assets.Code;

public class GraphicalResourceStack : Stack, IResourceProvider
{
	[Serializable]
	public class GraphicalResourceStackSaveData : SaveClass<GraphicalResourceStack, GraphicalResourceStackSaveData>
	{
		public int count;

		public int resourceID;

		public SerializableVector3 pos;

		public override GraphicalResourceStackSaveData Pack(GraphicalResourceStack s)
		{
			count = s.Count();
			resourceID = s.resourceID;
			pos = s.xform.position;
			return this;
		}

		public override GraphicalResourceStack Unpack(GraphicalResourceStack s)
		{
			return s;
		}
	}

	private ArrayExtRef<Villager> resourceClaims = new ArrayExtRef<Villager>(5);

	public object owner;

	public bool validToPickupToStoreElsewhere = true;

	private int landmass = -1;

	public object GetOwner()
	{
		return owner;
	}

	public bool ValidToPickupToStoreElsewhere()
	{
		return validToPickupToStoreElsewhere;
	}

	public void Clear()
	{
		Remove(internalCount);
	}

	public bool Available(int resourceID)
	{
		if (base.resourceID != resourceID)
		{
			return false;
		}
		return internalCount > resourceClaims.Count;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public int AvailableAmount()
	{
		return internalCount - resourceClaims.Count;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public bool ProvidesType(int _resourceID)
	{
		return resourceID == _resourceID;
	}

	public int MakeClaim(int _resourceID, int count, Villager claimer)
	{
		if (_resourceID != resourceID)
		{
			return 0;
		}
		int num = Mathf.Min(internalCount - resourceClaims.Count, count);
		for (int i = 0; i < num; i++)
		{
			resourceClaims.Add(claimer);
		}
		return num;
	}

	public void ReleaseClaim(int _resourceID, Villager claimer)
	{
		for (int i = 0; i < resourceClaims.Count; i++)
		{
			if (resourceClaims.data[i].guid == claimer.guid)
			{
				resourceClaims.RemoveAt(i);
				i--;
			}
		}
	}

	public FreeResource ProvideResource(int rID)
	{
		if (Remove(1) > 0)
		{
			return FreeResourceSystem.inst.AddFreeResource(resourceID, xform.position, LandMass());
		}
		return null;
	}

	public int LandMass()
	{
		if (landmass == -1)
		{
			landmass = World.inst.GetCellDataClamped(xform.position).landMassIdx;
		}
		return landmass;
	}

	bool IResourceProvider.ConsiderAsPrimary(int rID)
	{
		return true;
	}

	public Vector3 ResourcePosition(int resourceID1)
	{
		return xform.position;
	}

	public Vector3 CachingCenter()
	{
		return xform.position;
	}
}
