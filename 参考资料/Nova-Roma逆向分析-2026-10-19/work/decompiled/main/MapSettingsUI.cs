using TMPro;
using UnityEngine;

public class MapSettingsUI : MonoBehaviour
{
	public TMP_Dropdown mapSizeDropdown;

	public TMP_Dropdown mapBiasDropdown;

	public TMP_Dropdown mapRiverDropdown;

	public TMP_Dropdown mapResourceDropdown;

	public static MapSettingsUI inst;

	public void OnMapSizeChanged()
	{
		int value = mapSizeDropdown.value;
		World.inst.mapSize = (World.MapSize)value;
		int value2 = mapBiasDropdown.value;
		World.inst.mapBias = (World.MapBias)value2;
		int value3 = mapRiverDropdown.value;
		World.inst.mapRiverAmount = (World.MapRiverAmount)value3;
		int value4 = mapResourceDropdown.value;
		World.inst.mapResourceAmount = (World.MapResourceAmount)value4;
	}

	public void Awake()
	{
		inst = this;
	}

	public void SetMapBias(World.MapBias bias)
	{
		mapBiasDropdown.value = (int)bias;
		World.inst.mapBias = bias;
	}

	public void SetSizeBias(World.MapSize bias)
	{
		mapSizeDropdown.value = (int)bias;
		World.inst.mapSize = bias;
	}

	public void SetRiverBias(World.MapRiverAmount bias)
	{
		mapRiverDropdown.value = (int)bias;
		World.inst.mapRiverAmount = bias;
	}

	public void SetResourceAmount(World.MapResourceAmount amount)
	{
		mapResourceDropdown.value = (int)amount;
		World.inst.mapResourceAmount = amount;
	}
}
