using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using UnityEngine;

public class DifficultyManager : MonoBehaviour
{
	public enum Frequency
	{
		Never,
		Low,
		Medium,
		High,
		VeryHigh,
		NumOptions
	}

	public struct DifficultyEntry
	{
		public int id;

		public string name;
	}

	[Serializable]
	public class DifficultySaveData : SaveClass<DifficultyManager, DifficultySaveData>
	{
		public int difficulty;

		public bool isInvasionsEnabled;

		public float invasionEscalationMultiplier = 1f;

		public int invasionFrequencyChoice;

		public int minInvasionFrequency = 7;

		public int maxInvasionFrequency = 9;

		public int invasionStartYear = 4;

		public bool deescalateOnObjectiveComplete = true;

		public bool invadersAttackBuildings;

		public int maxShipEscalation = 1;

		public float yearPointsDivider = 25f;

		public float citizenPercentToOverridePoints = 0.1f;

		public int maxInvasionPoints = 325;

		public bool distributeInvasionPerLandmassPopulation = true;

		public int goldStealAmount = 100;

		public bool limitedResources;

		public bool unlimitedResources = true;

		public int merchantVisitFrequencyChoice;

		public int minMerchantInterval = 210;

		public int maxMerchantInterval = 270;

		public int floodingFrequency;

		public int droughFrequency;

		public int testDropdownIndex;

		public int fires = 1;

		public int invasionIntensityChoice = 1;

		public int godWrath;

		public int foodConsumption;

		public int plagues = 1;

		public override DifficultySaveData Pack(DifficultyManager obj)
		{
			isInvasionsEnabled = obj.currOption.isInvasionsEnabled;
			invasionIntensityChoice = obj.currOption.invasionIntensityChoice;
			invasionFrequencyChoice = obj.currOption.invasionFrequencyChoice;
			minInvasionFrequency = obj.currOption.minInvasionFrequency;
			maxInvasionFrequency = obj.currOption.maxInvasionFrequency;
			invasionStartYear = obj.currOption.invasionStartYear;
			unlimitedResources = obj.currOption.unlimitedResources;
			merchantVisitFrequencyChoice = obj.currOption.merchantVisitFrequencyChoice;
			minMerchantInterval = obj.currOption.minMerchantInterval;
			maxMerchantInterval = obj.currOption.maxMerchantInterval;
			floodingFrequency = obj.currOption.floodingFrequency;
			droughFrequency = obj.currOption.droughtFrequency;
			fires = obj.currOption.fires;
			godWrath = obj.currOption.godWrath;
			foodConsumption = obj.currOption.foodConsumption;
			plagues = obj.currOption.plagues;
			return this;
		}

		public override DifficultyManager Unpack(DifficultyManager obj)
		{
			obj.currOption.isInvasionsEnabled = isInvasionsEnabled;
			obj.currOption.invasionIntensityChoice = invasionIntensityChoice;
			obj.currOption.invasionFrequencyChoice = invasionFrequencyChoice;
			obj.currOption.minInvasionFrequency = minInvasionFrequency;
			obj.currOption.maxInvasionFrequency = maxInvasionFrequency;
			obj.currOption.invasionStartYear = invasionStartYear;
			obj.currOption.unlimitedResources = unlimitedResources;
			obj.currOption.merchantVisitFrequencyChoice = merchantVisitFrequencyChoice;
			obj.currOption.minMerchantInterval = minMerchantInterval;
			obj.currOption.maxMerchantInterval = maxMerchantInterval;
			obj.currOption.floodingFrequency = floodingFrequency;
			obj.currOption.droughtFrequency = droughFrequency;
			obj.currOption.fires = fires;
			obj.currOption.foodConsumption = foodConsumption;
			obj.currOption.godWrath = godWrath;
			obj.currOption.plagues = plagues;
			int num = 5;
			foreach (KeyValuePair<int, DifficultyOption> option in obj.options)
			{
				if (option.Key != 5 && option.Value.IsIdentical(obj.currOption))
				{
					num = option.Key;
					break;
				}
			}
			obj.difficulty = num;
			return obj;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			fires = 1;
			droughFrequency = 1;
			floodingFrequency = 1;
			invasionIntensityChoice = 1;
			godWrath = 1;
			foodConsumption = 1;
			unlimitedResources = true;
			plagues = 1;
		}
	}

	public static DifficultyManager inst;

	public DifficultyOption currOption;

	public Dictionary<int, DifficultyOption> options = new Dictionary<int, DifficultyOption>();

	public int difficulty = 1;

	public static List<DifficultyEntry> Difficulties = new List<DifficultyEntry>(16);

	public static Dictionary<int, int> DifficultiesIndexMap = new Dictionary<int, int>(16);

	private void Awake()
	{
		inst = this;
		AddOption(0, Resources.Load<DifficultyOption>("Difficulty_Peaceful"), "peaceful");
		AddOption(1, Resources.Load<DifficultyOption>("Difficulty_Easy"), "easy");
		AddOption(2, Resources.Load<DifficultyOption>("Difficulty_Normal"), "normal");
		AddOption(3, Resources.Load<DifficultyOption>("Difficulty_Hard"), "hard");
		AddOption(4, Resources.Load<DifficultyOption>("Difficulty_Survival"), "survival");
		AddOption(5, UnityEngine.Object.Instantiate(options[1]), "custom");
		currOption = ScriptableObject.CreateInstance<DifficultyOption>();
	}

	private void Start()
	{
	}

	public void AddOption(int id, DifficultyOption option, string name)
	{
		options.Add(id, option);
		DifficultiesIndexMap.Add(id, Difficulties.Count);
		Difficulties.Add(new DifficultyEntry
		{
			id = id,
			name = name
		});
	}

	public void ApplyDifficultyOption(int difficulty)
	{
		currOption.CopyFrom(options[difficulty]);
	}
}
