using UnityEngine;
using UnityEngine.UI;

public class ColosseumBuildingUI : MonoBehaviour, IWorkerUIElement
{
	public Button planGamesButton;

	public TooltipHook btnTooltip;

	private Colosseum currentColosseum;

	public void TryShow()
	{
		currentColosseum = null;
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null)
		{
			Colosseum component = buildingSelected.GetComponent<Colosseum>();
			if (component != null)
			{
				currentColosseum = component;
			}
		}
		gameObject.SetActive(currentColosseum != null);
	}

	public void UpdateForNewSelection()
	{
	}

	private void Update()
	{
		if (gameObject.activeSelf)
		{
			RefreshUI();
		}
	}

	private void RefreshUI()
	{
		bool flag = currentColosseum.b.GetWorkerPercent() >= 1f;
		bool flag2 = currentColosseum.b.IsOnFire();
		planGamesButton.interactable = flag && currentColosseum.CanStartNewEvent() && !flag2;
		if (!flag)
		{
			btnTooltip.tooltipTerm = "NeedsFullStaff";
		}
		else if (flag2)
		{
			btnTooltip.tooltipTerm = "Fire Risk";
		}
		else
		{
			btnTooltip.tooltipTerm = string.Empty;
		}
	}

	public void OnPlanGamesClicked()
	{
		SfxSystem.PlayUiSelect();
		if (currentColosseum != null && currentColosseum.CanStartNewEvent() && !currentColosseum.b.IsOnFire())
		{
			ColosseumEvent colosseumEvent = currentColosseum.StartNewEvent();
			ColosseumPlannerUI.inst.Show(currentColosseum, colosseumEvent);
		}
	}
}
