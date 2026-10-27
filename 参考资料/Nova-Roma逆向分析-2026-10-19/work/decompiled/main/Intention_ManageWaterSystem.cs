using System;
using System.Collections.Generic;
using UnityEngine;

public class Intention_ManageWaterSystem : AIIntentionBase
{
	private Intention_BuildExactBuilding buildNoriaIntention;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Vector3 lastNoria;

	public bool CompletelyOutOfSpaceForNoria;

	private bool[] visited;

	private List<Cell> openSet = new List<Cell>();

	private bool CompletelyOutOfSpaceForNoriaBlock;

	private Intention_BuildPreplannedBuilding noriaIntention;

	private Intention_BuildPreplannedBuilding[] moatIntentions;

	private bool isProcessingNoriaBlock;

	private bool needToConnectAquaducts;

	private float noAqueductActivityTime;

	private Timer timer = new Timer(10f);

	private int lastSubIntentionCount;

	private float bonusPriority;

	private ArrayExt<Vector3> scratch = new ArrayExt<Vector3>(32);

	private Building buildingInNeedOfWater;

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		lastNoria = Layout.KingdomStart;
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() == LandMass && !obj.added && obj.targetBuilding.categoryHash == World.noriaHash)
		{
			CompletelyOutOfSpaceForNoria = false;
		}
	}

	private bool TestCell(int x, int z)
	{
		Cell cellData = World.inst.GetCellData(x, z);
		if (!Layout.GetDefenceCell(x, z).CastleEdge && cellData.Type == TerrainType.Water && !cellData.saltWater && cellData.OccupyingStructure.Count == 0)
		{
			return cellData.SubStructure.Count == 0;
		}
		return false;
	}

	private int ValidForNoria(Cell c)
	{
		if (c.Type == TerrainType.None && Layout.GetAICell(c).buildingMeta == null && !Layout.GetDefenceCell(c).CastleEdge)
		{
			if (TestCell(c.x - 1, c.z - 1) && TestCell(c.x, c.z - 1) && TestCell(c.x + 1, c.z - 1))
			{
				return 90;
			}
			if (TestCell(c.x - 1, c.z + 1) && TestCell(c.x, c.z + 1) && TestCell(c.x + 1, c.z + 1))
			{
				return -90;
			}
			if (TestCell(c.x - 1, c.z - 1) && TestCell(c.x - 1, c.z) && TestCell(c.x - 1, c.z + 1))
			{
				return 180;
			}
			if (TestCell(c.x + 1, c.z - 1) && TestCell(c.x + 1, c.z) && TestCell(c.x + 1, c.z + 1))
			{
				return 0;
			}
		}
		return -1;
	}

	public void FindNoriaPosition(ref Cell cell, ref int rot, Vector3 referencePos)
	{
		if (CompletelyOutOfSpaceForNoria)
		{
			return;
		}
		int gridWidth = World.inst.GridWidth;
		if (visited == null)
		{
			visited = new bool[gridWidth * World.inst.GridHeight];
		}
		for (int i = 0; i < visited.Length; i++)
		{
			visited[i] = false;
		}
		openSet.Clear();
		openSet.Add(World.inst.GetCellDataClamped(referencePos));
		while (openSet.Count > 0)
		{
			Cell cell2 = openSet[0];
			openSet.RemoveAt(0);
			int num = cell2.z * gridWidth + cell2.x;
			if (!visited[num])
			{
				visited[num] = true;
				int num2 = ValidForNoria(cell2);
				if (num2 != -1)
				{
					cell = cell2;
					rot = num2;
					openSet.Clear();
					return;
				}
				if (cell2.Type != TerrainType.Water)
				{
					openSet.Add(World.inst.GetCellData(cell2.x + 1, cell2.z));
					openSet.Add(World.inst.GetCellData(cell2.x, cell2.z + 1));
					openSet.Add(World.inst.GetCellData(cell2.x - 1, cell2.z));
					openSet.Add(World.inst.GetCellData(cell2.x, cell2.z - 1));
				}
			}
		}
		if (!CompletelyOutOfSpaceForNoria && !isProcessingNoriaBlock)
		{
			if (!CompletelyOutOfSpaceForNoriaBlock)
			{
				OnOutOfSpaceForNoria(referencePos);
			}
			else
			{
				CompletelyOutOfSpaceForNoria = true;
			}
		}
		openSet.Clear();
	}

	private void OnOutOfSpaceForNoria(Vector3 referencePos)
	{
		AILayoutBlock newBlock = null;
		if (Layout.PlaceNewBlockContainingUniqueName(World.noriaName, out newBlock, (int)referencePos.x, (int)referencePos.z, 10))
		{
			if (moatIntentions == null)
			{
				moatIntentions = new Intention_BuildPreplannedBuilding[3];
			}
			for (int i = 0; i < moatIntentions.Length; i++)
			{
				moatIntentions[i] = ManagerReference.AddIntention<Intention_BuildPreplannedBuilding>("build moat");
				moatIntentions[i].InitFastest(World.moatName, AIBuildingBlockType.Civic);
			}
			isProcessingNoriaBlock = true;
		}
		else
		{
			CompletelyOutOfSpaceForNoriaBlock = true;
			isProcessingNoriaBlock = false;
		}
	}

	private void TryBuildNoria(Vector3 refPos, out Cell c)
	{
		c = null;
		if (buildNoriaIntention == null && !IsBeingBuilt(World.noriaHash))
		{
			int rot = 0;
			FindNoriaPosition(ref c, ref rot, refPos);
			if (c != null)
			{
				buildNoriaIntention = AddSubIntention<Intention_BuildExactBuilding>("build noria");
				buildNoriaIntention.Init("noria", c.Position, rot, demoExisting: true, skipPlacementValidation: true);
				lastNoria = c.Position;
			}
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = (int)Mathff.Min(60f + bonusPriority, 65f);
		if (subIntentions.Count == 0)
		{
			noAqueductActivityTime += dt;
		}
		else
		{
			noAqueductActivityTime = 0f;
		}
		if (timer.Update(dt))
		{
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.bathhouseHash);
			ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(LandMass, World.reservoirHash);
			ArrayExt<Building> buildingListForLandMass3 = Player.inst.GetBuildingListForLandMass(LandMass, World.noriaHash);
			int num = 0;
			for (int i = 0; i < buildingListForLandMass3.Count; i++)
			{
				if (buildingListForLandMass3.data[i].WorkersAllocated == buildingListForLandMass3.data[i].WorkersForFullYield)
				{
					num++;
				}
			}
			if (buildingListForLandMass3.Count > 0)
			{
				lastNoria = buildingListForLandMass3.data[buildingListForLandMass3.Count - 1].Center();
			}
			if (buildingListForLandMass.Count + buildingListForLandMass2.Count > 0 && buildingListForLandMass3.Count == 0)
			{
				Vector3 refPos = lastNoria;
				if (buildingListForLandMass.Count > 0)
				{
					refPos = buildingListForLandMass.data[0].Center();
				}
				else if (buildingListForLandMass2.Count > 0)
				{
					refPos = buildingListForLandMass2.data[0].Center();
				}
				Cell c = null;
				TryBuildNoria(refPos, out c);
			}
			if (num == buildingListForLandMass3.Count && buildingListForLandMass3.Count > 0 && noAqueductActivityTime > 0.25f)
			{
				for (int j = 0; j < buildingListForLandMass.Count; j++)
				{
					Building building = buildingListForLandMass.data[j];
					IWaterSystemUser component = building.GetComponent<IWaterSystemUser>();
					CheckForNoria(building, component, buildingListForLandMass3);
				}
				for (int k = 0; k < buildingListForLandMass2.Count; k++)
				{
					Building building2 = buildingListForLandMass2.data[k];
					IWaterSystemUser component2 = building2.GetComponent<IWaterSystemUser>();
					CheckForNoria(building2, component2, buildingListForLandMass3);
				}
			}
		}
		if (subIntentions.Count == lastSubIntentionCount && lastSubIntentionCount > 0)
		{
			bonusPriority += dt * 0.1f;
		}
		else
		{
			bonusPriority = 0f;
		}
		lastSubIntentionCount = subIntentions.Count;
		if (isProcessingNoriaBlock)
		{
			if (noriaIntention != null)
			{
				CompletelyOutOfSpaceForNoriaBlock = noriaIntention.failType != FailType.None;
				isProcessingNoriaBlock = !noriaIntention.done;
				return;
			}
			bool flag = true;
			for (int l = 0; l < moatIntentions.Length; l++)
			{
				if (moatIntentions[l] != null && moatIntentions[l].failType != FailType.None)
				{
					Debug.Log("FAILED TO PLACE MOAT!!!!");
				}
				if (!(moatIntentions[l] == null) && !moatIntentions[l].done)
				{
					flag = false;
					break;
				}
			}
			if (flag)
			{
				noriaIntention = ManagerReference.AddIntention<Intention_BuildPreplannedBuilding>("build noria");
				noriaIntention.InitFastest(World.noriaName, AIBuildingBlockType.Civic);
			}
		}
		for (int m = 0; m < subIntentions.Count; m++)
		{
			if (subIntentions[m] != null && subIntentions[m].Done)
			{
				DestroyIntention(subIntentions[m]);
			}
		}
	}

	public bool BuildOutAqueduct(Cell start, Cell end)
	{
		Layout.FindAqueductPath(start, end, ref scratch);
		if (scratch.Count == 0)
		{
			return false;
		}
		for (int i = 0; i < scratch.Count; i++)
		{
			Cell cellData = World.inst.GetCellData(scratch.data[i]);
			if (cellData.StructureCompareUniqueNameAll(World.noriaHash) || cellData.StructureCompareUniqueNameAll(World.aqueductHash) || cellData.StructureCompareUniqueNameAll(World.reservoirHash) || cellData.StructureCompareUniqueNameAll(World.bathhouseHash))
			{
				continue;
			}
			bool flag = false;
			for (int j = 0; j < subIntentions.Count; j++)
			{
				Intention_BuildAqueduct intention_BuildAqueduct = subIntentions[j] as Intention_BuildAqueduct;
				if (intention_BuildAqueduct != null && intention_BuildAqueduct.targetCell == cellData)
				{
					flag = true;
				}
			}
			if (!flag)
			{
				AddSubIntention<Intention_BuildAqueduct>("build aqueduct").Init(cellData);
				DebugEx.DrawCircleXZ(scratch.data[i], 0.5f, Color.cyan);
				DebugEx.DrawCircleXZ(scratch.data[i] + new Vector3(0f, 0.5f, 0f), 0.5f, Color.cyan);
				DebugEx.DrawCircleXZ(scratch.data[i] + new Vector3(0f, 1f, 0f), 0.5f, Color.cyan);
			}
		}
		return true;
	}

	public void CheckForNoria(Building building, IWaterSystemUser wsu, ArrayExt<Building> norias)
	{
		if (building == null)
		{
			return;
		}
		if (!wsu.IsConnected)
		{
			float num = float.MaxValue;
			Building building2 = norias.data[0];
			for (int i = 0; i < norias.Count; i++)
			{
				float num2 = Mathff.DistSqrdXZ(norias.data[i].GetComponent<Noria>().basePos.position, building.Center());
				AICell aICell = Layout.GetAICell(norias.data[i].GetCell());
				if (num > num2 && (aICell.buildingMeta == null || aICell.Road))
				{
					num = num2;
					building2 = norias.data[i];
				}
			}
			Cell cell = null;
			int rot = 0;
			FindNoriaPosition(ref cell, ref rot, building.Center());
			Cell start;
			Vector3 position;
			if (cell != null && num > Mathff.DistSqrdXZ(cell.Center2D, building.Center()) + 100f)
			{
				start = cell;
				position = cell.Position;
				buildNoriaIntention = AddSubIntention<Intention_BuildExactBuilding>("build noria");
				buildNoriaIntention.Init("noria", cell.Position, rot, demoExisting: true, skipPlacementValidation: true);
			}
			else
			{
				position = building2.GetComponent<Noria>().basePos.position;
				start = World.inst.GetCellData(position);
			}
			Vector3 worldPos = ((building.uniqueNameHash == World.bathhouseHash) ? GetClosestEdgeToNoria(building, position) : building.GetPosition());
			Cell cellData = World.inst.GetCellData(worldPos);
			BuildOutAqueduct(start, cellData);
			needToConnectAquaducts = false;
		}
		else if (!wsu.HasWater && buildNoriaIntention == null)
		{
			Cell c = null;
			TryBuildNoria(building.Center(), out c);
			if (c != null)
			{
				Vector3 worldPos2 = ((building.uniqueNameHash == World.bathhouseHash) ? GetClosestEdgeToNoria(building, c.Position) : building.GetPosition());
				Cell cellData2 = World.inst.GetCellData(worldPos2);
				BuildOutAqueduct(c, cellData2);
			}
		}
	}

	public Vector3 GetClosestEdgeToNoria(Building building, Vector3 noriaCenter)
	{
		Vector3 result = Vector3.zero;
		float num = float.MaxValue;
		building.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		minX--;
		minZ--;
		maxX++;
		maxZ++;
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				if ((j != minX && i != minZ && j != maxX && i != maxZ) || (j == minX && i == minZ) || (j == minX && i == maxZ) || (i == minZ && j == maxX) || (i == maxZ && j == maxX))
				{
					continue;
				}
				PathCell pathCell = World.inst.GetPathCell(j, i);
				if (!Layout.AqueductBlocksPathTest(pathCell, -1))
				{
					Vector3 vector = new Vector3(j, 0f, i);
					float num2 = Mathff.DistSqrdXZ(noriaCenter, vector);
					if (num2 < num)
					{
						num = num2;
						result = vector;
					}
				}
			}
		}
		return result;
	}
}
