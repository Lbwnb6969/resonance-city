public class AL_ForesterStamp : AILayoutBlock
{
	public bool avoidPlacingForesterOnLand = true;

	public override bool BlockValidityTest(int posX, int posZ)
	{
		bool flag = false;
		int num = 0;
		int num2 = (SizeX - 1) / 2;
		int num3 = (SizeZ - 1) / 2;
		for (int i = 0; i < SizeX; i++)
		{
			for (int j = 0; j < SizeZ; j++)
			{
				Cell cellData = World.inst.GetCellData(posX + i, posZ + j);
				flag |= World.inst.treeSystem.ItemAmount(cellData) > 0;
				if (cellData.Type == TerrainType.Water)
				{
					num++;
				}
				if (i == num2 && j == num3 && cellData.Type != TerrainType.None)
				{
					return false;
				}
			}
		}
		if (flag)
		{
			if (avoidPlacingForesterOnLand)
			{
				return (float)(sizeX * sizeZ) * 0.2f <= (float)num;
			}
			return true;
		}
		return false;
	}
}
