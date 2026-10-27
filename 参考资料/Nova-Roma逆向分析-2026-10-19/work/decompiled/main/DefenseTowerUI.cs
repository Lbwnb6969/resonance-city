using I2.Loc;
using TMPro;
using UnityEngine;

public class DefenseTowerUI : MonoBehaviour, IWorkerUIElement
{
	public TextMeshProUGUI dmgTxt;

	public TextMeshProUGUI bonusTxt;

	public GameObject bonusIcon;

	public void TryShow()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null && (bool)buildingSelected.GetComponent<ArrowDamage>())
		{
			gameObject.SetActive(value: true);
		}
		else
		{
			gameObject.SetActive(value: false);
		}
	}

	public void UpdateForNewSelection()
	{
	}

	private void Start()
	{
	}

	private void Update()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (!(buildingSelected != null))
		{
			return;
		}
		ArrowDamage component = buildingSelected.GetComponent<ArrowDamage>();
		int num = 0;
		Cell cell = buildingSelected.GetCell();
		RadiusBonusBuildingProduction radiusBonusBuildingProduction = null;
		CellProductionInfluence cellProductionInfluenceDataClamped = World.inst.GetCellProductionInfluenceDataClamped(cell.x, cell.z);
		for (int i = 0; i < cellProductionInfluenceDataClamped.radiusBonusesBuilding.Count; i++)
		{
			if (cellProductionInfluenceDataClamped.radiusBonusesBuilding[i].GetBonus() > num)
			{
				num = cellProductionInfluenceDataClamped.radiusBonusesBuilding[i].GetBonus();
				radiusBonusBuildingProduction = cellProductionInfluenceDataClamped.radiusBonusesBuilding[i];
			}
		}
		if (num > 0 && radiusBonusBuildingProduction != null)
		{
			bonusTxt.text = string.Format(LocalizationManager.GetTranslation("workerui_defensetowerui_templebonus"), (radiusBonusBuildingProduction.GetBonus() > 0) ? radiusBonusBuildingProduction.Bonus.ToString() : ("<color=red>" + radiusBonusBuildingProduction.GetBonus() + "</color>"));
		}
		Util.SetActive(bonusIcon, num > 0);
		float num2 = component.EffectiveDPS() * (1f + (float)num / 100f) * 10f;
		if (LocalizationManager.CurrentLanguage == "Japanese" || LocalizationManager.CurrentLanguage == "Turkish")
		{
			if (num > 0)
			{
				dmgTxt.text = $"{ScriptLocalization.PerSecond} <color=green>{((int)num2).ToString()}";
			}
			else
			{
				dmgTxt.text = $"{ScriptLocalization.PerSecond} {((int)num2).ToString()}";
			}
		}
		else if (num > 0)
		{
			dmgTxt.text = $"<color=green>{((int)num2).ToString()}</color> {ScriptLocalization.PerSecond}";
		}
		else
		{
			dmgTxt.text = $"{((int)num2).ToString()} {ScriptLocalization.PerSecond}";
		}
	}
}
