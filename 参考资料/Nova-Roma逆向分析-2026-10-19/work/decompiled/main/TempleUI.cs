using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class TempleUI : MonoBehaviour, IWorkerUIElement
{
	public TextMeshProUGUI bonusDesc;

	public TextMeshProUGUI dedicateDesc;

	public GameObject dedicateLaurel1;

	public GameObject dedicateLaurel2;

	public TextMeshProUGUI customTMP;

	public Button consult;

	private void Start()
	{
	}

	public void UpdateForNewSelection()
	{
	}

	public void OnClickConsult()
	{
		GameUI.inst.GetBuildingSelected().GetComponent<Temple>().ShowGods();
	}

	private void Update()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (!(buildingSelected != null))
		{
			return;
		}
		consult.interactable = buildingSelected.WorkersAllocated > 0;
		Temple component = buildingSelected.GetComponent<Temple>();
		int dedicateIdx = component.GetDedicateIdx();
		if (dedicateIdx != -1)
		{
			GodInfoUI component2 = GodUI.inst.godDisplay.gods[dedicateIdx].GetComponent<GodInfoUI>();
			dedicateDesc.SetText(string.Format(ScriptLocalization.workerui_templeui_dedicatedto_desc, LocalizationManager.GetTranslation(component2.GetLocalizedName())));
			Util.SetEnabled(customTMP, buildingSelected.uniqueNameHash == World.templeHash && dedicateIdx == 3 && component.bonusLevel > 0);
			if (dedicateIdx == 3)
			{
				customTMP.text = string.Format(LocalizationManager.GetTranslation("workerui_templeui_apollo_blessedvillagers"), component.GetActivePlaguedCount(), 20);
			}
		}
		else
		{
			Util.SetEnabled(customTMP, active: false);
			dedicateDesc.GetComponent<Localize>().Term = "workerui_templeui_undedicated_desc";
		}
		if (dedicateIdx != -1 && component.bonusLevel >= 1)
		{
			bonusDesc.SetText(GodUI.inst.bonuses[dedicateIdx].GetFormattedDesc(buildingSelected.WorkersAllocated > 0, component));
		}
		else
		{
			bonusDesc.SetText("");
		}
		Util.SetActive(dedicateLaurel1.gameObject, dedicateIdx != -1);
		Util.SetActive(dedicateLaurel2.gameObject, dedicateIdx != -1);
	}

	void IWorkerUIElement.TryShow()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null && (bool)buildingSelected.GetComponent<Temple>())
		{
			gameObject.SetActive(value: true);
		}
		else
		{
			gameObject.SetActive(value: false);
		}
	}
}
