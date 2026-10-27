using UnityEngine;

public class ThroneRoom : MonoBehaviour, IWorkerUIDisplay
{
	public int MaxGold = 250;

	public Building b;

	private string taxRate = "";

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	public bool ShowCustomButton()
	{
		return false;
	}

	public bool CustomButtonInteractable()
	{
		return false;
	}

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public string CustomButtonTitle()
	{
		return "ScriptLocalization.ThroneRoomTaxRate";
	}

	public string CustomButtonText()
	{
		return taxRate;
	}

	public Sprite CustomButtonImage()
	{
		return null;
	}

	public void CustomButtonClicked()
	{
	}
}
