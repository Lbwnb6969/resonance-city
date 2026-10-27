using System;

namespace Assets;

[Serializable]
public class HippiePersonality : AIPersonality
{
	public bool CompletesRoads => false;

	public int StartThreatLevel => 0;

	public bool AllowLibraries => true;

	public bool BelievesInWalls => false;

	public int ExtraHeightForTowers => 0;

	public AILayoutBlock[] BlockStamps { get; set; }

	public HippiePersonality()
	{
		BlockStamps = new AILayoutBlock[27]
		{
			new AL_FoodStamp7x7(),
			new AL_FoodStamp7x7_2(),
			new AL_FoodStamp3x11(),
			new AL_FoodStamp3x11_2(),
			new AL_FoodStamp3x7(),
			new AL_FoodStamp3x7_2(),
			new AL_FoodStamp3x3(),
			new AL_FoodStamp3x3_2(),
			new AL_ResidentialBlock7x7_2(),
			new AL_ResidentialBlock7x7_3(),
			new AL_ResidentialBlock7x7_4(),
			new AL_ResidentialBlock7x7_5(),
			new AL_ResidentialBlock3x3(),
			new AL_CivicBlock3x3(),
			new AL_KeepBlock3x3(),
			new AL_ForesterBlock3x7(),
			new AL_ForesterBlock3x3(),
			new AL_GraveStamp3x3(),
			new AL_DockBlock2x2(),
			new AL_MerchantShipBlock1x2(),
			new AL_TroopTransportShipBlock1x2(),
			new AL_CastleBlock3x7(),
			new AL_CastleBlock3x3(),
			new AL_QuarryBlock1x1(),
			new AL_IronMineBlock1x1(),
			new AL_NoriaBlock3x3(),
			new AL_NoriaBlock3x3_1()
		};
		for (int i = 0; i < BlockStamps.Length; i++)
		{
			BlockStamps[i].Init();
		}
	}
}
