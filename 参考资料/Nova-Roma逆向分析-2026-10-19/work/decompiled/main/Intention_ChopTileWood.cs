public class Intention_ChopTileWood : AIIntentionBase
{
	public bool TileClear;

	private ClearCutterJob cutterJob;

	private Cell cell;

	public void Init(Cell tile)
	{
		cell = tile;
		transform.position = tile.Center2D;
		if (World.inst.treeSystem.ItemAmount(tile) == 0)
		{
			TileClear = true;
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		if (cutterJob == null && World.inst.treeSystem.ItemAmount(cell) > 0 && !cell.Busy)
		{
			cutterJob = new ClearCutterJob(cell);
			JobSystem.inst.AddNewJob(0, cutterJob, 21);
			cutterJob.StartClearingAt(cell);
		}
		if (cutterJob != null && cutterJob.employer == null)
		{
			cutterJob = null;
		}
		TileClear = World.inst.treeSystem.ItemAmount(cell) == 0;
	}
}
