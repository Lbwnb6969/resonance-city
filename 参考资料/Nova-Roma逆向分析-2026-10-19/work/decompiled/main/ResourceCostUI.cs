using System.Collections.Generic;
using Assets.Code;
using TMPro;
using UnityEngine;

public class ResourceCostUI : MonoBehaviour
{
	public List<TMP_Text> texts = new List<TMP_Text>();

	public void UpdateUI(ResourceAmount resourceAmount)
	{
		int num = 0;
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			if (resourceDef.ID != 4)
			{
				texts[num].text = resourceAmount.Get(resourceDef.ID).ToString();
				num++;
			}
		}
	}
}
