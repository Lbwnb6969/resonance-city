using I2.Loc;
using TMPro;
using UnityEngine;

public class RiverTapCapacityUI : MonoBehaviour
{
	[SerializeField]
	private TextMeshProUGUI drawTMP;

	[SerializeField]
	private TextMeshProUGUI utilizationTMP;

	private RiverTap tap;

	private Color utilizationNormalColor;

	private float shownUsed = -1f;

	private float shownMax = -1f;

	private void Awake()
	{
		utilizationNormalColor = utilizationTMP.color;
	}

	public void OnBuildingSelected(ISelectableBuilding building)
	{
		tap = building as RiverTap;
		shownUsed = (shownMax = -1f);
		gameObject.SetActive(tap != null);
		if (tap != null)
		{
			Refresh();
		}
	}

	public void OnDeselected()
	{
		tap = null;
		gameObject.SetActive(value: false);
	}

	private void Update()
	{
		if (tap == null)
		{
			gameObject.SetActive(value: false);
		}
		else
		{
			Refresh();
		}
	}

	private void Refresh()
	{
		float num = tap.SourceCapacity();
		float num2 = Mathf.Min(tap.inputFromEnvironment, num);
		if (num2 != shownUsed || num != shownMax)
		{
			shownUsed = num2;
			shownMax = num;
			float num3 = ((num > 0f) ? Mathf.Round(num2 / num * 100f) : 0f);
			drawTMP.text = string.Format(LocalizationManager.GetTranslation("workerui_rivertapcapacity_draw"), num2, num);
			utilizationTMP.text = string.Format(LocalizationManager.GetTranslation("aqueductwaterchart_ui_utilization"), (int)num3);
			utilizationTMP.color = AqueductWaterChartUI.UtilizationColor(num3, utilizationNormalColor);
		}
	}
}
