using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UnitSwordsmenGroupUI : MonoBehaviour, IUnitGroupUI
{
	[SerializeField]
	private GameObject containerObj;

	[SerializeField]
	private GameObject moraleContainerObj;

	[SerializeField]
	private GameObject energyContainerObj;

	[SerializeField]
	private Slider energySlider;

	[SerializeField]
	private Button disbandBtn;

	[SerializeField]
	private UnitTabUI tabUI;

	[SerializeField]
	private Button recuperateBtn;

	private bool isVisible;

	public TextMeshProUGUI waterDebuffTxt;

	public TextMeshProUGUI experienceBuff;

	public Transform bonusIconContainer;

	public Transform bonusTextContainer;

	public Transform starContainer;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void Start()
	{
		disbandBtn.onClick.AddListener(OnDisbandClicked);
		recuperateBtn.onClick.AddListener(OnRecuperateClicked);
	}

	private void SetType(int type)
	{
		UnitUI.inst.SetTitle(LocalizationManager.GetTranslation(UnitSystem.inst.unitDataMap[type].name));
	}

	public void SetVisibility(bool v)
	{
		if (!isVisible & v)
		{
			IUnitControllable unitControllable = UnitUI.inst.currSelection.First();
			if (unitControllable != null)
			{
				SetType(unitControllable.GetUnitType());
			}
		}
		Util.SetActive(containerObj, v);
		enabled = v;
		isVisible = v;
		Util.SetActive(moraleContainerObj, active: false);
		Util.SetActive(energyContainerObj, active: false);
	}

	public bool DoShowTab(UnitUI.GroupEntry entry, ArrayExt<IUnitControllable> currSelection)
	{
		for (int i = 0; i < currSelection.Count; i++)
		{
			if ((entry.id == 1 && currSelection.data[i].GetUnitType() == 0) || (entry.id == 4 && currSelection.data[i].GetUnitType() == 4) || (entry.id == 5 && currSelection.data[i].GetUnitType() == 5))
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
		bool flag = true;
		float num = -1f;
		bool interactable = false;
		ArrayExt<IUnitControllable> currSelection = UnitUI.inst.currSelection;
		for (int i = 0; i < currSelection.Count; i++)
		{
			LegionUnit legionUnit = (LegionUnit)currSelection.data[i];
			LegionGroup legionGroup = legionUnit.GetGroup();
			if (num == -1f)
			{
				num = legionGroup.pep / (float)legionGroup.origNumCells;
			}
			else if (Mathff.Abs(num - legionGroup.pep) > 0.1f)
			{
				flag = false;
			}
			if (!flag)
			{
				break;
			}
			if (!legionUnit.IsBeingCarried())
			{
				Vector3 pos = legionUnit.GetPos();
				int landMassIdx = World.inst.GetCellDataClamped(pos).landMassIdx;
				if ((bool)legionUnit.ownerBarracks && legionUnit.ownerBarracks.LandMass() == landMassIdx && (legionGroup.numCells < legionGroup.origNumCells || legionGroup.pep < (float)legionGroup.numCells))
				{
					interactable = true;
				}
			}
		}
		recuperateBtn.interactable = interactable;
		if (flag)
		{
			energySlider.value = num;
		}
		Util.SetActive(energyContainerObj, flag);
		if (currSelection.Count == 1)
		{
			LegionGroup legionGroup2 = ((LegionUnit)currSelection.data[0]).GetGroup();
			if (legionGroup2.type != 4)
			{
				for (int j = 0; j < starContainer.transform.childCount; j++)
				{
					starContainer.transform.GetChild(j).GetComponent<Image>().color = ((j < legionGroup2.morale) ? Color.white : Color.gray);
				}
				if (legionGroup2.morale > 0)
				{
					experienceBuff.text = "+" + string.Format(LocalizationManager.GetTranslation("unitui_experiencebonus"), (int)((float)legionGroup2.morale * LegionSystem.Inst.moralePointReduction * 100f));
				}
				else
				{
					experienceBuff.text = "";
				}
			}
			Util.SetActive(moraleContainerObj, legionGroup2.type != 4);
			int num2 = 0;
			bonusTextContainer.GetChild(num2).GetComponent<TextMeshProUGUI>().text = ScriptLocalization.AMapSelectNone;
			Util.SetActive(bonusTextContainer.GetChild(num2), active: true);
			Util.SetActive(bonusIconContainer.GetChild(num2), active: true);
			if (legionGroup2.heightAdvantageBonus > 0f)
			{
				string text = string.Format(LocalizationManager.GetTranslation("unitui_attackbonus_height"), "+ " + (int)(legionGroup2.heightAdvantageBonus * 100f));
				bonusTextContainer.GetChild(num2).GetComponent<TextMeshProUGUI>().SetText(text);
				Util.SetActive(bonusTextContainer.GetChild(num2), active: true);
				Util.SetActive(bonusIconContainer.GetChild(num2), active: true);
				num2++;
			}
			if (legionGroup2.flankBonus > 0f)
			{
				string text2 = string.Format(LocalizationManager.GetTranslation("unitui_attackbonus_flanking"), "+ " + (int)(legionGroup2.flankBonus * 100f));
				bonusTextContainer.GetChild(num2).GetComponent<TextMeshProUGUI>().SetText(text2);
				Util.SetActive(bonusTextContainer.GetChild(num2), active: true);
				Util.SetActive(bonusIconContainer.GetChild(num2), active: true);
				num2++;
			}
			if (LegionSystem.Inst.IsFrenzied())
			{
				string text3 = string.Format(LocalizationManager.GetTranslation("unitui_attackbonus_emboldened"), "+ 25");
				bonusTextContainer.GetChild(num2).GetComponent<TextMeshProUGUI>().SetText(text3);
				Util.SetActive(bonusTextContainer.GetChild(num2), active: true);
				Util.SetActive(bonusIconContainer.GetChild(num2), active: true);
				num2++;
			}
			for (int k = num2; k < bonusTextContainer.childCount; k++)
			{
				Util.SetActive(bonusTextContainer.GetChild(k), active: false);
				Util.SetActive(bonusIconContainer.GetChild(k), active: false);
			}
			Util.SetActive(waterDebuffTxt.gameObject, legionGroup2.inWater);
			if (legionGroup2.inWater)
			{
				waterDebuffTxt.SetText(LocalizationManager.GetTranslation("unitui_waterdebuff"), -25f);
			}
		}
		else
		{
			for (int l = 0; l < bonusTextContainer.childCount; l++)
			{
				Util.SetActive(bonusTextContainer.GetChild(l), active: false);
				Util.SetActive(bonusIconContainer.GetChild(l), active: false);
			}
			Util.SetActive(moraleContainerObj, active: false);
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

	public void OnRecuperateClicked()
	{
		ArrayExt<IUnitControllable> currSelection = UnitUI.inst.currSelection;
		for (int i = 0; i < currSelection.Count; i++)
		{
			IUnitControllable unitControllable = currSelection.data[i];
			if (!unitControllable.IsBeingCarried() && unitControllable is LegionUnit legionUnit)
			{
				Vector3 pos = unitControllable.GetPos();
				int landMassIdx = World.inst.GetCellDataClamped(pos).landMassIdx;
				if ((bool)legionUnit.ownerBarracks && legionUnit.ownerBarracks.LandMass() == landMassIdx)
				{
					UnitSystem.inst.MoveTo(currSelection.data[i], legionUnit.ownerBarracks.GetComponent<Building>());
				}
			}
		}
	}
}
