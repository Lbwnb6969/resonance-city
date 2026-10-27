using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets.Code.Interface;
using UnityEngine;

namespace Assets;

public class FreeResource : InstanceSystem.Owner, IResourceProvider
{
	[Serializable]
	public class FreeResourceSaveData : SaveClass<FreeResource, FreeResourceSaveData>
	{
		public SerializableVector3 position;

		public SerializableQuaternion rotation;

		public int resourceID;

		[OptionalField(VersionAdded = 2)]
		public List<object> components = new List<object>();

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			components = new List<object>();
		}

		public override FreeResourceSaveData Pack(FreeResource f)
		{
			position = f.Pos;
			rotation = f.Rot;
			resourceID = f.resourceID;
			return this;
		}

		public override FreeResource Unpack(FreeResource f)
		{
			f.SetPositionAndRotation(position, rotation);
			return f;
		}
	}

	[NonSerialized]
	public int landMassIdx = -1;

	internal bool skipVisibility = true;

	private bool registeredAsProvider;

	public Vector3 bounds;

	public Vector3 offset = Vector3.zero;

	private int idxIntoActiveResourceList = -1;

	public int idxIntoPool = -1;

	public static int freeResourcePoolCount = 0;

	public static ArrayExt<FreeResource> freeResourcePool = new ArrayExt<FreeResource>(10000);

	public static ArrayExt<FreeResource> freeResources = new ArrayExt<FreeResource>(5000);

	private bool firstUpdate = true;

	private bool shutdown = true;

	private string stack;

	public int resourceID;

	private Villager holder;

	internal Villager claim;

	public bool visible = true;

	private Vector3 pos;

	private Quaternion rot;

	private Vector3 scale = Vector3.one;

	private InstanceSystem instSystem;

	public Villager Holder
	{
		get
		{
			return holder;
		}
		set
		{
			if (value == null)
			{
				if (!registeredAsProvider)
				{
					FreeResourceManager.inst.AddResourceProvider(this);
				}
				registeredAsProvider = true;
			}
			else
			{
				if (registeredAsProvider)
				{
					FreeResourceManager.inst.RemoveResourceProvider(this);
				}
				registeredAsProvider = false;
			}
			holder = value;
		}
	}

	public Vector3 Pos
	{
		get
		{
			return pos;
		}
		set
		{
			pos = value;
			Mathff.SetTRS(ref instSystem.silos.data[s][idx], value, Rot, Scale, visible ? 1f : 0f);
		}
	}

	public Quaternion Rot
	{
		get
		{
			return rot;
		}
		set
		{
			rot = value;
			Mathff.SetTRS(ref instSystem.silos.data[s][idx], Pos, value, Scale, visible ? 1f : 0f);
		}
	}

	public Vector3 Scale => scale;

	public static bool operator ==(FreeResource c1, object c2)
	{
		if ((object)c1 == null)
		{
			return c2 == null;
		}
		if (c1.shutdown && c2 == null)
		{
			return true;
		}
		return c1.Equals(c2);
	}

	public override int GetHashCode()
	{
		return base.GetHashCode();
	}

	public static bool operator !=(FreeResource c1, object c2)
	{
		return !(c1 == c2);
	}

	public override bool Equals(object obj)
	{
		if (shutdown && obj == null)
		{
			return true;
		}
		return base.Equals(obj);
	}

	public virtual void Init()
	{
		if (!shutdown)
		{
			_ = 0;
		}
		shutdown = false;
		registeredAsProvider = false;
		freeResources.Add(this);
		idxIntoActiveResourceList = freeResources.Count - 1;
		instSystem = FreeResourceSystem.inst.instances[resourceID];
		holder = null;
		claim = null;
		visible = true;
		firstUpdate = true;
	}

	public virtual void Tick(float dt)
	{
		if (FogOfWar.inst.dirty || firstUpdate)
		{
			Vector3 vector = Pos;
			int x = (int)vector.x;
			int z = (int)vector.z;
			bool flag = skipVisibility || FogOfWar.inst.IsVisible(x, z);
			if (flag != visible)
			{
				visible = flag;
				if (holder == null)
				{
					SetPositionAndRotation(pos, rot);
				}
			}
		}
		firstUpdate = false;
	}

	public virtual void Shutdown()
	{
		if (shutdown)
		{
			_ = 0;
		}
		shutdown = true;
		instSystem = null;
		if (registeredAsProvider)
		{
			FreeResourceManager.inst.RemoveResourceProvider(this);
			registeredAsProvider = false;
		}
		ReleaseFromPool(idxIntoPool, freeResourcePool);
		ReleaseFromList(idxIntoActiveResourceList, freeResources);
		FreeResourceSystem.inst.RemoveFreeResource(this);
	}

	public static void ReleaseFromPool(int idx, ArrayExt<FreeResource> array)
	{
		array.RemoveAtSwapBoth(idx);
		if (array.Count > 0 && idx < array.Count)
		{
			array.data[idx].idxIntoPool = idx;
		}
	}

	public static void ReleaseFromList(int idx, ArrayExt<FreeResource> array)
	{
		array.RemoveAtSwap(idx);
		if (array.Count > 0 && idx < array.Count)
		{
			array.data[idx].idxIntoActiveResourceList = idx;
		}
	}

	public void SetPositionAndRotation(Vector3 newPos, Quaternion newRot)
	{
		pos = newPos;
		rot = newRot;
		Mathff.SetTRS(ref instSystem.silos.data[s][idx], pos, rot, scale, visible ? 1f : 0f);
	}

	int IResourceProvider.LandMass()
	{
		return landMassIdx;
	}

	public Vector3 ResourcePosition(int resourceID1)
	{
		return pos;
	}

	public Vector3 CachingCenter()
	{
		return pos;
	}

	public FreeResource ProvideResource(int resourceID)
	{
		if (holder == null)
		{
			return this;
		}
		return null;
	}

	public object GetOwner()
	{
		return this;
	}

	public bool ValidToPickupToStoreElsewhere()
	{
		return true;
	}

	bool IResourceProvider.ConsiderAsPrimary(int resourceID)
	{
		return true;
	}

	public bool ProvidesType(int rID)
	{
		return resourceID == rID;
	}

	public bool Available(int resourceID)
	{
		if (claim == null)
		{
			return Holder == null;
		}
		return false;
	}

	public int MakeClaim(int resourceID, int count, Villager claimer)
	{
		if (claim == null)
		{
			claim = claimer;
			return 1;
		}
		return 0;
	}

	public void ReleaseClaim(int resourceID, Villager claimer)
	{
		claim = null;
	}
}
