using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class BuildTabConsole : BuildTab
{
	public Slider slider;

	public override BuildingCostUpdater AddButton(Building prefab, Building preReq, Vector3 scaleMod, OnButtonClicked onClick)
	{
		BuildingCostUpdater buildingCostUpdater = Object.Instantiate(buttonPrefab);
		buildingCostUpdater.buildingObject = prefab.gameObject;
		buildingCostUpdater.titleText.GetComponent<Localize>().SetTerm(prefab.GetFriendlyNameTerm);
		buildingCostUpdater.prefab = prefab;
		buildingCostUpdater.name = prefab.UniqueName;
		buildingCostUpdater.PreReq = preReq;
		Transform original = ((!prefab.DisplayModel) ? prefab.transform.Find("Offset").GetChild(0) : prefab.DisplayModel.transform);
		Transform transform = Object.Instantiate(original);
		transform.transform.localScale = scaleMod * 1.25f;
		int layer = LayerMask.NameToLayer("UI");
		foreach (Transform item in Util.ComponentsInNodeAndAllDescendants<Transform>(transform.gameObject))
		{
			item.gameObject.layer = layer;
		}
		transform.SetParent(buildingCostUpdater.transform.Find("modelDisplay"), worldPositionStays: false);
		buildingCostUpdater.transform.SetParent(ButtonPanel, worldPositionStays: false);
		buildingCostUpdater.GetComponent<ConsoleUIIndexSlider>().slider = slider;
		buttons.Add(buildingCostUpdater);
		return buildingCostUpdater;
	}
}
