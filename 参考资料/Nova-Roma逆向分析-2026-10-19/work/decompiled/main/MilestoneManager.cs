using System;
using System.Collections.Generic;
using UnityEngine;

public class MilestoneManager : MonoBehaviour
{
	public struct MilestoneEntry
	{
		public delegate void OnCelebrate();

		public int id;

		public string achivement;

		public string titleTerm;

		public string descriptionTermUnfinished;

		public string descriptionTermFinished;

		public OnCelebrate onCelebrate;

		public bool doCelebration;

		public bool allowMultipleCelebrations;
	}

	[Serializable]
	public class MilestoneManagerSaveData : SaveClass<MilestoneManager, MilestoneManagerSaveData>
	{
		public int[] hasAchieved;

		public int legionsDefeated;

		public byte[] baselineFertility;

		public override MilestoneManagerSaveData Pack(MilestoneManager obj)
		{
			hasAchieved = new int[obj.hasAchieved.Count];
			int num = 0;
			foreach (int item in obj.hasAchieved)
			{
				hasAchieved[num++] = item;
			}
			legionsDefeated = obj.legionsDefeated;
			baselineFertility = obj.baselineFertility;
			return this;
		}

		public override MilestoneManager Unpack(MilestoneManager obj)
		{
			obj.hasAchieved = new HashSet<int>(hasAchieved);
			obj.legionsDefeated = legionsDefeated;
			obj.baselineFertility = baselineFertility;
			return obj;
		}
	}

	public static MilestoneManager inst;

	private bool isAchievementsActive;

	public const int POPULATION_01 = 100;

	public const int POPULATION_02 = 101;

	public const int POPULATION_03 = 102;

	public const int POPULATION_04 = 103;

	public const int HAPPINESS_01 = 200;

	public const int HAPPINESS_02 = 201;

	public const int HAPPINESS_03 = 202;

	public const int FIRST_TERRAINPROJECT = 300;

	public const int FIRST_AQUEDUCT = 301;

	public const int FIRST_DOCK = 302;

	public const int FIRST_COLOSSEUM_CIRCUSMAXIMUS = 303;

	public const int FIRST_PANTHEON = 304;

	public const int FIRST_TECHNOLOGY_UNLOCK = 305;

	public const int FIRST_OUTPOST = 306;

	public const int FIRST_OCCUPY_NEW_ISLAND = 307;

	public const int FIRST_DAM_PROJECT_BUILT = 308;

	public const int GOLD_01 = 400;

	public const int GOLD_02 = 401;

	public const int GOD_TASK_01 = 500;

	public const int GOD_TASK_02 = 501;

	public const int GOD_TASK_03 = 502;

	public const int GOD_TASK_04 = 503;

	public const int BATHHOUSE_SIZE_01 = 600;

	public const int BATHHOUSE_SIZE_02 = 601;

	public const int BATHHOUSE_SIZE_03 = 602;

	public const int BATHHOUSE_SIZE_04 = 603;

	public const int EXTREMELY_LARGE_DAM = 700;

	public const int INSANELY_LARGE_DAM = 701;

	public const int SURVIVE_INVASION = 703;

	public const int SURVIVE_FOREVER = 704;

	public const int LEGIONS_25 = 705;

	public const int FOOD_OMNIVORE = 706;

	public const int IRRIGATION = 707;

	public const int DEMOLISH_25 = 708;

	public const int WASTER_FOOD = 709;

	public const int DEFOREST_WORLD = 710;

	public const int ABSURD_AQUEDUCT = 711;

	public const int SURVIVE_200_YEARS = 712;

	public const int GOD_ALL_TASKS_ONE = 713;

	public const int GOD_ALL_TASKS_ALL = 714;

	public HashSet<int> hasAchieved = new HashSet<int>();

	public int legionsDefeated;

	public byte[] baselineFertility;

	[NonSerialized]
	private float lastActiveWeatherTime = float.MinValue;

	public Dictionary<int, MilestoneEntry> entries = new Dictionary<int, MilestoneEntry>(128);

	[NonSerialized]
	public float waterBeforeDam = float.MaxValue;

	[NonSerialized]
	public float timeAtDamProjectComplete = float.MinValue;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		AddMilestone(new MilestoneEntry
		{
			id = 100,
			achivement = "population_01",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 101,
			achivement = "population_02",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 102,
			achivement = "population_03",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 103,
			achivement = "population_04",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 200,
			achivement = "happiness_01",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 201,
			achivement = "happiness_02",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 202,
			achivement = "happiness_03",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 300,
			achivement = "first_terrainproject",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 301,
			achivement = "first_aqueduct",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 302,
			achivement = "first_dock",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 303,
			achivement = "first_colosseum_circusmaximus",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 304,
			achivement = "first_pantheon",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 305,
			achivement = "first_technology_unlock",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 306,
			achivement = "first_outpost",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 307,
			achivement = "first_occupy_new_island",
			doCelebration = true,
			allowMultipleCelebrations = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 308,
			achivement = "first_dam_project_built",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 400,
			achivement = "gold_01",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 401,
			achivement = "gold_02",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 500,
			achivement = "god_task_01",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 501,
			achivement = "god_task_02",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 502,
			achivement = "god_task_03",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 503,
			achivement = "god_task_04",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 600,
			achivement = "bathhouse_size_01",
			doCelebration = true
		});
		AddMilestone(new MilestoneEntry
		{
			id = 601,
			achivement = "bathhouse_size_02",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 602,
			achivement = "bathhouse_size_03",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 603,
			achivement = "bathhouse_size_04",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 700,
			achivement = "extremely_large_dam",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 701,
			achivement = "insanely_large_dam",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 703,
			achivement = "survive_invasion",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 704,
			achivement = "survive_forever",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 705,
			achivement = "legions_25",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 706,
			achivement = "food_omnivore",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 707,
			achivement = "irrigation",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 708,
			achivement = "demolish_25_buildings",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 709,
			achivement = "waster_food_loss",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 710,
			achivement = "deforest_world",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 711,
			achivement = "absurd_aqueduct",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 712,
			achivement = "survive_200_years",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 713,
			achivement = "god_all_tasks_one",
			doCelebration = false
		});
		AddMilestone(new MilestoneEntry
		{
			id = 714,
			achivement = "god_all_tasks_all",
			doCelebration = false
		});
		UnitSystem.inst.OnUnitKilled += OnUnitKilled;
	}

	public void Reset()
	{
		hasAchieved.Clear();
		legionsDefeated = 0;
		baselineFertility = null;
		lastActiveWeatherTime = Time.time;
	}

	private void AddMilestone(MilestoneEntry entry)
	{
		entry.titleTerm = "milestoneui_" + entry.achivement + "_title";
		entry.descriptionTermUnfinished = "milestoneui_" + entry.achivement + "_locked_description";
		entry.descriptionTermFinished = "milestoneui_" + entry.achivement + "_unlocked_description";
		if (!entries.TryAdd(entry.id, entry))
		{
			Debug.LogError($"Trying to add milestone id:{entry.id} more than once!");
		}
	}

	public bool TryGetEntry(int id, out MilestoneEntry entry)
	{
		return entries.TryGetValue(id, out entry);
	}

	private bool TryUnlockMilestone(int id)
	{
		if (!entries.TryGetValue(id, out var value) || !GameState.inst.IsPlayMode())
		{
			return false;
		}
		if ((!Player.inst.hasUsedCheats || Player.inst.forceAchievementsWithCheats) && IntegrationManager.inst.UseAchievements())
		{
			IntegrationManager.inst.SetAchievement(value.achivement);
		}
		if (!hasAchieved.Contains(id))
		{
			hasAchieved.Add(id);
			if (value.doCelebration)
			{
				MilestoneUI.inst.ShowMilestone(id);
			}
			return true;
		}
		if (value.doCelebration && value.allowMultipleCelebrations)
		{
			MilestoneUI.inst.ShowMilestone(id);
			return true;
		}
		return false;
	}

	public void CheckPopulationMilestones(int landmass)
	{
		int num = Player.inst.TotalWorkersForLandMass(landmass);
		if (num > 0 && Player.inst.PlayerLandmassOwner.OwnsLandMass(landmass))
		{
			int startingLandmass = GetStartingLandmass();
			if (startingLandmass != -1 && landmass != startingLandmass)
			{
				TryUnlockMilestone(307);
			}
		}
		if (num >= 100)
		{
			TryUnlockMilestone(100);
		}
		if (num >= 500)
		{
			TryUnlockMilestone(101);
		}
		if (num >= 1000)
		{
			TryUnlockMilestone(102);
		}
		if (num >= 5000)
		{
			TryUnlockMilestone(103);
		}
	}

	public void CheckHappinessMilestones(int landmass)
	{
		Player.HappinessInfo happinessForLandmass = Player.inst.GetHappinessForLandmass(landmass);
		if (Player.inst.TotalWorkersForLandMass(landmass) >= 50)
		{
			if ((float)happinessForLandmass.currHappiness >= 80f && (float)happinessForLandmass.targetHappiness >= 80f)
			{
				TryUnlockMilestone(200);
			}
			if ((float)happinessForLandmass.currHappiness >= 90f && (float)happinessForLandmass.targetHappiness >= 90f)
			{
				TryUnlockMilestone(201);
			}
			if ((float)happinessForLandmass.currHappiness >= 100f && (float)happinessForLandmass.targetHappiness >= 100f)
			{
				TryUnlockMilestone(202);
			}
		}
	}

	public void CheckGoldMilestones()
	{
		LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
		if (playerLandmassOwner.Gold >= 1000)
		{
			TryUnlockMilestone(400);
		}
		if (playerLandmassOwner.Gold >= 5000)
		{
			TryUnlockMilestone(401);
		}
	}

	public void CheckForGodTaskMilestones()
	{
		int tasksComplete = GodManager.inst.tasksComplete;
		if (tasksComplete >= 10)
		{
			TryUnlockMilestone(500);
		}
		if (tasksComplete >= 50)
		{
			TryUnlockMilestone(501);
		}
	}

	public void CheckBathhouseSizeMilestones(BathManager.BathGroup bGroup)
	{
		int totalBathBuildings = bGroup.GetTotalBathBuildings();
		if (totalBathBuildings >= 8)
		{
			TryUnlockMilestone(600);
		}
		if (totalBathBuildings >= 25)
		{
			TryUnlockMilestone(601);
		}
		if (totalBathBuildings >= 50)
		{
			TryUnlockMilestone(602);
		}
		if (totalBathBuildings >= 100)
		{
			TryUnlockMilestone(603);
		}
	}

	public void CheckForDamSizes()
	{
		if (DynamicWater.inst.totalWater >= 1000f)
		{
			TryUnlockMilestone(700);
		}
		if (DynamicWater.inst.totalWater >= 5000f)
		{
			TryUnlockMilestone(701);
		}
	}

	public void CheckFirstFunctionalDam()
	{
		if (DynamicWater.inst.waterSimulationStable && DynamicWater.inst.totalWater - waterBeforeDam >= 5f && Time.time - timeAtDamProjectComplete <= 200f)
		{
			TryUnlockMilestone(308);
		}
	}

	public void TryFirstTerrainProjectMilestone()
	{
		TryUnlockMilestone(300);
	}

	public void TryFirstAqueductMilestone()
	{
		TryUnlockMilestone(301);
	}

	public void TryFirstOutpostMilestone()
	{
		TryUnlockMilestone(306);
	}

	public void TryFirstDamProjectBuiltMilestone()
	{
		TryUnlockMilestone(308);
	}

	public void TryFirstOccupyNewIsland()
	{
		TryUnlockMilestone(307);
	}

	public void TryFirstDockMilestone()
	{
		TryUnlockMilestone(302);
	}

	public void TryFirstColosseum()
	{
		TryUnlockMilestone(303);
	}

	public void TryFirstPantheonMilestone()
	{
		TryUnlockMilestone(304);
	}

	public void TryFirstTechnologyUnlocked()
	{
		TryUnlockMilestone(305);
	}

	public void TrySurviveInvasionMilestone()
	{
		TryUnlockMilestone(703);
	}

	public void TrySurviveForeverMilestone()
	{
		TryUnlockMilestone(704);
	}

	public void CheckLegionsDefeatedMilestone()
	{
		if (legionsDefeated >= 25)
		{
			TryUnlockMilestone(705);
		}
	}

	public void TryFoodOmnivoreMilestone()
	{
		TryUnlockMilestone(706);
	}

	public void CheckIrrigationMilestone()
	{
		if (!GameState.inst.IsPlayMode())
		{
			return;
		}
		if (hasAchieved.Contains(707))
		{
			if (IntegrationManager.inst.UseAchievements())
			{
				TryUnlockMilestone(707);
			}
		}
		else if (SeasonManager.inst.CurrWeather != SeasonManager.WeatherType.None)
		{
			lastActiveWeatherTime = Time.time;
		}
		else
		{
			if (GameUI.inst.TerrainWaterEditModeActive() || Time.time - lastActiveWeatherTime < 60f || !DynamicWater.inst.waterSimulationStable)
			{
				return;
			}
			int[] fertility = TerrainGen.inst.Fertility;
			if (fertility == null)
			{
				return;
			}
			if (baselineFertility == null || baselineFertility.Length != fertility.Length)
			{
				baselineFertility = new byte[fertility.Length];
				for (int i = 0; i < fertility.Length; i++)
				{
					baselineFertility[i] = (byte)fertility[i];
				}
				Debug.Log("[Irrigation] Baseline fertility snapshot recorded");
				return;
			}
			int num = 0;
			for (int j = 0; j < fertility.Length; j++)
			{
				if (fertility[j] > baselineFertility[j])
				{
					num++;
				}
				else if (fertility[j] < baselineFertility[j])
				{
					num--;
				}
			}
			if (num >= 100)
			{
				Debug.Log($"[Irrigation] Unlocked: net {num} cells improved above their baseline fertility");
				TryUnlockMilestone(707);
			}
		}
	}

	public void CheckDemolish25AtOnceMilestone(int count)
	{
		if (count >= 25)
		{
			TryUnlockMilestone(708);
		}
	}

	public void TryWasterFoodMilestone()
	{
		TryUnlockMilestone(709);
	}

	public void TryDeforestWorldMilestone()
	{
		TryUnlockMilestone(710);
	}

	public void CheckAbsurdAqueductMilestone(int numberOfConstructions)
	{
		if (numberOfConstructions >= 275)
		{
			TryUnlockMilestone(711);
		}
	}

	public void CheckSurvive200YearsMilestone(int year)
	{
		if (year >= 200)
		{
			TryUnlockMilestone(712);
		}
	}

	public void TryGodAllTasksOneMilestone()
	{
		TryUnlockMilestone(713);
	}

	public void TryGodAllTasksAllMilestone()
	{
		TryUnlockMilestone(714);
	}

	private void OnUnitKilled(IUnitControllable unit, int killerTeamID)
	{
		if (killerTeamID == 0 && unit is LegionUnit && unit.TeamID() != 0)
		{
			legionsDefeated++;
			CheckLegionsDefeatedMilestone();
		}
	}

	private int GetStartingLandmass()
	{
		ArrayExt<int> arrayExt = Player.inst?.PlayerLandmassOwner?.ownedLandMasses;
		if (arrayExt != null && arrayExt.Count > 0)
		{
			return arrayExt.data[0];
		}
		return -1;
	}
}
