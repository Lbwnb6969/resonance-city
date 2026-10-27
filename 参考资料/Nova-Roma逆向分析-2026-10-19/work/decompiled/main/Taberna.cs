using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Taberna : Tickable, IOutputInfo, IWorkerUIDisplay, IResourceStorage, IResourceStorageBase, IResourceProvider
{
	[Serializable]
	public struct StackOption
	{
		public GraphicalResourceStack stack;

		public Mesh mesh;
	}

	[Serializable]
	public class TabernaSaveData : SaveClass<Taberna, TabernaSaveData>
	{
		private int resourceID;

		private int count;

		public override TabernaSaveData Pack(Taberna obj)
		{
			resourceID = obj.resourceID;
			count = obj.stack.Count();
			return this;
		}

		public override Taberna Unpack(Taberna obj)
		{
			for (int i = 0; i < obj.stackOptions.Count; i++)
			{
				if (obj.stackOptions[i].stack.resourceID == resourceID)
				{
					obj.stack = obj.stackOptions[i].stack;
					obj.resourceID = resourceID;
					obj.meshFilter.mesh = obj.stackOptions[i].mesh;
					obj.stack.gameObject.SetActive(value: true);
					obj.stack.Set(count);
					return obj;
				}
			}
			return obj;
		}
	}

	[FreeResourceType]
	public int resourceID;

	public static int[] ValidResourceTypes = new int[8] { 0, 9, 12, 11, 8, 10, 13, 3 };

	public List<StackOption> stackOptions = new List<StackOption>();

	private GraphicalResourceStack stack;

	[SerializeField]
	private MeshFilter meshFilter;

	[SerializeField]
	private Transform dropOffLocation;

	private Building b;

	private void Awake()
	{
		b = GetComponent<Building>();
		stack = stackOptions[0].stack;
		meshFilter.mesh = stackOptions[0].mesh;
		resourceID = stack.resourceID;
	}

	private void OnDemolished()
	{
		FreeResourceManager.inst.GetAutoStackFor(resourceID, stack.Count(), dropOffLocation.position);
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b));
			}
			FreeResourceGathererJob obj = b.jobs[i] as FreeResourceGathererJob;
			obj.filterPrimary = JobFilterPrimary;
			obj.filterAlternate = JobFilterAlternate;
			obj.bonusCarryCapacity = 2;
		}
	}

	private bool JobFilterPrimary(IResourceProvider x, int type)
	{
		if (JobFilterAlternate(x, type))
		{
			return type == resourceID;
		}
		return false;
	}

	private bool JobFilterAlternate(IResourceProvider x, int type)
	{
		Type type2 = x.GetType();
		if (type2 != typeof(Home) && type2 != typeof(Market) && type2 != typeof(Baker))
		{
			return type2 != typeof(Taberna);
		}
		return false;
	}

	public void OnResourceChanged(int newResourceID)
	{
		if (resourceID == newResourceID)
		{
			return;
		}
		bool flag = false;
		StackOption stackOption = default;
		for (int i = 0; i < stackOptions.Count; i++)
		{
			if (stackOptions[i].stack.resourceID == newResourceID)
			{
				stackOption = stackOptions[i];
				flag = true;
			}
			else
			{
				stackOptions[i].stack.gameObject.SetActive(value: false);
			}
		}
		if (flag)
		{
			FreeResourceManager.inst.GetAutoStackFor(resourceID, stack.Count(), dropOffLocation.position);
			stack.Clear();
			FreeResourceManager.inst.RemoveResourceProvider(this);
			stack = stackOption.stack;
			stack.gameObject.SetActive(value: true);
			if (stackOption.mesh != null)
			{
				meshFilter.mesh = stackOption.mesh;
			}
			resourceID = stackOption.stack.resourceID;
			FreeResourceManager.inst.AddResourceProvider(this);
		}
	}

	public string GetTitle()
	{
		return ScriptLocalization.MarketTitle;
	}

	public string GetExplanation(OutputTileUI outputTile)
	{
		return $"{ResourceAmount.ResourceIcon(resourceID)}: {stack.Count()} / {stack.MaxCapacity()} ";
	}

	public string GetError()
	{
		return "";
	}

	public bool ShowCustomButton()
	{
		return false;
	}

	public bool CustomButtonInteractable()
	{
		return false;
	}

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public string CustomButtonTitle()
	{
		return "";
	}

	public string CustomButtonText()
	{
		return "";
	}

	public Sprite CustomButtonImage()
	{
		return null;
	}

	public void CustomButtonClicked()
	{
	}

	public int MaxStorageFor(int resourceID)
	{
		if (this.resourceID != resourceID)
		{
			return 0;
		}
		return stack.MaxCapacity();
	}

	public int StoredPublicResources(int resourceID)
	{
		if (this.resourceID != resourceID)
		{
			return 0;
		}
		return stack.AvailableAmount();
	}

	public bool AcceptsType(int resourceID)
	{
		return this.resourceID == resourceID;
	}

	public bool StoresTypePublic(int resourceID)
	{
		return this.resourceID == resourceID;
	}

	public void RemoveResources(ResourceAmount amount)
	{
		stack.Remove(amount.Get(resourceID));
	}

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	public object GetOwner()
	{
		return b;
	}

	public Vector3 ResourcePosition(int resourceID1)
	{
		return dropOffLocation.position;
	}

	public Vector3 CachingCenter()
	{
		return dropOffLocation.position;
	}

	public bool Available(int resourceID)
	{
		if (this.resourceID != resourceID)
		{
			return false;
		}
		return stack.Available(resourceID);
	}

	public bool ValidToPickupToStoreElsewhere()
	{
		return false;
	}

	public FreeResource ProvideResource(int resourceID)
	{
		return stack.ProvideResource(resourceID);
	}

	public bool ProvidesType(int resourceID)
	{
		return stack.ProvidesType(resourceID);
	}

	public bool ConsiderAsPrimary(int resourceID)
	{
		return ((IResourceProvider)stack).ConsiderAsPrimary(resourceID);
	}

	public int MakeClaim(int resourceID, int count, Villager claimer)
	{
		return stack.MakeClaim(resourceID, count, claimer);
	}

	public void ReleaseClaim(int resourceID, Villager claimer)
	{
		stack.ReleaseClaim(resourceID, claimer);
	}

	public void Deposit(ref ResourceAmount resources)
	{
		int num = stack.Add(resources.Get(resourceID));
		resources.Add(resourceID, -num);
	}

	public int SpaceAvailable(int resourceID)
	{
		if (this.resourceID != resourceID)
		{
			return 0;
		}
		return stack.MaxCapacity() - stack.Count();
	}

	public Vector3 DropOffLocation(int resourceID)
	{
		return dropOffLocation.position;
	}
}
