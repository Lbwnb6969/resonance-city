using System.Collections.Generic;
using UnityEngine;

public class Intention_BuildDrawbridges : AIIntentionBase
{
	private Intention_BuildExactBuilding buildIntention;

	private FloodFillCrawler flood = new FloodFillCrawler();

	private Building drawbridge;

	private bool hasDrawBridge;

	private Cell startCell;

	private Cell[] scratchCells4 = new Cell[4];

	private Cell[] neighborsScratchCells4 = new Cell[4];

	private AICell[] scratchAICells4 = new AICell[4];

	private bool[] isBridge = new bool[4];

	private int angle;

	private List<Cell> drawBridgeSet = new List<Cell>(8);

	private Cell tempCell;

	private bool VisitCell(Cell cell, ref List<Cell> openSet)
	{
		if (Layout.GetAICell(cell).Road)
		{
			if (cell.Type == TerrainType.Water)
			{
				hasDrawBridge = cell.StructureFind(World.drawBridgeHash) != null;
				if (!hasDrawBridge && CheckForDrawbridge(cell))
				{
					if (Kingdom.CurrentResources >= drawbridge.GetCost(LandMass))
					{
						buildIntention = AddSubIntention<Intention_BuildExactBuilding>("build drawbridge");
						buildIntention.Init(World.drawBridgeName, cell.Position, angle, demoExisting: true);
					}
				}
				else if (hasDrawBridge && !CheckForDrawbridge(cell))
				{
					buildIntention = AddSubIntention<Intention_BuildExactBuilding>("build bridge");
					buildIntention.Init(World.bridgeName, cell.Position, 0f, demoExisting: true);
				}
			}
			flood.AddNonDeepWaterCardinalToOpenSet(cell);
			return true;
		}
		return false;
	}

	public void Init()
	{
		drawbridge = GameState.inst.GetPlaceableByUniqueName(World.drawBridgeName);
		startCell = World.inst.FindMatchingSurroundingCell(World.inst.GetCellDataClamped(Layout.KingdomStart), testOrigin: false, 100, (Cell c) => Layout.GetAICell(c)?.Road ?? false);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 90;
		KillAndNullFinishedIntention(ref buildIntention);
		if (buildIntention != null)
		{
			return;
		}
		if (startCell == null || !Layout.GetAICell(startCell).Road)
		{
			startCell = World.inst.FindMatchingSurroundingCell(World.inst.GetCellDataClamped(Layout.KingdomStart), testOrigin: false, 10, (Cell c) => Layout.GetAICell(c)?.Road ?? false);
		}
		else
		{
			flood.Tick(startCell.Position, VisitCell);
		}
	}

	public bool CheckForDrawbridge(Cell targetCell)
	{
		angle = 0;
		drawBridgeSet.Clear();
		if (!CanPlaceDrawbridge(targetCell))
		{
			return false;
		}
		if (isBridge[0] && isBridge[2])
		{
			AddDrawbridgeNeighbors(targetCell.Position, Vector3.right);
			drawBridgeSet.Add(targetCell);
			AddDrawbridgeNeighbors(targetCell.Position, Vector3.left);
			if (drawBridgeSet.Count <= 2)
			{
				angle = ((drawBridgeSet[0] == targetCell) ? 90 : (-90));
				return true;
			}
			int num = Mathf.CeilToInt((float)drawBridgeSet.Count / 2f);
			if (drawBridgeSet[num] == targetCell)
			{
				angle = -90;
				return true;
			}
			if (drawBridgeSet[num - 1] == targetCell)
			{
				angle = 90;
				return true;
			}
		}
		if (isBridge[1] && isBridge[3])
		{
			AddDrawbridgeNeighbors(targetCell.Position, Vector3.forward);
			drawBridgeSet.Add(targetCell);
			AddDrawbridgeNeighbors(targetCell.Position, Vector3.back);
			if (drawBridgeSet.Count <= 2)
			{
				angle = ((drawBridgeSet[0] != targetCell) ? 180 : 0);
				return true;
			}
			int num2 = Mathf.CeilToInt((float)drawBridgeSet.Count / 2f);
			if (drawBridgeSet[num2] == targetCell)
			{
				angle = 180;
				return true;
			}
			if (drawBridgeSet[num2 - 1] == targetCell)
			{
				angle = 0;
				return true;
			}
		}
		return false;
	}

	private void AddDrawbridgeNeighbors(Vector3 origPos, Vector3 dirPos)
	{
		origPos += dirPos;
		tempCell = World.inst.GetCellData(origPos);
		while (CanPlaceDrawbridge(tempCell))
		{
			drawBridgeSet.Add(tempCell);
			origPos += dirPos;
			tempCell = World.inst.GetCellData(origPos);
		}
	}

	private bool CanPlaceDrawbridge(Cell targetCell)
	{
		World.inst.GetNeighborCells(targetCell, ref scratchCells4);
		Layout.GetNeighborAICells(Layout.GetAICell(targetCell), ref scratchAICells4);
		if (targetCell.Type != TerrainType.Water)
		{
			return false;
		}
		for (int i = 0; i < scratchCells4.Length; i++)
		{
			if (scratchCells4[i] != null)
			{
				isBridge[i] = scratchAICells4[i].Road && (bool)scratchCells4[i].StructureFindByCategory(World.pathHash);
			}
			else
			{
				isBridge[i] = false;
			}
			if (scratchCells4[i] == null || scratchCells4[i].Type != TerrainType.Water || scratchAICells4[i].Road)
			{
				continue;
			}
			int num = 0;
			World.inst.GetNeighborCells(scratchCells4[i], ref neighborsScratchCells4);
			for (int j = 0; j < neighborsScratchCells4.Length; j++)
			{
				if (neighborsScratchCells4[j] != null && neighborsScratchCells4[j].Type == TerrainType.Water && neighborsScratchCells4[j].SubStructure.Count == 0 && neighborsScratchCells4[j].OccupyingStructure.Count == 0 && !Layout.GetAICell(neighborsScratchCells4[i]).Road)
				{
					num++;
				}
			}
			if (num < 1)
			{
				return false;
			}
		}
		if (isBridge[0] && isBridge[2] && IsEmptyWaterCell(scratchCells4[1]) && IsEmptyWaterCell(scratchCells4[3]))
		{
			return true;
		}
		if (isBridge[1] && isBridge[3] && IsEmptyWaterCell(scratchCells4[0]) && IsEmptyWaterCell(scratchCells4[2]))
		{
			return true;
		}
		return false;
	}

	private bool IsEmptyWaterCell(Cell cell)
	{
		Layout.GetAICell(cell);
		if ((bool)cell.StructureFind(World.dockHash) || (bool)cell.StructureFind(World.fishinghutHash) || (bool)cell.StructureFind(World.seagateHash) || (bool)cell.StructureFind(World.shipHash))
		{
			return true;
		}
		if (cell.Type == TerrainType.Water)
		{
			return cell.OccupyingStructure.Count == 0;
		}
		return false;
	}
}
