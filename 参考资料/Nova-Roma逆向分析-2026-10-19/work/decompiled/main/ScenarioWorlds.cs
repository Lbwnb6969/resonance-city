using System;
using UnityEngine;

[Serializable]
[CreateAssetMenu(menuName = "ScriptableObjects/ScenarioWorlds")]
public class ScenarioWorlds : ScriptableObject
{
	[SerializeField]
	[HideInInspector]
	public byte[] demo;

	public void OnSaveDemo()
	{
		World.inst.isDemo = true;
		LoadSaveContainer data = new LoadSaveContainer().Pack(null);
		demo = SaveSerializer.SerializeToBytes(data);
	}

	public void OnLoadDemo()
	{
		if (demo != null)
		{
			LoadSaveContainer loadSaveContainer;
			try
			{
				loadSaveContainer = SaveSerializer.DeserializeFromBytes<LoadSaveContainer>(demo);
			}
			catch (LegacyFormatException ex)
			{
				Debug.LogWarning("[ScenarioWorlds] " + ex.Message);
				return;
			}
			LoadSave.Loading = true;
			loadSaveContainer.Unpack(null);
			Broadcast.OnLoadedEvent.Broadcast(new OnLoadedEvent());
			LoadSave.Loading = false;
			if (LoadSave.onLoadFinished != null)
			{
				LoadSave.onLoadFinished("demo");
			}
		}
	}
}
