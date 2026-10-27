using System;
using I2.Loc;
using UnityEngine;

public class Fountain : MonoBehaviour, IOutputInfo
{
	public Transform splash;

	public Transform waterMesh;

	public Building b;

	public Well well;

	public RadiusBonus radBonus;

	public WaterConsumer waterConsumer;

	[NonSerialized]
	public bool receievingWater;

	private void OnInit()
	{
		b = GetComponent<Building>();
		waterConsumer.SetupChangeCallback(WaterConsumptionChanged);
		well.minProtectionRadius = radBonus.radiusMin;
		well.maxProtectionRadius = radBonus.radiusMax;
		radBonus.happinessFunc = GetHappiness;
	}

	public void WaterConsumptionChanged()
	{
		receievingWater = waterConsumer.availableWaterPercentage > 0.75f;
		RefreshBonuses();
	}

	public void OnDestroy()
	{
		waterConsumer.SetupChangeCallback(null);
	}

	public string GetError()
	{
		if (!receievingWater)
		{
			if (waterConsumer.availableWaterPercentage > 0f)
			{
				return LocalizationManager.GetTranslation("workerui_fountain_error_notenoughwater");
			}
			return ScriptLocalization.FountainErrorNotConnected;
		}
		return "";
	}

	private int GetHappiness()
	{
		if (!receievingWater)
		{
			return 0;
		}
		return radBonus.Happiness;
	}

	private void OnBuilt()
	{
		RefreshBonuses();
	}

	public void RefreshBonuses(bool force = false)
	{
		if ((!force && (GameState.IsQuitting || LoadSave.Loading)) || !b.IsBuilt())
		{
			return;
		}
		splash.gameObject.SetActive(receievingWater);
		waterMesh.gameObject.SetActive(receievingWater);
		if (receievingWater)
		{
			if (!radBonus.applied)
			{
				radBonus.ApplyBonus();
			}
			well.SetWaterAccess(isWater: true);
		}
		else
		{
			well.SetWaterAccess(isWater: false);
			if (radBonus.applied)
			{
				radBonus.RemoveBonus();
			}
		}
	}
}
