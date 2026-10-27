using System.Collections.Generic;
using UnityEngine;

public class Intention_BuildRoadTile : AIIntentionBase
{
	private Intention_CaptureResource captureResourceIntention;

	private Intention_ChopTileWood chopTileIntention;

	private Intention_BuildExactBuilding gateIntention;

	private Cell targetCell;

	private AICell targetAICell;

	private Building pendingBuilding;

	private Timer shipDetectTimer = new Timer(3f);

	public void Init(Cell cell)
	{
		targetCell = cell;
		targetAICell = Layout.GetAICell(cell);
		transform.position = targetCell.Center2D;
		chopTileIntention = AddSubIntention<Intention_ChopTileWood>("clear wood");
		chopTileIntention.Init(cell);
		shipDetectTimer.ForceExpire();
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (pendingBuilding != null && (targetCell.StructureCompareCategoryNameAll(World.pathHash) || (targetAICell?.buildingMeta != null && targetAICell.buildingMeta.uniqueName == World.gardenName)))
		{
			Object.Destroy(pendingBuilding.gameObject);
			Done = true;
			return;
		}
		if (chopTileIntention.TileClear && targetCell.StructureCompareCategoryNameAll(World.castleblockHash) && Layout.CellNeedsGate(targetCell, out var angle))
		{
			string uniqueName = "";
			List<Building> occupyingStructure = targetCell.OccupyingStructure;
			for (int num = occupyingStructure.Count - 1; num >= 0; num--)
			{
				if (occupyingStructure[num].categoryHash == World.castleblockHash)
				{
					if (occupyingStructure[num].uniqueNameHash == World.woodcastleblockHash)
					{
						uniqueName = "woodengate";
					}
					if (occupyingStructure[num].uniqueNameHash == World.castleblockHash)
					{
						uniqueName = "gate";
					}
				}
				if (occupyingStructure[num].categoryHash == World.castleblockHash || occupyingStructure[num].categoryHash == World.projectileTopperHash)
				{
					World.inst.DemolishBuildingByAI(occupyingStructure[num]);
				}
			}
			gateIntention = AddSubIntention<Intention_BuildExactBuilding>("build gate");
			gateIntention.Init(uniqueName, targetCell.Position, angle);
		}
		if (chopTileIntention.TileClear && (gateIntention == null || gateIntention.Done) && pendingBuilding == null)
		{
			if (targetCell.Type == TerrainType.Water)
			{
				pendingBuilding = Object.Instantiate(GameState.inst.GetPlaceableByUniqueName("bridge"));
			}
			else
			{
				pendingBuilding = Object.Instantiate(GameState.inst.GetPlaceableByUniqueName("road"));
			}
			pendingBuilding.gameObject.SetActive(value: false);
			pendingBuilding.transform.position = new Vector3(targetCell.x, -10f, targetCell.z);
			pendingBuilding.Init();
		}
		if (pendingBuilding != null && captureResourceIntention == null && World.inst.CanPlace(pendingBuilding, ignoreLandMassChecks: true) == PlacementValidationResult.Valid)
		{
			captureResourceIntention = AddSubIntention<Intention_CaptureResource>("get road build cost");
		}
		if (captureResourceIntention != null && captureResourceIntention.ResourceCollected)
		{
			bool flag = true;
			if (targetCell.Type == TerrainType.Water)
			{
				if (shipDetectTimer.Update(dt))
				{
					ArrayExt<ShipBase> ships = ShipSystem.inst.ships;
					for (int i = 0; i < ships.Count; i++)
					{
						if (Mathff.DistSqrd(targetCell.Position, ships.data[i].GetPos()) < 4f)
						{
							flag = false;
							break;
						}
					}
					if (flag && IsShipConstructionNearby(targetCell.Position, World.troopTransportShipHash))
					{
						flag = false;
					}
					if (flag && IsShipConstructionNearby(targetCell.Position, World.playerMerchantShipHash))
					{
						flag = false;
					}
					if (flag && IsShipConstructionNearby(targetCell.Position, World.transportShipHash))
					{
						flag = false;
					}
				}
				else
				{
					flag = false;
				}
			}
			if (flag)
			{
				pendingBuilding.gameObject.SetActive(value: true);
				pendingBuilding.transform.position = new Vector3(targetCell.x, 0f, targetCell.z);
				World.inst.PlaceByAI(pendingBuilding);
				captureResourceIntention.Done = true;
				Done = true;
			}
		}
		KillAndNullFinishedIntention(ref gateIntention);
	}

	private bool IsShipConstructionNearby(Vector3 pos, int hash)
	{
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, hash);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			if (Mathff.DistSqrd(pos, buildingListForLandMass.data[i].GetPos()) < 4f)
			{
				return true;
			}
		}
		return false;
	}
}
