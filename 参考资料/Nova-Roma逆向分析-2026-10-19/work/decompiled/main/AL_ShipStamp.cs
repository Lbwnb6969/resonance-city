public class AL_ShipStamp : AILayoutBlock
{
	public override bool BlockValidityTest(int posX, int posZ)
	{
		for (int i = 0; i < SizeX; i++)
		{
			for (int j = 0; j < SizeZ; j++)
			{
				Cell cellData = World.inst.GetCellData(posX + i, posZ + j);
				if (cellData.Type != TerrainType.Water || cellData.deepWater || !cellData.partOfOcean)
				{
					return false;
				}
			}
		}
		return true;
	}
}
