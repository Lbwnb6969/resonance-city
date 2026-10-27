using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingMarketUI : MonoBehaviour
{
	[SerializeField]
	private TextMeshProUGUI storageTMP;

	[SerializeField]
	private Image iconRI;

	[SerializeField]
	private StaticTooltipHook tooltipHook;

	private Building building;

	private Market market;

	public void SetVisibility(bool isVisible)
	{
		gameObject.SetActive(isVisible);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (market = b.GetComponent<Market>()) == null)
		{
			SetVisibility(isVisible: false);
			return;
		}
		building = b;
		int resourceID = market.stack.resourceID;
		if (FreeResourceSystem.inst.resourceDefMap.TryGetValue(resourceID, out var value))
		{
			iconRI.sprite = value.texture;
			tooltipHook.SetTerm(value.name);
			RefreshVisuals();
			SetVisibility(isVisible: true);
		}
		else
		{
			SetVisibility(isVisible: false);
		}
	}

	public void OnDeselected()
	{
		building = null;
		market = null;
	}

	private void Update()
	{
		if (!(market == null))
		{
			RefreshVisuals();
		}
	}

	private void RefreshVisuals()
	{
		storageTMP.text = $"{market.stack.Count()} / {market.stack.MaxCapacity()}";
	}
}
