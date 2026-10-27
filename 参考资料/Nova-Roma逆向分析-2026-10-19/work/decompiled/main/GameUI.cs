using System;
using System.Collections.Generic;
using Assets;
using Assets.Code.Interface;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using Steamworks;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using cakeslice;

public class GameUI : MonoBehaviour
{
	public delegate void NotifyAnySelection();

	[Serializable]
	public enum CursorBrushes
	{
		None,
		Fire,
		Trees,
		Viking,
		EliteViking,
		Ogre,
		Catapult,
		Villager,
		General,
		ArcherGeneral,
		Envoy,
		Settlers,
		SmallDragon,
		LargeDragon,
		Wood,
		Stone,
		Food,
		Charcoal,
		Iron,
		Tools,
		Armaments,
		Apples,
		Fish,
		Pork,
		Delete,
		NumBrushes
	}

	[Serializable]
	public enum HoverIcons
	{
		None,
		Load,
		Unload,
		Chop,
		ChopRemove,
		Rebuild,
		Demolish,
		EditRoute,
		EditTerrain,
		NumIcons
	}

	public RectTransform rectT;

	public Transform gameCursor;

	public Selector HighlightPrefab;

	public Selector SelectorPrefab;

	public GameObject ShareUI;

	public GameObject RecordUI;

	public Text LoadSaveTitle;

	public Canvas worldCanvas;

	public Camera WorldCamera;

	public Camera UICamera;

	private List<CanvasScaler> canvasScalers = new List<CanvasScaler>();

	public ResourceText ResourceText;

	public GameObject tutorialSwipeHand;

	public float dpi;

	public AnimationCurve scaleInCurve;

	public WorkerUI workerUI;

	public OutputUI outputUI;

	public ConstructUI constructUI;

	public TileInfoUI tileInfoUI;

	public ConsoleTileUI consoleTileUI;

	public ResourceUI resourceUI;

	public PersonUI personUI;

	public ShipLogisticsUI shipLogisticsUI;

	public LevelUpUI levelUpUI;

	public SurvivalIntroUI survivalIntro;

	public SurvivalSuccessUI survivalSuccess;

	public DemolishWarningUI demolishWarningUI;

	public DiplomacyUI diplomacyUI;

	public GodUI godUI;

	public IslandInfoContainer islandInfoUI;

	public ForeignIslandInfoContainer foreignIslandInfoUI;

	public MiniMapViewer miniMapViewer;

	public VikingNotification vikingNotification;

	public DragonNotification dragonNotification;

	public MerchantNotification merchantNotification;

	public VignetteController vignetteController;

	public EditTerrainUI editTerrainUI;

	public DamPlannerUI damPlannerUI;

	public SlabUI slabUI;

	public DiplomacyNotificationUI diplomacyNotificationUI;

	public AudioSource cellSelectorSpeaker;

	public AudioSource uiSpeaker;

	public Canvas MainCanvas;

	[NonSerialized]
	public PlacementMode CurrPlacementMode = new PlacementMode();

	private float BuildingPlacementFromMenuSafetyDelay;

	public GameObject VotingFeature;

	private TerrainFeatureHighlight terrainFeatureHighlight;

	public EventReference startChopSound;

	public Mesh arrowMesh;

	public Material arrowMaterial;

	public Button menuButton;

	public CanvasScaler advisorCanvas;

	public float baseScale = 0.18f;

	public float uiScaleMag = 0.5f;

	public float matchValue;

	private bool hasUpdatedScalers;

	public Color successColor;

	public Color failColor;

	public Action ResolutionChanged;

	public CanvasScaler scaler;

	public static GameUI inst;

	public Transform cursorModeButtonContainer;

	private Cell lastCell;

	private Cell prevHighlightedCell;

	private TerrainResource prevRayTerrainResource;

	public VillagerTracker workerVillagerTracker;

	public VillagerTracker apolloShrineHealingTracker;

	private ISelectableBuilding selectedBuilding;

	private ISelectableBuilding lastSelectedBuilding;

	private ISelectableBuilding lastPlacedBuilding;

	private List<IOverlayUser> overlays = new List<IOverlayUser>();

	[NonSerialized]
	public List<ISelectable> selectedObjs = new List<ISelectable>();

	[NonSerialized]
	public List<ISelectable> highlightedObjs = new List<ISelectable>();

	public NotifyAnySelection OnSelectionUpdate;

	public const string brush_chop = "brush_chop";

	public const string brush_chopremove = "brush_chopremove";

	public const string brush_demolish = "brush_demolish";

	public const string brush_editRoute = "brush_editroute";

	public const string brush_editTerrain = "brush_editroute";

	public const string brush_load = "brush_load";

	public const string brush_rebuild = "brush_rebuild";

	public const string brush_unload = "brush_unload";

	public CursorBrushes brushMode;

	[NonSerialized]
	public Selector CellSelector;

	[NonSerialized]
	public Selector CellHighlighter;

	public const string Selector_DragHighlight = "selector_draghighlight";

	public const string Selector_CellHighlight = "selector_cellhighlight";

	private bool recalcFormationOffsets;

	public SiegeMonster ogrePrefab;

	private Vector3 leftMouseDownPos;

	private Vector3 middleMouseDownPos;

	private Vector3 rightMouseDownPos;

	internal CursorMode currCursorMode;

	internal CursorMode chopCursorMode;

	internal CursorMode chopCancelCursorMode;

	internal CursorMode demolishCursorMode;

	internal CursorMode rebuildCursorMode;

	internal CursorMode consoleCursorMode;

	internal CursorMode aqueductPlacementCursorMode;

	internal CursorMode dedicateGodCursorMode;

	internal CursorMode sampleCursorMode;

	internal CursorMode legionCursorMode = new LegionCursorMode();

	internal SelectLogisticsSourceMode sourceLogisticsCursorMode = new SelectLogisticsSourceMode();

	internal LogisticsRouteCursorMode routeLogisticsCursorMode = new LogisticsRouteCursorMode();

	internal CursorMode unitControlCursorMode = new UnitControlCursorMode();

	internal CursorMode chariotRaceCursorMode = new ChariotRaceCursorMode();

	internal LogisticsViewMode logisticsViewCursorMode = new LogisticsViewMode();

	private bool leftMouseDownCaptured;

	private bool dragSelecting;

	private Vector3 dragStart;

	private Vector3 dragEnd;

	public bool dragConfirm;

	[NonSerialized]
	public int lastScreenWidth;

	[NonSerialized]
	public int lastScreenHeight;

	[NonSerialized]
	public float lastCanvasWidth;

	[NonSerialized]
	public float lastCanvasHeight;

	private bool consumedPlace;

	private static ArrayExtRef<Villager> scratchVillagers = new ArrayExtRef<Villager>(128);

	private EventInstance buildingAmbientLoop;

	private List<Vector3>[] formationOffsets = new List<Vector3>[2];

	private List<bool>[] formationOffsetsInUse = new List<bool>[2];

	private List<IMoveableUnit> scratchList = new List<IMoveableUnit>();

	private OutlineEffect outlineEffect;

	private ArrayExt<ArrayExt<Building>> buildingListCat = new ArrayExt<ArrayExt<Building>>(10);

	private RaycastHit[] scratchHitResults = new RaycastHit[32];

	private Villager overPerson;

	private ISelectableBuilding highlightBuilding;

	private bool didDrag;

	public EventReference soundOnSelectBuilding;

	public EventReference soundOnReleaseBuildUIButton;

	public EventReference soundOnClickBuildUIButton;

	private bool firstUpdate = true;

	private void Awake()
	{
		inst = this;
		currCursorMode = null;
		chopCursorMode = new ChopCursorMode();
		chopCancelCursorMode = new ChopCancelCursorMode();
		demolishCursorMode = new DemolishCursorMode();
		rebuildCursorMode = new RebuildCursorMode();
		consoleCursorMode = new ConsoleCursorMode();
		aqueductPlacementCursorMode = new AqueductPlacementCursorMode();
		dedicateGodCursorMode = new GodDedicateCursorMode();
		sampleCursorMode = new SampleCursorMode();
		GetComponentsInChildren(canvasScalers);
		canvasScalers.Add(advisorCanvas);
		canvasScalers.Add(Cinematics.inst.GetComponent<CanvasScaler>());
		terrainFeatureHighlight = new TerrainFeatureHighlight();
	}

	public void SetVisabilityGameUIAllCanvases(bool visible)
	{
		foreach (Transform item in transform)
		{
			item.gameObject.SetActive(visible);
		}
	}

	public void SetVisabilityGameUICanvas(string name, bool visibility)
	{
		foreach (Transform item in base.transform)
		{
			if (item.name == name)
			{
				item.gameObject.SetActive(visibility);
			}
		}
	}

	internal void UpdateCanvasScalers()
	{
		float num = (float)Screen.width / (float)Screen.height;
		matchValue = baseScale * num - Assets.Settings.inst.UIScale * uiScaleMag * num;
		for (int i = 0; i < canvasScalers.Count; i++)
		{
			canvasScalers[i].screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
			canvasScalers[i].matchWidthOrHeight = matchValue;
		}
		hasUpdatedScalers = true;
	}

	private void Start()
	{
		CellHighlighter = UnityEngine.Object.Instantiate(HighlightPrefab);
		CellHighlighter.SetupSelectorLookup("selector_draghighlight");
		CellHighlighter.ApplyColors();
		CellHighlighter.doShowWorldSizes = true;
		CellHighlighter.AddBrush("brush_chop", Resources.Load<GameObject>("Brushes/brush_chop"));
		CellHighlighter.AddBrush("brush_chopremove", Resources.Load<GameObject>("Brushes/brush_chopremove"));
		CellHighlighter.AddBrush("brush_demolish", Resources.Load<GameObject>("Brushes/brush_demolish"));
		CellHighlighter.AddBrush("brush_load", Resources.Load<GameObject>("Brushes/brush_load"));
		CellHighlighter.AddBrush("brush_rebuild", Resources.Load<GameObject>("Brushes/brush_rebuild"));
		CellHighlighter.AddBrush("brush_unload", Resources.Load<GameObject>("Brushes/brush_unload"));
		CellHighlighter.AddBrush("brush_editroute", Resources.Load<GameObject>("Brushes/brush_editroute"));
		CellHighlighter.AddBrush("brush_editroute", Resources.Load<GameObject>("Brushes/brush_editroute"));
		CellSelector = UnityEngine.Object.Instantiate(SelectorPrefab);
		CellSelector.SetupSelectorLookup("selector_cellhighlight");
		CellSelector.SetSingleCellMesh();
		CellSelector.ApplyColors();
		dpi = ((Screen.dpi != 0f) ? Screen.dpi : 72f);
		Init();
		Screen.orientation = ScreenOrientation.LandscapeLeft;
		OrdersManager.inst.OnUnitDestroyed += Inst_OnUnitDestroyed;
		CreativeUI creativeUI = CreativeUI.inst;
		creativeUI.onBrushSelected = (CreativeUI.OnBrushSelected)Delegate.Combine(creativeUI.onBrushSelected, new CreativeUI.OnBrushSelected(OnCreativeBrushSelected));
	}

	private void OnEnable()
	{
		leftMouseDownCaptured = false;
		dragSelecting = false;
	}

	private void Inst_OnUnitDestroyed(IMoveableUnit u)
	{
		if (u is ISelectable)
		{
			RemoveFromSelection(u as ISelectable);
		}
	}

	public static bool AltHeld()
	{
		if (!Input.GetKey(KeyCode.LeftAlt))
		{
			return Input.GetKey(KeyCode.RightAlt);
		}
		return true;
	}

	public bool DockCursorModeActive()
	{
		if (shipLogisticsUI.cursorMode == null)
		{
			return false;
		}
		return inst.shipLogisticsUI.cursorMode == inst.currCursorMode;
	}

	public bool EditTerrainCursorModeActive()
	{
		if (editTerrainUI.cursorMode == null)
		{
			return false;
		}
		return inst.editTerrainUI.cursorMode == inst.currCursorMode;
	}

	public bool DamPlannerCursorModeActive()
	{
		if (damPlannerUI.cursorMode == null)
		{
			return false;
		}
		return inst.damPlannerUI.cursorMode == inst.currCursorMode;
	}

	public bool TerrainWaterEditModeActive()
	{
		if (!EditTerrainCursorModeActive())
		{
			return DamPlannerCursorModeActive();
		}
		return true;
	}

	public bool AqueductCursorModeActive()
	{
		if (aqueductPlacementCursorMode == null)
		{
			return false;
		}
		return aqueductPlacementCursorMode == inst.currCursorMode;
	}

	public bool IsLogisticViewModeActive()
	{
		if (logisticsViewCursorMode != null)
		{
			return logisticsViewCursorMode == currCursorMode;
		}
		return false;
	}

	public bool IsChariotRaceModeActive()
	{
		if (chariotRaceCursorMode != null)
		{
			return chariotRaceCursorMode == currCursorMode;
		}
		return false;
	}

	public bool IsUnitControlModeActive()
	{
		if (unitControlCursorMode != null)
		{
			return unitControlCursorMode == currCursorMode;
		}
		return false;
	}

	public bool IsColosseumFightModeActive()
	{
		return currCursorMode is ColosseumCursorMode;
	}

	public static bool EditTerrainCursorModeDragging()
	{
		return true;
	}

	public void SetCursorBrush(CursorBrushes newBrush)
	{
		brushMode = newBrush;
		ClearSelection();
		ReturnToDefaultCursorMode();
	}

	public void ReturnToDefaultCursorMode()
	{
		Debug.Log("Returning to default cursor mode.");
		if ((bool)CellHighlighter)
		{
			CellHighlighter.ResetBrushes();
		}
		if (!GamepadControl.inst.isControllerActive)
		{
			if (currCursorMode != null)
			{
				CurrPlacementMode.CancelWaitToPlace();
				currCursorMode.Shutdown();
			}
			currCursorMode = null;
			RefreshCursorModeButtonImages();
		}
		else
		{
			ConsoleCursorMenu.inst.SetConsoleMode();
		}
	}

	public void SetCursorMode(CursorMode newMode)
	{
		if (newMode == currCursorMode)
		{
			ReturnToDefaultCursorMode();
			return;
		}
		if (newMode != null)
		{
			Debug.Log("Entering Cursor Mode: " + newMode.ToString());
		}
		if (newMode != currCursorMode)
		{
			CurrPlacementMode.CancelWaitToPlace();
		}
		if (currCursorMode != null)
		{
			currCursorMode.Shutdown();
		}
		AbortCursorObjPlacement();
		currCursorMode = newMode;
		currCursorMode.Init();
		RefreshCursorModeButtonImages();
		SfxSystem.PlayUiSelect();
		TileInfoUI.inst.SetVisibility(v: false);
		CreativeUI.inst.SetWindowVisibility(v: false);
		ClearSelection();
		if (newMode.DoClearSelectedCellOnInit())
		{
			ClearCellSelected();
		}
		personUI.SetVisible(v: false);
		if ((bool)CellHighlighter)
		{
			if (currCursorMode == chopCursorMode)
			{
				CellHighlighter.SetBrush("brush_chop");
			}
			else if (currCursorMode == chopCancelCursorMode)
			{
				CellHighlighter.SetBrush("brush_chopremove");
			}
			else if (currCursorMode == demolishCursorMode)
			{
				CellHighlighter.SetBrush("brush_demolish");
			}
			else if (currCursorMode == rebuildCursorMode)
			{
				CellHighlighter.SetBrush("brush_rebuild");
			}
			else if (currCursorMode == shipLogisticsUI.cursorMode)
			{
				CellHighlighter.SetBrush("brush_editroute");
			}
			else if (currCursorMode == editTerrainUI.cursorMode)
			{
				CellHighlighter.SetBrush("brush_editroute");
			}
			else if (currCursorMode == aqueductPlacementCursorMode)
			{
				CellHighlighter.SetBrush("brush_editroute");
			}
			else if (currCursorMode == sampleCursorMode)
			{
				CellHighlighter.ResetBrushes();
			}
			else if (currCursorMode == consoleCursorMode)
			{
				CellHighlighter.ResetBrushes();
			}
		}
	}

	public void SetCursorModeConsole()
	{
		SetCursorMode(consoleCursorMode);
	}

	public void SetCursorModeChop()
	{
		SetCursorMode(chopCursorMode);
	}

	public void SetCursorModeChopCancel()
	{
		SetCursorMode(chopCancelCursorMode);
	}

	public void SetCursorModeDemolish()
	{
		SetCursorMode(demolishCursorMode);
	}

	public void SetCursorModeRebuild()
	{
		SetCursorMode(rebuildCursorMode);
	}

	public void SetCursorModeAqueductPlacement()
	{
		SetCursorMode(aqueductPlacementCursorMode);
	}

	public void SetCursorModeEditTerrain()
	{
		SetCursorMode(editTerrainUI.cursorMode);
	}

	public void SetCursorModeDamPlanner()
	{
		SetCursorMode(damPlannerUI.cursorMode);
	}

	public void SetCursorModeSample()
	{
		SetCursorMode(sampleCursorMode);
	}

	public void SetCursorModeChariotRace()
	{
		SetCursorMode(chariotRaceCursorMode);
	}

	public void SetCursorModeSelectLogisticsSource()
	{
		SetCursorMode(sourceLogisticsCursorMode);
	}

	public void SetCursorModeLogisticsRoute()
	{
		SetCursorMode(routeLogisticsCursorMode);
	}

	public void RefreshCursorModeButtonImages()
	{
		CursorModeUI.inst.ConsoleButton.isSelected.enabled = false;
		CursorModeUI.inst.ChopButton.isSelected.enabled = currCursorMode == chopCursorMode;
		CursorModeUI.inst.ChopCancelButton.isSelected.enabled = currCursorMode == chopCancelCursorMode;
		CursorModeUI.inst.EditTerrainButton.isSelected.enabled = currCursorMode == editTerrainUI.cursorMode;
		CursorModeUI.inst.RebuildButton.isSelected.enabled = currCursorMode == rebuildCursorMode;
		CursorModeUI.inst.DemolishButton.isSelected.enabled = currCursorMode == demolishCursorMode;
		CursorModeUI.inst.SampleButton.isSelected.enabled = currCursorMode == sampleCursorMode;
	}

	public void Init()
	{
		highlightBuilding = null;
		firstUpdate = true;
		prevHighlightedCell = null;
		UpdateCanvasScalers();
		ReturnToDefaultCursorMode();
		lastCell = null;
		lastPlacedBuilding = null;
		CreativeUI.inst.SetWindowVisibility(v: false);
		workerUI.SetVisible(v: false);
		constructUI.SetVisibility(v: false);
		personUI.gameObject.SetActive(value: false);
		shipLogisticsUI.gameObject.SetActive(value: false);
		editTerrainUI.gameObject.SetActive(value: false);
		damPlannerUI.gameObject.SetActive(value: false);
		diplomacyUI.Hide();
		godUI.Hide();
		if (diplomacyNotificationUI != null)
		{
			diplomacyNotificationUI.CloseAllBanners();
		}
		MiniMapUI.inst.ResetPings();
		AdvisorUI.inst.Hide();
		if ((bool)HappinessUI.inst)
		{
			HappinessUI.inst.HideOverlay();
		}
		SeasonViewer.inst.Reset();
		GodUI.inst.TryInit();
		if (IsOnConsole())
		{
			Vector2 referenceResolution = new Vector2(950f, 950f);
			if (workerUI.GetComponentInParent<CanvasScaler>() != null)
			{
				workerUI.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				islandInfoUI.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				CreativeUI.inst.canvasScaler.referenceResolution = referenceResolution;
				TileInfoUI.inst.GetComponent<CanvasScaler>().referenceResolution = referenceResolution;
				constructUI.GetComponent<CanvasScaler>().referenceResolution = referenceResolution;
				TownNameUI.inst.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				SpeedControlUI.inst.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				ForeignRegionNameUI.inst.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				BuildInfoFloating.inst.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				consoleTileUI.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				BuildInfoUI.inst.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				ConsoleBuildMenu.inst.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
				DecreeUI.inst.GetComponent<CanvasScaler>().referenceResolution = referenceResolution;
				AdvisorUI.inst.GetComponentInParent<CanvasScaler>().referenceResolution = referenceResolution;
			}
		}
	}

	public void Reset()
	{
		Init();
		AbortCursorObjPlacement(refund: false);
		terrainFeatureHighlight.Reset();
	}

	public void OnCreativeBrushSelected(CreativeBrush brush)
	{
		if (brush != null)
		{
			CellSelector.SetVisibility(v: false);
			CellHighlighter.SetVisibility(v: false);
		}
	}

	public static bool IsOnConsole()
	{
		if (SteamUtils.IsSteamRunningOnSteamDeck())
		{
			return true;
		}
		return false;
	}

	public bool PointerOverUI()
	{
		bool flag = EventSystem.current.IsPointerOverGameObject();
		if (Input.touchSupported)
		{
			for (int i = 0; i < Input.touchCount; i++)
			{
				bool flag2 = EventSystem.current.IsPointerOverGameObject(Input.GetTouch(0).fingerId);
				flag |= flag2;
			}
		}
		if (GamepadControl.inst.isControllerActive)
		{
			flag = GamepadControl.inst.IsNavigatingUI();
		}
		return flag;
	}

	public bool WasEventConsumed()
	{
		if (!PointerOverUI())
		{
			return GamepadControl.inst.ignoreInputThisFrame;
		}
		return true;
	}

	public void UpdateForNewSelection()
	{
		workerUI.UpdateForNewSelection();
		constructUI.UpdateForNewSelection();
	}

	public void AcceptCursorObjPlacement()
	{
		CurrPlacementMode.AcceptPlacement();
	}

	public Cell GetHighlightedCell()
	{
		return prevHighlightedCell;
	}

	public Cell GetCellSelected()
	{
		return lastCell;
	}

	public bool SelectedBuildingIs<T>()
	{
		ISelectableBuilding genericBuildingSelected = GetGenericBuildingSelected();
		if (genericBuildingSelected != null)
		{
			Building building = genericBuildingSelected as Building;
			if (building != null)
			{
				return building.GetComponent<T>() != null;
			}
			return genericBuildingSelected is T;
		}
		return false;
	}

	public T GetInterfaceFromSelectableBuilding<T>(ISelectableBuilding building) where T : class
	{
		if (building != null)
		{
			Building building2 = building as Building;
			if (building2 != null)
			{
				return building2.GetComponent<T>();
			}
			return building as T;
		}
		return null;
	}

	public bool GetGenericBuildingSelected<T>()
	{
		if (GetGenericBuildingSelected() != null)
		{
			return GetGenericBuildingSelected() is T;
		}
		return false;
	}

	public bool SelectedBuildingIs(Building specificBuilding)
	{
		return specificBuilding == GetBuildingSelected();
	}

	public bool SelectedBuildingIs(int uniqueNameHash)
	{
		if (GetBuildingSelected() != null)
		{
			return GetBuildingSelected().uniqueNameHash == uniqueNameHash;
		}
		return false;
	}

	public Building GetBuildingSelected()
	{
		Building building = selectedBuilding as Building;
		if (selectedBuilding != null && !selectedBuilding.Equals(null) && (object)building != null)
		{
			return building;
		}
		return null;
	}

	public ISelectableBuilding GetGenericBuildingSelected()
	{
		if (selectedBuilding != null && !selectedBuilding.Equals(null))
		{
			return selectedBuilding;
		}
		return null;
	}

	public void SetSelectedBuildingNew(ISelectableBuilding building, bool forceUpdate = false)
	{
		Building building2 = building as Building;
		if (building2 != null && DamProjectManager.inst.IsCellPartOfProject(building2.cachedCell, out var project))
		{
			SetSelectedBuildingNew(project);
			return;
		}
		if (building2 != null && building2.categoryHash == World.castleblockHash)
		{
			List<Building> occupyingStructure = building2.GetCell().OccupyingStructure;
			building = occupyingStructure[occupyingStructure.Count - 1];
		}
		bool flag = building != selectedBuilding;
		lastSelectedBuilding = selectedBuilding;
		selectedBuilding = building;
		if (building2 != null)
		{
			if (!string.IsNullOrEmpty(building2.selectedAmbientSound))
			{
				AudioEffectManager.ActivateLowpass();
			}
			if (GamepadControl.inst.isControllerActive)
			{
				Plane plane = new Plane(Vector3.up, 0f);
				plane.Raycast(Cam.inst.GetRay(), out var enter);
				Ray ray = new Ray(building2.Center(), Cam.inst.transform.forward);
				plane.Raycast(ray, out var enter2);
				Cam.inst.desiredDist = enter - enter2;
				DebugEx.DrawArrow(building2.Center(), building2.Center() + Vector3.forward * 2f, Color.black, 5f);
			}
		}
		UpdateVisibilityForBuildingUI();
		UpdateForNewSelection();
		if (flag | forceUpdate)
		{
			bool flag2 = false;
			if (lastPlacedBuilding != null && lastPlacedBuilding is Component component && component != null)
			{
				component.SendMessage("OnSelectionChanged", SendMessageOptions.DontRequireReceiver);
			}
			if (building != null)
			{
				(building as Component).SendMessage("OnSelectionChanged", SendMessageOptions.DontRequireReceiver);
				if (!CurrPlacementMode.IsPlacing())
				{
					building.PlaySelectSound();
				}
				flag2 = RefreshOverlay();
			}
			lastPlacedBuilding = building;
			if (!CurrPlacementMode.IsPlacing() && !flag2)
			{
				TerrainGen.inst.ClearOverlay(updateToo: true);
			}
			Vector4 packedCursorInfo = new Vector4(CellSelector.transform.position.x, CellSelector.transform.position.z, 0f, 0f);
			TerrainGen.inst.UpdateCursorPosition(packedCursorInfo);
		}
		BuildUI.inst.HideGroups();
	}

	public void SelectCell(Cell cell, bool forceChange = false)
	{
		if (cell == null)
		{
			Debug.Log("Use ClearCellSelected() instead");
			return;
		}
		CellSelector.SetVisibility(v: true);
		bool num = lastCell != cell || lastSelectedBuilding != GetBuildingSelected();
		lastCell = cell;
		UpdateVisibilityForSelectedCellUI();
		TileInfoUI.inst.UpdateForNewCell(cell);
		if (num | forceChange)
		{
			bool flag = false;
			Building buildingSelected = GetBuildingSelected();
			if (lastPlacedBuilding != null && lastPlacedBuilding is Component component && component != null)
			{
				component.SendMessage("OnSelectionChanged", SendMessageOptions.DontRequireReceiver);
			}
			if ((bool)buildingSelected)
			{
				buildingSelected.SendMessage("OnSelectionChanged", SendMessageOptions.DontRequireReceiver);
				if (!CurrPlacementMode.IsPlacing() && buildingSelected.SelectionSounds.Length != 0)
				{
					int num2 = SRand.Range(0, buildingSelected.SelectionSounds.Length);
					string groupName = buildingSelected.SelectionSounds[num2];
					SfxSystem.inst.PlayFromBank(groupName, buildingSelected.Center());
				}
				flag = RefreshOverlay();
			}
			lastPlacedBuilding = buildingSelected;
			if (!CurrPlacementMode.IsPlacing() && !flag)
			{
				TerrainGen.inst.ClearOverlay(updateToo: true);
			}
			Vector4 packedCursorInfo = new Vector4(CellSelector.transform.position.x, CellSelector.transform.position.z, 0f, 0f);
			TerrainGen.inst.UpdateCursorPosition(packedCursorInfo);
		}
		BuildUI.inst.HideGroups();
	}

	public void ClearCellSelected()
	{
		lastCell = null;
		TerrainGen.inst.ClearOverlay(updateToo: true);
		ISelectableBuilding selectableBuilding = selectedBuilding;
		selectedBuilding = null;
		if (selectableBuilding != null)
		{
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_deselect");
		}
		UpdateVisibilityForSelectedCellUI();
		if (selectableBuilding != null && selectableBuilding is Component component && component != null)
		{
			component.SendMessage("OnSelectionChanged", SendMessageOptions.DontRequireReceiver);
		}
		TileInfoUI.inst.SetVisibility(v: false);
		BuildUI.inst.HideGroups();
		AudioEffectManager.ResetLowpass();
		if (GamepadControl.inst.isControllerActive)
		{
			Ray ray = Cam.inst.GetRay();
			new Plane(Vector3.up, 0f).Raycast(ray, out var enter);
			Cam.inst.SetDesiredTrackingPos(ray.GetPoint(enter));
			Cam.inst.desiredDist = enter;
		}
	}

	public bool RefreshOverlay()
	{
		Building buildingSelected = GetBuildingSelected();
		if (!HappinessUI.inst.overlayOn && buildingSelected != null)
		{
			buildingSelected.GetComponents(overlays);
			for (int i = 0; i < overlays.Count; i++)
			{
				if (overlays[i].OverlayWhenSelected)
				{
					overlays[i].DrawOverlay(buildingSelected.Center());
					return true;
				}
			}
		}
		return false;
	}

	public void AbortCursorObjPlacement(bool refund = true)
	{
		CurrPlacementMode.AbortPlacement(refund);
		Cam.inst.posSmoothDampTime = Cam.inst.posSmoothDampTimeDefault;
		TerrainGen.inst.StopTerritoryTexture();
		if (CellSelector != null && GamepadControl.inst.isControllerActive)
		{
			ClearCellSelected();
		}
		BuildUI.inst.HideGroups();
		leftMouseDownCaptured = false;
	}

	public static bool CanRotate(Building b)
	{
		if (b.categoryHash == World.pathHash && b.uniqueNameHash != World.drawBridgeHash)
		{
			return false;
		}
		return true;
	}

	public void RotateBuilding(Building b, float angle)
	{
		if (CanRotate(b))
		{
			b.Rotate(angle);
		}
	}

	public Vector3 GridPointerIntersection()
	{
		Ray ray = PointingSystem.GetRay();
		if (TerrainGen.inst.Raycast(ray, out var hitInfo))
		{
			return hitInfo.point;
		}
		new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		return World.inst.SnapToGrid2D(point);
	}

	public void ClearUIForCinematics()
	{
		ClearCellSelected();
		workerUI.SetVisible(v: false);
		personUI.SetVisible(v: false);
		personUI.SetSelectedPerson(null);
		shipLogisticsUI.SetVisible(v: false);
		constructUI.SetVisibility(v: false);
		TileInfoUI.inst.SetVisibility(v: false);
		MerchantUI.inst.SetVisibility(visible: false);
		DecreeUI.inst.SetVisibility(v: false);
		diplomacyUI.Hide();
		editTerrainUI.SetVisible(v: false);
		damPlannerUI.SetVisible(v: false);
		if (SettlerShipUI.inst != null)
		{
			SettlerShipUI.inst.SetVisibility(v: false);
		}
		AdvisorUI.inst.Hide();
		BuildUI.inst.HideGroups();
	}

	public void ClearUIForClick()
	{
		ClearUIForCinematics();
		godUI.Hide();
	}

	private Villager WillSelectPerson(out float hitDist)
	{
		hitDist = float.MaxValue;
		if (DockCursorModeActive() || EditTerrainCursorModeActive() || AqueductCursorModeActive())
		{
			return null;
		}
		Ray ray = PointingSystem.GetRay();
		Vector3 vector = World.inst.SnapToGrid2D(GridPointerIntersection()).xz();
		int num = (int)Mathff.Clamp(vector.x - 2f, 0f, World.inst.GridWidth - 1);
		int num2 = (int)Mathff.Clamp(vector.x + 2f, 0f, World.inst.GridWidth - 1);
		int num3 = (int)Mathff.Clamp(vector.z - 2f, 0f, World.inst.GridHeight - 1);
		int num4 = (int)Mathff.Clamp(vector.z + 2f, 0f, World.inst.GridHeight - 1);
		for (int i = num3; i < num4; i++)
		{
			for (int j = num; j <= num2; j++)
			{
				ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(j, i);
				if (!FogOfWar.inst.IsVisible(j, i))
				{
					continue;
				}
				float num5 = 0.166f;
				if (GamepadControl.inst.isControllerActive)
				{
					num5 = 0.25f;
				}
				int k = 0;
				for (int count = villagersAt.Count; k < count; k++)
				{
					Vector3 posWithOffset = villagersAt.data[k].GetPosWithOffset();
					if (Mathff.RaySphereIntersect(ray, posWithOffset + new Vector3(0f, num5, 0f), num5, out hitDist))
					{
						return villagersAt.data[k];
					}
				}
			}
		}
		return null;
	}

	public void SelectPerson(Villager villager)
	{
		RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_buildMenu_select_topMenu_down");
		personUI.SetVisible(v: true);
		personUI.SetSelectedPerson(villager);
		constructUI.SetVisibility(v: false);
		TileInfoUI.inst.SetVisibility(v: false);
	}

	public bool RemoveFromSelection(ISelectable s)
	{
		int idx = selectedObjs.IndexOf(s);
		return RemoveFromSelection(idx);
	}

	public bool RemoveFromSelection(int idx)
	{
		if (idx != -1)
		{
			selectedObjs.RemoveAt(idx);
			recalcFormationOffsets = true;
			OnSelectionUpdate?.Invoke();
			return true;
		}
		return false;
	}

	public void ClearSelection()
	{
		selectedObjs.Clear();
		OnSelectionUpdate?.Invoke();
	}

	public bool IsSelected(ISelectable s)
	{
		return selectedObjs.Contains(s);
	}

	public bool IsHighlighted(ISelectable s)
	{
		return highlightedObjs.Contains(s);
	}

	public bool AddToSelection(ISelectable s)
	{
		if (!s.ValidToSelect())
		{
			return false;
		}
		if (selectedObjs.Contains(s))
		{
			return false;
		}
		if (s.ExclusiveSelect())
		{
			ClearSelection();
		}
		selectedObjs.Add(s);
		s.OnSelected();
		recalcFormationOffsets = true;
		OnSelectionUpdate?.Invoke();
		return true;
	}

	public bool TrySelect(ISelectable s)
	{
		if (inst.AddToSelection(s))
		{
			IMoveableUnit unitFromSelectable = GetUnitFromSelectable(s);
			if (DisplayIMovableUI(unitFromSelectable))
			{
				ClearCellSelected();
				CreativeUI.inst.SetWindowVisibility(v: false);
			}
			return true;
		}
		return false;
	}

	public bool DoPrimaryClick()
	{
		if (!inst.isActiveAndEnabled || GameState.inst.CurrMode != GameState.inst.playingMode || Cinematics.inst.IsCinematicRunning() || CreativeUI.inst.IsBrushActive() || WasEventConsumed())
		{
			return false;
		}
		if (InWorldExclamation.WillClick())
		{
			ClearUIForClick();
			InWorldExclamation.DoClick();
			return true;
		}
		if (GodDisplayIndividual.WillClick())
		{
			ClearUIForClick();
			GodDisplayIndividual.DoClick();
			return true;
		}
		if (currCursorMode == null || currCursorMode == consoleCursorMode)
		{
			if (UnitControlSystem.inst.TrySelectHighlightObjects(highlightedObjs))
			{
				highlightedObjs.Clear();
				selectedObjs.Clear();
				SetCursorMode(unitControlCursorMode);
				return true;
			}
			if (!Input.GetKey(KeyCode.LeftShift) && !Input.GetKey(KeyCode.RightShift))
			{
				ClearSelection();
			}
			for (int i = 0; i < highlightedObjs.Count; i++)
			{
				AddToSelection(highlightedObjs[i]);
			}
			if (selectedObjs.Count > 0)
			{
				return true;
			}
		}
		if (overPerson != null)
		{
			ClearUIForClick();
			SelectPerson(overPerson);
			return true;
		}
		if (highlightBuilding != null)
		{
			if (!CurrPlacementMode.IsPlacing())
			{
				bool flag = false;
				if (currCursorMode != null)
				{
					flag = currCursorMode.DoPrimaryClick(highlightBuilding, null);
				}
				if (!flag)
				{
					ClearUIForClick();
					SetSelectedBuildingNew(highlightBuilding);
				}
			}
			return true;
		}
		Ray ray = PointingSystem.GetRay();
		if (Vector3.Dot(Vector3.down, ray.direction.normalized) > 0f)
		{
			Cell cellData = World.inst.GetCellData(inst.GridPointerIntersection());
			if (cellData != null)
			{
				if (!diplomacyUI.Visible() && !godUI.Visible() && !AdvisorUI.inst.IsVisible() && World.IsAILandmass(cellData.landMassIdx) && !GameState.inst.DevOptionShowUIforAIs() && (currCursorMode == null || currCursorMode == consoleCursorMode))
				{
					ClearUIForClick();
					return false;
				}
				bool flag2 = false;
				if (currCursorMode != null)
				{
					flag2 = currCursorMode.DoPrimaryClick(null, cellData);
				}
				if (!flag2)
				{
					ClearUIForClick();
					selectedBuilding = null;
					SelectCell(cellData);
				}
				return true;
			}
		}
		return false;
	}

	public bool DisplayIMovableUI(IMoveableUnit unit)
	{
		if (IsUnitSelectable(unit) && !diplomacyUI.gameObject.activeSelf && !godUI.gameObject.activeSelf)
		{
			return true;
		}
		return false;
	}

	public bool IsUnitSelectable(IMoveableUnit unit)
	{
		if (unit != null && (unit.TeamID() == 0 || Creative.inst.IsCreativeOptionOn(10)) && unit is ISelectable selectable)
		{
			return selectable.ValidToSelect();
		}
		return false;
	}

	public bool IsHoveringUnitOfRelation(int teamId, World.Relations relation)
	{
		for (int i = 0; i < highlightedObjs.Count; i++)
		{
			if (highlightedObjs[i] is IMoveableUnit moveableUnit && World.inst.RelationBetween(teamId, moveableUnit.TeamID()) == relation)
			{
				return true;
			}
		}
		return false;
	}

	public ClearCutterJob GetClearCutterJob(Cell cell)
	{
		if (cell.landMassIdx == -1)
		{
			return null;
		}
		if (JobSystem.jobCategoriesMap.TryGetValue(21, out var value))
		{
			for (int i = 0; i < value.jobs.data[cell.landMassIdx].Count; i++)
			{
				if (value.jobs.data[cell.landMassIdx].data[i] is ClearCutterJob clearCutterJob && clearCutterJob.cellToChop == cell)
				{
					return clearCutterJob;
				}
			}
		}
		return null;
	}

	public void RemoveChopJobFromCell(Cell cell, bool sfx = true)
	{
		ClearCutterJob clearCutterJob = GetClearCutterJob(cell);
		if (clearCutterJob != null)
		{
			JobSystem.inst.RemoveJob(clearCutterJob);
			if (sfx)
			{
				SfxSystem.PlayUiCancel();
			}
			OneOffEffect oneOffEffect = EffectsMan.inst.TileActionEffect.Create(cell.Center3D + new Vector3(0f, 1f, 0f));
			oneOffEffect.Color = Color.white;
			oneOffEffect.AllowRelease = true;
			oneOffEffect.Play();
		}
	}

	public bool AddChopJobToCell(Cell cell, bool sfx = true, int jobCategory = 21)
	{
		if (GetClearCutterJob(cell) != null)
		{
			return false;
		}
		if (cell.Busy)
		{
			return false;
		}
		if (cell.IsCellClear())
		{
			return false;
		}
		if (World.inst.inFirstPlacementPhase || (Creative.inst.IsCreativeOptionOn(11) && jobCategory == 1))
		{
			cell.ClearCell();
		}
		else
		{
			ClearCutterJob clearCutterJob = new ClearCutterJob(cell);
			JobSystem.inst.AddNewJob(0, clearCutterJob, jobCategory);
			clearCutterJob.StartClearingAt(cell);
			RuntimeManager.PlayOneShot(startChopSound, cell.Center3D);
			OneOffEffect oneOffEffect = EffectsMan.inst.TileActionEffect.Create(cell.Center3D + new Vector3(0f, 1f, 0f));
			oneOffEffect.Color = new Color(0.5f, 1f, 0.5f);
			oneOffEffect.AllowRelease = true;
			oneOffEffect.Play();
		}
		return true;
	}

	public void UpdateUIScaling()
	{
	}

	public bool IsDragSelecting()
	{
		return dragSelecting;
	}

	private void UpdateDragSelectAndHighlighting()
	{
		highlightedObjs.Clear();
		if (dragSelecting)
		{
			dragEnd = GridPointerIntersection();
			if (dragStart.x != dragEnd.x || dragStart.z != dragEnd.z)
			{
				didDrag = true;
			}
			if (currCursorMode == null || currCursorMode == consoleCursorMode)
			{
				GetDragSelectBounds(out var minX, out var minZ, out var maxX, out var maxZ);
				UnitControlSystem.inst.TryAddHighlights(minX, minZ, maxX, maxZ, ref highlightedObjs);
				GameSelectable.AddHighlights(minX, minZ, maxX, maxZ, ref highlightedObjs);
			}
			else if (currCursorMode == demolishCursorMode)
			{
				GetDragSelectBounds(out var minX2, out var minZ2, out var maxX2, out var maxZ2);
				demolishWarningUI.HighlightBuildings(minX2, minZ2, maxX2, maxZ2);
			}
		}
		else if ((currCursorMode == null || currCursorMode == consoleCursorMode || currCursorMode == unitControlCursorMode) && !CurrPlacementMode.IsPlacing() && !PointerOverUI())
		{
			float unitDist = float.MaxValue;
			ISelectable unit = null;
			UnitControlSystem.inst.TryGetHighlight(out unitDist, out unit);
			ISelectable highlight = GameSelectable.GetHighlight(out var minDist);
			if (unitDist < minDist)
			{
				highlightedObjs.Add(unit);
			}
			else if (highlight != null)
			{
				highlightedObjs.Add(highlight);
			}
		}
	}

	private void PruneDeadObjectsFromSelection()
	{
		for (int i = 0; i < selectedObjs.Count; i++)
		{
			if (selectedObjs[i] == null || selectedObjs[i].Equals(null) || !selectedObjs[i].ValidToSelect())
			{
				RemoveFromSelection(i);
				i--;
			}
		}
	}

	private void ClearUIForRightClick()
	{
		AdvisorUI.inst.Hide();
		CreativeUI.inst.SetWindowVisibility(v: false);
		MerchantUI.inst.SetVisibility(visible: false);
		DecreeUI.inst.SetVisibility(v: false);
		PersonUI.inst.SetVisible(v: false);
		CurrPlacementMode.CancelWaitToPlace();
		ClearCellSelected();
		HappinessUI.inst.HideOverlay();
		SettlerShipUI.inst.SetVisibility(v: false);
		ProsperityUI.inst.SetMissionVisibility(v: false);
		ReturnToDefaultCursorMode();
	}

	public static void SetUIForModalHelper(bool v)
	{
		NotificationUI.inst.SetVisibility(v);
		BuildUI.inst.SetVisibility(v);
		CursorModeUI.inst.SetVisibility(v);
		ProsperityUI.inst.SetVisibility(v);
		MiniMapUI.inst.SetVisibility(v);
		SpeedControlUI.inst.SetVisibility(v);
		SeasonViewer.inst.SetVisibility(v);
		CreativeUI.inst.SetVisibility(v && Creative.inst.IsEnabled());
		SpeedControlUI.inst.SetVisibility(v);
	}

	private void UpdateForKeyboard()
	{
		if (PointingSystem.GetPointer().GetSecondaryDown())
		{
			rightMouseDownPos = Input.mousePosition;
		}
		if (PointingSystem.GetPointer().GetPrimaryDown())
		{
			leftMouseDownPos = Input.mousePosition;
			if (!WasEventConsumed())
			{
				leftMouseDownCaptured = true;
			}
		}
		if (PointingSystem.GetPointer().GetTertiaryDown())
		{
			middleMouseDownPos = Input.mousePosition;
		}
		bool flag = false;
		if (!WasEventConsumed() && PointingSystem.GetPointer().GetPrimaryDown() && !AltHeld())
		{
			flag = true;
		}
		if (leftMouseDownCaptured & flag)
		{
			if (!Cam.inst.IsDragging())
			{
				if (currCursorMode != null && !CurrPlacementMode.IsPlacing())
				{
					currCursorMode.HandlePrimaryDown();
				}
				else
				{
					CurrPlacementMode.TryHandlePrimaryDown();
				}
			}
			dragStart = (dragEnd = GridPointerIntersection());
		}
		if (!WasEventConsumed() && leftMouseDownCaptured && PointingSystem.GetPointer().GetPrimaryDownThisFrame() && !AltHeld() && Vector3.Distance(leftMouseDownPos, Input.mousePosition) > (float)(Cam.inst.GetPixelCamDragThreshold() - 1) && !dragSelecting && !CreativeUI.inst.IsBrushActive() && !CurrPlacementMode.IsPlacing())
		{
			dragSelecting = true;
			didDrag = false;
		}
		UpdateDragSelectAndHighlighting();
		PruneDeadObjectsFromSelection();
		if (CurrPlacementMode.IsPlacing())
		{
			BuildingPlacementFromMenuSafetyDelay += Time.unscaledDeltaTime;
			if (PointingSystem.GetPointer().GetSecondaryUp() && Vector3.Distance(rightMouseDownPos, Input.mousePosition) < (float)(Cam.inst.GetPixelCamDragThreshold() - 1))
			{
				if (!DamPlannerCursorModeActive())
				{
					AbortCursorObjPlacement();
				}
				else
				{
					currCursorMode?.DoSecondaryClick();
				}
			}
			if (PointingSystem.GetPointer().GetTertiaryUp() && Vector3.Distance(middleMouseDownPos, Input.mousePosition) < (float)(Cam.inst.GetPixelCamDragThreshold() - 1))
			{
				TryRotateHeldBuilding();
			}
		}
		else if (PointingSystem.GetPointer().GetSecondaryUp() && Vector3.Distance(rightMouseDownPos, Input.mousePosition) < (float)(Cam.inst.GetPixelCamDragThreshold() - 1))
		{
			if (!PointerOverUI())
			{
				MoveUnitsToPosition(GridPointerIntersection());
			}
			if ((currCursorMode == null || !currCursorMode.DoSecondaryClick()) && !TechnologyTree.inst.IsVisible())
			{
				ClearUIForRightClick();
			}
		}
		CurrPlacementMode.Update();
		if (!CurrPlacementMode.IsPlacing() && PointingSystem.GetPointer().GetTertiaryUp() && Vector3.Distance(middleMouseDownPos, Input.mousePosition) < 2f && !WasEventConsumed() && currCursorMode == null)
		{
			TryCopyHoveredBuilding();
		}
		if (!PointingSystem.GetPointer().GetPrimaryUp())
		{
			return;
		}
		if (dragSelecting)
		{
			bool returnedToOriginal = dragEnd.x == dragStart.x && dragEnd.z == dragStart.z && didDrag;
			if (currCursorMode == null || currCursorMode == consoleCursorMode)
			{
				if (UnitControlSystem.inst.TrySelectHighlightObjects(highlightedObjs))
				{
					highlightedObjs.Clear();
					SetCursorMode(unitControlCursorMode);
				}
				else
				{
					if (!Input.GetKey(KeyCode.LeftShift) && !Input.GetKey(KeyCode.RightShift))
					{
						ClearSelection();
					}
					for (int i = 0; i < highlightedObjs.Count; i++)
					{
						AddToSelection(highlightedObjs[i]);
					}
					int num = 0;
					for (int j = 0; j < selectedObjs.Count; j++)
					{
						IMoveableUnit unit = selectedObjs[0] as IMoveableUnit;
						if (IsUnitSelectable(unit))
						{
							num++;
						}
					}
					if (num != 1)
					{
						_ = 1;
					}
					highlightedObjs.Clear();
				}
			}
			else
			{
				GetDragSelectBounds(out var minX, out var minZ, out var maxX, out var maxZ);
				currCursorMode.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
			}
		}
		else if (currCursorMode != null)
		{
			currCursorMode.HandlePrimaryUp();
		}
		if (!Cam.inst.IsDragging() && BuildingPlacementFromMenuSafetyDelay > 0.25f && CurrPlacementMode.IsPlacing())
		{
			if (leftMouseDownCaptured)
			{
				AcceptCursorObjPlacement();
			}
		}
		else if (Vector3.Distance(leftMouseDownPos, Input.mousePosition) < (float)(Cam.inst.GetPixelCamDragThreshold() - 1) && !dragSelecting)
		{
			DoPrimaryClick();
		}
		highlightedObjs.Clear();
		leftMouseDownCaptured = false;
		dragSelecting = false;
	}

	private void UpdateForController()
	{
		if (!WasEventConsumed())
		{
			if (GamepadControl.inst.player.GetButtonDown("A"))
			{
				if (currCursorMode != null && !CurrPlacementMode.IsPlacing())
				{
					currCursorMode.HandlePrimaryDown();
				}
				else if (CurrPlacementMode.isDragging)
				{
					AcceptCursorObjPlacement();
					consumedPlace = true;
				}
				else
				{
					CurrPlacementMode.TryHandlePrimaryDown();
				}
				dragStart = (dragEnd = GridPointerIntersection());
			}
			if (GamepadControl.inst.player.GetButton("A") && Vector3.Distance(dragStart, GridPointerIntersection()) > 0.1f && !dragSelecting && !CreativeUI.inst.IsBrushActive() && CurrPlacementMode.IsPlacing())
			{
				dragSelecting = true;
				didDrag = false;
			}
		}
		UpdateDragSelectAndHighlighting();
		if (CurrPlacementMode.IsPlacing())
		{
			if (GamepadControl.inst.player.GetButtonUp("B"))
			{
				AbortCursorObjPlacement();
			}
			if (GamepadControl.inst.player.GetButtonUp("Y"))
			{
				TryRotateHeldBuilding();
			}
		}
		CurrPlacementMode.Update();
		if (GamepadControl.inst.player.GetButtonUp("A") && !WasEventConsumed())
		{
			if (dragSelecting)
			{
				bool returnedToOriginal = dragEnd.x == dragStart.x && dragEnd.z == dragStart.z && didDrag;
				if (currCursorMode == null || currCursorMode == consoleCursorMode)
				{
					ClearSelection();
					for (int i = 0; i < highlightedObjs.Count; i++)
					{
						AddToSelection(highlightedObjs[i]);
					}
					int num = 0;
					for (int j = 0; j < selectedObjs.Count; j++)
					{
						IMoveableUnit unit = selectedObjs[0] as IMoveableUnit;
						if (IsUnitSelectable(unit))
						{
							num++;
						}
					}
					if (num != 1)
					{
						_ = 1;
					}
					ClearCellSelected();
				}
				else
				{
					GetDragSelectBounds(out var minX, out var minZ, out var maxX, out var maxZ);
					currCursorMode.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
				}
			}
			else if (currCursorMode != null)
			{
				currCursorMode.HandlePrimaryUp();
			}
			if (CurrPlacementMode.IsPlacing())
			{
				if (!CurrPlacementMode.isDragging && !consumedPlace)
				{
					AcceptCursorObjPlacement();
				}
			}
			else if (!dragSelecting)
			{
				DoPrimaryClick();
			}
			highlightedObjs.Clear();
			dragSelecting = false;
			consumedPlace = false;
		}
		PruneDeadObjectsFromSelection();
		if (!WasEventConsumed() && GamepadControl.inst.player.GetButtonUp("X") && ContainsUnit(selectedObjs))
		{
			MoveUnitsToPosition(GridPointerIntersection());
			if (!EditTerrainCursorModeActive())
			{
				ClearUIForRightClick();
			}
		}
		if (selectedBuilding != null && !selectedBuilding.Equals(null) && !vignetteController.IsOpaque())
		{
			vignetteController.FadeIn();
		}
		else if ((selectedBuilding == null || selectedBuilding.Equals(null)) && !vignetteController.IsTransparent())
		{
			vignetteController.FadeOut();
		}
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		float deltaTime = Time.deltaTime;
		if (firstUpdate)
		{
			firstUpdate = false;
			if (Player.inst.keep == null && Player.inst.difficulty == Player.Difficulty.Survival && !CrossGameData.inst.BeatSurvival)
			{
				survivalIntro.gameObject.SetActive(value: true);
			}
		}
		if (SeasonManager.inst.CurrentYear() == 250 && Player.inst.difficulty == Player.Difficulty.Survival && !CrossGameData.inst.BeatSurvival && !GamepadControl.inst.IsNavigatingUI())
		{
			survivalSuccess.Show();
			CrossGameData.inst.BeatSurvival = true;
			CrossGameData.inst.Save();
			BuildUI.inst.TryAddSurvivalStatue();
			BuildUI.inst.UpdateMaterials(Player.inst.PlayerLandmassOwner.bannerIdx);
		}
		if (hasUpdatedScalers)
		{
			lastCanvasWidth = MainCanvas.GetComponent<RectTransform>().sizeDelta.x;
			lastCanvasHeight = MainCanvas.GetComponent<RectTransform>().sizeDelta.y;
			lastScreenWidth = Screen.width;
			lastScreenHeight = Screen.height;
			ResolutionChanged();
			hasUpdatedScalers = false;
		}
		if (lastScreenWidth != Screen.width || lastScreenHeight != Screen.height)
		{
			UpdateCanvasScalers();
		}
		UpdateUIScaling();
		if (currCursorMode != null)
		{
			currCursorMode.Tick(deltaTime);
		}
		if (GamepadControl.inst.isControllerActive)
		{
			UpdateForController();
		}
		else
		{
			UpdateForKeyboard();
		}
		UpdateCellSelector();
		if (selectedBuilding != null && !selectedBuilding.Equals(null))
		{
			Building building = (selectedBuilding as MonoBehaviour)?.GetComponent<Building>();
			if (building != null && building.uniqueNameHash == World.waterTowerHash)
			{
				WaterConsumerTracker.inst.TrackWaterConsumers(building.GetComponent<WaterSupplier>());
			}
			else
			{
				if (building != null && building.uniqueNameHash == World.templeHash)
				{
					Temple component = building.GetComponent<Temple>();
					if (component.GetDedicateIdx() == 3 && component.bonusLevel > 0)
					{
						scratchVillagers.ClearFast();
						for (int i = 0; i < component.plagued.Count; i++)
						{
							if (component.plagued.data[i].HasEmployee())
							{
								scratchVillagers.Add(component.plagued.data[i].Employee);
							}
						}
						building.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
						apolloShrineHealingTracker.TrackVillagers(building.Center(), minX, minZ, maxX, maxZ, scratchVillagers, Color.darkOliveGreen);
					}
				}
				workerVillagerTracker.TrackVillagers(selectedBuilding);
			}
		}
		if (workerUI.Visible || constructUI.IsVisible() || MerchantUI.inst.IsVisible() || tileInfoUI.IsVisible() || UnitUI.inst.IsVisible() || ConsoleBuildMenu.inst.Active || inst.IsChariotRaceModeActive())
		{
			CreativeUI.inst.SetWindowVisibility(v: false);
		}
		else
		{
			CreativeUI.inst.SetVisibility(Creative.inst.IsEnabled());
		}
		bool active = !Cinematics.inst.IsCinematicRunning() && !GodUI.inst.Visible() && !AdvisorUI.inst.IsVisible() && !DamPlannerCursorModeActive() && !EditTerrainCursorModeActive();
		Util.SetActive(NotificationUI.inst.gameObject, active);
		ObjectHighlighter.Update();
	}

	private void LateUpdate()
	{
		currCursorMode?.LateTick();
	}

	public bool TryCopyHoveredBuilding()
	{
		ISelectableBuilding selectableBuilding = GetHighlightedBuilding();
		if (selectableBuilding == null)
		{
			RaycastHit closestRayHit = PointingSystem.GetClosestRayHit(scratchHitResults);
			if (closestRayHit.collider != null)
			{
				BuildingCollider component = closestRayHit.collider.GetComponent<BuildingCollider>();
				if (component != null && Player.inst.PlayerLandmassOwner.OwnsLandMass(component.Building.LandMass()))
				{
					selectableBuilding = component.BuildingAsBuilding;
				}
			}
		}
		if (selectableBuilding != null)
		{
			int num = selectableBuilding.UniqueNameHash();
			if (num == World.keepHash || num == World.chamberOfWarHash || num == World.romanOutpostHash || num == World.rubbleHash)
			{
				return false;
			}
			if (num == World.damHash)
			{
				DamPlannerUI.inst.SetVisible(v: true);
			}
			else if (num == World.aqueductLineHash)
			{
				SetCursorModeAqueductPlacement();
			}
			else
			{
				Building building = selectableBuilding as Building;
				if (building == null)
				{
					return false;
				}
				Building placeableByUniqueName = GameState.inst.GetPlaceableByUniqueName(building.UniqueName);
				CurrPlacementMode.SetCursorObject(placeableByUniqueName, notFirstPlacement: false);
				CurrPlacementMode.lastBuilding = placeableByUniqueName;
				CurrPlacementMode.lastBuildInfo = new BuildBuildingDataInstance(placeableByUniqueName, enabled: true);
				ClearSelection();
				ClearUIForClick();
			}
			return true;
		}
		return false;
	}

	public void MoveUnitsToPosition(Vector3 pos)
	{
		if (recalcFormationOffsets)
		{
			CalculateFormationOffsets();
		}
		Cell cellDataClamped = World.inst.GetCellDataClamped(pos);
		IMoveTarget moveTarget = cellDataClamped;
		IMoveTarget moveTarget2 = null;
		List<IMoveableUnit> list = new List<IMoveableUnit>();
		List<IMoveableUnit> list2 = new List<IMoveableUnit>();
		IMoveableUnit moveableUnit = null;
		for (int i = 0; i < highlightedObjs.Count; i++)
		{
			if (highlightedObjs[i] is IMoveTarget)
			{
				if (!selectedObjs.Contains(highlightedObjs[i]) && highlightedObjs[i].TeamID() != 0)
				{
					moveTarget2 = highlightedObjs[i] as IMoveTarget;
				}
				if (highlightedObjs[i] is IMoveableUnit moveableUnit2 && moveableUnit2.CanCarry())
				{
					moveTarget2 = moveableUnit2 as IMoveTarget;
					moveableUnit = moveableUnit2;
				}
			}
		}
		if (moveTarget2 == null && highlightBuilding != null && highlightBuilding is Building building)
		{
			Cell cell = building.GetCell();
			for (int num = cell.OccupyingStructure.Count - 1; num >= 0; num--)
			{
				_ = cell.OccupyingStructure[num];
				if (cell.OccupyingStructure[num].categoryHash != World.pathHash && cell.OccupyingStructure[num].uniqueNameHash != World.rubbleHash)
				{
					moveTarget2 = cell.OccupyingStructure[num];
					break;
				}
			}
		}
		for (int j = 0; j < selectedObjs.Count; j++)
		{
			if (selectedObjs[j].TeamID() != 0 && !Creative.inst.IsCreativeOptionOn(10))
			{
				continue;
			}
			IMoveableUnit unitFromSelectable = GetUnitFromSelectable(selectedObjs[j]);
			if (unitFromSelectable != null)
			{
				if ((moveableUnit != null && !unitFromSelectable.CanBeCarried()) || moveTarget2 == null)
				{
					list2.Add(unitFromSelectable);
				}
				else
				{
					list.Add(unitFromSelectable);
				}
			}
		}
		if (list2.Count > 0)
		{
			Vector3 zero = Vector3.zero;
			for (int k = 0; k < list2.Count; k++)
			{
				zero += list2[k].GetPos();
			}
			zero /= (float)list2.Count;
			Vector3 vector = SnapTo(moveTarget.GetPos() - zero, 90f);
			DebugEx.DrawArrow(zero, zero + vector, Color.red, 1f);
			Quaternion quaternion = Quaternion.LookRotation(vector);
			for (int l = 0; l < formationOffsetsInUse.Length; l++)
			{
				if (formationOffsetsInUse[l] == null)
				{
					formationOffsetsInUse[l] = new List<bool>();
				}
				formationOffsetsInUse[l].Clear();
				for (int m = 0; m < formationOffsets[l].Count; m++)
				{
					formationOffsetsInUse[l].Add(item: false);
				}
			}
			for (int n = 0; n < list2.Count; n++)
			{
				int num2 = list2[n].FormationIdx();
				IMoveableUnit moveableUnit3 = list2[n];
				Vector3 vector2 = moveableUnit3.GetPos() - zero;
				Vector3 a = cellDataClamped.Center2D + vector2;
				float num3 = float.MaxValue;
				int index = -1;
				for (int num4 = 0; num4 < formationOffsets[num2].Count; num4++)
				{
					if (!formationOffsetsInUse[num2][num4])
					{
						Cell cellDataClamped2 = World.inst.GetCellDataClamped(pos + quaternion * formationOffsets[num2][num4]);
						float num5 = Mathff.DistSqrdXZ(a, cellDataClamped2.Center2D);
						if (num5 < num3)
						{
							num3 = num5;
							index = num4;
						}
					}
				}
				formationOffsetsInUse[num2][index] = true;
				Cell cellDataClamped3 = World.inst.GetCellDataClamped(pos + quaternion * formationOffsets[num2][index]);
				OrdersManager.inst.MoveTo(moveableUnit3, cellDataClamped3);
				ArmySystem.inst.PlayMoveSoundEffect(moveableUnit3);
				if (moveableUnit3 is ArmySystem.Army army)
				{
					army.isAutoTargeting = false;
					army.playerSetMoveTarget = cellDataClamped3;
				}
			}
		}
		for (int num6 = 0; num6 < list.Count; num6++)
		{
			ArmySystem.Army army2 = list[num6] as ArmySystem.Army;
			if (army2 != null && army2.armyType == ArmySystem.ArmyType.Envoy)
			{
				army2.general.GetComponent<Envoy>().rightClickNeedsConsumed = true;
			}
			OrdersManager.inst.MoveTo(list[num6], moveTarget2);
			ArmySystem.inst.PlayMoveSoundEffect(list[num6]);
			if (army2 != null)
			{
				army2.isAutoTargeting = false;
				if (moveTarget2 is Building)
				{
					army2.playerSetMoveTarget = moveTarget2;
				}
			}
		}
		if (MiniMapUI.inst != null && MiniMapUI.inst.gameObject.activeSelf)
		{
			MiniMapUI.inst.DrawRoutes();
		}
	}

	public IMoveableUnit GetUnitFromSelectable(ISelectable s)
	{
		IMoveableUnit moveableUnit = s as IMoveableUnit;
		if (moveableUnit == null)
		{
			MonoBehaviour monoBehaviour = s as MonoBehaviour;
			if ((bool)monoBehaviour)
			{
				moveableUnit = monoBehaviour.GetComponent<IMoveableUnit>();
			}
		}
		return moveableUnit;
	}

	private bool ContainsUnit(List<ISelectable> selectables)
	{
		for (int i = 0; i < selectables.Count; i++)
		{
			if (selectables[i] is IMoveableUnit)
			{
				return true;
			}
		}
		return false;
	}

	public bool IsUnitSelected()
	{
		return ContainsUnit(selectedObjs);
	}

	public void GetSelectedUnits(ref ArrayExt<IMoveableUnit> units)
	{
		for (int i = 0; i < selectedObjs.Count; i++)
		{
			if (selectedObjs[i].TeamID() == 0 || Creative.inst.IsCreativeOptionOn(10))
			{
				IMoveableUnit unitFromSelectable = GetUnitFromSelectable(selectedObjs[i]);
				if (unitFromSelectable != null)
				{
					units.Add(unitFromSelectable);
				}
			}
		}
	}

	public void GetDragSelectBounds(out int minX, out int minZ, out int maxX, out int maxZ)
	{
		minX = (int)Mathff.Min(dragEnd.x, dragStart.x);
		minZ = (int)Mathff.Min(dragEnd.z, dragStart.z);
		maxX = (int)Mathff.Max(dragEnd.x, dragStart.x);
		maxZ = (int)Mathff.Max(dragEnd.z, dragStart.z);
		maxX++;
		maxZ++;
		minX = Mathff.Clamp(minX, 0, World.inst.GridWidth - 1);
		maxX = Mathff.Clamp(maxX, 0, World.inst.GridWidth - 1);
		minZ = Mathff.Clamp(minZ, 0, World.inst.GridHeight - 1);
		maxZ = Mathff.Clamp(maxZ, 0, World.inst.GridHeight - 1);
	}

	private Vector3 SnapTo(Vector3 v3, float snapAngle)
	{
		float num = Vector3.Angle(v3, Vector3.forward);
		if (Vector3.Dot(v3, Vector3.right) < 0f)
		{
			num *= -1f;
		}
		num = Mathf.Round(num / snapAngle) * snapAngle;
		return Quaternion.AngleAxis(num, Vector3.up) * Vector3.forward;
	}

	private void CalculateFormationOffsets()
	{
		int num = 0;
		for (int i = 0; i < formationOffsets.Length; i++)
		{
			if (formationOffsets[i] == null)
			{
				formationOffsets[i] = new List<Vector3>();
			}
			scratchList.Clear();
			for (int j = 0; j < selectedObjs.Count; j++)
			{
				IMoveableUnit unitFromSelectable = GetUnitFromSelectable(selectedObjs[j]);
				if (unitFromSelectable != null && unitFromSelectable.FormationIdx() == i)
				{
					scratchList.Add(unitFromSelectable);
				}
			}
			int count = scratchList.Count;
			int num2 = scratchList.Count;
			if (count == 8)
			{
				num2 = 4;
			}
			if (count >= 9)
			{
				num2 = 5;
			}
			if (count >= 11)
			{
				num2 = 6;
			}
			int num3 = 0;
			if (num2 > 0)
			{
				num3 = Mathf.CeilToInt((float)count / (float)num2);
			}
			formationOffsets[i].Clear();
			for (int k = 0; k < num3; k++)
			{
				for (int l = 0; l < num2; l++)
				{
					Vector3 item = new Vector3(-num2 / 2 + l, 0f, -num3 / 2 + k + num);
					formationOffsets[i].Add(item);
				}
			}
			num -= num3;
			scratchList.Clear();
		}
	}

	private void CheckForNoBuilders(int lm)
	{
		if (lm != -1 && JobSystem.jobCategoriesMap.TryGetValue(1, out var value) && value.jobsFilled[lm] == 0 && value.jobsAvailable[lm] > 0)
		{
			NotificationUI.TryLog(-1, "nobuilders", ScriptLocalization.nobuilders, NotificationStatus.Warning, 10f, null, title: false, lm);
		}
	}

	public void TryRotateHeldBuilding(bool left = true)
	{
		if (!CurrPlacementMode.IsPlacing() || CurrPlacementMode.isDragging)
		{
			return;
		}
		Building currB = CurrPlacementMode.GetHoverBuilding();
		if (currB != null && CanRotate(currB))
		{
			currB.ForEachTileInBounds((int x, int z, Cell cell) =>
			{
				CurrPlacementMode.buildingMap[cell.index] = null;
			});
			PlacementMode.BuildingPRS prevPath = new PlacementMode.BuildingPRS
			{
				pos = currB.transform.position,
				size = currB.size,
				rot = currB.transform.GetChild(0).rotation
			};
			int num = (left ? 90 : (-90));
			RotateBuilding(currB, num);
			CurrPlacementMode.DidRotate();
			currB.ForEachTileInBounds((int x, int z, Cell cell) =>
			{
				CurrPlacementMode.buildingMap[cell.index] = currB;
			});
			CurrPlacementMode.UpdateNeighborRotations(prevPath);
		}
	}

	public void UpdateVisibilityForSelectedCellUI()
	{
		UpdateVisibilityForBuildingUI();
	}

	public void UpdateVisibilityForBuildingUI()
	{
		ISelectableBuilding genericBuildingSelected = GetGenericBuildingSelected();
		if (genericBuildingSelected == null)
		{
			return;
		}
		if (genericBuildingSelected is Building { isDemolishing: not false })
		{
			workerUI.SetVisible(v: false);
			constructUI.SetVisibility(v: false);
			CreativeUI.inst.SetVisibility(Creative.inst.IsEnabled());
			return;
		}
		bool flag = genericBuildingSelected != null && World.IsAILandmass(genericBuildingSelected.LandMass());
		bool flag2 = personUI.villager != null;
		bool flag3 = !CurrPlacementMode.IsPlacing() && !flag2;
		bool flag4 = ((genericBuildingSelected?.UnderConstruction() ?? false) & flag3) && !flag;
		bool flag5 = (!flag4 && genericBuildingSelected != null) & flag3;
		workerUI.SetVisible(flag5);
		constructUI.SetVisibility(flag4);
		if (!flag & flag5)
		{
			workerUI.TryShow();
		}
		if (flag5 | flag4)
		{
			CreativeUI.inst.SetWindowVisibility(v: false);
		}
		else
		{
			CreativeUI.inst.SetVisibility(Creative.inst.IsEnabled());
		}
	}

	public bool UIShowing()
	{
		if (!workerUI.gameObject.activeSelf && !constructUI.IsVisible() && !tileInfoUI.IsVisible())
		{
			return MerchantUI.inst.IsVisible();
		}
		return true;
	}

	public ISelectableBuilding GetHighlightedBuilding()
	{
		return highlightBuilding;
	}

	private void UpdateCellSelector()
	{
		CellHighlighter.ResetHighlightColor();
		terrainFeatureHighlight.Reset();
		if (Cinematics.inst.IsCinematicRunning() || CurrPlacementMode.IsPlacing() || GodUI.inst.gameObject.activeSelf || GladiatorTrainingModal.inst.IsVisible() || GladiatorRecruitModal.inst.IsVisible())
		{
			return;
		}
		if (TechnologyTree.inst.IsVisible() || EditTerrainCursorModeActive() || CurrPlacementMode.IsPlacing())
		{
			CellSelector.SetVisibility(v: false);
		}
		else
		{
			if (PointerOverUI() && BuildUI.inst.IsGroupActive())
			{
				return;
			}
			bool visibility = false;
			if (GetBuildingSelected() != null)
			{
				Building buildingSelected = GetBuildingSelected();
				buildingSelected.SetOutlineImmediate(1);
				if (buildingSelected.highlightType != Building.HighlightType.None && currCursorMode == null)
				{
					if (buildingSelected.highlightType == Building.HighlightType.Category)
					{
						buildingListCat.ClearFast();
						Player.inst.GetBuildingListsByCategoryForLandMass(buildingSelected.LandMass(), buildingSelected.categoryHash, ref buildingListCat);
						for (int i = 0; i < buildingListCat.Count; i++)
						{
							ArrayExt<Building> arrayExt = buildingListCat.data[i];
							for (int j = 0; j < arrayExt.Count; j++)
							{
								if (!(buildingSelected == arrayExt.data[j]))
								{
									arrayExt.data[j].SetOutlineImmediate(0);
								}
							}
						}
					}
					else
					{
						ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(buildingSelected.LandMass(), buildingSelected.uniqueNameHash);
						for (int k = 0; k < buildingListForLandMass.Count; k++)
						{
							if (!(buildingSelected == buildingListForLandMass.data[k]))
							{
								buildingListForLandMass.data[k].SetOutlineImmediate(0);
							}
						}
					}
				}
			}
			else if (GetGenericBuildingSelected() != null)
			{
				GetGenericBuildingSelected().SetOutlineImmediate(1);
			}
			else if (GetCellSelected() != null)
			{
				Cell cellSelected = GetCellSelected();
				if (TerrainResource.GetTracker(cellSelected.x, cellSelected.z) == null)
				{
					CellSelector.SetTargetWorldBounds(cellSelected.X, cellSelected.X + 1, cellSelected.Z, cellSelected.Z + 1);
					visibility = true;
				}
			}
			if (currCursorMode != null && !currCursorMode.ShowCellHighlighter())
			{
				visibility = false;
			}
			CellSelector.SetVisibility(visibility);
			for (int l = 0; l < selectedObjs.Count; l++)
			{
				selectedObjs[l].SetHighlightImmediate(1);
			}
			highlightBuilding = null;
			float num = float.MaxValue;
			TerrainResource terrainResource = null;
			Ray ray = PointingSystem.GetRay();
			float num2 = float.MaxValue;
			int num3 = Physics.RaycastNonAlloc(ray, scratchHitResults, 100f);
			int num4 = -1;
			for (int m = 0; m < num3; m++)
			{
				float num5 = scratchHitResults[m].distance;
				Building componentInParent = scratchHitResults[m].collider.GetComponentInParent<Building>();
				if (componentInParent != null && !string.IsNullOrEmpty(componentInParent.snapBuildingTarget))
				{
					num5--;
				}
				if (num5 < num2)
				{
					num2 = num5;
					num4 = m;
					terrainResource = ((dragSelecting || !scratchHitResults[m].transform.CompareTag("TerrainResource")) ? null : scratchHitResults[m].transform.parent.GetComponent<TerrainResource>());
				}
			}
			RaycastHit raycastHit = default;
			if (num4 != -1)
			{
				raycastHit = scratchHitResults[num4];
				num = scratchHitResults[num4].distance;
			}
			Cell cell = null;
			BuildingCollider buildingCollider = null;
			if (raycastHit.collider != null)
			{
				buildingCollider = raycastHit.collider.GetComponent<BuildingCollider>();
				if (buildingCollider != null && buildingCollider.Building != null)
				{
					_ = buildingCollider.BuildingAsBuilding;
					highlightBuilding = buildingCollider.Building;
				}
			}
			if (AqueductCursorModeActive())
			{
				CellSelector.SetVisibility(v: false);
				return;
			}
			if (highlightBuilding is Building building && building != null && building.CategoryHash() == World.editTerrainZoneHash)
			{
				int num6 = building.cachedCell.OccupyingStructure.FindLastIndex((Building b) => b.categoryHash != World.editTerrainZoneHash);
				if (num6 != -1)
				{
					highlightBuilding = building.cachedCell.OccupyingStructure[num6];
				}
				else
				{
					highlightBuilding = building.GetComponent<EditTerrainProjectReference>().project;
				}
			}
			if (buildingCollider == null)
			{
				cell = World.inst.GetCellData(inst.GridPointerIntersection());
				if (Vector3.Dot(Vector3.down, ray.direction.normalized) > 0f && cell != null)
				{
					if (cell.OccupyingStructure.Count > 0 && cell.OccupyingStructure[0].IsVisibleForFog())
					{
						Building building2 = cell.OccupyingStructure[0];
						if (building2.categoryHash == World.editTerrainZoneHash)
						{
							EditTerrainProjectReference component = building2.GetComponent<EditTerrainProjectReference>();
							if (component != null)
							{
								highlightBuilding = component.project;
							}
						}
						else
						{
							highlightBuilding = building2;
						}
					}
					else if (cell.SubStructure.Count > 0 && cell.TopSubStructure.IsVisibleForFog())
					{
						highlightBuilding = cell.TopSubStructure;
					}
				}
			}
			float hitDist = float.MaxValue;
			if (!IsUnitSelected() && (currCursorMode == null || currCursorMode == consoleCursorMode))
			{
				overPerson = WillSelectPerson(out hitDist);
			}
			VillagerSystem.inst.outline.Disable();
			bool flag = GetBuildingSelected() != null && GetBuildingSelected() == highlightBuilding;
			if (GetCellSelected() != null)
			{
				_ = cell == GetCellSelected();
			}
			else
				_ = 0;
			if (hitDist < num)
			{
				highlightBuilding = null;
			}
			else if (!flag)
			{
				overPerson = null;
			}
			for (int num7 = 0; num7 < highlightedObjs.Count; num7++)
			{
				if (!selectedObjs.Contains(highlightedObjs[num7]))
				{
					int num8 = highlightedObjs[num7].TeamID();
					if (num8 <= 0 || World.inst.RelationBetween(num8, 0) != World.Relations.Enemy)
					{
						highlightedObjs[num7].SetHighlightImmediate(0);
					}
					else
					{
						highlightedObjs[num7].SetHighlightImmediate(2);
					}
				}
			}
			if (currCursorMode == null || currCursorMode == consoleCursorMode)
			{
				bool flag2 = false;
				bool flag3 = false;
				int num9 = -1;
				int num10 = -1;
				for (int num11 = 0; num11 < selectedObjs.Count; num11++)
				{
					IMoveableUnit unitFromSelectable = GetUnitFromSelectable(selectedObjs[num11]);
					if (unitFromSelectable != null)
					{
						if (unitFromSelectable.CanBeCarried())
						{
							num9 = unitFromSelectable.TeamID();
							flag2 = true;
						}
						if (unitFromSelectable.CanCarry() && unitFromSelectable.CarryCount() > 0)
						{
							flag3 = true;
							num10 = unitFromSelectable.TeamID();
						}
					}
				}
				bool flag4 = true;
				if (flag2 && highlightedObjs.Count == 1)
				{
					if (highlightedObjs[0] is IMoveableUnit moveableUnit && moveableUnit.CanCarry() && num9 == moveableUnit.TeamID())
					{
						CellHighlighter.SetBrush("brush_load");
						flag4 = false;
					}
				}
				else if (flag3 && num10 == 0 && cell != null && !cell.deepWater)
				{
					CellHighlighter.SetBrush("brush_unload");
					flag4 = false;
				}
				if (flag4)
				{
					CellHighlighter.ResetBrushes();
				}
			}
			if (!dragSelecting)
			{
				bool flag5 = false;
				if (InWorldExclamation.hovered != null)
				{
					InWorldExclamation.hovered.highlighter.SetOutlineImmediate(0);
				}
				else if (overPerson != null)
				{
					cakeslice.Outline outline = VillagerSystem.inst.outline;
					outline.mesh = (overPerson.useLadyMesh ? VillagerSystem.inst.ladyVillagerMeshs[(int)overPerson.MeshType] : VillagerSystem.inst.villagerMeshs[(int)overPerson.MeshType]);
					outline.meshMtx = Matrix4x4.TRS(overPerson.GetPosWithOffset(), overPerson.Rot, Vector3.one);
					outline.Enable();
				}
				else if (highlightBuilding != null && !dragSelecting && highlightedObjs.Count == 0)
				{
					if ((!highlightBuilding.Equals(GetBuildingSelected()) || highlightBuilding != GetGenericBuildingSelected()) && (currCursorMode == null || currCursorMode == consoleCursorMode || currCursorMode.ShowBuildingHighlight(highlightBuilding)))
					{
						highlightBuilding.SetOutlineImmediate(0);
					}
				}
				else if (cell != null)
				{
					if (currCursorMode != null)
					{
						flag5 = currCursorMode.ShowCellHighlighter();
					}
					CellHighlighter.SetTargetWorldBounds(cell.Center3D, Vector3.one);
					if (flag5)
					{
						terrainFeatureHighlight.UpdateHoveredCell(cell, GetCellSelected());
					}
				}
				CellHighlighter.SetVisibility(flag5);
			}
			else if (currCursorMode == null || currCursorMode == consoleCursorMode || currCursorMode.ShowDragSelectBounds())
			{
				Vector3 vector = World.inst.SnapToGrid2D(dragStart);
				Vector3 vector2 = World.inst.SnapToGrid2D(dragEnd);
				Vector3 center = (vector + vector2) * 0.5f;
				Vector3 vector3 = vector2 - vector;
				Vector3 newSize = new Vector3(Mathf.Abs(vector3.x) + 1f, Mathff.Max(1f, Mathf.Abs(vector3.y)), Mathf.Abs(vector3.z) + 1f);
				center.x += 0.5f;
				center.z += 0.5f;
				CellHighlighter.SetTargetWorldBounds(center, newSize);
				CellHighlighter.SetVisibility(v: true);
				if (currCursorMode == demolishCursorMode)
				{
					CellHighlighter.SetHighlightColor(new Color(1f, 0f, 0f, 0.25f));
				}
				else if (currCursorMode == rebuildCursorMode)
				{
					CellHighlighter.SetHighlightColor(new Color(0.5f, 0.5f, 0f, 0.5f));
				}
				else if (currCursorMode == chopCursorMode || currCursorMode == chopCancelCursorMode)
				{
					GetDragSelectBounds(out var minX, out var minZ, out var maxX, out var maxZ);
					terrainFeatureHighlight.AddCells(minX, maxX, minZ, maxZ);
				}
			}
			else
			{
				CellHighlighter.SetVisibility(v: false);
			}
			if (highlightBuilding == null)
			{
				Cell cellSelected2 = GetCellSelected();
				if (cellSelected2?.terrainResource != null)
				{
					_ = cellSelected2?.terrainResource == cell?.terrainResource;
				}
				else
					_ = 0;
				TerrainResource terrainResource2 = null;
				if (prevHighlightedCell != null && prevHighlightedCell != cellSelected2)
				{
					terrainResource2 = TerrainResource.GetTracker(prevHighlightedCell.x, prevHighlightedCell.z);
					if (terrainResource2 != null && (dragSelecting || ((cellSelected2 == null || !(cellSelected2.terrainResource == terrainResource2)) && (!(terrainResource != null) || !(terrainResource == terrainResource2)))))
					{
						terrainResource2.outline.color = 1;
						terrainResource2.outline.Disable();
						terrainResource2.SetTooltipVisibility(isVisible: false);
					}
				}
				prevHighlightedCell = cell;
				if (terrainResource != prevRayTerrainResource)
				{
					if (prevRayTerrainResource != null && prevRayTerrainResource != terrainResource2)
					{
						prevRayTerrainResource.outline.color = 1;
						prevRayTerrainResource.outline.Disable();
						prevRayTerrainResource.SetTooltipVisibility(isVisible: false);
					}
					if (terrainResource != null)
					{
						terrainResource.outline.color = 0;
						terrainResource.outline.Enable();
						terrainResource.outline.clipOnTerrain = true;
						terrainResource.SetTooltipVisibility(isVisible: true);
					}
				}
				if (terrainResource != null)
				{
					CellHighlighter.SetVisibility(v: false);
				}
				prevRayTerrainResource = terrainResource;
			}
			else if (prevRayTerrainResource != null)
			{
				prevRayTerrainResource.outline.color = 1;
				prevRayTerrainResource.outline.Disable();
				prevRayTerrainResource.SetTooltipVisibility(isVisible: false);
				prevRayTerrainResource = null;
			}
		}
	}

	public void OnDownBuildTabButton()
	{
		RuntimeManager.PlayOneShot(soundOnClickBuildUIButton);
	}

	public void OnBuild(Building building, bool notFirstPlacement = false)
	{
		CurrPlacementMode.lastBuilding = building;
		if (!(building == null))
		{
			CurrPlacementMode.SetCursorObject(building, notFirstPlacement);
			dragConfirm = false;
			if (GamepadControl.inst.isControllerActive)
			{
				Cam.inst.posSmoothDampTime = 0.075f;
				ConsoleTileUI.inst.UpdateBuildPlacementModeVisuals();
			}
			if (!notFirstPlacement)
			{
				BuildingPlacementFromMenuSafetyDelay = 0f;
			}
			BuildInfoFloating.inst.SetVisibility(v: false);
		}
	}

	public void DockWorkerUI()
	{
		RectTransform component = workerUI.GetComponent<RectTransform>();
		Vector2 vector = (component.pivot = new Vector2(1f, 0f));
		Vector2 anchorMin = (component.anchorMax = vector);
		component.anchorMin = anchorMin;
		component.anchoredPosition = new Vector3(0f, 0f, 0f);
	}

	public void UndockWorkerUI()
	{
		RectTransform component = workerUI.GetComponent<RectTransform>();
		Vector2 anchorMin = (component.anchorMax = new Vector2(0.5f, 0.5f));
		component.anchorMin = anchorMin;
		component.pivot = new Vector2(0f, 0.5f);
		component.anchoredPosition = new Vector3(150f, 0f, 0f);
	}

	public void DockConstructionUI()
	{
		RectTransform root = constructUI.root;
		Vector2 vector = (root.pivot = new Vector2(1f, 0f));
		Vector2 anchorMin = (root.anchorMax = vector);
		root.anchorMin = anchorMin;
		root.anchoredPosition = new Vector3(0f, 0f, 0f);
	}

	public void UndockConstructionUI()
	{
		RectTransform root = constructUI.root;
		Vector2 anchorMin = (root.anchorMax = new Vector2(0.5f, 0.5f));
		root.anchorMin = anchorMin;
		root.pivot = new Vector2(0f, 0.5f);
		root.anchoredPosition = new Vector3(150f, 0f, 0f);
	}

	internal bool InModal()
	{
		if (EditTerrainCursorModeActive() || GladiatorTrainingModal.inst.IsVisible() || GladiatorRecruitModal.inst.IsVisible() || DamPlannerCursorModeActive() || IsChariotRaceModeActive() || PhotoMode.IsActive() || IsColosseumFightModeActive())
		{
			return true;
		}
		return false;
	}
}
