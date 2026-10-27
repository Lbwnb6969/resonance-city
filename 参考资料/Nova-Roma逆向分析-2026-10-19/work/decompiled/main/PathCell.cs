using System.Runtime.CompilerServices;
using UnityEngine;

public class PathCell
{
	public Vector3 Center;

	public int x;

	public int z;

	public TerrainType Type;

	public int[] villagerFootPathCost = new int[5];

	public int[] envoyFootPathCost = new int[5];

	public int[] waterPathCost = new int[5];

	public int ogreFootPathCost;

	public int hydraFootPathCost;

	public int wolfFootPathPenalty;

	public int wolfVikingFootPathPenalty;

	public bool[] pathBlockedForArmies = new bool[5];

	public bool[] pathBlockedForEnvoys = new bool[5];

	public bool isStairs;

	public bool isUpperGridBlocked = true;

	public bool[] waterPathBlocked = new bool[5];

	public bool blocksPathOgres;

	public bool blocksPathHydra;

	public bool blocksTransportCart;

	public bool isPathCell;

	public int hydraBlockingCost;

	public int unitBlockCost;

	public static int footPathDeepWaterCost = 5000;

	public static int footPathObstructionCost = 15000;

	public static int buildingFootpathCost = 350;

	public static int wallBlockedCost = 1250;

	public static int waterBlockedCost = 5000;

	public PathCell(int _x, int _z)
	{
		x = _x;
		z = _z;
		Center.x = (float)x + 0.5f;
		Center.y = 0f;
		Center.z = (float)z + 0.5f;
	}

	public static bool NoBlock(PathCell cell, int teamId)
	{
		return false;
	}

	public static void ApplyBlocksFootPathForEnvoys(PathCell pc, Cell cell, int teamId)
	{
		pc.pathBlockedForEnvoys[teamId] = pc.pathBlockedForArmies[teamId];
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (building.categoryHash == World.gateHash || building.uniqueNameHash == World.drawBridgeHash || building.uniqueNameHash == World.keepHash)
			{
				pc.pathBlockedForEnvoys[teamId] = false;
				break;
			}
		}
	}

	public static void ApplyBlocksFootPathForArmies(PathCell pc, Cell cell, int teamId)
	{
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (building.categoryHash == World.gateHash || building.uniqueNameHash == World.romanOutpostHash || building.uniqueNameHash == World.romanOutpostHashNewIsland || building.uniqueNameHash == World.drawBridgeHash)
			{
				if ((building.categoryHash == World.gateHash || building.uniqueNameHash == World.drawBridgeHash) && building.ConstructionForeman.ConstructionProgress < 0.3f)
				{
					pc.pathBlockedForArmies[teamId] = false;
				}
				else if (World.inst.RelationBetween(World.GetLandmassOwner(cell.landMassIdx).teamId, teamId) != World.Relations.Allies)
				{
					pc.pathBlockedForArmies[teamId] = true;
				}
				else
				{
					pc.pathBlockedForArmies[teamId] = false;
				}
				return;
			}
		}
		if (cell.Type == TerrainType.Obstruction || cell.Type == TerrainType.Water)
		{
			pc.pathBlockedForArmies[teamId] = true;
			return;
		}
		for (int j = 0; j < cell.OccupyingStructure.Count; j++)
		{
			Building building2 = cell.OccupyingStructure[j];
			if ((building2.categoryHash == World.castleblockHash || building2.categoryHash == World.noriaHash) && (building2.IsBuilt() || building2.ConstructionForeman.ConstructionProgress >= 0.3f))
			{
				pc.pathBlockedForArmies[teamId] = true;
				return;
			}
		}
		pc.pathBlockedForArmies[teamId] = false;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static bool GetBlocksFootPathForEnvoys(PathCell c, int teamId)
	{
		return c.pathBlockedForEnvoys[teamId];
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static bool GetBlocksFootPathForArmies(PathCell c, int teamId)
	{
		return c.pathBlockedForArmies[teamId];
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static bool GetBlocksFootPathForHydra(PathCell cell, int teamId)
	{
		return cell.blocksPathHydra;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static bool GetBlocksFootPathForOgres(PathCell cell, int teamId)
	{
		return cell.blocksPathOgres;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static bool GetBlocksFootPathForTransportCart(PathCell cell, int teamId)
	{
		return cell.blocksTransportCart;
	}

	public static void ApplyBlocksFootPathForOgres(PathCell pc, Cell cell)
	{
		if (GetBlocksFootPathForArmies(pc, 1))
		{
			pc.blocksPathOgres = true;
			return;
		}
		if (cell.StructureGetCategoryHash() == World.pathHash)
		{
			pc.blocksPathOgres = false;
			return;
		}
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			if (SiegeMonster.ShouldIgnore(cell.OccupyingStructure[i]))
			{
				pc.blocksPathOgres = false;
				return;
			}
		}
		for (int j = 0; j < cell.SubStructure.Count; j++)
		{
			if (SiegeMonster.ShouldIgnore(cell.SubStructure[j]))
			{
				pc.blocksPathOgres = false;
				return;
			}
		}
		if (cell.OccupyingStructure.Count > 0)
		{
			pc.blocksPathOgres = true;
		}
		else
		{
			pc.blocksPathOgres = false;
		}
	}

	public static void ApplyBlocksFootPathForHydra(PathCell pc, Cell cell)
	{
		if (cell.StructureGetCategoryHash() == World.pathHash)
		{
			pc.blocksPathHydra = false;
			return;
		}
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			if (SiegeMonster.ShouldIgnore(cell.OccupyingStructure[i]))
			{
				pc.blocksPathHydra = false;
				return;
			}
		}
		if (cell.OccupyingStructure.Count > 0)
		{
			pc.blocksPathHydra = true;
		}
		else
		{
			pc.blocksPathHydra = false;
		}
	}

	public static void ApplyBlocksFootPathForTransportCart(PathCell pd, Cell cell)
	{
		if (cell.OccupyingStructure.Count > 0)
		{
			pd.blocksTransportCart = true;
			for (int i = 0; i < cell.OccupyingStructure.Count; i++)
			{
				if (cell.OccupyingStructure[i].transportCartsCanTravelOn)
				{
					pd.blocksTransportCart = false;
					break;
				}
			}
		}
		else
		{
			pd.blocksTransportCart = cell.Type != TerrainType.None;
		}
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int GetOgreFootPathCost(PathCell cell, int teamId)
	{
		return cell.ogreFootPathCost + cell.wolfVikingFootPathPenalty;
	}

	public static void ApplyOgreFootPathCost(PathCell pc, Cell cell)
	{
		int num = cell.StructureGetUniqueNameHash();
		if (cell.StructureGetCategoryHash() == World.pathHash)
		{
			pc.ogreFootPathCost = 0;
		}
		else if (num == World.farmHash || num == World.orchardHash || num == World.townsquareHash || num == World.wellHash || num == World.rubbleHash)
		{
			pc.ogreFootPathCost = 0;
		}
		else if (cell.Type == TerrainType.Water)
		{
			if (cell.deepWater)
			{
				pc.ogreFootPathCost = footPathDeepWaterCost;
			}
			else
			{
				pc.ogreFootPathCost = 5;
			}
		}
		else if (cell.OccupyingStructure.Count > 0)
		{
			pc.ogreFootPathCost = 10;
		}
		else if (cell.Type == TerrainType.Obstruction)
		{
			pc.ogreFootPathCost = footPathObstructionCost;
		}
		else
		{
			pc.ogreFootPathCost = 0;
		}
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int GetHydraFootPathCost(PathCell cell, int teamId)
	{
		return cell.hydraFootPathCost;
	}

	public static void ApplyHydraBlockingCost(PathCell pc, Cell cell)
	{
	}

	public static void ApplyHydraFootPathCost(PathCell pc, Cell cell)
	{
		int num = cell.StructureGetUniqueNameHash();
		if (cell.StructureGetCategoryHash() == World.pathHash)
		{
			pc.hydraFootPathCost = 0;
		}
		else if (num == World.farmHash || num == World.orchardHash || num == World.townsquareHash || num == World.wellHash || num == World.rubbleHash)
		{
			pc.hydraFootPathCost = 0;
		}
		else if (cell.Type == TerrainType.Water)
		{
			pc.hydraFootPathCost = 5;
		}
		else if (cell.OccupyingStructure.Count > 0 && !SiegeMonster.ShouldIgnore(cell.OccupyingStructure[0]))
		{
			pc.hydraFootPathCost = 5000;
		}
		else if (cell.Type == TerrainType.Obstruction)
		{
			pc.hydraFootPathCost = 5000;
		}
		else
		{
			pc.hydraFootPathCost = 0;
		}
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int GetFootPathCost(PathCell cell, int teamId)
	{
		return cell.villagerFootPathCost[teamId] + cell.wolfFootPathPenalty + cell.hydraBlockingCost;
	}

	public static void ApplyEnvoyFootPathCost(PathCell pc, Cell cell, int teamId)
	{
		pc.envoyFootPathCost[teamId] = pc.villagerFootPathCost[teamId];
		if (GetBlocksFootPathForArmies(pc, teamId) && !cell.StructureCompareCategoryNameAll(World.pathHash))
		{
			pc.envoyFootPathCost[teamId] = 10000;
		}
		int i = 0;
		for (int count = cell.OccupyingStructure.Count; i < count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			int categoryHash = building.categoryHash;
			int uniqueNameHash = building.uniqueNameHash;
			if (categoryHash == World.gateHash || uniqueNameHash == World.drawBridgeHash)
			{
				pc.envoyFootPathCost[teamId] = 18;
				break;
			}
		}
	}

	public static void ApplyPathCategoryCostHelper(int nameHash, PathCell pc, Cell cell, int teamId)
	{
		if (nameHash == World.gardenHash)
		{
			pc.villagerFootPathCost[teamId] = 2;
		}
		else if (nameHash == World.stoneRoadHash || nameHash == World.stoneBridgeHash)
		{
			pc.villagerFootPathCost[teamId] = 0;
		}
		else if (nameHash == World.drawBridgeHash && cell.BottomStructure.GetComponent<DrawBridge>().wasOpen)
		{
			pc.villagerFootPathCost[teamId] = 250;
		}
		else
		{
			pc.villagerFootPathCost[teamId] = 1;
		}
	}

	public static void ApplyFootPathCost(PathCell pc, Cell cell, int teamId)
	{
		if (cell.Type == TerrainType.Water && cell.deepWater)
		{
			pc.villagerFootPathCost[teamId] = footPathDeepWaterCost;
			return;
		}
		int num = cell.StructureGetUniqueNameHash();
		int num2 = cell.StructureGetCategoryHash();
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			if (cell.OccupyingStructure[i].categoryHash == World.gateHash)
			{
				if (World.inst.RelationBetween(World.GetLandmassOwner(cell.landMassIdx).teamId, teamId) != World.Relations.Allies)
				{
					pc.villagerFootPathCost[teamId] = 350;
				}
				else if (cell.StructureCompareCategoryNameAll(World.pathHash) && cell.OccupyingStructure[0].IsBuilt())
				{
					ApplyPathCategoryCostHelper(num, pc, cell, teamId);
				}
				else
				{
					pc.villagerFootPathCost[teamId] = 13;
				}
				return;
			}
		}
		if (num2 == World.pathHash && cell.OccupyingStructure[0].IsBuilt())
		{
			ApplyPathCategoryCostHelper(num, pc, cell, teamId);
			return;
		}
		if (num == World.townsquareHash || num2 == World.fountainHash || num2 == World.forumHash)
		{
			pc.villagerFootPathCost[teamId] = 1;
			return;
		}
		if (num2 == World.editTerrainZoneHash)
		{
			pc.villagerFootPathCost[teamId] = 13;
			return;
		}
		if (num2 == World.farmHash || num == World.reservoirHash || num == World.wellHash || num2 == World.rubbleHash || num2 == World.cemeteryHash)
		{
			pc.villagerFootPathCost[teamId] = 15;
			return;
		}
		if (num == World.castlestairsHash)
		{
			pc.villagerFootPathCost[teamId] = 2;
			return;
		}
		if (cell.StructureCompareCategoryNameAll(World.castleblockHash) || cell.StructureCompareUniqueNameAll(World.noriaHash))
		{
			if (cell.BottomStructure.IsBuilt() || cell.BottomStructure.ConstructionForeman.ConstructionProgress >= 0.3f)
			{
				pc.villagerFootPathCost[teamId] = wallBlockedCost;
			}
			return;
		}
		if (cell.Type == TerrainType.Water)
		{
			pc.villagerFootPathCost[teamId] = wallBlockedCost * 6;
			PathCell pathCellClamped = World.inst.GetPathCellClamped(cell.x, cell.z + 1);
			int num3 = 0 | ((pathCellClamped.Type == TerrainType.None && pathCellClamped.Type != TerrainType.Obstruction) ? 1 : 0);
			pathCellClamped = World.inst.GetPathCellClamped(cell.x, cell.z - 1);
			int num4 = num3 | ((pathCellClamped.Type == TerrainType.None && pathCellClamped.Type != TerrainType.Obstruction) ? 1 : 0);
			pathCellClamped = World.inst.GetPathCellClamped(cell.x + 1, cell.z);
			int num5 = num4 | ((pathCellClamped.Type == TerrainType.None && pathCellClamped.Type != TerrainType.Obstruction) ? 1 : 0);
			pathCellClamped = World.inst.GetPathCellClamped(cell.x - 1, cell.z);
			if (((uint)num5 | ((pathCellClamped.Type == TerrainType.None && pathCellClamped.Type != TerrainType.Obstruction) ? 1u : 0u)) != 0)
			{
				pc.villagerFootPathCost[teamId] = wallBlockedCost * 4;
			}
			return;
		}
		if (cell.Type == TerrainType.Obstruction)
		{
			bool flag = false;
			if (cell.HasAccessibleTerrainResourceType(14) && cell.terrainResource.meshFilter.transform.localScale.x < 1.9f && cell.terrainResource.meshFilter.transform.localScale.z < 1.9f)
			{
				flag = true;
			}
			if (!flag)
			{
				pc.villagerFootPathCost[teamId] = footPathObstructionCost;
			}
			return;
		}
		float num6 = DynamicWater.inst.simplifiedWaterGrid[cell.index];
		if (num6 > 0f)
		{
			if (num6 >= 0.25f)
			{
				pc.villagerFootPathCost[teamId] = 500;
			}
			else if (num6 >= 0.1f)
			{
				pc.villagerFootPathCost[teamId] = 225;
			}
			else
			{
				pc.villagerFootPathCost[teamId] = 125;
			}
		}
		else if (num == World.statueArchHash || num == World.statueSmallArchHash)
		{
			pc.villagerFootPathCost[teamId] = 1;
		}
		else if (num2 == World.waterTowerHash)
		{
			pc.villagerFootPathCost[teamId] = 13;
		}
		else if (cell.OccupyingStructure.Count > 0)
		{
			pc.villagerFootPathCost[teamId] = buildingFootpathCost;
		}
		else if (cell.SubStructure.Count > 0 && cell.TopSubStructure.uniqueNameHash == World.pierHash)
		{
			pc.villagerFootPathCost[teamId] = 16;
		}
		else
		{
			pc.villagerFootPathCost[teamId] = 13;
		}
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static bool GetBlocksWaterPath(PathCell cell, int teamId)
	{
		return cell.waterPathBlocked[teamId];
	}

	public static void ApplyBlocksWaterPath(PathCell pc, Cell cell, int teamId)
	{
		if (cell.Type == TerrainType.Water && cell.deepWater)
		{
			pc.waterPathBlocked[teamId] = false;
			return;
		}
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (building.uniqueNameHash == World.seagateHash)
			{
				if (building.ConstructionForeman.ConstructionProgress < 0.3f)
				{
					pc.waterPathBlocked[teamId] = false;
				}
				else if (World.inst.RelationBetween(World.GetLandmassOwner(cell.landMassIdx).teamId, teamId) == World.Relations.Enemy)
				{
					pc.waterPathBlocked[teamId] = true;
				}
				else
				{
					pc.waterPathBlocked[teamId] = false;
				}
				return;
			}
		}
		if (cell.Type != TerrainType.Water)
		{
			pc.waterPathBlocked[teamId] = true;
			return;
		}
		int num = cell.StructureGetUniqueNameHash();
		if (num == World.dockHash || num == World.transportShipPortHash || num == World.fishinghutHash || num == World.stoneBridgeHash || num == World.woodBridgeHash)
		{
			pc.waterPathBlocked[teamId] = true;
			return;
		}
		Building topSubStructure = cell.TopSubStructure;
		if (topSubStructure != null && topSubStructure.uniqueNameHash == World.pierHash)
		{
			pc.waterPathBlocked[teamId] = true;
		}
		else if (num == World.woodBridgeHash || num == World.stoneBridgeHash)
		{
			pc.waterPathBlocked[teamId] = true;
		}
		else
		{
			pc.waterPathBlocked[teamId] = false;
		}
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int GetBoatPathCost(PathCell cell, int teamId)
	{
		return cell.waterPathCost[teamId];
	}

	public static void ApplyWaterPathCost(PathCell pc, Cell cell, int teamId)
	{
		if (GetBlocksWaterPath(pc, teamId))
		{
			if (GetBlocksFootPathForArmies(pc, teamId))
			{
				if (cell.StructureCompareCategoryNameAll(World.gateHash))
				{
					pc.waterPathCost[teamId] = waterBlockedCost + 2000;
				}
				else
				{
					pc.waterPathCost[teamId] = waterBlockedCost + 9990000;
				}
			}
			else if (cell.StructureCompareCategoryNameAll(World.pathHash))
			{
				pc.waterPathCost[teamId] = waterBlockedCost - 10;
			}
			else if (cell.OccupyingStructure.Count > 0)
			{
				pc.waterPathCost[teamId] = waterBlockedCost + 1000;
			}
			else
			{
				pc.waterPathCost[teamId] = waterBlockedCost + 500;
			}
		}
		else if (cell.deepWater)
		{
			pc.waterPathCost[teamId] = 0;
		}
		else if (cell.SubStructure.Count > 0 && cell.SubStructure[0].uniqueNameHash == World.moatHash)
		{
			pc.waterPathCost[teamId] = 1;
		}
		else if (cell.Type == TerrainType.Water)
		{
			pc.waterPathCost[teamId] = 2;
		}
		else
		{
			pc.waterPathCost[teamId] = waterBlockedCost;
		}
	}

	public static int GetMilitaryFootPathCost(PathCell cell, int teamId)
	{
		int footPathCost = GetFootPathCost(cell, teamId);
		if (footPathCost >= footPathDeepWaterCost)
		{
			return footPathCost;
		}
		if (footPathCost == buildingFootpathCost)
		{
			return buildingFootpathCost * 20;
		}
		if (GetBlocksFootPathForArmies(cell, teamId))
		{
			return wallBlockedCost;
		}
		if (footPathCost < 15)
		{
			return 15;
		}
		return footPathCost + cell.unitBlockCost;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public static int GetEnvoyFootPathCost(PathCell cell, int teamId)
	{
		return cell.envoyFootPathCost[teamId] + cell.wolfFootPathPenalty;
	}

	public static int GetTransportCartFootPathCost(PathCell cell, int teamId)
	{
		if (GetBlocksFootPathForTransportCart(cell, teamId))
		{
			return 10000;
		}
		return GetFootPathCost(cell, teamId);
	}

	public static void BakePathingCostsForCell(Cell cell)
	{
		PathCell pathCell = World.inst.GetPathCell(cell);
		pathCell.Type = cell.Type;
		pathCell.isPathCell = cell.StructureCompareCategoryNameAll(World.pathHash) && !cell.StructureCompareUniqueNameAll(World.woodBridgeHash) && !cell.StructureCompareUniqueNameAll(World.stoneBridgeHash);
		pathCell.isStairs = false;
		pathCell.isUpperGridBlocked = true;
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (building.IsBuilt())
			{
				if (building.uniqueNameHash == World.castlestairsHash)
				{
					pathCell.isStairs = true;
				}
				if (building.categoryHash == World.castleblockHash || building.categoryHash == World.castlestairsHash || building.categoryHash == World.gateHash)
				{
					pathCell.isUpperGridBlocked = false;
				}
			}
		}
		for (int j = 0; j < pathCell.waterPathBlocked.Length; j++)
		{
			ApplyBlocksWaterPath(pathCell, cell, j);
		}
		for (int k = 0; k < pathCell.pathBlockedForArmies.Length; k++)
		{
			ApplyBlocksFootPathForArmies(pathCell, cell, k);
			ApplyBlocksFootPathForEnvoys(pathCell, cell, k);
		}
		ApplyBlocksFootPathForOgres(pathCell, cell);
		ApplyBlocksFootPathForHydra(pathCell, cell);
		ApplyBlocksFootPathForTransportCart(pathCell, cell);
		for (int l = 0; l < pathCell.villagerFootPathCost.Length; l++)
		{
			ApplyFootPathCost(pathCell, cell, l);
			ApplyEnvoyFootPathCost(pathCell, cell, l);
			ApplyWaterPathCost(pathCell, cell, l);
		}
		ApplyOgreFootPathCost(pathCell, cell);
		ApplyHydraFootPathCost(pathCell, cell);
		ApplyHydraBlockingCost(pathCell, cell);
	}
}
