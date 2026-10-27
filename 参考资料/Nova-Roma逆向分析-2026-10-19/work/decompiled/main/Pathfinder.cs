using System;
using System.Collections.Generic;
using UnityEngine;

public class Pathfinder
{
	public class Node : IComparable<Node>
	{
		public Node parent;

		public PathCell cell;

		public Node[,] grid;

		public int G;

		public int F;

		public bool isFreeCell;

		public bool inOpenList;

		public bool visited;

		public int CompareTo(Node other)
		{
			return F - other.F;
		}
	}

	public delegate bool blocksPathTest(PathCell c, int teamId);

	public delegate int applyExtraCost(PathCell c, int teamId);

	private Node[,] pathGrid;

	private Node[,] upperPathGrid;

	private int numCellsAcross;

	private int numCellsDown;

	private Vector3 testStart;

	private Vector3 testEnd;

	private ArrayExt<Vector3> testPath = new ArrayExt<Vector3>(100);

	private int endX;

	private int endZ;

	private int dbg;

	private List<Node> scratchPathNode = new List<Node>();

	private ArrayExt<Node> openSet = new ArrayExt<Node>(500);

	public blocksPathTest blocksPath;

	public applyExtraCost extraCost;

	private bool rasterLine(Node a, Node b, applyExtraCost extraCost, blocksPathTest blockFunc, int teamId)
	{
		if (a.grid != b.grid)
		{
			return false;
		}
		int num = a.cell.x;
		int num2 = a.cell.z;
		int x = b.cell.x;
		int z = b.cell.z;
		float y = GetPathPoint(a).y;
		int num3 = extraCost(a.cell, teamId);
		int num4 = Mathf.Abs(x - num);
		int num5 = ((num < x) ? 1 : (-1));
		int num6 = Mathf.Abs(z - num2);
		int num7 = ((num2 < z) ? 1 : (-1));
		int num8 = num4 - num6;
		float num9 = ((num4 + num6 == 0) ? 1f : Mathf.Sqrt((float)num4 * (float)num4 + (float)num6 * (float)num6));
		while (true)
		{
			Node node = a.grid[num, num2];
			if (GetPathBlocked(node, blockFunc, teamId) || Mathff.Abs(num3 - extraCost(node.cell, teamId)) > 0 || Mathf.Abs(GetPathPoint(node).y - y) > 0.01f)
			{
				return false;
			}
			int num10 = num8;
			int num11 = num;
			if (2 * num10 >= -num4)
			{
				if (num == x)
				{
					break;
				}
				if ((float)(num10 + num6) < num9)
				{
					node = a.grid[num, num2 + num7];
					if (GetPathBlocked(node, blockFunc, teamId) || Mathff.Abs(num3 - extraCost(node.cell, teamId)) > 0 || Mathf.Abs(GetPathPoint(node).y - y) > 0.01f)
					{
						return false;
					}
				}
				num8 -= num6;
				num += num5;
			}
			if (2 * num10 > num6)
			{
				continue;
			}
			if (num2 == z)
			{
				break;
			}
			if ((float)(num4 - num10) < num9)
			{
				node = a.grid[num11 + num5, num2];
				if (GetPathBlocked(node, blockFunc, teamId) || Mathff.Abs(num3 - extraCost(node.cell, teamId)) > 0 || Mathf.Abs(GetPathPoint(node).y - y) > 0.01f)
				{
					return false;
				}
			}
			num8 += num4;
			num2 += num7;
		}
		return true;
	}

	public void Update()
	{
		if (!Application.isEditor || pathGrid == null || Camera.main == null)
		{
			return;
		}
		Ray ray = PointingSystem.GetPointer().GetRay();
		new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
		if (GameState.inst.AlphaNumericHotkeysEnabled)
		{
			if (Input.GetKeyDown(KeyCode.Alpha5))
			{
				testStart = ray.GetPoint(enter);
			}
			if (Input.GetKeyDown(KeyCode.Alpha6))
			{
				testEnd = ray.GetPoint(enter);
			}
			if (Input.GetKeyDown(KeyCode.Alpha0))
			{
				dbg++;
			}
			if (Input.GetKeyDown(KeyCode.Alpha9))
			{
				dbg--;
			}
		}
		DebugEx.DrawCircle(testStart, 0.25f, Color.yellow, new Vector3(0f, 1f, 0f), new Vector3(1f, 0f, 0f), 4f);
		DebugEx.DrawCircle(testEnd, 0.25f, Color.blue, new Vector3(0f, 1f, 0f), new Vector3(1f, 0f, 0f), 4f);
		for (int i = 0; i < testPath.Count - 1; i++)
		{
			Debug.DrawLine(testPath.data[i] + new Vector3(0f, 0.1f, 0f), testPath.data[i + 1] + new Vector3(0f, 0.1f, 0f), Color.cyan, 0f, depthTest: false);
		}
		if (testPath.Count > 0)
		{
			Debug.DrawLine(testStart, testPath.data[0], Color.red, 0f, depthTest: false);
		}
	}

	public void DebugDisplay()
	{
		for (int i = 0; i < numCellsAcross; i++)
		{
			for (int j = 0; j < numCellsDown; j++)
			{
				_ = Color.green;
				_ = Color.red;
			}
		}
	}

	public void InitGrid(int width, int height)
	{
		numCellsAcross = width;
		numCellsDown = height;
		upperPathGrid = new Node[numCellsAcross, numCellsDown];
		pathGrid = new Node[numCellsAcross, numCellsDown];
		for (int i = 0; i < numCellsAcross; i++)
		{
			for (int j = 0; j < numCellsDown; j++)
			{
				PathCell pathCell = World.inst.GetPathCell(i, j);
				pathGrid[i, j] = new Node();
				pathGrid[i, j].grid = pathGrid;
				pathGrid[i, j].cell = pathCell;
				upperPathGrid[i, j] = new Node();
				upperPathGrid[i, j].grid = upperPathGrid;
				upperPathGrid[i, j].cell = pathCell;
				upperPathGrid[i, j].cell.ogreFootPathCost = 5000;
			}
		}
	}

	private Node SearchForClosestUnblockedCell(int sx, int sz, Vector3 start, Vector3 end, int teamId)
	{
		PathCell pathCell = null;
		float num = float.MaxValue;
		int num2 = 1;
		int num3 = Mathf.Clamp(sx - num2, 0, World.inst.GridWidth - 1);
		int num4 = Mathf.Clamp(sx + num2, 0, World.inst.GridWidth - 1);
		int num5 = Mathf.Clamp(sz - num2, 0, World.inst.GridHeight - 1);
		int num6 = Mathf.Clamp(sz + num2, 0, World.inst.GridHeight - 1);
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num5; j <= num6; j++)
			{
				PathCell pathCell2 = World.inst.GetPathCell(i, j);
				if (!blocksPath(pathCell2, teamId))
				{
					float num7 = Mathff.DistSqrdXZ(pathCell2.Center, start);
					if (num7 < num)
					{
						num = num7;
						pathCell = pathCell2;
					}
				}
			}
		}
		if (pathCell != null)
		{
			return pathGrid[pathCell.x, pathCell.z];
		}
		return null;
	}

	private void ClearGrid()
	{
		for (int i = 0; i < numCellsAcross; i++)
		{
			for (int j = 0; j < numCellsDown; j++)
			{
				Node node = pathGrid[i, j];
				node.parent = null;
				node.inOpenList = false;
				node.visited = false;
				node.G = 0;
				node.isFreeCell = false;
				Node node2 = upperPathGrid[i, j];
				node2.parent = null;
				node2.inOpenList = false;
				node2.visited = false;
				node2.G = 0;
				node2.isFreeCell = false;
			}
		}
	}

	public void FindPathRaw(Vector3 startPos, Vector3 endPos, ref List<Vector3> path, blocksPathTest bt, applyExtraCost ec, int teamId)
	{
		path.Clear();
		if (startPos.Equals(endPos))
		{
			path.Add(endPos);
			return;
		}
		blocksPath = bt;
		extraCost = ec;
		int num = Mathf.FloorToInt(startPos.x);
		int num2 = Mathf.FloorToInt(startPos.z);
		int num3 = Mathf.FloorToInt(endPos.x);
		int num4 = Mathf.FloorToInt(endPos.z);
		if (num < 0 || num >= numCellsAcross || num2 < 0 || num2 >= numCellsDown || num3 < 0 || num3 >= numCellsAcross || num4 < 0 || num4 >= numCellsDown)
		{
			return;
		}
		Node node = pathGrid[num, num2];
		Node node2 = pathGrid[num3, num4];
		if (node.cell == node2.cell)
		{
			path.Add(node2.cell.Center);
			return;
		}
		if (blocksPath(node.cell, teamId))
		{
			Node node3 = SearchForClosestUnblockedCell(num, num2, endPos, startPos, teamId);
			if (node3 != null)
			{
				node = node3;
			}
		}
		endX = num3;
		endZ = num4;
		ClearGrid();
		ClearOpenSet();
		openSet.Add(node);
		node.F = 2147483646;
		int num5 = numCellsAcross;
		int num6 = numCellsDown;
		while (openSet.Count > 0)
		{
			Node node4 = null;
			int num7 = -1;
			int num8 = int.MaxValue;
			int i = 0;
			for (int count = openSet.Count; i < count; i++)
			{
				if (openSet.data[i].F < num8)
				{
					num8 = openSet.data[i].F;
					num7 = i;
				}
			}
			node4 = openSet.data[num7];
			RemoveOpenSetAt(num7);
			node4.inOpenList = false;
			node4.visited = true;
			if (node4 == node2)
			{
				break;
			}
			PathCell cell = node4.cell;
			int x = cell.x;
			int z = cell.z;
			if (x + 1 < num5)
			{
				AddToOpenSet(pathGrid[x + 1, z], node4, 10, teamId);
			}
			if (x - 1 >= 0)
			{
				AddToOpenSet(pathGrid[x - 1, z], node4, 10, teamId);
			}
			if (z + 1 < num6)
			{
				AddToOpenSet(pathGrid[x, z + 1], node4, 10, teamId);
			}
			if (z - 1 >= 0)
			{
				AddToOpenSet(pathGrid[x, z - 1], node4, 10, teamId);
			}
			if (openSet.Count == 0)
			{
				break;
			}
		}
		Node node5 = node2;
		while (node5 != node && node5 != null)
		{
			path.Insert(0, node5.cell.Center);
			node5 = node5.parent;
		}
	}

	public void FindPath(Vector3 startPos, bool startUseUpperGrid, Vector3 endPos, bool endUseUpperGrid, ref ArrayExt<Vector3> path, blocksPathTest bt, blocksPathTest pullBlock, applyExtraCost ec, int teamId, bool doDiagonal, bool doTrimming, bool allowUpperGrid)
	{
		path.Clear();
		blocksPath = bt;
		extraCost = ec;
		int num = Mathf.FloorToInt(startPos.x);
		int num2 = Mathf.FloorToInt(startPos.z);
		int num3 = Mathf.FloorToInt(endPos.x);
		int num4 = Mathf.FloorToInt(endPos.z);
		if (num < 0 || num >= numCellsAcross || num2 < 0 || num2 >= numCellsDown || num3 < 0 || num3 >= numCellsAcross || num4 < 0 || num4 >= numCellsDown)
		{
			return;
		}
		Node node = (startUseUpperGrid ? upperPathGrid[num, num2] : pathGrid[num, num2]);
		Node node2 = (endUseUpperGrid ? upperPathGrid[num3, num4] : pathGrid[num3, num4]);
		if (node.cell == node2.cell && startUseUpperGrid == endUseUpperGrid)
		{
			path.Add(GetPathPoint(node2));
			endPos.y = GetPathPoint(node2).y;
			path.Add(endPos);
			return;
		}
		if (blocksPath(node.cell, teamId))
		{
			Node node3 = SearchForClosestUnblockedCell(num, num2, endPos, startPos, teamId);
			if (node3 != null)
			{
				node = node3;
			}
		}
		endX = num3;
		endZ = num4;
		ClearGrid();
		if (!endUseUpperGrid)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(endX, endZ);
			if (cellDataUnsafe.OccupyingStructure.Count > 0)
			{
				cellDataUnsafe.OccupyingStructure[0].GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
				for (int i = minZ; i <= maxZ; i++)
				{
					for (int j = minX; j <= maxX; j++)
					{
						pathGrid[j, i].isFreeCell = true;
					}
				}
			}
			else
			{
				pathGrid[num3, num4].isFreeCell = true;
			}
		}
		if (!startUseUpperGrid)
		{
			Cell cellDataUnsafe2 = World.inst.GetCellDataUnsafe(num, num2);
			if (cellDataUnsafe2.OccupyingStructure.Count > 0)
			{
				cellDataUnsafe2.OccupyingStructure[0].GetBoundingFootprint(out var minX2, out var minZ2, out var maxX2, out var maxZ2);
				for (int k = minZ2; k <= maxZ2; k++)
				{
					for (int l = minX2; l <= maxX2; l++)
					{
						pathGrid[l, k].isFreeCell = true;
					}
				}
			}
		}
		ClearOpenSet();
		openSet.Add(node);
		node.F = 2147483646;
		int num5 = numCellsAcross;
		int num6 = numCellsDown;
		while (openSet.Count > 0)
		{
			Node node4 = null;
			int num7 = -1;
			int num8 = int.MaxValue;
			int num9 = int.MaxValue;
			int m = 0;
			for (int count = openSet.Count; m < count; m++)
			{
				Node node5 = openSet.data[m];
				if (node5.F < num8)
				{
					num8 = node5.F;
					num7 = m;
					num9 = node5.F - node5.G;
				}
				else if (node5.F == num8)
				{
					int num10 = node5.F - node5.G;
					if (num10 < num9)
					{
						num8 = node5.F;
						num9 = num10;
						num7 = m;
					}
				}
			}
			node4 = openSet.data[num7];
			RemoveOpenSetAt(num7);
			node4.inOpenList = false;
			node4.visited = true;
			if (node4 == node2)
			{
				break;
			}
			PathCell cell = node4.cell;
			int x = cell.x;
			int z = cell.z;
			Node[,] grid = node4.grid;
			if (x + 1 < num5)
			{
				AddToOpenSet(grid[x + 1, z], node4, 10, teamId);
			}
			if (x - 1 >= 0)
			{
				AddToOpenSet(grid[x - 1, z], node4, 10, teamId);
			}
			if (z + 1 < num6)
			{
				AddToOpenSet(grid[x, z + 1], node4, 10, teamId);
			}
			if (z - 1 >= 0)
			{
				AddToOpenSet(grid[x, z - 1], node4, 10, teamId);
			}
			if (!cell.isPathCell && node4.grid == pathGrid)
			{
				if (x + 1 < num5)
				{
					if (z + 1 < num6 && (doDiagonal || extraCost(grid[x + 1, z].cell, teamId) < PathCell.buildingFootpathCost || extraCost(grid[x, z + 1].cell, teamId) < PathCell.buildingFootpathCost))
					{
						AddToOpenSet(grid[x + 1, z + 1], node4, 14, teamId);
					}
					if (z - 1 >= 0 && (doDiagonal || extraCost(grid[x + 1, z].cell, teamId) < PathCell.buildingFootpathCost || extraCost(grid[x, z - 1].cell, teamId) < PathCell.buildingFootpathCost))
					{
						AddToOpenSet(grid[x + 1, z - 1], node4, 14, teamId);
					}
				}
				if (x - 1 >= 0)
				{
					if (z + 1 < num6 && (doDiagonal || extraCost(grid[x - 1, z].cell, teamId) < PathCell.buildingFootpathCost || extraCost(grid[x, z + 1].cell, teamId) < PathCell.buildingFootpathCost))
					{
						AddToOpenSet(grid[x - 1, z + 1], node4, 14, teamId);
					}
					if (z - 1 >= 0 && (doDiagonal || extraCost(grid[x - 1, z].cell, teamId) < PathCell.buildingFootpathCost || extraCost(grid[x, z - 1].cell, teamId) < PathCell.buildingFootpathCost))
					{
						AddToOpenSet(grid[x - 1, z - 1], node4, 14, teamId);
					}
				}
			}
			if (cell.isStairs & allowUpperGrid)
			{
				Node[,] array = pathGrid;
				if (node4.grid == array)
				{
					array = upperPathGrid;
				}
				AddToOpenSet(array[x, z], node4, 10, teamId);
			}
			if (openSet.Count == 0)
			{
				break;
			}
		}
		if (doTrimming)
		{
			StringPull(node, node2, teamId, pullBlock);
			StringPull(node, node2, teamId, pullBlock);
		}
		bool flag = !endUseUpperGrid && !startUseUpperGrid;
		scratchPathNode.Clear();
		Node node6 = node2;
		float num11 = 999f;
		while (node6 != node && node6 != null)
		{
			bool num12 = node6.grid == upperPathGrid && node6.cell.isStairs;
			Vector3 pathPoint = GetPathPoint(node6);
			if (!num12 && pathPoint.y > num11 && !flag)
			{
				pathPoint.y = num11;
			}
			path.Insert(0, pathPoint);
			scratchPathNode.Insert(0, node6);
			node6 = node6.parent;
			num11 = pathPoint.y;
		}
		if (node6 == node)
		{
			if (!flag)
			{
				num11 = startPos.y;
				for (int n = 0; n < scratchPathNode.Count; n++)
				{
					bool num13 = scratchPathNode[n].grid == upperPathGrid && scratchPathNode[n].cell.isStairs;
					Vector3 pathPoint2 = GetPathPoint(scratchPathNode[n]);
					if (!num13 && pathPoint2.y > num11)
					{
						pathPoint2.y = num11;
					}
					if (path.data[n].y < pathPoint2.y)
					{
						Vector3 vector = path.data[n];
						vector.y = pathPoint2.y;
						path.data[n] = vector;
					}
					num11 = pathPoint2.y;
				}
			}
			endPos.y = GetPathPoint(node2).y;
			path.Add(endPos);
		}
		else
		{
			path.Clear();
		}
	}

	internal void Shutdown()
	{
		pathGrid = null;
		upperPathGrid = null;
	}

	private Vector3 GetPathPoint(Node n)
	{
		Vector3 result = n.cell.Center;
		if (n.grid == upperPathGrid)
		{
			result = World.GetCellHeightPos(World.inst.GetCellData(n.cell));
		}
		return result;
	}

	private void ClearOpenSet()
	{
		openSet.ClearFast();
	}

	private void RemoveOpenSetAt(int idx)
	{
		openSet.RemoveAtSwap(idx);
	}

	private void StringPull(Node startNode, Node endNode, int teamId, blocksPathTest bt)
	{
		Node node = endNode;
		if (node.parent == null)
		{
			return;
		}
		Node parent = node.parent.parent;
		while (parent != null)
		{
			bool flag = rasterLine(node, parent, extraCost, bt, teamId);
			if (node.cell.isUpperGridBlocked & flag)
			{
				node.parent = parent;
				if (parent == startNode)
				{
					break;
				}
				parent = parent.parent;
			}
			else
			{
				node = node.parent;
				parent = node.parent.parent;
			}
		}
	}

	private bool GetPathBlocked(Node n, blocksPathTest bt, int teamId)
	{
		if (n.grid != upperPathGrid)
		{
			if (bt(n.cell, teamId))
			{
				return true;
			}
		}
		else if (n.cell.isUpperGridBlocked)
		{
			return true;
		}
		return false;
	}

	private void AddToOpenSet(Node node, Node parent, int sG, int teamId)
	{
		if (node.visited || GetPathBlocked(node, blocksPath, teamId))
		{
			return;
		}
		int num = sG;
		PathCell cell = node.cell;
		bool flag = node.grid == upperPathGrid;
		if (!node.isFreeCell && !flag)
		{
			num += extraCost(cell, teamId);
		}
		num += parent.G;
		if (!node.inOpenList || node.G > num)
		{
			int num2 = cell.x - endX;
			if (num2 < 0)
			{
				num2 *= -1;
			}
			int num3 = cell.z - endZ;
			if (num3 < 0)
			{
				num3 *= -1;
			}
			int num4 = (num2 + num3) * 10;
			int f = num + num4;
			node.G = num;
			node.F = f;
			node.parent = parent;
			if (!node.inOpenList)
			{
				openSet.Add(node);
				node.inOpenList = true;
			}
		}
	}
}
