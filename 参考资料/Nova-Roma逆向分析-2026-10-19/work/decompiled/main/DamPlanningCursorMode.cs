using System.Collections.Generic;
using Assets.Code;
using UnityEngine;

public class DamPlanningCursorMode : CursorMode
{
	public List<BuildingDescriptionDamPlanning> buildingsToAdd = new List<BuildingDescriptionDamPlanning>();

	public List<BuildingDescriptionDamPlanning> buildingsToRemove = new List<BuildingDescriptionDamPlanning>();

	public List<CellsToClearDamPlanning> cellsToClear = new List<CellsToClearDamPlanning>();

	public Dictionary<int, CellTerrainData> cellTerrainDataMap = new Dictionary<int, CellTerrainData>();

	private HashSet<int> modifiedPreviewVertices = new HashSet<int>();

	private Dictionary<int, List<(Building building, DamBlockState originalState)>> previewRepairedBlocks = new Dictionary<int, List<(Building, DamBlockState)>>();

	private Building damPrefab;

	private Building spillwayPrefab;

	private PlacementMode placementMode;

	private Vector3 middleMouseDownPos;

	private ResourceAmount costForAll = new ResourceAmount();

	private ResourceAmount costForADam = new ResourceAmount();

	private ResourceAmount costForASpillway = new ResourceAmount();

	private bool inited;

	public bool CancellingTool;

	public bool TryingToQuit;

	public BuildingDescriptionDamPlanning lastClickedPlaceable;

	private Timer showErrorTimer = new Timer(1f)
	{
		Enabled = false
	};

	private string errorMessage = string.Empty;

	public int toolId;

	public bool StateChange;

	private bool overUI;

	public ResourceAmount GetCostForAll()
	{
		costForAll.Clear();
		int num = 0;
		int num2 = 0;
		for (int i = 0; i < buildingsToAdd.Count; i++)
		{
			if (buildingsToAdd[i].uniqueNameHash == World.spilloverHash)
			{
				num2++;
			}
			else
			{
				num++;
			}
		}
		for (int j = 0; j < costForADam.resources.Count; j++)
		{
			costForAll.Add(costForADam.resources[j].resourceID, costForADam.resources[j].Amount * num);
		}
		for (int k = 0; k < costForASpillway.resources.Count; k++)
		{
			costForAll.Add(costForASpillway.resources[k].resourceID, costForASpillway.resources[k].Amount * num2);
		}
		return costForAll;
	}

	private void SetUIVisible(bool v)
	{
		BuildUI.inst.gameObject.SetActive(v);
		GameUI.inst.islandInfoUI.gameObject.SetActive(v);
		CursorModeUI.inst.gameObject.SetActive(v);
		ProsperityUI.inst.gameObject.SetActive(v);
		SeasonViewer.inst.gameObject.SetActive(v);
		SpeedControlUI.inst.gameObject.SetActive(v);
		MiniMapUI.inst.SetVisibility(v);
		CreativeUI.inst.SetVisibility(v);
		CreativeUI.inst.openCreativeBtn.gameObject.SetActive(v);
		GameUI.inst.menuButton.gameObject.SetActive(v);
	}

	public override void Init()
	{
		InWorldExclamation.hideForCursorMode = true;
		placementMode = GameUI.inst.CurrPlacementMode;
		placementMode.OnBuildingPlacing = OnBuildingAdded;
		damPrefab = GameState.inst.GetPlaceableByUniqueName(World.damName);
		spillwayPrefab = GameState.inst.GetPlaceableByUniqueName(World.spilloverName);
		buildingsToAdd.Clear();
		buildingsToRemove.Clear();
		cellsToClear.Clear();
		cellTerrainDataMap.Clear();
		modifiedPreviewVertices.Clear();
		previewRepairedBlocks.Clear();
		World.inst.skipGrassClearing = true;
		BlockStackUpdateSystem.inst.SuppressWaterUpdates = true;
		BlockStackUpdateSystem.inst.ClearWaterUpdates();
		BlockStackUpdateSystem.inst.SuppressColliderUpdates = true;
		BlockStackUpdateSystem.inst.ClearColliderUpdates();
		costForADam = GameState.inst.GetPlaceableByUniqueName(World.damName).GetCost(Player.inst.FocusedLandMass);
		costForASpillway = GameState.inst.GetPlaceableByUniqueName(World.spilloverName).GetCost(Player.inst.FocusedLandMass);
		if (!inited)
		{
			SetUIVisible(v: false);
			inited = true;
		}
	}

	public override bool ShowDragSelectBounds()
	{
		return false;
	}

	public override bool ShowCellHighlighter()
	{
		return toolId == -1;
	}

	public override void HandlePrimaryDown()
	{
	}

	public override void HandlePrimaryUp()
	{
		BlockStackUpdateSystem.inst.FlushWaterUpdatesAfterProcess = true;
		BlockStackUpdateSystem.inst.FlushColliderUpdatesAfterProcess = true;
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		BlockStackUpdateSystem.inst.FlushWaterUpdatesAfterProcess = true;
		BlockStackUpdateSystem.inst.FlushColliderUpdatesAfterProcess = true;
		base.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		return true;
	}

	public override bool DoSecondaryClick()
	{
		if (toolId != -1)
		{
			bool flag = false;
			if (GameUI.inst.CurrPlacementMode.buildings.Count > 0)
			{
				Cell cell = GameUI.inst.CurrPlacementMode.buildings[0].GetCell();
				for (int i = 0; i < GameUI.inst.CurrPlacementMode.buildings.Count; i++)
				{
					if (GameUI.inst.CurrPlacementMode.buildings[i].GetCell() != cell)
					{
						flag = true;
					}
				}
			}
			if (flag)
			{
				GameUI.inst.AbortCursorObjPlacement();
			}
			else
			{
				CancellingTool = true;
				SetTool(-1);
			}
			BlockStackUpdateSystem.inst.FlushBlockStackUpdates();
		}
		return true;
	}

	public override void Shutdown()
	{
		InWorldExclamation.hideForCursorMode = false;
		placementMode.AbortPlacement(refund: false);
		placementMode.OnBuildingPlacing = null;
		ClearAllTerrainPreview();
		BlockStackUpdateSystem.inst.SuppressWaterUpdates = false;
		BlockStackUpdateSystem.inst.ClearWaterUpdates();
		BlockStackUpdateSystem.inst.SuppressColliderUpdates = false;
		BlockStackUpdateSystem.inst.ClearColliderUpdates();
		if (inited)
		{
			SetUIVisible(v: true);
			inited = false;
			World.inst.skipGrassClearing = false;
			World.inst.SetGrassEnabled(e: true);
		}
		base.Shutdown();
	}

	public void SetTool(int id)
	{
		toolId = id;
		if (id == -1 || id == -2)
		{
			placementMode.AbortPlacement(refund: false);
			GameUI.inst.CellHighlighter.ResetBrushes();
		}
		if (id == 0)
		{
			placementMode.SetCursorObject(damPrefab, notFirstPlacement: false);
			placementMode.lastBuilding = damPrefab;
			placementMode.lastBuildInfo = new BuildBuildingDataInstance(damPrefab, enabled: true);
		}
		if (id == 1)
		{
			placementMode.SetCursorObject(spillwayPrefab, notFirstPlacement: false);
			placementMode.lastBuilding = spillwayPrefab;
			placementMode.lastBuildInfo = new BuildBuildingDataInstance(spillwayPrefab, enabled: true);
		}
		if (id == 2 || id == 3)
		{
			placementMode.AbortPlacement(refund: false);
			GameUI.inst.CellHighlighter.SetBrush("brush_demolish");
		}
		World.inst.SetGrassEnabled(e: false);
	}

	private void TrySampleBuildingUnderCursor()
	{
		if (!Physics.Raycast(PointingSystem.GetRay(), out var hitInfo, 100f))
		{
			return;
		}
		BuildingCollider component = hitInfo.transform.GetComponent<BuildingCollider>();
		if (component == null)
		{
			return;
		}
		Cell cell = component.BuildingAsBuilding.GetCell();
		if (cell != null && !(cell.HighestStructureWithUniqueHash(World.damHash) == null))
		{
			Building topStructure = cell.TopStructure;
			if (topStructure != null && topStructure.GetComponent<Spillover>() != null)
			{
				DamPlannerUI.inst.SelectTool(1);
			}
			else
			{
				DamPlannerUI.inst.SelectTool(0);
			}
		}
	}

	public override void Tick(float dt)
	{
		if (GameUI.inst.PointerOverUI() && !overUI)
		{
			overUI = true;
		}
		if (PointingSystem.GetPointer().GetTertiaryDown())
		{
			middleMouseDownPos = Input.mousePosition;
		}
		if (PointingSystem.GetPointer().GetTertiaryUp() && Vector3.Distance(middleMouseDownPos, Input.mousePosition) < 2f && !GameUI.inst.PointerOverUI())
		{
			TrySampleBuildingUnderCursor();
		}
		placementMode.extraCost = GetCostForAll();
		if (toolId == -1)
		{
			if (Physics.Raycast(PointingSystem.GetRay(), out var hitInfo, 100f))
			{
				BuildingCollider component = hitInfo.transform.GetComponent<BuildingCollider>();
				if (component != null)
				{
					Cell cell = component.BuildingAsBuilding?.GetCell();
					if (cell != null && cell.OccupyingStructure.Count > 0)
					{
						Building topStructure = cell.TopStructure;
						if (topStructure == null || topStructure.uniqueNameHash != World.spilloverHash)
						{
							Building building = cell.HighestStructureWithUniqueHash(World.damHash);
							if (building != null)
							{
								float y = building.transform.position.y + (float)building.StackHeight * 0.25f;
								HeightMarker.Show(new Vector3((float)cell.x + 0.5f, y, (float)cell.z + 0.5f));
							}
						}
					}
				}
			}
			if (PointingSystem.GetPointer().GetPrimaryDown() && Physics.Raycast(PointingSystem.GetRay(), out var hitInfo2, 100f) && hitInfo2.transform.GetComponent<BuildingCollider>() != null)
			{
				Building topStructure2 = hitInfo2.transform.GetComponent<BuildingCollider>().BuildingAsBuilding.GetCell().TopStructure;
				if (topStructure2.GetComponent<Spillover>() != null)
				{
					Cell cell2 = topStructure2.GetCell();
					if (!DamProjectManager.inst.IsCellPartOfProject(cell2, out var _))
					{
						DamPlannerUI.inst.PinSpillway(cell2.index);
						BuildingDescriptionDamPlanning selectedBuildingDescription = new BuildingDescriptionDamPlanning(topStructure2);
						lastClickedPlaceable = buildingsToAdd.Find((BuildingDescriptionDamPlanning b) => b.Equals(selectedBuildingDescription));
					}
				}
				else
				{
					lastClickedPlaceable = null;
				}
			}
		}
		else
		{
			lastClickedPlaceable = null;
		}
		if (toolId == 0)
		{
			if (placementMode != null)
			{
				if (!placementMode.IsPlacing() || placementMode.lastBuilding != damPrefab)
				{
					placementMode.SetCursorObject(damPrefab, notFirstPlacement: false);
					placementMode.lastBuilding = damPrefab;
					placementMode.lastBuildInfo = new BuildBuildingDataInstance(damPrefab, enabled: true);
				}
				placementMode.Update();
			}
		}
		else if (toolId == 1)
		{
			if (placementMode != null)
			{
				if (!placementMode.IsPlacing() || placementMode.lastBuilding != spillwayPrefab)
				{
					placementMode.SetCursorObject(spillwayPrefab, notFirstPlacement: false);
					placementMode.lastBuilding = spillwayPrefab;
					placementMode.lastBuildInfo = new BuildBuildingDataInstance(spillwayPrefab, enabled: true);
				}
				placementMode.Update();
			}
		}
		else
		{
			if ((toolId != 2 && toolId != 3) || !PointingSystem.GetPointer().GetPrimaryDown())
			{
				return;
			}
			Ray ray = PointingSystem.GetRay();
			if (!Physics.Raycast(ray, out var hitInfo3, 100f))
			{
				return;
			}
			BuildingCollider component2 = hitInfo3.transform.GetComponent<BuildingCollider>();
			Building building2 = null;
			Cell cell3 = null;
			if (component2 != null)
			{
				cell3 = component2.BuildingAsBuilding.GetCell();
				building2 = cell3.TopStructure;
			}
			else
			{
				Cell cellData = World.inst.GetCellData(GameUI.inst.GridPointerIntersection());
				if (Vector3.Dot(Vector3.down, ray.direction.normalized) > 0f && cellData.OccupyingStructure.Count > 0)
				{
					cell3 = cellData;
					building2 = cellData.TopStructure;
				}
			}
			if (!(building2 != null))
			{
				return;
			}
			if (building2.GetComponent<Spillover>() != null)
			{
				Cell cell4 = building2.GetCell();
				if (!DamProjectManager.inst.IsCellPartOfProject(cell4, out var _))
				{
					OnBuildingRemoved(building2);
					World.inst.VanishBuilding(building2);
					BlockBuilding.MarkBlockStackAndNeighborsDirty(cell4);
				}
				return;
			}
			Building building3 = cell3.HighestStructureWithUniqueHash(World.damHash);
			if (!(building3 != null) || !(building3.GetComponent<BlockBuilding>() != null))
			{
				return;
			}
			Cell cell5 = building3.GetCell();
			if (!DamProjectManager.inst.IsCellPartOfProject(cell5, out var _))
			{
				if (cell5.OccupyingStructure.Count == 2 && cell5.TopStructure.GetComponent<Spillover>() != null)
				{
					OnBuildingRemoved(cell5.TopStructure);
					World.inst.VanishBuilding(cell5.TopStructure);
				}
				OnBuildingRemoved(building3);
				World.inst.VanishBuilding(building3);
				BlockBuilding.MarkBlockStackAndNeighborsDirty(cell5);
			}
		}
	}

	public void OnBuildingAdded(Building building)
	{
		building.doBuildAnimation = false;
		building.CompletelyQuiet = true;
		building.Transparent = true;
		StateChange = true;
		building.ForEachTileInBounds((int x, int z, Cell cell3) =>
		{
			List<SavedItemData> list = new List<SavedItemData>();
			List<SavedItemData> list2 = new List<SavedItemData>();
			TreeSystem treeSystem = World.inst.treeSystem;
			TreeSystem.TreeCellData treeCellDataAt = treeSystem.GetTreeCellDataAt(cell3.x, cell3.z);
			if (treeCellDataAt != null && treeCellDataAt.TreeAmount > 0)
			{
				TreeSystem.Chunk chunk = treeSystem.GetChunk(cell3.x, cell3.z);
				for (int i = 0; i < treeCellDataAt.TreeIds.Length; i++)
				{
					int num3 = treeCellDataAt.TreeIds[i];
					if (num3 != -1)
					{
						TreeSystem.TreeData treeData = chunk.itemData[num3];
						list.Add(new SavedItemData
						{
							pos = treeData.pos,
							scale = treeData.scale,
							rotation = treeData.rotation,
							meshIdx = chunk.meshIdxs[num3]
						});
					}
				}
			}
			TreeSystem rockScatterSystem = World.inst.rockScatterSystem;
			TreeSystem.TreeCellData treeCellDataAt2 = rockScatterSystem.GetTreeCellDataAt(cell3.x, cell3.z);
			if (treeCellDataAt2 != null && treeCellDataAt2.TreeAmount > 0)
			{
				TreeSystem.Chunk chunk2 = rockScatterSystem.GetChunk(cell3.x, cell3.z);
				for (int j = 0; j < treeCellDataAt2.TreeIds.Length; j++)
				{
					int num4 = treeCellDataAt2.TreeIds[j];
					if (num4 != -1)
					{
						TreeSystem.TreeData treeData2 = chunk2.itemData[num4];
						list2.Add(new SavedItemData
						{
							pos = treeData2.pos,
							scale = treeData2.scale,
							rotation = treeData2.rotation,
							meshIdx = chunk2.meshIdxs[num4]
						});
					}
				}
			}
			if (list.Count != 0 || list2.Count != 0)
			{
				cellsToClear.Add(new CellsToClearDamPlanning
				{
					cellIdx = cell3.index,
					trees = list,
					rocks = list2
				});
				cell3.ClearCell();
			}
		});
		BuildingDescriptionDamPlanning item = new BuildingDescriptionDamPlanning(building);
		int num = buildingsToRemove.IndexOf(item);
		if (num >= 0)
		{
			BuildingDescriptionDamPlanning buildingDescriptionDamPlanning = buildingsToRemove[num];
			buildingsToRemove.RemoveAt(num);
			building.Life = buildingDescriptionDamPlanning.savedState.life;
			building.ModifiedMaxLife = buildingDescriptionDamPlanning.savedState.modifiedMaxLife;
			if (building.uniqueNameHash == World.damHash && buildingDescriptionDamPlanning.savedState.IsDamaged)
			{
				Cell cell = building.GetCell();
				if (cell != null)
				{
					int index = cell.index;
					if (previewRepairedBlocks.ContainsKey(index))
					{
						previewRepairedBlocks[index].Add((building, buildingDescriptionDamPlanning.savedState));
						building.Life = building.ModifiedMaxLife;
					}
				}
			}
			if (building.uniqueNameHash == World.spilloverHash)
			{
				DamPlannerUI.inst.SpawnSpillwayUIForBuilding(building);
			}
			return;
		}
		buildingsToAdd.Add(new BuildingDescriptionDamPlanning(building));
		if (building.uniqueNameHash == World.spilloverHash)
		{
			DamPlannerUI.inst.SpawnSpillwayUIForBuilding(building, isNewlyPlaced: true);
		}
		if (building.uniqueNameHash == World.damHash)
		{
			TryPreviewRepairCell(building.GetCell());
		}
		if (building.uniqueNameHash != World.damHash)
		{
			return;
		}
		Cell cell2 = building.GetCell();
		if (cell2 == null)
		{
			return;
		}
		int index2 = cell2.index;
		float num2 = building.transform.position.y;
		if (!cellTerrainDataMap.ContainsKey(index2))
		{
			foreach (Building item2 in cell2.OccupyingStructure)
			{
				if (item2.uniqueNameHash == World.damHash)
				{
					float y = item2.transform.position.y;
					if (y < num2)
					{
						num2 = y;
					}
				}
			}
			StoreOriginalHeightsAndApplyPreview(cell2, num2);
		}
		else
		{
			CellTerrainData cellTerrainData = cellTerrainDataMap[index2];
			if (num2 < cellTerrainData.damBottomHeight)
			{
				cellTerrainData.damBottomHeight = num2;
				UpdatePreviewForCell(cellTerrainData);
			}
		}
		DamPlannerUI.inst.RefreshSpillwayUIForCell(cell2, building);
	}

	public void OnBuildingRemoved(Building building)
	{
		StateChange = true;
		if (building.uniqueNameHash == World.spilloverHash)
		{
			DamPlannerUI.inst.RemoveSpillwayUIForBuilding(building);
		}
		if (buildingsToAdd.Contains(new BuildingDescriptionDamPlanning(building)))
		{
			buildingsToAdd.Remove(new BuildingDescriptionDamPlanning(building));
			if (building.uniqueNameHash == World.damHash)
			{
				Cell cell = building.GetCell();
				HandleDamBlockRemoval(building);
				TryRevertPreviewRepairCell(cell);
				DamPlannerUI.inst.RefreshSpillwayUIForCell(cell);
			}
		}
		else
		{
			buildingsToRemove.Add(new BuildingDescriptionDamPlanning(building));
			if (building.uniqueNameHash == World.damHash)
			{
				Cell cell2 = building.GetCell();
				HandleDamBlockRemoval(building);
				DamPlannerUI.inst.RefreshSpillwayUIForCell(cell2);
			}
		}
	}

	private void HandleDamBlockRemoval(Building building)
	{
		Cell cell = building.GetCell();
		if (cell == null)
		{
			return;
		}
		BlockStackUpdateSystem.inst.MarkWaterDirty(cell);
		int index = cell.index;
		CellTerrainData value2;
		if (!CellStillHasDamBlocks(cell, building))
		{
			if (cellTerrainDataMap.TryGetValue(index, out var value))
			{
				RevertPreviewForCell(value);
				cellTerrainDataMap.Remove(index);
			}
		}
		else if (cellTerrainDataMap.TryGetValue(index, out value2))
		{
			float lowestDamBottomInCell = GetLowestDamBottomInCell(cell, building);
			if (lowestDamBottomInCell < float.MaxValue)
			{
				value2.damBottomHeight = lowestDamBottomInCell;
				UpdatePreviewForCell(value2);
			}
		}
	}

	private void TryPreviewRepairCell(Cell cell)
	{
		if (cell == null)
		{
			return;
		}
		int index = cell.index;
		if (previewRepairedBlocks.ContainsKey(index))
		{
			return;
		}
		List<(Building, DamBlockState)> list = new List<(Building, DamBlockState)>();
		foreach (Building item in cell.OccupyingStructure)
		{
			if (item.uniqueNameHash == World.damHash && item.IsDamaged() && !buildingsToAdd.Contains(new BuildingDescriptionDamPlanning(item)))
			{
				list.Add((item, new DamBlockState(item)));
				item.Life = item.ModifiedMaxLife;
				item.TakeDamage(0f, item.Center(), "dam_preview_repair");
			}
		}
		if (list.Count > 0)
		{
			previewRepairedBlocks[index] = list;
		}
	}

	private void TryRevertPreviewRepairCell(Cell cell)
	{
		if (cell == null)
		{
			return;
		}
		int index = cell.index;
		if (!previewRepairedBlocks.ContainsKey(index))
		{
			return;
		}
		foreach (BuildingDescriptionDamPlanning item in buildingsToAdd)
		{
			if (item.uniqueNameHash == World.damHash)
			{
				Cell cellData = World.inst.GetCellData(item.position);
				if (cellData != null && cellData.index == index)
				{
					return;
				}
			}
		}
		foreach (var (building, damBlockState) in previewRepairedBlocks[index])
		{
			if (!(building == null))
			{
				damBlockState.RestoreToBuilding(building);
			}
		}
		previewRepairedBlocks.Remove(index);
	}

	public void RevertAllPreviewRepairs(bool revert = true)
	{
		if (revert)
		{
			foreach (KeyValuePair<int, List<(Building, DamBlockState)>> previewRepairedBlock in previewRepairedBlocks)
			{
				foreach (var (building, damBlockState) in previewRepairedBlock.Value)
				{
					if (!(building == null))
					{
						damBlockState.RestoreToBuilding(building);
					}
				}
			}
		}
		previewRepairedBlocks.Clear();
	}

	private void StoreOriginalHeightsAndApplyPreview(Cell cell, float damBottomHeight)
	{
		int index = cell.index;
		int meshWidth = World.MeshWidth;
		int num = DynamicWater.MapIndexWorldToMesh(index, World.inst.GridWidth);
		CellTerrainData cellTerrainData = new CellTerrainData
		{
			cellIndex = index,
			vertexIndices = new int[9],
			originalHeights = new float[9],
			damBottomHeight = damBottomHeight
		};
		int num2 = 0;
		for (int i = -1; i <= 1; i++)
		{
			for (int j = -1; j <= 1; j++)
			{
				int num3 = num + j + i * meshWidth;
				if (num3 >= 0 && num3 < TerrainGen.inst.heightCache.Length)
				{
					cellTerrainData.vertexIndices[num2] = num3;
					cellTerrainData.originalHeights[num2] = TerrainGen.inst.GetVertYUnsafe(num3);
				}
				num2++;
			}
		}
		cellTerrainDataMap[index] = cellTerrainData;
		UpdatePreviewForCell(cellTerrainData);
	}

	private void UpdatePreviewForCell(CellTerrainData cellData)
	{
		Color[] terrainPixelsPreview = TerrainGen.inst.terrainPixelsPreview;
		for (int i = 0; i < 9; i++)
		{
			int num = cellData.vertexIndices[i];
			if (num >= 0 && num < terrainPixelsPreview.Length)
			{
				float num2 = cellData.originalHeights[i];
				float num3 = cellData.damBottomHeight - num2;
				if (num3 > 0f)
				{
					float r = Mathf.Max(num3, CalculateMaxPreviewHeightForVertex(num, cellData.cellIndex));
					Color color = terrainPixelsPreview[num];
					color.r = r;
					terrainPixelsPreview[num] = color;
					modifiedPreviewVertices.Add(num);
				}
			}
		}
		ApplyTerrainPreview();
	}

	private float CalculateMaxPreviewHeightForVertex(int vertIdx, int excludeCellIndex = -1)
	{
		float num = 0f;
		foreach (KeyValuePair<int, CellTerrainData> item in cellTerrainDataMap)
		{
			if (item.Key == excludeCellIndex)
			{
				continue;
			}
			CellTerrainData value = item.Value;
			for (int i = 0; i < 9; i++)
			{
				if (value.vertexIndices[i] == vertIdx)
				{
					float num2 = value.originalHeights[i];
					float num3 = value.damBottomHeight - num2;
					if (num3 > num)
					{
						num = num3;
					}
				}
			}
		}
		return num;
	}

	private void RevertPreviewForCell(CellTerrainData cellData)
	{
		Color[] terrainPixelsPreview = TerrainGen.inst.terrainPixelsPreview;
		for (int i = 0; i < 9; i++)
		{
			int num = cellData.vertexIndices[i];
			if (num >= 0 && num < terrainPixelsPreview.Length)
			{
				float num2 = CalculateMaxPreviewHeightForVertex(num, cellData.cellIndex);
				Color color = terrainPixelsPreview[num];
				color.r = num2;
				terrainPixelsPreview[num] = color;
				if (num2 <= 0f)
				{
					modifiedPreviewVertices.Remove(num);
				}
			}
		}
		ApplyTerrainPreview();
	}

	private void ApplyTerrainPreview()
	{
		TerrainGen.inst.terrainHeightMapPreview.SetPixels(TerrainGen.inst.terrainPixelsPreview);
		TerrainGen.inst.terrainHeightMapPreview.Apply();
	}

	public void ClearAllTerrainPreview()
	{
		Color[] terrainPixelsPreview = TerrainGen.inst.terrainPixelsPreview;
		foreach (int modifiedPreviewVertex in modifiedPreviewVertices)
		{
			if (modifiedPreviewVertex >= 0 && modifiedPreviewVertex < terrainPixelsPreview.Length)
			{
				terrainPixelsPreview[modifiedPreviewVertex].r = 0f;
			}
		}
		modifiedPreviewVertices.Clear();
		cellTerrainDataMap.Clear();
		ApplyTerrainPreview();
	}

	public Dictionary<int, float> ApplyPreviewToActualTerrain()
	{
		Dictionary<int, float> dictionary = new Dictionary<int, float>();
		Color[] terrainPixelsPreview = TerrainGen.inst.terrainPixelsPreview;
		foreach (int modifiedPreviewVertex in modifiedPreviewVertices)
		{
			if (modifiedPreviewVertex >= 0 && modifiedPreviewVertex < terrainPixelsPreview.Length)
			{
				float vertYUnsafe = TerrainGen.inst.GetVertYUnsafe(modifiedPreviewVertex);
				float r = terrainPixelsPreview[modifiedPreviewVertex].r;
				if (r > 0f)
				{
					float y = vertYUnsafe + r;
					dictionary[modifiedPreviewVertex] = vertYUnsafe;
					TerrainGen.inst.SetVert(modifiedPreviewVertex, y, bakeDown: true);
				}
			}
		}
		TerrainGen.inst.UpdateTerrainDeformations();
		ClearAllTerrainPreview();
		return dictionary;
	}

	private bool CellStillHasDamBlocks(Cell cell, Building excludeBuilding)
	{
		foreach (Building item in cell.OccupyingStructure)
		{
			if (!(item == excludeBuilding) && item.uniqueNameHash == World.damHash)
			{
				return true;
			}
		}
		foreach (BuildingDescriptionDamPlanning item2 in buildingsToAdd)
		{
			if (item2.uniqueNameHash == World.damHash)
			{
				Cell cellData = World.inst.GetCellData(item2.position);
				if (cellData != null && cellData.index == cell.index)
				{
					return true;
				}
			}
		}
		return false;
	}

	public void ComputeTerrainModifications(out int[] vertexIndices, out float[] originalHeights, out float[] newHeights)
	{
		List<int> list = new List<int>();
		List<float> list2 = new List<float>();
		List<float> list3 = new List<float>();
		Color[] terrainPixelsPreview = TerrainGen.inst.terrainPixelsPreview;
		foreach (int modifiedPreviewVertex in modifiedPreviewVertices)
		{
			if (modifiedPreviewVertex >= 0 && modifiedPreviewVertex < terrainPixelsPreview.Length)
			{
				float vertYUnsafe = TerrainGen.inst.GetVertYUnsafe(modifiedPreviewVertex);
				float r = terrainPixelsPreview[modifiedPreviewVertex].r;
				if (r > 0f)
				{
					list.Add(modifiedPreviewVertex);
					list2.Add(vertYUnsafe);
					list3.Add(vertYUnsafe + r);
				}
			}
		}
		vertexIndices = list.ToArray();
		originalHeights = list2.ToArray();
		newHeights = list3.ToArray();
	}

	private float GetLowestDamBottomInCell(Cell cell, Building excludeBuilding)
	{
		float num = float.MaxValue;
		foreach (Building item in cell.OccupyingStructure)
		{
			if (!(item == excludeBuilding) && item.uniqueNameHash == World.damHash && item.transform.position.y < num)
			{
				num = item.transform.position.y;
			}
		}
		Building[] array = GameUI.inst.CurrPlacementMode?.buildingMap;
		if (array != null)
		{
			Building building = array[cell.index];
			if (building != null && building != excludeBuilding && building.uniqueNameHash == World.damHash && building.transform.position.y < num)
			{
				num = building.transform.position.y;
			}
		}
		return num;
	}
}
