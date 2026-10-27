using UnityEngine;

public class UnitCatapultGroupUI : MonoBehaviour, IUnitGroupUI
{
	[SerializeField]
	private UnitTabUI tabUI;

	[SerializeField]
	private GameObject containerObj;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void Start()
	{
		UnitSystem.UnitData unitData = UnitSystem.inst.unitDataMap[2];
		tabUI.icon.sprite = unitData.icon;
	}

	public void SetVisibility(bool v)
	{
		if (!isVisible & v)
		{
			UnitUI.inst.SetTitle("I2.Catapults");
		}
		Util.SetActive(containerObj, v);
		enabled = v;
		isVisible = v;
	}

	public bool DoShowTab(UnitUI.GroupEntry entry, ArrayExt<IUnitControllable> currSelection)
	{
		for (int i = 0; i < currSelection.Count; i++)
		{
			if (currSelection.data[i].GetUnitType() == 2)
			{
				return true;
			}
		}
		return false;
	}

	private void Update()
	{
		_ = isVisible;
	}
}
