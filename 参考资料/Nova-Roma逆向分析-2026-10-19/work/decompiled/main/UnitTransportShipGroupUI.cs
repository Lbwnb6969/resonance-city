using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UnitTransportShipGroupUI : MonoBehaviour, IUnitGroupUI
{
	private class CarryEntry
	{
		public int carryCount;

		public const int MAX_CARRY_PER_CONTAINER = 5;

		public Transform carryContainer;

		public ArrayExt<UnitCarryItemUI> carryItems;
	}

	[SerializeField]
	private GameObject containerObj;

	[SerializeField]
	private TextMeshProUGUI descriptionTMP;

	[SerializeField]
	private Transform carryContainerRootT;

	[SerializeField]
	private Transform carryContainerPrefab;

	[SerializeField]
	private UnitCarryItemUI carryItemUIPrefab;

	[SerializeField]
	private Button disbandBtn;

	private int carryItemPoolCount;

	private ArrayExt<UnitCarryItemUI> carryItemPool = new ArrayExt<UnitCarryItemUI>(32);

	private int carryEntryPoolCount;

	private ArrayExt<CarryEntry> carryEntriesPool = new ArrayExt<CarryEntry>(32);

	[SerializeField]
	private UnitTabUI tabUI;

	private bool isVisible;

	public Button settleButton;

	public GameObject settleContainer;

	public GameObject settleInstructionsLocked;

	public GameObject settleInstructions;

	public TextMeshProUGUI settleTitle;

	public GameObject romanOutpostPrefab;

	public Image outpostIcon;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void Start()
	{
		disbandBtn.onClick.AddListener(OnDisbandClicked);
		UnitSystem.UnitData unitData = UnitSystem.inst.unitDataMap[3];
		tabUI.icon.sprite = unitData.icon;
	}

	public void SetVisibility(bool v)
	{
		if (!isVisible & v)
		{
			IUnitControllable unitControllable = UnitUI.inst.currSelection.First();
			if (unitControllable != null)
			{
				switch (unitControllable.TeamID())
				{
				case 0:
					UnitUI.inst.SetTitle(LocalizationManager.GetTranslation("unitui_trooptransportship_name"));
					descriptionTMP.text = LocalizationManager.GetTranslation("unitui_trooptransportship_desc");
					break;
				case 1:
					UnitUI.inst.SetTitle(LocalizationManager.GetTranslation("unitui_trooptransportship_enemyname"));
					descriptionTMP.text = LocalizationManager.GetTranslation("unitui_trooptransportship_desc");
					break;
				}
			}
		}
		Util.SetActive(containerObj, v);
		enabled = v;
		isVisible = v;
	}

	public bool DoShowTab(UnitUI.GroupEntry entry, ArrayExt<IUnitControllable> currSelection)
	{
		for (int i = 0; i < currSelection.Count; i++)
		{
			if (currSelection.data[i].GetUnitType() == 3)
			{
				return true;
			}
		}
		return false;
	}

	private void Update()
	{
		if (!isVisible)
		{
			return;
		}
		ResetPool();
		bool flag = UnitUI.inst.currSelection.Count == 1 && UnitUI.inst.currSelection.First().TeamID() == 0;
		if (flag && UnitUI.inst.currSelection.First() is UnitTransportShip { maxUnitsCarryable: var num } unitTransportShip)
		{
			bool flag2 = false;
			for (int i = 0; i < unitTransportShip.loadTarget.Count; i++)
			{
				IUnitControllable unitControllable = unitTransportShip.loadTarget.data[i];
				if (unitControllable == null)
				{
					continue;
				}
				UnitSystem.UnitData unitDataByType = UnitSystem.inst.GetUnitDataByType(unitControllable.GetUnitType());
				if (unitDataByType.id == 0)
				{
					flag2 = true;
				}
				UnitCarryItemUI[] carryItems = GetCarryItems(unitControllable.GetSlotsOccupied());
				num -= unitControllable.GetSlotsOccupied();
				if (carryItems != null)
				{
					foreach (UnitCarryItemUI obj in carryItems)
					{
						obj.tooltip.tooltipTerm = unitDataByType.name;
						obj.icon.sprite = unitDataByType.icon;
						Util.SetEnabled(obj.icon, active: true);
						Util.SetActive(obj.gameObject, active: true);
					}
				}
			}
			if (num > 0)
			{
				UnitCarryItemUI[] carryItems2 = GetCarryItems(num);
				if (carryItems2 != null)
				{
					foreach (UnitCarryItemUI obj2 in carryItems2)
					{
						obj2.tooltip.tooltipTerm = "workerui_stockpileui_stack_tooltip_empty";
						Util.SetEnabled(obj2.icon, active: false);
						Util.SetActive(obj2.gameObject, active: true);
					}
				}
			}
			settleButton.interactable = unitTransportShip.CanSettle;
			if (unitTransportShip.CanSettle)
			{
				outpostIcon.color = Color.white;
				settleTitle.color = Color.white;
			}
			else
			{
				outpostIcon.color = Color.gray;
				settleTitle.color = Color.gray;
			}
			bool flag3 = unitTransportShip.CanSettle | flag2;
			Util.SetActive(settleInstructions, flag3);
			Util.SetActive(settleInstructionsLocked, !flag3);
		}
		HideUnusedCarryItems();
		Util.SetActive(carryContainerRootT.gameObject, flag);
		Util.SetActive(settleContainer.gameObject, flag);
	}

	private UnitCarryItemUI[] GetCarryItems(int amt)
	{
		if (amt > 5)
		{
			Debug.Log($"Unable to support size of unit. Size:{amt}");
			return null;
		}
		UnitCarryItemUI[] array = new UnitCarryItemUI[amt];
		for (int i = 0; i < carryEntryPoolCount; i++)
		{
			CarryEntry carryEntry = carryEntriesPool.data[i];
			int carryCount = carryEntry.carryCount;
			if (carryEntry.carryCount - 5 >= amt)
			{
				for (int j = 0; j < amt; j++)
				{
					array[j] = carryEntry.carryItems.data[j + carryCount];
				}
				carryEntry.carryCount += amt;
				return array;
			}
		}
		if (carryEntryPoolCount == carryEntriesPool.Count)
		{
			CarryEntry carryEntry2 = new CarryEntry();
			carryEntry2.carryItems = new ArrayExt<UnitCarryItemUI>(5);
			GameObject gameObject = Object.Instantiate(carryContainerPrefab.gameObject, carryContainerRootT);
			carryEntry2.carryContainer = gameObject.transform;
			for (int k = 0; k < 5; k++)
			{
				UnitCarryItemUI item = Object.Instantiate(carryItemUIPrefab, gameObject.transform);
				carryEntry2.carryItems.Add(item);
			}
			carryEntriesPool.Add(carryEntry2);
		}
		CarryEntry carryEntry3 = carryEntriesPool.data[carryEntryPoolCount++];
		for (int l = 0; l < amt; l++)
		{
			array[l] = carryEntry3.carryItems.data[l];
		}
		carryEntry3.carryCount = amt;
		Util.SetActive(carryEntry3.carryContainer, active: true);
		return array;
	}

	public void OnUnitLockChanged(int idx)
	{
		if (UnitUI.inst.IsAnyIndividualSelected() && UnitUI.inst.currSelection.First() is UnitTransportShip unitTransportShip)
		{
			unitTransportShip.ToggleUnitLock(unitTransportShip.carriedUnitInSlot[idx]);
		}
	}

	private void ResetPool()
	{
		carryEntryPoolCount = 0;
		for (int i = 0; i < carryEntriesPool.Count; i++)
		{
			carryEntriesPool.data[i].carryCount = 0;
		}
	}

	public void HideUnusedCarryItems()
	{
		for (int i = 0; i < carryEntriesPool.Count; i++)
		{
			CarryEntry carryEntry = carryEntriesPool.data[i];
			for (int j = carryEntry.carryCount; j < carryEntry.carryItems.Count; j++)
			{
				Util.SetActive(carryEntry.carryItems.data[j].gameObject, active: false);
			}
			Util.SetActive(carryEntry.carryContainer.gameObject, carryEntry.carryCount > 0);
		}
	}

	public void OnClickedSettle()
	{
		if (UnitUI.inst.currSelection.First() is UnitTransportShip unitTransportShip)
		{
			Outpost component = GameUI.inst.CurrPlacementMode.SetCursorObject(romanOutpostPrefab.GetComponent<Building>(), notFirstPlacement: false).GetComponent<Outpost>();
			component.seedShip = unitTransportShip;
			component.placementRadius = unitTransportShip.SearchRadius;
			gameObject.SetActive(value: false);
		}
	}

	public void OnDisbandClicked()
	{
		ArrayExt<IUnitControllable> currSelection = UnitUI.inst.currSelection;
		for (int num = currSelection.Count - 1; num >= 0; num--)
		{
			currSelection.data[num].Disband();
		}
	}
}
