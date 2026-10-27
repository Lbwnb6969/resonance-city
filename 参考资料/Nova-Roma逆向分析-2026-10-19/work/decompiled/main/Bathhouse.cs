using UnityEngine;

public class Bathhouse : Tickable, IOutputInfo, IWaterSystemUser
{
	public GameObject water;

	private bool shouldIrrigate;

	public Transform[] waitingPositions;

	public int Happiness = 10;

	public bool HasWater
	{
		get
		{
			return shouldIrrigate;
		}
		set
		{
			if (!shouldIrrigate & value)
			{
				Building component = GetComponent<Building>();
				for (int i = 0; i < component.attractionPositions.Length; i++)
				{
					if (!component.VerifyJobIs(i, typeof(IdleJob)))
					{
						component.SetAndAddJob(i, new IdleJob(component, IdleJob.IdleBehavior.Bathing));
					}
				}
			}
			else if (shouldIrrigate && !value)
			{
				Building component2 = GetComponent<Building>();
				for (int j = 0; j < component2.attractionJobs.Count; j++)
				{
					JobSystem.inst.RemoveJob(component2.attractionJobs[j]);
				}
				component2.attractionJobs.Clear();
			}
			shouldIrrigate = value;
			water.SetActive(value);
		}
	}

	public bool IsConnected { get; set; }

	public bool IsVisited { get; set; }

	string IOutputInfo.GetError()
	{
		if (!IsConnected)
		{
			return "ScriptLocalization.WaterAccessNotConnected";
		}
		if (IsConnected && !HasWater)
		{
			return "ScriptLocalization.WaterAccessConnectedNotClose";
		}
		return null;
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
		GetComponent<RadiusBonus>().happinessFunc = GetHappiness;
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
		water.GetComponent<MeshRenderer>().material = World.GetUniMaterialFor(GetComponent<Building>().LandMass());
	}

	private void OnBuilt()
	{
		Player.inst.irrigation.UpdateIrrigation();
		RefreshSurroundingRotation();
	}

	public int GetHappiness()
	{
		if (HappinessModifierSystem.inst.TryGetHappinessModifier(207, out var mod))
		{
			if (!HasWater)
			{
				return mod.negativeHappiness;
			}
			return mod.positiveHappiness;
		}
		return 0;
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(BathJob)))
			{
				b.SetAndAddJob(i, new BathJob(b));
			}
		}
	}
}
