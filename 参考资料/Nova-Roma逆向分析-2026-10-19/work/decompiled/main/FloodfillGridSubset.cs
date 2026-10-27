public class FloodfillGridSubset<T> : FloodFillGrid<T> where T : ICellXZ
{
	private int startX;

	private int startZ;

	private int endX;

	private int endZ;

	public void Init(int startX, int startZ, int endX, int endZ, T startCell)
	{
		this.startX = startX;
		this.startZ = startZ;
		this.endX = endX;
		this.endZ = endZ;
		Init(this.endX - this.startX + 1, this.endZ - this.startZ + 1, startCell, startX, startZ);
	}

	protected void AddToSet(T cell)
	{
		if (cell.X >= startX && cell.X <= endX && cell.Z >= startZ && cell.Z <= endZ)
		{
			AddToSet(cell, startX, startZ);
		}
	}
}
