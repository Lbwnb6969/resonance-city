using UnityEngine;

public class BlacksmithFilterUI : MonoBehaviour, IWorkerUIElement
{
	public ResourceToggleButton ToolToggleButton;

	public ResourceToggleButton WeaponToggleButton;

	private int blacksmithHash = "blacksmith".GetHashCode();

	private void Start()
	{
		ToolToggleButton.OnToggle.AddListener(UpdateFilter);
		WeaponToggleButton.OnToggle.AddListener(UpdateFilter);
	}

	private void UpdateFilter()
	{
		if (GameUI.inst.SelectedBuildingIs(blacksmithHash))
		{
			GameUI.inst.GetBuildingSelected().GetComponent<Blacksmith>();
		}
	}

	public void UpdateForNewSelection()
	{
		if (GameUI.inst.SelectedBuildingIs(blacksmithHash))
		{
			GameUI.inst.GetBuildingSelected().GetComponent<Blacksmith>();
		}
	}

	void IWorkerUIElement.TryShow()
	{
		gameObject.SetActive(CanShow());
	}

	public bool CanShow()
	{
		return GameUI.inst.SelectedBuildingIs(blacksmithHash);
	}
}
