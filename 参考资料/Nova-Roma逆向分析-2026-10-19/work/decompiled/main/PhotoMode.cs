using System;
using System.Collections.Generic;
using System.IO;
using Assets.Code.UI;
using Colorful;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using UnityStandardAssets.ImageEffects;
using cakeslice;

public class PhotoMode : MonoBehaviour
{
	private class Keyframe
	{
		public int idx;

		public Vector3 pos;

		public Quaternion rot;

		public PhotoModeLocationEntryUI entryUI;

		public bool isInvalid;
	}

	[Serializable]
	public struct KeyframeSaveData
	{
		public SerializableVector3 pos;

		public SerializableQuaternion rot;
	}

	[Serializable]
	public class KeyframeGroup
	{
		public SerializableGuid guid;

		public string name;

		public KeyframeSaveData[] keyframes;

		[NonSerialized]
		public PhotoModeTrackEntryUI entryUI;

		public KeyframeGroup()
		{
			guid = Guid.NewGuid();
		}
	}

	[Serializable]
	public class PhotoSaveData : SaveClass<PhotoMode, PhotoSaveData>
	{
		public KeyframeGroup[] data;

		public override PhotoSaveData Pack(PhotoMode obj)
		{
			if (obj.keyframeGroups.Count > 0)
			{
				data = new KeyframeGroup[obj.keyframeGroups.Count];
				for (int i = 0; i < data.Length; i++)
				{
					data[i] = obj.keyframeGroups[i];
				}
			}
			return this;
		}

		public override PhotoMode Unpack(PhotoMode obj)
		{
			if (data != null)
			{
				obj.keyframeGroups.Clear();
				for (int i = 0; i < data.Length; i++)
				{
					obj.keyframeGroups.Add(data[i]);
				}
			}
			return obj;
		}
	}

	public static PhotoMode inst;

	[SerializeField]
	private Sprite Pinned_Icon;

	[SerializeField]
	private Sprite Unpinned_Icon;

	[SerializeField]
	private Button Exit_Button;

	[SerializeField]
	private Toggle Pin_Toggle;

	[SerializeField]
	private Image Pin_Image;

	[SerializeField]
	private TextMeshProUGUI descriptionTMP;

	[SerializeField]
	private Toggle[] tabToggles;

	[SerializeField]
	private GameObject[] tabContents;

	[SerializeField]
	private Button resetSettingsBtn;

	[SerializeField]
	private Slider RotationSpeed_Slider;

	[SerializeField]
	private TMP_InputField RotationSpeed_Input;

	[SerializeField]
	private Button RotationSpeed_ResetBtn;

	private int origRotationSpeed = 20;

	private const int MIN_ROTATION_SPEED = 3;

	private const int MAX_ROTATION_SPEED = 20;

	[SerializeField]
	private Slider FieldOfView_Slider;

	[SerializeField]
	private TMP_InputField FieldOfView_Input;

	[SerializeField]
	private Button FieldOfView_ResetBtn;

	private int origFieldOfView = 34;

	private const int MIN_FOV = 10;

	private const int MAX_FOV = 120;

	[SerializeField]
	private Slider CameraRoll_Slider;

	[SerializeField]
	private TMP_InputField CameraRoll_Input;

	[SerializeField]
	private Button CameraRoll_ResetBtn;

	private int origCameraRoll;

	private const int MIN_CAMERA_ROLL = -90;

	private const int MAX_CAMERA_ROLL = 90;

	[SerializeField]
	private Toggle DepthOfField_Toggle;

	[SerializeField]
	private Slider FocalDistance_Slider;

	[SerializeField]
	private TMP_InputField FocalDistance_Input;

	[SerializeField]
	private Button FocalDistance_ResetBtn;

	private float origFocalDistance;

	private const float MIN_FOCAL_DIST = 0f;

	private const float MAX_FOCAL_DIST = 20f;

	[SerializeField]
	private Slider Aperture_Slider;

	[SerializeField]
	private TMP_InputField Aperture_Input;

	[SerializeField]
	private Button Aperture_ResetBtn;

	private float origFocalLength;

	private const float MIN_APERTURE = 0f;

	private const float MAX_APERTURE = 1f;

	[SerializeField]
	private Slider FocalLength_Slider;

	[SerializeField]
	private TMP_InputField FocalLength_Input;

	[SerializeField]
	private Button FocalLength_ResetBtn;

	private float origAperture;

	private const float MIN_FOCAL_LENGTH = 0f;

	private const float MAX_FOCAL_LENGTH = 2f;

	[SerializeField]
	private Toggle SunRotation_Toggle;

	[SerializeField]
	private Slider SunRotation_Slider;

	[SerializeField]
	private TMP_InputField SunRotation_Input;

	[SerializeField]
	private Button SunRotation_ResetBtn;

	private float origSunRotation;

	public DayNightManager.DayNightParameters PhotoDayNightParameters;

	[SerializeField]
	private Slider Saturation_Slider;

	[SerializeField]
	private TMP_InputField Saturation_Input;

	[SerializeField]
	private Button Saturation_ResetBtn;

	private float origSaturation;

	private const float MIN_SATURATION = 0f;

	private const float MAX_SATURATION = 5f;

	[SerializeField]
	private Slider Contrast_Slider;

	[SerializeField]
	private TMP_InputField Contrast_Input;

	[SerializeField]
	private Button Contrast_ResetBtn;

	private float origContrast;

	private const float MIN_CONTRAST = 0f;

	private const float MAX_CONTRAST = 100f;

	[SerializeField]
	private Slider Gamma_Slider;

	[SerializeField]
	private TMP_InputField Gamma_Input;

	[SerializeField]
	private Button Gamma_ResetBtn;

	private float origGamma;

	private const float MIN_GAMMA = 0f;

	private const float MAX_GAMMA = 3f;

	[SerializeField]
	private Slider Bloom_Intensity_Slider;

	[SerializeField]
	private TMP_InputField Bloom_Intensity_Input;

	[SerializeField]
	private Button Bloom_Intensity_ResetBtn;

	private float origBloomIntensity;

	private const float MIN_BLOOM_INTENSITY = 0f;

	private const float MAX_BLOOM_INTENSITY = 10f;

	[SerializeField]
	private Slider Bloom_Threshold_Slider;

	[SerializeField]
	private TMP_InputField Bloom_Threshold_Input;

	[SerializeField]
	private Button Bloom_Threshold_ResetBtn;

	private float origBloomThreshold;

	private const float MIN_BLOOM_THRESHOLD = -0.05f;

	private const float MAX_BLOOM_THRESHOLD = 4f;

	[SerializeField]
	private Slider WhiteBalance_R_Slider;

	[SerializeField]
	private TMP_InputField WhiteBalance_R_Input;

	[SerializeField]
	private Button WhiteBalance_R_ResetBtn;

	[SerializeField]
	private Slider WhiteBalance_G_Slider;

	[SerializeField]
	private TMP_InputField WhiteBalance_G_Input;

	[SerializeField]
	private Button WhiteBalance_G_ResetBtn;

	[SerializeField]
	private Slider WhiteBalance_B_Slider;

	[SerializeField]
	private TMP_InputField WhiteBalance_B_Input;

	[SerializeField]
	private Button WhiteBalance_B_ResetBtn;

	[SerializeField]
	private RawImage WhiteBalance_Reference;

	private Color origWhiteBalance;

	[SerializeField]
	private Slider Vignette_Sharpness_Slider;

	[SerializeField]
	private TMP_InputField Vignette_Sharpness_Input;

	[SerializeField]
	private Button Vignette_Sharpness_ResetBtn;

	private float origVignetteSharpness;

	private const float MIN_VIGNETTE_SHARPNESS = -100f;

	private const float MAX_VIGNETTE_SHARPNESS = 100f;

	[SerializeField]
	private Slider Vignette_Darkness_Slider;

	[SerializeField]
	private TMP_InputField Vignette_Darkness_Input;

	[SerializeField]
	private Button Vignette_Darkness_ResetBtn;

	private float origVignetteDarkness;

	private const float MIN_VIGNETTE_DARKNESS = 0f;

	private const float MAX_VIGNETTE_DARKNESS = 100f;

	[SerializeField]
	private Toggle Vignette_Toggle;

	private List<Keyframe> keyframes = new List<Keyframe>(32);

	private List<KeyframeGroup> keyframeGroups = new List<KeyframeGroup>(32);

	[SerializeField]
	private GameObject activeTrackChangesObj;

	[SerializeField]
	private PhotoModeTrackEntryUI trackEntryPrefab;

	[SerializeField]
	private Button newTrackBtn;

	[SerializeField]
	private RectTransform trackContainer;

	[SerializeField]
	private GameObject timelineObj;

	[SerializeField]
	private GameObject locationsObj;

	[SerializeField]
	private Confirmation unsavedConfirmation;

	[SerializeField]
	private Confirmation deleteConfirmation;

	[SerializeField]
	private TextMeshProUGUI deleteConfirmationTitle;

	private int trackPoolCount;

	private ArrayExtRef<PhotoModeTrackEntryUI> trackPool = new ArrayExtRef<PhotoModeTrackEntryUI>(64);

	private KeyframeGroup activeTrack;

	private bool isActiveTrackDirty;

	[SerializeField]
	private PhotoModeLocationEntryUI locationEntryPrefab;

	[SerializeField]
	private GameObject locationLayoutPrefab;

	[SerializeField]
	private RectTransform locationContentContainer;

	[SerializeField]
	private RectTransform locationLayoutContainer;

	[SerializeField]
	private ScrollRect locationScrollRect;

	[SerializeField]
	private RectTransform locationScrollViewRectT;

	[SerializeField]
	private RectTransform locationScrollContainer;

	[SerializeField]
	private Button addLocationBtn;

	[SerializeField]
	private StaticTooltipHook addLocationInvalidTooltip;

	[SerializeField]
	private GameObject addLocationInvalidObj;

	[SerializeField]
	private float locationLayoutSpeed = 1f;

	[SerializeField]
	private TMP_InputField speedInput;

	[SerializeField]
	private Button speedIncrementBtn;

	[SerializeField]
	private Button speedDecrementBtn;

	[SerializeField]
	private StaticTooltipHook speedIncrementHook;

	[SerializeField]
	private StaticTooltipHook speedDecrementHook;

	[SerializeField]
	private Slider animSlider;

	[SerializeField]
	private TextMeshProUGUI animTimeTMP;

	[SerializeField]
	private Button animPlayBtn;

	[SerializeField]
	private TooltipHook animPlayHook;

	[SerializeField]
	private StaticTooltipHook animStopHook;

	[SerializeField]
	private Image animPauseIconImg;

	[SerializeField]
	private Image animPlayIconImg;

	[SerializeField]
	private Button animStopBtn;

	private CentripetalCatmullRomSpline spline;

	public float moveSpeed = 1f;

	public float MAX_MOVE_SPEED = 5f;

	public float MIN_MOVE_SPEED = 0.5f;

	public int MOVE_SPEED_STEPS = 10;

	public float rotationSpeed = 1f;

	public float rotationStrength = 1f;

	public float moveSpeedMod = 2f;

	private float theta;

	private float phi;

	private float yaw;

	[SerializeField]
	private float slideSpeed = 1f;

	private bool isAnimating;

	private bool isPaused;

	private int animationIdx;

	private int rotationIdx;

	private float animationTime;

	[SerializeField]
	private float animationSpeed = 0.05f;

	[SerializeField]
	private float MAX_ANIMATION_SPEED = 2f;

	public int splineResolution = 8;

	[Range(0f, 1f)]
	public float splineAlpha = 0.5f;

	private Cam cam;

	private Camera camera;

	private DepthOfField depthOfField;

	private ColorCorrectionCurves colorCorrection;

	private Levels levels;

	private Bloom bloom;

	private WhiteBalance whiteBalance;

	private FastVignette vignette;

	private GraphicRaycaster gRaycaster;

	private Canvas canvas;

	private List<RaycastResult> results = new List<RaycastResult>(32);

	private RectTransform rectT;

	private Vector3 initMousePos;

	private Vector3 initRot;

	private Quaternion targetRot;

	private bool isVisible;

	private bool isHovering;

	private bool isPinned = true;

	private bool isInteractingWithUI;

	private FogAndLightingStack.FogAndLighting photoFogLighting = new FogAndLightingStack.FogAndLighting();

	private bool isLocationAlreadyStored;

	private float cachedDist;

	private float currDist;

	private bool isCamPosRotDirty;

	private bool isDragging;

	private int originalIdx;

	private PhotoModeLocationEntryUI dragEntry;

	private float edgeScrolling;

	private float edgeScrollSpeed = 1f;

	private Vector3 dragOffset;

	private List<Keyframe> scratch = new List<Keyframe>(32);

	private List<Keyframe> splineKeyframes = new List<Keyframe>(32);

	public static bool IsActive()
	{
		if (inst != null)
		{
			return inst.isVisible;
		}
		return false;
	}

	public bool IsCustomSunEnabled()
	{
		return SunRotation_Toggle.isOn;
	}

	public float GetCustomSunRotation()
	{
		return SunRotation_Slider.value;
	}

	private void OnSplineSettingsChanged()
	{
		if (Application.isPlaying && spline != null)
		{
			spline.resolution = splineResolution;
			spline.alpha = splineAlpha;
			spline.isLooped = false;
			OrganizeKeyframesAndGenerateSpline();
		}
	}

	public void SetVisibility(bool v)
	{
		if (isVisible != v)
		{
			cam.enabled = !v;
			GameUI.inst.gameObject.SetActive(!v);
			MiniMapUI.inst.SetVisibility(!v);
			GameState.inst.AlphaNumericHotkeysEnabled = !v;
			Cam.inst.GetComponent<OutlineEffect>().enabled = !v;
			if (v)
			{
				GameUI.inst.ReturnToDefaultCursorMode();
				Vector3 eulerAngles = cam.transform.eulerAngles;
				phi = eulerAngles.x;
				theta = eulerAngles.y;
				eulerAngles.z = 0f - CameraRoll_Slider.value;
				cam.transform.rotation = Quaternion.Euler(eulerAngles);
				ApplySettings();
			}
			else
			{
				isAnimating = false;
				ResetAnimationTimeline();
				Reset();
			}
			Util.SetEnabled(canvas, v);
			Util.SetEnabled(gRaycaster, v);
			Util.SetEnabled(this, v);
			isVisible = v;
		}
	}

	private void Awake()
	{
		inst = this;
		rectT = transform.GetChild(0).GetComponent<RectTransform>();
		cam = UnityEngine.Object.FindAnyObjectByType<Cam>();
		camera = cam.GetComponent<Camera>();
		depthOfField = cam.GetComponent<DepthOfField>();
		colorCorrection = cam.GetComponent<ColorCorrectionCurves>();
		levels = cam.GetComponent<Levels>();
		bloom = cam.GetComponent<Bloom>();
		whiteBalance = cam.GetComponent<WhiteBalance>();
		vignette = cam.GetComponent<FastVignette>();
		canvas = transform.GetComponent<Canvas>();
		gRaycaster = transform.GetComponent<GraphicRaycaster>();
		spline = new CentripetalCatmullRomSpline();
		spline.resolution = splineResolution;
		spline.alpha = splineAlpha;
		origRotationSpeed = 20;
		origFieldOfView = (int)camera.fieldOfView;
		origFocalDistance = depthOfField.focalLength;
		origAperture = depthOfField.aperture;
		origFocalLength = depthOfField.focalSize;
		origSaturation = colorCorrection.saturation;
		origContrast = levels.InputL.x;
		origGamma = levels.InputL.z;
		origVignetteSharpness = vignette.Sharpness;
		origVignetteDarkness = vignette.Darkness;
		resetSettingsBtn.onClick.AddListener(OnResetToDefaults);
		RotationSpeed_Slider.minValue = 3f;
		RotationSpeed_Slider.maxValue = 20f;
		RotationSpeed_Input.SetTextWithoutNotify(origRotationSpeed.ToString());
		RotationSpeed_Input.onEndEdit.AddListener(OnRotationSpeedInputChanged);
		RotationSpeed_Slider.SetValueWithoutNotify(20f);
		RotationSpeed_Slider.onValueChanged.AddListener(OnRotationSpeedSliderChanged);
		RotationSpeed_ResetBtn.onClick.AddListener(() =>
		{
			OnRotationSpeedInputChanged(origRotationSpeed.ToString());
		});
		FieldOfView_Slider.minValue = 10f;
		FieldOfView_Slider.maxValue = 120f;
		FieldOfView_Input.SetTextWithoutNotify(origFieldOfView.ToString());
		FieldOfView_Input.onEndEdit.AddListener(OnFieldOfViewInputChanged);
		FieldOfView_Slider.SetValueWithoutNotify(origFieldOfView);
		FieldOfView_Slider.onValueChanged.AddListener(OnFieldOfViewSliderChanged);
		FieldOfView_ResetBtn.onClick.AddListener(() =>
		{
			OnFieldOfViewInputChanged(origFieldOfView.ToString());
		});
		CameraRoll_Slider.minValue = -90f;
		CameraRoll_Slider.maxValue = 90f;
		CameraRoll_Input.SetTextWithoutNotify("0");
		CameraRoll_Input.onEndEdit.AddListener(OnCameraRollInputChanged);
		CameraRoll_Slider.SetValueWithoutNotify(0f);
		CameraRoll_Slider.onValueChanged.AddListener(OnCameraRollSliderChanged);
		CameraRoll_ResetBtn.onClick.AddListener(() =>
		{
			OnCameraRollInputChanged(origCameraRoll.ToString());
		});
		SunRotation_Toggle.SetIsOnWithoutNotify(value: false);
		SunRotation_Toggle.onValueChanged.AddListener(OnSunRotationToggleChanged);
		SunRotation_Input.SetTextWithoutNotify(0f.ToString());
		SunRotation_Input.onEndEdit.AddListener(OnSunRotationInputChanged);
		SunRotation_Slider.SetValueWithoutNotify(0f);
		SunRotation_Slider.onValueChanged.AddListener(OnSunRotationSliderChanged);
		SunRotation_ResetBtn.onClick.AddListener(() =>
		{
			OnSunRotationSliderChanged(origSunRotation);
		});
		DepthOfField_Toggle.isOn = false;
		DepthOfField_Toggle.onValueChanged.AddListener((bool val) =>
		{
			depthOfField.enabled = val;
		});
		FocalDistance_Slider.minValue = 0f;
		FocalDistance_Slider.maxValue = 20f;
		FocalDistance_Input.SetTextWithoutNotify(origFocalDistance.ToString());
		FocalDistance_Input.onEndEdit.AddListener(OnFocalDistanceInputChanged);
		FocalDistance_Slider.SetValueWithoutNotify(origFocalDistance);
		FocalDistance_Slider.onValueChanged.AddListener(OnFocalDistanceSliderChanged);
		FocalDistance_ResetBtn.onClick.AddListener(() =>
		{
			OnFocalDistanceInputChanged(origFocalDistance.ToString());
		});
		Aperture_Slider.minValue = 0f;
		Aperture_Slider.maxValue = 1f;
		Aperture_Input.SetTextWithoutNotify(origAperture.ToString());
		Aperture_Input.onEndEdit.AddListener(OnApertureInputChanged);
		Aperture_Slider.SetValueWithoutNotify(origAperture);
		Aperture_Slider.onValueChanged.AddListener(OnApertureSliderChanged);
		Aperture_ResetBtn.onClick.AddListener(() =>
		{
			OnApertureInputChanged(origAperture.ToString());
		});
		FocalLength_Slider.minValue = 0f;
		FocalLength_Slider.maxValue = 2f;
		FocalLength_Input.SetTextWithoutNotify(origFocalLength.ToString());
		FocalLength_Input.onEndEdit.AddListener(OnFocalLengthInputChanged);
		FocalLength_Slider.SetValueWithoutNotify(origFocalLength);
		FocalLength_Slider.onValueChanged.AddListener(OnFocalLengthSliderChanged);
		FocalLength_ResetBtn.onClick.AddListener(() =>
		{
			OnFocalLengthInputChanged(origFocalLength.ToString());
		});
		Saturation_Slider.minValue = 0f;
		Saturation_Slider.maxValue = 5f;
		Saturation_Input.SetTextWithoutNotify(origSaturation.ToString());
		Saturation_Input.onEndEdit.AddListener(OnSaturationInputChanged);
		Saturation_Slider.SetValueWithoutNotify(origSaturation);
		Saturation_Slider.onValueChanged.AddListener(OnSaturationSliderChanged);
		Saturation_ResetBtn.onClick.AddListener(() =>
		{
			OnSaturationInputChanged(origSaturation.ToString());
		});
		Contrast_Slider.minValue = 0f;
		Contrast_Slider.maxValue = 100f;
		Contrast_Input.SetTextWithoutNotify(origContrast.ToString());
		Contrast_Input.onEndEdit.AddListener(OnContrastInputChanged);
		Contrast_Slider.SetValueWithoutNotify(origContrast);
		Contrast_Slider.onValueChanged.AddListener(OnContrastSliderChanged);
		Contrast_ResetBtn.onClick.AddListener(() =>
		{
			OnContrastInputChanged(origContrast.ToString());
		});
		Gamma_Slider.minValue = 0f;
		Gamma_Slider.maxValue = 3f;
		Gamma_Input.SetTextWithoutNotify(origGamma.ToString());
		Gamma_Input.onEndEdit.AddListener(OnGammaInputChanged);
		Gamma_Slider.SetValueWithoutNotify(origGamma);
		Gamma_Slider.onValueChanged.AddListener(OnGammaSliderChanged);
		Gamma_ResetBtn.onClick.AddListener(() =>
		{
			OnGammaInputChanged(origGamma.ToString());
		});
		Bloom_Intensity_Slider.minValue = 0f;
		Bloom_Intensity_Slider.maxValue = 10f;
		Bloom_Intensity_Input.SetTextWithoutNotify(origGamma.ToString());
		Bloom_Intensity_Input.onEndEdit.AddListener(OnBloomIntensityInputChanged);
		Bloom_Intensity_Slider.SetValueWithoutNotify(origGamma);
		Bloom_Intensity_Slider.onValueChanged.AddListener(OnBloomIntensitySliderChanged);
		Bloom_Intensity_ResetBtn.onClick.AddListener(() =>
		{
			OnBloomIntensityInputChanged(origBloomIntensity.ToString());
		});
		Bloom_Threshold_Slider.minValue = -0.05f;
		Bloom_Threshold_Slider.maxValue = 4f;
		Bloom_Threshold_Input.SetTextWithoutNotify(origGamma.ToString());
		Bloom_Threshold_Input.onEndEdit.AddListener(OnBloomThresholdInputChanged);
		Bloom_Threshold_Slider.SetValueWithoutNotify(origGamma);
		Bloom_Threshold_Slider.onValueChanged.AddListener(OnBloomThresholdSliderChanged);
		Bloom_Threshold_ResetBtn.onClick.AddListener(() =>
		{
			OnBloomThresholdInputChanged(origBloomThreshold.ToString());
		});
		WhiteBalance_R_Input.SetTextWithoutNotify(origWhiteBalance.r.ToString());
		WhiteBalance_R_Input.onEndEdit.AddListener(OnWhiteBalanceRInputChanged);
		WhiteBalance_R_Slider.SetValueWithoutNotify(origWhiteBalance.r);
		WhiteBalance_R_Slider.onValueChanged.AddListener(OnWhiteBalanceRSliderChanged);
		WhiteBalance_R_ResetBtn.onClick.AddListener(() =>
		{
			OnWhiteBalanceRInputChanged(origWhiteBalance.r.ToString());
		});
		WhiteBalance_G_Input.SetTextWithoutNotify(origWhiteBalance.g.ToString());
		WhiteBalance_G_Input.onEndEdit.AddListener(OnWhiteBalanceGInputChanged);
		WhiteBalance_G_Slider.SetValueWithoutNotify(origWhiteBalance.g);
		WhiteBalance_G_Slider.onValueChanged.AddListener(OnWhiteBalanceGSliderChanged);
		WhiteBalance_G_ResetBtn.onClick.AddListener(() =>
		{
			OnWhiteBalanceGInputChanged(origWhiteBalance.g.ToString());
		});
		WhiteBalance_B_Input.SetTextWithoutNotify(origWhiteBalance.b.ToString());
		WhiteBalance_B_Input.onEndEdit.AddListener(OnWhiteBalanceBInputChanged);
		WhiteBalance_B_Slider.SetValueWithoutNotify(origWhiteBalance.b);
		WhiteBalance_B_Slider.onValueChanged.AddListener(OnWhiteBalanceBSliderChanged);
		WhiteBalance_B_ResetBtn.onClick.AddListener(() =>
		{
			OnWhiteBalanceBInputChanged(origWhiteBalance.b.ToString());
		});
		Vignette_Toggle.onValueChanged.AddListener((bool isOn) =>
		{
			vignette.enabled = isOn;
		});
		Vignette_Sharpness_Slider.minValue = -100f;
		Vignette_Sharpness_Slider.maxValue = 100f;
		Vignette_Sharpness_Input.SetTextWithoutNotify(vignette.Sharpness.ToString());
		Vignette_Sharpness_Input.onEndEdit.AddListener(OnVignetteSharpnessInputChanged);
		Vignette_Sharpness_Slider.SetValueWithoutNotify(vignette.Sharpness);
		Vignette_Sharpness_Slider.onValueChanged.AddListener(OnVignetteSharpnessSliderChanged);
		Vignette_Sharpness_ResetBtn.onClick.AddListener(() =>
		{
			OnVignetteSharpnessInputChanged(origVignetteSharpness.ToString());
		});
		Vignette_Darkness_Slider.minValue = 0f;
		Vignette_Darkness_Slider.maxValue = 100f;
		Vignette_Darkness_Input.SetTextWithoutNotify(vignette.Darkness.ToString());
		Vignette_Darkness_Input.onEndEdit.AddListener(OnVignetteDarknessInputChanged);
		Vignette_Darkness_Slider.SetValueWithoutNotify(vignette.Darkness);
		Vignette_Darkness_Slider.onValueChanged.AddListener(OnVignetteDarknessSliderChanged);
		Vignette_Darkness_ResetBtn.onClick.AddListener(() =>
		{
			OnVignetteDarknessInputChanged(origVignetteDarkness.ToString());
		});
		Exit_Button.onClick.AddListener(() =>
		{
			SetVisibility(v: false);
		});
		Pin_Toggle.onValueChanged.AddListener((bool val) =>
		{
			isPinned = val;
			Pin_Image.sprite = (val ? Pinned_Icon : Unpinned_Icon);
		});
		for (int num = 0; num < tabToggles.Length; num++)
		{
			int p = num;
			tabToggles[num].onValueChanged.AddListener((bool isOn) =>
			{
				OnTabClicked(isOn, p);
			});
		}
		photoFogLighting.setSunLightRotation = true;
		activeTrack = null;
		newTrackBtn.onClick.AddListener(OnAddNewTrack);
		addLocationBtn.onClick.AddListener(() =>
		{
			OnAddKeyframe(cam.transform.position, cam.transform.rotation, doSfx: true, markDirty: true);
		});
		speedInput.onSelect.AddListener((string val) =>
		{
			isInteractingWithUI = true;
		});
		speedInput.onEndEdit.AddListener((string val) =>
		{
			isInteractingWithUI = false;
			TryAddToAnimationSpeed();
		});
		speedIncrementBtn.onClick.AddListener(() =>
		{
			TryAddToAnimationSpeed(1);
		});
		speedDecrementBtn.onClick.AddListener(() =>
		{
			TryAddToAnimationSpeed(-1);
		});
		animPlayBtn.onClick.AddListener(() =>
		{
			if (isAnimating)
			{
				PauseAnimation();
			}
			else
			{
				PlayAnimation();
			}
		});
		animStopBtn.onClick.AddListener(StopAnimation);
		animSlider.onValueChanged.AddListener(OnAnimSliderChanged);
	}

	private void Start()
	{
		Util.SetEnabled(this, active: false);
		speedInput.text = "5";
		animationSpeed = MAX_ANIMATION_SPEED * 0.5f;
		string text = (isAnimating ? LocalizationManager.GetTranslation("settingsui_keybind_name_pausespeed") : LocalizationManager.GetTranslation("constructui_tooltip_play"));
		text = text + Environment.NewLine + string.Format(LocalizationManager.GetTranslation("tooltipui_hotkey"), ConfigurableControls.KeyChord.GetLocalizedKeyName(KeyCode.P));
		animPlayHook.toolTipText = text;
		animStopHook.onLocalize = (string str) => LocalizationManager.GetTranslation(str) + Environment.NewLine + string.Format(LocalizationManager.GetTranslation("tooltipui_hotkey"), ConfigurableControls.KeyChord.GetLocalizedKeyName(KeyCode.O));
		speedIncrementHook.onLocalize = (string str) => string.Format(LocalizationManager.GetTranslation(str), ConfigurableControls.KeyChord.GetLocalizedKeyName(KeyCode.Equals));
		speedDecrementHook.onLocalize = (string str) => string.Format(LocalizationManager.GetTranslation(str), ConfigurableControls.KeyChord.GetLocalizedKeyName(KeyCode.Minus));
		LoadCinematic();
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		Vector3 position = cam.transform.position;
		Vector3 forward = cam.transform.forward;
		Vector3 right = cam.transform.right;
		isLocationAlreadyStored = false;
		if (keyframes.Count > 0)
		{
			List<Keyframe> list = keyframes;
			if (Mathff.DistSqrd(list[list.Count - 1].pos, position) < 0.01f)
			{
				isLocationAlreadyStored = true;
			}
			for (int i = 0; i < keyframes.Count; i++)
			{
				Keyframe keyframe = keyframes[i];
				Util.SetActive(keyframe.entryUI.disabledObj, keyframe.isInvalid);
			}
		}
		addLocationBtn.interactable = !isLocationAlreadyStored && !isAnimating;
		addLocationInvalidTooltip.enabled = isLocationAlreadyStored;
		float axis = Input.GetAxis("Mouse ScrollWheel");
		if (Mathff.Abs(axis) > 0.09f && !EventSystem.current.IsPointerOverGameObject())
		{
			int num = Mathf.FloorToInt(axis / 0.1f);
			moveSpeed = Mathff.Clamp(moveSpeed + (float)num * (MAX_MOVE_SPEED / (float)MOVE_SPEED_STEPS), MIN_MOVE_SPEED, MAX_MOVE_SPEED);
		}
		if (Util.SetEnabled(animPlayIconImg, !isAnimating))
		{
			string text = (isAnimating ? LocalizationManager.GetTranslation("settingsui_keybind_name_pausespeed") : LocalizationManager.GetTranslation("constructui_tooltip_play"));
			text = text + Environment.NewLine + string.Format(LocalizationManager.GetTranslation("tooltipui_hotkey"), ConfigurableControls.KeyChord.GetLocalizedKeyName(KeyCode.P));
			animPlayHook.toolTipText = text;
		}
		Util.SetEnabled(animPauseIconImg, isAnimating);
		bool flag = false;
		float num2 = unscaledDeltaTime;
		if (Input.GetMouseButtonDown(1))
		{
			initMousePos = Input.mousePosition;
			phi = (initRot.x = Mathf.DeltaAngle(0f, cam.transform.eulerAngles.x));
			theta = (initRot.y = cam.transform.eulerAngles.y);
			Cursor.visible = false;
			isAnimating = false;
		}
		if (Input.GetMouseButton(1))
		{
			Vector3 vector = Input.mousePosition - initMousePos;
			theta = Mathff.Lerp(theta, initRot.y + vector.x * rotationStrength, Mathff.Clamp01(unscaledDeltaTime * rotationSpeed));
			float b = Mathff.Clamp(initRot.x - vector.y * rotationStrength, -89f, 89f);
			phi = Mathff.Lerp(phi, b, Mathff.Clamp01(unscaledDeltaTime * rotationSpeed));
			cam.transform.rotation = Quaternion.Euler(phi, theta, 0f - CameraRoll_Slider.value);
			isCamPosRotDirty = true;
			flag = true;
			isAnimating = false;
		}
		if (Input.GetMouseButtonUp(1))
		{
			Cursor.visible = true;
		}
		if (!isInteractingWithUI)
		{
			Vector3 zero = Vector3.zero;
			if (Input.GetKey(KeyCode.LeftShift))
			{
				num2 *= moveSpeedMod;
			}
			if (Input.GetKey(KeyCode.W))
			{
				zero += forward;
			}
			if (Input.GetKey(KeyCode.A))
			{
				zero -= right;
			}
			if (Input.GetKey(KeyCode.S))
			{
				zero -= forward;
			}
			if (Input.GetKey(KeyCode.D))
			{
				zero += right;
			}
			position += zero.normalized * (num2 * moveSpeed);
			if (Input.GetKey(KeyCode.Q))
			{
				position += Vector3.up * (num2 * moveSpeed);
			}
			if (Input.GetKey(KeyCode.E))
			{
				position -= Vector3.up * (num2 * moveSpeed);
			}
			if (zero.magnitude > 0f || Mathff.DistSqrd(position, cam.transform.position) > 0.001f)
			{
				isCamPosRotDirty = true;
				cam.transform.position = position;
				isAnimating = false;
			}
		}
		if (!isInteractingWithUI && (Input.GetKeyUp(KeyCode.Equals) || Input.GetKeyUp(KeyCode.Minus)) && int.TryParse(speedInput.text, out var _))
		{
			TryAddToAnimationSpeed(Input.GetKeyUp(KeyCode.Equals) ? 1 : (-1));
		}
		isAnimating &= animationIdx < spline.splinePoints.Count - 1;
		if (isAnimating)
		{
			float num3 = unscaledDeltaTime;
			num3 *= animationSpeed;
			int num4 = animationIdx / (spline.resolution - 1);
			Vector3 pos = splineKeyframes[num4].pos;
			Vector3 pos2 = splineKeyframes[num4 + 1].pos;
			Quaternion rot = splineKeyframes[num4].rot;
			Quaternion rot2 = splineKeyframes[num4 + 1].rot;
			Vector3 newPos = cam.transform.position;
			Quaternion rotation = cam.transform.rotation;
			while (isAnimating && num3 > 0f)
			{
				Vector3 next = spline.splinePoints[animationIdx + 1];
				bool flag2 = Mathff.MoveTowards(newPos, next, num3, out var actualAmt, out newPos);
				num3 -= actualAmt;
				currDist += actualAmt;
				if (!flag2)
				{
					break;
				}
				animationIdx++;
				if (animationIdx == spline.splinePoints.Count - 1)
				{
					isAnimating = false;
				}
			}
			float num5 = Mathff.DistSqrd(pos, pos2);
			float num6 = Mathff.DistSqrd(newPos, pos2);
			float num7 = 1f - num6 / num5;
			rotation = Quaternion.Lerp(rot, rot2, num7 * num7);
			cam.transform.position = newPos;
			cam.transform.rotation = rotation;
			UpdateTimelineTime();
		}
		PointerEventData pointerEventData = new PointerEventData(EventSystem.current);
		pointerEventData.position = Input.mousePosition;
		results.Clear();
		isHovering = false;
		gRaycaster.Raycast(pointerEventData, results);
		for (int j = 0; j < results.Count; j++)
		{
			if (results[j].gameObject == rectT.gameObject)
			{
				isHovering = true;
				break;
			}
		}
		if (!isHovering && !isPinned && GUICamera.inst.cam.ScreenToViewportPoint(flag ? initMousePos : Input.mousePosition).x < 0.98f)
		{
			Vector2 anchoredPosition = rectT.anchoredPosition;
			anchoredPosition.x = Mathff.Lerp(anchoredPosition.x, rectT.sizeDelta.x + 10f, unscaledDeltaTime * slideSpeed);
			rectT.anchoredPosition = anchoredPosition;
		}
		else
		{
			Vector2 anchoredPosition2 = rectT.anchoredPosition;
			anchoredPosition2.x = Mathff.Lerp(anchoredPosition2.x, 0f, unscaledDeltaTime * slideSpeed);
			rectT.anchoredPosition = anchoredPosition2;
		}
		if (Input.GetKeyUp(KeyCode.P) && keyframes.Count > 1 && !isInteractingWithUI)
		{
			if (isAnimating)
			{
				PauseAnimation();
			}
			else
			{
				PlayAnimation();
			}
		}
		if (Input.GetKeyUp(KeyCode.O) && !isInteractingWithUI)
		{
			StopAnimation();
		}
		if (!isInteractingWithUI && ConfigurableControls.inst.GetInputActionKeyDown(200))
		{
			if (TimeManager.inst.IsPaused())
			{
				TimeManager.inst.ReturnToPrevious();
			}
			else
			{
				TimeManager.inst.SetPaused();
			}
		}
		photoFogLighting.setSunLightRotation = SunRotation_Toggle.isOn;
		if (SunRotation_Toggle.isOn)
		{
			float currentSeasonTime = SeasonManager.inst.CalcSeasonTimeAt24Hour(SunRotation_Slider.value * 24f);
			SeasonDefinition currentSeason = SeasonManager.GetCurrentSeason();
			DayNightManager.inst.GetDayNightParameters(ref PhotoDayNightParameters, currentSeasonTime, currentSeason.duration, currentSeason.nights, currentSeason.nightRatio);
			Vector3 vector2 = Quaternion.AngleAxis(DayNightManager.inst.sunRigRotDegrees, new Vector3(0f, 1f, 0f)) * Vector3.forward;
			Vector3 vector3 = World.inst.GridCenter() + vector2 * DayNightManager.inst.groundDist;
			Vector3 vector4 = Quaternion.AngleAxis(DayNightManager.inst.sunRigRotDegrees, new Vector3(0f, 1f, 0f)) * Vector3.right;
			Vector3 vector5 = Quaternion.AngleAxis(PhotoDayNightParameters.lightProgress * 180f, vector2) * vector4 * DayNightManager.inst.skyDist;
			if (!PhotoDayNightParameters.isDay)
			{
				vector5 = Quaternion.AngleAxis(PhotoDayNightParameters.darkProgress * 180f + 180f, vector2) * vector4 * DayNightManager.inst.skyDist;
			}
			Vector3 vector6 = vector3 + vector5;
			Vector3 sunLightRotation = World.inst.GridCenter() - vector6;
			photoFogLighting.sunLightRotation = sunLightRotation;
			World.inst.romeUnimaterial.SetFloat("_NightProgress", PhotoDayNightParameters.darkProgress);
			TerrainGen.inst.TerrainMaterial.SetFloat("_DayNight", PhotoDayNightParameters.noonToMidnightProgress);
		}
		FogAndLightingStack.inst.SetPhotoSettings(ref photoFogLighting);
		Util.SetActive(RotationSpeed_ResetBtn.gameObject, (float)origRotationSpeed != rotationSpeed);
		Util.SetActive(FieldOfView_ResetBtn.gameObject, (float)origFieldOfView != FieldOfView_Slider.value);
		Util.SetActive(CameraRoll_ResetBtn.gameObject, (float)origCameraRoll != CameraRoll_Slider.value);
		Util.SetActive(FocalDistance_ResetBtn.gameObject, origFocalDistance != FocalDistance_Slider.value);
		Util.SetActive(Aperture_ResetBtn.gameObject, origAperture != Aperture_Slider.value);
		Util.SetActive(FocalLength_ResetBtn.gameObject, origFocalLength != FocalLength_Slider.value);
		Util.SetActive(SunRotation_ResetBtn.gameObject, origSunRotation != SunRotation_Slider.value);
		Util.SetActive(Saturation_ResetBtn.gameObject, origSaturation != Saturation_Slider.value);
		Util.SetActive(Contrast_ResetBtn.gameObject, origContrast != Contrast_Slider.value);
		Util.SetActive(Gamma_ResetBtn.gameObject, origGamma != Gamma_Slider.value);
		Util.SetActive(Bloom_Intensity_ResetBtn.gameObject, origBloomIntensity != Bloom_Intensity_Slider.value);
		Util.SetActive(Bloom_Threshold_ResetBtn.gameObject, origBloomThreshold != Bloom_Threshold_Slider.value);
		Util.SetActive(WhiteBalance_R_ResetBtn.gameObject, origWhiteBalance.r != WhiteBalance_R_Slider.value);
		Util.SetActive(WhiteBalance_G_ResetBtn.gameObject, origWhiteBalance.g != WhiteBalance_G_Slider.value);
		Util.SetActive(WhiteBalance_B_ResetBtn.gameObject, origWhiteBalance.b != WhiteBalance_B_Slider.value);
		Util.SetActive(Vignette_Sharpness_ResetBtn.gameObject, origVignetteSharpness != Vignette_Sharpness_Slider.value);
		Util.SetActive(Vignette_Darkness_ResetBtn.gameObject, origVignetteDarkness != Vignette_Darkness_Slider.value);
		Cam.inst.CamPos = cam.transform.position;
		Util.SetActive(activeTrackChangesObj, isActiveTrackDirty && activeTrack != null);
		Util.SetActive(locationsObj, activeTrack != null);
		Util.SetActive(timelineObj, keyframes.Count >= 2);
		if (isDragging && Mathff.Abs(edgeScrolling) > 0.0001f)
		{
			locationScrollRect.verticalNormalizedPosition = Mathff.Clamp01(locationScrollRect.verticalNormalizedPosition + edgeScrolling);
		}
		if (activeTrack != null && activeTrack.entryUI != null)
		{
			Util.SetActive(activeTrack.entryUI.saveBtn.gameObject, isActiveTrackDirty && activeTrack != null);
		}
		for (int k = 0; k < keyframes.Count; k++)
		{
			Keyframe keyframe2 = keyframes[k];
			if (dragEntry == keyframe2.entryUI)
			{
				continue;
			}
			Vector3 a = keyframe2.entryUI.rectT.anchoredPosition;
			Vector3 b2 = keyframe2.entryUI.layoutRectT.anchoredPosition;
			keyframe2.entryUI.rectT.anchoredPosition = Vector3.Lerp(a, b2, unscaledDeltaTime * locationLayoutSpeed);
			if (keyframe2.entryUI.doPositionInstant > 0)
			{
				keyframe2.entryUI.doPositionInstant--;
				if (keyframe2.entryUI.doPositionInstant == 0)
				{
					keyframe2.entryUI.rectT.anchoredPosition = keyframe2.entryUI.layoutRectT.anchoredPosition;
				}
			}
		}
		speedDecrementBtn.interactable = (double)animationSpeed > (double)MAX_ANIMATION_SPEED * 0.1;
		speedIncrementBtn.interactable = animationSpeed < MAX_ANIMATION_SPEED;
	}

	private void OnAnimSliderChanged(float norm)
	{
		float totalDistanceInAnimation = GetTotalDistanceInAnimation();
		if (totalDistanceInAnimation <= 0f)
		{
			return;
		}
		float num = totalDistanceInAnimation * norm;
		float num2 = 0f;
		for (int i = 0; i < spline.splinePoints.Count - 1; i++)
		{
			Vector3 a = spline.splinePoints[i];
			Vector3 b = spline.splinePoints[i + 1];
			float num3 = Mathff.Dist(a, b);
			if (num3 + num2 > num)
			{
				int num4 = i / (spline.resolution - 1);
				Quaternion rot = splineKeyframes[num4].rot;
				Quaternion rot2 = splineKeyframes[num4 + 1].rot;
				float num5 = num - num2;
				float t = num5 / num3;
				Vector3 vector = Vector3.Lerp(a, b, t);
				Vector3 pos = splineKeyframes[num4 + 1].pos;
				float num6 = Mathff.DistSqrd(vector, pos);
				float num7 = Mathff.DistSqrd(splineKeyframes[num4].pos, pos);
				float num8 = 1f - num6 / num7;
				Quaternion rotation = Quaternion.Lerp(rot, rot2, num8 * num8);
				animationIdx = i;
				currDist = num2 + num5;
				cam.transform.position = vector;
				cam.transform.rotation = rotation;
				isCamPosRotDirty = false;
				break;
			}
			num2 += num3;
		}
	}

	private void PauseAnimation()
	{
		isAnimating = false;
	}

	private void StopAnimation()
	{
		isAnimating = false;
		ResetAnimationTimeline(applyPos: true);
	}

	private void PlayAnimation()
	{
		if (spline.splinePoints.Count >= 2)
		{
			if (isCamPosRotDirty || animationIdx >= spline.splinePoints.Count - 1)
			{
				ResetAnimationTimeline(applyPos: true);
			}
			isAnimating = true;
			cachedDist = GetTotalDistanceInAnimation();
		}
	}

	private void ResetAnimationTimeline(bool applyPos = false)
	{
		animationIdx = 0;
		currDist = 0f;
		cachedDist = GetTotalDistanceInAnimation();
		UpdateTimelineTime();
		isCamPosRotDirty = true;
		if (applyPos && keyframes.Count > 0)
		{
			cam.transform.position = keyframes[0].pos;
			cam.transform.rotation = keyframes[0].rot;
			isCamPosRotDirty = false;
		}
	}

	private void UpdateTimelineTime()
	{
		float num = cachedDist / animationSpeed;
		float num2 = ((cachedDist == 0f) ? 0f : (currDist / cachedDist));
		float num3 = num2 * num;
		string text = TimeSpan.FromSeconds(num).ToString("mm\\:ss");
		string text2 = TimeSpan.FromSeconds(num3).ToString("mm\\:ss");
		animSlider.SetValueWithoutNotify(num2);
		animTimeTMP.text = text2 + " / " + text;
	}

	private void UpdateTracks()
	{
		trackPoolCount = 0;
		for (int i = 0; i < keyframeGroups.Count; i++)
		{
			KeyframeGroup group = keyframeGroups[i];
			bool active = false;
			if (activeTrack != null && activeTrack.Equals(group))
			{
				active = true;
			}
			PhotoModeTrackEntryUI entry = GetTrackEntry();
			group.entryUI = entry;
			entry.nameInput.text = group.name;
			Util.SetEnabled(entry.isActiveImg, active);
			entry.selectBtn.onClick.RemoveAllListeners();
			entry.selectBtn.onClick.AddListener(() =>
			{
				OnSelectTrack(group);
			});
			entry.removeBtn.onClick.RemoveAllListeners();
			entry.removeBtn.onClick.AddListener(() =>
			{
				OnDeleteTrack(group);
			});
			entry.nameInput.onEndEdit.RemoveAllListeners();
			entry.nameInput.onEndEdit.AddListener((string val) =>
			{
				isInteractingWithUI = false;
				OnDeselectNameInput(val, entry, group);
			});
		}
		for (int num = trackPoolCount; num < trackPool.Count; num++)
		{
			Util.SetActive(trackPool.data[num].gameObject, active: false);
		}
	}

	private PhotoModeTrackEntryUI GetTrackEntry()
	{
		if (trackPoolCount >= trackPool.Count)
		{
			PhotoModeTrackEntryUI newEntry = UnityEngine.Object.Instantiate(trackEntryPrefab, trackContainer, worldPositionStays: false);
			newEntry.nameInput.GetComponentInChildren<TMP_SelectionCaret>().raycastTarget = false;
			newEntry.saveBtn.onClick.AddListener(OnSaveTrack);
			newEntry.nameInput.onSelect.AddListener((string val) =>
			{
				isInteractingWithUI = true;
			});
			newEntry.editNameBtn.onClick.AddListener(() =>
			{
				newEntry.nameInput.interactable = !newEntry.nameInput.interactable;
				if (newEntry.nameInput.interactable)
				{
					newEntry.nameInput.ActivateInputField();
				}
				else
				{
					newEntry.nameInput.DeactivateInputField();
				}
			});
			trackPool.Add(newEntry);
		}
		PhotoModeTrackEntryUI obj = trackPool.data[trackPoolCount++];
		Util.SetActive(obj.gameObject, active: true);
		Util.SetActive(obj.saveBtn.gameObject, active: false);
		return obj;
	}

	private void OnDeselectNameInput(string val, PhotoModeTrackEntryUI entry, KeyframeGroup targetGroup)
	{
		if (string.IsNullOrEmpty(val.Trim()))
		{
			val = targetGroup.name;
		}
		targetGroup.name = val;
		entry.nameInput.text = val;
		entry.nameInput.interactable = false;
		SaveCinematic();
	}

	private void OnSelectTrack(KeyframeGroup targetGroup)
	{
		for (int i = 0; i < keyframeGroups.Count; i++)
		{
			KeyframeGroup entry = keyframeGroups[i];
			if (!entry.Equals(targetGroup))
			{
				continue;
			}
			if (isActiveTrackDirty)
			{
				unsavedConfirmation.ShowConfirmation(() =>
				{
					SetActiveTrack(entry);
				}, () =>
				{
				});
			}
			else
			{
				SetActiveTrack(entry);
			}
			break;
		}
	}

	private void SetActiveTrack(KeyframeGroup group)
	{
		if (group == null)
		{
			Debug.LogError("Group is null!?");
		}
		SfxSystem.PlayUiSelect();
		ClearLocations();
		if (group.keyframes != null)
		{
			for (int i = 0; i < group.keyframes.Length; i++)
			{
				KeyframeSaveData keyframeSaveData = group.keyframes[i];
				OnAddKeyframe(keyframeSaveData.pos, keyframeSaveData.rot);
			}
		}
		activeTrack = group;
		isActiveTrackDirty = false;
		UpdateTracks();
		ResetAnimationTimeline();
		isAnimating = false;
	}

	private void ClearLocations()
	{
		for (int i = 0; i < keyframes.Count; i++)
		{
			Keyframe keyframe = keyframes[i];
			UnityEngine.Object.DestroyImmediate(keyframe.entryUI.gameObject);
			UnityEngine.Object.DestroyImmediate(keyframe.entryUI.layoutRectT.gameObject);
		}
		keyframes.Clear();
		OrganizeKeyframesAndGenerateSpline();
	}

	private void OnRotationSpeedInputChanged(string str)
	{
		int result = 0;
		if (int.TryParse(str, out result))
		{
			result = Mathff.Clamp(result, 3, 20);
			RotationSpeed_Slider.SetValueWithoutNotify(result);
			RotationSpeed_Input.SetTextWithoutNotify(result.ToString());
			rotationSpeed = result;
		}
	}

	private void OnRotationSpeedSliderChanged(float val)
	{
		RotationSpeed_Input.SetTextWithoutNotify(val.ToString());
		RotationSpeed_Slider.SetValueWithoutNotify(val);
		rotationSpeed = val;
	}

	private void OnFieldOfViewInputChanged(string str)
	{
		int result = 0;
		if (int.TryParse(str, out result))
		{
			result = Mathff.Clamp(result, 10, 120);
			FieldOfView_Slider.SetValueWithoutNotify(result);
			FieldOfView_Input.SetTextWithoutNotify(result.ToString());
			camera.fieldOfView = result;
		}
	}

	private void OnFieldOfViewSliderChanged(float val)
	{
		FieldOfView_Input.SetTextWithoutNotify(val.ToString());
		FieldOfView_Slider.SetValueWithoutNotify(val);
		camera.fieldOfView = val;
	}

	private void OnCameraRollInputChanged(string str)
	{
		int result = 0;
		if (int.TryParse(str, out result))
		{
			result = Mathff.Clamp(result, -90, 90);
			CameraRoll_Slider.SetValueWithoutNotify(result);
			CameraRoll_Input.SetTextWithoutNotify(result.ToString());
			Vector3 eulerAngles = cam.transform.eulerAngles;
			eulerAngles.z = -result;
			cam.transform.rotation = Quaternion.Euler(eulerAngles);
		}
	}

	private void OnCameraRollSliderChanged(float val)
	{
		CameraRoll_Input.SetTextWithoutNotify(val.ToString());
		CameraRoll_Slider.SetValueWithoutNotify(val);
		Vector3 eulerAngles = cam.transform.eulerAngles;
		eulerAngles.z = 0f - val;
		cam.transform.rotation = Quaternion.Euler(eulerAngles);
	}

	private void OnSunRotationToggleChanged(bool isOn)
	{
		if (isOn)
		{
			PhotoDayNightParameters = DayNightManager.inst.GameParameters;
			origSunRotation = PhotoDayNightParameters._24HourTime / 24f;
			SunRotation_Input.SetTextWithoutNotify(origSunRotation.ToString());
			SunRotation_Slider.SetValueWithoutNotify(origSunRotation);
		}
		else
		{
			SunRotation_Input.SetTextWithoutNotify(origSunRotation.ToString());
			SunRotation_Slider.SetValueWithoutNotify(origSunRotation);
		}
	}

	private void OnSunRotationInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = Mathff.Clamp01(result);
			SunRotation_Slider.SetValueWithoutNotify(result);
			SunRotation_Input.SetTextWithoutNotify(result.ToString());
		}
	}

	private void OnSunRotationSliderChanged(float val)
	{
		SunRotation_Input.SetTextWithoutNotify(val.ToString());
		SunRotation_Slider.SetValueWithoutNotify(val);
	}

	private void OnFocalDistanceInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, 0f, 20f), 2);
			FocalDistance_Slider.SetValueWithoutNotify(result);
			FocalDistance_Input.SetTextWithoutNotify(result.ToString());
			depthOfField.focalLength = result;
		}
	}

	private void OnFocalDistanceSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, 0f, 20f), 2);
		FocalDistance_Slider.SetValueWithoutNotify(val);
		FocalDistance_Input.SetTextWithoutNotify(val.ToString());
		depthOfField.focalLength = val;
	}

	private void OnApertureInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, 0f, 1f), 2);
			Aperture_Slider.SetValueWithoutNotify(result);
			Aperture_Input.SetTextWithoutNotify(Math.Round(result, 2).ToString());
			depthOfField.aperture = result;
		}
	}

	private void OnApertureSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, 0f, 1f), 2);
		Aperture_Slider.SetValueWithoutNotify(val);
		Aperture_Input.SetTextWithoutNotify(val.ToString());
		depthOfField.aperture = val;
	}

	private void OnFocalLengthInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, 0f, 2f), 2);
			FocalLength_Slider.SetValueWithoutNotify(result);
			FocalLength_Input.SetTextWithoutNotify(Math.Round(result, 2).ToString());
			depthOfField.focalSize = result;
		}
	}

	private void OnFocalLengthSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, 0f, 2f), 2);
		FocalLength_Slider.SetValueWithoutNotify(val);
		FocalLength_Input.SetTextWithoutNotify(val.ToString());
		depthOfField.focalSize = val;
	}

	private void OnSaturationInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, 0f, 5f), 2);
			Saturation_Slider.SetValueWithoutNotify(result);
			Saturation_Input.SetTextWithoutNotify(Math.Round(result, 2).ToString());
			colorCorrection.saturation = result;
		}
	}

	private void OnSaturationSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, 0f, 5f), 2);
		Saturation_Slider.SetValueWithoutNotify(val);
		Saturation_Input.SetTextWithoutNotify(val.ToString());
		colorCorrection.saturation = val;
	}

	private void OnContrastInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, 0f, 100f), 2);
			Contrast_Slider.SetValueWithoutNotify(result);
			Contrast_Input.SetTextWithoutNotify(Math.Round(result, 2).ToString());
			levels.InputL.x = result;
		}
	}

	private void OnContrastSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, 0f, 100f), 2);
		Contrast_Slider.SetValueWithoutNotify(val);
		Contrast_Input.SetTextWithoutNotify(val.ToString());
		levels.InputL.x = val;
	}

	private void OnGammaInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, 0f, 3f), 2);
			Gamma_Slider.SetValueWithoutNotify(result);
			Gamma_Input.SetTextWithoutNotify(Math.Round(result, 2).ToString());
			levels.InputL.z = result;
		}
	}

	private void OnGammaSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, 0f, 3f), 2);
		Gamma_Slider.SetValueWithoutNotify(val);
		Gamma_Input.SetTextWithoutNotify(val.ToString());
		levels.InputL.z = val;
	}

	private void OnBloomIntensityInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, 0f, 10f), 2);
			Bloom_Intensity_Slider.SetValueWithoutNotify(result);
			Bloom_Intensity_Input.SetTextWithoutNotify(Math.Round(result, 2).ToString());
			bloom.bloomIntensity = result;
		}
	}

	private void OnBloomIntensitySliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, 0f, 10f), 2);
		Bloom_Intensity_Slider.SetValueWithoutNotify(val);
		Bloom_Intensity_Input.SetTextWithoutNotify(Math.Round(val, 2).ToString());
		bloom.bloomIntensity = val;
	}

	private void OnBloomThresholdInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, -0.05f, 4f), 2);
			Bloom_Threshold_Slider.SetValueWithoutNotify(result);
			Bloom_Threshold_Input.SetTextWithoutNotify(Math.Round(result, 2).ToString());
			bloom.bloomThreshold = result;
		}
	}

	private void OnBloomThresholdSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, -0.05f, 4f), 2);
		Bloom_Threshold_Slider.SetValueWithoutNotify(val);
		Bloom_Threshold_Input.SetTextWithoutNotify(Math.Round(val, 2).ToString());
		bloom.bloomThreshold = val;
	}

	private void OnWhiteBalanceRInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp01(result), 2);
			WhiteBalance_R_Slider.SetValueWithoutNotify(result);
			WhiteBalance_R_Input.SetTextWithoutNotify(result.ToString());
			whiteBalance.White.r = result;
			WhiteBalance_Reference.color = whiteBalance.White;
		}
	}

	private void OnWhiteBalanceRSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp01(val), 2);
		WhiteBalance_R_Slider.SetValueWithoutNotify(val);
		WhiteBalance_R_Input.SetTextWithoutNotify(val.ToString());
		whiteBalance.White.r = val;
		WhiteBalance_Reference.color = whiteBalance.White;
	}

	private void OnWhiteBalanceGInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp01(result), 2);
			WhiteBalance_G_Slider.SetValueWithoutNotify(result);
			WhiteBalance_G_Input.SetTextWithoutNotify(result.ToString());
			whiteBalance.White.g = result;
			WhiteBalance_Reference.color = whiteBalance.White;
		}
	}

	private void OnWhiteBalanceGSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp01(val), 2);
		WhiteBalance_G_Slider.SetValueWithoutNotify(val);
		WhiteBalance_G_Input.SetTextWithoutNotify(val.ToString());
		whiteBalance.White.g = val;
		WhiteBalance_Reference.color = whiteBalance.White;
	}

	private void OnWhiteBalanceBInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp01(result), 2);
			WhiteBalance_B_Slider.SetValueWithoutNotify(result);
			WhiteBalance_B_Input.SetTextWithoutNotify(result.ToString());
			whiteBalance.White.b = result;
			WhiteBalance_Reference.color = whiteBalance.White;
		}
	}

	private void OnWhiteBalanceBSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp01(val), 2);
		WhiteBalance_B_Slider.SetValueWithoutNotify(val);
		WhiteBalance_B_Input.SetTextWithoutNotify(val.ToString());
		whiteBalance.White.b = val;
		WhiteBalance_Reference.color = whiteBalance.White;
	}

	private void OnVignetteSharpnessInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, -100f, 100f), 2);
			Vignette_Sharpness_Slider.SetValueWithoutNotify(result);
			Vignette_Sharpness_Input.SetTextWithoutNotify(result.ToString());
			vignette.Sharpness = result;
		}
	}

	private void OnVignetteSharpnessSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, -100f, 100f), 2);
		Vignette_Sharpness_Slider.SetValueWithoutNotify(val);
		Vignette_Sharpness_Input.SetTextWithoutNotify(val.ToString());
		vignette.Sharpness = val;
	}

	private void OnVignetteDarknessInputChanged(string str)
	{
		float result = 0f;
		if (float.TryParse(str, out result))
		{
			result = (float)Math.Round(Mathff.Clamp(result, 0f, 100f), 2);
			Vignette_Darkness_Slider.SetValueWithoutNotify(result);
			Vignette_Darkness_Input.SetTextWithoutNotify(result.ToString());
			vignette.Darkness = result;
		}
	}

	private void OnVignetteDarknessSliderChanged(float val)
	{
		val = (float)Math.Round(Mathff.Clamp(val, 0f, 100f), 2);
		Vignette_Darkness_Slider.SetValueWithoutNotify(val);
		Vignette_Darkness_Input.SetTextWithoutNotify(val.ToString());
		vignette.Darkness = val;
	}

	private void OnResetToDefaults()
	{
		OnRotationSpeedInputChanged(origRotationSpeed.ToString());
		OnFieldOfViewInputChanged(origFieldOfView.ToString());
		OnCameraRollInputChanged(0.ToString());
		SunRotation_Toggle.isOn = false;
		DepthOfField_Toggle.isOn = false;
		OnFocalDistanceInputChanged(origFocalDistance.ToString());
		OnApertureInputChanged(origAperture.ToString());
		OnFocalLengthInputChanged(origFocalLength.ToString());
		OnSaturationInputChanged(origSaturation.ToString());
		OnContrastInputChanged(origContrast.ToString());
		OnGammaInputChanged(origGamma.ToString());
		OnVignetteDarknessInputChanged(origVignetteDarkness.ToString());
		OnVignetteSharpnessInputChanged(origVignetteSharpness.ToString());
		Vignette_Toggle.isOn = false;
	}

	private void OnSaveTrack()
	{
		if (activeTrack == null)
		{
			Debug.LogError("Group is null!?");
		}
		KeyframeSaveData[] array = new KeyframeSaveData[keyframes.Count];
		for (int i = 0; i < keyframes.Count; i++)
		{
			array[i] = new KeyframeSaveData
			{
				pos = keyframes[i].pos,
				rot = keyframes[i].rot
			};
		}
		activeTrack.keyframes = array;
		isActiveTrackDirty = false;
		SaveCinematic();
	}

	private void OnDeleteTrack(KeyframeGroup group)
	{
		deleteConfirmationTitle.text = string.Format(LocalizationManager.GetTranslation("photomode_deletetrack_confirmation_title"), group.name);
		deleteConfirmation.ShowConfirmation(() =>
		{
			if (group == activeTrack)
			{
				activeTrack = null;
				isActiveTrackDirty = false;
				ClearLocations();
			}
			keyframeGroups.Remove(group);
			UpdateTracks();
			SaveCinematic();
		}, () =>
		{
		});
	}

	private void OnAddNewTrack()
	{
		KeyframeGroup keyframeGroup = new KeyframeGroup();
		keyframeGroup.name = string.Format(LocalizationManager.GetTranslation("photomodeui_cinematic_track_entry_title"), keyframeGroups.Count + 1);
		keyframeGroups.Add(keyframeGroup);
		OnSelectTrack(keyframeGroup);
		UpdateTracks();
		SaveCinematic();
	}

	private void OnBeginDrag(PointerEventData pData, PhotoModeLocationEntryUI entry)
	{
		if (!isDragging)
		{
			RuntimeManager.PlayOneShot("event:/OldSFX/ui_pickup");
			entry.rectT.SetAsLastSibling();
			originalIdx = entry.layoutRectT.GetSiblingIndex();
			RectTransformUtility.ScreenPointToWorldPointInRectangle(entry.rectT, pData.position, pData.pressEventCamera, out var worldPoint);
			dragOffset = entry.rectT.position - worldPoint;
			dragEntry = entry;
			isDragging = true;
		}
	}

	private void OnDrag(PointerEventData pData, PhotoModeLocationEntryUI entry)
	{
		if (RectTransformUtility.ScreenPointToWorldPointInRectangle(entry.rectT, pData.position, pData.pressEventCamera, out var worldPoint))
		{
			entry.rectT.position = worldPoint + dragOffset;
		}
		if (RectTransformUtility.RectangleContainsScreenPoint(locationScrollViewRectT, pData.position, pData.pressEventCamera))
		{
			if (RectTransformUtility.RectangleContainsScreenPoint(locationLayoutContainer, pData.position, pData.pressEventCamera))
			{
				RectTransformUtility.ScreenPointToLocalPointInRectangle(locationLayoutContainer, pData.position, pData.pressEventCamera, out var localPoint);
				int siblingIndex = Mathff.Max(1, (int)(Mathf.Abs(localPoint.y) / Mathf.Abs(entry.layoutRectT.sizeDelta.y)) + 1);
				entry.layoutRectT.SetSiblingIndex(siblingIndex);
				edgeScrolling = 0f;
			}
			return;
		}
		RectTransformUtility.ScreenPointToLocalPointInRectangle(locationScrollViewRectT, pData.position, pData.pressEventCamera, out var localPoint2);
		if (localPoint2.y + locationScrollViewRectT.rect.y > 0f)
		{
			edgeScrolling = Time.unscaledDeltaTime * Mathff.Clamp01((localPoint2.y + locationScrollViewRectT.rect.y) / (entry.layoutRectT.sizeDelta.y * 1.5f)) * edgeScrollSpeed;
		}
		else if (localPoint2.y < locationScrollViewRectT.rect.y)
		{
			edgeScrolling = Time.unscaledDeltaTime * Mathff.Clamp01((locationScrollViewRectT.rect.y - localPoint2.y) / (entry.layoutRectT.sizeDelta.y * 1.5f)) * (0f - edgeScrollSpeed);
		}
		if (edgeScrolling > 0f)
		{
			entry.layoutRectT.SetSiblingIndex(1);
		}
		if (edgeScrolling < 0f)
		{
			entry.layoutRectT.SetAsLastSibling();
		}
	}

	private void OnEndDrag(PointerEventData pData, PhotoModeLocationEntryUI entry)
	{
		if (isDragging && !(entry != dragEntry) && pData != null)
		{
			RuntimeManager.PlayOneShot("event:/OldSFX/ui_drop");
			bool flag = false;
			for (int i = 0; i < keyframes.Count; i++)
			{
				Keyframe keyframe = keyframes[i];
				int num = (keyframe.idx = keyframe.entryUI.layoutRectT.GetSiblingIndex());
				flag |= i > 0 && num < keyframes[i - 1].idx;
			}
			OrganizeKeyframesAndGenerateSpline();
			if (flag)
			{
				isActiveTrackDirty = true;
				ResetAnimationTimeline(applyPos: true);
			}
			dragEntry = null;
			isDragging = false;
		}
	}

	private void OrganizeKeyframesAndGenerateSpline()
	{
		scratch.Clear();
		scratch.AddRange(keyframes);
		keyframes.Clear();
		for (int i = 0; i < scratch.Count; i++)
		{
			Keyframe keyframe = scratch[i];
			int siblingIndex = keyframe.entryUI.layoutRectT.GetSiblingIndex();
			keyframe.isInvalid = false;
			int j;
			for (j = 0; j < keyframes.Count && keyframes[j].entryUI.layoutRectT.GetSiblingIndex() <= siblingIndex; j++)
			{
			}
			keyframes.Insert(j, keyframe);
		}
		Keyframe keyframe2 = ((keyframes.Count > 0) ? keyframes[0] : null);
		for (int k = 1; k < keyframes.Count; k++)
		{
			Keyframe keyframe3 = keyframes[k];
			if (keyframe2 != null && Mathff.DistSqrd(keyframe2.pos, keyframe3.pos) < 0.01f)
			{
				keyframe3.isInvalid = true;
			}
			if (!keyframe3.isInvalid)
			{
				keyframe2 = keyframe3;
			}
		}
		spline.controlPoints.Clear();
		splineKeyframes.Clear();
		for (int l = 0; l < keyframes.Count; l++)
		{
			if (keyframes[l].isInvalid)
			{
				keyframes[l].entryUI.nameTMP.text = LocalizationManager.GetTranslation("photomodeui_cinematic_invalid_location_title");
				continue;
			}
			keyframes[l].entryUI.nameTMP.text = string.Format(LocalizationManager.GetTranslation("photomodeui_cinematic_location_title"), l + 1);
			spline.controlPoints.Add(keyframes[l].pos);
			splineKeyframes.Add(keyframes[l]);
		}
		spline.GenerateSplinePoints();
	}

	private void OnTabClicked(bool isOn, int idx)
	{
		if (isOn)
		{
			for (int i = 0; i < tabContents.Length; i++)
			{
				tabContents[i].SetActive(i == idx);
			}
			if (idx == 1)
			{
				UpdateTracks();
			}
			SfxSystem.PlayUiSelect();
		}
	}

	private void OnAddKeyframe(Vector3 pos, Quaternion rot, bool doSfx = false, bool markDirty = false)
	{
		Keyframe key = new Keyframe();
		key.pos = pos;
		key.rot = rot;
		if (keyframes.Count > 0)
		{
			List<Keyframe> list = keyframes;
			if (Mathff.DistSqrd(list[list.Count - 1].pos, pos) < 0.01f)
			{
				if (doSfx)
				{
					SfxSystem.PlayUiCancel();
				}
				return;
			}
		}
		if (doSfx)
		{
			SfxSystem.PlayUiSelect();
		}
		isActiveTrackDirty = true;
		key.idx = keyframes.Count;
		keyframes.Add(key);
		RectTransform component = UnityEngine.Object.Instantiate(locationLayoutPrefab, locationLayoutContainer, worldPositionStays: false).GetComponent<RectTransform>();
		PhotoModeLocationEntryUI contentEntry = UnityEngine.Object.Instantiate(locationEntryPrefab, locationContentContainer, worldPositionStays: false);
		contentEntry.layoutRectT = component;
		contentEntry.doPositionInstant = 2;
		key.entryUI = contentEntry;
		contentEntry.removeBtn.onClick.AddListener(() =>
		{
			OnLocationRemoved(key);
		});
		contentEntry.focusBtn.onClick.AddListener(() =>
		{
			OnLocationFocused(key);
		});
		contentEntry.captureBtn.onClick.AddListener(() =>
		{
			OnCaptureLocation(key);
		});
		EventTrigger.Entry entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.BeginDrag
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnBeginDrag((PointerEventData)data, contentEntry);
		});
		contentEntry.eTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.Drag
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnDrag((PointerEventData)data, contentEntry);
		});
		contentEntry.eTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.EndDrag
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnEndDrag((PointerEventData)data, contentEntry);
		});
		contentEntry.eTrigger.triggers.Add(entry);
		OrganizeKeyframesAndGenerateSpline();
	}

	private void OnLocationFocused(Keyframe key)
	{
		SfxSystem.PlayUiSelect();
		isAnimating = false;
		ResetAnimationTimeline();
		cam.transform.position = key.pos;
		cam.transform.rotation = key.rot;
	}

	private void OnCaptureLocation(Keyframe Key)
	{
		SfxSystem.inst.PlayFromBank("ui_edit", Vector3.zero);
		isAnimating = false;
		isActiveTrackDirty = true;
		Key.pos = cam.transform.position;
		Key.rot = cam.transform.rotation;
		OrganizeKeyframesAndGenerateSpline();
		ResetAnimationTimeline();
	}

	private void OnLocationRemoved(Keyframe key)
	{
		SfxSystem.PlayUiClose();
		isActiveTrackDirty = true;
		keyframes.Remove(key);
		UnityEngine.Object.DestroyImmediate(key.entryUI.layoutRectT.gameObject);
		UnityEngine.Object.DestroyImmediate(key.entryUI.gameObject);
		for (int i = 0; i < keyframes.Count; i++)
		{
			Keyframe keyframe = keyframes[i];
			keyframe.idx = keyframe.entryUI.layoutRectT.GetSiblingIndex();
		}
		OrganizeKeyframesAndGenerateSpline();
		ResetAnimationTimeline(applyPos: true);
	}

	public float GetTotalDistanceInAnimation()
	{
		float num = 0f;
		for (int i = 0; i < spline.splinePoints.Count - 1; i++)
		{
			Vector3 a = spline.splinePoints[i];
			Vector3 b = spline.splinePoints[i + 1];
			num += Mathff.Dist(a, b);
		}
		return num;
	}

	public void Reset()
	{
		Cursor.visible = true;
		camera.fieldOfView = origFieldOfView;
		levels.InputL.x = origContrast;
		levels.InputL.z = origGamma;
		colorCorrection.saturation = origSaturation;
		depthOfField.enabled = false;
		vignette.enabled = false;
	}

	public void ApplySettings()
	{
		rotationSpeed = RotationSpeed_Slider.value;
		camera.fieldOfView = FieldOfView_Slider.value;
		levels.InputL.x = Contrast_Slider.value;
		levels.InputL.z = Gamma_Slider.value;
		colorCorrection.saturation = Saturation_Slider.value;
		depthOfField.enabled = DepthOfField_Toggle.isOn;
		depthOfField.aperture = Aperture_Slider.value;
		depthOfField.focalLength = FocalDistance_Slider.value;
		depthOfField.focalSize = FocalLength_Slider.value;
		vignette.enabled = Vignette_Toggle.isOn;
	}

	private void TryAddToAnimationSpeed(int amt = 0)
	{
		if (int.TryParse(speedInput.text, out var result))
		{
			result = Mathff.Clamp(result + amt, 1, 10);
			animationSpeed = (float)result / 10f * MAX_ANIMATION_SPEED;
			speedInput.text = result.ToString();
			UpdateTimelineTime();
		}
	}

	public void SaveCinematic()
	{
		Stream stream = new FileStream(Application.persistentDataPath + "/photomode", FileMode.Create);
		SaveSerializer.SerializeToStream(new PhotoSaveData().Pack(this), stream);
		stream.Close();
		stream.Dispose();
	}

	public void LoadCinematic()
	{
		if (!File.Exists(Application.persistentDataPath + "/photomode"))
		{
			return;
		}
		Stream stream = null;
		try
		{
			stream = new FileStream(Application.persistentDataPath + "/photomode", FileMode.Open);
			SaveSerializer.DeserializeFromStream<PhotoSaveData>(stream).Unpack(this);
		}
		catch (LegacyFormatException ex)
		{
			Debug.LogWarning("[Photomode] " + ex.Message);
		}
		catch
		{
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
}
