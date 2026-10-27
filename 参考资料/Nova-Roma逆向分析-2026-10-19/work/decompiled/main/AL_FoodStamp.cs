public class AL_FoodStamp : AILayoutBlock
{
	public override bool BlockValidityTest(int posX, int posZ)
	{
		int num = 0;
		int num2 = 0;
		for (int i = 0; i < buildingTransforms.Count; i++)
		{
			if (buildingTransforms[i].type == AIBuildingBlockType.Food)
			{
				num++;
				Cell cellData = World.inst.GetCellData(buildingTransforms[i].OffsetX + posX, buildingTransforms[i].OffsetZ + posZ);
				if (cellData != null && cellData.GetFertility() > 0)
				{
					num2++;
				}
				else if (buildingTransforms[i].uniqueName == World.farmName || buildingTransforms[i].uniqueName == World.orchardName)
				{
					return false;
				}
			}
		}
		return (float)num2 / (float)num > 0.75f;
	}
}
