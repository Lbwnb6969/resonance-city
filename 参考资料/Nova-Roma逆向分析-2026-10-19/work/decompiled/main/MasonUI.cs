using UnityEngine;
using UnityEngine.UI;

public class MasonUI : MonoBehaviour, IWorkerUIElement
{
	public Button FocusButton;

	private void Start()
	{
	}

	public void UpdateForNewSelection()
	{
	}

	public void OnClickFocusRepairTarget()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected.GetComponent<Mason>().damagedBuilding != null)
		{
			if (Cam.inst.desiredDist > 19f)
			{
				Cam.inst.desiredDist = 19f;
			}
			Cam.inst.SetDesiredTrackingPos(buildingSelected.GetComponent<Mason>().damagedBuilding.Center());
		}
	}

	public void Update()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		FocusButton.interactable = buildingSelected != null && buildingSelected.GetComponent<Mason>().damagedBuilding != null;
	}

	void IWorkerUIElement.TryShow()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null && (bool)buildingSelected.GetComponent<Mason>())
		{
			gameObject.SetActive(value: true);
		}
		else
		{
			gameObject.SetActive(value: false);
		}
	}
}
