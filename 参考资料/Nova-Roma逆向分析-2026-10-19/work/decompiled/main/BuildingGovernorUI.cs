using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingGovernorUI : MonoBehaviour, IWorkerUIElement
{
	public TextMeshProUGUI governorName;

	public TextMeshProUGUI governorDesc;

	public Button selectGovernor;

	public void TryShow()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null && (buildingSelected.uniqueNameHash == World.romanOutpostHash || buildingSelected.uniqueNameHash == World.romanOutpostHashNewIsland))
		{
			gameObject.SetActive(value: true);
			int count = World.inst.GetVillagersForLandMass(buildingSelected.LandMass()).Count;
			Governor focusedGovenor = Player.inst.FocusedGovenor;
			if (focusedGovenor == null)
			{
				if (count < Player.inst.citizensGovernorReq)
				{
					governorName.text = string.Format(ScriptLocalization.workerui_barracksui_locked, Player.inst.citizensGovernorReq);
				}
				else
				{
					governorName.text = LocalizationManager.GetTranslation("workerui_nogovernor");
				}
			}
			else
			{
				governorName.text = LocalizationManager.GetTranslation("workerui_governor") + ": " + focusedGovenor.profile.Name;
			}
			selectGovernor.interactable = count >= Player.inst.citizensGovernorReq;
			Util.SetActive(governorDesc.gameObject, active: false);
		}
		else
		{
			gameObject.SetActive(value: false);
		}
	}

	public void UpdateForNewSelection()
	{
	}

	public void OnGovernorClicked()
	{
		AdvisorUI.inst.Show();
	}
}
