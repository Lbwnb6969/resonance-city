using System;
using I2.Loc;
using TMPro;
using UnityEngine;

public class IntegrityUI : InfoButton
{
	public static IntegrityUI inst;

	public TextMeshProUGUI integrityTextUI;

	private int lastIntegrity = -1;

	private int[] cellData;

	private int prevFocusedLandmass = -1;

	public GameObject overlayBgToggleImg;

	private void Start()
	{
		inst = this;
	}

	public static string GetColor(int integrity)
	{
		return Player.IntegrityInfo.ToRating(integrity) switch
		{
			Player.IntegrityInfo.IntegrityRating.Excellent => "#26FF00", 
			Player.IntegrityInfo.IntegrityRating.Good => "#A2D100", 
			Player.IntegrityInfo.IntegrityRating.Fair => "#CAA500", 
			Player.IntegrityInfo.IntegrityRating.VeryPoor => "#9E3F15", 
			_ => "white", 
		};
	}

	public override string GetExplanation()
	{
		Player.IntegrityInfo integrityForFocusedLandMass = Player.inst.IntegrityForFocusedLandMass;
		string text = "<b>" + ScriptLocalization.IntegrityTitle + " <color=" + GetColor(integrityForFocusedLandMass.currentIntegrity) + ">" + integrityForFocusedLandMass.currentIntegrity + "</color></b>";
		text += "\n --------------------------------------------------\n";
		text += LocalizationManager.GetTranslation("IntegrityDescription");
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(Player.inst.FocusedLandMass, World.masonHash);
		bool flag = false;
		bool flag2 = false;
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			Building building = buildingListForLandMass.data[i];
			if (building.IsBuilt())
			{
				float num = building.GetWorkerPercent() * 100f;
				if (!building.IsOpen())
				{
					flag = true;
				}
				else if (num != 100f)
				{
					flag2 = true;
				}
			}
		}
		if (buildingListForLandMass.Count > 0)
		{
			text += Environment.NewLine;
			text += Environment.NewLine;
			if (integrityForFocusedLandMass.currentIntegrity < 90 && !flag && !flag2)
			{
				text += Environment.NewLine;
				text = text + "<color=yellow>" + ScriptLocalization.IntegrityMasonsNeedResources + "</color>";
			}
		}
		else if (integrityForFocusedLandMass.currentIntegrity < 100)
		{
			text += Environment.NewLine;
			text += Environment.NewLine;
			text += Environment.NewLine;
			text = text + "<color=red>" + ScriptLocalization.IntegrityNoMasons + "</color>";
		}
		if ((integrityForFocusedLandMass.currentIntegrity < 90) & flag)
		{
			text += Environment.NewLine;
			text += Environment.NewLine;
			text += Environment.NewLine;
			text = text + "<color=yellow>" + ScriptLocalization.IntegrityOpenMasons + "</color>";
		}
		if ((integrityForFocusedLandMass.currentIntegrity < 90) & flag2)
		{
			text += Environment.NewLine;
			text += Environment.NewLine;
			text += Environment.NewLine;
			text = text + "<color=yellow>" + ScriptLocalization.IntegrityMoreWorkers + "</color>";
		}
		return text;
	}

	public override void UpdateInternal()
	{
		Player.IntegrityInfo integrityForFocusedLandMass = Player.inst.IntegrityForFocusedLandMass;
		if (integrityForFocusedLandMass != null && Player.inst.FocusedLandMass != -1)
		{
			if (integrityForFocusedLandMass.currentIntegrity != lastIntegrity)
			{
				integrityTextUI.SetText($"<color={GetColor(integrityForFocusedLandMass.currentIntegrity)}>{integrityForFocusedLandMass.currentIntegrity}</color>");
				UpdateSlider(integrityForFocusedLandMass.currentIntegrity);
			}
			lastIntegrity = integrityForFocusedLandMass.currentIntegrity;
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
			if (HealthUI.inst.overlayOn)
			{
				HealthUI.inst.HideOverlay();
			}
			overlayOn = true;
			ArrayExt<Building> buildings = Player.inst.Buildings;
			for (int i = 0; i < buildings.Count; i++)
			{
				buildings.data[i].ShowOverlay(Building.OverlayType.Integrity);
			}
			IslandInfoContainer.inst.SetOverlayTitleText(LocalizationManager.GetTranslation("islandui_integrityoverlay"));
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
			ArrayExt<Building> buildings = Player.inst.Buildings;
			for (int i = 0; i < buildings.Count; i++)
			{
				buildings.data[i].HideOverlay();
			}
			overlayOn = false;
			GameUI.inst.ReturnToDefaultCursorMode();
		}
	}
}
