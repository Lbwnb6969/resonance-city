public class AL_CastleBlock3x3 : AL_CastleStamp
{
	public override void Init()
	{
		OutlineWithRoads = false;
		GenerateTypeRectangle(3, 3, AIBuildingBlockType.Castle);
	}

	public override bool BlockValidityTest(int posX, int posZ)
	{
		for (int i = 0; i < SizeX; i++)
		{
			for (int j = 0; j < SizeZ; j++)
			{
				if (World.inst.GetCellData(posX + i, posZ + j).Type != TerrainType.None)
				{
					return false;
				}
			}
		}
		return true;
	}
}
