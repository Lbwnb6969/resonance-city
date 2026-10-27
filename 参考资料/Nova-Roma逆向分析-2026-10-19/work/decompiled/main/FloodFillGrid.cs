using System.Collections.Generic;

public class FloodFillGrid<T> where T : ICellXZ
{
	public List<T> openSet = new List<T>();

	public bool[] visitGrid;

	public int width;

	public int height;

	protected void Init(int width, int height, T startCell, int xOffset = 0, int zOffset = 0)
	{
		this.width = width;
		this.height = height;
		if (visitGrid == null || visitGrid.Length != width * height)
		{
			visitGrid = new bool[width * height];
		}
		for (int i = 0; i < visitGrid.Length; i++)
		{
			visitGrid[i] = false;
		}
		openSet.Clear();
		AddToSet(startCell, xOffset, zOffset);
	}

	protected void AddToSet(T cell, int xOffset = 0, int zOffset = 0)
	{
		int num = (cell.X - xOffset) * width + (cell.Z - zOffset);
		if (!visitGrid[num])
		{
			openSet.Add(cell);
			visitGrid[num] = true;
		}
	}

	protected T GetNextCell()
	{
		T result = openSet[0];
		openSet.RemoveAt(0);
		return result;
	}

	protected bool HasCells()
	{
		return openSet.Count > 0;
	}
}
