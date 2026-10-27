using System.Collections.Generic;
using FMODUnity;
using UnityEngine;

public class UnitControlSystem : MonoBehaviour
{
	public delegate void SelectionChange(ArrayExt<IUnitControllable> currSelection);

	public class StaticPosMoveTarget : IMoveTarget
	{
		private Vector3 pos;

		public StaticPosMoveTarget(Vector3 p)
		{
			pos = p;
		}

		public Vector3 GetPos()
		{
			return pos;
		}

		public Vector3 GetPredictedPosition(float time)
		{
			return pos;
		}

		public bool IsStationary()
		{
			return true;
		}

		public int TeamID()
		{
			return -2;
		}
	}

	public static UnitControlSystem inst;

	private float prevClickTime;

	public ArrayExt<IUnitControllable> currSelection = new ArrayExt<IUnitControllable>(32);

	public bool isCustomSelection;

	public ArrayExt<IUnitControllable> customCurrSelection = new ArrayExt<IUnitControllable>(32);

	public SelectionChange OnSelectionChanged;

	private ArrayExt<IUnitControllable> scratchUnits = new ArrayExt<IUnitControllable>(32);

	private static ArrayExt<IUnitControllable> scratchUnitsToCell = new ArrayExt<IUnitControllable>(32);

	private static ArrayExt<IUnitControllable> scratchUnitsToTarget = new ArrayExt<IUnitControllable>(32);

	private static ArrayExt<Vector3> scratchPos = new ArrayExt<Vector3>(8);

	private ArrayExt<IUnitControllable> unitsToArrange = new ArrayExt<IUnitControllable>(10);

	public bool HasSelection()
	{
		return currSelection.Count > 0;
	}

	public int GetSelectionCount()
	{
		return currSelection.Count;
	}

	public bool TryRemoveFromSelection(IUnitControllable unit)
	{
		if (!currSelection.Contains(unit))
		{
			return false;
		}
		currSelection.RemoveSwap(unit);
		OnSelectionChanged?.Invoke(currSelection);
		return true;
	}

	public bool TryAddToSelection(IUnitControllable unit)
	{
		if (currSelection.Contains(unit))
		{
			return false;
		}
		currSelection.Add(unit);
		OnSelectionChanged?.Invoke(currSelection);
		return true;
	}

	public void ClearSelection()
	{
		currSelection.ClearFast();
		OnSelectionChanged?.Invoke(currSelection);
	}

	public void ExclusiveSelect(IUnitControllable unit)
	{
		currSelection.ClearFast();
		currSelection.Add(unit);
		OnSelectionChanged?.Invoke(currSelection);
	}

	public void ExclusiveSelect(IUnitControllable[] units)
	{
		currSelection.ClearFast();
		currSelection.AddRange(units);
		OnSelectionChanged?.Invoke(currSelection);
	}

	public void GetSelectedUnits(ref ArrayExt<IUnitControllable> targetUnits)
	{
		ArrayExt<IUnitControllable> arrayExt = (isCustomSelection ? customCurrSelection : currSelection);
		for (int i = 0; i < arrayExt.Count; i++)
		{
			if (arrayExt.data[i].TeamID() == 0 || Creative.inst.IsCreativeOptionOn(10))
			{
				targetUnits.Add(arrayExt.data[i]);
			}
		}
	}

	public bool IsSelected(IUnitControllable unit)
	{
		if (isCustomSelection)
		{
			return customCurrSelection.Contains(unit);
		}
		return currSelection.Contains(unit);
	}

	public bool IsUnitControllableByTeam(IUnitControllable unit, int teamID)
	{
		if (teamID == unit.TeamID())
		{
			return true;
		}
		if (teamID == 0 && Creative.inst.IsCreativeOptionOn(10))
		{
			return true;
		}
		return false;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		UnitSystem.inst.OnUnitRemoved += OnUnitDestroyed;
	}

	private void OnUnitDestroyed(IUnitControllable unit)
	{
		if (customCurrSelection.Contains(unit))
		{
			customCurrSelection.RemoveSwap(unit);
		}
		if (currSelection.Contains(unit))
		{
			currSelection.RemoveSwap(unit);
			OnSelectionChanged?.Invoke(currSelection);
			if (currSelection.Count == 0 && GameUI.inst.IsUnitControlModeActive())
			{
				GameUI.inst.ReturnToDefaultCursorMode();
			}
		}
	}

	public void TryGetHighlight(out float unitDist, out ISelectable unit)
	{
		unitDist = float.MaxValue;
		unit = null;
		UnitSystem.inst.GetHighlight(out unitDist, out unit);
	}

	public void TryAddHighlights(int minX, int minZ, int maxX, int maxZ, ref List<ISelectable> objs)
	{
		UnitSystem.inst.AddHighlights(minX, minZ, maxX, maxZ, ref objs);
		SiegeCatapultSystem.inst.AddHighlights(minX, minZ, maxX, maxZ, ref objs);
	}

	public bool TrySelectHighlightObjects(List<ISelectable> highlightObjs)
	{
		bool flag = Time.unscaledTime - prevClickTime <= 0.2f;
		prevClickTime = Time.unscaledTime;
		bool flag2 = Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl);
		bool num = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);
		GameUI.inst.IsDragSelecting();
		if (!num && !flag2)
		{
			currSelection.Clear();
		}
		Plane[] planes = (flag ? GeometryUtility.CalculateFrustumPlanes(Cam.inst.cam) : null);
		for (int i = 0; i < highlightObjs.Count; i++)
		{
			if (!(highlightObjs[i] is IUnitControllable unitControllable) || !IsUnitControllableByTeam(unitControllable, 0))
			{
				continue;
			}
			int unitType = unitControllable.GetUnitType();
			if (flag)
			{
				scratchUnits.Clear();
				switch (unitType)
				{
				case 0:
					UnitSystem.inst.GetUnitTypeInView(planes, unitType, 0, ref scratchUnits);
					break;
				case 2:
					SiegeCatapultSystem.inst.AddInView(planes, 0, ref scratchUnits);
					break;
				case 3:
					ShipSystem.inst.AddInView(planes, unitType, 0, ref scratchUnits);
					break;
				}
				for (int j = 0; j < scratchUnits.Count; j++)
				{
					if (flag2)
					{
						if (currSelection.Contains(scratchUnits.data[j]))
						{
							currSelection.Remove(scratchUnits.data[j]);
						}
					}
					else if (!currSelection.Contains(scratchUnits.data[j]))
					{
						currSelection.Add(scratchUnits.data[j]);
					}
				}
			}
			else if (flag2)
			{
				if (currSelection.Contains(unitControllable))
				{
					currSelection.Remove(unitControllable);
				}
			}
			else if (!currSelection.Contains(unitControllable))
			{
				currSelection.Add(unitControllable);
			}
		}
		if (currSelection.Count > 0)
		{
			IUnitControllable unitControllable2 = currSelection.Last();
			if (unitControllable2.GetUnitType() == 4)
			{
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_select_militia", unitControllable2.GetPos());
			}
			else if (unitControllable2.GetUnitType() == 0)
			{
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_select_legion", unitControllable2.GetPos());
			}
			else if (unitControllable2.GetUnitType() == 5)
			{
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_select_cavalry", unitControllable2.GetPos());
			}
		}
		OnSelectionChanged?.Invoke(currSelection);
		return currSelection.Count > 0;
	}

	public void DoPlayerMoveTo(Vector3 targetPos, Cell targetCell)
	{
		scratchUnitsToCell.ClearFast();
		scratchUnitsToTarget.ClearFast();
		List<ISelectable> highlightedObjs = GameUI.inst.highlightedObjs;
		ArrayExt<IUnitControllable> arrayExt = (inst.isCustomSelection ? inst.customCurrSelection : inst.currSelection);
		IUnitControllable unitControllable = null;
		IUnitControllable unitControllable2 = null;
		for (int i = 0; i < highlightedObjs.Count; i++)
		{
			if (!(highlightedObjs[i] is IUnitControllable unitControllable3))
			{
				continue;
			}
			if (World.inst.RelationBetween(unitControllable3.TeamID(), 0) == World.Relations.Enemy)
			{
				if (!inst.IsSelected(unitControllable3))
				{
					unitControllable = unitControllable3;
				}
			}
			else if (unitControllable3.CanCarry())
			{
				unitControllable = unitControllable3;
				unitControllable2 = unitControllable3;
			}
		}
		for (int j = 0; j < arrayExt.Count; j++)
		{
			IUnitControllable unitControllable4 = arrayExt.data[j];
			if ((unitControllable2 != null && !unitControllable4.CanBeCarried()) || unitControllable == null)
			{
				scratchUnitsToCell.Add(unitControllable4);
			}
			else
			{
				scratchUnitsToTarget.Add(unitControllable4);
			}
		}
		if (scratchUnitsToCell.Count > 1)
		{
			Vector3 zero = Vector3.zero;
			for (int k = 0; k < scratchUnitsToCell.Count; k++)
			{
				zero += scratchUnitsToCell.data[k].GetPos();
			}
			zero /= (float)scratchUnitsToCell.Count;
			Vector3 vector = targetCell.Center2D - zero.xz();
			vector.Normalize();
			Vector3 vector2 = Vector3.Cross(vector, Vector3.up);
			Vector3 vector3 = targetPos;
			Vector3 vector4 = targetPos;
			int num = 0;
			for (int l = 0; l < 3; l++)
			{
				unitsToArrange.Clear();
				for (int m = 0; m < scratchUnitsToCell.Count; m++)
				{
					if (scratchUnitsToCell.data[m].GetFormationIdx() == l)
					{
						unitsToArrange.Add(scratchUnitsToCell.data[m]);
					}
				}
				while (unitsToArrange.Count > 0)
				{
					float num2 = float.MaxValue;
					IUnitControllable unitControllable5 = null;
					for (int n = 0; n < unitsToArrange.Count; n++)
					{
						float num3 = Mathff.DistSqrd(unitsToArrange.data[n].GetPos(), targetPos);
						if (num3 < num2)
						{
							num2 = num3;
							unitControllable5 = unitsToArrange.data[n];
						}
					}
					if (unitControllable5 != null)
					{
						int num4 = 1;
						if (unitControllable5 is LegionUnit legionUnit)
						{
							num4 = legionUnit.GetGroup().numCells;
						}
						float num5 = Mathff.DistSqrd(unitControllable5.GetPos(), vector3);
						float num6 = Mathff.DistSqrd(unitControllable5.GetPos(), vector4);
						Vector3 vector5 = targetPos;
						if (num6 < num5)
						{
							vector5 = vector4 + vector2 * num4 / 2f;
							vector4 += vector2 * num4;
						}
						else
						{
							vector5 = vector3 - vector2 * num4 / 2f;
							vector3 -= vector2 * num4;
						}
						UnitSystem.inst.MoveTo(unitControllable5, new StaticPosMoveTarget(vector5));
						unitsToArrange.Remove(unitControllable5);
						if (Mathff.Dist(vector3, vector4) >= 9f)
						{
							num++;
							vector4 = (vector3 = targetPos - vector * ((float)num * 1.5f));
						}
						scratchPos.ClearFast();
						scratchPos.Add(vector5);
						CommandPathMarker obj = EffectsMan.inst.PathMarker.Create(Vector3.zero) as CommandPathMarker;
						obj.ShowPath(scratchPos);
						obj.Play();
					}
				}
				vector4 = (vector3 = targetPos - vector * ((float)num * 1.5f));
			}
		}
		else if (scratchUnitsToCell.Count == 1)
		{
			UnitSystem.inst.MoveTo(scratchUnitsToCell.data[0], new StaticPosMoveTarget(targetPos));
			scratchPos.ClearFast();
			scratchPos.Add(targetPos);
			CommandPathMarker obj2 = EffectsMan.inst.PathMarker.Create(Vector3.zero) as CommandPathMarker;
			obj2.ShowPath(scratchPos);
			obj2.Play();
		}
		for (int num7 = 0; num7 < scratchUnitsToTarget.Count; num7++)
		{
			IUnitControllable obj3 = scratchUnitsToTarget.data[num7];
			UnitSystem.inst.MoveTo(scratchUnitsToTarget.data[num7], unitControllable as IMoveTarget);
			if (obj3 is LegionUnit legionUnit2)
			{
				legionUnit2.isPlayerMoveTo = true;
			}
		}
		if (scratchUnitsToTarget.Count > 0)
		{
			scratchPos.ClearFast();
			scratchPos.Add(unitControllable.GetPos());
			CommandPathMarker obj4 = EffectsMan.inst.PathMarker.Create(Vector3.zero) as CommandPathMarker;
			obj4.ShowPath(scratchPos, World.inst.RelationBetween(0, unitControllable.TeamID()) == World.Relations.Enemy);
			obj4.Play();
		}
		for (int num8 = 0; num8 < arrayExt.Count; num8++)
		{
			switch (arrayExt.data[num8].GetUnitType())
			{
			case 4:
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_militia_command");
				break;
			case 5:
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_cavalry_command");
				break;
			case 0:
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_legion_command");
				break;
			case 3:
				continue;
			}
			break;
		}
		if (MiniMapUI.inst != null && MiniMapUI.inst.IsVisible())
		{
			MiniMapUI.inst.DrawRoutes();
		}
		unitsToArrange.Clear();
	}
}
