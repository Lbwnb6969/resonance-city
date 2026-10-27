using Sirenix.OdinInspector;

public class CreativeOption
{
	public const int BuildForFree = 0;

	public const int VillagersEat = 1;

	public const int VillagersDieOfStarvation = 2;

	public const int VillagersLeaveIfUnhappy = 3;

	public const int Plagues = 4;

	public const int VikingAttacks = 5;

	public const int DragonAttacks = 6;

	public const int RandomFires = 7;

	public const int IgnoreBuildInTerritory = 8;

	public const int HideFogOfWar = 9;

	public const int ControlAITroops = 10;

	public const int BuildImmediately = 11;

	public static ValueDropdownList<int> ValueDropdown = new ValueDropdownList<int>
	{
		{ "BuildForFree", 0 },
		{ "VillagersEat", 1 },
		{ "VillagersDieOfStarvation", 2 },
		{ "VillagersLeaveIfUnhappy", 3 },
		{ "Plagues", 4 },
		{ "VikingAttacks", 5 },
		{ "DragonAttacks", 6 },
		{ "RandomFires", 7 },
		{ "IgnoreBuildInTerritory", 8 },
		{ "HideFogOfWar", 9 },
		{ "ControlAITroops", 10 },
		{ "BuildImmediately", 11 }
	};
}
