using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Home : Tickable, IResidence, IOutputInfo, IWorkerUIDisplay, IEmployer, IResourceStorageBase
{
	public enum OverlayType
	{
		None,
		Happiness,
		Health
	}

	[Serializable]
	public class Consumable
	{
		[Header("Resource Settings")]
		[FreeResourceType]
		public int type = -1;

		public int happinessModifierID;

		[Header("Resource Settings")]
		[FreeResourceType]
		public int altType = -1;

		public int altHappinessModifierID;

		public float timer;

		public bool doMissingThought;
	}

	[Serializable]
	public class HomeSaveData : SaveClass<Home, HomeSaveData>
	{
		public List<Guid> ids = new List<Guid>();

		private bool charcoalAvailable;

		[OptionalField(VersionAdded = 2)]
		private ResourceAmount storedResourceAmount;

		[OptionalField(VersionAdded = 3)]
		private float taxRev;

		[OptionalField(VersionAdded = 4)]
		private Guid[] idArray;

		public SerializableDictionary<int, int> consumableHappinessModifiers;

		public bool[] consumableAvailable;

		public int[] dietFilled;

		public float health;

		public override HomeSaveData Pack(Home obj)
		{
			taxRev = obj.taxRev;
			idArray = new Guid[obj.Residents.Count];
			int i = 0;
			for (int count = obj.Residents.Count; i < count; i++)
			{
				idArray[i] = obj.Residents[i].guid;
			}
			storedResourceAmount = obj.resourcesStored;
			consumableHappinessModifiers = new SerializableDictionary<int, int>(obj.ConsumableHappinessModifiers);
			consumableAvailable = obj.consumablesAvailable;
			dietFilled = obj.dietFilled;
			return this;
		}

		private void UnloadVillager(Home obj, Guid g)
		{
			Villager worker = Player.inst.GetWorker(g);
			if (worker != null)
			{
				obj.AddResident(worker);
			}
			else
			{
				Debug.Log("Invalid reference to villager.");
			}
		}

		public override Home Unpack(Home obj)
		{
			obj.taxRev = taxRev;
			if (ids != null)
			{
				for (int i = 0; i < ids.Count; i++)
				{
					UnloadVillager(obj, ids[i]);
				}
			}
			if (idArray != null)
			{
				for (int j = 0; j < idArray.Length; j++)
				{
					UnloadVillager(obj, idArray[j]);
				}
			}
			obj.resourcesStored = storedResourceAmount;
			if (consumableHappinessModifiers != null)
			{
				foreach (KeyValuePair<int, int> consumableHappinessModifier in consumableHappinessModifiers)
				{
					if (!obj.ConsumableHappinessModifiers.TryAdd(consumableHappinessModifier.Key, consumableHappinessModifier.Value))
					{
						obj.ConsumableHappinessModifiers[consumableHappinessModifier.Key] = consumableHappinessModifier.Value;
					}
				}
			}
			if (consumableAvailable != null)
			{
				for (int k = 0; k < obj.consumablesAvailable.Length && k < consumableAvailable.Length; k++)
				{
					obj.consumablesAvailable[k] = consumableAvailable[k];
				}
			}
			if (dietFilled != null)
			{
				for (int l = 0; l < obj.dietFilled.Length && l < dietFilled.Length; l++)
				{
					obj.dietFilled[l] = dietFilled[l];
				}
			}
			return obj;
		}
	}

	private bool nearWater;

	private Dictionary<int, int> MaxHappinessObserved = new Dictionary<int, int>(64);

	public Dictionary<int, int> HappinessBonuses = new Dictionary<int, int>(64);

	[NonSerialized]
	public Dictionary<int, int> ConsumableHappinessModifiers;

	[NonSerialized]
	public Dictionary<int, int> TileHappinessModifiers;

	public int MaxHappinessFromHealth = 50;

	private float startDamageHappinessDebuf = 0.7f;

	public Transform lifeDetritus;

	public int MaxResidents = 3;

	[NonSerialized]
	public List<Villager> Residents = new List<Villager>();

	public ParticleSystem ChimneySmoke;

	public Material lowHappiness;

	public Material mediumLowHappiness;

	public Material mediumHappiness;

	public Material highHappiness;

	public Material veryHighHappiness;

	public Material noResidents;

	public Material lowHealth;

	public Material mediumLowHealth;

	public Material mediumHealth;

	public Material highHealth;

	public Material mediumHighHealth;

	public Material veryHighHealth;

	[NonSerialized]
	public Building b;

	private WaterConsumer WaterConsumer;

	[NonSerialized]
	public ResourceAmount resourceMaxStorage;

	public ResourceAmount resourcesStored = new ResourceAmount();

	private EventHandler<OnBuildingAddRemove> addRemoveListenEventHandler;

	private EventHandler<OnBuildingOpenClose> openCloseListenEventHandler;

	private EventHandler<OnBuildingBuilt> buildListenEventHandler;

	private float eatTime;

	private float eatTimeInterval;

	public float eatTimeMultiplier = 1f;

	private OverlayType overlayType;

	private Timer overlayUpdateTimer = new Timer(5f);

	[NonSerialized]
	public Timer taxTimer = new Timer(56.25f);

	public float taxYield = 1f;

	public int[] dietFilled;

	public Consumable[] diet;

	public Consumable[] consumables;

	public List<int> ExcludeTileHappinessModifiers;

	private int frameSpread = 100;

	private int updateFrame;

	private static int updateID = 0;

	private float taxRev;

	private ArrayExt<int> typesAvailableToCollect = new ArrayExt<int>(5);

	private int[] gatherTypes;

	private int[] gatherTypeOrder;

	public bool wantAqueduct;

	internal int missedMeal;

	internal int missingFood = -1;

	internal bool foodExists;

	private float waterTimer;

	private float happyThought;

	private const int ResidentSwapInterval = 10;

	private const int ResidentSwapHalfWidth = 5;

	private const float MinCommuteImprovement = 3f;

	private int residentSwapCounter;

	private static HashSet<Building> swapScannedEmployers = new HashSet<Building>();

	private Timer[] consumableTimers;

	internal bool[] consumablesAvailable;

	private static ArrayExt<RadiusBonus> processed = new ArrayExt<RadiusBonus>(20);

	private static Dictionary<RadiusBonus, int> rMaxBonus = new Dictionary<RadiusBonus, int>(32);

	internal bool filthNearby;

	internal float wellAccess;

	public bool wantsNeighbors = true;

	private List<Job> openHomemakerJobs = new List<Job>();

	private int currEatIdx;

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
		return false;
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

	public int GetHappiness()
	{
		int num = 0;
		foreach (KeyValuePair<int, int> consumableHappinessModifier in ConsumableHappinessModifiers)
		{
			num += consumableHappinessModifier.Value;
		}
		int num2 = GetHappinessFromDiet() + GetHappinessFromWater() + GetHealthDebuffFromFilth() + GetHappinessFromClinicHealth();
		foreach (KeyValuePair<int, int> tileHappinessModifier in TileHappinessModifiers)
		{
			num += tileHappinessModifier.Value;
		}
		return GetHappinessFromTax() + num + num2;
	}

	public float GetWaterAccessQuality()
	{
		float num = wellAccess * 0.5f;
		if (WaterConsumer.availableWaterPercentage > num)
		{
			num = WaterConsumer.availableWaterPercentage;
		}
		return num;
	}

	public int GetHappinessFromClinicHealth()
	{
		return (int)(GetClinicHealth() * 5f);
	}

	public float GetClinicHealth()
	{
		if (IsWithinClinicRadius(out var isStaffed) & isStaffed)
		{
			return 1f;
		}
		if (!IsFarmVilla() && Player.inst.Workers.Count >= 200)
		{
			return -1f;
		}
		return 0f;
	}

	public bool IsFarmVilla()
	{
		return b.uniqueNameHash == World.villarusticaHash;
	}

	public bool IsWithinClinicRadius(out bool isStaffed)
	{
		bool isClinicNearby = false;
		bool isClinicStaffed = false;
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			CellInfluence cellInfluenceDataClamped = World.inst.GetCellInfluenceDataClamped(x, z);
			for (int i = 0; i < cellInfluenceDataClamped.radiusHealthBonuses.Count; i++)
			{
				if (cellInfluenceDataClamped.radiusHealthBonuses.data[i].residentialTileID == 239)
				{
					isClinicNearby = true;
					isClinicStaffed |= cellInfluenceDataClamped.radiusHealthBonuses.data[i].GetComponent<Building>().GetWorkerPercent() > 0f;
				}
			}
		});
		isStaffed = isClinicStaffed;
		return isClinicNearby;
	}

	public float GetDietQuality()
	{
		int num = 0;
		for (int i = 0; i < diet.Length; i++)
		{
			if (resourcesStored.Get(diet[i].type) > 0 || resourcesStored.Get(diet[i].altType) > 0)
			{
				num++;
			}
		}
		return Mathff.Clamp(Mathf.Sqrt((float)num / (float)diet.Length), 0f, 1f);
	}

	public int GetHealthDebuffFromFilth()
	{
		if (TileHappinessModifiers.TryGetValue(235, out var value))
		{
			return value;
		}
		return 0;
	}

	public float GetHealth()
	{
		if (Residents.Count == 0)
		{
			return 0f;
		}
		float dietQuality = GetDietQuality();
		float waterAccessQuality = GetWaterAccessQuality();
		float num = GetClinicHealth() * 0.1f + dietQuality * 0.75f + waterAccessQuality * 0.25f + (float)GetHealthDebuffFromFilth() / 20f * 0.5f;
		for (int i = 0; i < Residents.Count; i++)
		{
			Residents[i].health = num;
		}
		return num;
	}

	public int GetHappinessFromDiet()
	{
		int num = MaxHappinessFromHealth;
		if (b.TeamID() == 0 && TechnologyTree.inst.isFineWineUnlocked && resourcesStored.Get(13) > 0)
		{
			num += 3;
		}
		return Mathf.CeilToInt(GetDietQuality() * (float)num);
	}

	public int GetHappinessFromTax()
	{
		float taxRate = GetTaxRate();
		if (taxRate >= 0.5f && taxRate < 1f)
		{
			return -3;
		}
		if (taxRate >= 1f && taxRate < 1.5f)
		{
			return -7;
		}
		if (taxRate >= 1.5f && taxRate < 2f)
		{
			return -15;
		}
		if (taxRate == 2f && taxRate < 2.5f)
		{
			return -20;
		}
		if (taxRate >= 2.5f && taxRate < 3f)
		{
			return -35;
		}
		if (taxRate == 3f)
		{
			return -50;
		}
		return 0;
	}

	public int GetHappinessFromWater()
	{
		return Mathf.CeilToInt(GetWaterAccessQuality() * 15f);
	}

	string IOutputInfo.GetError()
	{
		if (Residents.Count <= 0)
		{
			return null;
		}
		if (b.thought.thought == ThoughtBubbleSystem.Thought.Cold)
		{
			return ScriptLocalization.HomeErrorCold;
		}
		if (b.thought.thought == ThoughtBubbleSystem.Thought.Aqueduct)
		{
			return ScriptLocalization.HomeErrorAqueduct;
		}
		if (b.thought.thought == ThoughtBubbleSystem.Thought.Pottery)
		{
			return ScriptLocalization.HomeErrorPottery;
		}
		if (b.thought.thought == ThoughtBubbleSystem.Thought.Water)
		{
			return ScriptLocalization.HomeErrorWater;
		}
		if (b.thought.thought == ThoughtBubbleSystem.Thought.Wine)
		{
			return ScriptLocalization.HomeErrorWine;
		}
		if (b.thought.thought == ThoughtBubbleSystem.Thought.Food)
		{
			return ScriptLocalization.HomeErrorFood;
		}
		if (b.thought.thought == ThoughtBubbleSystem.Thought.FoodCritical)
		{
			return ScriptLocalization.HomeErrorFoodCritical;
		}
		if (b.Life / b.ModifiedMaxLife <= startDamageHappinessDebuf)
		{
			return ScriptLocalization.HomeErrorDamaged;
		}
		return null;
	}

	public string GetExplanation(OutputTileUI tileOutput)
	{
		if (Residents.Count <= 0)
		{
			return "";
		}
		int num = 0;
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i].Employee != null)
			{
				num++;
			}
		}
		string text = "";
		if (Player.inst.GetTaxRate(b.LandMass()) > 0f)
		{
			float taxRate = Player.inst.GetTaxRate(b.LandMass());
			if (taxRate >= 1f && taxRate < 2f)
			{
				text += "<color=yellow>";
			}
			if (taxRate >= 2f && taxRate < 3f)
			{
				text += "<color=orange>";
			}
			else if (taxRate >= 3f)
			{
				text += "<color=red>";
			}
			text = text + string.Format(ScriptLocalization.HomeBeingTaxed, -GetHappinessFromTax()) + "</color>\n";
		}
		return text;
	}

	private string ExplainResource(int type)
	{
		int a = resourcesStored.Get(type);
		int num = resourceMaxStorage.Get(type);
		a = Mathff.Min(a, num);
		string text = "";
		if (num > 0)
		{
			if (a > 0)
			{
				text = text + ResourceAmount.ResourceIcon(type) + ": " + a + " / " + num;
			}
			else
			{
				text = text + ResourceAmount.ResourceIcon(type) + ": <color=yellow>" + a + "</color> / " + num;
				text = ((Player.inst.resourcesPerLandmass[LandMass()].Get(type) > 0) ? (text + ScriptLocalization.ToFarAway) : (text + ScriptLocalization.NoneAvailable));
			}
			text += Environment.NewLine;
		}
		return text;
	}

	public void WaterUpdate()
	{
	}

	private void OnInit()
	{
		b = GetComponent<Building>();
		WaterConsumer = GetComponent<WaterConsumer>();
		if (WaterConsumer != null)
		{
			WaterConsumer.SetupChangeCallback(WaterUpdate);
		}
		b.visibilityChanged += B_visibilityChanged;
		b.PlacementValidaton = PlacementValidation;
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		if (validationResult != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		bool hasSmallHouseUnder = false;
		bool hasAnythingElseUnder = false;
		if (b.uniqueNameHash != World.smallHouseHash)
		{
			b.ForEachTileInBounds((int x, int z, Cell cell) =>
			{
				for (int i = 0; i < cell.OccupyingStructure.Count; i++)
				{
					Building building = cell.OccupyingStructure[i];
					if (building.uniqueNameHash == World.smallHouseHash || building.uniqueNameHash == World.rubbleHash)
					{
						hasSmallHouseUnder = true;
					}
					else
					{
						hasAnythingElseUnder = true;
					}
				}
			});
		}
		if (hasSmallHouseUnder && !hasAnythingElseUnder)
		{
			validationResult = PlacementValidationResult.Valid;
		}
	}

	private void B_visibilityChanged(bool v)
	{
	}

	private void OnShutdown()
	{
		b.visibilityChanged -= B_visibilityChanged;
	}

	private void Start()
	{
		updateFrame = updateID % frameSpread;
		updateID++;
		residentSwapCounter = SRand.Range(0, 10);
		if ((bool)lifeDetritus)
		{
			for (int i = 0; i < lifeDetritus.childCount; i++)
			{
				lifeDetritus.GetChild(i).gameObject.SetActive(value: false);
			}
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
			FreeResourceGathererJob obj = b.jobs[i] as FreeResourceGathererJob;
			obj.ManualAssignment = true;
			obj.filterPrimary = JobFilterPrimary;
			obj.filterAlternate = JobFilterAlternate;
			obj.searchRadius = 30f;
			obj.typeOrder = gatherTypeOrder;
		}
	}

	private bool JobFilterPrimary(IResourceProvider x, int type)
	{
		if (x.GetType() == typeof(Home))
		{
			return false;
		}
		if (!x.ConsiderAsPrimary(type))
		{
			return false;
		}
		return true;
	}

	private bool JobFilterAlternate(IResourceProvider x, int type)
	{
		return x.GetType() != typeof(Home);
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		ConsumableHappinessModifiers = new Dictionary<int, int>(consumables.Length);
		for (int i = 0; i < consumables.Length; i++)
		{
			int happinessModifierID = consumables[i].happinessModifierID;
			HappinessModifierSystem.inst.TryGetNegativeHappiness(happinessModifierID, out var happinessMod);
			ConsumableHappinessModifiers.TryAdd(happinessModifierID, happinessMod);
			if (consumables[i].altType != -1)
			{
				HappinessModifierSystem.inst.TryGetNegativeHappiness(consumables[i].altHappinessModifierID, out var happinessMod2);
				ConsumableHappinessModifiers.TryAdd(consumables[i].altHappinessModifierID, happinessMod2);
			}
		}
		TileHappinessModifiers = new Dictionary<int, int>(64);
		consumablesAvailable = new bool[consumables.Length];
		consumableTimers = new Timer[consumables.Length];
		for (int j = 0; j < consumableTimers.Length; j++)
		{
			consumableTimers[j] = new Timer(consumables[j].timer);
			consumableTimers[j].CurrTime = SRand.Range(0f, consumables[j].timer);
			consumablesAvailable[j] = false;
		}
		taxTimer.CurrTime = SRand.Range(0f, taxTimer.Duration);
		if (gatherTypes == null)
		{
			int num = 0;
			for (int k = 0; k < consumables.Length; k++)
			{
				if (consumables[k].altType != -1)
				{
					num++;
				}
			}
			for (int l = 0; l < diet.Length; l++)
			{
				if (diet[l].altType != -1)
				{
					num++;
				}
			}
			gatherTypes = new int[diet.Length + consumables.Length + num];
			int num2 = 0;
			for (int m = 0; m < diet.Length; m++)
			{
				gatherTypes[num2++] = diet[m].type;
				if (diet[m].altType != -1)
				{
					gatherTypes[num2++] = diet[m].altType;
				}
			}
			int num3 = diet.Length;
			for (int n = num3; n < num3 + consumables.Length; n++)
			{
				gatherTypes[num2++] = consumables[n - num3].type;
				if (consumables[n - num3].altType != -1)
				{
					gatherTypes[num2++] = consumables[n - num3].altType;
				}
			}
			gatherTypeOrder = new int[gatherTypes.Length];
			dietFilled = new int[diet.Length];
			for (int num4 = 0; num4 < dietFilled.Length; num4++)
			{
				dietFilled[num4] = -2;
			}
		}
		eatTimeInterval = SeasonManager.inst.TimeInYear() / ((float)diet.Length / 2f) * (1f / eatTimeMultiplier);
		currEatIdx = SRand.Range(0, diet.Length);
		int val = Mathf.CeilToInt(SeasonManager.inst.TimeInYear() / eatTimeInterval);
		resourceMaxStorage = new ResourceAmount();
		for (int num5 = 0; num5 < diet.Length; num5++)
		{
			resourceMaxStorage.Set(diet[num5].type, val);
			if (diet[num5].altType != -1)
			{
				resourceMaxStorage.Set(diet[num5].altType, val);
			}
		}
		for (int num6 = 0; num6 < consumables.Length; num6++)
		{
			int val2 = Mathf.Min(2, Mathf.CeilToInt(SeasonManager.inst.TimeInYear() / consumables[num6].timer));
			resourceMaxStorage.Set(consumables[num6].type, val2);
			if (consumables[num6].altType != -1)
			{
				resourceMaxStorage.Set(consumables[num6].altType, val2);
			}
		}
		resourcesStored.Set(0, Mathff.Max(2, (int)(1f * eatTimeMultiplier)));
		resourcesStored.Set(1, Mathff.Max(2, resourceMaxStorage.Get(1) / 2));
		for (int num7 = 0; num7 < consumables.Length; num7++)
		{
			TryConsume(num7);
		}
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		ClearResidence();
		HideOverlay();
	}

	public void ClearResidence()
	{
		int num = Residents.Count;
		for (int i = 0; i < num; i++)
		{
			Residents[i].Residence = null;
			Player.inst.Homeless.Add(Residents[i]);
		}
		Residents.Clear();
	}

	public float GetTaxRate()
	{
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		float num = 0f;
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				Cell cellData = World.inst.GetCellData(i, j);
				float taxOfficeCoverageWithStaff = TaxOfficeManager.inst.GetTaxOfficeCoverageWithStaff(cellData.x, cellData.z);
				if (taxOfficeCoverageWithStaff > num)
				{
					num = taxOfficeCoverageWithStaff;
				}
			}
		}
		return num;
	}

	public void ShowOverlay(OverlayType t)
	{
		if (overlayType != t && Player.inst.LandMassIsAPlayerLandMass(LandMass()))
		{
			if (t == OverlayType.Happiness)
			{
				UpdateHappinessOverlayMaterial();
			}
			if (t == OverlayType.Health)
			{
				UpdateHealthOverlayMaterial();
			}
			overlayType = t;
		}
	}

	public void UpdateHappinessOverlayMaterial()
	{
		int happiness = GetHappiness();
		Material material = lowHappiness;
		if (Residents.Count > 0)
		{
			if (happiness > 90)
			{
				material = veryHighHappiness;
			}
			else if (happiness > 75)
			{
				material = highHappiness;
			}
			else if (happiness > 60)
			{
				material = mediumHappiness;
			}
			else if (happiness > 40)
			{
				material = mediumLowHappiness;
			}
		}
		else
		{
			material = noResidents;
		}
		for (int i = 0; i < b.renderersWithBuildingShader.Count; i++)
		{
			b.renderersWithBuildingShader[i].material = material;
		}
	}

	public void UpdateHealthOverlayMaterial()
	{
		Player.HealthInfo.HealthRating healthRating = Player.HealthInfo.ToRating((int)(GetHealth() * 100f));
		Material material = lowHealth;
		if (Residents.Count > 0)
		{
			switch (healthRating)
			{
			case Player.HealthInfo.HealthRating.Excellent:
				material = veryHighHealth;
				break;
			case Player.HealthInfo.HealthRating.VeryGood:
				material = highHealth;
				break;
			case Player.HealthInfo.HealthRating.Good:
				material = mediumHighHealth;
				break;
			case Player.HealthInfo.HealthRating.Fair:
				material = mediumHealth;
				break;
			case Player.HealthInfo.HealthRating.Poor:
				material = mediumLowHealth;
				break;
			case Player.HealthInfo.HealthRating.VeryPoor:
				material = lowHealth;
				break;
			}
		}
		else
		{
			material = noResidents;
		}
		for (int i = 0; i < b.renderersWithBuildingShader.Count; i++)
		{
			b.renderersWithBuildingShader[i].material = material;
		}
	}

	public void HideOverlay()
	{
		if (overlayType != OverlayType.None)
		{
			overlayType = OverlayType.None;
			b.UpdateMaterialSelection();
		}
	}

	public float GetEstimatedTaxYield()
	{
		return SeasonManager.inst.TimeInYear() / taxTimer.Duration * (GetTaxRate() * taxYield * GetGovernorTaxMod() * ((float)Residents.Count / (float)MaxResidents));
	}

	public int LandMass()
	{
		return b.LandMass();
	}

	public int GetJobCategory()
	{
		return 0;
	}

	public bool DuringWorkHours(float buffer)
	{
		return true;
	}

	public float GetStartHour()
	{
		return -1f;
	}

	public float GetEndHour()
	{
		return -1f;
	}

	public static void BuildGatherTypeOrder(int landmass, ArrayExt<int> typesAvailableToCollect, ref int[] gatherTypeOrder, ResourceAmount resourcesStored, ResourceAmount resourceStorageMax, int[] gatherTypes)
	{
		typesAvailableToCollect.Clear();
		for (int i = 0; i < gatherTypes.Length; i++)
		{
			typesAvailableToCollect.Add(gatherTypes[i]);
		}
		for (int j = 0; j < gatherTypeOrder.Length; j++)
		{
			int num = -1;
			float num2 = 1f;
			int num3 = -1;
			for (int k = 0; k < typesAvailableToCollect.Count; k++)
			{
				float num4 = (float)resourcesStored.Get(typesAvailableToCollect.data[k]) / (float)resourceStorageMax.Get(typesAvailableToCollect.data[k]);
				if (num4 < num2)
				{
					num2 = num4;
					num = typesAvailableToCollect.data[k];
					num3 = k;
				}
			}
			gatherTypeOrder[j] = num;
			if (num3 != -1)
			{
				typesAvailableToCollect.RemoveAtSwap(num3);
			}
		}
	}

	private void TryConsume(int i)
	{
		int happinessModifierID = consumables[i].happinessModifierID;
		HappinessModifierSystem.inst.TryGetHappinessModifier(happinessModifierID, out var mod);
		ConsumableHappinessModifiers[happinessModifierID] = mod.negativeHappiness;
		int altHappinessModifierID = consumables[i].altHappinessModifierID;
		if (consumables[i].altType != -1)
		{
			HappinessModifierSystem.inst.TryGetHappinessModifier(altHappinessModifierID, out var mod2);
			ConsumableHappinessModifiers[altHappinessModifierID] = mod2.negativeHappiness;
		}
		consumablesAvailable[i] = resourcesStored.TrySubtract(consumables[i].type, 1);
		if (consumablesAvailable[i])
		{
			int num = mod.positiveHappiness;
			if (mod.id == 103 && TechnologyTree.inst.isFineWineUnlocked)
			{
				num += 3;
			}
			ConsumableHappinessModifiers[happinessModifierID] = num;
		}
		else if (consumables[i].altType != -1)
		{
			consumablesAvailable[i] = resourcesStored.TrySubtract(consumables[i].altType, 1);
			if (consumablesAvailable[i])
			{
				HappinessModifierSystem.inst.TryGetHappinessModifier(altHappinessModifierID, out var mod3);
				ConsumableHappinessModifiers[altHappinessModifierID] = mod3.positiveHappiness;
			}
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (updateFrame == currFrame % frameSpread)
		{
			int id = SeasonManager.GetCurrentSeason().id;
			if (b.IsBuilt())
			{
				float num = 1f;
				switch (DifficultyManager.inst.currOption.foodConsumption)
				{
				case 2:
					num = 1.25f;
					break;
				case 3:
					num = 1.5f;
					break;
				case 4:
					num = 1.75f;
					break;
				}
				float num2 = (float)frameSpread * dt * ((float)Residents.Count / (float)MaxResidents) * num;
				Governor governor = Player.inst.governors[b.LandMass()];
				if (governor != null)
				{
					Governor.TraitInstance trait = governor.GetTrait(Traits.FoodConsumption);
					if (trait != null)
					{
						num2 *= 1f + (trait.negative ? trait.magnitude : (0f - trait.magnitude));
					}
				}
				eatTime += num2;
				if (eatTime > eatTimeInterval && Residents.Count > 0)
				{
					eatTime -= eatTimeInterval;
					if (TryEat())
					{
						missedMeal = 0;
					}
					else if (missedMeal <= 1)
					{
						missedMeal++;
					}
					else if (missedMeal >= 2 && Creative.inst.IsCreativeOptionOn(2) && SRand.Range(0, 100) < 40)
					{
						Player.inst.TryAddStarvationDeath(Residents[SRand.Range(0, Residents.Count)]);
					}
				}
				if (Residents.Count > 0)
				{
					for (int i = 0; i < consumableTimers.Length; i++)
					{
						int type = consumables[i].type;
						float num3 = 1f;
						if (type == 3 && id == 2)
						{
							num3 *= 2f;
						}
						if (consumableTimers[i].Update(num2 * num3))
						{
							TryConsume(i);
						}
					}
				}
				RefreshBonuses();
				BuildGatherTypeOrder(LandMass(), typesAvailableToCollect, ref gatherTypeOrder, resourcesStored, resourceMaxStorage, gatherTypes);
				if (++residentSwapCounter >= 10)
				{
					residentSwapCounter = 0;
					TrySwapInCloserWorker();
				}
				if (Residents.Count > 0 && b.jobs.Count > 0)
				{
					int num4 = MaxResidents / b.jobs.Count;
					int num5 = 0;
					for (int j = 0; j < b.jobs.Count; j++)
					{
						if (b.jobs[j].HasEmployee())
						{
							num5++;
						}
					}
					if (Mathf.Min(Mathf.CeilToInt((float)Residents.Count / (float)num4), b.jobs.Count) - num5 != 0)
					{
						UpdateHomemakerAssignment();
					}
				}
				foodExists = false;
				for (int k = 0; k < diet.Length; k++)
				{
					if (resourcesStored.Get(diet[k].type) > 0 || resourcesStored.Get(diet[k].altType) > 0)
					{
						foodExists = true;
						break;
					}
				}
				int num6 = -1;
				for (int l = 0; l < consumablesAvailable.Length; l++)
				{
					if (!consumablesAvailable[l] && consumables[l].doMissingThought)
					{
						num6 = l;
						break;
					}
				}
				missingFood = -1;
				for (int m = 0; m < diet.Length; m++)
				{
					if (dietFilled[m] <= 0 && diet[m].doMissingThought)
					{
						missingFood = m;
					}
				}
				bool flag = false;
				for (int n = 0; n < b.jobs.Count; n++)
				{
					Villager employee = b.jobs[n].Employee;
					if (!(employee != null))
					{
						continue;
					}
					int carriedType = employee.GetCarriedType();
					if (carriedType == -1)
					{
						continue;
					}
					bool flag2 = false;
					for (int num7 = 0; num7 < diet.Length; num7++)
					{
						if (carriedType == diet[num7].type || carriedType == diet[num7].altType)
						{
							flag2 = true;
							break;
						}
					}
					if (missingFood != -1 && (carriedType == diet[missingFood].type || carriedType == diet[missingFood].altType))
					{
						missingFood = -1;
					}
					if (num6 != -1 && (carriedType == consumables[num6].type || carriedType == consumables[num6].altType))
					{
						num6 = -1;
					}
					if (flag2 && Mathff.DistSqrdXZ(employee.Pos, b.cachedPos) < 225f)
					{
						flag = true;
					}
				}
				bool flag3 = false;
				ThoughtBubbleSystem.Thought thought = b.thought.thought;
				if (Residents.Count > 0 && b.IsVisibleForFog())
				{
					if (!foodExists && !flag)
					{
						thought = ThoughtBubbleSystem.Thought.Food;
						flag3 = true;
						NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
						{
							single = ScriptLocalization.VillagerHungry
						};
						NotificationUI.TryNotify(NotificationUI.LowFoodGroup, -1, "foodshortage", message, NotificationStatus.Warning, 60f, b.Center(), title: false, b.LandMass());
					}
					else if (num6 != -1)
					{
						ThoughtBubbleSystem.Thought thoughtWhenMissing = FreeResourceSystem.inst.resourceDefMap[consumables[num6].type].thoughtWhenMissing;
						if (thoughtWhenMissing != ThoughtBubbleSystem.Thought.Satisfied)
						{
							bool flag4 = false;
							if (consumables[num6].type == 3 && (id == 3 || id == 0))
							{
								flag4 = true;
							}
							if (World.inst.GetVillagersForLandMass(LandMass()).Count < 50 && consumables[num6].type == 16)
							{
								flag4 = true;
							}
							if (!flag4)
							{
								thought = thoughtWhenMissing;
								flag3 = true;
							}
						}
					}
					else if (missingFood != -1)
					{
						ThoughtBubbleSystem.Thought thoughtWhenMissing2 = FreeResourceSystem.inst.resourceDefMap[diet[missingFood].type].thoughtWhenMissing;
						if (thoughtWhenMissing2 != ThoughtBubbleSystem.Thought.Satisfied)
						{
							thought = thoughtWhenMissing2;
							flag3 = true;
						}
					}
					if ((wantAqueduct && WaterConsumer.availableWaterPercentage <= 0f) || (!wantAqueduct && wellAccess <= 0f && WaterConsumer.availableWaterPercentage <= 0f))
					{
						waterTimer += (float)frameSpread * dt;
						if (waterTimer > 60f)
						{
							if (wantAqueduct)
							{
								if (World.inst.GetVillagersForLandMass(LandMass()).Count > 55)
								{
									thought = ThoughtBubbleSystem.Thought.Aqueduct;
									flag3 = true;
								}
							}
							else
							{
								thought = ThoughtBubbleSystem.Thought.Water;
								flag3 = true;
							}
						}
					}
					else
					{
						waterTimer = 0f;
					}
				}
				if (!flag3 && b.thought.thought != ThoughtBubbleSystem.Thought.Satisfied)
				{
					thought = ThoughtBubbleSystem.Thought.Satisfied;
					happyThought = 4f;
					flag3 = true;
				}
				b.thought.thought = thought;
				b.thought.visible = flag3;
			}
		}
		if (happyThought > 0f)
		{
			happyThought -= dt;
			if (happyThought <= 0f)
			{
				b.thought.visible = false;
			}
		}
		if (overlayType != OverlayType.None && overlayUpdateTimer.Update(dt))
		{
			if (overlayType == OverlayType.Happiness)
			{
				UpdateHappinessOverlayMaterial();
			}
			else if (overlayType == OverlayType.Health)
			{
				UpdateHealthOverlayMaterial();
			}
		}
		if (!b.IsBuilt() || !taxTimer.Update(dt))
		{
			return;
		}
		float taxRate = GetTaxRate();
		if (taxRate > 0f)
		{
			float num8 = taxRate * taxYield * ((float)Residents.Count / (float)MaxResidents);
			num8 *= GetGovernorTaxMod();
			taxRev += num8;
			if (taxRev >= 1f)
			{
				int num9 = Mathf.RoundToInt(taxRev);
				World.GetLandmassOwner(b.LandMass()).Gold += num9;
				taxRev -= num9;
			}
		}
	}

	private static bool HasCommute(Villager v)
	{
		if (v.job != null && !v.job.idleJob)
		{
			return v.job.employer.GetStartHour() != -1f;
		}
		return false;
	}

	private void TrySwapInCloserWorker()
	{
		if (b.isDemolishing)
		{
			return;
		}
		Vector3 position = GetPosition();
		bool flag = GetAvailableResidentialSlots() <= 0;
		int num = LandMass();
		Villager villager = null;
		Villager villager2 = null;
		float num2 = 3f;
		int num3 = (int)position.x;
		int num4 = (int)position.z;
		int num5 = Mathff.Clamp(num3 - 5, 0, World.inst.GridWidth - 1);
		int num6 = Mathff.Clamp(num3 + 5, 0, World.inst.GridWidth - 1);
		int num7 = Mathff.Clamp(num4 - 5, 0, World.inst.GridHeight - 1);
		int num8 = Mathff.Clamp(num4 + 5, 0, World.inst.GridHeight - 1);
		swapScannedEmployers.Clear();
		for (int i = num7; i <= num8; i++)
		{
			for (int j = num5; j <= num6; j++)
			{
				List<Building> occupyingStructure = World.inst.GetCellDataUnsafe(j, i).OccupyingStructure;
				for (int k = 0; k < occupyingStructure.Count; k++)
				{
					Building building = occupyingStructure[k];
					if (building == b || building.jobs.Count == 0 || building.LandMass() != num || !swapScannedEmployers.Add(building) || building.GetStartHour() == -1f)
					{
						continue;
					}
					Vector3 position2 = building.GetPosition();
					float num9 = Mathf.Sqrt(Mathff.DistSqrdXZ(position, position2));
					for (int l = 0; l < building.jobs.Count; l++)
					{
						Job job = building.jobs[l];
						Villager employee = job.Employee;
						if (!job.HasEmployee() || job.idleJob || !(employee.Residence is Home home) || (object)home == this || employee.sick)
						{
							continue;
						}
						Vector3 position3 = home.GetPosition();
						float num10 = Mathff.DistSqrdXZ(position3, position2);
						if (num10 <= Mathff.Sqr(num9 + num2))
						{
							continue;
						}
						Villager villager3 = null;
						if (flag)
						{
							villager3 = FindResidentWillingToMove(position3, position);
							if (villager3 == null)
							{
								continue;
							}
						}
						villager = employee;
						villager2 = villager3;
						num2 = Mathf.Sqrt(num10) - num9;
					}
				}
			}
		}
		if (!(villager == null))
		{
			if (villager2 != null)
			{
				Player.inst.SwapResidents(villager.Residence, this, villager, villager2);
				return;
			}
			villager.Residence.RemoveResident(villager);
			AddResident(villager);
			villager.ResetTiredness();
			villager.ResetCommute();
		}
	}

	private Villager FindResidentWillingToMove(Vector3 newHomePos, Vector3 homePos)
	{
		for (int i = 0; i < Residents.Count; i++)
		{
			Villager villager = Residents[i];
			if ((villager.job == null || villager.job.employer != this) && (!HasCommute(villager) || Mathff.DistSqrdXZ(newHomePos, villager.job.employer.GetPosition()) <= Mathff.DistSqrdXZ(homePos, villager.job.employer.GetPosition())))
			{
				return villager;
			}
		}
		return null;
	}

	private float GetGovernorTaxMod()
	{
		Governor governor = Player.inst.governors[b.LandMass()];
		if (governor != null)
		{
			Governor.TraitInstance trait = governor.GetTrait(Traits.TaxRevenues);
			if (trait != null)
			{
				return 1f + (trait.negative ? (0f - trait.magnitude) : trait.magnitude);
			}
		}
		return 1f;
	}

	internal void RefreshBonuses()
	{
		if (!b.IsBuilt())
		{
			return;
		}
		wellAccess = 0f;
		HappinessBonuses.Clear();
		MaxHappinessObserved.Clear();
		TileHappinessModifiers.Clear();
		rMaxBonus.Clear();
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		Vector3 p = default;
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				p.x = (float)j + 0.5f;
				p.y = 0f;
				p.z = (float)i + 0.5f;
				CellInfluence cellInfluenceDataClamped = World.inst.GetCellInfluenceDataClamped(j, i);
				int k = 0;
				for (int num = cellInfluenceDataClamped.radiusBonuses.Count; k < num; k++)
				{
					RadiusBonus radiusBonus = cellInfluenceDataClamped.radiusBonuses.data[k];
					if ((ExcludeTileHappinessModifiers != null && ExcludeTileHappinessModifiers.Contains(radiusBonus.residentialTileID)) || (radiusBonus.residentialTileID == 202 && (radiusBonus.b == b || !wantsNeighbors)))
					{
						continue;
					}
					int residentialTileID = radiusBonus.residentialTileID;
					int currentHappiness = radiusBonus.GetCurrentHappiness();
					if (MaxHappinessObserved.TryGetValue(residentialTileID, out var value))
					{
						if (Mathf.Abs(value) < Mathf.Abs(currentHappiness))
						{
							MaxHappinessObserved[residentialTileID] = currentHappiness;
						}
					}
					else
					{
						MaxHappinessObserved.Add(residentialTileID, currentHappiness);
					}
					int radialHappiness = radiusBonus.GetRadialHappiness(p);
					if (rMaxBonus.TryGetValue(radiusBonus, out var value2))
					{
						if (Mathff.Abs(radialHappiness) > Mathff.Abs(value2))
						{
							rMaxBonus[radiusBonus] = radialHappiness;
						}
					}
					else
					{
						rMaxBonus.Add(radiusBonus, radialHappiness);
					}
				}
				float protection = WellManager.inst.GetProtection(j, i);
				if (protection > wellAccess)
				{
					wellAccess = protection;
				}
			}
		}
		foreach (KeyValuePair<RadiusBonus, int> rMaxBonu in rMaxBonus)
		{
			if (rMaxBonu.Value == 0)
			{
				continue;
			}
			int residentialTileID2 = rMaxBonu.Key.residentialTileID;
			int num2 = MaxHappinessObserved[residentialTileID2];
			if (TileHappinessModifiers.TryGetValue(residentialTileID2, out var value3))
			{
				int num3 = value3 + rMaxBonu.Value;
				if (Mathff.Abs(num3) > Mathff.Abs(num2))
				{
					TileHappinessModifiers[residentialTileID2] = num2;
				}
				else
				{
					TileHappinessModifiers[residentialTileID2] = num3;
				}
			}
			else
			{
				TileHappinessModifiers.Add(residentialTileID2, (Mathff.Abs(rMaxBonu.Value) > Mathff.Abs(num2)) ? num2 : rMaxBonu.Value);
			}
		}
		if (wantsNeighbors && !TileHappinessModifiers.ContainsKey(202))
		{
			HappinessModifierSystem.inst.TryGetNegativeHappiness(202, out var happinessMod);
			TileHappinessModifiers.Add(202, happinessMod);
		}
		if (!TileHappinessModifiers.ContainsKey(201))
		{
			HappinessModifierSystem.inst.TryGetNegativeHappiness(201, out var happinessMod2);
			TileHappinessModifiers.Add(201, happinessMod2);
		}
		if (nearWater)
		{
			HappinessModifierSystem.inst.TryGetPositiveHappiness(203, out var happinessMod3);
			TileHappinessModifiers.TryAdd(203, happinessMod3);
		}
		float num4 = b.Life / b.ModifiedMaxLife;
		if (num4 <= startDamageHappinessDebuf)
		{
			if (num4 <= startDamageHappinessDebuf - 0.2f)
			{
				TileHappinessModifiers.TryAdd(238, -30);
			}
			if (num4 <= startDamageHappinessDebuf - 0.1f)
			{
				TileHappinessModifiers.TryAdd(238, -20);
			}
			else
			{
				TileHappinessModifiers.TryAdd(238, -10);
			}
		}
	}

	public Vector3 GetPosition()
	{
		return b.Center();
	}

	public TransformData GetPositionForPerson(Villager person)
	{
		int num = -1;
		int i = 0;
		for (int num2 = Residents.Count; i < num2; i++)
		{
			if (Residents[i].guid == person.guid)
			{
				num = i;
				break;
			}
		}
		if (num >= 0 && num < b.personPositions.Length)
		{
			return new TransformData
			{
				position = b.personPositions[num].position
			};
		}
		return new TransformData
		{
			position = transform.position
		};
	}

	public int GetAvailableResidentialSlots()
	{
		return MaxResidents - Residents.Count;
	}

	public int GetTotalResidentialSlots()
	{
		return MaxResidents;
	}

	private void UpdateLifeDetritus()
	{
		if ((bool)lifeDetritus)
		{
			int num = (int)((float)Residents.Count / (float)MaxResidents * (float)lifeDetritus.childCount);
			for (int i = 0; i < lifeDetritus.childCount; i++)
			{
				lifeDetritus.GetChild(i).gameObject.SetActive(i < num);
			}
		}
	}

	public void AddResident(Villager person)
	{
		if (Residents.Count == 0)
		{
			b.SetLights(1f);
		}
		if (Residents.Count < MaxResidents)
		{
			Residents.Add(person);
			person.Residence = this;
		}
		UpdateLifeDetritus();
	}

	public void RemoveResident(Villager person)
	{
		Residents.Remove(person);
		if (Residents.Count == 0)
		{
			b.SetLights(0f);
		}
		UpdateLifeDetritus();
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i].Employee == person)
			{
				person.QuitJob();
			}
		}
		UpdateHomemakerAssignment();
	}

	public void UpdateHomemakerAssignment()
	{
		if (!b.IsBuilt())
		{
			return;
		}
		List<Job> jobs = b.jobs;
		if (jobs.Count == 0)
		{
			return;
		}
		openHomemakerJobs.Clear();
		int num = MaxResidents / jobs.Count;
		int num2 = 0;
		for (int i = 0; i < jobs.Count; i++)
		{
			if (jobs[i].HasEmployee())
			{
				num2++;
			}
			else
			{
				openHomemakerJobs.Add(jobs[i]);
			}
		}
		if (Residents.Count == 0)
		{
			if (num2 > 0)
			{
				Debug.LogError("Resident count is 0, but jobs are still assigned to someone?");
			}
			return;
		}
		int num3 = Mathf.Min(Mathf.CeilToInt((float)Residents.Count / (float)num), jobs.Count);
		int num4 = Math.Max(0, num3 - num2);
		for (int j = 0; j < Residents.Count && num4 > 0; j++)
		{
			Villager villager = Residents[j];
			if (villager.job is FireFighterVolunteer || villager.job is ConscriptedJob || villager.sick)
			{
				continue;
			}
			if (villager.job != null)
			{
				bool flag = false;
				for (int k = 0; k < jobs.Count; k++)
				{
					if (jobs[k].Employee == villager)
					{
						flag = true;
						break;
					}
				}
				if (flag)
				{
					continue;
				}
				villager.QuitJob(updateplacement: false);
			}
			Job job = openHomemakerJobs[0];
			openHomemakerJobs.RemoveAt(0);
			job.AssignEmployee(villager);
			num4--;
		}
		if (num4 >= 0)
		{
			return;
		}
		for (int l = num4; l < 0; l++)
		{
			for (int m = 0; m < jobs.Count; m++)
			{
				if (jobs[m].HasEmployee())
				{
					jobs[m].Employee.QuitJob();
					break;
				}
			}
		}
	}

	public bool Open()
	{
		if (b.IsBuilt())
		{
			return !b.isDemolishing;
		}
		return false;
	}

	private void OnBuilt()
	{
		if (HappinessUI.inst.overlayOn)
		{
			ShowOverlay(OverlayType.Happiness);
		}
		if (HealthUI.inst.overlayOn)
		{
			ShowOverlay(OverlayType.Health);
		}
		BuildGatherTypeOrder(LandMass(), typesAvailableToCollect, ref gatherTypeOrder, resourcesStored, resourceMaxStorage, gatherTypes);
	}

	private void OnBuildingPlacement(bool undo)
	{
		b.thought.pos = b.Center();
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		int num = Mathff.Clamp(minX - 1, 0, World.inst.GridWidth - 1);
		int num2 = Mathff.Clamp(maxX + 1, 0, World.inst.GridWidth - 1);
		int num3 = Mathff.Clamp(minZ - 1, 0, World.inst.GridHeight - 1);
		int num4 = Mathff.Clamp(maxZ + 1, 0, World.inst.GridHeight - 1);
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num; j <= num2; j++)
			{
				if (World.inst.GetCellDataUnsafe(j, i).Type == TerrainType.Water)
				{
					nearWater = true;
					break;
				}
			}
			if (nearWater)
			{
				break;
			}
		}
	}

	public bool TryEatType(int t)
	{
		if (resourcesStored.Get(t) > 0)
		{
			resourcesStored.Add(t, -1);
			return true;
		}
		return false;
	}

	public bool TryEat()
	{
		if (!Creative.inst.IsCreativeOptionOn(1))
		{
			for (int i = 0; i < dietFilled.Length; i++)
			{
				dietFilled[i] = 2;
			}
			return true;
		}
		if (DifficultyManager.inst.currOption.foodConsumption == 0)
		{
			int num = currEatIdx;
			for (int j = 0; j < diet.Length; j++)
			{
				bool flag = resourcesStored.Get(diet[j].type) > 0 || resourcesStored.Get(diet[j].altType) > 0;
				if ((dietFilled[j] < 1) & flag)
				{
					num = j;
					if (dietFilled[j] == -1)
					{
						break;
					}
				}
			}
			if (num == currEatIdx)
			{
				currEatIdx = (currEatIdx + 1) % diet.Length;
			}
			if (resourcesStored.Get(diet[num].type) > 0)
			{
				dietFilled[num] = 2;
			}
			else if (diet[num].altType != -1 && resourcesStored.Get(diet[num].altType) > 0)
			{
				dietFilled[num] = 1;
			}
			return true;
		}
		int num2 = currEatIdx;
		for (int k = 0; k < diet.Length; k++)
		{
			bool flag2 = resourcesStored.Get(diet[k].type) > 0 || resourcesStored.Get(diet[k].altType) > 0;
			if ((dietFilled[k] < 1) & flag2)
			{
				num2 = k;
				if (dietFilled[k] == -1)
				{
					break;
				}
			}
		}
		if (num2 == currEatIdx)
		{
			currEatIdx = (currEatIdx + 1) % diet.Length;
		}
		if (TryEatType(diet[num2].type))
		{
			dietFilled[num2] = 2;
		}
		else if (diet[num2].altType != -1 && TryEatType(diet[num2].altType))
		{
			dietFilled[num2] = 1;
		}
		else
		{
			bool flag3 = false;
			for (int l = 0; l < diet.Length; l++)
			{
				if (TryEatType(diet[l].type))
				{
					flag3 = true;
					break;
				}
			}
			if (!flag3)
			{
				for (int m = 0; m < diet.Length; m++)
				{
					if (diet[m].altType != -1 && TryEatType(diet[m].altType))
					{
						flag3 = true;
						break;
					}
				}
			}
			dietFilled[num2] = ((!flag3) ? (-1) : 0);
		}
		return dietFilled[num2] != -1;
	}

	public void Deposit(ref ResourceAmount resources)
	{
		ResourceStatistics.AddConsumption(LandMass(), "home", resources);
		resourcesStored.Add(in resources);
		resources.Clear();
		for (int i = 0; i < consumablesAvailable.Length; i++)
		{
			if (!consumablesAvailable[i] && (resourcesStored.Get(consumables[i].type) >= 1 || resourcesStored.Get(consumables[i].altType) >= 1))
			{
				TryConsume(i);
			}
		}
		if (missedMeal > 0 && TryEat())
		{
			missedMeal = 0;
			eatTime = 0f;
		}
		if (diet.Length == 0 || consumables.Length == 0)
		{
			return;
		}
		bool flag = true;
		for (int j = 0; j < dietFilled.Length; j++)
		{
			if (dietFilled[j] <= 0)
			{
				flag = false;
				break;
			}
		}
		if (flag)
		{
			for (int k = 0; k < consumablesAvailable.Length; k++)
			{
				if (!consumablesAvailable[k])
				{
					flag = false;
					break;
				}
			}
		}
		if (flag)
		{
			MilestoneManager.inst.TryFoodOmnivoreMilestone();
		}
	}

	int IResourceStorageBase.SpaceAvailable(int resourceID)
	{
		return resourceMaxStorage.Get(resourceID) - resourcesStored.Get(resourceID);
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceID)
	{
		return b.personPositions[0].position;
	}

	bool IEmployer.IsOpen()
	{
		return true;
	}

	void IEmployer.OnAssigned(Villager p)
	{
	}

	void IEmployer.OnUnAssigned(Villager p)
	{
	}

	void IEmployer.OnJobRemoved(Job j)
	{
	}

	string IEmployer.GetUsedSkill()
	{
		return "";
	}

	public List<Villager> GetResidents()
	{
		return Residents;
	}
}
