using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Interface;
using UnityEngine;

[RequireComponent(typeof(AIIntentionManager))]
[RequireComponent(typeof(LandmassOwner))]
public class AIKingdom : MonoBehaviour
{
	public enum SkillLevel
	{
		Low,
		Medium,
		High,
		VeryHigh
	}

	public enum RulerPersonality
	{
		Anxious,
		Playful,
		Aggressive,
		MaxNum
	}

	public struct BaseStartCellInfo(float s, Cell c)
	{
		public float score = s;

		public Cell cell = c;
	}

	[Serializable]
	public class AIKingdomSaveData : SaveClass<AIKingdom, AIKingdomSaveData>
	{
		private LandmassOwner.LandmassOwnerSaveData landmassOwnerSaveData = new LandmassOwner.LandmassOwnerSaveData();

		private AILayout.AILayoutSaveData layoutData = new AILayout.AILayoutSaveData();

		private AIPersonality personality;

		private string personalityKey;

		private int rivalCode;

		private bool hasPlayerVisitedKeep;

		private bool doneIntroConvo;

		private int globalThreatLevel;

		private bool allowLibraries;

		private float audienceTimer;

		private float flavorChatTimer;

		private List<string> flavorConvos;

		private int FavoriteFood;

		private int headIdx;

		private int diplomacyPoints;

		private bool didAbdicate;

		private AIUnitControlSystem.AIUnitControlSystemData unitControlSaveData = new AIUnitControlSystem.AIUnitControlSystemData();

		private Intention_ManageDiplomacy.ManageDiplomacySaveData diplomacySaveData = new Intention_ManageDiplomacy.ManageDiplomacySaveData();

		private Intention_ManageTrade.ManagTradeSaveData tradeSaveData = new Intention_ManageTrade.ManagTradeSaveData();

		private Intention_WallDefense.WallDefenseSaveData wallDefenseSaveData = new Intention_WallDefense.WallDefenseSaveData();

		private Intention_ManageTrade.ManagTradeSaveData[] tradeSaveDataArray;

		private object missionData;

		private bool didFlavor;

		private string lastName;

		private int lastGiftGivenYear;

		private List<int> happinessRollingAvg;

		private Intention_ManageDiplomacyAI.ManageDiplomacyAISaveData diplomacyAISaveData = new Intention_ManageDiplomacyAI.ManageDiplomacyAISaveData();

		private Intention_InfrastructureDefense.InfrastructureDefenseSaveData infrastructureDefense = new Intention_InfrastructureDefense.InfrastructureDefenseSaveData();

		private RulerPersonality rulerPersonality;

		private int LeastFavoriteFood;

		private Intention_ManageInvasion.ManageInvasionSaveData[] invasionSaveDataArray;

		private Dictionary<int, float> atLowResourceTime;

		private SkillLevel skillLevel;

		private int damagePoints;

		private int enemyPoints;

		private bool didEnemyWarning;

		public override AIKingdomSaveData Pack(AIKingdom v)
		{
			rivalCode = v.LandmassOwner.bannerIdx;
			landmassOwnerSaveData.Pack(v.LandmassOwner);
			layoutData.Pack(v.Layout);
			personalityKey = PersonalityCollection.GetKeyByType(v.personality.GetType());
			skillLevel = v.skillLevel;
			hasPlayerVisitedKeep = v.hasPlayerVisitedKeep;
			doneIntroConvo = v.doneIntroConvo;
			globalThreatLevel = v.globalThreatLevel;
			allowLibraries = v.allowLibraries;
			audienceTimer = v.audienceTimer;
			flavorChatTimer = v.flavorChatTimer;
			flavorConvos = v.flavorConvos;
			diplomacyPoints = v.diplomacyPoints;
			didAbdicate = v.didAbdicate;
			FavoriteFood = v.FavoriteFood;
			LeastFavoriteFood = v.LeastFavoriteFood;
			headIdx = v.headIdx;
			unitControlSaveData.Pack(v.unitControl);
			diplomacySaveData.Pack(v.manageDiplomacyIntention);
			diplomacyAISaveData.Pack(v.manageDiplomacyAIIntention);
			tradeSaveDataArray = new Intention_ManageTrade.ManagTradeSaveData[v.manageTradeIntentions.Length];
			for (int i = 0; i < tradeSaveDataArray.Length; i++)
			{
				tradeSaveDataArray[i] = new Intention_ManageTrade.ManagTradeSaveData().Pack(v.manageTradeIntentions[i]);
			}
			wallDefenseSaveData.Pack(v.maintainWallDefense);
			infrastructureDefense.Pack(v.infrastructureDefenseIntention);
			if (v.currMission is DefendVikingsRequest)
			{
				missionData = new DefendVikingsRequest.SaveData().Pack(v.currMission as DefendVikingsRequest);
			}
			else if (v.currMission is ClearWolvesRequest)
			{
				missionData = new ClearWolvesRequest.SaveData().Pack(v.currMission as ClearWolvesRequest);
			}
			else if (v.currMission is BuildingResourceRequest)
			{
				missionData = new BuildingResourceRequest.SaveData().Pack(v.currMission as BuildingResourceRequest);
			}
			didFlavor = v.didFlavor;
			lastName = v.lastName;
			lastGiftGivenYear = v.lastGiftGivenYear;
			happinessRollingAvg = v.happinessRollingAvg;
			rulerPersonality = v.rulerPersonality;
			invasionSaveDataArray = new Intention_ManageInvasion.ManageInvasionSaveData[v.manageInvasionIntentions.Length];
			for (int j = 0; j < invasionSaveDataArray.Length; j++)
			{
				invasionSaveDataArray[j] = new Intention_ManageInvasion.ManageInvasionSaveData().Pack(v.manageInvasionIntentions[j]);
			}
			atLowResourceTime = v.atLowResourceTime;
			damagePoints = v.damagePoints;
			enemyPoints = v.enemyPoints;
			didEnemyWarning = v.didEnemyWarning;
			return this;
		}

		public AIKingdom UnpackPrePlayer(AIKingdom v)
		{
			v.SetupReferences();
			landmassOwnerSaveData.Unpack(v.LandmassOwner);
			v.LandmassOwner.SetBannerIdx(rivalCode);
			return v;
		}

		public override AIKingdom Unpack(AIKingdom v)
		{
			v.hasPlayerVisitedKeep = hasPlayerVisitedKeep;
			v.doneIntroConvo = doneIntroConvo;
			if (personalityKey == null)
			{
				v.personality = new ByTheBookPersonality();
			}
			else
			{
				v.personality = (AIPersonality)Activator.CreateInstance(PersonalityCollection.GetTypeByKey(personalityKey));
			}
			v.Layout = new AILayout();
			v.InitPersonality();
			v.skillLevel = skillLevel;
			v.globalThreatLevel = globalThreatLevel;
			v.allowLibraries = allowLibraries;
			v.audienceTimer = audienceTimer;
			v.flavorChatTimer = flavorChatTimer;
			v.flavorConvos = flavorConvos;
			v.diplomacyPoints = diplomacyPoints;
			v.didAbdicate = didAbdicate;
			v.FavoriteFood = FavoriteFood;
			v.LeastFavoriteFood = LeastFavoriteFood;
			v.headIdx = headIdx;
			v.didFlavor = didFlavor;
			v.lastName = lastName;
			v.lastGiftGivenYear = lastGiftGivenYear;
			v.happinessRollingAvg = happinessRollingAvg;
			if (v.happinessRollingAvg == null)
			{
				v.happinessRollingAvg = new List<int>();
			}
			v.rulerPersonality = rulerPersonality;
			layoutData.Unpack(v.Layout, v);
			v.StartBaseIntentions();
			if (unitControlSaveData != null)
			{
				unitControlSaveData.Unpack(v.unitControl);
			}
			if (diplomacySaveData != null)
			{
				diplomacySaveData.Unpack(v.manageDiplomacyIntention);
			}
			if (diplomacyAISaveData != null)
			{
				diplomacyAISaveData.Unpack(v.manageDiplomacyAIIntention);
			}
			if (tradeSaveDataArray != null)
			{
				for (int i = 0; i < tradeSaveDataArray.Length; i++)
				{
					tradeSaveDataArray[i].Unpack(v.manageTradeIntentions[i]);
				}
			}
			if (wallDefenseSaveData != null)
			{
				wallDefenseSaveData.Unpack(v.maintainWallDefense);
			}
			if (infrastructureDefense != null)
			{
				infrastructureDefense.Unpack(v.infrastructureDefenseIntention);
			}
			if (missionData is DefendVikingsRequest.SaveData)
			{
				v.currMission = new DefendVikingsRequest(v);
				(missionData as DefendVikingsRequest.SaveData).Unpack(v.currMission as DefendVikingsRequest);
			}
			else if (missionData is ClearWolvesRequest.SaveData)
			{
				v.currMission = new ClearWolvesRequest(v);
				(missionData as ClearWolvesRequest.SaveData).Unpack(v.currMission as ClearWolvesRequest);
			}
			else if (missionData is BuildingResourceRequest.SaveData)
			{
				v.currMission = new BuildingResourceRequest(v);
				(missionData as BuildingResourceRequest.SaveData).Unpack(v.currMission as BuildingResourceRequest);
			}
			if (invasionSaveDataArray != null)
			{
				for (int j = 0; j < invasionSaveDataArray.Length; j++)
				{
					invasionSaveDataArray[j].Unpack(v.manageInvasionIntentions[j]);
				}
			}
			v.atLowResourceTime = atLowResourceTime;
			if (v.atLowResourceTime == null)
			{
				v.atLowResourceTime = new Dictionary<int, float>();
			}
			v.damagePoints = damagePoints;
			v.enemyPoints = enemyPoints;
			v.didEnemyWarning = didEnemyWarning;
			return v;
		}
	}

	private static Dictionary<int, AIKingdom> aiOnLandmass;

	public AIPersonality personality;

	public ResourceAmount CurrentResources;

	internal int headIdx = -1;

	public int FavoriteFood;

	public int LeastFavoriteFood = 9;

	public List<string> flavorConvos = new List<string>();

	public int diplomacyPoints;

	public bool didAbdicate;

	public int enemyPoints;

	public bool didEnemyWarning;

	public float audienceTimer;

	public float flavorChatTimer;

	public Intention_EnoughFood enoughFoodIntention;

	public Intention_EnoughResidential enoughFoodResidential;

	public Intention_EnoughCharcoal enoughCharcoal;

	public Intention_CollectWood collectWoodIntention;

	public Intention_CollectStone collectStoneIntention;

	public Intention_CollectIron collectIronIntention;

	public Intention_GenerateGold generateGoldIntention;

	public Intention_ManageTrade[] manageTradeIntentions;

	public Intention_ManageInvasion[] manageInvasionIntentions;

	public Intention_FillShallowWater fillShallowWaterIntention;

	public Intention_BuildDrawbridges buildDrawbridgesIntention;

	public Intention_MakeFishingHuts makeFishingHutsIntention;

	public Intention_ManageWaterSystem manageWaterSystem;

	public Intention_MakeTools makeToolsIntention;

	public Intention_ManageArmies manageArmiesIntention;

	public Intention_InfrastructureDefense infrastructureDefenseIntention;

	public Intention_ManageDiplomacy manageDiplomacyIntention;

	public Intention_ManageDiplomacyAI manageDiplomacyAIIntention;

	public Intention_ManageDiplomacyInfrastructure manageDiplomacyInfrastructure;

	public Intention_ManageTransportShips manageTransportShips;

	public Intention_BuildingUpkeep buildingUpkeepIntention;

	public Intention_WallDefense maintainWallDefense;

	public Intention_ManageRoads manageRoadsIntention;

	public Intention_FoodDistribution manageFoodDistribution;

	public Intention_ClearObstructions clearObstructions;

	public Intention_BuildDock buildDock;

	public Intention_BuildBakeries buildBakeries;

	public Intention_BuildGreatHall buildGreatHall;

	public AIUnitControlSystem unitControl;

	[NonSerialized]
	public bool hasPlayerVisitedKeep;

	[NonSerialized]
	public bool doneIntroConvo;

	[NonSerialized]
	public bool didFlavor = true;

	internal string lastName;

	internal int lastGiftGivenYear;

	internal bool avoidPlacingResidentialOnFertile = true;

	internal bool avoidPlacingForesterOnLand = true;

	internal bool avoidPlacingGravesOnFertile = true;

	[NonSerialized]
	public SkillLevel skillLevel = SkillLevel.Medium;

	[NonSerialized]
	public RulerPersonality rulerPersonality;

	private Dictionary<int, float> atLowResourceTime = new Dictionary<int, float>();

	public ResourceAmount frameRequestedResources = new ResourceAmount();

	public ResourceAmount lastFrameRequestedResources = new ResourceAmount();

	private List<GameObject> flattenedIntentionHierarchy = new List<GameObject>();

	private List<Intention_CaptureResource> resourceCaptures = new List<Intention_CaptureResource>();

	public int globalThreatLevel = 1;

	private const int MAX_THREAT = 5;

	private const int THREAT_EVERY_X_YEARS = 10;

	public const int BUILD_WALLS_AT_YEAR = 35;

	public bool allowLibraries = true;

	[NonSerialized]
	public bool tookDamageFromLastInvasion;

	public Mission currMission;

	public Mission potentialMission;

	private EventHandler<OnBuildingAddRemove> buildingAddRemove;

	internal int damagePoints;

	private List<GameObject> shipsToDestroy = new List<GameObject>();

	private List<int> happinessRollingAvg = new List<int>(10);

	public LandmassOwner LandmassOwner;

	public AIIntentionManager IntentionManager;

	public AILayout Layout;

	private Timer cheatTimer = new Timer(150f);

	private float generateMissionTimer;

	public bool drawDebug;

	private const int SEARCH_RADIUS = 4;

	public static AIKingdom GetKingdomByLandmass(int lm)
	{
		AIKingdom value = null;
		if (aiOnLandmass != null)
		{
			aiOnLandmass.TryGetValue(lm, out value);
		}
		return value;
	}

	public static void ClearLandmassMap()
	{
		if (aiOnLandmass != null)
		{
			aiOnLandmass.Clear();
		}
	}

	public static void AddToLandmassMap(int lm, AIKingdom k)
	{
		aiOnLandmass[lm] = k;
	}

	public int GetEnemyPointsForWarning()
	{
		if (rulerPersonality == RulerPersonality.Aggressive)
		{
			return 15;
		}
		if (rulerPersonality == RulerPersonality.Playful)
		{
			return 20;
		}
		if (rulerPersonality == RulerPersonality.Anxious)
		{
			return 30;
		}
		return 999;
	}

	private bool IsFlavorConvoValid(string s, bool aiVisitingUs)
	{
		bool result = true;
		if (s == "FlavorStatue" && !Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(World.statueName, mustBeBuilt: true))
		{
			result = false;
		}
		else if (s == "FlavorGarden" && !Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(World.gardenName, mustBeBuilt: true))
		{
			result = false;
		}
		else if (s == "FlavorTheater" && !Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(World.theaterName, mustBeBuilt: true))
		{
			result = false;
		}
		else if ((s == "FlavorBath" || s == "FlavorBathRules") && !Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(World.bathhouseName, mustBeBuilt: true))
		{
			result = false;
		}
		else if (s == "FlavorEventOffensiveStatue" && !Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("statue_sam", mustBeBuilt: true) && !Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("statue_smalldragon", mustBeBuilt: true))
		{
			result = false;
		}
		else if (s == "FlavorEventTavern" && !Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(World.tavernName, mustBeBuilt: true))
		{
			result = false;
		}
		else if (s == "FlavorEventJousting" && (!Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(World.joustingArenaName, mustBeBuilt: true) || !aiVisitingUs))
		{
			result = false;
		}
		else if (s == "FlavorEventSickDiplomat" && !aiVisitingUs)
		{
			result = false;
		}
		return result;
	}

	public bool HasValidFlavor(bool aiVisitingUs)
	{
		for (int i = 0; i < flavorConvos.Count; i++)
		{
			if (IsFlavorConvoValid(flavorConvos[i], aiVisitingUs))
			{
				return true;
			}
		}
		return false;
	}

	public string GetFlavorConvo(bool aiVisitingUs)
	{
		int index = SRand.Range(0, flavorConvos.Count);
		string text = flavorConvos[index];
		int num = 20;
		bool flag = true;
		do
		{
			flag = IsFlavorConvoValid(text, aiVisitingUs);
			if (!flag)
			{
				index = SRand.Range(0, flavorConvos.Count);
				text = flavorConvos[index];
				num--;
			}
		}
		while (!flag && num > 0);
		if (!flag)
		{
			index = SRand.Range(0, flavorConvos.Count);
			text = flavorConvos[index];
		}
		flavorConvos.RemoveAt(index);
		return text;
	}

	public bool AtLowResources(int t, int threshold)
	{
		if ((lastFrameRequestedResources.Get(t) > CurrentResources.Get(t) || CurrentResources.Get(t) < threshold) && CurrentResources.Get(t) < 200)
		{
			return true;
		}
		return false;
	}

	public bool AtLowResourcesExtended(int t)
	{
		return atLowResourceTime[t] >= 120f;
	}

	public void UpdateResourceAllocation()
	{
		frameRequestedResources.Clear();
		CurrentResources = Player.inst.resourcesPerLandmass[Layout.LandMass];
		resourceCaptures.Clear();
		IntentionManager.GetComponentsInChildren(resourceCaptures);
		for (int i = 0; i < resourceCaptures.Count; i++)
		{
			if (!resourceCaptures[i].Done && !resourceCaptures[i].Ignore)
			{
				ResourceAmount resourceAmount = ResourcesTryCapture(resourceCaptures[i].amountToCollect);
				resourceCaptures[i].ResourceCollected = resourceAmount >= resourceCaptures[i].amountToCollect;
			}
		}
	}

	public void AddThreat(int amt = 1)
	{
		globalThreatLevel = Mathff.Clamp(globalThreatLevel + amt, 1, GetMaxThreat());
	}

	public int GetMaxThreat()
	{
		return Mathff.Min(Mathff.Max(1, (SeasonManager.inst.CurrentYear() - 35) / 10), 5);
	}

	public bool IsWolfMissionPotentialOrActive()
	{
		if (!(potentialMission is ClearWolvesRequest))
		{
			if (currMission is ClearWolvesRequest clearWolvesRequest)
			{
				if (clearWolvesRequest.status != Mission.Status.InProgress)
				{
					return clearWolvesRequest.status == Mission.Status.NotStarted;
				}
				return true;
			}
			return false;
		}
		return true;
	}

	private Mission GeneratePotentialMission()
	{
		if (potentialMission is DefendVikingsRequest && RaiderSystem.inst.yearsUntilNextAttack <= 3)
		{
			potentialMission.Dispose();
			potentialMission = null;
		}
		if (potentialMission == null)
		{
			if (tookDamageFromLastInvasion && Player.inst.difficulty != Player.Difficulty.Peaceful && RaiderSystem.inst.yearsUntilNextAttack > 3)
			{
				potentialMission = new DefendVikingsRequest(this);
			}
			else
			{
				int num = ArmySystem.inst.UnitCount(LandmassOwner.teamId);
				if (SRand.Range(0, 100) > 50 && num <= 0 && World.inst.GetWolfDenCountPerLandmass(Layout.LandMass) >= 2)
				{
					potentialMission = new ClearWolvesRequest(this)
					{
						yearsRemain = 7
					};
				}
				else if (World.inst.GetVillagersForLandMass(Layout.LandMass).Count >= 50 && hasPlayerVisitedKeep)
				{
					Intention_BuildBuilding[] componentsInChildren = IntentionManager.GetComponentsInChildren<Intention_BuildBuilding>();
					Intention_BuildBuilding intention_BuildBuilding = null;
					float num2 = 0f;
					for (int i = 0; i < componentsInChildren.Length; i++)
					{
						if (componentsInChildren[i].Done || !componentsInChildren[i].initSuccess)
						{
							continue;
						}
						Building pendingBuilding = componentsInChildren[i].pendingBuilding;
						if ((bool)pendingBuilding && pendingBuilding.gameObject.activeSelf)
						{
							continue;
						}
						int uniqueNameHash = componentsInChildren[i].pendingBuilding.uniqueNameHash;
						int categoryHash = componentsInChildren[i].pendingBuilding.categoryHash;
						if (uniqueNameHash != World.orchardHash && uniqueNameHash != World.smallHouseHash && uniqueNameHash != World.farmHash && categoryHash != World.pathHash)
						{
							ResourceAmount cost = pendingBuilding.GetCost(componentsInChildren[i].LandMass);
							int num3 = cost.Get(1) + cost.Get(2) + cost.Get(4);
							if ((float)num3 > num2)
							{
								num2 = num3;
								intention_BuildBuilding = componentsInChildren[i];
							}
						}
					}
					if (intention_BuildBuilding != null)
					{
						ResourceAmount cost2 = intention_BuildBuilding.pendingBuilding.GetCost(intention_BuildBuilding.LandMass);
						potentialMission = new BuildingResourceRequest(this)
						{
							request = cost2,
							yearsRemain = 10,
							friendlyName = intention_BuildBuilding.pendingBuilding.FriendlyName
						};
					}
				}
			}
		}
		return potentialMission;
	}

	public void OnEnable()
	{
		buildingAddRemove = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		Broadcast.SeasonEvent.Listen(OnSeasonEvent);
		RaiderSystem inst = RaiderSystem.inst;
		inst.OnRaidStarted = (RaiderSystem.raidNotify)Delegate.Combine(inst.OnRaidStarted, new RaiderSystem.raidNotify(OnVikingRaidStarted));
	}

	public void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(BuildingAddRemove);
		Broadcast.SeasonEvent.Unlisten(OnSeasonEvent);
		RaiderSystem inst = RaiderSystem.inst;
		inst.OnRaidStarted = (RaiderSystem.raidNotify)Delegate.Remove(inst.OnRaidStarted, new RaiderSystem.raidNotify(OnVikingRaidStarted));
		unitControl.Shutdown();
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (Layout == null)
		{
			Debug.LogError("Building add/remove before layout init'd: " + obj.targetBuilding.UniqueName);
		}
		else if (obj.targetBuilding.LandMass() == Layout.LandMass && obj.added && obj.targetBuilding.categoryHash != World.pathHash && obj.targetBuilding.uniqueNameHash != World.rubbleHash)
		{
			Vector3 size = obj.targetBuilding.size;
			damagePoints -= (int)(size.x * size.z);
			if (damagePoints < 0)
			{
				damagePoints = 0;
			}
		}
	}

	public void GrantControlTo(LandmassOwner lmo)
	{
		Player.inst.CloseAllDocksInvolving(LandmassOwner);
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.keepHash);
		if (buildingListForLandMass.Count > 0 && buildingListForLandMass.data[0].Life > 0f)
		{
			buildingListForLandMass.data[0].GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
			World.inst.DemolishBuilding(buildingListForLandMass.data[0], reclaimResources: false);
			for (int i = minZ; i <= maxZ; i++)
			{
				for (int j = minX; j <= maxX; j++)
				{
					Building building = UnityEngine.Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(World.gardenName));
					building.transform.position = new Vector3(j, 0f, i);
					building.SetUpHashes();
					building.Init();
					World.inst.PlaceByAI(building);
				}
			}
		}
		Player.inst.SetTaxRate(Layout.LandMass, 1f);
		lmo.TakeOwnership(Layout.LandMass);
		Player.inst.RefreshVisibilityFor(Layout.LandMass, force: true);
		Player.inst.updateBanner?.Invoke();
		shipsToDestroy.Clear();
		for (int k = 0; k < ShipSystem.inst.ships.Count; k++)
		{
			ShipBase shipBase = ShipSystem.inst.ships.data[k];
			if (shipBase.teamID != LandmassOwner.teamId)
			{
				continue;
			}
			if (shipBase.type == ShipBase.ShipType.PlayerMerchant)
			{
				shipsToDestroy.Add(shipBase.gameObject);
				continue;
			}
			IMoveableUnit component = ShipSystem.inst.ships.data[k].GetComponent<IMoveableUnit>();
			if (component != null)
			{
				OrdersManager.inst.RemoveUnit(component);
			}
			shipBase.Init(lmo.teamId);
		}
		for (int l = 0; l < shipsToDestroy.Count; l++)
		{
			UnityEngine.Object.Destroy(shipsToDestroy[l]);
		}
		shipsToDestroy.Clear();
		ArrayExt<ArmySystem.Army> armies = ArmySystem.inst.armies;
		for (int m = 0; m < armies.Count; m++)
		{
			ArmySystem.Army army = armies.data[m];
			if (army.teamId == LandmassOwner.teamId)
			{
				if (army.locked)
				{
					OrdersManager.inst.DestroyUnit(army);
				}
				else
				{
					army.Disband();
				}
				m--;
			}
		}
		ArrayExt<Building> arrayExt = new ArrayExt<Building>(100);
		ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(Layout.LandMass);
		for (int n = 0; n < buildingListForLandMass2.Count; n++)
		{
			if (!buildingListForLandMass2.data[n].IsBuilt())
			{
				arrayExt.Add(buildingListForLandMass2.data[n]);
			}
			Barracks component2 = buildingListForLandMass2.data[n].GetComponent<Barracks>();
			if (component2 != null)
			{
				while (component2.pendingTraining > 0)
				{
					component2.CancelTraining();
				}
			}
			buildingListForLandMass2.data[n].UpdateMaterialSelection();
			buildingListForLandMass2.data[n].Open = true;
		}
		for (int num = 0; num < arrayExt.Count; num++)
		{
			World.inst.DemolishBuildingByAI(arrayExt.data[num]);
		}
		arrayExt.Clear();
		ArrayExt<Building> buildingListForLandMass3 = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.chamberOfWarHash);
		for (int num2 = 0; num2 < buildingListForLandMass3.Count; num2++)
		{
			World.inst.DemolishBuilding(buildingListForLandMass3.data[num2], reclaimResources: false);
		}
		Player.inst.CalcMaxResources(null);
		World.inst.RebakeCellsForLandmass(Layout.LandMass);
	}

	public void ShutdownKingdom()
	{
		ClearMission();
		if (potentialMission != null)
		{
			potentialMission.Dispose();
			potentialMission = null;
		}
		AIBrainsContainer.inst.kingdoms.Remove(this);
		for (int i = 0; i < AIBrainsContainer.inst.kingdoms.Count; i++)
		{
			AIKingdom aIKingdom = AIBrainsContainer.inst.kingdoms[i];
			Intention_ManageTrade[] array = aIKingdom.manageTradeIntentions;
			aIKingdom.manageTradeIntentions = new Intention_ManageTrade[array.Length - 1];
			Intention_ManageInvasion[] array2 = aIKingdom.manageInvasionIntentions;
			aIKingdom.manageInvasionIntentions = new Intention_ManageInvasion[array2.Length - 1];
			int num = 0;
			for (int j = 0; j < array.Length; j++)
			{
				if (array[j].foreignTeamId == LandmassOwner.teamId)
				{
					UnityEngine.Object.Destroy(array[j].gameObject);
					UnityEngine.Object.Destroy(array2[j].gameObject);
				}
				else
				{
					aIKingdom.manageTradeIntentions[num] = array[j];
					aIKingdom.manageInvasionIntentions[num] = array2[j];
					num++;
				}
			}
		}
	}

	private void OnSeasonEvent(object sender, SeasonEventData seasonEvent)
	{
		if (seasonEvent.SeasonDefinition.id == 0 && currMission != null)
		{
			currMission.OnNewYear();
		}
		if (happinessRollingAvg.Count > 7)
		{
			happinessRollingAvg.RemoveAt(0);
		}
		Player.HappinessInfo landmassHappiness = Player.inst.GetLandmassHappiness(Layout.LandMass);
		happinessRollingAvg.Add(landmassHappiness.currHappiness);
		if (seasonEvent.SeasonDefinition.id != 0 || GetMaxThreat() - globalThreatLevel <= 2)
		{
			return;
		}
		if (globalThreatLevel >= 3)
		{
			if (3 + (int)((float)CurrentResources.Get(2) * 0.025f) > globalThreatLevel)
			{
				AddThreat();
			}
			return;
		}
		int num = (int)((float)CurrentResources.Get(1) * 0.015f);
		if ((int)((float)CurrentResources.Get(2) * 0.01f) - num > 2)
		{
			AddThreat(4 - globalThreatLevel);
		}
		else if (num > globalThreatLevel)
		{
			AddThreat();
		}
	}

	public int GetHappinessRollingAvg()
	{
		if (happinessRollingAvg.Count != 0)
		{
			float num = 0f;
			float num2 = 0f;
			for (int i = 0; i < happinessRollingAvg.Count; i++)
			{
				float num3 = (float)i / (float)happinessRollingAvg.Count;
				float num4 = num3 * num3;
				num += (float)happinessRollingAvg[i] * num3;
				num2 += num4;
			}
			return (int)(num / num2);
		}
		return Player.inst.GetLandmassHappiness(Layout.LandMass).currHappiness;
	}

	private ResourceAmount ResourcesTryCapture(ResourceAmount amount)
	{
		ResourceAmount result = new ResourceAmount();
		ResourceAmount resourceAmount = CurrentResources - frameRequestedResources;
		for (int i = 0; i < resourceAmount.resources.Count; i++)
		{
			if (resourceAmount.resources[i].Amount < 0)
			{
				resourceAmount.resources[i].Amount = 0;
			}
		}
		if (resourceAmount >= amount)
		{
			result = amount;
		}
		frameRequestedResources.Add(in amount);
		if (amount.Get(1) > 0 && (bool)collectWoodIntention)
		{
			collectWoodIntention.SetNewGoalAmount(frameRequestedResources.Get(1));
		}
		if (amount.Get(2) > 0 && collectStoneIntention == null)
		{
			collectStoneIntention = IntentionManager.AddIntention<Intention_CollectStone>("always collect stone");
			collectStoneIntention.Init();
		}
		if (amount.Get(4) > 0)
		{
			generateGoldIntention.StartBuildingTreasureRooms();
		}
		return result;
	}

	internal void TryAcceptPotentialMission()
	{
		if (currMission == null)
		{
			currMission = potentialMission;
			potentialMission = null;
		}
	}

	private void SetupReferences()
	{
		if (IntentionManager == null)
		{
			IntentionManager = GetComponent<AIIntentionManager>();
			LandmassOwner = GetComponent<LandmassOwner>();
			IntentionManager.Init(this);
			if (aiOnLandmass == null)
			{
				aiOnLandmass = new Dictionary<int, AIKingdom>();
			}
		}
	}

	public void ClearMission()
	{
		if (currMission != null)
		{
			currMission.Dispose();
			currMission = null;
		}
	}

	private void OnVikingRaidStarted()
	{
		tookDamageFromLastInvasion = false;
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		if (Layout != null)
		{
			UpdateResourceAllocation();
			Layout.UpdateInvalidZones(deltaTime);
			int i = 0;
			List<Cell> deferredRoads = Layout.deferredRoads;
			for (; i < 3; i++)
			{
				if (deferredRoads.Count <= 0)
				{
					break;
				}
				bool flag = false;
				Cell c = deferredRoads[0];
				Transform transform = IntentionManager.intentionRoot.transform;
				int j = 0;
				for (int childCount = transform.childCount; j < childCount; j++)
				{
					Intention_BuildRoadTile component = transform.GetChild(j).GetComponent<Intention_BuildRoadTile>();
					if (component != null)
					{
						Vector3 position = component.transform.position;
						if (c.x == (int)position.x && c.z == (int)position.z)
						{
							flag = true;
							break;
						}
					}
				}
				if (!flag)
				{
					IntentionManager.AddIntention<Intention_BuildRoadTile>("build road tile").Init(deferredRoads[0]);
				}
				deferredRoads.RemoveAt(0);
				deferredRoads.RemoveAll((Cell cell) => cell.x == c.x && cell.z == c.z);
			}
		}
		if (currMission != null)
		{
			currMission.Update();
		}
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int num = 0;
		for (int count = resourceDefs.Count; num < count; num++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[num];
			int threshold = 15;
			if (resourceDef.ID == 6 || resourceDef.ID == 7)
			{
				threshold = 5;
			}
			if (AtLowResources(resourceDef.ID, threshold))
			{
				atLowResourceTime[num] += deltaTime;
			}
			else
			{
				atLowResourceTime[num] -= deltaTime * 3f;
			}
			atLowResourceTime[num] = Mathff.Clamp(atLowResourceTime[num], 0f, 120f);
		}
		if (SeasonManager.inst.CurrentYear() > 50)
		{
			int count2 = World.inst.GetVillagersForLandMass(Layout.LandMass).Count;
			int num2 = 15 - count2;
			if (num2 > 0)
			{
				for (int num3 = 0; num3 < num2; num3++)
				{
					Player.inst.AddVillager(Layout.KingdomStart);
				}
			}
		}
		if (skillLevel == SkillLevel.VeryHigh && cheatTimer.Update(deltaTime))
		{
			int count3 = World.inst.GetVillagersForLandMass(Layout.LandMass).Count;
			if (LandmassOwner.Gold < 5 && Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.throneRoomHash).Count > 0)
			{
				LandmassOwner.Gold += (int)Mathff.Max(1f, (float)count3 * 0.05f);
			}
			int num4 = Player.inst.TotalResidentialSlotsOnLandMass(Layout.LandMass) - count3;
			if (num4 > 0)
			{
				int num5 = Mathff.Min(10, num4 / 4);
				for (int num6 = 0; num6 < num5; num6++)
				{
					Player.inst.AddVillager(Layout.KingdomStart);
				}
			}
			List<FreeResourceSystem.ResourceDef> resourceDefs2 = FreeResourceSystem.inst.resourceDefs;
			for (int num7 = 0; num7 < resourceDefs2.Count; num7++)
			{
				int iD = resourceDefs2[num7].ID;
				if (AtLowResourcesExtended(iD))
				{
					int num8 = 0;
					if (iD == 9)
					{
						num8 = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.orchardHash).Count * 3;
					}
					if (iD == 0)
					{
						num8 = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.farmHash).Count * 3;
					}
					if (iD == 8)
					{
						num8 = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.fishinghutHash).Count * 3;
					}
					if (iD == 1)
					{
						num8 = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.foresterHash).Count * 5;
					}
					if (iD == 2)
					{
						num8 = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.quarryHash).Count * 5;
					}
					if (iD == 5)
					{
						num8 = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.ironMineHash).Count * 5;
					}
					if (iD == 6 || iD == 7)
					{
						num8 = Player.inst.GetBuildingListForLandMass(Layout.LandMass, World.blacksmithHash).Count * 5;
					}
					if (num8 > 0)
					{
						FreeResourceManager.inst.GetAutoStackFor(iD, Mathff.Max(10, num8), Layout.KingdomStart);
					}
				}
			}
		}
		generateMissionTimer -= deltaTime;
		if (generateMissionTimer < 0f && potentialMission == null && currMission == null)
		{
			GeneratePotentialMission();
			generateMissionTimer = 1f;
		}
		audienceTimer -= Time.deltaTime;
		flavorChatTimer -= Time.deltaTime;
		if (unitControl != null)
		{
			unitControl.Update();
		}
		IntentionManager.Tick(Time.deltaTime);
		lastFrameRequestedResources = frameRequestedResources;
	}

	private void DrawDebug()
	{
		if (Layout != null)
		{
			Layout.DrawDebug();
		}
	}

	private void StartBaseIntentions()
	{
		unitControl = new AIUnitControlSystem();
		unitControl.Init(LandmassOwner.teamId);
		collectWoodIntention = IntentionManager.AddIntention<Intention_CollectWood>("always collect wood");
		collectWoodIntention.Init();
		collectIronIntention = IntentionManager.AddIntention<Intention_CollectIron>("collect iron");
		collectIronIntention.Init();
		enoughFoodIntention = IntentionManager.AddIntention<Intention_EnoughFood>("always make enough food");
		enoughFoodIntention.Init();
		enoughFoodResidential = IntentionManager.AddIntention<Intention_EnoughResidential>("always have enough houses");
		enoughFoodResidential.Init();
		enoughCharcoal = IntentionManager.AddIntention<Intention_EnoughCharcoal>("always have enough charcoal");
		IntentionManager.AddIntention<Intention_KeepCleanOfRubble>("always cleanup rubble");
		IntentionManager.AddIntention<Intention_SuppressFires>("suppress fires").Init();
		IntentionManager.AddIntention<Intention_KeepPeopleHealthy>("keep people healthy").Init();
		IntentionManager.AddIntention<Intention_KeepPeopleHappy>("keep people happy").Init();
		IntentionManager.AddIntention<Intention_CleanupDeadBodies>("clean up dead bodies").Init();
		IntentionManager.AddIntention<Intention_MaintainAmpleStorage>("maintain ample storage").Init();
		maintainWallDefense = IntentionManager.AddIntention<Intention_WallDefense>("maintain wall defense");
		maintainWallDefense.Init();
		manageTradeIntentions = new Intention_ManageTrade[World.LandMassOwners.Count - 1];
		manageInvasionIntentions = new Intention_ManageInvasion[World.LandMassOwners.Count - 1];
		int num = 0;
		for (int i = 0; i < World.LandMassOwners.Count; i++)
		{
			int teamId = World.LandMassOwners.data[i].teamId;
			if (teamId != LandmassOwner.teamId)
			{
				manageTradeIntentions[num] = IntentionManager.AddIntention<Intention_ManageTrade>($"manage trade {teamId}");
				manageTradeIntentions[num].Init(teamId);
				manageInvasionIntentions[num] = IntentionManager.AddIntention<Intention_ManageInvasion>($"manage invasion {teamId}");
				manageInvasionIntentions[num].Init(teamId);
				num++;
			}
		}
		buildDock = IntentionManager.AddIntention<Intention_BuildDock>("build dock");
		buildDock.Init();
		fillShallowWaterIntention = IntentionManager.AddIntention<Intention_FillShallowWater>("fill shallow water");
		buildDrawbridgesIntention = IntentionManager.AddIntention<Intention_BuildDrawbridges>("build drawbridges");
		buildDrawbridgesIntention.Init();
		makeFishingHutsIntention = IntentionManager.AddIntention<Intention_MakeFishingHuts>("make fishing huts");
		makeFishingHutsIntention.Init();
		manageWaterSystem = IntentionManager.AddIntention<Intention_ManageWaterSystem>("manage water system");
		manageWaterSystem.Init();
		makeToolsIntention = IntentionManager.AddIntention<Intention_MakeTools>("make tools");
		makeToolsIntention.Init();
		manageArmiesIntention = IntentionManager.AddIntention<Intention_ManageArmies>("manage armies");
		manageArmiesIntention.Init();
		infrastructureDefenseIntention = IntentionManager.AddIntention<Intention_InfrastructureDefense>("infrastructure defense");
		infrastructureDefenseIntention.Init();
		manageDiplomacyIntention = IntentionManager.AddIntention<Intention_ManageDiplomacy>("manage diplomacy");
		manageDiplomacyIntention.Init();
		manageDiplomacyAIIntention = IntentionManager.AddIntention<Intention_ManageDiplomacyAI>("manage diplomacy AI");
		manageDiplomacyAIIntention.Init();
		manageDiplomacyInfrastructure = IntentionManager.AddIntention<Intention_ManageDiplomacyInfrastructure>("manage diplomacy infrastructure");
		manageTransportShips = IntentionManager.AddIntention<Intention_ManageTransportShips>("manage transport ships");
		buildingUpkeepIntention = IntentionManager.AddIntention<Intention_BuildingUpkeep>("maintain building integrity");
		buildingUpkeepIntention.Init();
		generateGoldIntention = IntentionManager.AddIntention<Intention_GenerateGold>("always generate gold");
		generateGoldIntention.Init();
		manageRoadsIntention = IntentionManager.AddIntention<Intention_ManageRoads>("manage roads");
		manageRoadsIntention.Init();
		manageFoodDistribution = IntentionManager.AddIntention<Intention_FoodDistribution>("manage food distribution");
		manageFoodDistribution.Init();
		clearObstructions = IntentionManager.AddIntention<Intention_ClearObstructions>("clear obstructions");
		buildBakeries = IntentionManager.AddIntention<Intention_BuildBakeries>("build bakeries");
		if (Layout.LandmassReferenceSize >= 35)
		{
			buildGreatHall = IntentionManager.AddIntention<Intention_BuildGreatHall>("build greathall");
			buildGreatHall.Init();
		}
	}

	internal string GetLocalizedName()
	{
		if (World.inst.kingdomHeadInfo[headIdx].maleHonorific)
		{
			return string.Format("ScriptLocalization.KingName", lastName);
		}
		return string.Format("ScriptLocalization.QueenName", lastName);
	}

	public bool IsMerchantShipAssigned(Ship ship)
	{
		for (int i = 0; i < manageTradeIntentions.Length; i++)
		{
			if (manageTradeIntentions[i] != null && manageTradeIntentions[i].merchantShip == ship)
			{
				return true;
			}
		}
		return false;
	}

	public Intention_ManageTrade GetTradeIntentionOfForeignTeamID(int foreignTeamId)
	{
		for (int i = 0; i < manageTradeIntentions.Length; i++)
		{
			if (manageTradeIntentions[i] != null && manageTradeIntentions[i].foreignTeamId == foreignTeamId)
			{
				return manageTradeIntentions[i];
			}
		}
		return null;
	}

	public Intention_ManageInvasion GetInvasionIntentionForTeamID(int foreignTeamId)
	{
		for (int i = 0; i < manageInvasionIntentions.Length; i++)
		{
			if (manageInvasionIntentions[i] != null && manageInvasionIntentions[i].targetTeamId == foreignTeamId)
			{
				return manageInvasionIntentions[i];
			}
		}
		return null;
	}

	public void SellGoodsToForeignMerchant(MerchantShip ship)
	{
		Dock currentDock = ship.GetCurrentDock();
		IResourceStorage loadingStorageComponent = currentDock.loadingStorageComponent;
		ResourceAmount resourceAmount = new ResourceAmount();
		int num = 0;
		ResourceAmount sellToPrice = ship.GetSellToPrice();
		for (int i = 0; i < CurrentResources.resources.Count; i++)
		{
			int resourceID = CurrentResources.resources[i].resourceID;
			if (resourceID != 4 && CurrentResources.resources[i].Amount > 200)
			{
				num += sellToPrice.Get(resourceID) * loadingStorageComponent.StoredPublicResources(resourceID);
				resourceAmount.Add(resourceID, loadingStorageComponent.StoredPublicResources(resourceID));
			}
		}
		ship.AddToHold(resourceAmount);
		((IResourceStorage)currentDock.loadingStorageComponent).RemoveResources(resourceAmount);
		LandmassOwner.Gold += num;
	}

	public void BuyGoodsFromForeignMerchant(MerchantShip ship, Dock dock)
	{
		ResourceAmount currentResources = CurrentResources;
		int num = currentResources.Get(4);
		int num2 = (int)((float)num * 0.25f);
		if (num > 200)
		{
			num2 = (int)((float)num * 0.33f);
		}
		if (num > 300)
		{
			num2 = (int)((float)num * 0.5f);
		}
		ResourceAmount amt = new ResourceAmount();
		int num3 = 0;
		for (int i = 0; i < ship.Hold.resources.Count; i++)
		{
			if (num2 <= 0)
			{
				break;
			}
			Resource resource = ship.Hold.resources[i];
			int resourceID = resource.resourceID;
			if (resourceID != 4 && AtLowResourcesExtended(resourceID))
			{
				int num4 = currentResources.Get(resourceID);
				int num5 = num4 + SRand.Range(5, 55);
				int amount = resource.Amount;
				int num6 = ship.buyFromPrice.Get(resourceID);
				int num7 = Mathff.Min(amount, num5 - num4);
				if (num6 > 0)
				{
					num7 = Mathff.Min(Mathff.Min(amount, num5 - num4), num2 / num6);
				}
				if (num7 > 0)
				{
					amt.Set(resourceID, num7);
					int num8 = num7 * num6;
					num2 -= num8;
					num3 += num8;
				}
			}
		}
		if (num3 > 0)
		{
			int num9 = 0;
			for (int j = 0; j < amt.resources.Count; j++)
			{
				ResourceTextStackManager.inst.ShowResourceAmount(this, ship.GetPos() + new Vector3(0f, (float)num9 * 0.25f, 0f), amt.resources[j].resourceID, amt.resources[j].Amount);
				num9++;
			}
		}
		ship.RemoveFromHold(amt);
		dock.loadingStorageComponent.Deposit(ref amt);
		LandmassOwner.Gold -= num3;
	}

	public void SetupBase(int landMass, int rivalKingdomBioCode, AIPersonality personality, int teamId)
	{
		SetupReferences();
		LandmassOwner.teamId = teamId;
		LandmassOwner.SetBannerIdx(rivalKingdomBioCode);
		this.personality = personality;
		int num = SRand.Range(0, 4);
		if (num == 0)
		{
			FavoriteFood = 9;
		}
		if (num == 1)
		{
			FavoriteFood = 8;
		}
		if (num == 2)
		{
			FavoriteFood = 10;
		}
		if (num == 3)
		{
			FavoriteFood = 0;
		}
		int num2 = (num + 1) % 4;
		if (num2 == 0)
		{
			LeastFavoriteFood = 9;
		}
		if (num2 == 1)
		{
			LeastFavoriteFood = 8;
		}
		if (num2 == 2)
		{
			LeastFavoriteFood = 10;
		}
		if (num2 == 3)
		{
			LeastFavoriteFood = 0;
		}
		bool flag = true;
		while (flag)
		{
			headIdx = SRand.Range(0, World.inst.kingdomHeadInfo.Length);
			flag = false;
			for (int i = 0; i < AIBrainsContainer.inst.kingdoms.Count; i++)
			{
				if (AIBrainsContainer.inst.kingdoms[i].headIdx == headIdx)
				{
					flag = true;
					break;
				}
			}
		}
		flag = true;
		int num3 = 25;
		while (flag && num3 > 0)
		{
			int num4 = SRand.Range(0, 100);
			if (headIdx == 0)
			{
				rulerPersonality = ((num4 <= 50) ? RulerPersonality.Playful : RulerPersonality.Anxious);
			}
			else if (headIdx == 1)
			{
				rulerPersonality = ((num4 <= 50) ? RulerPersonality.Aggressive : RulerPersonality.Anxious);
			}
			else
			{
				rulerPersonality = ((num4 > 50) ? RulerPersonality.Playful : RulerPersonality.Aggressive);
			}
			num3--;
			flag = false;
			for (int j = 0; j < AIBrainsContainer.inst.kingdoms.Count; j++)
			{
				if (AIBrainsContainer.inst.kingdoms[j].rulerPersonality == rulerPersonality)
				{
					flag = true;
					break;
				}
			}
		}
		LandmassOwner.TakeOwnership(landMass);
		Layout = new AILayout();
		InitPersonality();
		Layout.Setup(World.inst.GridWidth, World.inst.GridHeight, landMass, PickStartSpot(landMass), this);
	}

	public Vector3 PickStartSpot(int landMass)
	{
		List<Cell> list = new List<Cell>();
		List<Cell> list2 = new List<Cell>();
		for (int i = 0; i < World.inst.cellsToLandmass[landMass].Count; i++)
		{
			Cell cell = World.inst.cellsToLandmass[landMass].data[i];
			if (cell.terrainResource != null)
			{
				switch (cell.terrainResource.resourceID)
				{
				case 2:
					list.Add(cell);
					break;
				case 5:
					list2.Add(cell);
					break;
				}
			}
		}
		List<BaseStartCellInfo> list3 = new List<BaseStartCellInfo>();
		for (int j = 0; j < World.inst.cellsToLandmass[landMass].Count; j++)
		{
			Cell cell2 = World.inst.cellsToLandmass[landMass].data[j];
			if (cell2.Type != TerrainType.None)
			{
				continue;
			}
			float num = 100f;
			int k = 0;
			for (int count = list.Count; k < count; k++)
			{
				float num2 = Mathff.Dist(cell2.Center2D, list[k].Center2D);
				if (num > num2 && num2 > 4f)
				{
					num = num2;
				}
			}
			float num3 = 100f;
			int l = 0;
			for (int count2 = list2.Count; l < count2; l++)
			{
				float num4 = Mathff.Dist(cell2.Center2D, list2[l].Center2D);
				if (num3 > num4 && num4 > 4f)
				{
					num3 = num4;
				}
			}
			int num5 = 0;
			int num6 = 0;
			int num7 = Mathff.Clamp(cell2.x - 4, 0, World.inst.GridWidth - 1);
			int num8 = Mathff.Clamp(cell2.z - 4, 0, World.inst.GridHeight - 1);
			int num9 = Mathff.Clamp(cell2.x + 4, 0, World.inst.GridWidth - 1);
			int num10 = Mathff.Clamp(cell2.z + 4, 0, World.inst.GridHeight - 1);
			for (int m = num7; m <= num9; m++)
			{
				for (int n = num8; n <= num10; n++)
				{
					Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(m, n);
					if (cellDataUnsafe.Type == TerrainType.None && World.inst.treeSystem.ItemAmount(cellDataUnsafe) == 0)
					{
						num5++;
					}
					num6 += World.inst.treeSystem.ItemAmount(cellDataUnsafe);
				}
			}
			int num11 = 64;
			float s = (float)(num11 * 4 - num6) * 0.75f + num * 2f + num3 / 8f + (float)(num11 - num5);
			list3.Add(new BaseStartCellInfo(s, cell2));
		}
		list3.Sort((BaseStartCellInfo c1, BaseStartCellInfo c2) =>
		{
			if (c1.score < c2.score)
			{
				return -1;
			}
			return (c2.score < c1.score) ? 1 : 0;
		});
		foreach (BaseStartCellInfo item in list3)
		{
			Debug.DrawLine(item.cell.Center2D, item.cell.Center2D + new Vector3(0f, item.score / 100f, 0f), Color.red, 100f);
		}
		return list3[0].cell.Position;
	}

	public Color GetColor()
	{
		return World.inst.liverySets[LandmassOwner.bannerIdx].mapColor;
	}

	public Texture GetTexture()
	{
		return LandmassOwner.BannerTexture;
	}

	public void BeginBase()
	{
		transform.position = Layout.PlaceInitialBlocks();
		StartBaseIntentions();
	}

	public void InitPersonality()
	{
		globalThreatLevel = personality.StartThreatLevel;
		allowLibraries = personality.AllowLibraries;
		lastName = "";
		flavorConvos.Add("FlavorEventJousting");
		flavorConvos.Add("FlavorFood");
		flavorConvos.Add("FlavorPlague");
		flavorConvos.Add("FlavorEventTavern");
		if (rulerPersonality == RulerPersonality.Aggressive)
		{
			flavorConvos.Add("FlavorMilitary");
			flavorConvos.Add("FlavorDragonSoldiers");
			flavorConvos.Add("FlavorStatue");
			flavorConvos.Add("FlavorQuarry");
			flavorConvos.Add("FlavorBathRules");
		}
		if (rulerPersonality == RulerPersonality.Anxious)
		{
			flavorConvos.Add("FlavorEventSickDiplomat");
			flavorConvos.Add("FlavorEventOffensiveStatue");
			flavorConvos.Add("FlavorGarden");
			flavorConvos.Add("FlavorDragonFear");
			flavorConvos.Add("FlavorHarvestWish");
			if (!allowLibraries)
			{
				flavorConvos.Add("FlavorLibraries");
			}
		}
		if (rulerPersonality == RulerPersonality.Playful)
		{
			flavorConvos.Add("TavernDisguise");
			flavorConvos.Add("FlavorFlight");
			flavorConvos.Add("FlavorTheater");
		}
		if (headIdx == 1)
		{
			flavorConvos.Add("FlavorJoke");
		}
		if (rulerPersonality == RulerPersonality.Playful || rulerPersonality == RulerPersonality.Anxious)
		{
			flavorConvos.Add("FlavorBath");
		}
	}

	internal void VikingsDidDamage()
	{
		if (globalThreatLevel < 1)
		{
			globalThreatLevel = 1;
		}
		tookDamageFromLastInvasion = true;
		if (!(potentialMission is DefendVikingsRequest))
		{
			potentialMission = new DefendVikingsRequest(this);
		}
	}
}
