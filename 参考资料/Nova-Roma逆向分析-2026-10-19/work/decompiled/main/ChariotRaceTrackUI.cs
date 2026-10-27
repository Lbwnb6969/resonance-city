using System;
using System.Collections;
using System.Collections.Generic;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class ChariotRaceTrackUI : MonoBehaviour
{
	private enum BetState
	{
		PickCharioteer,
		WaitingForRaceStart
	}

	public static ChariotRaceTrackUI inst;

	[SerializeField]
	private ChariotRaceTrackEntryUI entryPrefab;

	[SerializeField]
	private ChariotRaceTrackContestantPositionUI positionPrefab;

	[SerializeField]
	private RectTransform layoutPrefab;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private GameObject betWindowObj;

	[SerializeField]
	private GameObject pickRacerWindowObj;

	[SerializeField]
	private GameObject racerWindowObj;

	[SerializeField]
	private GameObject winnerHighlightObj;

	[SerializeField]
	private RectTransform winnerRectT;

	[SerializeField]
	private TextMeshProUGUI winnerAmountTMP;

	[SerializeField]
	private TextMeshProUGUI winnerNameTMP;

	[SerializeField]
	private TextMeshProUGUI winnerOddsMP;

	[SerializeField]
	private TextMeshProUGUI titleTMP;

	[SerializeField]
	private TextMeshProUGUI subTitleTMP;

	[SerializeField]
	private Button winnerContinueBtn;

	[SerializeField]
	private float winAnimSpeed = 2f;

	private float winAnimTime;

	private bool doWinAnim;

	[SerializeField]
	private GameObject aboutToStartRaceObj;

	[SerializeField]
	private ToggleGroup toggleGroup;

	[SerializeField]
	private Transform competitorContainer;

	private int currSelectedIdx = -1;

	[SerializeField]
	private Button cancelBtn;

	[SerializeField]
	private TooltipHook selectCompetitorTooltip;

	[SerializeField]
	private TextMeshProUGUI payoutTMP;

	[SerializeField]
	private TextMeshProUGUI lapTMP;

	[SerializeField]
	private TextMeshProUGUI raceEarningsTMP;

	[SerializeField]
	private RectTransform raceEarningsRectT;

	[SerializeField]
	private TextMeshProUGUI raceBetTMP;

	[SerializeField]
	private Image raceSponsorCharioteerIcon;

	[SerializeField]
	private TextMeshProUGUI racePotentialEarningsTMP;

	[SerializeField]
	private Button skipRaceBtn;

	[SerializeField]
	private Image fadeBackground;

	[SerializeField]
	private float raceBounceTime = 1.5f;

	[SerializeField]
	private float raceBounceClimb = 1.5f;

	[SerializeField]
	private float raceHideTime = 1.5f;

	[SerializeField]
	private RectTransform layoutContainer;

	[SerializeField]
	private RectTransform contentContainer;

	private bool isVisible;

	private ChariotRaceTrack raceTrack;

	private ArrayExt<ChariotRaceTrackEntryUI> entries = new ArrayExt<ChariotRaceTrackEntryUI>(8);

	private ArrayExt<RectTransform> layoutItems = new ArrayExt<RectTransform>(8);

	private ArrayExt<ChariotRaceTrackContestantPositionUI> positionItems = new ArrayExt<ChariotRaceTrackContestantPositionUI>(8);

	private bool doInstantAnim;

	public float animSpeed = 1f;

	private float currTimeToStartRace;

	private const float TIME_TO_START_RACE = 3f;

	private BetState currBetState;

	private int status = 2;

	public const int STATUS_BETTING = 0;

	public const int STATUS_RACING = 1;

	public const int STATUS_SHUTDOWN = 2;

	public const int STATUS_WINNER = 3;

	private int currCamType = -1;

	private const int CAM_NONE = -1;

	private const int CAM_DEFAULT = 0;

	private const int CAM_GATE = 1;

	private const int CAM_FINISH = 2;

	private const int CAM_TRACK_FIRST_HIGH = 3;

	private const int CAM_TRACK_FIRST_LOW = 4;

	private const int CAM_GATE_PAN = 5;

	private const int CAM_GATE_TRACK = 6;

	private Quaternion camRot;

	private Quaternion camDesiredRot;

	[SerializeField]
	private float camRotSpeed = 1f;

	[SerializeField]
	private float camGateRotSpeed = 3f;

	[SerializeField]
	private Vector3 highCamTrackOffset;

	[SerializeField]
	private Vector3 lowCamTrackOffset;

	[SerializeField]
	private float camHighTrackSpeed = 1f;

	[SerializeField]
	private float camHighDistSpeedMultiplier = 1f;

	[SerializeField]
	private Vector3 focusCamOffset;

	[SerializeField]
	private float focusCamSpeed = 1f;

	[SerializeField]
	private float focusCamRotateSpeed = 1f;

	[SerializeField]
	private float focusHeightAdjust = -0.5f;

	[SerializeField]
	public AnimationCurve horseSelectCurve;

	[SerializeField]
	public float horseAnimAngle = 45f;

	[SerializeField]
	public float horseAnimSpeed = 1f;

	private float horseAnimTime = 1f;

	private Vector3 camPos;

	private Vector3 camDesiredPos;

	private int currHighlightIdx = -1;

	private Timer positionUpdate = new Timer(5f);

	private EventInstance eMusic;

	private EventInstance eAmbRace;

	private ArrayExt<ChariotRaceTrack.Charioteer> orderedByPosition = new ArrayExt<ChariotRaceTrack.Charioteer>(8);

	private Coroutine transitionToLow;

	private Coroutine fadeToEndCoroutine;

	public bool IsVisible()
	{
		return isVisible;
	}

	private void SetVisible(bool v)
	{
		if (!isVisible & v)
		{
			RuntimeManager.PlayOneShot("event:/SFX ASITP/Ambiences/ambScatter_crowdReact_cheer", raceTrack.b.Center());
			eMusic = RuntimeManager.CreateInstance("event:/SFX ASITP/sfx_chariot_race_music");
			eAmbRace = RuntimeManager.CreateInstance("event:/SFX ASITP/sfx_chariot_race_amb");
			MusicSystem.inst.StopMusic();
			BespokeCelebratingCitizens.inst.Init(raceTrack.b);
		}
		else if (isVisible && !v)
		{
			PLAYBACK_STATE state;
			if (eMusic.isValid())
			{
				if (eMusic.getPlaybackState(out state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
				{
					eMusic.stop(STOP_MODE.IMMEDIATE);
				}
				eMusic.release();
			}
			if (eAmbRace.isValid())
			{
				if (eAmbRace.getPlaybackState(out state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
				{
					eAmbRace.stop(STOP_MODE.IMMEDIATE);
				}
				eAmbRace.release();
			}
			BespokeCelebratingCitizens.inst.Shutdown();
		}
		isVisible = v;
		Util.SetEnabled(canvas, isVisible);
		Util.SetEnabled(gRaycaster, isVisible);
	}

	public bool IsThisTrackRacing(ChariotRaceTrack track)
	{
		if (track == null || raceTrack == null)
		{
			return false;
		}
		return raceTrack == track;
	}

	public int GetStatus()
	{
		return status;
	}

	public bool DoShowResources()
	{
		if (status != 2)
		{
			return status == 0;
		}
		return true;
	}

	public void SetStatus(int s)
	{
		SetVisible(s != 2);
		Util.SetActive(betWindowObj, s == 0);
		Util.SetActive(racerWindowObj, s == 1 || s == 3);
		Util.SetActive(aboutToStartRaceObj, active: false);
		Util.SetActive(winnerRectT.gameObject, active: false);
		Util.SetActive(winnerHighlightObj, active: false);
		GameUI.SetUIForModalHelper(s == 2 && status != s);
		if (status == 2 && s != status)
		{
			Cam.inst.enabled = false;
		}
		else if (status != 2 && s == 2)
		{
			SetCameraType(-1);
			Cam.inst.enabled = true;
		}
		switch (s)
		{
		case 0:
			Cinematics.inst.ShowBars(show: false);
			if (eAmbRace.isValid())
			{
				eAmbRace.stop(STOP_MODE.IMMEDIATE);
			}
			SetBetState(BetState.PickCharioteer);
			raceTrack.SetStatus(ChariotRaceTrack.Status.Resting);
			currSelectedIdx = -1;
			currHighlightIdx = -1;
			RefreshVisuals();
			break;
		case 1:
		{
			Util.SetActive(skipRaceBtn.gameObject, active: false);
			Cinematics.inst.ShowBars(show: true);
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_horseRace_gateOpen", raceTrack.startingPositions[1].position);
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_chariotrace_start_horn", raceTrack.startingPositions[1].position);
			eMusic.start();
			eAmbRace.start();
			SetCameraType(6);
			LayoutRebuilder.ForceRebuildLayoutImmediate(racerWindowObj.GetComponent<RectTransform>());
			for (int i = 0; i < positionItems.Count; i++)
			{
				ChariotRaceTrack.Charioteer charitoeerAtTrackIdx2 = GetCharitoeerAtTrackIdx(i, out var _);
				ChariotRaceTrackContestantPositionUI obj = positionItems.data[i];
				RectTransform rectTransform = layoutItems.data[i];
				ChariotRaceTrackEntryUI chariotRaceTrackEntryUI = entries.data[i];
				Util.SetEnabled(obj.isBetTarget, i == currSelectedIdx);
				rectTransform.SetSiblingIndex(charitoeerAtTrackIdx2.trackIdx);
				doInstantAnim = true;
				obj.nameTMP.text = charitoeerAtTrackIdx2.profile.Name;
				obj.oddsTMP.text = chariotRaceTrackEntryUI.oddsTMP.text;
				obj.icon.sprite = raceTrack.modelPool[charitoeerAtTrackIdx2.modelPoolIdx].icon;
			}
			ChariotRaceTrack.Charioteer charitoeerAtTrackIdx3 = GetCharitoeerAtTrackIdx(currSelectedIdx, out var _);
			raceSponsorCharioteerIcon.sprite = raceTrack.modelPool[charitoeerAtTrackIdx3.modelPoolIdx].icon;
			raceEarningsTMP.text = LocalizationManager.GetTranslation("chariotraceui_reward_colon") + $" {charitoeerAtTrackIdx3.chance.rewardAmt} <sprite name=icon_prosperity>";
			break;
		}
		case 3:
		{
			RuntimeManager.PlayOneShot("event:/SFX ASITP/Ambiences/ambScatter_crowdReact_raceEnd", raceTrack.b.Center());
			Util.SetActive(skipRaceBtn.gameObject, active: false);
			ChariotRaceTrack.Charioteer charitoeerAtTrackIdx = GetCharitoeerAtTrackIdx(currSelectedIdx, out var _);
			string translation = LocalizationManager.GetTranslation("chariotraceui_reward_colon");
			raceTrack.b.GetLandMassOwner().Gold -= charitoeerAtTrackIdx.chance.goldCost;
			if (charitoeerAtTrackIdx.predictedFinishPos == 0)
			{
				Player.inst.GiveProsperityPoints(charitoeerAtTrackIdx.chance.rewardAmt);
				translation += $"<color=green> {charitoeerAtTrackIdx.chance.rewardAmt} <sprite name=icon_prosperity>";
			}
			else
			{
				translation += "<color=red> 0 <sprite name=icon_prosperity>";
			}
			raceEarningsTMP.text = translation;
			Util.SetEnabled(raceEarningsTMP, active: true);
			break;
		}
		}
		status = s;
	}

	private void SetBetState(BetState state)
	{
		switch (state)
		{
		case BetState.WaitingForRaceStart:
			SetCameraType(5);
			currTimeToStartRace = 0f;
			horseAnimTime = 0f;
			Util.SetEnabled(subTitleTMP, active: false);
			break;
		case BetState.PickCharioteer:
			SetCameraType(1);
			if (currSelectedIdx != -1)
			{
				ChariotRaceTrack.Charioteer charitoeerAtTrackIdx = GetCharitoeerAtTrackIdx(currSelectedIdx, out var _);
				ChariotRaceTrack.ModelData modelData = raceTrack.modelPool[charitoeerAtTrackIdx.modelPoolIdx];
				for (int i = 0; i < modelData.horses.Length; i++)
				{
					modelData.horses[i].localRotation = Quaternion.identity;
				}
			}
			currSelectedIdx = -1;
			currHighlightIdx = -1;
			titleTMP.text = LocalizationManager.GetTranslation("chariotraceui_pickteamsponsor_title");
			Util.SetEnabled(subTitleTMP, active: true);
			break;
		}
		Util.SetActive(pickRacerWindowObj, state == BetState.PickCharioteer);
		Util.SetActive(aboutToStartRaceObj, state == BetState.WaitingForRaceStart);
		currBetState = state;
	}

	private void Awake()
	{
		inst = this;
		cancelBtn.onClick.AddListener(() =>
		{
			SetBetState(BetState.PickCharioteer);
		});
		winnerContinueBtn.onClick.AddListener(() =>
		{
			SetStatus(0);
			AutoSave.inst.RunAutoSave();
		});
		skipRaceBtn.onClick.AddListener(() =>
		{
			fadeToEndCoroutine = StartCoroutine(SkipFadeToEndOfRace());
		});
	}

	private void Start()
	{
		canvas.worldCamera = GUICamera.inst.cam;
		SetVisible(v: false);
	}

	public void Init(ChariotRaceTrack track)
	{
		raceTrack = track;
		ChariotRaceTrack chariotRaceTrack = raceTrack;
		chariotRaceTrack.onStatusChange = (ChariotRaceTrack.OnStatusChange)Delegate.Combine(chariotRaceTrack.onStatusChange, new ChariotRaceTrack.OnStatusChange(OnRaceTrackStatusChange));
		raceTrack.SetStatus(ChariotRaceTrack.Status.Resting);
	}

	public void Shutdown()
	{
		if (eMusic.isValid() && eMusic.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			eMusic.stop(STOP_MODE.IMMEDIATE);
			eMusic.release();
		}
		if (eAmbRace.isValid() && eAmbRace.getPlaybackState(out state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			eAmbRace.stop(STOP_MODE.IMMEDIATE);
			eAmbRace.release();
		}
		raceTrack.SetStatus(ChariotRaceTrack.Status.Resting);
		raceTrack = null;
		SetStatus(2);
		if (transitionToLow != null)
		{
			StopCoroutine(transitionToLow);
		}
		if (fadeToEndCoroutine != null)
		{
			StopCoroutine(fadeToEndCoroutine);
		}
		Util.SetEnabled(fadeBackground, active: false);
	}

	private void Update()
	{
		if (status == 2)
		{
			return;
		}
		raceTrack.b.GetLandMassOwner();
		if (status == 0)
		{
			if (currBetState == BetState.PickCharioteer)
			{
				if (currHighlightIdx != -1)
				{
					ChariotRaceTrack.Charioteer charitoeerAtTrackIdx = GetCharitoeerAtTrackIdx(currHighlightIdx, out var _);
					raceTrack.modelPool[charitoeerAtTrackIdx.modelPoolIdx].highlighter.SetOutlineImmediate(0);
					float num = charitoeerAtTrackIdx.chance.weight + (float)Mathf.FloorToInt((1f - charitoeerAtTrackIdx.chance.weight) / 4f / 0.05f) * 0.05f;
					float num2 = 1f - num;
					float num3 = 0f;
					for (int i = 0; i < raceTrack.charioteers.Count; i++)
					{
						ChariotRaceTrack.Charioteer charioteer = raceTrack.charioteers[i];
						if (charioteer.trackIdx != currHighlightIdx)
						{
							num3 += charioteer.chance.weight;
						}
					}
					for (int j = 0; j < raceTrack.charioteers.Count; j++)
					{
						ChariotRaceTrack.Charioteer charioteer2 = raceTrack.charioteers[j];
						ChariotRaceTrackEntryUI chariotRaceTrackEntryUI = entries.data[charioteer2.trackIdx];
						if (charioteer2.trackIdx == currHighlightIdx)
						{
							chariotRaceTrackEntryUI.oddsTMP.text = string.Format(LocalizationManager.GetTranslation("chariotraceui_chancetowin"), $"<color=green>{Mathf.RoundToInt(num * 100f)}%</color>");
							continue;
						}
						float num4 = charioteer2.chance.weight / num3 * num2;
						chariotRaceTrackEntryUI.oddsTMP.text = string.Format(LocalizationManager.GetTranslation("chariotraceui_chancetowin"), Mathf.RoundToInt(num4 * 100f) + "%");
					}
				}
				else
				{
					for (int k = 0; k < raceTrack.charioteers.Count; k++)
					{
						ChariotRaceTrack.Charioteer charioteer3 = raceTrack.charioteers[k];
						entries.data[charioteer3.trackIdx].oddsTMP.text = string.Format(LocalizationManager.GetTranslation("chariotraceui_chancetowin"), charioteer3.chance.percent + "%");
					}
				}
			}
			if (currSelectedIdx != -1)
			{
				ChariotRaceTrack.Charioteer charitoeerAtTrackIdx2 = GetCharitoeerAtTrackIdx(currSelectedIdx, out var _);
				raceTrack.modelPool[charitoeerAtTrackIdx2.modelPoolIdx].highlighter.SetOutlineImmediate(1);
			}
			if (currBetState == BetState.WaitingForRaceStart)
			{
				currTimeToStartRace += Time.unscaledDeltaTime;
				titleTMP.text = string.Format(LocalizationManager.GetTranslation("chariotracetrackui_racestart_time_title"), (3f - currTimeToStartRace).ToString("0.0"));
				ChariotRaceTrack.Charioteer charitoeerAtTrackIdx3 = GetCharitoeerAtTrackIdx(currSelectedIdx, out var _);
				horseAnimTime += Time.unscaledDeltaTime * horseAnimSpeed;
				if (horseAnimTime < 1f)
				{
					float num5 = horseSelectCurve.Evaluate(horseAnimTime) * horseAnimAngle;
					ChariotRaceTrack.ModelData modelData = raceTrack.modelPool[charitoeerAtTrackIdx3.modelPoolIdx];
					for (int l = 0; l < modelData.horses.Length; l++)
					{
						modelData.horses[l].localRotation = Quaternion.AngleAxis(0f - num5, Vector3.right);
					}
				}
				else
				{
					ChariotRaceTrack.ModelData modelData2 = raceTrack.modelPool[charitoeerAtTrackIdx3.modelPoolIdx];
					for (int m = 0; m < modelData2.horses.Length; m++)
					{
						modelData2.horses[m].localRotation = Quaternion.identity;
					}
				}
				if (currTimeToStartRace >= 3f)
				{
					raceTrack.SetStatus(ChariotRaceTrack.Status.BetStartRace);
					SetStatus(1);
				}
				if (currCamType == 5)
				{
					Transform transform = raceTrack.camLocations[1];
					Vector3 input = transform.position;
					input.NonAllocateAdd(-transform.forward * 2f);
					camPos = (camDesiredPos = Mathff.MoveTowards(camPos, input, Time.unscaledDeltaTime * 0.25f));
					Cam.inst.transform.position = camPos;
				}
			}
			if (currCamType == 1)
			{
				if (currSelectedIdx == -1)
				{
					Transform transform2 = raceTrack.camLocations[1];
					camDesiredPos = transform2.position;
					camDesiredRot = Quaternion.LookRotation(transform2.forward);
				}
				else
				{
					ChariotRaceTrack.Charioteer charitoeerAtTrackIdx4 = GetCharitoeerAtTrackIdx(currSelectedIdx, out var _);
					Transform transform3 = raceTrack.startingPositions[charitoeerAtTrackIdx4.trackIdx];
					Vector3 vector = transform3.rotation * focusCamOffset;
					camDesiredPos = transform3.position + vector;
					camDesiredRot = Quaternion.LookRotation(transform3.position + new Vector3(0f, focusHeightAdjust, 0f) - camDesiredPos);
				}
				Cam.inst.cam.transform.position = (camPos = Vector3.Lerp(camPos, camDesiredPos, Time.unscaledDeltaTime * focusCamSpeed));
				Cam.inst.cam.transform.rotation = (camRot = Quaternion.Lerp(camRot, camDesiredRot, Time.unscaledDeltaTime * focusCamRotateSpeed));
			}
		}
		else
		{
			if (status != 1 && status != 3)
			{
				return;
			}
			lapTMP.text = string.Format(LocalizationManager.GetTranslation("chariotracetrackui_lap_description"), Mathf.CeilToInt(Mathff.Clamp01(raceTrack.raceTime / raceTrack.DesiredRaceDuration) * (float)raceTrack.trackSampleRatio), raceTrack.trackSampleRatio);
			int num6 = 0;
			Vector3 input2 = Vector3.zero;
			orderedByPosition.ClearFast();
			List<ChariotRaceTrack.Charioteer> charioteers = raceTrack.charioteers;
			for (int n = 0; n < charioteers.Count; n++)
			{
				ChariotRaceTrack.Charioteer charioteer4 = charioteers[n];
				if (!charioteer4.incident.isActive || !charioteer4.incident.hasCompleted)
				{
					input2.NonAllocateAdd(charioteer4.currentPos);
					num6++;
				}
				int num7 = 0;
				while (true)
				{
					if (num7 < orderedByPosition.Count)
					{
						if (!(orderedByPosition.data[num7].pathDist > charioteer4.pathDist))
						{
							orderedByPosition.Insert(num7, charioteer4);
							break;
						}
						num7++;
						continue;
					}
					orderedByPosition.Add(charioteer4);
					break;
				}
			}
			if (num6 == 0)
			{
				input2 = orderedByPosition.data[0].currentPos;
			}
			else
			{
				input2.NonAllocateDivide(num6);
			}
			for (int num8 = 0; num8 < orderedByPosition.Count; num8++)
			{
				ChariotRaceTrack.Charioteer charioteer5 = orderedByPosition.data[num8];
				charioteer5.currFinishPos = num8;
				RectTransform rectTransform = layoutItems.data[charioteer5.trackIdx];
				ChariotRaceTrackContestantPositionUI chariotRaceTrackContestantPositionUI = positionItems.data[charioteer5.trackIdx];
				if (raceTrack.raceTime >= 0.9f || positionUpdate.Update(Time.unscaledDeltaTime))
				{
					rectTransform.SetSiblingIndex(num8);
				}
				if (doInstantAnim)
				{
					doInstantAnim = false;
					chariotRaceTrackContestantPositionUI.transform.position = rectTransform.position;
				}
				else
				{
					Vector3 position = chariotRaceTrackContestantPositionUI.transform.position;
					position = Vector3.MoveTowards(position, rectTransform.position, Time.unscaledDeltaTime * animSpeed);
					chariotRaceTrackContestantPositionUI.transform.position = position;
				}
			}
			ChariotRaceTrack.Charioteer charitoeerAtTrackIdx5 = GetCharitoeerAtTrackIdx(currSelectedIdx, out var _);
			if (status == 1)
			{
				raceTrack.modelPool[charitoeerAtTrackIdx5.modelPoolIdx].highlighter.SetOutlineImmediate(1);
				if (raceTrack.raceTime >= raceTrack.DesiredRaceDuration * 0.9f)
				{
					Util.SetActive(skipRaceBtn.gameObject, active: false);
				}
			}
			if (status == 3 && doWinAnim)
			{
				winAnimTime = Mathff.Clamp01(winAnimTime + Time.unscaledDeltaTime * winAnimSpeed);
				float y = Mathff.Lerp(0f - winnerRectT.rect.size.y, 0f, winAnimTime * winAnimTime);
				Vector3 vector2 = winnerRectT.anchoredPosition;
				vector2.y = y;
				winnerRectT.anchoredPosition = vector2;
				if (winAnimTime >= 1f)
				{
					doWinAnim = false;
					winAnimTime = 0f;
					if (charitoeerAtTrackIdx5.currFinishPos == 0)
					{
						RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_favourGained");
					}
				}
			}
			if (raceTrack.GetStatus() == ChariotRaceTrack.Status.BetRacing && raceTrack.raceTime / raceTrack.DesiredRaceDuration * (float)raceTrack.trackSampleRatio >= 0.85f * (float)raceTrack.trackSampleRatio && currCamType != 2 && status == 1)
			{
				SetCameraType(2);
			}
			if (currCamType == 6)
			{
				camDesiredRot = Quaternion.LookRotation(charitoeerAtTrackIdx5.currentPos + charitoeerAtTrackIdx5.velocity.normalized * 1f - Cam.inst.transform.position);
				camRot = Quaternion.Lerp(camRot, camDesiredRot, Time.unscaledDeltaTime * camGateRotSpeed);
				Cam.inst.transform.rotation = camRot;
			}
			else if (currCamType == 2)
			{
				camDesiredRot = Quaternion.LookRotation(orderedByPosition.data[0].currentPos + orderedByPosition.data[0].velocity.normalized * 0.25f - Cam.inst.transform.position);
				camRot = Quaternion.Lerp(camRot, camDesiredRot, Time.unscaledDeltaTime * camGateRotSpeed);
				Cam.inst.transform.rotation = camRot;
			}
			else if (currCamType == 3 || currCamType == 4)
			{
				Vector3 vector3 = input2;
				if (currCamType == 4)
				{
					vector3 = orderedByPosition.data[0].currentPos;
				}
				Vector3 vector4 = raceTrack.b.GetOffset().rotation * ((currCamType == 3) ? highCamTrackOffset : lowCamTrackOffset);
				Vector3 vector5 = vector3 + vector4;
				Quaternion quaternion = Quaternion.LookRotation(vector3 - vector5);
				camDesiredPos = vector5;
				camDesiredRot = quaternion;
				float num9 = Mathf.Exp(Mathff.DistSqrdXZ(camPos, camDesiredPos));
				camPos = Vector3.Lerp(camPos, camDesiredPos, Time.unscaledDeltaTime * (camHighTrackSpeed * (num9 * camHighDistSpeedMultiplier)));
				camRot = Quaternion.Lerp(camRot, camDesiredRot, Time.unscaledDeltaTime * camRotSpeed);
				Cam.inst.transform.position = camPos;
				Cam.inst.transform.rotation = camRot;
			}
		}
	}

	private void RefreshVisuals()
	{
		List<ChariotRaceTrack.Charioteer> charioteers = raceTrack.charioteers;
		while (entries.Count < 4)
		{
			ChariotRaceTrackEntryUI chariotRaceTrackEntryUI = UnityEngine.Object.Instantiate(entryPrefab, competitorContainer);
			int idx = entries.Count;
			chariotRaceTrackEntryUI.sponsorBtn.onClick.AddListener(() =>
			{
				currSelectedIdx = idx;
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_horseRace_winnie", raceTrack.startingPositions[idx].position);
				ChariotRaceTrack.Charioteer charitoeerAtTrackIdx = GetCharitoeerAtTrackIdx(idx, out var _);
				ChariotRaceTrack.Chance chance = charitoeerAtTrackIdx.chance;
				chance.isSponsored = true;
				charitoeerAtTrackIdx.chance = chance;
				EffectsMan.inst.ChariotSponsorEffect.CreateAndPlay(charitoeerAtTrackIdx.currentPos);
				SetBetState(BetState.WaitingForRaceStart);
			});
			EventTrigger.Entry entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerEnter;
			entry.callback.AddListener((BaseEventData data) =>
			{
				currHighlightIdx = idx;
			});
			chariotRaceTrackEntryUI.eTrigger.triggers.Add(entry);
			entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerExit;
			entry.callback.AddListener((BaseEventData data) =>
			{
				if (currHighlightIdx == idx)
				{
					currHighlightIdx = -1;
				}
			});
			chariotRaceTrackEntryUI.eTrigger.triggers.Add(entry);
			Util.SetActive(chariotRaceTrackEntryUI.gameObject, active: false);
			entries.Add(chariotRaceTrackEntryUI);
			GameObject gameObject = UnityEngine.Object.Instantiate(layoutPrefab.gameObject, layoutContainer);
			layoutItems.Add(gameObject.GetComponent<RectTransform>());
			ChariotRaceTrackContestantPositionUI chariotRaceTrackContestantPositionUI = UnityEngine.Object.Instantiate(positionPrefab, contentContainer);
			positionItems.Add(chariotRaceTrackContestantPositionUI);
			chariotRaceTrackContestantPositionUI.transform.position = gameObject.transform.position;
		}
		LandmassOwner landMassOwner = raceTrack.b.GetLandMassOwner();
		for (int num = 0; num < charioteers.Count; num++)
		{
			ChariotRaceTrack.Charioteer charioteer = charioteers[num];
			ChariotRaceTrackEntryUI obj = entries.data[charioteer.trackIdx];
			obj.nameTMP.text = charioteer.profile.Name;
			obj.oddsTMP.text = string.Format(LocalizationManager.GetTranslation("chariotraceui_chancetowin"), charioteer.chance.percent + "%");
			obj.icon.sprite = raceTrack.modelPool[charioteer.modelPoolIdx].icon;
			obj.rewardTMP.text = LocalizationManager.GetTranslation("chariotraceui_pickcharioteer_reward") + Environment.NewLine + $"{charioteer.chance.rewardAmt} <sprite name=icon_prosperity>";
			int goldCost = charioteer.chance.goldCost;
			obj.sponserAmtTMP.text = $"{goldCost} <sprite name=icon_gold>";
			obj.sponsorBtn.interactable = landMassOwner.Gold >= goldCost;
			obj.sponsorTooltip.enabled = landMassOwner.Gold < goldCost;
			Util.SetActive(obj.gameObject, active: true);
			Util.SetEnabled(obj.icon, active: true);
		}
	}

	public void OnExitClicked()
	{
		GameUI.inst.ReturnToDefaultCursorMode();
	}

	public void OnContinueToBetClicked()
	{
		SetStatus(0);
	}

	public ChariotRaceTrack.Charioteer GetCharitoeerAtTrackIdx(int tIdx, out int idx)
	{
		idx = -1;
		if (raceTrack == null)
		{
			return null;
		}
		for (int i = 0; i < raceTrack.charioteers.Count; i++)
		{
			if (raceTrack.charioteers[i].trackIdx == tIdx)
			{
				idx = i;
				return raceTrack.charioteers[i];
			}
		}
		return null;
	}

	private void SetCameraType(int type)
	{
		if (currCamType != type)
		{
			switch (type)
			{
			case 0:
			{
				Transform transform2 = raceTrack.camLocations[0];
				Cam.inst.transform.position = transform2.position;
				Cam.inst.transform.forward = transform2.forward;
				break;
			}
			case 1:
			case 5:
			{
				Transform transform = raceTrack.camLocations[1];
				SetCamPosRot(transform.position, Quaternion.LookRotation(transform.forward));
				break;
			}
			case 2:
			{
				Transform transform3 = raceTrack.camLocations[2];
				Quaternion rot = Quaternion.LookRotation(orderedByPosition.data[0].currentPos - transform3.position);
				SetCamPosRot(transform3.position, rot);
				break;
			}
			case 3:
			case 4:
			{
				Vector3 currentPos = orderedByPosition.data[0].currentPos;
				Vector3 vector = raceTrack.b.GetOffset().rotation * ((type == 3) ? highCamTrackOffset : lowCamTrackOffset);
				Vector3 vector2 = currentPos + vector;
				SetCamPosRot(vector2, Quaternion.LookRotation(currentPos - vector2));
				break;
			}
			}
			currCamType = type;
		}
	}

	private void SetCamPosRot(Vector3 pos, Quaternion rot)
	{
		camPos = (camDesiredPos = pos);
		camRot = (camDesiredRot = rot);
		Cam.inst.transform.SetPositionAndRotation(pos, rot);
	}

	public void OnRaceTrackStatusChange(ChariotRaceTrack.Status status)
	{
		switch (status)
		{
		case ChariotRaceTrack.Status.BetRacing:
			Util.SetActive(skipRaceBtn.gameObject, active: true);
			SetCameraType(3);
			break;
		case ChariotRaceTrack.Status.BetFinished:
			if (transitionToLow != null)
			{
				StopCoroutine(transitionToLow);
			}
			transitionToLow = StartCoroutine(WaitToTransitionToLow());
			break;
		}
	}

	public IEnumerator WaitToTransitionToLow()
	{
		yield return new WaitForSecondsRealtime(3f);
		SetCameraType(4);
		doWinAnim = true;
		winAnimTime = 0f;
		Vector3 vector = winnerRectT.anchoredPosition;
		vector.y = 0f - winnerRectT.rect.size.y;
		winnerRectT.anchoredPosition = vector;
		ChariotRaceTrack.Charioteer charitoeerAtTrackIdx = GetCharitoeerAtTrackIdx(currSelectedIdx, out var _);
		if (charitoeerAtTrackIdx.currFinishPos == 0)
		{
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_chariot_race_win");
			winnerAmountTMP.text = LocalizationManager.GetTranslation("chariotraceui_sponsor_wins") + $"\n<color=green>+{charitoeerAtTrackIdx.chance.rewardAmt} <sprite name=icon_prosperity>";
		}
		else
		{
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_chariot_race_loss");
			winnerAmountTMP.text = LocalizationManager.GetTranslation("chariotraceui_sponsor_lost");
		}
		Util.SetActive(winnerRectT.gameObject, active: true);
		Util.SetActive(winnerHighlightObj, active: true);
		Cinematics.inst.ShowBars(show: false);
	}

	public bool IsFadingToEnd()
	{
		return fadeToEndCoroutine != null;
	}

	public IEnumerator SkipFadeToEndOfRace()
	{
		if (eMusic.isValid())
		{
			eMusic.stop(STOP_MODE.IMMEDIATE);
		}
		Util.SetEnabled(fadeBackground, active: true);
		Color c = fadeBackground.color;
		c.a = 0f;
		fadeBackground.color = c;
		float val = 0f;
		while (val < 1f)
		{
			val += Time.unscaledDeltaTime * 0.75f;
			c.a = Mathff.Clamp01(val);
			fadeBackground.color = c;
			yield return true;
		}
		raceTrack.raceTime = raceTrack.DesiredRaceDuration * 0.9f;
		yield return new WaitForSecondsRealtime(1.5f);
		val = 0f;
		while (val < 1f)
		{
			val += Time.unscaledDeltaTime * 0.75f;
			c.a = Mathff.Clamp01(1f - val);
			fadeBackground.color = c;
			yield return true;
		}
		Util.SetEnabled(fadeBackground, active: false);
		Util.SetActive(skipRaceBtn.gameObject, active: false);
	}
}
