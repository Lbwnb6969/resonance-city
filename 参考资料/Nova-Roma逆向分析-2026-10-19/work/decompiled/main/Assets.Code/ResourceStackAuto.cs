using System.Collections.Generic;
using Assets.Interface;
using UnityEngine;

namespace Assets.Code;

internal class ResourceStackAuto : MonoBehaviour, IResourceStorage, IResourceStorageBase
{
	internal float timeCreated;

	public static List<ResourceStackAuto>[] stackGrid;

	public static ArrayExtRef<GraphicalResourceStack> stacks = new ArrayExtRef<GraphicalResourceStack>(10);

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	internal bool timeExpire;

	public bool deleteOnEmpty = true;

	internal GraphicalResourceStack stack;

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
	}

	public int LandMass()
	{
		return World.inst.GetCellDataClamped(transform.position).landMassIdx;
	}

	int IResourceStorageBase.SpaceAvailable(int resourceID)
	{
		return 0;
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		if (resourceID != stack.resourceID)
		{
			return 0;
		}
		return stack.AvailableAmount();
	}

	bool IResourceStorage.AcceptsType(int resourceID)
	{
		return false;
	}

	bool IResourceStorage.StoresTypePublic(int resourceID)
	{
		return resourceID == stack.resourceID;
	}

	int IResourceStorage.MaxStorageFor(int resourceID)
	{
		return 0;
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceAmount)
	{
		return transform.position;
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		stack.Remove(amount.Get(stack.resourceID));
	}

	private void Awake()
	{
		stack = GetComponent<GraphicalResourceStack>();
		stack.owner = this;
	}

	private void OnEnable()
	{
		FreeResourceManager.inst.AddResourceProvider(stack);
		FreeResourceManager.inst.AddResourceStorage(this);
		stacks.Add(stack);
		FreeResourceManager.inst.autoStackInitList.Add(this);
		FreeResourceManager.inst.autoStackUpdateList.Add(this);
		timeCreated = Time.time + SRand.Range(0f, 20f);
	}

	public static void InitGrid()
	{
		stackGrid = new List<ResourceStackAuto>[World.inst.GridWidth * World.inst.GridHeight];
	}

	public static void RefreshVisibilityFor(int x, int z, bool visible)
	{
		int num = z * World.inst.GridWidth + x;
		List<ResourceStackAuto> list = stackGrid[num];
		if (list != null)
		{
			for (int i = 0; i < list.Count; i++)
			{
				list[i].stack.B_visibilityChanged(visible);
			}
		}
	}

	public void Init()
	{
		int num = (int)transform.position.x;
		int num2 = (int)transform.position.z * World.inst.GridWidth + num;
		if (stackGrid[num2] == null)
		{
			stackGrid[num2] = new List<ResourceStackAuto>();
		}
		stackGrid[num2].Add(this);
	}

	public void OnDestroy()
	{
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
	}

	public void Unhook()
	{
		FreeResourceManager.inst.RemoveResourceProvider(stack);
		FreeResourceManager.inst.RemoveResourceStorage(this);
		stacks.Remove(stack);
		FreeResourceManager.inst.autoStackInitList.Remove(this);
		FreeResourceManager.inst.autoStackUpdateList.Remove(this);
		int num = (int)transform.position.x;
		int num2 = (int)transform.position.z;
		stackGrid[num2 * World.inst.GridWidth + num]?.Remove(this);
	}
}
