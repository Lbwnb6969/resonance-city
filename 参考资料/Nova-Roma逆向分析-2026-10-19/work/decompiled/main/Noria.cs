using Assets;
using UnityEngine;

public class Noria : Tickable, IOutputInfo, IWaterSystemUser
{
	public Transform wheel;

	public GameObject water;

	public float affectedRadius;

	public Transform basePos;

	public Transform[] waterPos;

	private bool irrigating;

	private Building _b;

	private bool hasWater;

	private Building b => _b ?? (_b = GetComponent<Building>());

	public bool IsVisited { get; set; }

	public bool HasWater
	{
		get
		{
			return hasWater;
		}
		set
		{
			hasWater = value;
			UpdateWater();
		}
	}

	public bool IsConnected
	{
		get
		{
			return true;
		}
		set
		{
		}
	}

	public int WaterPressure
	{
		get
		{
			if (!ShouldIrrigate())
			{
				return 0;
			}
			return 24;
		}
	}

	public bool IsWheelInWater()
	{
		for (int i = 0; i < waterPos.Length; i++)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(waterPos[i].position);
			if (cellDataClamped.Type != TerrainType.Water || (cellDataClamped.BottomSubStructure != null && cellDataClamped.BottomSubStructure.uniqueNameHash == World.pierHash))
			{
				return false;
			}
		}
		return true;
	}

	public bool IsWheelInFreshWater()
	{
		for (int i = 0; i < waterPos.Length; i++)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(waterPos[i].position);
			if (!cellDataClamped.saltWater || ((bool)cellDataClamped.BottomSubStructure && cellDataClamped.BottomSubStructure.uniqueNameHash == World.moatHash))
			{
				return true;
			}
		}
		return false;
	}

	public bool IsBaseOnLand()
	{
		return World.inst.GetCellDataClamped(basePos.position).Type == TerrainType.None;
	}

	public void Start()
	{
		wheel.gameObject.SetActive(value: true);
		b.PlacementValidaton = PlacementValidation;
	}

	public void PlacementValidation(ref PlacementValidationResult result)
	{
		if (!IsBaseOnLand())
		{
			result = PlacementValidationResult.NoriaBaseOnLand;
		}
		else
		{
			result = PlacementValidationResult.Valid;
		}
		if (!IsWheelInWater())
		{
			result = PlacementValidationResult.NoriaWheelOnWater;
		}
		bool touchingExisting = false;
		World.inst.ForEachTileTouchingRadius(b.Center(), 2f, (int subx, int subz, Cell c) =>
		{
			if ((bool)c.BottomStructure && c.BottomStructure.uniqueNameHash == World.noriaHash)
			{
				touchingExisting = true;
			}
		});
		if (touchingExisting)
		{
			result = PlacementValidationResult.NoriaTooCloseToExisting;
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b != null)
		{
			if (b.IsOpen() && b.GetWorkerPercent() > 0.99f)
			{
				wheel.Rotate(dt * -30f, 0f, 0f);
			}
			bool flag = ShouldIrrigate();
			if (irrigating != flag)
			{
				irrigating = flag;
				Player.inst.irrigation.UpdateIrrigation();
				UpdateWater();
			}
		}
	}

	public void UpdateWater()
	{
		water.gameObject.SetActive(hasWater || irrigating);
	}

	public bool ShouldIrrigate()
	{
		if (b.IsOpen() && b.GetWorkerPercent() > 0.99f)
		{
			return b.IsBuilt();
		}
		return false;
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

	private void OnBuilt()
	{
		Player.inst.irrigation.UpdateIrrigation();
		RefreshSurroundingRotation();
		wheel.gameObject.SetActive(value: true);
	}

	private void OnBuildingPlacement(bool undo)
	{
		wheel.GetComponent<MeshRenderer>().material = World.GetUniMaterialFor(GetComponent<Building>().LandMass());
		water.GetComponent<MeshRenderer>().material = World.GetUniMaterialFor(GetComponent<Building>().LandMass());
		RefreshSurroundingRotation();
		if (!b.IsBuilt())
		{
			wheel.gameObject.SetActive(value: false);
		}
	}

	public string GetExplanation(OutputTileUI outputTile)
	{
		return "";
	}

	public string GetError()
	{
		if (b.GetWorkerPercent() < 0.99f)
		{
			return "ScriptLocalization.NoriaStaff";
		}
		return null;
	}
}
