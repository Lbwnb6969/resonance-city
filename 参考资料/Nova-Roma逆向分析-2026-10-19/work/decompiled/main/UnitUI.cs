using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UnitUI : MonoBehaviour
{
	[Serializable]
	public struct GroupEntry
	{
		public int id;

		public UnitTabUI tabUI;

		public InterfaceReference<IUnitGroupUI> itemUI;

		public int unitType;
	}

	public static UnitUI inst;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private Button closeBtn;

	[SerializeField]
	private TextMeshProUGUI titleTMP;

	[SerializeField]
	private GameObject tabContainer;

	[SerializeField]
	private List<GroupEntry> entries = new List<GroupEntry>(32);

	private Dictionary<int, GroupEntry> groups = new Dictionary<int, GroupEntry>(32);

	private int currSelectedGroupID;

	private bool isIndividualSelected;

	public ArrayExt<IUnitControllable> currSelection = new ArrayExt<IUnitControllable>(32);

	public static ValueDropdownList<int> GroupOptions = new ValueDropdownList<int>
	{
		{ "ALL", 0 },
		{ "SWORDSMEN", 1 },
		{ "MILITIA", 4 },
		{ "CAVALRY", 5 },
		{ "CATAPULTS", 2 },
		{ "TRANSPORT SHIPS", 3 }
	};

	public const int TAB_ALL = 0;

	public const int TAB_SWORDSMEN = 1;

	public const int TAB_CATAPULTS = 2;

	public const int TAB_TRANSPORT_SHIPS = 3;

	public const int TAB_MILITIA = 4;

	public const int TAB_CAVALRY = 5;

	private bool isVisible;

	public bool IsAnyGroupSelected()
	{
		return !isIndividualSelected;
	}

	public bool IsGroupSelected(int tabID)
	{
		return currSelectedGroupID == tabID;
	}

	public bool IsAnyIndividualSelected()
	{
		if (isIndividualSelected)
		{
			return currSelection.Count == 1;
		}
		return false;
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		if (!v)
		{
			currSelection.ClearFast();
			UnitControlSystem.inst.isCustomSelection = false;
			UnitControlSystem.inst.customCurrSelection.ClearFast();
			currSelectedGroupID = 0;
			isIndividualSelected = false;
			for (int i = 0; i < entries.Count; i++)
			{
				entries[i].itemUI.Value.SetVisibility(v: false);
			}
		}
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		closeBtn.onClick.AddListener(() =>
		{
			GameUI.inst.ReturnToDefaultCursorMode();
		});
		groups.Clear();
		for (int num = 0; num < entries.Count; num++)
		{
			groups.TryAdd(entries[num].id, entries[num]);
		}
		for (int num2 = 0; num2 < entries.Count; num2++)
		{
			int idx = num2;
			entries[num2].tabUI.toggle.onValueChanged.AddListener((bool isOn) =>
			{
				if (isOn)
				{
					SelectGroup(entries[idx].id);
				}
			});
		}
		UnitControlSystem unitControlSystem = UnitControlSystem.inst;
		unitControlSystem.OnSelectionChanged = (UnitControlSystem.SelectionChange)Delegate.Combine(unitControlSystem.OnSelectionChanged, new UnitControlSystem.SelectionChange(OnSelectionChanged));
	}

	private void OnDestroy()
	{
		UnitControlSystem unitControlSystem = UnitControlSystem.inst;
		unitControlSystem.OnSelectionChanged = (UnitControlSystem.SelectionChange)Delegate.Remove(unitControlSystem.OnSelectionChanged, new UnitControlSystem.SelectionChange(OnSelectionChanged));
	}

	private void Update()
	{
		if (!isVisible || !UnitControlSystem.inst.HasSelection())
		{
			return;
		}
		for (int i = 0; i < entries.Count; i++)
		{
			bool flag = entries[i].itemUI.Value.DoShowTab(entries[i], UnitControlSystem.inst.currSelection);
			entries[i].tabUI.SetVisibility(flag);
			if (!flag)
			{
				continue;
			}
			int num = 0;
			for (int j = 0; j < UnitControlSystem.inst.currSelection.Count; j++)
			{
				IUnitControllable unitControllable = UnitControlSystem.inst.currSelection.data[j];
				if (entries[i].id == 0 || entries[i].unitType == unitControllable.GetUnitType())
				{
					num++;
				}
			}
			entries[i].tabUI.amtTMP.text = num.ToString();
		}
		Util.SetActive(tabContainer, UnitControlSystem.inst.currSelection.Count > 1);
	}

	public void OnSelectionChanged(ArrayExt<IUnitControllable> curr)
	{
		if (curr.Count == 1)
		{
			SelectTarget(curr.First());
		}
		else if (IsAnyIndividualSelected())
		{
			SelectGroup(0);
		}
		else
		{
			if (!IsAnyGroupSelected() || !groups.TryGetValue(currSelectedGroupID, out var value))
			{
				return;
			}
			if (value.id == 0)
			{
				SelectGroup(0);
				return;
			}
			for (int i = 0; i < curr.Count; i++)
			{
				if (value.unitType == curr.data[i].GetUnitType())
				{
					SelectGroup(currSelectedGroupID);
					return;
				}
			}
			SelectGroup(0);
		}
	}

	public void SelectTarget(IUnitControllable target)
	{
		if (currSelectedGroupID != -1 && groups.TryGetValue(currSelectedGroupID, out var value))
		{
			value.tabUI.toggle.SetIsOnWithoutNotify(value: false);
			value.itemUI.Value.SetVisibility(v: false);
		}
		currSelectedGroupID = -1;
		currSelection.Clear();
		currSelection.Add(target);
		bool flag = UnitControlSystem.inst.currSelection.Count > 1;
		UnitControlSystem.inst.isCustomSelection = flag;
		if (flag)
		{
			UnitControlSystem.inst.customCurrSelection.ClearFast();
			UnitControlSystem.inst.customCurrSelection.Add(target);
		}
		for (int i = 0; i < entries.Count; i++)
		{
			entries[i].itemUI.Value.SetVisibility(v: false);
		}
		for (int j = 0; j < entries.Count; j++)
		{
			GroupEntry groupEntry = entries[j];
			if (groupEntry.unitType == target.GetUnitType())
			{
				currSelectedGroupID = groupEntry.id;
				isIndividualSelected = true;
				groupEntry.itemUI.Value.SetVisibility(v: true);
				break;
			}
		}
	}

	public void SelectGroup(int id)
	{
		if (currSelectedGroupID != -1 && currSelectedGroupID != id && groups.TryGetValue(currSelectedGroupID, out var value))
		{
			value.tabUI.toggle.SetIsOnWithoutNotify(value: false);
			value.itemUI.Value.SetVisibility(v: false);
		}
		if (groups.TryGetValue(id, out var value2))
		{
			currSelection.Clear();
			if (value2.id == 0)
			{
				UnitControlSystem.inst.isCustomSelection = false;
				currSelection.AddRange(UnitControlSystem.inst.currSelection);
			}
			else
			{
				for (int i = 0; i < UnitControlSystem.inst.currSelection.Count; i++)
				{
					IUnitControllable unitControllable = UnitControlSystem.inst.currSelection.data[i];
					if (value2.unitType == unitControllable.GetUnitType())
					{
						currSelection.Add(unitControllable);
					}
				}
				UnitControlSystem.inst.isCustomSelection = true;
				UnitControlSystem.inst.customCurrSelection.ClearFast();
				UnitControlSystem.inst.customCurrSelection.AddRange(currSelection);
			}
			value2.itemUI.Value.SetVisibility(v: true);
			value2.tabUI.toggle.SetIsOnWithoutNotify(value: true);
		}
		currSelectedGroupID = id;
		isIndividualSelected = false;
	}

	private void CollectSelection()
	{
		if (IsAnyIndividualSelected() || !groups.TryGetValue(currSelectedGroupID, out var value))
		{
			return;
		}
		currSelection.Clear();
		if (value.id == 0)
		{
			UnitControlSystem.inst.isCustomSelection = false;
			currSelection.AddRange(UnitControlSystem.inst.currSelection);
			return;
		}
		for (int i = 0; i < UnitControlSystem.inst.currSelection.Count; i++)
		{
			IUnitControllable unitControllable = UnitControlSystem.inst.currSelection.data[i];
			if (value.id == 0 || value.unitType == unitControllable.GetUnitType())
			{
				currSelection.Add(unitControllable);
			}
		}
		UnitControlSystem.inst.isCustomSelection = true;
		UnitControlSystem.inst.customCurrSelection.ClearFast();
		UnitControlSystem.inst.customCurrSelection.AddRange(currSelection);
	}

	public void SetTitle(string text)
	{
		titleTMP.text = text;
	}
}
