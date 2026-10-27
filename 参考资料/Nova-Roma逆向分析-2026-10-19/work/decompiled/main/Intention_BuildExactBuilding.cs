using System.Collections.Generic;
using UnityEngine;

public class Intention_BuildExactBuilding : AIIntentionBase
{
	private List<Intention_ChopTileWood> clearWoodIntentions = new List<Intention_ChopTileWood>();

	private Intention_CaptureResource captureResourceIntention;

	private Building pendingBuilding;

	private bool demoExisting;

	private int[] demoIgnoreList;

	private bool initSuccess;

	private Vector3 position;

	private Quaternion rotation;

	private Timer updateTimer = new Timer(2f);

	private bool readyForBuilding = true;

	public Building GetPendingBuilding()
	{
		return pendingBuilding;
	}

	public void MaybeDemo()
	{
		if (!demoExisting)
		{
			return;
		}
		pendingBuilding.BakeBoundingFootprint();
		pendingBuilding.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				Cell cellData = World.inst.GetCellData(j, i);
				if (cellData == null)
				{
					continue;
				}
				if ((bool)cellData.StructureFind(World.quarryHash) || (bool)cellData.StructureFind(World.foresterHash) || (bool)cellData.StructureFind(World.ironMineHash) || (bool)cellData.StructureFind(World.dockHash) || (bool)cellData.StructureFind(World.noriaHash) || (bool)cellData.StructureFind(World.keepHash))
				{
					break;
				}
				for (int num = cellData.OccupyingStructure.Count - 1; num >= 0; num--)
				{
					if (demoIgnoreList != null)
					{
						bool flag = false;
						for (int k = 0; k < demoIgnoreList.Length; k++)
						{
							if (demoIgnoreList[k] == cellData.OccupyingStructure[num].uniqueNameHash)
							{
								flag = true;
							}
						}
						if (!flag)
						{
							if (!World.inst.DemolishBuildingByAI(cellData.OccupyingStructure[num]))
							{
								break;
							}
							num = cellData.OccupyingStructure.Count;
						}
					}
					else
					{
						if (!World.inst.DemolishBuildingByAI(cellData.OccupyingStructure[num]))
						{
							break;
						}
						num = cellData.OccupyingStructure.Count;
					}
				}
			}
		}
	}

	public bool Init(string uniqueName, Vector3 position, float angle = 0f, bool demoExisting = false, bool skipPlacementValidation = false, int[] demoIgnoreList = null)
	{
		this.demoExisting = demoExisting;
		this.demoIgnoreList = demoIgnoreList;
		if (pendingBuilding == null)
		{
			pendingBuilding = Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(uniqueName));
		}
		pendingBuilding.SetUpHashes();
		pendingBuilding.transform.position = position;
		GameUI.inst.RotateBuilding(pendingBuilding, angle);
		MaybeDemo();
		if ((!skipPlacementValidation && World.inst.CanPlace(pendingBuilding, ignoreLandMassChecks: true, allowBuildOverForest: true) != PlacementValidationResult.Valid) || World.inst.GetCellDataClamped(position).landMassIdx != LandMass)
		{
			Debug.LogError("BuildExactBuilding() - Didn't pass validation for building " + pendingBuilding.FriendlyName);
			Done = true;
			Object.Destroy(pendingBuilding.gameObject);
			pendingBuilding = null;
			return false;
		}
		CompleteInit();
		pendingBuilding.gameObject.SetActive(value: false);
		return initSuccess;
	}

	public void AddChopToCell(int x, int z, Cell c)
	{
		AICell aICell = Layout.GetAICell(c);
		if (aICell.buildingMeta != null)
		{
			aICell.buildingMeta.inDevelopment = true;
		}
		Intention_ChopTileWood intention_ChopTileWood = AddSubIntention<Intention_ChopTileWood>("clear wood");
		intention_ChopTileWood.Init(c);
		clearWoodIntentions.Add(intention_ChopTileWood);
	}

	public void CompleteInit()
	{
		pendingBuilding.ForEachTileInBounds(AddChopToCell);
		transform.position = pendingBuilding.transform.position;
		pendingBuilding.gameObject.SetActive(value: true);
		pendingBuilding.Init();
		pendingBuilding.gameObject.SetActive(value: false);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (pendingBuilding == null)
		{
			Done = true;
		}
		else
		{
			if (!updateTimer.Update(dt))
			{
				return;
			}
			bool flag = true;
			for (int i = 0; i < clearWoodIntentions.Count; i++)
			{
				if (!clearWoodIntentions[i].TileClear)
				{
					flag = false;
				}
			}
			if (flag && readyForBuilding && captureResourceIntention == null)
			{
				captureResourceIntention = AddSubIntention<Intention_CaptureResource>("get resources for building");
				captureResourceIntention.Init(pendingBuilding.GetCost(LandMass));
			}
			if (captureResourceIntention != null && captureResourceIntention.ResourceCollected && !pendingBuilding.gameObject.activeSelf)
			{
				MaybeDemo();
				pendingBuilding.gameObject.SetActive(value: true);
				World.inst.PlaceByAI(pendingBuilding);
				captureResourceIntention.Done = true;
			}
			if (pendingBuilding != null && pendingBuilding.IsPlaced() && pendingBuilding.IsBuilt())
			{
				Done = true;
			}
		}
	}

	public void ReadyForBuilding(bool ready)
	{
		readyForBuilding = ready;
	}

	public bool? IsPlaced()
	{
		return pendingBuilding?.IsPlaced();
	}

	private void OnDisable()
	{
		if (pendingBuilding != null && !pendingBuilding.IsPlaced())
		{
			Object.Destroy(pendingBuilding.gameObject);
		}
	}
}
