using System.Collections.Generic;

public class Intention_FillShallowWater : AIIntentionBase
{
	private Intention_BuildExactBuilding pierIntention;

	private FloodFillCrawler flood = new FloodFillCrawler();

	private Cell[] scratchCells12 = new Cell[12];

	private bool VisitCell(Cell cell, ref List<Cell> openSet)
	{
		if (cell.Type == TerrainType.Water && !cell.deepWater)
		{
			AICell aICell = Layout.GetAICell(cell);
			AIBuildingMeta buildingMeta = aICell.buildingMeta;
			DefenseCell defenceCell = Layout.GetDefenceCell(cell);
			if (cell.OccupyingStructure.Count == 0 && cell.SubStructure.Count == 0 && !aICell.invalid && buildingMeta != null && !buildingMeta.inDevelopment && buildingMeta.type != AIBuildingBlockType.None && !defenceCell.CastleEdge)
			{
				bool flag = false;
				World.inst.GetNeighborCellsExtendedPlus(cell, ref scratchCells12);
				for (int i = 0; i < scratchCells12.Length; i++)
				{
					if (scratchCells12[i] != null)
					{
						if (scratchCells12[i].deepWater)
						{
							flag = true;
							break;
						}
						if (Layout.GetAICell(scratchCells12[i]).Road && scratchCells12[i].Type == TerrainType.Water)
						{
							flag = true;
							break;
						}
					}
				}
				if (!flag)
				{
					if (pierIntention == null)
					{
						pierIntention = AddSubIntention<Intention_BuildExactBuilding>("build " + World.pierName);
						pierIntention.Init(World.pierName, cell.Position, 0f, demoExisting: true);
					}
					return false;
				}
			}
		}
		flood.AddNonDeepWaterCardinalToOpenSet(cell);
		return true;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 20;
		if (World.inst.GetVillagersForLandMass(LandMass).Count >= 250 && (Kingdom.CurrentResources - Kingdom.lastFrameRequestedResources).Get(2) >= 100)
		{
			if (pierIntention == null)
			{
				flood.Tick(Layout.KingdomStart, VisitCell);
			}
			KillAndNullFinishedIntention(ref pierIntention);
		}
	}
}
