using System;
using System.Collections.Generic;

public class Intention_ManageArmies : AIIntentionBase
{
	private Intention_BuildBuilding buildBarracks;

	private Intention_BuildBuilding buildChamberOfWar;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private int invasionArmies;

	private int invasionArchers;

	private int invasionCatapults;

	private bool needsMet;

	private static int frameID;

	private FrameUpdater defenderUpdate = new FrameUpdater(ref frameID, 10);

	private List<IMoveableUnit> defenders = new List<IMoveableUnit>();

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() == LandMass)
		{
			_ = obj.added;
		}
	}

	public void SetRequestArmyBuildUp(int count)
	{
		invasionArmies = count;
	}

	public void SetRequestArcherBuildUp(int count)
	{
		invasionArchers = count;
	}

	public void SetRequestCatapultBuildUp(int count)
	{
		invasionCatapults = count;
	}

	private void TrainUp(ArrayExt<Building> facilities, string name, int hash)
	{
		if (facilities.Count > 0)
		{
			Barracks component = facilities.data[0].GetComponent<Barracks>();
			if (!component.training)
			{
				component.AddTraining();
			}
			if (Kingdom.CurrentResources.Get(7) < 50)
			{
				Kingdom.makeToolsIntention.MakeTools(mt: false);
			}
		}
		else if (Player.inst.GetBuildingListForLandMass(LandMass, World.chamberOfWarHash).Count > 0)
		{
			if (buildBarracks == null && !IsBeingBuilt(hash))
			{
				buildBarracks = AddSubIntention<Intention_BuildBuilding>("build " + name);
				buildBarracks.Init(name, AIBuildingBlockType.Castle, Layout.KingdomStart, 16);
			}
		}
		else if (buildChamberOfWar == null && !IsBeingBuilt(World.chamberOfWarHash))
		{
			buildChamberOfWar = AddSubIntention<Intention_BuildBuilding>("build chamber of war");
			buildChamberOfWar.Init(World.chamberOfWarName, AIBuildingBlockType.Castle, Layout.KingdomStart, 16);
		}
	}

	public bool NeedsMet()
	{
		return needsMet;
	}

	public void ResetBuildUp()
	{
		invasionArchers = 0;
		invasionArmies = 0;
		Kingdom.makeToolsIntention.MakeTools(mt: true);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		bool flag = false;
		for (int i = 0; i < World.LandMassOwners.Count; i++)
		{
			if (!(LandmassOwner == World.LandMassOwners.data[i]) && World.inst.RelationBetween(LandmassOwner.teamId, World.LandMassOwners.data[i].teamId) == World.Relations.Enemy)
			{
				flag = true;
				break;
			}
		}
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.barracksHash);
		ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(LandMass, World.archerSchoolHash);
		ArrayExt<Building> buildingListForLandMass3 = Player.inst.GetBuildingListForLandMass(LandMass, World.siegeWorkshopHash);
		if (flag && (buildingListForLandMass.Count <= 0 || buildingListForLandMass2.Count <= 0 || buildingListForLandMass3.Count <= 0))
		{
			priority = 90;
		}
		else
		{
			priority = 66;
		}
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(LandMass);
		if (villagersForLandMass.Count < 125)
		{
			return;
		}
		int b = Mathff.Max(1, villagersForLandMass.Count / 200);
		b = Mathff.Min(Barracks.UnitLimit, Mathff.Max(invasionArmies, b));
		int num = ArmySystem.inst.UnitCount(LandmassOwner.teamId, ArmySystem.ArmyType.Default);
		needsMet = true;
		if (b > num)
		{
			needsMet = false;
			TrainUp(buildingListForLandMass, World.barracksName, World.barracksHash);
		}
		int b2 = Mathff.Max(1, villagersForLandMass.Count / 400);
		b2 = Mathff.Min(Barracks.UnitLimit, Mathff.Max(invasionArchers, b2));
		int num2 = ArmySystem.inst.UnitCount(LandmassOwner.teamId, ArmySystem.ArmyType.Archer);
		if (b2 > num2)
		{
			needsMet = false;
			TrainUp(buildingListForLandMass2, World.archerSchoolName, World.archerSchoolHash);
		}
		int b3 = Mathff.Max(1, villagersForLandMass.Count / 1000);
		b3 = Mathff.Min(Barracks.UnitLimit, Mathff.Max(invasionCatapults, b3));
		int num3 = SiegeCatapult.CountCatapults(LandmassOwner.teamId);
		if (b3 > num3)
		{
			needsMet = false;
			TrainUp(buildingListForLandMass3, World.siegeWorkshopName, World.siegeWorkshopHash);
		}
		if (needsMet && !Kingdom.makeToolsIntention.makeTools && !IsTraining(buildingListForLandMass) && !IsTraining(buildingListForLandMass2) && !IsTraining(buildingListForLandMass3))
		{
			Kingdom.makeToolsIntention.MakeTools(mt: true);
		}
		ArrayExt<IMoveTarget> arrayExt = Player.inst.HostilesOnLandmass(LandMass);
		for (int j = 0; j < arrayExt.Count; j++)
		{
			AddObjective(arrayExt.data[j]);
		}
		if (Kingdom.IsWolfMissionPotentialOrActive())
		{
			for (int k = 0; k < WolfDen.wolfDens.Count; k++)
			{
				WolfDen wolfDen = WolfDen.wolfDens[k];
				if (World.inst.GetCellDataClamped(wolfDen.transform.position).landMassIdx == LandMass)
				{
					RemoveObjective(wolfDen);
				}
			}
		}
		else
		{
			for (int l = 0; l < WolfDen.wolfDens.Count; l++)
			{
				WolfDen wolfDen2 = WolfDen.wolfDens[l];
				if (World.inst.GetCellDataClamped(wolfDen2.transform.position).landMassIdx == LandMass)
				{
					AddObjective(wolfDen2);
				}
			}
		}
		defenderUpdate.Update();
		if (defenderUpdate.Trigger())
		{
			CollectDefenders();
			for (int m = 0; m < defenders.Count; m++)
			{
				if (defenders[m] is ArmySystem.Army)
				{
					ArmySystem.Army army = defenders[m] as ArmySystem.Army;
					if ((float)army.units.Count < (float)army.squadSize * 0.25f && !army.tryRecooperate)
					{
						army.Recooperate();
					}
				}
			}
		}
		KillAndNullFinishedIntention(ref buildChamberOfWar);
		KillAndNullFinishedIntention(ref buildBarracks);
	}

	private bool IsTraining(ArrayExt<Building> barracks)
	{
		if (barracks.Count == 0)
		{
			return true;
		}
		for (int i = 0; i < barracks.Count; i++)
		{
			if (barracks.data[i].GetComponent<Barracks>().training)
			{
				return true;
			}
		}
		return false;
	}

	private void RemoveObjective(IMoveTarget t)
	{
		AIUnitControlSystem.Objective objective = Kingdom.unitControl.GetObjective(AIUnitControlSystem.ObjectiveType.DestroyUnit, t);
		if (objective != null)
		{
			Kingdom.unitControl.RemoveObjective(objective);
		}
	}

	private void AddObjective(IMoveTarget t)
	{
		if (!(t is TroopTransportShip) && Kingdom.unitControl.GetObjective(AIUnitControlSystem.ObjectiveType.DestroyUnit, t) == null)
		{
			AIUnitControlSystem.Objective objective = new AIUnitControlSystem.Objective
			{
				type = AIUnitControlSystem.ObjectiveType.DestroyUnit,
				target = t,
				time = SeasonManager.inst.TimeInYear() * 2f
			};
			if (t is ArmySystem.Army { armyType: not ArmySystem.ArmyType.Envoy })
			{
				objective.priority = 1;
			}
			Kingdom.unitControl.AddObjective(objective);
		}
	}

	private void CollectDefenders()
	{
		defenders.Clear();
		List<AIUnitControlSystem.UnitData> unitData = Kingdom.unitControl.unitData;
		int i = 0;
		for (int count = unitData.Count; i < count; i++)
		{
			if (unitData[i].unit is ArmySystem.Army army)
			{
				int landMassIdx = World.inst.GetCellDataClamped(army.generalPos).landMassIdx;
				if (army.armyType != ArmySystem.ArmyType.Envoy && landMassIdx == LandMass)
				{
					defenders.Add(army);
				}
			}
		}
	}
}
