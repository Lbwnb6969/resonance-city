public class AL_CastleStamp : AILayoutBlock
{
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
				if (cellData.Type == TerrainType.None)
				{
					num++;
					if (cellData.GetFertility() > 0)
					{
						num3++;
					}
				}
				else
				{
					num2++;
				}
				if (cellData.Type == TerrainType.Water)
				{
					return false;
				}
			}
		}
		if ((float)num3 < (float)num * 0.5f)
		{
			return num2 <= 3;
		}
		return false;
	}

	public override void OnBlockPlaced(AILayout layout)
	{
		base.OnBlockPlaced(layout);
		layout.DesignateCastleRegion(posX, posZ, posX + sizeX, posZ + sizeZ);
	}
}
