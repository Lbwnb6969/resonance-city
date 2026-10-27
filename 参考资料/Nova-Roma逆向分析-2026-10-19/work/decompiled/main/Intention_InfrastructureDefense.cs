using System;
using System.Collections.Generic;
using UnityEngine;

public class Intention_InfrastructureDefense : AIIntentionBase
{
	[Serializable]
	public class InfrastructureDefenseSaveData : SaveClass<Intention_InfrastructureDefense, InfrastructureDefenseSaveData>
	{
		public int nearbyPTUniqueHash;

		public Guid nearbyPTGuid;

		public override InfrastructureDefenseSaveData Pack(Intention_InfrastructureDefense v)
		{
			if (v.nearbyPT != null)
			{
				nearbyPTGuid = v.nearbyPT.guid;
				nearbyPTUniqueHash = v.nearbyPT.uniqueNameHash;
			}
			else
			{
				nearbyPTGuid = Guid.Empty;
			}
			return this;
		}

		public override Intention_InfrastructureDefense Unpack(Intention_InfrastructureDefense v)
		{
			if (nearbyPTGuid != Guid.Empty)
			{
				v.DisableTowerModification = true;
				ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(v.LandMass, nearbyPTUniqueHash);
				for (int i = 0; i < buildingListForLandMass.Count; i++)
				{
					if (buildingListForLandMass.data[i].guid == nearbyPTGuid)
					{
						v.nearbyPT = buildingListForLandMass.data[i];
						break;
					}
				}
			}
			return v;
		}
	}

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private EventHandler<OnWolfKillVillager> wolfKillHandler;

	public bool DisableTowerModification;

	private BuildStack buildIntentionStacks = new BuildStack();

	private Building nearbyPT;

	public int[] roadHashes = new int[2]
	{
		World.roadHash,
		World.stoneRoadHash
	};

	public int[] aqueductHashes = new int[1] { World.aqueductHash };

	private bool isWolfMissionActive;

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		wolfKillHandler = Broadcast.WolfKillVillagerEvent.Listen(OnWolfKillVillager);
		World.inst.OnWolfDenCleared += OnWolfDenDestroyed;
		priority = 66;
	}

	private void OnWolfDenDestroyed(int landmassIdx, int teamID)
	{
		if (nearbyPT != null && landmassIdx == LandMass)
		{
			ResetBuildings(nearbyPT.uniqueNameHash);
			DisableTowerModification = false;
			nearbyPT = null;
		}
	}

	private void OnWolfKillVillager(object sender, OnWolfKillVillager obj)
	{
		if (obj.teamID != LandmassOwner.teamId || nearbyPT != null || isWolfMissionActive)
		{
			return;
		}
		if (buildIntentionStacks.available)
		{
			priority = Mathf.Min(75, priority + 5);
		}
		Cell targetCell = null;
		Vector3 center2D = World.inst.GetCellData(obj.eventPosition).Center2D;
		if (!IsArcherTowerNearby(center2D, ref targetCell) && buildIntentionStacks.available)
		{
			TrySetupTowerAtPosition(center2D);
		}
		else
		{
			if (targetCell == null)
			{
				return;
			}
			nearbyPT = targetCell.StructureFindByCategory(World.projectileTopperHash);
			if (!(nearbyPT != null) || JobSystem.inst.IsCategoryOpen(LandMass, nearbyPT.jobCategory))
			{
				return;
			}
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, nearbyPT.uniqueNameHash);
			JobSystem.inst.SetCategoryOpen(LandMass, nearbyPT.jobCategory, isOpen: true);
			if (buildingListForLandMass != null)
			{
				DisableTowerModification = true;
				for (int i = 0; i < buildingListForLandMass.Count; i++)
				{
					buildingListForLandMass.data[i].Open = nearbyPT == buildingListForLandMass.data[i];
				}
			}
		}
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() != LandMass || !obj.added)
		{
			return;
		}
		if (SeasonManager.inst.CurrentYear() > 15 && buildIntentionStacks.available)
		{
			Cell targetCell = null;
			Vector3 vector = obj.targetBuilding.Center();
			if (!IsArcherTowerNearby(vector, ref targetCell))
			{
				TrySetupTowerAtPosition(vector);
			}
		}
		if (obj.targetBuilding.uniqueNameHash == World.archerTowerHash)
		{
			obj.targetBuilding.Open = !isWolfMissionActive && nearbyPT == null;
		}
	}

	private bool IsArcherTowerNearby(Vector3 pos, ref Cell targetCell)
	{
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.archerTowerHash);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			float ballisticMaxRange = buildingListForLandMass.data[i].GetComponent<ArcherTower>().GetBallisticMaxRange();
			if (Mathff.DistSqrdXZ(buildingListForLandMass.data[i].cachedPos, pos) < ballisticMaxRange * ballisticMaxRange * 0.95f)
			{
				targetCell = buildingListForLandMass.data[i].GetCell();
				return true;
			}
		}
		return false;
	}

	private void TrySetupTowerAtPosition(Vector3 cellCenter)
	{
		Cell cell = World.inst.FindMatchingSurroundingCell(cellCenter, testOrigin: false, 5, (Cell c) =>
		{
			AICell aICell = Layout.GetAICell(c);
			DefenseCell defenceCell = Layout.GetDefenceCell(c);
			return (c.OccupyingStructure.Count == 0 && c.Type == TerrainType.None && c.landMassIdx == LandMass && !aICell.Road && !aICell.invalid && (aICell.buildingMeta == null || (aICell.buildingMeta.uniqueName == string.Empty && !aICell.buildingMeta.inDevelopment && (aICell.buildingMeta.type == AIBuildingBlockType.Civic || aICell.buildingMeta.type == AIBuildingBlockType.Residential))) && !defenceCell.CastleEdge) ? true : false;
		});
		if (cell != null)
		{
			TrySetupTowerAtCell(cell);
		}
	}

	private void ResetBuildings(int hash)
	{
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, hash);
		if (buildingListForLandMass != null)
		{
			for (int i = 0; i < buildingListForLandMass.Count; i++)
			{
				buildingListForLandMass.data[i].Open = true;
			}
		}
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
		Broadcast.WolfKillVillagerEvent.Unlisten(wolfKillHandler);
		World.inst.OnWolfDenCleared -= OnWolfDenDestroyed;
	}

	private void TrySetupTowerAtCell(Cell c)
	{
		if (buildIntentionStacks.available && c != null && (c.Type == TerrainType.None || c.Type == TerrainType.Water))
		{
			bool demoExisting = false;
			int num = 1;
			int i = 0;
			string woodengateName = World.woodengateName;
			string woodcastleblockName = World.woodcastleblockName;
			float num2 = 0f;
			if (c.Type == TerrainType.Water && c.StructureFind(World.pierHash) == null && !c.deepWater)
			{
				buildIntentionStacks.available = false;
				buildIntentionStacks.intentionStack[i] = AddSubIntention<Intention_BuildExactBuilding>("build " + World.pierName);
				buildIntentionStacks.intentionStack[i].Init(World.pierName, c.Position, 0f, demoExisting);
				buildIntentionStacks.intentionStack[i].ReadyForBuilding(ready: false);
				demoExisting = false;
				i++;
				num++;
			}
			if (num > 0 && Layout.CellNeedsGate(c, out var angle))
			{
				buildIntentionStacks.available = false;
				buildIntentionStacks.intentionStack[i] = AddSubIntention<Intention_BuildExactBuilding>("build " + woodcastleblockName);
				buildIntentionStacks.intentionStack[i].Init(woodengateName, c.Position + new Vector3(0f, num2, 0f), angle, demoExisting, skipPlacementValidation: true, roadHashes);
				buildIntentionStacks.intentionStack[i].ReadyForBuilding(ready: false);
				demoExisting = false;
				num2 += 1.5f;
				i++;
				num--;
			}
			for (; i < num; i++)
			{
				buildIntentionStacks.available = false;
				buildIntentionStacks.intentionStack[i] = AddSubIntention<Intention_BuildExactBuilding>("build " + woodcastleblockName);
				buildIntentionStacks.intentionStack[i].Init(woodcastleblockName, c.Position + new Vector3(0f, num2, 0f), 0f, demoExisting, skipPlacementValidation: true, aqueductHashes);
				buildIntentionStacks.intentionStack[i].ReadyForBuilding(ready: false);
				demoExisting = false;
				num2 += 0.5f;
			}
			for (int j = 0; j < Kingdom.personality.ExtraHeightForTowers; j++)
			{
				buildIntentionStacks.available = false;
				buildIntentionStacks.intentionStack[i] = AddSubIntention<Intention_BuildExactBuilding>("build " + woodcastleblockName);
				buildIntentionStacks.intentionStack[i].Init(woodcastleblockName, c.Position + new Vector3(0f, num2, 0f), 0f, demoExisting: false, skipPlacementValidation: true, aqueductHashes);
				buildIntentionStacks.intentionStack[i].ReadyForBuilding(ready: false);
				num2 += 0.5f;
				i++;
			}
			if (num2 > 0f)
			{
				buildIntentionStacks.available = false;
				buildIntentionStacks.intentionStack[i] = AddSubIntention<Intention_BuildExactBuilding>("build archer tower");
				buildIntentionStacks.intentionStack[i].Init(World.archerTowerName, c.Position + new Vector3(0f, num2, 0f), 0f, demoExisting: false, skipPlacementValidation: true, aqueductHashes);
				buildIntentionStacks.intentionStack[i].ReadyForBuilding(ready: false);
			}
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (buildIntentionStacks.Update(this))
		{
			priority = 66;
		}
		if (Kingdom.IsWolfMissionPotentialOrActive())
		{
			if (!isWolfMissionActive)
			{
				List<WolfDen> wolfDens = WolfDen.wolfDens;
				for (int i = 0; i < wolfDens.Count; i++)
				{
					Cell cellData = World.inst.GetCellData(wolfDens[i].transform.position);
					if (cellData.landMassIdx == LandMass)
					{
						Cell targetCell = null;
						if (IsArcherTowerNearby(cellData.Position, ref targetCell))
						{
							targetCell.TopStructure.Open = false;
						}
					}
				}
				nearbyPT = null;
				DisableTowerModification = false;
			}
			isWolfMissionActive = true;
		}
		else
		{
			if (isWolfMissionActive)
			{
				ResetBuildings(World.archerTowerHash);
			}
			isWolfMissionActive = false;
		}
		if (!DisableTowerModification)
		{
			bool isOpen = RaiderSystem.inst.IsRaidInProgress() || (DragonSpawn.inst.currentDragons.Count > 0 && Player.inst.HostilesOnLandmass(LandMass).Count > 0);
			JobSystem.inst.SetCategoryOpen(LandMass, 5, isOpen);
			JobSystem.inst.SetCategoryOpen(LandMass, 6, isOpen);
		}
	}
}
