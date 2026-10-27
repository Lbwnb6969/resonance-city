public class AL_GraveStamp3x3 : AILayoutBlock
{
	public bool avoidPlacingOnFertile;

	public override void Init()
	{
		ParseEditorCodes(AIBuildingBlockType.None, "3,3:N,cemeterykeeper,0,0,2,1:N,cemetery,2,0,1,1:N,cemetery,0,1,1,1:N,cemetery,1,1,1,1:N,cemetery,2,1,1,1:N,cemetery,0,2,1,1:N,cemetery,1,2,1,1:N,cemetery,2,2,1,1");
	}

	public override bool BlockValidityTest(int posX, int posZ)
	{
		Cell cellData = World.inst.GetCellData(posX, posZ);
		if (cellData.Type != TerrainType.None)
		{
			return false;
		}
		int num = 0;
		int num2 = 0;
		for (int i = 0; i < SizeX; i++)
		{
			for (int j = 0; j < SizeZ; j++)
			{
				cellData = World.inst.GetCellData(posX + i, posZ + j);
				if (avoidPlacingOnFertile && cellData.Type == TerrainType.None)
				{
					num++;
					if (cellData.GetFertility() > 0)
					{
						num2++;
					}
				}
				if (cellData.Type == TerrainType.Water)
				{
					return false;
				}
			}
		}
		if (!((float)num2 < (float)num * 0.33f))
		{
			return !avoidPlacingOnFertile;
		}
		return true;
	}
}
