using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization;
using UnityEngine;

namespace Assets;

public class Settings : MonoBehaviour
{
	public delegate void OnKeybindChanged(int id, ConfigurableControls.Keybind keybind);

	[Serializable]
	public class SettingsSaveData : SaveClass<Settings, SettingsSaveData>
	{
		public float masterVolume;

		public float masterSfx;

		public bool invertZoom;

		[OptionalField(VersionAdded = 2)]
		public bool showClouds = true;

		[OptionalField(VersionAdded = 3)]
		public bool SSAO = true;

		[OptionalField(VersionAdded = 3)]
		public bool PostEffects = true;

		[OptionalField(VersionAdded = 3)]
		public bool Shadows = true;

		[OptionalField(VersionAdded = 3)]
		public bool Birds = true;

		[OptionalField(VersionAdded = 3)]
		public bool Waves = true;

		[OptionalField(VersionAdded = 4)]
		public bool AntiAliasing = true;

		[OptionalField(VersionAdded = 4)]
		public bool EdgeScroll = true;

		[OptionalField(VersionAdded = 5)]
		public bool AdvisorNotifications = true;

		[OptionalField(VersionAdded = 6)]
		public bool VSync = true;

		[OptionalField(VersionAdded = 6)]
		public float MaxPanningSpeed = 0.5f;

		[OptionalField(VersionAdded = 7)]
		public bool Fog = true;

		[OptionalField(VersionAdded = 8)]
		public float UIScale = 0.5f;

		[OptionalField(VersionAdded = 9)]
		public bool VikingDragonTimers = true;

		[OptionalField(VersionAdded = 10)]
		public bool StreamerMode;

		[OptionalField(VersionAdded = 11)]
		public bool DisableInstancedRendering;

		[OptionalField(VersionAdded = 12)]
		public bool LegacyMouseControls;

		[OptionalField(VersionAdded = 12)]
		public float ZoomSpeed = 0.5f;

		[OptionalField(VersionAdded = 14)]
		public float FogDistance;

		[OptionalField(VersionAdded = 15)]
		public bool ConsoleControls;

		[OptionalField(VersionAdded = 16)]
		public MiniMapUI.MiniMapSaveData MiniMapSaveData;

		[OptionalField(VersionAdded = 16)]
		public PhotoMode.PhotoSaveData PhotoModeSaveData;

		[OptionalField(VersionAdded = 17)]
		public SerializableDictionary<int, ConfigurableControls.KeyChord> modifiedKeybinds;

		[OptionalField(VersionAdded = 18)]
		public ConfigurableControls.KeyChord[] KeyboardSettings = new ConfigurableControls.KeyChord[21];

		[OptionalField(VersionAdded = 19)]
		public float masterAmbient;

		[OptionalField(VersionAdded = 20)]
		public bool pauseOnLoseFocus;

		[OptionalField(VersionAdded = 21)]
		public bool muteOnLoseFocus;

		public override SettingsSaveData Pack(Settings obj)
		{
			masterVolume = obj.MasterMusicVolume;
			masterSfx = obj.MasterSfxVolume;
			masterAmbient = obj.MasterAmbientVolume;
			invertZoom = obj.InvertZoom;
			showClouds = obj.ShowClouds;
			SSAO = obj.SSAO;
			PostEffects = obj.PostEffects;
			Shadows = obj.Shadows;
			Birds = obj.Birds;
			Waves = obj.Waves;
			AntiAliasing = obj.AntiAliasing;
			EdgeScroll = obj.EdgeScroll;
			AdvisorNotifications = obj.AdvisorNotifications;
			VSync = obj.VSync;
			MaxPanningSpeed = obj.MaxPanningSpeed;
			ZoomSpeed = obj.ZoomSpeed;
			Fog = obj.Fog;
			FogDistance = obj.FogDistance;
			UIScale = obj.UIScale;
			VikingDragonTimers = obj.VikingDragonTimers;
			StreamerMode = obj.StreamerMode;
			DisableInstancedRendering = obj.DisableInstancedRendering;
			ConsoleControls = obj.ConsoleControls;
			pauseOnLoseFocus = obj.PauseOnLoseFocus;
			muteOnLoseFocus = obj.MuteOnLoseFocus;
			modifiedKeybinds = new SerializableDictionary<int, ConfigurableControls.KeyChord>(obj.modifiedKeybinds);
			MiniMapSaveData = new MiniMapUI.MiniMapSaveData().Pack(MiniMapUI.inst);
			return this;
		}

		public override Settings Unpack(Settings obj)
		{
			obj.MasterMusicVolume = masterVolume;
			obj.MasterSfxVolume = masterSfx;
			obj.MasterAmbientVolume = masterAmbient;
			obj.InvertZoom = invertZoom;
			obj.EdgeScroll = EdgeScroll;
			obj.ShowClouds = showClouds;
			obj.SSAO = SSAO;
			obj.PostEffects = PostEffects;
			obj.Shadows = Shadows;
			obj.Birds = Birds;
			obj.Waves = Waves;
			obj.AntiAliasing = AntiAliasing;
			obj.AdvisorNotifications = AdvisorNotifications;
			obj.VSync = VSync;
			obj.MaxPanningSpeed = MaxPanningSpeed;
			obj.ZoomSpeed = ZoomSpeed;
			obj.Fog = Fog;
			obj.FogDistance = Mathff.Clamp01(FogDistance);
			obj.UIScale = UIScale;
			obj.VikingDragonTimers = VikingDragonTimers;
			obj.StreamerMode = StreamerMode;
			obj.DisableInstancedRendering = DisableInstancedRendering;
			obj.ConsoleControls = false;
			obj.PauseOnLoseFocus = pauseOnLoseFocus;
			obj.MuteOnLoseFocus = muteOnLoseFocus;
			obj.modifiedKeybinds.Clear();
			if (modifiedKeybinds != null)
			{
				foreach (KeyValuePair<int, ConfigurableControls.KeyChord> modifiedKeybind in modifiedKeybinds)
				{
					obj.OnModifiedKeybind(modifiedKeybind.Key, modifiedKeybind.Value);
				}
			}
			obj.savedMiniMapData = MiniMapSaveData;
			return obj;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			showClouds = true;
			SSAO = true;
			PostEffects = true;
			Birds = true;
			Waves = true;
			Shadows = true;
			EdgeScroll = true;
			AntiAliasing = true;
			AdvisorNotifications = true;
			VSync = true;
			MaxPanningSpeed = 0.5f;
			ZoomSpeed = 0.5f;
			Fog = true;
			UIScale = 0.5f;
			VikingDragonTimers = true;
			StreamerMode = false;
			DisableInstancedRendering = false;
			ConsoleControls = false;
			pauseOnLoseFocus = false;
			muteOnLoseFocus = false;
			FogDistance = 0f;
		}
	}

	public static Settings inst;

	public Dictionary<int, ConfigurableControls.KeyChord> modifiedKeybinds = new Dictionary<int, ConfigurableControls.KeyChord>();

	private bool streamerMode;

	[NonSerialized]
	public MiniMapUI.MiniMapSaveData savedMiniMapData;

	[NonSerialized]
	public PhotoMode.PhotoSaveData savedPhotoModeData;

	public static OnKeybindChanged onKeybindChanged;

	public bool supportsInstancing => SystemInfo.supportsInstancing;

	public float MasterMusicVolume { get; set; }

	public float MasterSfxVolume { get; set; }

	public float MasterAmbientVolume { get; set; }

	public bool InvertZoom { get; set; }

	public bool ShowClouds { get; set; }

	public bool SSAO { get; set; }

	public bool PostEffects
	{
		get
		{
			return true;
		}
		set
		{
		}
	}

	public bool Shadows { get; set; }

	public bool AntiAliasing { get; set; }

	public bool Birds { get; set; }

	public bool Waves { get; set; }

	public bool EdgeScroll { get; set; }

	public bool AdvisorNotifications { get; set; }

	public bool Fog { get; set; }

	public float FogDistance { get; set; }

	public float MaxPanningSpeed { get; set; }

	public float ZoomSpeed { get; set; }

	public float UIScale { get; set; }

	public bool VikingDragonTimers { get; set; }

	public bool DisableInstancedRendering { get; set; }

	public bool ConsoleControls { get; set; }

	public bool PauseOnLoseFocus { get; set; }

	public bool MuteOnLoseFocus { get; set; }

	public bool StreamerMode
	{
		get
		{
			return streamerMode;
		}
		set
		{
			if ((bool)GameUI.inst)
			{
				streamerMode = value && !GameUI.IsOnConsole();
				GameUI.inst.VotingFeature.SetActive(streamerMode);
				if (!streamerMode && StatusEffectsManager.inst != null)
				{
					StatusEffectsManager.inst.ClearEffects();
				}
			}
		}
	}

	public bool VSync
	{
		get
		{
			return QualitySettings.vSyncCount == 1;
		}
		set
		{
			QualitySettings.vSyncCount = (value ? 1 : 0);
		}
	}

	private void Awake()
	{
		inst = this;
		LoadSettings();
	}

	public void SaveSettings()
	{
		Stream stream = new FileStream(Application.persistentDataPath + "/settings", FileMode.Create);
		SaveSerializer.SerializeToStream(new SettingsSaveData().Pack(this), stream);
		stream.Close();
		stream.Dispose();
	}

	private void LoadSettings()
	{
		if (File.Exists(Application.persistentDataPath + "/settings"))
		{
			Stream stream = null;
			try
			{
				stream = new FileStream(Application.persistentDataPath + "/settings", FileMode.Open);
				SaveSerializer.DeserializeFromStream<SettingsSaveData>(stream).Unpack(this);
				return;
			}
			catch (LegacyFormatException ex)
			{
				Debug.LogWarning("[Settings] " + ex.Message);
				SetToDefaults();
				return;
			}
			catch
			{
				SetToDefaults();
				throw;
			}
			finally
			{
				if (stream != null)
				{
					stream.Close();
					stream.Dispose();
				}
			}
		}
		SetToDefaults();
	}

	public void OnModifiedKeybind(int id, ConfigurableControls.KeyChord keyChord)
	{
		ConfigurableControls.Keybind keyAction = ConfigurableControls.inst.GetKeyAction(id);
		keyAction.keychord = keyChord;
		if (keyAction.itemUI != null)
		{
			keyAction.itemUI.input.SetTextWithoutNotify(keyAction.ToString());
		}
		onKeybindChanged?.Invoke(keyAction.id, keyAction);
		if (ConfigurableControls.inst.GetOriginalKeybind(id) == keyChord)
		{
			modifiedKeybinds.Remove(id);
		}
		else if (modifiedKeybinds.ContainsKey(id))
		{
			modifiedKeybinds[id] = keyChord;
		}
		else
		{
			modifiedKeybinds.Add(id, keyChord);
		}
	}

	private void SetToDefaults()
	{
		SetDefaultPreferences();
		SetDefaultGraphics();
	}

	public void SetDefaultPreferences()
	{
		MasterMusicVolume = 0.5f;
		MasterSfxVolume = 1f;
		MasterAmbientVolume = 1f;
		InvertZoom = true;
		EdgeScroll = false;
		ConsoleControls = false;
		PauseOnLoseFocus = false;
		MuteOnLoseFocus = false;
		MaxPanningSpeed = 0.5f;
		ZoomSpeed = 0.5f;
		UIScale = (GameUI.IsOnConsole() ? 1f : 0.5f);
	}

	public void SetDefaultGraphics()
	{
		ShowClouds = true;
		SSAO = true;
		PostEffects = true;
		Shadows = true;
		Waves = true;
		Birds = true;
		AntiAliasing = true;
		VSync = true;
		Fog = true;
		FogDistance = 0f;
	}
}
