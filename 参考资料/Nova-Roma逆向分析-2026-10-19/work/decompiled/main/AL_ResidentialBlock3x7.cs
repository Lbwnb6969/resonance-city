public class AL_ResidentialBlock3x7 : AL_ResidentialStamp
{
	public override void Init()
	{
		largestRectangleSizeX = 3;
		largestRectangleSizeZ = 3;
		ParseEditorCodes(AIBuildingBlockType.Residential, "3,7:R,0,0,1,1:R,1,0,1,1:R,2,0,1,1:R,0,1,1,1:R,1,1,1,1:R,2,1,1,1:R,0,2,1,1:R,1,2,1,1:R,2,2,1,1:R,0,3,1,1:R,well,1,3,1,1:R,2,3,1,1:R,0,4,1,1:R,1,4,1,1:R,2,4,1,1:R,0,5,1,1:R,1,5,1,1:R,2,5,1,1:R,0,6,1,1:R,1,6,1,1:R,2,6,1,1");
	}
}
