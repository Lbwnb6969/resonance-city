using System;
using UnityEngine;

[Serializable]
[CreateAssetMenu(fileName = "NewSeasonDefinition", menuName = "Tools/SeasonDefinition", order = 1)]
public class SeasonDefinition : ScriptableObject
{
	public bool markNewYear;

	public new string name;

	public int id;

	public int transitionTime;

	public float duration;

	public int nights = 3;

	public float nightRatio = 0.5f;

	public TerrainSkinConfiguration terrainSkinConfiguration;

	public FogAndLightingStack.FogAndLighting fogAndLightingSeasonalBase;

	public Weather.WeatherSettings weatherSettings;

	public FoliageManager.FoliageColorSet treeColorSet;

	public Texture2D bannerTexture;

	public void OnValidate()
	{
	}
}
