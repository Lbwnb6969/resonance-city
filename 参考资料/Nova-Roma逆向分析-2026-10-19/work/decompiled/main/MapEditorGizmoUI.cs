using UnityEngine;
using UnityEngine.UI;

public class MapEditorGizmoUI : MonoBehaviour
{
	private const float ScreenOffsetX = 24f;

	public RectTransform panel;

	public GameObject[] rockOnlyButtons;

	public GameObject strengthRow;

	public Button[] carveStrengthButtons;

	private static readonly Color TintIdle = Color.white;

	private static readonly Color TintActive = new Color(1f, 0.85f, 0.4f);

	private Canvas canvas;

	private static MapEditorController Ctrl => MapEditorController.inst;

	private static bool Active
	{
		get
		{
			if (Ctrl != null)
			{
				return Ctrl.IsOpen;
			}
			return false;
		}
	}

	public void OnDuplicate()
	{
		if (Active)
		{
			Ctrl.selectionTool.DuplicateSelected();
		}
	}

	public void OnDelete()
	{
		if (Active)
		{
			Ctrl.selectionTool.DeleteSelected();
		}
	}

	public void OnCarveStrength(int level)
	{
		if (Active)
		{
			Ctrl.selectionTool.SetCarveStrengthOnSelection(level);
		}
	}

	private void Awake()
	{
		canvas = GetComponentInParent<Canvas>();
	}

	private void LateUpdate()
	{
		if (panel == null)
		{
			return;
		}
		bool flag = Active && Ctrl.currentMode == MapEditorController.EditorMode.Select && Ctrl.selectionTool.HasSelection && !Ctrl.selectionTool.IsDragging;
		if (flag)
		{
			flag = PositionPanel(Ctrl.selectionTool.GizmoAnchor, Ctrl.selectionTool.GizmoWorldRadius);
		}
		if (panel.gameObject.activeSelf != flag)
		{
			panel.gameObject.SetActive(flag);
		}
		if (flag && rockOnlyButtons != null)
		{
			bool hasRockSelection = Ctrl.selectionTool.HasRockSelection;
			GameObject[] array = rockOnlyButtons;
			foreach (GameObject gameObject in array)
			{
				if (gameObject != null && gameObject.activeSelf != hasRockSelection)
				{
					gameObject.SetActive(hasRockSelection);
				}
			}
		}
		if (!flag || !(strengthRow != null))
		{
			return;
		}
		bool hasSpringSelection = Ctrl.selectionTool.HasSpringSelection;
		if (strengthRow.activeSelf != hasSpringSelection)
		{
			strengthRow.SetActive(hasSpringSelection);
		}
		if (!hasSpringSelection || carveStrengthButtons == null)
		{
			return;
		}
		int selectedSpringStrength = Ctrl.selectionTool.GetSelectedSpringStrength();
		for (int j = 0; j < carveStrengthButtons.Length; j++)
		{
			if (carveStrengthButtons[j] != null)
			{
				carveStrengthButtons[j].image.color = ((j == selectedSpringStrength) ? TintActive : TintIdle);
			}
		}
	}

	private bool PositionPanel(Vector3 worldPos, float worldRadius)
	{
		if (canvas == null)
		{
			canvas = GetComponentInParent<Canvas>();
		}
		if (canvas == null)
		{
			return false;
		}
		Camera cam = Cam.inst.cam;
		Vector3 vector = cam.WorldToScreenPoint(worldPos);
		if (vector.z < 0f)
		{
			return false;
		}
		Vector3 vector2 = cam.WorldToScreenPoint(worldPos + cam.transform.right * worldRadius);
		vector.x += Mathf.Abs(vector2.x - vector.x) + 24f;
		vector.x = Mathf.Clamp(vector.x, 0f, (float)Screen.width - 180f);
		vector.y = Mathf.Clamp(vector.y, 140f, (float)Screen.height - 140f);
		Camera cam2 = ((canvas.renderMode == RenderMode.ScreenSpaceOverlay) ? null : canvas.worldCamera);
		if (!RectTransformUtility.ScreenPointToLocalPointInRectangle((RectTransform)panel.parent, vector, cam2, out var localPoint))
		{
			return false;
		}
		panel.anchoredPosition = localPoint;
		return true;
	}
}
