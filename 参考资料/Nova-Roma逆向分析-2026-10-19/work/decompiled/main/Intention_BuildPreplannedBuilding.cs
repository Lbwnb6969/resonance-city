using System;
using System.Collections.Generic;
using UnityEngine;

public class Intention_BuildPreplannedBuilding : AIIntentionBase
{
	public enum MetaBuildingSearchType
	{
		First,
		Closest
	}

	public bool PlaceBlockIfNeeded = true;

	public bool doRoads;

	public bool prioritzeCornerRoads = true;

	public bool unZone;

	private List<Intention_ChopTileWood> clearWoodIntentions = new List<Intention_ChopTileWood>();

	private Intention_CaptureResource captureResourceIntention;

	private Building pendingBuilding;

	private AIBuildingMeta bm;

	private bool initSuccess;

	private MetaBuildingSearchType searchType;

	private string searchName;

	private Vector3 startPos;

	public AIBuildingBlockType blockType;

	[NonSerialized]
	public bool handlingError;

	[NonSerialized]
	public bool placementSuccess = true;

	private AILayoutBlock block;

	public void CompleteInit()
	{
		pendingBuilding.ForEachTileInBounds((int x, int z, Cell c) =>
		{
			Layout.GetAICell(c).buildingMeta.inDevelopment = true;
			Intention_ChopTileWood intention_ChopTileWood = AddSubIntention<Intention_ChopTileWood>("clear wood");
			intention_ChopTileWood.Init(c);
			clearWoodIntentions.Add(intention_ChopTileWood);
		});
		transform.position = pendingBuilding.transform.position;
		pendingBuilding.gameObject.SetActive(value: true);
		pendingBuilding.Init();
		pendingBuilding.gameObject.SetActive(value: false);
		pendingBuilding.BakeBoundingFootprint();
	}

	public bool InitClosest(string uniqueName, Vector3 startPos, AIBuildingBlockType blockType = AIBuildingBlockType.Any)
	{
		searchType = MetaBuildingSearchType.Closest;
		this.startPos = startPos;
		this.blockType = blockType;
		return internalInit(uniqueName);
	}

	public bool InitFastest(string uniqueName, AIBuildingBlockType blockType = AIBuildingBlockType.Any)
	{
		searchType = MetaBuildingSearchType.First;
		startPos = Layout.KingdomStart;
		this.blockType = blockType;
		return internalInit(uniqueName);
	}

	private bool internalInit(string uniqueName)
	{
		searchName = uniqueName;
		if (pendingBuilding == null)
		{
			pendingBuilding = UnityEngine.Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(uniqueName));
		}
		pendingBuilding.SetUpHashes();
		pendingBuilding.gameObject.SetActive(value: false);
		return true;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (pendingBuilding == null)
		{
			Done = true;
			return;
		}
		if (!initSuccess)
		{
			initSuccess = Layout.FitBuildingIntoBuildingMeta(pendingBuilding, blockType, (int)startPos.x, (int)startPos.z);
			if (PlaceBlockIfNeeded && !initSuccess && Layout.PlaceNewBlockContainingUniqueName(pendingBuilding.UniqueName, out block, (int)startPos.x, (int)startPos.z))
			{
				initSuccess = Layout.FitBuildingIntoBlockBuildingMeta(pendingBuilding, block);
			}
			if (!initSuccess)
			{
				failType = FailType.LayoutBlockOutOfSpace;
				done = true;
				return;
			}
			CompleteInit();
			placementSuccess = initSuccess;
		}
		bool flag = true;
		for (int i = 0; i < clearWoodIntentions.Count; i++)
		{
			if (!clearWoodIntentions[i].TileClear)
			{
				flag = false;
			}
		}
		if (flag && captureResourceIntention == null)
		{
			captureResourceIntention = AddSubIntention<Intention_CaptureResource>("get resources for building");
			captureResourceIntention.Init(pendingBuilding.GetCost(LandMass));
		}
		if (captureResourceIntention != null && captureResourceIntention.ResourceCollected && !pendingBuilding.gameObject.activeSelf)
		{
			pendingBuilding.BakeBoundingFootprint();
			pendingBuilding.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
			for (int j = minZ; j <= maxZ; j++)
			{
				for (int k = minX; k <= maxX; k++)
				{
					Cell cellData = World.inst.GetCellData(k, j);
					if (cellData != null && (bool)cellData.StructureFindByCategory(World.castleblockHash))
					{
						while (cellData.TopStructure != null)
						{
							World.inst.DemolishBuildingByAI(cellData.TopStructure);
						}
					}
				}
			}
			pendingBuilding.gameObject.SetActive(value: true);
			World.inst.PlaceByAI(pendingBuilding);
			captureResourceIntention.Done = true;
			if (doRoads)
			{
				Layout.BuildOutRoad(pendingBuilding, this, prioritzeCornerRoads);
			}
			if (unZone && block != null)
			{
				Layout.UnplaceBlock(block);
			}
		}
		if (pendingBuilding != null && pendingBuilding.IsPlaced() && pendingBuilding.IsBuilt())
		{
			Done = true;
		}
	}

	private void OnDisable()
	{
		if (pendingBuilding != null && !pendingBuilding.IsPlaced())
		{
			UnityEngine.Object.Destroy(pendingBuilding.gameObject);
		}
	}
}
