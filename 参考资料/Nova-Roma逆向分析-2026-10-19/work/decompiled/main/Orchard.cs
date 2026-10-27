using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Jobs;
using I2.Loc;
using UnityEngine;

public class Orchard : ExtractionBuilding
{
	[Serializable]
	public class OrchardSaveData : SaveClass<Orchard, OrchardSaveData>
	{
		public float lifeTime;

		public int apples;

		public override OrchardSaveData Pack(Orchard obj)
		{
			lifeTime = obj.lifeTime;
			apples = obj.stack.Count();
			return this;
		}

		public override Orchard Unpack(Orchard obj)
		{
			obj.lifeTime = lifeTime;
			obj.UpdateTreeScale();
			obj.stack.Clear();
			obj.stack.Add(apples);
			return obj;
		}
	}

	public ResourceAmount yieldResult = new ResourceAmount();

	public Mesh fruitMesh;

	public Material fruitMaterial;

	public Transform treeContainer;

	private OrchardFruit[] treeInstances;

	private bool addedInstances;

	private Matrix4x4 scratch;

	public GameObject treePrefab;

	public float fruitScale;

	public int YearsToMature;

	private float matureTime = 1f;

	private float lifeTime;

	public int bonusPerFertileScore = 1;

	private int irrigationBonus;

	public int fertilityBonus;

	private int barrenCells;

	private float currRefreshBonusTime = -1f;

	private float refreshBonusTime = 1f;

	private int currentSeason = -1;

	private EventHandler<SeasonEventData> onSeasonEvent;

	private const int frameSpread = 4;

	private int updateFrame = SRand.srand.Next(0, 4);

	private int skillBonus;

	public YieldProducerSeason yieldProducer;

	private AdjacentMesh adjacentMesh;

	private List<FieldSystem.Owner> owners = new List<FieldSystem.Owner>();

	private FieldSystem fruitSystem;

	private bool IsOrchardMature()
	{
		return lifeTime >= matureTime;
	}

	protected override void Awake()
	{
		base.Awake();
		yieldProducer = GetComponent<YieldProducerSeason>();
		adjacentMesh = GetComponent<AdjacentMesh>();
		fruitSystem = Player.inst.GetFruitSystem(fruitMesh, fruitMaterial);
		fruitSystem.chunkSize = 24;
		fruitSystem.type = 1;
		fruitSystem.scaleMod = Vector3.one;
		yieldProducer.OnYieldResources += OnYieldResources;
		adjacentMesh.shouldConnect = ShouldConnect;
	}

	private void OnDestroy()
	{
		RemoveInstances();
		Player.inst.irrigation.OnReservoirIrrigationUpdated -= Irrigation_OnIrrigationUpdated;
		Broadcast.SeasonEvent.Unlisten(onSeasonEvent);
	}

	protected override void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		Cell cell = b.GetCell();
		if (cell.GetEffectiveFertility() <= 0)
		{
			validationResult = PlacementValidationResult.MustBeOnFertileLand;
		}
		if (cell.Type != TerrainType.None)
		{
			validationResult = PlacementValidationResult.MustBeOnFlatLand;
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (!b.IsBuilt())
		{
			return;
		}
		if (currRefreshBonusTime != -1f)
		{
			currRefreshBonusTime += dt;
			if (currRefreshBonusTime > refreshBonusTime)
			{
				RefreshBonuses();
				currRefreshBonusTime = -1f;
			}
		}
		if (lifeTime < matureTime)
		{
			UpdateTreeScale();
		}
		if (b.IsOpen())
		{
			float num = Mathf.Lerp(dt, 0f, (float)barrenCells / 4f);
			lifeTime += num;
		}
		if (currFrame % 4 == updateFrame)
		{
			if (currentSeason == 2 || !IsOrchardMature())
			{
				yieldProducer.PauseYield = true;
				return;
			}
			yieldProducer.PauseYield = false;
			fruitSystem.SetTime(owners[0], yieldProducer.actualYieldPercentage);
		}
	}

	private void OnInit()
	{
		lifeTime = 0f;
		customProductionItems[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = productionIcon,
			type = BuildingProductionUI.CustomProductionItem.CustomType.Infinite,
			locTerm = "custom_production_cost_" + b.UniqueName,
			hideBottom = true,
			currentStorage = -1
		};
		resourceStorageMax.Set(stack.resourceID, stack.MaxCapacity());
		matureTime = (float)YearsToMature * SeasonManager.inst.TimeInYear();
		if (matureTime <= 0f)
		{
			matureTime = 0.01f;
		}
		Player.inst.irrigation.OnReservoirIrrigationUpdated += Irrigation_OnIrrigationUpdated;
		onSeasonEvent = Broadcast.SeasonEvent.Listen(OnSeasonChanged);
		b.visibilityChanged += OnBuildingVisibilityChanged;
	}

	private void OnBuilt()
	{
		UpdateYieldBonus();
		TryCreateTrees();
		AddFruitInstances();
	}

	private void OnFinishedLoad()
	{
		UpdateYieldBonus();
	}

	private void OnBuildingPlacement(bool undo)
	{
		TryCreateTrees();
		AddFruitInstances();
	}

	private void OnYieldResources(int typeID, int yield)
	{
		if (yield > 0)
		{
			UpdateYieldBonus();
			yield += GetTotalBonus();
			ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), yieldProducer.YieldType, yield);
			stack.Add(yield);
			ResourceStatistics.AddProduction(b.LandMass(), b.UniqueName, yieldProducer.YieldType, yield);
			for (int i = 0; i < b.jobs.Count; i++)
			{
				(b.jobs[i] as HarvesterJob).Harvest();
			}
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(HarvesterJob)))
			{
				b.SetAndAddJob(i, new HarvesterJob(b));
			}
			InitHarvesterJob(b.jobs[i] as HarvesterJob);
		}
	}

	private void InitHarvesterJob(HarvesterJob j)
	{
		j.freeResourceType = yieldProducer.YieldType;
	}

	public void OnSeasonChanged(object sender, SeasonEventData obj)
	{
		if (obj.SeasonDefinition.id == 3)
		{
			RotStack();
		}
		currentSeason = obj.SeasonDefinition.id;
	}

	public void RotStack()
	{
		int num = stack.AvailableAmount();
		if (num > 0)
		{
			ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), yieldProducer.YieldType, -num);
			ResourceStatistics.AddConsumption(b.LandMass(), "rot", yieldProducer.YieldType, num);
			stack.Clear();
			MilestoneManager.inst.TryWasterFoodMilestone();
		}
	}

	private bool ShouldConnect(Cell c)
	{
		if (c == null)
		{
			return false;
		}
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (c.OccupyingStructure[i].uniqueNameHash == b.uniqueNameHash)
			{
				return true;
			}
		}
		return false;
	}

	private void OnBuildingVisibilityChanged(bool v)
	{
		for (int i = 0; i < treeInstances.Length; i++)
		{
			treeInstances[i].SetTreeTrunkTopVisible(v);
		}
		UpdateTreeScale();
	}

	private void AddFruitInstances()
	{
		if (!b.IsBuilt() || addedInstances)
		{
			return;
		}
		addedInstances = true;
		fruitSystem.BeginAdd();
		for (int i = 0; i < treeInstances.Length; i++)
		{
			Transform fruitContainer = treeInstances[i].fruitContainer;
			for (int j = 0; j < fruitContainer.childCount; j++)
			{
				Transform child = fruitContainer.GetChild(j);
				FieldSystem.Owner owner = new FieldSystem.Owner();
				fruitSystem.AddInstance(owner, child.position, Quaternion.identity, Vector3.zero);
				owners.Add(owner);
			}
		}
		fruitSystem.EndAdd();
		fruitSystem.SetTime(owners[0], yieldProducer.actualYieldPercentage);
	}

	public void ResetField()
	{
		if (owners.Count > 0)
		{
			fruitSystem.SetTime(owners[0], 0f);
		}
	}

	private void RemoveInstances()
	{
		for (int i = 0; i < owners.Count; i++)
		{
			fruitSystem.RemoveInstance(owners[i]);
		}
		owners.Clear();
		addedInstances = false;
	}

	private void Irrigation_OnIrrigationUpdated()
	{
		RefreshBonuses();
	}

	private void TryCreateTrees()
	{
		if (treeInstances == null)
		{
			float num = 0f;
			treeInstances = new OrchardFruit[treeContainer.childCount];
			for (int i = 0; i < treeContainer.childCount; i++)
			{
				Transform child = treeContainer.GetChild(i);
				OrchardFruit component = UnityEngine.Object.Instantiate(treePrefab, child).GetComponent<OrchardFruit>();
				component.transform.position = child.position;
				component.transform.rotation = Quaternion.Euler(0f, num, 0f);
				component.Setup();
				treeInstances[i] = component;
				num += 90f;
			}
		}
	}

	private void UpdateYieldBonus()
	{
		int fertility = 0;
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			fertility += cell.GetFertility();
		});
		fertilityBonus = Mathf.FloorToInt((float)fertility / (b.size.x * b.size.z));
	}

	private void RefreshBonuses()
	{
		irrigationBonus = Mathff.Clamp(b.GetCell().IrrigationCoverage, 0, 1);
	}

	private void UpdateTreeScale()
	{
		float num = Mathff.Clamp01(lifeTime / matureTime);
		Vector3 scalev = new Vector3(num, num, num);
		for (int i = 0; i < treeInstances.Length; i++)
		{
			treeInstances[i].UpdateTreeTransform(scalev);
		}
	}

	public override int GetResult(int rID)
	{
		if (rID != yieldProducer.YieldType)
		{
			return 0;
		}
		if (GameState.inst.IsPersistantBuildingPrefab(gameObject))
		{
			return yieldProducer.YieldAmt;
		}
		if (fertilityBonus > 0)
		{
			return yieldProducer.YieldAmt;
		}
		return int.MinValue;
	}

	public override bool ShowResultStorage()
	{
		return false;
	}

	public override int GetOutputStorage(int rID)
	{
		if (rID != yieldProducer.YieldType)
		{
			return 0;
		}
		return stack.Count();
	}

	public override BuildingProductionUI.CustomProductionItem[] GetCustomCost()
	{
		if (fertilityBonus > 0)
		{
			customProductionItems[0].type = BuildingProductionUI.CustomProductionItem.CustomType.Infinite;
		}
		else
		{
			customProductionItems[0].type = BuildingProductionUI.CustomProductionItem.CustomType.TerrainResource;
		}
		return customProductionItems;
	}

	public override float GetProgress()
	{
		return yieldProducer.actualYieldPercentage;
	}

	public override int GetTotalBonus()
	{
		return fertilityBonus - 1;
	}

	public override string GetCustomText()
	{
		string text = "";
		if (!IsOrchardMature())
		{
			text = text + "<color=yellow>" + LocalizationManager.GetTranslation("workerui_orchardnotmature") + "</color>\n\n";
		}
		if (GetTotalBonus() > 0)
		{
			text += string.Format(LocalizationManager.GetTranslation("VeryFertileBonus"), GetTotalBonus());
		}
		return text;
	}

	public override string GetError()
	{
		if (barrenCells > 0)
		{
			return ScriptLocalization.OrchardFertileError;
		}
		bool flag = false;
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is HarvesterJob harvesterJob && harvesterJob.GetStatus() == HarvesterJob.Status.WaitForStorageToOpen && harvesterJob.HasFailedToFindStorage())
			{
				flag = true;
				break;
			}
		}
		if (flag)
		{
			return ScriptLocalization.workerui_harvesterjob_waitingforstorage_error;
		}
		return null;
	}
}
