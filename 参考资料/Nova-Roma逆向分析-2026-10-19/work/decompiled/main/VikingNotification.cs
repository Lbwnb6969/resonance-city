using System.Collections.Generic;
using Assets;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class VikingNotification : MonoBehaviour
{
	public MiniMapViewer miniMapViewer;

	public Slider progressSlider;

	public GameObject focusButtonContainer;

	public Button prevBtn;

	public Button nextBtn;

	public TextMeshProUGUI vikingCountText;

	public TextMeshProUGUI vikingYearCountdownText;

	private bool IsAnimatingHide;

	private bool IsShowing;

	public GameObject Content;

	public static VikingNotification inst;

	public Color bg1;

	public Color bg2;

	private int currFrame;

	private bool IsRaidInProgress;

	private int vikingUnitCount;

	private int lastYears = -1;

	private int lastVikings = -1;

	private float totalTime;

	public Image bg;

	public GameObject raidActiveBg;

	public void Awake()
	{
		inst = this;
	}

	public void HideNotification()
	{
		if (!IsAnimatingHide)
		{
			IsAnimatingHide = true;
			miniMapViewer.HideTab(MiniMapViewer.NotificationGroup.Vikings, OnFinishedHideAnimation);
		}
	}

	private void OnFinishedHideAnimation()
	{
		if (IsAnimatingHide)
		{
			Content.SetActive(value: false);
		}
		IsShowing = false;
		IsAnimatingHide = false;
		MusicSystem.inst.StopVikingMusic();
	}

	public void ShowNotification()
	{
		IsShowing = true;
		miniMapViewer.ShowTab(MiniMapViewer.NotificationGroup.Vikings);
		Content.SetActive(value: true);
	}

	public void ShowBanner()
	{
		MusicSystem.inst.StartVikingMusic();
		miniMapViewer.DisplayBanner(MiniMapViewer.NotificationGroup.Vikings);
	}

	private void Update()
	{
		currFrame++;
		bool flag = RaiderSystem.inst.IsRaidInProgress();
		bool flag2 = flag || (RaiderSystem.inst.AllowSpawningVikings() && Settings.inst.VikingDragonTimers && Player.inst.difficulty != Player.Difficulty.Peaceful);
		if (IsShowing && !flag2 && !IsAnimatingHide)
		{
			HideNotification();
		}
		else if (!IsShowing & flag2)
		{
			ShowNotification();
		}
		Util.SetActive(focusButtonContainer.gameObject, IsRaidInProgress && IsShowing && !IsAnimatingHide);
		Util.SetActive(vikingYearCountdownText.gameObject, IsShowing && !IsAnimatingHide);
		if (!IsShowing || IsAnimatingHide)
		{
			return;
		}
		if (!IsRaidInProgress & flag)
		{
			ShowBanner();
		}
		else if (IsRaidInProgress && !flag)
		{
			MusicSystem.inst.StopVikingMusic();
		}
		IsRaidInProgress = flag;
		progressSlider.gameObject.SetActive(!IsRaidInProgress);
		raidActiveBg.SetActive(IsRaidInProgress);
		if (IsRaidInProgress)
		{
			prevBtn.gameObject.SetActive(!GamepadControl.inst.isControllerActive);
			nextBtn.gameObject.SetActive(!GamepadControl.inst.isControllerActive);
			vikingUnitCount = 0;
			List<RaiderSystem.UnitData> unitData = RaiderSystem.inst.unitData;
			_ = RaiderSystem.inst.lastTracked;
			for (int i = 0; i < unitData.Count; i++)
			{
				if (!unitData[i].unit.IsBeingCarried())
				{
					vikingUnitCount++;
				}
			}
			Util.TrySetText(vikingCountText, "{0}", vikingUnitCount, ref lastVikings);
			bg.color = bg1;
			return;
		}
		float yearProgress = SeasonManager.inst.GetYearProgress();
		float num = (float)(RaiderSystem.inst.totalYearsUntilNextAttack - RaiderSystem.inst.yearsUntilNextAttack) + yearProgress;
		if (currFrame % 30 == 0)
		{
			progressSlider.value = num / ((float)RaiderSystem.inst.totalYearsUntilNextAttack + 1f);
		}
		if (lastYears != RaiderSystem.inst.yearsUntilNextAttack + 1)
		{
			vikingYearCountdownText.SetText(ScriptLocalization.YearsRemain, RaiderSystem.inst.yearsUntilNextAttack + 1);
			lastYears = RaiderSystem.inst.yearsUntilNextAttack + 1;
		}
		if (progressSlider.value > 0.9f)
		{
			totalTime += Time.unscaledDeltaTime;
			float t = Mathf.Sin(totalTime * 5f) * 0.5f + 0.5f;
			bg.color = Color.Lerp(bg1, bg2, t);
		}
	}

	public void OnViewNextClicked()
	{
		if (object.Equals(Cam.inst.OverrideTrack, RaiderSystem.inst))
		{
			RaiderSystem.inst.TrackNext();
		}
		else
		{
			RaiderSystem.inst.TrackNearest();
		}
		Cam.inst.Track(RaiderSystem.inst);
	}

	public void OnViewPrevClicked()
	{
		if (object.Equals(Cam.inst.OverrideTrack, RaiderSystem.inst))
		{
			RaiderSystem.inst.TrackPrev();
		}
		else
		{
			RaiderSystem.inst.TrackNearest();
		}
		Cam.inst.Track(RaiderSystem.inst);
	}

	public void Reset()
	{
		IsShowing = false;
		IsAnimatingHide = false;
		if (IsRaidInProgress)
		{
			MusicSystem.inst.StopVikingMusic();
		}
		IsRaidInProgress = false;
	}
}
