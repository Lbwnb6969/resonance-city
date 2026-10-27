using System;
using Assets.Code;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Baker : ProductionBuilding, IResourceStorage, IResourceStorageBase, IProductionInfo
{
	[Serializable]
	public class BakerSaveData : SaveClass<Baker, BakerSaveData>
	{
		private int internalCharcoal;

		private int internalWheat;

		private int stackCount;

		public override BakerSaveData Pack(Baker obj)
		{
			internalWheat = obj.resourcesStored.Get(0);
			internalCharcoal = obj.resourcesStored.Get(3);
			stackCount = obj.stack.Count();
			return this;
		}

		public override Baker Unpack(Baker obj)
		{
			obj.resourcesStored.Set(0, internalWheat);
			obj.resourcesStored.Set(3, internalCharcoal);
			obj.stack.Add(stackCount);
			return obj;
		}
	}

	public ParticleSystem fire;

	private bool isVisible = true;

	private EventHandler<OnTechnologyTreeUnlock> unlockEventHandler;

	private bool isAdvancedBakeryUnlocked;

	private void Awake()
	{
		statsID = World.bakerName;
	}

	private void OnDestroy()
	{
		b.visibilityChanged -= OnBuildingVisibilityChanged;
		Broadcast.TechnologyTreeUnlockEvent.Unlisten(unlockEventHandler);
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (b.IsBuilt() && b.IsOpen())
		{
			if (isVisible && fire.isStopped)
			{
				fire.Play();
			}
			else if (!isVisible && fire.isPlaying)
			{
				fire.Stop();
			}
		}
		else if (fire.isPlaying)
		{
			fire.Stop();
		}
	}

	private void OnInit()
	{
		b.visibilityChanged += OnBuildingVisibilityChanged;
	}

	private void OnBuildingVisibilityChanged(bool v)
	{
		if (isVisible != v)
		{
			if (v && fire.isStopped)
			{
				fire.Play();
			}
			else if (!v && fire.isPlaying)
			{
				fire.Stop();
			}
			isVisible = v;
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			if (TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_advancedbakery"))
			{
				isAdvancedBakeryUnlocked = true;
			}
			else
			{
				unlockEventHandler = Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyTreeUnlock);
			}
		}
	}

	private void OnTechnologyTreeUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		if (data.unlockKey == "unlockkey_advancedbakery")
		{
			isAdvancedBakeryUnlocked = true;
			Broadcast.TechnologyTreeUnlockEvent.Unlisten(unlockEventHandler);
		}
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		ResourceStorageHelper.Deposit(resourcesStored, resourceStorageMax, null, ref resources, b.Center());
	}

	int IProductionInfo.GetTotalBonus()
	{
		if (!isAdvancedBakeryUnlocked)
		{
			return 0;
		}
		return 1;
	}

	string IProductionInfo.GetCustomText()
	{
		if (!isAdvancedBakeryUnlocked)
		{
			return null;
		}
		return string.Format(ScriptLocalization.workerui_productionui_customtext_bakerybonus, 1);
	}
}
