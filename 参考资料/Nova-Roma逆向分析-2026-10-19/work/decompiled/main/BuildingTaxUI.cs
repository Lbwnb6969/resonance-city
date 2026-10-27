using System;
using System.Collections.Generic;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingTaxUI : MonoBehaviour
{
	[Serializable]
	public class TaxInfo
	{
		public string uniqueName;

		public Sprite icon;

		internal int count;

		internal float yield;
	}

	public Button increaseBtn;

	public Button decreaseBtn;

	public TextMeshProUGUI taxRateTMP;

	public TextMeshProUGUI governorBonusTMP;

	public Image happinessIcon;

	private Building building;

	private TaxOffice taxOffice;

	private int prevTaxRate = -1;

	private ArrayExt<Building> taxOffices;

	private List<ResourceTooltipUI> taxNotes = new List<ResourceTooltipUI>();

	private List<Home> homes = new List<Home>();

	public Transform infoEntryContainer;

	public TaxUIInfoEntry infoPrefab;

	public TaxInfo[] homeTypeTaxInfo;

	private void Awake()
	{
		increaseBtn.onClick.AddListener(() =>
		{
			AdjustTaxRate(0.5f);
		});
		decreaseBtn.onClick.AddListener(() =>
		{
			AdjustTaxRate(-0.5f);
		});
	}

	public void SetVisibility(bool isVisible)
	{
		gameObject.SetActive(isVisible);
	}

	private void UpdateTaxDisplay()
	{
		homes.Clear();
		Vector3 pos = building.Center();
		float radius = taxOffice.Radius;
		_ = World.inst.GridWidth;
		World.inst.ForEachTileTouchingRadius(pos, radius, (int x, int z, Cell cell) =>
		{
			if ((bool)cell.StructureFindByCategory(World.houseCategoryHash) && TaxOfficeManager.InsideRadius(pos, radius, cell.Center2D))
			{
				ArrayExtRef<TaxOffice> officesForCell = TaxOfficeManager.inst.GetOfficesForCell(x, z);
				TaxOffice taxOffice = officesForCell.data[0];
				for (int i = 0; i < officesForCell.Count; i++)
				{
					if (officesForCell.data[i].Rate > taxOffice.Rate)
					{
						taxOffice = officesForCell.data[i];
					}
				}
				if (taxOffice == this.taxOffice)
				{
					for (int j = 0; j < cell.OccupyingStructure.Count; j++)
					{
						Home component2 = cell.OccupyingStructure[j].GetComponent<Home>();
						if (component2 != null && !homes.Contains(component2))
						{
							homes.Add(component2);
						}
					}
				}
			}
		});
		for (int num = 0; num < homeTypeTaxInfo.Length; num++)
		{
			homeTypeTaxInfo[num].count = 0;
			homeTypeTaxInfo[num].yield = 0f;
		}
		for (int num2 = 0; num2 < homes.Count; num2++)
		{
			string uniqueName = homes[num2].b.UniqueName;
			for (int num3 = 0; num3 < homeTypeTaxInfo.Length; num3++)
			{
				if (homeTypeTaxInfo[num3].uniqueName == uniqueName && homes[num2].GetEstimatedTaxYield() > 0f)
				{
					homeTypeTaxInfo[num3].count++;
					homeTypeTaxInfo[num3].yield += homes[num2].GetEstimatedTaxYield();
				}
			}
		}
		Governor governor = Player.inst.governors[building.LandMass()];
		Governor.TraitInstance traitInstance = null;
		if (governor != null)
		{
			traitInstance = governor.GetTrait(Traits.TaxRevenues);
			if (traitInstance != null)
			{
				string text = LocalizationManager.GetTranslation("advisorui_governortitle") + " ";
				Traits.Trait def = Traits.inst.GetDef(traitInstance.id);
				text += def.GetDesc(traitInstance);
				governorBonusTMP.text = text;
			}
		}
		if (traitInstance == null)
		{
			governorBonusTMP.text = "";
		}
		for (int num4 = 0; num4 < homeTypeTaxInfo.Length; num4++)
		{
			if (infoEntryContainer.childCount < homeTypeTaxInfo.Length)
			{
				TaxUIInfoEntry taxUIInfoEntry = UnityEngine.Object.Instantiate(infoPrefab);
				taxUIInfoEntry.transform.SetParent(infoEntryContainer);
				taxUIInfoEntry.transform.localScale = new Vector3(1f, 1f, 1f);
			}
			TaxUIInfoEntry component = infoEntryContainer.transform.GetChild(num4).GetComponent<TaxUIInfoEntry>();
			component.image.sprite = homeTypeTaxInfo[num4].icon;
			component.count.SetText("{0}", homeTypeTaxInfo[num4].count);
			component.yield.SetText("{0}", Mathf.RoundToInt(homeTypeTaxInfo[num4].yield));
			component.yield.color = ((homeTypeTaxInfo[num4].count > 0) ? Color.white : Color.grey);
			Building prefabByUniqueName = BuildUI.inst.GetPrefabByUniqueName(homeTypeTaxInfo[num4].uniqueName);
			float num5 = SeasonManager.inst.TimeInYear() / prefabByUniqueName.GetComponent<Home>().taxTimer.Duration;
			float num6 = 1f;
			if (traitInstance != null)
			{
				num6 = 1f + (traitInstance.negative ? (0f - traitInstance.magnitude) : traitInstance.magnitude);
			}
			float num7 = prefabByUniqueName.GetComponent<Home>().taxYield * num5 * taxOffice.Rate * num6;
			component.individualYield.text = $"x {num7:0.#}";
			if (homeTypeTaxInfo[num4].count > 0)
			{
				if (traitInstance != null)
				{
					component.individualYield.color = (traitInstance.negative ? Color.orangeRed : Color.limeGreen);
				}
				else
				{
					component.individualYield.color = Color.white;
				}
			}
			else
			{
				component.individualYield.color = Color.grey;
			}
		}
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || b.uniqueNameHash != World.taxOfficeHash)
		{
			SetVisibility(isVisible: false);
			return;
		}
		building = b;
		taxOffice = b.GetComponent<TaxOffice>();
		taxOffices = Player.inst.GetBuildingListForLandMass(b.LandMass(), World.taxOfficeHash);
		for (int i = 0; i < taxOffices.Count; i++)
		{
			if (taxNotes.Count <= i)
			{
				ResourceTooltipUI component = UnityEngine.Object.Instantiate(World.inst.resourceTooltipPrefab, World.inst.resourceTooltipContainer.transform).GetComponent<ResourceTooltipUI>();
				taxNotes.Add(component);
			}
			taxNotes[i].targetPosition = taxOffices.data[i].GetCell().Center3D;
			taxNotes[i].targetOffset = new Vector3(0f, 1f, 0f);
			taxNotes[i].gameObject.SetActive(value: true);
		}
		for (int j = taxOffices.Count; j < taxNotes.Count; j++)
		{
			taxNotes[j].gameObject.SetActive(value: false);
		}
		RefreshVisuals();
		SetVisibility(isVisible: true);
	}

	public void OnDeselected()
	{
		taxOffice = null;
		taxOffices = null;
		for (int i = 0; i < taxNotes.Count; i++)
		{
			taxNotes[i].gameObject.SetActive(value: false);
		}
	}

	public void RefreshVisuals()
	{
		float num = taxOffice.Rate * 10f * 2f;
		string text = ((LocalizationManager.CurrentLanguage == "Turkish") ? "%{0}" : "{0}%");
		Util.TrySetText(taxRateTMP, text, (int)num, ref prevTaxRate);
		for (int i = 0; i < taxOffices.Count; i++)
		{
			float num2 = taxOffices.data[i].GetComponent<TaxOffice>().Rate * 10f * 2f;
			taxNotes[i].SetText(string.Format(text, num2));
		}
		Sprite veryHappy = HappinessUI.inst.veryHappy;
		if (Mathf.Abs(taxOffice.Rate - 0f) < 0.01f)
		{
			veryHappy = HappinessUI.inst.veryHappy;
		}
		else if (Mathf.Abs(taxOffice.Rate - 0.5f) < 0.01f)
		{
			veryHappy = HappinessUI.inst.veryHappy;
		}
		else if (Mathf.Abs(taxOffice.Rate - 1f) < 0.01f)
		{
			veryHappy = HappinessUI.inst.happy;
		}
		else if (Mathf.Abs(taxOffice.Rate - 1.5f) < 0.01f)
		{
			veryHappy = HappinessUI.inst.neutral;
		}
		else if (Mathf.Abs(taxOffice.Rate - 2f) < 0.01f)
		{
			veryHappy = HappinessUI.inst.neutral;
		}
		else
		{
			veryHappy = ((!(Mathf.Abs(taxOffice.Rate - 2.5f) < 0.01f)) ? HappinessUI.inst.veryUnhappy : HappinessUI.inst.unhappy);
		}
		happinessIcon.sprite = veryHappy;
		UpdateTaxDisplay();
	}

	private void Update()
	{
		if (!(taxOffice == null))
		{
			RefreshVisuals();
		}
	}

	public void AdjustTaxRate(float rate)
	{
		taxOffice.Rate += rate;
		if (taxOffice.Rate < 0f)
		{
			taxOffice.Rate = 0f;
		}
		if (taxOffice.Rate > 3f)
		{
			taxOffice.Rate = 3f;
		}
		RuntimeManager.PlayOneShot((rate > 0f) ? "event:/SFX ASITP/UI/ui_taxRate_increase" : "event:/SFX ASITP/UI/ui_taxRate_decrease");
		TaxOfficeManager.inst.DrawOverlay();
		TerrainGen.inst.UpdateOverlayTextures();
	}
}
