using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;

[CreateAssetMenu(fileName = "DifficultyOption", menuName = "ScriptableObjects/DifficultyOption")]
public class DifficultyOption : ScriptableObject
{
	public bool isInvasionsEnabled = true;

	public int invasionFrequencyChoice;

	[HideInInspector]
	public int minInvasionFrequency = 7;

	[HideInInspector]
	public int maxInvasionFrequency = 9;

	public int invasionStartYear = 4;

	public int invasionIntensityChoice;

	public bool unlimitedResources = true;

	public int merchantVisitFrequencyChoice;

	[HideInInspector]
	public int minMerchantInterval = 210;

	[HideInInspector]
	public int maxMerchantInterval = 270;

	public int droughtFrequency;

	public int floodingFrequency;

	public int fires;

	public int plagues = 1;

	public int godWrath;

	public int foodConsumption;

	private static IEnumerable<ValueDropdownItem<int>> InvasionFrequencyDropdown => DifficultyDropdownChoices.GetDropdownItems(DifficultyDropdownChoices.Frequency);

	private static IEnumerable<ValueDropdownItem<int>> InvasionIntensityDropdown => DifficultyDropdownChoices.GetDropdownItems(DifficultyDropdownChoices.InvasionIntensity);

	private static IEnumerable<ValueDropdownItem<int>> MerchantFrequencyDropdown => DifficultyDropdownChoices.GetDropdownItems(DifficultyDropdownChoices.MerchantFrequency);

	private static IEnumerable<ValueDropdownItem<int>> FrequencyDropdown => DifficultyDropdownChoices.GetDropdownItems(DifficultyDropdownChoices.Frequency);

	private static IEnumerable<ValueDropdownItem<int>> MagnitudeDropdown => DifficultyDropdownChoices.GetDropdownItems(DifficultyDropdownChoices.Magnitude);

	public void CopyFrom(DifficultyOption other)
	{
		isInvasionsEnabled = other.isInvasionsEnabled;
		invasionFrequencyChoice = other.invasionFrequencyChoice;
		minInvasionFrequency = other.minInvasionFrequency;
		maxInvasionFrequency = other.maxInvasionFrequency;
		invasionIntensityChoice = other.invasionIntensityChoice;
		invasionStartYear = other.invasionStartYear;
		unlimitedResources = other.unlimitedResources;
		merchantVisitFrequencyChoice = other.merchantVisitFrequencyChoice;
		minMerchantInterval = other.minMerchantInterval;
		maxMerchantInterval = other.maxMerchantInterval;
		droughtFrequency = other.droughtFrequency;
		floodingFrequency = other.floodingFrequency;
		fires = other.fires;
		plagues = other.plagues;
		godWrath = other.godWrath;
		foodConsumption = other.foodConsumption;
	}

	public bool IsIdentical(DifficultyOption other)
	{
		bool flag = isInvasionsEnabled == other.isInvasionsEnabled;
		if (isInvasionsEnabled)
		{
			flag &= invasionStartYear == other.invasionStartYear;
			flag &= invasionFrequencyChoice == other.invasionFrequencyChoice;
			flag &= invasionIntensityChoice == other.invasionIntensityChoice;
		}
		flag &= unlimitedResources == other.unlimitedResources;
		flag &= merchantVisitFrequencyChoice == other.merchantVisitFrequencyChoice;
		flag &= floodingFrequency == other.floodingFrequency;
		flag &= droughtFrequency == other.droughtFrequency;
		flag &= fires == other.fires;
		flag &= plagues == other.plagues;
		flag &= godWrath == other.godWrath;
		return flag & (foodConsumption == other.foodConsumption);
	}
}
