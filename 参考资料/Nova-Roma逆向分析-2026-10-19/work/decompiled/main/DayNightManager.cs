using UnityEngine;

public class DayNightManager : MonoBehaviour
{
	public struct DayNightParameters
	{
		public bool isDay;

		public float dayProgress;

		public float _24HourTime;

		public float lightProgress;

		public float darkProgress;

		public float noonToMidnightProgress;
	}

	public static DayNightManager inst;

	private FogAndLightingStack.FogAndLighting fogAndLightingDaily = new FogAndLightingStack.FogAndLighting();

	public DayNightParameters GameParameters;

	public float groundDist = 100f;

	public float skyDist = 100f;

	public float sunRigRotDegrees = 22f;

	private void Start()
	{
		inst = this;
		fogAndLightingDaily.setSunLightRotation = true;
	}

	public void SetDayNight(float currentSeasonTime, float totalSeasonDuration, int numberOfDaysInSeason, float nightRatio)
	{
		float num = (float)numberOfDaysInSeason * (currentSeasonTime / totalSeasonDuration);
		GameParameters.dayProgress = num - (float)Mathf.FloorToInt(num);
		GameParameters._24HourTime = (GameParameters.dayProgress + 0.5f - (float)Mathf.FloorToInt(GameParameters.dayProgress + 0.5f)) * 24f;
		if (GameParameters.dayProgress > 0.5f - nightRatio / 2f && GameParameters.dayProgress < 0.5f + nightRatio / 2f)
		{
			if (GameParameters.isDay)
			{
				Broadcast.EveningEvent.Broadcast(new TimeOfDayEventData());
			}
			GameParameters.lightProgress = 0f;
			GameParameters.darkProgress = GameParameters.dayProgress.Remap(0.5f - nightRatio / 2f, 0.5f + nightRatio / 2f, 0f, 1f);
			GameParameters.noonToMidnightProgress = 1f - Mathf.Abs(GameParameters.darkProgress.Remap(0f, 1f, -0.5f, 0.5f));
			GameParameters.isDay = false;
			return;
		}
		if (!GameParameters.isDay)
		{
			Broadcast.MorningEvent.Broadcast(new TimeOfDayEventData());
		}
		GameParameters.darkProgress = 0f;
		if (GameParameters.dayProgress < 0.5f)
		{
			GameParameters.lightProgress = GameParameters.dayProgress.Remap(0f, 0.5f - nightRatio / 2f, 0.5f, 1f);
			GameParameters.noonToMidnightProgress = GameParameters.dayProgress.Remap(0f, 0.5f - nightRatio / 2f, 0.5f, 0f);
		}
		else if (GameParameters.dayProgress > 0.5f)
		{
			GameParameters.lightProgress = GameParameters.dayProgress.Remap(0.5f + nightRatio / 2f, 1f, 0f, 0.5f);
		}
		GameParameters.noonToMidnightProgress = Mathf.Abs(GameParameters.lightProgress.Remap(0f, 1f, -0.5f, 0.5f));
		GameParameters.isDay = true;
	}

	public void GetDayNightParameters(ref DayNightParameters param, float currentSeasonTime, float totalSeasonDuration, int numberOfDaysInSeason, float nightRatio)
	{
		float num = (float)numberOfDaysInSeason * (currentSeasonTime / totalSeasonDuration);
		param.dayProgress = num - (float)Mathf.FloorToInt(num);
		param._24HourTime = (param.dayProgress + 0.5f - (float)Mathf.FloorToInt(param.dayProgress + 0.5f)) * 24f;
		if (param.dayProgress > 0.5f - nightRatio / 2f && param.dayProgress < 0.5f + nightRatio / 2f)
		{
			param.lightProgress = 0f;
			param.darkProgress = param.dayProgress.Remap(0.5f - nightRatio / 2f, 0.5f + nightRatio / 2f, 0f, 1f);
			param.noonToMidnightProgress = 1f - Mathf.Abs(param.darkProgress.Remap(0f, 1f, -0.5f, 0.5f));
			param.isDay = false;
			return;
		}
		param.darkProgress = 0f;
		if (param.dayProgress < 0.5f)
		{
			param.lightProgress = param.dayProgress.Remap(0f, 0.5f - nightRatio / 2f, 0.5f, 1f);
			param.noonToMidnightProgress = param.dayProgress.Remap(0f, 0.5f - nightRatio / 2f, 0.5f, 0f);
		}
		else if (param.dayProgress > 0.5f)
		{
			param.lightProgress = param.dayProgress.Remap(0.5f + nightRatio / 2f, 1f, 0f, 0.5f);
		}
		param.noonToMidnightProgress = Mathf.Abs(param.lightProgress.Remap(0f, 1f, -0.5f, 0.5f));
		param.isDay = true;
	}

	public void Update()
	{
		Vector3 vector = Quaternion.AngleAxis(sunRigRotDegrees, new Vector3(0f, 1f, 0f)) * Vector3.forward;
		Vector3 vector2 = World.inst.GridCenter() + vector * groundDist;
		Vector3 vector3 = Quaternion.AngleAxis(sunRigRotDegrees, new Vector3(0f, 1f, 0f)) * Vector3.right;
		Vector3 vector4 = Quaternion.AngleAxis(GameParameters.lightProgress * 180f, vector) * vector3 * skyDist;
		if (!GameParameters.isDay)
		{
			vector4 = Quaternion.AngleAxis(GameParameters.darkProgress * 180f + 180f, vector) * vector3 * skyDist;
		}
		Vector3 vector5 = vector2 + vector4;
		Vector3 sunLightRotation = World.inst.GridCenter() - vector5;
		fogAndLightingDaily.sunLightRotation = sunLightRotation;
		FogAndLightingStack.inst.SetDailySettings(ref fogAndLightingDaily);
		if (PhotoMode.IsActive() && PhotoMode.inst.IsCustomSunEnabled())
		{
			World.inst.romeUnimaterial.SetFloat("_NightProgress", PhotoMode.inst.PhotoDayNightParameters.darkProgress);
			TerrainGen.inst.TerrainMaterial.SetFloat("_DayNight", PhotoMode.inst.PhotoDayNightParameters.noonToMidnightProgress);
		}
		else
		{
			World.inst.romeUnimaterial.SetFloat("_NightProgress", GameParameters.darkProgress);
			TerrainGen.inst.TerrainMaterial.SetFloat("_DayNight", GameParameters.noonToMidnightProgress);
		}
	}

	public bool NowIsBetween(float workStartHour, float workEndHour)
	{
		if (workStartHour < workEndHour)
		{
			if (GameParameters._24HourTime >= workStartHour)
			{
				return GameParameters._24HourTime <= workEndHour;
			}
			return false;
		}
		if (!(GameParameters._24HourTime >= workStartHour))
		{
			return GameParameters._24HourTime <= workEndHour;
		}
		return true;
	}
}
