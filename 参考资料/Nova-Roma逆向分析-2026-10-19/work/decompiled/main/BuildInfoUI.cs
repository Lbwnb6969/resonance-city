using System;
using System.Collections.Generic;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildInfoUI : MonoBehaviour
{
	public Transform buildRuleParent;

	public TextMeshProUGUI ruleTextUI;

	public Image ruleImage;

	public Color errorColor;

	public Color warningColor;

	public Color kindaOkayColor;

	public Color okayColor;

	public Transform buildDescParent;

	public TextMeshProUGUI buildDescText;

	public TextMeshProUGUI costTextUI;

	public Transform buildCostParent;

	public Sprite[] cursorIcons;

	public TextMeshProUGUI cursorTitle;

	public Image cursorMainImage;

	public Image cursorSubImage;

	public Transform cursorDetailsContainer;

	public static BuildInfoUI inst;

	private Building prevBuilding;

	private Vector3[] testPoints = new Vector3[4];

	private string aqueductHint;

	public void Awake()
	{
		inst = this;
	}

	private void Update()
	{
		Building b = GameUI.inst.CurrPlacementMode.GetHoverBuilding();
		bool num = (bool)b || GameUI.inst.currCursorMode != null;
		bool flag = GameUI.inst.PointerOverUI() && !GameUI.inst.AqueductCursorModeActive();
		if (num && !flag)
		{
			string text = "";
			string text2 = ruleTextUI.text;
			if ((bool)b)
			{
				bool active = true;
				Util.SetActive(cursorDetailsContainer, active: false);
				Util.SetActive(buildDescParent, active: true);
				if (GamepadControl.inst.isControllerActive && b.dragPlacementMode == Building.DragPlacementMode.None)
				{
					buildDescParent.gameObject.SetActive(value: false);
				}
				if (b != prevBuilding)
				{
					string text3 = "";
					if (b.dragPlacementMode != Building.DragPlacementMode.None)
					{
						text3 = GamepadControl.GetPlatformLocalization("DragPlacement", "ConsoleDragPlacement");
					}
					else
					{
						text3 = ((b.uniqueNameHash != World.waterTowerHash) ? string.Format(ScriptLocalization.rotate_instructions, KeyCode.R) : LocalizationManager.GetTranslation("buildinfoui_watertowerhint"));
					}
					if (buildDescText.text != text3)
					{
						buildDescText.text = text3;
					}
				}
				List<Building> buildings = GameUI.inst.CurrPlacementMode.buildings;
				Building building = buildings[buildings.Count - 1];
				float num2 = -1000f;
				testPoints[0] = building.transform.position + new Vector3(0f, building.size.y + 0.25f, 0f);
				testPoints[1] = building.transform.position + new Vector3(building.size.x, building.size.y + 0.25f, 0f);
				testPoints[2] = building.transform.position + new Vector3(0f, building.size.y + 0.25f, building.size.z);
				testPoints[3] = building.transform.position + new Vector3(building.size.x, building.size.y + 0.25f, building.size.z);
				for (int i = 0; i < testPoints.Length; i++)
				{
					Vector2 vector = Mathff.WorldPosToScreen(testPoints[i], GameUI.inst.rectT);
					if (vector.y > num2)
					{
						num2 = vector.y;
					}
				}
				if ((bool)b.GetComponent<AqueductBuilding>())
				{
					num2 += 50f;
				}
				Vector3 vector2 = Mathff.WorldPosToScreen(building.Center(), GameUI.inst.rectT);
				vector2.y = num2;
				GetComponent<RectTransform>().anchoredPosition = vector2;
				bool doesAnyCellTouchWater = false;
				b.ForEachTileInBounds((int x, int z, Cell c) =>
				{
					if (c.Type == TerrainType.Water)
					{
						doesAnyCellTouchWater = true;
					}
				});
				Cell cellData = World.inst.GetCellData(b.transform.position);
				if (cellData == null)
				{
					ruleTextUI.SetText(ScriptLocalization.OutOfBounds);
					return;
				}
				if (GameUI.inst.CurrPlacementMode.IsOneNotAffordable())
				{
					if (GameUI.inst.CurrPlacementMode.PlacementCount() > 1 && GameUI.inst.CurrPlacementMode.IsOneAffordable())
					{
						ruleImage.color = (b.entireDragMustBeValid ? errorColor : warningColor);
						text = LocalizationManager.GetTranslation(b.entireDragMustBeValid ? "BuildInfoMustAfford" : "BuildInfoAffordWarning");
					}
					else
					{
						ruleImage.color = errorColor;
						text = ScriptLocalization.b_Insufficient_resources_b;
					}
				}
				bool flag2 = !GameUI.inst.CurrPlacementMode.IsOneNotAffordable();
				PlacementValidationResult placementValidationResult = GameUI.inst.CurrPlacementMode.CanPlace();
				if (placementValidationResult == PlacementValidationResult.Valid)
				{
					placementValidationResult = GameUI.inst.CurrPlacementMode.GetInvalidPlacementResult();
				}
				if (flag2 && placementValidationResult != PlacementValidationResult.Valid)
				{
					ruleImage.color = errorColor;
				}
				if (flag2)
				{
					text = GetTextForValidationResult(placementValidationResult, doesAnyCellTouchWater);
				}
				if (flag2 && placementValidationResult == PlacementValidationResult.Valid)
				{
					if (b.uniqueNameHash == World.fishinghutHash)
					{
						text = b.GetComponent<FishingHut>().GetPlacementInfo(out var okLevel);
						if (okLevel == 0)
						{
							ruleImage.color = warningColor;
						}
						if (okLevel == 1)
						{
							ruleImage.color = kindaOkayColor;
						}
						if (okLevel == 2)
						{
							ruleImage.color = okayColor;
						}
					}
					if (b.categoryHash == World.fountainHash || b.uniqueNameHash == "publictoilets".GetHashCode())
					{
						int count = 0;
						b.ForEachTileInBounds((int x, int z, Cell cell) =>
						{
							if (!WaterTower.IsTileInRangeOfTowers(b.GetCell()))
							{
								count++;
							}
						});
						if ((float)count >= b.size.x * b.size.z)
						{
							text = ScriptLocalization.FountainErrorNotConnected;
							ruleImage.color = warningColor;
						}
					}
					if (b.categoryHash == World.orchardHash || b.categoryHash == World.farmHash)
					{
						int effectiveFertility = cellData.GetEffectiveFertility();
						if (effectiveFertility == 1)
						{
							text = ScriptLocalization.FieldMediumFertility;
							ruleImage.color = kindaOkayColor;
						}
						if (effectiveFertility == 2)
						{
							text = ScriptLocalization.FieldHighFertility;
							ruleImage.color = okayColor;
						}
						Field component = b.GetComponent<Field>();
						if (component != null && component.angleLimit != -1f && component.IsSlopedForBonus(cellData, Mathf.Cos(component.angleLimit * (MathF.PI / 180f))))
						{
							if (effectiveFertility == 1 || effectiveFertility == 2)
							{
								text = text + " | " + LocalizationManager.GetTranslation("TileSlopedForBonus");
							}
							else
							{
								text = LocalizationManager.GetTranslation("TileSlopedForBonus");
								ruleImage.color = kindaOkayColor;
							}
						}
					}
				}
				ResourceAmount placementCost = GameUI.inst.CurrPlacementMode.GetPlacementCost();
				string text4 = "";
				if (!placementCost.IsNone())
				{
					text4 = placementCost.ToString();
				}
				else
				{
					ResourceAmount resourceAmount = (b.entireDragMustBeValid ? GameUI.inst.CurrPlacementMode.GetTotalPotentialCost(Player.inst.FocusedLandMass) : b.GetCost(Player.inst.FocusedLandMass));
					if (resourceAmount.IsNone())
					{
						active = false;
					}
					else
					{
						text4 = resourceAmount.NeedCost(Player.inst.FocusedResources);
					}
				}
				if (GameUI.inst.DamPlannerCursorModeActive() && string.IsNullOrEmpty(text))
				{
					ResourceAmount costForAll = DamPlannerUI.inst.cursorMode.GetCostForAll();
					if (!Player.inst.FocusedResources.HasCost(costForAll))
					{
						ruleImage.color = warningColor;
						text = ScriptLocalization.b_Insufficient_resources_b;
					}
				}
				if (costTextUI.text != text4)
				{
					costTextUI.text = text4;
				}
				Util.SetActive(buildCostParent, active);
			}
			else if (GameUI.inst.currCursorMode != null)
			{
				if (GameUI.inst.AqueductCursorModeActive())
				{
					GetComponent<RectTransform>().anchoredPosition = new Vector2(0f, GetComponent<RectTransform>().sizeDelta.y * 1.25f);
				}
				else
				{
					Vector2 anchoredPosition = Mathff.WorldPosToScreen(GameUI.inst.GridPointerIntersection() + new Vector3(0f, 2.5f, 0f), GameUI.inst.rectT);
					GetComponent<RectTransform>().anchoredPosition = anchoredPosition;
				}
				buildDescText.SetText(GamepadControl.GetPlatformLocalization("DragSelection", "ConsoleDragSelection"));
				buildDescParent.gameObject.SetActive(value: true);
				cursorDetailsContainer.gameObject.SetActive(value: true);
				cursorMainImage.gameObject.SetActive(value: true);
				buildCostParent.gameObject.SetActive(value: false);
				cursorSubImage.gameObject.SetActive(value: false);
				CursorMode currCursorMode = GameUI.inst.currCursorMode;
				cursorMainImage.color = Color.white;
				if (currCursorMode == GameUI.inst.chopCursorMode)
				{
					cursorTitle.SetText(ScriptLocalization.Chop);
					cursorMainImage.sprite = cursorIcons[0];
					cursorMainImage.color = Color.white;
					Cell highlightedCell = GameUI.inst.GetHighlightedCell();
					if (highlightedCell != null && highlightedCell.Type == TerrainType.Obstruction && (highlightedCell.terrainResource == null || highlightedCell.HasTerrainResourceType(2)))
					{
						text = ScriptLocalization.cursormodeui_stonestoolargeerror;
						ruleImage.color = errorColor;
					}
				}
				else if (currCursorMode == GameUI.inst.chopCancelCursorMode)
				{
					cursorTitle.SetText(ScriptLocalization.ChopCancelMode);
					cursorMainImage.sprite = cursorIcons[0];
					cursorSubImage.gameObject.SetActive(value: true);
				}
				else if (currCursorMode == GameUI.inst.rebuildCursorMode)
				{
					cursorTitle.SetText(ScriptLocalization.RebuildMode);
					cursorMainImage.sprite = cursorIcons[1];
					cursorMainImage.color = Color.yellow;
				}
				else if (currCursorMode == GameUI.inst.demolishCursorMode)
				{
					cursorTitle.SetText(ScriptLocalization.Demolish);
					cursorMainImage.sprite = cursorIcons[2];
					cursorMainImage.color = Color.red;
				}
				else if (currCursorMode == GameUI.inst.sampleCursorMode)
				{
					cursorTitle.SetText(ScriptLocalization.buildinfoui_cursormode_sample_title);
					cursorMainImage.sprite = cursorIcons[5];
					buildDescText.SetText(ScriptLocalization.buildinfoui_cursormode_sample_description);
				}
				else if (currCursorMode == GameUI.inst.shipLogisticsUI.cursorMode)
				{
					if (GameUI.inst.shipLogisticsUI.inEditRouteMode || !GamepadControl.inst.isControllerActive)
					{
						cursorTitle.SetText(ScriptLocalization.EditRouteMode);
						cursorMainImage.sprite = cursorIcons[3];
						cursorMainImage.color = Color.white;
						cursorMainImage.gameObject.SetActive(value: false);
						ruleTextUI.SetText(GameUI.inst.shipLogisticsUI.logsiticsErrorText.text);
						buildRuleParent.gameObject.SetActive(GameUI.inst.shipLogisticsUI.logsiticsError.activeInHierarchy);
						buildDescText.SetText(GamepadControl.GetPlatformLocalization("EditTransportRoute", "ScriptTerms.ConsoleEditTransportRoute"));
						if (currCursorMode is DockRouteCursorMode { InvalidInsertionPoint: not false } dockRouteCursorMode)
						{
							buildRuleParent.gameObject.SetActive(value: true);
							ruleTextUI.SetText(dockRouteCursorMode.InvalidInsertionPointMessage);
						}
						GameUI.inst.CellHighlighter.SetHoverIcon(GameUI.HoverIcons.EditRoute);
					}
					else
					{
						GameUI.inst.CellHighlighter.SetHoverIcon(GameUI.HoverIcons.None);
						buildDescParent.gameObject.SetActive(value: false);
						cursorDetailsContainer.gameObject.SetActive(value: false);
						cursorMainImage.gameObject.SetActive(value: false);
					}
				}
				else if (currCursorMode == GameUI.inst.editTerrainUI.cursorMode)
				{
					text = GameUI.inst.editTerrainUI.cursorMode.SetBuildInfo(this);
				}
				else if (GameUI.inst.currCursorMode is LogisticsRouteCursorMode logisticsRouteCursorMode)
				{
					cursorMainImage.color = Color.white;
					cursorMainImage.sprite = cursorIcons[3];
					cursorTitle.SetText(LocalizationManager.GetTranslation("AssignLogisticsRoutes"));
					ruleImage.color = errorColor;
					string error = logisticsRouteCursorMode.GetError();
					Util.SetActive(buildDescParent, active: false);
					if (!string.IsNullOrEmpty(error))
					{
						text = error;
					}
					else if (Player.inst.FocusedLandMass != -1 && !LogisticsManager.inst.AnyRoutesOnLandmass(Player.inst.FocusedLandMass))
					{
						text = LocalizationManager.GetTranslation("transportui_error_noroutes");
					}
				}
				else if (GameUI.inst.currCursorMode is SelectLogisticsSourceMode selectLogisticsSourceMode)
				{
					cursorMainImage.color = Color.white;
					cursorMainImage.sprite = cursorIcons[5];
					cursorTitle.SetText(LocalizationManager.GetTranslation("AddSupplier"));
					buildDescText.SetText(LocalizationManager.GetTranslation("AddSupplierDesc"));
					ruleImage.color = errorColor;
					string error2 = selectLogisticsSourceMode.GetError();
					if (!string.IsNullOrEmpty(error2))
					{
						text = error2;
					}
				}
				else if (currCursorMode == GameUI.inst.aqueductPlacementCursorMode)
				{
					AqueductPlacementCursorMode aqueductPlacementCursorMode = currCursorMode as AqueductPlacementCursorMode;
					cursorTitle.SetText(ScriptLocalization.AqueductBuildMode);
					if (aqueductHint == null)
					{
						aqueductHint = ScriptLocalization.AqueductBuildModeDescription + "\n" + LocalizationManager.GetTranslation("AqueductConnectionRequiredNoRiver");
					}
					buildDescText.SetText(aqueductHint);
					cursorMainImage.gameObject.SetActive(value: false);
					string buildStatus = aqueductPlacementCursorMode.GetBuildStatus(out var colorIndex);
					if (!string.IsNullOrEmpty(buildStatus))
					{
						text = buildStatus;
						if (colorIndex == 0)
						{
							ruleImage.color = errorColor;
						}
						if (colorIndex == 1)
						{
							ruleImage.color = okayColor;
						}
						if (colorIndex == 2)
						{
							ruleImage.color = warningColor;
						}
					}
					ResourceAmount buildCost = aqueductPlacementCursorMode.placingAqueductLine.GetBuildCost();
					if (!Creative.inst.IsCreativeOptionOn(0) && buildCost.Get(2) > aqueductPlacementCursorMode.placingAqueductLine.costPerMesh.Get(2))
					{
						buildCostParent.gameObject.SetActive(value: true);
						if (Player.inst.FocusedResources.HasCost(buildCost))
						{
							costTextUI.SetText(buildCost.ToString());
						}
						else
						{
							costTextUI.SetText(ResourceAmount.MakeRed(buildCost.ToString()));
						}
					}
					else
					{
						buildCostParent.gameObject.SetActive(value: false);
					}
				}
				else
				{
					buildDescParent.gameObject.SetActive(value: false);
					cursorDetailsContainer.gameObject.SetActive(value: false);
					cursorMainImage.gameObject.SetActive(value: false);
				}
			}
			if (text != text2)
			{
				ruleTextUI.text = text;
			}
			Util.SetActive(buildRuleParent, ruleTextUI.text != "");
			if (buildRuleParent.gameObject.activeSelf)
			{
				Util.SetActive(buildDescParent.gameObject, active: false);
			}
			prevBuilding = b;
		}
		else
		{
			Util.SetActive(buildCostParent, active: false);
			Util.SetActive(buildRuleParent, active: false);
			Util.SetActive(buildDescParent, active: false);
			Util.SetActive(cursorDetailsContainer, active: false);
			ruleImage.color = errorColor;
			prevBuilding = null;
			aqueductHint = null;
		}
	}

	private string GetTextForValidationResult(PlacementValidationResult validationResult, bool doesAnyCellTouchWater)
	{
		string result = "";
		switch (validationResult)
		{
		case PlacementValidationResult.OutsideOfTerritory:
			result = ScriptLocalization.PVROutsideOfTerritory;
			break;
		case PlacementValidationResult.BridgeNotInWater:
			result = ScriptLocalization.PVRBridgesInWater;
			break;
		case PlacementValidationResult.PierNotInWater:
			result = "ScriptLocalization.PVRPierInWater";
			break;
		case PlacementValidationResult.RoadNotOnLand:
			result = ScriptLocalization.PVRRoadNotOnLand;
			break;
		case PlacementValidationResult.MustBeOnFertileLand:
			result = ScriptLocalization.PVRMustBeFertile;
			break;
		case PlacementValidationResult.MustBeOnWaterOrClearLand:
			result = ScriptLocalization.PVRMustBeFlatLand;
			break;
		case PlacementValidationResult.MustBeOnFlatLand:
			result = (doesAnyCellTouchWater ? ScriptLocalization.PVRCannotBuildOnWater : ScriptLocalization.PVRMustBeFlatLand);
			break;
		case PlacementValidationResult.ExistingStructure:
			result = ScriptLocalization.PVRBlockedByExistingStructure;
			break;
		case PlacementValidationResult.QuarryMustBeAdjacentToStone:
			result = ScriptLocalization.PVRQuarryNearStone;
			break;
		case PlacementValidationResult.IronMineMustBeAdjacentToIron:
			result = ScriptLocalization.PVRIronNearStone;
			break;
		case PlacementValidationResult.OnlyStackOnCastleBlocks:
			result = ScriptLocalization.PVROnlyStackOnCastleBlocks;
			break;
		case PlacementValidationResult.ForesterTooCloseToForester:
			result = ScriptLocalization.PVRForesterTooClose;
			break;
		case PlacementValidationResult.QuarryMustBeAdjacentToMarble:
			result = LocalizationManager.GetTranslation("PVRQuarryNearMarble");
			break;
		case PlacementValidationResult.TooManyIronMines:
			result = ScriptLocalization.PVRTooManyIronMines;
			break;
		case PlacementValidationResult.CastleBlockNoSupport:
			result = "ScriptLocalization.PVRCastleBlockSupport";
			break;
		case PlacementValidationResult.QuarryMustFaceRock:
			result = ScriptLocalization.PVRQuarryOrientation;
			break;
		case PlacementValidationResult.IronMineMustFaceRock:
			result = ScriptLocalization.PVRIronMineOrientation;
			break;
		case PlacementValidationResult.CastleBlocksNotLikeType:
			result = "ScriptLocalization.PVRCastleBlocksOfLikeType";
			break;
		case PlacementValidationResult.NoriaBaseOnLand:
			result = "ScriptLocalization.PVRNoriaBaseOnLand";
			break;
		case PlacementValidationResult.NoriaTooCloseToExisting:
			result = "ScriptLocalization.PVRNoriaTooCloseToExisting";
			break;
		case PlacementValidationResult.NoriaWheelOnWater:
			result = "ScriptLocalization.PVRNoriaWheelOnWater";
			break;
		case PlacementValidationResult.NoriaWheelOnFreshWater:
			result = "ScriptLocalization.PVRNoriaWheelOnFreshWater";
			break;
		case PlacementValidationResult.MustBeOnShallowWater:
			result = ScriptLocalization.PVRCannotBuildOnDeepWater;
			break;
		case PlacementValidationResult.WoodCastleWallLimit:
			result = "ScriptLocalization.PVRWoodCastleWallLimit";
			break;
		case PlacementValidationResult.WellOnGround:
			result = ScriptLocalization.PVRWellOnGround;
			break;
		case PlacementValidationResult.BadStartingArea:
			result = ScriptLocalization.PVRBadStartingArea;
			break;
		case PlacementValidationResult.DockNearWater:
			result = ScriptLocalization.PVRDockNearWater;
			break;
		case PlacementValidationResult.ShipNotInWater:
			result = ScriptLocalization.PVRShipsInWater;
			break;
		case PlacementValidationResult.MustBeOnCorrectLandMass:
			result = ScriptLocalization.PVRWrongIsland;
			break;
		case PlacementValidationResult.BuildAnOutpostOnUnclaimedLand:
			result = ScriptLocalization.PVRBuildAnOutpostOnUnclaimedLand;
			break;
		case PlacementValidationResult.OneOutpostPerLandmass:
			result = LocalizationManager.GetTranslation("PVROneOutpostPerLandmass");
			break;
		case PlacementValidationResult.CannotBuildOnWater:
			result = ScriptLocalization.PVRCannotBuildOnWater;
			break;
		case PlacementValidationResult.TooCloseToWolves:
			result = "ScriptLocalization.PVRTooCloseToWolves";
			break;
		case PlacementValidationResult.NotNearFish:
			result = ScriptLocalization.PVRNotNearFish;
			break;
		case PlacementValidationResult.SeaGateNotOnWater:
			result = ScriptLocalization.PVRBuildingNotInWater;
			break;
		case PlacementValidationResult.OnPlannedAIIsland:
			result = "ScriptLocalization.PVROnPlannedAIIsland";
			break;
		case PlacementValidationResult.OutpostTooFarFromSeedShip:
			result = LocalizationManager.GetTranslation("PVROutpostTooFarFromSeedShip");
			break;
		case PlacementValidationResult.TooFarFromWater:
			result = ScriptLocalization.PVRTooFarFromWater;
			break;
		case PlacementValidationResult.MustBuildBridgeOverWater:
			result = ScriptLocalization.PVRMustBuildBridgeOverWater;
			break;
		case PlacementValidationResult.EndsOfBridgeMustBeClearLand:
			result = ScriptLocalization.PVREndsOfBridgeMustBeClearLand;
			break;
		case PlacementValidationResult.CannotBuildOnDynamicWater:
			result = ScriptLocalization.PVRCannotBuildOnWater;
			break;
		case PlacementValidationResult.CannotBuildOnExistingDamPlanningProject:
			result = ScriptLocalization.PVRCannotBuildOnExistingDamPlanningProject;
			break;
		case PlacementValidationResult.BridgeIsTooSteep:
			result = ScriptLocalization.PVRBridgeIsTooSteep;
			break;
		case PlacementValidationResult.BridgeIsTooCloseToAnotherBridge:
			result = ScriptLocalization.PVRBridgeIsTooCloseToOtherBridge;
			break;
		case PlacementValidationResult.MustBeOnOrOffForumEntirely:
			result = ScriptLocalization.PVRMustBeOnOrOffForumEntirely;
			break;
		case PlacementValidationResult.DockIsTooSteep:
			result = ScriptLocalization.pvr_dockistoosteep_error;
			break;
		case PlacementValidationResult.SpilloverMustBeBetweenTwoDamsOnly:
			result = LocalizationManager.GetTranslation("PVRSpilloverMustBeBetweenTwoDamsOnly");
			break;
		case PlacementValidationResult.SpilloverAlreadyASpillover:
			result = LocalizationManager.GetTranslation("PVRSpilloverAlreadyASpillover");
			break;
		case PlacementValidationResult.SpilloverDamHasTap:
			result = LocalizationManager.GetTranslation("PVRSpilloverDamHasTap");
			break;
		case PlacementValidationResult.ShopMustBeInApartment:
			result = ScriptLocalization.PVRShopMustBeInApartment;
			break;
		case PlacementValidationResult.GroundTooSteep:
			result = LocalizationManager.GetTranslation("PVRGroundTooSteep");
			break;
		case PlacementValidationResult.DamBlockCannotBePlacedAdjacentToSpillway:
			result = LocalizationManager.GetTranslation("PVRDamBlockCannotBePlacedAdjacentToSpillway");
			break;
		case PlacementValidationResult.MustFaceOcean:
			result = LocalizationManager.GetTranslation("PVRMustFaceOcean");
			break;
		case PlacementValidationResult.BridgeCannotBuildOverOcean:
			result = LocalizationManager.GetTranslation("PVRBridgeCannotBuildOverOcean");
			break;
		case PlacementValidationResult.ResourceDepositCovered:
			result = LocalizationManager.GetTranslation("PVRResourceDepositCovered");
			break;
		case PlacementValidationResult.ResourceDepositBuried:
			result = LocalizationManager.GetTranslation("PVRResourceDepositBuried");
			break;
		}
		return result;
	}
}
