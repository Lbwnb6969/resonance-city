using System.Collections.Generic;
using Assets;
using Colorful;
using UnityEngine;
using UnityEngine.Rendering;

public class LogisticCursor : CursorMode
{
	protected static int bTooltipCount = 0;

	protected static List<ResourceTooltipUI> bTooltipPool = new List<ResourceTooltipUI>(32);

	protected ArrayExt<Renderer> highlight = new ArrayExt<Renderer>(1000);

	protected ArrayExt<Renderer> normal = new ArrayExt<Renderer>(1000);

	protected bool doForcedUpdate;

	protected ResourceTooltipUI TrySetupTooltipForBuilding(Building b)
	{
		if (b == null)
		{
			return null;
		}
		for (int i = 0; i < bTooltipCount; i++)
		{
			if (bTooltipPool[i].id == b.guid)
			{
				return null;
			}
		}
		if (bTooltipCount == bTooltipPool.Count)
		{
			bTooltipPool.Add(Object.Instantiate(World.inst.resourceTooltipPrefab, World.inst.resourceTooltipContainer.transform).GetComponent<ResourceTooltipUI>());
		}
		ResourceTooltipUI resourceTooltipUI = bTooltipPool[bTooltipCount++];
		resourceTooltipUI.text.SetText(b.customName);
		resourceTooltipUI.targetPosition = b.Center();
		resourceTooltipUI.targetOffset = Vector3.up;
		resourceTooltipUI.id = b.guid;
		Util.SetActive(resourceTooltipUI.gameObject, active: true);
		return resourceTooltipUI;
	}

	protected void HideRemaningTooltips()
	{
		for (int i = bTooltipCount; i < bTooltipPool.Count; i++)
		{
			bTooltipPool[i].text.SetText(string.Empty);
			Util.SetActive(bTooltipPool[i].gameObject, active: false);
		}
	}

	public override void Shutdown()
	{
		base.Shutdown();
		bTooltipCount = 0;
		HideRemaningTooltips();
	}

	public override void LateTick()
	{
		base.LateTick();
		HideRemaningTooltips();
	}

	public override bool DoClearSelectedCellOnInit()
	{
		return false;
	}

	public override bool ShowDragSelectBounds()
	{
		return false;
	}

	public override bool ShowCellHighlighter()
	{
		return false;
	}

	public override bool HideThoughtBubble()
	{
		return true;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		LogisticArrow.DeferHideArrows();
		bTooltipCount = 0;
		if (doForcedUpdate)
		{
			doForcedUpdate = false;
			WorldMask.inst.ForceUpdate();
		}
	}

	public virtual void PopulateMasking()
	{
	}

	public void Masking(CommandBuffer buffer, Material maskingMaterial, RenderTexture rTexture)
	{
		buffer.Clear();
		buffer.SetRenderTarget(rTexture);
		buffer.ClearRenderTarget(clearDepth: true, clearColor: true, Color.clear);
		normal.Clear();
		highlight.Clear();
		PopulateMasking();
		for (int i = 0; i < normal.Count; i++)
		{
			if (normal.data[i].gameObject.activeInHierarchy && normal.data[i] != null)
			{
				buffer.DrawRenderer(normal.data[i], maskingMaterial, 0, 1);
			}
		}
		for (int j = 0; j < highlight.Count; j++)
		{
			if (highlight.data[j].gameObject.activeInHierarchy && highlight.data[j] != null)
			{
				buffer.DrawRenderer(highlight.data[j], maskingMaterial, 0, 2);
			}
		}
	}

	protected void AddMarkerForVehicle(LogisticsVehicle vehicle)
	{
		Vector3 position = vehicle.transform.position;
		position.y += (vehicle.isShip ? 1.5f : 0.75f);
		MarkerDrawer.inst.AddPoint(position);
	}

	protected void SetGameUIVisibility(bool v)
	{
		BuildUI.inst.gameObject.SetActive(v);
		GameUI.inst.islandInfoUI.gameObject.SetActive(v);
		CursorModeUI.inst.gameObject.SetActive(v);
		ProsperityUI.inst.gameObject.SetActive(v);
		NotificationUI.inst.gameObject.SetActive(v);
		SeasonViewer.inst.gameObject.SetActive(v);
		SpeedControlUI.inst.gameObject.SetActive(v);
		MiniMapUI.inst.SetVisibility(v);
		Cam.inst.GetComponent<FastVignette>().enabled = !v;
	}

	protected void UpdateArrowColorsForVehicle(LogisticsVehicle currVehicle)
	{
		for (int i = 0; i < LogisticArrow.active.Count; i++)
		{
			LogisticArrow logisticArrow = LogisticArrow.active.data[i];
			int idx;
			if (currVehicle.TryGetCurrentRoute(out var logisticRoute) && logisticRoute.sourceBuilding == logisticArrow.sourceBuilding && logisticRoute.targetBuilding == logisticArrow.targetBuilding)
			{
				logisticArrow.SetColor(LogisticArrow.activeRouteColor);
			}
			else if (currVehicle.HasRouteFor(logisticArrow.targetBuilding, logisticArrow.sourceBuilding, out idx))
			{
				logisticArrow.SetColor(LogisticArrow.assignedRouteColor);
			}
			else if (!LogisticsManager.ValidSourceBuildingForVehicle(currVehicle, logisticArrow.targetBuilding.LandMass(), logisticArrow.sourceBuilding))
			{
				logisticArrow.SetColor(LogisticArrow.disabledRouteColor);
			}
			else
			{
				logisticArrow.SetColor(LogisticArrow.unassignedRouteColor);
			}
		}
	}
}
