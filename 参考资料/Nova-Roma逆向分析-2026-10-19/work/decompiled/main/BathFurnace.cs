using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class BathFurnace : MonoBehaviour, IResourceStorage, IResourceStorageBase, IProductionInfo, IOutputInfo
{
	[Serializable]
	public class BathFurnaceSaveData : SaveClass<BathFurnace, BathFurnaceSaveData>
	{
		private int internalCharcoal;

		private float currTime;

		private float timeWithoutPreqs;

		private bool hasHeat;

		public override BathFurnaceSaveData Pack(BathFurnace obj)
		{
			internalCharcoal = obj.storage.Get(3);
			currTime = obj.currTime;
			timeWithoutPreqs = obj.timeWithoutPreqs;
			hasHeat = obj.hasHeat;
			return this;
		}

		public override BathFurnace Unpack(BathFurnace obj)
		{
			obj.storage.Set(3, internalCharcoal);
			obj.currTime = currTime;
			obj.timeWithoutPreqs = timeWithoutPreqs;
			obj.SetHeat(hasHeat);
			return obj;
		}
	}

	public Building b;

	public ParticleSystem fireFX;

	public Sprite fireIcon;

	public const int MAX_HEAT = 9;

	private int heatRemaining = 9;

	[NonSerialized]
	public ResourceAmount storage = new ResourceAmount();

	public ResourceAmount maxStorage;

	private const int AMOUNT_PER_CONSUME = 4;

	private const int CONSUMER_PER_YEAR = 2;

	private float currTime;

	private float maxTime;

	private float timeWithoutPreqs;

	private const float MAX_TIME_WITHOUT_PREQS = 50f;

	private bool hasHeat;

	private EventHandler<OnBuildingOpenClose> onOpenCloseEventHandler;

	private ThoughtBubbleSystem.ThoughtBubble thought;

	private BuildingProductionUI.CustomProductionItem[] customProductionItem = new BuildingProductionUI.CustomProductionItem[1];

	public Dictionary<BathManager.BathGroup.PoolGroup, int> consumers = new Dictionary<BathManager.BathGroup.PoolGroup, int>(4);

	private static ArrayExt<BathManager.BathGroup.PoolGroup> tempPoolGroups = new ArrayExt<BathManager.BathGroup.PoolGroup>(4);

	public ResourceAmount pCost = new ResourceAmount();

	public bool HasHeat()
	{
		return hasHeat;
	}

	public void SetHeat(bool val)
	{
		if (hasHeat != val)
		{
			Cell cell = b.GetCell();
			BathManager.inst.bathCells[cell.index].bGroup.isDirty = true;
		}
		Util.SetParticleEffects(fireFX, val);
		hasHeat = val;
	}

	public int GetRemainingHeat()
	{
		return heatRemaining;
	}

	public bool TryClaimHeat(BathManager.BathGroup.PoolGroup pGroup, int amt)
	{
		if (amt > heatRemaining)
		{
			return false;
		}
		heatRemaining -= amt;
		consumers.Add(pGroup, amt);
		return true;
	}

	public void Reset()
	{
		consumers.Clear();
		heatRemaining = 9;
	}

	public void CheckHeatProviding()
	{
		thought.visible = consumers.Count == 0;
	}

	public int GetNeighborPoolGroupCount()
	{
		tempPoolGroups.ClearFast();
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		minX = Mathff.Clamp(minX - 1, 0, gridWidth - 1);
		maxX = Mathff.Clamp(maxX + 1, 0, gridWidth - 1);
		minZ = Mathff.Clamp(minZ - 1, 0, gridHeight - 1);
		maxZ = Mathff.Clamp(maxZ + 1, 0, gridHeight - 1);
		int num = 0;
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				if ((i != minX || j != minZ) && (i != maxX || j != minZ) && (i != maxX || j != maxZ) && (i != minX || j != maxZ) && (j == minZ || j == maxZ || i == minX || i == maxX))
				{
					int num2 = i + j * gridWidth;
					BathManager.BathCell bathCell = BathManager.inst.bathCells[num2];
					if (bathCell.pGroup != null && !tempPoolGroups.Contains(bathCell.pGroup))
					{
						tempPoolGroups.Add(bathCell.pGroup);
						num++;
					}
				}
			}
		}
		return num;
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		currTime = 0f;
		maxTime = SeasonManager.inst.TimeInYear() / 2f;
		timeWithoutPreqs = 0f;
		onOpenCloseEventHandler = Broadcast.BuildingOpenClose.Listen(World.bathFurnaceHash, OnBuildingOpenClose);
		thought = ThoughtBubbleSystem.inst.AddThoughtBubble(b.Center());
		thought.SetThought(ThoughtBubbleSystem.Thought.GeneralError, ThoughtBubbleSystem.ThoughtCategory.Water);
		thought.offset = new Vector3(0f, 1f, 0f);
		thought.visible = false;
		customProductionItem[0] = new BuildingProductionUI.CustomProductionItem
		{
			maxStorage = 9,
			icon = fireIcon,
			locTerm = "custom_production_produce_bathfurnace",
			hideConsumption = true
		};
	}

	private void OnDestroy()
	{
		if (onOpenCloseEventHandler != null)
		{
			Broadcast.BuildingOpenClose.UnlistenAny(onOpenCloseEventHandler);
		}
		if (thought != null)
		{
			ThoughtBubbleSystem.inst.RemoveThoughtBubble(ref thought);
		}
	}

	private void OnBuildingOpenClose(object sender, OnBuildingOpenClose args)
	{
		if (args.targetBuilding == b)
		{
			if (!args.open)
			{
				SetHeat(val: false);
			}
			else if (timeWithoutPreqs <= 0f)
			{
				SetHeat(val: true);
			}
		}
	}

	public void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			thought.pos = b.Center();
			BathManager.inst.Register(b);
			currTime = maxTime;
			timeWithoutPreqs = 0f;
		}
		else
		{
			BathManager.inst.Deregister(b);
		}
	}

	private void Update()
	{
		if (!b.IsOpen() || !b.IsBuilt())
		{
			thought.visible = false;
			return;
		}
		float deltaTime = Time.deltaTime;
		if (heatRemaining != 9)
		{
			currTime += deltaTime * (1f - (float)heatRemaining / 9f);
		}
		if (currTime >= maxTime)
		{
			if (storage.Get(3) >= 4)
			{
				currTime = 0f;
				timeWithoutPreqs = 0f;
				storage.Add(3, -4);
				SetHeat(val: true);
				thought.visible = false;
			}
			else
			{
				timeWithoutPreqs += deltaTime;
			}
		}
		if (timeWithoutPreqs >= 50f)
		{
			SetHeat(val: false);
			thought.visible = true;
		}
		if (hasHeat && consumers.Count == 0)
		{
			Cell cell = b.GetCell();
			for (int i = -1; i <= 1; i++)
			{
				for (int j = -1; j <= 1; j++)
				{
					if ((j == 0 || i == 0) && (i != 0 || j != 0))
					{
						int num = cell.x + i + (j + cell.z) * World.inst.GridWidth;
						BathManager.BathCell bathCell = BathManager.inst.bathCells[num];
						if (bathCell.pGroup != null && !bathCell.pGroup.isHeated)
						{
							thought.visible = true;
							return;
						}
					}
				}
			}
		}
		else if (timeWithoutPreqs < 50f)
		{
			thought.visible = false;
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b, _consumeOnPickup: true));
			}
			InitGatherJob(b.jobs[i] as FreeResourceGathererJob);
		}
	}

	private void InitGatherJob(FreeResourceGathererJob job)
	{
		job.Configure(3, null);
		job.searchUpdate.SetFrameSpread(45);
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		int num = resources.Get(3);
		if (num <= 0)
		{
			return;
		}
		resources.Set(3, 0);
		int num2 = Mathff.Max(0, maxStorage.Get(3) - storage.Get(3));
		if (num > num2)
		{
			FreeResourceManager.inst.AddOrMakeAutoStackFor(3, num - num2, b.Center());
			if (num2 == 0)
			{
				return;
			}
		}
		storage.Add(3, Mathff.Min(num2, num));
	}

	int IResourceStorageBase.SpaceAvailable(int resourceID)
	{
		if (resourceID == 3)
		{
			return Mathff.Max(0, maxStorage.Get(3) - storage.Get(3));
		}
		return 0;
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	int IResourceStorage.MaxStorageFor(int resourceID)
	{
		if (resourceID == 3)
		{
			return maxStorage.Get(3);
		}
		return 0;
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		return 0;
	}

	bool IResourceStorage.AcceptsType(int resourceID)
	{
		return resourceID == 3;
	}

	bool IResourceStorage.StoresTypePublic(int resourceID)
	{
		return false;
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		storage.Subtract(in amount);
	}

	int IResourceStorage.LandMass()
	{
		return b.LandMass();
	}

	ResourceAmount IProductionInfo.GetCost()
	{
		pCost.Set(3, 4);
		return pCost;
	}

	int IProductionInfo.GetResult(int rID)
	{
		return 0;
	}

	bool IProductionInfo.ShowResultStorage()
	{
		return true;
	}

	int IProductionInfo.GetInputStorage(int rID)
	{
		if (rID != 3)
		{
			return 0;
		}
		return storage.Get(3);
	}

	public int GetInputMaxStorage(int rID)
	{
		return maxStorage.Get(rID);
	}

	public int GetOutputStorage(int rID)
	{
		return 0;
	}

	public int GetOutputMaxStorage(int rID)
	{
		return 0;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomCost()
	{
		return null;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomResult()
	{
		customProductionItem[0].currentStorage = (hasHeat ? heatRemaining : 0);
		return customProductionItem;
	}

	float IProductionInfo.GetProgress()
	{
		return Mathff.Clamp01(currTime / maxTime);
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		return string.Empty;
	}

	string IOutputInfo.GetError()
	{
		if (!thought.visible)
		{
			return string.Empty;
		}
		if (timeWithoutPreqs >= 50f)
		{
			return ScriptLocalization.workerui_bathui_furnace_nocharcoal_error;
		}
		return ScriptLocalization.workerui_bathui_furnace_notenoughheat_error;
	}
}
