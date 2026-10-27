using UnityEngine;

public class DLCHilderBuildItem : MonoBehaviour
{
	private bool firstInit = true;

	private void Update()
	{
		if (!firstInit)
		{
			return;
		}
		firstInit = false;
		BuildingCostUpdater componentInParent = GetComponentInParent<BuildingCostUpdater>();
		bool active = Player.inst.IsDecorationsPack();
		gameObject.SetActive(value: false);
		if (!(componentInParent.prefab != null))
		{
			return;
		}
		string uniqueName = componentInParent.prefab.UniqueName;
		for (int i = 0; i < BuildUI.parksAndStatues.Length; i++)
		{
			if (uniqueName == BuildUI.parksAndStatues[i].name)
			{
				gameObject.SetActive(active);
				break;
			}
		}
	}
}
