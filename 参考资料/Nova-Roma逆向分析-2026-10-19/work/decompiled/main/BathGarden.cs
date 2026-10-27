using System;
using UnityEngine;

public class BathGarden : MonoBehaviour
{
	[NonSerialized]
	public Building b;

	public AdjacentMesh gardenAdjMesh;

	public AdjacentMesh wallMesh;

	public GameObject foundationObj;

	private void Awake()
	{
		b = GetComponent<Building>();
		gardenAdjMesh.shouldConnect = ShouldConnect;
		wallMesh.shouldConnect = ShouldConnect2;
	}

	public bool ShouldConnect2(Cell c)
	{
		if (c == null)
		{
			return false;
		}
		Building building = GameUI.inst.CurrPlacementMode.buildingMap[c.index];
		if (building != null)
		{
			return b.categoryHash == building.categoryHash;
		}
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (c.OccupyingStructure[i].categoryHash == b.categoryHash)
			{
				return true;
			}
		}
		return false;
	}

	private bool ShouldConnect(Cell c)
	{
		if (c == null)
		{
			return false;
		}
		Building building = GameUI.inst.CurrPlacementMode.buildingMap[c.index];
		if (building != null)
		{
			return b.uniqueNameHash == building.uniqueNameHash;
		}
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (c.OccupyingStructure[i].uniqueNameHash == b.uniqueNameHash)
			{
				return true;
			}
		}
		return false;
	}

	public void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			if (LoadSave.Loading && b.IsBuilt())
			{
				BathManager.inst.Register(b);
			}
		}
		else if (b.IsBuilt())
		{
			BathManager.inst.Deregister(b);
		}
	}

	public void OnBuilt()
	{
		BathManager.inst.Register(b);
	}

	public void OnAddJobs()
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				IdleJob job = new IdleJob(b, IdleJob.IdleBehavior.Looking);
				b.SetAndAddJob(i, job);
			}
		}
	}
}
