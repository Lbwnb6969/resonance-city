public class AL_ResidentialBlock3x11 : AL_ResidentialStamp
{
	public override void Init()
	{
		largestRectangleSizeX = 3;
		largestRectangleSizeZ = 3;
		ParseEditorCodes(AIBuildingBlockType.Residential, "3,11:R,0,0,1,1:R,1,0,1,1:R,2,0,1,1:R,0,1,1,1:R,1,1,1,1:R,2,1,1,1:R,0,2,1,1:R,1,2,1,1:R,2,2,1,1:R,0,3,1,1:R,well,1,3,1,1:R,2,3,1,1:R,0,4,1,1:R,1,4,1,1:R,2,4,1,1:R,0,5,1,1:R,1,5,1,1:R,2,5,1,1:R,0,6,1,1:R,1,6,1,1:R,2,6,1,1:R,0,7,1,1:R,well,1,7,1,1:R,2,7,1,1:R,0,8,1,1:R,1,8,1,1:R,2,8,1,1:R,0,9,1,1:R,1,9,1,1:R,2,9,1,1:R,0,10,1,1:R,1,10,1,1:R,2,10,1,1");
	}
}
