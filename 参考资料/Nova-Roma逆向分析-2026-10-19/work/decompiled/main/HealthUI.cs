using System;
using I2.Loc;
using TMPro;
using UnityEngine;

public class HealthUI : InfoButton
{
	public static HealthUI inst;

	public TextMeshProUGUI happinessTextUI;

	public GameObject deadBodyWarningContainer;

	public TextMeshProUGUI deadBodyText;

	private int lastHealth = -1;

	public GameObject overlayBgToggleImg;

	private void Start()
	{
		inst = this;
	}

	public void FindDeadBody()
	{
		int focusedLandMass = Player.inst.FocusedLandMass;
		ArrayExt<DeadVillager> villagers = DeadVillagerSystem.inst.villagers;
		for (int i = 0; i < villagers.Count; i++)
		{
			if (villagers.data[i].hasNotified && villagers.data[i].landmass == focusedLandMass)
			{
				if (Cam.inst.desiredDist > 17f)
				{
					Cam.inst.desiredDist = 17f;
				}
				Cam.inst.SetDesiredTrackingPos(villagers.data[i].Pos);
			}
		}
	}

	public static string GetColor(int n)
	{
		return Player.HealthInfo.ToRating(n) switch
		{
			Player.HealthInfo.HealthRating.Excellent => "#26FF00", 
			Player.HealthInfo.HealthRating.VeryGood => "#85CC00", 
			Player.HealthInfo.HealthRating.Good => "#A2D100", 
			Player.HealthInfo.HealthRating.Fair => "#CAA500", 
			Player.HealthInfo.HealthRating.Poor => "#F46B00", 
			Player.HealthInfo.HealthRating.VeryPoor => "#FF6833", 
			_ => "white", 
		};
	}

	public override string GetExplanation()
	{
		int focusedLandMass = Player.inst.FocusedLandMass;
		if (focusedLandMass == -1)
		{
			return "";
		}
		if (LoadSave.Loading)
		{
			return "";
		}
		Player.HealthInfo healthForFocusedLandMass = Player.inst.HealthForFocusedLandMass;
		string text = "<b>" + ScriptLocalization.Health + " <color=" + GetColor(healthForFocusedLandMass.currHealth) + ">" + healthForFocusedLandMass.currHealth + "</color></b>";
		switch (Player.HealthInfo.ToRating(healthForFocusedLandMass.currHealth))
		{
		case Player.HealthInfo.HealthRating.Excellent:
			text = text + " - " + ScriptLocalization.HealthExcellent + Environment.NewLine;
			text += " --------------------------------------------------\n";
			text = text + string.Format(ScriptLocalization.ChanceOfPlague, "<color=green>" + ScriptLocalization.LowChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.PlagueVirulence, "<color=green>" + ScriptLocalization.VeryLowChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.LifeExpectancy, "<color=green>" + ScriptLocalization.VeryHighChance + "</color>") + Environment.NewLine;
			break;
		case Player.HealthInfo.HealthRating.VeryGood:
			text = text + " - " + ScriptLocalization.HealthVeryGood + Environment.NewLine;
			text += " --------------------------------------------------\n";
			text = text + string.Format(ScriptLocalization.ChanceOfPlague, "<color=green>" + ScriptLocalization.LowChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.PlagueVirulence, "<color=green>" + ScriptLocalization.LowChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.LifeExpectancy, "<color=green>" + ScriptLocalization.HighChance + "</color>") + Environment.NewLine;
			break;
		case Player.HealthInfo.HealthRating.Good:
			text = text + " - " + ScriptLocalization.HealthGood + Environment.NewLine;
			text += " --------------------------------------------------\n";
			text = text + string.Format(ScriptLocalization.ChanceOfPlague, "<color=green>" + ScriptLocalization.LowChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.PlagueVirulence, "<color=yellow>" + ScriptLocalization.ModerateChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.LifeExpectancy, "<color=yellow>" + ScriptLocalization.ModerateChance + "</color>") + Environment.NewLine;
			break;
		case Player.HealthInfo.HealthRating.Fair:
			text = text + " - " + ScriptLocalization.HealthFair + Environment.NewLine;
			text += " --------------------------------------------------\n";
			text = text + string.Format(ScriptLocalization.ChanceOfPlague, "<color=yellow>" + ScriptLocalization.ModerateChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.PlagueVirulence, "<color=yellow>" + ScriptLocalization.ModerateChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.LifeExpectancy, "<color=yellow>" + ScriptLocalization.ModerateChance + "</color>") + Environment.NewLine;
			break;
		case Player.HealthInfo.HealthRating.Poor:
			text = text + " - " + ScriptLocalization.HealthPoor + Environment.NewLine;
			text += " --------------------------------------------------\n";
			text = text + string.Format(ScriptLocalization.ChanceOfPlague, "<color=yellow>" + ScriptLocalization.ModerateChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.PlagueVirulence, "<color=red>" + ScriptLocalization.HighChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.LifeExpectancy, "<color=red>" + ScriptLocalization.LowChance + "</color>") + Environment.NewLine;
			break;
		default:
			text = text + " - " + ScriptLocalization.HealthVeryPoor + Environment.NewLine;
			text += " --------------------------------------------------\n";
			text = text + string.Format(ScriptLocalization.ChanceOfPlague, "<color=red>" + ScriptLocalization.HighChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.PlagueVirulence, "<color=red>" + ScriptLocalization.HighChance + "</color>") + Environment.NewLine;
			text = text + string.Format(ScriptLocalization.LifeExpectancy, "<color=red>" + ScriptLocalization.LowChance + "</color>") + Environment.NewLine;
			break;
		}
		text += Environment.NewLine;
		text = text + ScriptLocalization.PeasantsWithAccess + Environment.NewLine;
		string format = "<color={0}>{1}%</color>";
		if (LocalizationManager.CurrentLanguage == "Turkish")
		{
			format = "<color={0}>%{1}</color>";
		}
		int num = 0;
		int num2 = 0;
		int num3 = 0;
		int num4 = 0;
		int num5 = 0;
		int num6 = 0;
		ArrayExt<Home> arrayExt = Player.inst.ResidentialsPerLandmass[focusedLandMass];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			Home.Consumable[] diet = arrayExt.data[i].diet;
			int[] dietFilled = arrayExt.data[i].dietFilled;
			for (int j = 0; j < diet.Length; j++)
			{
				if (diet[j].type == 11)
				{
					num5++;
					if (dietFilled[j] >= 1)
					{
						num6++;
					}
				}
				if (diet[j].type == 9)
				{
					num++;
					if (dietFilled[j] >= 1)
					{
						num2++;
					}
				}
				if (diet[j].type == 10)
				{
					num3++;
					if (dietFilled[j] >= 1)
					{
						num4++;
					}
				}
			}
		}
		int num7 = 0;
		if (num5 > 0)
		{
			num7 = (int)((float)num6 / (float)num5 * 100f);
		}
		if (num6 > 0)
		{
			num7 = Mathff.Max(num7, 1);
		}
		text += string.Format("- " + ScriptLocalization.WheatCoverage + "\n", string.Format(format, GetColor(num7), num7));
		int num8 = 0;
		if (num > 0)
		{
			num8 = (int)((float)num2 / (float)num * 100f);
		}
		if (num2 > 0)
		{
			num8 = Mathff.Max(num8, 1);
		}
		text += string.Format("- " + ScriptLocalization.FruitCoverage + "\n", string.Format(format, GetColor(num8), num8));
		int num9 = 0;
		if (num3 > 0)
		{
			num9 = (int)((float)num4 / (float)num3 * 100f);
		}
		if (num4 > 0)
		{
			num9 = Mathff.Max(num9, 1);
		}
		text += string.Format("- " + ScriptLocalization.MeatCoverage + "\n", string.Format(format, GetColor(num9), num9));
		if (healthForFocusedLandMass.HospitalClinicPenalty)
		{
			text += Environment.NewLine;
			text = text + "<color=#F05E5E>" + string.Format(LocalizationManager.GetTranslation("healthui_clinic_penalty") + "</color>" + Environment.NewLine, -5);
		}
		Util.SetActive(deadBodyWarningContainer, healthForFocusedLandMass.deadBodyHealth < 0);
		if (healthForFocusedLandMass.deadBodyHealth < 0)
		{
			deadBodyText.text = string.Format(ScriptLocalization.DeadBodiesNotBuried, healthForFocusedLandMass.deadBodyHealth);
		}
		return text;
	}

	public override void UpdateInternal()
	{
		Player.HealthInfo healthForFocusedLandMass = Player.inst.HealthForFocusedLandMass;
		if (healthForFocusedLandMass != null && Player.inst.FocusedLandMass != -1)
		{
			if (healthForFocusedLandMass.currHealth != lastHealth)
			{
				happinessTextUI.SetText($"<color={GetColor(healthForFocusedLandMass.currHealth)}>{healthForFocusedLandMass.currHealth}</color>");
				UpdateSlider(healthForFocusedLandMass.currHealth);
			}
			lastHealth = healthForFocusedLandMass.currHealth;
		}
		else
		{
			enterCount = 0;
		}
		overlayBgToggleImg.SetActive(overlayOn);
	}

	public void OnClickedShowOverlay()
	{
		if (!overlayOn)
		{
			if (HappinessUI.inst.overlayOn)
			{
				HappinessUI.inst.HideOverlay();
			}
			if (IntegrityUI.inst.overlayOn)
			{
				IntegrityUI.inst.HideOverlay();
			}
			overlayOn = true;
			for (int i = 0; i < Player.inst.Residentials.Count; i++)
			{
				Player.inst.Residentials.data[i].ShowOverlay(Home.OverlayType.Health);
			}
			IslandInfoContainer.inst.SetOverlayTitleText(LocalizationManager.GetTranslation("islandui_healthoverlay"));
			GameUI.inst.ReturnToDefaultCursorMode();
		}
		else
		{
			HideOverlay();
		}
	}

	public void HideOverlay()
	{
		if (overlayOn)
		{
			TerrainGen.inst.ClearOverlay(updateToo: true);
			for (int i = 0; i < Player.inst.Residentials.Count; i++)
			{
				Player.inst.Residentials.data[i].HideOverlay();
			}
			overlayOn = false;
			GameUI.inst.ReturnToDefaultCursorMode();
		}
	}
}
