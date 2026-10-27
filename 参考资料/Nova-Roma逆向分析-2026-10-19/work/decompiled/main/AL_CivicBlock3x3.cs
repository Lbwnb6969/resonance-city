public class AL_CivicBlock3x3 : AL_ResidentialStamp
{
	public override void Init()
	{
		ParseEditorCodes(AIBuildingBlockType.Civic, "3,3:C,0,0,1,1:C,1,0,1,1:C,2,0,1,1:C,0,1,1,1:C,1,1,1,1:C,2,1,1,1:C,0,2,1,1:C,1,2,1,1:C,well,2,2,1,1");
	}
}
