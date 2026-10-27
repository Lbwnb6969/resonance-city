using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingRubbleUI : MonoBehaviour
{
	[SerializeField]
	private RubbleGroupUI prefab;

	[SerializeField]
	private Transform groupContainer;

	[SerializeField]
	private TextMeshProUGUI totalCostTMP;

	[SerializeField]
	private Button rebuildBtn;

	[SerializeField]
	private Localize rebuildLocalize;

	[SerializeField]
	private TooltipHook tooltip;

	[SerializeField]
	private GameObject warningObj;

	private Rubble rubble;

	private Building building;

	private int rubbleCount;

	private ArrayExt<RubbleGroupUI> rubblePool = new ArrayExt<RubbleGroupUI>(32);

	private Dictionary<string, int> rubbleMap = new Dictionary<string, int>(32);

	private List<BuildingCollapseManager.RubbleGroup> rubbleGroups = new List<BuildingCollapseManager.RubbleGroup>(32);

	private List<Building> linkedRubble = new List<Building>(32);

	private ResourceAmount totalCost = new ResourceAmount();

	public bool IsVisible()
	{
		return gameObject.activeSelf;
	}

	private void Awake()
	{
		rebuildBtn.onClick.AddListener(OnRebuild);
	}

	private void Start()
	{
		tooltip.tooltipTerm = "tooltipui_hotkey";
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
		tooltip.toolTipText = string.Format(ScriptLocalization.tooltipui_hotkey, ConfigurableControls.inst.GetKeyAction(303));
	}

	private void OnKeybindChanged(int id, ConfigurableControls.Keybind keybind)
	{
		if (id == 303)
		{
			tooltip.toolTipText = string.Format(ScriptLocalization.tooltipui_hotkey, keybind);
		}
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(gameObject, v);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || b.UniqueNameHash() != World.rubbleHash)
		{
			SetVisibility(v: false);
			return;
		}
		building = b;
		rubble = building.GetComponent<Rubble>();
		Cell cell = building.GetCell();
		ArrayExt<BuildingCollapseManager.RubbleGroup> arrayExt = BuildingCollapseManager.inst.groupCells[cell.index];
		if (arrayExt == null || arrayExt.Count == 0)
		{
			SetVisibility(v: false);
			return;
		}
		rubbleMap.Clear();
		rubbleGroups.Clear();
		linkedRubble.Clear();
		BuildingCollapseManager.CollectGroups(cell, ref rubbleGroups, ref rubbleMap, ref linkedRubble);
		totalCost.Clear();
		rubbleCount = 0;
		foreach (KeyValuePair<string, int> item in rubbleMap)
		{
			RubbleGroupUI rubbleGroupUI = GetRubbleGroupUI();
			Building placeableByUniqueName = GameState.inst.GetPlaceableByUniqueName(item.Key);
			ResourceAmount addR = placeableByUniqueName.GetCost(building.LandMass());
			if (item.Value > 1)
			{
				addR *= (float)item.Value;
			}
			totalCost.Add(in addR);
			rubbleGroupUI.titleTMP.text = $"{item.Value}x {placeableByUniqueName.FriendlyName}";
			rubbleGroupUI.costTMP.text = "  " + addR.ToString("  ");
			Util.SetEnabled(rubbleGroupUI.costTMP, !addR.IsNone());
			Util.SetActive(rubbleGroupUI.gameObject, active: true);
		}
		for (int num = rubblePool.Count - 1; num >= rubbleCount; num--)
		{
			Util.SetActive(rubblePool.data[num].gameObject, active: false);
		}
		Util.SetActive(warningObj, Creative.inst.IsCreativeOptionOn(0));
		RefreshVisuals();
		SetVisibility(v: true);
	}

	public void OnDeselected()
	{
		building = null;
		rubble = null;
	}

	private void RefreshVisuals()
	{
		ResourceAmount resourceAmount = Player.inst.resourcesPerLandmass[building.LandMass()];
		totalCostTMP.text = ScriptLocalization.Total + ":  " + totalCost.NeedCost(resourceAmount);
		Util.SetEnabled(totalCostTMP, !totalCost.IsNone() && rubbleMap.Keys.Count > 1);
		bool flag = resourceAmount.HasCost(totalCost);
		rebuildBtn.interactable = flag;
		rebuildLocalize.SetTerm(flag ? "RubbleUIRebuild" : "b Insufficient resources b");
		for (int i = 0; i < linkedRubble.Count; i++)
		{
			if (!(linkedRubble[i] == building))
			{
				linkedRubble[i].SetOutlineImmediate(1);
			}
		}
		if (flag && ConfigurableControls.inst.GetInputActionKeyDown(303))
		{
			OnRebuild();
		}
	}

	private RubbleGroupUI GetRubbleGroupUI()
	{
		if (rubbleCount > 0)
		{
			Util.SetActive(rubblePool.data[rubbleCount - 1].dividerObj, active: true);
		}
		if (rubbleCount >= rubblePool.Count)
		{
			RubbleGroupUI item = UnityEngine.Object.Instantiate(prefab, groupContainer, worldPositionStays: false);
			rubblePool.Add(item);
		}
		RubbleGroupUI obj = rubblePool.data[rubbleCount++];
		Util.SetActive(obj.dividerObj, active: false);
		return obj;
	}

	private void OnRebuild()
	{
		Building building = BuildingCollapseManager.RebuildGroups(rubbleGroups);
		this.building.GetLandMassOwner().Gold -= totalCost.Get(4);
		if (rubbleGroups.Count == 1 && building != null)
		{
			GameUI.inst.SetSelectedBuildingNew(building, forceUpdate: true);
		}
		else
		{
			GameUI.inst.ClearCellSelected();
		}
	}

	private void Update()
	{
		if (!(rubble == null) && !(building == null))
		{
			RefreshVisuals();
		}
	}
}
