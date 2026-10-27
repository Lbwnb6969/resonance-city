public class AL_NoriaStamp : AILayoutBlock
{
	public override bool BlockValidityTest(int posX, int posZ)
	{
		for (int i = 0; i < buildingTransforms.Count; i++)
		{
			AIBuildingMeta aIBuildingMeta = buildingTransforms[i];
			if ((aIBuildingMeta.uniqueName == World.moatName || aIBuildingMeta.uniqueName == World.noriaName) && World.inst.GetCellData(aIBuildingMeta.offsetX + posX, aIBuildingMeta.offsetZ + posZ).Type != TerrainType.None)
			{
				return false;
			}
		}
		return true;
	}
}
