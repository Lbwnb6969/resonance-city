using System;
using UnityEngine;

[Serializable]
public struct PathingGraphBaked
{
	public short[] tree;

	public SerializableVector3[] vertices;

	public byte[] type;

	public static bool FindClosestInternalVertIndexTo(Vector3 point, out short vertIndex, ref PathingGraphBaked bakedData)
	{
		short num = -1;
		float num2 = float.MaxValue;
		for (short num3 = 0; num3 < bakedData.vertices.Length; num3++)
		{
			if (bakedData.type[num3] == 1)
			{
				float num4 = Mathff.DistSqrd(bakedData.vertices[num3], point);
				if (num4 < num2)
				{
					num2 = num4;
					num = num3;
				}
			}
		}
		vertIndex = num;
		return vertIndex != -1;
	}

	public static bool FindClosestExternalVertIndexTo(Vector3 point, out short vertIndex, ref PathingGraphBaked bakedData)
	{
		short num = -1;
		float num2 = float.MaxValue;
		for (short num3 = 0; num3 < bakedData.vertices.Length; num3++)
		{
			if (bakedData.type[num3] == 2)
			{
				float num4 = Mathff.DistSqrd(bakedData.vertices[num3], point);
				if (num4 < num2)
				{
					num2 = num4;
					num = num3;
				}
			}
		}
		vertIndex = num;
		return vertIndex != -1;
	}

	public static bool FindClosestVertIndexTo(Vector3 point, out short vertIndex, ref PathingGraphBaked bakedData)
	{
		short num = -1;
		float num2 = float.MaxValue;
		for (short num3 = 0; num3 < bakedData.vertices.Length; num3++)
		{
			float num4 = Mathff.DistSqrd(bakedData.vertices[num3], point);
			if (num4 < num2)
			{
				num2 = num4;
				num = num3;
			}
		}
		vertIndex = num;
		return vertIndex != -1;
	}

	public static bool AddPathNodesBetween(Vector3 start, Vector3 end, ArrayExt<TravelNode> travelPath, int insertPoint, ref PathingGraphBaked baked, out int nodesAdded, Building b)
	{
		nodesAdded = 0;
		bool flag = FindClosestVertIndexTo(start, out var vertIndex, ref baked);
		if (!FindClosestVertIndexTo(end, out var vertIndex2, ref baked) || !flag)
		{
			return false;
		}
		short num = vertIndex2;
		nodesAdded++;
		travelPath.Insert(insertPoint, new TravelNode
		{
			building = b,
			isLocal = true,
			pos = baked.vertices[num]
		});
		while (num != vertIndex)
		{
			short num2 = baked.tree[vertIndex * baked.vertices.Length + num];
			nodesAdded++;
			travelPath.Insert(insertPoint, new TravelNode
			{
				building = b,
				isLocal = true,
				pos = baked.vertices[num2]
			});
			num = num2;
		}
		return true;
	}

	public static bool AddPathNodesForEndPath(Vector3 start, Vector3 end, ArrayExt<TravelNode> travelPath, int insertPoint, ref PathingGraphBaked baked, out int nodesAdded, Building b)
	{
		nodesAdded = 0;
		bool flag = FindClosestExternalVertIndexTo(start, out var vertIndex, ref baked);
		if (!FindClosestInternalVertIndexTo(end, out var vertIndex2, ref baked) || !flag)
		{
			return false;
		}
		short num = vertIndex2;
		nodesAdded++;
		travelPath.Insert(insertPoint, new TravelNode
		{
			building = b,
			isLocal = true,
			pos = baked.vertices[num]
		});
		while (num != vertIndex)
		{
			short num2 = baked.tree[vertIndex * baked.vertices.Length + num];
			nodesAdded++;
			travelPath.Insert(insertPoint, new TravelNode
			{
				building = b,
				isLocal = true,
				pos = baked.vertices[num2]
			});
			num = num2;
		}
		return true;
	}

	public static bool AddPathNodesExternalsOnly(Vector3 start, Vector3 end, ArrayExt<TravelNode> travelPath, int insertPoint, ref PathingGraphBaked baked, out int nodesAdded, Building b)
	{
		nodesAdded = 0;
		bool flag = FindClosestExternalVertIndexTo(start, out var vertIndex, ref baked);
		if (!FindClosestExternalVertIndexTo(end, out var vertIndex2, ref baked) || !flag)
		{
			return false;
		}
		short num = vertIndex2;
		nodesAdded++;
		travelPath.Insert(insertPoint, new TravelNode
		{
			building = b,
			isLocal = true,
			pos = baked.vertices[num]
		});
		while (num != vertIndex)
		{
			short num2 = baked.tree[vertIndex * baked.vertices.Length + num];
			nodesAdded++;
			travelPath.Insert(insertPoint, new TravelNode
			{
				building = b,
				isLocal = true,
				pos = baked.vertices[num2]
			});
			num = num2;
		}
		return true;
	}

	public static bool AddPathNodesForStartPath(Vector3 start, Vector3 end, ArrayExt<TravelNode> travelPath, int insertPoint, ref PathingGraphBaked baked, out int nodesAdded, Building b)
	{
		nodesAdded = 0;
		bool flag = FindClosestInternalVertIndexTo(start, out var vertIndex, ref baked);
		if (!FindClosestExternalVertIndexTo(end, out var vertIndex2, ref baked) || !flag)
		{
			return false;
		}
		short num = vertIndex2;
		nodesAdded++;
		travelPath.Insert(insertPoint, new TravelNode
		{
			building = b,
			isLocal = true,
			pos = baked.vertices[num]
		});
		while (num != vertIndex)
		{
			short num2 = baked.tree[vertIndex * baked.vertices.Length + num];
			nodesAdded++;
			travelPath.Insert(insertPoint, new TravelNode
			{
				building = b,
				isLocal = true,
				pos = baked.vertices[num2]
			});
			num = num2;
		}
		return true;
	}
}
