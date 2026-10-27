using System;
using Assets.Code;
using Assets.Interface;
using UnityEngine;

public class CharcoalMaker : ProductionBuilding, IResourceStorage, IResourceStorageBase, IProductionInfo
{
	[Serializable]
	public class CharcoalMakerSaveData : SaveClass<CharcoalMaker, CharcoalMakerSaveData>
	{
		private int internalWood;

		private int stackCount;

		private int internalTools;

		public override CharcoalMakerSaveData Pack(CharcoalMaker obj)
		{
			internalWood = obj.resourcesStored.Get(1);
			internalTools = obj.resourcesStored.Get(6);
			stackCount = obj.stack.Count();
			return this;
		}

		public override CharcoalMaker Unpack(CharcoalMaker obj)
		{
			obj.resourcesStored.Set(1, internalWood);
			obj.resourcesStored.Set(6, internalTools);
			obj.stack.Add(stackCount);
			return obj;
		}
	}

	public ParticleSystem[] fire;

	public GameObject[] dirtAndWood;

	private bool isVisible = true;

	private void Awake()
	{
		GetComponent<YieldProducer>().OnUsedTool += YieldProducer_OnUsedTool;
		statsID = World.charcoalMakerName;
	}

	private bool YieldProducer_OnUsedTool()
	{
		if (resourcesStored.TrySubtract(6, 1))
		{
			ResourceStatistics.AddConsumption(b.LandMass(), World.charcoalMakerName, 6, 1);
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
			bool flag = resourcesStored.Get(1) > 0;
			for (int i = 0; i < dirtAndWood.Length; i++)
			{
				dirtAndWood[i].gameObject.SetActive(flag);
			}
			for (int j = 0; j < fire.Length; j++)
			{
				if ((isVisible & flag) && b.WorkersAllocated > 0)
				{
					if (fire[j].isStopped)
					{
						fire[j].Play();
					}
				}
				else if (fire[j].isPlaying)
				{
					fire[j].Stop();
				}
			}
			return;
		}
		for (int k = 0; k < fire.Length; k++)
		{
			if (fire[k].isPlaying)
			{
				fire[k].Stop();
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
		for (int i = 0; i < fire.Length; i++)
		{
			if (v && fire[i].isStopped)
			{
				fire[i].Play();
			}
			else if (!v && fire[i].isPlaying)
			{
				fire[i].Stop();
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
