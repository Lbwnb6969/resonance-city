using Assets;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class BuildingInfoUI : MonoBehaviour
{
	[SerializeField]
	private TMP_InputField titleInput;

	private TMP_SelectionCaret caret;

	[SerializeField]
	private Localize titleLocalize;

	[SerializeField]
	private EventTrigger titleEventTrigger;

	[SerializeField]
	private Button editTitleBtn;

	[SerializeField]
	private GameObject editBackground;

	[SerializeField]
	private TextMeshProUGUI descriptionTMP;

	[SerializeField]
	private GameObject healthContainer;

	[SerializeField]
	private Slider healthSlider;

	[SerializeField]
	private TextMeshProUGUI healthTMP;

	[SerializeField]
	private TooltipHook healthTooltip;

	[SerializeField]
	private GameObject fireContainer;

	[SerializeField]
	private Slider fireSlider;

	[SerializeField]
	private TooltipHook fireTooltip;

	[SerializeField]
	private GameObject openContainer;

	[SerializeField]
	private Toggle openToggle;

	[SerializeField]
	private Button exitBtn;

	private Building building;

	private ISelectableBuilding genericBuilding;

	private IWorkerUIDisplay iWorkerUIDisplay;

	private bool inited;

	private bool isTitleHovered;

	private bool isRubble;

	private bool isAqueduct;

	private bool isRiverTap;

	private void TryInit()
	{
		if (inited)
		{
			return;
		}
		EventTrigger.Entry entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerEnter;
		entry.callback.AddListener((BaseEventData eventData) =>
		{
			isTitleHovered = true;
		});
		titleEventTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerExit;
		entry.callback.AddListener((BaseEventData eventData) =>
		{
			isTitleHovered = false;
		});
		titleEventTrigger.triggers.Add(entry);
		titleInput.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
		});
		titleInput.onEndEdit.AddListener((string val) =>
		{
			genericBuilding.CustomName = titleInput.text;
			GameState.inst.AlphaNumericHotkeysEnabled = true;
			titleInput.textComponent.rectTransform.localPosition = Vector3.zero;
			caret.rectTransform.localPosition = Vector3.zero;
		});
		openToggle.onValueChanged.AddListener((bool on) =>
		{
			if (building != null && building.IsOpen() != on)
			{
				building.Open = on;
				ResourceTextStackManager.inst.ShowText(this, building.Center(), on ? ScriptLocalization.Open : ScriptLocalization.OutputUIClosed);
			}
			else if (building == null && genericBuilding is RiverTap riverTap && riverTap.IsOpen() != on)
			{
				riverTap.SetOpen(on);
				ResourceTextStackManager.inst.ShowText(this, riverTap.Center(), on ? ScriptLocalization.Open : ScriptLocalization.OutputUIClosed);
			}
		});
		inited = true;
	}

	public void SetVisibility(bool isVisible)
	{
		if (!isVisible)
		{
			titleInput.DeactivateInputField();
		}
		gameObject.SetActive(isVisible);
		if (isVisible)
		{
			caret = titleInput.GetComponentInChildren<TMP_SelectionCaret>();
		}
	}

	public void OnBuildingSelected(Building b, ISelectableBuilding gBuilding)
	{
		if (b == null && gBuilding.IsNull())
		{
			SetVisibility(isVisible: false);
			return;
		}
		building = b;
		genericBuilding = gBuilding;
		iWorkerUIDisplay = (gBuilding as MonoBehaviour)?.GetComponent<IWorkerUIDisplay>();
		TryInit();
		bool flag = World.IsAILandmass(genericBuilding.LandMass());
		titleInput.text = genericBuilding.CustomName;
		descriptionTMP.text = (flag ? "" : genericBuilding.Description);
		openContainer.SetActive(!iWorkerUIDisplay.IsNull() && iWorkerUIDisplay.ShowOpenClose());
		openToggle.SetIsOnWithoutNotify(genericBuilding.IsOpen());
		isRubble = genericBuilding.UniqueNameHash() == World.rubbleHash;
		isAqueduct = genericBuilding.UniqueNameHash() == World.aqueductLineHash;
		isRiverTap = genericBuilding.UniqueNameHash() == RiverTap.uniqueHash;
		bool flag2 = (isRubble || isAqueduct || isRiverTap) | flag;
		bool flag3 = isRubble || isAqueduct || isRiverTap;
		fireContainer.SetActive(!flag2);
		healthContainer.SetActive(!flag3);
		SetVisibility(isVisible: true);
	}

	public void OnDeselected()
	{
		building = null;
		isTitleHovered = false;
		isRubble = false;
		iWorkerUIDisplay = null;
	}

	private void Update()
	{
		if (!(building != null))
		{
			return;
		}
		if (!isRubble)
		{
			if (!World.IsImmuneToFire(building))
			{
				float riskPercent = Mathf.Clamp01(1f - building.GetMaxVigilesCoverage());
				UpdateRiskUI(riskPercent, immune: false);
			}
			else
			{
				UpdateRiskUI(0f, immune: true);
			}
			UpdateHealthBar(building.ModifiedMaxLife * 10f, building.Life * 10f, building.TeamID() != 0, building.Life * 10f);
		}
		editBackground.SetActive(titleInput.isFocused || isTitleHovered);
	}

	public void UpdateRiskUI(float riskPercent, bool immune)
	{
		fireTooltip.toolTipText = ScriptLocalization.Fire_Risk + "\n";
		if (building.uniqueNameHash == World.roadHash)
		{
			TooltipHook tooltipHook = fireTooltip;
			tooltipHook.toolTipText = tooltipHook.toolTipText + "<color=green>" + ScriptLocalization.FireRiskLowRisk + "</color>";
		}
		else if (immune)
		{
			fireTooltip.toolTipText += ScriptLocalization.FireRiskStoneImmune;
		}
		else if (riskPercent < 0.001f)
		{
			TooltipHook tooltipHook2 = fireTooltip;
			tooltipHook2.toolTipText = tooltipHook2.toolTipText + "<color=green>" + ScriptLocalization.FireRiskFullProtection + "</color>";
		}
		else if ((double)riskPercent < 0.25)
		{
			TooltipHook tooltipHook3 = fireTooltip;
			tooltipHook3.toolTipText = tooltipHook3.toolTipText + "<color=green>" + ScriptLocalization.FireRiskLowRisk + "</color>";
		}
		else if ((double)riskPercent < 0.85)
		{
			TooltipHook tooltipHook4 = fireTooltip;
			tooltipHook4.toolTipText = tooltipHook4.toolTipText + "<color=yellow>" + ScriptLocalization.FireRiskMediumRisk + "</color>";
		}
		else
		{
			TooltipHook tooltipHook5 = fireTooltip;
			tooltipHook5.toolTipText = tooltipHook5.toolTipText + "<color=#FFA68D>" + ScriptLocalization.FireRiskHighRisk + "</color>";
		}
		if (!immune)
		{
			Governor focusedGovenor = Player.inst.FocusedGovenor;
			Governor.TraitInstance traitInstance = null;
			if (focusedGovenor != null)
			{
				traitInstance = focusedGovenor.GetTrait(Traits.FireRisk);
				if (traitInstance != null)
				{
					Traits.Trait def = Traits.inst.GetDef(traitInstance.id);
					riskPercent *= 1f + (traitInstance.negative ? traitInstance.magnitude : (0f - traitInstance.magnitude));
					TooltipHook tooltipHook6 = fireTooltip;
					tooltipHook6.toolTipText = tooltipHook6.toolTipText + "\n" + LocalizationManager.GetTranslation("advisorui_governortitle") + " " + def.GetDesc(traitInstance);
				}
			}
		}
		fireSlider.value = riskPercent;
	}

	public void UpdateHealthBar(float max, float current, bool aiBuilding, float currentReal)
	{
		healthSlider.maxValue = max;
		healthSlider.value = currentReal;
		healthTMP.SetText("{0}/{1}", Mathf.CeilToInt(current), Mathf.CeilToInt(max));
		healthTooltip.toolTipText = ScriptLocalization.WorkerUIHealthWarning + "\n";
		Governor focusedGovenor = Player.inst.FocusedGovenor;
		Governor.TraitInstance traitInstance = null;
		if (focusedGovenor != null)
		{
			traitInstance = focusedGovenor.GetTrait(Traits.BuildingDecay);
			if (traitInstance != null)
			{
				Traits.Trait def = Traits.inst.GetDef(traitInstance.id);
				TooltipHook tooltipHook = healthTooltip;
				tooltipHook.toolTipText = tooltipHook.toolTipText + LocalizationManager.GetTranslation("advisorui_governortitle") + " " + def.GetDesc(traitInstance);
			}
		}
	}
}
