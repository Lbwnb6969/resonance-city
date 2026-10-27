using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets.Code.Interface;
using UnityEngine;

public class GladiatorSchool : Tickable, IWorkerUIDisplay, IOverlayUser, IOutputInfo
{
	[Serializable]
	public class GladiatorSchoolSaveData : SaveClass<GladiatorSchool, GladiatorSchoolSaveData>
	{
		public List<int> gladiatorIds;

		public int currentSlots;

		public List<TrainingAssignment.TrainingAssignmentSaveData> activeTrainingData;

		public override GladiatorSchoolSaveData Pack(GladiatorSchool obj)
		{
			gladiatorIds = new List<int>(obj.gladiatorIds);
			currentSlots = obj.currentSlots;
			activeTrainingData = new List<TrainingAssignment.TrainingAssignmentSaveData>(obj.activeTraining.Count);
			foreach (KeyValuePair<int, TrainingAssignment> item in obj.activeTraining)
			{
				activeTrainingData.Add(new TrainingAssignment.TrainingAssignmentSaveData().Pack(item.Value));
			}
			return this;
		}

		public override GladiatorSchool Unpack(GladiatorSchool obj)
		{
			obj.gladiatorIds = ((gladiatorIds != null) ? new List<int>(gladiatorIds) : new List<int>());
			obj.currentSlots = currentSlots;
			obj.activeTraining.Clear();
			if (activeTrainingData != null)
			{
				foreach (TrainingAssignment.TrainingAssignmentSaveData activeTrainingDatum in activeTrainingData)
				{
					TrainingAssignment trainingAssignment = new TrainingAssignment();
					activeTrainingDatum.Unpack(trainingAssignment);
					obj.activeTraining[trainingAssignment.gladiatorId] = trainingAssignment;
				}
			}
			return obj;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			gladiatorIds = new List<int>();
			currentSlots = 3;
			activeTrainingData = new List<TrainingAssignment.TrainingAssignmentSaveData>();
		}
	}

	private Building b;

	[SerializeField]
	private GameObject[] animObjs;

	public Transform arenaCenter;

	[Header("Capacity")]
	[SerializeField]
	private int baseSlots = 3;

	[SerializeField]
	private int maxSlots = 10;

	private int currentSlots;

	[Header("Costs")]
	[SerializeField]
	private int recruitCostGold = 200;

	[SerializeField]
	private int slotUpgradeCostGold = 500;

	private List<int> gladiatorIds = new List<int>();

	private Dictionary<int, TrainingAssignment> activeTraining = new Dictionary<int, TrainingAssignment>();

	public bool overlayWhenPlacing = true;

	public bool overlayWhenSelected = true;

	public int barracksBonusSkillReq = 20;

	public float Radius = 5f;

	private static int gladiatorSchoolHash = "gladiatorschool".GetHashCode();

	public Color overlayColor;

	bool IOverlayUser.OverlayWhenPlacing => overlayWhenPlacing;

	bool IOverlayUser.OverlayWhenSelected => overlayWhenSelected;

	private void Awake()
	{
		b = GetComponent<Building>();
		currentSlots = baseSlots;
	}

	private void Start()
	{
		if (GladiatorSystem.inst != null)
		{
			GladiatorSystem.inst.OnGladiatorRemoved += OnGladiatorRemoved;
		}
	}

	private void OnDestroy()
	{
		if (GladiatorSystem.inst != null)
		{
			GladiatorSystem.inst.OnGladiatorRemoved -= OnGladiatorRemoved;
		}
	}

	private void OnGladiatorRemoved(Gladiator gladiator)
	{
		gladiatorIds.Remove(gladiator.gladiatorId);
		activeTraining.Remove(gladiator.gladiatorId);
	}

	internal bool TrainingBonusAvailable()
	{
		int num = 0;
		for (int i = 0; i < gladiatorIds.Count; i++)
		{
			Gladiator gladiator = GladiatorSystem.inst?.GetGladiator(gladiatorIds[i]);
			num += gladiator.skills.bestiarius;
			num += gladiator.skills.retiarius;
			num += gladiator.skills.bestiarius;
		}
		if (num >= barracksBonusSkillReq)
		{
			return b.GetWorkerPercent() > 0.95f;
		}
		return false;
	}

	private void OnInit()
	{
		b = GetComponent<Building>();
		currentSlots = baseSlots;
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.IdleLooking));
			}
		}
	}

	public void RefreshAnimObjVisibility()
	{
		if (b.IsBuilt())
		{
			SetAnimVisuals(v: true);
		}
		else
		{
			SetAnimVisuals(v: false);
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		RefreshAnimObjVisibility();
		if (undo && !LoadSave.Loading)
		{
			int[] array = gladiatorIds.ToArray();
			foreach (int gladiatorId in array)
			{
				GladiatorSystem.inst?.RemoveGladiator(gladiatorId);
			}
			gladiatorIds.Clear();
			activeTraining.Clear();
		}
	}

	private void OnBuilt()
	{
		SetAnimVisuals(v: true);
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (!b.IsBuilt() || !b.IsOpen())
		{
			return;
		}
		List<int> list = new List<int>();
		foreach (KeyValuePair<int, TrainingAssignment> item in activeTraining)
		{
			item.Value.Tick(dt);
			if (item.Value.IsComplete())
			{
				list.Add(item.Key);
			}
		}
		foreach (int item2 in list)
		{
			CompleteTraining(item2);
		}
		for (int i = 0; i < gladiatorIds.Count; i++)
		{
			Gladiator gladiator = GladiatorSystem.inst?.GetGladiator(gladiatorIds[i]);
			if (IsGladiatorTraining(gladiatorIds[i]) || gladiator.fatigueTier <= 0)
			{
				continue;
			}
			gladiator.fatigueTimer += dt;
			if (gladiator.fatigueTimer > 112f)
			{
				gladiator.fatigueTimer = 0f;
				if (gladiator.fatigueTier > 0)
				{
					gladiator.fatigueTier--;
				}
			}
		}
	}

	public int GetGladiatorCount()
	{
		return gladiatorIds.Count;
	}

	public int GetSlotCount()
	{
		return currentSlots;
	}

	public int GetMaxSlots()
	{
		return maxSlots;
	}

	public bool HasEmptySlot()
	{
		return gladiatorIds.Count < currentSlots;
	}

	public bool CanUpgradeSlots()
	{
		if (currentSlots < maxSlots)
		{
			return HasGoldForUpgrade();
		}
		return false;
	}

	private bool HasGoldForUpgrade()
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
		if (landmassOwner != null)
		{
			return landmassOwner.Gold >= slotUpgradeCostGold;
		}
		return false;
	}

	public bool UpgradeSlots()
	{
		if (!CanUpgradeSlots())
		{
			return false;
		}
		World.GetLandmassOwner(b.LandMass()).Gold -= slotUpgradeCostGold;
		ResourceStatistics.AddConsumption(b.LandMass(), "gold_gladiator_upgrade", 4, slotUpgradeCostGold);
		currentSlots++;
		return true;
	}

	public Gladiator GetGladiator(int i)
	{
		return GladiatorSystem.inst?.GetGladiator(gladiatorIds[i]);
	}

	public bool HasSlotForRecruit()
	{
		if (b.IsBuilt() && b.IsOpen())
		{
			return HasEmptySlot();
		}
		return false;
	}

	public bool CanAffordRecruit(int goldCost)
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
		if (landmassOwner != null)
		{
			return landmassOwner.Gold >= goldCost;
		}
		return false;
	}

	public Gladiator RecruitGladiator(int goldCost)
	{
		if (!HasSlotForRecruit() || !CanAffordRecruit(goldCost))
		{
			return null;
		}
		World.GetLandmassOwner(b.LandMass()).Gold -= goldCost;
		ResourceStatistics.AddConsumption(b.LandMass(), "gold_gladiator_recruit", 4, goldCost);
		Gladiator gladiator = GladiatorSystem.inst.CreateGladiator(b.guid);
		gladiatorIds.Add(gladiator.gladiatorId);
		return gladiator;
	}

	public bool IsGladiatorTraining(int gladiatorId)
	{
		return activeTraining.ContainsKey(gladiatorId);
	}

	public TrainingAssignment GetTrainingAssignment(int gladiatorId)
	{
		activeTraining.TryGetValue(gladiatorId, out var value);
		return value;
	}

	public bool CanStartTraining(int gladiatorId, TrainingCourse course)
	{
		if (!b.IsBuilt() || !b.IsOpen())
		{
			return false;
		}
		if (!gladiatorIds.Contains(gladiatorId))
		{
			return false;
		}
		if (IsGladiatorTraining(gladiatorId))
		{
			return false;
		}
		Gladiator gladiator = GladiatorSystem.inst?.GetGladiator(gladiatorId);
		if (gladiator == null || !gladiator.CanTrain())
		{
			return false;
		}
		LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
		if (landmassOwner == null || landmassOwner.Gold < course.goldCost)
		{
			return false;
		}
		return true;
	}

	public bool StartTraining(int gladiatorId, TrainingCourse course)
	{
		if (!CanStartTraining(gladiatorId, course))
		{
			return false;
		}
		GladiatorSystem.inst.GetGladiator(gladiatorId);
		World.GetLandmassOwner(b.LandMass()).Gold -= course.goldCost;
		ResourceStatistics.AddConsumption(b.LandMass(), "gold_gladiator_training", 4, course.goldCost);
		TrainingAssignment value = new TrainingAssignment(gladiatorId, course);
		activeTraining[gladiatorId] = value;
		return true;
	}

	public bool CancelTraining(int gladiatorId)
	{
		if (!activeTraining.TryGetValue(gladiatorId, out var _))
		{
			return false;
		}
		activeTraining.Remove(gladiatorId);
		return true;
	}

	private void CompleteTraining(int gladiatorId)
	{
		if (!activeTraining.TryGetValue(gladiatorId, out var value))
		{
			return;
		}
		Gladiator gladiator = GladiatorSystem.inst?.GetGladiator(gladiatorId);
		if (gladiator == null)
		{
			activeTraining.Remove(gladiatorId);
			return;
		}
		TrainingCourse trainingCourse = GladiatorSystem.inst.GetTrainingCourse(value.courseId);
		if (trainingCourse != null)
		{
			gladiator.fatigueTier = Mathf.Min(5, gladiator.fatigueTier + trainingCourse.fatigueGain);
			if (trainingCourse.skillTargets != null && trainingCourse.skillGains != null)
			{
				int num = Mathf.Min(trainingCourse.skillTargets.Length, trainingCourse.skillGains.Length);
				for (int i = 0; i < num; i++)
				{
					gladiator.skills.AddSkill(trainingCourse.skillTargets[i], trainingCourse.skillGains[i]);
				}
			}
			gladiator.fame = Mathf.Clamp(gladiator.fame + trainingCourse.fameGain, 0, 5);
			if (trainingCourse.injuryRisk > 0f && UnityEngine.Random.value < trainingCourse.injuryRisk)
			{
				gladiator.fatigueTier = Mathf.Min(5, gladiator.fatigueTier + 1);
			}
		}
		activeTraining.Remove(gladiatorId);
	}

	public void SetAnimVisuals(bool v)
	{
		for (int i = 0; i < animObjs.Length; i++)
		{
			Util.SetActive(animObjs[i], v);
		}
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}

	private static void DrawIndividual(GladiatorSchool m)
	{
		Building building = m.b;
		Vector3 pos = building.Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, m.Radius, (int x, int z, Cell cell) =>
		{
			if (Mathff.DistSqrdXZ(pos, cell.Center2D) <= m.Radius * m.Radius)
			{
				TerrainGen.inst.SetOverlayTileColorNoBuilding(x, z, m.overlayColor);
				for (int i = 0; i < cell.OccupyingStructure.Count; i++)
				{
					if (cell.OccupyingStructure[i].uniqueNameHash != gladiatorSchoolHash)
					{
						cell.OccupyingStructure[i].SetInfoColor(m.overlayColor);
						TerrainGen.inst.AddBuildingToOverlay(cell.OccupyingStructure[i]);
					}
				}
			}
		});
	}

	void IOverlayUser.DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.ClearOverlay(updateToo: false);
		int focusedLandMass = Player.inst.FocusedLandMass;
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(focusedLandMass, gladiatorSchoolHash);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			DrawIndividual(buildingListForLandMass.data[i].GetComponent<GladiatorSchool>());
		}
		if (!b.IsPlaced())
		{
			DrawIndividual(this);
		}
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	public string GetError()
	{
		return "";
	}
}
