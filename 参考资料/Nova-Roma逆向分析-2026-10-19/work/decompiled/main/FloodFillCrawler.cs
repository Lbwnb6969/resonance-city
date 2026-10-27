using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;

public class FloodFillCrawler
{
	public delegate bool visitCell(Cell cell, ref List<Cell> openSet);

	public int cellsPerFrame = 10;

	private List<Cell> openSet = new List<Cell>();

	public bool[] visited;

	public bool finishedCrawl;

	public bool exitedEarly;

	public void Reset()
	{
		openSet.Clear();
	}

	public void Tick(Vector3 start, visitCell visitor)
	{
		if (openSet.Count == 0)
		{
			Cell cellData = World.inst.GetCellData(start);
			openSet.Add(cellData);
			if (visited == null)
			{
				visited = new bool[World.inst.GridWidth * World.inst.GridHeight];
			}
			Util.Memset(visited, 0);
			finishedCrawl = false;
			exitedEarly = false;
		}
		int gridWidth = World.inst.GridWidth;
		int num = cellsPerFrame;
		while (openSet.Count > 0 && num > 0)
		{
			Cell cell = openSet[0];
			openSet.RemoveAt(0);
			if (!visited[cell.z * gridWidth + cell.x])
			{
				num--;
				visited[cell.z * gridWidth + cell.x] = true;
				if (!visitor(cell, ref openSet))
				{
					break;
				}
			}
		}
		exitedEarly = num > 0;
		finishedCrawl = openSet.Count == 0;
	}

	public void AddNonDeepWaterCardinalToOpenSet(Cell cell)
	{
		if (!cell.deepWater)
		{
			openSet.Add(World.inst.GetCellData(cell.x + 1, cell.z));
			openSet.Add(World.inst.GetCellData(cell.x, cell.z + 1));
			openSet.Add(World.inst.GetCellData(cell.x - 1, cell.z));
			openSet.Add(World.inst.GetCellData(cell.x, cell.z - 1));
		}
	}

	public void AddAllCardinalToOpenSet(Cell cell)
	{
		openSet.Add(World.inst.GetCellData(cell.x + 1, cell.z));
		openSet.Add(World.inst.GetCellData(cell.x, cell.z + 1));
		openSet.Add(World.inst.GetCellData(cell.x - 1, cell.z));
		openSet.Add(World.inst.GetCellData(cell.x, cell.z - 1));
	}

	public void AddAllNeighborsToOpenSet(Cell cell)
	{
		openSet.Add(World.inst.GetCellData(cell.x + 1, cell.z));
		openSet.Add(World.inst.GetCellData(cell.x + 1, cell.z + 1));
		openSet.Add(World.inst.GetCellData(cell.x, cell.z + 1));
		openSet.Add(World.inst.GetCellData(cell.x - 1, cell.z + 1));
		openSet.Add(World.inst.GetCellData(cell.x - 1, cell.z));
		openSet.Add(World.inst.GetCellData(cell.x - 1, cell.z - 1));
		openSet.Add(World.inst.GetCellData(cell.x, cell.z - 1));
		openSet.Add(World.inst.GetCellData(cell.x + 1, cell.z - 1));
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public void AddCellToOpenSet(Cell cell)
	{
		openSet.Add(cell);
	}
}
