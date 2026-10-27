using System;
using System.Collections.Generic;

public class Intention_ManageInvasion : AIIntentionBase
{
	public class Wave
	{
		public List<AIUnitControlSystem.Objective> objectives = new List<AIUnitControlSystem.Objective>();
	}

	[Serializable]
	public class ManageInvasionSaveData : SaveClass<Intention_ManageInvasion, ManageInvasionSaveData>
	{
		private List<Guid> waveObjectives;

		private int targetTeamId;

		private int successfulWaves;

		private int objectiveAmount;

		private float waveTime;

		private int escalate;

		public override ManageInvasionSaveData Pack(Intention_ManageInvasion v)
		{
			if (v.currWave != null)
			{
				waveObjectives = new List<Guid>();
				for (int i = 0; i < v.currWave.objectives.Count; i++)
				{
					waveObjectives.Add(v.currWave.objectives[i].guid);
				}
			}
			else
			{
				waveObjectives = null;
			}
			targetTeamId = v.targetTeamId;
			successfulWaves = v.successfulWaves;
			objectiveAmount = v.objectiveAmount;
			waveTime = v.waveTime;
			escalate = v.escalate;
			return this;
		}

		public override Intention_ManageInvasion Unpack(Intention_ManageInvasion v)
		{
			if (waveObjectives != null)
			{
				v.currWave = new Wave();
				for (int i = 0; i < waveObjectives.Count; i++)
				{
					v.currWave.objectives.Add(v.Kingdom.unitControl.GetObjectiveByGuid(waveObjectives[i]));
				}
			}
			v.targetTeamId = targetTeamId;
			v.successfulWaves = successfulWaves;
			v.objectiveAmount = objectiveAmount;
			v.waveTime = waveTime;
			v.escalate = escalate;
			return v;
		}
	}

	internal Wave currWave;

	internal int targetTeamId;

	internal int successfulWaves = -1;

	private int objectiveAmount = 10;

	private float waveTime;

	private int escalate;

	public void Init(int foreignTeamId)
	{
		targetTeamId = foreignTeamId;
		Kingdom.unitControl.OnObjectiveCompleted += OnObjectiveCompleted;
		Kingdom.unitControl.OnObjectiveRemoved += OnObjectiveRemoved;
	}

	private void OnDisable()
	{
		Kingdom.unitControl.OnObjectiveCompleted -= OnObjectiveCompleted;
		Kingdom.unitControl.OnObjectiveRemoved -= OnObjectiveRemoved;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 71;
		if (World.inst.RelationBetween(LandmassOwner.teamId, targetTeamId) == World.Relations.Enemy)
		{
			if (currWave == null)
			{
				int num = 3;
				int num2 = 2;
				int num3 = 1;
				num3 += escalate;
				num2 += escalate;
				num += escalate;
				Kingdom.manageArmiesIntention.SetRequestArmyBuildUp(num);
				Kingdom.manageArmiesIntention.SetRequestArcherBuildUp(num2);
				Kingdom.manageArmiesIntention.SetRequestCatapultBuildUp(num3);
				if (Kingdom.manageArmiesIntention.NeedsMet())
				{
					Kingdom.manageArmiesIntention.ResetBuildUp();
					currWave = new Wave();
					AddObjectives(currWave.objectives);
				}
				return;
			}
			waveTime += dt;
			if (currWave.objectives.Count != 0 && !(waveTime > SeasonManager.inst.TimeInYear() * 10f))
			{
				return;
			}
			if (waveTime > SeasonManager.inst.TimeInYear() * 10f)
			{
				escalate += 2;
				objectiveAmount = 10;
				successfulWaves = 0;
			}
			else
			{
				if (successfulWaves == -1)
				{
					successfulWaves = 0;
				}
				successfulWaves++;
				if (Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Aggressive)
				{
					objectiveAmount += 10;
				}
				else
				{
					objectiveAmount += 3;
				}
				escalate--;
			}
			escalate = Mathff.Clamp(escalate, 0, 5);
			CleanUpWave();
		}
		else if (currWave != null)
		{
			CleanUpWave();
			escalate /= 2;
			successfulWaves = -1;
		}
	}

	private void CleanUpWave()
	{
		for (int i = 0; i < currWave.objectives.Count; i++)
		{
			Kingdom.unitControl.RemoveObjective(currWave.objectives[i]);
		}
		currWave.objectives.Clear();
		currWave = null;
		waveTime = 0f;
	}

	private void OnObjectiveRemoved(AIUnitControlSystem.Objective o)
	{
		if (currWave != null)
		{
			currWave.objectives.Remove(o);
		}
	}

	private void OnObjectiveCompleted(AIUnitControlSystem.Objective o)
	{
		if (currWave != null)
		{
			currWave.objectives.Remove(o);
		}
	}

	private void AddObjectives(List<AIUnitControlSystem.Objective> objectives)
	{
		Building building = null;
		int landmass = -1;
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			LandmassOwner landmassOwner = World.GetLandmassOwner(i);
			if (landmassOwner != null && landmassOwner.teamId == targetTeamId)
			{
				ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(i, World.keepHash);
				if (buildingListForLandMass.Count > 0)
				{
					building = buildingListForLandMass.data[0];
					landmass = i;
					break;
				}
			}
		}
		ArrayExt<Cell> landings = Kingdom.unitControl.GetLandings(landmass);
		Cell nearestLanding = Kingdom.unitControl.GetNearestLanding(landings, building.Center());
		List<Cell> list = new List<Cell>();
		bool[] array = new bool[World.inst.GridWidth * World.inst.GridHeight];
		int num = objectiveAmount;
		list.Add(nearestLanding);
		while (list.Count > 0 && num > 0)
		{
			Cell cell = list[0];
			list.RemoveAt(0);
			int num2 = cell.z * World.inst.GridWidth + cell.x;
			if (!array[num2])
			{
				if (cell.OccupyingStructure.Count > 0 && !SiegeMonster.ShouldIgnore(cell.OccupyingStructure[0]) && (!cell.StructureCompareCategory(World.castleblockHash) || cell.StructureCompareCategoryNameAll(World.projectileTopperHash)))
				{
					AIUnitControlSystem.Objective objective = new AIUnitControlSystem.Objective
					{
						type = AIUnitControlSystem.ObjectiveType.DestroyBuilding,
						target = cell.OccupyingStructure[0]
					};
					Kingdom.unitControl.AddObjective(objective);
					objectives.Add(objective);
					num--;
				}
				if (!cell.deepWater)
				{
					list.Add(World.inst.GetCellData(cell.x + 1, cell.z));
					list.Add(World.inst.GetCellData(cell.x, cell.z + 1));
					list.Add(World.inst.GetCellData(cell.x - 1, cell.z));
					list.Add(World.inst.GetCellData(cell.x, cell.z - 1));
				}
				array[num2] = true;
			}
		}
	}
}
