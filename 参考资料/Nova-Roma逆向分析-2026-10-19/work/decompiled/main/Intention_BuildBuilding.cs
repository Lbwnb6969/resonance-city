using System.Collections.Generic;
using UnityEngine;

public class Intention_BuildBuilding : AIIntentionBase
{
	private Intention_WaitForClearOfBuildings waitForBuildingClearIntention;

	private List<Intention_ChopTileWood> clearWoodIntentions = new List<Intention_ChopTileWood>();

	private Intention_CaptureResource captureResourceIntention;

	public Building pendingBuilding;

	public bool initSuccess;

	private AIBuildingBlockType blockType;

	private Vector3 idealPosition;

	public bool PlaceNewBlockIfNeeded = true;

	private Timer updateTimer = new Timer(2f);

	private int checkRadius = 100;

	public bool ReservedForMission { get; private set; }

	public void ReserveForMission()
	{
		if (!ReservedForMission && captureResourceIntention != null)
		{
			captureResourceIntention.Ignore = true;
		}
		ReservedForMission = true;
	}

	public void UnreserveForMission()
	{
		if (ReservedForMission && captureResourceIntention != null)
		{
			captureResourceIntention.Ignore = false;
		}
		ReservedForMission = false;
	}

	public void Init(string uniqueName, AIBuildingBlockType blockType, Vector3 idealPosition, int checkRadius = 100)
	{
		this.blockType = blockType;
		this.idealPosition = idealPosition;
		this.checkRadius = checkRadius;
		if (pendingBuilding == null)
		{
			pendingBuilding = Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(uniqueName));
		}
		pendingBuilding.SetUpHashes();
		pendingBuilding.gameObject.SetActive(value: false);
		updateTimer.CurrTime = SRand.Range(0f, updateTimer.Duration);
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
		pendingBuilding.BakeBoundingFootprint();
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
			if (!initSuccess)
			{
				AILayoutBlock placedBlock = null;
				initSuccess = Layout.FitBuildingIntoBlockType(pendingBuilding, blockType, (int)idealPosition.x, (int)idealPosition.z, checkRadius);
				if (!initSuccess)
				{
					if (PlaceNewBlockIfNeeded && Layout.PlaceNewBlockOfType(pendingBuilding, blockType, (int)idealPosition.x, (int)idealPosition.z, out placedBlock))
					{
						initSuccess = Layout.FitBuildingIntoBlock(pendingBuilding, blockType, placedBlock);
					}
					if (!initSuccess)
					{
						failType = FailType.LayoutBlockOutOfSpace;
						Done = true;
						return;
					}
				}
				if (initSuccess)
				{
					CompleteInit();
				}
			}
			if (ReservedForMission)
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
			if (flag && captureResourceIntention == null)
			{
				captureResourceIntention = AddSubIntention<Intention_CaptureResource>("get resources for building");
				captureResourceIntention.Init(pendingBuilding.GetCost(LandMass));
			}
			if (flag)
			{
				Intention_CaptureResource intention_CaptureResource = captureResourceIntention;
				if ((object)intention_CaptureResource != null && intention_CaptureResource.ResourceCollected && !pendingBuilding.gameObject.activeSelf)
				{
					if (pendingBuilding.size.x == pendingBuilding.size.z)
					{
						float angle = SRand.Range(0, 3) * 90;
						GameUI.inst.RotateBuilding(pendingBuilding, angle);
					}
					pendingBuilding.gameObject.SetActive(value: true);
					World.inst.PlaceByAI(pendingBuilding);
					captureResourceIntention.Done = true;
					ResetDevelopmentMetaData(pendingBuilding);
				}
			}
			if (pendingBuilding != null && pendingBuilding.IsPlaced() && pendingBuilding.IsBuilt())
			{
				Done = true;
			}
		}
	}

	private void OnDisable()
	{
		if (pendingBuilding != null && !pendingBuilding.IsPlaced())
		{
			ResetDevelopmentMetaData(pendingBuilding);
			Object.Destroy(pendingBuilding.gameObject);
		}
	}

	public void ResetDevelopmentMetaData(Building pendingBuilding)
	{
		if (!initSuccess)
		{
			return;
		}
		pendingBuilding.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			AICell aICell = Layout.GetAICell(x, z);
			if (aICell?.buildingMeta != null)
			{
				aICell.buildingMeta.inDevelopment = false;
			}
		});
	}
}
