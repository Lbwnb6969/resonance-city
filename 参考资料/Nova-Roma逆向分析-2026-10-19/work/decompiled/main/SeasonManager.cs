using System;
using System.Collections.Generic;
using System.Linq;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class SeasonManager : MonoBehaviour
{
	public delegate List<SeasonDefinition> SeasonPlanner();

	public enum WeatherType
	{
		None,
		Rain,
		HeavyRain,
		Drought
	}

	[Serializable]
	public class SeasonManagerSaveData : SaveClass<SeasonManager, SeasonManagerSaveData>
	{
		public float seasonElapsedTime;

		public float seasonsCompletedTime;

		public float snowFade;

		public bool freezeSeason;

		public bool holdTimeNow;

		public bool holdTimePending;

		public float holdTimeAt;

		public int currYear;

		public WeatherType currWeather;

		public float waterSourceMul;

		public override SeasonManagerSaveData Pack(SeasonManager w)
		{
			seasonElapsedTime = w.seasonElapsedTime;
			seasonsCompletedTime = w.seasonsCompletedTime;
			snowFade = w.snowFade;
			currYear = w.Year;
			holdTimeNow = w.holdTimeNow;
			holdTimePending = w.holdTimePending;
			holdTimeAt = w.holdTimeAt;
			waterSourceMul = w.waterSourceMul;
			currWeather = w.currWeather;
			return this;
		}

		public override SeasonManager Unpack(SeasonManager w)
		{
			w.ResetWeather();
			w.Year = currYear;
			w.seasonDefinitions.Clear();
			w.seasonDefinitions.AddRange(w.currentPlanner());
			float num = seasonsCompletedTime;
			while (num > 0f)
			{
				num -= w.seasonDefinitions[0].duration;
				w.seasonDefinitions.RemoveAt(0);
			}
			if (w.seasonDefinitions.Count == 0)
			{
				w.seasonDefinitions.AddRange(w.currentPlanner());
				seasonsCompletedTime = 0f;
				seasonElapsedTime = 0f;
			}
			w.CurrentSeason = w.seasonDefinitions[0];
			w.seasonsCompletedTime = seasonsCompletedTime;
			w.seasonElapsedTime = seasonElapsedTime;
			w.snowFade = snowFade;
			w.holdTimeNow = holdTimeNow;
			w.holdTimePending = holdTimePending;
			w.holdTimeAt = holdTimeAt;
			TerrainGen.inst.SetNextSkin(w.CurrentSeason.terrainSkinConfiguration);
			TerrainGen.inst.BlendInNextSkin(0.001f);
			FoliageManager.inst.SetTreeColorSet(w.CurrentSeason.treeColorSet);
			FoliageManager.inst.SetNextTreeColorSet(w.CurrentSeason.treeColorSet);
			FoliageManager.inst.BlendInNextColorSet(0.001f);
			FogAndLightingStack.inst.SetSeasonSettings(ref w.CurrentSeason.fogAndLightingSeasonalBase);
			w.waterSourceMul = waterSourceMul;
			w.SetWeather(currWeather);
			if (w.currWeather == WeatherType.Rain || w.currWeather == WeatherType.HeavyRain)
			{
				w.rainLightFX.Simulate(5f);
				w.rainLightFX.Play(withChildren: true);
				if (w.currWeather == WeatherType.Rain)
				{
					FogAndLightingStack.inst.SetWeatherSettings(ref w.rainSettings);
				}
				if (w.currWeather == WeatherType.HeavyRain)
				{
					w.rainHeavyFX.Simulate(5f);
					w.rainHeavyFX.Play(withChildren: true);
					FogAndLightingStack.inst.SetWeatherSettings(ref w.heavyRainSettings);
				}
			}
			FogAndLightingStack.inst.UpdateNewSettingsImmediately();
			DayNightManager.inst.SetDayNight(seasonElapsedTime, w.CurrentSeason.duration, w.CurrentSeason.nights, w.CurrentSeason.nightRatio);
			NotificationUI.TryLog(NotificationUI.GeneralGroup, "newyear", string.Format(ScriptLocalization.LogGameUIYear, currYear), NotificationStatus.Neutral, -1f, null, title: true);
			return w;
		}
	}

	public static SeasonManager inst;

	public const int ID_SUMMER = 0;

	public const int ID_AUTUMN = 1;

	public const int ID_WINTER = 2;

	public const int ID_SPRING = 3;

	private int Year;

	public SeasonDefinition CurrentSeason;

	internal List<SeasonDefinition> seasonDefinitions = new List<SeasonDefinition>();

	private float timeInYear;

	public SeasonPlanner currentPlanner;

	public bool holdTimeNow;

	public bool holdTimePending;

	public float holdTimeAt;

	public float seasonElapsedTime;

	public float seasonsCompletedTime;

	public ParticleSystem snowLightFX;

	public ParticleSystem snowHeavyFX;

	public float snowDistFromCam = 20f;

	public float snowHeightFromCam = 10f;

	public ParticleSystem rainLightFX;

	public ParticleSystem rainHeavyFX;

	public float rainDistFromCam = 20f;

	public float rainHeightFromCam = 10f;

	public EventInstance eRainEvent;

	private WeatherType weatherType;

	private bool weatherRunning;

	public FogAndLightingStack.FogAndLighting rainSettings;

	public FogAndLightingStack.FogAndLighting heavyRainSettings;

	public FogAndLightingStack.FogAndLighting droughtSettings;

	[NonSerialized]
	public float waterSourceMul;

	public float snowFadeTime = 30f;

	public float snowFade;

	public Vector4 snowColor;

	private WeatherType currWeather;

	private Timer lightningTimer = new Timer(7f);

	public WeatherType CurrWeather => currWeather;

	public int CurrentYear()
	{
		return Year;
	}

	public void SetCurrentYear(int targetYear)
	{
		if (targetYear > 0)
		{
			Year = targetYear - 1;
			SkipToSeason(3);
			SetTime(12f);
		}
	}

	private void Awake()
	{
		inst = this;
	}

	private void OnEnable()
	{
		currentPlanner = DefaultPlanner;
		SetupYear();
		FoliageManager.inst.SetTreeColorSet(seasonDefinitions[0].treeColorSet);
		FogAndLightingStack.inst.UpdateNewSettingsImmediately();
	}

	public float TimeInYear()
	{
		return timeInYear;
	}

	public float GetYearProgress()
	{
		return (seasonsCompletedTime + seasonElapsedTime) / timeInYear;
	}

	public List<SeasonDefinition> DefaultPlanner()
	{
		List<SeasonDefinition> list = new List<SeasonDefinition>();
		list.Add(LoadSeasonDefinitionByName("SpringSeason"));
		list.Add(LoadSeasonDefinitionByName("SummerSeason"));
		list.Add(LoadSeasonDefinitionByName("AutumnSeason"));
		list.Add(LoadSeasonDefinitionByName("WinterSeason"));
		TerrainGen.inst.SetSummerSkin(list[1].terrainSkinConfiguration);
		return list;
	}

	private void UpdateYearData()
	{
		timeInYear = seasonDefinitions.Sum((SeasonDefinition a) => a.duration);
	}

	private void Start()
	{
		UpdateYearData();
		eRainEvent = RuntimeManager.CreateInstance("event:/OldSFX/ambientRain");
	}

	private void Update()
	{
		float num = 1f;
		if (Year == 1 && DayNightManager.inst.GameParameters.isDay)
		{
			if (CurrentSeason.id == 3)
			{
				num = 0.5f;
			}
			if (CurrentSeason.id == 0)
			{
				num = 0.75f;
			}
		}
		seasonElapsedTime = Mathf.Clamp(seasonElapsedTime + Time.deltaTime * num, 0f, CurrentSeason.duration);
		if (holdTimePending && seasonElapsedTime > holdTimeAt)
		{
			holdTimePending = false;
			holdTimeNow = true;
		}
		if (holdTimeNow)
		{
			seasonElapsedTime = holdTimeAt;
		}
		UpdateSnow(Time.deltaTime);
		UpdateWeather(Time.deltaTime);
		bool flag = false;
		if ((seasonElapsedTime >= CurrentSeason.duration) | flag)
		{
			seasonDefinitions.RemoveAt(0);
			if (seasonDefinitions.Count > 0)
			{
				BootupSeason(seasonDefinitions[0]);
			}
			else
			{
				SetupYear();
			}
		}
		DayNightManager.inst.SetDayNight(seasonElapsedTime, CurrentSeason.duration, CurrentSeason.nights, CurrentSeason.nightRatio);
	}

	public void SkipToSeason(int seasonId)
	{
		do
		{
			seasonDefinitions.RemoveAt(0);
			if (seasonDefinitions.Count > 0)
			{
				BootupSeason(seasonDefinitions[0]);
			}
			else
			{
				SetupYear();
			}
		}
		while (CurrentSeason.id != seasonId);
	}

	private void ResetWeather()
	{
		snowLightFX.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
		snowHeavyFX.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
		rainLightFX.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
		rainHeavyFX.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
		if (eRainEvent.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			eRainEvent.stop(STOP_MODE.IMMEDIATE);
		}
		SetWeather(WeatherType.None);
		waterSourceMul = 0f;
		CloudSystem.inst.stormAlpha = 0f;
		snowFade = 0f;
		weatherRunning = false;
	}

	private void UpdateWeather(float dt)
	{
		rainLightFX.transform.position = Cam.inst.transform.position + Cam.inst.transform.forward.xz() * rainDistFromCam + Cam.inst.transform.up * rainHeightFromCam;
		rainHeavyFX.transform.position = Cam.inst.transform.position + Cam.inst.transform.forward.xz() * (rainDistFromCam - 5f) + Cam.inst.transform.up * rainHeightFromCam;
		rainLightFX.transform.parent.localRotation = Quaternion.LookRotation(Cam.inst.transform.forward.xz());
		int floodingFrequency = DifficultyManager.inst.currOption.floodingFrequency;
		_ = DifficultyManager.inst.currOption.droughtFrequency;
		switch (currWeather)
		{
		case WeatherType.Rain:
			if ((CurrentSeason.id == 3 && seasonElapsedTime > CurrentSeason.duration * 0.75f) || (CurrentSeason.id == 0 && seasonElapsedTime < CurrentSeason.duration * 0.5f))
			{
				weatherRunning = true;
				if (!rainLightFX.isPlaying)
				{
					rainLightFX.Play(withChildren: true);
				}
				if (eRainEvent.getPlaybackState(out var state2) == RESULT.OK && state2 == PLAYBACK_STATE.STOPPED)
				{
					eRainEvent.start();
				}
				waterSourceMul += dt * 0.075f;
				float num2 = 0f;
				switch (floodingFrequency)
				{
				case 1:
					num2 = 0.75f;
					break;
				case 2:
					num2 = 1f;
					break;
				case 3:
					num2 = 1.25f;
					break;
				case 4:
					num2 = 1.5f;
					break;
				}
				if (waterSourceMul > num2)
				{
					waterSourceMul = num2;
				}
				FogAndLightingStack.inst.SetWeatherSettings(ref rainSettings);
			}
			else if (weatherRunning)
			{
				SetWeather(WeatherType.None);
				weatherRunning = false;
			}
			break;
		case WeatherType.HeavyRain:
			if (currWeather != WeatherType.HeavyRain)
			{
				break;
			}
			if ((CurrentSeason.id == 3 && seasonElapsedTime > CurrentSeason.duration * 0.5f) || CurrentSeason.id == 0)
			{
				if (!weatherRunning)
				{
					NotificationUI.NotificationMessage message2 = new NotificationUI.NotificationMessage
					{
						single = LocalizationManager.GetTranslation("NotificationUI_Flooding")
					};
					NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "flooding", message2, NotificationStatus.Warning);
				}
				weatherRunning = true;
				if (!rainLightFX.isPlaying)
				{
					rainLightFX.Play(withChildren: true);
				}
				if (!rainHeavyFX.isPlaying)
				{
					rainHeavyFX.Play(withChildren: true);
				}
				if (eRainEvent.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.STOPPED)
				{
					eRainEvent.start();
				}
				waterSourceMul += dt * 0.05f;
				FogAndLightingStack.inst.SetWeatherSettings(ref heavyRainSettings);
				float num = 0f;
				switch (floodingFrequency)
				{
				case 1:
					num = 1.5f;
					break;
				case 2:
					num = 2f;
					break;
				case 3:
					num = 2.5f;
					break;
				case 4:
					num = 3f;
					break;
				}
				if (waterSourceMul > num)
				{
					waterSourceMul = num;
				}
			}
			else if (weatherRunning)
			{
				SetWeather(WeatherType.None);
				weatherRunning = false;
			}
			break;
		case WeatherType.Drought:
			if ((CurrentSeason.id == 3 && seasonElapsedTime > CurrentSeason.duration * 0.12f) || CurrentSeason.id == 0 || (CurrentSeason.id == 1 && seasonElapsedTime < CurrentSeason.duration * 0.66f))
			{
				if (!weatherRunning)
				{
					NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
					{
						single = LocalizationManager.GetTranslation("NotificationUI_Drought")
					};
					NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "drought", message, NotificationStatus.Warning);
				}
				weatherRunning = true;
				FogAndLightingStack.inst.SetWeatherSettings(ref droughtSettings);
				waterSourceMul = -1.25f;
			}
			else if (weatherRunning)
			{
				SetWeather(WeatherType.None);
				weatherRunning = false;
			}
			break;
		}
		lightningTimer.Enabled = (currWeather == WeatherType.Rain || currWeather == WeatherType.HeavyRain) && weatherRunning;
		if (lightningTimer.Update(dt))
		{
			if (currWeather == WeatherType.HeavyRain)
			{
				lightningTimer.Duration = 10f + SRand.Range(0f, 5f);
			}
			else if (currWeather == WeatherType.Rain)
			{
				lightningTimer.Duration = 14f + SRand.Range(0f, 8f);
			}
			Vector3 vector = Cam.inst.transform.forward.xz();
			vector = ((SRand.Range(0, 100) >= 70) ? (Quaternion.Euler(0f, SRand.Range(-180, 180), 0f) * vector) : (Quaternion.Euler(0f, SRand.Range(-75, 75), 0f) * vector));
			float num3 = SRand.Range(30, 120);
			Vector3 strikePos = Cam.inst.CamPos + vector * num3;
			strikePos.y = 10f;
			Weather.inst.LightningStrike(strikePos);
		}
		if (currWeather == WeatherType.Rain || currWeather == WeatherType.HeavyRain)
		{
			CloudSystem.inst.stormAlpha += dt * 0.5f;
		}
		if (currWeather != WeatherType.Rain && currWeather != WeatherType.HeavyRain)
		{
			if (rainHeavyFX.isPlaying)
			{
				rainHeavyFX.Stop(withChildren: true);
			}
			if (rainLightFX.isPlaying)
			{
				rainLightFX.Stop(withChildren: true);
			}
			if (eRainEvent.getPlaybackState(out var state3) == RESULT.OK && state3 == PLAYBACK_STATE.PLAYING)
			{
				eRainEvent.stop(STOP_MODE.ALLOWFADEOUT);
			}
		}
		if (currWeather == WeatherType.None)
		{
			CloudSystem.inst.stormAlpha -= dt * 0.5f;
			Mathff.MoveTowards(waterSourceMul, 0f, dt * 0.125f, out var _, out var newPos);
			waterSourceMul = newPos;
			FogAndLightingStack.inst.ClearWeatherSettings();
		}
		CloudSystem.inst.stormAlpha = Mathf.Clamp01(CloudSystem.inst.stormAlpha);
	}

	private void UpdateSnow(float dt)
	{
		snowLightFX.transform.position = Cam.inst.transform.position + Cam.inst.transform.forward.xz() * snowDistFromCam + Cam.inst.transform.up * snowHeightFromCam;
		snowHeavyFX.transform.position = Cam.inst.transform.position + Cam.inst.transform.forward.xz() * (snowDistFromCam - 5f) + Cam.inst.transform.up * snowHeightFromCam;
		snowLightFX.transform.parent.localRotation = Quaternion.LookRotation(Cam.inst.transform.forward.xz());
		if ((CurrentSeason.id == 1 && seasonElapsedTime > CurrentSeason.duration * 0.85f) || (CurrentSeason.id == 2 && seasonElapsedTime < CurrentSeason.duration * 0.6f))
		{
			if (!snowLightFX.isPlaying)
			{
				snowLightFX.Play();
			}
		}
		else if (snowLightFX.isPlaying)
		{
			snowLightFX.Stop();
		}
		if (CurrentSeason.id == 2 && seasonElapsedTime < CurrentSeason.duration * 0.4f)
		{
			if (!snowHeavyFX.isPlaying)
			{
				snowHeavyFX.Play();
			}
		}
		else if (snowHeavyFX.isPlaying)
		{
			snowHeavyFX.Stop();
		}
		if (CurrentSeason.id == 2)
		{
			if (seasonElapsedTime <= snowFadeTime)
			{
				snowFade += dt / snowFadeTime;
			}
			else if (seasonElapsedTime >= CurrentSeason.duration - snowFadeTime)
			{
				snowFade -= dt / snowFadeTime;
			}
		}
		else
		{
			snowFade -= dt / snowFadeTime;
		}
		snowFade = Mathff.Clamp01(snowFade);
		bool flag = GameUI.inst.IsLogisticViewModeActive();
		Shader.SetGlobalFloat("_Snow", flag ? 0f : snowFade);
	}

	public void SetMidnight()
	{
		SetTime(0f);
	}

	public void SetNoon()
	{
		SetTime(12f);
	}

	public float CalcSeasonTimeAt24Hour(float __24HourTime)
	{
		int num = Mathf.FloorToInt((float)CurrentSeason.nights * (seasonElapsedTime / CurrentSeason.duration));
		float num2 = __24HourTime / 24f + 0.5f;
		if (num2 >= 1f)
		{
			num2--;
		}
		return ((float)num + num2) * CurrentSeason.duration / (float)CurrentSeason.nights;
	}

	private float CalcSeasonTimeAt24Hour(float __24HourTime, int dayOfSeason)
	{
		float num = __24HourTime / 24f + 0.5f;
		if (num >= 1f)
		{
			num--;
		}
		return ((float)dayOfSeason + num) * CurrentSeason.duration / (float)CurrentSeason.nights;
	}

	public void SetTime(float __24HourTime, int dayOfSeason)
	{
		seasonElapsedTime = CalcSeasonTimeAt24Hour(__24HourTime, dayOfSeason);
		DayNightManager.inst.SetDayNight(seasonElapsedTime, CurrentSeason.duration, CurrentSeason.nights, CurrentSeason.nightRatio);
		DayNightManager.inst.Update();
		FogAndLightingStack.inst.UpdateNewSettingsImmediately();
		FogAndLightingStack.inst.Update();
	}

	public void SetTime(float __24HourTime)
	{
		seasonElapsedTime = CalcSeasonTimeAt24Hour(__24HourTime);
		DayNightManager.inst.SetDayNight(seasonElapsedTime, CurrentSeason.duration, CurrentSeason.nights, CurrentSeason.nightRatio);
		DayNightManager.inst.Update();
		FogAndLightingStack.inst.UpdateNewSettingsImmediately();
		FogAndLightingStack.inst.Update();
	}

	public void SetHoldAt(float __24HourTime, int dayOfSeason)
	{
		holdTimePending = true;
		holdTimeAt = CalcSeasonTimeAt24Hour(__24HourTime, dayOfSeason);
		holdTimeNow = false;
	}

	public void SetHold()
	{
		holdTimeAt = seasonElapsedTime;
		holdTimeNow = true;
	}

	public void CancelHold()
	{
		holdTimePending = false;
		holdTimeNow = false;
	}

	public void SetAndHoldDay()
	{
		SetTime(0f);
		SetHold();
	}

	private void SetupYear()
	{
		seasonDefinitions.Clear();
		seasonDefinitions.AddRange(currentPlanner());
		UpdateYearData();
		CurrentSeason = null;
		seasonElapsedTime = 0f;
		seasonsCompletedTime = 0f;
		BootupSeason(seasonDefinitions[0]);
	}

	public void Reset()
	{
		seasonDefinitions.Clear();
		seasonDefinitions.AddRange(currentPlanner());
		WeatherOverlayUI.inst.Reset();
		UpdateYearData();
		ResetWeather();
		seasonElapsedTime = 0f;
		seasonsCompletedTime = 0f;
		Year = 1;
		CurrentSeason = seasonDefinitions[0];
		FogAndLightingStack.inst.SetSeasonSettings(ref CurrentSeason.fogAndLightingSeasonalBase);
		if (TerrainGen.inst != null)
		{
			TerrainGen.inst.SetSkin(CurrentSeason.terrainSkinConfiguration);
			TerrainGen.inst.SetNextSkin(CurrentSeason.terrainSkinConfiguration);
		}
		if (FoliageManager.inst != null)
		{
			FoliageManager.inst.SetTreeColorSet(CurrentSeason.treeColorSet);
			FoliageManager.inst.SetNextTreeColorSet(CurrentSeason.treeColorSet);
			FoliageManager.inst.ApplyColorSet();
		}
	}

	public void SetWeather(WeatherType wType)
	{
		bool flag = false;
		if (wType != currWeather)
		{
			flag = true;
		}
		currWeather = wType;
		if (flag)
		{
			WeatherOverlayUI.inst.RefreshVisuals();
		}
	}

	private void BootupSeason(SeasonDefinition Season)
	{
		if (CurrentSeason != null)
		{
			seasonsCompletedTime += CurrentSeason.duration;
		}
		seasonElapsedTime = 0f;
		CurrentSeason = Season;
		Broadcast.SeasonEvent.Broadcast(new SeasonEventData
		{
			SeasonDefinition = CurrentSeason,
			year = Year
		});
		if (CurrentSeason.markNewYear)
		{
			Year++;
			Broadcast.NewYearEvent.Broadcast(new NewYearEvent
			{
				year = Year
			});
			MilestoneManager.inst.CheckSurvive200YearsMilestone(Year);
			NotificationUI.TryLog(NotificationUI.GeneralGroup, "newyear", string.Format(ScriptLocalization.LogGameUIYear, Year), NotificationStatus.Neutral, -1f, null, title: true);
			if (GameState.inst.CurrMode == GameState.inst.playingMode)
			{
				WeatherType weather = WeatherType.None;
				int floodingFrequency = DifficultyManager.inst.currOption.floodingFrequency;
				int droughtFrequency = DifficultyManager.inst.currOption.droughtFrequency;
				int num = 1;
				int num2 = Mathff.Max(floodingFrequency, droughtFrequency);
				if (num2 >= 1)
				{
					num = 6;
				}
				if (num2 >= 2)
				{
					num = 5;
				}
				if (num2 >= 3)
				{
					num = 3;
				}
				if (num2 >= 4)
				{
					num = 2;
				}
				if (Year >= num)
				{
					float num3 = 25f + 30f * ((float)num2 / 4f);
					if ((float)SRand.Range(0, 100) < num3)
					{
						weather = WeatherType.Rain;
						float num4 = 50f * ((float)floodingFrequency / 4f);
						int num5 = SRand.Range(0, 100);
						if ((float)num5 < num4)
						{
							weather = WeatherType.HeavyRain;
						}
						float num6 = 50f * ((float)droughtFrequency / 4f);
						int num7 = SRand.Range(0, 100);
						if ((float)num7 < num6)
						{
							weather = WeatherType.Drought;
						}
						if ((float)num7 < num6 && (float)num5 < num4)
						{
							weather = ((num7 <= num5) ? WeatherType.HeavyRain : WeatherType.Drought);
						}
					}
				}
				lightningTimer.Reset();
				SetWeather(weather);
				if (SRand.value <= 0.1f)
				{
					RuntimeManager.PlayOneShot("event:/OldSFX/EnvRooster");
				}
			}
			else
			{
				SetWeather(WeatherType.None);
			}
		}
		FogAndLightingStack.inst.SetSeasonSettings(ref CurrentSeason.fogAndLightingSeasonalBase);
		if (TerrainGen.inst != null)
		{
			TerrainGen.inst.SetNextSkin(CurrentSeason.terrainSkinConfiguration);
			TerrainGen.inst.BlendInNextSkin(CurrentSeason.transitionTime);
		}
		if (FoliageManager.inst != null)
		{
			FoliageManager.inst.SetNextTreeColorSet(CurrentSeason.treeColorSet);
			FoliageManager.inst.BlendInNextColorSet(CurrentSeason.transitionTime);
		}
	}

	public void RefreshSeasonSkin()
	{
		CurrentSeason.terrainSkinConfiguration.OnValidate();
		TerrainGen.inst.SetSkin(CurrentSeason.terrainSkinConfiguration);
	}

	public SeasonDefinition LoadSeasonDefinitionByName(string name)
	{
		return Resources.Load<SeasonDefinition>("SeasonDefinitions/" + name);
	}

	public static SeasonDefinition GetCurrentSeason()
	{
		return inst.CurrentSeason;
	}

	public float GetEndOfSeasonMusicCountdown()
	{
		float num = inst.CurrentSeason.duration / (float)CurrentSeason.nights / 4f;
		float num2 = inst.CurrentSeason.duration - num;
		return Mathff.Clamp01((seasonElapsedTime - num2) / num);
	}
}
