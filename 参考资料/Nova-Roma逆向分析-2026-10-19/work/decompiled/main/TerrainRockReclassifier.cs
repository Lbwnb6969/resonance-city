using Code;
using UnityEngine;

public static class TerrainRockReclassifier
{
	private static readonly RaycastHit[] protrusionHits = new RaycastHit[16];

	public static void ReclassifyVertRect(int minVertX, int minVertZ, int maxVertX, int maxVertZ, bool bakeDeformations = true)
	{
		if (maxVertX < minVertX || maxVertZ < minVertZ)
		{
			return;
		}
		if (bakeDeformations)
		{
			TerrainGen.inst.UpdateTerrainDeformations();
		}
		int num = Mathf.Max(0, minVertX / 2 - 1);
		int num2 = Mathf.Max(0, minVertZ / 2 - 1);
		int num3 = Mathf.Min(World.inst.GridWidth - 1, maxVertX / 2 + 1);
		int num4 = Mathf.Min(World.inst.GridHeight - 1, maxVertZ / 2 + 1);
		if (num > num3 || num2 > num4)
		{
			return;
		}
		for (int i = num2; i <= num4; i++)
		{
			for (int j = num; j <= num3; j++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(j, i);
				if (cellDataUnsafe.Type != TerrainType.None && cellDataUnsafe.Type != TerrainType.Obstruction && cellDataUnsafe.Type != TerrainType.Water)
				{
					continue;
				}
				TerrainResource terrainResource = cellDataUnsafe.terrainResource;
				bool flag = ((terrainResource != null && !ResourceHasTerrainCollider(terrainResource)) ? StoneDepositExposed(j, i, terrainResource) : CellHasProtrudingRock(j, i));
				if (cellDataUnsafe.Type == TerrainType.Obstruction && !flag)
				{
					if (TerrainGen.inst.GetGroundHeight((float)j + 0.5f, (float)i + 0.5f) < TerrainGen.waterHeightTestThresold)
					{
						TerrainGen.inst.SetWaterTile(j, i, modifyHeight: false);
						cellDataUnsafe.deepWater = false;
						cellDataUnsafe.landMassIdx = -1;
					}
					else
					{
						cellDataUnsafe.Type = TerrainType.None;
					}
				}
				else if ((cellDataUnsafe.Type != TerrainType.Obstruction) & flag)
				{
					cellDataUnsafe.Type = TerrainType.Obstruction;
				}
			}
		}
		TerrainGen.inst.RecalcWaterObstructionForArea(num, num2, num3 - num + 1, num4 - num2 + 1);
	}

	private static bool CellHasProtrudingRock(int cellX, int cellZ)
	{
		int mask = LayerMask.GetMask("Terrain");
		float y = Water.inst.transform.position.y;
		TerrainResource terrainResource = World.inst.GetCellDataUnsafe(cellX, cellZ).terrainResource;
		int num = 0;
		for (int i = 0; i <= 2; i++)
		{
			for (int j = 0; j <= 2; j++)
			{
				int num2 = cellX * 2 + i;
				int num3 = cellZ * 2 + j;
				if (num2 < 0 || num3 < 0 || num2 >= World.MeshWidth || num3 >= World.MeshHeight)
				{
					continue;
				}
				int num4 = Physics.RaycastNonAlloc(new Ray(new Vector3((float)num2 * 0.5f, 100f, (float)num3 * 0.5f), Vector3.down), protrusionHits, 150f, mask);
				float num5 = float.MaxValue;
				float num6 = float.MinValue;
				for (int k = 0; k < num4; k++)
				{
					TerrainResource componentInParent = protrusionHits[k].collider.GetComponentInParent<TerrainResource>();
					if ((!(componentInParent != null) || !(componentInParent != terrainResource)) && protrusionHits[k].distance < num5)
					{
						num5 = protrusionHits[k].distance;
						num6 = protrusionHits[k].point.y;
					}
				}
				if (num5 != float.MaxValue && !(num6 <= y) && !(num6 - TerrainGen.inst.heightCache[num2 + num3 * World.MeshWidth] <= MountainPlacer.MESH_TO_TERRAIN_THRESHOLD))
				{
					if (i == 1 && j == 1)
					{
						return true;
					}
					num++;
					if (num > 2)
					{
						return true;
					}
				}
			}
		}
		return false;
	}

	private static bool StoneDepositExposed(int cellX, int cellZ, TerrainResource resource)
	{
		float height = resource.GetHeight();
		int num = 0;
		for (int i = 0; i <= 2; i++)
		{
			for (int j = 0; j <= 2; j++)
			{
				int num2 = cellX * 2 + i;
				int num3 = cellZ * 2 + j;
				if (num2 < 0 || num3 < 0 || num2 >= World.MeshWidth || num3 >= World.MeshHeight)
				{
					continue;
				}
				int num4 = num2 + num3 * World.MeshWidth;
				if (!(TerrainGen.inst.originalHeightCache[num4] + height - TerrainGen.inst.heightCache[num4] <= MountainPlacer.MESH_TO_TERRAIN_THRESHOLD))
				{
					if (i == 1 && j == 1)
					{
						return true;
					}
					num++;
					if (num > 2)
					{
						return true;
					}
				}
			}
		}
		return false;
	}

	private static bool ResourceHasTerrainCollider(TerrainResource resource)
	{
		Collider[] componentsInChildren = resource.GetComponentsInChildren<Collider>();
		int num = LayerMask.NameToLayer("Terrain");
		for (int i = 0; i < componentsInChildren.Length; i++)
		{
			if (componentsInChildren[i].gameObject.layer == num)
			{
				return true;
			}
		}
		return false;
	}
}
