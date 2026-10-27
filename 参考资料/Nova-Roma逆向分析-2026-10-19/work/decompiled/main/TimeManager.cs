using System;
using Assets;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using UnityEngine;

public class TimeManager : MonoBehaviour
{
	public static TimeManager inst;

	private bool isLocked;

	private bool onUnlockDoPrevious;

	[NonSerialized]
	public int lastSpeedInUse = 1;

	[NonSerialized]
	public int speedInUse;

	public float[] playSpeeds = new float[5] { 0f, 0.85f, 1.2f, 2f, 10f };

	private EventInstance handle;

	[NonSerialized]
	public bool skipNextSfx;

	public bool IsLocked()
	{
		return isLocked;
	}

	public void SetLocked(bool val)
	{
		if (val != isLocked)
		{
			isLocked = val;
			if (val)
			{
				onUnlockDoPrevious = speedInUse != 0;
				SetSpeed(0);
			}
			else if (onUnlockDoPrevious)
			{
				ReturnToPrevious(skipSfx: true);
			}
		}
	}

	public float GetTimeScale()
	{
		return playSpeeds[speedInUse];
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		SetSpeed(1, skipSfx: true);
	}

	public float GetSpeedUpPercent()
	{
		return playSpeeds[speedInUse] / playSpeeds[1];
	}

	public void ReturnToPlaySpeed(bool skipSfx = false)
	{
		SetPlay1(skipSfx);
	}

	public void ReturnToPrevious(bool skipSfx = false)
	{
		SetSpeed(lastSpeedInUse, skipSfx);
	}

	public bool IsPaused()
	{
		return speedInUse == 0;
	}

	public void SetSpeed(int idx, bool skipSfx = false)
	{
		if (idx == 0)
		{
			SetPaused(skipSfx);
		}
		else if (idx == 1)
		{
			SetPlay1(skipSfx);
		}
		else if (idx == 2)
		{
			SetPlay2(skipSfx);
		}
		else if (idx == 3)
		{
			SetPlay3(skipSfx);
		}
		else if (idx >= 4)
		{
			SetPlay4(skipSfx);
		}
	}

	private void SetSpeed(int idx)
	{
		if (isLocked)
		{
			idx = 0;
		}
		Time.timeScale = playSpeeds[idx];
		if (speedInUse != 0)
		{
			lastSpeedInUse = speedInUse;
		}
		speedInUse = idx;
		SpeedControlUI.inst.SetSpeedVisuals(speedInUse);
		ClothTimescaleFix.CheckCloth();
	}

	private bool TrySetSpeed(int idx)
	{
		if (idx != speedInUse && idx >= 0 && idx < playSpeeds.Length)
		{
			SetSpeed(idx);
			return true;
		}
		return false;
	}

	private void StopPreviousSfx()
	{
		if (handle.isValid() && handle.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			handle.stop(STOP_MODE.IMMEDIATE);
		}
	}

	public void SetPaused(bool skipSfx = false)
	{
		if (TrySetSpeed(0))
		{
			StopPreviousSfx();
			if (!skipSfx)
			{
				RuntimeManager.StudioSystem.setParameterByName("parameter:/TimeSpeed", 0f);
				handle = RuntimeManager.CreateInstance("event:/SFX ASITP/UI/ui_time_move");
				handle.start();
			}
		}
		skipNextSfx = false;
	}

	public void PauseIfRaidInProgress()
	{
		if (RaiderSystem.inst.IsRaidInProgress())
		{
			SetPaused(skipSfx: true);
		}
	}

	public void SetPlay1(bool skipSfx = false)
	{
		if (TrySetSpeed(1))
		{
			StopPreviousSfx();
			if (!skipSfx)
			{
				RuntimeManager.StudioSystem.setParameterByName("parameter:/TimeSpeed", 1f);
				handle = RuntimeManager.CreateInstance("event:/SFX ASITP/UI/ui_time_move");
				handle.start();
			}
		}
	}

	public void SetPlay2(bool skipSfx = false)
	{
		if (TrySetSpeed(2))
		{
			StopPreviousSfx();
			if (!skipSfx)
			{
				RuntimeManager.StudioSystem.setParameterByName("parameter:/TimeSpeed", 2f);
				handle = RuntimeManager.CreateInstance("event:/SFX ASITP/UI/ui_time_move");
				handle.start();
			}
		}
	}

	public void SetPlay3(bool skipSfx = false)
	{
		if (TrySetSpeed(3))
		{
			StopPreviousSfx();
			if (!skipSfx)
			{
				RuntimeManager.StudioSystem.setParameterByName("parameter:/TimeSpeed", 3f);
				handle = RuntimeManager.CreateInstance("event:/SFX ASITP/UI/ui_time_move");
				handle.start();
			}
		}
	}

	public void SetPlay4(bool skipSfx = false)
	{
		if (TrySetSpeed(4))
		{
			StopPreviousSfx();
			if (!skipSfx)
			{
				RuntimeManager.StudioSystem.setParameterByName("parameter:/TimeSpeed", 3f);
				handle = RuntimeManager.CreateInstance("event:/SFX ASITP/UI/ui_time_move");
				handle.start();
			}
		}
	}

	public void OnApplicationFocus(bool focus)
	{
		if (!focus && GameState.inst.CurrMode == GameState.inst.playingMode && Assets.Settings.inst.PauseOnLoseFocus)
		{
			SetPaused(skipSfx: true);
		}
	}
}
