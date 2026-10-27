using UnityEngine;
using UnityEngine.UI;

public class StorageTabUI : MonoBehaviour
{
	public static StorageTabUI inst;

	public Toggle ordersToggle;

	public Toggle storageToggle;

	public Toggle logisticsToggle;

	public BuildingStockpileUI stockpileUI;

	public BuildingLogisticsUI logisticsUI;

	public BuildingDockUI dockUI;

	private bool isVisible;

	private Stockpile stockpile;

	private Building building;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		storageToggle.onValueChanged.AddListener(stockpileUI.ToggleStorage);
		logisticsToggle.onValueChanged.AddListener(logisticsUI.ToggleLogistics);
		ordersToggle.onValueChanged.AddListener(dockUI.ToggleOrders);
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(gameObject, v);
		isVisible = v;
		bool active = TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_tradeagreements") && building != null && building.GetComponent<Dock>() != null;
		Util.SetActive(ordersToggle.gameObject, active);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (stockpile = b.GetComponent<Stockpile>()) == null)
		{
			SetVisibility(v: false);
			return;
		}
		building = b;
		storageToggle.SetIsOnWithoutNotify(value: true);
		SetVisibility(v: true);
	}
}
