using System;
using System.Collections.Generic;
using UnityEngine;

public class Creative : MonoBehaviour
{
	[Serializable]
	public class CreativeSaveData : SaveClass<Creative, CreativeSaveData>
	{
		public bool isEnabled;

		public SerializableDictionary<int, bool> isCreativeOptionOn;

		public override CreativeSaveData Pack(Creative obj)
		{
			isCreativeOptionOn = new SerializableDictionary<int, bool>(obj.isCreativeOptionOn);
			isEnabled = obj.isEnabled;
			return this;
		}

		public override Creative Unpack(Creative obj)
		{
			foreach (KeyValuePair<int, bool> item in isCreativeOptionOn)
			{
				if (obj.isCreativeOptionOn.ContainsKey(item.Key))
				{
					obj.isCreativeOptionOn[item.Key] = item.Value;
				}
			}
			obj.SetEnabled(isEnabled);
			return obj;
		}
	}

	public static Creative inst;

	private List<int> creativeOptions = new List<int>();

	private Dictionary<int, bool> isCreativeOptionOn = new Dictionary<int, bool>();

	private Dictionary<int, bool> isCreativeOptionDefault = new Dictionary<int, bool>();

	private List<CreativeBrush> brushes = new List<CreativeBrush>();

	private bool isEnabled;

	public bool IsEnabled()
	{
		return isEnabled;
	}

	public void SetEnabled(bool enabled)
	{
		isEnabled = enabled;
		if (enabled && Player.inst != null)
		{
			Player.inst.CheatsEnabled = true;
		}
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		AddCreativeOption(0, isOn: false);
		AddCreativeOption(11, isOn: false);
		AddCreativeOption(8, isOn: false);
		AddCreativeOption(1, isOn: true);
		AddCreativeOption(2, isOn: true);
		AddCreativeOption(3, isOn: true);
		AddCreativeOption(4, isOn: true);
		AddCreativeOption(5, isOn: true);
		AddCreativeOption(6, isOn: true);
		AddCreativeOption(7, isOn: true);
		AddCreativeOption(9, isOn: false);
		AddCreativeOption(10, isOn: false);
	}

	public void AddCreativeOption(int option, bool isOn)
	{
		creativeOptions.Add(option);
		isCreativeOptionOn.Add(option, isOn);
		isCreativeOptionDefault.Add(option, isOn);
	}

	public bool SetCreativeModeOption(int option, bool isOn)
	{
		if (!isCreativeOptionOn.ContainsKey(option))
		{
			return false;
		}
		isCreativeOptionOn[option] = isOn;
		return true;
	}

	public bool IsCreativeOptionOn(int option)
	{
		bool value;
		return isCreativeOptionOn.TryGetValue(option, out value) & value;
	}

	public void ResetCreativeOptions()
	{
		for (int i = 0; i < creativeOptions.Count; i++)
		{
			isCreativeOptionOn[creativeOptions[i]] = isCreativeOptionDefault[creativeOptions[i]];
		}
		isEnabled = false;
	}
}
