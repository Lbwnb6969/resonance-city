using System;
using System.Collections.Generic;
using Assets;
using Code;
using UnityEngine;

public class MapEditorController : MonoBehaviour
{
	public enum EditorMode
	{
		Select,
		Paint,
		Sculpt
	}

	public static MapEditorController inst;

	public EditorMode currentMode;

	public EditTerrainCursorMode sculptMode;

	public MapSelectionTool selectionTool;

	private bool open;

	private float[] sculptBaseline;

	private Vector3 rightDownPos;

	private readonly Dictionary<Transform, float> rockFollow = new Dictionary<Transform, float>();

	private readonly Dictionary<Transform, float> depositFollow = new Dictionary<Transform, float>();

	private readonly Dictionary<Transform, float> _prevRockFollow = new Dictionary<Transform, float>();

	private readonly Dictionary<Transform, float> _prevDepositFollow = new Dictionary<Transform, float>();

	private readonly List<Transform> _followDead = new List<Transform>();

	private int lastDepositCount = -1;

	public bool IsOpen => open;

	public static bool IsEditing
	{
		get
		{
			if (inst != null)
			{
				return inst.open;
			}
			return false;
		}
	}

	public static MapEditorController Ensure()
	{
		if (inst == null)
		{
			inst = new GameObject("MapEditorController").AddComponent<MapEditorController>();
		}
		return inst;
	}

	public void Open()
	{
		if (!open)
		{
			open = true;
			if (sculptMode == null)
			{
				sculptMode = new EditTerrainCursorMode
				{
					mapEditorMode = true
				};
				selectionTool = new MapSelectionTool();
			}
			sculptBaseline = new float[World.MeshWidth * World.MeshHeight];
			Array.Copy(TerrainGen.inst.heightCache, sculptBaseline, sculptBaseline.Length);
			sculptMode.SetOriginalHeightsCache(sculptBaseline);
			sculptMode.ClearUndoHistory();
			sculptMode.brushSize = 2;
			sculptMode.currentTool = 0;
			sculptMode.onStrokeCommitted = OnTerrainStrokeCommitted;
			MapEditorUndoStack.Clear();
			currentMode = EditorMode.Select;
			selectionTool.Activate();
			RebuildFollowBaselines();
			TerrainGen.suppressEditModeGrid = true;
			TerrainGen.alwaysSnapDecorations = true;
			TerrainGen.inst.EditTerrainSimulateOn(on: true);
			DynamicWater.inst.EditTerrainSimulateOn(on: true);
			DynamicWater.inst.waterfallParticleManager.SimulationMode();
		}
	}

	public void Close()
	{
		if (open)
		{
			SwitchMode(EditorMode.Select);
			selectionTool.Deactivate();
			open = false;
			TerrainGen.suppressEditModeGrid = false;
			TerrainGen.alwaysSnapDecorations = false;
			if (!(TerrainGen.inst == null) && !(DynamicWater.inst == null))
			{
				TerrainGen.inst.EditTerrainSimulateOn(on: false);
				DynamicWater.inst.EditTerrainSimulateOn(on: false);
				DynamicWater.inst.waterfallParticleManager.SimulationMode(simulationModeOn: false);
				TerrainGen.inst.FixDecorationHeightsForAllCells();
				Player.inst.ResetPerLandMassData();
			}
		}
	}

	public void ResetForRegeneratedWorld()
	{
		if (open)
		{
			Close();
			Open();
		}
	}

	public void EnterSculpt(int tool)
	{
		if (open)
		{
			if (currentMode != EditorMode.Sculpt)
			{
				SwitchMode(EditorMode.Sculpt);
			}
			sculptMode.currentTool = Mathf.Clamp(tool, 0, 7);
		}
	}

	public void ExitToSelect()
	{
		if (open)
		{
			SwitchMode(EditorMode.Select);
		}
	}

	private void SwitchMode(EditorMode mode)
	{
		if (mode != currentMode)
		{
			switch (currentMode)
			{
			case EditorMode.Select:
				selectionTool.Deactivate();
				break;
			case EditorMode.Sculpt:
				sculptMode.Shutdown();
				break;
			case EditorMode.Paint:
				MapEdit.inst.ClearBrush();
				World.inst.GenerateLandMassIds();
				TerrainGen.inst.RefreshCellLandmassCache();
				break;
			}
			currentMode = mode;
			switch (mode)
			{
			case EditorMode.Select:
				selectionTool.Activate();
				break;
			case EditorMode.Sculpt:
				sculptMode.Init();
				break;
			}
		}
	}

	private void Update()
	{
		if (!open)
		{
			return;
		}
		if (MapEdit.inst == null || !MapEdit.inst.gameObject.activeInHierarchy)
		{
			Close();
			return;
		}
		if (MapEdit.inst.brushMode != MapEdit.BrushMode.None && currentMode != EditorMode.Paint)
		{
			SwitchMode(EditorMode.Paint);
		}
		else if (currentMode == EditorMode.Paint && MapEdit.inst.brushMode == MapEdit.BrushMode.None)
		{
			SwitchMode(EditorMode.Select);
		}
		HandleRightClickExit();
		if ((Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl)) && Input.GetKeyDown(KeyCode.Z))
		{
			MapEditorUndoStack.PerformUndo();
		}
		sculptMode.brushSize = Mathf.Max(Mathf.RoundToInt(MapEdit.inst.BrushRadius) + 1, 1);
		TerrainGen.suppressEditModeGrid = currentMode != EditorMode.Sculpt;
		switch (currentMode)
		{
		case EditorMode.Select:
			selectionTool.Tick();
			break;
		case EditorMode.Sculpt:
			UpdateSculpt();
			break;
		}
		if (PointingSystem.GetPointer().GetPrimaryUp() && !GameUI.inst.PointerOverUI() && (currentMode == EditorMode.Sculpt || (currentMode == EditorMode.Paint && MapEdit.BrushChangesShoreline(MapEdit.inst.brushMode))))
		{
			Water.inst.RenderDistanceFieldsGPU();
		}
		ObjectHighlighter.Update();
		UpdateFollowers();
		if (MapEditorUndoStack.RescanPending)
		{
			MapEditorUndoStack.RescanPending = false;
			selectionTool.RescanErrors();
		}
	}

	private void HandleRightClickExit()
	{
		if (PointingSystem.GetPointer().GetSecondaryDown())
		{
			rightDownPos = Input.mousePosition;
		}
		if (PointingSystem.GetPointer().GetSecondaryUp() && Vector3.Distance(rightDownPos, Input.mousePosition) < 6f)
		{
			if (currentMode == EditorMode.Sculpt)
			{
				SwitchMode(EditorMode.Select);
			}
			else if (currentMode == EditorMode.Select)
			{
				selectionTool.DisarmAddSpring();
			}
			MapEditorPaletteUI.ClearToolToggles();
		}
	}

	private void OnTerrainStrokeCommitted()
	{
		MapEditorUndoStack.Push(new TerrainStrokeUndoEntry(sculptMode));
	}

	private void UpdateSculpt()
	{
		for (int i = 0; i < 8; i++)
		{
			if (Input.GetKeyDown((KeyCode)(49 + i)))
			{
				sculptMode.currentTool = i;
			}
		}
		if (Input.GetKeyDown(KeyCode.Minus))
		{
			MapEdit.inst.DecreaseRadius();
		}
		if (Input.GetKeyDown(KeyCode.Equals))
		{
			MapEdit.inst.IncreaseRadius();
		}
		sculptMode.Tick(Time.unscaledDeltaTime);
	}

	public void RebuildFollowBaselines()
	{
		_prevRockFollow.Clear();
		foreach (KeyValuePair<Transform, float> item in rockFollow)
		{
			_prevRockFollow[item.Key] = item.Value;
		}
		_prevDepositFollow.Clear();
		foreach (KeyValuePair<Transform, float> item2 in depositFollow)
		{
			_prevDepositFollow[item2.Key] = item2.Value;
		}
		rockFollow.Clear();
		depositFollow.Clear();
		List<GameObject> mountainRocks = TerrainGen.inst.mountainRocks;
		for (int i = 0; i < mountainRocks.Count; i++)
		{
			if (mountainRocks[i] == null)
			{
				continue;
			}
			MountainPlacer component = mountainRocks[i].GetComponent<MountainPlacer>();
			Transform transform = ((component != null) ? component.RocksContainer : mountainRocks[i].transform);
			for (int j = 0; j < transform.childCount; j++)
			{
				Transform child = transform.GetChild(j);
				if (child.gameObject.activeSelf && !(child.GetComponent<MeshRenderer>() == null))
				{
					rockFollow[child] = (_prevRockFollow.TryGetValue(child, out var value) ? value : (child.position.y - TerrainGen.inst.GetGroundHeight(child.position.x, child.position.z)));
				}
			}
		}
		for (int k = 0; k < TerrainResource.terrainResources.Count; k++)
		{
			TerrainResource terrainResource = TerrainResource.terrainResources.data[k];
			if (!(terrainResource == null))
			{
				MeshRenderer componentInChildren = terrainResource.GetComponentInChildren<MeshRenderer>();
				if (!(componentInChildren == null))
				{
					Transform transform2 = componentInChildren.transform;
					depositFollow[transform2] = (_prevDepositFollow.TryGetValue(transform2, out var value2) ? value2 : (transform2.position.y - TerrainGen.inst.GetGroundHeight(transform2.position.x, transform2.position.z)));
				}
			}
		}
		lastDepositCount = TerrainResource.terrainResources.Count;
		if (selectionTool != null)
		{
			selectionTool.RescanErrors();
		}
	}

	public bool FocusNextPlacementError()
	{
		if (!open || selectionTool == null)
		{
			return false;
		}
		selectionTool.RescanErrors();
		Transform transform = selectionTool.NextErrorRock();
		if (transform == null)
		{
			return false;
		}
		SwitchMode(EditorMode.Select);
		Cam.inst.SetDesiredTrackingPos(transform.position);
		Cam.inst.desiredDist = 30f;
		return true;
	}

	public void RebaselineFollow(Transform rock)
	{
		if (!(rock == null))
		{
			rockFollow[rock] = rock.position.y - TerrainGen.inst.GetGroundHeight(rock.position.x, rock.position.z);
		}
	}

	private void UpdateFollowers()
	{
		if (TerrainResource.terrainResources.Count != lastDepositCount)
		{
			RebuildFollowBaselines();
		}
		_followDead.Clear();
		foreach (KeyValuePair<Transform, float> item in rockFollow)
		{
			Transform key = item.Key;
			if (key == null)
			{
				_followDead.Add(key);
			}
			else if (!selectionTool.IsRockSelected(key))
			{
				float num = TerrainGen.inst.GetGroundHeight(key.position.x, key.position.z) + item.Value;
				if (Mathf.Abs(key.position.y - num) > 0.0005f)
				{
					Vector3 position = key.position;
					position.y = num;
					key.position = position;
				}
			}
		}
		foreach (Transform item2 in _followDead)
		{
			rockFollow.Remove(item2);
		}
		_followDead.Clear();
		foreach (KeyValuePair<Transform, float> item3 in depositFollow)
		{
			Transform key2 = item3.Key;
			if (key2 == null)
			{
				_followDead.Add(key2);
				continue;
			}
			float num2 = TerrainGen.inst.GetGroundHeight(key2.position.x, key2.position.z) + item3.Value;
			if (Mathf.Abs(key2.position.y - num2) > 0.0005f)
			{
				Vector3 position2 = key2.position;
				position2.y = num2;
				key2.position = position2;
			}
		}
		foreach (Transform item4 in _followDead)
		{
			depositFollow.Remove(item4);
		}
	}
}
