public class AL_CastleBlock3x7 : AL_CastleStamp
{
	public override void Init()
	{
		OutlineWithRoads = false;
		GenerateTypeRectangle(3, 7, AIBuildingBlockType.Castle);
	}
}
