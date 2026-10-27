using System;
using System.Collections.Generic;
using Assets.Code;
using UnityEngine;

public class Intention_ManageDiplomacy : AIIntentionBase
{
	[Serializable]
	public class ManageDiplomacySaveData : SaveClass<Intention_ManageDiplomacy, ManageDiplomacySaveData>
	{
		private int objectiveIdx;

		private Timer objectiveTimer;

		private bool invasionStarted;

		private AIObjectiveType objective;

		private Guid unitObjective;

		private bool didFirstGoldDemand;

		private AIObjectiveType setNextObjective;

		private int denyPeace;

		private int removeTroopCount;

		private float removeTroopTime;

		private int lastGiftYear;

		public override ManageDiplomacySaveData Pack(Intention_ManageDiplomacy v)
		{
			objectiveIdx = v.objectiveIdx;
			objectiveTimer = v.objectiveTimer;
			invasionStarted = v.invasionStarted;
			objective = v.objective;
			if (v.currUnitObjective != null)
			{
				unitObjective = v.currUnitObjective.guid;
			}
			didFirstGoldDemand = v.didFirstGoldDemand;
			setNextObjective = v.setNextObjective;
			denyPeace = v.denyPeace;
			removeTroopCount = v.removeTroopCount;
			removeTroopTime = v.removeTroopTime;
			lastGiftYear = v.lastGiftYear;
			return this;
		}

		public override Intention_ManageDiplomacy Unpack(Intention_ManageDiplomacy v)
		{
			v.objectiveIdx = objectiveIdx;
			v.objectiveTimer = objectiveTimer;
			v.invasionStarted = invasionStarted;
			v.objective = objective;
			v.didFirstGoldDemand = didFirstGoldDemand;
			_ = unitObjective;
			v.currUnitObjective = v.Kingdom.unitControl.GetObjectiveByGuid(unitObjective);
			v.setNextObjective = setNextObjective;
			v.denyPeace = denyPeace;
			v.removeTroopCount = removeTroopCount;
			v.removeTroopTime = removeTroopTime;
			v.lastGiftYear = lastGiftYear;
			return v;
		}
	}

	private EventHandler<SeasonEventData> eventHandle;

	private AIUnitControlSystem.Objective currUnitObjective;

	[NonSerialized]
	public AIObjectiveType objective;

	private int lastGiftYear;

	private bool deferClearUnitObjective;

	internal int denyPeace;

	private AIObjectiveType setNextObjective;

	private float removeTroopTime;

	[NonSerialized]
	public int bonusPriority;

	internal int removeTroopCount;

	private List<ArmySystem.Army> idleEnvoies = new List<ArmySystem.Army>();

	private AIObjectiveType[] script;

	private int objectiveIdx;

	private Timer objectiveTimer = new Timer(480f);

	private bool invasionStarted;

	[NonSerialized]
	public bool didFirstGoldDemand;

	public void Init()
	{
		eventHandle = Broadcast.SeasonEvent.Listen(OnSeasonChange);
		if (Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Anxious)
		{
			script = new AIObjectiveType[5]
			{
				AIObjectiveType.AskForMissionHelp,
				AIObjectiveType.Chat,
				AIObjectiveType.AskForMissionHelp,
				AIObjectiveType.GiveGift,
				AIObjectiveType.AskTradeRouteOpen
			};
		}
		else if (Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Aggressive)
		{
			script = new AIObjectiveType[6]
			{
				AIObjectiveType.Chat,
				AIObjectiveType.DemandGold,
				AIObjectiveType.AskForMissionHelp,
				AIObjectiveType.DemandGold,
				AIObjectiveType.AskTradeRouteOpen,
				AIObjectiveType.DemandGold
			};
		}
		else
		{
			script = new AIObjectiveType[5]
			{
				AIObjectiveType.Chat,
				AIObjectiveType.AskForMissionHelp,
				AIObjectiveType.Chat,
				AIObjectiveType.GiveGift,
				AIObjectiveType.AskTradeRouteOpen
			};
		}
		objectiveIdx = Mathf.Clamp(objectiveIdx, 0, script.Length - 1);
		objective = script[objectiveIdx];
		Kingdom.unitControl.OnObjectiveCompleted += OnObjectiveComplete;
		Kingdom.unitControl.OnObjectiveUnassigned += OnObjectiveUnassigned;
	}

	private void OnDisable()
	{
		Broadcast.SeasonEvent.Unlisten(eventHandle);
		Kingdom.unitControl.OnObjectiveCompleted -= OnObjectiveComplete;
		Kingdom.unitControl.OnObjectiveUnassigned -= OnObjectiveUnassigned;
	}

	private void OnSeasonChange(object sender, SeasonEventData seasonEvent)
	{
		if (seasonEvent.SeasonDefinition.markNewYear)
		{
			LandmassOwner.Standing standingFor = LandmassOwner.GetStandingFor(Player.inst.PlayerLandmassOwner.teamId);
			if (standingFor == LandmassOwner.Standing.VeryFavorable)
			{
				Kingdom.diplomacyPoints++;
			}
			else if (standingFor <= LandmassOwner.Standing.Neutral)
			{
				Kingdom.diplomacyPoints = 0;
			}
			if (standingFor == LandmassOwner.Standing.VeryUnfavorable)
			{
				Kingdom.enemyPoints++;
			}
			else if (standingFor >= LandmassOwner.Standing.Unfavorable)
			{
				Kingdom.enemyPoints = 0;
			}
		}
	}

	private void InitTourObjective()
	{
		Building component = Player.inst.keep.GetComponent<Building>();
		ArrayExt<Cell> arrayExt = new ArrayExt<Cell>(100);
		Player.inst.keep.LandMass();
		int num = (int)component.Center().x;
		int num2 = (int)component.Center().z;
		int num3 = 7;
		int num4 = Mathf.Max(num - num3, 0);
		int num5 = Mathf.Max(num2 - num3, 0);
		int num6 = Mathf.Min(num + num3, World.inst.GridWidth - 1);
		int num7 = Mathf.Min(num2 + num3, World.inst.GridHeight - 1);
		for (int i = num4; i <= num6; i++)
		{
			for (int j = num5; j <= num7; j++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i, j);
				if (cellDataUnsafe.StructureCompareCategory(World.pathHash))
				{
					arrayExt.Add(cellDataUnsafe);
				}
			}
		}
		component = arrayExt.RandomElement().OccupyingStructure[0];
		currUnitObjective = new AIUnitControlSystem.Objective
		{
			type = AIUnitControlSystem.ObjectiveType.MoveToBuilding,
			target = component,
			exclusive = true
		};
		Kingdom.unitControl.AddObjective(currUnitObjective);
	}

	private bool InitGiftObjective()
	{
		Building building = null;
		int num = 0;
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(World.keepHash);
		for (int i = 0; i < buildingList.Count; i++)
		{
			if (buildingList.data[i].TeamID() == num)
			{
				building = buildingList.data[i];
				break;
			}
		}
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.hallofdiplomacyHash);
		if (buildingListForLandMass.Count > 0 && building != null)
		{
			Building target = buildingListForLandMass.data[0];
			AIUnitControlSystem.Objective objective = new AIUnitControlSystem.Objective
			{
				type = AIUnitControlSystem.ObjectiveType.PickUpGift,
				target = target,
				exclusive = true
			};
			Kingdom.unitControl.AddObjective(objective);
			currUnitObjective = objective;
			AIUnitControlSystem.Objective objective2 = new AIUnitControlSystem.Objective
			{
				type = AIUnitControlSystem.ObjectiveType.GiveGift,
				target = building,
				exclusive = true
			};
			Kingdom.unitControl.AddObjectiveAsDependency(objective2, objective);
			AIUnitControlSystem.Objective child = new AIUnitControlSystem.Objective
			{
				type = AIUnitControlSystem.ObjectiveType.WaitForComplete,
				target = building,
				exclusive = true
			};
			Kingdom.unitControl.AddObjectiveAsDependency(child, objective2);
			lastGiftYear = SeasonManager.inst.CurrentYear();
			return true;
		}
		return false;
	}

	private void OnObjectiveComplete(AIUnitControlSystem.Objective o)
	{
		if (o == currUnitObjective)
		{
			if (currUnitObjective.next != null)
			{
				currUnitObjective = currUnitObjective.next;
				return;
			}
			currUnitObjective = null;
			objective = AIObjectiveType.None;
		}
	}

	private void OnObjectiveUnassigned(AIUnitControlSystem.Objective o)
	{
		if (o == currUnitObjective && currUnitObjective.unitsAssigned.Count == 0)
		{
			deferClearUnitObjective = true;
		}
	}

	private ResourceAmount GetPotentialGiftAmount()
	{
		LandmassOwner.Standing standingFor = LandmassOwner.GetStandingFor(Player.inst.PlayerLandmassOwner.teamId);
		ResourceAmount resourceAmount = Kingdom.CurrentResources - Kingdom.lastFrameRequestedResources;
		resourceAmount *= 0.5f;
		for (int i = 0; i < resourceAmount.resources.Count; i++)
		{
			if (resourceAmount.resources[i].Amount > 50)
			{
				resourceAmount.resources[i].Amount = 50;
			}
		}
		ResourceAmount resourceAmount2 = new ResourceAmount();
		for (int j = 0; j < resourceAmount.resources.Count; j++)
		{
			Resource resource = resourceAmount.resources[j];
			if (resource.Amount > 5)
			{
				float num = SRand.Range(0.25f, 0.5f);
				switch (standingFor)
				{
				case LandmassOwner.Standing.Favorable:
					num += 0.25f;
					break;
				case LandmassOwner.Standing.VeryFavorable:
					num += 0.5f;
					break;
				}
				num = Mathf.Clamp01(num);
				float num2 = (float)resource.Amount * num;
				resourceAmount2.Set(resource.resourceID, Mathf.Max(5, (int)num2));
			}
		}
		return resourceAmount2;
	}

	public void OnDeclaredWar()
	{
		ClearDiplomaticUnitObjectives();
		objective = AIObjectiveType.None;
		denyPeace = 0;
	}

	public void SetNextObjective(AIObjectiveType o)
	{
		setNextObjective = o;
		objectiveTimer.ForceExpire();
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(LandMass);
		if (villagersForLandMass.Count < 75)
		{
			return;
		}
		priority = 67;
		if (villagersForLandMass.Count > 150 && Player.inst.GetBuildingListForLandMass(LandMass, World.hallofdiplomacyHash).Count <= 0)
		{
			priority = 90;
		}
		if (deferClearUnitObjective && currUnitObjective != null)
		{
			Kingdom.unitControl.RemoveObjective(currUnitObjective);
			currUnitObjective = null;
			deferClearUnitObjective = false;
		}
		LandmassOwner.Standing standingFor = LandmassOwner.GetStandingFor(Player.inst.PlayerLandmassOwner.teamId);
		ValidateCurrentObjective();
		if (objective == AIObjectiveType.None)
		{
			removeTroopTime += dt;
			if (removeTroopTime > 25f)
			{
				removeTroopTime = 0f;
				if (PlayerNeedsToCallTroopsHome())
				{
					objective = AIObjectiveType.AskForTroopDrawDown;
				}
				else
				{
					removeTroopCount = Mathff.Max(0, removeTroopCount - 1);
				}
			}
			if (objectiveTimer.Update(dt))
			{
				bool flag = false;
				if (setNextObjective != AIObjectiveType.None)
				{
					objective = setNextObjective;
					setNextObjective = AIObjectiveType.None;
				}
				else
				{
					AdvanceScript();
					if (Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Playful || Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Anxious)
					{
						int num = 150;
						if (Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Playful)
						{
							num = 300;
						}
						if (Kingdom.diplomacyPoints >= num && standingFor == LandmassOwner.Standing.VeryFavorable && LandmassOwner.lastStandingChange > 0)
						{
							objective = AIObjectiveType.Abdicate;
						}
					}
					if (standingFor == LandmassOwner.Standing.Unfavorable && LandmassOwner.lastStandingChange < 0)
					{
						if (!Kingdom.didEnemyWarning)
						{
							if (Kingdom.enemyPoints >= Kingdom.GetEnemyPointsForWarning())
							{
								objective = AIObjectiveType.DiscussBadBlood;
							}
						}
						else if (Kingdom.enemyPoints >= Kingdom.GetEnemyPointsForWarning() + SRand.Range(10, 20))
						{
							objective = AIObjectiveType.DiscussBadBlood;
						}
					}
					ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(Kingdom.Layout.LandMass, World.dockHash);
					if (SeasonManager.inst.CurrentYear() > 45 && !Player.inst.DocksOpen(Player.inst.PlayerLandmassOwner, LandmassOwner) && standingFor >= LandmassOwner.Standing.Neutral && buildingListForLandMass.Count > 0 && (objective == AIObjectiveType.Chat || objective == AIObjectiveType.AskForMissionHelp) && SRand.Range(0, 100) > 50)
					{
						objective = AIObjectiveType.AskTradeRouteOpen;
					}
					int num2 = objectiveIdx;
					while (!flag)
					{
						if (objective != AIObjectiveType.AskTradeRouteOpen)
						{
							if (objective == AIObjectiveType.Chat)
							{
								flag = Kingdom.audienceTimer <= 0f && Kingdom.HasValidFlavor(aiVisitingUs: true);
							}
							else
							{
								flag = ((objective == AIObjectiveType.AskForMissionHelp) ? (Kingdom.potentialMission != null) : (objective != AIObjectiveType.GiveGift || (Player.inst.GetBuildingListForLandMass(LandMass, World.hallofdiplomacyHash).Count > 0 && standingFor >= LandmassOwner.Standing.Neutral && !GetPotentialGiftAmount().IsNone() && LandmassOwner.lastStandingChange > 0 && SeasonManager.inst.CurrentYear() - lastGiftYear > 15)));
							}
						}
						else
						{
							bool flag2 = !Player.inst.DocksOpen(Player.inst.PlayerLandmassOwner, Kingdom.LandmassOwner) && standingFor == LandmassOwner.Standing.VeryUnfavorable;
							flag = buildingListForLandMass.Count > 0 && !flag2;
						}
						if (!flag)
						{
							AdvanceScript();
							if (objectiveIdx == num2)
							{
								objective = AIObjectiveType.None;
								break;
							}
						}
					}
				}
				if (World.inst.RelationBetween(LandmassOwner.teamId, 0) == World.Relations.Enemy)
				{
					int num3 = 2;
					if (Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Aggressive)
					{
						num3 = 1;
					}
					if (denyPeace > num3)
					{
						objective = AIObjectiveType.None;
					}
					else
					{
						objective = AIObjectiveType.DiscussSurrender;
					}
				}
				if (flag)
				{
					float num4 = 1f;
					for (int i = 0; i < AIBrainsContainer.inst.kingdoms.Count; i++)
					{
						AIKingdom aIKingdom = AIBrainsContainer.inst.kingdoms[i];
						if (!(aIKingdom == Kingdom))
						{
							if (aIKingdom.manageDiplomacyIntention.objective == AIObjectiveType.Chat || aIKingdom.manageDiplomacyIntention.objective == AIObjectiveType.AskForMissionHelp || aIKingdom.manageDiplomacyIntention.objective == AIObjectiveType.AskTradeRouteOpen)
							{
								aIKingdom.manageDiplomacyIntention.objectiveTimer.CurrTime -= SRand.Range(550, 850);
							}
							if (aIKingdom.manageDiplomacyIntention.objectiveTimer.CurrTime < num4)
							{
								num4 = aIKingdom.manageDiplomacyIntention.objectiveTimer.CurrTime;
							}
						}
					}
					if (num4 < 1f)
					{
						objectiveTimer.CurrTime = num4 - 200f;
					}
					objectiveTimer.Duration += 20f;
					if (objectiveTimer.Duration > 840f)
					{
						objectiveTimer.Duration = 840f;
					}
				}
			}
		}
		if (objective == AIObjectiveType.GiveGift && currUnitObjective == null)
		{
			HallOfDiplomacy hallOfDiplomacy = null;
			ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(LandMass, World.hallofdiplomacyHash);
			if (buildingListForLandMass2.Count > 0)
			{
				hallOfDiplomacy = buildingListForLandMass2.data[0].GetComponent<HallOfDiplomacy>();
			}
			if (!hallOfDiplomacy.MakingGift() && !hallOfDiplomacy.HasGift())
			{
				hallOfDiplomacy.StartMakingGift(GetPotentialGiftAmount());
			}
			if (hallOfDiplomacy.HasGift())
			{
				InitGiftObjective();
			}
		}
		if ((objective == AIObjectiveType.Chat || objective == AIObjectiveType.AskForMissionHelp || objective == AIObjectiveType.AskTradeRouteOpen || objective == AIObjectiveType.Abdicate || objective == AIObjectiveType.DiscussBadBlood || objective == AIObjectiveType.DemandGold || objective == AIObjectiveType.DiscussSurrender || objective == AIObjectiveType.ImmigrateDiplomat || objective == AIObjectiveType.AskForTroopDrawDown) && currUnitObjective == null)
		{
			Building component = Player.inst.keep.GetComponent<Building>();
			currUnitObjective = new AIUnitControlSystem.Objective
			{
				type = AIUnitControlSystem.ObjectiveType.MoveToBuilding,
				target = component,
				exclusive = true
			};
			Kingdom.unitControl.AddObjective(currUnitObjective);
			AIUnitControlSystem.Objective child = new AIUnitControlSystem.Objective
			{
				type = AIUnitControlSystem.ObjectiveType.WaitForComplete,
				target = component,
				exclusive = true
			};
			Kingdom.unitControl.AddObjectiveAsDependency(child, currUnitObjective);
		}
	}

	public bool PlayerNeedsToCallTroopsHome()
	{
		int num = OrdersManager.inst.TroopsOnLandmass(0, Layout.LandMass);
		int num2 = OrdersManager.inst.TroopsOnLandmass(LandmassOwner.teamId, Layout.LandMass);
		World.Relations relations = World.inst.RelationBetween(LandmassOwner.teamId, 0);
		if (relations == World.Relations.Neutral && num > 0)
		{
			return true;
		}
		if (relations == World.Relations.Allies && num > num2 && num > 10 && !Kingdom.IsWolfMissionPotentialOrActive())
		{
			return true;
		}
		return false;
	}

	private void ValidateCurrentObjective()
	{
		if (objective == AIObjectiveType.AskForMissionHelp && Kingdom.currMission == null && Kingdom.potentialMission == null)
		{
			objective = AIObjectiveType.Chat;
		}
		if (objective == AIObjectiveType.Chat && !Kingdom.HasValidFlavor(aiVisitingUs: true))
		{
			ResetObjective();
		}
		if (objective == AIObjectiveType.GiveGift && Player.inst.GetBuildingListForLandMass(LandMass, World.hallofdiplomacyHash).Count <= 0)
		{
			ResetObjective();
		}
	}

	public void ResetObjective()
	{
		ClearDiplomaticUnitObjectives();
		objective = AIObjectiveType.None;
	}

	private void ClearDiplomaticUnitObjectives()
	{
		if (currUnitObjective != null)
		{
			GameUI.inst.diplomacyNotificationUI.CloseBanner(LandmassOwner.teamId);
			Kingdom.unitControl.RemoveObjective(currUnitObjective);
			currUnitObjective = null;
		}
	}

	private void AdvanceScript()
	{
		objective = script[objectiveIdx];
		objectiveIdx++;
		if (objectiveIdx >= script.Length)
		{
			objectiveIdx = 0;
		}
	}
}
