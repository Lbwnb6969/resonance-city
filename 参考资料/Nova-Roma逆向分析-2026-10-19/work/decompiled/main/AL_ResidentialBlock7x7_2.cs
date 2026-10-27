public class AL_ResidentialBlock7x7_2 : AL_ResidentialStamp
{
	public override void Init()
	{
		largestRectangleSizeX = 3;
		largestRectangleSizeZ = 3;
		ParseEditorCodes(AIBuildingBlockType.Residential, "7,7:R,0,0,1,1:R,1,0,1,1:R,2,0,1,1:O,3,0,1,1:R,4,0,1,1:R,5,0,1,1:R,6,0,1,1:R,0,1,1,1:R,1,1,1,1:R,2,1,1,1:O,3,1,1,1:R,4,1,1,1:R,5,1,1,1:R,6,1,1,1:R,0,2,1,1:R,1,2,1,1:O,garden,2,2,1,1:O,garden,3,2,1,1:O,garden,4,2,1,1:R,5,2,1,1:R,6,2,1,1:O,0,3,1,1:O,1,3,1,1:O,garden,2,3,1,1:R,well,3,3,1,1:O,garden,4,3,1,1:O,5,3,1,1:O,6,3,1,1:R,0,4,1,1:R,1,4,1,1:O,garden,2,4,1,1:O,garden,3,4,1,1:O,garden,4,4,1,1:R,5,4,1,1:R,6,4,1,1:R,0,5,1,1:R,1,5,1,1:R,2,5,1,1:O,3,5,1,1:R,4,5,1,1:R,5,5,1,1:R,6,5,1,1:R,0,6,1,1:R,1,6,1,1:R,2,6,1,1:O,3,6,1,1:R,4,6,1,1:R,5,6,1,1:R,6,6,1,1");
	}
}
