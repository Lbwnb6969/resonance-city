using UnityEngine;

public class DamBlock : BlockBuilding, IWorkerUIDisplay
{
	private Cell[] neighbors = new Cell[4];

	protected override void OnBuilt()
	{
		base.OnBuilt();
		RiverTap.OnDamBlockChanged(b.GetCell(), null);
	}

	protected override void OnUnBuilt()
	{
		base.OnUnBuilt();
		RiverTap.OnDamBlockChanged(b.GetCell(), b);
	}

	public override void OnInit()
	{
		base.OnInit();
		b.PlacementValidaton = PlacementValidaton;
	}

	private new void PlacementValidaton(ref PlacementValidationResult result)
	{
		PlacementValidationResult res = PlacementValidationResult.Valid;
		b.ForEachTileInBounds((int x, int z, Cell cell2) =>
		{
			if (cell2.Type == TerrainType.Water)
			{
				res = PlacementValidationResult.CannotBuildOnWater;
			}
		});
		Cell cell = b.GetCell();
		if (cell.OccupyingStructure.Count > 0)
		{
			bool num = (bool)cell.TopMostStructure && cell.TopMostStructure.uniqueNameHash == World.rubbleHash;
			bool flag = cell.TopStructureIs(uniqueNameHash);
			bool flag2 = cell.TopStructureIs(World.spilloverHash);
			if (!num && !(flag | flag2))
			{
				res = PlacementValidationResult.ExistingStructure;
			}
		}
		if (DamProjectManager.inst.IsCellPartOfProject(cell, out var _))
		{
			res = PlacementValidationResult.CannotBuildOnExistingDamPlanningProject;
		}
		if (res == PlacementValidationResult.Valid)
		{
			World.inst.GetNeighborCells(cell, ref neighbors);
			for (int num2 = 0; num2 < neighbors.Length; num2++)
			{
				if (neighbors[num2] == null || !neighbors[num2].StructureCompareUniqueNameAll(World.spilloverHash))
				{
					continue;
				}
				Building building = neighbors[num2].StructureFind<Spillover>();
				if (building == null)
				{
					continue;
				}
				Spillover component = building.GetComponent<Spillover>();
				if (!(component == null))
				{
					Vector3 vector = cell.Center2D - neighbors[num2].Center2D;
					Vector2 normalized = new Vector2(vector.x, vector.z).normalized;
					Vector2 normalized2 = new Vector2(component.forward.x, component.forward.z).normalized;
					if (Mathf.Abs(Vector2.Dot(normalized, normalized2)) > 0.7f)
					{
						res = PlacementValidationResult.DamBlockCannotBePlacedAdjacentToSpillway;
						break;
					}
				}
			}
		}
		result = res;
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		DamPlanningProject project;
		return !DamProjectManager.inst.IsCellPartOfProject(b.cachedCell, out project);
	}
}
