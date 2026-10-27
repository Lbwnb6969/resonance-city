using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using Assets;
using Assets.Code;
using Assets.Code.UI;
using Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class MainMenuMode : GameMode, IKeyboardInputOverride
{
	public enum State
	{
		Uninitialized,
		Menu,
		ChooseMode,
		ChooseDifficulty,
		NewMap,
		NameAndBanner,
		PauseMenu,
		SettingsMenu,
		Save,
		Load,
		QuitConfirm,
		ExitConfirm,
		LoadError,
		SendSave,
		Credits,
		Failure,
		KeepDestroyed,
		BannerSelect,
		GameWorkshopUI,
		RivalChoiceUI,
		KingdomShareFromMenu,
		KingdomShareFromGame,
		IntroDialogue,
		IntroSailing
	}

	private struct LandmarkShot(int hash, float weight, float dist)
	{
		public int hash = hash;

		public float weight = weight;

		public float dist = dist;
	}

	public GameObject mainMenuUI;

	public GameObject topLevelUI;

	public Button continueBtn;

	public TextMeshProUGUI continueCityLabel;

	public TextMeshProUGUI continueYearLabel;

	public GameObject newMapUI;

	public PickNameUI pickNameUI;

	public GameObject chooseModeUI;

	public SettingsMenuUI settingsUI;

	public GameObject creditsUI;

	public SaveLoadUI saveLoadUI;

	public Confirmation LoadErrorSendSave;

	public SendSave SendSaveUI;

	public GameObject failureUI;

	public GameObject chooseBannerUI;

	public GameObject gameWorkshopUI;

	public RivalKingdomSettingsUI rivalSettingsUI;

	public TourismModalUI kingdomShareUI;

	public Canvas pauseMenuUICanvas;

	public GameObject pauseMenuContainer;

	public GameObject quitConfirmContainer;

	public Confirmation quitConfirmation;

	public TextMeshProUGUI quitText;

	public bool doIntro = true;

	public int introDialogueIdx;

	public List<string> introDialogueTerms = new List<string> { "intro_dialogue_1", "intro_dialogue_2", "intro_dialogue_3" };

	public GameObject introPropsGO;

	public Transform introShip;

	public GameObject introCityCamCenter;

	private float currIntroCityDistance;

	public float introCityTheta = -30f;

	public float introCityPhi = 33.5f;

	public float introCityDistance = 13.5f;

	public Vector3 introDialoguePosition;

	public float introDialogueTheta = -30f;

	public float introDialoguePhi = 33.5f;

	public float introDialogueDistance = 13.5f;

	private float currIntroDialogueDistance;

	public float introDialogSailingSpeed = 0.5f;

	public Vector3 introDialogShipOffset;

	public float introDialogueThetaShot1 = 70f;

	public float introDialoguePhiShot1 = 33.5f;

	public float introDialogueDistanceShot1 = 30.5f;

	public float introDialogueThetaShot2 = 70f;

	public float currIntroDialogueThetaShot2;

	public float introDialoguePhiShot2 = 33.5f;

	public float introDialogueDistanceShot2 = 30.5f;

	private float currIntroDialogueDistanceShot2;

	public float introSailingSpeed = 0.5f;

	public float introSailingRotationSpeed = 0.5f;

	public float introSailingPhiSpeed = 0.5f;

	public float introSailingSmoothSpeed = 0.5f;

	public float introSailingThetaSpeed = 0.5f;

	public float introSailingPosEndSmoothDamp = 2f;

	public float introSailingPosStartSmoothDamp = 0.5f;

	private float introSailingOrigPosSmoothDamp;

	public float introSailingDistEndSmoothDamp = 0.1f;

	public float introSailingDistStartSmoothDamp = 1f;

	private float introSailingOrigDistSmoothDamp;

	public float introSailingPhiEndSmoothDamp = 0.05f;

	public float introSailingPhiStartSmoothDamp = 0.1f;

	private float introSailingOrigPhiSmoothDamp;

	public float introSailingThetaEndSmoothDamp = 0.05f;

	public float introSailingThetaStartSmoothDamp = 0.1f;

	private float introSailingOrigThetaSmoothDamp;

	public float introSailingDistSpeed = 0.5f;

	public float introSailingTrackingSpeed = 2f;

	public float transitionFromIntroToMapSelectTime = 1.5f;

	public float newMapTheta = 30f;

	public float newMapPhi = 50f;

	public float newMapDistance = 13.5f;

	public float nameAndBannerDist = 30f;

	public float nameAndBannerPhi = 25f;

	public float nameAndBannerTheta = 70f;

	public float menuIdleRotateSpeed = 2f;

	public float menuIdleRotateGrace = 5f;

	private float idleRotateWait;

	private float idleExpectedTheta;

	private float idleLastDist;

	private Vector3 idleLastTrackingPos;

	public Button copySeedBtn;

	public GameObject SeedUI;

	public TextMeshProUGUI SeedText;

	private State prevState;

	private State state;

	private bool creditsInited;

	private Vector3 mapArrivalPos;

	private static readonly LandmarkShot[] landmarkShots = new LandmarkShot[13]
	{
		new LandmarkShot(World.colosseumHash, 100f, 45f),
		new LandmarkShot(World.chariotRaceTrackHash, 95f, 48f),
		new LandmarkShot(World.pantheonHash, 80f, 50f),
		new LandmarkShot("senate".GetHashCode(), 75f, 50f),
		new LandmarkShot("basilica".GetHashCode(), 70f, 50f),
		new LandmarkShot(World.theaterHash, 60f, 50f),
		new LandmarkShot("temple3".GetHashCode(), 55f, 50f),
		new LandmarkShot("temple2".GetHashCode(), 50f, 50f),
		new LandmarkShot("smalltheater".GetHashCode(), 45f, 52f),
		new LandmarkShot("gladiatorschool".GetHashCode(), 40f, 52f),
		new LandmarkShot(World.townsquareHash, 35f, 55f),
		new LandmarkShot(World.templeHash, 30f, 52f),
		new LandmarkShot(World.romanOutpostHash, 10f, 50f)
	};

	private int oldSpeed;

	public GameObject demoEndSlate;

	private bool shownDemoEndSlate;

	private float stateTime;

	public GameObject mapEditUI;

	private const float continueFadeTime = 0.15f;

	public Confirmation confirm;

	public Localize confirmTerm;

	private ArrayExt<Vector3> cornerPoints = new ArrayExt<Vector3>(4);

	public State PreviousState => prevState;

	private void CopySeedToClipboard()
	{
		GUIUtility.systemCopyBuffer = SeedText.text;
		SfxSystem.PlayUiSelect();
	}

	public State GetState()
	{
		return state;
	}

	private void Start()
	{
		creditsUI.SetActive(value: false);
		introPropsGO.SetActive(value: false);
		demoEndSlate.SetActive(value: false);
	}

	public override void Init()
	{
		mainMenuUI.SetActive(value: true);
		oldSpeed = TimeManager.inst.speedInUse;
		TimeManager.inst.SetPaused(skipSfx: true);
		MiniMapUI.inst.SetVisibility(v: false);
		if (state == State.Uninitialized)
		{
			if (!World.inst.isDemo)
			{
				Vector3 center2D = World.inst.GetCellData(World.inst.GridWidth / 2, World.inst.GridHeight / 2).Center2D;
				Cam.inst.SetTrackingPos(center2D);
				Cam.inst.dist = 65f;
			}
			TransitionTo(State.Menu);
			copySeedBtn.onClick.AddListener(CopySeedToClipboard);
			if (continueBtn != null)
			{
				continueBtn.onClick.AddListener(OnClickedContinue);
			}
		}
		base.Init();
	}

	public override void UpdateManual(float dt)
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		stateTime += Time.unscaledDeltaTime;
		if (GameUI.IsOnConsole())
		{
			mainMenuUI.GetComponentInParent<CanvasScaler>().referenceResolution = new Vector2(620f, 620f);
		}
		if (state == State.Menu && GameState.inst.enableContinueMode)
		{
			UpdateMenuIdleRotation(unscaledDeltaTime);
		}
		if (state != State.PauseMenu)
		{
			float actualAmt2;
			Vector3 newPos2;
			if (state == State.IntroDialogue || state == State.IntroSailing)
			{
				Vector3 vector = new Vector3(1f, 0f, 1f);
				if (!Mathff.MoveTowards(introShip.position, vector, unscaledDeltaTime * ((state == State.IntroSailing) ? introSailingSpeed : introDialogSailingSpeed), out var _, out var newPos) && Cinematics.inst.GetCurrTextIdx() != 0)
				{
					introShip.position = newPos;
					introShip.rotation = Quaternion.Lerp(introShip.rotation, Quaternion.LookRotation(vector - newPos), unscaledDeltaTime * introSailingRotationSpeed);
				}
				if (state == State.IntroDialogue)
				{
					if (!introPropsGO.activeSelf)
					{
						introPropsGO.SetActive(value: true);
					}
					if (Cinematics.inst.GetCurrTextIdx() == 0)
					{
						Cam.inst.SetTrackingPos(introCityCamCenter.transform.position);
						currIntroCityDistance += unscaledDeltaTime * 0.1f;
						Cam inst = Cam.inst;
						float desiredDist = (Cam.inst.dist = Mathff.Min(30f, currIntroCityDistance));
						inst.desiredDist = desiredDist;
						Cam.inst.SetPhi(introCityPhi);
						Cam.inst.SetTheta(introCityTheta);
					}
					else if (Cinematics.inst.GetCurrTextIdx() == 1)
					{
						Cam.inst.SetTrackingPos(newPos + introDialogShipOffset);
						currIntroDialogueDistance += unscaledDeltaTime * 0.1f;
						Cam inst2 = Cam.inst;
						float desiredDist = (Cam.inst.dist = currIntroDialogueDistance);
						inst2.desiredDist = desiredDist;
						Cam.inst.SetPhi(introDialoguePhi);
						Cam.inst.SetTheta(introDialogueTheta);
					}
					else if (Cinematics.inst.GetCurrTextIdx() == 2)
					{
						Cam inst3 = Cam.inst;
						float desiredDist = (Cam.inst.dist = introDialogueDistanceShot1);
						inst3.desiredDist = desiredDist;
						Cam.inst.SetPhi(introDialoguePhiShot1);
						Cam.inst.SetTheta(introDialogueThetaShot1);
						currIntroDialogueDistanceShot2 = introDialogueDistanceShot2;
						currIntroDialogueThetaShot2 = introDialogueThetaShot2;
						Cam.inst.SetTrackingPos(newPos);
						SeasonManager.inst.SetHoldAt(2f, 0);
					}
					else if (Cinematics.inst.GetCurrTextIdx() == 3)
					{
						currIntroDialogueDistanceShot2 += unscaledDeltaTime * 0.5f;
						currIntroDialogueThetaShot2 += unscaledDeltaTime * 0.5f;
						Cam inst4 = Cam.inst;
						float desiredDist = (Cam.inst.dist = currIntroDialogueDistanceShot2);
						inst4.desiredDist = desiredDist;
						Cam.inst.SetPhi(introDialoguePhiShot2);
						Cam.inst.SetTheta(currIntroDialogueThetaShot2);
						SeasonManager.inst.SetHoldAt(12f, 0);
						Cam.inst.SetTrackingPos(newPos);
					}
					else
					{
						Cam.inst.SetDesiredTrackingPos(newPos);
						if (Cinematics.inst.IsTextDone())
						{
							TransitionTo(State.IntroSailing);
						}
					}
					if (Input.GetKeyDown(KeyCode.Space) || Input.GetMouseButtonDown(0) || ConfigurableControls.inst.GetInputActionKeyDown(900))
					{
						if (Cinematics.inst.GetCurrTextIdx() == 2)
						{
							Water.inst.UnMoveWaterForIntro();
							Water.UpdateNeeded = true;
						}
						Cinematics.inst.OnContinueText();
					}
				}
				else if (state == State.IntroSailing)
				{
					cornerPoints.ClearFast();
					for (int i = 0; i < World.inst.landmassCenters.Count; i++)
					{
						Vector3 center = World.inst.landmassCenters.data[i].center;
						Vector3 item = default;
						for (int j = -1; j <= 1; j += 2)
						{
							for (int k = -1; k <= 1; k += 2)
							{
								item.x = center.x + (float)j * 10f;
								item.z = center.z + (float)k * 10f;
								cornerPoints.Add(item);
							}
						}
						cornerPoints.Add(center);
					}
					Cam.inst.isGenerateZoomedOut = true;
					Cam.inst.isNewMap = true;
					Vector3 origin = new Vector3((float)World.inst.GridWidth / 2f, 0f, 0f);
					Cam.inst.BringIntoView(origin, cornerPoints);
					Cam.inst.desiredTheta = 90f;
					Cam.inst.desiredDist = 115f;
					Cam.inst.desiredPhi = 30f;
					Cam.inst.posSmoothDampTime = Mathff.Lerp(Cam.inst.posSmoothDampTime, introSailingPosEndSmoothDamp, unscaledDeltaTime * introSailingSmoothSpeed);
					Cam.inst.distSmoothDampTime = Mathff.Lerp(Cam.inst.distSmoothDampTime, introSailingDistEndSmoothDamp, unscaledDeltaTime * introSailingSmoothSpeed);
					Cam.inst.phiSmoothDampTime = Mathff.Lerp(Cam.inst.phiSmoothDampTime, introSailingPhiEndSmoothDamp, unscaledDeltaTime * introSailingSmoothSpeed);
					Cam.inst.thetaSmoothDampTime = Mathff.Lerp(Cam.inst.thetaSmoothDampTime, introSailingThetaEndSmoothDamp, unscaledDeltaTime * introSailingSmoothSpeed);
					if ((Cam.inst.TrackingPos - Cam.inst.DesiredTrackingPos).xz().magnitude < 1f)
					{
						introPropsGO.SetActive(value: false);
						Cam.inst.posSmoothDampTime = introSailingOrigPosSmoothDamp;
						Cam.inst.distSmoothDampTime = introSailingOrigDistSmoothDamp;
						Cam.inst.phiSmoothDampTime = introSailingOrigPhiSmoothDamp;
						Cam.inst.thetaSmoothDampTime = introSailingOrigThetaSmoothDamp;
						KeyboardControl.inst.inputOverride = null;
						TransitionTo(State.ChooseMode);
						Cinematics.inst.ShowBars(show: false);
						World.inst.ShowResourceGroupTooltipUIs(-1, doShowFish: true);
					}
				}
			}
			else if (state == State.NameAndBanner && !Mathff.MoveTowards(introShip.position, mapArrivalPos, unscaledDeltaTime * introDialogSailingSpeed * 2f, out actualAmt2, out newPos2))
			{
				introShip.position = newPos2;
				introShip.rotation = Quaternion.Lerp(introShip.rotation, Quaternion.LookRotation(mapArrivalPos - newPos2), unscaledDeltaTime * introSailingRotationSpeed);
			}
		}
		base.UpdateManual(dt);
	}

	private static bool TryFindContinueShot(out Vector3 anchor, out float dist)
	{
		anchor = Vector3.zero;
		dist = 55f;
		int num = Mathf.Max(1, Mathf.CeilToInt((float)World.inst.GridWidth / 16f));
		int num2 = Mathf.Max(1, Mathf.CeilToInt((float)World.inst.GridHeight / 16f));
		float[,] array = new float[num, num2];
		Vector3[,] array2 = new Vector3[num, num2];
		Building building = null;
		float num3 = 0f;
		float num4 = 0f;
		List<Building> list = new List<Building>(4);
		int num5 = 0;
		LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
		for (int i = 0; i < playerLandmassOwner.ownedLandMasses.Count; i++)
		{
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(playerLandmassOwner.ownedLandMasses.data[i]);
			for (int j = 0; j < buildingListForLandMass.Count; j++)
			{
				Building building2 = buildingListForLandMass.data[j];
				if (building2 == null || !building2.IsBuilt() || building2.isDemolishing || building2.uniqueNameHash == World.rubbleHash)
				{
					continue;
				}
				Vector3 vector = building2.Center();
				int num6 = Mathf.Clamp((int)(vector.x / 16f), 0, num - 1);
				int num7 = Mathf.Clamp((int)(vector.z / 16f), 0, num2 - 1);
				array[num6, num7]++;
				array2[num6, num7] += vector;
				num5++;
				for (int k = 0; k < landmarkShots.Length; k++)
				{
					if (landmarkShots[k].hash == building2.uniqueNameHash)
					{
						if (landmarkShots[k].weight > num3)
						{
							num3 = landmarkShots[k].weight;
							num4 = landmarkShots[k].dist;
							building = building2;
							list.Clear();
							list.Add(building2);
						}
						else if (Mathf.Approximately(landmarkShots[k].weight, num3))
						{
							list.Add(building2);
						}
						break;
					}
				}
			}
		}
		if (num5 == 0)
		{
			List<GameObject> gysers = DynamicWater.inst.gysers;
			Vector3 vector2 = World.inst.GridCenter();
			GameObject gameObject = null;
			float num8 = float.MaxValue;
			for (int l = 0; l < gysers.Count; l++)
			{
				if (!(gysers[l] == null))
				{
					float sqrMagnitude = (gysers[l].transform.position - vector2).sqrMagnitude;
					if (sqrMagnitude < num8)
					{
						num8 = sqrMagnitude;
						gameObject = gysers[l];
					}
				}
			}
			if (gameObject == null)
			{
				return false;
			}
			anchor = gameObject.transform.position;
			dist = 40f;
			return true;
		}
		int num9 = 0;
		int num10 = 0;
		float num11 = -1f;
		for (int m = 0; m < num; m++)
		{
			for (int n = 0; n < num2; n++)
			{
				float num12 = 0f;
				for (int num13 = -1; num13 <= 1; num13++)
				{
					for (int num14 = -1; num14 <= 1; num14++)
					{
						int num15 = m + num13;
						int num16 = n + num14;
						if (num15 >= 0 && num15 < num && num16 >= 0 && num16 < num2)
						{
							num12 += array[num15, num16];
						}
					}
				}
				if (num12 > num11)
				{
					num11 = num12;
					num9 = m;
					num10 = n;
				}
			}
		}
		Vector3 zero = Vector3.zero;
		float num17 = 0f;
		for (int num18 = -1; num18 <= 1; num18++)
		{
			for (int num19 = -1; num19 <= 1; num19++)
			{
				int num20 = num9 + num18;
				int num21 = num10 + num19;
				if (num20 >= 0 && num20 < num && num21 >= 0 && num21 < num2)
				{
					zero += array2[num20, num21];
					num17 += array[num20, num21];
				}
			}
		}
		Vector3 vector3 = ((num17 > 0f) ? (zero / num17) : World.inst.GridCenter());
		if (building != null)
		{
			for (int num22 = 0; num22 < list.Count; num22++)
			{
				if (Mathff.DistSqrdXZ(list[num22].Center(), vector3) < Mathff.DistSqrdXZ(building.Center(), vector3))
				{
					building = list[num22];
				}
			}
			anchor = building.Center();
			dist = num4;
			return true;
		}
		anchor = vector3;
		dist = 60f;
		return true;
	}

	private void PrimeMenuIdleRotation()
	{
		idleRotateWait = 0f;
		idleExpectedTheta = Cam.inst.desiredTheta;
		idleLastDist = Cam.inst.desiredDist;
		idleLastTrackingPos = Cam.inst.DesiredTrackingPos;
	}

	private void UpdateMenuIdleRotation(float udt)
	{
		Cam inst = Cam.inst;
		if (inst.IsDragging() || Input.GetMouseButton(1) || Input.GetMouseButton(2) || Mathf.Abs(Input.GetAxis("Mouse ScrollWheel")) > 0.0001f || Mathf.Abs(inst.desiredTheta - idleExpectedTheta) > 0.01f || Mathf.Abs(inst.desiredDist - idleLastDist) > 0.01f || (inst.DesiredTrackingPos - idleLastTrackingPos).sqrMagnitude > 0.001f)
		{
			idleRotateWait = menuIdleRotateGrace;
		}
		else if (idleRotateWait > 0f)
		{
			idleRotateWait -= udt;
		}
		else
		{
			inst.desiredTheta += menuIdleRotateSpeed * udt;
		}
		idleExpectedTheta = inst.desiredTheta;
		idleLastDist = inst.desiredDist;
		idleLastTrackingPos = inst.DesiredTrackingPos;
	}

	public override void Shutdown()
	{
		KeyboardControl.inst.inputOverride = null;
		if (state == State.PauseMenu || state == State.BannerSelect)
		{
			TimeManager.inst.SetSpeed(oldSpeed, skipSfx: true);
		}
		else
		{
			TimeManager.inst.ReturnToPlaySpeed(skipSfx: true);
		}
		mainMenuUI.SetActive(value: false);
		base.Shutdown();
	}

	public void TryShowDemoEndSlate()
	{
		if (World.inst.demoMode)
		{
			if (!shownDemoEndSlate)
			{
				demoEndSlate.gameObject.SetActive(value: true);
			}
			shownDemoEndSlate = false;
		}
	}

	public void RefreshMenuBackdrop()
	{
		if (LoadSave.continueLoadFailed && continueBtn != null)
		{
			continueBtn.gameObject.SetActive(value: false);
		}
		if (!LoadSave.continueWorldReady && continueCityLabel != null)
		{
			continueCityLabel.gameObject.SetActive(value: false);
		}
		if (!World.inst.isDemo)
		{
			if (LoadSave.continueWorldReady && TryFindContinueShot(out var anchor, out var dist))
			{
				Cam.inst.SetTrackingPos(anchor);
			}
			else
			{
				anchor = new Vector3(93.03f, 1.61f, 39.91f);
				dist = 55f;
				Cam.inst.SetDesiredTrackingPos(anchor);
			}
			Cam.inst.SetDist(dist);
			Cam.inst.SetPhi(34.5f);
		}
		else
		{
			Cam.inst.SetDist(65f);
			Cam.inst.SetPhi(18.79f);
			Cam.inst.SetTheta(327f);
			Vector3 desiredTrackingPos = new Vector3(81.6f, 0.44f, 74.21f);
			Cam.inst.SetDesiredTrackingPos(desiredTrackingPos);
		}
		PrimeMenuIdleRotation();
		TimeManager.inst.SetPlay1(skipSfx: true);
		TimeManager.inst.PauseIfRaidInProgress();
		if (state == State.Menu)
		{
			MusicSystem.inst.StartMainMenuMusic();
		}
		if (!LoadSave.continueWorldReady)
		{
			SeasonManager.inst.Reset();
			SeasonManager.inst.SetTime(7.6f, 0);
			SeasonManager.inst.SetHold();
		}
	}

	public void TransitionTo(State newState)
	{
		stateTime = 0f;
		mapEditUI.SetActive(value: false);
		prevState = state;
		state = newState;
		if (prevState == State.NewMap)
		{
			rivalSettingsUI.ResetRivalItems();
		}
		topLevelUI.SetActive(state == State.Menu);
		if (state == State.Menu && continueBtn != null)
		{
			continueBtn.gameObject.SetActive(GameState.inst.enableContinueMode && !LoadSave.continueLoadFailed && (LoadSave.continueWorldReady || LoadSave.HasAnySaves()));
			if (continueCityLabel != null)
			{
				LoadSave.WorldSummaryData worldSummaryData = (continueBtn.gameObject.activeSelf ? LoadSave.GetContinueSummary() : null);
				bool flag = worldSummaryData != null && !string.IsNullOrEmpty(worldSummaryData.CityName);
				continueCityLabel.gameObject.SetActive(flag);
				if (flag)
				{
					continueCityLabel.text = worldSummaryData.CityName;
					if (continueYearLabel != null)
					{
						continueYearLabel.SetText(ScriptLocalization.SaveLoadYear, worldSummaryData.Year);
					}
				}
			}
		}
		newMapUI.SetActive(state == State.NewMap);
		MiniMapUI.inst.SetVisibility(state == State.NewMap);
		pickNameUI.SetVisibility(state == State.NameAndBanner);
		Util.SetEnabled(pauseMenuUICanvas, state == State.PauseMenu || state == State.QuitConfirm || state == State.ExitConfirm);
		pauseMenuContainer.SetActive(state == State.PauseMenu);
		quitConfirmContainer.SetActive(state == State.QuitConfirm || state == State.ExitConfirm);
		chooseModeUI.SetActive(state == State.ChooseMode);
		settingsUI.SetVisibility(state == State.SettingsMenu);
		DifficultyUI.inst.SetVisibility(state == State.ChooseDifficulty);
		if (kingdomShareUI != null && (state == State.KingdomShareFromMenu || state == State.KingdomShareFromGame))
		{
			if (state == State.KingdomShareFromMenu)
			{
				kingdomShareUI.SetupForMenuClick();
			}
			else
			{
				kingdomShareUI.SetupForGameClick();
			}
		}
		if (state == State.Load)
		{
			saveLoadUI.SetVisibility(v: true);
		}
		else if (state != State.Save)
		{
			saveLoadUI.SetVisibility(v: false);
		}
		LoadErrorSendSave.gameObject.SetActive(state == State.LoadError);
		SendSaveUI.gameObject.SetActive(state == State.SendSave);
		creditsUI.SetActive(state == State.Credits);
		failureUI.SetActive(state == State.Failure || state == State.KeepDestroyed);
		if (state == State.Failure || state == State.KeepDestroyed)
		{
			Localize[] componentsInChildren = failureUI.GetComponentsInChildren<Localize>();
			if (componentsInChildren[0] != null && componentsInChildren[1] != null)
			{
				componentsInChildren[0].Term = ((state == State.Failure) ? "ScriptTerms.You_Have_Been_Overthrown" : "ScriptTerms.keep_destroyed");
				componentsInChildren[1].Term = ((state == State.Failure) ? "ScriptTerms.overthrown_description" : "ScriptTerms.KeepDestroyed_description");
			}
		}
		chooseBannerUI.SetActive(state == State.BannerSelect);
		gameWorkshopUI.SetActive(state == State.GameWorkshopUI);
		if (state == State.Menu && (prevState == State.Uninitialized || prevState == State.PauseMenu || prevState == State.QuitConfirm || prevState == State.ExitConfirm || prevState == State.Failure || prevState == State.KeepDestroyed))
		{
			RefreshMenuBackdrop();
		}
		else
		{
			if (state == State.ChooseDifficulty)
			{
				return;
			}
			if (state == State.NewMap)
			{
				if (GamepadControl.inst.isControllerActive)
				{
					Cam.inst.desiredDist = 115f;
				}
				if (prevState != State.IntroSailing)
				{
					Cam.inst.SetDesiredTrackingPos(World.inst.GridCenter());
				}
				CloudSystem.inst.threshold1 = 0.6f;
				CloudSystem.inst.threshold2 = 0.8f;
				CloudSystem.inst.BaseFreq = 4.5f;
				mapEditUI.SetActive(value: true);
			}
			else if (state == State.QuitConfirm)
			{
				quitText.GetComponent<Localize>().SetTerm("quitui_tomainmenu_message");
				quitConfirmation.ShowConfirmation(BackToMainMenuSave, BackToMainMenu);
			}
			else if (state == State.ExitConfirm)
			{
				quitText.GetComponent<Localize>().SetTerm("quitui_todesktop_message");
				quitConfirmation.ShowConfirmation(ExitGameSave, ExitGame);
			}
			else if (state == State.LoadError)
			{
				LoadErrorSendSave.ShowConfirmation(OnClickedSendSaveToDev, BackToMainMenu);
			}
			else if (state == State.SendSave)
			{
				SendSaveUI.SetupSendSaveUI();
			}
			else if (state == State.Credits)
			{
				MusicSystem.inst.PlayCreditsMusic();
			}
			else if (state == State.Failure)
			{
				MusicSystem.inst.PlayGameOverMusic();
			}
			else if (state == State.IntroDialogue)
			{
				introPropsGO.SetActive(value: true);
				introShip.gameObject.SetActive(value: true);
				introShip.position = introDialoguePosition;
				introShip.rotation = Quaternion.Euler(0f, 45f, 0f);
				currIntroCityDistance = introCityDistance;
				currIntroDialogueDistance = introDialogueDistance;
				Cam.inst.desiredDist = introDialogueDistance;
				Cam.inst.desiredPhi = introDialoguePhi;
				Cam.inst.desiredTheta = introDialogueTheta;
				Cinematics.inst.FadeIn();
				Cinematics.inst.ShowBars(show: true);
				Cinematics.inst.SetTextList(introDialogueTerms);
				World.inst.HideResourceTooltipUIs();
				SeasonManager.inst.SetTime(0.5f, 0);
				SeasonManager.inst.SetHoldAt(1f, 0);
				KeyboardControl.inst.inputOverride = this;
				Water.inst.MoveWaterForIntro();
				Water.UpdateNeeded = true;
			}
			else if (state == State.NameAndBanner)
			{
				introShip.position = new Vector3(1f, 0f, 1f);
				Cell cell = World.inst.LineTestForFirstLand(World.inst.GetCellData(introShip.position), World.inst.GetCellData(World.inst.GridCenter()));
				if (cell == null)
				{
					cell = World.inst.GetCellData(World.inst.GridCenter());
				}
				mapArrivalPos = (cell.Center2D + (introShip.position - cell.Center2D).normalized * 10f).xz();
			}
			else if (state == State.IntroSailing)
			{
				introSailingOrigPosSmoothDamp = Cam.inst.posSmoothDampTime;
				introSailingOrigDistSmoothDamp = Cam.inst.distSmoothDampTime;
				introSailingOrigPhiSmoothDamp = Cam.inst.phiSmoothDampTime;
				introSailingOrigThetaSmoothDamp = Cam.inst.thetaSmoothDampTime;
				Cam.inst.posSmoothDampTime = introSailingPosStartSmoothDamp;
				Cam.inst.distSmoothDampTime = introSailingDistStartSmoothDamp;
				Cam.inst.phiSmoothDampTime = introSailingPhiStartSmoothDamp;
				Cam.inst.thetaSmoothDampTime = introSailingThetaStartSmoothDamp;
			}
			else if (state == State.PauseMenu)
			{
				SeedText.text = World.inst.GetTextSeed();
				SeedUI.SetActive(World.inst.HasSeed());
			}
		}
	}

	public void OnClickedStandardMode()
	{
		TransitionTo(State.NewMap);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedContinue()
	{
		SfxSystem.PlayUiSelect();
		if (LoadSave.continueWorldReady)
		{
			StartCoroutine(ContinueFadeSwitch());
		}
		else
		{
			LoadSave.Load();
		}
	}

	private static CanvasGroup GetOrAddGroup(GameObject go)
	{
		CanvasGroup canvasGroup = go.GetComponent<CanvasGroup>();
		if (canvasGroup == null)
		{
			canvasGroup = go.AddComponent<CanvasGroup>();
		}
		return canvasGroup;
	}

	private static IEnumerator FadeGroups(float from, float to, params CanvasGroup[] cgs)
	{
		CanvasGroup[] array;
		for (float t = 0f; t < 0.15f; t += Time.unscaledDeltaTime)
		{
			float alpha = Mathf.Lerp(from, to, t / 0.15f);
			array = cgs;
			for (int i = 0; i < array.Length; i++)
			{
				array[i].alpha = alpha;
			}
			yield return null;
		}
		array = cgs;
		for (int i = 0; i < array.Length; i++)
		{
			array[i].alpha = to;
		}
	}

	private IEnumerator ContinueFadeSwitch()
	{
		CanvasGroup menuCg = GetOrAddGroup(mainMenuUI);
		menuCg.blocksRaycasts = false;
		yield return FadeGroups(1f, 0f, menuCg);
		if (!LoadSave.continueWorldReady)
		{
			menuCg.alpha = 1f;
			menuCg.blocksRaycasts = true;
			yield break;
		}
		LoadSave.ClearContinueWorld();
		GameState component = GetComponent<GameState>();
		component.SetNewMode(component.playingMode);
		TimeManager.inst.SetPlay1(skipSfx: true);
		TimeManager.inst.PauseIfRaidInProgress();
		menuCg.alpha = 1f;
		menuCg.blocksRaycasts = true;
		CanvasGroup hudCg = GetOrAddGroup(component.playingMode.GameUIParent);
		CanvasGroup mapCg = GetOrAddGroup(MiniMapUI.inst.canvas.gameObject);
		hudCg.alpha = 0f;
		mapCg.alpha = 0f;
		yield return null;
		yield return FadeGroups(0f, 1f, hudCg, mapCg);
	}

	private void ResetSeasonForNewGame()
	{
		TimeManager.inst.SetPlay1(skipSfx: true);
		SeasonManager.inst.Reset();
		SeasonManager.inst.SetTime(7.6f, 0);
		SeasonManager.inst.SetHold();
	}

	public void OnClickedNew()
	{
		SfxSystem.PlayUiSelect();
		ResetSeasonForNewGame();
		if (doIntro)
		{
			World.inst.Generate();
			TransitionTo(State.IntroDialogue);
		}
		else
		{
			TransitionTo(State.ChooseMode);
		}
		DifficultyUI.inst.SetState(0);
	}

	public void OnClickedCreativeMode()
	{
		Creative.inst.SetEnabled(enabled: true);
		ResetSeasonForNewGame();
		Player.inst.difficulty = Player.Difficulty.Hard;
		TransitionTo(State.NewMap);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedAcceptDifficulty()
	{
		Creative.inst.SetEnabled(enabled: false);
		TransitionTo(State.NameAndBanner);
		SfxSystem.PlayUiSelect();
	}

	public void OnFinishedPickingRivals()
	{
		TransitionTo(State.ChooseDifficulty);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedAcceptNameBanner()
	{
		SfxSystem.PlayUiSelect();
		StartGame();
	}

	private void StartGame()
	{
		LoadSave.ClearContinueWorld();
		World.inst.guid = Guid.NewGuid();
		GameState component = GetComponent<GameState>();
		component.SetNewMode(component.playingMode);
		TimeManager.inst.SetPlay1(skipSfx: true);
		Cam.inst.desiredDist = 45f;
		TownNameUI.inst.Reset();
		World.inst.SetupInitialPathCosts();
		World.inst.inFirstPlacementPhase = true;
		World.inst.ShowResourceGroupTooltipUIs(-1, doShowFish: true);
		AIBrainsContainer.PreStartAIConfig preStartAIConfig = new AIBrainsContainer.PreStartAIConfig();
		int num = 0;
		if (RivalKingdomSettingsUI.inst != null)
		{
			for (int i = 0; i < RivalKingdomSettingsUI.inst.rivalItems.Length; i++)
			{
				RivalItemUI rivalItemUI = RivalKingdomSettingsUI.inst.rivalItems[i];
				if (rivalItemUI.Enabled && !rivalItemUI.Locked)
				{
					num++;
				}
			}
		}
		int num2 = 0;
		preStartAIConfig.startData = new AIBrainsContainer.PreStartAIConfig.AIStartData[num];
		if (RivalKingdomSettingsUI.inst != null)
		{
			for (int j = 0; j < RivalKingdomSettingsUI.inst.rivalItems.Length; j++)
			{
				RivalItemUI rivalItemUI2 = RivalKingdomSettingsUI.inst.rivalItems[j];
				if (rivalItemUI2.Enabled && !rivalItemUI2.Locked)
				{
					preStartAIConfig.startData[num2] = new AIBrainsContainer.PreStartAIConfig.AIStartData();
					preStartAIConfig.startData[num2].landmass = rivalItemUI2.flag.landmass;
					preStartAIConfig.startData[num2].bioCode = rivalItemUI2.bannerIdx;
					preStartAIConfig.startData[num2].personalityKey = PersonalityCollection.aiPersonalityKeys[0];
					preStartAIConfig.startData[num2].skillLevel = rivalItemUI2.GetSkillLevel();
					num2++;
				}
			}
		}
		AIBrainsContainer.inst.aiStartInfo = preStartAIConfig;
		if (GamepadControl.inst.isControllerActive)
		{
			ConsoleCursorMenu.inst.PrepForGamepad();
		}
		if (doIntro)
		{
			OnIntroGameStart();
		}
	}

	public void OnClickedStartMap()
	{
		SfxSystem.PlayUiSelect();
		if (Creative.inst.IsEnabled() && mapEditUI.GetComponent<MapEdit>().dirty)
		{
			if (mapEditUI.GetComponent<MapEdit>().Validate() != MapEdit.Validation.NoError)
			{
				confirmTerm.Term = "Creative Mode Edit Bad Map";
				confirm.ShowConfirmation(() =>
				{
					TransitionTo(State.ChooseDifficulty);
					SfxSystem.PlayUiSelect();
				}, () =>
				{
				});
			}
			else
			{
				TransitionTo(State.ChooseDifficulty);
			}
		}
		else
		{
			TransitionTo(State.ChooseDifficulty);
		}
	}

	public void OnClickedReturnToGame()
	{
		GameState component = GetComponent<GameState>();
		component.SetNewMode(component.playingMode);
		SfxSystem.PlayUiCancel();
		World.inst.triedQuittingAlready = false;
	}

	public void OnClickedReturnToMainMenu()
	{
		TransitionTo(State.QuitConfirm);
		SfxSystem.PlayUiCancel();
	}

	public void OnClickedReturnToMainMenuFromFailure()
	{
		TransitionTo(State.Menu);
		SfxSystem.PlayUiCancel();
		World.inst.Generate();
	}

	private void ExitGameSave()
	{
		LoadSave.Save(string.Empty, ExitGame);
	}

	private void ExitGame()
	{
		World.inst.triedQuittingAlready = true;
		Quit();
	}

	private void BackToMainMenuSave()
	{
		LoadSave.Save(string.Empty, BackToMainMenu);
	}

	private void BackToMainMenu()
	{
		if (!World.inst.isDemo)
		{
			TryShowDemoEndSlate();
		}
		TransitionTo(State.Menu);
		World.inst.Generate();
		if (GamepadControl.inst.isControllerActive)
		{
			topLevelUI.GetComponent<ConsoleUIItem>().Hover();
		}
	}

	public void OnExitFromGame()
	{
		TransitionTo(State.ExitConfirm);
	}

	public void OnLoadErrorSend(bool sendSave)
	{
		World.inst.Generate();
	}

	public void OnLoadErrorDontSend(bool sendSave)
	{
		World.inst.Generate();
		SfxSystem.PlayUiCancel();
	}

	public void OnClickedSendSaveToDev()
	{
		Process.Start("https://discord.com/channels/175640716515606528/1446270088364691637/1446270088364691637");
		TransitionTo(State.Menu);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickKingdomShareFromMainMenu()
	{
		TransitionTo(State.KingdomShareFromMenu);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickKingdomShareFromGame()
	{
		TransitionTo(State.KingdomShareFromGame);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickLoadGameWorkshop()
	{
		TransitionTo(State.GameWorkshopUI);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedBackToTopLevel()
	{
		TransitionTo(State.Menu);
		SfxSystem.PlayUiCancel();
	}

	public void OnClickedBackToModeSelect()
	{
		TransitionTo(State.ChooseMode);
		SfxSystem.PlayUiCancel();
	}

	public void OnClickedBackToNameBanner()
	{
		TransitionTo(State.NameAndBanner);
		SfxSystem.PlayUiCancel();
	}

	public void OnClickPlayDemo()
	{
		LoadSave.ClearContinueWorld();
		DemoScenario.inst.Setup();
		GameState.inst.SetNewMode(GameState.inst.playingMode);
		Creative.inst.SetEnabled(enabled: false);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedBackToDifficultySelect()
	{
		if (Creative.inst.IsEnabled())
		{
			TransitionTo(State.ChooseMode);
		}
		else
		{
			TransitionTo(State.ChooseDifficulty);
		}
		SfxSystem.PlayUiCancel();
	}

	public void OnClickedBackToMapSelect()
	{
		TransitionTo(State.NewMap);
		SfxSystem.PlayUiCancel();
	}

	public void OnClickedBackToRivalChoice()
	{
		TransitionTo(State.RivalChoiceUI);
		SfxSystem.PlayUiCancel();
	}

	public void OnClickedShowSettings()
	{
		SfxSystem.PlayUiSelect();
		TransitionTo(State.SettingsMenu);
	}

	public void OnClickedShowCredits()
	{
		SfxSystem.PlayUiSelect();
		if (GameState.inst.DoCredits())
		{
			TransitionTo(State.Credits);
		}
	}

	public void OnClickedClose()
	{
		TransitionTo(prevState);
	}

	public void OnClickedLoad()
	{
		SaveLoadUI.inst.BuiltInSaves = false;
		SaveLoadUI.inst.MapSaves = false;
		TransitionTo(State.Load);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedDeveloperLoad()
	{
		SaveLoadUI.inst.BuiltInSaves = true;
		SaveLoadUI.inst.MapSaves = false;
		TransitionTo(State.Load);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedLoadMap()
	{
		SaveLoadUI.inst.BuiltInSaves = false;
		SaveLoadUI.inst.MapSaves = true;
		TransitionTo(State.Load);
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedSave()
	{
		LoadSave.Save();
		GameSavedUI.inst.SetVisibility(v: true);
		SfxSystem.PlayUiSelect();
		GameState component = GetComponent<GameState>();
		component.SetNewMode(component.playingMode);
	}

	public void OnClickedDiscord()
	{
		Process.Start("https://discord.gg/kingdomsandcastles");
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedTwitter()
	{
		Process.Start("https://www.twitter.com/LionShieldGames");
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedTwitch()
	{
		Process.Start("https://www.twitch.tv/LionShieldGames");
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedYoutube()
	{
		Process.Start("https://www.youtube.com/@lionshieldgames");
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedEmail()
	{
		Process.Start("mailto:contact@lionshieldstudios.com");
		SfxSystem.PlayUiSelect();
	}

	public void OnClickedRegenSeed(int seed)
	{
		bool flag = Creative.inst.IsEnabled();
		World.inst.Generate(seed);
		Creative.inst.SetEnabled(flag);
		FrameGeneratedMap();
		SfxSystem.PlayUiSelect();
	}

	public void FrameGeneratedMap()
	{
		cornerPoints.ClearFast();
		for (int i = 0; i < World.inst.landmassCenters.Count; i++)
		{
			Vector3 center = World.inst.landmassCenters.data[i].center;
			Vector3 item = default;
			for (int j = -1; j <= 1; j += 2)
			{
				for (int k = -1; k <= 1; k += 2)
				{
					item.x = center.x + (float)j * 10f;
					item.z = center.z + (float)k * 10f;
					cornerPoints.Add(item);
				}
			}
			cornerPoints.Add(center);
		}
		Cam.inst.isGenerateZoomedOut = true;
		Cam.inst.BringIntoView(cornerPoints);
		Cam.inst.desiredTheta = 90f;
		Cam.inst.desiredDist = 150f;
	}

	public void OnMapLoadedIntoMapSelect()
	{
		TransitionTo(State.NewMap);
		mapEditUI.GetComponent<MapEdit>().dirty = true;
		MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
		rivalSettingsUI.UpdateSlotAvailability();
		Player.inst.ResetPerLandMassData();
		World.inst.SetupInitialPathCosts();
		World.inst.ShowResourceGroupTooltipUIs(-1, doShowFish: true);
		if (MapEditorController.inst != null)
		{
			MapEditorController.inst.ResetForRegeneratedWorld();
		}
		SeedButtonUI.inst.SetSeed(World.inst.seed);
		FrameGeneratedMap();
		newMapUI.GetComponent<NewMapUI>().OnEdit();
	}

	public void OnClickedQuit()
	{
		Quit();
	}

	public void Quit()
	{
		Application.Quit();
	}

	private void OnIntroGameStart()
	{
		introShip.gameObject.SetActive(value: false);
		introPropsGO.SetActive(value: false);
	}

	void IKeyboardInputOverride.UpdateKeyboardInput()
	{
	}
}
