using System.Collections.Generic;
using Assets.Code;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ResourceEntryUI : MonoBehaviour
{
	public TMP_InputField valueTxt;

	public Button deleteButton;

	public Dropdown resourceDrop;

	public TMP_Dropdown loadUnloadDrop;

	private void Start()
	{
		valueTxt.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
		});
		valueTxt.onEndEdit.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = true;
		});
	}

	private Sprite GetSelectedResourceSprite()
	{
		return resourceDrop.options[resourceDrop.value].image;
	}

	public void RefreshDropdown(Transform firstEntry)
	{
		List<Dropdown.OptionData> list = new List<Dropdown.OptionData>();
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			Dropdown.OptionData optionData = new Dropdown.OptionData();
			optionData.text = "";
			optionData.image = resourceDef.texture;
			list.Add(optionData);
		}
		resourceDrop.ClearOptions();
		resourceDrop.AddOptions(list);
	}

	private int GetTypeFromResourceDropdown()
	{
		Sprite image = resourceDrop.options[resourceDrop.value].image;
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			if (image == resourceDef.texture)
			{
				return resourceDef.ID;
			}
		}
		return -1;
	}

	public void AddAmountToLoadUnload(ref ResourceAmount toLoad, ref ResourceAmount toUnload)
	{
		int.TryParse(valueTxt.text, out var result);
		int typeFromResourceDropdown = GetTypeFromResourceDropdown();
		if (loadUnloadDrop.value == 0)
		{
			toLoad.Add(typeFromResourceDropdown, result);
		}
		else
		{
			toUnload.Add(typeFromResourceDropdown, result);
		}
	}
}
