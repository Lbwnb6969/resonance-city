using System.Collections.Generic;

public class Intention_ClearObstructions : AIIntentionBase
{
	private FloodFillCrawler floodCrawler = new FloodFillCrawler();

	private Intention_BuildExactBuilding excavationSite;

	private Cell obstructionCell;

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 35;
		if (Kingdom.CurrentResources.Get(6) >= 10 && excavationSite == null && !IsBeingBuilt(World.stoneRemovalHash))
		{
			floodCrawler.Tick(Layout.KingdomStart, VisitCell);
		}
		KillAndNullFinishedIntention(ref excavationSite);
	}

	public bool VisitCell(Cell c, ref List<Cell> openSet)
	{
		if (c.Type == TerrainType.Obstruction || c.Type == TerrainType.EmptyCave)
		{
			obstructionCell = c;
			excavationSite = AddSubIntention<Intention_BuildExactBuilding>("clear rock");
			excavationSite.Init(World.stoneRemovalName, c.Position);
			return false;
		}
		floodCrawler.AddNonDeepWaterCardinalToOpenSet(c);
		return true;
	}
}
