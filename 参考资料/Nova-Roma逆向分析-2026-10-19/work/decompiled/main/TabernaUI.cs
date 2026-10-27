using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class TabernaUI : MonoBehaviour
{
	[SerializeField]
	private TMP_Dropdown dropdown;

	private List<TMP_Dropdown.OptionData> options;

	private void Awake()
	{
		options = new List<TMP_Dropdown.OptionData>(Taberna.ValidResourceTypes.Length);
		ResetDropdownOptions();
		dropdown.onValueChanged.AddListener(OnResourceChanged);
	}

	private void OnResourceChanged(int idx)
	{
		GameUI.inst.GetBuildingSelected().GetComponent<Taberna>().OnResourceChanged(Taberna.ValidResourceTypes[idx]);
	}

	public void OnUpdateSelected(Component b)
	{
		Taberna component = b.GetComponent<Taberna>();
		if (component == null)
		{
			gameObject.SetActive(value: false);
			return;
		}
		gameObject.SetActive(value: true);
		int resourceID = component.resourceID;
		for (int i = 0; i < Taberna.ValidResourceTypes.Length; i++)
		{
			if (resourceID == Taberna.ValidResourceTypes[i])
			{
				dropdown.SetValueWithoutNotify(i);
			}
		}
	}

	public void ResetDropdownOptions()
	{
		dropdown.ClearOptions();
		options.Clear();
		for (int i = 0; i < Taberna.ValidResourceTypes.Length; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[Taberna.ValidResourceTypes[i]];
			TMP_Dropdown.OptionData optionData = new TMP_Dropdown.OptionData();
			optionData.image = resourceDef.texture;
			optionData.text = char.ToUpper(resourceDef.name[0]) + resourceDef.name.Substring(1);
			options.Add(optionData);
		}
		dropdown.AddOptions(options);
	}

	private void OnDestroy()
	{
		dropdown.onValueChanged.RemoveListener(OnResourceChanged);
	}
}
