using System;
using System.Collections.Generic;
using Assets.Code.Interface;
using UnityEngine;

namespace Assets.Code;

public class ResourceStack : MonoBehaviour, IResourceProvider
{
	[Serializable]
	public class ResourceStackSaveData : SaveClass<ResourceStack, ResourceStackSaveData>
	{
		public int count;

		public int type;

		public SerializableVector3 pos;

		public override ResourceStackSaveData Pack(ResourceStack s)
		{
			count = s.Count();
			type = s.StackType;
			pos = s.transform.position;
			return this;
		}

		public override ResourceStack Unpack(ResourceStack s)
		{
			return s;
		}
	}

	public Stack GraphicalStack;

	public int StackType;

	private List<Villager> resourceClaims = new List<Villager>();

	public object owner;

	public bool validToPickupToStoreElsewhere = true;

	public FreeResource prefab;

	public int Add(int num)
	{
		return GraphicalStack.Add(num);
	}

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
		GraphicalStack.Remove(GraphicalStack.Count());
	}

	public int Count()
	{
		return GraphicalStack.Count();
	}

	public int MaxCapacity()
	{
		return GraphicalStack.MaxCapacity();
	}

	public bool Available(int resourceID)
	{
		return GraphicalStack.Count() > resourceClaims.Count;
	}

	public int AvailableAmount()
	{
		return GraphicalStack.Count() - resourceClaims.Count;
	}

	public bool ProvidesType(int _resourceID)
	{
		return StackType == _resourceID;
	}

	public int MakeClaim(int resourceID, int count, Villager claimer)
	{
		if (resourceID != StackType)
		{
			return 0;
		}
		int num = Mathf.Min(GraphicalStack.Count() - resourceClaims.Count, count);
		for (int i = 0; i < num; i++)
		{
			resourceClaims.Add(claimer);
		}
		return num;
	}

	public void ReleaseClaim(int resourceID, Villager claimer)
	{
		for (int i = 0; i < resourceClaims.Count; i++)
		{
			if (resourceClaims[i].guid == claimer.guid)
			{
				resourceClaims.RemoveAt(i);
				i--;
			}
		}
	}

	public FreeResource ProvideResource(int resourceID)
	{
		if (GraphicalStack.Remove(1) > 0)
		{
			return FreeResourceSystem.inst.AddFreeResource(resourceID, GraphicalStack.transform.position, LandMass());
		}
		return null;
	}

	public int LandMass()
	{
		return World.inst.GetCellDataClamped(transform.position).landMassIdx;
	}

	bool IResourceProvider.ConsiderAsPrimary(int resourceID)
	{
		return true;
	}

	public void Remove(int a)
	{
		GraphicalStack.Remove(a);
	}

	public Vector3 ResourcePosition(int resourceID)
	{
		return transform.position;
	}

	public Vector3 CachingCenter()
	{
		return transform.position;
	}
}
