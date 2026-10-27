using System;
using System.Collections.Generic;
using UnityEngine;

public class Intention_WallDefense : AIIntentionBase
{
	public class CheckCastleWallsForProjectileToppers : FloodfillGridSubset<DefenseCell>
	{
		private int x;

		private int z;

		private Cell[] scratch = new Cell[4];

		public bool IsNearProjectileTopper(int maxDistance, DefenseCell startCell, AILayout layout)
		{
			x = startCell.x;
			z = startCell.z;
			Init(startCell.x - maxDistance, startCell.z - maxDistance, startCell.x + maxDistance, startCell.z + maxDistance, startCell);
			while (HasCells())
			{
				DefenseCell nextCell = GetNextCell();
				World.inst.GetNeighborCells(nextCell.GetWorldCell(), ref scratch);
				for (int i = 0; i < scratch.Length; i++)
				{
					if (scratch[i] != null)
					{
						DefenseCell defenceCell = layout.GetDefenceCell(scratch[i]);
						if (defenceCell.CastleEdge)
						{
							AddToSet(defenceCell);
						}
					}
				}
				if (nextCell != startCell && nextCell.GetWorldCell().StructureCompareCategoryNameAll(World.projectileTopperHash))
				{
					return true;
				}
			}
			return false;
		}
	}

	public class CheckCastleWallsForExternalCorners : FloodfillGridSubset<DefenseCell>
	{
		private int x;

		private int z;

		private Cell[] scratch = new Cell[4];

		public bool IsNearACorner(int maxDistance, DefenseCell startCell, AILayout layout)
		{
			x = startCell.x;
			z = startCell.z;
			Init(startCell.x - maxDistance, startCell.z - maxDistance, startCell.x + maxDistance, startCell.z + maxDistance, startCell);
			while (HasCells())
			{
				DefenseCell nextCell = GetNextCell();
				World.inst.GetNeighborCells(nextCell.GetWorldCell(), ref scratch);
				for (int i = 0; i < scratch.Length; i++)
				{
					if (scratch[i] != null)
					{
						DefenseCell defenceCell = layout.GetDefenceCell(scratch[i]);
						if (defenceCell.CastleEdge)
						{
							AddToSet(defenceCell);
						}
					}
				}
				if (nextCell != startCell && IsExternalWallCorner(nextCell, layout))
				{
					return true;
				}
			}
			return false;
		}

		public bool IsExternalWallCorner(DefenseCell cell, AILayout layout)
		{
			World.inst.GetNeighborCells(cell.GetWorldCell(), ref scratch);
			int num = 0;
			for (int i = 0; i < scratch.Length; i++)
			{
				if (scratch[i] != null)
				{
					DefenseCell defenceCell = layout.GetDefenceCell(scratch[i]);
					if (scratch[i].Type == TerrainType.Water || !defenceCell.Castle)
					{
						num++;
					}
				}
			}
			return num >= 2;
		}
	}

	public class CheckCastleEnclosure : FloodFillGrid<DefenseCell>
	{
		private DefenseCell[] scratchDefenceCells4 = new DefenseCell[4];

		public bool CheckEnclosed(DefenseCell startCell, AILayout layout)
		{
			Init(World.inst.GridWidth, World.inst.GridHeight, startCell);
			while (HasCells())
			{
				DefenseCell nextCell = GetNextCell();
				if (!nextCell.Castle)
				{
					return false;
				}
				layout.GetNeighborDefenceCells(nextCell, ref scratchDefenceCells4);
				for (int i = 0; i < scratchDefenceCells4.Length; i++)
				{
					DefenseCell defenseCell = scratchDefenceCells4[i];
					Cell worldCell = defenseCell.GetWorldCell();
					if (worldCell != null && worldCell.Type != TerrainType.Obstruction && worldCell.Type != TerrainType.WolfDen && worldCell.Type != TerrainType.EmptyCave && !worldCell.StructureCompareCategoryNameAll(World.castleblockHash) && !worldCell.StructureCompareCategoryNameAll(World.gateHash) && !worldCell.StructureCompareUniqueNameAll(World.keepHash) && !worldCell.StructureCompareUniqueNameAll(World.quarryHash) && !worldCell.StructureCompareUniqueNameAll(World.foresterHash) && !worldCell.StructureCompareUniqueNameAll(World.ironMineHash) && !worldCell.StructureCompareUniqueNameAll(World.dockHash) && !worldCell.StructureCompareUniqueNameAll(World.noriaHash))
					{
						AddToSet(defenseCell);
					}
				}
			}
			return true;
		}
	}

	private class AnalyseCellDefenses
	{
		public int woodBlocks;

		public int stoneBlocks;

		public bool hasArcherTower;

		public bool hasBallistaTower;

		public bool hasWoodGate;

		public bool hasStoneGate;

		public bool hasSeaGate;

		public bool hasGate;

		public int height;

		public void Analyse(Cell cell)
		{
			woodBlocks = 0;
			stoneBlocks = 0;
			hasArcherTower = false;
			hasBallistaTower = false;
			hasGate = false;
			hasWoodGate = false;
			hasStoneGate = false;
			hasSeaGate = false;
			height = 0;
			for (int i = 0; i < cell.OccupyingStructure.Count; i++)
			{
				if (cell.OccupyingStructure[i].uniqueNameHash == World.woodcastleblockHash)
				{
					woodBlocks++;
				}
				if (cell.OccupyingStructure[i].uniqueNameHash == World.castleblockHash)
				{
					stoneBlocks++;
				}
				if (cell.OccupyingStructure[i].uniqueNameHash == World.archerTowerHash)
				{
					hasArcherTower = true;
				}
				if (cell.OccupyingStructure[i].uniqueNameHash == World.ballistaTowerHash)
				{
					hasBallistaTower = true;
				}
				if (cell.OccupyingStructure[i].categoryHash == World.gateHash)
				{
					hasGate = true;
				}
				if (cell.OccupyingStructure[i].uniqueNameHash == World.woodengateHash)
				{
					hasWoodGate = true;
				}
				if (cell.OccupyingStructure[i].uniqueNameHash == World.gateHash)
				{
					hasStoneGate = true;
				}
				if (cell.OccupyingStructure[i].uniqueNameHash == World.seagateHash)
				{
					hasSeaGate = true;
				}
				if (cell.OccupyingStructure[i].Stackable)
				{
					height += cell.OccupyingStructure[i].StackHeight;
				}
			}
		}
	}

	[Serializable]
	public class WallDefenseSaveData : SaveClass<Intention_WallDefense, WallDefenseSaveData>
	{
		[Serializable]
		private struct CellM
		{
			public int x;

			public int z;
		}

		private List<CellM> cellsNeedWall = new List<CellM>();

		private bool firstWallCompleted;

		private bool secondWallCompleted;

		private int prevMinX;

		private int prevMaxX;

		private int prevMinZ;

		private int prevMaxZ;

		public override WallDefenseSaveData Pack(Intention_WallDefense v)
		{
			for (int i = 0; i < v.cellsThatNeedWall.Count; i++)
			{
				CellM item = new CellM
				{
					x = v.cellsThatNeedWall.data[i].x,
					z = v.cellsThatNeedWall.data[i].z
				};
				cellsNeedWall.Add(item);
			}
			firstWallCompleted = v.firstWallComplete;
			secondWallCompleted = v.secondWallComplete;
			prevMinX = v.prevMinX;
			prevMaxX = v.prevMaxX;
			prevMinZ = v.prevMinZ;
			prevMaxZ = v.prevMaxZ;
			return this;
		}

		public override Intention_WallDefense Unpack(Intention_WallDefense v)
		{
			for (int i = 0; i < cellsNeedWall.Count; i++)
			{
				v.cellsThatNeedWall.Add(World.inst.GetCellDataClamped(cellsNeedWall[i].x, cellsNeedWall[i].z));
			}
			v.firstWallComplete = firstWallCompleted;
			v.secondWallComplete = secondWallCompleted;
			v.prevMinX = prevMinX;
			v.prevMaxX = prevMaxX;
			v.prevMinZ = prevMinZ;
			v.prevMaxZ = prevMaxZ;
			return v;
		}
	}

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private BuildStack[] buildIntentionStacks = new BuildStack[10];

	private EventHandler<OnAICastleRegionUpdateEvent> listener;

	private ArrayExt<Cell> cellsThatNeedWall = new ArrayExt<Cell>(20);

	private List<Cell> cellsThatNeedWallRemoved = new List<Cell>(20);

	private ArrayExt<Cell> cellsThatNeedWallReplaced = new ArrayExt<Cell>(20);

	private Timer removalTimer = new Timer(3f);

	private bool pendingUpdate;

	private bool runningUpdate;

	public bool firstWallComplete;

	public bool secondWallComplete;

	private int prevMinX;

	private int prevMaxX;

	private int prevMinZ;

	private int prevMaxZ;

	private List<Cell> edgeOpenSet = new List<Cell>();

	private Cell[] scratchCells8 = new Cell[8];

	private bool[] visited;

	private CheckCastleEnclosure checkCastleEnclosure = new CheckCastleEnclosure();

	private CheckCastleWallsForExternalCorners cornerCheck = new CheckCastleWallsForExternalCorners();

	private CheckCastleWallsForProjectileToppers projectileTopperCheck = new CheckCastleWallsForProjectileToppers();

	private List<Building> deferDelete = new List<Building>(5);

	private AnalyseCellDefenses analyseCellDefense = new AnalyseCellDefenses();

	public int[] roadHashes = new int[3]
	{
		World.aqueductHash,
		World.roadHash,
		World.stoneRoadHash
	};

	public int[] aqueductHashes = new int[1] { World.aqueductHash };

	private int threatLevel = 1;

	public bool debugDraw;

	private float noCastleBlockActivicty;

	private int previousSubIntentionCount;

	private FloodFillCrawler wallCrawler = new FloodFillCrawler();

	private Cell startCell;

	private int stacksInProgress;

	private int stacksToUtilize;

	private bool skipWaterCells = true;

	private bool skipOuterWalls = true;

	private Intention_BuildExactBuilding stairIntention;

	private Intention_BuildExactBuilding projectileTopperIntention;

	private DefenseCell[] scratchDCells8 = new DefenseCell[8];

	private Cell[] scratchCells4 = new Cell[4];

	private DefenseCell[] scratchDCells4 = new DefenseCell[4];

	private bool[] isCastleEdge = new bool[4];

	private List<Cell> seaGateOpenSet = new List<Cell>(8);

	private Cell tempCell;

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		for (int i = 0; i < buildIntentionStacks.Length; i++)
		{
			buildIntentionStacks[i] = new BuildStack();
		}
		wallCrawler.cellsPerFrame = 5;
		secondWallComplete = Layout.LandmassReferenceSize < 40;
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() != LandMass || (obj.targetBuilding.uniqueNameHash != World.quarryHash && obj.targetBuilding.uniqueNameHash != World.foresterHash && obj.targetBuilding.uniqueNameHash != World.ironMineHash && obj.targetBuilding.uniqueNameHash != World.dockHash && obj.targetBuilding.uniqueNameHash != World.noriaHash && obj.targetBuilding.uniqueNameHash != World.keepHash))
		{
			return;
		}
		obj.targetBuilding.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		bool flag = obj.targetBuilding.uniqueNameHash == World.dockHash;
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				DefenseCell defenceCell = Layout.GetDefenceCell(j, i);
				defenceCell.DisallowCastleEdge = obj.added;
				defenceCell.DisallowCastle = obj.added & flag;
			}
		}
		if (obj.targetBuilding.uniqueNameHash != World.noriaHash)
		{
			return;
		}
		Noria component = obj.targetBuilding.GetComponent<Noria>();
		if (component != null)
		{
			for (int k = 0; k < component.waterPos.Length; k++)
			{
				Layout.GetDefenceCell((int)component.waterPos[k].position.x, (int)component.waterPos[k].position.z).DisallowCastleEdge = obj.added;
			}
		}
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	public void UpdateCastleWalls(int radius)
	{
		Cell[] cellsData = World.inst.GetCellsData();
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		int num = Mathff.Clamp((int)Layout.KingdomGridStart.x - radius - 2, 0, gridWidth - 1);
		int num2 = Mathff.Clamp((int)Layout.KingdomGridStart.x + radius + 4, 0, gridWidth - 1);
		int num3 = Mathff.Clamp((int)Layout.KingdomGridStart.z - radius - 2, 0, gridHeight - 1);
		int num4 = Mathff.Clamp((int)Layout.KingdomGridStart.z + radius + 4, 0, gridHeight - 1);
		Vector3 kingdomGridStart = Layout.KingdomGridStart;
		kingdomGridStart.x++;
		kingdomGridStart.z++;
		int num5 = num;
		int num6 = num2;
		int num7 = num3;
		int num8 = num4;
		bool flag = false;
		int num9 = radius + 4;
		int num10 = 0;
		int num11 = 0;
		int num12 = 0;
		int num13 = 0;
		for (int i = 2; i < num9; i++)
		{
			if (num5 == num)
			{
				num13 = (int)kingdomGridStart.x - i;
			}
			if (num7 == num3)
			{
				num11 = (int)kingdomGridStart.z - i;
			}
			if (num6 == num2)
			{
				num12 = (int)kingdomGridStart.x + i;
			}
			if (num8 == num4)
			{
				num10 = (int)kingdomGridStart.z + i;
			}
			if (flag)
			{
				break;
			}
			for (int j = num11; j <= num10; j++)
			{
				if (flag)
				{
					break;
				}
				if (j < 0)
				{
					continue;
				}
				if (j >= gridHeight)
				{
					break;
				}
				for (int k = num13; k <= num12; k++)
				{
					if (flag)
					{
						break;
					}
					if (k < 0)
					{
						continue;
					}
					if (k >= gridWidth)
					{
						break;
					}
					if ((k == num13 || j == num11 || k == num12 || j == num10) && (k != num13 || j != num11) && (k != num12 || j != num11) && (k != num13 || j != num10) && (k != num12 || j != num10) && cellsData[k + j * gridWidth].Type == TerrainType.Water)
					{
						if (j == num11 && num7 == num3)
						{
							num7 = j;
						}
						if (k == num13 && num5 == num)
						{
							num5 = k;
						}
						if (j == num10 && num8 == num4)
						{
							num8 = j;
						}
						if (k == num12 && num6 == num2)
						{
							num6 = k;
						}
						flag = num6 != num2 && num5 != num && num8 != num4 && num7 != num3;
					}
				}
			}
		}
		if (firstWallComplete)
		{
			if (num8 - prevMaxZ <= 4)
			{
				num8 = prevMaxZ;
			}
			if (prevMinZ - num7 <= 4)
			{
				num7 = prevMinZ;
			}
			if (num6 - prevMaxX <= 4)
			{
				num6 = prevMaxX;
			}
			if (prevMinX - num5 <= 4)
			{
				num5 = prevMinX;
			}
		}
		num8 = Mathff.Clamp(num8, 1, gridHeight - 2);
		num7 = Mathff.Clamp(num7, 1, gridHeight - 2);
		num6 = Mathff.Clamp(num6, 1, gridWidth - 2);
		num5 = Mathff.Clamp(num5, 1, gridWidth - 2);
		Layout.DesignateCastleRegion(num5, num7, num6, num8);
		prevMaxX = num6;
		prevMinX = num5;
		prevMaxZ = num8;
		prevMinZ = num7;
		DeterminePendingEdges();
		skipWaterCells = true;
		skipOuterWalls = true;
	}

	public void DeterminePendingEdges()
	{
		int gridWidth = World.inst.GridWidth;
		DefenseCell[] defCells = Layout.defCells;
		startCell = World.inst.GetCellData(Layout.KingdomGridStart);
		int num = startCell.x + 3;
		int z = startCell.z;
		bool flag = defCells[z * gridWidth + num].Castle;
		do
		{
			bool flag2 = defCells[z * gridWidth + num].Castle && !defCells[z * gridWidth + num].DisallowCastleEdge;
			if (flag && !flag2)
			{
				break;
			}
			startCell = World.inst.GetCellData(num, z);
			flag = flag2;
			num++;
		}
		while (num < World.inst.GridWidth);
		edgeOpenSet.Clear();
		if (visited == null)
		{
			visited = new bool[World.inst.GridWidth * World.inst.GridHeight];
		}
		else
		{
			for (int i = 0; i < visited.Length; i++)
			{
				visited[i] = false;
			}
		}
		edgeOpenSet.Add(startCell);
		while (edgeOpenSet.Count > 0)
		{
			Cell cell = edgeOpenSet[0];
			edgeOpenSet.RemoveAt(0);
			int num2 = cell.z * gridWidth + cell.x;
			if (visited[num2])
			{
				continue;
			}
			visited[num2] = true;
			bool flag3 = false;
			DefenseCell defenseCell = defCells[num2];
			if (!defenseCell.Castle || (cell.Type == TerrainType.Water && cell.deepWater) || cell.Type == TerrainType.Obstruction)
			{
				continue;
			}
			if (!defenseCell.CastleEdge)
			{
				World.inst.GetNeighborCellsExtended(cell, ref scratchCells8);
				for (int j = 0; j < scratchCells8.Length; j++)
				{
					if (scratchCells8[j] != null && !defCells[scratchCells8[j].z * gridWidth + scratchCells8[j].x].Castle)
					{
						flag3 = true;
					}
				}
				if (flag3 && defenseCell.DisallowCastleEdge)
				{
					Layout.DesignateCastleRegion(cell.x - 1, cell.z - 1, cell.x + 1, cell.z + 1);
					flag3 = false;
				}
				defenseCell.CastleEdge = flag3;
			}
			World.inst.GetNeighborCells(cell, ref scratchCells4);
			for (int k = 0; k < 4; k++)
			{
				if (defCells[scratchCells4[k].z * gridWidth + scratchCells4[k].x].Castle)
				{
					edgeOpenSet.Add(scratchCells4[k]);
				}
			}
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 65;
		if (subIntentions.Count > 0 && previousSubIntentionCount <= subIntentions.Count)
		{
			noCastleBlockActivicty += dt;
			if (noCastleBlockActivicty > 10f)
			{
				priority = Mathff.Min(75, priority + (int)(noCastleBlockActivicty * 0.2f));
			}
		}
		else
		{
			noCastleBlockActivicty = 0f;
		}
		previousSubIntentionCount = subIntentions.Count;
		if (debugDraw)
		{
			Cell[] cellsData = World.inst.GetCellsData();
			int gridWidth = World.inst.GridWidth;
			int gridHeight = World.inst.GridHeight;
			for (int i = 0; i < gridWidth; i++)
			{
				for (int j = 0; j < gridHeight; j++)
				{
					int num = j + i * gridWidth;
					Cell cell = cellsData[num];
					DefenseCell defenseCell = Layout.defCells[num];
					if (defenseCell.CastleEdge)
					{
						DebugEx.DrawBox(cell.Center2D - new Vector3(0.05f, 0f, 0.05f), cell.Center2D + new Vector3(0.05f, 1f, 0.05f), Color.black);
					}
					if (defenseCell.Castle)
					{
						DebugEx.DrawBox(cell.Center2D - new Vector3(0.05f, 0.1f, 0.05f), cell.Center2D + new Vector3(0.05f, 0.2f, 0.05f), Color.cyan);
					}
					if (defenseCell.DisallowCastleEdge)
					{
						DebugEx.DrawBox(cell.Center2D - new Vector3(0.065f, 0.1f, 0.065f), cell.Center2D + new Vector3(0.065f, 0.3f, 0.065f), Color.red);
					}
					if (defenseCell.CastleEdge)
					{
						if (cornerCheck.IsExternalWallCorner(defenseCell, Layout))
						{
							DebugEx.DrawBox(cell.Center2D - new Vector3(0.3f, 0f, 0.3f), cell.Center2D + new Vector3(0.3f, 0f, 0.3f), Color.white);
						}
						else if (cornerCheck.IsNearACorner(2, defenseCell, Layout))
						{
							DebugEx.DrawBox(cell.Center2D - new Vector3(0.2f, 0f, 0.2f), cell.Center2D + new Vector3(0.2f, 0f, 0.2f), Color.yellow);
						}
						else
						{
							DebugEx.DrawBox(cell.Center2D - new Vector3(0.05f, 0f, 0.05f), cell.Center2D + new Vector3(0.05f, 0f, 0.05f), Color.yellow);
						}
					}
				}
			}
		}
		stacksInProgress = 0;
		for (int k = 0; k < buildIntentionStacks.Length; k++)
		{
			if (!buildIntentionStacks[k].available)
			{
				stacksInProgress++;
			}
		}
		if (stacksInProgress < buildIntentionStacks.Length && firstWallComplete)
		{
			if (startCell != null)
			{
				DefenseCell defenceCell = Layout.GetDefenceCell(startCell);
				if (defenceCell != null && !defenceCell.CastleEdge)
				{
					startCell = null;
				}
			}
			if (startCell == null)
			{
				int gridWidth2 = World.inst.GridWidth;
				World.inst.ForEachTileInRadiusOrDone((int)Layout.KingdomGridStart.x, (int)Layout.KingdomGridStart.z, 30, (int x, int z, Cell cell2) =>
				{
					DefenseCell obj = Layout.defCells[x + z * gridWidth2];
					if (obj != null && obj.CastleEdge)
					{
						startCell = cell2;
						return true;
					}
					return false;
				});
			}
			if (startCell != null && SeasonManager.inst.CurrentYear() > 35 && Player.inst.TotalWorkersForLandMass(LandMass) > 50)
			{
				int num2 = ((Kingdom.globalThreatLevel < 3) ? Kingdom.CurrentResources.Get(1) : Kingdom.CurrentResources.Get(2));
				stacksToUtilize = Mathff.Max(1, num2 / 50);
				if (stacksInProgress < stacksToUtilize)
				{
					wallCrawler.Tick(startCell.Position, VisitCastleEdge);
					if (wallCrawler.finishedCrawl)
					{
						skipOuterWalls = skipWaterCells;
						skipWaterCells = false;
					}
				}
			}
		}
		for (int num3 = 0; num3 < buildIntentionStacks.Length; num3++)
		{
			buildIntentionStacks[num3].Update(this);
		}
	}

	public bool VisitCastleEdge(Cell cell, ref List<Cell> openSet)
	{
		DefenseCell defenceCell = Layout.GetDefenceCell(cell);
		if ((defenceCell != null && !defenceCell.CastleEdge) || (!defenceCell.innerWall && skipOuterWalls))
		{
			return false;
		}
		if (Layout.GetAICell(cell).invalid)
		{
			return true;
		}
		if (cell.Type != TerrainType.Obstruction && cell.Type != TerrainType.EmptyCave && cell.Type != TerrainType.WolfDen && (!skipWaterCells || cell.Type != TerrainType.Water))
		{
			int num = -1;
			bool flag = false;
			for (int i = 0; i < buildIntentionStacks.Length; i++)
			{
				if (num == -1 && buildIntentionStacks[i].available)
				{
					num = i;
				}
				if (buildIntentionStacks[i].cell == cell)
				{
					flag = true;
					break;
				}
			}
			if (!flag && num != -1)
			{
				buildIntentionStacks[num].cell = cell;
				analyseCellDefense.Analyse(cell);
				int num2 = 0;
				bool flag2 = false;
				bool flag3 = false;
				bool flag4 = false;
				bool flag5 = IsTouchingGate(cell);
				bool flag6 = cornerCheck.IsExternalWallCorner(defenceCell, Layout);
				bool flag7 = IsWallJunction(defenceCell);
				bool num3 = !analyseCellDefense.hasArcherTower && !analyseCellDefense.hasBallistaTower;
				int num4 = 0;
				int num5 = 1;
				int globalThreatLevel = Kingdom.globalThreatLevel;
				string text;
				string uniqueName;
				if (globalThreatLevel > 3)
				{
					text = World.castleblockName;
					uniqueName = World.gateName;
					flag2 = analyseCellDefense.woodBlocks > 0 || analyseCellDefense.hasWoodGate;
					if (analyseCellDefense.stoneBlocks == 0 && !analyseCellDefense.hasStoneGate)
					{
						num2 = 1;
					}
					else
					{
						num5 = Mathff.Max(1, globalThreatLevel - 3);
						if (defenceCell.innerWall)
						{
							num5 += 2;
						}
						if ((flag6 | flag7) || analyseCellDefense.hasBallistaTower || ((Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Aggressive) & flag5))
						{
							num5++;
						}
						num4 = analyseCellDefense.stoneBlocks;
						if (analyseCellDefense.hasStoneGate)
						{
							num4 += 3;
							if (num5 < 3)
							{
								num5 = 3;
							}
						}
						num2 = num5 - num4;
					}
				}
				else
				{
					text = World.woodcastleblockName;
					uniqueName = World.woodengateName;
					flag2 = analyseCellDefense.stoneBlocks > 0 || analyseCellDefense.hasStoneGate;
					num5 = Mathff.Min(globalThreatLevel, 2);
					if (globalThreatLevel > 1)
					{
						num5 = ((!defenceCell.innerWall) ? (num5 - 1) : (num5 + 1));
					}
					if (flag6 | flag7)
					{
						num5++;
					}
					num4 = analyseCellDefense.woodBlocks;
					if (analyseCellDefense.hasWoodGate)
					{
						num4 += 3;
						if (num5 < 3)
						{
							num5 = 3;
						}
					}
					num2 = Mathff.Min(num5, 3) - num4;
				}
				if (num3 && (projectileTopperIntention == null || projectileTopperIntention.done))
				{
					int maxDistance = 5;
					if (Kingdom.rulerPersonality == AIKingdom.RulerPersonality.Aggressive)
					{
						maxDistance = 3;
					}
					if (flag5 && !flag7 && !flag6 && defenceCell.innerWall && globalThreatLevel > 4 && Player.inst.GetBuildingListForLandMass(LandMass, World.chamberOfWarHash).Count != 0)
					{
						flag4 = !projectileTopperCheck.IsNearProjectileTopper(maxDistance, defenceCell, Layout);
					}
					else if ((flag7 | flag6) || !defenceCell.innerWall)
					{
						flag3 = !projectileTopperCheck.IsNearProjectileTopper(maxDistance, defenceCell, Layout);
					}
				}
				Cell stairCell = null;
				bool flag8 = false;
				if (analyseCellDefense.hasGate && !IsBeingBuilt(World.castlestairsHash) && (stairIntention == null || stairIntention.done))
				{
					flag8 = CanPlaceStairs(defenceCell, out stairCell);
				}
				if (cell.OccupyingStructure.Count > 0 && analyseCellDefense.stoneBlocks == 0 && analyseCellDefense.woodBlocks == 0 && !analyseCellDefense.hasGate)
				{
					flag2 = true;
				}
				int j = 0;
				float num6 = (flag2 ? 0f : ((float)analyseCellDefense.height * 0.25f));
				bool flag9 = analyseCellDefense.hasGate && !flag2;
				if (num2 < 0 && !flag2)
				{
					bool flag10 = false;
					for (int num7 = cell.OccupyingStructure.Count - 1; num7 >= 0; num7--)
					{
						if ((cell.OccupyingStructure[num7].categoryHash == World.castleblockHash || cell.OccupyingStructure[num7].categoryHash == World.gateHash || cell.OccupyingStructure[num7].categoryHash == World.projectileTopperHash) && cell.OccupyingStructure[num7].CanDemolishBuilding())
						{
							World.inst.DemolishBuildingByAI(cell.OccupyingStructure[num7]);
							flag10 = true;
							num2++;
						}
						if (num2 == 0)
						{
							break;
						}
					}
					if (flag10)
					{
						BlockBuilding.MarkBlockStackDirty(cell);
					}
				}
				else
				{
					float angle;
					if (cell.Type == TerrainType.Water && !analyseCellDefense.hasSeaGate && cell.StructureFind(World.pierHash) == null && !cell.deepWater)
					{
						if (CellNeedsSeaGate(cell, out angle))
						{
							buildIntentionStacks[num].available = false;
							buildIntentionStacks[num].intentionStack[j] = AddSubIntention<Intention_BuildExactBuilding>("build " + World.seaGate);
							buildIntentionStacks[num].intentionStack[j].Init(World.seaGate, cell.Position, angle, flag2, skipPlacementValidation: true);
							buildIntentionStacks[num].intentionStack[j].ReadyForBuilding(ready: false);
							flag2 = false;
							j++;
							num2 = ((num2 > 3) ? (num2 - 3) : 0);
						}
						else
						{
							buildIntentionStacks[num].available = false;
							buildIntentionStacks[num].intentionStack[j] = AddSubIntention<Intention_BuildExactBuilding>("build " + World.pierName);
							buildIntentionStacks[num].intentionStack[j].Init(World.pierName, cell.Position, 0f, flag2);
							buildIntentionStacks[num].intentionStack[j].ReadyForBuilding(ready: false);
							flag2 = false;
							j++;
						}
					}
					if (num2 > 0 && !flag9 && Layout.CellNeedsGate(cell, out angle))
					{
						buildIntentionStacks[num].available = false;
						buildIntentionStacks[num].intentionStack[j] = AddSubIntention<Intention_BuildExactBuilding>("build " + text);
						buildIntentionStacks[num].intentionStack[j].Init(uniqueName, cell.Position + new Vector3(0f, num6, 0f), angle, flag2, skipPlacementValidation: true, roadHashes);
						buildIntentionStacks[num].intentionStack[j].ReadyForBuilding(ready: false);
						flag2 = false;
						j++;
						if (!cell.StructureFindByCategory(World.pathHash))
						{
							buildIntentionStacks[num].intentionStack[j] = AddSubIntention<Intention_BuildExactBuilding>("build road");
							buildIntentionStacks[num].intentionStack[j].Init(World.roadName, cell.Position, angle, demoExisting: false, skipPlacementValidation: true);
							buildIntentionStacks[num].intentionStack[j].ReadyForBuilding(ready: false);
						}
						num6 += 1.5f;
						j++;
						num2 -= 2;
					}
					for (; j < num2; j++)
					{
						buildIntentionStacks[num].available = false;
						buildIntentionStacks[num].intentionStack[j] = AddSubIntention<Intention_BuildExactBuilding>("build " + text);
						buildIntentionStacks[num].intentionStack[j].Init(text, cell.Position + new Vector3(0f, num6, 0f), 0f, flag2, skipPlacementValidation: true, aqueductHashes);
						buildIntentionStacks[num].intentionStack[j].ReadyForBuilding(ready: false);
						flag2 = false;
						num6 += 0.5f;
					}
					if ((flag4 | flag3) && num6 > 0f)
					{
						string text2 = (flag4 ? World.ballistaTowerName : World.archerTowerName);
						buildIntentionStacks[num].available = false;
						buildIntentionStacks[num].intentionStack[j] = AddSubIntention<Intention_BuildExactBuilding>("build " + text2 + " tower");
						buildIntentionStacks[num].intentionStack[j].Init(text2, cell.Position + new Vector3(0f, num6, 0f), 0f, demoExisting: false, skipPlacementValidation: true, aqueductHashes);
						buildIntentionStacks[num].intentionStack[j].ReadyForBuilding(ready: false);
						projectileTopperIntention = buildIntentionStacks[num].intentionStack[j];
						j++;
					}
					if (flag8)
					{
						buildIntentionStacks[num].available = false;
						buildIntentionStacks[num].intentionStack[j] = AddSubIntention<Intention_BuildExactBuilding>("build " + World.castlestairsName);
						buildIntentionStacks[num].intentionStack[j].Init(World.castlestairsName, stairCell.Position);
						buildIntentionStacks[num].intentionStack[j].ReadyForBuilding(ready: false);
						stairIntention = buildIntentionStacks[num].intentionStack[j];
					}
					if (!buildIntentionStacks[num].available)
					{
						stacksInProgress++;
					}
				}
			}
		}
		wallCrawler.AddAllNeighborsToOpenSet(cell);
		if (stacksInProgress >= buildIntentionStacks.Length || stacksInProgress >= stacksToUtilize)
		{
			return false;
		}
		return true;
	}

	public bool IsTouchingGate(Cell cell)
	{
		World.inst.GetNeighborCells(cell, ref scratchCells4);
		for (int i = 0; i < scratchCells4.Length; i++)
		{
			if (scratchCells4[i].StructureCompareCategoryNameAll(World.gateHash))
			{
				return true;
			}
		}
		return false;
	}

	public bool CanPlaceStairs(DefenseCell start, out Cell stairCell)
	{
		stairCell = null;
		Layout.GetNeighborDefenceCellsExtended(start, ref scratchDCells8);
		for (int i = 0; i < scratchDCells8.Length; i++)
		{
			DefenseCell defenseCell = scratchDCells8[i];
			if (!defenseCell.innerWall)
			{
				continue;
			}
			Cell cellData = World.inst.GetCellData(defenseCell.x, defenseCell.z);
			if (cellData.Type != TerrainType.None)
			{
				continue;
			}
			bool flag = true;
			for (int j = 0; j < cellData.OccupyingStructure.Count; j++)
			{
				if (cellData.OccupyingStructure[j].categoryHash != World.pathHash && cellData.OccupyingStructure[j].uniqueNameHash != World.aqueductHash)
				{
					flag = false;
					break;
				}
			}
			if (!flag)
			{
				continue;
			}
			World.inst.GetNeighborCells(cellData, ref scratchCells4);
			for (int k = 0; k < scratchCells4.Length; k++)
			{
				if (scratchCells4[k].StructureCompareCategoryNameAll(World.castleblockHash))
				{
					stairCell = cellData;
					break;
				}
			}
			if (stairCell == null)
			{
				continue;
			}
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.castlestairsHash);
			for (int l = 0; l < buildingListForLandMass.Count; l++)
			{
				if (Mathff.DistSqrdXZ(stairCell.Position, buildingListForLandMass.data[l].GetPosition()) < 50f)
				{
					stairCell = null;
					break;
				}
			}
			if (stairCell != null)
			{
				return true;
			}
		}
		return false;
	}

	public bool IsWallJunction(DefenseCell dCell)
	{
		if (!dCell.CastleEdge)
		{
			return false;
		}
		Layout.GetNeighborDefenceCellsExtended(dCell, ref scratchDCells8);
		if (scratchDCells8[0].CastleEdge || scratchDCells8[2].CastleEdge || scratchDCells8[5].CastleEdge || scratchDCells8[7].CastleEdge)
		{
			return false;
		}
		int num = 0;
		if (scratchDCells8[1].CastleEdge)
		{
			num++;
		}
		if (scratchDCells8[3].CastleEdge)
		{
			num++;
		}
		if (scratchDCells8[4].CastleEdge)
		{
			num++;
		}
		if (scratchDCells8[6].CastleEdge)
		{
			num++;
		}
		return num > 2;
	}

	public bool CellNeedsSeaGate(Cell targetCell, out float angle)
	{
		angle = 0f;
		edgeOpenSet.Clear();
		if (!CanPlaceSeagate(targetCell))
		{
			return false;
		}
		if (isCastleEdge[0] && isCastleEdge[2])
		{
			AddSeagateNeighbors(targetCell.Position, Vector3.right);
			edgeOpenSet.Add(targetCell);
			AddSeagateNeighbors(targetCell.Position, Vector3.left);
			if (edgeOpenSet.Count <= 2)
			{
				angle = ((edgeOpenSet[0] == targetCell) ? 90 : (-90));
				return true;
			}
			int num = Mathf.CeilToInt((float)edgeOpenSet.Count / 2f);
			if (edgeOpenSet[num] == targetCell)
			{
				angle = -90f;
				return true;
			}
			if (edgeOpenSet[num - 1] == targetCell)
			{
				angle = 90f;
				return true;
			}
		}
		if (isCastleEdge[1] && isCastleEdge[3])
		{
			AddSeagateNeighbors(targetCell.Position, Vector3.forward);
			edgeOpenSet.Add(targetCell);
			AddSeagateNeighbors(targetCell.Position, Vector3.back);
			if (edgeOpenSet.Count <= 2)
			{
				angle = ((edgeOpenSet[0] != targetCell) ? 180 : 0);
				return true;
			}
			int num2 = Mathf.CeilToInt((float)edgeOpenSet.Count / 2f);
			if (edgeOpenSet[num2] == targetCell)
			{
				angle = 180f;
				return true;
			}
			if (edgeOpenSet[num2 - 1] == targetCell)
			{
				angle = 0f;
				return true;
			}
		}
		return false;
	}

	private void AddSeagateNeighbors(Vector3 origPos, Vector3 dirPos)
	{
		origPos += dirPos;
		tempCell = World.inst.GetCellData(origPos);
		while (CanPlaceSeagate(tempCell))
		{
			edgeOpenSet.Add(tempCell);
			origPos += dirPos;
			tempCell = World.inst.GetCellData(origPos);
		}
	}

	public bool CanPlaceSeagate(Cell targetCell)
	{
		World.inst.GetNeighborCells(targetCell, ref scratchCells4);
		Layout.GetNeighborDefenceCells(Layout.GetDefenceCell(targetCell), ref scratchDCells4);
		for (int i = 0; i < scratchCells4.Length; i++)
		{
			if (scratchCells4[i] != null)
			{
				isCastleEdge[i] = scratchDCells4[i]?.CastleEdge ?? false;
			}
		}
		if (isCastleEdge[0] && isCastleEdge[2] && IsEmptyWaterCell(scratchCells4[1]) && IsEmptyWaterCell(scratchCells4[3]))
		{
			return true;
		}
		if (isCastleEdge[1] && isCastleEdge[3] && IsEmptyWaterCell(scratchCells4[0]) && IsEmptyWaterCell(scratchCells4[2]))
		{
			return true;
		}
		return false;
	}

	private bool IsEmptyWaterCell(Cell cell)
	{
		DefenseCell defenceCell = Layout.GetDefenceCell(cell);
		AICell aICell = Layout.GetAICell(cell);
		if (aICell != null && aICell.blockReference != null && aICell.blockReference.layoutType != AIBuildingBlockType.Any)
		{
			return false;
		}
		if (defenceCell != null && !defenceCell.CastleEdge && cell.Type == TerrainType.Water && (cell.OccupyingStructure.Count == 0 || (bool)cell.StructureFind(World.dockHash) || (bool)cell.StructureFind(World.drawBridgeHash) || (bool)cell.StructureFindByCategory(World.shipHash)))
		{
			return true;
		}
		return false;
	}
}
