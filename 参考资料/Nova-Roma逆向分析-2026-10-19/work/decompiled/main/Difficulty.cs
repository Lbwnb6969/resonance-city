using Sirenix.OdinInspector;

public class Difficulty
{
	public const int PEACEFUL = 0;

	public const int EASY = 1;

	public const int NORMAL = 2;

	public const int HARD = 3;

	public const int SURVIVAL = 4;

	public const int CUSTOM = 5;

	public static ValueDropdownList<int> ValueDropdown = new ValueDropdownList<int>
	{
		{ "PEACEFUL", 0 },
		{ "EASY", 1 },
		{ "NORMAL", 2 },
		{ "HARD", 3 },
		{ "SURVIVAL", 4 },
		{ "CUSTOM", 5 }
	};
}
