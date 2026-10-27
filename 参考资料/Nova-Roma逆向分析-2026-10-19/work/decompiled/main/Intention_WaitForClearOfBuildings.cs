public class Intention_WaitForClearOfBuildings : AIIntentionBase
{
	public bool TileClear;

	private Building building;

	private int minX;

	private int minZ;

	private int maxX;

	private int maxZ;

	public void Init(Building building)
	{
		this.building = building;
		transform.position = building.GetPos();
		TileClear = CheckFootprintForClear();
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		TileClear = CheckFootprintForClear();
	}

	public bool CheckFootprintForClear()
	{
		bool flag = true;
		building.GetBoundingFootprint(out minX, out minZ, out maxX, out maxZ);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(j, i);
				if (cellDataUnsafe != null)
				{
					flag &= cellDataUnsafe.OccupyingStructure.Count == 0;
				}
			}
		}
		return flag;
	}
}
