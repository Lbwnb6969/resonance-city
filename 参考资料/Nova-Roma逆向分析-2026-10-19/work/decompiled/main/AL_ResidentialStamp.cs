public class AL_ResidentialStamp : AILayoutBlock
{
	public bool avoidPlacingResidentialOnFertile;

	public override bool BlockValidityTest(int posX, int posZ)
	{
		int num = 0;
		int num2 = 0;
		int num3 = 0;
		for (int i = 0; i < SizeX; i++)
		{
			for (int j = 0; j < SizeZ; j++)
			{
				Cell cellData = World.inst.GetCellData(posX + i, posZ + j);
				if (avoidPlacingResidentialOnFertile && cellData.Type == TerrainType.None)
				{
					num++;
					if (cellData.GetFertility() > 0)
					{
						num2++;
					}
				}
				if (cellData.Type == TerrainType.Water)
				{
					if (cellData.deepWater)
					{
						return false;
					}
					num3++;
				}
			}
		}
		if ((float)num2 < (float)num * 0.33f || !avoidPlacingResidentialOnFertile)
		{
			return num3 <= 5;
		}
		return false;
	}
}
