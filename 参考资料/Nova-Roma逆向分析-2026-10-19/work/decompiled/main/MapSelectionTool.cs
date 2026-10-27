using System.Collections;
using System.Collections.Generic;
using Assets;
using Code;
using Drawing;
using UnityEngine;

public class MapSelectionTool
{
	private class SpringMarker
	{
		public int index;

		public float rate;

		public Vector3 pos;

		public Vector3 dragPos;

		public bool selected;

		public GameObject geyser;

		public ObjectHighlighter highlighter;
	}

	private enum HandleKind
	{
		None,
		Lift,
		RotateY,
		Tilt,
		ScaleX,
		ScaleY,
		ScaleZ,
		UniformScale,
		MoveXZ
	}

	private class RockState
	{
		public Transform rock;

		public Vector3 pos;

		public Quaternion rot;

		public Vector3 scale;
	}

	private class RockRecord
	{
		public Mesh mesh;

		public Material material;

		public Transform parent;

		public Vector3 pos;

		public Quaternion rot;

		public Vector3 scale;
	}

	private class SpringMoveRecord
	{
		public int fromIndex;

		public int toIndex;

		public float rate;
	}

	private class SpringRecord
	{
		public int index;

		public float rate;

		public int strength;
	}

	private class SelectionMoveUndo : IMapEditorUndoEntry
	{
		public readonly List<RockState> rocks = new List<RockState>();

		public readonly List<SpringMoveRecord> springs = new List<SpringMoveRecord>();

		public void Undo()
		{
			RestoreRockStates(rocks);
			foreach (SpringMoveRecord spring in springs)
			{
				int carveStrength = DynamicWater.inst.GetCarveStrength(spring.toIndex);
				RemoveSpringAt(spring.toIndex);
				RestoreSpring(spring.fromIndex, spring.rate, carveStrength);
			}
			AfterUndoRefresh(springs.Count > 0);
		}
	}

	private class RockButtonsUndo : IMapEditorUndoEntry
	{
		public readonly List<RockState> rocks = new List<RockState>();

		public bool Matches(List<Transform> selection)
		{
			if (rocks.Count != selection.Count)
			{
				return false;
			}
			foreach (RockState rock in rocks)
			{
				if (!selection.Contains(rock.rock))
				{
					return false;
				}
			}
			return true;
		}

		public void Undo()
		{
			RestoreRockStates(rocks);
			AfterUndoRefresh(springsChanged: false);
		}
	}

	private class DuplicateUndo : IMapEditorUndoEntry
	{
		public readonly List<Transform> clones = new List<Transform>();

		public void Undo()
		{
			Bounds? bounds = null;
			foreach (Transform clone in clones)
			{
				if (!(clone == null))
				{
					Bounds bounds2 = RockBounds(clone);
					if (bounds.HasValue)
					{
						Bounds value = bounds.Value;
						value.Encapsulate(bounds2);
						bounds = value;
					}
					else
					{
						bounds = bounds2;
					}
					clone.gameObject.SetActive(value: false);
					Object.Destroy(clone.gameObject);
				}
			}
			if (bounds.HasValue && MapEditorController.inst != null)
			{
				MapEditorController.inst.StartCoroutine(ReclassifyNextFrameRoutine(bounds.Value));
			}
			AfterUndoRefresh(springsChanged: false);
		}
	}

	private class DeleteUndo : IMapEditorUndoEntry
	{
		public readonly List<RockRecord> rocks = new List<RockRecord>();

		public readonly List<SpringRecord> springs = new List<SpringRecord>();

		public void Undo()
		{
			foreach (RockRecord rock in rocks)
			{
				Transform transform = RecreateRock(rock);
				if (transform != null)
				{
					ReclassifyWorldBounds(RockBounds(transform));
				}
			}
			foreach (SpringRecord spring in springs)
			{
				RestoreSpring(spring.index, spring.rate, spring.strength);
			}
			AfterUndoRefresh(springs.Count > 0);
		}
	}

	private class CarveStrengthUndo : IMapEditorUndoEntry
	{
		public class Entry
		{
			public int index;

			public int level;
		}

		public readonly List<Entry> entries = new List<Entry>();

		public void Undo()
		{
			foreach (Entry entry in entries)
			{
				DynamicWater.inst.UndoRiverCarveForEdit(entry.index);
				DynamicWater.inst.SetCarveStrength(entry.index, entry.level);
				ReclassifyCarve(DynamicWater.inst.CarveRiverFromSourceForEdit(entry.index));
			}
			AfterUndoRefresh(springsChanged: true);
		}
	}

	private class SpringAddUndo : IMapEditorUndoEntry
	{
		public int index;

		public void Undo()
		{
			RemoveSpringAt(index);
			AfterUndoRefresh(springsChanged: true);
		}
	}

	private const float RotateStep = 15f;

	private const float NudgeStep = 0.25f;

	private const float EmbedMargin = 0.1f;

	private const float SpringPickRadius = 2f;

	private const float ClickMaxDragPx = 6f;

	private const float MinSpringMove = 1f;

	private readonly List<SpringMarker> allSprings = new List<SpringMarker>();

	private readonly List<Transform> selectedRocks = new List<Transform>();

	private Transform hoverRock;

	private SpringMarker hoverSpring;

	private HandleKind handleHover;

	private HandleKind handleDrag;

	private readonly List<RockState> handleStartStates = new List<RockState>();

	private float liftStartY;

	private Vector3 dragPlane;

	private Plane handleDragPlane;

	private Vector3 handleMoveStart;

	private Vector3 ringStartDirection;

	private Vector3 rotationAxis;

	private Quaternion scaleOrientation;

	private Vector2 dragScreenAxis;

	private float dragScreenLength;

	private float rotationAngle;

	private float lastRingAngle;

	private bool ringUsesPlane;

	private bool liftUsesPlane;

	private bool handleChanged;

	private Vector3 rotatePivot;

	private Vector3 handleAnchor;

	private float handleScale;

	private Vector3 gizmoPos;

	private Vector3 gizmoGround;

	private Vector3 ringKnobDirection;

	private float lastBallClickTime = -1f;

	private Vector2 lastBallClickScreen;

	private Transform lastBallClickRock;

	private float gizmoRadius;

	private float gizmoStalkLength;

	private float scaleFactorMin;

	private float scaleFactorMax;

	private readonly MapSelectionGizmo gizmo = new MapSelectionGizmo();

	private bool wasHeld;

	private bool movingSelection;

	private bool boxSelecting;

	private Vector2 pressScreen;

	private Vector2 secondaryDownScreen;

	private Bounds dragStartBounds;

	private bool armAddSpring;

	private Camera[] _camTargets = new Camera[1];

	private static readonly RaycastHit[] _rayHits = new RaycastHit[16];

	private static readonly Vector3[] CornerSigns = new Vector3[8]
	{
		new Vector3(-1f, -1f, -1f),
		new Vector3(1f, -1f, -1f),
		new Vector3(1f, -1f, 1f),
		new Vector3(-1f, -1f, 1f),
		new Vector3(-1f, 1f, -1f),
		new Vector3(1f, 1f, -1f),
		new Vector3(1f, 1f, 1f),
		new Vector3(-1f, 1f, 1f)
	};

	private const int HoverOutlineColor = 0;

	private const int SelectedOutlineColor = 1;

	private const int ErrorOutlineColor = 2;

	private readonly Dictionary<Transform, ObjectHighlighter> rockHighlighters = new Dictionary<Transform, ObjectHighlighter>();

	private GameObject armGhost;

	private List<RockState> pendingMoveStates;

	private readonly List<int> _reselect = new List<int>();

	private readonly HashSet<Transform> errorRocks = new HashSet<Transform>();

	private readonly List<Transform> _errorCycle = new List<Transform>();

	private int errorCycleCursor = -1;

	private static readonly List<Vector3> contactVertices = new List<Vector3>();

	private static readonly List<int> contactTriangles = new List<int>();

	private static Vector3[] contactTerrain = new Vector3[3];

	private static readonly Vector3[] contactPolygonA = new Vector3[8];

	private static readonly Vector3[] contactPolygonB = new Vector3[8];

	private readonly HashSet<Transform> looseRocks = new HashSet<Transform>();

	private static readonly List<Transform> _allRocks = new List<Transform>();

	private static readonly List<Transform> _supportRocks = new List<Transform>();

	private static readonly List<Bounds> _supportBounds = new List<Bounds>();

	private static readonly List<Transform> _unsupported = new List<Transform>();

	private static readonly List<Vector3> touchVertices = new List<Vector3>();

	private const float BandInset = 0.25f;

	private static readonly Color ErrorColor = new Color(1f, 0.25f, 0.2f, 0.9f);

	public bool HasSelection
	{
		get
		{
			if (selectedRocks.Count <= 0)
			{
				return SelectedSpringCount > 0;
			}
			return true;
		}
	}

	public bool HasRockSelection => selectedRocks.Count > 0;

	public bool IsDragging
	{
		get
		{
			if (!movingSelection)
			{
				return handleDrag != HandleKind.None;
			}
			return true;
		}
	}

	private int SelectedSpringCount
	{
		get
		{
			int num = 0;
			foreach (SpringMarker allSpring in allSprings)
			{
				if (allSpring.selected)
				{
					num++;
				}
			}
			return num;
		}
	}

	public bool HasSpringSelection => SelectedSpringCount > 0;

	public bool IsAddSpringArmed => armAddSpring;

	public Vector3 GizmoAnchor => gizmoPos;

	public float GizmoWorldRadius => gizmoRadius;

	private Vector3 JoystickTip => gizmoPos + scaleOrientation * Vector3.up * gizmoStalkLength;

	public bool HasPlacementErrors
	{
		get
		{
			errorRocks.RemoveWhere((Transform r) => r == null);
			return errorRocks.Count > 0;
		}
	}

	public bool IsRockSelected(Transform rock)
	{
		return selectedRocks.Contains(rock);
	}

	public void SetCarveStrengthOnSelection(int level)
	{
		CarveStrengthUndo carveStrengthUndo = new CarveStrengthUndo();
		foreach (SpringMarker allSpring in allSprings)
		{
			if (allSpring.selected)
			{
				int carveStrength = DynamicWater.inst.GetCarveStrength(allSpring.index);
				if (carveStrength != level)
				{
					carveStrengthUndo.entries.Add(new CarveStrengthUndo.Entry
					{
						index = allSpring.index,
						level = carveStrength
					});
					DynamicWater.inst.UndoRiverCarveForEdit(allSpring.index);
					DynamicWater.inst.SetCarveStrength(allSpring.index, level);
					ReclassifyCarve(DynamicWater.inst.CarveRiverFromSourceForEdit(allSpring.index));
				}
			}
		}
		if (carveStrengthUndo.entries.Count != 0)
		{
			MapEditorUndoStack.Push(carveStrengthUndo);
			MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
			if (MapEditorController.inst != null)
			{
				MapEditorController.inst.RebuildFollowBaselines();
			}
		}
	}

	public int GetSelectedSpringStrength()
	{
		int num = -1;
		foreach (SpringMarker allSpring in allSprings)
		{
			if (allSpring.selected)
			{
				int carveStrength = DynamicWater.inst.GetCarveStrength(allSpring.index);
				if (num == -1)
				{
					num = carveStrength;
				}
				else if (num != carveStrength)
				{
					return -1;
				}
			}
		}
		return num;
	}

	public void Activate()
	{
		RefreshSprings();
		ClearSelection();
		RescanErrors();
		wasHeld = false;
		movingSelection = false;
		boxSelecting = false;
		armAddSpring = false;
	}

	public void Deactivate()
	{
		if (movingSelection)
		{
			CommitMove();
		}
		ClearSelection();
		movingSelection = false;
		boxSelecting = false;
		armAddSpring = false;
		gizmo.Destroy();
		if (armGhost != null)
		{
			Object.Destroy(armGhost);
			armGhost = null;
		}
		foreach (ObjectHighlighter value in rockHighlighters.Values)
		{
			value.Release();
		}
		rockHighlighters.Clear();
		foreach (SpringMarker allSpring in allSprings)
		{
			allSpring.highlighter?.Release();
		}
	}

	public void ArmAddSpring()
	{
		armAddSpring = true;
	}

	public void DisarmAddSpring()
	{
		armAddSpring = false;
	}

	private void ClearSelection()
	{
		if (handleDrag != HandleKind.None)
		{
			EndHandleDrag();
		}
		selectedRocks.Clear();
		lastBallClickTime = -1f;
		foreach (SpringMarker allSpring in allSprings)
		{
			allSpring.selected = false;
		}
	}

	private void RefreshSprings()
	{
		foreach (SpringMarker allSpring in allSprings)
		{
			allSpring.highlighter?.Release();
		}
		allSprings.Clear();
		foreach (DynamicWater.SavedWaterSource item in DynamicWater.inst.CollectPersistentSources())
		{
			Vector3 vector = SpringPosFromIndex(item.index);
			GameObject geyser = GeyserNear(vector);
			allSprings.Add(new SpringMarker
			{
				index = item.index,
				rate = item.rate,
				pos = vector,
				dragPos = vector,
				geyser = geyser,
				highlighter = BuildGeyserHighlighter(geyser)
			});
		}
	}

	private static GameObject GeyserNear(Vector3 pos)
	{
		List<GameObject> gysers = DynamicWater.inst.gysers;
		for (int i = 0; i < gysers.Count; i++)
		{
			if (!(gysers[i] == null))
			{
				Vector3 vector = gysers[i].transform.position - pos;
				vector.y = 0f;
				if (vector.magnitude < 1.5f)
				{
					return gysers[i];
				}
			}
		}
		return null;
	}

	private static ObjectHighlighter BuildGeyserHighlighter(GameObject geyser)
	{
		if (geyser == null)
		{
			return null;
		}
		List<MeshRenderer> renderers = new List<MeshRenderer>(geyser.GetComponentsInChildren<MeshRenderer>());
		List<SkinnedMeshRenderer> meshRenderers = new List<SkinnedMeshRenderer>(geyser.GetComponentsInChildren<SkinnedMeshRenderer>());
		return ObjectHighlighter.SetupOutlines(geyser, renderers, meshRenderers);
	}

	private static Vector3 SpringPosFromIndex(int index)
	{
		Vector3 result = new Vector3((float)(index % World.MeshWidth) * 0.5f, 0f, (float)(index / World.MeshWidth) * 0.5f);
		result.y = TerrainGen.inst.GetGroundHeight(result.x, result.z);
		return result;
	}

	private static void RestoreRockStates(List<RockState> states)
	{
		foreach (RockState state in states)
		{
			if (!(state.rock == null))
			{
				Bounds bounds = RockBounds(state.rock);
				state.rock.position = state.pos;
				state.rock.rotation = state.rot;
				state.rock.localScale = state.scale;
				if (MapEditorController.inst != null)
				{
					MapEditorController.inst.RebaselineFollow(state.rock);
				}
				ReclassifyWorldBounds(bounds);
				ReclassifyWorldBounds(RockBounds(state.rock));
			}
		}
	}

	private static DynamicWater.RiverCarveRecord RemoveSpringAt(int index)
	{
		DynamicWater.RiverCarveRecord result = DynamicWater.inst.UndoRiverCarveForEdit(index);
		DynamicWater.inst.RemoveWaterSource(index);
		DynamicWater.inst.RemoveCarveStrength(index);
		RemoveGeyserNear(SpringPosFromIndex(index));
		return result;
	}

	public static void RestoreSpring(int index, float rate, int strength = 2)
	{
		Cell cellData = World.inst.GetCellData(SpringPosFromIndex(index));
		if (IsValidSpringCell(cellData))
		{
			DynamicWater.inst.CreateWaterSourceNewMap(cellData, rate);
			int sourceIndex = DynamicWater.MapIndexWorldToMesh(cellData.index, World.inst.GridWidth);
			DynamicWater.inst.SetCarveStrength(sourceIndex, strength);
			ReclassifyCarve(DynamicWater.inst.CarveRiverFromSourceForEdit(sourceIndex));
		}
	}

	private static Transform RecreateRock(RockRecord r)
	{
		if (r.mesh == null || r.parent == null)
		{
			return null;
		}
		GameObject gameObject = new GameObject("Mountain Rock (restored)");
		gameObject.layer = LayerMask.NameToLayer("Terrain");
		gameObject.transform.SetParent(r.parent, worldPositionStays: true);
		gameObject.AddComponent<MeshFilter>().sharedMesh = r.mesh;
		gameObject.AddComponent<MeshRenderer>().sharedMaterial = r.material;
		gameObject.AddComponent<MeshCollider>().sharedMesh = r.mesh;
		gameObject.AddComponent<WaterDisplacementMesh>();
		gameObject.transform.position = r.pos;
		gameObject.transform.rotation = r.rot;
		gameObject.transform.localScale = r.scale;
		return gameObject.transform;
	}

	public static void AfterUndoRefresh(bool springsChanged)
	{
		if (springsChanged)
		{
			MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
		}
		MapEditorController inst = MapEditorController.inst;
		if (!(inst == null))
		{
			inst.RebuildFollowBaselines();
			inst.selectionTool.OnSelectionExternallyChanged();
		}
	}

	public void OnSelectionExternallyChanged()
	{
		ClearSelection();
		RefreshSprings();
		hoverRock = null;
		hoverSpring = null;
	}

	public void Tick()
	{
		selectedRocks.RemoveAll((Transform r) => r == null);
		bool flag = GameUI.inst.PointerOverUI();
		bool primaryDownThisFrame = PointingSystem.GetPointer().GetPrimaryDownThisFrame();
		Vector3 vector = CursorGroundPoint();
		Vector2 vector2 = Input.mousePosition;
		if (!flag && (Input.GetKeyDown(KeyCode.Delete) || Input.GetKeyDown(KeyCode.Backspace)))
		{
			DeleteSelected();
		}
		Ray ray = PointingSystem.GetPointer().GetRay();
		UpdateHandleGeometry();
		if (!movingSelection && !boxSelecting && handleDrag == HandleKind.None)
		{
			handleHover = ((!flag) ? HitTestHandles(ray) : HandleKind.None);
			hoverSpring = ((flag || handleHover != HandleKind.None) ? null : FindSpringNear(vector));
			hoverRock = ((flag || handleHover != HandleKind.None || hoverSpring != null) ? null : PickRock());
		}
		if (primaryDownThisFrame && !wasHeld && !flag)
		{
			if (handleHover != HandleKind.None)
			{
				pressScreen = vector2;
				BeginHandleDrag(ray);
			}
			else
			{
				OnPress(vector, vector2, ray);
			}
		}
		if (primaryDownThisFrame)
		{
			if (handleDrag != HandleKind.None)
			{
				UpdateHandleDrag(ray);
			}
			else if (movingSelection)
			{
				UpdateMove(vector, ray);
			}
		}
		else if (wasHeld)
		{
			if (handleDrag != HandleKind.None)
			{
				EndHandleDrag();
			}
			else if (movingSelection)
			{
				if ((vector2 - pressScreen).magnitude < 6f)
				{
					CancelMoveAsClick();
				}
				else
				{
					CommitMove();
				}
			}
			else if (boxSelecting)
			{
				CommitBox(vector2);
			}
		}
		if (PointingSystem.GetPointer().GetSecondaryDown())
		{
			secondaryDownScreen = vector2;
		}
		if (PointingSystem.GetPointer().GetSecondaryUp() && !flag && HasSelection && handleDrag == HandleKind.None && !movingSelection && !boxSelecting && (vector2 - secondaryDownScreen).magnitude < 6f)
		{
			ClearSelection();
		}
		wasHeld = primaryDownThisFrame;
		UpdateArmGhost(vector);
		MaintainHighlights();
		UpdateHandleGeometry();
		UpdateGizmoVisual();
		DrawOverlay(vector2);
	}

	private void UpdateHandleGeometry()
	{
		if (!HasSelection)
		{
			handleHover = HandleKind.None;
			gizmo.Hide();
		}
		else if (handleDrag == HandleKind.None)
		{
			handleAnchor = (HasRockSelection ? AverageRockPosition() : SelectionBounds().center);
			handleScale = MapSelectionGizmo.ScreenScale(Cam.inst.cam, handleAnchor);
			gizmoPos = handleAnchor;
			gizmoRadius = 5.9f * handleScale;
			gizmoStalkLength = 4f * handleScale;
			scaleOrientation = (HasRockSelection ? selectedRocks[0].rotation : Quaternion.identity);
			gizmoGround = new Vector3(gizmoPos.x, TerrainGen.inst.GetGroundHeight(gizmoPos.x, gizmoPos.z), gizmoPos.z);
		}
	}

	private static Vector2 ScreenPoint(Vector3 point)
	{
		return Cam.inst.cam.WorldToScreenPoint(point);
	}

	private static Vector2 PointerScreen(Ray ray)
	{
		return ScreenPoint(ray.GetPoint(10f));
	}

	private static float SegmentDistance(Vector2 point, Vector2 a, Vector2 b, out float fraction)
	{
		Vector2 vector = b - a;
		fraction = ((vector.sqrMagnitude > 0.001f) ? Mathf.Clamp01(Vector2.Dot(point - a, vector) / vector.sqrMagnitude) : 0f);
		return Vector2.Distance(point, a + vector * fraction);
	}

	private Vector3 RingPoint(float angle)
	{
		return gizmoPos + scaleOrientation * Quaternion.AngleAxis(angle, Vector3.up) * Vector3.right * (3f * handleScale);
	}

	private float RingDistance(Vector2 screen, out Vector3 localDirection)
	{
		float num = float.MaxValue;
		localDirection = Vector3.right;
		Vector2 a = ScreenPoint(RingPoint(0f));
		for (int i = 1; i <= 64; i++)
		{
			float angle = (float)i * 5.625f;
			Vector2 vector = ScreenPoint(RingPoint(angle));
			float num2 = SegmentDistance(screen, a, vector, out var fraction);
			if (num2 < num)
			{
				num = num2;
				localDirection = Quaternion.AngleAxis(((float)(i - 1) + fraction) * 5.625f, Vector3.up) * Vector3.right;
			}
			a = vector;
		}
		return num;
	}

	private Vector3 JoystickDirection(Ray ray)
	{
		float num = gizmoStalkLength;
		Vector3 lhs = ray.origin - dragPlane;
		float num2 = Vector3.Dot(lhs, ray.direction);
		float num3 = num2 * num2 - lhs.sqrMagnitude + num * num;
		if (num3 < 0f)
		{
			return (ray.GetPoint(Mathf.Max(0f, 0f - num2)) - dragPlane).normalized;
		}
		float num4 = Mathf.Sqrt(num3);
		Vector3 normalized = (ray.GetPoint(0f - num2 - num4) - dragPlane).normalized;
		Vector3 normalized2 = (ray.GetPoint(0f - num2 + num4) - dragPlane).normalized;
		if (!(Vector3.Dot(normalized, ringStartDirection) >= Vector3.Dot(normalized2, ringStartDirection)))
		{
			return normalized2;
		}
		return normalized;
	}

	private HandleKind HitTestHandles(Ray ray)
	{
		if (!HasRockSelection || movingSelection || boxSelecting || handleDrag != HandleKind.None)
		{
			return HandleKind.None;
		}
		Vector2 vector = PointerScreen(ray);
		Camera cam = Cam.inst.cam;
		float num = Mathf.Clamp(Vector2.Distance(ScreenPoint(gizmoPos), ScreenPoint(gizmoPos + cam.transform.right * handleScale)) * 0.3f, 8f, 16f);
		HandleKind handleKind = HandleKind.None;
		float num2 = float.MaxValue;
		if (Vector2.Distance(vector, ScreenPoint(JoystickTip)) < num + 2f)
		{
			handleKind = HandleKind.Tilt;
			num2 = MapSelectionGizmo.HandleDepth(cam, JoystickTip);
		}
		Vector3 vector2 = MapSelectionGizmo.BeadPosition(gizmoPos, gizmoStalkLength);
		Vector3 vector3 = MapSelectionGizmo.BeadRotation(cam, vector2) * Vector3.up * (handleScale * 0.35f);
		float num3 = MapSelectionGizmo.HandleDepth(cam, vector2);
		if (num3 < num2 && SegmentDistance(vector, ScreenPoint(vector2 - vector3), ScreenPoint(vector2 + vector3), out var fraction) < num)
		{
			handleKind = HandleKind.Lift;
			num2 = num3;
		}
		float num4 = MapSelectionGizmo.HandleDepth(cam, gizmoPos);
		if (num4 < num2 && Vector2.Distance(vector, ScreenPoint(gizmoPos)) < num)
		{
			handleKind = HandleKind.UniformScale;
			num2 = num4;
		}
		for (int i = 0; i < 3; i++)
		{
			Vector3 vector4 = MapSelectionGizmo.ScaleHandleAxis(cam, gizmoPos, scaleOrientation, i, handleScale);
			Vector3 vector5 = gizmoPos + vector4 * (MapSelectionGizmo.ScaleHandleDistance(i) * handleScale);
			Vector3 vector6 = MapSelectionGizmo.BillboardRotation(cam, vector5, vector4) * Vector3.up * (1.2f * MapSelectionGizmo.ScreenScale(cam, vector5) * 0.5f);
			float num5 = MapSelectionGizmo.HandleDepth(cam, vector5);
			if (SegmentDistance(vector, ScreenPoint(vector5 - vector6), ScreenPoint(vector5 + vector6), out fraction) < num && num5 < num2)
			{
				num2 = num5;
				handleKind = (HandleKind)(4 + i);
			}
		}
		if (handleKind != HandleKind.None)
		{
			return handleKind;
		}
		if (!(RingDistance(vector, out var _) < num))
		{
			return HandleKind.None;
		}
		return HandleKind.RotateY;
	}

	private void BeginHandleDrag(Ray ray)
	{
		handleDrag = handleHover;
		handleChanged = false;
		handleStartStates.Clear();
		foreach (Transform selectedRock in selectedRocks)
		{
			if (selectedRock != null)
			{
				handleStartStates.Add(new RockState
				{
					rock = selectedRock,
					pos = selectedRock.position,
					rot = selectedRock.rotation,
					scale = selectedRock.localScale
				});
			}
		}
		dragStartBounds = SelectionBounds();
		rotatePivot = AverageRockPosition();
		dragPlane = gizmoPos;
		pressScreen = PointerScreen(ray);
		float enter;
		if (handleDrag == HandleKind.Lift)
		{
			Vector3 normalized = Vector3.ProjectOnPlane(Cam.inst.cam.transform.forward, Vector3.up).normalized;
			handleDragPlane = new Plane(normalized, dragPlane);
			liftUsesPlane = normalized.sqrMagnitude > 0.5f && Mathf.Abs(Vector3.Dot(ray.direction, normalized)) > 0.05f && handleDragPlane.Raycast(ray, out enter);
			if (liftUsesPlane && handleDragPlane.Raycast(ray, out var enter2))
			{
				liftStartY = ray.GetPoint(enter2).y;
			}
			Vector3 vector = MapSelectionGizmo.BeadPosition(gizmoPos, gizmoStalkLength);
			Vector2 vector2 = ScreenPoint(vector + Vector3.up * handleScale) - ScreenPoint(vector);
			dragScreenAxis = ((vector2.sqrMagnitude > 1f) ? vector2.normalized : Vector2.up);
			dragScreenLength = Mathf.Max(12f, vector2.magnitude) / handleScale;
		}
		else if (handleDrag == HandleKind.MoveXZ)
		{
			handleDragPlane = new Plane(Vector3.up, dragPlane);
			if (handleDragPlane.Raycast(ray, out var enter3))
			{
				handleMoveStart = ray.GetPoint(enter3);
			}
			else
			{
				handleDrag = HandleKind.None;
			}
		}
		else if (handleDrag == HandleKind.Tilt)
		{
			ringStartDirection = scaleOrientation * Vector3.up;
			if (lastBallClickRock == selectedRocks[0] && Time.unscaledTime - lastBallClickTime < 0.3f && (pressScreen - lastBallClickScreen).sqrMagnitude < 36f)
			{
				ResetTiltToUpright();
				EndHandleDrag();
				lastBallClickTime = -1f;
				return;
			}
		}
		else if (handleDrag == HandleKind.RotateY)
		{
			rotationAxis = scaleOrientation * Vector3.up;
			RingDistance(pressScreen, out ringKnobDirection);
			ringStartDirection = scaleOrientation * ringKnobDirection;
			Vector3 vector3 = gizmoPos + ringStartDirection * (3f * handleScale);
			Vector3 vector4 = Vector3.Cross(rotationAxis, ringStartDirection);
			Vector2 vector5 = ScreenPoint(vector3 + vector4 * (3f * handleScale)) - ScreenPoint(vector3);
			dragScreenLength = Mathf.Max(30f, vector5.magnitude);
			dragScreenAxis = ((vector5.sqrMagnitude > 1f) ? vector5.normalized : Vector2.right);
			handleDragPlane = new Plane(rotationAxis, gizmoPos);
			ringUsesPlane = Mathf.Abs(Vector3.Dot(ray.direction, rotationAxis)) > 0.2f && handleDragPlane.Raycast(ray, out enter);
			if (ringUsesPlane && handleDragPlane.Raycast(ray, out var enter4))
			{
				ringStartDirection = (ray.GetPoint(enter4) - gizmoPos).normalized;
			}
			rotationAngle = 0f;
			lastRingAngle = 0f;
		}
		else
		{
			int num = (int)(handleDrag - 4);
			bool flag = handleDrag == HandleKind.UniformScale;
			Vector2 vector6 = (flag ? (Vector2.one.normalized * Vector2.Distance(ScreenPoint(gizmoPos), ScreenPoint(gizmoPos + Cam.inst.cam.transform.right * gizmoRadius))) : (ScreenPoint(gizmoPos + MapSelectionGizmo.ScaleHandleAxis(Cam.inst.cam, gizmoPos, scaleOrientation, num, handleScale) * (MapSelectionGizmo.ScaleHandleDistance(num) * handleScale)) - ScreenPoint(gizmoPos)));
			dragScreenLength = Mathf.Max(50f, vector6.magnitude);
			dragScreenAxis = ((vector6.sqrMagnitude > 25f) ? vector6.normalized : Vector2.up);
			scaleFactorMin = 0f;
			scaleFactorMax = float.MaxValue;
			foreach (RockState handleStartState in handleStartStates)
			{
				float b = (flag ? Mathf.Min(handleStartState.scale.x, handleStartState.scale.y, handleStartState.scale.z) : handleStartState.scale[num]);
				float b2 = (flag ? Mathf.Max(handleStartState.scale.x, handleStartState.scale.y, handleStartState.scale.z) : handleStartState.scale[num]);
				scaleFactorMin = Mathf.Max(scaleFactorMin, 0.05f / Mathf.Max(0.05f, b));
				scaleFactorMax = Mathf.Min(scaleFactorMax, 12f / Mathf.Max(0.05f, b2));
			}
		}
		lastBallClickTime = -1f;
	}

	private void ResetTiltToUpright()
	{
		foreach (RockState handleStartState in handleStartStates)
		{
			if (!(handleStartState.rock == null) && !(Vector3.Angle(handleStartState.rot * Vector3.up, Vector3.up) < 0.1f))
			{
				CaptureHandleUndo();
				handleStartState.rock.rotation = Quaternion.FromToRotation(handleStartState.rot * Vector3.up, Vector3.up) * handleStartState.rot;
			}
		}
		UpdateSelectionErrors();
	}

	private void CaptureHandleUndo()
	{
		if (!handleChanged)
		{
			RockButtonsUndo rockButtonsUndo = new RockButtonsUndo();
			rockButtonsUndo.rocks.AddRange(handleStartStates);
			MapEditorUndoStack.Push(rockButtonsUndo);
			handleChanged = true;
		}
	}

	private void UpdateHandleDrag(Ray ray)
	{
		Vector2 vector = PointerScreen(ray) - pressScreen;
		if (!handleChanged && vector.sqrMagnitude < 1f)
		{
			return;
		}
		CaptureHandleUndo();
		if (handleDrag >= HandleKind.ScaleX && handleDrag <= HandleKind.UniformScale)
		{
			float num = Mathf.Clamp(1f + Vector2.Dot(vector, dragScreenAxis) / dragScreenLength, scaleFactorMin, scaleFactorMax);
			bool flag = handleDrag == HandleKind.UniformScale;
			int index = (int)(handleDrag - 4);
			foreach (RockState handleStartState in handleStartStates)
			{
				if (!(handleStartState.rock == null))
				{
					Vector3 scale = handleStartState.scale;
					if (flag)
					{
						scale *= num;
					}
					else
					{
						scale[index] *= num;
					}
					handleStartState.rock.localScale = new Vector3(Mathf.Max(0.05f, scale.x), Mathf.Max(0.05f, scale.y), Mathf.Max(0.05f, scale.z));
					handleStartState.rock.position = (flag ? (rotatePivot + (handleStartState.pos - rotatePivot) * num) : handleStartState.pos);
				}
			}
		}
		else if (handleDrag == HandleKind.Lift)
		{
			float num2;
			if (liftUsesPlane)
			{
				if (!handleDragPlane.Raycast(ray, out var enter))
				{
					return;
				}
				num2 = ray.GetPoint(enter).y - liftStartY;
			}
			else
			{
				num2 = Vector2.Dot(vector, dragScreenAxis) / dragScreenLength;
			}
			foreach (RockState handleStartState2 in handleStartStates)
			{
				if (handleStartState2.rock != null)
				{
					handleStartState2.rock.position = handleStartState2.pos + Vector3.up * num2;
				}
			}
		}
		else if (handleDrag == HandleKind.MoveXZ)
		{
			if (handleDragPlane.Raycast(ray, out var enter2))
			{
				Vector3 vector2 = ray.GetPoint(enter2) - handleMoveStart;
				vector2.y = 0f;
				foreach (RockState handleStartState3 in handleStartStates)
				{
					if (handleStartState3.rock != null)
					{
						handleStartState3.rock.position = handleStartState3.pos + vector2;
					}
				}
			}
		}
		else if (handleDrag == HandleKind.Tilt)
		{
			Vector2 vector3 = ScreenPoint(JoystickTip) + vector;
			Vector3 toDirection = JoystickDirection(Cam.inst.cam.ScreenPointToRay(vector3));
			ApplyHandleRotation(Quaternion.FromToRotation(ringStartDirection, toDirection));
		}
		else
		{
			if (ringUsesPlane)
			{
				if (handleDragPlane.Raycast(ray, out var enter3))
				{
					float target = Vector3.SignedAngle(ringStartDirection, ray.GetPoint(enter3) - gizmoPos, rotationAxis);
					rotationAngle += Mathf.DeltaAngle(lastRingAngle, target);
					lastRingAngle = target;
				}
			}
			else
			{
				rotationAngle = Vector2.Dot(vector, dragScreenAxis) / dragScreenLength * 57.29578f;
			}
			ApplyHandleRotation(Quaternion.AngleAxis(rotationAngle, rotationAxis));
		}
		UpdateSelectionErrors();
	}

	private void ApplyHandleRotation(Quaternion spin)
	{
		foreach (RockState handleStartState in handleStartStates)
		{
			if (!(handleStartState.rock == null))
			{
				handleStartState.rock.position = rotatePivot + spin * (handleStartState.pos - rotatePivot);
				handleStartState.rock.rotation = spin * handleStartState.rot;
			}
		}
	}

	private void EndHandleDrag()
	{
		if (handleDrag == HandleKind.Tilt && !handleChanged)
		{
			lastBallClickTime = Time.unscaledTime;
			lastBallClickScreen = pressScreen;
			lastBallClickRock = selectedRocks[0];
		}
		handleDrag = HandleKind.None;
		if (!handleChanged)
		{
			return;
		}
		foreach (Transform selectedRock in selectedRocks)
		{
			MapEditorController.inst.RebaselineFollow(selectedRock);
		}
		Physics.SyncTransforms();
		ReclassifyWorldBounds(dragStartBounds);
		ReclassifyWorldBounds(SelectionBounds());
		RefreshFollow();
	}

	private ObjectHighlighter GetRockHighlighter(Transform rock)
	{
		if (!rockHighlighters.TryGetValue(rock, out var value))
		{
			value = ObjectHighlighter.SetupOutline(rock.gameObject, rock.GetComponent<MeshRenderer>(), null);
			rockHighlighters[rock] = value;
		}
		return value;
	}

	private void MaintainHighlights()
	{
		foreach (Transform selectedRock in selectedRocks)
		{
			if (selectedRock != null)
			{
				GetRockHighlighter(selectedRock).SetOutlineImmediate(1);
			}
		}
		if (hoverRock != null && !selectedRocks.Contains(hoverRock))
		{
			GetRockHighlighter(hoverRock).SetOutlineImmediate(0);
		}
		foreach (SpringMarker allSpring in allSprings)
		{
			if (allSpring.highlighter != null)
			{
				if (allSpring.selected)
				{
					allSpring.highlighter.SetOutlineImmediate(1);
				}
				else if (allSpring == hoverSpring)
				{
					allSpring.highlighter.SetOutlineImmediate(0);
				}
			}
		}
		errorRocks.RemoveWhere((Transform r) => r == null);
		foreach (Transform errorRock in errorRocks)
		{
			GetRockHighlighter(errorRock).SetOutlineImmediate(2);
		}
	}

	private void UpdateArmGhost(Vector3 cursor)
	{
		if (armAddSpring)
		{
			if (armGhost == null)
			{
				armGhost = Object.Instantiate(DynamicWater.inst.gyserPrefab);
			}
			armGhost.transform.position = cursor;
		}
		else if (armGhost != null)
		{
			Object.Destroy(armGhost);
			armGhost = null;
		}
	}

	private void OnPress(Vector3 cursor, Vector2 screen, Ray ray)
	{
		pressScreen = screen;
		if (armAddSpring)
		{
			armAddSpring = false;
			AddSpring(cursor);
		}
		else if (!Input.GetKey(KeyCode.LeftShift) && !Input.GetKey(KeyCode.RightShift) && ((hoverRock != null && selectedRocks.Contains(hoverRock)) || (hoverSpring != null && hoverSpring.selected)))
		{
			BeginMove(ray);
		}
		else
		{
			boxSelecting = true;
		}
	}

	private void BeginMove(Ray ray)
	{
		Vector3 inPoint = (rotatePivot = AverageRockPosition());
		if (HasRockSelection)
		{
			handleDragPlane = new Plane(Vector3.up, inPoint);
			if (!handleDragPlane.Raycast(ray, out var enter))
			{
				return;
			}
			handleMoveStart = ray.GetPoint(enter);
		}
		movingSelection = true;
		pendingMoveStates = new List<RockState>();
		foreach (Transform selectedRock in selectedRocks)
		{
			pendingMoveStates.Add(new RockState
			{
				rock = selectedRock,
				pos = selectedRock.position,
				rot = selectedRock.rotation,
				scale = selectedRock.localScale
			});
		}
		foreach (SpringMarker allSpring in allSprings)
		{
			allSpring.dragPos = allSpring.pos;
		}
		dragStartBounds = SelectionBounds();
	}

	private void UpdateMove(Vector3 cursor, Ray ray)
	{
		if (selectedRocks.Count > 0 && handleDragPlane.Raycast(ray, out var enter))
		{
			Vector3 vector = ray.GetPoint(enter) - handleMoveStart;
			vector.y = 0f;
			foreach (RockState pendingMoveState in pendingMoveStates)
			{
				if (pendingMoveState.rock != null)
				{
					pendingMoveState.rock.position = pendingMoveState.pos + vector;
				}
			}
			UpdateSelectionErrors();
		}
		Vector3 vector2 = CursorGroundFromScreen(pressScreen);
		Vector3 vector3 = cursor - vector2;
		vector3.y = 0f;
		foreach (SpringMarker allSpring in allSprings)
		{
			if (allSpring.selected)
			{
				Vector3 vector4 = allSpring.pos + vector3;
				vector4.y = TerrainGen.inst.GetGroundHeight(vector4.x, vector4.z);
				allSpring.dragPos = vector4;
				if (allSpring.geyser != null)
				{
					allSpring.geyser.transform.position = vector4;
				}
			}
		}
	}

	private void CancelMoveAsClick()
	{
		movingSelection = false;
		if (pendingMoveStates != null)
		{
			foreach (RockState pendingMoveState in pendingMoveStates)
			{
				if (pendingMoveState.rock != null)
				{
					pendingMoveState.rock.position = pendingMoveState.pos;
					pendingMoveState.rock.rotation = pendingMoveState.rot;
				}
			}
			pendingMoveStates = null;
			UpdateSelectionErrors();
		}
		foreach (SpringMarker allSpring in allSprings)
		{
			if (allSpring.selected)
			{
				allSpring.dragPos = allSpring.pos;
				if (allSpring.geyser != null)
				{
					allSpring.geyser.transform.position = allSpring.pos;
				}
			}
		}
		if (hoverRock != null)
		{
			ClearSelection();
			selectedRocks.Add(hoverRock);
		}
		else if (hoverSpring != null)
		{
			ClearSelection();
			hoverSpring.selected = true;
		}
	}

	private void CommitMove()
	{
		movingSelection = false;
		if (selectedRocks.Count > 0)
		{
			ReclassifyWorldBounds(dragStartBounds);
			ReclassifyWorldBounds(SelectionBounds());
			if (MapEditorController.inst != null)
			{
				foreach (Transform selectedRock in selectedRocks)
				{
					MapEditorController.inst.RebaselineFollow(selectedRock);
				}
			}
		}
		SelectionMoveUndo selectionMoveUndo = new SelectionMoveUndo();
		if (pendingMoveStates != null)
		{
			foreach (RockState pendingMoveState in pendingMoveStates)
			{
				if (pendingMoveState.rock != null && ((pendingMoveState.rock.position - pendingMoveState.pos).sqrMagnitude > 0.0001f || Quaternion.Angle(pendingMoveState.rock.rotation, pendingMoveState.rot) > 0.01f))
				{
					selectionMoveUndo.rocks.Add(pendingMoveState);
				}
			}
			pendingMoveStates = null;
		}
		bool flag = false;
		foreach (SpringMarker allSpring in allSprings)
		{
			if (!allSpring.selected)
			{
				continue;
			}
			if (allSpring.geyser != null)
			{
				allSpring.geyser.transform.position = allSpring.pos;
			}
			Vector3 vector = allSpring.dragPos - allSpring.pos;
			vector.y = 0f;
			if (!(vector.magnitude < 1f))
			{
				int index = allSpring.index;
				if (MoveSpring(allSpring, allSpring.dragPos))
				{
					flag = true;
					selectionMoveUndo.springs.Add(new SpringMoveRecord
					{
						fromIndex = index,
						toIndex = allSpring.index,
						rate = allSpring.rate
					});
				}
			}
		}
		if (selectionMoveUndo.rocks.Count > 0 || selectionMoveUndo.springs.Count > 0)
		{
			MapEditorUndoStack.Push(selectionMoveUndo);
		}
		if (flag)
		{
			MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
			ReselectSpringsAfterRefresh();
		}
		if (MapEditorController.inst != null)
		{
			MapEditorController.inst.RebuildFollowBaselines();
		}
	}

	private void ReselectSpringsAfterRefresh()
	{
		_reselect.Clear();
		foreach (SpringMarker allSpring in allSprings)
		{
			if (allSpring.selected)
			{
				_reselect.Add(allSpring.index);
			}
		}
		RefreshSprings();
		foreach (SpringMarker allSpring2 in allSprings)
		{
			allSpring2.selected = _reselect.Contains(allSpring2.index);
		}
	}

	private void CommitBox(Vector2 screen)
	{
		boxSelecting = false;
		bool flag = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);
		if ((screen - pressScreen).magnitude < 6f)
		{
			if (hoverSpring != null || hoverRock != null)
			{
				bool flag2 = ((hoverSpring != null) ? hoverSpring.selected : selectedRocks.Contains(hoverRock));
				if (flag & flag2)
				{
					if (hoverSpring != null)
					{
						hoverSpring.selected = false;
					}
					else
					{
						selectedRocks.Remove(hoverRock);
					}
					return;
				}
				if (!flag)
				{
					ClearSelection();
				}
				if (hoverSpring != null)
				{
					hoverSpring.selected = true;
				}
				else if (!selectedRocks.Contains(hoverRock))
				{
					selectedRocks.Add(hoverRock);
				}
			}
			else if (!flag)
			{
				ClearSelection();
			}
			return;
		}
		if (!flag)
		{
			ClearSelection();
		}
		Vector2 vector = Vector2.Min(pressScreen, screen);
		Vector2 vector2 = Vector2.Max(pressScreen, screen);
		Camera cam = Cam.inst.cam;
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
					Vector3 vector3 = cam.WorldToScreenPoint(child.position);
					if (vector3.z > 0f && vector3.x >= vector.x && vector3.x <= vector2.x && vector3.y >= vector.y && vector3.y <= vector2.y && !selectedRocks.Contains(child))
					{
						selectedRocks.Add(child);
					}
				}
			}
		}
		foreach (SpringMarker allSpring in allSprings)
		{
			Vector3 vector4 = cam.WorldToScreenPoint(allSpring.pos);
			if (vector4.z > 0f && vector4.x >= vector.x && vector4.x <= vector2.x && vector4.y >= vector.y && vector4.y <= vector2.y)
			{
				allSpring.selected = true;
			}
		}
	}

	private void CaptureButtonUndo()
	{
		if (MapEditorUndoStack.Peek() is RockButtonsUndo rockButtonsUndo && rockButtonsUndo.Matches(selectedRocks))
		{
			return;
		}
		RockButtonsUndo rockButtonsUndo2 = new RockButtonsUndo();
		foreach (Transform selectedRock in selectedRocks)
		{
			if (selectedRock != null)
			{
				rockButtonsUndo2.rocks.Add(new RockState
				{
					rock = selectedRock,
					pos = selectedRock.position,
					rot = selectedRock.rotation,
					scale = selectedRock.localScale
				});
			}
		}
		if (rockButtonsUndo2.rocks.Count > 0)
		{
			MapEditorUndoStack.Push(rockButtonsUndo2);
		}
	}

	public void RotateSelected(float sign)
	{
		CaptureButtonUndo();
		Vector3 vector = AverageRockPosition();
		Quaternion quaternion2 = Quaternion.AngleAxis(sign * 15f, Vector3.up);
		foreach (Transform selectedRock in selectedRocks)
		{
			if (!(selectedRock == null))
			{
				Bounds bounds = RockBounds(selectedRock);
				selectedRock.position = vector + quaternion2 * (selectedRock.position - vector);
				selectedRock.rotation = quaternion2 * selectedRock.rotation;
				if (MapEditorController.inst != null)
				{
					MapEditorController.inst.RebaselineFollow(selectedRock);
				}
				ReclassifyWorldBounds(bounds);
				ReclassifyWorldBounds(RockBounds(selectedRock));
			}
		}
		UpdateSelectionErrors();
		RefreshFollow();
	}

	public void NudgeSelected(float sign)
	{
		CaptureButtonUndo();
		foreach (Transform selectedRock in selectedRocks)
		{
			if (!(selectedRock == null))
			{
				Vector3 position = selectedRock.position;
				position.y += sign * 0.25f;
				selectedRock.position = position;
				if (MapEditorController.inst != null)
				{
					MapEditorController.inst.RebaselineFollow(selectedRock);
				}
				ReclassifyWorldBounds(RockBounds(selectedRock));
			}
		}
		UpdateSelectionErrors();
		RefreshFollow();
	}

	public void DuplicateSelected()
	{
		List<Transform> list = new List<Transform>();
		foreach (Transform selectedRock in selectedRocks)
		{
			if (!(selectedRock == null))
			{
				Transform transform = Object.Instantiate(selectedRock.gameObject, selectedRock.parent).transform;
				float num = HeightAboveGround(selectedRock);
				Vector3 position = selectedRock.position + new Vector3(2f, 0f, 2f);
				position.y = TerrainGen.inst.GetGroundHeight(position.x, position.z) + num;
				transform.position = position;
				ClampToBand(transform);
				ReclassifyWorldBounds(RockBounds(transform));
				list.Add(transform);
			}
		}
		if (list.Count > 0)
		{
			DuplicateUndo duplicateUndo = new DuplicateUndo();
			duplicateUndo.clones.AddRange(list);
			MapEditorUndoStack.Push(duplicateUndo);
			selectedRocks.Clear();
			selectedRocks.AddRange(list);
			RefreshFollow();
		}
	}

	public void SpawnRockFromPicker(int meshIdx)
	{
		List<Mesh> mountainRockMeshes = TerrainGen.inst.mountainRockMeshes;
		if (meshIdx < 0 || meshIdx >= mountainRockMeshes.Count)
		{
			return;
		}
		GameObject gameObject = TerrainGen.inst.mountainRocks.Find((GameObject g) => g != null && g.name == "Mountain Group: Editor");
		if (gameObject == null)
		{
			Transform transform = TerrainGen.inst.mountainContainer;
			if (transform == null)
			{
				transform = new GameObject("Mountain Container").transform;
				TerrainGen.inst.mountainContainer = transform;
			}
			gameObject = new GameObject("Mountain Group: Editor");
			gameObject.transform.SetParent(transform);
			TerrainGen.inst.mountainRocks.Add(gameObject);
		}
		Vector3 pos = CursorGroundFromRay(Cam.inst.cam.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0f)));
		Transform transform2 = RecreateRock(new RockRecord
		{
			mesh = mountainRockMeshes[meshIdx],
			material = World.inst.romeMountainUnimaterial,
			parent = gameObject.transform,
			pos = pos,
			rot = Quaternion.identity,
			scale = Vector3.one
		});
		if (!(transform2 == null))
		{
			ClampToBand(transform2);
			ReclassifyWorldBounds(RockBounds(transform2));
			MapEditorUndoStack.Push(new DuplicateUndo
			{
				clones = { transform2 }
			});
			ClearSelection();
			selectedRocks.Add(transform2);
			RefreshFollow();
		}
	}

	public void DeleteSelected()
	{
		DeleteUndo deleteUndo = new DeleteUndo();
		if (selectedRocks.Count > 0)
		{
			Bounds bounds = SelectionBounds();
			foreach (Transform selectedRock in selectedRocks)
			{
				if (!(selectedRock == null))
				{
					MeshFilter component = selectedRock.GetComponent<MeshFilter>();
					MeshRenderer component2 = selectedRock.GetComponent<MeshRenderer>();
					deleteUndo.rocks.Add(new RockRecord
					{
						mesh = ((component != null) ? component.sharedMesh : null),
						material = ((component2 != null) ? component2.sharedMaterial : null),
						parent = selectedRock.parent,
						pos = selectedRock.position,
						rot = selectedRock.rotation,
						scale = selectedRock.localScale
					});
					selectedRock.gameObject.SetActive(value: false);
					Object.Destroy(selectedRock.gameObject);
				}
			}
			selectedRocks.Clear();
			MapEditorController.inst.StartCoroutine(ReclassifyNextFrameRoutine(bounds));
		}
		bool flag = false;
		foreach (SpringMarker allSpring in allSprings)
		{
			if (allSpring.selected)
			{
				deleteUndo.springs.Add(new SpringRecord
				{
					index = allSpring.index,
					rate = allSpring.rate,
					strength = DynamicWater.inst.GetCarveStrength(allSpring.index)
				});
				RemoveSpringAt(allSpring.index);
				flag = true;
			}
		}
		if (flag)
		{
			MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
			RefreshSprings();
		}
		if (deleteUndo.rocks.Count > 0 || deleteUndo.springs.Count > 0)
		{
			MapEditorUndoStack.Push(deleteUndo);
		}
		hoverRock = null;
		hoverSpring = null;
		RefreshFollow();
	}

	private static void RefreshFollow()
	{
		if (MapEditorController.inst != null)
		{
			MapEditorController.inst.RebuildFollowBaselines();
		}
	}

	private SpringMarker FindSpringNear(Vector3 point)
	{
		SpringMarker result = null;
		float num = 2f;
		foreach (SpringMarker allSpring in allSprings)
		{
			Vector3 vector = allSpring.pos - point;
			vector.y = 0f;
			if (vector.magnitude < num)
			{
				num = vector.magnitude;
				result = allSpring;
			}
		}
		return result;
	}

	private static bool IsValidSpringCell(Cell cell)
	{
		if (cell != null && cell.landMassIdx != -1)
		{
			return cell.Type != TerrainType.Water;
		}
		return false;
	}

	public static List<SculptCasualtyLog.RecarvedSpring> RecarveSpringsTouchedByStroke(ICollection<int> strokeVerts)
	{
		List<SculptCasualtyLog.RecarvedSpring> list = new List<SculptCasualtyLog.RecarvedSpring>();
		foreach (DynamicWater.SavedWaterSource item in DynamicWater.inst.CollectPersistentSources())
		{
			int num = item.index % World.MeshWidth / 2;
			int num2 = item.index / World.MeshWidth / 2;
			bool flag = false;
			for (int i = 0; i <= 2; i++)
			{
				if (flag)
				{
					break;
				}
				for (int j = 0; j <= 2; j++)
				{
					if (flag)
					{
						break;
					}
					if (strokeVerts.Contains(num * 2 + j + (num2 * 2 + i) * World.MeshWidth))
					{
						flag = true;
					}
				}
			}
			if (flag)
			{
				DynamicWater.RiverCarveRecord preRecord = RecarveSpring(item.index);
				list.Add(new SculptCasualtyLog.RecarvedSpring
				{
					index = item.index,
					preRecord = preRecord
				});
			}
		}
		if (list.Count > 0)
		{
			AfterUndoRefresh(springsChanged: true);
		}
		return list;
	}

	public static DynamicWater.RiverCarveRecord RecarveSpring(int index)
	{
		DynamicWater.RiverCarveRecord result = DynamicWater.inst.UndoRiverCarveForEdit(index);
		ReclassifyCarve(DynamicWater.inst.CarveRiverFromSourceForEdit(index));
		ReseatGeyser(index);
		return result;
	}

	public static void ReseatGeyser(int index)
	{
		Vector3 pos = SpringPosFromIndex(index);
		GameObject gameObject = GeyserNear(pos);
		if (gameObject != null)
		{
			Vector3 position = gameObject.transform.position;
			gameObject.transform.position = new Vector3(position.x, pos.y, position.z);
		}
	}

	public static void RestoreSpringWithCarveRecord(int index, float rate, int strength, DynamicWater.RiverCarveRecord record)
	{
		Cell cellData = World.inst.GetCellData(SpringPosFromIndex(index));
		if (cellData != null)
		{
			DynamicWater.inst.CreateWaterSourceNewMap(cellData, rate);
			int num = DynamicWater.MapIndexWorldToMesh(cellData.index, World.inst.GridWidth);
			DynamicWater.inst.SetCarveStrength(num, strength);
			if (record != null)
			{
				DynamicWater.inst.ReapplyCarveRecord(num, record);
			}
			else
			{
				ReclassifyCarve(DynamicWater.inst.CarveRiverFromSourceForEdit(num));
			}
			ReseatGeyser(num);
		}
	}

	public static void DrownSpringsBelowWater()
	{
		List<DynamicWater.SavedWaterSource> list = DynamicWater.inst.CollectPersistentSources();
		bool flag = false;
		foreach (DynamicWater.SavedWaterSource item in list)
		{
			Vector3 worldPos = SpringPosFromIndex(item.index);
			Cell cellData = World.inst.GetCellData(worldPos);
			if (cellData == null || cellData.Type == TerrainType.Water || !(worldPos.y >= TerrainGen.waterHeightTestThresold))
			{
				int carveStrength = DynamicWater.inst.GetCarveStrength(item.index);
				DynamicWater.RiverCarveRecord record = RemoveSpringAt(item.index);
				SculptCasualtyLog.springs.Add(new SculptCasualtyLog.DrownedSpring
				{
					index = item.index,
					rate = item.rate,
					strength = carveStrength,
					record = record
				});
				flag = true;
			}
		}
		if (flag)
		{
			AfterUndoRefresh(springsChanged: true);
		}
	}

	private bool MoveSpring(SpringMarker marker, Vector3 target)
	{
		Cell cellData = World.inst.GetCellData(target);
		if (!IsValidSpringCell(cellData))
		{
			return false;
		}
		DynamicWater.inst.UndoRiverCarveForEdit(marker.index);
		DynamicWater.inst.RemoveWaterSource(marker.index);
		RemoveGeyserNear(marker.pos);
		DynamicWater.inst.CreateWaterSourceNewMap(cellData, marker.rate);
		int num = DynamicWater.MapIndexWorldToMesh(cellData.index, World.inst.GridWidth);
		DynamicWater.inst.MoveCarveStrength(marker.index, num);
		ReclassifyCarve(DynamicWater.inst.CarveRiverFromSourceForEdit(num));
		marker.index = num;
		return true;
	}

	private void AddSpring(Vector3 target)
	{
		Cell cellData = World.inst.GetCellData(target);
		if (!IsValidSpringCell(cellData))
		{
			return;
		}
		int num = DynamicWater.MapIndexWorldToMesh(cellData.index, World.inst.GridWidth);
		DynamicWater.inst.CreateWaterSourceNewMap(cellData, DynamicWater.inst.sourceAmount);
		ReclassifyCarve(DynamicWater.inst.CarveRiverFromSourceForEdit(num));
		MapEditorUndoStack.Push(new SpringAddUndo
		{
			index = num
		});
		MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
		RefreshSprings();
		foreach (SpringMarker allSpring in allSprings)
		{
			allSpring.selected = allSpring.index == num;
		}
	}

	public static void RemoveGeyserNear(Vector3 pos)
	{
		GameObject gameObject = GeyserNear(pos);
		if (gameObject != null)
		{
			Object.Destroy(gameObject);
			DynamicWater.inst.gysers.Remove(gameObject);
		}
	}

	private static void ReclassifyCarve(DynamicWater.RiverCarveRecord rec)
	{
		if (rec == null || rec.verts.Length == 0)
		{
			return;
		}
		int num = int.MaxValue;
		int num2 = int.MaxValue;
		int num3 = int.MinValue;
		int num4 = int.MinValue;
		for (int i = 0; i < rec.verts.Length; i++)
		{
			int num5 = rec.verts[i] % World.MeshWidth;
			int num6 = rec.verts[i] / World.MeshWidth;
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
		TerrainRockReclassifier.ReclassifyVertRect(num, num2, num3, num4);
	}

	private Transform PickRock()
	{
		int num = Physics.RaycastNonAlloc(PointingSystem.GetPointer().GetRay(), _rayHits, 1000f, LayerMask.GetMask("Terrain"));
		float num2 = float.MaxValue;
		Transform result = null;
		float num3 = float.MaxValue;
		Transform transform = null;
		for (int i = 0; i < num; i++)
		{
			Collider collider = _rayHits[i].collider;
			if (!(collider.GetComponentInParent<TerrainChunk>() != null) && !(collider.GetComponentInParent<TerrainResource>() != null) && TryResolveRock(collider.transform, out var rock))
			{
				if (_rayHits[i].distance < num2)
				{
					num2 = _rayHits[i].distance;
					result = rock;
				}
				if (selectedRocks.Contains(rock) && _rayHits[i].distance < num3)
				{
					num3 = _rayHits[i].distance;
					transform = rock;
				}
			}
		}
		if (!(transform != null))
		{
			return result;
		}
		return transform;
	}

	private static bool TryResolveRock(Transform hit, out Transform rock)
	{
		rock = null;
		List<GameObject> mountainRocks = TerrainGen.inst.mountainRocks;
		Transform transform = hit;
		while (transform != null)
		{
			for (int i = 0; i < mountainRocks.Count; i++)
			{
				if (mountainRocks[i] == null || mountainRocks[i].transform != transform)
				{
					continue;
				}
				MountainPlacer component = transform.GetComponent<MountainPlacer>();
				Transform transform2 = ((component != null) ? component.RocksContainer : transform);
				Transform transform3 = hit;
				while (transform3 != null)
				{
					if (transform3.parent == transform2)
					{
						rock = transform3;
						return true;
					}
					transform3 = transform3.parent;
				}
				return false;
			}
			transform = transform.parent;
		}
		return false;
	}

	private static float HeightAboveGround(Transform rock)
	{
		return rock.position.y - TerrainGen.inst.GetGroundHeight(rock.position.x, rock.position.z);
	}

	private static Bounds RockBounds(Transform rock)
	{
		MeshRenderer component = rock.GetComponent<MeshRenderer>();
		if (!(component != null))
		{
			return new Bounds(rock.position, Vector3.one);
		}
		return component.bounds;
	}

	public Bounds SelectionBounds()
	{
		bool flag = false;
		Bounds result = default;
		foreach (Transform selectedRock in selectedRocks)
		{
			if (!(selectedRock == null))
			{
				Bounds bounds = RockBounds(selectedRock);
				if (!flag)
				{
					result = bounds;
					flag = true;
				}
				else
				{
					result.Encapsulate(bounds);
				}
			}
		}
		foreach (SpringMarker allSpring in allSprings)
		{
			if (allSpring.selected)
			{
				Bounds bounds2 = new Bounds(allSpring.pos, Vector3.one * 2f);
				if (!flag)
				{
					result = bounds2;
					flag = true;
				}
				else
				{
					result.Encapsulate(bounds2);
				}
			}
		}
		if (!flag)
		{
			return new Bounds(Vector3.zero, Vector3.zero);
		}
		return result;
	}

	private Vector3 AverageRockPosition()
	{
		Vector3 zero = Vector3.zero;
		int num = 0;
		foreach (Transform selectedRock in selectedRocks)
		{
			if (!(selectedRock == null))
			{
				zero += selectedRock.position;
				num++;
			}
		}
		if (num <= 0)
		{
			return Vector3.zero;
		}
		return zero / num;
	}

	public static bool IsRockFloating(Transform rock)
	{
		Mesh mesh = RockMesh(rock);
		if (mesh == null)
		{
			return false;
		}
		float mESH_TO_TERRAIN_THRESHOLD = MountainPlacer.MESH_TO_TERRAIN_THRESHOLD;
		float num = Water.inst.transform.position.y + mESH_TO_TERRAIN_THRESHOLD;
		Matrix4x4 localToWorldMatrix = rock.localToWorldMatrix;
		Vector3 lhs = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
		Vector3 lhs2 = new Vector3(float.MinValue, float.MinValue, float.MinValue);
		mesh.GetVertices(contactVertices);
		for (int i = 0; i < contactVertices.Count; i++)
		{
			Vector3 vector = localToWorldMatrix.MultiplyPoint3x4(contactVertices[i]);
			if (vector.y <= num || vector.y <= TerrainGen.inst.GetGroundHeight(vector.x, vector.z) + mESH_TO_TERRAIN_THRESHOLD)
			{
				return false;
			}
			contactVertices[i] = vector;
			lhs = Vector3.Min(lhs, vector);
			lhs2 = Vector3.Max(lhs2, vector);
		}
		float num2 = float.MinValue;
		int num3 = Mathf.Max(0, Mathf.FloorToInt(lhs.x * 2f));
		int num4 = Mathf.Min(World.inst.GridWidth * 2, Mathf.CeilToInt(lhs2.x * 2f));
		int num5 = Mathf.Max(0, Mathf.FloorToInt(lhs.z * 2f));
		int num6 = Mathf.Min(World.inst.GridHeight * 2, Mathf.CeilToInt(lhs2.z * 2f));
		for (int j = num5; j <= num6; j++)
		{
			for (int k = num3; k <= num4; k++)
			{
				num2 = Mathf.Max(num2, TerrainGen.inst.GetVertY(k, j));
			}
		}
		if (lhs.y > num2 + mESH_TO_TERRAIN_THRESHOLD)
		{
			return true;
		}
		for (int l = 0; l < mesh.subMeshCount; l++)
		{
			mesh.GetTriangles(contactTriangles, l);
			for (int m = 0; m < contactTriangles.Count; m += 3)
			{
				Vector3 a = contactVertices[contactTriangles[m]];
				Vector3 b = contactVertices[contactTriangles[m + 1]];
				Vector3 c = contactVertices[contactTriangles[m + 2]];
				int num7 = Mathf.Max(0, Mathf.FloorToInt(Mathf.Min(a.x, b.x, c.x) * 2f));
				int num8 = Mathf.Min(World.inst.GridWidth * 2 - 1, Mathf.FloorToInt(Mathf.Max(a.x, b.x, c.x) * 2f));
				int num9 = Mathf.Max(0, Mathf.FloorToInt(Mathf.Min(a.z, b.z, c.z) * 2f));
				int num10 = Mathf.Min(World.inst.GridHeight * 2 - 1, Mathf.FloorToInt(Mathf.Max(a.z, b.z, c.z) * 2f));
				float num11 = Mathf.Min(a.y, b.y, c.y);
				for (int n = num9; n <= num10; n++)
				{
					for (int num12 = num7; num12 <= num8; num12++)
					{
						for (int num13 = 0; num13 < 2; num13++)
						{
							TerrainGen.inst.GetTriangleAtPoint((float)num12 * 0.5f + 0.125f + (float)num13 * 0.25f, (float)n * 0.5f + 0.25f, ref contactTerrain);
							if (!(num11 > Mathf.Max(contactTerrain[0].y, contactTerrain[1].y, contactTerrain[2].y) + mESH_TO_TERRAIN_THRESHOLD) && TouchesGroundTriangle(a, b, c, mESH_TO_TERRAIN_THRESHOLD))
							{
								return false;
							}
						}
					}
				}
			}
		}
		return true;
	}

	private static float CrossXZ(Vector3 a, Vector3 b)
	{
		return a.x * b.z - a.z * b.x;
	}

	private static bool TouchesGroundTriangle(Vector3 a, Vector3 b, Vector3 c, float tolerance)
	{
		Vector3[] array = contactPolygonA;
		Vector3[] array2 = contactPolygonB;
		array[0] = a;
		array[1] = b;
		array[2] = c;
		int num = 3;
		float num2 = Mathf.Sign(CrossXZ(contactTerrain[1] - contactTerrain[0], contactTerrain[2] - contactTerrain[0]));
		for (int i = 0; i < 3; i++)
		{
			Vector3 vector = contactTerrain[i];
			Vector3 a2 = contactTerrain[(i + 1) % 3] - vector;
			Vector3 vector2 = array[num - 1];
			float num3 = num2 * CrossXZ(a2, vector2 - vector);
			int num4 = 0;
			for (int j = 0; j < num; j++)
			{
				Vector3 vector3 = array[j];
				float num5 = num2 * CrossXZ(a2, vector3 - vector);
				if (num5 >= 0f != num3 >= 0f)
				{
					array2[num4++] = Vector3.LerpUnclamped(vector2, vector3, num3 / (num3 - num5));
				}
				if (num5 >= 0f)
				{
					array2[num4++] = vector3;
				}
				vector2 = vector3;
				num3 = num5;
			}
			if (num4 == 0)
			{
				return false;
			}
			num = num4;
			Vector3[] array3 = array;
			array = array2;
			array2 = array3;
		}
		for (int k = 0; k < num; k++)
		{
			Vector3 vector4 = array[k];
			if (vector4.y <= TerrainGen.inst.GetGroundHeight(vector4.x, vector4.z) + tolerance)
			{
				return true;
			}
		}
		return false;
	}

	private void UpdateSelectionErrors()
	{
		foreach (Transform selectedRock in selectedRocks)
		{
			if (!(selectedRock == null))
			{
				if (IsRockFloating(selectedRock))
				{
					looseRocks.Add(selectedRock);
				}
				else
				{
					looseRocks.Remove(selectedRock);
				}
			}
		}
		ResolveSupport();
	}

	public void RescanErrors()
	{
		looseRocks.Clear();
		CollectRocks(_allRocks);
		foreach (Transform allRock in _allRocks)
		{
			if (IsRockFloating(allRock))
			{
				looseRocks.Add(allRock);
			}
		}
		ResolveSupport();
	}

	private static void CollectRocks(List<Transform> rocks)
	{
		rocks.Clear();
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
				if (child.gameObject.activeSelf && child.GetComponent<MeshRenderer>() != null)
				{
					rocks.Add(child);
				}
			}
		}
	}

	private void ResolveSupport()
	{
		errorRocks.Clear();
		looseRocks.RemoveWhere((Transform r) => r == null || !r.gameObject.activeSelf);
		if (looseRocks.Count == 0)
		{
			return;
		}
		CollectRocks(_allRocks);
		_supportRocks.Clear();
		_supportBounds.Clear();
		foreach (Transform allRock in _allRocks)
		{
			if (!looseRocks.Contains(allRock))
			{
				_supportRocks.Add(allRock);
				_supportBounds.Add(RockWorldAABB(allRock));
			}
		}
		_unsupported.Clear();
		_unsupported.AddRange(looseRocks);
		float mESH_TO_TERRAIN_THRESHOLD = MountainPlacer.MESH_TO_TERRAIN_THRESHOLD;
		bool flag = true;
		while (flag)
		{
			flag = false;
			for (int num = _unsupported.Count - 1; num >= 0; num--)
			{
				Transform transform = _unsupported[num];
				Bounds bounds = RockWorldAABB(transform);
				bounds.Expand(mESH_TO_TERRAIN_THRESHOLD * 2f);
				for (int num2 = 0; num2 < _supportRocks.Count; num2++)
				{
					if (bounds.Intersects(_supportBounds[num2]) && RocksTouch(transform, _supportRocks[num2], mESH_TO_TERRAIN_THRESHOLD))
					{
						_supportRocks.Add(transform);
						_supportBounds.Add(RockWorldAABB(transform));
						_unsupported.RemoveAt(num);
						flag = true;
						break;
					}
				}
			}
		}
		errorRocks.UnionWith(_unsupported);
	}

	private static bool RocksTouch(Transform a, Transform b, float tolerance)
	{
		if (!VertexInsideBox(a, b, tolerance))
		{
			return VertexInsideBox(b, a, tolerance);
		}
		return true;
	}

	private static bool VertexInsideBox(Transform rock, Transform box, float tolerance)
	{
		Mesh mesh = RockMesh(rock);
		Mesh mesh2 = RockMesh(box);
		if (mesh == null || mesh2 == null)
		{
			return false;
		}
		Bounds bounds = mesh2.bounds;
		Vector3 lossyScale = box.lossyScale;
		bounds.Expand(new Vector3(tolerance / Mathf.Abs(lossyScale.x), tolerance / Mathf.Abs(lossyScale.y), tolerance / Mathf.Abs(lossyScale.z)) * 2f);
		Matrix4x4 matrix4x = box.worldToLocalMatrix * rock.localToWorldMatrix;
		mesh.GetVertices(touchVertices);
		for (int i = 0; i < touchVertices.Count; i++)
		{
			if (bounds.Contains(matrix4x.MultiplyPoint3x4(touchVertices[i])))
			{
				return true;
			}
		}
		return false;
	}

	private static Mesh RockMesh(Transform rock)
	{
		MeshFilter component = rock.GetComponent<MeshFilter>();
		MeshCollider component2 = rock.GetComponent<MeshCollider>();
		if (!(component != null))
		{
			if (!(component2 != null))
			{
				return null;
			}
			return component2.sharedMesh;
		}
		return component.sharedMesh;
	}

	public Transform NextErrorRock()
	{
		errorRocks.RemoveWhere((Transform r) => r == null);
		if (errorRocks.Count == 0)
		{
			return null;
		}
		_errorCycle.Clear();
		_errorCycle.AddRange(errorRocks);
		errorCycleCursor = (errorCycleCursor + 1) % _errorCycle.Count;
		return _errorCycle[errorCycleCursor];
	}

	public static void DropAndClampY(Transform rock)
	{
		MeshRenderer component = rock.GetComponent<MeshRenderer>();
		if (component == null)
		{
			return;
		}
		Bounds localBounds = component.localBounds;
		float num = float.MaxValue;
		for (int i = 0; i < CornerSigns.Length; i++)
		{
			Vector3 vector = localBounds.center + Vector3.Scale(localBounds.size * 0.5f, CornerSigns[i]);
			Vector3 vector2 = rock.TransformPoint(vector * 0.8f);
			float groundHeight = TerrainGen.inst.GetGroundHeight(vector2.x, vector2.z);
			if (groundHeight < num)
			{
				num = groundHeight;
			}
		}
		Vector3 position = rock.position;
		position.y = num;
		rock.position = position;
		Bounds worldBounds = RockClampBounds(rock);
		GroundRangeUnder(worldBounds, out var _, out var highest);
		float num2 = highest + MountainPlacer.MESH_TO_TERRAIN_THRESHOLD;
		if (worldBounds.max.y < num2)
		{
			position.y += num2 - worldBounds.max.y;
			rock.position = position;
		}
	}

	private static Bounds RockWorldAABB(Transform rock)
	{
		MeshCollider component = rock.GetComponent<MeshCollider>();
		Bounds bounds;
		if (component != null && component.sharedMesh != null)
		{
			bounds = component.sharedMesh.bounds;
		}
		else
		{
			MeshRenderer component2 = rock.GetComponent<MeshRenderer>();
			if (component2 == null)
			{
				return new Bounds(rock.position, Vector3.one);
			}
			bounds = component2.localBounds;
		}
		Vector3 vector = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
		Vector3 vector2 = new Vector3(float.MinValue, float.MinValue, float.MinValue);
		for (int i = 0; i < CornerSigns.Length; i++)
		{
			Vector3 rhs = rock.TransformPoint(bounds.center + Vector3.Scale(bounds.size * 0.5f, CornerSigns[i]));
			vector = Vector3.Min(vector, rhs);
			vector2 = Vector3.Max(vector2, rhs);
		}
		return new Bounds((vector + vector2) * 0.5f, vector2 - vector);
	}

	private static Bounds RockClampBounds(Transform rock)
	{
		Bounds result = RockWorldAABB(rock);
		float num = Mathf.Min(0.25f, result.size.y * 0.25f);
		result.size = new Vector3(result.size.x, result.size.y - num * 2f, result.size.z);
		return result;
	}

	public static void ClampToBand(Transform rock)
	{
		Bounds worldBounds = RockClampBounds(rock);
		GroundRangeUnder(worldBounds, out var lowest, out var highest);
		float y = rock.position.y;
		float num = y + (lowest + MountainPlacer.MESH_TO_TERRAIN_THRESHOLD - worldBounds.max.y);
		float num2 = y + (highest - 0.1f - worldBounds.min.y);
		if (num > num2)
		{
			DropAndClampY(rock);
			return;
		}
		Vector3 position = rock.position;
		position.y = Mathf.Clamp(y, num, num2);
		rock.position = position;
	}

	private static void GroundRangeUnder(Bounds worldBounds, out float lowest, out float highest)
	{
		lowest = float.MaxValue;
		highest = float.MinValue;
		for (int i = 0; i <= 2; i++)
		{
			for (int j = 0; j <= 2; j++)
			{
				float x = Mathf.Lerp(worldBounds.min.x, worldBounds.max.x, (float)i * 0.5f);
				float z = Mathf.Lerp(worldBounds.min.z, worldBounds.max.z, (float)j * 0.5f);
				float groundHeight = TerrainGen.inst.GetGroundHeight(x, z);
				if (groundHeight < lowest)
				{
					lowest = groundHeight;
				}
				if (groundHeight > highest)
				{
					highest = groundHeight;
				}
			}
		}
	}

	private static void ReclassifyWorldBounds(Bounds bounds)
	{
		int minVertX = Mathf.Clamp(Mathf.FloorToInt(bounds.min.x * 2f) - 1, 0, World.MeshWidth - 1);
		int maxVertX = Mathf.Clamp(Mathf.CeilToInt(bounds.max.x * 2f) + 1, 0, World.MeshWidth - 1);
		int minVertZ = Mathf.Clamp(Mathf.FloorToInt(bounds.min.z * 2f) - 1, 0, World.MeshHeight - 1);
		int maxVertZ = Mathf.Clamp(Mathf.CeilToInt(bounds.max.z * 2f) + 1, 0, World.MeshHeight - 1);
		TerrainRockReclassifier.ReclassifyVertRect(minVertX, minVertZ, maxVertX, maxVertZ);
	}

	private static IEnumerator ReclassifyNextFrameRoutine(Bounds bounds)
	{
		yield return null;
		ReclassifyWorldBounds(bounds);
		if (MapEditorController.inst != null)
		{
			MapEditorController.inst.RebuildFollowBaselines();
		}
	}

	public static Vector3 CursorGroundPoint()
	{
		return CursorGroundFromRay(PointingSystem.GetPointer().GetRay());
	}

	public static Vector3 CursorWaterFloorPoint()
	{
		Ray ray = PointingSystem.GetPointer().GetRay();
		Vector3 result = CursorGroundFromRay(ray);
		if (result.y >= TerrainGen.SeaLevel)
		{
			return result;
		}
		new Plane(Vector3.up, new Vector3(0f, TerrainGen.SeaLevel, 0f)).Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		point.x = Mathf.Clamp(point.x, 0f, (float)World.inst.GridWidth - 0.01f);
		point.z = Mathf.Clamp(point.z, 0f, (float)World.inst.GridHeight - 0.01f);
		return point;
	}

	private static Vector3 CursorGroundFromScreen(Vector2 screen)
	{
		return CursorGroundFromRay(Cam.inst.cam.ScreenPointToRay(screen));
	}

	public static Vector3 CursorGroundFromRay(Ray ray)
	{
		int num = Physics.RaycastNonAlloc(ray, _rayHits, 1000f, LayerMask.GetMask("Terrain"));
		float num2 = float.MaxValue;
		Vector3 result = default;
		bool flag = false;
		for (int i = 0; i < num; i++)
		{
			if (!(_rayHits[i].collider.GetComponentInParent<TerrainChunk>() == null) && _rayHits[i].distance < num2)
			{
				num2 = _rayHits[i].distance;
				result = _rayHits[i].point;
				flag = true;
			}
		}
		if (flag)
		{
			return result;
		}
		new Plane(Vector3.up, Vector3.zero).Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		point.x = Mathf.Clamp(point.x, 0f, (float)World.inst.GridWidth - 0.01f);
		point.z = Mathf.Clamp(point.z, 0f, (float)World.inst.GridHeight - 0.01f);
		return point;
	}

	private void UpdateGizmoVisual()
	{
		if (!HasRockSelection)
		{
			gizmo.Hide();
			return;
		}
		HandleKind handleKind;
		if (movingSelection)
		{
			handleKind = HandleKind.MoveXZ;
		}
		else
		{
			handleKind = ((handleDrag != HandleKind.None) ? handleDrag : handleHover);
		}
		int num = handleKind switch
		{
			HandleKind.RotateY => 1, 
			HandleKind.Tilt => 3, 
			HandleKind.UniformScale => 9, 
			HandleKind.MoveXZ => 5, 
			HandleKind.Lift => 4, 
			HandleKind.None => -1, 
			_ => (int)(handleKind - 4 + 6), 
		};
		Quaternion rotation = selectedRocks[0].rotation;
		Vector3 center = ((handleDrag == HandleKind.Lift || handleDrag == HandleKind.MoveXZ) ? AverageRockPosition() : gizmoPos);
		Vector3 ground = ((handleDrag == HandleKind.MoveXZ) ? new Vector3(center.x, TerrainGen.inst.GetGroundHeight(center.x, center.z), center.z) : gizmoGround);
		Vector3 knobDirection = rotation * ringKnobDirection;
		float num2 = MapSelectionGizmo.ScreenScale(Cam.inst.cam, center);
		float length = 4f * num2;
		gizmo.UpdateLayout(Cam.inst.cam, center, knobDirection, length, num2, rotation, num, IsDragging);
		if (IsDragging)
		{
			gizmo.DrawDragGuide(Cam.inst.cam, center, ground, num2, num);
		}
		gizmo.Render(Cam.inst.cam);
	}

	private void DrawOverlay(Vector2 screen)
	{
		bool flag = boxSelecting && (screen - pressScreen).magnitude >= 6f;
		bool flag2 = errorRocks.Count > 0;
		if (flag || flag2)
		{
			_camTargets[0] = Cam.inst.cam;
			CommandBuilder builder = DrawingManager.GetBuilder(renderInGame: true);
			builder.cameraTargets = _camTargets;
			if (flag)
			{
				DrawBoxRect(builder, pressScreen, screen);
			}
			if (flag2)
			{
				DrawErrorMarkers(builder);
			}
			builder.Dispose();
		}
	}

	private void DrawErrorMarkers(CommandBuilder cmd)
	{
		using (cmd.WithLineWidth(2f))
		{
			using (cmd.WithColor(ErrorColor))
			{
				foreach (Transform errorRock in errorRocks)
				{
					if (!(errorRock == null))
					{
						Bounds bounds = RockBounds(errorRock);
						Vector3 vector = new Vector3(bounds.center.x, TerrainGen.inst.GetGroundHeight(bounds.center.x, bounds.center.z), bounds.center.z);
						cmd.Line(new Vector3(bounds.center.x, bounds.min.y, bounds.center.z), vector);
						cmd.Circle(vector, Vector3.up, 0.5f);
					}
				}
			}
		}
	}

	private static void DrawBoxRect(CommandBuilder cmd, Vector2 a, Vector2 b)
	{
		Vector3 vector = CursorGroundFromScreen(new Vector2(a.x, a.y));
		Vector3 vector2 = CursorGroundFromScreen(new Vector2(b.x, a.y));
		Vector3 vector3 = CursorGroundFromScreen(new Vector2(b.x, b.y));
		Vector3 vector4 = CursorGroundFromScreen(new Vector2(a.x, b.y));
		using (cmd.WithColor(new Color(1f, 1f, 1f, 0.8f)))
		{
			cmd.Line(vector, vector2);
			cmd.Line(vector2, vector3);
			cmd.Line(vector3, vector4);
			cmd.Line(vector4, vector);
		}
	}
}
