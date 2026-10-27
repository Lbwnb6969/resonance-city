using Assets.Code.Interface;
using UnityEngine;

public class Reservoir : Tickable, IOutputInfo, IOverlayUser, IWorkerUIDisplay, IWaterSystemUser
{
	public GameObject water;

	public float affectedRadius;

	private Building _b;

	private bool irrigating;

	private bool shouldIrrigate;

	public Color overlayColor = new Color(0.3f, 0.4f, 1f, 0.3f);

	private Building b => _b ?? (_b = GetComponent<Building>());

	public bool HasWater
	{
		get
		{
			return shouldIrrigate;
		}
		set
		{
			shouldIrrigate = value;
			water.SetActive(value);
		}
	}

	public bool IsConnected { get; set; }

	public bool IsVisited { get; set; }

	public bool OverlayWhenPlacing => true;

	public bool OverlayWhenSelected => true;

	private void OnInit()
	{
		water.SetActive(value: false);
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b != null)
		{
			bool doIrrigate = b.IsOpen() && b.GetWorkerPercent() > 0.99f && b.IsBuilt() && HasWater && IsConnected;
			UpdateIrrigation(doIrrigate);
		}
	}

	private void RefreshSurroundingRotation()
	{
		Cell cell = GetComponent<Building>().GetCell();
		if (cell == null)
		{
			return;
		}
		World.inst.ToGridCoord(cell.Center2D, out var x, out var z);
		World.inst.ForEachTile(x - 1, z - 1, x + 1, z + 1, (int tx, int tz, Cell c) =>
		{
			Building topMostStructure = c.TopMostStructure;
			if (topMostStructure != null && topMostStructure.UniqueName == "aqueduct")
			{
				topMostStructure.GetComponent<AdjacentMesh>().UpdateRotation();
			}
		});
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		RefreshSurroundingRotation();
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		RefreshSurroundingRotation();
	}

	private void OnBuildingPlacement(bool undo)
	{
		RefreshSurroundingRotation();
	}

	private void OnBuilt()
	{
		Player.inst.irrigation.UpdateIrrigation();
		RefreshSurroundingRotation();
	}

	private void OnShutdown()
	{
		if (irrigating)
		{
			UpdateIrrigation(doIrrigate: false);
		}
	}

	private void UpdateIrrigation(bool doIrrigate)
	{
		if (doIrrigate != irrigating)
		{
			Player.inst.irrigation.wasReservoirIrrigationUpdated = true;
			irrigating = doIrrigate;
		}
	}

	public void DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.ClearOverlay(updateToo: false);
		ForCellsInRange(origin, (int x, int z, Cell cell) =>
		{
			TerrainGen.inst.SetOverlayTileColor(x, z, overlayColor);
		});
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	public void ForCellsInRange(Vector3 origin, Building.EvaluateCell handler)
	{
		World.inst.ForEachTileTouchingRadius(origin, affectedRadius, (int x, int z, Cell cell) =>
		{
			if (cell != null)
			{
				handler(x, z, cell);
			}
		});
	}

	public string GetError()
	{
		if (!IsConnected)
		{
			return "ScriptLocalization.WaterAccessNotConnected";
		}
		if (IsConnected && !HasWater)
		{
			return "ScriptLocalization.WaterAccessConnectedNotClose";
		}
		return "";
	}

	public bool ShowCustomButton()
	{
		return false;
	}

	public bool CustomButtonInteractable()
	{
		return false;
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public string CustomButtonTitle()
	{
		return null;
	}

	public string CustomButtonText()
	{
		return null;
	}

	public Sprite CustomButtonImage()
	{
		return null;
	}

	public void CustomButtonClicked()
	{
	}
}
