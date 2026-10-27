using System;
using System.Collections.Generic;
using Assets.Code;
using Code;
using FMODUnity;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class CreativeUI : MonoBehaviour
{
	public delegate void OnBrushSelected(CreativeBrush brush);

	public enum InputType
	{
		OnPrimaryUp,
		OnPrimaryDown,
		OnPrimaryHeld,
		OnPrimaryDownNewCell,
		OnPrimaryHeldNewCell
	}

	public delegate void BrushUpdate(Cell currC, Cell prevC);

	public static CreativeUI inst;

	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	public CanvasScaler canvasScaler;

	[SerializeField]
	private Canvas wCanvas;

	[SerializeField]
	private GraphicRaycaster wGRaycaster;

	[SerializeField]
	private GameObject optionContainer;

	[SerializeField]
	private GameObject tileBrushContainer;

	[SerializeField]
	private GameObject unitBrushContainer;

	[SerializeField]
	private TMP_Dropdown difficultyDropdown;

	[SerializeField]
	private Button goldBtn;

	[SerializeField]
	private Button unlockTechTreeBtn;

	[SerializeField]
	private Button exitBtn;

	[SerializeField]
	private Button changeDifficultyBtn;

	[SerializeField]
	public Button openCreativeBtn;

	[SerializeField]
	private CreativeBrush brushPrefab;

	[SerializeField]
	private CreativeToggleOption optionPrefab;

	[NonSerialized]
	public CreativeBrush activeBrush;

	[NonSerialized]
	public List<CreativeBrush> brushes = new List<CreativeBrush>(32);

	public OnBrushSelected onBrushSelected;

	public const string Selector_CreativeHighlight = "selector_creativehighlight";

	[NonSerialized]
	public Selector highlight;

	private bool isVisible;

	private bool isWindowVisible;

	public Dictionary<int, CreativeToggleOption> options = new Dictionary<int, CreativeToggleOption>();

	private Cell lastBrushCell;

	private Vector3 rightMouseDownPos;

	private bool doAlternateBackground;

	public bool IsBrushActive()
	{
		if (inst != null)
		{
			return inst.activeBrush != null;
		}
		return false;
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	public bool IsWindowVisible()
	{
		return isWindowVisible;
	}

	private void Awake()
	{
		inst = this;
	}

	public void SetVisibility(bool v)
	{
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
		if (!v)
		{
			SetWindowVisibility(v: false);
		}
	}

	public void ToggleWindowVisibility()
	{
		SetWindowVisibility(!isWindowVisible);
	}

	public void SetWindowVisibility(bool v)
	{
		if (v && !isWindowVisible)
		{
			foreach (KeyValuePair<int, CreativeToggleOption> option in options)
			{
				option.Value.toggle.SetIsOnWithoutNotify(Creative.inst.IsCreativeOptionOn(option.Key));
			}
			difficultyDropdown.SetValueWithoutNotify((int)Player.inst.difficulty);
			BuildUI.inst.HideGroups();
		}
		else if (!v && isWindowVisible)
		{
			SetBrushNone();
		}
		isWindowVisible = v;
		Util.SetEnabled(wCanvas, v);
		Util.SetEnabled(wGRaycaster, v);
	}

	private void Start()
	{
		highlight = UnityEngine.Object.Instantiate(GameUI.inst.HighlightPrefab);
		highlight.SetupSelectorLookup("selector_creativehighlight");
		highlight.SetSingleCellMesh();
		AddOption(0);
		AddOption(11);
		AddOption(8);
		AddOption(2);
		AddOption(1);
		AddOption(3);
		AddOption(7);
		AddOption(10);
		AddOption(4);
		AddBrush("unit_militia", Resources.Load<Sprite>("Brushes/Icons/brush_legion_militia"), "brush_legion_militia", Resources.Load<GameObject>("Brushes/brush_creative_legion"), (Cell c, Cell prevC) =>
		{
			LegionSystem.Inst.TrySpawn(4, c.Center3D, 0, 1);
		}, InputType.OnPrimaryHeldNewCell);
		AddBrush("unit_legionswordsmen", Resources.Load<Sprite>("Brushes/Icons/brush_legion_swordsmen"), "brush_legion_swordsmen", Resources.Load<GameObject>("Brushes/brush_creative_legion"), (Cell c, Cell prevC) =>
		{
			LegionSystem.Inst.TrySpawn(0, c.Center3D, 0);
		}, InputType.OnPrimaryHeldNewCell);
		AddBrush("unit_cavalry", Resources.Load<Sprite>("Brushes/Icons/icon_cavalry"), "brush_cavalry", Resources.Load<GameObject>("Brushes/brush_creative_cavalry"), (Cell c, Cell prevC) =>
		{
			LegionSystem.Inst.TrySpawn(5, c.Center3D, 0, 1);
		}, InputType.OnPrimaryHeldNewCell);
		AddBrush("unit_invader", Resources.Load<Sprite>("Brushes/Icons/brush_legion_invader"), "brush_legion_invader", Resources.Load<GameObject>("Brushes/brush_creative_legion"), (Cell c, Cell prevC) =>
		{
			if (c != prevC)
			{
				if (c.Type == TerrainType.Water)
				{
					Vector3 center3D = c.Center3D;
					if (center3D.y < Water.inst.transform.position.y)
					{
						center3D.y = Water.inst.transform.position.y;
					}
					LegionUnit legionUnit = LegionSystem.Inst.TrySpawn(0, center3D, 1);
					IUnitControllable unitControllable = RaiderSystem.inst.SpawnBoatRaw(center3D, ShipSystem.inst.raiderTransportShip);
					if (legionUnit != null)
					{
						(unitControllable as MonoBehaviour).GetComponent<UnitTransportShip>().TryForceLoad(legionUnit);
					}
				}
				else
				{
					LegionSystem.Inst.TrySpawn(0, c.Center3D, 1);
				}
			}
		}, InputType.OnPrimaryHeldNewCell);
		AddBrush("CreativeMenuBrushnameDestroy", Resources.Load<Sprite>("Brushes/Icons/brush_creative_delete"), "brush_creative_delete", Resources.Load<GameObject>("Brushes/brush_creative_delete"), (Cell c, Cell prevC) =>
		{
			ClearCell(c);
		}, InputType.OnPrimaryHeldNewCell);
		AddBrush("CreativeMenuBrushnameRepair", Resources.Load<Sprite>("Brushes/Icons/brush_creative_repair"), "brush_creative_repair", Resources.Load<GameObject>("Brushes/brush_creative_repair"), (Cell c, Cell prevC) =>
		{
			if (c != prevC)
			{
				for (int i = 0; i < c.OccupyingStructure.Count; i++)
				{
					c.OccupyingStructure[i].Repair(float.MaxValue);
				}
			}
		}, InputType.OnPrimaryHeldNewCell);
		AddBrush("creativeui_brushname_addwater", Resources.Load<Sprite>("Brushes/Icons/brush_creative_addwater"), "brush_creative_addwater", Resources.Load<GameObject>("Brushes/brush_creative_addwater"), (Cell c, Cell prevC) =>
		{
			DynamicWater.inst.AddWaterToCellDeferred(c, 0.1f);
		});
		AddBrush("creativeui_brushname_removewater", Resources.Load<Sprite>("Brushes/Icons/brush_creative_removewater"), "brush_removewater", Resources.Load<GameObject>("Brushes/brush_creative_removewater"), (Cell c, Cell prevC) =>
		{
			OnWaterRemoved(c);
		});
		AddBrush("CreativeMenuBrushnameFire", Resources.Load<Sprite>("Brushes/Icons/brush_creative_fire"), "brush_creative_fire", Resources.Load<GameObject>("Brushes/brush_creative_fire"), (Cell c, Cell prevC) =>
		{
			FireManager.inst.StartFireAt(c);
		}, InputType.OnPrimaryDown);
		AddBrush("CreativeMenuBrushnameForest", Resources.Load<Sprite>("Brushes/Icons/brush_creative_forest"), "brush_creative_forest", Resources.Load<GameObject>("Brushes/brush_creative_forest"), (Cell c, Cell prevC) =>
		{
			if (c.Type == TerrainType.None && c.TopMostStructure == null && c != prevC)
			{
				for (int i = 0; i < 4; i++)
				{
					World.inst.treeSystem.PlaceItem(c);
				}
			}
		}, InputType.OnPrimaryHeldNewCell);
		AddBrush("CreativeMenuBrushnameVillagers", Resources.Load<Sprite>("Brushes/Icons/brush_creative_villagers"), "brush_creative_villagers", Resources.Load<GameObject>("Brushes/brush_creative_villagers"), (Cell c, Cell prevC) =>
		{
			if (c.Type != TerrainType.Water)
			{
				for (int i = 0; i < 5; i++)
				{
					Villager villager = Villager.CreateVillager();
					Player.inst.Workers.Add(villager);
					Player.inst.Homeless.Add(villager);
					villager.TeleportTo(c.Center3D + SRand.insideUnitSquareXZ * 0.5f);
				}
			}
		}, InputType.OnPrimaryHeldNewCell);
		foreach (FreeResourceSystem.ResourceDef rDef in FreeResourceSystem.inst.resourceDefs)
		{
			if (rDef.ID != 4 && rDef.ID != 17)
			{
				AddBrush(rDef.name, rDef.texture, "brush_creative_" + rDef.name, Resources.Load<GameObject>("Brushes/brush_creative_" + rDef.name), (Cell c, Cell prevC) =>
				{
					AddResource(c, rDef.ID);
				}, InputType.OnPrimaryHeldNewCell);
			}
		}
		difficultyDropdown.onValueChanged.AddListener(OnDifficultyChanged);
		List<TMP_Dropdown.OptionData> list = new List<TMP_Dropdown.OptionData>();
		list.Add(new TMP_Dropdown.OptionData("difficulty_peaceful"));
		list.Add(new TMP_Dropdown.OptionData("difficulty_easy"));
		list.Add(new TMP_Dropdown.OptionData("difficulty_hard"));
		list.Add(new TMP_Dropdown.OptionData("difficulty_survival"));
		difficultyDropdown.options = list;
		goldBtn.onClick.AddListener(AddGold);
		exitBtn.onClick.AddListener(() =>
		{
			SetWindowVisibility(v: false);
		});
		unlockTechTreeBtn.onClick.AddListener(() =>
		{
			TechnologyTree.inst.UnlockAvailable();
		});
		changeDifficultyBtn.onClick.AddListener(OnDifficultyChangeClick);
	}

	private void Update()
	{
		if (!isWindowVisible)
		{
			return;
		}
		if (activeBrush != null)
		{
			IPointer pointer = PointingSystem.GetPointer();
			bool flag = (activeBrush.inputType == InputType.OnPrimaryDown && pointer.GetPrimaryDown()) || (activeBrush.inputType == InputType.OnPrimaryUp && pointer.GetPrimaryUp()) || (activeBrush.inputType == InputType.OnPrimaryHeld && pointer.GetPrimaryDownThisFrame());
			Cell cell = null;
			if (flag)
			{
				cell = World.inst.GetCellDataClamped(GameUI.inst.GridPointerIntersection());
			}
			else if ((activeBrush.inputType == InputType.OnPrimaryHeldNewCell && pointer.GetPrimaryDownThisFrame()) || (activeBrush.inputType == InputType.OnPrimaryDownNewCell && pointer.GetPrimaryDown()))
			{
				cell = World.inst.GetCellDataClamped(GameUI.inst.GridPointerIntersection());
				if (cell != lastBrushCell)
				{
					flag = true;
				}
			}
			if (flag && !GameUI.inst.WasEventConsumed())
			{
				activeBrush.UpdateBrush(cell, lastBrushCell);
				lastBrushCell = cell;
			}
		}
		if (highlight != null)
		{
			Cell cellData = World.inst.GetCellData(GameUI.inst.GridPointerIntersection());
			if (cellData != null)
			{
				highlight.SetTargetWorldBounds(cellData.x, cellData.x + 1, cellData.z, cellData.z + 1);
			}
		}
		if (PointingSystem.GetPointer().GetSecondaryDown())
		{
			rightMouseDownPos = Input.mousePosition;
		}
		if (PointingSystem.GetPointer().GetSecondaryUp() && Vector3.Distance(rightMouseDownPos, Input.mousePosition) < 4f)
		{
			SetBrushNone();
		}
	}

	private void AddOption(int option)
	{
		CreativeToggleOption creativeToggleOption = UnityEngine.Object.Instantiate(optionPrefab, optionContainer.transform, worldPositionStays: false);
		Util.SetEnabled(creativeToggleOption.backgroundRI, doAlternateBackground = !doAlternateBackground);
		creativeToggleOption.localize.Term = "creativeui_option_" + CreativeOption.ValueDropdown[option].Text + "_title";
		creativeToggleOption.toggle.onValueChanged.AddListener((bool isOn) =>
		{
			OnToggleOptionChanged(option, isOn);
		});
		options.Add(option, creativeToggleOption);
	}

	private void OnDifficultyChanged(int idx)
	{
		Player.inst.difficulty = (Player.Difficulty)idx;
	}

	private void OnToggleOptionChanged(int optionIdx, bool isOn)
	{
		Creative.inst.SetCreativeModeOption(optionIdx, isOn);
	}

	public void AddBrush(string locTerm, Sprite icon, string brushUniqueName, GameObject brushObj, BrushUpdate func, InputType type = InputType.OnPrimaryHeld)
	{
		CreativeBrush brush = UnityEngine.Object.Instantiate(brushPrefab, tileBrushContainer.transform, worldPositionStays: false);
		SetupBrush(brush, locTerm, icon, brushUniqueName, brushObj, func, type);
	}

	public void AddUnitBrush(string locTerm, Sprite icon, string brushUniqueName, GameObject brushObj, BrushUpdate func)
	{
		CreativeBrush brush = UnityEngine.Object.Instantiate(brushPrefab, unitBrushContainer.transform, worldPositionStays: false);
		SetupBrush(brush, locTerm, icon, brushUniqueName, brushObj, func);
	}

	private void SetupBrush(CreativeBrush brush, string locTerm, Sprite icon, string brushUniqueName, GameObject brushObj, BrushUpdate func, InputType type = InputType.OnPrimaryHeld)
	{
		if (brushObj == null)
		{
			Debug.Log(brushUniqueName);
			return;
		}
		brush.UniqueName = brushUniqueName;
		brush.iconImage.sprite = icon;
		brush.hook.SetTerm(locTerm);
		brush.UpdateBrush = func;
		brush.button.onClick.AddListener(() =>
		{
			OnClickBrush(brush.hash);
		});
		brush.inputType = type;
		highlight.AddBrush(brushUniqueName, brushObj);
		brushes.Add(brush);
	}

	public void OnClickBrush(int uniqueHash)
	{
		if (GameUI.inst.currCursorMode != null)
		{
			GameUI.inst.ReturnToDefaultCursorMode();
		}
		if (GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			GameUI.inst.CurrPlacementMode.AbortPlacement(refund: true);
		}
		for (int i = 0; i < brushes.Count; i++)
		{
			CreativeBrush creativeBrush = brushes[i];
			if (creativeBrush.hash == uniqueHash)
			{
				creativeBrush.selectedOverlay.SetActive(value: true);
				activeBrush = creativeBrush;
				highlight.SetVisibility(v: true);
				highlight.SetBrush(creativeBrush.hash);
				onBrushSelected?.Invoke(creativeBrush);
			}
			else
			{
				creativeBrush.selectedOverlay.SetActive(value: false);
			}
		}
		lastBrushCell = null;
	}

	private void OnWaterAdded(Cell c)
	{
		int num = c.x * 2 + 1;
		int num2 = c.z * 2 + 1;
		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				int num3 = num + i;
				int index = (num2 + j) * (World.inst.GridWidth * 2 + 1) + num3;
				DynamicWater.WaterCell value = DynamicWater.inst.waterGrid[index];
				value.waterAmount += 0.1f;
				DynamicWater.inst.waterGrid[index] = value;
			}
		}
	}

	private void OnWaterRemoved(Cell c)
	{
		int num = c.x * 2 + 1;
		int num2 = c.z * 2 + 1;
		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				int num3 = num + i;
				int index = (num2 + j) * (World.inst.GridWidth * 2 + 1) + num3;
				DynamicWater.WaterCell value = DynamicWater.inst.waterGrid[index];
				value.waterAmount = Mathff.Max(0f, value.waterAmount - 5f);
				DynamicWater.inst.waterGrid[index] = value;
			}
		}
	}

	private unsafe void ClearCell(Cell cell)
	{
		World.inst.treeSystem.DeleteTreesAt(cell);
		GameUI.inst.RemoveChopJobFromCell(cell, sfx: false);
		ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(cell.x, cell.z);
		while (villagersAt.Count > 0)
		{
			Player.inst.DestroyPerson(villagersAt.data[0], leaveBehindBody: false);
		}
		GameObject caveAt = World.inst.GetCaveAt(cell);
		if (caveAt != null)
		{
			UnityEngine.Object.Destroy(caveAt);
			cell.Type = TerrainType.None;
			cell.StorePostGenerationType();
		}
		for (int num = cell.OccupyingStructure.Count - 1; num >= 0; num--)
		{
			Building building = cell.OccupyingStructure[num];
			if (building.uniqueNameHash == World.stoneBridgeHash || building.uniqueNameHash == World.woodBridgeHash)
			{
				Bridge component = building.GetComponent<Bridge>();
				for (int i = 0; i < component.bridgePath.Count; i++)
				{
					Cell cellData = World.inst.GetCellData(component.bridgePath.data[i]);
					for (int j = 0; j < cellData.OccupyingStructure.Count; j++)
					{
						Building building2 = cellData.OccupyingStructure[j];
						if (building2 != null && building2.uniqueNameHash == building.uniqueNameHash)
						{
							World.inst.DemolishBuilding(building2);
						}
					}
				}
			}
			else if (building.UniqueName != "keep")
			{
				World.inst.DemolishBuilding(cell.OccupyingStructure[num]);
			}
			BuildingCollapseManager.inst.CancelCollapse(building);
		}
		while (cell.SubStructure.Count > 0)
		{
			World.inst.DemolishBuilding(cell.SubStructure[cell.SubStructure.Count - 1]);
		}
		GameUI.inst.ClearCellSelected();
		for (int k = 0; k < ShipSystem.inst.ships.Count; k++)
		{
			ShipBase shipBase = ShipSystem.inst.ships.data[k];
			if (GameUI.inst.IsHighlighted(shipBase.GetComponent<ISelectable>()))
			{
				if ((bool)shipBase.GetComponent<Ship>())
				{
					UnityEngine.Object.Destroy(shipBase.gameObject);
				}
				else if ((bool)shipBase.GetComponent<UnitTransportShip>())
				{
					UnitSystem.inst.DestroyUnit(shipBase.GetComponent<IUnitControllable>());
				}
			}
		}
		for (int l = 0; l < OrdersManager.inst.units.Count; l++)
		{
			IMoveableUnit moveableUnit = OrdersManager.inst.units[l];
			if (moveableUnit.IsBeingCarried())
			{
				continue;
			}
			Cell cellDataClamped = World.inst.GetCellDataClamped(moveableUnit.GetPos());
			if (cell == cellDataClamped || (moveableUnit is ISelectable && GameUI.inst.IsHighlighted(moveableUnit as ISelectable)) || (moveableUnit as MonoBehaviour != null && GameUI.inst.IsHighlighted((moveableUnit as MonoBehaviour).GetComponent<ISelectable>())))
			{
				if (moveableUnit is ArmySystem.Army)
				{
					ArmySystem.inst.ReleaseArmy(moveableUnit as ArmySystem.Army);
				}
				else if (moveableUnit is IProjectileHitable projectileHitable)
				{
					projectileHitable.TakeProjectileDamage(99999f, DamageType.Standard, DamageSource.Melee, moveableUnit.GetPos(), Vector3.zero, -1);
				}
			}
		}
		for (int m = 0; m < DragonSpawn.inst.currentDragons.Count; m++)
		{
			Dragon dragon = DragonSpawn.inst.currentDragons.data[m];
			if (World.inst.GetCellData(dragon.transform.position) == cell)
			{
				dragon.TakeDamage(dragon.HP() + 1f);
			}
		}
		for (int n = 0; n < ResourceStackAuto.stacks.Count; n++)
		{
			if (World.inst.GetCellDataClamped(ResourceStackAuto.stacks.data[n].transform.position) == cell)
			{
				ResourceStackAuto.stacks.data[n].Clear();
			}
		}
		for (int num2 = 0; num2 < UnitSystem.inst.legionUnits.Count; num2++)
		{
			LegionUnit legionUnit = UnitSystem.inst.legionUnits.data[num2];
			LegionGroup legionGroup = legionUnit.GetGroup();
			for (int num3 = 0; num3 < legionGroup.numCells; num3++)
			{
				if (World.inst.GetCellDataClamped(LegionSystem.Inst.legionCells[legionGroup.cells[num3]].position) == cell)
				{
					UnitSystem.inst.DestroyUnit(legionUnit);
					break;
				}
			}
		}
		World.inst.rebakeCells.Add(cell);
	}

	public void AddGold()
	{
		if (Player.inst.FocusedLandMass >= 0)
		{
			LandmassOwner landmassOwner = World.GetLandmassOwner(Player.inst.FocusedLandMass);
			if (landmassOwner != null)
			{
				landmassOwner.Gold += 250;
			}
			RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_merchant_sellto");
		}
	}

	public void AddResource(Cell cell, int t)
	{
		if (cell.landMassIdx != -1 && t != 4)
		{
			FreeResourceManager.inst.GetAutoStackFor(t, 50, cell.Center3D);
			ResourceStatistics.AddProduction(cell.landMassIdx, "creative", t, 50);
		}
	}

	public void SetBrushNone()
	{
		activeBrush = null;
		if (highlight != null)
		{
			highlight.SetVisibility(v: false);
			highlight.ResetBrushes();
		}
		lastBrushCell = null;
		for (int i = 0; i < brushes.Count; i++)
		{
			brushes[i].selectedOverlay.SetActive(value: false);
		}
		onBrushSelected?.Invoke(null);
	}

	private void OnDifficultyChangeClick()
	{
		DifficultyUI.inst.SetState(1);
		DifficultyUI.inst.SetReturnFunc(() =>
		{
			DifficultyUI.inst.SetVisibility(v: false);
			GameState.inst.SetNewMode(GameState.inst.playingMode);
		});
		DifficultyUI.inst.SetExitFunc(() =>
		{
			DifficultyUI.inst.SetVisibility(v: false);
			GameState.inst.SetNewMode(GameState.inst.playingMode);
		});
		GameUI.inst.AbortCursorObjPlacement();
		GameUI.inst.ReturnToDefaultCursorMode();
		GameState.inst.SetNewMode(GameState.inst.mainMenuMode);
		GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.ChooseDifficulty);
		TimeManager.inst.SetPaused(skipSfx: true);
		SfxSystem.PlayUiSelect();
	}
}
