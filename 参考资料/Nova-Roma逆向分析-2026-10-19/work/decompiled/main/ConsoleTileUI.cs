using System.Collections.Generic;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class ConsoleTileUI : UIWindowBase
{
	public static ConsoleTileUI inst;

	public GameObject A;

	public GameObject X;

	public GameObject Y;

	public GameObject B;

	public Vector3 targetPosition = Vector3.zero;

	public Slider demolishSilder;

	public override void AwakeInternal()
	{
		inst = this;
	}

	private void OnDisable()
	{
	}

	public override void UpdateInternal(float dt)
	{
	}

	private void LateUpdate()
	{
		if (GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			targetPosition = GameUI.inst.CurrPlacementMode.GetHoverBuilding().Center();
		}
		if (targetPosition != Vector3.zero)
		{
			Vector2 anchoredPosition = Mathff.WorldPosToScreen(targetPosition + new Vector3(0f, 0f, 0f), GameUI.inst.rectT);
			rectT.anchoredPosition = anchoredPosition;
		}
	}

	public void ResetButtons()
	{
		A.SetActive(value: false);
		X.SetActive(value: false);
		Y.SetActive(value: false);
		B.SetActive(value: false);
	}

	public void UpdateDefaultCursorModeVisuals()
	{
		SetVisible(v: false);
		targetPosition = Vector3.zero;
	}

	public void UpdateBuildPlacementModeVisuals()
	{
		if (!Visible)
		{
			SetVisible(v: true);
		}
		X.SetActive(value: false);
		if (GameUI.CanRotate(GameUI.inst.CurrPlacementMode.GetHoverBuilding()))
		{
			ShowButton(Y, active: true, "Rotate");
		}
		else
		{
			Y.SetActive(value: false);
		}
		ShowButton(B, active: true, "Back");
		ShowButton(A, active: true, "Place");
	}

	private void ShowButton(GameObject button, bool active, string term = "")
	{
		button.SetActive(active);
		button.transform.GetChild(2).GetComponent<Localize>().Term = term;
	}

	public void UpdateHoverVisuals(Building b)
	{
		ResetButtons();
		if (!Visible)
		{
			SetVisible(v: true);
		}
		Cell cell = null;
		Ray ray = PointingSystem.GetRay();
		if (Vector3.Dot(Vector3.down, ray.direction.normalized) > 0f)
		{
			cell = World.inst.GetCellData(GameUI.inst.GridPointerIntersection());
		}
		if (!GameUI.inst.IsUnitSelected())
		{
			if (cell != null)
			{
				if (GameUI.inst.GetCellSelected() != cell)
				{
					ShowButton(A, active: true, "Select");
				}
				if (b == null)
				{
					ShowButton(X, active: true, "Build");
				}
				else
				{
					ShowButton(Y, b.CanDemolishBuilding(), "Demolish");
				}
				if (World.inst.treeSystem.ItemAmount(cell) > 0)
				{
					ClearCutterJob clearCutterJob = GameUI.inst.GetClearCutterJob(cell);
					ShowButton(A, active: true, (clearCutterJob == null) ? "Chop" : "Cancel");
				}
				targetPosition = cell.Center2D;
			}
		}
		else
		{
			UpdateUnitVisuals();
			if (cell != null)
			{
				targetPosition = cell.Center2D;
			}
		}
	}

	public void UpdateUnitVisuals()
	{
		List<ISelectable> selectedObjs = GameUI.inst.selectedObjs;
		List<ISelectable> highlightedObjs = GameUI.inst.highlightedObjs;
		int teamId = 0;
		bool flag = false;
		bool flag2 = false;
		for (int i = 0; i < selectedObjs.Count; i++)
		{
			if (!(selectedObjs[i] is IMoveableUnit moveableUnit))
			{
				continue;
			}
			teamId = moveableUnit.TeamID();
			if (GameUI.inst.IsUnitSelectable(moveableUnit))
			{
				flag = true;
				if (!moveableUnit.CanCarry())
				{
					flag2 = true;
				}
				break;
			}
		}
		bool flag3 = GameUI.inst.IsHoveringUnitOfRelation(teamId, World.Relations.Allies);
		bool flag4 = GameUI.inst.IsHoveringUnitOfRelation(teamId, World.Relations.Enemy);
		if (flag3)
		{
			string term = "Select";
			for (int j = 0; j < highlightedObjs.Count; j++)
			{
				if (GameUI.inst.IsSelected(highlightedObjs[j]))
				{
					term = "Deselect";
					break;
				}
			}
			ShowButton(A, active: true, term);
			X.SetActive(value: false);
		}
		else
		{
			if (flag)
			{
				ShowButton(X, active: true, (flag4 & flag2) ? "ScriptTerms.Attack" : "Move");
			}
			else
			{
				X.SetActive(value: false);
			}
			ShowButton(B, active: true, "Deselect");
		}
	}

	public void UpdateSelectedCellVisuals(Building b, Cell cell)
	{
		ResetButtons();
		if (!Visible)
		{
			SetVisible(v: true);
		}
		if (GameUI.inst.IsUnitSelected())
		{
			UpdateUnitVisuals();
			return;
		}
		ShowButton(X, active: true, "Build");
		if (b != null)
		{
			targetPosition = b.Center();
			X.SetActive(value: false);
		}
		else if (cell != null)
		{
			targetPosition = cell.Center2D;
			if (World.inst.treeSystem.ItemAmount(cell) > 0)
			{
				ClearCutterJob clearCutterJob = GameUI.inst.GetClearCutterJob(cell);
				ShowButton(A, active: true, (clearCutterJob == null) ? "Chop" : "Cancel");
			}
		}
		if (b == null && cell == null)
		{
			ShowButton(A, active: true, "Select");
			Ray ray = PointingSystem.GetRay();
			if (Vector3.Dot(Vector3.down, ray.direction.normalized) > 0f)
			{
				Cell cellData = World.inst.GetCellData(GameUI.inst.GridPointerIntersection());
				targetPosition = cellData.Center2D;
			}
		}
	}

	public void UpdateYSlider(float val)
	{
		demolishSilder.value = val;
		if (val <= 0f)
		{
			SetSliderVisible(visible: false);
		}
	}

	public void SetSliderVisible(bool visible)
	{
		demolishSilder.gameObject.SetActive(visible);
	}
}
