using Sirenix.OdinInspector;

public class UnitTypes
{
	public const int TYPE_ANY = -1;

	public const int TYPE_LEGION_SWORDSMEN = 0;

	public const int TYPE_LEGION_ARCHERS = 1;

	public const int TYPE_SIEGE_CATAPULTS = 2;

	public const int TYPE_UNIT_TRANSPORT_SHIP = 3;

	public const int TYPE_LEGION_MILITIA = 4;

	public const int TYPE_LEGION_CAVALRY = 5;

	public static ValueDropdownList<int> ValueDropdown = new ValueDropdownList<int>
	{
		{ "Any", -1 },
		{ "Legion Swordsmen", 0 },
		{ "Siege Catapults", 2 },
		{ "Transport Ship", 3 },
		{ "Militia", 4 },
		{ "Cavalry", 5 }
	};
}
