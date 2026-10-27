using System;
using System.Collections;
using AOT;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using UnityEngine;

public class MusicSystem : MonoBehaviour
{
	public delegate void OnComplete();

	public static MusicSystem inst;

	private EventInstance introMusic;

	private EventInstance currentMusic;

	private EventInstance attackerMusic;

	private EventInstance dragonMusic;

	private PARAMETER_ID winterParam;

	private Coroutine coroutine;

	private EventInstance eMusic;

	private int currPlaying = -1;

	private string currPath = string.Empty;

	public const int MUSIC_NONE = -1;

	public const int MUSIC_INTRO = 0;

	public const int MUSIC_SEASON = 1;

	public const int MUSIC_DAM_PLANNER = 2;

	public const int MUSIC_MOTIF_AQUEDUCT = 3;

	public const int MUSIC_INVASION = 4;

	public const int MUSIC_GODS = 5;

	public const int MUSIC_MOTIF_MILESTONES = 6;

	public OnComplete onComplete;

	public static bool isMusicComplete;

	private bool firstUpdate = true;

	private float winterFade;

	private bool wasLoading;

	private bool vikingsAttacking;

	private bool dragonAttacking;

	private void Awake()
	{
		inst = this;
		LoadSave.onLoadFinished = (LoadSave.OnLoadFinished)Delegate.Combine(LoadSave.onLoadFinished, (LoadSave.OnLoadFinished)((string s) =>
		{
			StartDefaultMusic();
		}));
		LoadSave.onLoadStart = (LoadSave.OnLoadFinished)Delegate.Combine(LoadSave.onLoadStart, (LoadSave.OnLoadFinished)((string s) =>
		{
			StopMusic();
		}));
		Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyTreeUnlock);
		RuntimeManager.StudioSystem.getParameterDescriptionByName("parameter:/_Winter", out var parameter);
		winterParam = parameter.id;
	}

	public void Init()
	{
		Broadcast.SeasonEvent.Listen(OnNewSeason);
	}

	private void ClearPrevious()
	{
		if (coroutine != null)
		{
			StopCoroutine(coroutine);
		}
		coroutine = null;
		onComplete = null;
		isMusicComplete = false;
		currPlaying = -1;
	}

	public void StartDamPlannerMusic()
	{
		ClearPrevious();
		coroutine = StartCoroutine(TransitionTo(2, "event:/Music/Music_DamPlanner"));
	}

	private void StartSeasonMusic()
	{
		if (!(GameState.inst.CurrMode != GameState.inst.playingMode) && !GameUI.inst.IsChariotRaceModeActive() && !GameUI.inst.IsColosseumFightModeActive())
		{
			ClearPrevious();
			string arg = "";
			switch (SeasonManager.GetCurrentSeason().id)
			{
			case 2:
				arg = "Winter";
				break;
			case 0:
				arg = "Summer";
				break;
			case 3:
				arg = "Spring";
				break;
			case 1:
				arg = "Autumn";
				break;
			}
			coroutine = StartCoroutine(TransitionTo(1, $"event:/Music/Music_{arg}{CalculateCityStage()}"));
		}
	}

	private void TryStartNextSeasonTrack()
	{
		if ((currPlaying == 1 || currPlaying == -1) && IsInstanceStopped())
		{
			StartSeasonMusic();
		}
	}

	public void StartDefaultMusic()
	{
		if (RaiderSystem.inst.IsRaidInProgress())
		{
			if (currPlaying != 4)
			{
				if (RaiderSystem.inst.prevTotalPoints >= 50f)
				{
					StartSmallInvasionMusic();
				}
				else
				{
					StartLargeInvasionMusic();
				}
			}
		}
		else
		{
			StartSeasonMusic();
		}
	}

	public void StartSmallInvasionMusic()
	{
		ClearPrevious();
		coroutine = StartCoroutine(TransitionTo(4, "event:/Music/Music_Invasion_Small"));
	}

	public void StartLargeInvasionMusic()
	{
		ClearPrevious();
		coroutine = StartCoroutine(TransitionTo(4, "event:/Music/Music_Invasion_Large"));
	}

	public void StartMainMenuMusic()
	{
		ClearPrevious();
		coroutine = StartCoroutine(TransitionTo(0, "event:/Music/Music_Intro"));
	}

	public void StartSettleLandMusic()
	{
		ClearPrevious();
		coroutine = StartCoroutine(TransitionTo(3, "event:/Music/Music_Motif_StartJourney", OnCompleteCallback));
		onComplete = StartDefaultMusic;
	}

	public void StartAqueductMusic()
	{
		ClearPrevious();
		coroutine = StartCoroutine(TransitionTo(3, "event:/Music/Music_Motif_Aqueduct", OnCompleteCallback));
		onComplete = StartDefaultMusic;
	}

	public void StartMilestoneMusic()
	{
		ClearPrevious();
		coroutine = StartCoroutine(TransitionTo(6, "event:/OldSFX/LevelUp", OnCompleteCallback));
		onComplete = StartDefaultMusic;
	}

	public void StartGodMusic()
	{
		ClearPrevious();
		coroutine = StartCoroutine(TransitionTo(5, "event:/Music/Music_Gods"));
	}

	[MonoPInvokeCallback(typeof(EVENT_CALLBACK))]
	public static RESULT OnCompleteCallback(EVENT_CALLBACK_TYPE eType, IntPtr eventPtr, IntPtr paramPtr)
	{
		if (eType == EVENT_CALLBACK_TYPE.STOPPED)
		{
			isMusicComplete = true;
		}
		return RESULT.OK;
	}

	public IEnumerator TransitionTo(int id, string eName, EVENT_CALLBACK callback = null)
	{
		if (currPlaying == id && currPath == eName)
		{
			UnityEngine.Debug.Log($"Already Playing {id} {eName}. Skipping...");
			yield break;
		}
		currPlaying = -1;
		if (eMusic.isValid())
		{
			eMusic.stop(STOP_MODE.ALLOWFADEOUT);
			RESULT playbackState = eMusic.getPlaybackState(out var state);
			if ((playbackState == RESULT.OK || playbackState == RESULT.ERR_INVALID_HANDLE) && state != PLAYBACK_STATE.STOPPED)
			{
				while (!IsInstanceStopped())
				{
					yield return null;
				}
			}
		}
		eMusic = RuntimeManager.CreateInstance(eName);
		eMusic.start();
		eMusic.release();
		if (callback != null)
		{
			eMusic.setCallback(callback, EVENT_CALLBACK_TYPE.STOPPED);
		}
		currPlaying = id;
		currPath = eName;
	}

	public void StopMusic()
	{
		ClearPrevious();
		if (eMusic.isValid())
		{
			eMusic.stop(STOP_MODE.ALLOWFADEOUT);
		}
		currPath = string.Empty;
	}

	public bool IsInstanceStopped()
	{
		if (eMusic.isValid())
		{
			RESULT playbackState = eMusic.getPlaybackState(out var state);
			if ((playbackState != RESULT.OK && playbackState != RESULT.ERR_INVALID_HANDLE) || state != PLAYBACK_STATE.STOPPED)
			{
				return false;
			}
		}
		return true;
	}

	private void OnTechnologyTreeUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		if (data.unlocked && !LoadSave.Loading)
		{
			RuntimeManager.PlayOneShot("event:/Music/Music_Motif_Advancement");
		}
	}

	public void OnNewSeason(object sender, SeasonEventData data)
	{
		TryStartNextSeasonTrack();
	}

	private void Update()
	{
		if (!(GameState.inst == null))
		{
			if (onComplete != null && isMusicComplete)
			{
				onComplete();
				onComplete = null;
				isMusicComplete = false;
			}
			winterFade = Mathff.Clamp01(winterFade + (float)((SeasonManager.inst.CurrentSeason.id == 2) ? 1 : (-1)) * Time.unscaledDeltaTime * 0.33f);
			RuntimeManager.StudioSystem.setParameterByID(winterParam, winterFade);
			if (currPlaying == 4 && !RaiderSystem.inst.IsRaidInProgress())
			{
				StartDefaultMusic();
			}
			if (Input.GetKeyDown(KeyCode.End))
			{
				StopMusic();
			}
		}
	}

	public int CalculateCityStage()
	{
		int num = 1;
		int val = 1;
		int num2 = Player.inst.PlayerOwnerWorkersCount();
		num = ((num2 < 50) ? 1 : ((num2 >= 300) ? 2 : 2));
		if (SRand.Range(0, 3) == 0)
		{
			num = Math.Max(val, num - 1);
		}
		return num;
	}

	public void StartVikingMusic()
	{
		attackerMusic.getPlaybackState(out var state);
		if (state != PLAYBACK_STATE.PLAYING)
		{
			attackerMusic.start();
		}
	}

	public void StopVikingMusic()
	{
		attackerMusic.stop(STOP_MODE.ALLOWFADEOUT);
	}

	public void StartDragonMusic()
	{
		dragonMusic.getPlaybackState(out var state);
		if (state != PLAYBACK_STATE.PLAYING)
		{
			dragonMusic.start();
		}
	}

	public void StopDragonMusic()
	{
		dragonMusic.stop(STOP_MODE.ALLOWFADEOUT);
	}

	public void Reset()
	{
	}

	public void PlayLevelUpMotif()
	{
	}

	public void PlayCreditsMusic()
	{
	}

	public void PlayGameOverMusic()
	{
	}
}
