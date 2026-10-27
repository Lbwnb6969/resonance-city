using System;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using UnityEngine;

public class Market : Tickable, IResourceProviderContainer, IResourceStorage, IResourceStorageBase, IOutputInfo, IStorageInfo, IWorkerUIDisplay
{
	[Serializable]
	public class MarketSaveData : SaveClass<Market, MarketSaveData>
	{
		private int stackCount;

		public override MarketSaveData Pack(Market obj)
		{
			stackCount = obj.stack.Count();
			return this;
		}

		public override Market Unpack(Market obj)
		{
			obj.stack.Add(stackCount);
			return obj;
		}
	}

	public static int[] ValidResourceTypes = new int[11]
	{
		0, 11, 12, 13, 3, 8, 10, 16, 9, 18,
		19
	};

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	public GraphicalResourceStack stack;

	private Building b;

	private static Cell[] scratchNeighbors = new Cell[4];

	private void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
		stack.owner = this;
	}

	private void PlacementValidation(ref PlacementValidationResult result)
	{
		if (result != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		bool isValid = true;
		b.ForEachTileInBounds((int x, int z, Cell c) =>
		{
			for (int i = 0; i < c.OccupyingStructure.Count; i++)
			{
				int uniqueNameHash = c.OccupyingStructure[i].uniqueNameHash;
				if (uniqueNameHash != World.roadHash && uniqueNameHash != World.stoneRoadHash)
				{
					isValid = false;
				}
			}
		});
		if (isValid)
		{
			result = PlacementValidationResult.Valid;
		}
	}

	private static bool IsRoad(Cell c)
	{
		int num = ((c != null && (bool)c.BottomStructure) ? c.BottomStructure.uniqueNameHash : 0);
		if (num != World.roadHash)
		{
			return num == World.stoneRoadHash;
		}
		return true;
	}

	public void AlignWithRoad()
	{
		Cell cell = b.GetCell();
		if (!IsRoad(cell))
		{
			return;
		}
		World.inst.GetNeighborCells(cell, ref scratchNeighbors);
		bool flag = IsRoad(scratchNeighbors[0]) || IsRoad(scratchNeighbors[2]);
		bool flag2 = IsRoad(scratchNeighbors[1]) || IsRoad(scratchNeighbors[3]);
		if (flag != flag2)
		{
			Transform child = transform.GetChild(0);
			if (Mathf.Abs(child.right.x) > 0.5f != flag)
			{
				child.Rotate(0f, 90f, 0f, Space.World);
			}
		}
	}

	private void OnDestroy()
	{
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
	}

	private void OnInit()
	{
		cullingGroup = new CullingGroup();
		cullingGroup.onStateChanged = stack.StateChangedMethod;
		cullingGroup.SetBoundingSpheres(spheres);
		cullingGroup.SetBoundingSphereCount(1);
		cullingGroup.targetCamera = Cam.inst.cam;
	}

	private void OnBuilt()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	private void OnFinishedLoad()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	private void OnDemolished()
	{
		if (stack.Count() > 0)
		{
			FreeResourceManager.inst.GetAutoStackFor(stack.resourceID, stack.Count(), b.GetCell().Position);
		}
	}

	private void OnAddJobs()
	{
		for (int i = 0; i < 2; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b));
			}
			InitGatherJob(b.jobs[i] as FreeResourceGathererJob);
		}
	}

	private bool PrimaryFilter(IResourceProvider x, int type)
	{
		return !(x.GetOwner() is Market);
	}

	private void InitGatherJob(FreeResourceGathererJob j)
	{
		j.searchUpdate.SetFrameSpread(30);
		j.meshType = VillagerSystem.MeshType.HandCart;
		j.bonusCarryCapacity = 3;
		j.searchRadius = 30f;
		j.Configure(stack.resourceID, PrimaryFilter);
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		int num = resources.Get(stack.resourceID);
		if (num <= 0)
		{
			return;
		}
		resources.Set(stack.resourceID, 0);
		int num2 = Mathff.Max(0, stack.MaxCapacity() - stack.Count());
		if (num > num2)
		{
			FreeResourceManager.inst.AddOrMakeAutoStackFor(stack.resourceID, num - num2, b.Center());
			if (num2 == 0)
			{
				return;
			}
		}
		stack.Add(Mathff.Min(num2, num));
	}

	int IResourceStorageBase.SpaceAvailable(int resourceID)
	{
		return stack.MaxCapacity() - stack.Count();
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	int IResourceStorage.MaxStorageFor(int resourceID)
	{
		return stack.MaxCapacity();
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		return stack.AvailableAmount();
	}

	bool IResourceStorage.AcceptsType(int resourceID)
	{
		return false;
	}

	bool IResourceStorage.StoresTypePublic(int resourceID)
	{
		return stack.resourceID == resourceID;
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		stack.Remove(amount.Get(stack.resourceID));
	}

	int IResourceStorage.LandMass()
	{
		return b.LandMass();
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		FreeResourceManager.inst.AddResourceProviderChecked(stack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(stack);
	}

	bool IStorageInfo.DoesStoreResource(int r)
	{
		if (b == null)
		{
			b = GetComponent<Building>();
		}
		if (b.UniqueName == World.smallMarketName)
		{
			for (int i = 0; i < ValidResourceTypes.Length; i++)
			{
				if (r == ValidResourceTypes[i])
				{
					return true;
				}
			}
			return false;
		}
		return stack.resourceID == r;
	}

	string IOutputInfo.GetError()
	{
		return null;
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
