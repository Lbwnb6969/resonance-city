public class AL_CastleBlock3x3_GreatHall : AILayoutBlock
{
	public override void Init()
	{
		OutlineWithRoads = false;
		ParseEditorCodes(AIBuildingBlockType.Castle, "3,3:D,greathall,0,0,3,2:D,0,2,1,1:D,1,2,1,1:D,2,2,1,1");
	}

	public override bool BlockValidityTest(int posX, int posZ)
	{
		for (int i = 0; i < SizeX; i++)
		{
			for (int j = 0; j < SizeZ; j++)
			{
				Cell cellData = World.inst.GetCellData(posX + i, posZ + j);
				if (j <= SizeZ - 1 && cellData.Type != TerrainType.None)
				{
					return false;
				}
			}
		}
		return true;
	}
}
