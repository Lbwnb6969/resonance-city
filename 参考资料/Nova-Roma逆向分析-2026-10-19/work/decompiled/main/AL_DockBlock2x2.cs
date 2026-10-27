public class AL_DockBlock2x2 : AILayoutBlock
{
	public override void Init()
	{
		OutlineWithRoads = false;
		ParseEditorCodes(AIBuildingBlockType.None, "2,2:N,dock,0,0,2,2");
	}

	public override bool BlockValidityTest(int posX, int posZ)
	{
		int num = 0;
		int num2 = 0;
		int num3 = 0;
		for (int i = -1; i <= SizeX; i++)
		{
			for (int j = -1; j <= SizeZ; j++)
			{
				Cell cellData = World.inst.GetCellData(posX + i, posZ + j);
				if (i != -1 && j != -1 && i != SizeX && j != SizeZ)
				{
					if (cellData.OccupyingStructure.Count != 0)
					{
						return false;
					}
					if (cellData.Type == TerrainType.Water)
					{
						num2++;
					}
					if (cellData.Type == TerrainType.None)
					{
						num3++;
					}
				}
				else if (cellData.Type == TerrainType.Water && cellData.OccupyingStructure.Count == 0 && cellData.partOfOcean)
				{
					num++;
				}
			}
		}
		if (num >= 3 && num3 == 1)
		{
			return num2 == 3;
		}
		return false;
	}
}
