using I2.Loc;
using LeTai.Asset.TranslucentImage;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class WaterConsumptionUI : MonoBehaviour
{
	private Building building;

	private Home home;

	private WaterConsumer WaterConsumer;

	[SerializeField]
	private RectTransform rectT;

	[SerializeField]
	private TextMeshProUGUI descriptionTMP;

	[SerializeField]
	private RawImage checkmarkRI;

	[SerializeField]
	private Image abortRI;

	[SerializeField]
	private TooltipHook waterTooltip;

	[SerializeField]
	private TranslucentImage backgroundTI;

	[SerializeField]
	private RectTransform healthContainer;

	[SerializeField]
	private RectTransform defaultContainer;

	public Image waterAccessImg;

	public Sprite waterIcon;

	public Sprite wellIcon;

	public Sprite fountainIcon;

	public Image circleBG;

	public Sprite successBG;

	public Sprite failBG;

	public void SetVisibility(bool isVisible)
	{
		Util.SetActive(gameObject, isVisible);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null)
		{
			SetVisibility(isVisible: false);
			return;
		}
		home = b.GetComponent<Home>();
		WaterConsumer = b.GetComponent<WaterConsumer>();
		bool flag = WaterConsumer != null;
		if (b == null || !flag)
		{
			SetVisibility(isVisible: false);
			return;
		}
		building = b;
		if (home != null)
		{
			if (rectT.parent != healthContainer)
			{
				rectT.SetParent(healthContainer, worldPositionStays: false);
				rectT.SetSiblingIndex(2);
			}
			Util.SetEnabled(backgroundTI, active: false);
		}
		else
		{
			if (rectT.parent != defaultContainer)
			{
				rectT.SetParent(defaultContainer, worldPositionStays: false);
				rectT.SetSiblingIndex(2);
			}
			Util.SetEnabled(backgroundTI, active: true);
		}
		SetVisibility(isVisible: true);
		RefreshVisuals();
	}

	private void Update()
	{
		if (!(WaterConsumer == null))
		{
			RefreshVisuals();
		}
	}

	private void RefreshVisuals()
	{
		descriptionTMP.fontSizeMin = 8f;
		descriptionTMP.fontSizeMax = 10f;
		bool flag = false;
		bool flag2 = WaterConsumer.availableWaterPercentage > 0f;
		bool flag3 = home != null && home.wellAccess > 0f;
		flag = flag2 | flag3;
		if (flag2)
		{
			waterTooltip.tooltipTerm = "workerui_happinesstile_positivewell";
			waterAccessImg.sprite = waterIcon;
			descriptionTMP.fontSizeMax = 10f;
			descriptionTMP.text = string.Format(ScriptLocalization.workerui_waterconsumptionui_description, Mathf.RoundToInt(WaterConsumer.availableWaterPercentage * WaterConsumer.consumptionRate), WaterConsumer.consumptionRate);
			descriptionTMP.color = ((WaterConsumer.availableWaterPercentage >= 0.99f) ? Color.white : Color.yellow);
		}
		else if (flag3)
		{
			bool flag4 = home.TileHappinessModifiers.ContainsKey(228);
			if (flag4)
			{
				waterAccessImg.sprite = fountainIcon;
			}
			else
			{
				waterTooltip.tooltipTerm = "workerui_happinesstile_positivewell";
				waterAccessImg.sprite = wellIcon;
			}
			if (home.wantAqueduct)
			{
				if (flag4)
				{
					descriptionTMP.text = LocalizationManager.GetTranslation("workerui_waterconsumptionui_wantwatertowerfountain");
				}
				else
				{
					descriptionTMP.text = ScriptLocalization.workerui_waterconsumptionui_wantwatertower;
				}
			}
			else if (flag4)
			{
				descriptionTMP.text = LocalizationManager.GetTranslation("workerui_waterconsumptionui_hasfountain");
			}
			else
			{
				descriptionTMP.text = ScriptLocalization.workerui_waterconsumptionui_haswell;
			}
		}
		if (!flag)
		{
			waterAccessImg.sprite = waterIcon;
			waterTooltip.tooltipTerm = "negativewell";
			if (home != null)
			{
				descriptionTMP.text = ScriptLocalization.workerui_waterconsumptionui_noaccess;
			}
			else
			{
				descriptionTMP.fontSizeMax = 10f;
				descriptionTMP.text = string.Format(ScriptLocalization.workerui_waterconsumptionui_description, 0, WaterConsumer.consumptionRate);
			}
		}
		circleBG.sprite = (flag ? successBG : failBG);
		Util.SetEnabled(abortRI, !flag);
		Util.SetEnabled(checkmarkRI, flag);
	}

	public void OnDeselected()
	{
		building = null;
		WaterConsumer = null;
	}
}
