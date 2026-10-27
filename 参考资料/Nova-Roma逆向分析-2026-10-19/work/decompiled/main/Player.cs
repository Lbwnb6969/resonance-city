using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using Assets;
using Assets.Code;
using Assets.Interface;
using Drawing;
using I2.Loc;
using UnityEngine;

public class Player : MonoBehaviour
{
	[Serializable]
	public struct DockOpening
	{
		public int teamIDa;

		public int teamIDb;
	}

	public delegate void OnDockUpdate(LandmassOwner a, LandmassOwner b, bool isOpen);

	public enum UpgradeType
	{
		None,
		ArmorPiercingArrows,
		ArmorPiercingBallistas,
		ImprovedConstruction,
		BetterBreadOvens,
		BeautifulTapestries,
		FineRugs,
		StrongerSails,
		NumUpgrades
	}

	public enum ToolUser
	{
		Quarry,
		Forester,
		IronMine,
		Butcher,
		FishMonger,
		NumOfToolUsers
	}

	public class BuildingRegistry
	{
		[NonSerialized]
		public int uniqueNameHash;

		[NonSerialized]
		public int categoryNameHash;

		[NonSerialized]
		public ArrayExt<Building> buildings = new ArrayExt<Building>(100);
	}

	public class LandMassBuildingRegistry
	{
		[NonSerialized]
		public ArrayExt<BuildingRegistry> registry = new ArrayExt<BuildingRegistry>(50);

		[NonSerialized]
		public ArrayExt<Building> buildings = new ArrayExt<Building>(100);
	}

	public delegate void OnPlayerEvent();

	public class PlagueDeathInfo
	{
		[NonSerialized]
		public List<Villager> deathQueue = new List<Villager>();

		[NonSerialized]
		public int deaths;

		[NonSerialized]
		public float deathTime;

		[NonSerialized]
		public int plagued;

		[NonSerialized]
		public float healed;
	}

	public delegate void OnProsperityChanged(int amt);

	public enum GodStanding
	{
		VeryUnhappy,
		Unhappy,
		Neutral,
		Happy,
		VeryHappy
	}

	public class GodHonorInfo
	{
		public int honor;

		public bool templeNotStaffed;

		public GodStanding GetStanding(LandmassOwner lmo)
		{
			int honorGoal = inst.GetHonorGoal(lmo);
			int num = honor - honorGoal;
			if (num >= 2)
			{
				return GodStanding.Happy;
			}
			if (num >= 4)
			{
				return GodStanding.VeryHappy;
			}
			if (num <= -10)
			{
				return GodStanding.VeryUnhappy;
			}
			if (num <= -5)
			{
				return GodStanding.Unhappy;
			}
			return GodStanding.Neutral;
		}
	}

	[Serializable]
	public struct HappinessMod
	{
		public float time;

		public int amount;

		public string id;

		public string description;

		[OptionalField(VersionAdded = 2)]
		public int landMass;
	}

	private struct PlagueStartLocation
	{
		public float score;

		public Vector3 pos;

		public float avgHealth;
	}

	private struct Plague
	{
		public float plagueChance;

		public ArrayExt<PlagueStartLocation> plagueStartLocations;
	}

	[Serializable]
	public class HappinessInfo
	{
		public int HappinessFromHomeless;

		public int houseHappiness;

		public int lesiureHappiness;

		public int foodHappiness = 50;

		public int currHappiness = 100;

		public int targetHappiness = 100;

		public bool libChurchPenalty;

		[OptionalField(VersionAdded = 3)]
		public int deadBodiesPenalty;

		public bool joustingArenaPenalty;

		public bool theaterPenalty;

		public int theaterMaxScore;

		public int theaterCurrScore;

		public bool shopPenalty;

		public int shopMaxScore;

		public int shopCurrScore;

		public float bathhouseNeed;

		public bool templePenalty;

		public int numGodsHonored;

		public bool forumPenalty;
	}

	[Serializable]
	public class HealthInfo
	{
		public enum HealthRating
		{
			Excellent,
			VeryGood,
			Good,
			Fair,
			Poor,
			VeryPoor
		}

		public int currHealth;

		public float houseHealth;

		public bool HospitalClinicPenalty;

		public int deadBodyHealth;

		public static HealthRating ToRating(int n)
		{
			if (n >= 90)
			{
				return HealthRating.Excellent;
			}
			if (n >= 75 && n < 90)
			{
				return HealthRating.VeryGood;
			}
			if (n >= 60 && n < 75)
			{
				return HealthRating.Good;
			}
			if (n >= 40 && n < 60)
			{
				return HealthRating.Fair;
			}
			if (n > 10 && n < 40)
			{
				return HealthRating.Poor;
			}
			return HealthRating.VeryPoor;
		}
	}

	[Serializable]
	public class IntegrityInfo
	{
		public enum IntegrityRating
		{
			Excellent,
			Good,
			Fair,
			VeryPoor
		}

		public int currentIntegrity;

		public static IntegrityRating ToRating(int integrity)
		{
			switch (integrity)
			{
			case 100:
				return IntegrityRating.Excellent;
			case 75:
			case 76:
			case 77:
			case 78:
			case 79:
			case 80:
			case 81:
			case 82:
			case 83:
			case 84:
			case 85:
			case 86:
			case 87:
			case 88:
			case 89:
			case 90:
			case 91:
			case 92:
			case 93:
			case 94:
			case 95:
			case 96:
			case 97:
			case 98:
			case 99:
				return IntegrityRating.Good;
			default:
				if (integrity < 75 && integrity >= 50)
				{
					return IntegrityRating.Fair;
				}
				_ = 50;
				return IntegrityRating.VeryPoor;
			}
		}
	}

	public enum Difficulty
	{
		Peaceful,
		Easy,
		Hard,
		Survival,
		NumSettings
	}

	public delegate void UpdateBanner();

	[Serializable]
	public class TourismInfo
	{
		public string code = string.Empty;

		public string editAuthCode = string.Empty;
	}

	[Serializable]
	public class PlayerSaveData : SaveClass<Player, PlayerSaveData>
	{
		private class BuildingLoadHelper
		{
			public Building building;

			public Building.BuildingSaveData buildingSaveData;

			public int priority;

			public BuildingLoadHelper(Building b, Building.BuildingSaveData d, int loadPriority)
			{
				building = b;
				buildingSaveData = d;
				priority = loadPriority;
			}
		}

		public int bannerIdx;

		public int TownHappiness;

		public int HappinessFromReligion;

		public int HappinessFromFood;

		public List<Villager.VillagerSaveData> Workers;

		public List<Guid> HomelessData;

		public bool bDidFirstFire;

		public Difficulty Difficulty;

		public int CurrYear;

		public List<Building.BuildingSaveData[]> structures;

		public List<Building.BuildingSaveData[]> subStructures;

		public List<AqueductLine.AqueductLineSaveData> aqueducts;

		public List<HappinessMod> happinessMods;

		public float timeAtFailHappiness;

		public bool quarriesCanUseTools = true;

		public bool forestersCanUseTool = true;

		public bool minesCanUseTools = true;

		public List<HappinessInfo> happinessInfos;

		public List<HappinessMod> globalHappinessMods;

		public List<string> landMassNames;

		public int[][] JobPriorityOrder;

		public bool[][] JobEnabledFlag;

		private List<UpgradeType> upgrades = new List<UpgradeType>();

		public float[] TaxRates;

		public bool usedCheats;

		public int deathsInThisYear;

		public string nameForOldAgeDeath;

		public LandmassOwner.LandmassOwnerSaveData playerLandmassOwnerSaveData;

		public bool hazardPay;

		public List<HealthInfo> healthInfos;

		public float poorHealthGracePeriod;

		public List<IntegrityInfo> integrityInfos;

		public bool[][] CanUseTools;

		public List<DockOpening> dockOpenings;

		public bool newBannerSystem;

		public Villager.VillagerSaveData[] WorkersArray;

		public TechnologyTree.TechnologyTreeSaveData technologySaveData;

		public TourismInfo tourism;

		public int prosperityPoints;

		public float currProsperityTime;

		public int populationGoalIdx;

		public SerializableDictionary<string, bool> buildingsUnlocked;

		public string[] buildingsPreq;

		public string[] groupsPreq;

		public bool seenDamPlannerIntro;

		public float[] arrivalTimerDurationLandmass;

		public Governor.GovernorSaveData[] governors;

		public int[] nextPlagueYearLandmass;

		public float[] timeOfYearToPlagueLandmass;

		private static int aqueductHash = "aqueduct".GetHashCode();

		private static int castleblockHash = "castleblock".GetHashCode();

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			upgrades = new List<UpgradeType>();
			deathsInThisYear = 0;
			nameForOldAgeDeath = "";
			seenDamPlannerIntro = false;
			newBannerSystem = false;
		}

		public override PlayerSaveData Pack(Player p)
		{
			LegionSystem.Inst.CompleteJobs();
			newBannerSystem = true;
			upgrades = new List<UpgradeType>();
			bannerIdx = p.PlayerLandmassOwner.bannerIdx;
			WorkersArray = new Villager.VillagerSaveData[p.Workers.Count];
			int i = 0;
			for (int count = p.Workers.Count; i < count; i++)
			{
				if (p.Workers.data[i] != null)
				{
					WorkersArray[i] = new Villager.VillagerSaveData().Pack(p.Workers.data[i]);
				}
			}
			HomelessData = new List<Guid>();
			for (int j = 0; j < p.Homeless.Count; j++)
			{
				HomelessData.Add(p.Homeless.data[j].guid);
			}
			structures = new List<Building.BuildingSaveData[]>();
			subStructures = new List<Building.BuildingSaveData[]>();
			Cell[] cellsData = World.inst.GetCellsData();
			int k = 0;
			for (int num = cellsData.Length; k < num; k++)
			{
				Cell cell = cellsData[k];
				if (cell.OccupyingStructure.Count > 0)
				{
					int num2 = 0;
					for (int l = 0; l < cell.OccupyingStructure.Count; l++)
					{
						if (!cell.OccupyingStructure[l].isDemolishing && cell.OccupyingStructure[l].GetCell() == cell)
						{
							num2++;
						}
					}
					Building.BuildingSaveData[] array = new Building.BuildingSaveData[num2];
					num2 = 0;
					for (int m = 0; m < cell.OccupyingStructure.Count; m++)
					{
						if (!cell.OccupyingStructure[m].isDemolishing && cell.OccupyingStructure[m].GetCell() == cell)
						{
							array[num2++] = new Building.BuildingSaveData().Pack(cell.OccupyingStructure[m]);
						}
					}
					if (num2 > 0)
					{
						structures.Add(array);
					}
				}
				if (cell.SubStructure.Count <= 0)
				{
					continue;
				}
				List<Building.BuildingSaveData> list = new List<Building.BuildingSaveData>();
				for (int n = 0; n < cell.SubStructure.Count; n++)
				{
					if (!cell.SubStructure[n].isDemolishing && cell.SubStructure[n].GetCell() == cell)
					{
						list.Add(new Building.BuildingSaveData().Pack(cell.SubStructure[n]));
					}
				}
				if (list.Count > 0)
				{
					subStructures.Add(list.ToArray());
				}
			}
			aqueducts = new List<AqueductLine.AqueductLineSaveData>(AqueductLine.allLines.Count);
			int num3 = 0;
			for (int count2 = AqueductLine.allLines.Count; num3 < count2; num3++)
			{
				aqueducts.Add(new AqueductLine.AqueductLineSaveData().Pack(AqueductLine.allLines[num3]));
			}
			TownHappiness = p.KingdomHappiness;
			happinessInfos = p.landMassHappiness;
			integrityInfos = p.landMassIntegrity;
			playerLandmassOwnerSaveData = new LandmassOwner.LandmassOwnerSaveData().Pack(p.PlayerLandmassOwner);
			bDidFirstFire = p.bDidFirstFire;
			if (p.taxRates != null)
			{
				TaxRates = new float[p.taxRates.Length];
				Array.Copy(p.taxRates, TaxRates, p.taxRates.Length);
			}
			Difficulty = p.difficulty;
			timeAtFailHappiness = p.timeAtFailHappiness;
			seenDamPlannerIntro = p.seenDamPlannerIntro;
			happinessMods = p.happinessMods;
			landMassNames = new List<string>();
			for (int num4 = 0; num4 < p.LandMassNames.Count; num4++)
			{
				landMassNames.Add(p.LandMassNames[num4]);
			}
			CanUseTools = new bool[p.CanUseTools.Length][];
			for (int num5 = 0; num5 < p.CanUseTools.Length; num5++)
			{
				CanUseTools[num5] = new bool[p.CanUseTools[num5].Length];
				Array.Copy(p.CanUseTools[num5], CanUseTools[num5], CanUseTools[num5].Length);
			}
			usedCheats = p.hasUsedCheats;
			nameForOldAgeDeath = p.nameForOldAgeDeath;
			deathsInThisYear = p.deathsInThisYear;
			poorHealthGracePeriod = p.poorHealthGracePeriod;
			dockOpenings = p.dockOpenings;
			tourism = p.tourism;
			buildingsUnlocked = new SerializableDictionary<string, bool>(BuildUI.inst.UnlockedMap);
			buildingsPreq = new string[BuildUI.inst.BuildingPreq.Count];
			for (int num6 = 0; num6 < buildingsPreq.Length; num6++)
			{
				buildingsPreq[num6] = BuildUI.inst.BuildingPreq.data[num6];
			}
			groupsPreq = new string[BuildUI.inst.GroupsPreq.Count];
			for (int num7 = 0; num7 < groupsPreq.Length; num7++)
			{
				groupsPreq[num7] = BuildUI.inst.GroupsPreq.data[num7];
			}
			technologySaveData = new TechnologyTree.TechnologyTreeSaveData().Pack(TechnologyTree.inst);
			prosperityPoints = p.prosperityPoints;
			currProsperityTime = p.currProsperityTime;
			arrivalTimerDurationLandmass = new float[p.personArrivalTimer.Length];
			for (int num8 = 0; num8 < arrivalTimerDurationLandmass.Length; num8++)
			{
				arrivalTimerDurationLandmass[num8] = p.personArrivalTimer[num8].Duration;
			}
			governors = new Governor.GovernorSaveData[p.governors.Length];
			for (int num9 = 0; num9 < governors.Length; num9++)
			{
				if (p.governors[num9] != null)
				{
					governors[num9] = new Governor.GovernorSaveData().Pack(p.governors[num9]);
				}
			}
			nextPlagueYearLandmass = (int[])p.nextPlagueYear.Clone();
			timeOfYearToPlagueLandmass = (float[])p.timeOfYearToPlague.Clone();
			return this;
		}

		public Building ProcessBuilding(Building.BuildingSaveData structureData, Player p)
		{
			Building placeableByUniqueName = GameState.inst.GetPlaceableByUniqueName(structureData.uniqueName);
			if ((bool)placeableByUniqueName)
			{
				Building building = UnityEngine.Object.Instantiate(placeableByUniqueName);
				building.transform.position = structureData.globalPosition;
				building.Init();
				building.transform.SetParent(p.buildingContainer.transform, worldPositionStays: true);
				structureData.Unpack(building);
				building.SetupHighlight();
				p.AddBuilding(building);
				if (building.GetComponent<Keep>() != null && building.TeamID() == 0)
				{
					p.keep = building.GetComponent<Keep>();
				}
				return building;
			}
			Debug.LogError(structureData.uniqueName + " failed to load correctly");
			return null;
		}

		public override Player Unpack(Player p)
		{
			BuildUI.inst.UnlockedMap = ((buildingsUnlocked != null) ? new Dictionary<string, bool>(buildingsUnlocked) : new Dictionary<string, bool>());
			if (buildingsPreq != null)
			{
				BuildUI.inst.BuildingPreq.ClearFast();
				for (int i = 0; i < buildingsPreq.Length; i++)
				{
					BuildUI.inst.BuildingPreq.Add(buildingsPreq[i]);
				}
			}
			if (groupsPreq != null)
			{
				BuildUI.inst.GroupsPreq.ClearFast();
				for (int j = 0; j < groupsPreq.Length; j++)
				{
					BuildUI.inst.GroupsPreq.Add(groupsPreq[j]);
				}
			}
			BuildUI.inst.ApplyPreqs();
			technologySaveData.Unpack(TechnologyTree.inst);
			p.currProsperityTime = currProsperityTime;
			p.prosperityPoints = prosperityPoints;
			ProsperityUI.inst.Reset();
			p.ResetPerLandMassData();
			p.KingdomHappiness = TownHappiness;
			p.landMassHappiness = happinessInfos;
			if (p.landMassHappiness == null)
			{
				p.landMassHappiness = new List<HappinessInfo>();
			}
			while (p.landMassHappiness.Count < World.inst.NumLandMasses)
			{
				p.landMassHappiness.Add(new HappinessInfo());
			}
			p.landMassHealth = healthInfos;
			if (p.landMassHealth == null)
			{
				p.landMassHealth = new List<HealthInfo>();
			}
			while (p.landMassHealth.Count < World.inst.NumLandMasses)
			{
				p.landMassHealth.Add(new HealthInfo());
			}
			p.landMassIntegrity = integrityInfos;
			if (p.landMassIntegrity == null)
			{
				p.landMassIntegrity = new List<IntegrityInfo>();
			}
			while (p.landMassIntegrity.Count < World.inst.NumLandMasses)
			{
				p.landMassIntegrity.Add(new IntegrityInfo());
			}
			p.bDidFirstFire = bDidFirstFire;
			if (TaxRates != null)
			{
				p.taxRates = new float[TaxRates.Length];
				Array.Copy(TaxRates, p.taxRates, TaxRates.Length);
			}
			else
			{
				p.taxRates = null;
			}
			p.difficulty = Difficulty;
			p.timeAtFailHappiness = timeAtFailHappiness;
			p.happinessMods = happinessMods;
			if (p.happinessMods == null)
			{
				p.happinessMods = new List<HappinessMod>();
			}
			p.LandMassNames.Clear();
			for (int k = 0; k < landMassNames.Count; k++)
			{
				p.LandMassNames.Add(landMassNames[k]);
			}
			if (playerLandmassOwnerSaveData != null)
			{
				playerLandmassOwnerSaveData.Unpack(p.PlayerLandmassOwner);
			}
			if (bannerIdx != -1)
			{
				p.SetIndexedBanner(bannerIdx);
			}
			if (!newBannerSystem)
			{
				p.SetIndexedBanner(5);
				p.SetCustomBannerTexture(World.inst.liverySets[bannerIdx].bannerMaterial.mainTexture as Texture2D);
			}
			if (p.PlayerLandmassOwner.Gold < 0)
			{
				p.PlayerLandmassOwner.Gold = 0;
			}
			for (int l = 0; l < upgrades.Count; l++)
			{
				p.PlayerLandmassOwner.AddUpgrade(upgrades[l]);
			}
			p.Workers.Clear();
			p.Homeless.Clear();
			p.sick.Clear();
			for (int m = 0; m < WorkersArray.Length; m++)
			{
				Villager villager = Villager.CreateVillagerWithGender(WorkersArray[m].lady);
				villager.Pos = WorkersArray[m].pos;
				WorkersArray[m].Unpack(villager);
				p.Workers.Add(villager);
				if (villager.sick)
				{
					p.sick.Add(villager);
					PlagueDeathInfo plageDeathInfoForLandmass = p.GetPlageDeathInfoForLandmass(villager.landMass);
					if (plageDeathInfoForLandmass != null)
					{
						plageDeathInfoForLandmass.plagued++;
					}
				}
			}
			for (int n = 0; n < HomelessData.Count; n++)
			{
				Villager worker = p.GetWorker(HomelessData[n]);
				if (worker != null)
				{
					p.Homeless.Add(worker);
				}
			}
			List<BuildingLoadHelper> list = new List<BuildingLoadHelper>();
			for (int num = 0; num < structures.Count; num++)
			{
				Building.BuildingSaveData[] array = structures[num];
				for (int num2 = 0; num2 < array.Length; num2++)
				{
					Building building = ProcessBuilding(array[num2], p);
					if (building != null)
					{
						list.Add(new BuildingLoadHelper(building, array[num2], num2));
					}
				}
			}
			for (int num3 = 0; num3 < subStructures.Count; num3++)
			{
				Building.BuildingSaveData[] array2 = subStructures[num3];
				for (int num4 = 0; num4 < array2.Length; num4++)
				{
					Building building2 = ProcessBuilding(array2[num4], p);
					if (building2 != null)
					{
						list.Add(new BuildingLoadHelper(building2, array2[num4], num4 - 1000));
					}
				}
			}
			foreach (BuildingLoadHelper item in list.OrderBy((BuildingLoadHelper x) => x.priority))
			{
				if (item.building.uniqueNameHash == World.editTerrainZoneHash)
				{
					item.building.removeRocksOnComplete = false;
					item.building.removeTreesOnComplete = false;
				}
				World.inst.PlaceFromLoad(item.building);
				item.buildingSaveData.UnpackStage2(item.building);
			}
			GameObject original = Resources.Load<GameObject>("AqueductLine");
			if (aqueducts != null)
			{
				for (int num5 = 0; num5 < aqueducts.Count; num5++)
				{
					GameObject gameObject = UnityEngine.Object.Instantiate(original);
					try
					{
						if (aqueducts[num5].Unpack(gameObject.GetComponent<AqueductLine>()) == null)
						{
							UnityEngine.Object.DestroyImmediate(gameObject);
						}
					}
					catch
					{
						UnityEngine.Object.DestroyImmediate(gameObject);
						throw;
					}
				}
			}
			AqueductFlowController.RefreshForLoad();
			for (int num6 = 0; num6 < p.Workers.Count; num6++)
			{
				if (p.Workers.data[num6].Residence == null && !p.Homeless.Contains(p.Workers.data[num6]))
				{
					p.Homeless.Add(p.Workers.data[num6]);
					Debug.LogError("worker with null residence not in homeless saved data...");
				}
			}
			List<AdjacentMesh> list2 = new List<AdjacentMesh>();
			for (int num7 = 0; num7 < list.Count; num7++)
			{
				list[num7].building.GetComponents(list2);
				for (int num8 = 0; num8 < list2.Count; num8++)
				{
					list2[num8].UpdateRotation();
				}
			}
			Cell[] cellsData = World.inst.GetCellsData();
			for (int num9 = 0; num9 < cellsData.Length; num9++)
			{
				List<Building> occupyingStructure = cellsData[num9].OccupyingStructure;
				for (int num10 = 0; num10 < occupyingStructure.Count; num10++)
				{
					if (occupyingStructure[num10].categoryHash == castleblockHash)
					{
						occupyingStructure[num10].GetComponent<BlockBuilding>().UpdateStackPostLoad();
						break;
					}
					WaterConsumer component = occupyingStructure[num10].GetComponent<WaterConsumer>();
					if (component != null)
					{
						component.RegisterWithWaterSystem();
					}
				}
				for (int num11 = 0; num11 < occupyingStructure.Count; num11++)
				{
					if (occupyingStructure[num11].snapInstances.Length != 0)
					{
						Building building3 = cellsData[num9].StructureFindByCategory(occupyingStructure[num11].snapBuildingTarget.GetHashCode());
						if (building3 != null)
						{
							occupyingStructure[num11].SnapInside(building3);
						}
						break;
					}
				}
			}
			ArrayExt<Building> buildingList = inst.GetBuildingList(World.fountainHash);
			for (int num12 = 0; num12 < buildingList.Count; num12++)
			{
				buildingList.data[num12].GetComponent<Fountain>().RefreshBonuses(force: true);
			}
			ArrayExt<Building> buildingList2 = inst.GetBuildingList(World.largefountainHash);
			for (int num13 = 0; num13 < buildingList2.Count; num13++)
			{
				buildingList2.data[num13].GetComponent<Fountain>().RefreshBonuses(force: true);
			}
			ArrayExt<Building> buildingList3 = inst.GetBuildingList("temple2".GetHashCode());
			for (int num14 = 0; num14 < buildingList3.Count; num14++)
			{
				buildingList3.data[num14].GetComponent<Temple>().OnLoadAfterAllBuildingsPlaced();
			}
			World.inst.SetupInitialPathCosts();
			inst.irrigation.UpdateIrrigation();
			inst.CalcMaxResources(null);
			if (CanUseTools != null)
			{
				for (int num15 = 0; num15 < CanUseTools.Length && num15 < p.CanUseTools.Length; num15++)
				{
					Array.Copy(CanUseTools[num15], p.CanUseTools[num15], CanUseTools[num15].Length);
				}
			}
			p.hasUsedCheats = usedCheats;
			p.nameForOldAgeDeath = nameForOldAgeDeath;
			p.deathsInThisYear = deathsInThisYear;
			World.inst.RebuildVillagerGrid();
			ArrayExt<Building> buildingList4 = inst.GetBuildingList(World.cemeteryKeeperHash);
			for (int num16 = 0; num16 < buildingList4.Count; num16++)
			{
				buildingList4.data[num16].GetComponent<CemeteryKeeper>().RebuildPathData();
			}
			if (arrivalTimerDurationLandmass == null)
			{
				arrivalTimerDurationLandmass = new float[World.inst.NumLandMasses];
				for (int num17 = 0; num17 < arrivalTimerDurationLandmass.Length; num17++)
				{
					arrivalTimerDurationLandmass[num17] = 100f;
				}
			}
			else
			{
				for (int num18 = 0; num18 < arrivalTimerDurationLandmass.Length; num18++)
				{
					p.personArrivalTimer[num18].Duration = arrivalTimerDurationLandmass[num18];
				}
			}
			p.governors = new Governor[World.inst.NumLandMasses];
			if (governors != null)
			{
				for (int num19 = 0; num19 < governors.Length; num19++)
				{
					if (governors[num19] != null)
					{
						p.governors[num19] = governors[num19].Unpack(new Governor());
					}
				}
			}
			p.ChangeHazardPayActive(p.PlayerLandmassOwner.hazardPay, warmup: false);
			p.poorHealthGracePeriod = poorHealthGracePeriod;
			p.seenDamPlannerIntro = seenDamPlannerIntro;
			p.UpdateFocusedLandmass();
			PopulationUI.inst.regionName.RefreshRegionName();
			p.dockOpenings = dockOpenings;
			if (p.dockOpenings == null)
			{
				p.dockOpenings = new List<DockOpening>();
			}
			p.IntegrityTimer.ForceExpire();
			if (tourism != null)
			{
				p.tourism = tourism;
			}
			else
			{
				p.tourism = new TourismInfo();
			}
			p.godHonorTimer.ForceExpire();
			for (int num20 = 0; num20 < p.sick.Count; num20++)
			{
				p.sick.data[num20].UpdatePlacement();
			}
			World.inst.timeLastPlaced = -999f;
			if (nextPlagueYearLandmass != null)
			{
				Array.Copy(nextPlagueYearLandmass, p.nextPlagueYear, Mathff.Min(nextPlagueYearLandmass.Length, p.nextPlagueYear.Length));
			}
			if (timeOfYearToPlagueLandmass != null)
			{
				Array.Copy(timeOfYearToPlagueLandmass, p.timeOfYearToPlague, Mathff.Min(timeOfYearToPlagueLandmass.Length, p.timeOfYearToPlague.Length));
			}
			return p;
		}
	}

	public LandmassOwner PlayerLandmassOwner;

	public BuildingDamageAnimator buildingDamageAnimator = new BuildingDamageAnimator();

	public ResourceAmount defaultPayCost;

	public OnDockUpdate OnDocksOpenForTrade;

	private List<DockOpening> dockOpenings = new List<DockOpening>();

	public Timer hazardPayWarmup;

	private StreamerEffect hazardPayEffect;

	public Color FullProductionInfluence = new Color(0.4f, 0.9f, 0.3f, 1f);

	public Color NoProductionInfluence = new Color(0.15f, 0.1f, 0.05f, 0.75f);

	public Color FullNegativeProductionInfluence = new Color(0.6f, 0.25f, 0f, 1f);

	public Color FullHappinessInfluence = new Color(0.4f, 0.9f, 0.3f, 1f);

	public Color NoHappinessInfluence = new Color(0.15f, 0.1f, 0.05f, 0.75f);

	public Color FullNegativeHappinessInfluence = new Color(0.6f, 0.25f, 0f, 1f);

	public Color happinessMapHigh = new Color(0f, 0.8f, 0f, 0.9f);

	public Color happinessMapMid = new Color(0.8f, 0.8f, 0f, 0.9f);

	public Color happinessMapMidLow = new Color(0.8f, 0.8f, 0f, 0.9f);

	public Color happinessMapLow = new Color(1f, 0.2f, 0.05f, 0.7f);

	private List<FieldSystem> fruitSystems = new List<FieldSystem>();

	private List<FieldSystem> fieldSystems = new List<FieldSystem>();

	public bool[][] CanUseTools;

	public AnimationCurve showBounce;

	public AnimationCurve walkBounce;

	private ResourceAmount emptyAmount = new ResourceAmount();

	[NonSerialized]
	public ResourceAmount[] resourcesPerLandmass;

	[NonSerialized]
	public ResourceAmount[] storagePerLandmass;

	[NonSerialized]
	public int[] housingPerLandmass;

	public int InitialWorkers = 5;

	[HideInInspector]
	public int dragonThoughtCount = 25;

	[NonSerialized]
	public int villagerThoughtsCount = 29;

	[NonSerialized]
	public ArrayExtRef<Villager> Homeless = new ArrayExtRef<Villager>(30);

	[NonSerialized]
	public ArrayExt<Villager> Workers = new ArrayExt<Villager>(500);

	[NonSerialized]
	public ArrayExt<Villager> sick = new ArrayExt<Villager>(500);

	[NonSerialized]
	public ArrayExt<Home> Residentials = new ArrayExt<Home>(300);

	[NonSerialized]
	public ArrayExt<Home>[] ResidentialsPerLandmass;

	[NonSerialized]
	public ArrayExt<Building> Buildings = new ArrayExt<Building>(5000);

	[NonSerialized]
	public ArrayExt<WagePayer> WagePayers = new ArrayExt<WagePayer>(50);

	[NonSerialized]
	public ArrayExt<RadiusBonus> RadiusBonuses = new ArrayExt<RadiusBonus>(100);

	[NonSerialized]
	public ArrayExt<RadiusBonusHealth> RadiusHealthBonuses = new ArrayExt<RadiusBonusHealth>(100);

	public List<string> LandMassNames = new List<string>(1);

	private ArrayExt<ArrayExt<Building>> unbuiltBuildingsPerLandmass = new ArrayExt<ArrayExt<Building>>(10);

	private ArrayExt<LandMassBuildingRegistry> landMassBuildingRegistry = new ArrayExt<LandMassBuildingRegistry>(10);

	private ArrayExt<BuildingRegistry> globalBuildingRegistry = new ArrayExt<BuildingRegistry>(50);

	private ArrayExt<Building> emptyBuildingList = new ArrayExt<Building>(1);

	public static string BannerPath = "CustomBanners/";

	public Texture2D referenceBanner;

	public static Player inst;

	public HealthBar healthBarPrefab;

	public UnitIGUI unitIGUIprefab;

	[HideInInspector]
	public GameObject buildingContainer;

	public IrrigationManager irrigation;

	internal bool resetting;

	public static OnPlayerEvent onPlayerReset;

	[NonSerialized]
	public Governor[] governors;

	public List<Building>[] DamagedList;

	public int KingdomHappiness = 100;

	private Timer HappinessTimer = new Timer(3f);

	private Timer HealthTimer = new Timer(3f);

	private Timer IntegrityTimer = new Timer(3f);

	private Timer godHonorTimer = new Timer(3f);

	private int focusedLandMassIdx;

	private int focusedLandMassIdxLastValid;

	public ResourceAmount[] constructionPromisedResources;

	[NonSerialized]
	public float timeAtFailHappiness;

	[NonSerialized]
	public Keep keep;

	private List<Villager> DeferredPersonRemoval = new List<Villager>();

	private List<PlagueDeathInfo> plagueDeathInfo = new List<PlagueDeathInfo>();

	private List<Villager> OldAgeDeathQueue = new List<Villager>();

	[NonSerialized]
	public int MaxGoldStorage;

	[NonSerialized]
	public ArrayExt<ArrayExt<IMoveTarget>> invadersPerLandmass = new ArrayExt<ArrayExt<IMoveTarget>>(10);

	internal int loadTickDelay = 1;

	private int debugLogCount;

	public CommandBuilder cBuilder;

	public OnProsperityChanged onProsperityGained;

	public OnProsperityChanged onProsperityChanged;

	public float currProsperityTime;

	public const float MAX_PROSPERITY_TIME = 200f;

	private int prosperityPoints;

	private string nameForOldAgeDeath = "";

	private int deathsInThisYear;

	private int maxOldAgeDeaths = 1;

	private Timer coldTimer = new Timer(40f);

	private ArrayExt<Home> homesAtColdRisk = new ArrayExt<Home>(50);

	private Timer governorEffectTimer = new Timer(1f);

	internal int citizensGovernorReq = 50;

	private ArrayExt<int> needExtraHonor = new ArrayExt<int>(10);

	[NonSerialized]
	public int GodHonorMax = 30;

	private int keepHash = "keep".GetHashCode();

	private int outpostHash = "outpost".GetHashCode();

	private bool bDidFirstFire;

	private Timer[] combustionTimer;

	[NonSerialized]
	public int CurrTargetHappiness;

	private List<int> HappinessFromMods = new List<int>();

	private float poorHealthGracePeriod;

	[NonSerialized]
	public List<HappinessMod> happinessMods = new List<HappinessMod>();

	private bool[] homeForHomelessPerLandmass;

	private Timer[] personArrivalTimer;

	private int[] nextPlagueYear;

	private float[] timeOfYearToPlague;

	public const int MIN_WORKERS_FOR_PLAGUE = 200;

	public int plaguedHealed;

	public int plagued;

	private Timer randomEventTimer = new Timer(160f);

	private ArrayExt<int> scratchLandmasses = new ArrayExt<int>(32);

	private static int largehouseHash = "largehouse".GetHashCode();

	private static int smallhouseHash = "smallhouse".GetHashCode();

	private static int manorhouseHash = "manorhouse".GetHashCode();

	private ArrayExt<ArrayExt<Building>> scratchHouses = new ArrayExt<ArrayExt<Building>>(8);

	private ArrayExt<Guid> scratchGuid = new ArrayExt<Guid>(128);

	private ArrayExt<PlagueStartLocation> plagueEntries = new ArrayExt<PlagueStartLocation>(10);

	private ArrayExt<Plague> plagueGroups = new ArrayExt<Plague>(128);

	private const float PLAGUE_DEAD_BODY_RADIUS = 4f;

	private const float PLAGUE_DEAD_BODY_SCORE_SCALE = 2f;

	private ArrayExt<DeadVillager> scratchDeadBodies = new ArrayExt<DeadVillager>(32);

	private List<Villager> deathQueue = new List<Villager>(5);

	private int StarvationDeaths;

	private float StarvationTimer;

	private HappinessInfo nullHappinessInfo = new HappinessInfo();

	private List<HappinessInfo> landMassHappiness = new List<HappinessInfo>();

	private ArrayExt<ArrayExt<Building>> bathhouseScratch = new ArrayExt<ArrayExt<Building>>(10);

	private ArrayExt<ArrayExt<Building>> shopScratch = new ArrayExt<ArrayExt<Building>>(10);

	private HealthInfo nullHealthInfo = new HealthInfo();

	private List<HealthInfo> landMassHealth = new List<HealthInfo>();

	private IntegrityInfo nullIntegrityInfo = new IntegrityInfo();

	private List<IntegrityInfo> landMassIntegrity = new List<IntegrityInfo>();

	public Color waterTowerHasWater = new Color(0f, 0f, 0.5f);

	public Color buildingHasWater = new Color(1f, 0f, 0f);

	public Color buildingHasWaterPartial = Color.yellow;

	public Color buildingNoWater = new Color(1f, 0f, 0f);

	public Color waterTowerHasWaterHighlight = new Color(0f, 0f, 1f);

	public Color waterTowerNoWaterHighlight = new Color(0f, 0f, 1f);

	public Color waterTowerNoWater = new Color(1f, 0f, 0f);

	public int YearsUntilDecay = 200;

	[NonSerialized]
	public int MaxBuildingDecayPerYear = int.MaxValue;

	public Material HighIntegrity;

	public Material MediumIntegrity;

	public Material LowIntegrity;

	public Material VeryLowIntegrity;

	private int decayIdx;

	private float decayCheckTime;

	public float[] taxRates;

	public UpdateBanner updateBanner;

	public Texture2D customBannerTexture2D;

	public bool usingCustomBanner;

	public Difficulty difficulty = Difficulty.Easy;

	public bool hasUsedCheats;

	[NonSerialized]
	public bool forceAchievementsWithCheats;

	private float deadBodyPlagueCooldown = 100f;

	public BuildDockCutscene BuildDockCutscenePrefab;

	internal bool seenDamPlannerIntro;

	public TourismInfo tourism = new TourismInfo();

	public ResourceAmount FocusedStorage
	{
		get
		{
			if (focusedLandMassIdx != -1)
			{
				return storagePerLandmass[focusedLandMassIdx];
			}
			return emptyAmount;
		}
	}

	public ResourceAmount FocusedResources
	{
		get
		{
			if (focusedLandMassIdx != -1)
			{
				return resourcesPerLandmass[focusedLandMassIdx];
			}
			return emptyAmount;
		}
	}

	public int FocusedLandMass => focusedLandMassIdx;

	public Governor FocusedGovenor
	{
		get
		{
			if (focusedLandMassIdx == -1)
			{
				return null;
			}
			return governors[focusedLandMassIdx];
		}
	}

	public int FocusedLandMassIdxLastValid => focusedLandMassIdxLastValid;

	public int ProsperityPoints => prosperityPoints;

	public HappinessInfo HappinessForFocusedLandMass
	{
		get
		{
			if (focusedLandMassIdx >= 0 && focusedLandMassIdx < landMassHappiness.Count)
			{
				return landMassHappiness[focusedLandMassIdx];
			}
			return nullHappinessInfo;
		}
	}

	public HealthInfo HealthForFocusedLandMass
	{
		get
		{
			if (focusedLandMassIdx >= 0 && focusedLandMassIdx < landMassHappiness.Count)
			{
				return landMassHealth[focusedLandMassIdx];
			}
			return nullHealthInfo;
		}
	}

	public IntegrityInfo IntegrityForFocusedLandMass
	{
		get
		{
			if (focusedLandMassIdx >= 0 && focusedLandMassIdx < landMassIntegrity.Count)
			{
				return landMassIntegrity[focusedLandMassIdx];
			}
			return nullIntegrityInfo;
		}
	}

	public bool CheatsEnabled
	{
		get
		{
			return hasUsedCheats;
		}
		set
		{
			hasUsedCheats = value;
			if (!value)
			{
				ResetCheatStates();
			}
		}
	}

	private int FindDockOpening(LandmassOwner a, LandmassOwner b)
	{
		if (a == null || b == null)
		{
			return -1;
		}
		for (int i = 0; i < dockOpenings.Count; i++)
		{
			if ((dockOpenings[i].teamIDa == a.teamId && dockOpenings[i].teamIDb == b.teamId) || (dockOpenings[i].teamIDa == b.teamId && dockOpenings[i].teamIDb == a.teamId))
			{
				return i;
			}
		}
		return -1;
	}

	public bool DocksOpen(LandmassOwner a, LandmassOwner b)
	{
		if (a == b)
		{
			return true;
		}
		return FindDockOpening(a, b) != -1;
	}

	public void OpenDocks(LandmassOwner a, LandmassOwner b)
	{
		if (FindDockOpening(a, b) == -1)
		{
			DockOpening item = new DockOpening
			{
				teamIDa = a.teamId,
				teamIDb = b.teamId
			};
			dockOpenings.Add(item);
			OnDocksOpenForTrade(a, b, isOpen: true);
		}
	}

	public void CloseDocks(LandmassOwner a, LandmassOwner b)
	{
		int num = FindDockOpening(a, b);
		if (num != -1)
		{
			dockOpenings.RemoveAt(num);
			OnDocksOpenForTrade(a, b, isOpen: false);
		}
	}

	public void CloseAllDocksInvolving(LandmassOwner a)
	{
		for (int i = 0; i < dockOpenings.Count; i++)
		{
			if (dockOpenings[i].teamIDa == a.teamId || dockOpenings[i].teamIDb == a.teamId)
			{
				LandmassOwner b = null;
				if (dockOpenings[i].teamIDa == a.teamId)
				{
					b = World.GetLandmassOwnerByTeamId(dockOpenings[i].teamIDb);
				}
				if (dockOpenings[i].teamIDb == a.teamId)
				{
					b = World.GetLandmassOwnerByTeamId(dockOpenings[i].teamIDa);
				}
				OnDocksOpenForTrade(a, b, isOpen: false);
				dockOpenings.RemoveAt(i);
				i--;
			}
		}
	}

	public bool IsDecorationsPack()
	{
		if (IntegrationManager.inst != null && IntegrationManager.inst.IsDLCInstalled(1764300u))
		{
			return DecorationsManager.inst != null;
		}
		return false;
	}

	public void ChangeHazardPayActive(bool active, bool warmup)
	{
		if (active)
		{
			if (warmup)
			{
				hazardPayWarmup.Enabled = true;
				hazardPayWarmup.Reset();
			}
			else
			{
				StartHazardPay();
			}
			return;
		}
		hazardPayWarmup.Enabled = false;
		if (hazardPayEffect != null)
		{
			hazardPayEffect.Done();
			hazardPayEffect = null;
		}
		PlayerLandmassOwner.hazardPay = false;
	}

	private void StartHazardPay()
	{
		PlayerLandmassOwner.hazardPay = true;
		hazardPayEffect = StatusEffectsManager.inst.StartEffect(typeof(ChamberOfWarEffect_HazardPay));
	}

	internal FieldSystem GetFruitSystem(Mesh fruitMesh, Material fruitMaterial)
	{
		for (int i = 0; i < fruitSystems.Count; i++)
		{
			if (fruitSystems[i].mesh == fruitMesh)
			{
				return fruitSystems[i];
			}
		}
		FieldSystem fieldSystem = new FieldSystem();
		fieldSystem.mesh = fruitMesh;
		fieldSystem.material = fruitMaterial;
		fieldSystem.type = 1;
		fieldSystem.debugName = "FieldSystem_Fruit_" + fruitMesh.name;
		fieldSystem.Init();
		fruitSystems.Add(fieldSystem);
		return fieldSystem;
	}

	internal FieldSystem GetFieldSystem(Mesh fruitMesh, Material fruitMaterial)
	{
		for (int i = 0; i < fieldSystems.Count; i++)
		{
			if (fieldSystems[i].mesh == fruitMesh)
			{
				return fieldSystems[i];
			}
		}
		FieldSystem fieldSystem = new FieldSystem();
		fieldSystem.mesh = fruitMesh;
		fieldSystem.material = fruitMaterial;
		fieldSystem.type = 0;
		fieldSystem.debugName = "FieldSystem_Field_" + fruitMesh.name;
		fieldSystem.Init();
		fieldSystems.Add(fieldSystem);
		return fieldSystem;
	}

	public int GetPlayerTotalResource(int rID)
	{
		if (rID == 4)
		{
			return PlayerLandmassOwner.Gold;
		}
		int num = 0;
		for (int i = 0; i < PlayerLandmassOwner.ownedLandMasses.Count; i++)
		{
			int num2 = PlayerLandmassOwner.ownedLandMasses.data[i];
			ResourceAmount resourceAmount = resourcesPerLandmass[num2];
			num += resourceAmount.Get(rID);
		}
		return num;
	}

	private void RandomizeAllBuildingColors()
	{
		for (int i = 0; i < Buildings.Count; i++)
		{
			if (Buildings.data[i] != null)
			{
				Color color = new Color(UnityEngine.Random.Range(0f, 1f), UnityEngine.Random.Range(0f, 1f), UnityEngine.Random.Range(0f, 1f), 1f);
				Buildings.data[i].SetInfoColor(color);
			}
		}
		Debug.Log($"Applied random colors to {Buildings.Count} buildings!");
	}

	private void ClearAllBuildingColors()
	{
		for (int i = 0; i < Buildings.Count; i++)
		{
			if (Buildings.data[i] != null)
			{
				Buildings.data[i].ClearInfoOverlay();
			}
		}
		Debug.Log($"Cleared colors from {Buildings.Count} buildings!");
	}

	public void RefreshVisibility(bool force)
	{
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			RefreshVisibilityFor(i, force);
		}
	}

	public void RefreshVisibilityFor(int lm, bool force)
	{
		bool visible = false;
		LandmassOwner landmassOwner = World.GetLandmassOwner(lm);
		if (landmassOwner != null)
		{
			visible = World.inst.RelationBetween(landmassOwner.teamId, 0) == World.Relations.Allies;
		}
		FogOfWar.inst.RefreshVisible(lm, visible, force);
	}

	public ArrayExt<Building> GetBuildingList(string uniqueName)
	{
		int hashCode = uniqueName.GetHashCode();
		return GetBuildingList(hashCode);
	}

	public ArrayExt<Building> GetBuildingList(int hash)
	{
		int i = 0;
		for (int count = globalBuildingRegistry.Count; i < count; i++)
		{
			if (hash == globalBuildingRegistry.data[i].uniqueNameHash)
			{
				return globalBuildingRegistry.data[i].buildings;
			}
		}
		return emptyBuildingList;
	}

	public void GetBuildingListsByCategoryForLandMass(int landMass, int categoryHash, ref ArrayExt<ArrayExt<Building>> buildingArrays)
	{
		buildingArrays.ClearFast();
		if (landMass < 0 || landMass >= landMassBuildingRegistry.Count)
		{
			return;
		}
		ArrayExt<BuildingRegistry> registry = landMassBuildingRegistry.data[landMass].registry;
		int i = 0;
		for (int count = registry.Count; i < count; i++)
		{
			if (categoryHash == registry.data[i].categoryNameHash)
			{
				buildingArrays.Add(registry.data[i].buildings);
			}
		}
	}

	public void GetBuildingListsByCategoryForLandMass(int landMass, int categoryHash, ref ArrayExt<Building> buildingArrays)
	{
		buildingArrays.ClearFast();
		if (landMass < 0 || landMass >= landMassBuildingRegistry.Count)
		{
			return;
		}
		ArrayExt<BuildingRegistry> registry = landMassBuildingRegistry.data[landMass].registry;
		int i = 0;
		for (int count = registry.Count; i < count; i++)
		{
			if (categoryHash == registry.data[i].categoryNameHash)
			{
				buildingArrays.AddRange(registry.data[i].buildings);
			}
		}
	}

	public bool DoesBuildingExistInCategoryForLandmass(int landmass, int categoryHash)
	{
		if (landmass >= 0 && landmass < landMassBuildingRegistry.Count)
		{
			ArrayExt<BuildingRegistry> registry = landMassBuildingRegistry.data[landmass].registry;
			int i = 0;
			for (int count = registry.Count; i < count; i++)
			{
				if (categoryHash == registry.data[i].categoryNameHash && registry.data[i].buildings.Count > 0)
				{
					return true;
				}
			}
		}
		return false;
	}

	public ArrayExt<Building> GetBuildingListForLandMass(int landMass, int hash)
	{
		if (landMass >= 0 && landMass < landMassBuildingRegistry.Count)
		{
			ArrayExt<BuildingRegistry> registry = landMassBuildingRegistry.data[landMass].registry;
			int i = 0;
			for (int count = registry.Count; i < count; i++)
			{
				if (hash == registry.data[i].uniqueNameHash)
				{
					return registry.data[i].buildings;
				}
			}
		}
		return emptyBuildingList;
	}

	public ArrayExt<Building> GetBuildingListForLandMassOwner(LandmassOwner owner, int hash)
	{
		ArrayExt<Building> arrayExt = new ArrayExt<Building>(32);
		for (int i = 0; i < owner.ownedLandMasses.Count; i++)
		{
			arrayExt.AddRange(GetBuildingListForLandMass(owner.ownedLandMasses.data[i], hash));
		}
		return arrayExt;
	}

	public int CountBuildingsForLandMassOwner(LandmassOwner owner, int hash)
	{
		int num = 0;
		for (int i = 0; i < owner.ownedLandMasses.Count; i++)
		{
			num += GetBuildingListForLandMass(owner.ownedLandMasses.data[i], hash).Count;
		}
		return num;
	}

	public ArrayExt<Building> GetBuildingListForLandMass(int landMass)
	{
		if (landMass >= 0 && landMass < landMassBuildingRegistry.Count)
		{
			return landMassBuildingRegistry.data[landMass].buildings;
		}
		return emptyBuildingList;
	}

	public ArrayExt<Building> GetUnbuiltBuildingListForLandMass(int landMass)
	{
		if (landMass >= 0 && landMass < unbuiltBuildingsPerLandmass.Count)
		{
			return unbuiltBuildingsPerLandmass.data[landMass];
		}
		return emptyBuildingList;
	}

	public bool AnyBuildingsOnLandMass(int landMass)
	{
		if (landMass >= 0 && landMass < landMassBuildingRegistry.Count)
		{
			ArrayExt<BuildingRegistry> registry = landMassBuildingRegistry.data[landMass].registry;
			int i = 0;
			for (int count = registry.Count; i < count; i++)
			{
				if (registry.data[i].buildings.Count > 0)
				{
					return true;
				}
			}
		}
		return false;
	}

	public bool LandMassIsAPlayerLandMass(int landmass)
	{
		return PlayerLandmassOwner.OwnsLandMass(landmass);
	}

	public bool AnyBuildingsOnPlayerLandMasses()
	{
		for (int i = 0; i < inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
		{
			int num = inst.PlayerLandmassOwner.ownedLandMasses.data[i];
			ArrayExt<BuildingRegistry> registry = landMassBuildingRegistry.data[num].registry;
			int j = 0;
			for (int count = registry.Count; j < count; j++)
			{
				if (registry.data[j].buildings.Count > 0)
				{
					return true;
				}
			}
		}
		return false;
	}

	public void ClearRegistry()
	{
		int i = 0;
		for (int count = globalBuildingRegistry.Count; i < count; i++)
		{
			globalBuildingRegistry.data[i].buildings.Clear();
		}
		globalBuildingRegistry.Clear();
		for (int j = 0; j < landMassBuildingRegistry.Count; j++)
		{
			landMassBuildingRegistry.data[j].registry.Clear();
			landMassBuildingRegistry.data[j].buildings.Clear();
		}
		for (int k = 0; k < unbuiltBuildingsPerLandmass.Count; k++)
		{
			unbuiltBuildingsPerLandmass.data[k].Clear();
		}
		unbuiltBuildingsPerLandmass.Clear();
	}

	public void AddToRegistry(ArrayExt<BuildingRegistry> buildingRegistry, Building b)
	{
		BuildingRegistry buildingRegistry2 = null;
		int uniqueNameHash = b.uniqueNameHash;
		int i = 0;
		for (int count = buildingRegistry.Count; i < count; i++)
		{
			if (uniqueNameHash == buildingRegistry.data[i].uniqueNameHash)
			{
				buildingRegistry2 = buildingRegistry.data[i];
				break;
			}
		}
		if (buildingRegistry2 == null)
		{
			buildingRegistry2 = new BuildingRegistry();
			buildingRegistry2.uniqueNameHash = uniqueNameHash;
			buildingRegistry2.categoryNameHash = b.categoryHash;
			buildingRegistry.Add(buildingRegistry2);
		}
		buildingRegistry2.buildings.Add(b);
	}

	public void RemoveFromRegistry(ArrayExt<BuildingRegistry> buildingRegistry, Building b)
	{
		int uniqueNameHash = b.uniqueNameHash;
		int i = 0;
		for (int count = buildingRegistry.Count; i < count; i++)
		{
			if (uniqueNameHash == buildingRegistry.data[i].uniqueNameHash)
			{
				buildingRegistry.data[i].buildings.RemoveSwap(b);
				break;
			}
		}
	}

	public void CurePlague()
	{
		for (int i = 0; i < Workers.Count; i++)
		{
			Workers.data[i].HealSickness();
		}
	}

	public bool DoesAnyBuildingHaveUniqueNameOnLandMass(string uniqueName, int landmass, bool mustBeBuilt)
	{
		int hashCode = uniqueName.GetHashCode();
		int i = 0;
		for (int count = landMassBuildingRegistry.data[landmass].registry.Count; i < count; i++)
		{
			BuildingRegistry buildingRegistry = landMassBuildingRegistry.data[landmass].registry.data[i];
			if (hashCode != buildingRegistry.uniqueNameHash || buildingRegistry.buildings.Count <= 0)
			{
				continue;
			}
			if (mustBeBuilt)
			{
				for (int j = 0; j < buildingRegistry.buildings.Count; j++)
				{
					if (buildingRegistry.buildings.data[j].IsBuilt())
					{
						return true;
					}
				}
				return false;
			}
			return true;
		}
		return false;
	}

	public int DoesAnyBuildingHaveCategoryOnLandMass(string category, int landmass, bool mustBeBuilt)
	{
		int num = 0;
		int hashCode = category.GetHashCode();
		int i = 0;
		for (int count = landMassBuildingRegistry.data[landmass].registry.Count; i < count; i++)
		{
			BuildingRegistry buildingRegistry = landMassBuildingRegistry.data[landmass].registry.data[i];
			if (hashCode != buildingRegistry.categoryNameHash || buildingRegistry.buildings.Count <= 0)
			{
				continue;
			}
			for (int j = 0; j < buildingRegistry.buildings.Count; j++)
			{
				if ((mustBeBuilt && buildingRegistry.buildings.data[j].IsBuilt()) || !mustBeBuilt)
				{
					num++;
				}
			}
		}
		return num;
	}

	public bool DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(string uniqueName, bool mustBeBuilt)
	{
		bool flag = false;
		for (int i = 0; i < inst.PlayerLandmassOwner.ownedLandMasses.data.Length; i++)
		{
			flag |= DoesAnyBuildingHaveUniqueNameOnLandMass(uniqueName, PlayerLandmassOwner.ownedLandMasses.data[i], mustBeBuilt);
		}
		return flag;
	}

	public bool DoesAnyBuildingHaveCategoryOnPlayerLandmass(string category, bool mustBeBuilt)
	{
		int num = 0;
		for (int i = 0; i < PlayerLandmassOwner.ownedLandMasses.data.Length; i++)
		{
			num += DoesAnyBuildingHaveCategoryOnLandMass(category, PlayerLandmassOwner.ownedLandMasses.data[i], mustBeBuilt);
		}
		return num > 0;
	}

	public Villager GetNearestWorker(Vector3 p)
	{
		Villager result = null;
		float num = float.MaxValue;
		int i = 0;
		for (int count = Workers.Count; i < count; i++)
		{
			float num2 = Mathff.DistSqrdXZ(p, Workers.data[i].Pos);
			if (num2 < num)
			{
				num = num2;
				result = Workers.data[i];
			}
		}
		return result;
	}

	public int TotalWorkers()
	{
		return Workers.Count;
	}

	public int TotalWorkersForLandMass(int landMass)
	{
		return World.inst.GetVillagersForLandMass(landMass).Count;
	}

	public int TotalResidentialSlotsOnLandMass(int landMass)
	{
		if (landMass != -1)
		{
			return housingPerLandmass[landMass];
		}
		return 0;
	}

	public Villager GetWorker(Guid id)
	{
		int i = 0;
		for (int count = Workers.Count; i < count; i++)
		{
			if (Workers.data[i].guid == id)
			{
				return Workers.data[i];
			}
		}
		return null;
	}

	public Building GetBuilding(Guid id)
	{
		Building[] data = Buildings.data;
		int i = 0;
		for (int count = Buildings.Count; i < count; i++)
		{
			if (data[i].guid == id)
			{
				return data[i];
			}
		}
		return null;
	}

	private void Awake()
	{
		inst = this;
		PlayerLandmassOwner = GetComponent<LandmassOwner>();
		HeightMarker.EnsureInitialized();
	}

	private void OnDestroy()
	{
		for (int i = 0; i < fruitSystems.Count; i++)
		{
			fruitSystems[i].Shutdown();
		}
		for (int j = 0; j < fieldSystems.Count; j++)
		{
			fieldSystems[j].Shutdown();
		}
		HeightMarker.Shutdown();
	}

	public void SetupInitialWorkers(Keep keep)
	{
		for (int i = 0; i < InitialWorkers; i++)
		{
			Villager villager = Villager.CreateVillager();
			Workers.Add(villager);
			Homeless.Add(villager);
			villager.TeleportTo(keep.transform.position + new Vector3(SRand.Range(-1.5f, 1.5f), 0f, SRand.Range(-1.5f, 1.5f)));
		}
	}

	public void Reset()
	{
		resetting = true;
		LegionSystem.Inst.CompleteJobs();
		LoadSave.ClearContinueWorld();
		poorHealthGracePeriod = 0f;
		PlayerLandmassOwner.Gold = 0;
		PooledObject.ClearAll();
		SiegeCatapult.ResetCatapults();
		SiegeMonster.ResetOgres();
		buildingDamageAnimator.Reset();
		for (int i = 0; i < fruitSystems.Count; i++)
		{
			fruitSystems[i].Clear();
		}
		for (int j = 0; j < fieldSystems.Count; j++)
		{
			fieldSystems[j].Clear();
		}
		Building.ClearDamageFlashAnimators();
		Building.ClearBuildingConstructionList();
		if (DamagedList != null)
		{
			for (int k = 0; k < DamagedList.Length; k++)
			{
				DamagedList[k].Clear();
			}
			DamagedList = null;
		}
		Broadcast.Clear();
		Broadcast.SeasonEvent.Listen(OnSeasonChanged);
		Broadcast.BuildingBuilt.ListenAny(OnBuildingBuilt);
		PopulationUI.inst.InitListeners();
		OrdersManager.inst.InitListeners();
		AmbientSfx.inst.TryInit();
		decayIdx = 0;
		ResetProsperity();
		irrigation.Reset();
		ClearRegistry();
		if ((bool)buildingContainer)
		{
			Building[] componentsInChildren = buildingContainer.transform.GetComponentsInChildren<Building>();
			for (int l = 0; l < componentsInChildren.Length; l++)
			{
				componentsInChildren[l].destroyedWhileInPlay = false;
				UnityEngine.Object.Destroy(componentsInChildren[l].gameObject);
			}
		}
		UnityEngine.Object.Destroy(buildingContainer);
		buildingContainer = new GameObject();
		buildingContainer.name = "Buildings";
		JobSystem.inst.ClearAllJobs();
		for (int m = 0; m < Workers.Count; m++)
		{
			Workers.data[m].Shutdown();
		}
		Workers.Clear();
		sick.Clear();
		int num = 0;
		for (int n = 0; n < Homeless.Count; n++)
		{
			if (!Homeless.data[n].shutdown)
			{
				num++;
			}
		}
		Homeless.Clear();
		World.inst.ResetVillagersToLandmasses();
		World.inst.RebuildVillagerGrid();
		ShipSystem.inst.Reset();
		CartSystem.inst.Reset();
		Residentials.Clear();
		Buildings.Clear();
		RadiusBonuses.Clear();
		RadiusHealthBonuses.Clear();
		WagePayers.Clear();
		FreeResourceManager.inst.Reset();
		timeAtFailHappiness = 0f;
		MaxGoldStorage = 0;
		KingdomHappiness = 100;
		landMassHappiness.Clear();
		landMassHealth.Clear();
		landMassIntegrity.Clear();
		HealthTimer.ForceExpire();
		happinessMods.Clear();
		for (int num2 = 0; num2 < plagueDeathInfo.Count; num2++)
		{
			plagueDeathInfo[num2].deathQueue.Clear();
			plagueDeathInfo[num2].deaths = 0;
			plagueDeathInfo[num2].deathTime = 0f;
			plagueDeathInfo[num2].healed = 0f;
			plagueDeathInfo[num2].plagued = 0;
		}
		OldAgeDeathQueue.Clear();
		deathsInThisYear = 0;
		ResetPerLandMassData();
		ResetTaxRates();
		Creative.inst.ResetCreativeOptions();
		PlayerLandmassOwner.ReleaseOwnership();
		LoadSave.CustomSaveData_DontAccessDirectly.Clear();
		RaiderSystem.inst.Reset();
		UnityEngine.Object.Destroy(World.inst.caveContainer);
		World.inst.HideResourceTooltipUIs();
		GameUI.inst.miniMapViewer.Reset();
		GameUI.inst.vikingNotification.Reset();
		GameUI.inst.dragonNotification.Reset();
		GameUI.inst.merchantNotification.Reset();
		FireManager.inst.ClearFires();
		if (StatusEffectsManager.inst != null)
		{
			StatusEffectsManager.inst.ClearEffects();
		}
		Tickable.Clear();
		dockOpenings.Clear();
		currProsperityTime = 0f;
		prosperityPoints = 0;
		TechnologyTree.inst.Reset();
		BuildUI.inst.Reset();
		ProsperityUI.inst.Reset();
		GodManager.inst.Reset();
		DamProjectManager.inst.Reset();
		SpeedControlUI.inst.Reset();
		MilestoneManager.inst.Reset();
		MilestoneUI.inst.Reset();
		MusicSystem.inst.Init();
		onPlayerReset?.Invoke();
		resetting = false;
	}

	public void ResetPerLandMassData()
	{
		focusedLandMassIdx = -1;
		JobSystem.inst.SetLandmassCount(World.inst.NumLandMasses);
		ResourceStatistics.inst.Reset();
		constructionPromisedResources = new ResourceAmount[World.inst.NumLandMasses];
		resourcesPerLandmass = new ResourceAmount[World.inst.NumLandMasses];
		storagePerLandmass = new ResourceAmount[World.inst.NumLandMasses];
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			constructionPromisedResources[i] = new ResourceAmount();
			resourcesPerLandmass[i] = new ResourceAmount();
			storagePerLandmass[i] = new ResourceAmount();
		}
		DecreeUI.inst.SetVisibility(v: false);
		MerchantUI.inst.SetVisibility(visible: false);
		landMassHappiness.Clear();
		while (landMassHappiness.Count < World.inst.NumLandMasses)
		{
			landMassHappiness.Add(new HappinessInfo());
		}
		landMassHealth.Clear();
		while (landMassHealth.Count < World.inst.NumLandMasses)
		{
			landMassHealth.Add(new HealthInfo());
		}
		landMassIntegrity.Clear();
		while (landMassIntegrity.Count < World.inst.NumLandMasses)
		{
			landMassIntegrity.Add(new IntegrityInfo());
		}
		landMassBuildingRegistry.Clear();
		while (landMassBuildingRegistry.Count < World.inst.NumLandMasses)
		{
			landMassBuildingRegistry.Add(new LandMassBuildingRegistry());
		}
		unbuiltBuildingsPerLandmass.Clear();
		while (unbuiltBuildingsPerLandmass.Count < World.inst.NumLandMasses)
		{
			unbuiltBuildingsPerLandmass.Add(new ArrayExt<Building>(100));
		}
		invadersPerLandmass.Clear();
		while (invadersPerLandmass.Count < World.inst.NumLandMasses)
		{
			invadersPerLandmass.Add(new ArrayExt<IMoveTarget>(64));
		}
		CanUseTools = new bool[World.inst.NumLandMasses][];
		for (int j = 0; j < World.inst.NumLandMasses; j++)
		{
			CanUseTools[j] = new bool[5];
			for (int k = 0; k < CanUseTools[j].Length; k++)
			{
				CanUseTools[j][k] = true;
			}
		}
		homeForHomelessPerLandmass = new bool[World.inst.NumLandMasses];
		Cemetery.ResetCemeteries();
		housingPerLandmass = new int[World.inst.NumLandMasses];
		ResetLandMassNames();
		FogOfWar.inst.Reset();
		ResidentialsPerLandmass = new ArrayExt<Home>[World.inst.NumLandMasses];
		for (int l = 0; l < World.inst.NumLandMasses; l++)
		{
			ResidentialsPerLandmass[l] = new ArrayExt<Home>(300);
		}
		DamagedList = new List<Building>[World.inst.NumLandMasses];
		for (int m = 0; m < DamagedList.Length; m++)
		{
			DamagedList[m] = new List<Building>();
		}
		personArrivalTimer = new Timer[World.inst.NumLandMasses];
		for (int n = 0; n < personArrivalTimer.Length; n++)
		{
			personArrivalTimer[n] = new Timer(70f);
		}
		combustionTimer = new Timer[World.inst.NumLandMasses];
		for (int num = 0; num < combustionTimer.Length; num++)
		{
			combustionTimer[num] = new Timer(30f);
		}
		nextPlagueYear = new int[World.inst.NumLandMasses];
		timeOfYearToPlague = new float[World.inst.NumLandMasses];
		while (plagueDeathInfo.Count < World.inst.NumLandMasses)
		{
			plagueDeathInfo.Add(new PlagueDeathInfo());
		}
		governors = new Governor[World.inst.NumLandMasses];
	}

	public int PlayerOwnerWorkersCount()
	{
		int num = 0;
		for (int i = 0; i < inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
		{
			num += World.inst.GetVillagersForLandMass(inst.PlayerLandmassOwner.ownedLandMasses.data[i]).Count;
		}
		return num;
	}

	public ResourceAmount CountResources(int landMass, ResourceAmount countedResources)
	{
		countedResources.Clear();
		ResourceAmount resourceAmount = constructionPromisedResources[landMass];
		resourceAmount.Clear();
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int i = 0;
		for (int count = resourceDefs.Count; i < count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			ArrayExtRef<IResourceStorage> resourceStorageListFor = FreeResourceManager.inst.GetResourceStorageListFor(resourceDef.ID, landMass);
			countedResources.Set(resourceDef.ID, 0);
			Resource resource = countedResources.FindResource(resourceDef.ID);
			int j = 0;
			for (int count2 = resourceStorageListFor.Count; j < count2; j++)
			{
				IResourceStorage resourceStorage = resourceStorageListFor.data[j];
				resource.Amount += resourceStorage.StoredPublicResources(resourceDef.ID);
			}
		}
		ArrayExt<FreeResource> freeResources = FreeResource.freeResources;
		FreeResource[] data = freeResources.data;
		int k = 0;
		for (int count3 = freeResources.Count; k < count3; k++)
		{
			FreeResource freeResource = data[k];
			if (freeResource.landMassIdx == landMass)
			{
				Villager holder = freeResource.Holder;
				Villager claim = freeResource.claim;
				if ((holder == null || !holder.consumeOnPickup) && (claim == null || !claim.consumeOnPickup))
				{
					countedResources.Add(freeResource.resourceID, 1);
				}
			}
		}
		ResourceAmount subR = new ResourceAmount();
		int num = 0;
		ArrayExt<Building> unbuiltBuildingListForLandMass = GetUnbuiltBuildingListForLandMass(landMass);
		int l = 0;
		for (int count4 = unbuiltBuildingListForLandMass.Count; l < count4; l++)
		{
			Building building = unbuiltBuildingListForLandMass.data[l];
			if (building.uniqueNameHash != num)
			{
				subR = building.GetCost(building.LandMass());
			}
			num = building.uniqueNameHash;
			ResourceAmount addR = building.ConstructionForeman.GetCollectedResources();
			ResourceAmount addR2 = building.ConstructionForeman.GetTotalPromisedBuildResources();
			countedResources.Subtract(in subR);
			countedResources.Add(in addR);
			countedResources.Add(in addR2);
			resourceAmount.Add(in subR);
			resourceAmount.Subtract(in addR);
			resourceAmount.Subtract(in addR2);
		}
		return countedResources;
	}

	public PlagueDeathInfo GetPlageDeathInfoForLandmass(int lmIdx)
	{
		if (lmIdx < 0 || lmIdx >= plagueDeathInfo.Count)
		{
			return null;
		}
		return plagueDeathInfo[lmIdx];
	}

	private void UpdateFocusedLandmass()
	{
		Vector3 trackingPos = Cam.inst.TrackingPos;
		Cell cellDataClamped = World.inst.GetCellDataClamped(trackingPos);
		int landMassIdx = cellDataClamped.landMassIdx;
		if (landMassIdx == -1)
		{
			Cell cell = World.inst.FindMatchingSurroundingCell(cellDataClamped, testOrigin: false, 5, (Cell c) => c.landMassIdx != -1);
			if (cell != null)
			{
				landMassIdx = cell.landMassIdx;
			}
		}
		if (landMassIdx != focusedLandMassIdx)
		{
			focusedLandMassIdx = landMassIdx;
		}
		if (landMassIdx != -1)
		{
			focusedLandMassIdxLastValid = landMassIdx;
		}
	}

	private void ClearLandmassHostiles(bool flush = false)
	{
		if (flush)
		{
			for (int i = 0; i < invadersPerLandmass.Count; i++)
			{
				invadersPerLandmass.data[i].Clear();
			}
		}
		else
		{
			for (int j = 0; j < invadersPerLandmass.Count; j++)
			{
				invadersPerLandmass.data[j].ClearFast();
			}
		}
	}

	private void CollectHostilesPerLandmass()
	{
		ClearLandmassHostiles();
		List<IMoveableUnit> units = OrdersManager.inst.units;
		int i = 0;
		for (int count = units.Count; i < count; i++)
		{
			IMoveableUnit moveableUnit = units[i];
			int landMassIdx = World.inst.GetCellDataClamped(moveableUnit.GetPos()).landMassIdx;
			if (!(moveableUnit is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy }))
			{
				LandmassOwner landmassOwner = World.GetLandmassOwner(landMassIdx);
				if (landmassOwner != null && landMassIdx != -1 && World.inst.RelationBetween(landmassOwner.teamId, moveableUnit.TeamID()) == World.Relations.Enemy)
				{
					invadersPerLandmass.data[landMassIdx].Add(moveableUnit as IMoveTarget);
				}
			}
		}
	}

	public ArrayExt<IMoveTarget> HostilesOnLandmass(int lm)
	{
		return invadersPerLandmass.data[lm];
	}

	private void Update()
	{
		HeightMarker.BeginFrame();
		if (!World.inst.Inited || LoadSave.Loading)
		{
			return;
		}
		float deltaTime = Time.deltaTime;
		if (ResourceAmount.empty.resources.Count > 0 && debugLogCount < 5)
		{
			Debug.LogError("readonly Resources.Empty has data and is not empty");
			debugLogCount++;
		}
		if (hazardPayWarmup.Update(deltaTime))
		{
			SfxSystem.inst.PlayFromBank("ui_recruitsoldiers", Camera.main.transform.position);
			StartHazardPay();
			hazardPayWarmup.Enabled = false;
		}
		Stack.Tick();
		FaceCamera.TickAll();
		if (loadTickDelay > 0)
		{
			loadTickDelay--;
		}
		else
		{
			Tickable.TickAll(deltaTime);
		}
		HealthBar.TickHealthBars(deltaTime);
		buildingDamageAnimator.Tick(deltaTime);
		for (int i = 0; i < fruitSystems.Count; i++)
		{
			fruitSystems[i].Tick();
		}
		for (int j = 0; j < fieldSystems.Count; j++)
		{
			fieldSystems[j].Tick();
		}
		InWorldExclamation.TickAll();
		Building.UpdateFlash();
		Building.UpdateBuildingConstruction(deltaTime);
		PooledObject.TickAll(deltaTime);
		GodDisplayIndividual.RaycastAll();
		if (MapEditorController.IsEditing)
		{
			return;
		}
		if (DynamicWater.inst.hasGoodData)
		{
			int k = 0;
			for (int count = Buildings.Count; k < count; k++)
			{
				Building building = Buildings.data[k];
				if (building.TakesWaterDamage)
				{
					building.UpdateBuildingWaterDamage(deltaTime);
				}
			}
		}
		deadBodyPlagueCooldown -= deltaTime;
		UpdateFocusedLandmass();
		CollectHostilesPerLandmass();
		if (difficulty >= Difficulty.Survival && timeAtFailHappiness <= 500f)
		{
			if (KingdomHappiness < 35)
			{
				if (timeAtFailHappiness <= 10f)
				{
					_ = timeAtFailHappiness + deltaTime;
					_ = 10f;
				}
				if (timeAtFailHappiness <= 300f)
				{
					_ = timeAtFailHappiness + deltaTime;
					_ = 300f;
				}
				if (timeAtFailHappiness <= 400f)
				{
					_ = timeAtFailHappiness + deltaTime;
					_ = 400f;
				}
				timeAtFailHappiness += deltaTime;
			}
			else
			{
				timeAtFailHappiness -= deltaTime * 2f;
			}
			if (timeAtFailHappiness < 0f)
			{
				timeAtFailHappiness = 0f;
			}
			if (timeAtFailHappiness > 500f)
			{
				GameState.inst.SetNewMode(GameState.inst.mainMenuMode);
				GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.Failure);
				TimeManager.inst.SetPaused(skipSfx: true);
			}
		}
		for (int l = 0; l < resourcesPerLandmass.Length; l++)
		{
			CountResources(l, resourcesPerLandmass[l]);
		}
		for (int m = 0; m < World.LandMassOwners.Count; m++)
		{
			LandmassOwner landmassOwner = World.LandMassOwners.data[m];
			for (int n = 0; n < landmassOwner.ownedLandMasses.Count; n++)
			{
				int num = landmassOwner.ownedLandMasses.data[n];
				resourcesPerLandmass[num].Set(4, landmassOwner.Gold);
			}
		}
		if (GameState.inst.IsPlayMode())
		{
			ProcessStarvation(deltaTime);
			UpdateHappiness();
			UpdateHealth();
			UpdateIntegrity();
			CheckForBuildingDecay(deltaTime);
			UpdateSpontaneousCombustion();
			UpdatePersonArrival(deltaTime);
			UpdateRandomEvents();
			UpdatePlague();
			UpdateTaxes();
			UpdateColdPenalty();
			UpdateGodHonor(deltaTime);
			UpdateGovernorEffects(deltaTime);
		}
		float num2 = 1f * deltaTime;
		if (StreamerEffects.Flag_SlowVillagers)
		{
			num2 /= 4f;
		}
		if (StreamerEffects.Flag_FastVillagers)
		{
			num2 *= 2f;
		}
		float rotateDistanceDt = MathF.PI * 2f * deltaTime;
		int frame = Tickable.frame;
		DeferredPersonRemoval.Clear();
		int num3 = 0;
		for (int count2 = Workers.Count; num3 < count2; num3++)
		{
			Villager villager = Workers.data[num3];
			villager.UpdateMind(deltaTime, num2, rotateDistanceDt, frame);
			if (villager.life <= 0f)
			{
				OldAgeDeathQueue.Add(villager);
			}
			else
			{
				if (!villager.sick)
				{
					continue;
				}
				PlaguedJob plaguedJob = null;
				bool flag = false;
				if (villager.job != null && villager.job is PlaguedJob plaguedJob2)
				{
					if (plaguedJob2.status == PlaguedJob.Status.Healing)
					{
						flag = true;
					}
				}
				else
				{
					villager.TrySeekShrine();
				}
				villager.healTime += (flag ? deltaTime : 0f);
				float sickTime = villager.sickTime;
				villager.sickTime += (flag ? 0f : deltaTime);
				float infectionJumpTime = GetInfectionJumpTime();
				if (villager.healTime >= villager.sickTime + infectionJumpTime * 0.75f)
				{
					if (SRand.Range(0, 100) <= 75)
					{
						villager.HealSickness();
					}
					else
					{
						this.plagueDeathInfo[villager.landMass].deathQueue.Add(villager);
					}
				}
				else if (sickTime < infectionJumpTime && villager.sickTime >= infectionJumpTime)
				{
					int v = (int)villager.Pos.x;
					int v2 = (int)villager.Pos.z;
					v = Mathff.Clamp(v, 1, World.inst.GridWidth - 2);
					v2 = Mathff.Clamp(v2, 1, World.inst.GridHeight - 2);
					int num4 = GetMaxInfectionsAttemptsPerBurst(villager.landMass);
					for (int num5 = v2 - 1; num5 <= v2 + 1; num5++)
					{
						for (int num6 = v - 1; num6 <= v + 1; num6++)
						{
							ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(num6, num5);
							for (int num7 = 0; num7 < villagersAt.Count; num7++)
							{
								if (SRand.Range(0, 100) < villager.sicknessStrength && !villagersAt.data[num7].sick)
								{
									int infectionStrength = 0;
									switch (DifficultyManager.inst.currOption.plagues)
									{
									case 1:
										infectionStrength = villager.sicknessStrength / 3;
										break;
									case 2:
										infectionStrength = villager.sicknessStrength / 3;
										break;
									case 3:
										infectionStrength = villager.sicknessStrength / 3;
										break;
									case 4:
										infectionStrength = villager.sicknessStrength / 2;
										break;
									}
									villagersAt.data[num7].BecomeSick(infectionStrength, villager.sickFromDeadBody);
									num4--;
									if (num4 <= 0)
									{
										goto end_IL_0671;
									}
								}
							}
						}
						continue;
						end_IL_0671:
						break;
					}
				}
				if (villager.sickTime > infectionJumpTime + 12f)
				{
					this.plagueDeathInfo[villager.landMass].deathQueue.Add(villager);
				}
			}
		}
		FreeResourceSystem.inst.Tick(deltaTime);
		for (int num8 = 0; num8 < World.inst.NumLandMasses; num8++)
		{
			PlagueDeathInfo plagueDeathInfo = this.plagueDeathInfo[num8];
			List<Villager> list = plagueDeathInfo.deathQueue;
			for (int num9 = 0; num9 < list.Count; num9++)
			{
				CheckProperBurialConditions(list[num9]);
				inst.DestroyPerson(list[num9], leaveBehindBody: true);
				DeferredPersonRemoval.Remove(list[num9]);
			}
			list.Clear();
			if (plagueDeathInfo.plagued <= 0)
			{
				continue;
			}
			plagueDeathInfo.deathTime += deltaTime;
			if (!(plagueDeathInfo.deathTime > 30f))
			{
				continue;
			}
			int num10 = 0;
			while (true)
			{
				if (num10 < sick.Count)
				{
					if (sick.data[num10].landMass == num8)
					{
						break;
					}
					num10++;
					continue;
				}
				NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
				{
					single = string.Format(LocalizationManager.GetTranslation("notificationui_plague_results"), plagueDeathInfo.plagued, plagueDeathInfo.deaths, plagueDeathInfo.healed)
				};
				NotificationUI.TryNotify(NotificationUI.PlagueGroup, -1, "plagueconclusion", message, NotificationStatus.Warning);
				AddHappinessMod("plaguedeaths", 60f, Mathf.Clamp(-2 * plagueDeathInfo.deaths, -50, 0), ScriptLocalization.PlayerPlagueDeathSadness, num8);
				plagueDeathInfo.deaths = 0;
				plagueDeathInfo.deathTime = 0f;
				plagueDeathInfo.plagued = 0;
				plagueDeathInfo.healed = 0f;
				break;
			}
		}
		int num11 = 0;
		for (int num12 = 0; num12 < OldAgeDeathQueue.Count; num12++)
		{
			if (World.inst.GetVillagerCountForLandmass(OldAgeDeathQueue[num12].landMass) <= 5)
			{
				continue;
			}
			Broadcast.CemeteryEvent.Broadcast(new OnCemetryEvent
			{
				eventPosition = OldAgeDeathQueue[num12].Pos,
				eventType = OnCemetryEvent.CemeteryEventType.NormalDeath
			});
			CheckProperBurialConditions(OldAgeDeathQueue[num12]);
			inst.DestroyPerson(OldAgeDeathQueue[num12], leaveBehindBody: true);
			if (!World.IsAILandmass(OldAgeDeathQueue[num12].landMass))
			{
				if (string.IsNullOrEmpty(nameForOldAgeDeath))
				{
					nameForOldAgeDeath = OldAgeDeathQueue[num12].name;
				}
				if (!string.IsNullOrEmpty(OldAgeDeathQueue[num12].CustomName))
				{
					nameForOldAgeDeath = OldAgeDeathQueue[num12].CustomName;
				}
				num11++;
			}
			DeferredPersonRemoval.Remove(OldAgeDeathQueue[num12]);
		}
		deathsInThisYear += num11;
		OldAgeDeathQueue.Clear();
		for (int num13 = 0; num13 < DeferredPersonRemoval.Count; num13++)
		{
			inst.DestroyPerson(DeferredPersonRemoval[num13], leaveBehindBody: true);
		}
		DeferredPersonRemoval.Clear();
		WaterTower.UpdateDeferredWaterTowerMapRecreation();
	}

	private void CheckProperBurialConditions(Villager villager)
	{
		if (World.inst.GetVillagersForLandMass(villager.landMass).Count < 150)
		{
			return;
		}
		ArrayExt<Cemetery> arrayExt = Cemetery.CemeteriesForLandMass(villager.landMass);
		if (arrayExt.Count <= 0)
		{
			return;
		}
		float num = 0f;
		Home home = villager.Residence as Home;
		if (home != null)
		{
			if (home.b.uniqueNameHash == World.smallHouseHash)
			{
				num = 0f;
			}
			else if (home.b.UniqueName == "smallinsula")
			{
				num = 10f;
			}
			else if (home.b.UniqueName == "mediuminsula")
			{
				num = 30f;
			}
			else if (home.b.UniqueName == "largeinsula")
			{
				num = 50f;
			}
		}
		bool flag = (float)SRand.Range(0, 100) < num;
		bool flag2 = false;
		bool flag3 = false;
		for (int i = 0; i < arrayExt.Count; i++)
		{
			if (arrayExt.data[i].b.IsBuilt() && arrayExt.data[i].GravesAvailable() > 0)
			{
				if (arrayExt.data[i].isColumbarium)
				{
					flag3 = true;
				}
				else
				{
					flag2 = true;
				}
				if (flag2 & flag3)
				{
					break;
				}
			}
		}
		if (flag && !flag2)
		{
			AddHappinessMod("notombs", 45f, -10, LocalizationManager.GetTranslation("PlayerMoreTombs"), villager.landMass);
		}
		if (!flag && !flag3)
		{
			if (inst.GetBuildingListForLandMass(villager.landMass, "columbarium".GetHashCode()).Count > 0)
			{
				AddHappinessMod("notombs", 45f, -10, LocalizationManager.GetTranslation("PlayerMoreColumbarium"), villager.landMass);
			}
			else
			{
				AddHappinessMod("notombs", 45f, -10, LocalizationManager.GetTranslation("PlayerNoColumbarium"), villager.landMass);
			}
		}
	}

	internal void SwapResidents(IResidence currResidence, Home targetHome, Villager currVillager, Villager targetVillager)
	{
		targetHome.RemoveResident(targetVillager);
		targetHome.AddResident(currVillager);
		currResidence.RemoveResident(currVillager);
		currResidence.AddResident(targetVillager);
		currVillager.ResetTiredness();
		currVillager.ResetCommute();
		targetVillager.ResetTiredness();
		targetVillager.ResetCommute();
	}

	internal bool TrySwapResidents(IResidence currResidence, Home targetHome, Villager currVillager, Vector3 homePos)
	{
		bool result = false;
		if (targetHome.GetAvailableResidentialSlots() > 0)
		{
			currVillager.Residence.RemoveResident(currVillager);
			targetHome.AddResident(currVillager);
			currVillager.ResetTiredness();
			result = true;
		}
		else
		{
			Vector3 position = targetHome.GetPosition();
			int i = 0;
			for (int count = targetHome.Residents.Count; i < count; i++)
			{
				Villager villager = targetHome.Residents[i];
				if (!(villager == currVillager))
				{
					if (villager.job == null || villager.job.idleJob)
					{
						SwapResidents(currResidence, targetHome, currVillager, villager);
						result = true;
						break;
					}
					Vector3 position2 = villager.job.employer.GetPosition();
					float num = Mathff.DistSqrdXZ(position, position2);
					if (Mathff.DistSqrdXZ(homePos, position2) <= num)
					{
						SwapResidents(currResidence, targetHome, currVillager, villager);
						result = true;
						break;
					}
				}
			}
		}
		return result;
	}

	public void OnBuildingBuilt(object sender, OnBuildingBuilt args)
	{
		Building targetBuilding = args.targetBuilding;
		if (targetBuilding.categoryHash == World.houseCategoryHash)
		{
			targetBuilding.Center();
			targetBuilding.GetComponent<Home>();
		}
	}

	public void ResetProsperity()
	{
		prosperityPoints = 0;
		currProsperityTime = 0f;
	}

	public void GiveProsperityPoints(int val)
	{
		if (val != 0)
		{
			prosperityPoints += val;
			onProsperityGained?.Invoke(val);
			onProsperityChanged?.Invoke(prosperityPoints);
		}
	}

	public void TakeProsperityPoints(int val)
	{
		if (val != 0 || prosperityPoints == 0)
		{
			prosperityPoints = Mathff.Max(0, prosperityPoints - val);
			onProsperityChanged?.Invoke(prosperityPoints);
		}
	}

	public void BuildingNowBuilt(Building b)
	{
		unbuiltBuildingsPerLandmass.data[b.LandMass()].RemoveSwap(b);
		CalcMaxResources(b, b.LandMass());
	}

	private void UpdateColdPenalty()
	{
		if (SeasonManager.GetCurrentSeason().id == 2)
		{
			if (!coldTimer.Update(Time.deltaTime))
			{
				return;
			}
			float v = SeasonManager.inst.seasonElapsedTime / (SeasonManager.inst.CurrentSeason.duration * 0.75f);
			v = Mathff.Clamp01(v);
			v *= 0.3f * Mathff.Clamp01((float)(SeasonManager.inst.CurrentYear() - 3) / 3f);
			if (!(v > 0f))
			{
				return;
			}
			float num = SeasonManager.inst.seasonElapsedTime / SeasonManager.inst.CurrentSeason.duration;
			for (int i = 0; i < World.inst.NumLandMasses; i++)
			{
				if (World.inst.GetVillagerCountForLandmass(i) <= 40)
				{
					continue;
				}
				homesAtColdRisk.ClearFast();
				for (int j = 0; j < ResidentialsPerLandmass[i].Count; j++)
				{
					Home home = ResidentialsPerLandmass[i].data[j];
					if (home.resourcesStored.Get(3) <= 0 && home.resourcesStored.Get(1) <= 0 && home.Residents.Count > 0)
					{
						homesAtColdRisk.Add(home);
					}
				}
				if (homesAtColdRisk.Count <= 0)
				{
					continue;
				}
				int num2 = Mathf.RoundToInt((float)SRand.Range(homesAtColdRisk.Count / 2, homesAtColdRisk.Count + 1) * num);
				int num3 = 0;
				Home home2 = null;
				while (num2 > 0)
				{
					Home home3 = homesAtColdRisk.RandomElement();
					List<Villager> residents = home3.Residents;
					if (residents.Count > 0 && (float)SRand.Range(0, 100) < v * 100f)
					{
						Villager p = residents[SRand.Range(0, residents.Count)];
						DestroyPerson(p, leaveBehindBody: true);
						home2 = home3;
						num3++;
					}
					num2--;
				}
				if (num3 > 0)
				{
					NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
					{
						single = string.Format(ScriptLocalization.notificationui_diedofexposurewarning, num3)
					};
					NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "colddeath", message, NotificationStatus.Warning, 20f, home2.GetComponent<Building>(), title: false, i);
				}
			}
		}
		else
		{
			coldTimer.Reset();
		}
	}

	private void UpdateGovernorEffects(float dt)
	{
		for (int i = 0; i < governors.Length; i++)
		{
			if (governors[i] != null)
			{
				governors[i].Update(dt);
			}
		}
		if (!governorEffectTimer.Update(dt))
		{
			return;
		}
		for (int j = 0; j < World.inst.NumLandMasses; j++)
		{
			Governor governor = governors[j];
			if (governor == null)
			{
				continue;
			}
			if (governor != null)
			{
				Governor.TraitInstance trait = governor.GetTrait(Traits.Happiness);
				if (trait != null)
				{
					inst.AddHappinessMod("governorbonushappiness", governorEffectTimer.Duration + 1f, trait.negative ? (-(int)trait.magnitude) : ((int)trait.magnitude), LocalizationManager.GetTranslation("happinessmod_governorbonus"), j);
				}
				float remainingTerm = governor.GetRemainingTerm();
				if (remainingTerm < 0f)
				{
					int amount = (int)Mathff.Clamp(remainingTerm / 50f, -30f, -5f);
					inst.AddHappinessMod("governortoolong", governorEffectTimer.Duration + 1f, amount, LocalizationManager.GetTranslation("happinessmod_toolonggovernor"), j);
				}
				if (governor.reappoints > 0)
				{
					int amount2 = (int)Mathff.Clamp((float)governor.reappoints * -5f, -30f, -5f);
					inst.AddHappinessMod("governortoomanyterm", governorEffectTimer.Duration + 1f, amount2, LocalizationManager.GetTranslation("happinessmod_toomanytermgovernor"), j);
				}
			}
			else if (World.inst.GetVillagersForLandMass(j).Count >= citizensGovernorReq)
			{
				inst.AddHappinessMod("nogovernorhappiness", governorEffectTimer.Duration + 1f, -20, LocalizationManager.GetTranslation("happinessmod_nogovernor"), j);
			}
		}
	}

	private void CalcHonor(string uniqueName, LandmassOwner lmo, int honorVal)
	{
		for (int i = 0; i < lmo.ownedLandMasses.Count; i++)
		{
			ArrayExt<Building> buildingListForLandMass = GetBuildingListForLandMass(lmo.ownedLandMasses.data[i], uniqueName.GetHashCode());
			for (int j = 0; j < buildingListForLandMass.Count; j++)
			{
				int dedicateIdx = buildingListForLandMass.data[j].GetComponent<Temple>().GetDedicateIdx();
				if (dedicateIdx != -1)
				{
					if (buildingListForLandMass.data[j].WorkersAllocated <= 0)
					{
						lmo.godHonor[dedicateIdx].templeNotStaffed = true;
						continue;
					}
					lmo.godHonor[dedicateIdx].honor += honorVal;
					lmo.godHonor[dedicateIdx].templeNotStaffed = false;
				}
			}
		}
	}

	public bool UpdateGodAnger(LandmassOwner lmo)
	{
		GodHonorInfo[] godHonor = lmo.godHonor;
		for (int i = 0; i < godHonor.Length; i++)
		{
			godHonor[i].honor = 0;
		}
		CalcHonor("temple", lmo, 1);
		CalcHonor("temple2", lmo, 5);
		CalcHonor("temple3", lmo, 15);
		int num = 0;
		for (int j = 0; j < lmo.ownedLandMasses.Count; j++)
		{
			num += World.inst.GetVillagersForLandMass(lmo.ownedLandMasses.data[j]).Count;
		}
		int num2 = Mathff.Clamp(num / 75, 0, 10);
		if (num > 50 && num <= 75)
		{
			num2 = 2;
		}
		lmo.angryGods.ClearFast();
		needExtraHonor.ClearFast();
		int num3 = num2 / 4;
		int num4 = 0;
		for (int k = 0; k < GodManager.numGods; k++)
		{
			if (GodManager.inst.tasks[k].Count > 0)
			{
				num4++;
			}
		}
		num2 = Mathf.Clamp(num2, 0, num4);
		for (int l = 0; l < godHonor.Length; l++)
		{
			if (godHonor[l].honor > 0)
			{
				num2--;
			}
		}
		int num5 = 0;
		for (int m = 0; m < godHonor.Length; m++)
		{
			if (godHonor[m].honor > 0)
			{
				if (num3 > 0)
				{
					if (godHonor[m].honor >= GetHonorGoal(lmo))
					{
						num5++;
					}
					else
					{
						needExtraHonor.Add(m);
					}
				}
			}
			else if (num2 > 0 && GodManager.inst.tasks[m].Count > 0)
			{
				lmo.angryGods.Add(m);
			}
		}
		if (needExtraHonor.Count > 0 && needExtraHonor.Count < num5)
		{
			int item = -1;
			int num6 = int.MinValue;
			for (int n = 0; n < needExtraHonor.Count; n++)
			{
				int honor = godHonor[needExtraHonor.data[n]].honor;
				if (honor > num6)
				{
					num6 = honor;
					item = needExtraHonor.data[n];
				}
			}
			lmo.angryGods.Add(item);
		}
		return lmo.angryGods.Count > 0;
	}

	public bool IsGodAngry(LandmassOwner lmo, int godIdx)
	{
		if (lmo != null)
		{
			return lmo.angryGods.Contains(godIdx);
		}
		return false;
	}

	private void UpdateGodHonor(float dt)
	{
		if (!godHonorTimer.Update(dt))
		{
			return;
		}
		for (int i = 0; i < World.LandMassOwners.Count; i++)
		{
			if (UpdateGodAnger(World.LandMassOwners.data[i]))
			{
				bool flag = false;
				if (GameUI.inst.currCursorMode != null)
				{
					flag = true;
				}
				if (GameUI.inst.CurrPlacementMode.IsPlacing() || BuildUI.inst.IsGroupActive())
				{
					flag = true;
				}
				if (flag)
				{
					GodManager.inst.EnsureMinCooldown(5f);
				}
				if (GameUI.inst.currCursorMode == null && !flag)
				{
					int godIdx = World.LandMassOwners.data[i].angryGods.RandomElement();
					GodManager.inst.SpawnGodAngerAtCam(godIdx);
				}
			}
		}
	}

	public int GetHonorGoal(LandmassOwner lmo)
	{
		int num = 0;
		for (int i = 0; i < lmo.ownedLandMasses.Count; i++)
		{
			num += World.inst.GetVillagersForLandMass(lmo.ownedLandMasses.data[i]).Count;
		}
		if (num >= 0 && num < 300)
		{
			return 1;
		}
		if (num >= 300 && num < 500)
		{
			return 3;
		}
		if (num >= 500 && num < 1250)
		{
			return 5;
		}
		if (num >= 1250 && num < 3000)
		{
			return 8;
		}
		return 19;
	}

	private void UpdateTaxes()
	{
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			if (GetBuildingListForLandMass(i, "taxoffice".GetHashCode()).Count == 0)
			{
				SetTaxRate(i, 0f);
			}
		}
	}

	public void CalcMaxResources(Building b, int lmFilter = -1)
	{
		if (b == null || ((bool)b && b.GetComponent<IResourceStorage>() != null))
		{
			for (int i = 0; i < World.inst.NumLandMasses; i++)
			{
				if (lmFilter != -1 && lmFilter != i)
				{
					continue;
				}
				storagePerLandmass[i] = new ResourceAmount();
				ArrayExtRef<IResourceStorage> resourceStorageListFor = FreeResourceManager.inst.GetResourceStorageListFor(i);
				int j = 0;
				for (int count = resourceStorageListFor.Count; j < count; j++)
				{
					IResourceStorage resourceStorage = resourceStorageListFor.data[j];
					List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
					int k = 0;
					for (int count2 = resourceDefs.Count; k < count2; k++)
					{
						FreeResourceSystem.ResourceDef resourceDef = resourceDefs[k];
						if (resourceStorage.StoresTypePublic(resourceDef.ID))
						{
							storagePerLandmass[i].Add(resourceDef.ID, resourceStorage.MaxStorageFor(resourceDef.ID));
						}
					}
				}
			}
		}
		if (b == null || ((bool)b && b.GetComponent<IResidence>() != null))
		{
			for (int l = 0; l < World.inst.NumLandMasses; l++)
			{
				if (lmFilter == -1 || lmFilter == l)
				{
					housingPerLandmass[l] = 0;
				}
			}
			int m = 0;
			for (int count3 = Residentials.Count; m < count3; m++)
			{
				Home home = Residentials.data[m];
				int num = home.LandMass();
				if ((home.LandMass() == lmFilter || lmFilter == -1) && home.GetComponent<Building>().IsBuilt())
				{
					housingPerLandmass[num] += home.GetTotalResidentialSlots();
				}
			}
		}
		if (b == null || b.categoryHash == "temple".GetHashCode())
		{
			for (int n = 0; n < World.LandMassOwners.Count; n++)
			{
				World.LandMassOwners.data[n].CalcMaxGold();
			}
		}
	}

	private void UpdateSpontaneousCombustion()
	{
		if (!Creative.inst.IsCreativeOptionOn(7) || DifficultyManager.inst.currOption.fires == 0)
		{
			return;
		}
		if (TotalWorkers() > 35 && !bDidFirstFire && TotalWorkers() < 45)
		{
			Ray ray = new Ray(Camera.main.transform.position, Camera.main.transform.forward);
			new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
			Cell cell = null;
			float num = float.MaxValue;
			Vector3 point = ray.GetPoint(enter);
			for (int i = 0; i < Buildings.Count; i++)
			{
				if (World.IsBurnable(Buildings.data[i]))
				{
					float num2 = Vector3.Distance(Buildings.data[i].cachedPos, point);
					if (num2 < num)
					{
						num = num2;
						cell = Buildings.data[i].GetCell();
					}
				}
			}
			if (cell != null)
			{
				FireManager.inst.StartFireAt(cell, 0, 0f, 0f, 0f);
				NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
				{
					single = ScriptLocalization.LogPlayerFireStarted
				};
				NotificationUI.TryNotify(NotificationUI.FireGroup, -1, "firstfirewarning", message, NotificationStatus.Warning, 240f);
				bDidFirstFire = true;
			}
		}
		for (int j = 0; j < World.inst.NumLandMasses; j++)
		{
			int num3 = 60;
			if (DifficultyManager.inst.currOption.fires == 2)
			{
				num3 = 55;
			}
			if (DifficultyManager.inst.currOption.fires == 3)
			{
				num3 = 50;
			}
			if (DifficultyManager.inst.currOption.fires == 4)
			{
				num3 = 45;
			}
			if (World.inst.GetVillagersForLandMass(j).Count <= num3)
			{
				continue;
			}
			Governor governor = governors[j];
			Governor.TraitInstance traitInstance = null;
			if (governor != null)
			{
				traitInstance = governor.GetTrait(Traits.FireRisk);
			}
			float num4 = 1f;
			if (traitInstance != null)
			{
				num4 = 1f + (traitInstance.negative ? traitInstance.magnitude : (0f - traitInstance.magnitude));
			}
			if (!combustionTimer[j].Update(Time.deltaTime * num4))
			{
				continue;
			}
			if (DifficultyManager.inst.currOption.fires == 1)
			{
				combustionTimer[j].Duration = SRand.Range(45, 60);
			}
			else if (DifficultyManager.inst.currOption.fires == 2)
			{
				combustionTimer[j].Duration = SRand.Range(40, 55);
			}
			else if (DifficultyManager.inst.currOption.fires == 3)
			{
				combustionTimer[j].Duration = SRand.Range(35, 50);
			}
			else if (DifficultyManager.inst.currOption.fires == 4)
			{
				combustionTimer[j].Duration = SRand.Range(30, 45);
			}
			float value = SRand.value;
			Building building = Buildings.RandomElement();
			if (building == null)
			{
				break;
			}
			int num5 = 0;
			while ((!ValidSpontaneousFireBuilding(building) || !World.IsBurnable(building)) && num5 < 30)
			{
				building = Buildings.RandomElement();
				num5++;
			}
			if (!World.IsBurnable(building) || RaiderSystem.inst.IsTargetedForBurning(building))
			{
				continue;
			}
			Cell cell2 = building.GetCell();
			float maxVigilesCoverage = building.GetMaxVigilesCoverage();
			float num6 = building.fireChance;
			float num7 = 1f - maxVigilesCoverage;
			int count = World.inst.GetVillagersForLandMass(cell2.landMassIdx).Count;
			float num8 = Mathff.Lerp(0.5f, 1f, Mathff.Clamp01(((float)count - 50f) / 500f));
			float num9 = Mathff.Lerp(0.05f, 0.15f, Mathff.Clamp01(((float)count - 50f) / 500f));
			if (traitInstance != null)
			{
				num9 *= 1f + (traitInstance.negative ? traitInstance.magnitude : (0f - traitInstance.magnitude));
				num6 *= 1f + (traitInstance.negative ? traitInstance.magnitude : (0f - traitInstance.magnitude));
				num8 *= 1f + (traitInstance.negative ? traitInstance.magnitude : (0f - traitInstance.magnitude));
				num7 *= 1f + (traitInstance.negative ? traitInstance.magnitude : (0f - traitInstance.magnitude));
			}
			num6 = Mathf.Clamp(num6, num9, num6 * num7 * num8);
			if (!(value < num6))
			{
				continue;
			}
			Fire fire = FireManager.inst.StartFireAt(cell2);
			if (fire != null)
			{
				if (count > 175 && count <= 300)
				{
					fire.PostModifyBurnout(1.5f);
				}
				if (count > 300)
				{
					fire.PostModifyBurnout(2f);
				}
				if (traitInstance == null || !traitInstance.negative)
				{
					combustionTimer[j].Duration = SRand.Range(120, 180);
				}
			}
		}
	}

	private bool ValidSpontaneousFireBuilding(Building target)
	{
		if (!(target.CategoryName == "house") && !(target.CategoryName == "shop") && !(target.CategoryName == "baker") && !(target.CategoryName == "pottery") && !(target.CategoryName == "charcoal") && !(target.UniqueName == "weaponsmith"))
		{
			return target.UniqueName == "toolsmith";
		}
		return true;
	}

	private void UpdateHappinessFromMods(float dt, ref List<int> sums)
	{
		sums.Clear();
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			sums.Add(0);
		}
		for (int j = 0; j < happinessMods.Count; j++)
		{
			HappinessMod value = happinessMods[j];
			value.time -= dt;
			happinessMods[j] = value;
			if (happinessMods[j].time < 0f)
			{
				happinessMods.RemoveAt(j);
				j--;
			}
			else
			{
				sums[happinessMods[j].landMass] += happinessMods[j].amount;
			}
		}
	}

	private void UpdateHappiness()
	{
		float deltaTime = Time.deltaTime;
		UpdateHappinessFromMods(deltaTime, ref HappinessFromMods);
		if (!HappinessTimer.Update(deltaTime))
		{
			return;
		}
		int num = 0;
		int num2 = 0;
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			if (!AnyBuildingsOnLandMass(i))
			{
				continue;
			}
			HappinessInfo happinessInfo = landMassHappiness[i];
			UpdateHomelessHappiness(i, ref happinessInfo.HappinessFromHomeless);
			GetLeisureHappiness(i, ref happinessInfo.lesiureHappiness);
			UpdateFood(i, ref happinessInfo.foodHappiness);
			UpdateDeadBodyPenalty(i, ref happinessInfo.deadBodiesPenalty);
			happinessInfo.houseHappiness = 0;
			int num3 = 0;
			for (int j = 0; j < ResidentialsPerLandmass[i].Count; j++)
			{
				Home home = ResidentialsPerLandmass[i].data[j];
				if (home.GetResidents().Count > 0)
				{
					happinessInfo.houseHappiness += home.GetHappiness();
					num3++;
				}
			}
			if (num3 > 0)
			{
				happinessInfo.houseHappiness /= num3;
			}
			else
			{
				happinessInfo.houseHappiness = 50;
			}
			happinessInfo.targetHappiness = happinessInfo.houseHappiness + happinessInfo.foodHappiness + happinessInfo.lesiureHappiness + happinessInfo.HappinessFromHomeless + happinessInfo.deadBodiesPenalty + HappinessFromMods[i];
			happinessInfo.targetHappiness = Mathff.Clamp(happinessInfo.targetHappiness, 0, 100);
			if (happinessInfo.targetHappiness > happinessInfo.currHappiness)
			{
				happinessInfo.currHappiness++;
			}
			if (happinessInfo.targetHappiness < happinessInfo.currHappiness)
			{
				happinessInfo.currHappiness--;
			}
			happinessInfo.currHappiness = Mathff.Clamp(happinessInfo.currHappiness, 0, 100);
			if (!World.IsAILandmass(i))
			{
				num += happinessInfo.currHappiness;
				num2++;
			}
			MilestoneManager.inst.CheckHappinessMilestones(i);
		}
		if (num2 > 0)
		{
			num /= num2;
			KingdomHappiness = Mathf.Clamp(num, 0, 100);
		}
	}

	private void UpdateHealth()
	{
		float deltaTime = Time.deltaTime;
		poorHealthGracePeriod += deltaTime;
		if (!HealthTimer.Update(deltaTime))
		{
			return;
		}
		bool flag = poorHealthGracePeriod > SeasonManager.inst.TimeInYear() * 5f;
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			HealthInfo healthInfo = landMassHealth[i];
			UpdateLandmassHealth(i);
			switch (HealthInfo.ToRating(healthInfo.currHealth))
			{
			case HealthInfo.HealthRating.Excellent:
				AddHappinessMod("excellentHealth", HealthTimer.Duration + 1f, 7, ScriptLocalization.PeasantsExcellentHealth, i);
				break;
			case HealthInfo.HealthRating.VeryGood:
				AddHappinessMod("goodHealth", HealthTimer.Duration + 1f, 5, ScriptLocalization.PeasantsVeryGoodHealth, i);
				break;
			case HealthInfo.HealthRating.Good:
				AddHappinessMod("goodHealth", HealthTimer.Duration + 1f, 3, ScriptLocalization.PeasantsGoodHealth, i);
				break;
			case HealthInfo.HealthRating.Fair:
			{
				int count2 = World.inst.GetVillagersForLandMass(i).Count;
				if ((count2 > 200) & flag)
				{
					AddHappinessMod("fairHealth", HealthTimer.Duration + 1f, Mathff.Clamp(-((count2 - 100) / 100) * 2, -15, -1), ScriptLocalization.PeasantsFairHealth, i);
				}
				break;
			}
			case HealthInfo.HealthRating.Poor:
			case HealthInfo.HealthRating.VeryPoor:
			{
				int count = World.inst.GetVillagersForLandMass(i).Count;
				if ((count > 200) & flag)
				{
					AddHappinessMod("poorHealth", HealthTimer.Duration + 1f, Mathff.Clamp(-((count - 100) / 100) * 3, -20, -1), ScriptLocalization.PeasantsPoorHealth, i);
				}
				if ((Creative.inst.IsCreativeOptionOn(2) & flag) && SRand.Range(0, 200) == 0 && World.inst.GetVillagerCountForLandmass(i) > 5)
				{
					Villager randomPersonForLandMass = GetRandomPersonForLandMass(i);
					if (randomPersonForLandMass != null)
					{
						DestroyPerson(randomPersonForLandMass, leaveBehindBody: false);
					}
				}
				break;
			}
			}
		}
	}

	private void UpdateIntegrity()
	{
		float deltaTime = Time.deltaTime;
		if (IntegrityTimer.Update(deltaTime))
		{
			for (int i = 0; i < World.inst.NumLandMasses; i++)
			{
				UpdateLandmassIntegrity(i);
			}
		}
	}

	public IResidence FindHappiestOpenResidentialOnLandMass(int landMass)
	{
		IResidence result = null;
		int num = 0;
		if (landMass >= 0 && landMass <= World.inst.NumLandMasses)
		{
			for (int i = 0; i < ResidentialsPerLandmass[landMass].Count; i++)
			{
				Home home = ResidentialsPerLandmass[landMass].data[i];
				if (home.Open() && home.GetAvailableResidentialSlots() > 0 && home.GetHappiness() > num)
				{
					num = home.GetHappiness();
					result = home;
				}
			}
		}
		return result;
	}

	public int GetTotalOpenResidentialSlots(int landMass)
	{
		int num = 0;
		if (landMass >= 0 && landMass <= World.inst.NumLandMasses)
		{
			for (int i = 0; i < ResidentialsPerLandmass[landMass].Count; i++)
			{
				Home home = ResidentialsPerLandmass[landMass].data[i];
				if (home.Open())
				{
					num += home.GetAvailableResidentialSlots();
				}
			}
		}
		return num;
	}

	public SettlerShip TrySettle(int landMass, int settlerProspectAmount)
	{
		if (settlerProspectAmount == 0)
		{
			return null;
		}
		Vector3 targetPos = Vector3.one;
		IResidence residence = FindHappiestOpenResidentialOnLandMass(landMass);
		if (residence != null)
		{
			targetPos = ((MonoBehaviour)residence).GetComponent<Building>().GetPos();
		}
		Dock dock = GetBuildingListForLandMass(landMass, World.dockHash).data[0]?.GetComponent<Dock>();
		if (dock != null)
		{
			targetPos = dock.dockPositions[SRand.Range(0, dock.dockPositions.Count)].Position;
		}
		if (dock == null && residence == null)
		{
			return null;
		}
		Transform transform = UnityEngine.Object.Instantiate(ShipSystem.inst.settlerShipPrefab);
		Vector3 pos = new Vector3(1f, TerrainGen.waterHeightTestThresold, 1f);
		World.inst.GetRandomPositionOnEdge(ref pos);
		transform.position = pos;
		transform.GetComponent<ShipBase>().SetPos(pos);
		SettlerShip component = transform.GetComponent<SettlerShip>();
		component.Setup(landMass, settlerProspectAmount, targetPos);
		return component;
	}

	public void AddVillager(Vector3 position)
	{
		Villager villager = Villager.CreateVillager();
		Workers.Add(villager);
		Homeless.Add(villager);
		villager.TeleportTo(position);
	}

	public void AddHappinessMod(string id, float time, int amount, string description, int landMass, bool addition = false, int max = int.MaxValue, int min = int.MinValue)
	{
		for (int i = 0; i < happinessMods.Count; i++)
		{
			if (happinessMods[i].landMass == landMass && happinessMods[i].id == id)
			{
				HappinessMod value = happinessMods[i];
				value.time = time;
				if (addition)
				{
					value.amount += amount;
				}
				else
				{
					value.amount = amount;
				}
				if (value.amount > max)
				{
					value.amount = max;
				}
				if (value.amount < min)
				{
					value.amount = min;
				}
				value.description = description;
				happinessMods[i] = value;
				return;
			}
		}
		HappinessMod item = new HappinessMod
		{
			id = id,
			time = time,
			amount = amount,
			description = description,
			landMass = landMass
		};
		happinessMods.Add(item);
	}

	public bool HasHappinessMod(string id, int landmass)
	{
		for (int i = 0; i < happinessMods.Count; i++)
		{
			if (happinessMods[i].id == id && happinessMods[i].landMass == landmass)
			{
				return true;
			}
		}
		return false;
	}

	private void UpdatePersonArrival(float dt)
	{
		for (int i = 0; i < Homeless.Count; i++)
		{
			if (Homeless.data[i].Residence != null)
			{
				Homeless.RemoveAtSwap(i);
				i = -1;
			}
		}
		for (int j = 0; j < homeForHomelessPerLandmass.Length; j++)
		{
			homeForHomelessPerLandmass[j] = true;
		}
		for (int k = 0; k < Homeless.Count; k++)
		{
			Villager villager = Homeless.data[k];
			IResidence residence = null;
			int landMass = villager.landMass;
			if (landMass >= 0 && landMass < World.inst.NumLandMasses)
			{
				if (!homeForHomelessPerLandmass[landMass])
				{
					continue;
				}
				int l = 0;
				for (int count = ResidentialsPerLandmass[landMass].Count; l < count; l++)
				{
					Home home = ResidentialsPerLandmass[landMass].data[l];
					if (home.GetAvailableResidentialSlots() > 0 && home.Open())
					{
						residence = home;
						break;
					}
				}
			}
			if (residence != null)
			{
				Homeless.RemoveAtSwap(k);
				villager.SetHome(residence);
				villager.UpdatePlacement();
				break;
			}
			homeForHomelessPerLandmass[landMass] = false;
		}
		for (int m = 0; m < World.inst.NumLandMasses; m++)
		{
			float num = 1f;
			Governor governor = governors[m];
			if (governor != null)
			{
				Governor.TraitInstance trait = governor.GetTrait(Traits.SettlerShipRate);
				if (trait != null)
				{
					num += (trait.negative ? (0f - trait.magnitude) : trait.magnitude);
				}
			}
			if (!personArrivalTimer[m].Update(dt * num))
			{
				continue;
			}
			int num2 = 0;
			LandmassOwner landmassOwner = World.GetLandmassOwner(m);
			if (landmassOwner != null)
			{
				for (int n = 0; n < landmassOwner.ownedLandMasses.Count; n++)
				{
					int num3 = landmassOwner.ownedLandMasses.data[n];
					ArrayExt<Home> arrayExt = ResidentialsPerLandmass[num3];
					for (int num4 = 0; num4 < arrayExt.Count; num4++)
					{
						num2 += arrayExt.data[num4].MaxResidents;
					}
				}
				if (AnyBuildingsOnLandMass(m) && (num2 >= 15 || SeasonManager.inst.CurrentYear() > 1))
				{
					PersonArrivalForLandMass(m);
				}
			}
			personArrivalTimer[m].Duration += 5f;
			if (personArrivalTimer[m].Duration > 100f)
			{
				personArrivalTimer[m].Duration = 100f;
			}
		}
	}

	private void OnSeasonChanged(object sender, SeasonEventData data)
	{
		if (Workers.Count >= 70 && data.SeasonDefinition.markNewYear)
		{
			NotificationUI.NotificationMessage message = default;
			string arg = string.Format((SettlerShip.totalSettledShips > 0) ? "<color=green>{0}</color>" : "<color=red>{0}</color>", SettlerShip.totalSettledShips);
			string arg2 = string.Format((SettlerShip.totalSettled > 0) ? "<color=green>{0}</color>" : "<color=red>{0}</color>", SettlerShip.totalSettled);
			message.single = string.Format(LocalizationManager.GetTranslation("YearlySettlerMessage"), arg, arg2);
			NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "settlerMessage", message, NotificationStatus.Neutral, 0f);
		}
		if (data.SeasonDefinition.markNewYear)
		{
			RaiderSystem.inst.OnNewYear();
			SettlerShip.totalSettled = 0;
			SettlerShip.totalSettledShips = 0;
		}
		if (data.SeasonDefinition.id == 1 && deathsInThisYear > 0)
		{
			if (deathsInThisYear > maxOldAgeDeaths)
			{
				maxOldAgeDeaths = deathsInThisYear;
			}
			NotificationUI.NotificationMessage message2 = default;
			if (deathsInThisYear == 1)
			{
				message2.single = string.Format(ScriptLocalization.LogPlayerOldAgeDeath, nameForOldAgeDeath);
			}
			else
			{
				message2.single = string.Format(ScriptLocalization.LogPlayerOldAgeDeathMultiple, nameForOldAgeDeath, deathsInThisYear);
			}
			NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "oldagedeath", message2);
			nameForOldAgeDeath = "";
			deathsInThisYear = 0;
		}
		AutoSave.inst.OnSeasonChange(sender, data);
	}

	private void PersonArrivalForLandMass(int landMass)
	{
		int num = Mathff.Max((int)((float)maxOldAgeDeaths * 1.1f), 35);
		int settlerProspectAmount = Mathf.Max(3, SRand.Range(3, 5) + (int)Mathf.Min((float)TotalWorkersForLandMass(landMass) * 0.075f, num));
		SettlerShip settlerShip = TrySettle(landMass, settlerProspectAmount);
		if (settlerShip != null)
		{
			string text = LandMassNames[landMass] + ": ";
			if (World.inst.NumLandMasses == 1)
			{
				text = "";
			}
			if (SeasonManager.inst.CurrentYear() < 2 && World.GetLandmassOwner(landMass) == PlayerLandmassOwner)
			{
				NotificationUI.TryNotify(NotificationUI.HomeGroup, -1, "SettlersSetSail" + landMass, new NotificationUI.NotificationMessage
				{
					single = text + LocalizationManager.GetTranslation("NotificationUI_SettlersSetSail")
				}, NotificationStatus.Neutral, -1f, settlerShip, title: false, landMass);
			}
		}
	}

	private void UpdatePlague()
	{
		bool keyDown = Input.GetKeyDown(KeyCode.P);
		if (!keyDown && (DifficultyManager.inst.currOption.plagues == 0 || !Creative.inst.IsCreativeOptionOn(4)))
		{
			return;
		}
		int num = SeasonManager.inst.CurrentYear();
		float yearProgress = SeasonManager.inst.GetYearProgress();
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			if (!keyDown && World.inst.GetVillagersForLandMass(i).Count < 200)
			{
				continue;
			}
			if (nextPlagueYear[i] <= 0)
			{
				nextPlagueYear[i] = num + 1;
				timeOfYearToPlague[i] = yearProgress;
			}
			if (num < nextPlagueYear[i] && !keyDown)
			{
				continue;
			}
			if (timeOfYearToPlague[i] <= 0f)
			{
				timeOfYearToPlague[i] = SRand.Range(Mathff.Max(0.1f, yearProgress), 0.9f);
			}
			if (yearProgress < timeOfYearToPlague[i] && !keyDown)
			{
				continue;
			}
			timeOfYearToPlague[i] = 0f;
			int min = 0;
			int max = 0;
			if (TryStartPlague(i, 0.5f))
			{
				switch (DifficultyManager.inst.currOption.plagues)
				{
				case 1:
					min = 4;
					max = 6;
					break;
				case 2:
					min = 3;
					max = 6;
					break;
				case 3:
					min = 2;
					max = 5;
					break;
				case 4:
					min = 2;
					max = 4;
					break;
				}
				plagued = 0;
				plaguedHealed = 0;
			}
			else
			{
				min = 1;
				max = 1;
			}
			nextPlagueYear[i] = num + SRand.Range(min, max);
		}
	}

	private void UpdateRandomEvents()
	{
		bool keyDown = Input.GetKeyDown(KeyCode.L);
		if ((TotalWorkers() < 40 && !keyDown) || !(randomEventTimer.Update(Time.deltaTime) | keyDown) || SRand.Range(0, 100) <= 50)
		{
			return;
		}
		int num = SRand.Range(0, 6);
		if (num < 3 || num >= 6)
		{
			return;
		}
		bool flag = DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("forester", mustBeBuilt: true);
		bool flag2 = DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("quarry", mustBeBuilt: true);
		bool flag3 = DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("well", mustBeBuilt: true);
		bool flag4 = true;
		Villager villager = null;
		int num2 = SRand.Range(0, PlayerLandmassOwner.ownedLandMasses.Count);
		for (int i = 0; i < PlayerLandmassOwner.ownedLandMasses.Count; i++)
		{
			int num3 = (i + num2) % PlayerLandmassOwner.ownedLandMasses.Count;
			int idx = PlayerLandmassOwner.ownedLandMasses.data[num3];
			if (World.inst.GetVillagerCountForLandmass(idx) > 5)
			{
				villager = World.inst.GetVillagersForLandMass(idx)?.RandomElement();
			}
		}
		if (!(villager != null))
		{
			return;
		}
		NotificationUI.NotificationMessage message = default;
		int num4 = SRand.Range(0, 6);
		switch (num4)
		{
		case 0:
			message.single = ScriptLocalization.LogPlayerDeathMysterious;
			break;
		case 1:
			message.single = ScriptLocalization.LogPlayerDeathDrowned;
			break;
		default:
			if ((num4 == 2) & flag)
			{
				message.single = ScriptLocalization.LogPlayerDeathWoodCutting;
			}
			else if ((num4 == 3) & flag2)
			{
				message.single = ScriptLocalization.LogPlayerDeathStoneCutting;
			}
			else if (num4 == 4)
			{
				message.single = ScriptLocalization.LogPlayerDeathOcean;
			}
			else if ((num4 == 5) & flag3)
			{
				message.single = ScriptLocalization.LogPlayerDeathWell;
			}
			else
			{
				flag4 = false;
			}
			break;
		}
		if (flag4)
		{
			DestroyPerson(villager, leaveBehindBody: false);
			NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "death", message, NotificationStatus.Neutral, 20f, null, title: false, villager.landMass);
		}
	}

	public int GetRandomLandmassWithMinPopulation(int minPopulation)
	{
		scratchLandmasses.ClearFast();
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			if (World.inst.GetVillagersForLandMass(i).Count >= minPopulation)
			{
				scratchLandmasses.Add(i);
			}
		}
		if (scratchLandmasses.Count == 0)
		{
			return -1;
		}
		return scratchLandmasses.RandomElement();
	}

	public float GetInfectionJumpTime()
	{
		switch (DifficultyManager.inst.currOption.plagues)
		{
		case 0:
		case 1:
			return 32f;
		case 2:
			return 32f;
		case 3:
			return 28f;
		case 4:
			return 24f;
		default:
			return 0f;
		}
	}

	public float GetPlagueSeekShrineThreshold()
	{
		return GetInfectionJumpTime() * 0.25f;
	}

	public int GetMaxInfectionsAtStart(int landmass)
	{
		return DifficultyManager.inst.currOption.plagues switch
		{
			1 => 2 + Mathff.Min(World.inst.GetVillagersForLandMass(landmass).Count / 100, 25), 
			2 => 3 + Mathff.Min(World.inst.GetVillagersForLandMass(landmass).Count / 75, 50), 
			3 => 4 + Mathff.Min(World.inst.GetVillagersForLandMass(landmass).Count / 50, 65), 
			4 => 5 + Mathff.Min(World.inst.GetVillagersForLandMass(landmass).Count / 30, 65), 
			_ => 0, 
		};
	}

	public int GetMaxInfectionsAttemptsPerBurst(int landmass)
	{
		return DifficultyManager.inst.currOption.plagues switch
		{
			1 => 1 + World.inst.GetVillagersForLandMass(landmass).Count / 3000, 
			2 => 1 + World.inst.GetVillagersForLandMass(landmass).Count / 1500, 
			3 => 2 + World.inst.GetVillagersForLandMass(landmass).Count / 1000, 
			4 => 4 + World.inst.GetVillagersForLandMass(landmass).Count / 750, 
			_ => 0, 
		};
	}

	private int GetPlagueVirulence(int landmass, float mod)
	{
		int count = World.inst.GetVillagersForLandMass(landmass).Count;
		int num = 125;
		switch (DifficultyManager.inst.currOption.plagues)
		{
		case 1:
			num = 55;
			break;
		case 2:
			num = 50;
			break;
		case 3:
			num = 40;
			break;
		case 4:
			num = 25;
			break;
		}
		int num2 = 40 + World.inst.GetVillagersForLandMass(landmass).Count / num;
		if (count > 500)
		{
			switch (HealthInfo.ToRating(landMassHealth[landmass].currHealth))
			{
			case HealthInfo.HealthRating.Excellent:
				num2 = (int)((float)num2 * 0.85f);
				break;
			case HealthInfo.HealthRating.VeryGood:
				num2 = (int)((float)num2 * 0.9f);
				break;
			case HealthInfo.HealthRating.Good:
				num2 = (int)((float)num2 * 0.95f);
				break;
			case HealthInfo.HealthRating.Fair:
				num2 = (int)((float)num2 * 1f);
				break;
			case HealthInfo.HealthRating.Poor:
			case HealthInfo.HealthRating.VeryPoor:
				num2 = (int)((float)num2 * 1.1f);
				break;
			}
		}
		num2 = Mathf.Clamp(num2, 0, 125);
		return (int)((float)num2 * mod);
	}

	public bool TryStartPlague(int landMass, float mod = 1f)
	{
		int num = 1;
		plagueEntries.ClearFast();
		scratchHouses.ClearFast();
		plagueGroups.ClearFast();
		for (int i = 0; i < num; i++)
		{
			plagueGroups.Add(new Plague
			{
				plagueChance = SRand.value * 1.1f,
				plagueStartLocations = new ArrayExt<PlagueStartLocation>(10)
			});
		}
		GetBuildingListsByCategoryForLandMass(landMass, World.houseCategoryHash, ref scratchHouses);
		for (int j = 0; j < scratchHouses.Count; j++)
		{
			ArrayExt<Building> arrayExt = scratchHouses.data[j];
			for (int k = 0; k < arrayExt.Count; k++)
			{
				Home component = arrayExt.data[k].GetComponent<Home>();
				if (component.Residents.Count == 0)
				{
					continue;
				}
				float health = component.GetHealth();
				float score = 0f;
				float avgHealth = 0f;
				for (int l = 0; l < plagueGroups.Count; l++)
				{
					if (!(health <= plagueGroups.data[l].plagueChance))
					{
						continue;
					}
					Vector3 position = component.GetPosition();
					scratchGuid.ClearFast();
					World.inst.ForEachTileTouchingRadius(position, 5f, (int x, int z, Cell cell) =>
					{
						Building building = cell.StructureFindByCategory(World.houseCategoryHash);
						if (building != null && !scratchGuid.Contains(building.guid))
						{
							Home component2 = building.GetComponent<Home>();
							if (component2.Residents.Count != 0)
							{
								scratchGuid.Add(building.guid);
								float health2 = component2.GetHealth();
								float num20 = component2.GetHealthDebuffFromFilth();
								avgHealth += health2;
								score += (0f - num20) / 20f + (1f - health2) + (float)component2.Residents.Count / 40f;
							}
						}
					});
					for (int num2 = 0; num2 < plagueGroups.Count; num2++)
					{
						Plague plague = plagueGroups.data[num2];
						if (health < plague.plagueChance)
						{
							plague.plagueStartLocations.Add(new PlagueStartLocation
							{
								pos = position,
								score = score,
								avgHealth = avgHealth / (float)scratchGuid.Count
							});
						}
					}
					break;
				}
			}
		}
		scratchDeadBodies.ClearFast();
		ArrayExt<DeadVillager> villagers = DeadVillagerSystem.inst.villagers;
		for (int num3 = 0; num3 < villagers.Count; num3++)
		{
			DeadVillager deadVillager = villagers.data[num3];
			if (deadVillager.landmass == landMass && !deadVillager.isHeld)
			{
				scratchDeadBodies.Add(deadVillager);
			}
		}
		for (int num4 = 0; num4 < plagueGroups.Count; num4++)
		{
			ArrayExt<PlagueStartLocation> plagueStartLocations = plagueGroups.data[num4].plagueStartLocations;
			for (int num5 = 0; num5 < plagueStartLocations.Count; num5++)
			{
				Vector3 pos = plagueStartLocations.data[num5].pos;
				float num6 = 1f;
				for (int num7 = 0; num7 < scratchDeadBodies.Count; num7++)
				{
					DeadVillager deadVillager2 = scratchDeadBodies.data[num7];
					float num8 = deadVillager2.Pos.x - pos.x;
					float num9 = deadVillager2.Pos.z - pos.z;
					if (num8 * num8 + num9 * num9 <= 16f)
					{
						num6 += deadVillager2.GetDangerFactor() * 2f;
					}
				}
				plagueStartLocations.data[num5].score *= num6;
			}
		}
		int maxInfectionsAtStart = GetMaxInfectionsAtStart(landMass);
		int plagueVirulence = GetPlagueVirulence(landMass, 1f);
		int num10 = 0;
		Villager villager = null;
		while (plagueGroups.Count > 0)
		{
			Plague plague2 = plagueGroups.PopLast();
			if (plague2.plagueStartLocations.Count == 0)
			{
				continue;
			}
			PlagueStartLocation plagueStartLocation = default;
			float num11 = float.MinValue;
			for (int num12 = 0; num12 < plague2.plagueStartLocations.Count; num12++)
			{
				PlagueStartLocation plagueStartLocation2 = plague2.plagueStartLocations.data[num12];
				if (plagueStartLocation2.score > num11)
				{
					num11 = plagueStartLocation2.score;
					plagueStartLocation = plagueStartLocation2;
				}
			}
			int infectionStrength = (int)((float)plagueVirulence * Mathff.Max(0.15f, 1.2f - plagueStartLocation.avgHealth));
			int num13 = Mathff.Clamp((int)plagueStartLocation.pos.x - 3, 0, World.inst.GridWidth - 1);
			int num14 = Mathff.Clamp((int)plagueStartLocation.pos.z - 3, 0, World.inst.GridHeight - 1);
			int num15 = Mathff.Clamp((int)plagueStartLocation.pos.x + 3, 0, World.inst.GridWidth - 1);
			int num16 = Mathff.Clamp((int)plagueStartLocation.pos.z + 3, 0, World.inst.GridHeight - 1);
			for (int num17 = num14; num17 <= num16; num17++)
			{
				for (int num18 = num13; num18 <= num15; num18++)
				{
					ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(num18, num17);
					for (int num19 = 0; num19 < villagersAt.Count; num19++)
					{
						if (villagersAt.data[num19].BecomeSick(infectionStrength))
						{
							num10++;
							villager = villagersAt.data[num19];
							if (num10 >= maxInfectionsAtStart)
							{
								goto end_IL_050f;
							}
							if (SRand.Range(0, 100) > 50)
							{
								break;
							}
						}
					}
				}
				continue;
				end_IL_050f:
				break;
			}
		}
		if (num10 > 0)
		{
			SfxSystem.inst.PlayFromBankIfVisible("BuildingSelectHospital", villager.Pos);
			NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
			{
				single = string.Format(ScriptLocalization.LogPlayerPlagueTakenIll, $"<color=yellow>{num10}</color>")
			};
			NotificationUI.TryNotify(NotificationUI.PlagueGroup, -1, "plagueonset", message, NotificationStatus.Warning, 0f, villager.Pos, title: false, landMass);
			AddHappinessMod("plagueonset", 50f, -15, ScriptLocalization.PlayerPlagueUnease, landMass);
			return true;
		}
		return false;
	}

	public int PlagueStartAtLocation(Vector3 pos, int infectionAmt, float mod = 1f, bool fromDeadBody = false)
	{
		Villager villager = null;
		int num = 0;
		int landMassIdx = World.inst.GetCellDataClamped(pos).landMassIdx;
		if (landMassIdx == -1)
		{
			return 0;
		}
		int num2 = (int)pos.x;
		int num3 = (int)pos.z;
		int plagueVirulence = GetPlagueVirulence(landMassIdx, mod);
		int num4 = Mathff.Clamp(num2 - 1, 0, World.inst.GridWidth - 1);
		int num5 = Mathff.Clamp(num3 - 1, 0, World.inst.GridHeight - 1);
		int num6 = Mathff.Clamp(num2 + 1, 0, World.inst.GridWidth - 1);
		int num7 = Mathff.Clamp(num3 + 1, 0, World.inst.GridHeight - 1);
		for (int i = num5; i <= num7; i++)
		{
			for (int j = num4; j <= num6; j++)
			{
				ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(j, i);
				for (int k = 0; k < villagersAt.Count; k++)
				{
					if (villagersAt.data[k].BecomeSick(plagueVirulence, fromDeadBody))
					{
						infectionAmt--;
						num++;
						villager = villagersAt.data[k];
						if (infectionAmt <= 0)
						{
							goto end_IL_0100;
						}
					}
				}
			}
			continue;
			end_IL_0100:
			break;
		}
		if (num > 0)
		{
			Cell cellData = World.inst.GetCellData(pos);
			if (cellData != null && cellData.landMassIdx > -1)
			{
				AddHappinessMod("plagueonset", 50f, -15, ScriptLocalization.PlayerPlagueUnease, cellData.landMassIdx);
				if (PlayerLandmassOwner.OwnsLandMass(cellData.landMassIdx))
				{
					MiniMapUI.inst.SetupPlaguePing(pos);
				}
			}
			if (fromDeadBody)
			{
				SfxSystem.inst.PlayFromBankOneShot("VikingHitByArrow", pos);
				SfxSystem.inst.PlayFromBankOneShot("VillagerCough", pos);
				EffectsMan.inst.GreenSmoke.CreateAndPlay(pos);
				NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
				{
					single = ScriptLocalization.LogDeadBodyPlague
				};
				NotificationUI.TryNotify(NotificationUI.PlagueGroup, -1, "deadbodyplague", message, NotificationStatus.Warning, 20f, pos, title: false, landMassIdx);
			}
			else
			{
				NotificationUI.NotificationMessage message2 = new NotificationUI.NotificationMessage
				{
					single = string.Format(ScriptLocalization.LogPlayerPlagueTakenIll, $"<color=yellow>{num}</color>")
				};
				NotificationUI.TryNotify(NotificationUI.PlagueGroup, -1, "plague", message2, NotificationStatus.Warning, 20f, villager.Pos, title: false, cellData.landMassIdx);
			}
		}
		return num;
	}

	public void PlagueStartNormal()
	{
	}

	public void PlagueStartSuper()
	{
	}

	public void DragonWarning(List<int> visitedLandmasses)
	{
		for (int i = 0; i < visitedLandmasses.Count; i++)
		{
			AddHappinessMod("afraidofdragons", 50f, -15, "ScriptLocalization.PlayerHappinessModWorriedDragons", visitedLandmasses[i]);
			if ((bool)keep)
			{
				keep.SetAdvisorMessage("dragonwarn", "interested");
			}
		}
	}

	public void DragonKill(List<int> visitedLandmasses)
	{
		for (int i = 0; i < visitedLandmasses.Count; i++)
		{
			AddHappinessMod("dragonkill", 100f, 20, "ScriptLocalization.PlayerHappinessModDragonKill", visitedLandmasses[i]);
		}
	}

	public void DragonAlmostKill(List<int> visitedLandmasses)
	{
		for (int i = 0; i < visitedLandmasses.Count; i++)
		{
			AddHappinessMod("dragonalmostkill", 100f, 10, "ScriptLocalization.PlayerHappinessModDragonDrivenAway", visitedLandmasses[i]);
			if ((bool)keep)
			{
				keep.SetAdvisorMessage("dragonnokillretreat", "mischief");
			}
		}
	}

	public void DragonEscape(List<int> visitedLandmasses)
	{
		for (int i = 0; i < visitedLandmasses.Count; i++)
		{
			AddHappinessMod("dragonescape", 50f, -25, "ScriptLocalization.PlayerHappinessModDragonAttacked", visitedLandmasses[i]);
			if ((bool)keep)
			{
				keep.SetAdvisorMessage("dragonnokill", "mischief");
			}
		}
	}

	public Villager GetRandomPersonForLandMass(int l)
	{
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(l);
		if (villagersForLandMass.Count == 0)
		{
			return null;
		}
		int num = SRand.Range(0, villagersForLandMass.Count);
		return villagersForLandMass.data[num];
	}

	private Villager GetRandomPerson()
	{
		if (Workers.Count == 0)
		{
			return null;
		}
		int num = SRand.Range(0, Workers.Count);
		return Workers.data[num];
	}

	public void RemovePersonFromWorld(Villager p)
	{
		p.QuitJob();
		p.LeaveHome();
		Workers.RemoveSwap(p);
		Homeless.RemoveSwap(p);
		World.inst.RemoveFromVillagerGrid(p, ref p.lastCell);
		World.inst.RemoveVillagerFromLandmass(p);
		p.Shutdown();
	}

	public void DestroyPerson(Villager p, bool leaveBehindBody)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(p.Pos);
		RemovePersonFromWorld(p);
		CloserHomeFinder.inst.OnPersonRemoved(p);
		if (leaveBehindBody && cellDataClamped.landMassIdx != -1)
		{
			Vector3 vector = p.Pos + new Vector3(0f, 0.1f, 0f);
			World.inst.GetCellData(vector);
			if (vector.x >= 0f && vector.x < (float)World.inst.GridWidth && vector.z >= 0f && vector.z < (float)World.inst.GridHeight)
			{
				EffectsMan.inst.GhostEffect.Alloc(vector);
				new DeadVillager(vector, Quaternion.Euler(0f, SRand.Range(0, 360), 0f), p.useLadyMesh).CopyDataFromPerson(p);
			}
		}
		p.Shutdown();
	}

	public void AbductPerson(Villager p)
	{
		p.paralyzed = true;
		RemovePersonFromWorld(p);
	}

	public void ReturnPerson(Villager p, Vector3 pos)
	{
		p.paralyzed = false;
		if (!Workers.Contains(p))
		{
			Workers.Add(p);
		}
		if (!Homeless.Contains(p))
		{
			Homeless.Add(p);
		}
		if (World.inst.GetCellDataClamped(pos).landMassIdx != -1)
		{
			p.TeleportTo(pos);
		}
		else
		{
			DestroyPerson(p, leaveBehindBody: false);
		}
	}

	private void UpdateFood(int landMass, ref int happinessFromFood)
	{
		int num = 0;
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(landMass);
		for (int i = 0; i < Residentials.Count; i++)
		{
			if (Residentials.data[i].LandMass() == landMass && Residentials.data[i].missedMeal > 0)
			{
				num++;
			}
		}
		happinessFromFood += ((num <= 0) ? 1 : (-2));
		int a = (int)Mathff.Lerp(-25f, -35f, Mathff.Clamp01(((float)villagersForLandMass.Count - 100f) / 600f));
		a = Mathff.Max(a, -(int)((float)num * 0.5f));
		happinessFromFood = Mathf.Clamp(happinessFromFood, a, 0);
	}

	private void UpdateHomelessHappiness(int landMass, ref int happinessFromHomeless)
	{
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(landMass);
		int num = 0;
		for (int i = 0; i < villagersForLandMass.Count; i++)
		{
			num += ((villagersForLandMass.data[i].Residence == null) ? 1 : 0);
		}
		if ((float)num > (float)villagersForLandMass.Count * 0.025f)
		{
			happinessFromHomeless -= 2;
		}
		else
		{
			happinessFromHomeless++;
		}
		int min = Mathf.Clamp(-1 * num, -35, 0);
		happinessFromHomeless = Mathf.Clamp(happinessFromHomeless, min, 0);
	}

	private void UpdateDeadBodyPenalty(int landMass, ref int deadBodyPenalty)
	{
		deadBodyPenalty = 0;
		ArrayExt<DeadVillager> villagers = DeadVillagerSystem.inst.villagers;
		DeadVillager[] data = villagers.data;
		for (int i = 0; i < villagers.Count; i++)
		{
			if (data[i].hasNotified && data[i].landmass == landMass && !data[i].isHeld)
			{
				deadBodyPenalty++;
			}
		}
		deadBodyPenalty = -Mathf.Clamp(deadBodyPenalty, 0, 15);
	}

	public void TryAddStarvationDeath(Villager v)
	{
		int num = (int)Mathf.Clamp((float)Workers.Count * 0.15f, 1f, Workers.Count);
		if (deathQueue.Count < num && !deathQueue.Contains(v))
		{
			deathQueue.Add(v);
		}
	}

	private void ProcessStarvation(float dt)
	{
		if (deathQueue.Count > 0)
		{
			for (int i = 0; i < deathQueue.Count; i++)
			{
				if (World.inst.GetVillagerCountForLandmass(deathQueue[i].landMass) > 5)
				{
					if (!World.IsAILandmass(deathQueue[i].landMass))
					{
						StarvationDeaths++;
						StarvationTimer = 0f;
					}
					DestroyPerson(deathQueue[i], leaveBehindBody: true);
				}
			}
			deathQueue.Clear();
		}
		if (StarvationDeaths > 0)
		{
			StarvationTimer += dt;
			if (StarvationTimer > 5f)
			{
				NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
				{
					single = string.Format(ScriptLocalization.LogPlayerStarvedToDeath, $"<color=red>{StarvationDeaths}</color>")
				};
				NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "starvedeath", message, NotificationStatus.Warning);
				StarvationDeaths = 0;
				StarvationTimer = 0f;
			}
		}
	}

	public void FeedAllForFree()
	{
	}

	public HappinessInfo GetHappinessForLandmass(int lm)
	{
		if (lm >= 0 && lm < landMassHappiness.Count)
		{
			return landMassHappiness[lm];
		}
		return null;
	}

	public HappinessInfo GetLandmassHappiness(int landmass)
	{
		return landMassHappiness[landmass];
	}

	private void GetLeisureHappiness(int landMass, ref int leisureHappiness)
	{
		landMassHappiness[landMass].shopPenalty = false;
		landMassHappiness[landMass].shopCurrScore = 0;
		landMassHappiness[landMass].shopMaxScore = 0;
		landMassHappiness[landMass].libChurchPenalty = false;
		int count = World.inst.GetVillagersForLandMass(landMass).Count;
		landMassHappiness[landMass].templePenalty = false;
		landMassHappiness[landMass].numGodsHonored = 0;
		int num = 0;
		LandmassOwner landmassOwner = World.GetLandmassOwner(landMass);
		if (landmassOwner != null)
		{
			GodHonorInfo[] godHonor = landmassOwner.godHonor;
			for (int i = 0; i < godHonor.Length; i++)
			{
				num += godHonor[i].honor;
				if (godHonor[i].honor > 0)
				{
					landMassHappiness[landMass].numGodsHonored++;
				}
			}
		}
		if (Residentials.Count >= 3 && num <= 0 && GetBuildingListForLandMass(landMass, World.farmHash).Count > 0)
		{
			landMassHappiness[landMass].templePenalty = true;
		}
		if (count > 65 && landMassHappiness[landMass].numGodsHonored < 3)
		{
			landMassHappiness[landMass].templePenalty = true;
		}
		if (count > 50)
		{
			bool flag = GetBuildingListForLandMass(landMass, "largehouse".GetHashCode()).Count > 0;
			bool flag2 = GetBuildingListForLandMass(landMass, "manorhouse".GetHashCode()).Count > 0;
			GetBuildingListsByCategoryForLandMass(landMass, "shop".GetHashCode(), ref shopScratch);
			for (int j = 0; j < shopScratch.Count; j++)
			{
				for (int k = 0; k < shopScratch.data[j].Count; k++)
				{
					landMassHappiness[landMass].shopMaxScore++;
					if (shopScratch.data[j].data[k].IsOpen())
					{
						landMassHappiness[landMass].shopCurrScore++;
					}
				}
			}
			int num2 = 0;
			for (int l = 0; l < World.inst.NumLandMasses; l++)
			{
				num2 += GetBuildingListForLandMass(l, World.joustingArenaHash).Count;
			}
			landMassHappiness[landMass].theaterPenalty = false;
			landMassHappiness[landMass].theaterCurrScore = 0;
			landMassHappiness[landMass].theaterMaxScore = 0;
			int hashCode = "smalltheater".GetHashCode();
			for (int m = 0; m < World.inst.NumLandMasses; m++)
			{
				ArrayExt<Building> buildingListForLandMass = GetBuildingListForLandMass(m, World.theaterHash);
				for (int n = 0; n < buildingListForLandMass.Count; n++)
				{
					landMassHappiness[landMass].theaterMaxScore += 2;
					if (buildingListForLandMass.data[n].IsOpen())
					{
						landMassHappiness[landMass].theaterCurrScore += 2;
					}
				}
				ArrayExt<Building> buildingListForLandMass2 = GetBuildingListForLandMass(m, hashCode);
				for (int num3 = 0; num3 < buildingListForLandMass2.Count; num3++)
				{
					landMassHappiness[landMass].theaterMaxScore++;
					if (buildingListForLandMass2.data[num3].IsOpen())
					{
						landMassHappiness[landMass].theaterCurrScore++;
					}
				}
			}
			int num4 = GetBuildingListForLandMass(landMass, "church".GetHashCode()).Count + GetBuildingListForLandMass(landMass, "cathedral".GetHashCode()).Count;
			int num5 = GetBuildingListForLandMass(landMass, "library".GetHashCode()).Count + GetBuildingListForLandMass(landMass, "greatlibrary".GetHashCode()).Count;
			GetBuildingListsByCategoryForLandMass(landMass, World.bathCategoryHash, ref bathhouseScratch);
			int num6 = 0;
			for (int num7 = 0; num7 < bathhouseScratch.Count; num7++)
			{
				ArrayExt<Building> arrayExt = bathhouseScratch.data[num7];
				for (int num8 = 0; num8 < arrayExt.Count; num8++)
				{
					if (arrayExt.data[num8].IsBuilt())
					{
						num6++;
					}
				}
			}
			landMassHappiness[landMass].forumPenalty = false;
			if (DoesAnyBuildingHaveCategoryOnLandMass(World.forumName, landMass, mustBeBuilt: false) <= 0)
			{
				landMassHappiness[landMass].forumPenalty = true;
			}
			float num9 = (((float)count > 80f) ? (Mathff.Max((float)count / 100f, 1f) - (float)landMassHappiness[landMass].shopCurrScore) : 0f);
			if ((flag | flag2) && count > 75)
			{
				Mathff.Max((float)count / 200f, 1f);
			}
			float num10 = (((float)count > 200f) ? (Mathff.Max((float)count / 100f, 1f) - (float)num6) : 0f);
			if (count >= 1200)
			{
				Mathf.Clamp01(1f - (float)num2);
			}
			float num11 = ((count >= 100) ? (Mathff.Max((float)count / 750f, 1f) - (float)landMassHappiness[landMass].theaterCurrScore) : 0f);
			bool flag3 = num9 > 0f;
			bool flag4 = false;
			bool flag5 = false;
			bool flag6 = num11 > 0f;
			landMassHappiness[landMass].shopPenalty = flag3;
			landMassHappiness[landMass].libChurchPenalty = flag4;
			landMassHappiness[landMass].bathhouseNeed = num10;
			landMassHappiness[landMass].joustingArenaPenalty = flag5;
			landMassHappiness[landMass].theaterPenalty = flag6;
			if (((flag3 | flag4) || num10 > 0f) | flag5 | flag6)
			{
				leisureHappiness--;
			}
			else
			{
				leisureHappiness++;
			}
			int num12 = 0;
			if (flag4)
			{
				num12 -= 10;
			}
			if (flag3)
			{
				num12 -= 10;
			}
			if (num10 > 0f)
			{
				num12 -= GetBathHousePenalty(num10);
			}
			if (flag5)
			{
				num12 -= 10;
			}
			if (flag6)
			{
				num12 -= 10;
			}
			leisureHappiness = Mathf.Clamp(leisureHappiness, num12, 0);
		}
		else
		{
			leisureHappiness = 0;
		}
	}

	public static int GetBathHousePenalty(float need)
	{
		return Mathff.Clamp(Mathf.CeilToInt(need / 2f) * 7, 10, 25);
	}

	public float GetCurrHealthForLandmass(int lm)
	{
		if (lm >= landMassHealth.Count)
		{
			return 0f;
		}
		return landMassHealth[lm].currHealth;
	}

	private void UpdateLandmassHealth(int landMass)
	{
		HealthInfo healthInfo = landMassHealth[landMass];
		healthInfo.HospitalClinicPenalty = false;
		int count = World.inst.GetVillagersForLandMass(landMass).Count;
		if (count > 150)
		{
			ArrayExt<Building> buildingListForLandMass = GetBuildingListForLandMass(landMass, "clinic".GetHashCode());
			int num = Mathff.Max(Mathf.FloorToInt((float)count / 400f), 1) - buildingListForLandMass.Count;
			healthInfo.HospitalClinicPenalty = num > 0;
		}
		healthInfo.houseHealth = 0f;
		int num2 = 0;
		for (int i = 0; i < ResidentialsPerLandmass[landMass].Count; i++)
		{
			Home home = ResidentialsPerLandmass[landMass].data[i];
			if (home.GetResidents().Count > 0)
			{
				healthInfo.houseHealth += home.GetHealth();
				num2++;
			}
		}
		if (num2 > 0)
		{
			healthInfo.houseHealth /= num2;
		}
		else if (count > 0 && count <= 50)
		{
			healthInfo.houseHealth = 0.5f;
		}
		else if (count > 50 && count <= 75)
		{
			healthInfo.houseHealth = 0.4f;
		}
		else if (count > 75 && count <= 100)
		{
			healthInfo.houseHealth = 0.3f;
		}
		else
		{
			healthInfo.houseHealth = 0.2f;
		}
		if (landMassHappiness[landMass].deadBodiesPenalty < 0)
		{
			healthInfo.deadBodyHealth--;
		}
		else
		{
			healthInfo.deadBodyHealth = 0;
		}
		healthInfo.deadBodyHealth = Mathff.Clamp(healthInfo.deadBodyHealth, -15, 0);
		healthInfo.currHealth = Mathf.CeilToInt(healthInfo.houseHealth * 100f) + (healthInfo.HospitalClinicPenalty ? (-5) : 0) + healthInfo.deadBodyHealth;
		healthInfo.currHealth = Mathff.Clamp(healthInfo.currHealth, 0, 100);
	}

	public IntegrityInfo GetLandmassIntegrity(int landmass)
	{
		return landMassIntegrity[landmass];
	}

	private void UpdateLandmassIntegrity(int landMass)
	{
		IntegrityInfo integrityInfo = landMassIntegrity[landMass];
		ArrayExt<Building> buildingListForLandMass = GetBuildingListForLandMass(landMass);
		int num = 0;
		int num2 = 0;
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			Building building = buildingListForLandMass.data[i];
			int num3 = 0;
			if (building.Life > 0f && (building.decayChance > 0 || building.decayChance == -1))
			{
				num3 = Mathf.RoundToInt(building.Life / building.ModifiedMaxLife * 100f);
				num3 = Mathf.Clamp(num3, 0, 100);
				num2++;
			}
			num += num3;
		}
		if (num2 > 0)
		{
			int v = ((num != 0) ? (num / num2) : 0);
			integrityInfo.currentIntegrity = Mathff.Clamp(v, 0, 100);
		}
		else
		{
			integrityInfo.currentIntegrity = 100;
		}
	}

	public void CheckForBuildingDecay(float dt)
	{
		float num = 350f / (float)Buildings.Count;
		int num2 = decayIdx;
		decayCheckTime += dt;
		int num3 = SeasonManager.inst.CurrentYear();
		while (decayCheckTime > num)
		{
			if (decayIdx >= Buildings.Count)
			{
				decayIdx = 0;
				if (num2 == decayIdx)
				{
					decayCheckTime = 0f;
					break;
				}
			}
			int num4 = decayIdx;
			Building building = Buildings.data[num4];
			if ((building.uniqueNameHash != World.damHash || !(building.GetCell().BottomStructure != building)) && building.IsBuilt() && (building.decayChance > 0 || building.decayChance == -1))
			{
				decayCheckTime -= num;
				if (building.YearBuilt + YearsUntilDecay <= num3)
				{
					int num5 = Mathf.CeilToInt(building.size.x * building.size.z * building.size.y);
					for (int i = 0; i < num5; i++)
					{
						if (building.TryApplyDecay())
						{
							break;
						}
					}
				}
			}
			decayIdx++;
			if (num2 == decayIdx)
			{
				decayCheckTime = 0f;
				break;
			}
		}
	}

	public float GetTaxRate(int landMass)
	{
		if (landMass == -1)
		{
			return 0f;
		}
		if (taxRates != null && landMass < taxRates.Length)
		{
			return taxRates[landMass];
		}
		return 0f;
	}

	public void SetTaxRate(int landMass, float taxRate)
	{
		if (landMass != -1)
		{
			if (taxRates == null || landMass >= taxRates.Length)
			{
				taxRates = new float[World.inst.NumLandMasses];
			}
			taxRates[landMass] = taxRate;
		}
	}

	public void ResetTaxRates()
	{
		taxRates = null;
	}

	public void IncreaseTaxRate(int landMass)
	{
		float taxRate = GetTaxRate(landMass);
		taxRate += 0.5f;
		if (taxRate > 3f)
		{
			taxRate = 3f;
		}
		SetTaxRate(landMass, taxRate);
	}

	public void DecreaseTaxRate(int landMass)
	{
		float taxRate = GetTaxRate(landMass);
		taxRate -= 0.5f;
		if (taxRate < 0f)
		{
			taxRate = 0f;
		}
		SetTaxRate(landMass, taxRate);
	}

	public void SetIndexedBanner(int bIdx)
	{
		if (bIdx != PlayerLandmassOwner.bannerIdx || usingCustomBanner)
		{
			PlayerLandmassOwner.SetBannerIdx(bIdx);
			BuildUI.inst.UpdateMaterials(bIdx);
			updateBanner?.Invoke();
			Texture mainTexture = PlayerLandmassOwner.UniMaterial.mainTexture;
			for (int i = 0; i < Buildings.Count; i++)
			{
				Building building = Buildings.data[i];
				for (int j = 0; j < building.fullMaterial.Count; j++)
				{
					building.fullMaterial[j].mainTexture = mainTexture;
				}
				building.UpdateMaterialSelection();
			}
		}
		usingCustomBanner = false;
	}

	public void SetCustomBannerTexture(Texture2D texture)
	{
		usingCustomBanner = true;
		customBannerTexture2D = texture;
		PlayerLandmassOwner.BannerTexture = texture;
		updateBanner?.Invoke();
	}

	public void AddBuilding(Building b)
	{
		Buildings.Add(b);
		IResourceStorage[] components = b.GetComponents<IResourceStorage>();
		for (int i = 0; i < components.Length; i++)
		{
			FreeResourceManager.inst.AddResourceStorage(components[i]);
		}
		int num = b.LandMass();
		Home component = b.GetComponent<Home>();
		if (component != null)
		{
			Residentials.Add(component);
			ResidentialsPerLandmass[num].Add(component);
		}
		WagePayer component2 = b.GetComponent<WagePayer>();
		if (component2 != null)
		{
			WagePayers.Add(component2);
		}
		RadiusBonus component3 = b.GetComponent<RadiusBonus>();
		if (component3 != null)
		{
			RadiusBonuses.Add(component3);
		}
		RadiusBonusHealth component4 = b.GetComponent<RadiusBonusHealth>();
		if (component4 != null)
		{
			RadiusHealthBonuses.Add(component4);
		}
		AddToRegistry(globalBuildingRegistry, b);
		AddToRegistry(landMassBuildingRegistry.data[num].registry, b);
		landMassBuildingRegistry.data[num].buildings.Add(b);
		if (!b.IsBuilt())
		{
			unbuiltBuildingsPerLandmass.data[num].Add(b);
		}
	}

	public void RemoveBuilding(Building b)
	{
		Buildings.RemoveSwap(b);
		IResourceStorage[] components = b.GetComponents<IResourceStorage>();
		for (int i = 0; i < components.Length; i++)
		{
			FreeResourceManager.inst.RemoveResourceStorage(components[i]);
		}
		int num = b.LandMass();
		Home component = b.GetComponent<Home>();
		if (component != null)
		{
			Residentials.RemoveSwap(component);
			ResidentialsPerLandmass[num].RemoveSwap(component);
		}
		WagePayer component2 = b.GetComponent<WagePayer>();
		if (component2 != null)
		{
			WagePayers.RemoveSwap(component2);
		}
		RadiusBonus component3 = b.GetComponent<RadiusBonus>();
		if (component3 != null)
		{
			RadiusBonuses.RemoveSwap(component3);
		}
		RadiusBonusHealth component4 = b.GetComponent<RadiusBonusHealth>();
		if (component4 != null)
		{
			RadiusHealthBonuses.RemoveSwap(component4);
		}
		RemoveFromRegistry(globalBuildingRegistry, b);
		RemoveFromRegistry(landMassBuildingRegistry.data[num].registry, b);
		landMassBuildingRegistry.data[num].buildings.RemoveSwap(b);
		unbuiltBuildingsPerLandmass.data[num].RemoveSwap(b);
		CalcMaxResources(b, num);
	}

	public bool CanUseTool(ToolUser user, int Landmass = -1)
	{
		if (Landmass == -1)
		{
			Landmass = focusedLandMassIdx;
		}
		if (CanUseTools == null || Landmass < 0)
		{
			return true;
		}
		return CanUseTools[Landmass][(int)user];
	}

	public void SetUseTool(ToolUser user, bool use)
	{
		if (FocusedLandMass >= 0)
		{
			CanUseTools[FocusedLandMass][(int)user] = use;
		}
	}

	public void SetUseTool(int landmass, ToolUser user, bool use)
	{
		if (landmass >= 0)
		{
			CanUseTools[landmass][(int)user] = use;
		}
	}

	public void ResetLandMassNames()
	{
		LandMassNames = new List<string>(World.inst.NumLandMasses);
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			LandMassNames.Add("");
		}
	}

	public string GetFocusedLandMassName()
	{
		if (FocusedLandMass == -1 || FocusedLandMass >= LandMassNames.Count)
		{
			return "ScriptLocalization.OceanName";
		}
		return LandMassNames[FocusedLandMass];
	}

	public void SetFocusedLandMassName(string name)
	{
		if (FocusedLandMass != -1)
		{
			string text = GetFocusedLandMassName();
			if (string.IsNullOrEmpty(text))
			{
				text = ScriptLocalization.PopulationUIUnnamedRegion;
			}
			if (string.IsNullOrEmpty(name))
			{
				name = ScriptLocalization.PopulationUIUnnamedRegion;
			}
			if (text != name)
			{
				SfxSystem.inst.PlayFromBank("RenameThing", Camera.main.transform.position);
				LandMassNames[FocusedLandMass] = name;
			}
		}
	}

	private void ResetCheatStates()
	{
		if (TimeManager.inst != null)
		{
			TimeManager.inst.SetPlay1(skipSfx: true);
		}
		if (KeyboardControl.inst != null)
		{
			KeyboardControl.inst.SetGameUIVisibility(visible: true);
		}
	}

	private void OnApplicationQuit()
	{
		LegionSystem.Inst.Cleanup();
	}

	public float GetTaxCollectorsEffectiveness(int lm)
	{
		if (JobSystem.jobCategoriesMap.TryGetValue(26, out var value))
		{
			return Mathff.Max((float)value.jobsFilled[lm] / (float)value.jobsAvailable[lm], 0.5f);
		}
		return 0f;
	}

	public void ReportCemeteriesFull(Building b)
	{
		b.TeamID();
		Broadcast.CemeteryEvent.Broadcast(new OnCemetryEvent
		{
			eventPosition = b.transform.position,
			eventType = OnCemetryEvent.CemeteryEventType.CemeteryFull
		});
	}

	public void ReportOldPlagueVillager(DeadVillager deadVillager)
	{
		Broadcast.CemeteryEvent.Broadcast(new OnCemetryEvent
		{
			eventPosition = deadVillager.Pos,
			eventType = OnCemetryEvent.CemeteryEventType.DeadBodyPlague
		});
		Cell cellData = World.inst.GetCellData(deadVillager.Pos);
		if (cellData != null && cellData.landMassIdx > -1 && !deadVillager.fromDeadBodyPlague && (double)SRand.value < 0.05 && inst.deadBodyPlagueCooldown < 0f && DifficultyManager.inst.currOption.plagues != 0 && Creative.inst.IsCreativeOptionOn(4) && World.inst.GetVillagersForLandMass(cellData.landMassIdx).Count >= 200 && PlagueStartAtLocation(deadVillager.Pos, GetMaxInfectionsAttemptsPerBurst(cellData.landMassIdx), 0.2f, fromDeadBody: true) > 0)
		{
			inst.deadBodyPlagueCooldown = SeasonManager.inst.TimeInYear() * 2f;
		}
	}

	internal bool AllBuildingsOfTypeStaffed(int landMass, int hash)
	{
		ArrayExt<Building> buildingListForLandMass = inst.GetBuildingListForLandMass(landMass, hash);
		int num = 0;
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			if (buildingListForLandMass.data[i].WorkersAllocated == buildingListForLandMass.data[i].WorkersForFullYield)
			{
				num++;
			}
		}
		return num == buildingListForLandMass.Count;
	}
}
