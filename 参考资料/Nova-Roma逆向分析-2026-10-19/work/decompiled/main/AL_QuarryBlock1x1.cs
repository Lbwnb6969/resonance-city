public class AL_QuarryBlock1x1 : AILayoutBlock
{
	public override void Init()
	{
		OutlineWithRoads = false;
		ParseEditorCodes(AIBuildingBlockType.None, "1,1:N,quarry,0,0,1,1");
	}
}
