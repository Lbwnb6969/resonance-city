using UnityEngine;
using UnityEngine.UI;

public class UnitMilitiaGroupUI : MonoBehaviour, IUnitGroupUI
{
	[SerializeField]
	private GameObject containerObj;

	[SerializeField]
	private GameObject moraleContainerObj;

	[SerializeField]
	private GameObject energyContainerObj;

	[SerializeField]
	private GameObject[] moraleObjs;

	[SerializeField]
	private Slider energySlider;

	[SerializeField]
	private Button disbandBtn;

	[SerializeField]
	private UnitTabUI tabUI;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void Start()
	{
		UnitSystem.UnitData unitData = UnitSystem.inst.unitDataMap[4];
		tabUI.icon.sprite = unitData.icon;
		disbandBtn.onClick.AddListener(OnDisbandClicked);
	}

	public void SetVisibility(bool v)
	{
		if (!isVisible & v)
		{
			UnitUI.inst.SetTitle("I2.Militia");
		}
		Util.SetActive(containerObj, v);
		enabled = v;
		isVisible = v;
	}

	public bool DoShowTab(UnitUI.GroupEntry entry, ArrayExt<IUnitControllable> currSelection)
	{
		for (int i = 0; i < currSelection.Count; i++)
		{
			if (currSelection.data[i].GetUnitType() == 4)
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
		int num = -1;
		bool flag2 = true;
		float num2 = -1f;
		ArrayExt<IUnitControllable> currSelection = UnitUI.inst.currSelection;
		for (int i = 0; i < currSelection.Count; i++)
		{
			LegionGroup legionGroup = ((LegionUnit)currSelection.data[i]).GetGroup();
			if (num == -1)
			{
				num = legionGroup.morale;
			}
			else if (num != legionGroup.morale)
			{
				flag = false;
			}
			if (num2 == -1f)
			{
				num2 = legionGroup.pep;
			}
			else if (Mathff.Abs(num2 - legionGroup.pep) > 0.1f)
			{
				flag2 = false;
			}
			if (!flag && !flag2)
			{
				break;
			}
		}
		if (flag)
		{
			for (int num3 = moraleObjs.Length - 1; num3 >= 0; num3--)
			{
				Util.SetActive(moraleObjs[num3], num3 >= num);
			}
		}
		Util.SetActive(moraleContainerObj, flag);
		if (flag2)
		{
			energySlider.value = num2;
		}
		Util.SetActive(energyContainerObj, flag2);
	}

	public void OnDisbandClicked()
	{
		ArrayExt<IUnitControllable> currSelection = UnitUI.inst.currSelection;
		for (int i = 0; i < currSelection.Count; i++)
		{
			currSelection.data[i].Disband();
		}
	}
}
