using System;
using System.Collections.Generic;
using System.Linq;
using Code;
using FMODUnity;
using I2.Loc;
using UnityEngine;
using UnityEngine.Rendering;

public class AqueductPlacementCursorMode : CursorMode
{
	private const int maxConnections = 1;

	private AqueductTargetResolver targetResolver;

	private AqueductConnectionValidator connectionValidator;

	private InlineSelectionManager inlineManager;

	private RiverTapPlacer riverTapPlacer;

	private AqueductPreviewRenderer previewRenderer;

	private AqueductPlacementPhase currentPhase;

	private InfoLineForAqueductSystem infoLine;

	private const float inlineEndpointSnapDistance = 0.35f;

	private const float minWaypointDistance = 0.5f;

	public AqueductLine placingAqueductLine;

	private AqueductBuilding startBuilding;

	private AqueductBuilding destinationVirtualRiverTap;

	private RiverTap previewRiverTap;

	private bool waypointsWereReversed;

	private InlineAqueductSelection startInlineSelection;

	private InlineAqueductSelection destinationInlineSelection;

	private Vector3 startPos;

	private Vector3 endPos;

	private AqueductBuilding sourceBuilding;

	private AqueductBuilding destinationBuilding;

	private bool sourcePortAvailable;

	private bool destinationPortAvailable;

	private List<Vector3> waypoints;

	private int hoverErrorCode;

	private ArrayExt<Renderer> normal = new ArrayExt<Renderer>(1000);

	private ArrayExt<Renderer> highlight = new ArrayExt<Renderer>(1000);

	private AqueductBuilding prevDestBuilding;

	private bool validFirstClick;

	private bool IsSnappedToDestination
	{
		get
		{
			if (currentPhase != AqueductPlacementPhase.SnappedToDestination)
			{
				return currentPhase == AqueductPlacementPhase.ReadyToBuild;
			}
			return true;
		}
	}

	private bool IsReadyToBuild => currentPhase == AqueductPlacementPhase.ReadyToBuild;

	public override bool HideThoughtBubble()
	{
		return true;
	}

	public override void Init()
	{
		InWorldExclamation.hideForCursorMode = true;
		waypoints = new List<Vector3>();
		if (targetResolver == null)
		{
			targetResolver = new AqueductTargetResolver();
		}
		if (connectionValidator == null)
		{
			connectionValidator = new AqueductConnectionValidator();
		}
		if (inlineManager == null)
		{
			inlineManager = new InlineSelectionManager();
		}
		if (riverTapPlacer == null)
		{
			riverTapPlacer = new RiverTapPlacer();
		}
		if (previewRenderer == null)
		{
			previewRenderer = new AqueductPreviewRenderer();
		}
		GameObject original = Resources.Load<GameObject>("AqueductLine");
		placingAqueductLine = UnityEngine.Object.Instantiate(original).GetComponent<AqueductLine>();
		placingAqueductLine.DisplayOnly(b: true);
		placingAqueductLine.SetStartEnd();
		placingAqueductLine.FullBuild();
		if (infoLine == null)
		{
			GameObject gameObject = UnityEngine.Object.Instantiate(Resources.Load<GameObject>("InfoLineForAqueducts"), null, worldPositionStays: false);
			gameObject.name = "Info line for aqueduct";
			infoLine = gameObject.GetComponent<InfoLineForAqueductSystem>();
			infoLine.Init();
		}
		infoLine.gameObject.SetActive(value: false);
		GameUI.inst.ClearCellSelected();
		WorldMask.inst.Activate(Masking);
		World.inst.treeSystem.enabled = false;
	}

	public override bool ShowDragSelectBounds()
	{
		return false;
	}

	public override bool ShowCellHighlighter()
	{
		return false;
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		return true;
	}

	public override bool DoSecondaryClick()
	{
		if (HoldingBuilding())
		{
			if (waypoints.Count > 0)
			{
				waypoints.RemoveAt(waypoints.Count - 1);
				if (IsSnappedToDestination)
				{
					currentPhase = AqueductPlacementPhase.PlacingWaypoints;
				}
			}
			else
			{
				if (startBuilding is RiverTap)
				{
					UnityEngine.Object.Destroy(startBuilding.gameObject);
				}
				CleanupVirtualRiverTap();
				inlineManager.ClearInlineSelection(ref startInlineSelection);
				inlineManager.ClearInlineSelection(ref destinationInlineSelection);
				startBuilding = null;
				waypointsWereReversed = false;
				currentPhase = AqueductPlacementPhase.Idle;
			}
			return true;
		}
		return false;
	}

	private void CleanupPreviewRiverTap()
	{
		riverTapPlacer.CleanupPreviewRiverTap(ref previewRiverTap);
	}

	private void CleanupVirtualRiverTap()
	{
		riverTapPlacer.CleanupDestinationRiverTap(ref destinationVirtualRiverTap);
	}

	public bool HoldingBuilding()
	{
		return startBuilding != null;
	}

	private bool TryGetLineUnderCursor(Ray ray, out AqueductLine line, out RaycastHit hitInfo, out RiverTapPlacer.DamFaceHit damFace)
	{
		bool flag = targetResolver.TryGetAqueductLineUnderCursor(ray, out line, out hitInfo);
		riverTapPlacer.TryGetDamFaceUnderCursor(ray, out damFace);
		if (flag && damFace != null && damFace.distance < hitInfo.distance)
		{
			flag = false;
			line = null;
		}
		return flag;
	}

	public override void HandlePrimaryDown()
	{
		Ray ray = PointingSystem.GetRay();
		if (startBuilding == null)
		{
			if (targetResolver.TryGetAqueductBuildingUnderCursor(ray, out var building, out var _))
			{
				if (building.HasAvailablePorts())
				{
					RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_aqueduct_snap", building.transform.position);
					startBuilding = building;
					currentPhase = AqueductPlacementPhase.PlacingWaypoints;
				}
				return;
			}
			if (TryGetLineUnderCursor(ray, out var line, out var hitInfo2, out var damFace) && inlineManager.TryResolveLineTarget(line, hitInfo2, ref startInlineSelection, out var building2, out var _) && building2 != null)
			{
				if (startInlineSelection != null || building2.HasAvailablePorts())
				{
					RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_aqueduct_snap", building2.transform.position);
					startBuilding = building2;
					currentPhase = AqueductPlacementPhase.PlacingWaypoints;
				}
				return;
			}
			DynamicWater.WaterRaycastHit waterRaycastHit = DynamicWater.inst.RaycastWater(ray);
			bool flag = waterRaycastHit.hit && waterRaycastHit.waterAmount > 0f;
			bool num = damFace != null && (!flag || damFace.distance < waterRaycastHit.distance);
			RiverTap riverTap = null;
			if (num)
			{
				if (damFace.hasWaterBehind)
				{
					riverTap = riverTapPlacer.CreateDamMountedTap(damFace);
				}
			}
			else if (flag)
			{
				riverTap = riverTapPlacer.CreateRiverTap(waterRaycastHit.point);
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_tap", waterRaycastHit.point);
			}
			if (!(riverTap == null))
			{
				AqueductBuilding component = riverTap.GetComponent<AqueductBuilding>();
				if (!(component == null))
				{
					RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_aqueduct_snap", component.transform.position);
					startBuilding = component;
					currentPhase = AqueductPlacementPhase.PlacingWaypoints;
				}
			}
		}
		else if (IsReadyToBuild)
		{
			BuildAqueduct();
		}
		else
		{
			if (IsSnappedToDestination)
			{
				return;
			}
			Ray ray2 = PointingSystem.GetRay();
			if (!Physics.Raycast(ray2, out var hitInfo3, 100f, LayerMask.GetMask("Terrain")) || hitInfo3.point.y < Water.inst.transform.position.y)
			{
				return;
			}
			Vector3 vector = ray2.GetPoint(hitInfo3.distance) + Vector3.up * 1f;
			Vector3 vector2 = ((waypoints.Count > 0) ? waypoints[waypoints.Count - 1] : startBuilding.GetPortPosition(vector));
			if (waypoints.Count != 0 || AqueductConnectionValidator.IsDamTapApproachValid(startBuilding, vector2, vector))
			{
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_aqueduct_snap", vector);
				if ((vector - vector2).sqrMagnitude >= 0.25f)
				{
					waypoints.Add(vector);
				}
			}
		}
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		if (startBuilding != null && IsReadyToBuild)
		{
			BuildAqueduct();
		}
	}

	public override void Shutdown()
	{
		InWorldExclamation.hideForCursorMode = false;
		base.Shutdown();
		if (placingAqueductLine != null)
		{
			UnityEngine.Object.Destroy(placingAqueductLine.gameObject);
			placingAqueductLine = null;
		}
		WorldMask.inst.Deactivate();
		World.inst.treeSystem.enabled = true;
		if (startBuilding is RiverTap)
		{
			UnityEngine.Object.Destroy(startBuilding.gameObject);
		}
		CleanupVirtualRiverTap();
		CleanupPreviewRiverTap();
		infoLine.gameObject.SetActive(value: false);
		startBuilding = null;
		waypointsWereReversed = false;
		inlineManager.ClearInlineSelection(ref startInlineSelection);
		inlineManager.ClearInlineSelection(ref destinationInlineSelection);
		currentPhase = AqueductPlacementPhase.Idle;
	}

	public void BuildAqueduct()
	{
		if (GetBuildError() != 0)
		{
			return;
		}
		using (AqueductJunction.SuppressCollapseScope())
		{
			if (startInlineSelection != null && destinationInlineSelection != null && startInlineSelection.line != null && startInlineSelection.line == destinationInlineSelection.line)
			{
				if (startInlineSelection.normalizedT <= destinationInlineSelection.normalizedT)
				{
					InlineSplitResult? inlineSplitResult = inlineManager.FinalizeInlineSelection(ref startInlineSelection);
					if (inlineSplitResult.HasValue)
					{
						inlineManager.AdjustSelectionForSplit(destinationInlineSelection, inlineSplitResult.Value);
					}
					inlineManager.FinalizeInlineSelection(ref destinationInlineSelection);
				}
				else
				{
					InlineSplitResult? inlineSplitResult2 = inlineManager.FinalizeInlineSelection(ref destinationInlineSelection);
					if (inlineSplitResult2.HasValue)
					{
						inlineManager.AdjustSelectionForSplit(startInlineSelection, inlineSplitResult2.Value);
					}
					inlineManager.FinalizeInlineSelection(ref startInlineSelection);
				}
			}
			else
			{
				InlineSplitResult? inlineSplitResult3 = inlineManager.FinalizeInlineSelection(ref startInlineSelection);
				if (inlineSplitResult3.HasValue && destinationInlineSelection != null)
				{
					inlineManager.AdjustSelectionForSplit(destinationInlineSelection, inlineSplitResult3.Value);
				}
				inlineManager.FinalizeInlineSelection(ref destinationInlineSelection);
			}
		}
		Vector3[] array = waypoints.ToArray();
		if (waypointsWereReversed)
		{
			Array.Reverse(array);
		}
		placingAqueductLine.SetStartEnd(sourceBuilding, array, destinationBuilding);
		placingAqueductLine.FullBuild();
		placingAqueductLine.DisplayOnly(b: false);
		placingAqueductLine.fullyConstructed = false;
		placingAqueductLine.Place();
		placingAqueductLine.DoBuildPuff();
		placingAqueductLine.FullBuild();
		sourceBuilding.ConnectLine(placingAqueductLine);
		destinationBuilding.ConnectLine(placingAqueductLine);
		sourceBuilding.UpdateWaterFlow();
		destinationBuilding.UpdateWaterFlow();
		placingAqueductLine = null;
		startBuilding = null;
		destinationVirtualRiverTap = null;
		waypointsWereReversed = false;
		infoLine.gameObject.SetActive(value: false);
		currentPhase = AqueductPlacementPhase.Idle;
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_large", (sourceBuilding.transform.position + destinationBuilding.transform.position) * 0.5f);
		MusicSystem.inst.StartAqueductMusic();
		if (sourceBuilding is AqueductJunction aqueductJunction)
		{
			aqueductJunction.TryCollapseLines();
		}
		if (destinationBuilding is AqueductJunction aqueductJunction2)
		{
			aqueductJunction2.TryCollapseLines();
		}
		Init();
	}

	public void Masking(CommandBuffer buffer, Material maskingMaterial, RenderTexture rTexture)
	{
		buffer.Clear();
		buffer.SetRenderTarget(rTexture);
		buffer.ClearRenderTarget(clearDepth: true, clearColor: true, Color.green);
		int focusedLandMassIdxLastValid = Player.inst.FocusedLandMassIdxLastValid;
		normal.Clear();
		highlight.Clear();
		WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.waterTowerHash, focusedLandMassIdxLastValid);
		WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.castellumaquaeHash, focusedLandMassIdxLastValid);
		WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.waterOutletHash, focusedLandMassIdxLastValid);
		for (int i = 0; i < normal.Count; i++)
		{
			if (normal.data[i].gameObject.activeInHierarchy && normal.data[i] != null)
			{
				buffer.DrawRenderer(normal.data[i], maskingMaterial, 0, 1);
			}
		}
		for (int j = 0; j < AqueductLine.allLines.Count; j++)
		{
			AqueductLine.allLines[j].DrawHighlight(buffer, maskingMaterial, 1);
		}
		for (int k = 0; k < highlight.Count; k++)
		{
			if (highlight.data[k].gameObject.activeInHierarchy && highlight.data[k] != null)
			{
				buffer.DrawRenderer(highlight.data[k], maskingMaterial, 0, 2);
			}
		}
		if (placingAqueductLine != null)
		{
			placingAqueductLine.DrawHighlight(buffer, maskingMaterial, 1);
		}
	}

	public override void Tick(float dt)
	{
		HeightMarker.ShowLandmassWaterBuildings(Player.inst.FocusedLandMassIdxLastValid);
		if (GameUI.inst.PointerOverUI())
		{
			if (currentPhase == AqueductPlacementPhase.Idle)
			{
				CleanupPreviewRiverTap();
				if (placingAqueductLine != null)
				{
					placingAqueductLine.gameObject.SetActive(value: false);
				}
			}
			return;
		}
		validFirstClick = false;
		hoverErrorCode = 0;
		switch (currentPhase)
		{
		case AqueductPlacementPhase.Idle:
			TickIdlePhase();
			break;
		case AqueductPlacementPhase.PlacingWaypoints:
		case AqueductPlacementPhase.SnappedToDestination:
		case AqueductPlacementPhase.ReadyToBuild:
			TickActivePlacement();
			break;
		}
	}

	public override void LateTick()
	{
		if (WorldMask.inst.activated)
		{
			WorldMask.inst.ForceUpdate();
		}
	}

	private void TickIdlePhase()
	{
		infoLine.gameObject.SetActive(value: false);
		placingAqueductLine.gameObject.SetActive(value: false);
		Ray ray = PointingSystem.GetRay();
		DynamicWater.WaterRaycastHit waterRaycastHit = DynamicWater.inst.RaycastWater(ray);
		Vector3 vector = waterRaycastHit.point + Vector3.up * 0.8f;
		Vector3 vector2 = Cam.inst.cam.transform.right * 0.49f;
		targetResolver.TryGetAqueductBuildingUnderCursor(ray, out var building, out var _);
		bool flag = TryGetLineUnderCursor(ray, out var line, out var hitInfo2, out var damFace);
		bool flag2 = false;
		if (building != null)
		{
			if (!(validFirstClick = building.HasAvailablePorts()))
			{
				hoverErrorCode = 8;
				placingAqueductLine.SetMeshInvalid();
			}
			placingAqueductLine.gameObject.SetActive(value: true);
			HeightMarker.Show(building);
			CleanupPreviewRiverTap();
		}
		else if (flag && line != null)
		{
			hoverErrorCode = 0;
			validFirstClick = true;
			placingAqueductLine.gameObject.SetActive(value: true);
			Vector3 position = previewRenderer.UpdateInlineHoverPreview(placingAqueductLine, line, hitInfo2, hitInfo2.point, 0.35f);
			flag2 = true;
			HeightMarker.Show(position);
			CleanupPreviewRiverTap();
		}
		else
		{
			bool flag3 = waterRaycastHit.hit && waterRaycastHit.waterAmount > 0f;
			bool flag4 = damFace != null && (!flag3 || damFace.distance < waterRaycastHit.distance);
			if (previewRiverTap != null && previewRiverTap.damMounted != flag4)
			{
				CleanupPreviewRiverTap();
			}
			if (flag4)
			{
				validFirstClick = damFace.hasWaterBehind;
				if (previewRiverTap == null)
				{
					previewRiverTap = riverTapPlacer.CreateDamMountedTap(damFace, removeColliders: true);
				}
				else
				{
					riverTapPlacer.UpdateDamMount(previewRiverTap, damFace);
				}
				hoverErrorCode = (int)damFace.error;
				HeightMarker.Show(previewRiverTap);
				if (damFace.hasWaterBehind)
				{
					placingAqueductLine.SetMeshValid();
				}
				else
				{
					placingAqueductLine.SetMeshInvalid();
				}
				Vector3 tapPos = damFace.tapPos;
				Vector3 vector3 = damFace.tapPos - damFace.dirIntoWall * 1f;
				if (placingAqueductLine.waypoints != null && placingAqueductLine.waypoints.Length == 2)
				{
					placingAqueductLine.waypoints[0] = tapPos;
					placingAqueductLine.waypoints[^1] = vector3;
				}
				else
				{
					placingAqueductLine.waypoints = new Vector3[2] { tapPos, vector3 };
				}
				placingAqueductLine.gameObject.SetActive(value: true);
				flag2 = true;
			}
			else if (flag3)
			{
				validFirstClick = true;
				if (previewRiverTap == null)
				{
					previewRiverTap = riverTapPlacer.CreateRiverTap(waterRaycastHit.point, removeColliders: true);
				}
				else
				{
					riverTapPlacer.UpdatePosition(previewRiverTap, waterRaycastHit.point);
				}
				HeightMarker.Show(previewRiverTap);
				previewRiverTap.transform.rotation = Quaternion.LookRotation(vector2.normalized, Vector3.up);
				placingAqueductLine.gameObject.SetActive(value: false);
			}
			else
			{
				placingAqueductLine.SetMeshInvalid();
				placingAqueductLine.gameObject.SetActive(value: true);
				CleanupPreviewRiverTap();
			}
		}
		if (!flag2)
		{
			Vector3 vector4 = vector;
			Vector3 vector5 = vector + vector2 * 2f;
			if (placingAqueductLine.waypoints != null && placingAqueductLine.waypoints.Length == 2)
			{
				placingAqueductLine.waypoints[0] = vector4;
				placingAqueductLine.waypoints[^1] = vector5;
			}
			else
			{
				placingAqueductLine.waypoints = new Vector3[2] { vector4, vector5 };
			}
		}
	}

	private void TickActivePlacement()
	{
		placingAqueductLine.gameObject.SetActive(value: true);
		placingAqueductLine.SetMeshValid();
		if (startBuilding.GetComponent<Building>() != null)
		{
			startBuilding.GetComponent<Building>().highlight.SetOutlineImmediate(1);
		}
		if (startInlineSelection != null)
		{
			HeightMarker.Show(startInlineSelection.worldPoint);
		}
		bool flag = false;
		Ray ray = PointingSystem.GetRay();
		if (targetResolver.TryGetAqueductBuildingUnderCursor(ray, out var building, out var _) && building != startBuilding && !(building is RiverTap))
		{
			flag = TrySetupAqueductConnection(startBuilding, building);
			if (flag)
			{
				inlineManager.ClearInlineSelection(ref destinationInlineSelection);
			}
		}
		RiverTapPlacer.DamFaceHit damFace = null;
		if (!flag && TryGetLineUnderCursor(ray, out var line, out var hitInfo2, out damFace) && inlineManager.TryResolveLineTarget(line, hitInfo2, ref destinationInlineSelection, out var building2, out var _, GetStubContinuationRay()) && building2 != null && building2 != startBuilding)
		{
			if (startInlineSelection != null && destinationInlineSelection != null && (startInlineSelection.worldPoint - destinationInlineSelection.worldPoint).sqrMagnitude < 0.0001f)
			{
				inlineManager.ClearInlineSelection(ref destinationInlineSelection);
			}
			else
			{
				flag = TrySetupAqueductConnection(startBuilding, building2);
				if (flag && destinationInlineSelection == null)
				{
					HeightMarker.Show(building2);
				}
			}
		}
		if (!flag)
		{
			inlineManager.ClearInlineSelection(ref destinationInlineSelection);
		}
		if (!flag && ShouldAllowDestinationRiverTap())
		{
			DynamicWater.WaterRaycastHit waterRaycastHit = DynamicWater.inst.RaycastWater(ray);
			bool flag2 = waterRaycastHit.hit && waterRaycastHit.waterAmount > 0f;
			bool flag3 = damFace != null && (!flag2 || damFace.distance < waterRaycastHit.distance);
			if (destinationVirtualRiverTap is RiverTap riverTap && riverTap.damMounted != flag3)
			{
				CleanupVirtualRiverTap();
			}
			if (flag3)
			{
				if (destinationVirtualRiverTap == null)
				{
					destinationVirtualRiverTap = riverTapPlacer.CreateDamMountedTap(damFace);
				}
				else
				{
					riverTapPlacer.UpdateDamMount((RiverTap)destinationVirtualRiverTap, damFace);
				}
				HeightMarker.Show(destinationVirtualRiverTap);
				flag = TrySetupAqueductConnection(startBuilding, destinationVirtualRiverTap);
			}
			else if (flag2)
			{
				if (destinationVirtualRiverTap == null)
				{
					destinationVirtualRiverTap = riverTapPlacer.CreateRiverTap(waterRaycastHit.point);
				}
				else
				{
					riverTapPlacer.UpdatePosition((RiverTap)destinationVirtualRiverTap, waterRaycastHit.point);
				}
				HeightMarker.Show(destinationVirtualRiverTap);
				flag = TrySetupAqueductConnection(startBuilding, destinationVirtualRiverTap);
			}
			else
			{
				CleanupVirtualRiverTap();
			}
		}
		else if (!ShouldAllowDestinationRiverTap() | flag)
		{
			CleanupVirtualRiverTap();
		}
		if (!flag)
		{
			if (IsSnappedToDestination)
			{
				currentPhase = AqueductPlacementPhase.PlacingWaypoints;
			}
			Ray ray2 = PointingSystem.GetRay();
			if (Physics.Raycast(ray2, out var hitInfo3, 100f, LayerMask.GetMask("Terrain")))
			{
				Vector3 vector = ray2.GetPoint(hitInfo3.distance) + Vector3.up * 0.8f;
				Vector3 pos = vector;
				if (waypoints.Count > 0)
				{
					pos = waypoints[0];
				}
				Vector3 portPosition = startBuilding.GetPortPosition(pos);
				placingAqueductLine.waypoints = waypoints.Append(vector).Prepend(portPosition).ToArray();
				AqueductLine.GradeWaypoints(ref placingAqueductLine.waypoints);
				bool flag4 = connectionValidator.CheckBuildingIntersections(placingAqueductLine.waypoints);
				bool flag5 = hitInfo3.point.y < Water.inst.transform.position.y;
				bool flag6 = connectionValidator.CheckCoincidentWithExistingLines(placingAqueductLine.waypoints, placingAqueductLine);
				if (!AqueductConnectionValidator.IsDamTapApproachValid(startBuilding, placingAqueductLine.waypoints[0], placingAqueductLine.waypoints[1]))
				{
					placingAqueductLine.SetMeshInvalid();
					hoverErrorCode = 13;
				}
				else if (flag5 | flag4)
				{
					placingAqueductLine.SetMeshInvalid();
					if (flag5)
					{
						hoverErrorCode = 9;
					}
					if (flag4)
					{
						hoverErrorCode = 7;
					}
				}
				else if (flag6)
				{
					hoverErrorCode = 11;
				}
				infoLine.Set(portPosition, waypoints, vector, startBuilding, null, placing: true);
				infoLine.UpdateStatus();
				infoLine.gameObject.SetActive(value: true);
			}
			else if (destinationVirtualRiverTap == null)
			{
				infoLine.gameObject.SetActive(value: false);
			}
		}
		UpdatePlacementHighlights(flag);
		if (startBuilding is RiverTap { damMounted: false } riverTap2)
		{
			riverTap2.transform.rotation = Quaternion.LookRotation((placingAqueductLine.waypoints[0] - placingAqueductLine.waypoints[1]).xz(), Vector3.up);
		}
		CleanupPreviewRiverTap();
		if (destinationVirtualRiverTap != null && !(destinationVirtualRiverTap is RiverTap { damMounted: not false }))
		{
			Vector3 vector2 = placingAqueductLine.waypoints[^1];
			Vector3 vector3 = placingAqueductLine.waypoints[^2];
			destinationVirtualRiverTap.transform.rotation = Quaternion.LookRotation((vector3 - vector2).xz(), Vector3.up);
		}
	}

	private void UpdatePlacementHighlights(bool snappingToBuilding)
	{
		if (hoverErrorCode != 13 && !Creative.inst.IsCreativeOptionOn(0) && !Player.inst.FocusedResources.HasCost(placingAqueductLine.GetBuildCost()))
		{
			hoverErrorCode = 5;
			placingAqueductLine.SetMeshInvalid();
			if ((destinationBuilding != null) & snappingToBuilding)
			{
				Building component = destinationBuilding.GetComponent<Building>();
				if (component != null)
				{
					component.highlight.SetOutlineImmediate(2);
				}
			}
		}
		else if (snappingToBuilding && GetBuildError() != 0)
		{
			if (GetBuildError() == 11)
			{
				if (destinationBuilding.GetComponent<Building>() != null)
				{
					destinationBuilding.GetComponent<Building>().highlight.SetOutlineImmediate(1);
				}
				return;
			}
			if (destinationBuilding.GetComponent<Building>() != null)
			{
				destinationBuilding.GetComponent<Building>().highlight.SetOutlineImmediate(2);
			}
			placingAqueductLine.SetMeshInvalid();
		}
		else if (snappingToBuilding && destinationBuilding.GetComponent<Building>() != null)
		{
			destinationBuilding.GetComponent<Building>().highlight.SetOutlineImmediate(1);
		}
	}

	private Ray? GetStubContinuationRay()
	{
		if (waypoints.Count > 0 || startInlineSelection == null || !startInlineSelection.isEndpointConnection)
		{
			return null;
		}
		AqueductLine line = startInlineSelection.line;
		if (line == null || line.waypoints == null || line.waypoints.Length < 2)
		{
			return null;
		}
		Vector3 vector = (startInlineSelection.endpointIsStart ? (line.waypoints[0] - line.waypoints[1]) : (line.waypoints[^1] - line.waypoints[^2]));
		if (vector.sqrMagnitude < 1E-06f)
		{
			return null;
		}
		return new Ray(startInlineSelection.worldPoint, vector.normalized);
	}

	private bool ShouldAllowDestinationRiverTap()
	{
		if (startBuilding != null && !(startBuilding is RiverTap) && !Input.GetKey(KeyCode.LeftShift))
		{
			return !Input.GetKey(KeyCode.RightShift);
		}
		return false;
	}

	private bool TrySetupAqueductConnection(AqueductBuilding buildingA, AqueductBuilding buildingB)
	{
		AqueductBuilding aqueductBuilding = buildingA;
		AqueductBuilding aqueductBuilding2 = buildingB;
		Vector3 pos = aqueductBuilding2.Center();
		if (waypoints.Count > 0)
		{
			pos = waypoints[0];
		}
		Vector3 pos2 = aqueductBuilding.Center();
		if (waypoints.Count > 0)
		{
			List<Vector3> list = waypoints;
			pos2 = list[list.Count - 1];
		}
		bool flag = aqueductBuilding.HasAvailablePorts();
		bool flag2 = aqueductBuilding2.HasAvailablePorts();
		Vector3 vector = aqueductBuilding.GetPortPosition(pos);
		Vector3 vector2 = aqueductBuilding2.GetPortPosition(pos2);
		List<Vector3> list2 = new List<Vector3>(waypoints);
		waypointsWereReversed = false;
		infoLine.Set(vector, list2, vector2, aqueductBuilding, aqueductBuilding2, placing: true);
		infoLine.UpdateStatus();
		infoLine.gameObject.SetActive(value: true);
		if (vector.y < vector2.y)
		{
			AqueductBuilding aqueductBuilding3 = aqueductBuilding2;
			AqueductBuilding aqueductBuilding4 = aqueductBuilding;
			aqueductBuilding = aqueductBuilding3;
			aqueductBuilding2 = aqueductBuilding4;
			bool flag3 = flag2;
			bool flag4 = flag;
			flag = flag3;
			flag2 = flag4;
			Vector3 vector3 = vector2;
			Vector3 vector4 = vector;
			vector = vector3;
			vector2 = vector4;
			list2.Reverse();
			waypointsWereReversed = true;
		}
		startPos = vector;
		endPos = vector2;
		sourceBuilding = aqueductBuilding;
		destinationBuilding = aqueductBuilding2;
		sourcePortAvailable = flag;
		destinationPortAvailable = flag2;
		Vector3[] array = new Vector3[list2.Count + 2];
		array[0] = startPos;
		for (int i = 0; i < list2.Count; i++)
		{
			array[i + 1] = list2[i];
		}
		array[^1] = endPos;
		placingAqueductLine.waypoints = array;
		AqueductLine.GradeWaypoints(ref placingAqueductLine.waypoints);
		if (GetBuildError() == 0)
		{
			currentPhase = AqueductPlacementPhase.ReadyToBuild;
		}
		else
		{
			currentPhase = AqueductPlacementPhase.SnappedToDestination;
		}
		return true;
	}

	public int GetBuildError()
	{
		if (inlineManager.WouldCreateShortLine(startInlineSelection, destinationInlineSelection) || inlineManager.WouldCreateShortLine(destinationInlineSelection, startInlineSelection))
		{
			return 10;
		}
		return (int)connectionValidator.GetBuildError(sourceBuilding, destinationBuilding, sourcePortAvailable, destinationPortAvailable, placingAqueductLine?.waypoints, placingAqueductLine);
	}

	public string GetErrorString()
	{
		return GetErrorString(GetBuildError());
	}

	private string GetErrorString(int errorCode)
	{
		return ((AqueductPlacementError)errorCode).GetErrorString();
	}

	public string GetBuildStatus(out int colorIndex)
	{
		if (infoLine.gameObject.activeSelf && IsSnappedToDestination)
		{
			int buildError = GetBuildError();
			if (buildError != 0)
			{
				colorIndex = 0;
				return GetErrorString(buildError);
			}
			var (flag, flag2) = connectionValidator.ValidateAngles(placingAqueductLine.waypoints);
			if (flag | flag2)
			{
				colorIndex = 1;
				return string.Empty;
			}
		}
		else
		{
			if (hoverErrorCode != 0)
			{
				colorIndex = 0;
				return GetErrorString(hoverErrorCode);
			}
			if (!validFirstClick)
			{
				colorIndex = 0;
				if (startBuilding == null)
				{
					return LocalizationManager.GetTranslation("AqueductConnectionStart");
				}
			}
		}
		colorIndex = 0;
		return string.Empty;
	}
}
