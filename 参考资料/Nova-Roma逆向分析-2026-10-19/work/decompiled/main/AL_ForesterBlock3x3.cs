public class AL_ForesterBlock3x3 : AL_ForesterStamp
{
	public override void Init()
	{
		OutlineWithRoads = false;
		ParseEditorCodes(AIBuildingBlockType.None, "3,3:N,0,0,1,1:N,1,0,1,1:N,2,0,1,1:N,0,1,1,1:N,forester,1,1,1,1:N,2,1,1,1:N,0,2,1,1:N,1,2,1,1:N,2,2,1,1");
	}
}
