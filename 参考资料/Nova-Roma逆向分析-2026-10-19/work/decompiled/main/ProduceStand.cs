using System;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class ProduceStand : MonoBehaviour, IOutputInfo, IResourceStorage, IResourceStorageBase, IResourceProviderContainer
{
	[Serializable]
	public class ProduceStandSaveData : SaveClass<ProduceStand, ProduceStandSaveData>
	{
		private int food;

		public override ProduceStandSaveData Pack(ProduceStand obj)
		{
			food = obj.appleStack.Count();
			return this;
		}

		public override ProduceStand Unpack(ProduceStand obj)
		{
			obj.appleStack.Clear();
			obj.appleStack.Add(food);
			return obj;
		}
	}

	private Building b;

	private YieldProducer yieldProducer;

	public GraphicalResourceStack appleStack;

	public int Storage => appleStack.MaxCapacity();

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	string IOutputInfo.GetError()
	{
		return null;
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		FreeResourceManager.inst.AddResourceProviderChecked(appleStack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(appleStack);
	}

	private float BaseYearly()
	{
		return yieldProducer.Yield;
	}

	public string GetExplanation(OutputTileUI tileOutput)
	{
		if (IsFull())
		{
			return ScriptLocalization.FruitStorageFull;
		}
		return ScriptLocalization.FruitStorage;
	}

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	private void OnInit()
	{
		appleStack.Clear();
		yieldProducer = GetComponent<YieldProducer>();
	}

	private void OnDemolished()
	{
		FreeResourceManager.inst.GetAutoStackFor(9, appleStack.Count(), appleStack.transform.position.xz() + Vector3.up * 0.0246f);
	}

	private void ConfigureJob(FreeResourceGathererJob frg)
	{
		frg.bonusCarryCapacity = 2;
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b));
			}
			ConfigureJob(b.jobs[i] as FreeResourceGathererJob);
		}
	}

	private bool IsFull()
	{
		return appleStack.MaxCapacity() - appleStack.Count() < 1;
	}

	private void OnBuilt()
	{
		Vector3 start = GetComponent<Building>().Center();
		ResourceTextStackManager.inst.ShowText(this, start, string.Format(ScriptLocalization.GranaryAdditionalStorage, Storage), 4f);
	}

	public void Deposit(ref ResourceAmount resources)
	{
		int num = appleStack.Add(resources.Get(9));
		resources.Add(9, -num);
	}

	public int SpaceAvailable(int t)
	{
		if (t == 9)
		{
			return appleStack.MaxCapacity() - appleStack.Count();
		}
		return 0;
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		return appleStack.AvailableAmount();
	}

	int IResourceStorage.MaxStorageFor(int resourceID)
	{
		if (resourceID == 9)
		{
			return appleStack.MaxCapacity();
		}
		return 0;
	}

	public Vector3 DropOffLocation(int resourceID)
	{
		return transform.GetChild(0).Find("resourceDropoff").position;
	}

	public bool AcceptsType(int t)
	{
		return t == 9;
	}

	public bool StoresTypePublic(int t)
	{
		return t == 9;
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		appleStack.Remove(amount.Get(9));
	}

	public void EatHalf()
	{
		appleStack.Remove((int)((float)appleStack.AvailableAmount() * 0.5f));
	}
}
