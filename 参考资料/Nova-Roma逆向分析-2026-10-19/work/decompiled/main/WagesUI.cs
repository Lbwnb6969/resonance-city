using I2.Loc;
using TMPro;
using UnityEngine;

public class WagesUI : MonoBehaviour, IWorkerUIElement
{
	public TextMeshProUGUI wageTxt;

	private void Start()
	{
	}

	private void Update()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null)
		{
			WagePayer component = buildingSelected.GetComponent<WagePayer>();
			float num = (float)component.GetGoldWage(buildingSelected.GetLandMassOwner()) * component.PaydaysPerYear();
			wageTxt.SetText(ScriptLocalization.Wages, (int)num);
		}
	}

	void IWorkerUIElement.TryShow()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null && (bool)buildingSelected.GetComponent<WagePayer>())
		{
			gameObject.SetActive(value: true);
		}
		else
		{
			gameObject.SetActive(value: false);
		}
	}

	void IWorkerUIElement.UpdateForNewSelection()
	{
	}
}
