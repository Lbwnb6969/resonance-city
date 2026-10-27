using System;
using System.Collections.Generic;
using Crosstales;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class OldUnitUI : MonoBehaviour
{
	public enum UnitTabs
	{
		All,
		Knights,
		Archers,
		Settlers,
		Envoys,
		Catapults,
		TransportShips,
		Individual
	}

	public enum UnitPriorityOrder
	{
		SeedShip,
		TransportShips,
		Knights,
		Archers,
		Envoys,
		Catapults,
		Settlers,
		NumOfTypes
	}

	[Serializable]
	public struct OnBoardEntry
	{
		public GameObject container;

		public Toggle toggle;

		public StaticTooltipHook hook;

		public Image image;

		public GameObject lockIcon;
	}

	private struct NoteBuilding
	{
		public Building b;

		public ResourceTooltipUI note;
	}

	public static OldUnitUI inst;

	private UnitTabs currentTabSelected;

	private IMoveableUnit currentUnitSelected;

	private ISelectable currentUnitHovered;

	private int unitPoolCount;

	public GameObject unitOptionPrefab;

	public GameObject unitOptionContainer;

	private ArrayExt<GameObject> unitPool = new ArrayExt<GameObject>(32);

	public GameObject[] tabRoot;

	public GameObject header;

	public TextMeshProUGUI unitTitle;

	public Image unitIcon;

	public GameObject unitHealthContainer;

	public TextMeshProUGUI unitHealth;

	public GameObject unitAttackContainer;

	public Slider unitAttackProgressSlider;

	public TextMeshProUGUI unitAttackRechargeStateTxt;

	public TextMeshProUGUI unitInstructionsText;

	public GameObject unitWageErrorContainer;

	public GameObject shipOnBoardContainer;

	public OnBoardEntry[] shipOnBoardOptions;

	public GameObject unitAttackBehaviorContainer;

	public Toggle unitAttackBehaviorHold;

	public Toggle unitAttackBehaviorAttack;

	public Toggle unitAttackBehaviorPursue;

	public ToggleGroup unitAttackBehaviorToggleGroup;

	public GameObject settleContainer;

	public Button settleBtn;

	public Button disbandBtn;

	public GameObject envoyGiftContainer;

	public GameObject envoyInstructions;

	public GameObject envoyDropGift;

	public GameObject envoyDeliverGift;

	public GameObject envoyGiftCover;

	public ResourceAmountUI envoyGiftAmount;

	public GameObject recuperateContainer;

	public Button recuperateButton;

	public GameObject allUnitsDisplayContainer;

	public GameObject individualUnitDisplayContainer;

	private int activeTabCount;

	private int[] activeTabIndexs = new int[7];

	public ConsoleUIItem entryConsoleItem;

	public GameObject consoleRT;

	public GameObject consoleRB;

	public GameObject consoleLB;

	public bool IsConsoleFocused;

	private ArrayExt<IMoveableUnit> units = new ArrayExt<IMoveableUnit>(32);

	private ArrayExt<IMoveableUnit> tabUnits = new ArrayExt<IMoveableUnit>(32);

	public bool Visible;

	private List<NoteBuilding> notes = new List<NoteBuilding>();

	private ArmySystem.ArmyBehavior prevAttackBehavior;

	private void Awake()
	{
		inst = this;
	}

	private void Update()
	{
		if (currentUnitHovered != null && !currentUnitHovered.Equals(null))
		{
			currentUnitHovered.SetHighlightImmediate(0);
		}
		if (IsTabSelected())
		{
			for (int i = 0; i < tabUnits.Count; i++)
			{
				if (tabUnits.data[i] is ISelectable selectable && !selectable.Equals(null))
				{
					selectable.SetHighlightImmediate(0);
				}
			}
		}
		else if (IsUnitSelected())
		{
			ISelectable selectable2 = (ISelectable)currentUnitSelected;
			if (selectable2 != null && !selectable2.Equals(null))
			{
				selectable2.SetHighlightImmediate(0);
			}
		}
		if (GamepadControl.inst.isControllerActive)
		{
			consoleRT.SetActive(!entryConsoleItem.isHovered);
			if (!GamepadControl.inst.IsNavigatingUI() && GamepadControl.inst.player.GetButtonDown("RT"))
			{
				IsConsoleFocused = true;
				entryConsoleItem.Hover();
			}
			bool flag = activeTabCount > 1 && entryConsoleItem.isHovered;
			consoleLB.SetActive(flag);
			consoleRB.SetActive(flag);
			if (flag & (units.Count > 1))
			{
				if (GamepadControl.inst.player.GetButtonDown("LB"))
				{
					SelectTab(GetNextTab(-1));
				}
				else if (GamepadControl.inst.player.GetButtonDown("RB"))
				{
					SelectTab(GetNextTab(1));
				}
			}
			if (GamepadControl.inst.player.GetButtonDown("B"))
			{
				if (units.Count > 1 && currentTabSelected != UnitTabs.All)
				{
					SelectTab(UnitTabs.All);
				}
				else
				{
					IsConsoleFocused = false;
					entryConsoleItem.Reset();
				}
			}
		}
		else
		{
			consoleRT.SetActive(value: false);
		}
		RecooperateUpdate();
		if (!(currentUnitSelected is ArmySystem.Army army))
		{
			return;
		}
		if (army.armyType == ArmySystem.ArmyType.Envoy)
		{
			bool flag2 = false;
			Envoy component = army.general.GetComponent<Envoy>();
			if (component != null)
			{
				flag2 = !component.giftAmount.IsNone();
				envoyGiftAmount.SetResourceAmount(component.giftAmount);
			}
			envoyGiftContainer.SetActive(value: true);
			envoyGiftCover.SetActive(!flag2);
			envoyInstructions.SetActive(flag2);
			LandmassOwner landmassOwner = World.GetLandmassOwner(World.inst.GetCellDataClamped(army.generalPos).landMassIdx);
			if (landmassOwner == null || landmassOwner.teamId == army.teamId)
			{
				envoyDeliverGift.SetActive(value: false);
				envoyDropGift.SetActive(flag2);
			}
			else
			{
				envoyDeliverGift.SetActive(flag2);
				envoyDropGift.SetActive(value: false);
			}
			for (int j = 0; j < notes.Count; j++)
			{
				int teamId = notes[j].b.TeamID();
				AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(teamId);
				if (kingdomFromTeamId == null)
				{
					notes[j].note.gameObject.SetActive(value: false);
					continue;
				}
				if (kingdomFromTeamId.audienceTimer > 0f)
				{
					notes[j].note.SetText("ScriptLocalization.DiplomatKeepBusy");
				}
				else
				{
					notes[j].note.SetText("ScriptLocalization.DiplomatMoveToVisit");
				}
				notes[j].note.gameObject.SetActive(notes[j].b.IsVisibleForFog());
			}
		}
		else if (army.armyType == ArmySystem.ArmyType.Default)
		{
			unitAttackProgressSlider.value = (ArmySystem.burnMaxTime - Mathff.Max(army.burnTimer, 0f)) / ArmySystem.burnMaxTime;
			unitAttackRechargeStateTxt.SetText((army.burnTimer < 0f) ? ScriptLocalization.TorchReady : ScriptLocalization.PreparingTorch);
		}
	}

	private void OnEnable()
	{
		if (GamepadControl.inst.isControllerActive && IsConsoleFocused)
		{
			entryConsoleItem.Hover();
		}
	}

	public void Close()
	{
		if (gameObject.activeSelf)
		{
			currentUnitHovered = null;
			currentUnitSelected = null;
			GameUI gameUI = GameUI.inst;
			gameUI.OnSelectionUpdate = (GameUI.NotifyAnySelection)Delegate.Remove(gameUI.OnSelectionUpdate, new GameUI.NotifyAnySelection(OnSelectionUpdate));
			gameObject.SetActive(value: false);
			notes.Clear();
			World.inst.HideResourceTooltipUIs();
			Visible = false;
		}
	}

	public void Open()
	{
		if (gameObject.activeSelf)
		{
			return;
		}
		GameUI.inst.ClearUIForClick();
		CreativeUI.inst.SetVisibility(v: false);
		OnSelectionUpdate();
		GameUI gameUI = GameUI.inst;
		gameUI.OnSelectionUpdate = (GameUI.NotifyAnySelection)Delegate.Combine(gameUI.OnSelectionUpdate, new GameUI.NotifyAnySelection(OnSelectionUpdate));
		int bannerIdx = Player.inst.PlayerLandmassOwner.bannerIdx;
		for (int i = 1; i < tabRoot.Length; i++)
		{
			Sprite sprite = null;
			Transform transform = tabRoot[i].transform;
			switch (i)
			{
			case 1:
				sprite = World.inst.liverySets[bannerIdx].knightSprite;
				break;
			case 2:
				sprite = World.inst.liverySets[bannerIdx].archerSprite;
				break;
			case 3:
				sprite = World.inst.liverySets[bannerIdx].settlerSprite;
				break;
			case 4:
				sprite = World.inst.liverySets[bannerIdx].envoySprite;
				break;
			case 5:
				sprite = World.inst.liverySets[bannerIdx].catapultSprite;
				break;
			case 6:
				sprite = World.inst.liverySets[bannerIdx].transportSprite;
				break;
			}
			transform.GetChild(transform.childCount - 3).GetComponent<Image>().sprite = sprite;
		}
		gameObject.SetActive(value: true);
		Visible = true;
	}

	public UnitTabs GetNextTab(int diff)
	{
		if (activeTabCount == 1 || currentTabSelected == UnitTabs.Individual)
		{
			return UnitTabs.All;
		}
		int num = (int)currentTabSelected;
		int i;
		for (i = 0; i < activeTabCount && num != activeTabIndexs[i]; i++)
		{
		}
		int num2 = i + diff;
		num2 = ((num2 >= 0) ? (num2 % activeTabCount) : (num2 + activeTabCount));
		return (UnitTabs)activeTabIndexs[num2];
	}

	private void TryCollectSelectedUnits()
	{
		units.ClearFast();
		int[] array = new int[7];
		List<ISelectable> selectedObjs = GameUI.inst.selectedObjs;
		for (int i = 0; i < selectedObjs.Count; i++)
		{
			if (selectedObjs[i].TeamID() != 0 && !Creative.inst.IsEnabled())
			{
				continue;
			}
			IMoveableUnit unitFromSelectable = GameUI.inst.GetUnitFromSelectable(selectedObjs[i]);
			if (unitFromSelectable != null)
			{
				int unitPriority = (int)GetUnitPriority(unitFromSelectable);
				units.Insert(array[unitPriority], unitFromSelectable);
				for (int j = unitPriority; j < array.Length; j++)
				{
					array[j]++;
				}
			}
		}
	}

	public void OnSelectionUpdate()
	{
		TryCollectSelectedUnits();
		UpdateTabDisplay();
		if (currentTabSelected == UnitTabs.All)
		{
			PopulateUnitOptions();
		}
		else if (currentTabSelected != UnitTabs.Individual)
		{
			GetUnitsOfTab(currentTabSelected);
		}
		header.SetActive(units.Count != 1);
		if (units.Count == 0)
		{
			Close();
		}
	}

	public void UpdateTabDisplay()
	{
		int[] array = new int[7];
		bool flag = currentUnitSelected == null;
		for (int i = 0; i < units.Count; i++)
		{
			IMoveableUnit obj = units.data[i];
			UnitTabs unitTabs = UnitTabs.All;
			if (obj is ArmySystem.Army army)
			{
				if (army.armyType == ArmySystem.ArmyType.Default)
				{
					unitTabs = UnitTabs.Knights;
				}
				else if (army.armyType == ArmySystem.ArmyType.Archer)
				{
					unitTabs = UnitTabs.Archers;
				}
				else if (army.armyType == ArmySystem.ArmyType.Settler)
				{
					unitTabs = UnitTabs.Settlers;
				}
				else if (army.armyType == ArmySystem.ArmyType.Envoy)
				{
					unitTabs = UnitTabs.Envoys;
				}
			}
			if (obj is SiegeCatapult)
			{
				unitTabs = UnitTabs.Catapults;
			}
			if (obj is TroopTransportShip)
			{
				unitTabs = UnitTabs.TransportShips;
			}
			if (object.Equals(obj, currentUnitSelected))
			{
				flag = true;
			}
			if (unitTabs != UnitTabs.All)
			{
				array[(int)unitTabs]++;
			}
		}
		array[0] = units.Count;
		if (!flag)
		{
			SelectTab(UnitTabs.All);
		}
		activeTabCount = 0;
		for (int j = 0; j < array.Length; j++)
		{
			int num = array[j];
			if (num > 0)
			{
				activeTabIndexs[activeTabCount++] = j;
				tabRoot[j].SetActive(value: true);
				tabRoot[j].transform.GetChild(tabRoot[j].transform.childCount - 1).GetComponent<TextMeshProUGUI>().text = num.ToString();
				continue;
			}
			tabRoot[j].SetActive(value: false);
			if (j == (int)currentTabSelected)
			{
				SelectTab(UnitTabs.All);
			}
		}
	}

	public void OnUnitOptionClicked(int index)
	{
		if (index < units.Count)
		{
			IMoveableUnit moveableUnit = units.data[index];
			SetSelectedUnit(moveableUnit, force: true);
			Cam.inst.SetDesiredTrackingPos(moveableUnit.GetPos());
		}
	}

	public bool IsTabSelected()
	{
		if (currentTabSelected != UnitTabs.Individual && currentTabSelected != UnitTabs.All)
		{
			return currentUnitSelected == null;
		}
		return false;
	}

	public bool IsUnitSelected()
	{
		if (currentTabSelected == UnitTabs.Individual)
		{
			return currentUnitSelected != null;
		}
		return false;
	}

	public void OnUnitOptionHovered(int idx)
	{
		if (idx < units.Count)
		{
			ISelectable objA = units.data[idx] as ISelectable;
			if (!object.Equals(objA, null))
			{
				currentUnitHovered = objA;
			}
		}
	}

	public void OnUnitOptionDehovered()
	{
		currentUnitHovered = null;
	}

	public void OnTabOptionClicked(int index)
	{
		SelectTab((UnitTabs)index);
	}

	private void ShowEnvoyKeepInstructions()
	{
		notes.Clear();
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(World.keepHash);
		for (int i = 0; i < buildingList.Count; i++)
		{
			Building building = buildingList.data[i];
			if (building.TeamID() != 0)
			{
				GameObject gameObject = UnityEngine.Object.Instantiate(World.inst.resourceTooltipPrefab);
				ResourceTooltipUI component = gameObject.GetComponent<ResourceTooltipUI>();
				component.SetText("Right click to Visit");
				component.EnableTextAutoSizing();
				gameObject.transform.position = building.GetPos() + new Vector3(0f, 3.25f, 0f);
				gameObject.transform.SetParent(World.inst.resourceTooltipContainer.transform);
				notes.Add(new NoteBuilding
				{
					b = building,
					note = component
				});
			}
		}
	}

	public void SetSelectedUnit(IMoveableUnit unit, bool force = false)
	{
		if (!force && units.Count > 1 && currentTabSelected == UnitTabs.All)
		{
			return;
		}
		ResetVisuals(currentTabSelected, UnitTabs.Individual);
		individualUnitDisplayContainer.SetActive(value: true);
		currentUnitSelected = unit;
		currentUnitHovered = unit as ISelectable;
		SelectTab(UnitTabs.Individual);
		unitHealth.SetText("ScriptLocalization.GeneralUIArmyHealth", (int)unit.CurrHealth(), (int)unit.MaxHealth());
		unitHealthContainer.SetActive(value: true);
		if (unit is ArmySystem.Army army)
		{
			SetUnitInfo(army.generalName, GetSpriteForUnit(unit), GamepadControl.GetPlatformLocalization("ArmyDescription", "ScriptTerms.ConsoleArmyDescription"));
			UpdateAttackBehaviorVisuals(army.armyBehavior);
			unitAttackBehaviorContainer.SetActive(army.armyType == ArmySystem.ArmyType.Default || army.armyType == ArmySystem.ArmyType.Archer);
			int landMassIdx = World.inst.GetCellData(army.generalPos).landMassIdx;
			if (army.armyType == ArmySystem.ArmyType.Default)
			{
				unitAttackContainer.SetActive(army.armyType == ArmySystem.ArmyType.Default);
				if (army.teamId == 1)
				{
					unitTitle.text = "Vikings";
					unitInstructionsText.text += ScriptLocalization.UnitUI_CreativeModeDetails.PadLeft(1);
				}
			}
			else if (army.armyType == ArmySystem.ArmyType.Envoy)
			{
				unitInstructionsText.text = GamepadControl.GetPlatformLocalization("ScriptTerms.EnvoyDescription", "ScriptTerms.ConsoleEnvoyDescription");
				ShowEnvoyKeepInstructions();
			}
			else if (army.armyType == ArmySystem.ArmyType.Settler)
			{
				settleContainer.SetActive(value: true);
				settleBtn.interactable = Player.inst.LandMassIsAPlayerLandMass(landMassIdx);
				unitInstructionsText.text = GamepadControl.GetPlatformLocalization("ScriptTerms.SettlerDescription", "ScriptTerms.ConsoleSettlerDescription");
			}
			if (army.units.Count != army.squadSize)
			{
				LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(army.teamId);
				if (landmassOwnerByTeamId != null && landmassOwnerByTeamId.OwnsLandMass(landMassIdx))
				{
					int num = 0;
					if (army.armyType == ArmySystem.ArmyType.Default)
					{
						num = World.barracksHash;
					}
					else if (army.armyType == ArmySystem.ArmyType.Archer)
					{
						num = World.archerSchoolHash;
					}
					recuperateButton.interactable = num != 0 && Player.inst.GetBuildingListForLandMass(landMassIdx, num).Count > 0;
					recuperateContainer.SetActive(num != 0);
				}
			}
		}
		else if (unit is SiegeCatapult siegeCatapult)
		{
			SetUnitInfo(siegeCatapult.generalName, GetSpriteForUnit(unit), GamepadControl.GetPlatformLocalization("ArmyDescription", "ScriptTerms.ConsoleArmyDescription"));
		}
		else if (unit is TroopTransportShip troopTransportShip)
		{
			SetUnitInfo("ScriptLocalization.Building_trooptransportship_FriendlyName", GetSpriteForUnit(unit), GamepadControl.GetPlatformLocalization("ArmyDescription", "ScriptTerms.ConsoleArmyDescription"));
			if (troopTransportShip.teamID == 1)
			{
				unitInstructionsText.text += ScriptLocalization.UnitUI_CreativeModeDetails.PadLeft(1);
			}
			shipOnBoardContainer.SetActive(value: true);
			OnShipBoardUpdate(troopTransportShip);
		}
		else if (unit is SeedShip seedShip)
		{
			SetUnitInfo("ScriptLocalization.Building_seedship_FriendlyName", GetSpriteForUnit(unit), GamepadControl.GetPlatformLocalization("ScriptTerms.SettlerDescription", "ScriptTerms.ConsoleSettlerDescription"));
			settleContainer.SetActive(value: true);
			settleBtn.interactable = seedShip.CanSettle;
			disbandBtn.gameObject.SetActive(seedShip.CanDisband);
		}
		else if (unit is SiegeMonster)
		{
			SetUnitInfo("ScriptLocalization.SiegeMonsterOgre".CTToTitleCase(), GetSpriteForUnit(unit), ScriptLocalization.UnitUI_CreativeModeDetails);
		}
		allUnitsDisplayContainer.SetActive(value: false);
	}

	private void SetUnitInfo(string titleText, Sprite sprite, string instructionText)
	{
		unitTitle.text = titleText;
		unitIcon.sprite = sprite;
		unitInstructionsText.text = instructionText;
	}

	public void OnShipBoardUpdate(TroopTransportShip transportShip)
	{
		if (!gameObject.activeSelf || transportShip == null || !shipOnBoardContainer.activeInHierarchy || transportShip != currentUnitSelected as TroopTransportShip)
		{
			return;
		}
		for (int i = 0; i < 3; i++)
		{
			if (i >= transportShip.CarryCount())
			{
				shipOnBoardOptions[i].container.SetActive(value: false);
				continue;
			}
			shipOnBoardOptions[i].container.SetActive(value: true);
			shipOnBoardOptions[i].hook.toolTipText = (enabled ? LocalizationManager.GetTranslation("ScriptTerms.OnBoardLocked") : LocalizationManager.GetTranslation("ScriptTerms.OnBoardUnlocked"));
			shipOnBoardOptions[i].toggle.isOn = transportShip.lockLoadTarget.data[i];
			shipOnBoardOptions[i].lockIcon.SetActive(transportShip.lockLoadTarget.data[i]);
			shipOnBoardOptions[i].image.sprite = GetSpriteForUnit(transportShip.GetCarried(i));
		}
	}

	public void OnShipBoardSelected(int idx)
	{
		if (currentUnitSelected is TroopTransportShip troopTransportShip)
		{
			bool flag = !troopTransportShip.lockLoadTarget.data[idx];
			troopTransportShip.lockLoadTarget.data[idx] = flag;
			shipOnBoardOptions[idx].hook.toolTipText = (flag ? LocalizationManager.GetTranslation("ScriptTerms.OnBoardLocked") : LocalizationManager.GetTranslation("ScriptTerms.OnBoardUnlocked"));
			shipOnBoardOptions[idx].lockIcon.SetActive(flag);
		}
	}

	public void OnSettleUpdate(SeedShip seedShip, bool canSettle)
	{
		if (gameObject.activeSelf && seedShip == currentUnitSelected as SeedShip)
		{
			settleBtn.interactable = canSettle;
		}
	}

	public void RecooperateUpdate()
	{
		bool flag = false;
		ArmySystem.Army army;
		if (IsTabSelected())
		{
			for (int i = 0; i < tabUnits.Count; i++)
			{
				if (flag)
				{
					break;
				}
				flag = ValidRecooperate(tabUnits.data[i], out army);
			}
		}
		else if (IsUnitSelected())
		{
			flag = ValidRecooperate(currentUnitSelected, out army);
		}
		recuperateContainer.SetActive(flag);
		recuperateButton.interactable = flag;
	}

	public void OnGiftDrop()
	{
		if (currentUnitSelected is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy } army)
		{
			army.general.GetComponent<Envoy>().TryDropGift();
		}
	}

	public void OnGiftDeliver()
	{
		if (currentUnitSelected is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy } army)
		{
			int landMassIdx = World.inst.GetCellDataClamped(army.generalPos).landMassIdx;
			LandmassOwner landmassOwner = World.GetLandmassOwner(landMassIdx);
			Envoy component = army.general.GetComponent<Envoy>();
			AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(landMassIdx);
			GameUI.inst.diplomacyUI.Show(component, landmassOwner, landMassIdx, kingdomByLandmass);
			GameUI.inst.diplomacyUI.DoDeliverGift();
		}
	}

	public void OnDisband()
	{
		if (IsTabSelected())
		{
			for (int i = 0; i < tabUnits.Count; i++)
			{
				IMoveableUnit unit = tabUnits.data[i];
				DisbandUnit(unit);
			}
		}
		else if (IsUnitSelected())
		{
			DisbandUnit(currentUnitSelected);
		}
		currentUnitSelected = null;
		currentUnitHovered = null;
		SelectTab(UnitTabs.All);
	}

	private void DisbandUnit(IMoveableUnit unit)
	{
		if (unit is ArmySystem.Army { armyType: ArmySystem.ArmyType.Envoy } army)
		{
			army.general.GetComponent<Envoy>().TryDropGift();
		}
		unit.Disband();
	}

	private void ResetVisuals(UnitTabs prevTab, UnitTabs newTab)
	{
		unitHealthContainer.SetActive(value: false);
		unitAttackContainer.SetActive(value: false);
		if (newTab == UnitTabs.All || newTab == UnitTabs.Individual || (prevTab == UnitTabs.Archers && newTab != UnitTabs.Knights) || (prevTab == UnitTabs.Knights && newTab != UnitTabs.Archers))
		{
			unitAttackBehaviorContainer.SetActive(value: false);
		}
		envoyGiftContainer.SetActive(value: false);
		settleContainer.SetActive(value: false);
		shipOnBoardContainer.SetActive(value: false);
		unitWageErrorContainer.SetActive(value: false);
		recuperateContainer.SetActive(value: false);
	}

	public void SelectTab(UnitTabs tab)
	{
		if (tab == currentTabSelected)
		{
			return;
		}
		DeselectTab(currentTabSelected);
		if (tab == UnitTabs.All)
		{
			currentUnitSelected = null;
			PopulateUnitOptions();
			allUnitsDisplayContainer.SetActive(value: true);
			individualUnitDisplayContainer.SetActive(value: false);
		}
		if (tab != UnitTabs.Individual)
		{
			tabRoot[(int)tab].transform.GetChild(1).gameObject.SetActive(value: true);
			currentUnitSelected = null;
			SfxSystem.PlayUiSelect();
			if (tab != UnitTabs.All)
			{
				GetUnitsOfTab(tab);
				ResetVisuals(currentTabSelected, tab);
				unitTitle.SetText(GetTabLocalization(tab));
				int bannerIdx = Player.inst.PlayerLandmassOwner.bannerIdx;
				switch (tab)
				{
				case UnitTabs.Knights:
				case UnitTabs.Archers:
				{
					unitAttackBehaviorContainer.SetActive(value: true);
					unitAttackBehaviorToggleGroup.allowSwitchOff = true;
					unitAttackBehaviorAttack.isOn = false;
					unitAttackBehaviorHold.isOn = false;
					unitAttackBehaviorPursue.isOn = false;
					unitInstructionsText.SetText(GamepadControl.GetPlatformLocalization("ArmyDescription", "ScriptTerms.ConsoleArmyDescription"));
					unitIcon.sprite = ((tab == UnitTabs.Knights) ? World.inst.liverySets[bannerIdx].knightSprite : World.inst.liverySets[bannerIdx].archerSprite);
					for (int j = 0; j < tabUnits.Count; j++)
					{
						if (tabUnits.data[j] is ArmySystem.Army army && army.units.Count < army.squadSize)
						{
							recuperateButton.interactable = true;
							break;
						}
					}
					break;
				}
				case UnitTabs.Settlers:
				{
					settleContainer.SetActive(value: true);
					settleBtn.interactable = false;
					for (int i = 0; i < tabUnits.Count; i++)
					{
						Cell cellData = World.inst.GetCellData(tabUnits.data[i].GetPos());
						if (Player.inst.LandMassIsAPlayerLandMass(cellData.landMassIdx))
						{
							settleBtn.interactable = true;
							break;
						}
					}
					unitInstructionsText.text = GamepadControl.GetPlatformLocalization("ScriptTerms.SettlerDescription", "ScriptTerms.ConsoleSettlerDescription");
					unitIcon.sprite = World.inst.liverySets[bannerIdx].settlerSprite;
					break;
				}
				}
				individualUnitDisplayContainer.SetActive(value: true);
				allUnitsDisplayContainer.SetActive(value: false);
			}
		}
		else
		{
			SfxSystem.PlayUiCancel();
		}
		currentTabSelected = tab;
	}

	public void DeselectTab(UnitTabs tab)
	{
		if (tab != UnitTabs.Individual)
		{
			tabRoot[(int)currentTabSelected].transform.GetChild(1).gameObject.SetActive(value: false);
		}
	}

	private void UpdateAttackBehaviorVisuals(ArmySystem.ArmyBehavior behavior)
	{
		unitAttackBehaviorHold.isOn = behavior == ArmySystem.ArmyBehavior.Hold;
		unitAttackBehaviorAttack.isOn = behavior == ArmySystem.ArmyBehavior.Attack;
		unitAttackBehaviorPursue.isOn = behavior == ArmySystem.ArmyBehavior.Pursue;
		prevAttackBehavior = behavior;
	}

	public void ToggleHold()
	{
		SetToggle(ArmySystem.ArmyBehavior.Hold);
	}

	public void ToggleAttack()
	{
		SetToggle(ArmySystem.ArmyBehavior.Attack);
	}

	public void TogglePursue()
	{
		SetToggle(ArmySystem.ArmyBehavior.Pursue);
	}

	public void SetToggle(ArmySystem.ArmyBehavior behavior)
	{
		if (unitAttackBehaviorToggleGroup.allowSwitchOff)
		{
			unitAttackBehaviorToggleGroup.allowSwitchOff = false;
		}
		if (currentTabSelected == UnitTabs.Knights || currentTabSelected == UnitTabs.Archers)
		{
			for (int i = 0; i < tabUnits.Count; i++)
			{
				ArmySystem.Army army = (ArmySystem.Army)tabUnits.data[i];
				if (army != null)
				{
					army.armyBehavior = behavior;
				}
			}
		}
		else if (currentTabSelected == UnitTabs.Individual && currentUnitSelected != null)
		{
			ArmySystem.Army army2 = (ArmySystem.Army)currentUnitSelected;
			if (army2 != null)
			{
				army2.armyBehavior = behavior;
			}
		}
		SfxSystem.PlayUiSelect();
	}

	public void OnSettle()
	{
		if (IsTabSelected())
		{
			for (int i = 0; i < tabUnits.Count; i++)
			{
				Cell cellData = World.inst.GetCellData(tabUnits.data[i].GetPos());
				if (Player.inst.LandMassIsAPlayerLandMass(cellData.landMassIdx))
				{
					DisbandUnit(tabUnits.data[i]);
					tabUnits.RemoveAt(i);
					i--;
				}
			}
		}
		else if (IsUnitSelected())
		{
			if (currentUnitSelected is SeedShip seedShip)
			{
				Building placeableByUniqueName = GameState.inst.GetPlaceableByUniqueName(World.romanOutpostName);
				Keep component = placeableByUniqueName.GetComponent<Keep>();
				component.seedShip = seedShip;
				component.placementRadius = seedShip.SearchRadius;
				GameUI.inst.CurrPlacementMode.SetCursorObject(placeableByUniqueName, notFirstPlacement: false);
				if (GamepadControl.inst.isControllerActive && entryConsoleItem.isHovered)
				{
					entryConsoleItem.Reset();
				}
				return;
			}
			DisbandUnit(currentUnitSelected);
		}
		currentUnitSelected = null;
		currentUnitHovered = null;
		SelectTab(UnitTabs.All);
	}

	private bool ValidRecooperate(IMoveableUnit unit, out ArmySystem.Army army)
	{
		army = unit as ArmySystem.Army;
		if (army == null)
		{
			return false;
		}
		if (army.units.Count == army.squadSize)
		{
			return false;
		}
		int landMassIdx = World.inst.GetCellData(army.generalPos).landMassIdx;
		if (!Player.inst.PlayerLandmassOwner.OwnsLandMass(landMassIdx))
		{
			return false;
		}
		int num = 0;
		switch (army.armyType)
		{
		case ArmySystem.ArmyType.Default:
			num = World.barracksHash;
			break;
		case ArmySystem.ArmyType.Archer:
			num = World.archerSchoolHash;
			break;
		}
		if (num != 0)
		{
			return Player.inst.GetBuildingListForLandMass(landMassIdx, num).Count > 0;
		}
		return false;
	}

	public void OnRecooperate()
	{
		ArmySystem.Army army2;
		if (IsTabSelected())
		{
			for (int i = 0; i < tabUnits.Count; i++)
			{
				if (ValidRecooperate(tabUnits.data[i], out var army))
				{
					army.Recooperate();
				}
			}
		}
		else if (IsUnitSelected() && ValidRecooperate(currentUnitSelected, out army2))
		{
			army2.Recooperate();
		}
	}

	private void PopulateUnitOptions()
	{
		for (int i = 0; i < units.Count; i++)
		{
			GameObject option = null;
			if (i >= unitPoolCount)
			{
				if (i == unitPool.Count)
				{
					option = UnityEngine.Object.Instantiate(unitOptionPrefab, unitOptionContainer.transform);
					option.GetComponent<Button>().onClick.AddListener(() =>
					{
						int siblingIndex = option.transform.GetSiblingIndex();
						OnUnitOptionClicked(siblingIndex);
					});
					EventTrigger eventTrigger = option.AddComponent<EventTrigger>();
					EventTrigger.Entry entry = new EventTrigger.Entry();
					entry.eventID = EventTriggerType.PointerEnter;
					entry.callback.AddListener((BaseEventData bData) =>
					{
						int siblingIndex = option.transform.GetSiblingIndex();
						OnUnitOptionHovered(siblingIndex);
					});
					EventTrigger.Entry entry2 = new EventTrigger.Entry();
					entry2.eventID = EventTriggerType.Select;
					entry2.callback.AddListener((BaseEventData bData) =>
					{
						int siblingIndex = option.transform.GetSiblingIndex();
						OnUnitOptionHovered(siblingIndex);
					});
					EventTrigger.Entry entry3 = new EventTrigger.Entry();
					entry3.eventID = EventTriggerType.PointerExit;
					entry3.callback.AddListener((BaseEventData bData) =>
					{
						OnUnitOptionDehovered();
					});
					EventTrigger.Entry entry4 = new EventTrigger.Entry();
					entry4.eventID = EventTriggerType.Deselect;
					entry4.callback.AddListener((BaseEventData bData) =>
					{
						OnUnitOptionDehovered();
					});
					eventTrigger.triggers.Add(entry);
					eventTrigger.triggers.Add(entry2);
					eventTrigger.triggers.Add(entry3);
					eventTrigger.triggers.Add(entry4);
					unitPool.Add(option);
				}
				unitPoolCount++;
			}
			option = unitPool.data[i];
			option.transform.GetChild(0).GetComponent<Image>().sprite = GetSpriteForUnit(units.data[i]);
			option.SetActive(value: true);
		}
		if (unitPoolCount > units.Count)
		{
			for (int num = unitPoolCount - 1; num >= units.Count; num--)
			{
				unitPool.data[num].SetActive(value: false);
			}
			unitPoolCount = units.Count;
		}
	}

	private Sprite GetSpriteForUnit(IMoveableUnit unit)
	{
		int num = unit.TeamID();
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(num);
		int index = 0;
		if (landmassOwnerByTeamId != null)
		{
			index = landmassOwnerByTeamId.bannerIdx;
		}
		if (unit is ArmySystem.Army army)
		{
			if (army.armyType == ArmySystem.ArmyType.Default)
			{
				if (num == 1)
				{
					return World.inst.icon_viking;
				}
				return World.inst.liverySets[index].knightSprite;
			}
			if (army.armyType == ArmySystem.ArmyType.Archer)
			{
				return World.inst.liverySets[index].archerSprite;
			}
			if (army.armyType == ArmySystem.ArmyType.Envoy)
			{
				return World.inst.liverySets[index].envoySprite;
			}
			if (army.armyType == ArmySystem.ArmyType.Settler)
			{
				return World.inst.liverySets[index].settlerSprite;
			}
		}
		else
		{
			if (unit is SiegeCatapult)
			{
				return World.inst.liverySets[index].catapultSprite;
			}
			if (unit is TroopTransportShip)
			{
				if (num == 1 && unit is ShipBase shipBase)
				{
					if (shipBase.type == ShipBase.ShipType.VikingTroopTransport)
					{
						return World.inst.icon_troopTransportShip_vikings;
					}
					if (shipBase.type == ShipBase.ShipType.OgreTroopTransport)
					{
						return World.inst.icon_troopTransportShip_ogre;
					}
				}
				return World.inst.liverySets[index].transportSprite;
			}
			if (unit is SeedShip)
			{
				return World.inst.liverySets[index].seedSprite;
			}
			if (unit is SiegeMonster)
			{
				return World.inst.icon_ogre;
			}
		}
		return null;
	}

	private UnitPriorityOrder GetUnitPriority(IMoveableUnit unit)
	{
		if (unit is ArmySystem.Army army)
		{
			if (army.armyType == ArmySystem.ArmyType.Default)
			{
				return UnitPriorityOrder.Knights;
			}
			if (army.armyType == ArmySystem.ArmyType.Archer)
			{
				return UnitPriorityOrder.Archers;
			}
			if (army.armyType == ArmySystem.ArmyType.Settler)
			{
				return UnitPriorityOrder.Settlers;
			}
			if (army.armyType == ArmySystem.ArmyType.Envoy)
			{
				return UnitPriorityOrder.Envoys;
			}
			return UnitPriorityOrder.SeedShip;
		}
		if (unit is SiegeCatapult)
		{
			return UnitPriorityOrder.Catapults;
		}
		if (unit is TroopTransportShip)
		{
			return UnitPriorityOrder.TransportShips;
		}
		_ = unit is SeedShip;
		return UnitPriorityOrder.SeedShip;
	}

	private UnitTabs GetUnitTab(IMoveableUnit unit)
	{
		if (unit is ArmySystem.Army army)
		{
			if (army.armyType == ArmySystem.ArmyType.Default)
			{
				return UnitTabs.Knights;
			}
			if (army.armyType == ArmySystem.ArmyType.Archer)
			{
				return UnitTabs.Archers;
			}
			if (army.armyType == ArmySystem.ArmyType.Settler)
			{
				return UnitTabs.Settlers;
			}
		}
		return UnitTabs.All;
	}

	private void GetUnitsOfTab(UnitTabs tab)
	{
		tabUnits.ClearFast();
		for (int i = 0; i < units.Count; i++)
		{
			if (GetUnitTab(units.data[i]) == tab)
			{
				tabUnits.Add(units.data[i]);
			}
		}
	}

	private string GetTabLocalization(UnitTabs tab)
	{
		return tab switch
		{
			UnitTabs.All => ScriptLocalization.SelectUnit, 
			UnitTabs.Archers => "ScriptLocalization.JobCategoryArchers", 
			UnitTabs.Knights => "ScriptLocalization.Knights", 
			UnitTabs.Settlers => "ScriptLocalization.Settlers", 
			_ => "", 
		};
	}
}
