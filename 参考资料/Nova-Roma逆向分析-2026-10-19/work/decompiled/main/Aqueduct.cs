using System;
using UnityEngine;

public class Aqueduct : MonoBehaviour, IOutputInfo, IWaterSystemUser
{
	public GameObject waterCube;

	public float affectedRadius;

	public Transform WaterStraight;

	public Transform WaterElbow;

	public Transform WaterIntersection3;

	public Transform WaterIntersection4;

	public MeshFilter waterMeshFilter;

	private Transform curWaterTransform;

	private bool shouldIrrigate;

	private Building _b;

	private AdjacentMesh adjMesh;

	public bool HasWater
	{
		get
		{
			return shouldIrrigate;
		}
		set
		{
			shouldIrrigate = value;
			if (waterCube.activeSelf != shouldIrrigate)
			{
				waterCube.SetActive(shouldIrrigate);
			}
		}
	}

	public bool IsConnected { get; set; }

	public bool IsVisited { get; set; }

	private Building b => _b ?? (_b = GetComponent<Building>());

	private void OnInit()
	{
		TrySetWaterMesh(WaterStraight);
		curWaterTransform = WaterStraight;
		b.PlacementValidaton = PlacementValidation;
		if (adjMesh == null)
		{
			adjMesh = GetComponent<AdjacentMesh>();
		}
		adjMesh.shouldConnect = ShouldConnect;
		AdjacentMesh adjacentMesh = adjMesh;
		adjacentMesh.onRotationUpdate = (AdjacentMesh.OnRotationUpdate)Delegate.Combine(adjacentMesh.onRotationUpdate, new AdjacentMesh.OnRotationUpdate(OnRotationUpdate));
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		if (cellDataClamped.TopMostStructure != null && cellDataClamped.TopMostStructure.allowOverAndUnderAqueducts && !cellDataClamped.StructureCompareUniqueNameAll(World.aqueductHash))
		{
			validationResult = PlacementValidationResult.Valid;
		}
	}

	public void OnEnable()
	{
		RefreshSurroundingRotation();
	}

	public void OnDisable()
	{
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

	private void Start()
	{
		waterCube.SetActive(value: false);
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
			Building building = c.StructureFind(World.aqueductHash);
			if (building != null)
			{
				building.GetComponent<AdjacentMesh>().UpdateRotation();
			}
		});
	}

	private void TrySetWaterMesh(Transform prefab)
	{
		if (curWaterTransform != prefab)
		{
			curWaterTransform = prefab;
			waterMeshFilter.mesh = prefab.GetComponent<MeshFilter>().sharedMesh;
		}
	}

	private void OnRotationUpdate(AdjacentMesh.AdjacentType type)
	{
		switch (type)
		{
		case AdjacentMesh.AdjacentType.StraightSingle:
		case AdjacentMesh.AdjacentType.StraightDeadEnd:
		case AdjacentMesh.AdjacentType.StraightStraight:
			TrySetWaterMesh(WaterStraight);
			break;
		case AdjacentMesh.AdjacentType.StraightCorner:
			TrySetWaterMesh(WaterElbow);
			break;
		case AdjacentMesh.AdjacentType.StraightThreeWay:
			TrySetWaterMesh(WaterIntersection3);
			break;
		case AdjacentMesh.AdjacentType.StraightFourWay:
			TrySetWaterMesh(WaterIntersection4);
			break;
		}
	}

	public static bool ShouldConnect(Cell c)
	{
		if (c != null)
		{
			Building building = c.StructureFind<IWaterSystemUser>();
			if (building != null)
			{
				Noria component = building.GetComponent<Noria>();
				if (component != null)
				{
					for (int i = 0; i < component.waterPos.Length; i++)
					{
						if (World.inst.GetCellDataClamped(component.waterPos[i].position) == c)
						{
							return false;
						}
					}
				}
				return true;
			}
			if (GameUI.inst.CurrPlacementMode.TestAqueductConnection(c))
			{
				return true;
			}
		}
		return false;
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
}
