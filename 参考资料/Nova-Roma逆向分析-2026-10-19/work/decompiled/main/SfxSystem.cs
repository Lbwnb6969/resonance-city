using Assets;
using FMOD.Studio;
using FMODUnity;
using UnityEngine;

public class SfxSystem : MonoBehaviour
{
	public static SfxSystem inst;

	public VCA VolumeSFX;

	public VCA VolumeMusic;

	public VCA VolumeAmbient;

	private float UI_3D_DISTANCE = 1f;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		VolumeMusic = RuntimeManager.GetVCA("vca:/MusicVCA");
		VolumeSFX = RuntimeManager.GetVCA("vca:/SFXVCA");
		VolumeAmbient = RuntimeManager.GetVCA("vca:/AmbienceVCA");
	}

	public EventInstance PlayFromBank(string groupName, Vector3 position)
	{
		try
		{
			EventInstance result = RuntimeManager.CreateInstance("event:/OldSFX/" + groupName);
			result.set3DAttributes(position.To3DAttributes());
			result.start();
			return result;
		}
		catch
		{
			Debug.LogError("Missing event:/OldSFX/" + groupName);
			return default;
		}
	}

	public EventInstance PlayFromBankIfVisible(string groupName, Vector3 position)
	{
		return PlayFromBank(groupName, position);
	}

	public void PlayFromBankOneShot(string groupName, Vector3 position)
	{
		RuntimeManager.PlayOneShot("event:/OldSFX/" + groupName, position);
	}

	public void PlayFromBank3DUIOneShot(string groupName, Vector3 position)
	{
		Vector3 pos = GUICamera.inst.cam.WorldToViewportPoint(position);
		RuntimeManager.PlayOneShot(groupName, Cam.inst.cam.ViewportPointToRay(pos).GetPoint(UI_3D_DISTANCE));
	}

	public void PlayFromBankIfVisibleOneShot(string groupName, Vector3 position)
	{
		if (FogOfWar.inst.IsVisible(position) && Mathff.DistSqrd(Cam.inst.CamPos, position) < 3600f)
		{
			PlayFromBankOneShot(groupName, position);
		}
	}

	public void OnApplicationFocus(bool focus)
	{
		if (!focus && Assets.Settings.inst.MuteOnLoseFocus)
		{
			RuntimeManager.MuteAllEvents(muted: true);
		}
		if (focus)
		{
			RuntimeManager.MuteAllEvents(muted: false);
		}
	}

	private void Update()
	{
		if (!(Assets.Settings.inst == null))
		{
			VolumeSFX.setVolume(Assets.Settings.inst.MasterSfxVolume);
			float volume = Assets.Settings.inst.MasterMusicVolume * 0.5f;
			VolumeMusic.setVolume(volume);
			VolumeAmbient.setVolume(Assets.Settings.inst.MasterAmbientVolume);
		}
	}

	public static void PlayUiSelect()
	{
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_SelectFromMenu_01");
	}

	public static void PlayUiCancel()
	{
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_Cancel_01");
	}

	public static void PlayUiBack()
	{
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_Cancel_01");
	}

	public static void PlayUiOpen()
	{
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_Menu Open_01");
	}

	public static void PlayUiClose()
	{
		RuntimeManager.PlayOneShot("event:/SFX/Menu/SFX_NR_UI_Cancel_01");
	}

	public static EventInstance SFXTestSound()
	{
		EventInstance result = RuntimeManager.CreateInstance("event:/SFX/Menu/SFX_NR_UI_Cancel_01");
		result.start();
		result.release();
		return result;
	}

	public void Reset()
	{
	}
}
