using System;
using System.Collections.Generic;
using System.Linq;
using Code;
using Drawing;
using I2.Loc;
using Unity.Collections;
using UnityEngine;

public class EditTerrainCursorMode : CursorMode
{
	private struct RockSpan
	{
		public float bottom;

		public float top;
	}

	private struct UndoVertState
	{
		public float height;

		public bool firstModifiedThisEdit;
	}

	private enum TerrainEditError
	{
		None,
		OccupiedByBuilding,
		InOcean,
		NotOwnedByPlayer,
		WrongLandmass,
		MapEdge
	}

	private GameObject sphere;

	private float[] originalHeightsCache;

	public int currentTool;

	public int brushSize = 1;

	public bool mapEditorMode;

	private bool mouseDown;

	public bool TryingToQuit;

	private int _rockDirtyMinX;

	private int _rockDirtyMaxX;

	private int _rockDirtyMinZ;

	private int _rockDirtyMaxZ;

	private bool _rockDirtyValid;

	private int _lastActiveTool = -1;

	private Dictionary<int, RockSpan> _rockSpanCache = new Dictionary<int, RockSpan>();

	private Dictionary<int, int> modifiedVerts = new Dictionary<int, int>();

	private Stack<Dictionary<int, UndoVertState>> undoQueue = new Stack<Dictionary<int, UndoVertState>>();

	private Dictionary<int, UndoVertState> currentUndo = new Dictionary<int, UndoVertState>();

	private static float[] preGenIdsHeights;

	private float summationOfDirt;

	private float summationOfWork;

	private Vector3 manipPos;

	private int indexForManipulation = -1;

	private Color originalColor = new Color(1f, 1f, 1f, 0.5f);

	private Color errorColor = new Color(1f, 0f, 0f, 0.5f);

	private Color primaryColor = new Color(1f, 1f, 1f, 0.5f);

	private Color secondaryColor = new Color(0.2f, 0.2f, 1f, 0.5f);

	private int? lockedLandmass;

	private bool inited;

	private Timer showErrorTimer = new Timer(1f)
	{
		Enabled = false
	};

	private string errorMessage = string.Empty;

	private CommandBuilder _drawCmd;

	private Camera[] _drawCameraTargets = new Camera[1];

	public Action onStrokeCommitted;

	private static TerrainType[] preFieldTypes;

	private static bool[] preFieldDeep;

	private static bool[] preFieldOcean;

	private static int[] preFieldTrees;

	private static int[] preFieldScatter;

	private static bool[] preFieldFish;

	private static int[] preFieldLm;

	private int fineAdjustBrushSize;

	private float[] fineAdjustBases;

	private float fineAdjustAxisAnchorY;

	private int lastIndex;

	private Vector2 mouseDownPosition;

	private bool applied;

	private int x;

	private int z;

	private bool dragLocked;

	private bool tileToolHasPendingUndo;

	private int tileToolLastAppliedIndex;

	private bool tileToolHasLastApplied;

	private const float RaiseLowerEps = 0.001f;

	public bool updateWork;

	private float[] _smoothingBuffer;

	private float[] _raiseLowerTargets;

	private bool[] _raiseLowerValid;

	private Tuple<int, int>[][] _vertBrushVertDirections;

	private static readonly Tuple<int, int>[] _singleVertShape = new Tuple<int, int>[1] { Tuple.Create(0, 0) };

	private float MinTerrainHeight
	{
		get
		{
			if (!mapEditorMode)
			{
				return Water.inst.transform.position.y + 0.3f;
			}
			return TerrainGen.waterHeightDeep;
		}
	}

	public bool CanUndo => undoQueue.Count > 0;

	public override bool DoSecondaryClick()
	{
		return true;
	}

	public void SetOriginalHeightsCache(float[] heights)
	{
		originalHeightsCache = heights;
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
		sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
		sphere.transform.localScale = new Vector3(0.1f, 0.1f, 0.1f);
		sphere.gameObject.SetActive(value: false);
		summationOfDirt = 0f;
		summationOfWork = 0f;
		modifiedVerts.Clear();
		_rockSpanCache.Clear();
		lockedLandmass = null;
		if (!inited && !mapEditorMode)
		{
			SetUIVisible(v: false);
		}
		inited = true;
	}

	public override bool ShowDragSelectBounds()
	{
		return false;
	}

	public override bool ShowCellHighlighter()
	{
		return false;
	}

	public override void HandlePrimaryDown()
	{
	}

	public override void HandlePrimaryUp()
	{
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		base.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		return true;
	}

	public override void Shutdown()
	{
		FlushRockReclassification();
		InWorldExclamation.hideForCursorMode = false;
		base.Shutdown();
		UnityEngine.Object.Destroy(sphere);
		if (inited)
		{
			if (!mapEditorMode)
			{
				SetUIVisible(v: true);
			}
			inited = false;
		}
	}

	public string SetBuildInfo(BuildInfoUI buildInfoUI)
	{
		buildInfoUI.cursorMainImage.gameObject.SetActive(value: false);
		switch (currentTool)
		{
		case 0:
			buildInfoUI.cursorTitle.SetText(LocalizationManager.GetTranslation("TerrainPlanningMultiToolUp"));
			buildInfoUI.buildDescText.SetText(LocalizationManager.GetTranslation("TerrainPlanningMultiToolUpDesc"));
			break;
		case 1:
			buildInfoUI.cursorTitle.SetText(LocalizationManager.GetTranslation("TerrainPlanningMultiToolDown"));
			buildInfoUI.buildDescText.SetText(LocalizationManager.GetTranslation("TerrainPlanningMultiToolDownDesc"));
			break;
		case 2:
			buildInfoUI.cursorTitle.SetText(LocalizationManager.GetTranslation("TerrainPlanningSmoothLift"));
			buildInfoUI.buildDescText.SetText(LocalizationManager.GetTranslation("TerrainPlanningSmoothLiftDesc"));
			break;
		case 3:
			buildInfoUI.cursorTitle.SetText(LocalizationManager.GetTranslation("TerrainPlanningSmoothLower"));
			buildInfoUI.buildDescText.SetText(LocalizationManager.GetTranslation("TerrainPlanningSmoothLowerDesc"));
			break;
		case 4:
			buildInfoUI.cursorTitle.SetText(LocalizationManager.GetTranslation("TerrainPlanningSquareFlattenTool"));
			buildInfoUI.buildDescText.SetText(LocalizationManager.GetTranslation("TerrainPlanningSquareFlattenToolDesc"));
			break;
		case 5:
			buildInfoUI.cursorTitle.SetText(LocalizationManager.GetTranslation("TerrainPlanningSquareFineAjustmentTool"));
			buildInfoUI.buildDescText.SetText(LocalizationManager.GetTranslation("TerrainPlanningSquareFineAjustmentToolDesc"));
			break;
		case 6:
			buildInfoUI.cursorTitle.SetText(LocalizationManager.GetTranslation("TerrainPlanningSmoothTool"));
			buildInfoUI.buildDescText.SetText(LocalizationManager.GetTranslation("TerrainPlanningSmoothToolDesc"));
			break;
		case 7:
			buildInfoUI.cursorTitle.SetText(LocalizationManager.GetTranslation("TerrainPlanningRestoreTool"));
			buildInfoUI.buildDescText.SetText(LocalizationManager.GetTranslation("TerrainPlanningRestoreToolDesc"));
			break;
		}
		if (!showErrorTimer.Enabled)
		{
			return "";
		}
		return errorMessage;
	}

	public override void Tick(float dt)
	{
		if (currentTool != _lastActiveTool)
		{
			FlushRockReclassification();
			_lastActiveTool = currentTool;
		}
		if (!GameUI.inst.PointerOverUI())
		{
			mouseDown = PointingSystem.GetPointer().GetPrimaryDownThisFrame();
			HideError();
			primaryColor = originalColor;
			_drawCameraTargets[0] = Cam.inst.cam;
			_drawCmd = DrawingManager.GetBuilder(renderInGame: true);
			_drawCmd.cameraTargets = _drawCameraTargets;
			if (currentTool == 0)
			{
				UpdateTileTool(up: true, soft: false);
			}
			if (currentTool == 1)
			{
				UpdateTileTool(up: false, soft: false);
			}
			if (currentTool == 2)
			{
				UpdateTileTool(up: true, soft: true);
			}
			if (currentTool == 3)
			{
				UpdateTileTool(up: false, soft: true);
			}
			if (currentTool == 4)
			{
				UpdateFlattenTool();
			}
			if (currentTool == 5)
			{
				UpdateSmoothElevationTool();
			}
			if (currentTool == 6)
			{
				UpdateSmoothingTool();
			}
			if (currentTool == 7)
			{
				UpdateRestoreTool();
			}
			_drawCmd.Dispose();
			if (!mapEditorMode && Input.GetKeyDown(KeyCode.Z) && (Input.GetKey(KeyCode.RightControl) || Input.GetKey(KeyCode.LeftControl)))
			{
				PerformUndo();
			}
		}
	}

	private void CommitStroke()
	{
		if (mapEditorMode && currentUndo.Count > 0)
		{
			Water.UpdateNeeded = true;
		}
		if (mapEditorMode)
		{
			SculptCasualtyLog.Clear();
			SculptCasualtyLog.CaptureWater();
			SnapshotCellFields();
			FlushRockReclassification();
		}
		if (StrokeCrossesSeaLevel(currentUndo))
		{
			ApplySeaLevelReclassification(currentUndo);
		}
		if (mapEditorMode && currentUndo.Count > 0)
		{
			List<SculptCasualtyLog.RecarvedSpring> list = MapSelectionTool.RecarveSpringsTouchedByStroke(currentUndo.Keys);
			SculptCasualtyLog.recarvedSprings.AddRange(list);
			int num = int.MaxValue;
			int num2 = int.MaxValue;
			int num3 = int.MinValue;
			int num4 = int.MinValue;
			foreach (SculptCasualtyLog.RecarvedSpring item in list)
			{
				if (item.preRecord != null)
				{
					int[] verts = item.preRecord.verts;
					foreach (int num5 in verts)
					{
						int b = num5 % World.MeshWidth;
						int b2 = num5 / World.MeshWidth;
						num = Mathf.Min(num, b);
						num3 = Mathf.Max(num3, b);
						num2 = Mathf.Min(num2, b2);
						num4 = Mathf.Max(num4, b2);
					}
				}
			}
			if (num3 >= num)
			{
				SnapshotHeights();
				World.inst.SinkOrphanVerts(num - 1, num2 - 1, num3 + 1, num4 + 1);
				FoldHeightChangesIntoStroke(currentUndo);
			}
		}
		if (mapEditorMode)
		{
			DiffCellFieldsIntoLog();
		}
		undoQueue.Push(currentUndo);
		currentUndo = new Dictionary<int, UndoVertState>();
		if (mapEditorMode)
		{
			onStrokeCommitted?.Invoke();
		}
	}

	private void SnapshotCellFields()
	{
		int gridWidth = World.inst.GridWidth;
		int num = gridWidth * World.inst.GridHeight;
		if (preFieldTypes == null || preFieldTypes.Length != num)
		{
			preFieldTypes = new TerrainType[num];
			preFieldDeep = new bool[num];
			preFieldOcean = new bool[num];
			preFieldTrees = new int[num];
			preFieldScatter = new int[num];
			preFieldFish = new bool[num];
			preFieldLm = new int[num];
		}
		for (int i = 0; i < num; i++)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i % gridWidth, i / gridWidth);
			preFieldTypes[i] = cellDataUnsafe.Type;
			preFieldDeep[i] = cellDataUnsafe.deepWater;
			preFieldOcean[i] = cellDataUnsafe.partOfOcean;
			preFieldTrees[i] = World.inst.treeSystem.ItemAmount(cellDataUnsafe);
			preFieldScatter[i] = World.inst.rockScatterSystem.ItemAmount(cellDataUnsafe);
			FishSystem.FishCell fishCell = FishSystem.inst.fishCells[i];
			preFieldFish[i] = fishCell.owners.Count > 0 || fishCell.baseProbability >= 0.99f;
			preFieldLm[i] = cellDataUnsafe.landMassIdx;
		}
	}

	private void DiffCellFieldsIntoLog()
	{
		if (preFieldTypes == null)
		{
			return;
		}
		int gridWidth = World.inst.GridWidth;
		int num = gridWidth * World.inst.GridHeight;
		for (int i = 0; i < num; i++)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i % gridWidth, i / gridWidth);
			FishSystem.FishCell fishCell = FishSystem.inst.fishCells[i];
			bool flag = fishCell.owners.Count > 0 || fishCell.baseProbability >= 0.99f;
			if (cellDataUnsafe.Type != preFieldTypes[i] || cellDataUnsafe.deepWater != preFieldDeep[i] || cellDataUnsafe.partOfOcean != preFieldOcean[i] || cellDataUnsafe.landMassIdx != preFieldLm[i] || World.inst.treeSystem.ItemAmount(cellDataUnsafe) != preFieldTrees[i] || World.inst.rockScatterSystem.ItemAmount(cellDataUnsafe) != preFieldScatter[i] || flag != preFieldFish[i])
			{
				SculptCasualtyLog.cellChanges.Add(new SculptCasualtyLog.CellFieldChange
				{
					index = i,
					type = preFieldTypes[i],
					deepWater = preFieldDeep[i],
					ocean = preFieldOcean[i],
					trees = preFieldTrees[i],
					scatter = preFieldScatter[i],
					fish = preFieldFish[i],
					landmass = preFieldLm[i]
				});
			}
		}
	}

	public void BeginUndoCellGuard()
	{
		SnapshotCellFields();
	}

	public void RevertUnownedFields(HashSet<int> owned)
	{
		if (preFieldTypes == null)
		{
			return;
		}
		int gridWidth = World.inst.GridWidth;
		int num = gridWidth * World.inst.GridHeight;
		for (int i = 0; i < num; i++)
		{
			if (!owned.Contains(i))
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i % gridWidth, i / gridWidth);
				if (cellDataUnsafe.Type != preFieldTypes[i] || cellDataUnsafe.deepWater != preFieldDeep[i] || cellDataUnsafe.partOfOcean != preFieldOcean[i])
				{
					cellDataUnsafe.Type = preFieldTypes[i];
					cellDataUnsafe.deepWater = preFieldDeep[i];
					cellDataUnsafe.partOfOcean = preFieldOcean[i];
					cellDataUnsafe.StorePostGenerationType();
				}
			}
		}
	}

	public void ReassertUnownedLandmass(HashSet<int> owned)
	{
		if (preFieldLm == null)
		{
			return;
		}
		int gridWidth = World.inst.GridWidth;
		int num = gridWidth * World.inst.GridHeight;
		for (int i = 0; i < num; i++)
		{
			if (!owned.Contains(i))
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i % gridWidth, i / gridWidth);
				if (cellDataUnsafe.landMassIdx != preFieldLm[i])
				{
					cellDataUnsafe.landMassIdx = preFieldLm[i];
				}
			}
		}
	}

	public void RevertUnownedItems(HashSet<int> owned)
	{
		if (preFieldTypes == null)
		{
			return;
		}
		int gridWidth = World.inst.GridWidth;
		int num = gridWidth * World.inst.GridHeight;
		for (int i = 0; i < num; i++)
		{
			if (owned.Contains(i))
			{
				continue;
			}
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i % gridWidth, i / gridWidth);
			if (World.inst.treeSystem.ItemAmount(cellDataUnsafe) != preFieldTrees[i])
			{
				World.inst.treeSystem.DeleteTreesAt(cellDataUnsafe);
				for (int j = 0; j < preFieldTrees[i]; j++)
				{
					World.inst.treeSystem.PlaceItem(cellDataUnsafe, ignoreWater: true, allowOnMountains: true);
				}
			}
			if (World.inst.rockScatterSystem.ItemAmount(cellDataUnsafe) != preFieldScatter[i])
			{
				World.inst.rockScatterSystem.DeleteTreesAt(cellDataUnsafe);
				for (int k = 0; k < preFieldScatter[i]; k++)
				{
					World.inst.rockScatterSystem.PlaceItem(cellDataUnsafe, ignoreWater: true, allowOnMountains: true);
				}
			}
			FishSystem.FishCell fishCell = FishSystem.inst.fishCells[i];
			if ((fishCell.owners.Count > 0 || fishCell.baseProbability >= 0.99f) != preFieldFish[i])
			{
				if (preFieldFish[i])
				{
					FishSystem.inst.ForceFish(i % gridWidth, i / gridWidth);
				}
				else
				{
					FishSystem.inst.ForceClearFish(i % gridWidth, i / gridWidth);
				}
			}
		}
	}

	private bool StrokeCrossesSeaLevel(Dictionary<int, UndoVertState> stroke)
	{
		if (!mapEditorMode)
		{
			return false;
		}
		float y = Water.inst.transform.position.y;
		foreach (KeyValuePair<int, UndoVertState> item in stroke)
		{
			float height = item.Value.height;
			float vertYUnsafe = TerrainGen.inst.GetVertYUnsafe(item.Key);
			if (height < y != vertYUnsafe < y)
			{
				return true;
			}
		}
		return false;
	}

	private void SnapshotHeights()
	{
		float[] heightCache = TerrainGen.inst.heightCache;
		if (preGenIdsHeights == null || preGenIdsHeights.Length != heightCache.Length)
		{
			preGenIdsHeights = new float[heightCache.Length];
		}
		Array.Copy(heightCache, preGenIdsHeights, heightCache.Length);
	}

	private void FoldHeightChangesIntoStroke(Dictionary<int, UndoVertState> stroke)
	{
		float[] heightCache = TerrainGen.inst.heightCache;
		for (int i = 0; i < heightCache.Length; i++)
		{
			if (heightCache[i] != preGenIdsHeights[i] && !stroke.ContainsKey(i))
			{
				stroke[i] = new UndoVertState
				{
					height = preGenIdsHeights[i],
					firstModifiedThisEdit = false
				};
			}
		}
	}

	private void ApplySeaLevelReclassification(Dictionary<int, UndoVertState> stroke, bool undoing = false)
	{
		Water.UpdateNeeded = true;
		int num = int.MaxValue;
		int num2 = int.MaxValue;
		int num3 = int.MinValue;
		int num4 = int.MinValue;
		foreach (int key in stroke.Keys)
		{
			int num5 = key % World.MeshWidth;
			int num6 = key / World.MeshWidth;
			if (num5 < num)
			{
				num = num5;
			}
			if (num5 > num3)
			{
				num3 = num5;
			}
			if (num6 < num2)
			{
				num2 = num6;
			}
			if (num6 > num4)
			{
				num4 = num6;
			}
		}
		if (num3 >= num)
		{
			SculptCasualtyLog.Clear();
			SculptCasualtyLog.armed = true;
			bool flag = World.inst.ReclassifyLandWaterFromHeights(num / 2 - 1, num2 / 2 - 1, num3 / 2 + 1, num4 / 2 + 1);
			SculptCasualtyLog.armed = false;
			MapSelectionTool.DrownSpringsBelowWater();
			SnapshotHeights();
			World.inst.GenerateLandMassIds(!undoing, !undoing);
			if (!undoing)
			{
				World.inst.SinkOrphanVerts(num - 4, num2 - 4, num3 + 4, num4 + 4);
			}
			FoldHeightChangesIntoStroke(stroke);
			TerrainGen.inst.RefreshCellLandmassCache();
			MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
			if (flag)
			{
				World.inst.ShowResourceGroupTooltipUIs(-1, doShowFish: true);
			}
		}
	}

	public void PerformUndo()
	{
		if (undoQueue.Count > 0)
		{
			Dictionary<int, UndoVertState> dictionary = undoQueue.Pop();
			if (mapEditorMode && dictionary.Count > 0)
			{
				Water.UpdateNeeded = true;
			}
			bool flag = StrokeCrossesSeaLevel(dictionary);
			foreach (int key in dictionary.Keys)
			{
				TerrainGen.inst.SetVert(key % World.MeshWidth, key / World.MeshWidth, dictionary[key].height, bakeDown: true);
				MarkRockDirtyVert(key % World.MeshWidth, key / World.MeshWidth);
				if (dictionary[key].firstModifiedThisEdit)
				{
					modifiedVerts.Remove(key);
				}
			}
			if (mapEditorMode && dictionary.Count > 0)
			{
				DynamicWater.inst.dynamicWaterJobHandle.Complete();
				NativeArray<DynamicWater.WaterCell> waterGrid = DynamicWater.inst.waterGrid;
				foreach (int key2 in dictionary.Keys)
				{
					DynamicWater.WaterCell value = waterGrid[key2];
					if (!(value.waterAmount <= 0f) && !(value.waterProductionRate > 0f))
					{
						value.waterAmount = 0f;
						value.flux0 = (value.flux1 = (value.flux2 = (value.flux3 = 0f)));
						waterGrid[key2] = value;
					}
				}
			}
			if (mapEditorMode)
			{
				FlushRockObstructionOnly();
			}
			else
			{
				FlushRockReclassification();
			}
			if (flag)
			{
				ApplySeaLevelReclassification(dictionary, undoing: true);
			}
		}
		if (modifiedVerts.Count == 0)
		{
			lockedLandmass = null;
		}
		CalculateWork();
		updateWork = true;
		FlushRockReclassification();
	}

	private void UpdateSmoothElevationTool()
	{
		if (indexForManipulation == -1)
		{
			Ray ray = PointingSystem.GetRay();
			if (Physics.Raycast(ray, out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
			{
				Vector3 point = ray.GetPoint(hitInfo.distance);
				int num = SnapBrushCursor(brushSize, point.x);
				int num2 = SnapBrushCursor(brushSize, point.z);
				int num3 = (brushSize - 1) / 2;
				int num4 = -num3;
				int num5 = brushSize - 1 - num3;
				Tuple<int, int>[] vertBrushVertDirections = GetVertBrushVertDirections(brushSize);
				int index = num + num2 * World.MeshWidth;
				float num6 = (float)(num4 + num5) * 0.5f;
				float num7 = ((float)num + num6) / 2f;
				float num8 = ((float)num2 + num6) / 2f;
				Vector3 vector = new Vector3(num7, TerrainGen.inst.GetVertYUnsafe(index), num8);
				HandleTerrainEditError(CheckTerrainEditValid(index, vertBrushVertDirections));
				using (_drawCmd.WithColor(primaryColor))
				{
					_drawCmd.SolidCircle(vector, Vector3.up, 0.1f);
					_drawCmd.Arrow(vector, vector + Vector3.up * 0.5f, Vector3.up, 0.1f);
					_drawCmd.Arrow(vector, vector + Vector3.down * 0.5f, Vector3.up, 0.1f);
					if (brushSize > 1)
					{
						DrawFineAdjustPerimeter(num, num2, num4, num5, 0f, useBases: false);
					}
				}
				if (mouseDown && AnyVertValid(index, vertBrushVertDirections))
				{
					indexForManipulation = index;
					manipPos = vector;
					Vector3 linePoint = new Vector3(num7, 0f, num8);
					if (Mathff.ClosestPointsOnTwoLines(out var closestPointLine, out var _, linePoint, Vector3.up, Cam.inst.CamPos, ray.direction))
					{
						fineAdjustAxisAnchorY = closestPointLine.y;
					}
					else
					{
						fineAdjustAxisAnchorY = vector.y;
					}
					fineAdjustBrushSize = brushSize;
					int num9 = num5 - num4 + 1;
					int num10 = num9 * num9;
					if (fineAdjustBases == null || fineAdjustBases.Length < num10)
					{
						fineAdjustBases = new float[num10];
					}
					for (int i = num4; i <= num5; i++)
					{
						for (int j = num4; j <= num5; j++)
						{
							int num11 = (i - num4) * num9 + (j - num4);
							fineAdjustBases[num11] = TerrainGen.inst.GetVertY(num + i, num2 + j);
						}
					}
				}
			}
		}
		if (indexForManipulation == -1)
		{
			return;
		}
		int num12 = fineAdjustBrushSize;
		int num13 = (num12 - 1) / 2;
		int num14 = -num13;
		int num15 = num12 - 1 - num13;
		int num16 = num15 - num14 + 1;
		Tuple<int, int>[] vertBrushVertDirections2 = GetVertBrushVertDirections(num12);
		int num17 = indexForManipulation % World.MeshWidth;
		int num18 = indexForManipulation / World.MeshWidth;
		if (!mouseDown)
		{
			if (currentUndo.Count > 0)
			{
				FreezeChangesAndCalculateWork(indexForManipulation, vertBrushVertDirections2);
				CommitStroke();
			}
			indexForManipulation = -1;
			sphere.SetActive(value: false);
			FlushRockReclassification();
			return;
		}
		HandleTerrainEditError(CheckTerrainEditValid(indexForManipulation, vertBrushVertDirections2));
		Ray ray2 = PointingSystem.GetRay();
		if (!Mathff.ClosestPointsOnTwoLines(out var closestPointLine3, out var _, manipPos, Vector3.up, Cam.inst.CamPos, ray2.direction))
		{
			return;
		}
		float num19 = closestPointLine3.y - fineAdjustAxisAnchorY;
		float y = manipPos.y + num19;
		Vector3 vector2 = new Vector3(closestPointLine3.x, y, closestPointLine3.z);
		using (_drawCmd.WithColor(primaryColor))
		{
			_drawCmd.SolidCircle(vector2, Vector3.up, 0.1f);
			_drawCmd.Arrow(vector2, vector2 + Vector3.up * 0.5f, Vector3.up, 0.1f);
			_drawCmd.Arrow(vector2, vector2 + Vector3.down * 0.5f, Vector3.up, 0.1f);
			if (num12 > 1)
			{
				DrawFineAdjustPerimeter(num17, num18, num14, num15, num19, useBases: true);
			}
		}
		using (_drawCmd.WithColor(secondaryColor))
		{
			using (_drawCmd.WithLineWidth(3f))
			{
				_drawCmd.Circle(manipPos, Vector3.up, 0.15f);
			}
		}
		if (!AnyVertValid(indexForManipulation, vertBrushVertDirections2))
		{
			return;
		}
		bool flag = false;
		for (int k = num14; k <= num15; k++)
		{
			for (int l = num14; l <= num15; l++)
			{
				int num20 = (k - num14) * num16 + (l - num14);
				int num21 = num17 + k;
				int num22 = num18 + l;
				int index2 = num21 + num22 * World.MeshWidth;
				if (CheckSingleVertValid(num21, num22) == TerrainEditError.None)
				{
					if (!flag)
					{
						TryLockLandmass(index2, _singleVertShape);
						flag = true;
					}
					TrackUndoVerts(index2, _singleVertShape);
					float target = Mathf.Max(fineAdjustBases[num20] + num19, MinTerrainHeight);
					TerrainGen.inst.SetVert(num21, num22, ClampToRockBed(num21, num22, target), bakeDown: true);
				}
			}
		}
		FreezeChangesAndCalculateWork(indexForManipulation, vertBrushVertDirections2);
	}

	private void DrawFineAdjustPerimeter(int cx, int cz, int vertDxMin, int vertDxMax, float distance, bool useBases)
	{
		int num = vertDxMax - vertDxMin + 1;
		if (_raiseLowerTargets == null || _raiseLowerTargets.Length < num * num)
		{
			_raiseLowerTargets = new float[num * num];
		}
		if (_raiseLowerValid == null || _raiseLowerValid.Length < num * num)
		{
			_raiseLowerValid = new bool[num * num];
		}
		for (int i = vertDxMin; i <= vertDxMax; i++)
		{
			for (int j = vertDxMin; j <= vertDxMax; j++)
			{
				int num2 = cx + i;
				int num3 = cz + j;
				bool flag = CheckSingleVertValid(num2, num3) == TerrainEditError.None;
				float num5;
				if (useBases)
				{
					int num4 = (i - vertDxMin) * num + (j - vertDxMin);
					num5 = (flag ? Mathf.Max(fineAdjustBases[num4] + distance, MinTerrainHeight) : TerrainGen.inst.GetVertY(num2, num3));
				}
				else
				{
					num5 = TerrainGen.inst.GetVertY(num2, num3);
				}
				int num6 = (i - vertDxMin) * num + (j - vertDxMin);
				_raiseLowerTargets[num6] = num5 + 0.0001f;
				_raiseLowerValid[num6] = flag;
			}
		}
		int num7 = 0;
		int num8 = num - 1;
		for (int k = vertDxMin; k < vertDxMax; k++)
		{
			int num9 = (k - vertDxMin) * num + num7;
			int num10 = (k + 1 - vertDxMin) * num + num7;
			float num11 = (float)(cz + vertDxMin) / 2f;
			Vector3 a = new Vector3((float)(cx + k) / 2f, _raiseLowerTargets[num9], num11);
			Vector3 b = new Vector3((float)(cx + k + 1) / 2f, _raiseLowerTargets[num10], num11);
			bool flag2 = _raiseLowerValid[num9] && _raiseLowerValid[num10];
			using (_drawCmd.WithColor(flag2 ? originalColor : errorColor))
			{
				_drawCmd.Line(a, b);
			}
		}
		for (int l = vertDxMin; l < vertDxMax; l++)
		{
			int num12 = (l - vertDxMin) * num + num8;
			int num13 = (l + 1 - vertDxMin) * num + num8;
			float num14 = (float)(cz + vertDxMax) / 2f;
			Vector3 a2 = new Vector3((float)(cx + l) / 2f, _raiseLowerTargets[num12], num14);
			Vector3 b2 = new Vector3((float)(cx + l + 1) / 2f, _raiseLowerTargets[num13], num14);
			bool flag3 = _raiseLowerValid[num12] && _raiseLowerValid[num13];
			using (_drawCmd.WithColor(flag3 ? originalColor : errorColor))
			{
				_drawCmd.Line(a2, b2);
			}
		}
		for (int m = vertDxMin; m < vertDxMax; m++)
		{
			int num15 = num7 * num + (m - vertDxMin);
			int num16 = num7 * num + (m + 1 - vertDxMin);
			float num17 = (float)(cx + vertDxMin) / 2f;
			Vector3 a3 = new Vector3(num17, _raiseLowerTargets[num15], (float)(cz + m) / 2f);
			Vector3 b3 = new Vector3(num17, _raiseLowerTargets[num16], (float)(cz + m + 1) / 2f);
			bool flag4 = _raiseLowerValid[num15] && _raiseLowerValid[num16];
			using (_drawCmd.WithColor(flag4 ? originalColor : errorColor))
			{
				_drawCmd.Line(a3, b3);
			}
		}
		for (int n = vertDxMin; n < vertDxMax; n++)
		{
			int num18 = num8 * num + (n - vertDxMin);
			int num19 = num8 * num + (n + 1 - vertDxMin);
			float num20 = (float)(cx + vertDxMax) / 2f;
			Vector3 a4 = new Vector3(num20, _raiseLowerTargets[num18], (float)(cz + n) / 2f);
			Vector3 b4 = new Vector3(num20, _raiseLowerTargets[num19], (float)(cz + n + 1) / 2f);
			bool flag5 = _raiseLowerValid[num18] && _raiseLowerValid[num19];
			using (_drawCmd.WithColor(flag5 ? originalColor : errorColor))
			{
				_drawCmd.Line(a4, b4);
			}
		}
	}

	private void UpdateFlattenTool()
	{
		if (indexForManipulation == -1)
		{
			Ray ray = PointingSystem.GetRay();
			if (Physics.Raycast(ray, out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
			{
				Vector3 point = ray.GetPoint(hitInfo.distance);
				int num = SnapBrushCursor(brushSize, point.x);
				int num2 = SnapBrushCursor(brushSize, point.z);
				int index = num + num2 * World.MeshWidth;
				int num3 = (brushSize - 1) / 2;
				int num4 = -num3;
				int num5 = brushSize - 1 - num3;
				Tuple<int, int>[] vertBrushVertDirections = GetVertBrushVertDirections(brushSize);
				HandleTerrainEditError(CheckTerrainEditValid(index, vertBrushVertDirections));
				Vector3 vector = new Vector3((float)num / 2f, TerrainGen.inst.GetVertYUnsafe(index), (float)num2 / 2f);
				using (_drawCmd.WithColor(primaryColor))
				{
					if (brushSize > 1)
					{
						float num6 = (float)(num + num4) / 2f;
						float num7 = (float)(num2 + num4) / 2f;
						float num8 = (float)(num + num5) / 2f;
						float num9 = (float)(num2 + num5) / 2f;
						Vector3 vector2 = new Vector3(num6, vector.y, num7);
						Vector3 vector3 = new Vector3(num8, vector.y, num7);
						Vector3 vector4 = new Vector3(num8, vector.y, num9);
						Vector3 vector5 = new Vector3(num6, vector.y, num9);
						_drawCmd.DashedLine(vector2, vector3, 0.05f, 0.05f);
						_drawCmd.DashedLine(vector3, vector4, 0.05f, 0.05f);
						_drawCmd.DashedLine(vector4, vector5, 0.05f, 0.05f);
						_drawCmd.DashedLine(vector5, vector2, 0.05f, 0.05f);
						_drawCmd.Arrow((vector2 + vector3) / 2f, (vector2 + vector3) / 2f + Vector3.back * 0.5f, Vector3.up, 0.1f);
						_drawCmd.Arrow((vector3 + vector4) / 2f, (vector3 + vector4) / 2f + Vector3.right * 0.5f, Vector3.up, 0.1f);
						_drawCmd.Arrow((vector4 + vector5) / 2f, (vector4 + vector5) / 2f + Vector3.forward * 0.5f, Vector3.up, 0.1f);
						_drawCmd.Arrow((vector5 + vector2) / 2f, (vector5 + vector2) / 2f + Vector3.left * 0.5f, Vector3.up, 0.1f);
					}
					else
					{
						_drawCmd.SolidCircle(vector, Vector3.up, 0.1f);
						_drawCmd.Arrow(vector, vector + Vector3.back * 0.5f, Vector3.up, 0.1f);
						_drawCmd.Arrow(vector, vector + Vector3.right * 0.5f, Vector3.up, 0.1f);
						_drawCmd.Arrow(vector, vector + Vector3.forward * 0.5f, Vector3.up, 0.1f);
						_drawCmd.Arrow(vector, vector + Vector3.left * 0.5f, Vector3.up, 0.1f);
					}
				}
				if (mouseDown && AnyVertValid(index, vertBrushVertDirections))
				{
					indexForManipulation = (lastIndex = index);
					manipPos = vector;
				}
			}
		}
		if (indexForManipulation == -1)
		{
			return;
		}
		if (!mouseDown)
		{
			indexForManipulation = -1;
			if (currentUndo.Count > 0)
			{
				CommitStroke();
			}
			FlushRockReclassification();
			return;
		}
		Plane plane = new Plane(Vector3.up, manipPos);
		Ray ray2 = PointingSystem.GetRay();
		plane.Raycast(ray2, out var enter);
		Vector3 point2 = ray2.GetPoint(enter);
		int num10 = Mathf.Clamp(SnapBrushCursor(brushSize, point2.x), 0, World.MeshWidth - 1);
		int num11 = Mathf.Clamp(SnapBrushCursor(brushSize, point2.z), 0, World.MeshHeight - 1);
		int num12 = num10 + num11 * World.MeshWidth;
		int num13 = (brushSize - 1) / 2;
		int num14 = -num13;
		int num15 = brushSize - 1 - num13;
		Tuple<int, int>[] vertBrushVertDirections2 = GetVertBrushVertDirections(brushSize);
		HandleTerrainEditError(CheckTerrainEditValid(num12, vertBrushVertDirections2));
		Vector3 vector6 = new Vector3((float)num10 / 2f, point2.y, (float)num11 / 2f);
		using (_drawCmd.WithColor(secondaryColor))
		{
			using (_drawCmd.WithLineWidth(3f))
			{
				_drawCmd.Circle(manipPos, Vector3.up, 0.15f);
			}
		}
		using (_drawCmd.WithColor(primaryColor))
		{
			if (brushSize > 1)
			{
				float num16 = (float)(num10 + num14) / 2f;
				float num17 = (float)(num11 + num14) / 2f;
				float num18 = (float)(num10 + num15) / 2f;
				float num19 = (float)(num11 + num15) / 2f;
				Vector3 vector7 = new Vector3(num16, manipPos.y, num17);
				Vector3 vector8 = new Vector3(num18, manipPos.y, num17);
				Vector3 vector9 = new Vector3(num18, manipPos.y, num19);
				Vector3 vector10 = new Vector3(num16, manipPos.y, num19);
				_drawCmd.DashedLine(vector7, vector8, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector8, vector9, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector9, vector10, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector10, vector7, 0.05f, 0.05f);
				_drawCmd.Arrow((vector7 + vector8) / 2f, (vector7 + vector8) / 2f + Vector3.back * 0.5f, Vector3.up, 0.1f);
				_drawCmd.Arrow((vector8 + vector9) / 2f, (vector8 + vector9) / 2f + Vector3.right * 0.5f, Vector3.up, 0.1f);
				_drawCmd.Arrow((vector9 + vector10) / 2f, (vector9 + vector10) / 2f + Vector3.forward * 0.5f, Vector3.up, 0.1f);
				_drawCmd.Arrow((vector10 + vector7) / 2f, (vector10 + vector7) / 2f + Vector3.left * 0.5f, Vector3.up, 0.1f);
			}
			else
			{
				_drawCmd.SolidCircle(vector6, Vector3.up, 0.1f);
				_drawCmd.Arrow(vector6, vector6 + Vector3.back * 0.5f, Vector3.up, 0.1f);
				_drawCmd.Arrow(vector6, vector6 + Vector3.right * 0.5f, Vector3.up, 0.1f);
				_drawCmd.Arrow(vector6, vector6 + Vector3.forward * 0.5f, Vector3.up, 0.1f);
				_drawCmd.Arrow(vector6, vector6 + Vector3.left * 0.5f, Vector3.up, 0.1f);
			}
		}
		if (lastIndex == num12)
		{
			return;
		}
		int num20 = lastIndex;
		lastIndex = num12;
		bool flag = false;
		foreach (int item in GridLine.Walk(num20, num12, World.MeshWidth))
		{
			if (item == num20 || !AnyVertValid(item, vertBrushVertDirections2))
			{
				continue;
			}
			int num21 = item % World.MeshWidth;
			int num22 = item / World.MeshWidth;
			float target = Mathf.Max(manipPos.y, MinTerrainHeight);
			bool flag2 = false;
			for (int i = num14; i <= num15; i++)
			{
				for (int j = num14; j <= num15; j++)
				{
					int num23 = num21 + i;
					int num24 = num22 + j;
					int index2 = num23 + num24 * World.MeshWidth;
					if (CheckSingleVertValid(num23, num24) == TerrainEditError.None)
					{
						if (!flag2)
						{
							TryLockLandmass(index2, _singleVertShape);
							flag2 = true;
						}
						TrackUndoVerts(index2, _singleVertShape);
						TrackVerts(index2, _singleVertShape);
						float vertY = TerrainGen.inst.GetVertY(num23, num24);
						float num25 = ClampToRockBed(num23, num24, target);
						TerrainGen.inst.ChangeVertY(num23, num24, num25 - vertY);
					}
				}
			}
			flag = true;
		}
		if (flag)
		{
			TerrainGen.inst.UpdateTerrainDeformations();
			CalculateWork();
			updateWork = true;
		}
	}

	private void UpdateTileTool(bool up, bool soft)
	{
		if (!PointingSystem.GetPointer().GetPrimaryDownThisFrame() && tileToolHasPendingUndo)
		{
			CommitStroke();
			tileToolHasPendingUndo = false;
			FlushRockReclassification();
		}
		Ray ray = PointingSystem.GetRay();
		bool primaryDownThisFrame = PointingSystem.GetPointer().GetPrimaryDownThisFrame();
		if (primaryDownThisFrame && !dragLocked)
		{
			mouseDownPosition = Input.mousePosition;
		}
		if (dragLocked && Vector2.Distance(Input.mousePosition, mouseDownPosition) > 4f)
		{
			dragLocked = false;
		}
		if (!dragLocked && Physics.Raycast(ray, out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
		{
			Vector3 point = ray.GetPoint(hitInfo.distance);
			int num = SnapBrushCursor(brushSize, point.x);
			int num2 = SnapBrushCursor(brushSize, point.z);
			if ((num != x || num2 != z) && !dragLocked)
			{
				applied = false;
			}
			x = num;
			z = num2;
		}
		if (!primaryDownThisFrame)
		{
			applied = false;
			tileToolHasLastApplied = false;
		}
		int num3 = x + z * World.MeshWidth;
		int num4 = (brushSize - 1) / 2;
		int num5 = -num4;
		int num6 = brushSize - 1 - num4;
		Tuple<int, int>[] vertBrushVertDirections = GetVertBrushVertDirections(brushSize);
		if (primaryDownThisFrame && !applied)
		{
			applied = true;
			dragLocked = true;
			int num7 = (tileToolHasLastApplied ? tileToolLastAppliedIndex : num3);
			bool flag = false;
			foreach (int item in GridLine.Walk(num7, num3, World.MeshWidth))
			{
				if ((!tileToolHasLastApplied || item != num7) && AnyVertValid(item, vertBrushVertDirections))
				{
					int ix = item % World.MeshWidth;
					int iz = item / World.MeshWidth;
					if (soft)
					{
						ApplySoftRaiseLowerAt(ix, iz, item, up, num5, num6);
					}
					else
					{
						ApplyRaiseLowerAt(ix, iz, item, up, vertBrushVertDirections, num5, num6);
					}
					flag = true;
				}
			}
			tileToolLastAppliedIndex = num3;
			tileToolHasLastApplied = true;
			tileToolHasPendingUndo = true;
			if (flag)
			{
				TerrainGen.inst.UpdateTerrainDeformations();
				CalculateWork();
				updateWork = true;
			}
		}
		bool flag2 = false;
		float num8 = float.NegativeInfinity;
		float num9 = float.PositiveInfinity;
		for (int i = num5; i <= num6; i++)
		{
			for (int j = num5; j <= num6; j++)
			{
				int num10 = x + i;
				int num11 = z + j;
				if (CheckSingleVertValid(num10, num11) == TerrainEditError.None)
				{
					float vertY = TerrainGen.inst.GetVertY(num10, num11);
					if (vertY > num8)
					{
						num8 = vertY;
					}
					if (vertY < num9)
					{
						num9 = vertY;
					}
					flag2 = true;
				}
			}
		}
		bool hasStraggler = flag2 && num8 - num9 > 0.001f;
		float cap = (up ? num8 : num9);
		float num12 = (float)(x + num5) / 2f;
		float num13 = (float)(z + num5) / 2f;
		float num14 = (float)(x + num6) / 2f;
		float num15 = (float)(z + num6) / 2f;
		float vertY2 = TerrainGen.inst.GetVertY(x + num5, z + num5);
		float vertY3 = TerrainGen.inst.GetVertY(x + num6, z + num5);
		float vertY4 = TerrainGen.inst.GetVertY(x + num6, z + num6);
		float vertY5 = TerrainGen.inst.GetVertY(x + num5, z + num6);
		bool flag3 = CheckSingleVertValid(x + num5, z + num5) == TerrainEditError.None;
		bool flag4 = CheckSingleVertValid(x + num6, z + num5) == TerrainEditError.None;
		bool flag5 = CheckSingleVertValid(x + num6, z + num6) == TerrainEditError.None;
		bool flag6 = CheckSingleVertValid(x + num5, z + num6) == TerrainEditError.None;
		Vector3 a = new Vector3(num12, vertY2, num13);
		new Vector3(num14, vertY3, num13);
		new Vector3(num14, vertY4, num15);
		new Vector3(num12, vertY5, num15);
		float y;
		float y2;
		float y3;
		float y4;
		if (soft)
		{
			float num16 = (float)(num6 - num5) / 2f;
			float num17 = num16 + 1f;
			float num18 = 1f - num16 / num17;
			float num19 = (up ? 0.0625f : (-0.0625f));
			y = (flag3 ? (vertY2 + num19 * num18) : vertY2);
			y2 = (flag4 ? (vertY3 + num19 * num18) : vertY3);
			y3 = (flag5 ? (vertY4 + num19 * num18) : vertY4);
			y4 = (flag6 ? (vertY5 + num19 * num18) : vertY5);
		}
		else
		{
			y = (flag3 ? ComputeRaiseLowerTarget(vertY2, up, hasStraggler, cap) : vertY2);
			y2 = (flag4 ? ComputeRaiseLowerTarget(vertY3, up, hasStraggler, cap) : vertY3);
			y3 = (flag5 ? ComputeRaiseLowerTarget(vertY4, up, hasStraggler, cap) : vertY4);
			y4 = (flag6 ? ComputeRaiseLowerTarget(vertY5, up, hasStraggler, cap) : vertY5);
		}
		Vector3 vector = new Vector3(num12, y, num13);
		new Vector3(num14, y2, num13);
		new Vector3(num14, y3, num15);
		new Vector3(num12, y4, num15);
		HandleTerrainEditError(CheckTerrainEditValid(num3, vertBrushVertDirections));
		using (_drawCmd.WithColor(primaryColor))
		{
			if (brushSize == 1)
			{
				Vector3 vector2 = new Vector3(num12 + 0.5f, TerrainGen.inst.GetVertY(x + 1, z), num13);
				Vector3 vector3 = new Vector3(num12 - 0.5f, TerrainGen.inst.GetVertY(x - 1, z), num13);
				Vector3 vector4 = new Vector3(num12, TerrainGen.inst.GetVertY(x, z + 1), num13 + 0.5f);
				Vector3 vector5 = new Vector3(num12, TerrainGen.inst.GetVertY(x, z - 1), num13 - 0.5f);
				_drawCmd.Line(a, vector2);
				_drawCmd.Line(a, vector3);
				_drawCmd.Line(a, vector4);
				_drawCmd.Line(a, vector5);
				_drawCmd.DashedLine(vector, vector2, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector3, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector4, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector5, 0.05f, 0.05f);
			}
			else if (soft)
			{
				int num20 = num6 - num5 + 1;
				if (_raiseLowerTargets == null || _raiseLowerTargets.Length < num20 * num20)
				{
					_raiseLowerTargets = new float[num20 * num20];
				}
				if (_raiseLowerValid == null || _raiseLowerValid.Length < num20 * num20)
				{
					_raiseLowerValid = new bool[num20 * num20];
				}
				Color color = primaryColor;
				color.a *= 0.5f;
				float num21 = (float)(num5 + num6) / 2f;
				float num22 = (float)(num6 - num5) / 2f + 1f;
				for (int k = num5; k <= num6; k++)
				{
					for (int l = num5; l <= num6; l++)
					{
						int num23 = x + k;
						int num24 = z + l;
						float vertY6 = TerrainGen.inst.GetVertY(num23, num24);
						bool flag7 = CheckSingleVertValid(num23, num24) == TerrainEditError.None;
						float a2 = Mathf.Abs((float)k - num21);
						float b = Mathf.Abs((float)l - num21);
						float num25 = Mathf.Max(a2, b);
						float num26 = 1f - num25 / num22;
						float num27 = vertY6 + 0f;
						int num28 = (k - num5) * num20 + (l - num5);
						_raiseLowerValid[num28] = flag7;
						_raiseLowerTargets[num28] = num27;
						if (flag7 && num26 > 0f)
						{
							float num29 = (float)num23 / 2f;
							float num30 = (float)num24 / 2f;
							Vector3 normal = TerrainGen.inst.GetNormal(num29, num30);
							using (_drawCmd.WithColor(color))
							{
								_drawCmd.SolidCircle(new Vector3(num29, num27, num30), normal, 0.075f * num26);
							}
						}
					}
				}
				int num31 = 0;
				int num32 = num20 - 1;
				for (int m = num5; m < num6; m++)
				{
					int num33 = (m - num5) * num20 + num31;
					int num34 = (m + 1 - num5) * num20 + num31;
					float num35 = (float)(z + num5) / 2f;
					Vector3 a3 = new Vector3((float)(x + m) / 2f, _raiseLowerTargets[num33], num35);
					Vector3 b2 = new Vector3((float)(x + m + 1) / 2f, _raiseLowerTargets[num34], num35);
					bool flag8 = _raiseLowerValid[num33] && _raiseLowerValid[num34];
					using (_drawCmd.WithColor(flag8 ? originalColor : errorColor))
					{
						_drawCmd.Line(a3, b2);
					}
				}
				for (int n = num5; n < num6; n++)
				{
					int num36 = (n - num5) * num20 + num32;
					int num37 = (n + 1 - num5) * num20 + num32;
					float num38 = (float)(z + num6) / 2f;
					Vector3 a4 = new Vector3((float)(x + n) / 2f, _raiseLowerTargets[num36], num38);
					Vector3 b3 = new Vector3((float)(x + n + 1) / 2f, _raiseLowerTargets[num37], num38);
					bool flag9 = _raiseLowerValid[num36] && _raiseLowerValid[num37];
					using (_drawCmd.WithColor(flag9 ? originalColor : errorColor))
					{
						_drawCmd.Line(a4, b3);
					}
				}
				for (int num39 = num5; num39 < num6; num39++)
				{
					int num40 = num31 * num20 + (num39 - num5);
					int num41 = num31 * num20 + (num39 + 1 - num5);
					float num42 = (float)(x + num5) / 2f;
					Vector3 a5 = new Vector3(num42, _raiseLowerTargets[num40], (float)(z + num39) / 2f);
					Vector3 b4 = new Vector3(num42, _raiseLowerTargets[num41], (float)(z + num39 + 1) / 2f);
					bool flag10 = _raiseLowerValid[num40] && _raiseLowerValid[num41];
					using (_drawCmd.WithColor(flag10 ? originalColor : errorColor))
					{
						_drawCmd.Line(a5, b4);
					}
				}
				for (int num43 = num5; num43 < num6; num43++)
				{
					int num44 = num32 * num20 + (num43 - num5);
					int num45 = num32 * num20 + (num43 + 1 - num5);
					float num46 = (float)(x + num6) / 2f;
					Vector3 a6 = new Vector3(num46, _raiseLowerTargets[num44], (float)(z + num43) / 2f);
					Vector3 b5 = new Vector3(num46, _raiseLowerTargets[num45], (float)(z + num43 + 1) / 2f);
					bool flag11 = _raiseLowerValid[num44] && _raiseLowerValid[num45];
					using (_drawCmd.WithColor(flag11 ? originalColor : errorColor))
					{
						_drawCmd.Line(a6, b5);
					}
				}
			}
			else
			{
				int num47 = num6 - num5 + 1;
				if (_raiseLowerTargets == null || _raiseLowerTargets.Length < num47 * num47)
				{
					_raiseLowerTargets = new float[num47 * num47];
				}
				if (_raiseLowerValid == null || _raiseLowerValid.Length < num47 * num47)
				{
					_raiseLowerValid = new bool[num47 * num47];
				}
				for (int num48 = num5; num48 <= num6; num48++)
				{
					for (int num49 = num5; num49 <= num6; num49++)
					{
						int num50 = x + num48;
						int num51 = z + num49;
						float vertY7 = TerrainGen.inst.GetVertY(num50, num51);
						bool flag12 = CheckSingleVertValid(num50, num51) == TerrainEditError.None;
						float num52 = (flag12 ? ComputeRaiseLowerTarget(vertY7, up, hasStraggler, cap) : vertY7);
						int num53 = (num48 - num5) * num47 + (num49 - num5);
						_raiseLowerTargets[num53] = num52;
						_raiseLowerValid[num53] = flag12;
						if (flag12 && Mathf.Abs(num52 - vertY7) > 0.001f)
						{
							float num54 = (float)num50 / 2f;
							float num55 = (float)num51 / 2f;
							_drawCmd.Line(new Vector3(num54, vertY7, num55), new Vector3(num54, num52, num55));
						}
					}
				}
				for (int num56 = num5; num56 < num6; num56++)
				{
					for (int num57 = num5; num57 <= num6; num57++)
					{
						int num58 = (num56 - num5) * num47 + (num57 - num5);
						int num59 = (num56 + 1 - num5) * num47 + (num57 - num5);
						float num60 = (float)(z + num57) / 2f;
						Vector3 a7 = new Vector3((float)(x + num56) / 2f, _raiseLowerTargets[num58], num60);
						Vector3 b6 = new Vector3((float)(x + num56 + 1) / 2f, _raiseLowerTargets[num59], num60);
						bool flag13 = _raiseLowerValid[num58] && _raiseLowerValid[num59];
						using (_drawCmd.WithColor(flag13 ? originalColor : errorColor))
						{
							_drawCmd.Line(a7, b6);
						}
					}
				}
				for (int num61 = num5; num61 <= num6; num61++)
				{
					for (int num62 = num5; num62 < num6; num62++)
					{
						int num63 = (num61 - num5) * num47 + (num62 - num5);
						int num64 = (num61 - num5) * num47 + (num62 + 1 - num5);
						float num65 = (float)(x + num61) / 2f;
						Vector3 a8 = new Vector3(num65, _raiseLowerTargets[num63], (float)(z + num62) / 2f);
						Vector3 b7 = new Vector3(num65, _raiseLowerTargets[num64], (float)(z + num62 + 1) / 2f);
						bool flag14 = _raiseLowerValid[num63] && _raiseLowerValid[num64];
						using (_drawCmd.WithColor(flag14 ? originalColor : errorColor))
						{
							_drawCmd.Line(a8, b7);
						}
					}
				}
			}
			if (soft)
			{
				float num66 = (num12 + num14) * 0.5f;
				float num67 = (num13 + num15) * 0.5f;
				float vertY8 = TerrainGen.inst.GetVertY(x, z);
				Vector3 vector6 = new Vector3(num66, vertY8, num67);
				Vector3 vector7 = vector6 + Vector3.up * 0.75f;
				if (up)
				{
					_drawCmd.Arrow(vector6, vector7, Vector3.up, 0.15f);
				}
				else
				{
					_drawCmd.Arrow(vector7, vector6, Vector3.up, 0.15f);
				}
			}
		}
	}

	private void ApplyRaiseLowerAt(int ix, int iz, int idx, bool up, Tuple<int, int>[] brushShape, int vertDxMin, int vertDxMax)
	{
		bool flag = false;
		float num = float.NegativeInfinity;
		float num2 = float.PositiveInfinity;
		for (int i = vertDxMin; i <= vertDxMax; i++)
		{
			for (int j = vertDxMin; j <= vertDxMax; j++)
			{
				int num3 = ix + i;
				int num4 = iz + j;
				if (CheckSingleVertValid(num3, num4) == TerrainEditError.None)
				{
					float vertY = TerrainGen.inst.GetVertY(num3, num4);
					if (vertY > num)
					{
						num = vertY;
					}
					if (vertY < num2)
					{
						num2 = vertY;
					}
					flag = true;
				}
			}
		}
		if (!flag)
		{
			return;
		}
		bool hasStraggler = num - num2 > 0.001f;
		float cap = (up ? num : num2);
		bool flag2 = false;
		for (int k = vertDxMin; k <= vertDxMax; k++)
		{
			for (int l = vertDxMin; l <= vertDxMax; l++)
			{
				int num5 = ix + k;
				int num6 = iz + l;
				int index = num5 + num6 * World.MeshWidth;
				if (CheckSingleVertValid(num5, num6) == TerrainEditError.None)
				{
					if (!flag2)
					{
						TryLockLandmass(index, _singleVertShape);
						flag2 = true;
					}
					TrackUndoVerts(index, _singleVertShape);
					TrackVerts(index, _singleVertShape);
					float vertY2 = TerrainGen.inst.GetVertY(num5, num6);
					TerrainGen.inst.SetVert(num5, num6, ClampToRockBed(num5, num6, ComputeRaiseLowerTarget(vertY2, up, hasStraggler, cap)), bakeDown: true);
				}
			}
		}
	}

	private float ComputeRaiseLowerTarget(float h, bool up, bool hasStraggler, float cap)
	{
		float num = (up ? (Mathf.Floor(h * 4f) / 4f + 0.25f) : (Mathf.Ceil(h * 4f) / 4f - 0.25f));
		float a;
		if (hasStraggler)
		{
			a = (up ? Mathf.Min(num, cap) : Mathf.Max(num, cap));
		}
		else
		{
			a = num;
		}
		return Mathf.Max(a, MinTerrainHeight);
	}

	private void ApplySoftRaiseLowerAt(int ix, int iz, int idx, bool up, int vertDxMin, int vertDxMax)
	{
		float num = (up ? 0.0625f : (-0.0625f));
		float num2 = (float)(vertDxMin + vertDxMax) / 2f;
		float num3 = (float)(vertDxMax - vertDxMin) / 2f + 1f;
		bool flag = false;
		for (int i = vertDxMin; i <= vertDxMax; i++)
		{
			for (int j = vertDxMin; j <= vertDxMax; j++)
			{
				int num4 = ix + i;
				int num5 = iz + j;
				int index = num4 + num5 * World.MeshWidth;
				if (CheckSingleVertValid(num4, num5) != TerrainEditError.None)
				{
					continue;
				}
				float a = Mathf.Abs((float)i - num2);
				float b = Mathf.Abs((float)j - num2);
				float num6 = Mathf.Max(a, b);
				float num7 = 1f - num6 / num3;
				if (!(num7 <= 0f))
				{
					if (!flag)
					{
						TryLockLandmass(index, _singleVertShape);
						flag = true;
					}
					TrackUndoVerts(index, _singleVertShape);
					TrackVerts(index, _singleVertShape);
					float target = Mathf.Max(TerrainGen.inst.GetVertY(num4, num5) + num * num7, MinTerrainHeight);
					TerrainGen.inst.SetVert(num4, num5, ClampToRockBed(num4, num5, target), bakeDown: true);
				}
			}
		}
	}

	private void UpdateRestoreTool()
	{
		if (!PointingSystem.GetPointer().GetPrimaryDownThisFrame() && tileToolHasPendingUndo)
		{
			CommitStroke();
			tileToolHasPendingUndo = false;
			FlushRockReclassification();
		}
		if (TerrainGen.inst.originalHeightCache == null)
		{
			return;
		}
		Ray ray = PointingSystem.GetRay();
		bool primaryDownThisFrame = PointingSystem.GetPointer().GetPrimaryDownThisFrame();
		if (primaryDownThisFrame && !dragLocked)
		{
			mouseDownPosition = Input.mousePosition;
		}
		if (dragLocked && Vector2.Distance(Input.mousePosition, mouseDownPosition) > 4f)
		{
			dragLocked = false;
		}
		if (!dragLocked && Physics.Raycast(ray, out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
		{
			Vector3 point = ray.GetPoint(hitInfo.distance);
			int num = SnapBrushCursor(brushSize, point.x);
			int num2 = SnapBrushCursor(brushSize, point.z);
			if ((num != x || num2 != z) && !dragLocked)
			{
				applied = false;
			}
			x = num;
			z = num2;
		}
		if (!primaryDownThisFrame)
		{
			applied = false;
			tileToolHasLastApplied = false;
		}
		int num3 = x + z * World.MeshWidth;
		int num4 = (brushSize - 1) / 2;
		int num5 = -num4;
		int num6 = brushSize - 1 - num4;
		Tuple<int, int>[] vertBrushVertDirections = GetVertBrushVertDirections(brushSize);
		float num7 = (float)(x + num5) / 2f;
		float num8 = (float)(z + num5) / 2f;
		HandleTerrainEditError(CheckTerrainEditValid(num3, vertBrushVertDirections));
		using (_drawCmd.WithColor(primaryColor))
		{
			if (brushSize == 1)
			{
				float vertY = TerrainGen.inst.GetVertY(x, z);
				float y = TerrainGen.inst.originalHeightCache[x + z * World.MeshWidth];
				Vector3 a = new Vector3(num7, vertY, num8);
				Vector3 vector = new Vector3(num7, y, num8);
				Vector3 vector2 = new Vector3(num7 + 0.5f, TerrainGen.inst.GetVertY(x + 1, z), num8);
				Vector3 vector3 = new Vector3(num7 - 0.5f, TerrainGen.inst.GetVertY(x - 1, z), num8);
				Vector3 vector4 = new Vector3(num7, TerrainGen.inst.GetVertY(x, z + 1), num8 + 0.5f);
				Vector3 vector5 = new Vector3(num7, TerrainGen.inst.GetVertY(x, z - 1), num8 - 0.5f);
				_drawCmd.Line(a, vector2);
				_drawCmd.Line(a, vector3);
				_drawCmd.Line(a, vector4);
				_drawCmd.Line(a, vector5);
				_drawCmd.DashedLine(vector, vector2, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector3, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector4, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector5, 0.05f, 0.05f);
			}
			else
			{
				int num9 = num6 - num5 + 1;
				if (_raiseLowerTargets == null || _raiseLowerTargets.Length < num9 * num9)
				{
					_raiseLowerTargets = new float[num9 * num9];
				}
				if (_raiseLowerValid == null || _raiseLowerValid.Length < num9 * num9)
				{
					_raiseLowerValid = new bool[num9 * num9];
				}
				for (int i = num5; i <= num6; i++)
				{
					for (int j = num5; j <= num6; j++)
					{
						int num10 = x + i;
						int num11 = z + j;
						bool flag = CheckSingleVertValid(num10, num11) == TerrainEditError.None;
						float num12 = (flag ? TerrainGen.inst.originalHeightCache[num10 + num11 * World.MeshWidth] : TerrainGen.inst.GetVertY(num10, num11));
						int num13 = (i - num5) * num9 + (j - num5);
						_raiseLowerTargets[num13] = num12 + 0.0001f;
						_raiseLowerValid[num13] = flag;
					}
				}
				int num14 = 0;
				int num15 = num9 - 1;
				for (int k = num5; k < num6; k++)
				{
					int num16 = (k - num5) * num9 + num14;
					int num17 = (k + 1 - num5) * num9 + num14;
					float num18 = (float)(z + num5) / 2f;
					Vector3 a2 = new Vector3((float)(x + k) / 2f, _raiseLowerTargets[num16], num18);
					Vector3 b = new Vector3((float)(x + k + 1) / 2f, _raiseLowerTargets[num17], num18);
					bool flag2 = _raiseLowerValid[num16] && _raiseLowerValid[num17];
					using (_drawCmd.WithColor(flag2 ? originalColor : errorColor))
					{
						_drawCmd.Line(a2, b);
					}
				}
				for (int l = num5; l < num6; l++)
				{
					int num19 = (l - num5) * num9 + num15;
					int num20 = (l + 1 - num5) * num9 + num15;
					float num21 = (float)(z + num6) / 2f;
					Vector3 a3 = new Vector3((float)(x + l) / 2f, _raiseLowerTargets[num19], num21);
					Vector3 b2 = new Vector3((float)(x + l + 1) / 2f, _raiseLowerTargets[num20], num21);
					bool flag3 = _raiseLowerValid[num19] && _raiseLowerValid[num20];
					using (_drawCmd.WithColor(flag3 ? originalColor : errorColor))
					{
						_drawCmd.Line(a3, b2);
					}
				}
				for (int m = num5; m < num6; m++)
				{
					int num22 = num14 * num9 + (m - num5);
					int num23 = num14 * num9 + (m + 1 - num5);
					float num24 = (float)(x + num5) / 2f;
					Vector3 a4 = new Vector3(num24, _raiseLowerTargets[num22], (float)(z + m) / 2f);
					Vector3 b3 = new Vector3(num24, _raiseLowerTargets[num23], (float)(z + m + 1) / 2f);
					bool flag4 = _raiseLowerValid[num22] && _raiseLowerValid[num23];
					using (_drawCmd.WithColor(flag4 ? originalColor : errorColor))
					{
						_drawCmd.Line(a4, b3);
					}
				}
				for (int n = num5; n < num6; n++)
				{
					int num25 = num15 * num9 + (n - num5);
					int num26 = num15 * num9 + (n + 1 - num5);
					float num27 = (float)(x + num6) / 2f;
					Vector3 a5 = new Vector3(num27, _raiseLowerTargets[num25], (float)(z + n) / 2f);
					Vector3 b4 = new Vector3(num27, _raiseLowerTargets[num26], (float)(z + n + 1) / 2f);
					bool flag5 = _raiseLowerValid[num25] && _raiseLowerValid[num26];
					using (_drawCmd.WithColor(flag5 ? originalColor : errorColor))
					{
						_drawCmd.Line(a5, b4);
					}
				}
			}
		}
		if (!primaryDownThisFrame || applied)
		{
			return;
		}
		applied = true;
		dragLocked = true;
		int num28 = (tileToolHasLastApplied ? tileToolLastAppliedIndex : num3);
		bool flag6 = false;
		foreach (int item in GridLine.Walk(num28, num3, World.MeshWidth))
		{
			if ((!tileToolHasLastApplied || item != num28) && AnyVertValid(item, vertBrushVertDirections))
			{
				int ix = item % World.MeshWidth;
				int iz = item / World.MeshWidth;
				ApplyRestoreAt(ix, iz, item, vertBrushVertDirections, num5, num6);
				flag6 = true;
			}
		}
		tileToolLastAppliedIndex = num3;
		tileToolHasLastApplied = true;
		tileToolHasPendingUndo = true;
		if (flag6)
		{
			TerrainGen.inst.UpdateTerrainDeformations();
			CalculateWork();
			updateWork = true;
		}
	}

	private void ApplyRestoreAt(int ix, int iz, int idx, Tuple<int, int>[] brushShape, int vertDxMin, int vertDxMax)
	{
		bool flag = false;
		for (int i = vertDxMin; i <= vertDxMax; i++)
		{
			for (int j = vertDxMin; j <= vertDxMax; j++)
			{
				int num = ix + i;
				int num2 = iz + j;
				int num3 = num + num2 * World.MeshWidth;
				if (CheckSingleVertValid(num, num2) == TerrainEditError.None)
				{
					if (!flag)
					{
						TryLockLandmass(num3, _singleVertShape);
						flag = true;
					}
					TrackUndoVerts(num3, _singleVertShape);
					TrackVerts(num3, _singleVertShape);
					TerrainGen.inst.SetVert(num, num2, ClampToRockBed(num, num2, TerrainGen.inst.originalHeightCache[num3]), bakeDown: true);
				}
			}
		}
	}

	private void UpdateSmoothingTool()
	{
		if (!PointingSystem.GetPointer().GetPrimaryDownThisFrame() && tileToolHasPendingUndo)
		{
			CommitStroke();
			tileToolHasPendingUndo = false;
			FlushRockReclassification();
		}
		Ray ray = PointingSystem.GetRay();
		bool primaryDownThisFrame = PointingSystem.GetPointer().GetPrimaryDownThisFrame();
		if (primaryDownThisFrame && !dragLocked)
		{
			mouseDownPosition = Input.mousePosition;
		}
		if (dragLocked && Vector2.Distance(Input.mousePosition, mouseDownPosition) > 4f)
		{
			dragLocked = false;
		}
		if (!dragLocked && Physics.Raycast(ray, out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
		{
			Vector3 point = ray.GetPoint(hitInfo.distance);
			int num = SnapBrushCursor(brushSize, point.x);
			int num2 = SnapBrushCursor(brushSize, point.z);
			if ((num != x || num2 != z) && !dragLocked)
			{
				applied = false;
			}
			x = num;
			z = num2;
		}
		if (!primaryDownThisFrame)
		{
			applied = false;
			tileToolHasLastApplied = false;
		}
		int index = x + z * World.MeshWidth;
		int num3 = (brushSize - 1) / 2;
		int num4 = -num3;
		int num5 = brushSize - 1 - num3;
		Tuple<int, int>[] vertBrushVertDirections = GetVertBrushVertDirections(brushSize);
		float num6 = (float)(x + num4) / 2f;
		float num7 = (float)(z + num4) / 2f;
		HandleTerrainEditError(CheckTerrainEditValid(index, vertBrushVertDirections));
		using (_drawCmd.WithColor(primaryColor))
		{
			if (brushSize == 1)
			{
				float vertY = TerrainGen.inst.GetVertY(x, z);
				float y = vertY + (ComputeSmoothedHeight(x, z) - vertY) * 0.1f;
				Vector3 a = new Vector3(num6, vertY, num7);
				Vector3 vector = new Vector3(num6, y, num7);
				Vector3 vector2 = new Vector3(num6 + 0.5f, TerrainGen.inst.GetVertY(x + 1, z), num7);
				Vector3 vector3 = new Vector3(num6 - 0.5f, TerrainGen.inst.GetVertY(x - 1, z), num7);
				Vector3 vector4 = new Vector3(num6, TerrainGen.inst.GetVertY(x, z + 1), num7 + 0.5f);
				Vector3 vector5 = new Vector3(num6, TerrainGen.inst.GetVertY(x, z - 1), num7 - 0.5f);
				_drawCmd.Line(a, vector2);
				_drawCmd.Line(a, vector3);
				_drawCmd.Line(a, vector4);
				_drawCmd.Line(a, vector5);
				_drawCmd.DashedLine(vector, vector2, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector3, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector4, 0.05f, 0.05f);
				_drawCmd.DashedLine(vector, vector5, 0.05f, 0.05f);
			}
			else
			{
				int num8 = num5 - num4 + 1;
				if (_raiseLowerTargets == null || _raiseLowerTargets.Length < num8 * num8)
				{
					_raiseLowerTargets = new float[num8 * num8];
				}
				if (_raiseLowerValid == null || _raiseLowerValid.Length < num8 * num8)
				{
					_raiseLowerValid = new bool[num8 * num8];
				}
				for (int i = num4; i <= num5; i++)
				{
					for (int j = num4; j <= num5; j++)
					{
						int num9 = x + i;
						int num10 = z + j;
						float vertY2 = TerrainGen.inst.GetVertY(num9, num10);
						bool flag = CheckSingleVertValid(num9, num10) == TerrainEditError.None;
						float num11 = (flag ? Mathf.Max(vertY2 + (ComputeSmoothedHeight(num9, num10) - vertY2) * 0.1f, MinTerrainHeight) : vertY2);
						int num12 = (i - num4) * num8 + (j - num4);
						_raiseLowerTargets[num12] = num11 + 0.001f;
						_raiseLowerValid[num12] = flag;
					}
				}
				int num13 = 0;
				int num14 = num8 - 1;
				for (int k = num4; k < num5; k++)
				{
					int num15 = (k - num4) * num8 + num13;
					int num16 = (k + 1 - num4) * num8 + num13;
					float num17 = (float)(z + num4) / 2f;
					Vector3 a2 = new Vector3((float)(x + k) / 2f, _raiseLowerTargets[num15], num17);
					Vector3 b = new Vector3((float)(x + k + 1) / 2f, _raiseLowerTargets[num16], num17);
					bool flag2 = _raiseLowerValid[num15] && _raiseLowerValid[num16];
					using (_drawCmd.WithColor(flag2 ? originalColor : errorColor))
					{
						_drawCmd.Line(a2, b);
					}
				}
				for (int l = num4; l < num5; l++)
				{
					int num18 = (l - num4) * num8 + num14;
					int num19 = (l + 1 - num4) * num8 + num14;
					float num20 = (float)(z + num5) / 2f;
					Vector3 a3 = new Vector3((float)(x + l) / 2f, _raiseLowerTargets[num18], num20);
					Vector3 b2 = new Vector3((float)(x + l + 1) / 2f, _raiseLowerTargets[num19], num20);
					bool flag3 = _raiseLowerValid[num18] && _raiseLowerValid[num19];
					using (_drawCmd.WithColor(flag3 ? originalColor : errorColor))
					{
						_drawCmd.Line(a3, b2);
					}
				}
				for (int m = num4; m < num5; m++)
				{
					int num21 = num13 * num8 + (m - num4);
					int num22 = num13 * num8 + (m + 1 - num4);
					float num23 = (float)(x + num4) / 2f;
					Vector3 a4 = new Vector3(num23, _raiseLowerTargets[num21], (float)(z + m) / 2f);
					Vector3 b3 = new Vector3(num23, _raiseLowerTargets[num22], (float)(z + m + 1) / 2f);
					bool flag4 = _raiseLowerValid[num21] && _raiseLowerValid[num22];
					using (_drawCmd.WithColor(flag4 ? originalColor : errorColor))
					{
						_drawCmd.Line(a4, b3);
					}
				}
				for (int n = num4; n < num5; n++)
				{
					int num24 = num14 * num8 + (n - num4);
					int num25 = num14 * num8 + (n + 1 - num4);
					float num26 = (float)(x + num5) / 2f;
					Vector3 a5 = new Vector3(num26, _raiseLowerTargets[num24], (float)(z + n) / 2f);
					Vector3 b4 = new Vector3(num26, _raiseLowerTargets[num25], (float)(z + n + 1) / 2f);
					bool flag5 = _raiseLowerValid[num24] && _raiseLowerValid[num25];
					using (_drawCmd.WithColor(flag5 ? originalColor : errorColor))
					{
						_drawCmd.Line(a5, b4);
					}
				}
			}
		}
		if (!primaryDownThisFrame || applied)
		{
			return;
		}
		applied = true;
		dragLocked = true;
		int num27 = num5 - num4 + 1;
		int num28 = num27 * num27;
		if (_smoothingBuffer == null || _smoothingBuffer.Length < num28)
		{
			_smoothingBuffer = new float[num28];
		}
		bool flag6 = false;
		for (int num29 = num4; num29 <= num5; num29++)
		{
			for (int num30 = num4; num30 <= num5; num30++)
			{
				int num31 = (num29 - num4) * num27 + (num30 - num4);
				int num32 = x + num29;
				int num33 = z + num30;
				int index2 = num32 + num33 * World.MeshWidth;
				if (CheckSingleVertValid(num32, num33) != TerrainEditError.None)
				{
					_smoothingBuffer[num31] = float.NaN;
					continue;
				}
				if (!flag6)
				{
					TryLockLandmass(index2, _singleVertShape);
				}
				TrackUndoVerts(index2, _singleVertShape);
				float vertY3 = TerrainGen.inst.GetVertY(num32, num33);
				float num34 = ComputeSmoothedHeight(num32, num33);
				_smoothingBuffer[num31] = vertY3 + (num34 - vertY3) * 0.1f;
				flag6 = true;
			}
		}
		if (!flag6)
		{
			return;
		}
		for (int num35 = num4; num35 <= num5; num35++)
		{
			for (int num36 = num4; num36 <= num5; num36++)
			{
				int num37 = (num35 - num4) * num27 + (num36 - num4);
				if (!float.IsNaN(_smoothingBuffer[num37]))
				{
					TerrainGen.inst.SetVert(x + num35, z + num36, ClampToRockBed(x + num35, z + num36, Mathf.Max(_smoothingBuffer[num37], MinTerrainHeight)), bakeDown: true);
				}
			}
		}
		tileToolHasPendingUndo = true;
		FreezeChangesAndCalculateWork(index, vertBrushVertDirections);
	}

	private float ComputeSmoothedHeight(int vx, int vz)
	{
		float num = 0f;
		int num2 = 0;
		for (int i = -1; i <= 1; i++)
		{
			for (int j = -1; j <= 1; j++)
			{
				int num3 = vx + i;
				int num4 = vz + j;
				if (num3 >= 0 && num4 >= 0 && num3 < World.MeshWidth && num4 < World.MeshHeight)
				{
					num += TerrainGen.inst.GetVertY(num3, num4);
					num2++;
				}
			}
		}
		if (num2 <= 0)
		{
			return TerrainGen.inst.GetVertY(vx, vz);
		}
		return num / (float)num2;
	}

	private void ShowError(string error, float howLong = 3f)
	{
		showErrorTimer.Reset();
		showErrorTimer.Enabled = true;
		showErrorTimer.Duration = howLong;
		errorMessage = error;
	}

	private void HideError()
	{
		showErrorTimer.Enabled = false;
	}

	private void FreezeChangesAndCalculateWork(int index, Tuple<int, int>[] toolShape)
	{
		TrackVerts(index, toolShape);
		TerrainGen.inst.UpdateTerrainDeformations();
		CalculateWork();
		updateWork = true;
	}

	private int SnapBrushCursor(int size, float world)
	{
		if ((size & 1) != 1)
		{
			return Mathf.FloorToInt(world * 2f);
		}
		return Mathf.RoundToInt(world * 2f);
	}

	private Tuple<int, int>[] GetVertBrushVertDirections(int size)
	{
		if (_vertBrushVertDirections == null || _vertBrushVertDirections.Length <= size)
		{
			Tuple<int, int>[][] vertBrushVertDirections = _vertBrushVertDirections;
			_vertBrushVertDirections = new Tuple<int, int>[Mathf.Max(size + 4, 16)][];
			if (vertBrushVertDirections != null)
			{
				Array.Copy(vertBrushVertDirections, _vertBrushVertDirections, vertBrushVertDirections.Length);
			}
		}
		if (_vertBrushVertDirections[size] != null)
		{
			return _vertBrushVertDirections[size];
		}
		int num = (size - 1) / 2;
		int num2 = -num;
		int num3 = size - 1 - num;
		int num4 = num3 - num2 + 1;
		Tuple<int, int>[] array = new Tuple<int, int>[num4 * num4];
		int num5 = 0;
		for (int i = num2; i <= num3; i++)
		{
			for (int j = num2; j <= num3; j++)
			{
				array[num5++] = Tuple.Create(i, j);
			}
		}
		_vertBrushVertDirections[size] = array;
		return array;
	}

	private void TrackVerts(int index, Tuple<int, int>[] toolShape)
	{
		int num = World.MeshWidth * World.MeshHeight;
		for (int i = 0; i < toolShape.Length; i++)
		{
			int num2 = index + toolShape[i].Item1 + toolShape[i].Item2 * World.MeshWidth;
			if (num2 >= 0 && num2 < num && CheckSingleVertValid(num2 % World.MeshWidth, num2 / World.MeshWidth) == TerrainEditError.None)
			{
				modifiedVerts[num2] = 0;
				MarkRockDirtyVert(num2 % World.MeshWidth, num2 / World.MeshWidth);
			}
		}
	}

	private void TrackUndoVerts(int index, Tuple<int, int>[] toolShape)
	{
		int num = World.MeshWidth * World.MeshHeight;
		for (int i = 0; i < toolShape.Length; i++)
		{
			int num2 = index + toolShape[i].Item1 + toolShape[i].Item2 * World.MeshWidth;
			if (num2 >= 0 && num2 < num && !currentUndo.ContainsKey(num2))
			{
				currentUndo[num2] = new UndoVertState
				{
					height = TerrainGen.inst.GetVertYUnsafe(num2),
					firstModifiedThisEdit = !modifiedVerts.ContainsKey(num2)
				};
			}
		}
	}

	private bool CheckForInvalid(int index, Tuple<int, int>[] toolShape)
	{
		for (int i = 0; i < toolShape.Length; i++)
		{
			int num = index + toolShape[i].Item1 + toolShape[i].Item2 * World.MeshWidth;
			int num2 = num % World.MeshWidth;
			int num3 = num / World.MeshWidth;
			bool flag = num2 % 2 == 0;
			bool flag2 = num3 % 2 == 0;
			for (int j = (flag ? (-1) : 0); j <= (flag ? 1 : 0); j++)
			{
				for (int k = (flag2 ? (-1) : 0); k <= (flag2 ? 1 : 0); k++)
				{
					int num4 = num2 + j;
					int num5 = num3 + k;
					if (num4 >= 0 && num5 >= 0 && num4 < World.MeshWidth && num5 < World.MeshHeight)
					{
						int i2 = DynamicWater.MapIndexMeshToWorld(num4 + num5 * World.MeshWidth, World.inst.GridWidth);
						if (World.CellBlocksTerrainEdit(World.inst.GetCellDataUnsafe(i2)))
						{
							return true;
						}
					}
				}
			}
		}
		return false;
	}

	public static bool IsMapEdgeVert(int vx, int vz)
	{
		if (vx > 1 && vz > 1 && vx < World.MeshWidth - 2)
		{
			return vz >= World.MeshHeight - 2;
		}
		return true;
	}

	private TerrainEditError CheckSingleVertValid(int vx, int vz)
	{
		if (IsMapEdgeVert(vx, vz))
		{
			return TerrainEditError.MapEdge;
		}
		bool flag = vx % 2 == 0;
		bool flag2 = vz % 2 == 0;
		for (int i = (flag ? (-1) : 0); i <= (flag ? 1 : 0); i++)
		{
			for (int j = (flag2 ? (-1) : 0); j <= (flag2 ? 1 : 0); j++)
			{
				int num = vx + i;
				int num2 = vz + j;
				if (num >= 0 && num2 >= 0 && num < World.MeshWidth && num2 < World.MeshHeight)
				{
					int i2 = DynamicWater.MapIndexMeshToWorld(num + num2 * World.MeshWidth, World.inst.GridWidth);
					Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i2);
					if (!mapEditorMode && cellDataUnsafe.landMassIdx == -1)
					{
						return TerrainEditError.InOcean;
					}
					if (!mapEditorMode && World.GetLandmassOwner(cellDataUnsafe.landMassIdx) != Player.inst.PlayerLandmassOwner)
					{
						return TerrainEditError.NotOwnedByPlayer;
					}
					if (lockedLandmass.HasValue && cellDataUnsafe.landMassIdx != lockedLandmass.Value)
					{
						return TerrainEditError.WrongLandmass;
					}
					if (World.CellBlocksTerrainEdit(cellDataUnsafe))
					{
						return TerrainEditError.OccupiedByBuilding;
					}
				}
			}
		}
		if (mapEditorMode)
		{
			return TerrainEditError.None;
		}
		for (int k = vx - 1; k <= vx + 1; k++)
		{
			for (int l = vz - 1; l <= vz + 1; l++)
			{
				if ((k == vx && l == vz) || k < 0 || l < 0 || k >= World.MeshWidth || l >= World.MeshHeight)
				{
					continue;
				}
				bool flag3 = k % 2 == 0;
				bool flag4 = l % 2 == 0;
				for (int m = (flag3 ? (-1) : 0); m <= (flag3 ? 1 : 0); m++)
				{
					for (int n = (flag4 ? (-1) : 0); n <= (flag4 ? 1 : 0); n++)
					{
						int num3 = k + m;
						int num4 = l + n;
						if (num3 >= 0 && num4 >= 0 && num3 < World.MeshWidth && num4 < World.MeshHeight)
						{
							int i3 = DynamicWater.MapIndexMeshToWorld(num3 + num4 * World.MeshWidth, World.inst.GridWidth);
							if (World.inst.GetCellDataUnsafe(i3).landMassIdx == -1)
							{
								return TerrainEditError.InOcean;
							}
						}
					}
				}
			}
		}
		return TerrainEditError.None;
	}

	private TerrainEditError CheckTerrainEditValid(int index, Tuple<int, int>[] toolShape)
	{
		for (int i = 0; i < toolShape.Length; i++)
		{
			int num = index + toolShape[i].Item1 + toolShape[i].Item2 * World.MeshWidth;
			int vx = num % World.MeshWidth;
			int vz = num / World.MeshWidth;
			TerrainEditError terrainEditError = CheckSingleVertValid(vx, vz);
			if (terrainEditError != TerrainEditError.None)
			{
				return terrainEditError;
			}
		}
		return TerrainEditError.None;
	}

	private bool AnyVertValid(int index, Tuple<int, int>[] toolShape)
	{
		for (int i = 0; i < toolShape.Length; i++)
		{
			int num = index + toolShape[i].Item1 + toolShape[i].Item2 * World.MeshWidth;
			int vx = num % World.MeshWidth;
			int vz = num / World.MeshWidth;
			if (CheckSingleVertValid(vx, vz) == TerrainEditError.None)
			{
				return true;
			}
		}
		return false;
	}

	private bool HandleTerrainEditError(TerrainEditError error)
	{
		switch (error)
		{
		case TerrainEditError.InOcean:
			ShowError(LocalizationManager.GetTranslation("terrainplanning_oceanerror"));
			return true;
		case TerrainEditError.NotOwnedByPlayer:
			ShowError(LocalizationManager.GetTranslation("terrainplanning_notownedbyplayererror"));
			return true;
		case TerrainEditError.WrongLandmass:
			ShowError(LocalizationManager.GetTranslation("terrainplanning_wronglandmasserror"));
			return true;
		case TerrainEditError.OccupiedByBuilding:
			ShowError(LocalizationManager.GetTranslation("TerrainPlanningIntersectingRockBuildingError"));
			return true;
		case TerrainEditError.MapEdge:
			ShowError(LocalizationManager.GetTranslation("terrainplanning_oceanerror"));
			return true;
		default:
			return false;
		}
	}

	private void TryLockLandmass(int index, Tuple<int, int>[] toolShape)
	{
		if (!mapEditorMode && !lockedLandmass.HasValue)
		{
			int num = index + toolShape[0].Item1 + toolShape[0].Item2 * World.MeshWidth;
			int num2 = num % World.MeshWidth;
			int num3 = num / World.MeshWidth;
			int i = DynamicWater.MapIndexMeshToWorld(num2 + num3 * World.MeshWidth, World.inst.GridWidth);
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i);
			lockedLandmass = cellDataUnsafe.landMassIdx;
		}
	}

	private void CalculateWork()
	{
		summationOfDirt = 0f;
		summationOfWork = 0f;
		foreach (int key in modifiedVerts.Keys)
		{
			float num = originalHeightsCache[key];
			float num2 = TerrainGen.inst.GetVertYUnsafe(key) - num;
			if (num2 > 0f)
			{
				num2 -= RaiseFreeFillCached(key % World.MeshWidth, key / World.MeshWidth, num, num + num2);
			}
			summationOfDirt += num2;
			summationOfWork += Mathf.Abs(num2);
		}
	}

	private float RaiseFreeFillCached(int vx, int vz, float current, float target)
	{
		if (target <= current)
		{
			return 0f;
		}
		int key = vx + vz * World.MeshWidth;
		if (!_rockSpanCache.TryGetValue(key, out var value))
		{
			value.top = TerrainRockFill.RockTop(vx, vz);
			value.bottom = TerrainRockFill.RockBottom(vx, vz);
			_rockSpanCache[key] = value;
		}
		if (value.top <= current)
		{
			return 0f;
		}
		float num = Mathf.Max(current, value.bottom);
		float num2 = Mathf.Min(target, value.top);
		if (!(num2 > num))
		{
			return 0f;
		}
		return num2 - num;
	}

	private float RockBedLimit(int vx, int vz)
	{
		return TerrainRockFill.RockBottom(vx, vz);
	}

	private float ClampToRockBed(int vx, int vz, float target)
	{
		if (mapEditorMode)
		{
			return target;
		}
		float num = RockBedLimit(vx, vz);
		if (num == float.MinValue)
		{
			return target;
		}
		float b = TerrainGen.inst.heightCache[vx + vz * World.MeshWidth];
		float num2 = Mathf.Min(num, b);
		if (!(target < num2))
		{
			return target;
		}
		return num2;
	}

	private void MarkRockDirtyVert(int vx, int vz)
	{
		if (!_rockDirtyValid)
		{
			_rockDirtyMinX = (_rockDirtyMaxX = vx);
			_rockDirtyMinZ = (_rockDirtyMaxZ = vz);
			_rockDirtyValid = true;
			return;
		}
		if (vx < _rockDirtyMinX)
		{
			_rockDirtyMinX = vx;
		}
		if (vx > _rockDirtyMaxX)
		{
			_rockDirtyMaxX = vx;
		}
		if (vz < _rockDirtyMinZ)
		{
			_rockDirtyMinZ = vz;
		}
		if (vz > _rockDirtyMaxZ)
		{
			_rockDirtyMaxZ = vz;
		}
	}

	private void FlushRockReclassification()
	{
		if (_rockDirtyValid)
		{
			_rockDirtyValid = false;
			TerrainRockReclassifier.ReclassifyVertRect(_rockDirtyMinX, _rockDirtyMinZ, _rockDirtyMaxX, _rockDirtyMaxZ);
		}
	}

	private void FlushRockObstructionOnly()
	{
		if (_rockDirtyValid)
		{
			_rockDirtyValid = false;
			int num = Mathf.Max(0, _rockDirtyMinX / 2 - 1);
			int num2 = Mathf.Max(0, _rockDirtyMinZ / 2 - 1);
			int num3 = Mathf.Min(World.inst.GridWidth - 1, _rockDirtyMaxX / 2 + 1);
			int num4 = Mathf.Min(World.inst.GridHeight - 1, _rockDirtyMaxZ / 2 + 1);
			if (num <= num3 && num2 <= num4)
			{
				TerrainGen.inst.UpdateTerrainDeformations();
				TerrainGen.inst.RecalcWaterObstructionForArea(num, num2, num3 - num + 1, num4 - num2 + 1);
			}
		}
	}

	public float GetWorkAmount()
	{
		return summationOfWork;
	}

	public float GetTerrainChangeAmount()
	{
		return summationOfDirt;
	}

	public void GetChangeData(out int[] points, out float[] starts, out float[] ends)
	{
		points = new int[modifiedVerts.Keys.Count];
		starts = new float[modifiedVerts.Keys.Count];
		ends = new float[modifiedVerts.Keys.Count];
		int[] array = modifiedVerts.Keys.ToArray();
		for (int i = 0; i < array.Length; i++)
		{
			points[i] = array[i];
			starts[i] = originalHeightsCache[array[i]];
			ends[i] = TerrainGen.inst.GetVertYUnsafe(array[i]);
		}
	}

	internal void ClearUndoHistory()
	{
		currentUndo.Clear();
		undoQueue.Clear();
	}
}
