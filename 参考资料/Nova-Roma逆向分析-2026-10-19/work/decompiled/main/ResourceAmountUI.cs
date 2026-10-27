using Assets.Code;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ResourceAmountUI : MonoBehaviour
{
	public Transform resourceContainer;

	public Transform resourcePrefab;

	public bool skipGold = true;

	private Color invalidColor = new Color(1f, 0f, 0f, 0.6f);

	private Color validColor = new Color(0f, 0f, 0f, 0.6f);

	public bool hideZeroes;

	private void Start()
	{
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			if (resourceDef.ID != 4 || !skipGold)
			{
				resourceContainer.GetChild(i).GetChild(0).GetComponent<Image>()
					.sprite = resourceDef.texture;
			}
		}
	}

	public ResourceAmount GetResourceAmount()
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			if (resourceDef.ID != 4 || !skipGold)
			{
				int num = int.Parse(resourceContainer.GetChild(i).GetComponentInChildren<TMP_InputField>().text);
				if (num > 0)
				{
					resourceAmount.Set(resourceDef.ID, num);
				}
			}
		}
		return resourceAmount;
	}

	public void SetResourceAmount(ResourceAmount amt)
	{
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			if (resourceDef.ID == 4 && skipGold)
			{
				resourceContainer.GetChild(i).gameObject.SetActive(value: false);
				continue;
			}
			if (amt.Get(resourceDef.ID) <= 0 && hideZeroes)
			{
				resourceContainer.GetChild(i).gameObject.SetActive(value: false);
			}
			else
			{
				resourceContainer.GetChild(i).gameObject.SetActive(value: true);
			}
			resourceContainer.GetChild(i).GetComponentInChildren<TMP_InputField>().text = amt.Get(resourceDef.ID).ToString();
		}
	}

	public void HideZeros()
	{
		if (!hideZeroes)
		{
			return;
		}
		ResourceAmount resourceAmount = GetResourceAmount();
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			if (resourceDef.ID == 4 && skipGold)
			{
				resourceContainer.GetChild(i).gameObject.SetActive(value: false);
			}
			else if (resourceAmount.Get(resourceDef.ID) <= 0)
			{
				resourceContainer.GetChild(i).gameObject.SetActive(value: false);
			}
		}
	}

	public void ShowAll()
	{
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			if (FreeResourceSystem.inst.resourceDefs[i].ID == 4 && skipGold)
			{
				resourceContainer.GetChild(i).gameObject.SetActive(value: false);
			}
			else
			{
				resourceContainer.GetChild(i).gameObject.SetActive(value: true);
			}
		}
	}
}
