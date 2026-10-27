using System.Collections.Generic;
using Assets.Code;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class AINegotiationUI : MonoBehaviour
{
	private List<Slider> sliders = new List<Slider>();

	private List<TMP_Text> texts = new List<TMP_Text>();

	public GameObject entryPrefab;

	public GameObject container;

	private float prevSoundPlay;

	private const float MAX_GOLD_SOUND_DELAY = 0.3f;

	public void Init()
	{
		sliders.Add(entryPrefab.GetComponentInChildren<Slider>());
		texts.Add(entryPrefab.GetComponentInChildren<TMP_Text>());
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int i = 0;
		for (int count = resourceDefs.Count; i < count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			if (resourceDef.ID != 4)
			{
				GameObject gameObject = Object.Instantiate(entryPrefab);
				sliders.Add(gameObject.GetComponentInChildren<Slider>());
				texts.Add(gameObject.GetComponentInChildren<TMP_Text>());
				gameObject.transform.GetChild(0).GetChild(0).GetComponent<Image>()
					.sprite = resourceDef.texture;
				gameObject.transform.SetParent(container.transform);
				gameObject.transform.localScale = new Vector3(1f, 1f, 1f);
			}
		}
		for (int j = 0; j < sliders.Count; j++)
		{
			SliderIndexCapture(j);
		}
	}

	public void SliderIndexCapture(int index)
	{
		sliders[index].onValueChanged.AddListener((float value) =>
		{
			texts[index].text = value.ToString();
			if (Time.unscaledTime - prevSoundPlay >= 0.3f)
			{
				SfxSystem.inst.PlayFromBank("BuildingSelectThroneRoom", Cam.inst.CamPos);
			}
			prevSoundPlay = Time.unscaledTime;
		});
	}

	public void SetVisible(bool visible)
	{
		gameObject.SetActive(visible);
	}

	public void PopulateUI(LandmassOwner lmo, int teamId)
	{
		ResourceAmount payCosts = lmo.GetPayCosts(teamId);
		int num = 0;
		for (int i = 0; i < payCosts.resources.Count; i++)
		{
			if (payCosts.resources[i].resourceID != 4)
			{
				sliders[num].value = payCosts.resources[i].Amount;
				texts[num].text = payCosts.resources[i].Amount.ToString();
				num++;
			}
		}
	}

	public ResourceAmount GatherValues()
	{
		int num = 0;
		ResourceAmount resourceAmount = new ResourceAmount();
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int i = 0;
		for (int count = resourceDefs.Count; i < count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			if (resourceDef.ID != 4)
			{
				int val = (int)sliders[num].value;
				resourceAmount.Set(resourceDef.ID, val);
				num++;
			}
		}
		return resourceAmount;
	}

	public int CalculateFavor()
	{
		int num = 0;
		int num2 = 0;
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int i = 0;
		for (int count = resourceDefs.Count; i < count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			if (resourceDef.ID != 4)
			{
				num += (Player.inst.defaultPayCost.Get(resourceDef.ID) - (int)sliders[num2].value) * 10;
				num2++;
			}
		}
		return num;
	}
}
