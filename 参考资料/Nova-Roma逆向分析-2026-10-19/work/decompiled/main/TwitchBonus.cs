using System.Collections.Generic;
using Assets;
using UnityEngine;

public static class TwitchBonus
{
	public static Color buffColor = new Color(0.5724401f, 0.9622642f, 0.2587219f);

	public static Color debuffColor = new Color(1f, 0.9276844f, 0.4575472f);

	public static Color trollColor = new Color(101f / 106f, 0.336778f, 0.1752848f);

	public static object[] UIVotableLayout = new object[41]
	{
		new VoteListHeading
		{
			TitleSegment = "Buffs"
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_ChopFaster),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_TreeDoubleYield),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_BetterCropYield),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_BetterQuarry),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_BetterCharcoalMakers),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_BetterMines),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_BetterBlacksmiths),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_BetterBarracksTraining),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_StrongerArmies),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_FasterAttackSpeed),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_FastVillagers),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_FeedEveryoneInstantly),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_VillagersCarryMore),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_DestroyAnUnusableStone),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_BuildingCostsReduced),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_FreeBuilding),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_TimeOfPeace),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_ResourceGiftStone),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_ResourceGiftWood),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_ResourceGiftCharcoal),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_ResourceGiftArmament),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_ResourceGiftTools),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_ResourceGiftIron),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_GrandFestival),
			color = buffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_PopulationBoost),
			color = buffColor
		},
		new VoteListHeading
		{
			TitleSegment = "Debuffs"
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_StrongerEnemies),
			color = debuffColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_SlowVillagers),
			color = debuffColor
		},
		new VoteListHeading
		{
			TitleSegment = "Trolls"
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_SuperSpeedTroll),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_VeryCloudySky),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_LightningStorm),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_DragonStorm),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_InstantDragonAttack),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_InstantVikingAttack),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_OgreBlitz),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_NormalPlague),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_SuperPlague),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_CharcoalAccident),
			color = trollColor
		},
		new Votable
		{
			Implementation = typeof(StreamerEffect_RatsEatFood),
			color = trollColor
		}
	};

	public static List<Votable> VotablesOnly = new List<Votable>(40);
}
