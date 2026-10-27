using UnityEngine;

public static class TerrainRockFill
{
	private static int _terrainMask = -1;

	private static readonly Collider[] _overlapBuffer = new Collider[32];

	private static readonly RaycastHit[] _rayHits = new RaycastHit[16];

	public static float RockBottom(int vx, int vz)
	{
		if (_terrainMask == -1)
		{
			_terrainMask = LayerMask.GetMask("Terrain");
		}
		float x = (float)vx * 0.5f;
		float z = (float)vz * 0.5f;
		int num = Physics.OverlapBoxNonAlloc(new Vector3(x, 20f, z), new Vector3(0.05f, 80f, 0.05f), _overlapBuffer, Quaternion.identity, _terrainMask, QueryTriggerInteraction.Ignore);
		float num2 = float.MinValue;
		for (int i = 0; i < num; i++)
		{
			Collider collider = _overlapBuffer[i];
			if (!(collider == null) && !(collider.GetComponentInParent<TerrainChunk>() != null) && collider.Raycast(new Ray(new Vector3(x, -60f, z), Vector3.up), out var hitInfo, 200f) && hitInfo.point.y > num2)
			{
				num2 = hitInfo.point.y;
			}
		}
		return Mathf.Max(num2, DepositBottom(vx, vz));
	}

	public static float DepositBottom(int vx, int vz)
	{
		if (!VertBordersAnyResource(vx, vz))
		{
			return float.MinValue;
		}
		return TerrainGen.inst.originalHeightCache[vx + vz * World.MeshWidth];
	}

	public static float RockTop(int vx, int vz)
	{
		if (_terrainMask == -1)
		{
			_terrainMask = LayerMask.GetMask("Terrain");
		}
		float x = (float)vx * 0.5f;
		float z = (float)vz * 0.5f;
		int num = Physics.RaycastNonAlloc(new Ray(new Vector3(x, 100f, z), Vector3.down), _rayHits, 150f, _terrainMask);
		float num2 = float.MinValue;
		for (int i = 0; i < num; i++)
		{
			Collider collider = _rayHits[i].collider;
			if (!(collider.GetComponentInParent<TerrainChunk>() != null))
			{
				TerrainResource componentInParent = collider.GetComponentInParent<TerrainResource>();
				if ((!(componentInParent != null) || VertBordersResource(vx, vz, componentInParent)) && _rayHits[i].point.y > num2)
				{
					num2 = _rayHits[i].point.y;
				}
			}
		}
		return num2;
	}

	private static bool VertBordersResource(int vx, int vz, TerrainResource res)
	{
		bool flag = vx % 2 == 0;
		bool flag2 = vz % 2 == 0;
		for (int i = (flag ? (-1) : 0); i <= (flag ? 1 : 0); i++)
		{
			for (int j = (flag2 ? (-1) : 0); j <= (flag2 ? 1 : 0); j++)
			{
				int num = vx + i;
				int num2 = vz + j;
				if (num >= 0 && num2 >= 0 && num < World.MeshWidth && num2 < World.MeshHeight)
				{
					int meshIndex = num + num2 * World.MeshWidth;
					TerrainResource terrainResource = World.inst.GetCellDataUnsafe(DynamicWater.MapIndexMeshToWorld(meshIndex, World.inst.GridWidth)).terrainResource;
					if (terrainResource != null && (res == null || terrainResource == res))
					{
						return true;
					}
				}
			}
		}
		return false;
	}

	private static bool VertBordersAnyResource(int vx, int vz)
	{
		return VertBordersResource(vx, vz, null);
	}

	public static float RaiseFreeFill(int vx, int vz, float current, float target)
	{
		if (target <= current)
		{
			return 0f;
		}
		float num = RockTop(vx, vz);
		if (num <= current)
		{
			return 0f;
		}
		float num2 = Mathf.Max(current, RockBottom(vx, vz));
		float num3 = Mathf.Min(target, num);
		if (!(num3 > num2))
		{
			return 0f;
		}
		return num3 - num2;
	}
}
