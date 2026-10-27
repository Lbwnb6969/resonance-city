using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class DifficultyUI : MonoBehaviour
{
	public delegate void TransitionFunction();

	public static DifficultyUI inst;

	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	private int difficultyIndex;

	public Button toggleAdvancedModeButton;

	public bool showingAdvancedMode;

	public float advancedModeAnimationT;

	public Transform difficultyImageContainer;

	[SerializeField]
	private Toggle[] markers;

	[SerializeField]
	private GameObject[] infoContainers;

	public Localize difficultyTitleLocalize;

	public Button confirmBtn;

	public Button exitBtn;

	public Button leftBtn;

	public Button rightBtn;

	public GameObject invasionSettingsOverlay;

	public Toggle invasionsEnabledToggle;

	public TMP_InputField invasionStartYearInput;

	public DifficultyUIDropdownChoice invasionFrequencyChoice;

	public DifficultyUIDropdownChoice invasionIntensityChoice;

	public DifficultyUIDropdownChoice merchantFrequencyChoice;

	public DifficultyUIDropdownChoice droughtFrequencyChoice;

	public DifficultyUIDropdownChoice floodingFrequencyChoice;

	public DifficultyUIDropdownChoice fireChoice;

	public DifficultyUIDropdownChoice godWrathChoice;

	public DifficultyUIDropdownChoice foodConsumptionChoice;

	public DifficultyUIDropdownChoice plaguesChoice;

	public Toggle limitedResourcesToggle;

	public GameObject difficultySettingsObject;

	public GameObject difficultySelectObject;

	private float difficultySelectStartX;

	private bool isVisible;

	private int currState;

	public const int STATE_NEW_MAP = 0;

	public const int STATE_SETTINGS = 1;

	private DifficultyOption tempOption;

	private int tempDifficulty;

	public TransitionFunction returnFunc;

	public TransitionFunction exitFunc;

	public GameObject advModeLock;

	public StaticTooltipHook advModeToolTip;

	public TextMeshProUGUI surviveYearsTxt;

	public GameObject descLock;

	public GameObject futureLock;

	private void SetDifficultyIndex(int diffIndex)
	{
		difficultyIndex = diffIndex;
		markers[diffIndex].SetIsOnWithoutNotify(value: true);
		for (int i = 0; i < infoContainers.Length; i++)
		{
			Util.SetActive(infoContainers[i], diffIndex == i);
		}
		for (int j = 0; j < difficultyImageContainer.childCount; j++)
		{
			Util.SetActive(difficultyImageContainer.GetChild(j), j == difficultyIndex);
		}
		int id = DifficultyManager.Difficulties[difficultyIndex].id;
		switch (id)
		{
		case 0:
			difficultyTitleLocalize.Term = "difficulty_peaceful";
			break;
		case 1:
			difficultyTitleLocalize.Term = "difficulty_easy";
			break;
		case 2:
			difficultyTitleLocalize.Term = "difficulty_normal";
			break;
		case 3:
			difficultyTitleLocalize.Term = "difficulty_hard";
			break;
		case 4:
			difficultyTitleLocalize.Term = "difficulty_survival";
			break;
		case 5:
			difficultyTitleLocalize.Term = "difficulty_custom";
			break;
		}
		tempDifficulty = id;
		if (id != 5)
		{
			tempOption.CopyFrom(DifficultyManager.inst.options[id]);
			ApplyDifficultySettings(DifficultyManager.inst.options[id]);
		}
		Util.SetActive(invasionSettingsOverlay, !tempOption.isInvasionsEnabled);
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetState(int state)
	{
		currState = state;
	}

	private void DefaultReturnFunction()
	{
		GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.NameAndBanner);
	}

	private void DefaultExitFunction()
	{
		GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.NewMap);
	}

	public void SetReturnFunc(TransitionFunction func)
	{
		if (func == null)
		{
			returnFunc = DefaultReturnFunction;
		}
		else
		{
			returnFunc = func;
		}
	}

	public void SetExitFunc(TransitionFunction func)
	{
		if (func == null)
		{
			exitFunc = DefaultExitFunction;
		}
		else
		{
			exitFunc = func;
		}
	}

	public void SetVisibility(bool v)
	{
		if (v && !isVisible)
		{
			Init();
		}
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
		tempOption = ScriptableObject.CreateInstance<DifficultyOption>();
	}

	private void Start()
	{
		exitFunc = DefaultExitFunction;
		returnFunc = DefaultReturnFunction;
		invasionsEnabledToggle.onValueChanged.AddListener((bool isOn) =>
		{
			tempOption.isInvasionsEnabled = isOn;
			OnDifficultySettingChanged();
		});
		invasionStartYearInput.onEndEdit.AddListener((string val) =>
		{
			if (!int.TryParse(val, out var result) || result < 0)
			{
				invasionStartYearInput.SetTextWithoutNotify(tempOption.invasionStartYear.ToString());
			}
			else
			{
				tempOption.invasionStartYear = result;
				OnDifficultySettingChanged();
			}
		});
		invasionFrequencyChoice.Init(DifficultyDropdownChoices.InvasionFrequency, (int index) =>
		{
			tempOption.invasionFrequencyChoice = index;
			SetInvasionFrequency(index);
			OnDifficultySettingChanged();
		});
		invasionIntensityChoice.Init(DifficultyDropdownChoices.InvasionIntensity, (int index) =>
		{
			tempOption.invasionIntensityChoice = index;
			OnDifficultySettingChanged();
		});
		merchantFrequencyChoice.Init(DifficultyDropdownChoices.MerchantFrequency, (int index) =>
		{
			tempOption.merchantVisitFrequencyChoice = index;
			SetMerchantFrequency(index);
			OnDifficultySettingChanged();
		});
		droughtFrequencyChoice.Init(DifficultyDropdownChoices.Frequency, (int index) =>
		{
			tempOption.droughtFrequency = index;
			OnDifficultySettingChanged();
		});
		floodingFrequencyChoice.Init(DifficultyDropdownChoices.Frequency, (int index) =>
		{
			tempOption.floodingFrequency = index;
			OnDifficultySettingChanged();
		});
		fireChoice.Init(DifficultyDropdownChoices.Frequency, (int index) =>
		{
			tempOption.fires = index;
			OnDifficultySettingChanged();
		});
		plaguesChoice.Init(DifficultyDropdownChoices.Frequency, (int index) =>
		{
			tempOption.plagues = index;
			OnDifficultySettingChanged();
		});
		godWrathChoice.Init(DifficultyDropdownChoices.Magnitude, (int index) =>
		{
			tempOption.godWrath = index;
			OnDifficultySettingChanged();
		});
		foodConsumptionChoice.Init(DifficultyDropdownChoices.Magnitude, (int index) =>
		{
			tempOption.foodConsumption = index;
			OnDifficultySettingChanged();
		});
		limitedResourcesToggle.onValueChanged.AddListener((bool isOn) =>
		{
			tempOption.unlimitedResources = isOn;
			OnDifficultySettingChanged();
		});
		confirmBtn.onClick.AddListener(() =>
		{
			int id = DifficultyManager.Difficulties[difficultyIndex].id;
			if (id != 5)
			{
				DifficultyManager.inst.ApplyDifficultyOption(id);
			}
			else
			{
				DifficultyManager.inst.currOption.CopyFrom(tempOption);
			}
			DifficultyManager.inst.difficulty = id;
			if (currState == 0)
			{
				GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.NameAndBanner);
			}
			else if (currState == 1)
			{
				returnFunc?.Invoke();
			}
		});
		leftBtn.onClick.AddListener(() =>
		{
			int num = difficultyIndex - 1;
			if (num < 0)
			{
				num = DifficultyManager.Difficulties.Count - 2;
			}
			SetDifficultyIndex(num);
		});
		rightBtn.onClick.AddListener(() =>
		{
			bool flag = difficultyIndex == DifficultyManager.Difficulties.Count - 2;
			int num = (difficultyIndex + ((!flag) ? 1 : 2)) % DifficultyManager.Difficulties.Count;
			SetDifficultyIndex(num);
		});
		exitBtn.onClick.AddListener(() =>
		{
			exitFunc?.Invoke();
		});
		difficultySelectStartX = difficultySelectObject.GetComponent<RectTransform>().anchoredPosition.x;
		difficultySelectObject.GetComponent<RectTransform>().anchoredPosition = new Vector2(0f, difficultySelectObject.GetComponent<RectTransform>().anchoredPosition.y);
		toggleAdvancedModeButton.onClick.AddListener(onToggleAdvancedMode);
		difficultySettingsObject.SetActive(value: false);
	}

	private void onToggleAdvancedMode()
	{
		showingAdvancedMode = !showingAdvancedMode;
		_ = showingAdvancedMode;
	}

	private void Init()
	{
		DifficultyOption difficultyOption = null;
		surviveYearsTxt.text = string.Format(LocalizationManager.GetTranslation("difficultyui_survival_description_6"), 200);
		Util.SetActive(advModeLock, World.inst.demoMode);
		if (World.inst.demoMode)
		{
			advModeToolTip.SetTerm("technologytree_line_demo_lock_tooltip");
			toggleAdvancedModeButton.interactable = false;
		}
		if (currState == 0)
		{
			SetDifficultyIndex(1);
		}
		else if (currState == 1)
		{
			difficultyOption = ((DifficultyManager.inst.difficulty != 5) ? DifficultyManager.inst.options[DifficultyManager.inst.difficulty] : DifficultyManager.inst.currOption);
			tempOption.CopyFrom(difficultyOption);
			ApplyDifficultySettings(difficultyOption);
			SetDifficultyIndex(DifficultyManager.DifficultiesIndexMap[DifficultyManager.inst.difficulty]);
		}
	}

	private void OnDifficultySettingChanged()
	{
		foreach (KeyValuePair<int, DifficultyOption> option in DifficultyManager.inst.options)
		{
			if (option.Value.IsIdentical(tempOption) && option.Key != 5)
			{
				int num = DifficultyManager.DifficultiesIndexMap[option.Key];
				SetDifficultyIndex(num);
				return;
			}
		}
		SetDifficultyIndex(DifficultyManager.DifficultiesIndexMap[5]);
	}

	private void ApplyDifficultySettings(DifficultyOption option)
	{
		invasionsEnabledToggle.SetIsOnWithoutNotify(option.isInvasionsEnabled);
		invasionStartYearInput.SetTextWithoutNotify(option.invasionStartYear.ToString());
		limitedResourcesToggle.SetIsOnWithoutNotify(option.unlimitedResources);
		invasionFrequencyChoice.SetOptionWithoutNotify(option.invasionFrequencyChoice);
		SetInvasionFrequency(option.invasionFrequencyChoice);
		invasionIntensityChoice.SetOptionWithoutNotify(option.invasionIntensityChoice);
		merchantFrequencyChoice.SetOptionWithoutNotify(option.merchantVisitFrequencyChoice);
		SetMerchantFrequency(option.merchantVisitFrequencyChoice);
		droughtFrequencyChoice.SetOptionWithoutNotify(option.droughtFrequency);
		floodingFrequencyChoice.SetOptionWithoutNotify(option.floodingFrequency);
		fireChoice.SetOptionWithoutNotify(option.fires);
		plaguesChoice.SetOptionWithoutNotify(option.plagues);
		godWrathChoice.SetOptionWithoutNotify(option.godWrath);
		foodConsumptionChoice.SetOptionWithoutNotify(option.foodConsumption);
	}

	public void Update()
	{
		float num = advancedModeAnimationT;
		float num2 = 2f;
		advancedModeAnimationT = Mathff.Clamp01(advancedModeAnimationT + (showingAdvancedMode ? (Time.unscaledDeltaTime * num2) : ((0f - Time.unscaledDeltaTime) * num2)));
		if (advancedModeAnimationT >= 1f && num < 1f)
		{
			difficultySettingsObject.SetActive(value: true);
		}
		if (advancedModeAnimationT < 1f && num >= 1f)
		{
			difficultySettingsObject.SetActive(value: false);
		}
		difficultySelectObject.GetComponent<RectTransform>().anchoredPosition = new Vector2(difficultySelectStartX * Util.easeInQuad(Util.easeOutQuad(advancedModeAnimationT)), difficultySelectObject.GetComponent<RectTransform>().anchoredPosition.y);
		confirmBtn.interactable = difficultyIndex != 4;
		Util.SetActive(futureLock, !confirmBtn.interactable);
	}

	private void SetInvasionFrequency(int index)
	{
		switch (index)
		{
		case 0:
			tempOption.minInvasionFrequency = 7;
			tempOption.maxInvasionFrequency = 8;
			break;
		case 1:
			tempOption.minInvasionFrequency = 5;
			tempOption.maxInvasionFrequency = 6;
			break;
		default:
			tempOption.minInvasionFrequency = 4;
			tempOption.maxInvasionFrequency = 5;
			break;
		case 3:
			tempOption.minInvasionFrequency = 3;
			tempOption.maxInvasionFrequency = 4;
			break;
		case 4:
			tempOption.minInvasionFrequency = 2;
			tempOption.maxInvasionFrequency = 3;
			break;
		}
	}

	private void SetMerchantFrequency(int index)
	{
		switch (index)
		{
		case 0:
			tempOption.minMerchantInterval = 400;
			tempOption.maxMerchantInterval = 450;
			break;
		case 1:
			tempOption.minMerchantInterval = 300;
			tempOption.maxMerchantInterval = 350;
			break;
		default:
			tempOption.minMerchantInterval = 210;
			tempOption.maxMerchantInterval = 270;
			break;
		case 3:
			tempOption.minMerchantInterval = 150;
			tempOption.maxMerchantInterval = 200;
			break;
		case 4:
			tempOption.minMerchantInterval = 100;
			tempOption.maxMerchantInterval = 50;
			break;
		}
	}
}
