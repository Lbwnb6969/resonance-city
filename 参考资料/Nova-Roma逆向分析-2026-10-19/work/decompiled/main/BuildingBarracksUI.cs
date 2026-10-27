using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildingBarracksUI : MonoBehaviour
{
	[SerializeField]
	public TextMeshProUGUI titleTMP;

	[SerializeField]
	public Button recruitBtn;

	[SerializeField]
	public Button recuperateBtn;

	[SerializeField]
	public Button cancelBtn;

	[SerializeField]
	public Slider progressSlider;

	[SerializeField]
	public TextMeshProUGUI statusTMP;

	[SerializeField]
	public TextMeshProUGUI collectTMP;

	[SerializeField]
	public TextMeshProUGUI recruitTMP;

	[SerializeField]
	public GameObject UnOccupiedObj;

	[SerializeField]
	public GameObject OccupiedObj;

	[SerializeField]
	public Localize nameLocalize;

	[SerializeField]
	public Slider healthSlider;

	[SerializeField]
	public RawImage iconRI;

	[SerializeField]
	public Button disbandBtn;

	[SerializeField]
	public Button focusBtn;

	[SerializeField]
	public GameObject disabledCard;

	[SerializeField]
	public TextMeshProUGUI disabledTextTMP;

	private Building building;

	private RomanBarracks barracks;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(gameObject, v);
		isVisible = v;
	}

	private void Start()
	{
		recruitBtn.onClick.AddListener(OnRecruitClicked);
		cancelBtn.onClick.AddListener(OnCancelClicked);
		disbandBtn.onClick.AddListener(OnDisbandClicked);
		focusBtn.onClick.AddListener(OnFocusedClicked);
		recuperateBtn.onClick.AddListener(OnRecuperateClicked);
	}

	public void OnRecuperateClicked()
	{
		LegionUnit occupyingUnit = barracks.GetOccupyingUnit();
		UnitSystem.inst.MoveTo(occupyingUnit, barracks.GetComponent<Building>());
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (barracks = b.GetComponent<RomanBarracks>()) == null)
		{
			SetVisibility(v: false);
			return;
		}
		building = b;
		RefreshVisuals();
		SetVisibility(v: true);
	}

	public void OnDeselected()
	{
		building = null;
		barracks = null;
		SetVisibility(v: false);
	}

	private void Update()
	{
		if (isVisible && !(building == null) && !(barracks == null))
		{
			RefreshVisuals();
		}
	}

	public void RefreshVisuals()
	{
		bool flag = false;
		if (building.UniqueName == World.romanOutpostName)
		{
			int num = 0;
			for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
			{
				num += World.inst.GetVillagersForLandMass(Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i]).Count;
			}
			int num2 = RaiderSystem.vikingSpawnStartPopulation - 10;
			if (num < num2 && UnitSystem.inst.unitsByTeamID[0].Count <= 0)
			{
				disabledTextTMP.SetText(LocalizationManager.GetTranslation("workerui_barracksui_locked"), num2);
				flag = true;
			}
		}
		UnitSystem.UnitData unitData = UnitSystem.inst.unitDataMap[barracks.recruitUnitType];
		titleTMP.text = LocalizationManager.GetTranslation(unitData.name);
		Util.SetActive(disabledCard, flag);
		if (flag)
		{
			return;
		}
		Util.SetActive(OccupiedObj, barracks.IsOccupied());
		Util.SetActive(UnOccupiedObj, !barracks.IsOccupied());
		Util.SetActive(progressSlider.gameObject, barracks.IsRecruiting());
		Util.SetEnabled(collectTMP, !barracks.IsRecruiting());
		cancelBtn.interactable = barracks.IsRecruiting();
		recruitBtn.interactable = barracks.CanRecruit();
		if (!barracks.HasCostForRecruitment())
		{
			recruitTMP.text = ScriptLocalization.damplanningui_cannotafforderror;
		}
		else
		{
			recruitTMP.text = ScriptLocalization.workerui_barracksui_recruit;
		}
		ResourceAmount recruitCost = barracks.recruitCost;
		ResourceAmount currStorage = barracks.currStorage;
		string text = "";
		for (int j = 0; j < recruitCost.resources.Count; j++)
		{
			Resource resource = recruitCost.resources[j];
			if (resource.Amount > 0)
			{
				int amount = resource.Amount;
				int num3 = ((resource.resourceID == 4) ? building.GetLandMassOwner().Gold : currStorage.Get(resource.resourceID));
				FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[resource.resourceID];
				text += (string.IsNullOrEmpty(text) ? "" : "   ");
				text = text + resourceDef.iconName + ((num3 < amount) ? $"<color=red>{num3}</color>/{amount}" : $"{num3}/{amount}");
			}
		}
		int num4 = Mathff.Min(barracks.requiredRecruits, Player.inst.TotalWorkersForLandMass(building.LandMass()));
		text += (string.IsNullOrEmpty(text) ? "" : "   ");
		text = text + "<sprite name=icon_citizen>" + ((num4 < barracks.requiredRecruits) ? $"<color=red>{num4}</color>/{barracks.requiredRecruits}" : $"{num4}/{barracks.requiredRecruits}");
		collectTMP.text = text;
		if (barracks.IsRecruiting())
		{
			statusTMP.text = ((barracks.GetTrainingTime() > 0f) ? ScriptLocalization.Training : ScriptLocalization.workerui_barracksui_recruiting);
			progressSlider.value = barracks.GetRecruitProgress();
		}
		else
		{
			statusTMP.text = ScriptLocalization.Cost + ":";
		}
		if (barracks.IsOccupied())
		{
			LegionUnit occupyingUnit = barracks.GetOccupyingUnit();
			titleTMP.text = LocalizationManager.GetTranslation(unitData.name);
			iconRI.texture = unitData.icon.texture;
			LegionGroup legionGroup = occupyingUnit.GetGroup();
			healthSlider.value = legionGroup.pep / (float)legionGroup.origNumCells;
			Vector3 pos = occupyingUnit.GetPos();
			int landMassIdx = World.inst.GetCellDataClamped(pos).landMassIdx;
			recuperateBtn.interactable = !occupyingUnit.IsBeingCarried() && barracks.LandMass() == landMassIdx && (legionGroup.numCells < legionGroup.origNumCells || legionGroup.pep < (float)legionGroup.numCells);
		}
		else
		{
			recuperateBtn.interactable = false;
		}
	}

	private void OnRecruitClicked()
	{
		barracks?.TryStartRecruitment();
	}

	private void OnCancelClicked()
	{
		barracks?.TryCancelRecruitment();
	}

	private void OnDisbandClicked()
	{
		barracks?.TryDisband();
	}

	private void OnFocusedClicked()
	{
		barracks?.TryFocus();
	}
}
