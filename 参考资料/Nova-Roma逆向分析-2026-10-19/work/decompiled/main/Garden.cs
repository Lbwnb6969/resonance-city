using System;
using UnityEngine;

public class Garden : MonoBehaviour, IWorkerUIDisplay, IOutputInfo
{
	public Building b;

	public AdjacentMesh adjMesh;

	public Mesh StraightStraight_flowers;

	public Mesh StraightCorner_flowers;

	public Mesh StraightThreeWay_flowers;

	public Mesh StraightFourWay_flowers;

	public Mesh Full_flowers;

	public MeshFilter flowers;

	private int adjacencyHappinessBonus;

	private int irrigationBonus;

	public int baseHappiness = 3;

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
		return "";
	}

	public string CustomButtonText()
	{
		return "";
	}

	public Sprite CustomButtonImage()
	{
		return null;
	}

	public void CustomButtonClicked()
	{
	}

	string IOutputInfo.GetError()
	{
		return null;
	}

	private void OnEnable()
	{
		GetComponent<RadiusBonus>().happinessFunc = GetHappiness;
	}

	private void OnInit()
	{
		if (adjMesh == null)
		{
			adjMesh = GetComponent<AdjacentMesh>();
		}
		adjMesh.shouldConnect = Road.ShouldConnect;
		AdjacentMesh adjacentMesh = adjMesh;
		adjacentMesh.onRotationUpdate = (AdjacentMesh.OnRotationUpdate)Delegate.Combine(adjacentMesh.onRotationUpdate, new AdjacentMesh.OnRotationUpdate(OnRotationUpdate));
		Player.inst.irrigation.OnReservoirIrrigationUpdated += Irrigation_OnIrrigationUpdated;
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.Wander));
			}
		}
	}

	private void OnBuilt()
	{
		b = GetComponent<Building>();
		RefreshBonuses();
	}

	private void OnRotationUpdate(AdjacentMesh.AdjacentType adjType)
	{
		World.inst.ToGridCoord(transform.position, out var x, out var z);
		adjacencyHappinessBonus = 0;
		if (IsGarden(x + 1, z))
		{
			adjacencyHappinessBonus++;
		}
		if (IsGarden(x - 1, z))
		{
			adjacencyHappinessBonus++;
		}
		if (IsGarden(x, z + 1))
		{
			adjacencyHappinessBonus++;
		}
		if (IsGarden(x, z - 1))
		{
			adjacencyHappinessBonus++;
		}
		flowers.gameObject.SetActive(irrigationBonus > 0);
		switch (adjType)
		{
		case AdjacentMesh.AdjacentType.StraightFourWay:
			flowers.mesh = StraightFourWay_flowers;
			break;
		case AdjacentMesh.AdjacentType.StraightCorner:
			flowers.mesh = StraightCorner_flowers;
			break;
		case AdjacentMesh.AdjacentType.StraightSingle:
			flowers.mesh = StraightStraight_flowers;
			break;
		case AdjacentMesh.AdjacentType.StraightThreeWay:
			flowers.mesh = StraightThreeWay_flowers;
			break;
		case AdjacentMesh.AdjacentType.Full:
			flowers.mesh = Full_flowers;
			break;
		default:
			flowers.gameObject.SetActive(value: false);
			break;
		}
	}

	private void OnDestroy()
	{
		Player.inst.irrigation.OnReservoirIrrigationUpdated -= Irrigation_OnIrrigationUpdated;
	}

	private void Irrigation_OnIrrigationUpdated()
	{
		RefreshBonuses();
	}

	private void OnFinishedLoad()
	{
		RefreshBonuses();
	}

	private void RefreshBonuses()
	{
		Cell cell = GetComponent<Building>().GetCell();
		irrigationBonus = Mathff.Clamp(cell.IrrigationCoverage, 0, 1);
		adjMesh = GetComponent<AdjacentMesh>();
		adjMesh.UpdateRotation();
	}

	private int GetHappiness()
	{
		return HappinessModifierSystem.inst.GetPositiveHappiness(214) + adjacencyHappinessBonus + irrigationBonus;
	}

	public static bool IsGarden(int x, int z)
	{
		Cell cellData = World.inst.GetCellData(x, z);
		if (cellData != null)
		{
			if (!cellData.StructureCompareUniqueNameAll(World.gardenHash))
			{
				return cellData.StructureCompareCategoryNameAll(World.parkHash);
			}
			return true;
		}
		return false;
	}
}
