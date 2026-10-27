public class ChopCancelCursorMode : TileOperationCursorMode
{
	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		for (int i = minZ; i < maxZ; i++)
		{
			for (int j = minX; j < maxX; j++)
			{
				Cell cellDataClamped = World.inst.GetCellDataClamped(j, i);
				if (Player.inst.LandMassIsAPlayerLandMass(cellDataClamped.landMassIdx))
				{
					GameUI.inst.RemoveChopJobFromCell(cellDataClamped, j == minX && i == minZ);
				}
			}
		}
		base.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell cellData)
	{
		if (cellData != null && Player.inst.LandMassIsAPlayerLandMass(cellData.landMassIdx))
		{
			GameUI.inst.RemoveChopJobFromCell(cellData);
		}
		return true;
	}
}
