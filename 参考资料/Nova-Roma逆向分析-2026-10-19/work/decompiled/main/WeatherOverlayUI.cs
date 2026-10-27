using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class WeatherOverlayUI : MonoBehaviour
{
	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	public TextMeshProUGUI weatherLabel;

	public GameObject weatherNotifyContainer;

	public GameObject invasionContainerNotify;

	public Button nextInvader;

	public Button prevInvader;

	public static WeatherOverlayUI inst;

	public Image[] bars;

	private bool isVisible;

	public Color droughtColor;

	public Color rainColor;

	private bool showing;

	private bool showingBars;

	public float opacity = 0.33f;

	private void Awake()
	{
		inst = this;
		SetVisible(v: false);
	}

	private void Start()
	{
		nextInvader.onClick.AddListener(VikingNotification.inst.OnViewNextClicked);
		prevInvader.onClick.AddListener(VikingNotification.inst.OnViewPrevClicked);
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	private void SetVisible(bool v)
	{
		isVisible = v;
		Util.SetEnabled(canvas, isVisible);
		Util.SetEnabled(gRaycaster, isVisible);
	}

	public void Reset()
	{
		showing = false;
		showingBars = false;
		SetVisible(v: false);
		for (int i = 0; i < bars.Length; i++)
		{
			bars[i].color = new Color(1f, 1f, 1f, 0f);
		}
		Util.SetActive(weatherNotifyContainer, active: false);
		Util.SetActive(invasionContainerNotify, active: false);
	}

	public void RefreshVisuals()
	{
		showing = false;
		showingBars = false;
		Util.SetActive(weatherNotifyContainer, active: false);
		Util.SetActive(invasionContainerNotify, active: false);
		if (SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.Drought || SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.HeavyRain)
		{
			if (SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.Drought)
			{
				for (int i = 0; i < bars.Length; i++)
				{
					bars[i].color = new Color(droughtColor.r, droughtColor.g, droughtColor.b, 0f);
				}
				weatherLabel.text = LocalizationManager.GetTranslation("weather_drought");
			}
			else if (SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.HeavyRain)
			{
				for (int j = 0; j < bars.Length; j++)
				{
					bars[j].color = new Color(rainColor.r, rainColor.g, rainColor.b, 0f);
				}
				weatherLabel.text = LocalizationManager.GetTranslation("weather_flooding");
			}
			Util.SetActive(weatherNotifyContainer, active: true);
			SetVisible(v: true);
			showingBars = true;
			showing = true;
		}
		if (RaiderSystem.inst.IsRaidInProgress())
		{
			Util.SetActive(invasionContainerNotify, active: true);
			SetVisible(v: true);
			showing = true;
		}
	}

	public void Update()
	{
		if (RaiderSystem.inst.IsRaidInProgress() != (isVisible && invasionContainerNotify.activeSelf))
		{
			RefreshVisuals();
		}
		if (showingBars && showing)
		{
			for (int i = 0; i < bars.Length; i++)
			{
				float a = bars[i].color.a;
				if (a < opacity)
				{
					a += Time.unscaledDeltaTime;
					Color color = bars[i].color;
					color.a = Mathf.Clamp(a, 0f, opacity);
					bars[i].color = color;
				}
			}
			return;
		}
		for (int j = 0; j < bars.Length; j++)
		{
			float a2 = bars[j].color.a;
			if (a2 > 0f)
			{
				a2 -= Time.unscaledDeltaTime;
				Color color2 = bars[j].color;
				color2.a = Mathf.Clamp(a2, 0f, opacity);
				bars[j].color = color2;
				if (a2 <= 0f && !showing)
				{
					SetVisible(v: false);
				}
			}
		}
	}
}
