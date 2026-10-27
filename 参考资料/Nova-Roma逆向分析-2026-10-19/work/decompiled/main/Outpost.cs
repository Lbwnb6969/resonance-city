using System;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Interface;
using UnityEngine;

public class Outpost : Tickable, IResourceProviderContainer, IResourceStorage, IResourceStorageBase, IWorkerUIDisplay
{
	[Serializable]
	public class OutpostSaveData : SaveClass<Outpost, OutpostSaveData>
	{
		private int stone;

		private int wood;

		private int food;

		private int apples;

		public override OutpostSaveData Pack(Outpost k)
		{
			stone = k.stoneStack.Count();
			wood = k.woodStack.Count();
			food = k.foodStack.Count();
			apples = k.appleStack.Count();
			return this;
		}

		public override Outpost Unpack(Outpost k)
		{
			k.stoneStack.Clear();
			k.woodStack.Clear();
			k.foodStack.Clear();
			k.appleStack.Clear();
			k.stoneStack.Add(stone);
			k.woodStack.Add(wood);
			k.foodStack.Add(food);
			k.appleStack.Add(apples);
			return k;
		}
	}

	private Building b;

	private GraphicalResourceStack[] stacks = new GraphicalResourceStack[4];

	public GraphicalResourceStack woodStack;

	public GraphicalResourceStack stoneStack;

	public GraphicalResourceStack foodStack;

	public GraphicalResourceStack appleStack;

	public UnitTransportShip seedShip;

	public int placementRadius;

	private void Awake()
	{
		b = GetComponent<Building>();
		stacks[0] = foodStack;
		stacks[1] = woodStack;
		stacks[2] = stoneStack;
		stacks[3] = appleStack;
		b.PlacementValidaton = PlacementValidation;
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		PlacementValidationResult result = PlacementValidationResult.Valid;
		if (seedShip != null)
		{
			b.ForEachTileInBounds((int x, int z, Cell cell) =>
			{
				int num = placementRadius * placementRadius;
				Vector3 pos = seedShip.GetPos();
				if (((float)cell.x + 0.5f - pos.x) * ((float)cell.x + 0.5f - pos.x) + ((float)cell.z + 0.5f - pos.z) * ((float)cell.z + 0.5f - pos.z) > (float)num)
				{
					result = PlacementValidationResult.OutpostTooFarFromSeedShip;
				}
				if ((cell.landMassIdx != -1 && Player.inst.GetBuildingListForLandMass(cell.landMassIdx, World.romanOutpostHash).Count > 0) || Player.inst.GetBuildingListForLandMass(cell.landMassIdx, World.romanOutpostHashNewIsland).Count > 0)
				{
					result = PlacementValidationResult.OneOutpostPerLandmass;
				}
			});
		}
		if (result != PlacementValidationResult.Valid)
		{
			validationResult = result;
		}
	}

	public override void Tick(float dt, int currFrame)
	{
	}

	private void OnBuilt()
	{
	}

	private void OnPlayerPlacement()
	{
		if (seedShip != null)
		{
			b.ForEachTileInBounds((int x, int z, Cell c) =>
			{
				EffectsMan.inst.BuildPuff.CreateAndPlay(c.Center3D);
			});
			b.ConstructionForeman.AddBuildResource(b.GetCost(b.LandMass()));
			Player.inst.PlayerLandmassOwner.TakeOwnership(LandMass());
			Player.inst.RefreshVisibilityFor(LandMass(), force: true);
			seedShip.Settle(b);
			MilestoneManager.inst.TryFirstOccupyNewIsland();
			GameUI.inst.CurrPlacementMode.CancelWaitToPlace();
			GameUI.inst.SetSelectedBuildingNew(b);
			seedShip = null;
		}
	}

	public bool AcceptsType(int t)
	{
		if (t != 0 && t != 2)
		{
			return t == 1;
		}
		return true;
	}

	public bool StoresTypePublic(int t)
	{
		return AcceptsType(t);
	}

	public void Deposit(ref ResourceAmount resources)
	{
		int num = 0;
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i] != null && resources.Get(stacks[i].resourceID) > 0)
			{
				num = stacks[i].Add(resources.Get(stacks[i].resourceID));
				resources.Add(stacks[i].resourceID, -num);
			}
		}
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i] != null)
			{
				stacks[i].Remove(amount.Get(stacks[i].resourceID));
			}
		}
	}

	int IResourceStorage.MaxStorageFor(int t)
	{
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i].resourceID == t)
			{
				return stacks[i].MaxCapacity();
			}
		}
		return 0;
	}

	public int SpaceAvailable(int t)
	{
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i].resourceID == t)
			{
				return stacks[i].MaxCapacity() - stacks[i].Count();
			}
		}
		return 0;
	}

	int IResourceStorage.StoredPublicResources(int t)
	{
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i].resourceID == t)
			{
				return stacks[i].AvailableAmount();
			}
		}
		return 0;
	}

	public Vector3 DropOffLocation(int t)
	{
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i].resourceID == t)
			{
				return stacks[i].ResourcePosition(t);
			}
		}
		return b.Center();
	}

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		FreeResourceManager.inst.AddResourceProviderChecked(stoneStack);
		FreeResourceManager.inst.AddResourceProviderChecked(woodStack);
		FreeResourceManager.inst.AddResourceProviderChecked(appleStack);
		FreeResourceManager.inst.AddResourceProviderChecked(foodStack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(stoneStack);
		FreeResourceManager.inst.RemoveResourceProvider(woodStack);
		FreeResourceManager.inst.RemoveResourceProvider(appleStack);
		FreeResourceManager.inst.RemoveResourceProvider(foodStack);
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}
}
