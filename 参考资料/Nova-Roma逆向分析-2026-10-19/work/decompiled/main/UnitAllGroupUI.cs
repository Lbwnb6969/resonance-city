using I2.Loc;
using UnityEngine;
using UnityEngine.EventSystems;

public class UnitAllGroupUI : MonoBehaviour, IUnitGroupUI
{
	public static UnitAllGroupUI inst;

	[SerializeField]
	private LegionSelectUnitUI selectUnitUIPrefab;

	[SerializeField]
	private GameObject containerObj;

	[SerializeField]
	private GameObject itemContainerObj;

	[SerializeField]
	private UnitTabUI tabUI;

	private int selectUnitsPoolCount;

	private ArrayExt<LegionSelectUnitUI> selectUnitsPool = new ArrayExt<LegionSelectUnitUI>(32);

	public IUnitControllable currHoveredUnit;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		if (!isVisible & v)
		{
			UnitUI.inst.SetTitle(LocalizationManager.GetTranslation("unitui_groupselection"));
		}
		else if (isVisible && !v)
		{
			currHoveredUnit = null;
		}
		Util.SetActive(containerObj, v);
		enabled = v;
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
	}

	public bool DoShowTab(UnitUI.GroupEntry entry, ArrayExt<IUnitControllable> currSelection)
	{
		return true;
	}

	private void Update()
	{
		if (!isVisible)
		{
			return;
		}
		selectUnitsPoolCount = 0;
		for (int i = 0; i < UnitControlSystem.inst.currSelection.Count; i++)
		{
			LegionSelectUnitUI selectUnitUI = GetSelectUnitUI();
			if (UnitSystem.inst.unitDataMap.TryGetValue(UnitControlSystem.inst.currSelection.data[i].GetUnitType(), out var value))
			{
				selectUnitUI.tooltip.tooltipTerm = value.name;
				selectUnitUI.icon.texture = value.icon.texture;
			}
			Util.SetActive(selectUnitUI.gameObject, active: true);
		}
		HideAccessSelectUnits();
	}

	private LegionSelectUnitUI GetSelectUnitUI()
	{
		if (selectUnitsPoolCount == selectUnitsPool.Count)
		{
			LegionSelectUnitUI legionSelectUnitUI = Object.Instantiate(selectUnitUIPrefab, itemContainerObj.transform);
			int i = selectUnitsPoolCount;
			legionSelectUnitUI.btn.onClick.AddListener(() =>
			{
				OnSelectUnitClicked(i);
			});
			EventTrigger.Entry entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerEnter;
			entry.callback.AddListener((BaseEventData e) =>
			{
				OnUnitHovered(i);
			});
			legionSelectUnitUI.eTrigger.triggers.Add(entry);
			entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerExit;
			entry.callback.AddListener((BaseEventData e) =>
			{
				OnUnitDehovered(i);
			});
			legionSelectUnitUI.eTrigger.triggers.Add(entry);
			selectUnitsPool.Add(legionSelectUnitUI);
		}
		return selectUnitsPool.data[selectUnitsPoolCount++];
	}

	private void OnSelectUnitClicked(int idx)
	{
		UnitUI.inst.SelectTarget(UnitControlSystem.inst.currSelection.data[idx]);
	}

	private void OnUnitHovered(int idx)
	{
		currHoveredUnit = UnitControlSystem.inst.currSelection.data[idx];
	}

	private void OnUnitDehovered(int idx)
	{
		if (UnitControlSystem.inst.currSelection.data[idx] == currHoveredUnit)
		{
			currHoveredUnit = null;
		}
	}

	private void HideAccessSelectUnits()
	{
		for (int num = selectUnitsPool.Count - 1; num >= selectUnitsPoolCount; num--)
		{
			Util.SetActive(selectUnitsPool.data[num].gameObject, active: false);
		}
	}
}
