using System;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Granary : Tickable, IOutputInfo, IResourceStorage, IResourceStorageBase, IResourceProviderContainer
{
	private enum OverflowState
	{
		ScalingIn,
		ScalingOut,
		Idle
	}

	[Serializable]
	public class GranarySaveData : SaveClass<Granary, GranarySaveData>
	{
		private int food;

		public override GranarySaveData Pack(Granary obj)
		{
			food = obj.wheatStack.Count();
			return this;
		}

		public override Granary Unpack(Granary obj)
		{
			obj.wheatStack.Clear();
			obj.wheatStack.Add(food);
			return obj;
		}
	}

	private Building b;

	public GraphicalResourceStack wheatStack;

	private OverflowState overflowState = OverflowState.Idle;

	private Vector3 overflowScale = Vector3.zero;

	private float selectedTime;

	private float prevSelectedTime = -1f;

	public Transform granaryTop;

	public float topYFrom = 1.058323f;

	public float topYTo = 0.3f;

	public Transform fullContainer;

	public Vector3 resourceDropOff;

	public int Storage => wheatStack.MaxCapacity();

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	string IOutputInfo.GetError()
	{
		return null;
	}

	public string GetExplanation(OutputTileUI tileOutput)
	{
		if (IsFull())
		{
			return ScriptLocalization.GranaryIsFull;
		}
		return "ScriptLocalization.GranaryIsSafe";
	}

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	private void OnInit()
	{
		wheatStack.Clear();
		resourceDropOff = transform.GetChild(0).Find("resourceDropoff").position;
	}

	private void OnDemolished()
	{
		FreeResourceManager.inst.GetAutoStackFor(0, wheatStack.Count(), wheatStack.transform.position.xz() + Vector3.up * 0.0246f);
	}

	private void ConfigureJob(FreeResourceGathererJob frg)
	{
		frg.bonusCarryCapacity = 2;
		frg.consumer = false;
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
		return wheatStack.MaxCapacity() - wheatStack.Count() < 1;
	}

	public override void Tick(float dt, int currFrame)
	{
		switch (overflowState)
		{
		case OverflowState.ScalingIn:
			overflowScale.x = (overflowScale.z = (overflowScale.y += dt * 2f));
			if (overflowScale.y >= 1f)
			{
				overflowState = OverflowState.Idle;
				overflowScale = Vector3.one;
			}
			fullContainer.localScale = overflowScale;
			break;
		case OverflowState.ScalingOut:
			overflowScale.x = (overflowScale.z = (overflowScale.y -= dt * 2f));
			if (overflowScale.y <= 0f)
			{
				overflowState = OverflowState.Idle;
				overflowScale = Vector3.zero;
			}
			fullContainer.localScale = overflowScale;
			break;
		case OverflowState.Idle:
			if (IsFull() && b.IsVisibleForFog())
			{
				if (overflowScale.y < 1f)
				{
					overflowState = OverflowState.ScalingIn;
				}
			}
			else if (overflowScale.y > 0f)
			{
				if (!b.IsVisibleForFog())
				{
					overflowScale = Vector3.zero;
				}
				overflowState = OverflowState.ScalingOut;
			}
			break;
		}
		if (b.IsBuilt())
		{
			Cell cellSelected = GameUI.inst.GetCellSelected();
			if (cellSelected != null && b != null && cellSelected == b.GetCell() && b.IsBuilt())
			{
				selectedTime += dt * 5f;
			}
			else
			{
				selectedTime -= dt * 5f;
			}
			if (selectedTime > 1f)
			{
				selectedTime = 1f;
			}
			else if (selectedTime < 0f)
			{
				selectedTime = 0f;
			}
			if (selectedTime != prevSelectedTime)
			{
				granaryTop.localRotation = Quaternion.Euler(Mathf.SmoothStep(0f, -100f, selectedTime), 0f, 0f);
				Vector3 localPosition = granaryTop.localPosition;
				localPosition.y = Mathf.SmoothStep(topYFrom, topYTo, selectedTime);
				granaryTop.localPosition = localPosition;
			}
			prevSelectedTime = selectedTime;
		}
	}

	public void OnBuildingPlacement(bool undo)
	{
		granaryTop.gameObject.SetActive(b.IsBuilt());
		resourceDropOff = transform.GetChild(0).Find("resourceDropoff").position;
	}

	private void OnBuilt()
	{
		Vector3 start = GetComponent<Building>().Center();
		ResourceTextStackManager.inst.ShowText(this, start, string.Format(ScriptLocalization.GranaryAdditionalStorage, Storage), 4f);
		granaryTop.gameObject.SetActive(value: true);
	}

	private void OnFinishedLoad()
	{
		granaryTop.gameObject.SetActive(b.IsBuilt());
	}

	public void Deposit(ref ResourceAmount resources)
	{
		int num = wheatStack.Add(resources.Get(0));
		resources.Add(0, -num);
	}

	public int SpaceAvailable(int resourceID)
	{
		if (resourceID == 0)
		{
			return wheatStack.MaxCapacity() - wheatStack.Count();
		}
		return 0;
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		return wheatStack.AvailableAmount();
	}

	int IResourceStorage.MaxStorageFor(int resourceID)
	{
		if (resourceID == 0)
		{
			return wheatStack.MaxCapacity();
		}
		return 0;
	}

	public Vector3 DropOffLocation(int resourceID)
	{
		return resourceDropOff;
	}

	public bool AcceptsType(int t)
	{
		return t == 0;
	}

	public bool StoresTypePublic(int t)
	{
		return t == 0;
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		wheatStack.Remove(amount.Get(0));
	}

	public void EatHalf()
	{
		wheatStack.Remove((int)((float)wheatStack.AvailableAmount() * 0.5f));
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		wheatStack.owner = b;
		wheatStack.validToPickupToStoreElsewhere = false;
		FreeResourceManager.inst.AddResourceProviderChecked(wheatStack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(wheatStack);
	}
}
