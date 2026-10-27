public class AL_TroopTransportShipBlock1x2 : AL_ShipStamp
{
	public override void Init()
	{
		OutlineWithRoads = false;
		ParseEditorCodes(AIBuildingBlockType.None, "1,2:N,trooptransportship,0,0,1,2");
	}
}
