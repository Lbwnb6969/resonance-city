public class CastleBlock : BlockBuilding
{
	private Cell[] scratch4 = new Cell[4];

	protected override void OnBuilt()
	{
		base.OnBuilt();
		Cell cell = b.GetCell();
		if (GetComponent<Building>() == cell.BottomStructure)
		{
			return;
		}
		bool flag = false;
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (building.categoryHash == World.gateHash || building.categoryHash == World.castleblockHash)
			{
				if (!flag)
				{
					b.Life = building.Life;
					b.ModifiedMaxLife = building.ModifiedMaxLife;
					flag = true;
				}
				building.Life++;
				building.ModifiedMaxLife++;
			}
		}
	}

	protected override void OnUnBuilt()
	{
		base.OnUnBuilt();
		Cell cell = b.GetCell();
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (building.categoryHash == World.gateHash || building.categoryHash == World.castleblockHash)
			{
				building.ModifiedMaxLife--;
				if (building.Life > building.ModifiedMaxLife)
				{
					building.Life = building.ModifiedMaxLife;
				}
			}
		}
	}

	public override void OnInit()
	{
		base.OnInit();
		b.PlacementValidaton = PlacementValidation;
	}

	public void PlacementValidation(ref PlacementValidationResult result)
	{
		if (result != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		Cell cellData = World.inst.GetCellData(GetPos());
		bool flag = true;
		for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
		{
			Building building = cellData.OccupyingStructure[i];
			if (building.categoryHash != World.archerTowerHash && (b.uniqueNameHash != World.castleblockHash || building.uniqueNameHash != World.woodcastleblockHash))
			{
				flag = false;
				break;
			}
		}
		if (flag)
		{
			result = PlacementValidationResult.Valid;
		}
	}
}
