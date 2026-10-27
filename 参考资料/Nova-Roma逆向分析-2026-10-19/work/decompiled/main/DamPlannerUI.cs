using System.Collections.Generic;
using Assets.Code;
using Assets.Code.UI;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class DamPlannerUI : UIWindowBase
{
	public static DamPlannerUI inst;

	public DamPlanningCursorMode cursorMode;

	[SerializeField]
	private Toggle[] ToolToggles;

	[SerializeField]
	private Button StartProject_Button;

	[SerializeField]
	private Localize StartProject_Localize;

	[SerializeField]
	private Button Exit_Button;

	[SerializeField]
	private GameObject BuildingDamageWarning;

	[SerializeField]
	private Button BuildingDamageView_Button;

	[SerializeField]
	private TextMeshProUGUI CostLabel;

	[SerializeField]
	private GameObject CostContainer;

	[SerializeField]
	private TextMeshProUGUI CostAmount;

	[SerializeField]
	private TextMeshProUGUI HaveAmount;

	[SerializeField]
	private GameObject CostError;

	[SerializeField]
	private Button CancelButton;

	[SerializeField]
	private GameObject IntroPopup;

	[SerializeField]
	private Slider WaterSimTimeUserSlider;

	[SerializeField]
	private Slider WaterSimTimeVisualSlider;

	[SerializeField]
	private float WaterSimMaxTime = 10f;

	[SerializeField]
	private float WaterSimMinTime = 2f;

	[SerializeField]
	private float WaterSimStartTime = 5f;

	public Confirmation closeConfirmation;

	[SerializeField]
	public SpillwayUI spillwayUIPrefab;

	[SerializeField]
	private float spillwayUIMaxDistance = 30f;

	private List<SpillwayUI> spawnedSpillwayUIs = new List<SpillwayUI>();

	private Dictionary<int, float> plannedSpillwayHeights = new Dictionary<int, float>();

	private Dictionary<SpillwayUI, CanvasGroup> spillwayUICanvasGroups = new Dictionary<SpillwayUI, CanvasGroup>();

	private int pinnedSpillwayCellIndex = -1;

	private Canvas _cachedCanvas;

	private RectTransform _cachedCanvasRect;

	private bool isMouseOverSpillwayUI;

	private int previousToolStateBeforeHover = -1;

	private int lastTool;

	private Timer waterResetTimer = new Timer(5f);

	private int lastStone = -1;

	private int lastWood = -1;

	private DynamicWater.DynamicWaterSaveData waterState;

	private float[] savedWaterObstructionField;

	private Dictionary<int, SpillwayResetData> spillwayResetData = new Dictionary<int, SpillwayResetData>();

	private ArrayExt<Renderer> normal = new ArrayExt<Renderer>(1000);

	private ArrayExt<Renderer> highlight = new ArrayExt<Renderer>(1000);

	public void Awake()
	{
		inst = this;
		TryInitCursorMode();
		StartProject_Button.onClick.AddListener(OnStartProject);
		Exit_Button.onClick.AddListener(OnClickedClose);
		CancelButton.onClick.AddListener(OnClickedClose);
		WaterSimTimeUserSlider.minValue = 0f;
		WaterSimTimeUserSlider.maxValue = WaterSimMaxTime;
		WaterSimTimeVisualSlider.minValue = 0f;
		WaterSimTimeVisualSlider.maxValue = WaterSimMaxTime;
		WaterSimTimeUserSlider.onValueChanged.AddListener(OnWaterSimTimeUserSliderChanged);
		WaterSimTimeUserSlider.SetValueWithoutNotify(WaterSimStartTime);
		for (int i = 0; i < ToolToggles.Length; i++)
		{
			int p = i;
			ToolToggles[i].onValueChanged.AddListener((bool isOn) =>
			{
				OnToolToggleChanged(isOn, p);
			});
		}
		gameObject.SetActive(value: false);
	}

	public void CloseIntro()
	{
		IntroPopup.gameObject.SetActive(value: false);
		Player.inst.seenDamPlannerIntro = true;
	}

	public void ShowIntro()
	{
		IntroPopup.gameObject.SetActive(value: true);
	}

	private void OnWaterSimTimeUserSliderChanged(float t)
	{
		if (t < WaterSimMinTime)
		{
			t = WaterSimMinTime;
		}
		WaterSimTimeUserSlider.onValueChanged.RemoveListener(OnWaterSimTimeUserSliderChanged);
		WaterSimTimeUserSlider.value = t;
		WaterSimTimeUserSlider.onValueChanged.AddListener(OnWaterSimTimeUserSliderChanged);
	}

	private void OnToolToggleChanged(bool isOn, int id)
	{
		if (isOn)
		{
			cursorMode.SetTool(id);
			SfxSystem.PlayUiSelect();
		}
	}

	public void SelectTool(int toolIndex)
	{
		if (toolIndex >= 0 && toolIndex < ToolToggles.Length)
		{
			ToolToggles[toolIndex].isOn = true;
		}
	}

	private bool HasAnyChanges()
	{
		if (cursorMode.buildingsToAdd.Count > 0 || cursorMode.buildingsToRemove.Count > 0)
		{
			return true;
		}
		foreach (KeyValuePair<int, float> plannedSpillwayHeight in plannedSpillwayHeights)
		{
			if (spillwayResetData.TryGetValue(plannedSpillwayHeight.Key, out var value) && !Mathf.Approximately(plannedSpillwayHeight.Value, value.desired))
			{
				return true;
			}
		}
		return false;
	}

	private void OnStartProject()
	{
		Dictionary<int, CellTerrainData> dictionary = new Dictionary<int, CellTerrainData>();
		foreach (KeyValuePair<int, CellTerrainData> item in cursorMode.cellTerrainDataMap)
		{
			dictionary[item.Key] = item.Value;
		}
		cursorMode.ComputeTerrainModifications(out var vertexIndices, out var originalHeights, out var newHeights);
		cursorMode.ClearAllTerrainPreview();
		cursorMode.RevertAllPreviewRepairs(revert: false);
		UndoChanges();
		DamPlanningProject damPlanningProject = DamPlanningProject.CreateNewProject();
		List<BuildingDescriptionDamPlanning> list = new List<BuildingDescriptionDamPlanning>();
		list.AddRange(cursorMode.buildingsToAdd);
		List<BuildingDescriptionDamPlanning> list2 = new List<BuildingDescriptionDamPlanning>();
		list2.AddRange(cursorMode.buildingsToRemove);
		Dictionary<int, float> dictionary2 = new Dictionary<int, float>(plannedSpillwayHeights);
		Dictionary<int, SpillwayResetData> dictionary3 = new Dictionary<int, SpillwayResetData>(spillwayResetData);
		damPlanningProject.Init(list2, list, dictionary3, dictionary2);
		int[] array = new int[damPlanningProject.scaffoldColumns.Count];
		Vector3[][] array2 = new Vector3[damPlanningProject.scaffoldColumns.Count][];
		for (int i = 0; i < damPlanningProject.scaffoldColumns.Count; i++)
		{
			Vector3 worldPos = damPlanningProject.scaffoldColumns[i];
			Cell cellData = World.inst.GetCellData(worldPos);
			List<Vector3> list3 = new List<Vector3>();
			BlockBuilding blockBuilding = null;
			for (int num = cellData.OccupyingStructure.Count - 1; num >= 0; num--)
			{
				BlockBuilding component = cellData.OccupyingStructure[num].GetComponent<BlockBuilding>();
				if (component != null)
				{
					blockBuilding = component;
					break;
				}
			}
			if (blockBuilding != null)
			{
				Transform[] waterObstructionActive = blockBuilding.WaterObstructionActive;
				for (int j = 0; j < waterObstructionActive.Length; j++)
				{
					list3.Add(waterObstructionActive[j].position);
				}
			}
			Building building = cellData.StructureFind<Spillover>();
			if (building != null)
			{
				Spillover component2 = building.GetComponent<Spillover>();
				int meshIndexForDoor = component2.meshIndexForDoor;
				Vector3 vector = new Vector3((float)(meshIndexForDoor % World.MeshWidth) * 0.5f, component2.obstructionHeight + TerrainGen.inst.heightCache[meshIndexForDoor], (float)(meshIndexForDoor / World.MeshWidth) * 0.5f);
				bool flag = false;
				for (int k = 0; k < list3.Count; k++)
				{
					if (Mathf.Approximately(list3[k].x, vector.x) && Mathf.Approximately(list3[k].z, vector.z))
					{
						list3[k] = vector;
						flag = true;
						break;
					}
				}
				if (!flag)
				{
					list3.Add(vector);
				}
			}
			array[i] = cellData.index;
			array2[i] = list3.ToArray();
		}
		damPlanningProject.SetCaches(array, array2);
		damPlanningProject.SetDeferredTerrainData(vertexIndices, originalHeights, newHeights, dictionary);
		World.inst.skipGrassClearing = false;
		for (int l = 0; l < cursorMode.buildingsToAdd.Count; l++)
		{
			Building building2 = Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(cursorMode.buildingsToAdd[l].uniqueName), Player.inst.buildingContainer.transform);
			building2.gameObject.SetActive(value: true);
			building2.transform.position = cursorMode.buildingsToAdd[l].position - new Vector3(0.5f, 0f, 0.5f);
			building2.Init();
			World.inst.PlaceByAI(building2);
			Spillover component3 = building2.GetComponent<Spillover>();
			if (component3 != null)
			{
				Cell cell = building2.GetCell();
				if (cell != null && plannedSpillwayHeights.TryGetValue(cell.index, out var _))
				{
					component3.spillwayOpenPercentDesired = 1f;
					component3.spillwayOpenPercentCurrent = 1f;
				}
				component3.UpdateVisual(ignoreValidation: true);
				component3.UpdateSpillwayDoor();
				BlockStackUpdateSystem.inst.MarkWaterDirty(cell);
			}
		}
		BlockStackUpdateSystem.inst.SuppressColliderUpdates = false;
		BlockStackUpdateSystem.inst.ClearColliderUpdates();
		BlockStackUpdateSystem.inst.FlushBlockStackUpdates();
		foreach (KeyValuePair<int, SpillwayResetData> spillwayResetDatum in spillwayResetData)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(spillwayResetDatum.Key);
			if (cellDataUnsafe == null)
			{
				continue;
			}
			Building building3 = cellDataUnsafe.StructureFind<Spillover>();
			if (building3 == null)
			{
				continue;
			}
			Spillover component4 = building3.GetComponent<Spillover>();
			component4.UpdateVisual(ignoreValidation: true);
			float num2 = TerrainGen.inst.heightCache[component4.meshIndexForDoor];
			float num3 = num2;
			foreach (Building item2 in cellDataUnsafe.OccupyingStructure)
			{
				if (item2.uniqueNameHash == World.damHash)
				{
					float blockBuildingTopHeight = GetBlockBuildingTopHeight(item2.GetComponent<BlockBuilding>());
					if (blockBuildingTopHeight > num3)
					{
						num3 = blockBuildingTopHeight;
					}
				}
			}
			float value2 = Mathf.InverseLerp(num2, num3, spillwayResetDatum.Value.originalWorldHeight);
			component4.spillwayOpenPercentDesired = (component4.spillwayOpenPercentCurrent = Mathf.Clamp01(value2));
			component4.UpdateSpillwayDoor();
			BlockStackUpdateSystem.inst.MarkWaterDirty(cellDataUnsafe);
		}
		for (int m = 0; m < damPlanningProject.scaffoldColumns.Count; m++)
		{
			Cell cellData2 = World.inst.GetCellData(damPlanningProject.scaffoldColumns[m]);
			BlockStackUpdateSystem.inst.MarkWaterDirty(cellData2);
		}
		BlockStackUpdateSystem.inst.SuppressWaterUpdates = false;
		ClosePlanner();
	}

	public static Building FindBuilding(BuildingDescriptionDamPlanning building)
	{
		Cell cellData = World.inst.GetCellData(building.position);
		if (building.uniqueNameHash == World.spilloverHash)
		{
			Building building2 = cellData.StructureFind<Spillover>();
			if (building2 != null)
			{
				return building2;
			}
		}
		for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
		{
			if (Mathf.Approximately(cellData.OccupyingStructure[i].Center().y, building.position.y) && cellData.OccupyingStructure[i].uniqueNameHash == building.uniqueNameHash)
			{
				return cellData.OccupyingStructure[i];
			}
		}
		return null;
	}

	private void UndoChanges()
	{
		cursorMode.RevertAllPreviewRepairs();
		cursorMode.ClearAllTerrainPreview();
		for (int i = 0; i < cursorMode.buildingsToAdd.Count; i++)
		{
			Building building = FindBuilding(cursorMode.buildingsToAdd[i]);
			if (building != null)
			{
				Cell cachedCell = building.cachedCell;
				World.inst.VanishBuilding(building);
				BlockStackUpdateSystem.inst.MarkWaterDirty(cachedCell);
				TerrainGen.inst.ClearTempEffectTile(cachedCell);
				BlockBuilding.MarkBlockStackAndNeighborsDirty(cachedCell);
			}
		}
		cursorMode.buildingsToRemove.Sort((BuildingDescriptionDamPlanning v1, BuildingDescriptionDamPlanning v2) => (int)(v1.position.y * 1000f) - (int)(v2.position.y * 1000f));
		for (int num = 0; num < cursorMode.buildingsToRemove.Count; num++)
		{
			Building building2 = Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(cursorMode.buildingsToRemove[num].uniqueName), Player.inst.buildingContainer.transform);
			building2.gameObject.SetActive(value: true);
			building2.transform.position = cursorMode.buildingsToRemove[num].position - new Vector3(0.5f, 0f, 0.5f);
			building2.Init();
			building2.doBuildAnimation = false;
			building2.CompletelyQuiet = true;
			World.inst.PlaceByAI(building2);
			building2.ForceCompleteBuild();
			cursorMode.buildingsToRemove[num].savedState.RestoreToBuilding(building2);
			Spillover component = building2.GetComponent<Spillover>();
			if (component != null)
			{
				component.UpdateVisual(ignoreValidation: true);
				component.UpdateMovables();
			}
			BlockStackUpdateSystem.inst.MarkWaterDirty(building2.cachedCell);
		}
		foreach (KeyValuePair<int, SpillwayResetData> spillwayResetDatum in spillwayResetData)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(spillwayResetDatum.Key);
			Building building3 = cellDataUnsafe.StructureFind<Spillover>();
			if (building3 != null)
			{
				Spillover component2 = building3.GetComponent<Spillover>();
				component2.UpdateVisual(ignoreValidation: true);
				component2.spillwayOpenPercentCurrent = spillwayResetDatum.Value.current;
				component2.spillwayOpenPercentDesired = spillwayResetDatum.Value.desired;
				component2.UpdateSpillwayDoor();
				BlockStackUpdateSystem.inst.MarkWaterDirty(cellDataUnsafe);
			}
		}
		for (int num2 = 0; num2 < cursorMode.cellsToClear.Count; num2++)
		{
			CellsToClearDamPlanning cellsToClearDamPlanning = cursorMode.cellsToClear[num2];
			Cell cellDataUnsafe2 = World.inst.GetCellDataUnsafe(cellsToClearDamPlanning.cellIdx);
			foreach (SavedItemData tree in cellsToClearDamPlanning.trees)
			{
				World.inst.treeSystem.SetItem(cellDataUnsafe2, tree.pos, tree.scale, tree.rotation, (int)tree.meshIdx);
			}
			foreach (SavedItemData rock in cellsToClearDamPlanning.rocks)
			{
				World.inst.rockScatterSystem.SetItem(cellDataUnsafe2, rock.pos, rock.scale, rock.rotation, (int)rock.meshIdx);
			}
		}
	}

	public void OnDestroy()
	{
	}

	public void OnClickedClose()
	{
		AskToClose();
	}

	public void AskToClose()
	{
		lastTool = cursorMode.toolId;
		cursorMode.SetTool(-1);
		if (cursorMode.buildingsToAdd.Count == 0 && cursorMode.buildingsToRemove.Count == 0)
		{
			CloseConfirmed();
		}
		else
		{
			closeConfirmation.ShowConfirmation(CloseConfirmed, CloseCancelled);
		}
	}

	public void CloseCancelled()
	{
		cursorMode.SetTool(lastTool);
		closeConfirmation.Reset();
	}

	public void CloseConfirmed()
	{
		UndoChanges();
		ClosePlanner();
	}

	public void ClosePlanner()
	{
		ResetWaterState();
		BlockStackUpdateSystem.inst.FlushWaterUpdates();
		Close();
	}

	private void TryInitCursorMode()
	{
		if (cursorMode == null)
		{
			cursorMode = new DamPlanningCursorMode();
		}
	}

	private void OnDisable()
	{
	}

	public override void UpdateInternal(float dt)
	{
		base.UpdateInternal(dt);
		ResourceAmount resourceAmount = cursorMode.GetCostForAll() + GameUI.inst.CurrPlacementMode.cost;
		bool flag = Player.inst.FocusedResources.HasCost(resourceAmount);
		CostAmount.text = resourceAmount.NeedCost(Player.inst.FocusedResources);
		int num = Player.inst.FocusedResources.Get(2);
		int num2 = Player.inst.FocusedResources.Get(1);
		if (lastStone != num || lastWood != num2)
		{
			HaveAmount.text = ResourceAmount.ResourceIcon(2) + " " + num + "  " + ResourceAmount.ResourceIcon(1) + " " + num2;
		}
		lastStone = num;
		lastWood = num2;
		bool flag2 = resourceAmount == ResourceAmount.empty;
		if (CostContainer.gameObject.activeSelf == flag2)
		{
			CostContainer.gameObject.SetActive(!flag2);
		}
		bool flag3 = HasAnyChanges();
		StartProject_Button.interactable = flag & flag3;
		if (CostError.gameObject.activeSelf == flag)
		{
			CostError.gameObject.SetActive(!flag);
		}
		string text = (flag ? "damplanningui_startproject_button" : "damplanningui_cannotafforderror");
		if (StartProject_Localize.Term != text)
		{
			StartProject_Localize.SetTerm(text);
		}
		if (cursorMode.StateChange)
		{
			cursorMode.StateChange = false;
			waterResetTimer.CurrTime = 0f;
			WorldMask.inst.ForceUpdate();
			BlockStackUpdateSystem.inst.FlushBlockStackUpdates();
			ResetWaterState();
			BlockStackUpdateSystem.inst.FlushWaterUpdates();
		}
		if (cursorMode.TryingToQuit)
		{
			cursorMode.TryingToQuit = false;
			AskToClose();
		}
		if (cursorMode.CancellingTool)
		{
			cursorMode.CancellingTool = false;
			for (int i = 0; i < ToolToggles.Length; i++)
			{
				ToolToggles[i].SetIsOnWithoutNotify(value: false);
			}
		}
		waterResetTimer.Duration = WaterSimTimeUserSlider.value;
		WaterSimTimeVisualSlider.value = waterResetTimer.CurrTime;
		Util.SetActive(BuildingDamageWarning, DynamicWater.inst.damagedBuildings > 0);
		UpdateSpillwayUIHoverState();
	}

	private void UpdateSpillwayUIHoverState()
	{
		bool flag = false;
		if (_cachedCanvas == null)
		{
			_cachedCanvas = GetComponentInParent<Canvas>();
		}
		Camera cam = ((_cachedCanvas != null && _cachedCanvas.renderMode == RenderMode.ScreenSpaceCamera) ? _cachedCanvas.worldCamera : null);
		foreach (SpillwayUI spawnedSpillwayUI in spawnedSpillwayUIs)
		{
			if (!(spawnedSpillwayUI == null) && spawnedSpillwayUI.gameObject.activeInHierarchy)
			{
				RectTransform component = spawnedSpillwayUI.GetComponent<RectTransform>();
				if (component != null && RectTransformUtility.RectangleContainsScreenPoint(component, Input.mousePosition, cam))
				{
					flag = true;
					break;
				}
			}
		}
		bool flag2 = PointingSystem.GetPointer().GetPrimaryDownThisFrame() && cursorMode.toolId >= 0;
		if (flag2)
		{
			foreach (KeyValuePair<SpillwayUI, CanvasGroup> spillwayUICanvasGroup in spillwayUICanvasGroups)
			{
				if (spillwayUICanvasGroup.Value != null)
				{
					spillwayUICanvasGroup.Value.blocksRaycasts = false;
					spillwayUICanvasGroup.Value.alpha = Mathf.MoveTowards(spillwayUICanvasGroup.Value.alpha, 0f, Time.unscaledDeltaTime * 5f);
				}
			}
		}
		else
		{
			foreach (KeyValuePair<SpillwayUI, CanvasGroup> spillwayUICanvasGroup2 in spillwayUICanvasGroups)
			{
				if (spillwayUICanvasGroup2.Value != null)
				{
					spillwayUICanvasGroup2.Value.blocksRaycasts = true;
				}
			}
		}
		if (flag && !isMouseOverSpillwayUI && !flag2)
		{
			isMouseOverSpillwayUI = true;
			previousToolStateBeforeHover = cursorMode.toolId;
			if (previousToolStateBeforeHover >= 0)
			{
				cursorMode.SetTool(-2);
			}
		}
		else if (!flag && isMouseOverSpillwayUI)
		{
			isMouseOverSpillwayUI = false;
			if (previousToolStateBeforeHover >= 0)
			{
				cursorMode.SetTool(previousToolStateBeforeHover);
			}
		}
	}

	private void LateUpdate()
	{
		if (Visible)
		{
			UpdateSpillwayUIPositions();
		}
	}

	public void ViewDamagedBuilding()
	{
		Cam.inst.SetDesiredTrackingPos(DynamicWater.inst.buildingDamageLoc);
	}

	public void ResetWaterState()
	{
		DynamicWater.inst.RestoreState(waterState);
		DynamicWater.inst.damagedBuildings = 0;
	}

	private void SpawnSpillwayUIs()
	{
		DestroySpillwayUIs();
		plannedSpillwayHeights.Clear();
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(World.spilloverHash);
		for (int i = 0; i < buildingList.Count; i++)
		{
			Building spillway = buildingList.data[i];
			SpawnSpillwayUIForBuilding(spillway);
		}
	}

	public void SpawnSpillwayUIForBuilding(Building spillway, bool isNewlyPlaced = false)
	{
		if (spillwayUIPrefab == null || spillway == null)
		{
			return;
		}
		Spillover component = spillway.GetComponent<Spillover>();
		if (component == null)
		{
			return;
		}
		Cell cell = spillway.GetCell();
		if (cell == null || (!isNewlyPlaced && DamProjectManager.inst.IsCellPartOfProject(cell, out var _)))
		{
			return;
		}
		foreach (SpillwayUI spawnedSpillwayUI in spawnedSpillwayUIs)
		{
			if (spawnedSpillwayUI.spilloverBuilding == component)
			{
				return;
			}
		}
		if (isNewlyPlaced)
		{
			component.UpdateVisual(ignoreValidation: true);
			component.spillwayOpenPercentDesired = 1f;
			component.spillwayOpenPercentCurrent = 1f;
			component.UpdateSpillwayDoor();
			TerrainGen.inst.RecalcWaterObstructionForArea(cell.x, cell.z, 1, 1);
		}
		else if (component.spillOverDamBlocks == null || component.spillOverDamBlocks.Length == 0)
		{
			component.UpdateVisual(ignoreValidation: true);
		}
		SpillwayUI spillwayUI = Object.Instantiate(spillwayUIPrefab, transform);
		RectTransform component2 = spillwayUI.GetComponent<RectTransform>();
		component2.anchorMin = new Vector2(0.5f, 0.5f);
		component2.anchorMax = new Vector2(0.5f, 0.5f);
		component2.pivot = new Vector2(0.5f, 0f);
		CanvasGroup canvasGroup = spillwayUI.GetComponent<CanvasGroup>();
		if (canvasGroup == null)
		{
			canvasGroup = spillwayUI.gameObject.AddComponent<CanvasGroup>();
		}
		spillwayUICanvasGroups[spillwayUI] = canvasGroup;
		spillwayUI.InitForDamPlanner(component, OnSpillwayHeightChanged);
		spawnedSpillwayUIs.Add(spillwayUI);
		plannedSpillwayHeights[cell.index] = component.spillwayOpenPercentDesired;
	}

	public void RemoveSpillwayUIForBuilding(Building spillway)
	{
		if (spillway == null)
		{
			return;
		}
		Spillover component = spillway.GetComponent<Spillover>();
		if (component == null)
		{
			return;
		}
		for (int num = spawnedSpillwayUIs.Count - 1; num >= 0; num--)
		{
			if (spawnedSpillwayUIs[num].spilloverBuilding == component)
			{
				spillwayUICanvasGroups.Remove(spawnedSpillwayUIs[num]);
				Object.Destroy(spawnedSpillwayUIs[num].gameObject);
				spawnedSpillwayUIs.RemoveAt(num);
			}
		}
		Cell cell = spillway.GetCell();
		if (cell != null)
		{
			plannedSpillwayHeights.Remove(cell.index);
		}
	}

	public void RefreshSpillwayUIForCell(Cell cell, Building newlyPlacedBuilding = null)
	{
		if (cell == null)
		{
			return;
		}
		Building building = cell.StructureFind<Spillover>();
		if (building == null)
		{
			return;
		}
		Spillover component = building.GetComponent<Spillover>();
		if (component == null)
		{
			return;
		}
		float num = 0f;
		float a = TerrainGen.inst.heightCache[component.meshIndexForDoor];
		float num2 = 0f;
		if (component.topBlock != null)
		{
			num2 = ((component.topBlock.WaterObstructionActive == null || component.topBlock.WaterObstructionActive.Length == 0) ? (component.topBlock.transform.position.y + 0.5f) : component.topBlock.WaterObstructionActive[0].transform.position.y);
			num = Mathf.Lerp(a, num2, component.spillwayOpenPercentDesired);
		}
		component.UpdateVisual(ignoreValidation: true);
		float num3 = 0f;
		BlockBuilding blockBuilding = null;
		foreach (Building item in cell.OccupyingStructure)
		{
			if (item.uniqueNameHash == World.damHash)
			{
				BlockBuilding component2 = item.GetComponent<BlockBuilding>();
				float blockBuildingTopHeight = GetBlockBuildingTopHeight(component2);
				if (blockBuildingTopHeight > num3)
				{
					num3 = blockBuildingTopHeight;
					blockBuilding = component2;
				}
			}
		}
		if (newlyPlacedBuilding != null && newlyPlacedBuilding.uniqueNameHash == World.damHash)
		{
			BlockBuilding component3 = newlyPlacedBuilding.GetComponent<BlockBuilding>();
			float blockBuildingTopHeight2 = GetBlockBuildingTopHeight(component3);
			if (blockBuildingTopHeight2 > num3)
			{
				num3 = blockBuildingTopHeight2;
				blockBuilding = component3;
			}
		}
		if (blockBuilding != null)
		{
			component.topBlock = blockBuilding;
		}
		if (num3 > 0f && num > 0f)
		{
			a = TerrainGen.inst.heightCache[component.meshIndexForDoor];
			float value = Mathf.InverseLerp(a, num3, num);
			value = (component.spillwayOpenPercentCurrent = (component.spillwayOpenPercentDesired = Mathf.Clamp01(value)));
			component.UpdateSpillwayDoor();
			plannedSpillwayHeights[cell.index] = value;
		}
		foreach (SpillwayUI spawnedSpillwayUI in spawnedSpillwayUIs)
		{
			if (spawnedSpillwayUI != null && spawnedSpillwayUI.spilloverBuilding == component)
			{
				spawnedSpillwayUI.Refresh();
				break;
			}
		}
	}

	private void DestroySpillwayUIs()
	{
		foreach (SpillwayUI spawnedSpillwayUI in spawnedSpillwayUIs)
		{
			if (spawnedSpillwayUI != null)
			{
				Object.Destroy(spawnedSpillwayUI.gameObject);
			}
		}
		spawnedSpillwayUIs.Clear();
		spillwayUICanvasGroups.Clear();
		pinnedSpillwayCellIndex = -1;
	}

	private void OnSpillwayHeightChanged(Spillover spillover, float newHeight)
	{
		plannedSpillwayHeights[spillover.b.cachedCell.index] = newHeight;
	}

	public void PinSpillway(int cellIndex)
	{
		if (pinnedSpillwayCellIndex != cellIndex)
		{
			pinnedSpillwayCellIndex = cellIndex;
		}
	}

	public bool IsSpillwayPinned(int cellIndex)
	{
		return pinnedSpillwayCellIndex == cellIndex;
	}

	private static float GetBlockBuildingTopHeight(BlockBuilding blockBuilding)
	{
		if (blockBuilding == null)
		{
			return 0f;
		}
		if (blockBuilding.WaterObstructionActive != null && blockBuilding.WaterObstructionActive.Length != 0)
		{
			return blockBuilding.WaterObstructionActive[0].transform.position.y;
		}
		return blockBuilding.transform.position.y + 0.5f;
	}

	private void UpdateSpillwayUIPositions()
	{
		if (_cachedCanvas == null)
		{
			_cachedCanvas = GetComponentInParent<Canvas>();
			_cachedCanvasRect = ((_cachedCanvas != null) ? _cachedCanvas.GetComponent<RectTransform>() : null);
		}
		Camera cam = ((_cachedCanvas != null && _cachedCanvas.renderMode == RenderMode.ScreenSpaceCamera) ? _cachedCanvas.worldCamera : null);
		Vector3 position = Camera.main.transform.position;
		float num = 3.3333333f;
		for (int num2 = spawnedSpillwayUIs.Count - 1; num2 >= 0; num2--)
		{
			SpillwayUI spillwayUI = spawnedSpillwayUIs[num2];
			if (spillwayUI == null || spillwayUI.spilloverBuilding == null)
			{
				if (spillwayUI != null)
				{
					spillwayUICanvasGroups.Remove(spillwayUI);
					Object.Destroy(spillwayUI.gameObject);
				}
				spawnedSpillwayUIs.RemoveAt(num2);
			}
			else
			{
				Vector3 vector = spillwayUI.spilloverBuilding.b.Center();
				if (spillwayUI.spilloverBuilding.topBlock != null && spillwayUI.spilloverBuilding.topBlock.WaterObstructionActive != null && spillwayUI.spilloverBuilding.topBlock.WaterObstructionActive.Length != 0)
				{
					vector = spillwayUI.spilloverBuilding.topBlock.b.Center();
					vector.y = spillwayUI.spilloverBuilding.topBlock.WaterObstructionActive[0].position.y + 0.5f;
				}
				else
				{
					vector.y += 0.5f;
				}
				float num3 = Vector3.Distance(vector, position);
				int num4 = ((spillwayUI.spilloverBuilding.b.cachedCell != null) ? spillwayUI.spilloverBuilding.b.cachedCell.index : (-1));
				float target = (((num4 >= 0 && pinnedSpillwayCellIndex == num4) || num3 <= spillwayUIMaxDistance) ? 1f : 0f);
				bool num5 = PointingSystem.GetPointer().GetPrimaryDownThisFrame() && cursorMode.toolId >= 0;
				spillwayUICanvasGroups.TryGetValue(spillwayUI, out var value);
				if (!num5 && value != null)
				{
					float alpha = Mathf.MoveTowards(value.alpha, target, num * Time.unscaledDeltaTime);
					value.alpha = alpha;
				}
				Vector3 vector2 = Camera.main.WorldToScreenPoint(vector);
				float num6 = ((value != null) ? value.alpha : 1f);
				if (vector2.z > 0f && num6 > 0.01f)
				{
					spillwayUI.gameObject.SetActive(value: true);
					if (_cachedCanvasRect != null)
					{
						RectTransformUtility.ScreenPointToLocalPointInRectangle(_cachedCanvasRect, vector2, cam, out var localPoint);
						spillwayUI.GetComponent<RectTransform>().anchoredPosition = localPoint;
					}
				}
				else
				{
					spillwayUI.gameObject.SetActive(value: false);
				}
			}
		}
		spawnedSpillwayUIs.Sort((SpillwayUI a, SpillwayUI b) =>
		{
			if (a == null || a.spilloverBuilding == null)
			{
				return 1;
			}
			if (b == null || b.spilloverBuilding == null)
			{
				return -1;
			}
			Vector3 position2 = Camera.main.transform.position;
			float value2 = Vector3.SqrMagnitude(a.spilloverBuilding.b.Center() - position2);
			return Vector3.SqrMagnitude(b.spilloverBuilding.b.Center() - position2).CompareTo(value2);
		});
		for (int num7 = 0; num7 < spawnedSpillwayUIs.Count; num7++)
		{
			if (spawnedSpillwayUIs[num7] != null)
			{
				spawnedSpillwayUIs[num7].transform.SetSiblingIndex(num7);
			}
		}
	}

	public override void SetVisible(bool v)
	{
		if (Visible && !v)
		{
			if (isMouseOverSpillwayUI && previousToolStateBeforeHover >= 0)
			{
				cursorMode.SetTool(previousToolStateBeforeHover);
			}
			isMouseOverSpillwayUI = false;
			previousToolStateBeforeHover = -1;
			DestroySpillwayUIs();
			if (GameUI.inst.currCursorMode == cursorMode)
			{
				GameUI.inst.ReturnToDefaultCursorMode();
			}
			World.inst.HideResourceTooltipUIs();
			WorldMask.inst.Deactivate();
			MusicSystem.inst.StartDefaultMusic();
			GodManager.inst.EnsureMinCooldown(5f);
		}
		else if (!Visible & v)
		{
			MusicSystem.inst.StartDamPlannerMusic();
			MilestoneManager.inst.waterBeforeDam = DynamicWater.inst.totalWater;
		}
		if (v)
		{
			TimeManager.inst.SetLocked(val: true);
		}
		else if (!v && visible)
		{
			TimeManager.inst.SetLocked(val: false);
		}
		base.SetVisible(v);
		if (v)
		{
			if (Player.inst.seenDamPlannerIntro)
			{
				IntroPopup.gameObject.SetActive(value: false);
			}
			else
			{
				IntroPopup.gameObject.SetActive(value: true);
			}
			GameUI.inst.SetCursorMode(cursorMode);
			CreativeUI.inst.SetWindowVisibility(v: false);
			waterState = DynamicWater.inst.SaveState();
			savedWaterObstructionField = (float[])TerrainGen.inst.waterObstructionField.Clone();
			ToolToggles[0].isOn = true;
			cursorMode.SetTool(0);
			WorldMask.inst.Activate(MaskingDetails, 1);
			spillwayResetData.Clear();
			ArrayExt<Building> buildingList = Player.inst.GetBuildingList(World.spilloverHash);
			for (int i = 0; i < buildingList.Count; i++)
			{
				Building building = buildingList.data[i];
				Spillover component = building.GetComponent<Spillover>();
				float b;
				float a = (b = TerrainGen.inst.heightCache[component.meshIndexForDoor]);
				if (component.topBlock != null && component.topBlock.WaterObstructionActive != null && component.topBlock.WaterObstructionActive.Length != 0)
				{
					b = component.topBlock.WaterObstructionActive[0].position.y;
				}
				float originalWorldHeight = Mathf.Lerp(a, b, component.spillwayOpenPercentDesired);
				spillwayResetData[building.cachedCell.index] = new SpillwayResetData
				{
					current = component.spillwayOpenPercentCurrent,
					desired = component.spillwayOpenPercentDesired,
					originalWorldHeight = originalWorldHeight
				};
			}
			SpawnSpillwayUIs();
		}
		TerrainGen.inst.ClearOverlay(updateToo: true);
		TerrainGen.inst.FadeOverlay(v ? 1 : 0);
		DynamicWater.inst.EditTerrainSimulateOn(v);
		DynamicWater.inst.ShowDamageOverlay(v);
		DynamicWater.inst.waterfallParticleManager.SimulationMode(v);
	}

	private void MaskingDetails(CommandBuffer buffer, Material maskingMaterial, RenderTexture rTexture)
	{
		buffer.Clear();
		buffer.SetRenderTarget(rTexture);
		buffer.ClearRenderTarget(clearDepth: true, clearColor: true, Color.clear);
		normal.Clear();
		highlight.Clear();
		int focusedLandMassIdxLastValid = Player.inst.FocusedLandMassIdxLastValid;
		TerrainGen.inst.terrainChunks.ForEach((TerrainChunk chunk) =>
		{
			normal.Add(chunk.meshRenderer);
		});
		WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.damHash, focusedLandMassIdxLastValid);
		for (int num = 0; num < normal.Count; num++)
		{
			if (normal.data[num].gameObject.activeInHierarchy)
			{
				buffer.DrawRenderer(normal.data[num], maskingMaterial, 0, 4);
			}
		}
		for (int num2 = 0; num2 < highlight.Count; num2++)
		{
			if (highlight.data[num2].gameObject.activeInHierarchy)
			{
				buffer.DrawRenderer(highlight.data[num2], maskingMaterial, 0, 2);
			}
		}
	}

	private void OnEnable()
	{
	}
}
