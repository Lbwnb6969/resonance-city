using System;
using System.Collections;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;

public class HappinessModifierSystem : MonoBehaviour
{
	[Serializable]
	public struct HappinessModifier
	{
		public Sprite icon;

		public int id;

		public string name;

		public int positiveHappiness;

		public int negativeHappiness;

		public string positiveTerm;

		public string negativeTerm;

		public int priority;
	}

	public static HappinessModifierSystem inst;

	public const int Consumable_Wheat = 100;

	public const int Consumable_Bread = 101;

	public const int Consumable_Grapes = 102;

	public const int Consumable_Wine = 103;

	public const int Consumable_Ham = 104;

	public const int Consumable_Charcoal = 105;

	public const int Consumable_Apples = 106;

	public const int Consumable_Armaments = 107;

	public const int Consumable_Fish = 108;

	public const int Consumable_Wood = 109;

	public const int Consumable_Pottery = 110;

	public const int Consumable_Olives = 111;

	public const int Consumable_OliveOil = 112;

	public const int Tile_Well = 200;

	public const int Tile_Road = 201;

	public const int Tile_House = 202;

	public const int Tile_Waterfront = 203;

	public const int Tile_Tavern = 204;

	public const int Tile_Church = 205;

	public const int Tile_Library = 206;

	public const int Tile_Bathhouse = 207;

	public const int Tile_Theater = 208;

	public const int Tile_JoustingArena = 209;

	public const int Tile_Cathedral = 210;

	public const int Tile_GreatLibrary = 211;

	public const int Tile_TownCenter = 212;

	public const int Tile_Statue = 213;

	public const int Tile_Garden = 214;

	public const int Tile_Quarry = 215;

	public const int Tile_Blacksmith = 216;

	public const int Tile_IronMine = 217;

	public const int Tile_FishMonger = 218;

	public const int Tile_Swineherd = 219;

	public const int Tile_CharcoalMaker = 220;

	public const int Tile_ClayPit = 221;

	public const int Tile_Colosseum = 222;

	public const int Tile_ChariotRaceTrack = 223;

	public const int Tile_GladiatorSchool = 224;

	public const int Tile_PotteryWorkshop = 225;

	public const int Tile_Weaponsmith = 226;

	public const int Tile_Toolsmith = 227;

	public const int Tile_Fountain = 228;

	public const int Tile_JupiterTemple = 229;

	public const int Tile_Baker = 230;

	public const int Tile_Forum = 231;

	public const int Tile_Cemetery = 232;

	public const int Tile_OlivePress = 233;

	public const int Tile_Bath = 234;

	public const int Tile_Filth = 235;

	public const int Tile_Butcher = 236;

	public const int Tile_Columbarium = 237;

	public const int Tile_Degredation = 238;

	public const int Tile_Clinic = 239;

	public static IEnumerable DropdownOptions = new ValueDropdownList<int>
	{
		{ "Consumable_Wheat", 100 },
		{ "Consumable_Bread", 101 },
		{ "Consumable_Grapes", 102 },
		{ "Consumable_Wine", 103 },
		{ "Consumable_Ham", 104 },
		{ "Consumable_Charcoal", 105 },
		{ "Consumable_Apples", 106 },
		{ "Consumable_Armaments", 107 },
		{ "Consumable_Fish", 108 },
		{ "Consumable_Wood", 109 },
		{ "Consumable_Pottery", 110 },
		{ "Consumable_Olives", 111 },
		{ "Consumable_OliveOil", 112 },
		{ "Tile_Well", 200 },
		{ "Tile_Road", 201 },
		{ "Tile_House", 202 },
		{ "Tile_Waterfront", 203 },
		{ "Tile_Tavern", 204 },
		{ "Tile_Church", 205 },
		{ "Tile_Library", 206 },
		{ "Tile_Bathhouse", 207 },
		{ "Tile_Theater", 208 },
		{ "Tile_JoustingArena", 209 },
		{ "Tile_Cathedral", 210 },
		{ "Tile_GreatLibrary", 211 },
		{ "Tile_TownCenter", 212 },
		{ "Tile_Statue", 213 },
		{ "Tile_Garden", 214 },
		{ "Tile_Quarry", 215 },
		{ "Tile_Blacksmith", 216 },
		{ "Tile_IronMine", 217 },
		{ "Tile_FishMonger", 218 },
		{ "Tile_Swineherd", 219 },
		{ "Tile_CharcoalMaker", 220 },
		{ "Tile_ClayPit", 221 },
		{ "Tile_Colosseum", 222 },
		{ "Tile_ChariotRaceTrack", 223 },
		{ "Tile_GladiatorSchool", 224 },
		{ "Tile_PotteryWorkshop", 225 },
		{ "Tile_Weaponsmith", 226 },
		{ "Tile_Toolsmith", 227 },
		{ "Tile_Fountain", 228 },
		{ "Tile_JupiterTemple", 229 },
		{ "Tile_Baker", 230 },
		{ "Tile_Forum", 231 },
		{ "Tile_Cemetery", 232 },
		{ "Tile_OlivePress", 233 },
		{ "Tile_Bath", 234 },
		{ "Tile_Filth", 235 },
		{ "Tile_Butcher", 236 },
		{ "Tile_Columbarium", 237 },
		{ "Tile_Degredataion", 238 },
		{ "Tile_Clinic", 239 }
	};

	public static Dictionary<int, HappinessModifier> happinessModifierMap = new Dictionary<int, HappinessModifier>();

	private List<HappinessModifier> happinessModifiers = new List<HappinessModifier>();

	private void Awake()
	{
		inst = this;
		HappinessModifiers happinessModifiers = Resources.Load<HappinessModifiers>("HappinessModifiers");
		for (int i = 0; i < happinessModifiers.ConsumableModifiers.Count; i++)
		{
			AddHappinessModifier(happinessModifiers.ConsumableModifiers[i]);
		}
		for (int j = 0; j < happinessModifiers.ResidentialTileModifiers.Count; j++)
		{
			AddHappinessModifier(happinessModifiers.ResidentialTileModifiers[j]);
		}
	}

	public void AddHappinessModifier(HappinessModifier tile)
	{
		if (!happinessModifierMap.ContainsKey(tile.id))
		{
			happinessModifierMap.Add(tile.id, tile);
			happinessModifiers.Add(tile);
		}
		else
		{
			Debug.LogError("Duplicate Residential Tile IDs");
		}
	}

	public bool TryGetHappinessModifier(int id, out HappinessModifier mod)
	{
		mod = default;
		if (!happinessModifierMap.ContainsKey(id))
		{
			return false;
		}
		mod = happinessModifierMap[id];
		return true;
	}

	public bool TryGetPositiveHappiness(int id, out int happinessMod)
	{
		happinessMod = 0;
		if (!happinessModifierMap.ContainsKey(id))
		{
			return false;
		}
		happinessMod = happinessModifierMap[id].positiveHappiness;
		return true;
	}

	public int GetPositiveHappiness(int id)
	{
		if (!happinessModifierMap.ContainsKey(id))
		{
			return 0;
		}
		return happinessModifierMap[id].positiveHappiness;
	}

	public bool TryGetNegativeHappiness(int id, out int happinessMod)
	{
		happinessMod = 0;
		if (!happinessModifierMap.ContainsKey(id))
		{
			return false;
		}
		happinessMod = happinessModifierMap[id].negativeHappiness;
		return true;
	}

	public int GetNegativeHappiness(int id)
	{
		if (!happinessModifierMap.ContainsKey(id))
		{
			return 0;
		}
		return happinessModifierMap[id].negativeHappiness;
	}
}
