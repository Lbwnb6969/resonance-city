using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using I2.Loc;
using UnityEngine;

public class Field : ExtractionBuilding, IOverlayUser
{
	[Serializable]
	public class FieldSaveData : SaveClass<Field, FieldSaveData>
	{
		public float[] times;

		private int stackCount;

		private float floodTime;

		public float time;

		public override FieldSaveData Pack(Field obj)
		{
			floodTime = obj.floodTime;
			time = obj.time;
			stackCount = obj.stack.Count();
			return this;
		}

		public override Field Unpack(Field obj)
		{
			obj.floodTime = floodTime;
			obj.time = time;
			obj.stack.Add(stackCount);
			return obj;
		}
	}

	private List<FieldSystem.Owner> owners = new List<FieldSystem.Owner>();

	private ResourceAmount yResult = new ResourceAmount();

	public ResourceAmount pStorage = new ResourceAmount();

	public Transform transformRoot;

	public Transform flood;

	public Material floodMaterial;

	public Mesh badFieldMesh;

	public Mesh goodFieldMesh;

	public MeshFilter meshFilter;

	private const int frameSpread = 10;

	private int updateFrame = SRand.srand.Next(0, 10);

	private float floodTime;

	public Vector3 cropScaleMod = new Vector3(1f, 1f, 1f);

	public Mesh fruitMesh;

	public Material fruitMaterial;

	[NonSerialized]
	public Vector3 currCropScale;

	public float zStartOffset;

	public float xStartOffset;

	private float currRefreshBonusTime = -1f;

	private float refreshBonusTime = 1f;

	private bool flooded;

	private float floodChance;

	private float skillBonus;

	public int bonusPerFertileScore = 1;

	public int rows = 4;

	private float time;

	private float irrigationBonus;

	public int fertilityBonus;

	private float deferredYield;

	private float deferredYieldTime = -1f;

	private Vector3[] cropOffsets;

	private Vector3 cachedPos = Vector3.zero;

	[NonSerialized]
	public Quaternion cachedRot = Quaternion.identity;

	private int currentSeason = -1;

	private EventHandler<SeasonEventData> seasonEventListenEventHandler;

	public YieldProducerSeason yieldProducer;

	private FieldSystem fieldSystem;

	private bool addedInstances;

	private EventHandler<OnTechnologyTreeUnlock> unlockEventHandler;

	private bool isFertile = true;

	private float curseTime = -1f;

	private int slopedGroundBonus;

	public Color extraBonusColor;

	public float angleLimit = -1f;

	bool IOverlayUser.OverlayWhenPlacing => angleLimit != -1f;

	bool IOverlayUser.OverlayWhenSelected => false;

	protected override void Awake()
	{
		base.Awake();
		yieldProducer = GetComponent<YieldProducerSeason>();
		fieldSystem = Player.inst.GetFieldSystem(fruitMesh, fruitMaterial);
		fieldSystem.chunkSize = 4;
		fieldSystem.type = 0;
		fieldSystem.scaleMod = cropScaleMod;
		yieldProducer.OnYieldResources += OnYieldResources;
		cropOffsets = new Vector3[rows];
		time = 0f;
	}

	private void OnDestroy()
	{
		RemoveFieldInstances();
		Broadcast.SeasonEvent.Unlisten(seasonEventListenEventHandler);
		Broadcast.TechnologyTreeUnlockEvent.Unlisten(unlockEventHandler);
		b.visibilityChanged -= OnBuildingVisibilityChanged;
	}

	protected override void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		Cell cell = b.GetCell();
		isFertile = cell.GetEffectiveFertility() > 0;
		if (!isFertile)
		{
			validationResult = PlacementValidationResult.MustBeOnFertileLand;
		}
		meshFilter.sharedMesh = (isFertile ? goodFieldMesh : badFieldMesh);
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
		if (deferredYieldTime != -1f)
		{
			deferredYieldTime -= dt;
			if (deferredYieldTime < 0f)
			{
				DeferredYield();
				deferredYieldTime = -1f;
			}
		}
		if (currFrame % 10 != updateFrame)
		{
			return;
		}
		dt *= 10f;
		if (currentSeason == 2)
		{
			flooded = false;
			time = 0f;
		}
		else
		{
			UpdateYieldBonus();
			curseTime -= dt;
			if (flooded)
			{
				yieldProducer.PauseYield = true;
				time -= dt;
				if (time < 0f)
				{
					time = 0f;
				}
				yieldProducer.ResetYield();
				floodTime += dt * 0.5f;
				if (floodTime > 1f)
				{
					floodTime = 1f;
				}
			}
			else
			{
				floodTime -= dt * 0.5f;
				if (floodTime < 0f)
				{
					floodTime = 0f;
				}
				if (isFertile)
				{
					yieldProducer.PauseYield = false;
					time = Mathff.Clamp01(yieldProducer.actualYieldPercentage) * Mathf.Clamp01(0.6f + (float)fertilityBonus * 0.2f);
				}
				else
				{
					if (yieldProducer.actualYieldPercentage > 0.33f)
					{
						yieldProducer.actualYieldPercentage = 0.33f;
					}
					yieldProducer.PauseYield = true;
				}
			}
		}
		Vector3 localPosition = flood.localPosition;
		localPosition.y = Mathff.Lerp(-0.1f, 0.005f, floodTime);
		flood.localPosition = localPosition;
		fieldSystem.SetTime(owners[0], time);
	}

	public void ResetField()
	{
		if (owners.Count > 0)
		{
			fieldSystem.SetTime(owners[0], 0f);
		}
	}

	private void OnInit()
	{
		time = 0f;
		flooded = false;
		flood.GetComponent<MeshRenderer>().material = floodMaterial;
		customProductionItems[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = productionIcon,
			type = BuildingProductionUI.CustomProductionItem.CustomType.Infinite,
			locTerm = "custom_production_cost_field",
			hideBottom = true,
			currentStorage = -1
		};
		resourceStorageMax.Set(stack.resourceID, stack.MaxCapacity());
		seasonEventListenEventHandler = Broadcast.SeasonEvent.Listen(OnSeasonChanged);
		b.visibilityChanged += OnBuildingVisibilityChanged;
	}

	private void OnBuildingVisibilityChanged(bool v)
	{
		if (v)
		{
			AddFieldInstances();
		}
		else
		{
			RemoveFieldInstances();
		}
	}

	private void AddFieldInstances()
	{
		if (b.IsBuilt() && !addedInstances)
		{
			addedInstances = true;
			float num = 0.04f;
			float num2 = (b.size.z - (0.3f + num)) / (float)(rows - 1);
			fieldSystem.BeginAdd();
			for (int i = 0; i < rows; i++)
			{
				FieldSystem.Owner owner = new FieldSystem.Owner();
				cropOffsets[i] = cachedPos + cachedRot * new Vector3(xStartOffset, 0f, zStartOffset + (float)i * num2);
				fieldSystem.AddInstance(owner, cropOffsets[i], cachedRot, Vector3.zero);
				owners.Add(owner);
			}
			fieldSystem.EndAdd();
			fieldSystem.SetTime(owners[0], time);
		}
	}

	private void RemoveFieldInstances()
	{
		addedInstances = false;
		for (int i = 0; i < owners.Count; i++)
		{
			fieldSystem.RemoveInstance(owners[i]);
		}
	}

	private void OnBuilt()
	{
		UpdateYieldBonus();
		CalculateFloodChance();
		AddFieldInstances();
	}

	private void OnFinishedLoad()
	{
		UpdateYieldBonus();
		CalculateFloodChance();
	}

	public void OnBuildingPlacement(bool undo)
	{
		cachedPos = transform.GetChild(0).position;
		cachedRot = transform.GetChild(0).rotation;
		AddFieldInstances();
		if (!undo)
		{
			if (TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_advancedfarm"))
			{
				GetComponent<YieldProducerSeason>().YieldAmt++;
			}
			else
			{
				unlockEventHandler = Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyTreeUnlock);
			}
		}
	}

	private void OnTechnologyTreeUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		if (data.unlockKey == "unlockkey_advancedfarm")
		{
			GetComponent<YieldProducerSeason>().YieldAmt++;
			Broadcast.TechnologyTreeUnlockEvent.Unlisten(unlockEventHandler);
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

	private void OnYieldResources(int t, int YieldAmt)
	{
		deferredYield = YieldAmt;
		deferredYieldTime = SRand.Range(0f, 2f);
	}

	private void DeferredYield()
	{
		float num = deferredYield;
		if (num > 0f)
		{
			UpdateYieldBonus();
			num += (float)GetTotalBonus();
			ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), yieldProducer.YieldType, (int)num);
			stack.Add((int)num);
			Vector3 pos = stack.transform.position;
			TerrainGen.inst.GetGroundHeight(ref pos);
			stack.transform.position = pos;
			ResourceStatistics.AddProduction(b.LandMass(), b.UniqueName, yieldProducer.YieldType, (int)num);
			for (int i = 0; i < b.jobs.Count; i++)
			{
				(b.jobs[i] as HarvesterJob).Harvest();
			}
		}
		time = 0f;
	}

	private void CalculateFloodChance()
	{
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		int num = Mathff.Clamp(minX - 2, 0, World.inst.GridWidth - 1);
		int num2 = Mathff.Clamp(maxX + 2, 0, World.inst.GridWidth - 1);
		int num3 = Mathff.Clamp(minZ - 2, 0, World.inst.GridHeight - 1);
		int num4 = Mathff.Clamp(maxZ + 2, 0, World.inst.GridHeight - 1);
		floodChance = 0f;
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num; j <= num2; j++)
			{
				if (World.inst.GetCellDataUnsafe(j, i).Type == TerrainType.Water)
				{
					floodChance += 0.2f;
				}
			}
		}
		floodChance = Mathff.Clamp01(floodChance);
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

	public void OnSeasonChanged(object sender, SeasonEventData obj)
	{
		if (obj.SeasonDefinition.id == 3)
		{
			RotStack();
		}
		currentSeason = obj.SeasonDefinition.id;
	}

	public void RefreshBonuses()
	{
		irrigationBonus = Mathff.Clamp(b.GetCell().IrrigationCoverage, 0, 1);
	}

	public void Curse()
	{
		curseTime = 60f;
		UpdateYieldBonus();
	}

	private void UpdateYieldBonus()
	{
		int fertility = b.GetCell().GetFertility();
		fertilityBonus = Mathf.FloorToInt((float)fertility / (b.size.x * b.size.z));
		isFertile = fertilityBonus > 0;
		if (angleLimit != -1f)
		{
			slopedGroundBonus = (IsSlopedForBonus(b.GetCell(), Mathf.Cos(angleLimit * (MathF.PI / 180f))) ? 1 : 0);
		}
		else
		{
			slopedGroundBonus = 0;
		}
		if (curseTime > 0f)
		{
			isFertile = false;
		}
		meshFilter.sharedMesh = (isFertile ? goodFieldMesh : badFieldMesh);
	}

	public bool IsSlopedForBonus(Cell cell, float cosAngle)
	{
		return Vector3.Dot((TerrainGen.inst.GetNormal((float)cell.x + 0.5f, (float)cell.z + 0.5f) + TerrainGen.inst.GetNormal((float)cell.x + 0.75f, (float)cell.z + 0.5f) + TerrainGen.inst.GetNormal((float)cell.x + 0.25f, (float)cell.z + 0.5f) + TerrainGen.inst.GetNormal((float)cell.x + 0.5f, (float)cell.z + 0.75f) + TerrainGen.inst.GetNormal((float)cell.x + 0.5f, (float)cell.z + 0.25f)) / 5f, Vector3.up) < cosAngle;
	}

	public void ResetTime()
	{
		time = 0f;
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
		return slopedGroundBonus + fertilityBonus - 1;
	}

	public override string GetCustomText()
	{
		string text = "";
		if (fertilityBonus - 1 > 0)
		{
			text += string.Format(LocalizationManager.GetTranslation("VeryFertileBonus"), fertilityBonus - 1);
		}
		if (slopedGroundBonus > 0)
		{
			if (text.Length > 0)
			{
				text += "\n";
			}
			text += string.Format(LocalizationManager.GetTranslation("SlopedGroundBonus"), slopedGroundBonus);
		}
		return text;
	}

	public override string GetError()
	{
		if (fertilityBonus <= 0)
		{
			return ScriptLocalization.FieldFertilityError;
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

	void IOverlayUser.DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.ClearOverlay(updateToo: true);
		float cosMaxPlacementAngle = b.GetCosMaxPlacementAngle();
		Color col = extraBonusColor;
		col.a *= 0.75f;
		Vector3 up = Vector3.up;
		int focusedLandMass = Player.inst.FocusedLandMass;
		if (focusedLandMass != -1)
		{
			float cosAngle = Mathf.Cos(angleLimit * (MathF.PI / 180f));
			ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[focusedLandMass];
			for (int i = 0; i < arrayExt.Count; i++)
			{
				Cell cell = arrayExt.data[i];
				int effectiveFertility = cell.GetEffectiveFertility();
				if (effectiveFertility <= 0 || cell.GetRoadCoverage() <= 0)
				{
					continue;
				}
				bool flag = false;
				if (IsSlopedForBonus(cell, cosAngle) && !World.inst.IsTooSteep(cosMaxPlacementAngle, cell, up))
				{
					flag = true;
				}
				if (flag)
				{
					if (effectiveFertility > 1)
					{
						TerrainGen.inst.SetOverlayTileColor(cell.x, cell.z, extraBonusColor);
					}
					else
					{
						TerrainGen.inst.SetOverlayTileColor(cell.x, cell.z, col);
					}
				}
			}
		}
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}
}
