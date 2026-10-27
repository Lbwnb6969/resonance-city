using Sirenix.OdinInspector;

public class FreeResourceType
{
	public const int None = -1;

	public const int Wheat = 0;

	public const int Tree = 1;

	public const int Stone = 2;

	public const int Charcoal = 3;

	public const int Gold = 4;

	public const int IronOre = 5;

	public const int Tools = 6;

	public const int Armament = 7;

	public const int Fish = 8;

	public const int Apples = 9;

	public const int Pork = 10;

	public const int Bread = 11;

	public const int Grapes = 12;

	public const int Wine = 13;

	public const int Marble = 14;

	public const int Clay = 15;

	public const int Pottery = 16;

	public const int Dirt = 17;

	public const int Olives = 18;

	public const int OliveOil = 19;

	public const int Salt = 20;

	public static ValueDropdownList<int> DropdownOptions = new ValueDropdownList<int>
	{
		{ "Wheat", 0 },
		{ "Tree", 1 },
		{ "Stone", 2 },
		{ "Charcoal", 3 },
		{ "Gold", 4 },
		{ "IronOre", 5 },
		{ "Tools", 6 },
		{ "Armament", 7 },
		{ "Fish", 8 },
		{ "Apples", 9 },
		{ "Pork", 10 },
		{ "Bread", 11 },
		{ "Grapes", 12 },
		{ "Wine", 13 },
		{ "Marble", 14 },
		{ "Clay", 15 },
		{ "Pottery", 16 },
		{ "Dirt", 17 },
		{ "Olives", 18 },
		{ "OliveOil", 19 },
		{ "Salt", 20 }
	};
}
