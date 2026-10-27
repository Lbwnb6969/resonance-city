public class AL_MerchantShipBlock1x2 : AL_ShipStamp
{
	public override void Init()
	{
		OutlineWithRoads = false;
		ParseEditorCodes(AIBuildingBlockType.None, "1,2:N,playermerchant,0,0,1,2");
	}
}
