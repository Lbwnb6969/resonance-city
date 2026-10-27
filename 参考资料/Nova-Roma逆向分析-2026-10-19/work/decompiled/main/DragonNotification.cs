using Assets;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class DragonNotification : MonoBehaviour
{
	public MiniMapViewer miniMapViewer;

	public Slider progressSlider;

	public GameObject focusButtonContainer;

	public Button prevBtn;

	public Button nextBtn;

	public TextMeshProUGUI dragonCountText;

	public TextMeshProUGUI dragonYearCountdownText;

	private bool IsAnimatingHide;

	private bool IsShowing;

	public GameObject Content;

	private int currFrame;

	private bool IsAttackInProgress;

	private int lastDragonYears = -1;

	private int lastDragons = -1;

	private float totalTime;

	public Image bg;

	public Color bg1;

	public Color bg2;

	public GameObject attackActiveBg;

	public void OnVisiblityUpdate()
	{
	}

	public void HideNotification()
	{
		if (!IsAnimatingHide)
		{
			IsAnimatingHide = true;
			miniMapViewer.HideTab(MiniMapViewer.NotificationGroup.Dragons, OnFinishedHideAnimation);
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
		MusicSystem.inst.StopDragonMusic();
	}

	public void ShowNotification()
	{
		IsShowing = true;
		miniMapViewer.ShowTab(MiniMapViewer.NotificationGroup.Dragons);
		Content.SetActive(value: true);
	}

	public void ShowBanner()
	{
		MusicSystem.inst.StartDragonMusic();
		miniMapViewer.DisplayBanner(MiniMapViewer.NotificationGroup.Dragons);
	}

	private void Update()
	{
		bool flag = DragonSpawn.inst.IsAttackInProgress();
		currFrame++;
		bool flag2 = flag || (DragonSpawn.inst.AllowSpawning() && Settings.inst.VikingDragonTimers && Player.inst.difficulty != Player.Difficulty.Peaceful);
		if (IsShowing && !flag2 && !IsAnimatingHide)
		{
			HideNotification();
		}
		else if (!IsShowing & flag2)
		{
			ShowNotification();
		}
		focusButtonContainer.gameObject.SetActive(IsAttackInProgress && IsShowing && !IsAnimatingHide);
		if (!IsShowing || IsAnimatingHide)
		{
			return;
		}
		if (!IsAttackInProgress & flag)
		{
			ShowBanner();
		}
		else if (IsAttackInProgress && !flag)
		{
			MusicSystem.inst.StopDragonMusic();
		}
		IsAttackInProgress = flag;
		progressSlider.gameObject.SetActive(!IsAttackInProgress);
		attackActiveBg.gameObject.SetActive(IsAttackInProgress);
		if (IsAttackInProgress)
		{
			prevBtn.gameObject.SetActive(!GamepadControl.inst.isControllerActive);
			nextBtn.gameObject.SetActive(!GamepadControl.inst.isControllerActive);
			int count = DragonSpawn.inst.currentDragons.Count;
			Util.TrySetText(dragonCountText, "{0}", count, ref lastDragons);
			bg.color = bg1;
			return;
		}
		float yearProgress = SeasonManager.inst.GetYearProgress();
		float num = (float)(DragonSpawn.inst.totalYearsUntilNextAttack - DragonSpawn.inst.yearsUntilNextAttack) + yearProgress;
		if (currFrame % 30 == 0)
		{
			progressSlider.value = num / ((float)DragonSpawn.inst.totalYearsUntilNextAttack + 1f);
		}
		if (lastDragonYears != DragonSpawn.inst.yearsUntilNextAttack + 1)
		{
			dragonYearCountdownText.SetText(ScriptLocalization.YearsRemain, DragonSpawn.inst.yearsUntilNextAttack + 1);
			lastDragonYears = DragonSpawn.inst.yearsUntilNextAttack + 1;
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
		if (Cam.inst.OverrideTrack == DragonSpawn.inst)
		{
			DragonSpawn.inst.LookAtNextDragon(-1);
		}
		else
		{
			DragonSpawn.inst.LookAtNearestDragon();
		}
		Cam.inst.Track(DragonSpawn.inst);
	}

	public void OnViewPrevClicked()
	{
		if (Cam.inst.OverrideTrack == DragonSpawn.inst)
		{
			DragonSpawn.inst.LookAtNextDragon(1);
		}
		else
		{
			DragonSpawn.inst.LookAtNearestDragon();
		}
		Cam.inst.Track(DragonSpawn.inst);
	}

	public void Reset()
	{
		IsShowing = false;
		IsAnimatingHide = false;
		if (IsAttackInProgress)
		{
			MusicSystem.inst.StopDragonMusic();
		}
		IsAttackInProgress = false;
	}
}
