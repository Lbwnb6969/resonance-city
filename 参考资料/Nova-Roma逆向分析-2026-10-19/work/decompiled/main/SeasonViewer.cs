using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SeasonViewer : MonoBehaviour
{
	public static SeasonViewer inst;

	private const int TextureWidthScale = 98;

	public RectTransform seasonContainer;

	public Slider seasonSlider;

	private int itemPoolCount;

	private List<RectTransform> itemPool = new List<RectTransform>();

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	private bool isVisible;

	public Localize seasonTitle;

	public Localize dayNightTitle;

	public TextMeshProUGUI yearTitle;

	public Image dayNightRadial;

	private bool firstInit = true;

	private bool refresh = true;

	private int lastSeasonID = -1;

	private int lastYear = -1;

	private bool wasDay = true;

	private SeasonManager.WeatherType lastWeather;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
		SetVisibility(v: true);
		dayNightTitle.Term = "timeui_day";
	}

	public void Reset()
	{
		refresh = true;
	}

	private void Update()
	{
		if (!SeasonManager.inst)
		{
			return;
		}
		if (IsValidToSetVisibility())
		{
			bool visibility = false;
			for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
			{
				if (Player.inst.GetBuildingListForLandMass(Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i]).Count > 0)
				{
					visibility = true;
				}
			}
			SetVisibility(visibility);
		}
		List<SeasonDefinition> seasonDefinitions = SeasonManager.inst.seasonDefinitions;
		if (seasonDefinitions.Count > itemPoolCount)
		{
			for (int j = itemPoolCount; j < seasonDefinitions.Count; j++)
			{
				AddItemToPool();
			}
		}
		float num = SeasonManager.inst.TimeInYear();
		seasonSlider.value = SeasonManager.inst.GetYearProgress();
		if (firstInit)
		{
			float num2 = 0f;
			for (int k = 0; k < seasonDefinitions.Count; k++)
			{
				RectTransform rectTransform = itemPool[k];
				rectTransform.name = seasonDefinitions[k].name;
				rectTransform.GetComponent<TooltipHook>().toolTipText = LocalizationManager.GetTranslation(seasonDefinitions[k].name);
				RectTransform component = rectTransform.GetChild(0).GetComponent<RectTransform>();
				rectTransform.anchoredPosition = new Vector2(num2, 0f);
				float num3 = seasonContainer.rect.width * (seasonDefinitions[k].duration / num);
				rectTransform.sizeDelta = new Vector2(num3, seasonContainer.rect.height);
				num2 += num3;
				rectTransform.gameObject.SetActive(value: true);
				RawImage component2 = component.GetComponent<RawImage>();
				component2.enabled = false;
				component2.texture = seasonDefinitions[k].bannerTexture;
				component.position = seasonContainer.position;
				component.sizeDelta = seasonContainer.rect.size;
			}
			firstInit = false;
		}
		if (itemPoolCount > seasonDefinitions.Count)
		{
			for (int num4 = itemPoolCount - 1; num4 >= seasonDefinitions.Count; num4--)
			{
				itemPool[num4].gameObject.SetActive(value: false);
			}
		}
		int id = SeasonManager.inst.CurrentSeason.id;
		if (lastSeasonID != id || lastWeather != SeasonManager.inst.CurrWeather || refresh)
		{
			string term = "";
			switch (id)
			{
			case 3:
				term = "Spring";
				break;
			case 0:
				term = "Summer";
				break;
			case 1:
				term = "Autumn";
				break;
			case 2:
				term = "Winter";
				break;
			}
			if (SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.HeavyRain)
			{
				term = "weather_flooding";
			}
			else if (SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.Drought)
			{
				term = "weather_drought";
			}
			seasonTitle.Term = term;
		}
		lastWeather = SeasonManager.inst.CurrWeather;
		lastSeasonID = id;
		float _24HourTime = DayNightManager.inst.GameParameters._24HourTime;
		dayNightRadial.transform.rotation = Quaternion.Euler(0f, 0f, _24HourTime / 24f * 360f);
		if (wasDay != DayNightManager.inst.GameParameters.isDay || refresh)
		{
			if (DayNightManager.inst.GameParameters.isDay)
			{
				dayNightTitle.Term = "timeui_day";
			}
			else
			{
				dayNightTitle.Term = "timeui_night";
			}
		}
		wasDay = DayNightManager.inst.GameParameters.isDay;
		if (lastYear != SeasonManager.inst.CurrentYear() || refresh)
		{
			yearTitle.SetText(ScriptLocalization.LogGameUIYear, SeasonManager.inst.CurrentYear());
		}
		lastYear = SeasonManager.inst.CurrentYear();
		refresh = false;
	}

	private bool IsValidToSetVisibility()
	{
		if (!(GameUI.inst.currCursorMode is DockRouteCursorMode) && !ConsoleBuildMenu.inst.Active && !MerchantUI.inst.IsVisible())
		{
			return !GameUI.inst.IsChariotRaceModeActive();
		}
		return false;
	}

	private void AddItemToPool()
	{
		GameObject gameObject = new GameObject();
		RectTransform rectTransform = gameObject.AddComponent<RectTransform>();
		gameObject.AddComponent<Image>();
		gameObject.AddComponent<Mask>();
		gameObject.AddComponent<TooltipHook>();
		rectTransform.SetParent(seasonContainer, worldPositionStays: false);
		rectTransform.sizeDelta = new Vector2(0f, 35f);
		Vector2 vector = (rectTransform.anchorMin = new Vector2(0f, 0.5f));
		Vector2 pivot = (rectTransform.anchorMax = vector);
		rectTransform.pivot = pivot;
		GameObject gameObject2 = new GameObject();
		RectTransform rectTransform2 = gameObject2.AddComponent<RectTransform>();
		rectTransform2.name = "Background";
		gameObject2.AddComponent<RawImage>();
		rectTransform2.SetParent(rectTransform, worldPositionStays: false);
		rectTransform2.pivot = new Vector2(0.5f, 0.5f);
		itemPool.Add(rectTransform);
		itemPoolCount++;
	}
}
