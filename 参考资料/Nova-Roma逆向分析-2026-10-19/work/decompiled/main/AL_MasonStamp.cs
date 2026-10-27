public class AL_MasonStamp : AL_ResidentialStamp
{
	public override bool BlockValidityTest(int posX, int posZ)
	{
		for (int i = 0; i < buildingTransforms.Count; i++)
		{
			if (buildingTransforms[i].uniqueName != World.masonName)
			{
				continue;
			}
			AIBuildingMeta aIBuildingMeta = buildingTransforms[i];
			for (int j = 0; j < aIBuildingMeta.SizeX; j++)
			{
				for (int k = 0; k < aIBuildingMeta.SizeZ; k++)
				{
					if (World.inst.GetCellData(posX + aIBuildingMeta.OffsetX + j, posX + aIBuildingMeta.OffsetZ + k).Type != TerrainType.None)
					{
						return false;
					}
				}
			}
			break;
		}
		return base.BlockValidityTest(posX, posZ);
	}
}
