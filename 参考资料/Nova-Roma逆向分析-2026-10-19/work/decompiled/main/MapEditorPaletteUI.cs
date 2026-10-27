using UnityEngine;
using UnityEngine.UI;

public class MapEditorPaletteUI : MonoBehaviour
{
	public MapEditorGizmoUI gizmoUI;

	public GameObject rockPickerPanel;

	public Transform rockPickerContent;

	private bool rockButtonsWired;

	private static MapEditorController Ctrl => MapEditorController.inst;

	public static void ClearToolToggles()
	{
		if (!(MapEdit.inst == null))
		{
			ToggleGroup componentInChildren = MapEdit.inst.GetComponentInChildren<ToggleGroup>(includeInactive: true);
			if (componentInChildren != null)
			{
				componentInChildren.SetAllTogglesOff(sendCallback: false);
			}
		}
	}

	public void OnSculptTool(int tool)
	{
		if (Ctrl != null && Ctrl.IsOpen)
		{
			CloseRockPicker();
			Ctrl.EnterSculpt(tool);
			SfxSystem.PlayUiSelect();
		}
	}

	public void OnUndo()
	{
		if (Ctrl != null && Ctrl.IsOpen)
		{
			MapEditorUndoStack.PerformUndo();
		}
	}

	public void OnAddSpring()
	{
		if (Ctrl != null && Ctrl.IsOpen)
		{
			CloseRockPicker();
			Ctrl.ExitToSelect();
			Ctrl.selectionTool.ArmAddSpring();
			SfxSystem.PlayUiSelect();
		}
	}

	public void OnRockMesh(bool on)
	{
		if (!on)
		{
			CloseRockPicker();
		}
		else if (!(Ctrl == null) && Ctrl.IsOpen && !(rockPickerPanel == null))
		{
			if (rockPickerPanel.activeSelf)
			{
				CloseRockPicker();
				return;
			}
			Ctrl.ExitToSelect();
			WireRockButtons();
			rockPickerPanel.SetActive(value: true);
			SfxSystem.PlayUiSelect();
		}
	}

	public void CloseRockPicker()
	{
		if (rockPickerPanel != null && rockPickerPanel.activeSelf)
		{
			rockPickerPanel.SetActive(value: false);
		}
	}

	private void WireRockButtons()
	{
		if (rockButtonsWired || rockPickerContent == null)
		{
			return;
		}
		rockButtonsWired = true;
		foreach (Transform item in rockPickerContent)
		{
			Button component = item.GetComponent<Button>();
			if (component == null)
			{
				continue;
			}
			int num = item.name.LastIndexOf('_');
			if (num < 0 || !int.TryParse(item.name.Substring(num + 1), out var meshIdx))
			{
				continue;
			}
			component.onClick.AddListener(() =>
			{
				CloseRockPicker();
				if (Ctrl != null && Ctrl.IsOpen)
				{
					Ctrl.selectionTool.SpawnRockFromPicker(meshIdx);
					SfxSystem.PlayUiSelect();
				}
			});
		}
	}

	private void Update()
	{
		if (rockPickerPanel != null && rockPickerPanel.activeSelf && Input.GetMouseButtonDown(1))
		{
			CloseRockPicker();
			ClearToolToggles();
		}
	}

	private void OnDisable()
	{
		CloseRockPicker();
	}
}
