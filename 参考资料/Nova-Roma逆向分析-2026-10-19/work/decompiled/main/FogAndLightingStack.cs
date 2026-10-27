using System;
using Assets;
using Colorful;
using UnityEngine;
using UnityEngine.Serialization;
using UnityStandardAssets.ImageEffects;

[Serializable]
public class FogAndLightingStack : MonoBehaviour
{
	[Serializable]
	public class FogAndLighting
	{
		[HideInInspector]
		public bool forceSettings;

		[HideInInspector]
		public bool setSunLightRotation;

		public Vector3 sunLightRotation;

		[HideInInspector]
		public bool setDayWhiteBalance;

		public Gradient dayWhiteBalance = new Gradient();

		[HideInInspector]
		public bool setDaySkyboxTintColor;

		public Gradient daySkyboxTintColor = new Gradient();

		[HideInInspector]
		public bool setDayFogColor;

		public Gradient dayFogColor = new Gradient();

		[HideInInspector]
		public bool setDayLightColor;

		public Gradient dayLightColor = new Gradient();

		[HideInInspector]
		public bool setDayLightIntensity;

		public AnimationCurve dayLightIntensity = new AnimationCurve();

		[HideInInspector]
		public bool setDayLightShadowStrength;

		public AnimationCurve dayLightShadowStrength = new AnimationCurve();

		[HideInInspector]
		public bool setDayFillColor;

		public Gradient dayFillColor = new Gradient();

		[HideInInspector]
		public bool setDayFillIntensity;

		public AnimationCurve dayFillIntensity = new AnimationCurve();

		[HideInInspector]
		public bool setDayBackColor;

		public Gradient dayBackColor = new Gradient();

		[HideInInspector]
		public bool setDayBackIntensity;

		public AnimationCurve dayBackIntensity = new AnimationCurve();

		[HideInInspector]
		public bool setDayBloomIntensity;

		public AnimationCurve dayBloomIntensity = new AnimationCurve();

		[HideInInspector]
		public bool setNightWhiteBalance;

		public Gradient nightWhiteBalance = new Gradient();

		[HideInInspector]
		public bool setNightSkyboxTintColor;

		public Gradient nightSkyboxTintColor = new Gradient();

		[HideInInspector]
		public bool setNightFogColor;

		public Gradient nightFogColor = new Gradient();

		[HideInInspector]
		public bool setNightLightColor;

		public Gradient nightLightColor = new Gradient();

		[HideInInspector]
		public bool setNightLightIntensity;

		public AnimationCurve nightLightIntensity = new AnimationCurve();

		[HideInInspector]
		public bool setNightLightShadowStrength;

		public AnimationCurve nightLightShadowStrength = new AnimationCurve();

		[HideInInspector]
		public bool setNightFillColor;

		public Gradient nightFillColor = new Gradient();

		[HideInInspector]
		public bool setNightFillIntensity;

		public AnimationCurve nightFillIntensity = new AnimationCurve();

		[HideInInspector]
		public bool setNightBackColor;

		public Gradient nightBackColor = new Gradient();

		[HideInInspector]
		public bool setNightBackIntensity;

		public AnimationCurve nightBackIntensity = new AnimationCurve();

		[HideInInspector]
		public bool setNightBloomIntensity;

		public AnimationCurve nightBloomIntensity = new AnimationCurve();

		[HideInInspector]
		public bool setFogStartEnd;

		public MinMax fogStartEnd;

		private GradientColorKey[] defaultColorKeys;

		private GradientAlphaKey[] defaultaAlphaKeys;

		public FogAndLighting()
		{
			defaultColorKeys = new GradientColorKey[2];
			defaultColorKeys[0].color = Color.white;
			defaultColorKeys[0].time = 0f;
			defaultColorKeys[1].color = Color.white;
			defaultColorKeys[1].time = 1f;
			defaultaAlphaKeys = new GradientAlphaKey[2];
			defaultaAlphaKeys[0].alpha = 1f;
			defaultaAlphaKeys[0].time = 0f;
			defaultaAlphaKeys[1].alpha = 1f;
			defaultaAlphaKeys[1].time = 1f;
			Reset();
		}

		public void Reset()
		{
			setSunLightRotation = false;
			setDayWhiteBalance = false;
			setDaySkyboxTintColor = false;
			setDayFogColor = false;
			setDayLightColor = false;
			setDayLightIntensity = false;
			setDayLightShadowStrength = false;
			setDayFillColor = false;
			setDayFillIntensity = false;
			setDayBackColor = false;
			setDayBackIntensity = false;
			setDayBloomIntensity = false;
			setNightWhiteBalance = false;
			setNightSkyboxTintColor = false;
			setNightFogColor = false;
			setNightLightColor = false;
			setNightLightIntensity = false;
			setNightLightShadowStrength = false;
			setNightFillColor = false;
			setNightFillIntensity = false;
			setNightBackColor = false;
			setNightBackIntensity = false;
			setNightBloomIntensity = false;
			setFogStartEnd = false;
		}
	}

	[NonSerialized]
	public static FogAndLightingStack inst;

	public AnimationCurve fogToDistCurve;

	private float currFogEndDist;

	private Bloom bloom;

	private Light sunLight;

	private Light sunFillLight;

	private Light sunBackLight;

	private Light moonLight;

	private Light moonFillLight;

	private Light moonBackLight;

	private static readonly int MainLightDirId = Shader.PropertyToID("_MainLightDir");

	private Camera cam;

	private WhiteBalance whiteBalance;

	[FormerlySerializedAs("updateOnPause")]
	public bool editMode;

	public FogAndLighting BaseFogAndLightSettings = new FogAndLighting();

	private FogAndLighting Seasonal;

	private FogAndLighting Daily;

	private FogAndLighting Weather;

	private FogAndLighting Photo;

	private readonly FogAndLighting Default = new FogAndLighting();

	private bool updateImmediately;

	public float FogDistNewMap = 500f;

	public FogAndLighting Calculated { get; private set; } = new FogAndLighting();

	public void Awake()
	{
		inst = this;
	}

	public void OnEnable()
	{
		bloom = Camera.main.GetComponent<Bloom>();
		sunLight = GameObject.Find("Light Container/Sun Light").GetComponent<Light>();
		moonLight = GameObject.Find("Light Container/Sun Light/Moon Light").GetComponent<Light>();
		cam = Camera.main;
		whiteBalance = Camera.main.GetComponent<WhiteBalance>();
		Calculated = new FogAndLighting();
	}

	public void SetSeasonSettings(ref FogAndLighting seasonal)
	{
		Seasonal = seasonal;
	}

	public void SetDailySettings(ref FogAndLighting daily)
	{
		Daily = daily;
	}

	public void SetPhotoSettings(ref FogAndLighting photo)
	{
		Photo = photo;
	}

	public void SetWeatherSettings(ref FogAndLighting weather)
	{
		Weather = weather;
	}

	public void ClearSeasonSettings()
	{
		Seasonal.Reset();
	}

	public void ClearDailySettings()
	{
		Daily.Reset();
	}

	public void ClearWeatherSettings()
	{
		Weather = null;
	}

	public void UpdateNewSettingsImmediately()
	{
		updateImmediately = true;
	}

	public void Update()
	{
		CalculateStackedSettings();
		if (!Settings.inst.Fog)
		{
			Cam.inst.globalFog.startDistance = 250f;
		}
		else
		{
			float t = 0f;
			if (GameState.inst.CurrMode is MainMenuMode mainMenuMode && mainMenuMode.GetState() == MainMenuMode.State.NewMap)
			{
				t = FogDistNewMap;
			}
			Cam.inst.globalFog.startDistance = Mathf.Lerp(Calculated.fogStartEnd.Min, 100f, t);
		}
		float speed = Time.deltaTime * 0.5f;
		if (updateImmediately)
		{
			updateImmediately = false;
			speed = 1f;
		}
		LerpFogTo(Calculated.fogStartEnd.Min, Calculated.fogStartEnd.Max, speed);
		sunLight.transform.rotation = Quaternion.LookRotation(Calculated.sunLightRotation);
		if (PhotoMode.IsActive() && PhotoMode.inst.IsCustomSunEnabled())
		{
			ApplyDayNightParameters(PhotoMode.inst.PhotoDayNightParameters, speed);
		}
		else
		{
			ApplyDayNightParameters(DayNightManager.inst.GameParameters, speed);
		}
	}

	private void ApplyDayNightParameters(DayNightManager.DayNightParameters param, float speed)
	{
		Shader.SetGlobalVector(MainLightDirId, -(param.isDay ? sunLight : moonLight).transform.forward);
		if (param.isDay)
		{
			LerpBloomTo(Calculated.dayBloomIntensity.Evaluate(param.lightProgress), speed);
			whiteBalance.White = Color.Lerp(whiteBalance.White, Calculated.dayWhiteBalance.Evaluate(param.lightProgress), speed);
			cam.backgroundColor = Color.Lerp(RenderSettings.fogColor, Calculated.dayFogColor.Evaluate(param.dayProgress), speed);
			RenderSettings.skybox.SetColor("_Tint", Color.Lerp(RenderSettings.skybox.GetColor("_Tint"), Calculated.daySkyboxTintColor.Evaluate(param.lightProgress), speed));
			Cam.inst.cam.backgroundColor = RenderSettings.skybox.GetColor("_Tint");
			sunLight.color = Color.Lerp(sunLight.color, Calculated.dayLightColor.Evaluate(param.lightProgress), speed);
			sunLight.intensity = Mathf.Lerp(sunLight.intensity, Calculated.dayLightIntensity.Evaluate(param.lightProgress), speed);
			sunLight.shadowStrength = Mathff.Clamp01(Mathf.Lerp(sunLight.shadowStrength, Calculated.dayLightShadowStrength.Evaluate(param.lightProgress), speed));
			moonLight.intensity = Mathf.Lerp(moonLight.intensity, 0f, speed);
		}
		else
		{
			LerpBloomTo(Calculated.nightBloomIntensity.Evaluate(param.darkProgress), speed);
			whiteBalance.White = Color.Lerp(whiteBalance.White, Calculated.nightWhiteBalance.Evaluate(param.darkProgress), speed);
			cam.backgroundColor = Color.Lerp(RenderSettings.fogColor, Calculated.nightFogColor.Evaluate(param.darkProgress), speed);
			RenderSettings.skybox.SetColor("_Tint", Color.Lerp(RenderSettings.skybox.GetColor("_Tint"), Calculated.nightSkyboxTintColor.Evaluate(param.darkProgress), speed));
			Cam.inst.cam.backgroundColor = RenderSettings.skybox.GetColor("_Tint");
			moonLight.color = Color.Lerp(moonLight.color, Calculated.nightLightColor.Evaluate(param.darkProgress), speed);
			moonLight.intensity = Mathf.Lerp(moonLight.intensity, Calculated.nightLightIntensity.Evaluate(param.darkProgress), speed);
			moonLight.shadowStrength = Mathff.Clamp01(Mathf.Lerp(moonLight.shadowStrength, Calculated.nightLightShadowStrength.Evaluate(param.darkProgress), speed));
			sunLight.intensity = Mathf.Lerp(sunLight.intensity, 0f, speed);
		}
	}

	private void CalculateStackedSettings()
	{
		Calculated.Reset();
		ApplyFogAndLighting(BaseFogAndLightSettings);
		if (Seasonal != null)
		{
			ApplyFogAndLighting(Seasonal);
		}
		if (Daily != null)
		{
			ApplyFogAndLighting(Daily);
		}
		if (Weather != null)
		{
			ApplyFogAndLighting(Weather);
		}
		if (PhotoMode.IsActive() && Photo != null)
		{
			ApplyFogAndLighting(Photo);
		}
		void ApplyFogAndLighting(FogAndLighting target)
		{
			bool forceSettings = target.forceSettings;
			if (target.setSunLightRotation | forceSettings)
			{
				Calculated.sunLightRotation = target.sunLightRotation;
			}
			if (target.setFogStartEnd | forceSettings)
			{
				Calculated.fogStartEnd = target.fogStartEnd;
			}
			if (target.setDayBloomIntensity | forceSettings)
			{
				Calculated.dayBloomIntensity = target.dayBloomIntensity;
			}
			if (target.setDayWhiteBalance | forceSettings)
			{
				Calculated.dayWhiteBalance = target.dayWhiteBalance;
			}
			if (target.setDaySkyboxTintColor | forceSettings)
			{
				Calculated.daySkyboxTintColor = target.daySkyboxTintColor;
			}
			if (target.setDayFogColor | forceSettings)
			{
				Calculated.dayFogColor = target.dayFogColor;
			}
			if (target.setDayLightColor | forceSettings)
			{
				Calculated.dayLightColor = target.dayLightColor;
			}
			if (target.setDayLightIntensity | forceSettings)
			{
				Calculated.dayLightIntensity = target.dayLightIntensity;
			}
			if (target.setDayLightShadowStrength | forceSettings)
			{
				Calculated.dayLightShadowStrength = target.dayLightShadowStrength;
			}
			if (target.setDayFillColor | forceSettings)
			{
				Calculated.dayFillColor = target.dayFillColor;
			}
			if (target.setDayFillIntensity | forceSettings)
			{
				Calculated.dayFillIntensity = target.dayFillIntensity;
			}
			if (target.setDayBackColor | forceSettings)
			{
				Calculated.dayBackColor = target.dayBackColor;
			}
			if (target.setDayBackIntensity | forceSettings)
			{
				Calculated.dayBackIntensity = target.dayBackIntensity;
			}
			if (target.setNightBloomIntensity | forceSettings)
			{
				Calculated.nightBloomIntensity = target.nightBloomIntensity;
			}
			if (target.setNightWhiteBalance | forceSettings)
			{
				Calculated.nightWhiteBalance = target.nightWhiteBalance;
			}
			if (target.setNightSkyboxTintColor | forceSettings)
			{
				Calculated.nightSkyboxTintColor = target.nightSkyboxTintColor;
			}
			if (target.setNightFogColor | forceSettings)
			{
				Calculated.nightFogColor = target.nightFogColor;
			}
			if (target.setNightLightColor | forceSettings)
			{
				Calculated.nightLightColor = target.nightLightColor;
			}
			if (target.setNightLightIntensity | forceSettings)
			{
				Calculated.nightLightIntensity = target.nightLightIntensity;
			}
			if (target.setNightLightShadowStrength | forceSettings)
			{
				Calculated.nightLightShadowStrength = target.nightLightShadowStrength;
			}
			if (target.setNightFillColor | forceSettings)
			{
				Calculated.nightFillColor = target.nightFillColor;
			}
			if (target.setNightFillIntensity | forceSettings)
			{
				Calculated.nightFillIntensity = target.nightFillIntensity;
			}
			if (target.setNightBackColor | forceSettings)
			{
				Calculated.nightBackColor = target.nightBackColor;
			}
			if (target.setNightBackIntensity | forceSettings)
			{
				Calculated.nightBackIntensity = target.nightBackIntensity;
			}
		}
	}

	private void LerpFogTo(float start, float end, float speed)
	{
		RenderSettings.fogStartDistance = Mathf.Lerp(RenderSettings.fogStartDistance, start, speed);
		currFogEndDist = Mathf.Lerp(currFogEndDist, end, speed);
		float num = fogToDistCurve.Evaluate(Cam.inst.dist);
		RenderSettings.fogEndDistance = currFogEndDist + num;
	}

	private void LerpBloomTo(float target, float speed)
	{
		if (!(bloom == null))
		{
			bloom.bloomIntensity = Mathf.Lerp(bloom.bloomIntensity, target, speed);
		}
	}
}
