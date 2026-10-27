using System;
using Assets.Code;
using Assets.Interface;
using UnityEngine;

public class Blacksmith : ProductionBuilding, IResourceStorage, IResourceStorageBase, IProductionInfo
{
	[Serializable]
	public class BlacksmithSaveData : SaveClass<Blacksmith, BlacksmithSaveData>
	{
		private int internalCharcoal;

		private int internalIron;

		private int stackCount;

		private int internalTools;

		public override BlacksmithSaveData Pack(Blacksmith obj)
		{
			internalCharcoal = obj.resourcesStored.Get(3);
			internalIron = obj.resourcesStored.Get(5);
			internalTools = obj.resourcesStored.Get(6);
			stackCount = obj.stack.Count();
			return this;
		}

		public override Blacksmith Unpack(Blacksmith obj)
		{
			obj.resourcesStored.Set(3, internalCharcoal);
			obj.resourcesStored.Set(5, internalIron);
			obj.resourcesStored.Set(6, internalTools);
			obj.stack.Add(stackCount);
			return obj;
		}
	}

	[SerializeField]
	private ParticleSystem[] firePS;

	private bool isVisible = true;

	private void Awake()
	{
		GetComponent<YieldProducer>().OnUsedTool += YieldProducer_OnUsedTool;
	}

	private bool YieldProducer_OnUsedTool()
	{
		if (resourcesStored.TrySubtract(6, 1))
		{
			ResourceStatistics.AddConsumption(b.LandMass(), b.UniqueName, 6, 1);
			return true;
		}
		return false;
	}

	private void OnDestroy()
	{
		b.visibilityChanged -= OnBuildingVisibilityChanged;
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (b.IsBuilt() && b.IsOpen())
		{
			for (int i = 0; i < firePS.Length; i++)
			{
				if (isVisible && firePS[i].isStopped)
				{
					firePS[i].Play();
				}
				else if (!isVisible && firePS[i].isPlaying)
				{
					firePS[i].Stop();
				}
			}
			return;
		}
		for (int j = 0; j < firePS.Length; j++)
		{
			if (firePS[j].isPlaying)
			{
				firePS[j].Stop();
			}
		}
	}

	private void OnInit()
	{
		b.visibilityChanged += OnBuildingVisibilityChanged;
	}

	private void OnBuildingVisibilityChanged(bool v)
	{
		if (isVisible == v)
		{
			return;
		}
		for (int i = 0; i < firePS.Length; i++)
		{
			if (v && firePS[i].isStopped)
			{
				firePS[i].Play();
			}
			else if (!v && firePS[i].isPlaying)
			{
				firePS[i].Stop();
			}
		}
		isVisible = v;
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		ResourceStorageHelper.Deposit(resourcesStored, resourceStorageMax, yieldProducer, ref resources, b.Center());
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		return null;
	}
}
