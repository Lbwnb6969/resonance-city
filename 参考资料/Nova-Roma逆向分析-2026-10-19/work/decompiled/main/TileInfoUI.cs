using System;
using System.Collections.Generic;
using Assets;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class TileInfoUI : MonoBehaviour
{
	public static TileInfoUI inst;

	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	public Button exitBtn;

	public Button clearLandBtn;

	public TooltipHook clearLandTooltip;

	public TextMeshProUGUI titleTMP;

	public TextMeshProUGUI descriptionTMP;

	public RawImage tileRI;

	public Color VeryFertileColor;

	public Color FertileColor;

	public Color BarrenColor;

	public Color FreshWaterColor;

	public Color SaltWaterColor;

	public Color DeepWaterColor;

	public GameObject clearLandContainer;

	public TextMeshProUGUI clearLandTMP;

	public RawImage cancelClearLandRI;

	private bool isVisible;

	private Cell currCell;

	private Cell prevCell;

	private Dictionary<string, RadiusBonusProduction> bonusMap = new Dictionary<string, RadiusBonusProduction>();

	private Dictionary<string, RadiusBonusBuildingProduction> bonusBuildingMap = new Dictionary<string, RadiusBonusBuildingProduction>();

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		if (v != isVisible)
		{
			Util.SetEnabled(canvas, v);
			gRaycaster.enabled = v;
			if (!v)
			{
				currCell = null;
			}
			isVisible = v;
		}
	}

	private void Awake()
	{
		inst = this;
		exitBtn.onClick.AddListener(() =>
		{
			SetVisibility(v: false);
		});
		clearLandBtn.onClick.AddListener(OnClearLandClicked);
		clearLandTooltip.tooltipTerm = ScriptLocalization.tooltipui_hotkey;
	}

	private void Start()
	{
		OnLocalizeEvent();
		LocalizationManager.OnLocalizeEvent += OnLocalizeEvent;
		Settings.onKeybindChanged = (Settings.OnKeybindChanged)Delegate.Combine(Settings.onKeybindChanged, new Settings.OnKeybindChanged(OnKeybindChanged));
	}

	private void OnDestroy()
	{
		LocalizationManager.OnLocalizeEvent -= OnLocalizeEvent;
		Settings.onKeybindChanged = (Settings.OnKeybindChanged)Delegate.Remove(Settings.onKeybindChanged, new Settings.OnKeybindChanged(OnKeybindChanged));
	}

	private void OnLocalizeEvent()
	{
		clearLandTooltip.toolTipText = string.Format(ScriptLocalization.tooltipui_hotkey, ConfigurableControls.inst.GetKeyAction(300));
	}

	private void OnKeybindChanged(int id, ConfigurableControls.Keybind keybind)
	{
		if (id == 300)
		{
			clearLandTooltip.toolTipText = string.Format(ScriptLocalization.tooltipui_hotkey, keybind);
		}
	}

	private void OnClearLandClicked()
	{
		if (currCell != null && Player.inst.LandMassIsAPlayerLandMass(currCell.landMassIdx))
		{
			if (GameUI.inst.GetClearCutterJob(currCell) != null)
			{
				GameUI.inst.RemoveChopJobFromCell(currCell);
				cancelClearLandRI.enabled = false;
				clearLandTMP.text = ScriptLocalization.TileInfoChop;
			}
			else if (GameUI.inst.AddChopJobToCell(currCell))
			{
				cancelClearLandRI.enabled = true;
				clearLandTMP.text = ScriptLocalization.TileInfoCancel;
			}
		}
	}

	public void UpdateForNewCell(Cell cell)
	{
		if (cell == null)
		{
			SetVisibility(v: false);
			return;
		}
		currCell = cell;
		SetVisibility(v: true);
		RefreshVisuals(cell, isNewSelection: true);
		if (!Player.inst.AnyBuildingsOnPlayerLandMasses())
		{
			clearLandBtn.interactable = false;
		}
		else
		{
			clearLandBtn.interactable = true;
		}
		prevCell = cell;
	}

	private void Update()
	{
		if (isVisible && prevCell != null)
		{
			RefreshVisuals(prevCell, isNewSelection: false);
		}
	}

	private void RefreshVisuals(Cell cell, bool isNewSelection)
	{
		int num = 0;
		bool active = false;
		if (cell.Type == TerrainType.Water)
		{
			tileRI.color = DeepWaterColor;
			FishSystem.FishCell fishCell;
			if ((fishCell = FishSystem.inst.fishCells[cell.index]) != null && fishCell.owners.Count > 0)
			{
				titleTMP.text = ScriptLocalization.custom_production_cost_fishinghut;
				descriptionTMP.text = ScriptLocalization.tileinfoui_fish_description;
			}
			else
			{
				titleTMP.text = ScriptLocalization.TileInfoDeepWater;
				descriptionTMP.text = ScriptLocalization.TileInfoDeepWaterOnlyShips;
			}
			if (isNewSelection)
			{
				SfxSystem.inst.PlayFromBank("TileSelectWater", cell.Position);
			}
		}
		else if (cell.Type == TerrainType.Obstruction && cell.terrainResource == null)
		{
			titleTMP.text = LocalizationManager.GetTranslation("TileInfoCliff");
			descriptionTMP.text = LocalizationManager.GetTranslation("TileInfoCliffDetail");
			tileRI.color = BarrenColor;
			if (isNewSelection)
			{
				SfxSystem.inst.PlayFromBank("TileSelectStone", cell.Position);
			}
		}
		else if (cell.terrainResource != null)
		{
			switch (cell.terrainResource.resourceID)
			{
			case 2:
				titleTMP.text = ScriptLocalization.Stone;
				descriptionTMP.text = ScriptLocalization.TileInfoStone;
				break;
			case 5:
				titleTMP.text = ScriptLocalization.Iron;
				descriptionTMP.text = ScriptLocalization.TileInfoIron;
				break;
			case 14:
				titleTMP.text = ScriptLocalization.marble;
				descriptionTMP.text = LocalizationManager.GetTranslation("TileInfoMarbleDetail");
				break;
			}
			tileRI.color = BarrenColor;
			if (isNewSelection)
			{
				SfxSystem.inst.PlayFromBank("TileSelectStone", cell.Position);
			}
		}
		else if ((num = World.inst.treeSystem.ItemAmount(cell)) > 0 || World.inst.rockScatterSystem.ItemAmount(cell) > 0)
		{
			titleTMP.text = ((num > 0) ? ScriptLocalization.TileInfoForest : LocalizationManager.GetTranslation("TileInfoUsableStone"));
			descriptionTMP.text = ScriptLocalization.TileInfoUseChopTool;
			bool flag = GameUI.inst.GetClearCutterJob(cell) != null;
			cancelClearLandRI.enabled = flag;
			if (num > 0)
			{
				clearLandTMP.text = (flag ? ScriptLocalization.TileInfoCancel : ScriptLocalization.TileInfoChop);
			}
			else if (World.inst.rockScatterSystem.ItemAmount(cell) > 0)
			{
				clearLandTMP.text = (flag ? ScriptLocalization.TileInfoCancel : ScriptLocalization.TileInfoCollectStone);
			}
			active = true;
			SetTileDetails(cell.GetFertility());
			if (isNewSelection)
			{
				SfxSystem.inst.PlayFromBank((num > 0) ? "TileSelectTree" : "TileSelectStone", cell.Position);
			}
		}
		else if (DynamicWater.inst.simplifiedWaterGrid[cell.index] > 0f)
		{
			tileRI.color = FreshWaterColor;
			titleTMP.text = ScriptLocalization.tileinfoui_dynamicwater_title;
			descriptionTMP.text = ScriptLocalization.tileInfoui_dynamicwater_description;
			if (isNewSelection)
			{
				SfxSystem.inst.PlayFromBank("TileSelectWater", cell.Position);
			}
		}
		else
		{
			SetTileDetails(cell.GetFertility(), isEmptyCell: true);
			if (isNewSelection)
			{
				SfxSystem.inst.PlayFromBank("TileSelectGrass", cell.Position);
			}
		}
		descriptionTMP.text += Environment.NewLine;
		bonusMap.Clear();
		bonusBuildingMap.Clear();
		BuildingProductionUI.UpdateBonusMapForCell(bonusMap, bonusBuildingMap, cell.x, cell.z);
		foreach (KeyValuePair<string, RadiusBonusProduction> item in bonusMap)
		{
			RadiusBonusProduction value = item.Value;
			if (value.b.CategoryName == "temple" && (!value.BoostsResource(0) || cell.GetEffectiveFertility() != 0) && (!value.BoostsResource(8) || !(FishSystem.inst.fishCells[cell.index].baseProbability <= 0f)))
			{
				TextMeshProUGUI textMeshProUGUI = descriptionTMP;
				textMeshProUGUI.text = textMeshProUGUI.text + Environment.NewLine + string.Format(ScriptLocalization.workerui_productionui_templebonus, (value.GetBonus() > 0) ? value.Bonus.ToString() : ("<color=red>" + value.GetBonus() + "</color>"));
			}
		}
		clearLandContainer.SetActive(active);
	}

	private void SetTileDetails(int fertility, bool isEmptyCell = false)
	{
		switch (fertility)
		{
		case 0:
			if (isEmptyCell)
			{
				titleTMP.text = ScriptLocalization.TileInfoBarren;
				descriptionTMP.text = LocalizationManager.GetTranslation("TileInfoBarrenDetail");
			}
			tileRI.color = BarrenColor;
			break;
		case 1:
			if (isEmptyCell)
			{
				titleTMP.text = ScriptLocalization.TileInfoFertile;
				descriptionTMP.text = LocalizationManager.GetTranslation("TileInfoFertileDetail");
			}
			tileRI.color = FertileColor;
			break;
		case 2:
			if (isEmptyCell)
			{
				titleTMP.text = ScriptLocalization.TileInfoVeryFertile;
				descriptionTMP.text = LocalizationManager.GetTranslation("TileInfoVeryFertileDetail");
			}
			tileRI.color = VeryFertileColor;
			break;
		}
	}
}
