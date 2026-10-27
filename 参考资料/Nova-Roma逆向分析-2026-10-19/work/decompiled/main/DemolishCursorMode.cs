using UnityEngine;

public class DemolishCursorMode : TileOperationCursorMode
{
	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		if (!returnedToOriginal)
		{
			for (int i = minZ; i < maxZ; i++)
			{
				for (int j = minX; j < maxX; j++)
				{
					Cell cellData = World.inst.GetCellData(j, i);
					if (Player.inst.LandMassIsAPlayerLandMass(cellData.landMassIdx))
					{
						GameUI.inst.demolishWarningUI.AddCell(cellData);
					}
				}
			}
			GameUI.inst.demolishWarningUI.DoDemolishOrShowWarning(minX, maxX, minZ, maxZ);
		}
		base.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		Cell cell = clickedCell;
		if (cell == null && clickedBuilding is Building building)
		{
			cell = building.GetCell();
		}
		if (cell != null && DamProjectManager.inst.IsCellPartOfProject(cell, out var project))
		{
			if (project.CanDemolishBuilding())
			{
				project.DemolishBuilding();
			}
			return true;
		}
		Building building2 = clickedBuilding as Building;
		if (building2 != null && building2.IsPlayerBuilding())
		{
			Cell cell2 = building2.GetCell();
			if (building2.CategoryName == World.castleblockName)
			{
				World.inst.DemolishBuildingByPlayer(cell2.TopStructure);
			}
			else if (building2.uniqueNameHash == World.stoneBridgeHash || building2.uniqueNameHash == World.woodBridgeHash)
			{
				Bridge component = building2.GetComponent<Bridge>();
				for (int i = 0; i < component.bridgePath.Count; i++)
				{
					Cell cellData = World.inst.GetCellData(component.bridgePath.data[i]);
					for (int j = 0; j < cellData.OccupyingStructure.Count; j++)
					{
						Building building3 = cellData.OccupyingStructure[j];
						if (building3 != null && building3.uniqueNameHash == building2.uniqueNameHash)
						{
							World.inst.DemolishBuildingByPlayer(building3);
						}
					}
				}
			}
			else
			{
				World.inst.DemolishBuildingByPlayer(building2);
			}
			OneOffEffect oneOffEffect = EffectsMan.inst.TileActionEffect.Create(building2.GetCell().Center3D + new Vector3(0f, 1f, 0f));
			oneOffEffect.Color = new Color(1f, 0.3f, 0.3f);
			oneOffEffect.AllowRelease = true;
			oneOffEffect.Play();
		}
		else if (clickedBuilding != null && clickedBuilding.TeamID() == 0 && clickedBuilding.CanDemolishBuilding())
		{
			clickedBuilding.DemolishBuilding();
		}
		return true;
	}
}
