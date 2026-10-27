using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class IslandInfoContainer : MonoBehaviour, ISubmitHandler, IEventSystemHandler
{
	[SerializeField]
	private Button jobPriorityBtn;

	[SerializeField]
	private Button logisticsBtn;

	[SerializeField]
	private GameObject logisticOverlayGO;

	[SerializeField]
	private StaticTooltipHook logisticsTooltip;

	public RegionNameUI regionTitleBar;

	public PopulationUI StatsPanel;

	public GodHonorUI GodHonorUI;

	public HappinessUI HappinessUI;

	public HealthUI HealthUI;

	public IntegrityUI IntegrityUI;

	public SlideAnim slideAnim;

	public ConsoleUIItem consoleItemEntry;

	public GameObject consoleLTIcon;

	public GameObject jobPriorityLockContainer;

	public Button jobPriority;

	public static IslandInfoContainer inst;

	public bool isShowing;

	public GameObject overlayMarker;

	public TextMeshProUGUI overlayMarkerTitle;

	public bool deferGamepadToggle;

	private void Awake()
	{
		inst = this;
		jobPriorityBtn.onClick.AddListener(() =>
		{
			DecreeUI.inst.ToggleVisibility();
		});
	}

	private void OnDestroy()
	{
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(UpdateConsoleUI));
	}

	private void Start()
	{
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(UpdateConsoleUI));
		logisticsBtn.onClick.AddListener(() =>
		{
			HideOverlays();
			if (GameUI.inst.IsLogisticViewModeActive())
			{
				GameUI.inst.ReturnToDefaultCursorMode();
			}
			else
			{
				GameUI.inst.SetCursorMode(GameUI.inst.logisticsViewCursorMode);
			}
		});
	}

	public void UpdateConsoleUI(bool isControllerActive)
	{
		consoleLTIcon.SetActive(isControllerActive);
	}

	public void SetOverlayTitleText(string text)
	{
		overlayMarkerTitle.text = text;
	}

	private void Update()
	{
		if (!LoadSave.Loading)
		{
			bool flag = Player.inst.FocusedLandMass != -1 && Player.inst.GetBuildingListForLandMass(Player.inst.FocusedLandMass).Count > 0;
			bool flag2 = GameState.inst.DevOptionShowUIforAIs() || ((World.GetLandmassOwner(Player.inst.FocusedLandMass) == Player.inst.PlayerLandmassOwner) & flag);
			flag2 &= ChariotRaceTrackUI.inst.DoShowResources();
			slideAnim.Play(flag2 ? SlideAnim.PlayMode.Forward : SlideAnim.PlayMode.Reverse);
			bool active = HappinessUI.overlayOn || HealthUI.overlayOn || IntegrityUI.overlayOn || GameUI.inst.IsLogisticViewModeActive();
			Util.SetActive(overlayMarker, active);
			bool active2 = TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_transportcart") || TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_transportShip");
			Util.SetActive(logisticsBtn.gameObject, active2);
			bool flag3 = LogisticsManager.inst.logisticCarts.Count > 0 || ShipSystem.inst.HasLogisticShip();
			Util.SetEnabled(logisticsTooltip, !flag3);
			logisticsBtn.interactable = flag3;
			Util.SetActive(logisticOverlayGO, GameUI.inst.IsLogisticViewModeActive());
			bool flag4 = Player.inst.DoesAnyBuildingHaveCategoryOnPlayerLandmass("temple", mustBeBuilt: true);
			Util.SetActive(jobPriorityLockContainer, !flag4);
			jobPriority.interactable = flag4;
			Util.SetActive(GodHonorUI.gameObject, active: false);
			GamepadControl.DoGameUINavigation(consoleItemEntry);
			deferGamepadToggle = false;
		}
	}

	public void OnSubmit(BaseEventData eventData)
	{
		HideOverlays();
	}

	public void HideOverlays()
	{
		HappinessUI.HideOverlay();
		HealthUI.HideOverlay();
		IntegrityUI.HideOverlay();
	}
}
