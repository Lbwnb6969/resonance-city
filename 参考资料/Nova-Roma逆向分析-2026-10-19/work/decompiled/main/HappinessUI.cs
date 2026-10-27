using System;
using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class HappinessUI : InfoButton
{
	public static HappinessUI inst;

	public TextMeshProUGUI happinessTextUI;

	private ArrayExt<ArrayExt<Building>> shopScratch = new ArrayExt<ArrayExt<Building>>(10);

	public Sprite veryHappy;

	public Sprite happy;

	public Sprite neutral;

	public Sprite unhappy;

	public Sprite veryUnhappy;

	public GameObject exclamation;

	private int lastHappiness = -1;

	private int[] cellData;

	private int currLandmassProcessing;

	private int cellIdx;

	private static Dictionary<int, int> MaxHappinessObserved = new Dictionary<int, int>(64);

	private static Dictionary<int, int> HappinessBonuses = new Dictionary<int, int>(64);

	public GameObject overlayBgToggleImg;

	public Image happinessIcon;

	private void Start()
	{
		inst = this;
	}

	public static string GetColor(int happiness)
	{
		if (happiness >= 90)
		{
			return "#26F200";
		}
		if (happiness < 90 && happiness >= 75)
		{
			return "#87BF1E";
		}
		if (happiness < 75 && happiness >= 50)
		{
			return "#CAB400";
		}
		if (happiness < 50 && happiness >= 35)
		{
			return "#F48800";
		}
		return "#9E3F15";
	}

	public override string GetExplanation()
	{
		if (LoadSave.Loading || Player.inst.FocusedLandMass == -1)
		{
			return "";
		}
		Player.HappinessInfo happinessForFocusedLandMass = Player.inst.HappinessForFocusedLandMass;
		string text = "<b>" + ScriptLocalization.Happiness + " <color=" + GetColor(happinessForFocusedLandMass.currHappiness) + ">" + happinessForFocusedLandMass.currHappiness + "</color></b>";
		if (happinessForFocusedLandMass.targetHappiness != happinessForFocusedLandMass.currHappiness)
		{
			text = text + "<b> - " + string.Format(ScriptLocalization.HappinessUITrendingTowards, happinessForFocusedLandMass.targetHappiness) + "</b>";
		}
		text += "\n --------------------------------------------------\n";
		text += ScriptLocalization.HappinessUIExplanation;
		text += "\n\n";
		if (Player.inst.difficulty >= Player.Difficulty.Hard)
		{
			if (Player.inst.timeAtFailHappiness > 100f && Player.inst.timeAtFailHappiness < 300f)
			{
				text += "<color=yellow>ScriptLocalization.HappinessUITalkOfRioting</color>\n";
			}
			else if (Player.inst.timeAtFailHappiness >= 300f)
			{
				text += "<color=#FF6833>ScriptLocalization.HappinessUITalkOfOverthrown</color>\n";
			}
		}
		if (Player.inst.ResidentialsPerLandmass[Player.inst.FocusedLandMass].Count > 0)
		{
			text = text + "<b>" + string.Format(ScriptLocalization.HappinessUIAverageHappiness, happinessForFocusedLandMass.houseHappiness) + "</b>";
		}
		text += Environment.NewLine;
		if (happinessForFocusedLandMass.templePenalty)
		{
			text = ((happinessForFocusedLandMass.numGodsHonored >= 3) ? (text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUINoTemple, -5) + "</color>\n") : (text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUINotEnoughGodsHonored, -10) + "</color>\n"));
		}
		if (happinessForFocusedLandMass.forumPenalty)
		{
			text = text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUINoForum, -5) + "</color>\n";
		}
		if (happinessForFocusedLandMass.foodHappiness < 0)
		{
			text = text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUIFoodShortage, happinessForFocusedLandMass.foodHappiness) + "</color>\n";
		}
		if (happinessForFocusedLandMass.libChurchPenalty)
		{
			text = ((Player.inst.GetBuildingListForLandMass(Player.inst.FocusedLandMass, "church".GetHashCode()).Count <= 0 && Player.inst.GetBuildingListForLandMass(Player.inst.FocusedLandMass, "library".GetHashCode()).Count <= 0) ? (text + "<color=yellow>" + string.Format("ScriptLocalization.HappinessUINoChurch", -10) + "</color>\n") : (text + "<color=yellow>" + string.Format("ScriptLocalization.HappinessUIMoreChurches", -10) + "</color>\n"));
		}
		if (happinessForFocusedLandMass.shopPenalty)
		{
			if (happinessForFocusedLandMass.shopMaxScore != 0)
			{
				text = ((happinessForFocusedLandMass.shopCurrScore >= happinessForFocusedLandMass.shopMaxScore) ? (text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUIMoreShops, -10) + "</color>\n") : (text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUIOpenShops, -10) + "</color>\n"));
			}
			else
			{
				text = text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUINoShops, -10) + "</color>\n";
			}
		}
		if (happinessForFocusedLandMass.bathhouseNeed > 0f)
		{
			bool flag = false;
			Player.inst.GetBuildingListsByCategoryForLandMass(Player.inst.FocusedLandMass, World.bathCategoryHash, ref shopScratch);
			for (int i = 0; i < shopScratch.Count; i++)
			{
				flag |= shopScratch.data[i].Count > 0;
			}
			text = ((!flag) ? (text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUINoBathouses, -Player.GetBathHousePenalty(happinessForFocusedLandMass.bathhouseNeed)) + "</color>\n") : (text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUIMoreBathouses, -Player.GetBathHousePenalty(happinessForFocusedLandMass.bathhouseNeed)) + "</color>\n"));
		}
		_ = happinessForFocusedLandMass.joustingArenaPenalty;
		if (happinessForFocusedLandMass.theaterPenalty)
		{
			if (happinessForFocusedLandMass.theaterMaxScore != 0)
			{
				text = ((happinessForFocusedLandMass.theaterCurrScore >= happinessForFocusedLandMass.theaterMaxScore) ? (text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUIMoreTheaters, -10) + "</color>\n") : (text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUIOpenTheaters, -10) + "</color>\n"));
			}
			else
			{
				text = text + "<color=yellow>" + string.Format(ScriptLocalization.HappinessUINoTheater, -10) + "</color>\n";
			}
		}
		if (happinessForFocusedLandMass.HappinessFromHomeless < 0)
		{
			text = text + "<color=#FF6833>" + string.Format(ScriptLocalization.HappinessUIHomeless, happinessForFocusedLandMass.HappinessFromHomeless) + "</color>\n";
		}
		if (happinessForFocusedLandMass.deadBodiesPenalty < 0)
		{
			text = text + "<color=#FF6833>" + string.Format(ScriptLocalization.HappinessUIDeadBodiesPenalty, happinessForFocusedLandMass.deadBodiesPenalty) + "</color>\n";
		}
		for (int j = 0; j < Player.inst.happinessMods.Count; j++)
		{
			Player.HappinessMod happinessMod = Player.inst.happinessMods[j];
			if (happinessMod.landMass == Player.inst.FocusedLandMass)
			{
				text = text + ((happinessMod.amount > 0) ? "<color=green>+" : "<color=#FF6833>") + string.Format(happinessMod.description, happinessMod.amount) + "</color>\n";
			}
		}
		return text;
	}

	public override void UpdateInternal()
	{
		bool flag = false;
		Player.HappinessInfo happinessForFocusedLandMass = Player.inst.HappinessForFocusedLandMass;
		if (happinessForFocusedLandMass != null && Player.inst.FocusedLandMass != -1)
		{
			if (happinessForFocusedLandMass.bathhouseNeed > 0f || happinessForFocusedLandMass.deadBodiesPenalty < 0 || happinessForFocusedLandMass.joustingArenaPenalty || happinessForFocusedLandMass.libChurchPenalty || happinessForFocusedLandMass.shopPenalty || happinessForFocusedLandMass.theaterPenalty)
			{
				flag = true;
			}
			int currHappiness = happinessForFocusedLandMass.currHappiness;
			if (currHappiness != lastHappiness)
			{
				happinessTextUI.text = string.Format("<color={1}>{0}</color>", currHappiness, InfoButton.GetBarColor(currHappiness));
				happinessIcon.sprite = GetHappinessSprite(currHappiness);
				UpdateSlider(currHappiness);
			}
			lastHappiness = currHappiness;
		}
		else
		{
			enterCount = 0;
		}
		if (overlayOn != overlayBgToggleImg.activeSelf)
		{
			overlayBgToggleImg.SetActive(overlayOn);
		}
		if (flag != exclamation.activeSelf)
		{
			exclamation.SetActive(flag);
		}
	}

	internal Sprite GetHappinessSprite(int happiness)
	{
		if (happiness >= 90)
		{
			return veryHappy;
		}
		if (happiness < 90 && happiness >= 70)
		{
			return happy;
		}
		if (happiness < 70 && happiness >= 50)
		{
			return neutral;
		}
		if (happiness < 50 && happiness >= 35)
		{
			return unhappy;
		}
		return veryUnhappy;
	}

	private void LateUpdate()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		if (cellData == null || cellData.Length != World.inst.GetCellsData().Length)
		{
			cellData = new int[gridWidth * gridHeight];
		}
		if (!overlayOn)
		{
			return;
		}
		LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
		int num = 200;
		while (num > 0)
		{
			num--;
			int num2 = playerLandmassOwner.ownedLandMasses.data[currLandmassProcessing];
			ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[num2];
			Cell cell = arrayExt.data[cellIdx];
			bool anyInfluence = false;
			int happinessAt = GetHappinessAt(cell.x, cell.z, out anyInfluence);
			if (anyInfluence && happinessAt == 0)
			{
				cellData[cell.z * gridHeight + cell.x] = 1;
			}
			else
			{
				cellData[cell.z * gridHeight + cell.x] = happinessAt;
			}
			cellIdx++;
			if (cellIdx >= arrayExt.Count)
			{
				cellIdx = 0;
				currLandmassProcessing++;
			}
			if (currLandmassProcessing >= playerLandmassOwner.ownedLandMasses.Count)
			{
				currLandmassProcessing = 0;
			}
		}
		TerrainGen.inst.SetOverlayPixelsToTransparent();
		Color happinessMapMid = Player.inst.happinessMapMid;
		Color happinessMapMidLow = Player.inst.happinessMapMidLow;
		Color happinessMapHigh = Player.inst.happinessMapHigh;
		Color happinessMapLow = Player.inst.happinessMapLow;
		Color white = Color.white;
		for (int i = 0; i < playerLandmassOwner.ownedLandMasses.Count; i++)
		{
			ArrayExt<Cell> arrayExt2 = World.inst.cellsToLandmass[playerLandmassOwner.ownedLandMasses.data[i]];
			int j = 0;
			for (int count = arrayExt2.Count; j < count; j++)
			{
				Cell cell2 = arrayExt2.data[j];
				float num3 = (float)cellData[cell2.index] / 35f;
				if (num3 > 0f)
				{
					float t = Mathff.Clamp01(num3);
					white.r = Mathf.Lerp(happinessMapMid.r, happinessMapHigh.r, t);
					white.g = Mathf.Lerp(happinessMapMid.g, happinessMapHigh.g, t);
					white.b = Mathf.Lerp(happinessMapMid.b, happinessMapHigh.b, t);
					white.a = Mathf.Lerp(happinessMapMid.a, happinessMapHigh.a, t);
					TerrainGen.inst.SetOverlayTileColorOverlapCheck(cell2.x, cell2.z, cell2, white, white * 0.5f, applyBuildingMaterial: false);
				}
				else if (num3 < 0f)
				{
					num3 *= -1f;
					float t2 = Mathff.Clamp01(num3);
					white.r = Mathff.Lerp(happinessMapMidLow.r, happinessMapLow.r, t2);
					white.g = Mathff.Lerp(happinessMapMidLow.g, happinessMapLow.g, t2);
					white.b = Mathff.Lerp(happinessMapMidLow.b, happinessMapLow.b, t2);
					white.a = Mathff.Lerp(happinessMapMidLow.a, happinessMapLow.a, t2);
					TerrainGen.inst.SetOverlayTileColorOverlapCheck(cell2.x, cell2.z, cell2, white, white * 0.5f, applyBuildingMaterial: false);
				}
			}
		}
		TerrainGen.inst.ApplyBuildingOverlayMaterial();
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	public static int GetHappinessAt(int cx, int cz, out bool anyInfluence)
	{
		Vector3 p = new Vector3((float)cx + 0.5f, 0f, (float)cz + 0.5f);
		CellInfluence cellInfluenceDataClamped = World.inst.GetCellInfluenceDataClamped(cx, cz);
		anyInfluence = false;
		if (cellInfluenceDataClamped.radiusBonuses.Count == 0)
		{
			return 0;
		}
		if (MaxHappinessObserved.Count == 0)
		{
			foreach (int key in HappinessModifierSystem.happinessModifierMap.Keys)
			{
				MaxHappinessObserved.Add(key, 0);
				HappinessBonuses.Add(key, 0);
			}
		}
		foreach (int key2 in HappinessModifierSystem.happinessModifierMap.Keys)
		{
			MaxHappinessObserved[key2] = 0;
			HappinessBonuses[key2] = 0;
		}
		for (int i = 0; i < cellInfluenceDataClamped.radiusBonuses.Count; i++)
		{
			RadiusBonus radiusBonus = cellInfluenceDataClamped.radiusBonuses.data[i];
			if (radiusBonus.b.IsBuilt() && radiusBonus.b.IsOpen() && (radiusBonus.OverlayWhenPlacing || radiusBonus.OverlayWhenSelected))
			{
				anyInfluence = true;
				int residentialTileID = radiusBonus.residentialTileID;
				int currentHappiness = radiusBonus.GetCurrentHappiness();
				if (currentHappiness > MaxHappinessObserved[residentialTileID])
				{
					MaxHappinessObserved[residentialTileID] = currentHappiness;
				}
				HappinessBonuses[residentialTileID] += radiusBonus.GetRadialHappiness(p);
				int num = MaxHappinessObserved[residentialTileID];
				if (HappinessBonuses[residentialTileID] > num)
				{
					HappinessBonuses[residentialTileID] = num;
				}
			}
		}
		int num2 = 0;
		foreach (int value in HappinessBonuses.Values)
		{
			num2 += value;
		}
		return num2;
	}

	public void OnClickedShowOverlay()
	{
		if (!overlayOn)
		{
			if (HealthUI.inst.overlayOn)
			{
				HealthUI.inst.HideOverlay();
			}
			if (IntegrityUI.inst.overlayOn)
			{
				IntegrityUI.inst.HideOverlay();
			}
			overlayOn = true;
			int i = 0;
			for (int count = Player.inst.Residentials.Count; i < count; i++)
			{
				Player.inst.Residentials.data[i].ShowOverlay(Home.OverlayType.Happiness);
			}
			IslandInfoContainer.inst.SetOverlayTitleText(LocalizationManager.GetTranslation("islandui_happinessoverlay"));
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
			int i = 0;
			for (int count = Player.inst.Residentials.Count; i < count; i++)
			{
				Player.inst.Residentials.data[i].HideOverlay();
			}
			GameUI.inst.RefreshOverlay();
			overlayOn = false;
			GameUI.inst.ReturnToDefaultCursorMode();
		}
	}
}
