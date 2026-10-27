public class AL_IronMineBlock1x1 : AILayoutBlock
{
	public override void Init()
	{
		OutlineWithRoads = false;
		ParseEditorCodes(AIBuildingBlockType.None, "1,1:N,ironmine,0,0,1,1");
	}
}
