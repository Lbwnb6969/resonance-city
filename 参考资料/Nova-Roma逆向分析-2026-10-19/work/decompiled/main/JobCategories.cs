using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;

[CreateAssetMenu(fileName = "JobCategories", menuName = "ScriptableObjects/JobCategories")]
public class JobCategories : ScriptableObject
{
	public const int Undefined = 0;

	public const int Builders = 1;

	public const int Farms = 2;

	public const int Orchards = 3;

	public const int Markets = 4;

	public const int Archers = 5;

	public const int Ballista = 6;

	public const int Taverns = 7;

	public const int Hospitals = 8;

	public const int Stockpiles = 9;

	public const int FireFighter = 10;

	public const int WaterSystem = 11;

	public const int Homemakers = 12;

	public const int Infantry = 13;

	public const int Blacksmiths = 14;

	public const int CharcoalMakers = 15;

	public const int Churches = 16;

	public const int Library = 17;

	public const int Mason = 18;

	public const int Bakers = 19;

	public const int Docks = 20;

	public const int WoodCutting = 21;

	public const int IronMines = 22;

	public const int Quarries = 23;

	public const int Granaries = 24;

	public const int Castle = 25;

	public const int TreasureRoom = 26;

	public const int TownSquare = 27;

	public const int Windmill = 28;

	public const int MilitaryStaff = 29;

	public const int Cemetery = 30;

	public const int FireFighterProfessional = 31;

	public const int Fishing = 32;

	public const int Pigs = 33;

	public const int Jousting = 34;

	public const int Theater = 35;

	public const int TerrainEngineers = 36;

	public const int Idle = 37;

	public const int Winery = 38;

	public const int ClayPit = 39;

	public const int Colosseum = 40;

	public const int GladiatorSchool = 41;

	public const int PotteryWorkshop = 42;

	public const int Temple = 43;

	public const int TaxOffice = 44;

	public const int CircusMaximus = 45;

	public const int FishSaltingWorkshop = 46;

	public const int GrapeVines = 47;

	public const int Pantheon = 48;

	public const int Warehouse = 49;

	public const int Senate = 50;

	public const int Weaponsmiths = 51;

	public const int Toolsmiths = 52;

	public const int OliveTrees = 53;

	public const int OlivePress = 54;

	public const int Forester = 55;

	public const int Bathhouse = 56;

	public const int Shipyard = 57;

	public const int Butchers = 58;

	public const int SaltEvaporationPool = 59;

	public const int MarbleQuarry = 60;

	public const int CartDepot = 61;

	public const int ShipPort = 62;

	public const int Clinic = 63;

	public const int Plagued = 64;

	public static ValueDropdownList<int> DropdownOptions = new ValueDropdownList<int>
	{
		{ "Undefined", 0 },
		{ "Builders", 1 },
		{ "Farms", 2 },
		{ "Orchards", 3 },
		{ "Markets", 4 },
		{ "Archers", 5 },
		{ "Ballista", 6 },
		{ "Taverns", 7 },
		{ "Hospitals", 8 },
		{ "Stockpiles", 9 },
		{ "FireFighter", 10 },
		{ "WaterSystem", 11 },
		{ "Homemakers", 12 },
		{ "Infantry", 13 },
		{ "Blacksmiths", 14 },
		{ "CharcoalMakers", 15 },
		{ "Churches", 16 },
		{ "Library", 17 },
		{ "Mason", 18 },
		{ "Bakers", 19 },
		{ "Docks", 20 },
		{ "WoodCutting", 21 },
		{ "IronMines", 22 },
		{ "Quarries", 23 },
		{ "Granaries", 24 },
		{ "Castle", 25 },
		{ "TreasureRoom", 26 },
		{ "TownSquare", 27 },
		{ "Windmill", 28 },
		{ "MilitaryStaff", 29 },
		{ "Cemetery", 30 },
		{ "FireFighterProfessional", 31 },
		{ "Fishing", 32 },
		{ "Pigs", 33 },
		{ "Jousting", 34 },
		{ "Theater", 35 },
		{ "TerrainEngineers", 36 },
		{ "Idle", 37 },
		{ "Winery", 38 },
		{ "ClayPit", 39 },
		{ "Colosseum", 40 },
		{ "GladiatorSchool", 41 },
		{ "PotteryWorkshop", 42 },
		{ "Temple", 43 },
		{ "TaxOffice", 44 },
		{ "CircusMaximus", 45 },
		{ "FishSaltingWorkshop", 46 },
		{ "GrapeVines", 47 },
		{ "Pantheon", 48 },
		{ "Warehouse", 49 },
		{ "Senate", 50 },
		{ "Weaponsmiths", 51 },
		{ "Toolsmiths", 52 },
		{ "OliveTrees", 53 },
		{ "OlivePress", 54 },
		{ "Forester", 55 },
		{ "Bathhouse", 56 },
		{ "Ship Builders", 57 },
		{ "Butchers", 58 },
		{ "SaltEvaporationPool", 59 },
		{ "MarbleQuarry", 60 },
		{ "CartDepot", 61 },
		{ "ShipPort", 62 },
		{ "Clinic", 63 },
		{ "Plagued", 64 }
	};

	public List<JobSystem.JobCategory> jobCategories = new List<JobSystem.JobCategory>();
}
