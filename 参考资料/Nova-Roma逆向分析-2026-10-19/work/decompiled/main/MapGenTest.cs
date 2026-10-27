using System;
using System.Collections.Generic;
using UnityEngine;

public class MapGenTest : MonoBehaviour
{
	private enum State
	{
		ResolvingCircles,
		BuildGrid,
		PickIslands,
		Rasterize,
		MakeLakes,
		Finished,
		PruneTinyIslands
	}

	private class Node
	{
		public int posIdx = -1;

		public bool allEdgesRasterized;

		public bool connectivityMarked;

		public bool visitedForRiver;

		public int islandID = -1;

		public int islandIDAdjacent = -1;

		public List<Node> edges = new List<Node>();

		public int mDataIdx;
	}

	private State state;

	public float inflateRadiiForRaster = 2f;

	public float minIslandArea = 64f;

	private int gridWidth;

	private int gridHeight;

	private float kAttract = 0.001f;

	public bool DebugDraw;

	private bool makeLakes = true;

	public float minCircleArea = 80f;

	public int gridOffset = 35;

	private bool written;

	private int numIslands;

	private float remainingMapArea;

	private int ticks;

	private int claimTries;

	private int islandIdx;

	private ArrayExt<Node> nodes = new ArrayExt<Node>(1000);

	private List<List<Node>> lakeNodes = new List<List<Node>>();

	private List<List<Node>> islandNodes = new List<List<Node>>();

	private List<float> islandGrowChance = new List<float>();

	private List<bool> islandGrowSuccess = new List<bool>();

	private ArrayExt<int> unclaimedIslands = new ArrayExt<int>(1000);

	private float[] islandRadii;

	private Vector3[] islandPos;

	public int rasterBorder = 3;

	public float riverStepPunch = 2f;

	public MinMax riverRadiusPunch;

	public float riverPerpJitter = 1f;

	public MinMax edgeHoleRadius;

	public int edgeHoleStep = 5;

	public float waterFreq = 10f;

	private void Start()
	{
	}

	public void GenerateNewMap(int w, int h, ref bool[] oceanTiles, ref int[] landmassIdx, ref float[] height, ref List<TerrainGen.MountainData> mountainPositions, ref ArrayExt<Vector4>[] islandInteriorBounds, int estimatedUsuableTiles, int islandCount, bool doLakes)
	{
		Init(w, h, estimatedUsuableTiles, islandCount, doLakes);
		while (state != State.Finished)
		{
			Tick();
		}
		WriteMap(ref oceanTiles, ref landmassIdx, ref height, ref mountainPositions, ref islandInteriorBounds);
	}

	public float GetCircleMul()
	{
		int num = SRand.Range(0, 10);
		if (num < 4)
		{
			return 1f;
		}
		if (num >= 4 && num < 7)
		{
			return 1.5f;
		}
		if (num >= 7 && num < 9)
		{
			return 2f;
		}
		if (num == 9)
		{
			return 3f;
		}
		return 1f;
	}

	private void Init(int w, int h, int desiredTiles, int islandCount, bool doLakes)
	{
		makeLakes = false;
		numIslands = islandCount;
		remainingMapArea = desiredTiles;
		state = State.ResolvingCircles;
		nodes.Clear();
		islandNodes.Clear();
		gridWidth = w;
		gridHeight = h;
		ticks = 0;
		float num = (gridOffset + gridWidth) * (gridHeight + gridOffset);
		int num2 = 0;
		float num3 = num;
		while (num3 > 0f)
		{
			float num4 = minCircleArea * GetCircleMul();
			float num5 = Mathf.Sqrt(2f * num4 / MathF.PI);
			num3 -= 2f * num5 * (2f * num5);
			num2++;
		}
		islandRadii = new float[num2];
		islandPos = new Vector3[num2];
		for (int i = 0; i < islandPos.Length; i++)
		{
			islandPos[i] = new Vector3(SRand.Range(0f, gridWidth), 0f, SRand.Range(0f, gridHeight));
		}
		float num6 = num - (float)(num2 - 1) * minCircleArea;
		for (int j = 0; j < num2; j++)
		{
			float num7 = minCircleArea * GetCircleMul();
			islandRadii[j] = Mathf.Sqrt(2f * num7 / MathF.PI);
			num6 -= num7;
		}
	}

	private void Update()
	{
		Tick();
		if (state == State.Finished && !written)
		{
			bool[] waterTiles = new bool[gridWidth * gridHeight];
			int[] landmassIdx = new int[gridWidth * gridHeight];
			float[] height = new float[gridWidth * gridHeight];
			ArrayExt<Vector4>[] islandInteriorBounds = null;
			List<TerrainGen.MountainData> mountainPositions = new List<TerrainGen.MountainData>();
			new List<Vector3>();
			WriteMap(ref waterTiles, ref landmassIdx, ref height, ref mountainPositions, ref islandInteriorBounds);
			written = true;
		}
	}

	private void Tick()
	{
		if (islandPos == null)
		{
			return;
		}
		ticks++;
		Vector3 vector = new Vector3((float)gridOffset / -2f, 0f, (float)gridOffset / -2f);
		Vector3 vector2 = new Vector3((float)gridOffset / 2f + (float)gridWidth + 1f, 0f, (float)gridOffset / 2f + (float)gridHeight + 1f);
		new Vector3(vector2.x / 2f, 0f, vector2.z / 2f);
		switch (state)
		{
		case State.ResolvingCircles:
		{
			float num3 = 1f;
			Vector3 vector3 = default;
			for (int num4 = 0; num4 < islandPos.Length; num4++)
			{
				for (int num5 = 0; num5 < islandPos.Length; num5++)
				{
					if (num4 == num5)
					{
						continue;
					}
					float num6 = islandPos[num4].x - islandPos[num5].x;
					float num7 = islandPos[num4].z - islandPos[num5].z;
					float num8 = num6 * num6 + num7 * num7;
					if (num8 < (islandRadii[num4] + islandRadii[num5]) * (islandRadii[num4] + islandRadii[num5]))
					{
						float num9 = Mathf.Sqrt(num8);
						float num10 = num9 - (islandRadii[num4] + islandRadii[num5]);
						if (num10 < num3)
						{
							num3 = num10;
						}
						if (num9 > 0f)
						{
							vector3.x = num6 / num9;
							vector3.z = num7 / num9;
						}
						else
						{
							vector3.x = SRand.Range(-1f, 1f);
							vector3.y = 0f;
							vector3.z = SRand.Range(-1f, 1f);
							vector3.Normalize();
						}
						float num11 = num10 * 0.5f;
						islandPos[num4].x += (0f - vector3.x) * num11;
						islandPos[num4].z += (0f - vector3.z) * num11;
						islandPos[num5].x += vector3.x * num11;
						islandPos[num5].z += vector3.z * num11;
					}
				}
				Vector3 vector4 = Mathff.ClosestPointOnBoxXZ(vector, vector2, islandPos[num4]);
				float num12 = Mathff.Dist(vector4, islandPos[num4]);
				if (!Mathff.BoxContains(vector, vector2, islandPos[num4]))
				{
					vector3 = vector4 - islandPos[num4];
					vector3.Normalize();
					islandPos[num4] += vector3 * (islandRadii[num4] + num12);
				}
				else if (num12 < islandRadii[num4])
				{
					vector3 = islandPos[num4] - vector4;
					vector3.Normalize();
					if (num12 <= 0f)
					{
						vector3 = ((vector + vector2) * 0.5f - islandPos[num4]).normalized;
					}
					islandPos[num4] += vector3 * (islandRadii[num4] - num12);
				}
			}
			if (num3 > -0.01f || ticks > 250)
			{
				state = State.BuildGrid;
			}
			break;
		}
		case State.BuildGrid:
		{
			BuildGraph();
			state = State.PickIslands;
			islandNodes.Clear();
			islandGrowChance.Clear();
			islandGrowSuccess.Clear();
			for (int num26 = 0; num26 < numIslands; num26++)
			{
				islandNodes.Add(new List<Node>());
				islandGrowChance.Add(0.3f + 0.7f * (float)num26 / (float)numIslands);
				islandGrowSuccess.Add(item: true);
			}
			islandIdx = 0;
			break;
		}
		case State.PickIslands:
		{
			if (SRand.Range(0f, 1f) < islandGrowChance[islandIdx])
			{
				if (!ClaimNonAdjacentCircle(islandIdx))
				{
					islandGrowSuccess[islandIdx] = false;
				}
				else
				{
					int posIdx = islandNodes[islandIdx][islandNodes[islandIdx].Count - 1].posIdx;
					int num13 = 1;
					float num14 = islandRadii[posIdx] + inflateRadiiForRaster + (float)num13;
					float num15 = 2f * num14 * (2f * num14);
					remainingMapArea -= num15;
				}
			}
			islandIdx = (islandIdx + 1) % islandNodes.Count;
			int num16 = 0;
			for (int num17 = 0; num17 < islandGrowSuccess.Count; num17++)
			{
				if (!islandGrowSuccess[num17])
				{
					num16++;
				}
			}
			if (num16 >= islandGrowSuccess.Count || remainingMapArea < 0f)
			{
				lakeNodes = new List<List<Node>>();
				for (int num18 = 0; num18 < islandNodes.Count; num18++)
				{
					lakeNodes.Add(new List<Node>());
				}
				if (makeLakes)
				{
					state = State.MakeLakes;
				}
				else
				{
					state = State.PruneTinyIslands;
				}
			}
			break;
		}
		case State.MakeLakes:
		{
			for (int num19 = 0; num19 < islandNodes.Count; num19++)
			{
				List<Node> list2 = new List<Node>();
				int num20 = (int)((float)islandNodes[num19].Count * 0.4f);
				for (int num21 = 0; num21 < num20; num21++)
				{
					list2.Add(islandNodes[num19][SRand.Range(0, islandNodes[num19].Count)]);
				}
				while (list2.Count > 0)
				{
					Node node2 = list2[0];
					list2.RemoveAt(0);
					int islandID = node2.islandID;
					node2.islandID = -1;
					bool flag3 = false;
					if (islandID != -1)
					{
						for (int num22 = 0; num22 < node2.edges.Count; num22++)
						{
							ResetConnectivityTest(num19);
							FloodFillConnectivity(node2.edges[num22], islandID);
							int num23 = 0;
							while (num23 < node2.edges.Count)
							{
								if (node2.edges[num23].connectivityMarked)
								{
									num23++;
									continue;
								}
								goto IL_06d7;
							}
							continue;
							IL_06d7:
							flag3 = true;
							break;
						}
					}
					else
					{
						_ = 0;
					}
					if (flag3)
					{
						node2.islandID = islandID;
						continue;
					}
					islandNodes[num19].Remove(node2);
					lakeNodes[num19].Add(node2);
					int num24 = SRand.Range(0, 6);
					for (int num25 = 0; num25 < num24; num25++)
					{
						Node node3 = node2.edges[SRand.Range(0, node2.edges.Count)];
						if (node3.islandID != -1 && !list2.Contains(node3))
						{
							list2.Add(node3);
						}
					}
				}
			}
			state = State.PruneTinyIslands;
			break;
		}
		case State.PruneTinyIslands:
		{
			List<int> list = new List<int>();
			for (int i = 0; i < islandNodes.Count; i++)
			{
				float num = 0f;
				for (int j = 0; j < islandNodes[i].Count; j++)
				{
					num += MathF.PI / 2f * islandRadii[islandNodes[i][j].posIdx] * islandRadii[islandNodes[i][j].posIdx];
				}
				if (num < minIslandArea)
				{
					list.Add(i);
				}
			}
			for (int k = 0; k < list.Count; k++)
			{
				for (int l = 0; l < islandNodes.Count; l++)
				{
					if (islandNodes[l].Count > 0 && islandNodes[l][0].islandID == list[k])
					{
						islandNodes.RemoveAt(l);
					}
				}
			}
			bool flag = false;
			do
			{
				flag = false;
				for (int m = 0; m < nodes.Count; m++)
				{
					Node node = nodes.data[m];
					if (node.islandID != -1)
					{
						continue;
					}
					int num2 = -1;
					bool flag2 = false;
					for (int n = 0; n < node.edges.Count; n++)
					{
						if (node.edges[n].islandID != -1)
						{
							num2 = node.edges[n].islandID;
						}
						if (node.edges[n].islandID == -1)
						{
							flag2 = true;
							break;
						}
					}
					if (!flag2 && num2 != -1)
					{
						AddNodeToIsland(node, num2);
						flag = true;
					}
				}
			}
			while (flag);
			state = State.Finished;
			break;
		}
		case State.Rasterize:
		case State.Finished:
			break;
		}
	}

	private void ResetConnectivityTest(int island)
	{
		List<Node> list = islandNodes[island];
		for (int i = 0; i < list.Count; i++)
		{
			list[i].connectivityMarked = false;
		}
	}

	private void FloodFillConnectivity(Node n, int islandID)
	{
		List<Node> list = new List<Node>(islandNodes[islandID].Count);
		list.Add(n);
		while (list.Count > 0)
		{
			Node node = list[0];
			list.RemoveAt(0);
			node.connectivityMarked = true;
			for (int i = 0; i < node.edges.Count; i++)
			{
				if (node.edges[i].islandID == islandID && !node.edges[i].connectivityMarked && !list.Contains(node.edges[i]))
				{
					list.Add(node.edges[i]);
				}
			}
		}
	}

	private void BuildGraph()
	{
		nodes.Clear();
		for (int i = 0; i < islandPos.Length; i++)
		{
			Node node = new Node();
			node.posIdx = i;
			nodes.Add(node);
		}
		for (int j = 0; j < islandPos.Length; j++)
		{
			Node node2 = nodes.data[j];
			for (int k = 0; k < islandPos.Length; k++)
			{
				if (j != k)
				{
					Vector3 vector = islandPos[j] - islandPos[k];
					if (Mathf.Sqrt(vector.x * vector.x + vector.z * vector.z) - (islandRadii[j] * 1.5f + islandRadii[k] * 1.5f) < 0f)
					{
						node2.edges.Add(nodes.data[k]);
					}
				}
			}
		}
		for (int l = 0; l < nodes.Count; l++)
		{
			Node node3 = nodes.data[l];
			for (int m = 0; m < nodes.data[l].edges.Count; m++)
			{
				Debug.DrawLine(islandPos[node3.posIdx], islandPos[node3.edges[m].posIdx], new Color(255f, 255f, 0f, 60f), 0.1f);
			}
		}
	}

	private bool ClaimNonAdjacentCircle(int islandID)
	{
		if (islandNodes[islandID].Count == 0)
		{
			if (numIslands == 1)
			{
				ArrayExt<Node> arrayExt = new ArrayExt<Node>(50);
				Vector3 b = new Vector3(gridWidth / 2, 0f, gridHeight / 2);
				float num = (float)(gridWidth + gridHeight) / 2f / 2f / 3f;
				num *= num;
				for (int i = 0; i < nodes.Count; i++)
				{
					if (Mathff.DistSqrdXZ(islandPos[nodes.data[i].posIdx], b) < num)
					{
						arrayExt.Add(nodes.data[i]);
					}
				}
				AddNodeToIsland(arrayExt.RandomElement(), islandID);
			}
			else
			{
				Node node = null;
				int num2 = nodes.Count;
				do
				{
					bool flag = false;
					Node node2 = nodes.RandomElement();
					for (int j = 0; j < node2.edges.Count; j++)
					{
						if (node2.edges[j].islandID != -1 || node2.edges[j].islandIDAdjacent != -1)
						{
							flag = true;
							break;
						}
					}
					Vector3 vector = islandPos[node2.posIdx];
					float num3 = islandRadii[node2.posIdx];
					float num4 = vector.x - num3;
					float num5 = vector.x + num3;
					float num6 = vector.z - num3;
					float num7 = vector.z + num3;
					if (num4 < 0f || num5 > (float)gridWidth || num6 < 0f || num7 > (float)gridHeight)
					{
						flag = true;
					}
					for (int k = 0; k < node2.edges.Count; k++)
					{
						if (node2.edges[k].islandIDAdjacent == -1)
						{
							Node node3 = node2.edges[k];
							for (int l = 0; l < node3.edges.Count; l++)
							{
								if ((node3.edges[l].islandID != islandID && node3.edges[l].islandID != -1) || (node3.edges[l].islandIDAdjacent != islandID && node3.edges[l].islandIDAdjacent != -1))
								{
									flag = true;
									break;
								}
							}
							Vector3 vector2 = islandPos[node2.edges[k].posIdx];
							num3 = islandRadii[node2.edges[k].posIdx];
							num4 = vector2.x - num3;
							num5 = vector2.x + num3;
							num6 = vector2.z - num3;
							num7 = vector2.z + num3;
							if (num4 < 0f || num5 > (float)gridWidth || num6 < 0f || num7 > (float)gridHeight)
							{
								flag = true;
							}
						}
						else
						{
							flag = true;
						}
						if (flag)
						{
							break;
						}
					}
					if (!flag)
					{
						node = node2;
					}
					num2--;
				}
				while (node == null && num2 > 0);
				if (node == null)
				{
					return false;
				}
				AddNodeToIsland(node, islandID);
			}
		}
		ArrayExt<Node> arrayExt2 = new ArrayExt<Node>(50);
		List<Node> list = islandNodes[islandID];
		for (int m = 0; m < list.Count; m++)
		{
			Node node4 = list[m];
			for (int n = 0; n < node4.edges.Count; n++)
			{
				if ((node4.edges[n].islandIDAdjacent != islandID && node4.edges[n].islandIDAdjacent != -1) || node4.edges[n].islandID == islandID)
				{
					continue;
				}
				bool flag2 = false;
				Node node5 = node4.edges[n];
				for (int num8 = 0; num8 < node5.edges.Count; num8++)
				{
					if ((node5.edges[num8].islandID != islandID && node5.edges[num8].islandID != -1) || (node5.edges[num8].islandIDAdjacent != islandID && node5.edges[num8].islandIDAdjacent != -1))
					{
						flag2 = true;
						break;
					}
				}
				Vector3 vector3 = islandPos[node4.edges[n].posIdx];
				float num9 = islandRadii[node4.edges[n].posIdx];
				float num10 = vector3.x - num9;
				float num11 = vector3.x + num9;
				float num12 = vector3.z - num9;
				float num13 = vector3.z + num9;
				if (num10 < 0f || num11 > (float)gridWidth || num12 < 0f || num13 > (float)gridHeight)
				{
					flag2 = true;
				}
				if (!flag2 && !arrayExt2.Contains(node4.edges[n]))
				{
					arrayExt2.Add(node4.edges[n]);
				}
			}
		}
		if (arrayExt2.Count > 0)
		{
			Node node6 = null;
			int num14 = 0;
			Node node7 = islandNodes[islandID][0];
			bool flag3 = false;
			if (node7 != null)
			{
				flag3 = true;
				for (int num15 = 0; num15 < node7.edges.Count; num15++)
				{
					if (node7.edges[num15].islandID != islandID)
					{
						flag3 = false;
						break;
					}
				}
			}
			for (int num16 = arrayExt2.Count - 1; num16 >= 0; num16--)
			{
				if (!flag3 || SRand.Range(0, 100) > 40)
				{
					for (int num17 = 0; num17 < arrayExt2.Count; num17++)
					{
						List<Node> edges = arrayExt2.data[num17].edges;
						int num18 = 0;
						for (int num19 = 0; num19 < edges.Count; num19++)
						{
							if (edges[num19].islandID == islandID)
							{
								num18++;
							}
						}
						if (num14 < num18)
						{
							node6 = arrayExt2.data[num17];
							num14 = num18;
						}
					}
				}
				if (node6 == null)
				{
					node6 = arrayExt2.RandomElement();
				}
				Vector3 vector4 = islandPos[node6.posIdx];
				float num20 = islandRadii[node6.posIdx];
				float num21 = vector4.x - num20;
				float num22 = vector4.x + num20;
				float num23 = vector4.z - num20;
				float num24 = vector4.z + num20;
				if (num21 < 0f || num22 > (float)gridWidth || num23 < 0f || num24 > (float)gridHeight)
				{
					arrayExt2.RemoveSwap(node6);
					node6 = null;
				}
				if (node6 != null)
				{
					break;
				}
			}
			if (node6 != null)
			{
				AddNodeToIsland(node6, islandID);
				return true;
			}
		}
		return false;
	}

	private void AddNodeToIsland(Node newNode, int islandID)
	{
		newNode.islandID = islandID;
		newNode.islandIDAdjacent = islandID;
		islandNodes[islandID].Add(newNode);
		for (int i = 0; i < newNode.edges.Count; i++)
		{
			newNode.edges[i].islandIDAdjacent = islandID;
		}
	}

	private void Get2DAABB(Vector2[] points, out float minx, out float maxx, out float minz, out float maxz)
	{
		minx = float.MaxValue;
		minz = float.MaxValue;
		maxx = float.MinValue;
		maxz = float.MinValue;
		for (int i = 0; i < points.Length; i++)
		{
			if (points[i].x < minx)
			{
				minx = points[i].x;
			}
			if (points[i].y < minz)
			{
				minz = points[i].y;
			}
			if (points[i].x > maxx)
			{
				maxx = points[i].x;
			}
			if (points[i].y > maxz)
			{
				maxz = points[i].y;
			}
		}
	}

	private void RasterRiver(Node a, Node b, ref bool[] waterTiles, ref int[] landmassIdx)
	{
		Vector3 vector = islandPos[a.posIdx];
		Vector3 vector2 = islandPos[b.posIdx] - vector;
		float magnitude = vector2.magnitude;
		vector2.Normalize();
		Vector3 vector3 = new Vector3(0f - vector2.z, 0f, vector2.x);
		float num = riverStepPunch;
		for (float num2 = 0f; num2 < magnitude; num2 += num)
		{
			Vector3 vector4 = vector + vector2 * num2 + vector3 * SRand.Range(0f - riverPerpJitter, riverPerpJitter);
			PunchHole(Mathf.RoundToInt(vector4.x), Mathf.RoundToInt(vector4.z), (int)riverRadiusPunch.Rand(), ref waterTiles, ref landmassIdx);
		}
	}

	private void RasterNodes(Node a, Node b, ref bool[] waterTiles, ref int[] landmassIdx)
	{
		Vector3 vector = islandPos[a.posIdx];
		float num = islandRadii[a.posIdx] + inflateRadiiForRaster;
		Vector3 vector2 = islandPos[b.posIdx];
		float num2 = islandRadii[b.posIdx] + inflateRadiiForRaster;
		Vector3 vector3 = vector2 - vector;
		Vector3 normalized = new Vector3(0f - vector3.z, 0f, vector3.x).normalized;
		Vector2[] array = new Vector2[4]
		{
			(vector + normalized * num).xz2D(),
			(vector2 + normalized * num2).xz2D(),
			(vector2 - normalized * num2).xz2D(),
			(vector - normalized * num).xz2D()
		};
		Get2DAABB(array, out var minx, out var maxx, out var minz, out var maxz);
		int num3 = (int)Mathff.Clamp(minx, rasterBorder, gridWidth - rasterBorder);
		int num4 = (int)Mathff.Clamp(minz, rasterBorder, gridHeight - rasterBorder);
		int num5 = (int)Mathff.Clamp(maxx, rasterBorder, gridWidth - rasterBorder);
		int num6 = (int)Mathff.Clamp(maxz, rasterBorder, gridHeight - rasterBorder);
		for (int i = num4; i < num6; i++)
		{
			for (int j = num3; j < num5; j++)
			{
				Vector2 test = new Vector3((float)j + 0.5f, (float)i + 0.5f);
				if (Mathff.PointInPolygon(array, test))
				{
					int num7 = i * gridWidth + j;
					waterTiles[num7] = false;
					landmassIdx[num7] = a.islandID;
				}
			}
		}
	}

	private bool IsInterior(Node c)
	{
		for (int i = 0; i < c.edges.Count; i++)
		{
			if (c.edges[i].islandID == -1)
			{
				return false;
			}
		}
		return true;
	}

	private void PunchHole(int x, int z, int Radius, ref bool[] waterTiles, ref int[] landmassIdx)
	{
		int num = Mathff.Max(x - Radius, 0);
		int num2 = Mathff.Max(z - Radius, 0);
		int num3 = Mathff.Min(x + Radius, gridWidth - 1);
		int num4 = Mathff.Min(z + Radius, gridHeight - 1);
		int num5 = Radius * Radius;
		float num6 = (float)x + 0.5f;
		float num7 = (float)z + 0.5f;
		for (int i = num; i <= num3; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				float num8 = ((float)i - num6) * ((float)i - num6) + ((float)j - num7) * ((float)j - num7);
				float num9 = ((float)(i + 1) - num6) * ((float)(i + 1) - num6) + ((float)j - num7) * ((float)j - num7);
				float num10 = ((float)i - num6) * ((float)i - num6) + ((float)(j + 1) - num7) * ((float)(j + 1) - num7);
				float num11 = ((float)(i + 1) - num6) * ((float)(i + 1) - num6) + ((float)(j + 1) - num7) * ((float)(j + 1) - num7);
				if (num8 < (float)num5 || num9 < (float)num5 || num10 < (float)num5 || num11 < (float)num5)
				{
					int num12 = j * gridWidth + i;
					waterTiles[num12] = true;
					landmassIdx[num12] = -1;
				}
			}
		}
	}

	private bool IsDiagonalShoreTile(int x, int z, bool[] waterTiles)
	{
		int num = 0;
		int num2 = z * gridWidth + x;
		if (!waterTiles[num2])
		{
			num += (waterTiles[(z + 1) * gridWidth + x] ? 1 : 0);
			num += (waterTiles[(z - 1) * gridWidth + x] ? 1 : 0);
			num += (waterTiles[z * gridWidth + (x + 1)] ? 1 : 0);
			num += (waterTiles[z * gridWidth + (x - 1)] ? 1 : 0);
		}
		return num == 2;
	}

	private void WriteMap(ref bool[] waterTiles, ref int[] landmassIdx, ref float[] height, ref List<TerrainGen.MountainData> mountainPositions, ref ArrayExt<Vector4>[] islandInteriorBounds)
	{
		for (int i = 0; i < waterTiles.Length; i++)
		{
			waterTiles[i] = true;
		}
		for (int j = 0; j < landmassIdx.Length; j++)
		{
			landmassIdx[j] = -1;
		}
		for (int k = 0; k < height.Length; k++)
		{
			height[k] = TerrainGen.waterHeightTestThresold - 0.1f;
		}
		for (int l = 0; l < nodes.Count; l++)
		{
			nodes.data[l].allEdgesRasterized = false;
		}
		islandInteriorBounds = new ArrayExt<Vector4>[islandNodes.Count];
		int num = 1;
		for (int m = 0; m < islandNodes.Count; m++)
		{
			if (islandNodes[m].Count == 0)
			{
				continue;
			}
			int islandID = islandNodes[m][0].islandID;
			List<Node> list = new List<Node>();
			list.Add(islandNodes[m][0]);
			islandInteriorBounds[m] = new ArrayExt<Vector4>(2);
			while (list.Count > 0)
			{
				Node node = list[0];
				list.RemoveAt(0);
				for (int n = 0; n < node.edges.Count; n++)
				{
					if (!node.edges[n].allEdgesRasterized && node.edges[n].islandID == islandID)
					{
						RasterNodes(node, node.edges[n], ref waterTiles, ref landmassIdx);
						list.Add(node.edges[n]);
					}
				}
				node.allEdgesRasterized = true;
			}
			int num2 = 0;
			for (int num3 = 0; num3 < islandNodes[m].Count; num3++)
			{
				Node node2 = islandNodes[m][num3];
				if (node2.islandID != islandID)
				{
					continue;
				}
				int num4 = 0;
				int num5 = 0;
				Vector3 zero = Vector3.zero;
				Vector3 zero2 = Vector3.zero;
				bool flag = true;
				for (int num6 = 0; num6 < node2.edges.Count; num6++)
				{
					Node node3 = node2.edges[num6];
					if (node3.islandID == -1)
					{
						Vector3 normalized = (islandPos[node3.posIdx] - islandPos[node2.posIdx]).normalized;
						zero2 += normalized;
						num4++;
					}
					else
					{
						Vector3 normalized2 = (islandPos[node3.posIdx] - islandPos[node2.posIdx]).normalized;
						zero += normalized2;
						num5++;
					}
				}
				float num7 = islandRadii[node2.posIdx] + inflateRadiiForRaster;
				float num8 = num7 * num7;
				Vector3 a = islandPos[node2.posIdx];
				int num9 = (int)Mathff.Clamp(a.x - num7, rasterBorder, gridWidth - rasterBorder);
				int num10 = (int)Mathff.Clamp(a.z - num7, rasterBorder, gridHeight - rasterBorder);
				int num11 = (int)Mathff.Clamp(a.x + num7, rasterBorder, gridWidth - rasterBorder);
				int num12 = (int)Mathff.Clamp(a.z + num7, rasterBorder, gridHeight - rasterBorder);
				for (int num13 = num9; num13 < num11; num13++)
				{
					for (int num14 = num10; num14 < num12; num14++)
					{
						if (Mathff.DistSqrdXZ(b: new Vector3(num13, 0f, num14), a: a) < num8)
						{
							int num15 = num14 * gridWidth + num13;
							waterTiles[num15] = false;
							landmassIdx[num15] = islandID;
						}
					}
				}
				if (flag)
				{
					float area = (islandRadii[node2.posIdx] + inflateRadiiForRaster) * (islandRadii[node2.posIdx] + inflateRadiiForRaster);
					TerrainGen.MountainData.Size mountainSizeFromArea = GetMountainSizeFromArea(area);
					TerrainGen.MountainData.Type type = ((num4 != 0 || num5 < 3) ? TerrainGen.MountainData.Type.Exterior : TerrainGen.MountainData.Type.Interior);
					if (num2 < 4 && num4 > num5)
					{
						bool flag2 = true;
						for (int num16 = 0; num16 < node2.edges.Count; num16++)
						{
							Node item = node2.edges[num16];
							int num17 = islandNodes[m].IndexOf(item);
							if (num17 != -1 && num17 > num3)
							{
								flag2 = false;
								break;
							}
						}
						if (flag2)
						{
							type = TerrainGen.MountainData.Type.Corner;
							num2++;
						}
					}
					TerrainGen.MountainData item2 = new TerrainGen.MountainData
					{
						pos = islandPos[node2.posIdx],
						landDir = (zero / num5).normalized,
						waterDir = (zero2 / num4).normalized,
						type = type,
						size = mountainSizeFromArea,
						area = area,
						radius = islandRadii[node2.posIdx],
						landEdges = num5,
						waterEdges = num4,
						posIdx = node2.posIdx,
						landmassIdx = node2.islandID,
						idx = mountainPositions.Count
					};
					node2.mDataIdx = item2.idx;
					mountainPositions.Add(item2);
				}
				double num18 = 1.0 + (double)((float)num5 * 0.1f);
				if (SRand.Range(0, 100) < 20)
				{
					num18 *= 1.5;
				}
				int num19 = (int)((double)(islandRadii[node2.posIdx] + inflateRadiiForRaster) * num18);
				int num20 = num19 * num19;
				num9 = (int)Mathff.Clamp(a.x - (float)num19, rasterBorder, gridWidth - rasterBorder);
				num10 = (int)Mathff.Clamp(a.z - (float)num19, rasterBorder, gridHeight - rasterBorder);
				num11 = (int)Mathff.Clamp(a.x + (float)num19, rasterBorder, gridWidth - rasterBorder);
				num12 = (int)Mathff.Clamp(a.z + (float)num19, rasterBorder, gridHeight - rasterBorder);
				float num21 = (float)num5 / 4f;
				for (int num22 = num9; num22 < num11; num22++)
				{
					for (int num23 = num10; num23 < num12; num23++)
					{
						float num24 = Mathff.DistSqrdXZ(b: new Vector3(num22, 0f, num23), a: a);
						if (num24 < (float)num20)
						{
							int num25 = num23 * gridWidth + num22;
							height[num25] += Mathf.SmoothStep(0f, 1f, 1f - num24 / (float)num20) * num21 * 1.33f;
						}
					}
				}
			}
		}
		for (int num26 = mountainPositions.Count - 1; num26 >= 0; num26--)
		{
			TerrainGen.MountainData mountainData = mountainPositions[num26];
			if (mountainData.type == TerrainGen.MountainData.Type.Corner && mountainData.landEdges == 1)
			{
				List<Node> edges = nodes.data[mountainData.posIdx].edges;
				for (int num27 = 0; num27 < edges.Count; num27++)
				{
					if (edges[num27].islandID != -1)
					{
						int mountainDataOfIdx = GetMountainDataOfIdx(mountainPositions, edges[num27].posIdx);
						if (mountainDataOfIdx != -1)
						{
							TerrainGen.MountainData value = mountainPositions[mountainDataOfIdx];
							value.type = TerrainGen.MountainData.Type.None;
							mountainPositions[mountainDataOfIdx] = value;
						}
						break;
					}
				}
			}
		}
		List<int> list2 = new List<int>(16);
		Vector3[] array = new Vector3[50];
		for (int num28 = 0; num28 < mountainPositions.Count; num28++)
		{
			TerrainGen.MountainData value2 = mountainPositions[num28];
			if (mountainPositions[num28].type != TerrainGen.MountainData.Type.Exterior && mountainPositions[num28].type != TerrainGen.MountainData.Type.Edge)
			{
				continue;
			}
			Node node4 = nodes.data[value2.posIdx];
			list2.Clear();
			for (int num29 = 0; num29 < node4.edges.Count; num29++)
			{
				int mountainDataOfIdx2 = GetMountainDataOfIdx(mountainPositions, node4.edges[num29].posIdx);
				if (mountainDataOfIdx2 != -1 && mountainPositions[mountainDataOfIdx2].type == TerrainGen.MountainData.Type.Corner)
				{
					list2.Add(mountainDataOfIdx2);
				}
			}
			bool flag3 = false;
			for (int num30 = 0; num30 < node4.edges.Count; num30++)
			{
				int mountainDataOfIdx3 = GetMountainDataOfIdx(mountainPositions, node4.edges[num30].posIdx);
				if (mountainDataOfIdx3 == -1)
				{
					continue;
				}
				TerrainGen.MountainData value3 = mountainPositions[mountainDataOfIdx3];
				if (value3.waterEdges == 0 || mountainPositions[mountainDataOfIdx3].type != TerrainGen.MountainData.Type.Exterior)
				{
					continue;
				}
				Vector3 rhs = value2.waterDir.normalized;
				if (value2.groupId != 0)
				{
					rhs = array[value2.groupId];
				}
				if (!(Vector3.Dot(value3.waterDir.normalized, rhs) > 0.85f))
				{
					continue;
				}
				flag3 = true;
				Node node5 = nodes.data[value3.posIdx];
				for (int num31 = 0; num31 < node5.edges.Count; num31++)
				{
					int mountainDataOfIdx4 = GetMountainDataOfIdx(mountainPositions, node5.edges[num31].posIdx);
					if (mountainDataOfIdx4 != -1 && list2.Contains(mountainDataOfIdx4))
					{
						flag3 = false;
						break;
					}
				}
				if (flag3)
				{
					if (value2.groupId == 0)
					{
						value3.groupId = num;
						array[value3.groupId] = ((value3.waterDir + value2.waterDir) / 2f).normalized;
					}
					else
					{
						value3.groupId = value2.groupId;
					}
					value3.type = TerrainGen.MountainData.Type.Edge;
					mountainPositions[mountainDataOfIdx3] = value3;
				}
			}
			if (flag3)
			{
				if (value2.groupId == 0)
				{
					value2.groupId = num;
					num++;
				}
				value2.type = TerrainGen.MountainData.Type.Edge;
				mountainPositions[num28] = value2;
			}
		}
		for (int num32 = 0; num32 < gridWidth; num32 += edgeHoleStep)
		{
			float num33 = edgeHoleRadius.Rand();
			PunchHole(num32, -2, (int)num33, ref waterTiles, ref landmassIdx);
		}
		for (int num34 = 0; num34 < gridWidth; num34 += edgeHoleStep)
		{
			float num35 = edgeHoleRadius.Rand();
			PunchHole(num34, gridHeight + 1, (int)num35, ref waterTiles, ref landmassIdx);
		}
		for (int num36 = 0; num36 < gridHeight; num36 += edgeHoleStep)
		{
			float num37 = edgeHoleRadius.Rand();
			PunchHole(-2, num36, (int)num37, ref waterTiles, ref landmassIdx);
		}
		for (int num38 = 0; num38 < gridHeight; num38 += edgeHoleStep)
		{
			float num39 = edgeHoleRadius.Rand();
			PunchHole(gridWidth + 1, num38, (int)num39, ref waterTiles, ref landmassIdx);
		}
		bool[] array2 = new bool[mountainPositions.Count];
		ArrayExt<TerrainGen.MountainData> arrayExt = new ArrayExt<TerrainGen.MountainData>(32);
		for (int num40 = 0; num40 < mountainPositions.Count; num40++)
		{
			if (array2[num40])
			{
				continue;
			}
			array2[num40] = true;
			TerrainGen.MountainData item3 = mountainPositions[num40];
			if (item3.type != TerrainGen.MountainData.Type.Interior)
			{
				continue;
			}
			ArrayExt<TerrainGen.MountainData> arrayExt2 = new ArrayExt<TerrainGen.MountainData>(8);
			arrayExt2.Add(item3);
			int landmassIdx2 = item3.landmassIdx;
			arrayExt.ClearFast();
			List<Node> edges2 = nodes.data[item3.posIdx].edges;
			for (int num41 = 0; num41 < edges2.Count; num41++)
			{
				TerrainGen.MountainData item4 = mountainPositions[edges2[num41].mDataIdx];
				if (item4.landmassIdx == landmassIdx2)
				{
					arrayExt.Add(item4);
				}
			}
			while (arrayExt.Count > 0)
			{
				TerrainGen.MountainData item5 = arrayExt.PopLast();
				if (array2[item5.idx])
				{
					continue;
				}
				array2[item5.idx] = true;
				if (item5.type != TerrainGen.MountainData.Type.Interior)
				{
					continue;
				}
				arrayExt2.Add(item5);
				edges2 = nodes.data[item5.posIdx].edges;
				for (int num42 = 0; num42 < edges2.Count; num42++)
				{
					TerrainGen.MountainData item6 = mountainPositions[edges2[num42].mDataIdx];
					if (item6.landmassIdx == landmassIdx2)
					{
						arrayExt.Add(item6);
					}
				}
			}
			Vector4 item7 = new Vector4(float.MaxValue, float.MinValue, float.MaxValue, float.MinValue);
			for (int num43 = 0; num43 < arrayExt2.Count; num43++)
			{
				Vector4 vector = arrayExt2.data[num43].pos;
				float num44 = arrayExt2.data[num43].radius + inflateRadiiForRaster;
				int num45 = (int)Mathff.Clamp(vector.x - num44, rasterBorder, gridWidth - rasterBorder);
				int num46 = (int)Mathff.Clamp(vector.z - num44, rasterBorder, gridHeight - rasterBorder);
				int num47 = (int)Mathff.Clamp(vector.x + num44, rasterBorder, gridWidth - rasterBorder);
				int num48 = (int)Mathff.Clamp(vector.z + num44, rasterBorder, gridHeight - rasterBorder);
				if (item7.x > (float)num45)
				{
					item7.x = num45;
				}
				if (item7.y < (float)num47)
				{
					item7.y = num47;
				}
				if (item7.z > (float)num46)
				{
					item7.z = num46;
				}
				if (item7.w < (float)num48)
				{
					item7.w = num48;
				}
			}
			islandInteriorBounds[landmassIdx2].Add(item7);
		}
		bool[] waterTiles2 = new bool[gridWidth * gridHeight];
		waterTiles.CopyTo(waterTiles2, 0);
		int num49 = 6;
		for (int num50 = 1; num50 < gridHeight - 1; num50++)
		{
			int num51 = 0;
			int num52 = 0;
			for (int num53 = 1; num53 < gridWidth - 1; num53++)
			{
				if (!waterTiles[num50 * gridWidth + num53])
				{
					num51 = (waterTiles[(num50 + 1) * gridWidth + num53] ? (num51 + 1) : 0);
					num52 = (waterTiles[(num50 - 1) * gridWidth + num53] ? (num52 + 1) : 0);
				}
				else
				{
					num52 = 0;
					num51 = 0;
				}
				if (num51 >= num49)
				{
					int x = num53 - SRand.Range(0, num51);
					PunchHole(x, num50 + 1, SRand.Range(1, 3), ref waterTiles2, ref landmassIdx);
					num51 = 0;
				}
				if (num52 >= num49)
				{
					int x2 = num53 - SRand.Range(0, num52 - 1);
					PunchHole(x2, num50 - 1, SRand.Range(1, 3), ref waterTiles2, ref landmassIdx);
					num52 = 0;
				}
			}
		}
		for (int num54 = 1; num54 < gridWidth - 1; num54++)
		{
			int num55 = 0;
			int num56 = 0;
			for (int num57 = 1; num57 < gridHeight - 1; num57++)
			{
				if (!waterTiles[num57 * gridWidth + num54])
				{
					num55 = (waterTiles[num57 * gridWidth + (num54 + 1)] ? (num55 + 1) : 0);
					num56 = (waterTiles[num57 * gridWidth + (num54 - 1)] ? (num56 + 1) : 0);
				}
				else
				{
					num56 = (num55 = 0);
				}
				if (num55 > num49)
				{
					int z = num57 - SRand.Range(0, num55 - 1);
					PunchHole(num54 + 1, z, SRand.Range(1, 3), ref waterTiles2, ref landmassIdx);
					num55 = 0;
				}
				if (num56 > num49)
				{
					int z2 = num57 - SRand.Range(0, num56 - 1);
					PunchHole(num54 - 1, z2, SRand.Range(1, 3), ref waterTiles2, ref landmassIdx);
					num56 = 0;
				}
			}
		}
		int num58 = 5;
		for (int num59 = num58; num59 < gridHeight - num58; num59++)
		{
			for (int num60 = num58; num60 < gridHeight - num58; num60++)
			{
				if (IsDiagonalShoreTile(num60, num59, waterTiles2))
				{
					int num61 = 0;
					for (int num62 = 0; num62 < num58; num62++)
					{
						num61 += (IsDiagonalShoreTile(num60 - 2 + num62, num59 - 2 + num62, waterTiles2) ? 1 : 0);
					}
					if (num61 >= 5)
					{
						waterTiles2[num59 * gridWidth + num60] = false;
						waterTiles2[(num59 + 1) * gridWidth + num60] = false;
						waterTiles2[(num59 - 1) * gridWidth + num60] = false;
						waterTiles2[num59 * gridWidth + (num60 + 1)] = false;
						waterTiles2[num59 * gridWidth + (num60 - 1)] = false;
					}
				}
			}
		}
		waterTiles = waterTiles2;
		for (int num63 = 0; num63 < waterTiles.Length; num63++)
		{
			if (waterTiles[num63])
			{
				height[num63] = TerrainGen.waterHeightDeep;
			}
		}
		for (int num64 = 0; num64 < nodes.Count; num64++)
		{
			Node node6 = nodes.data[num64];
			if (node6.islandID != -1)
			{
				continue;
			}
			int num65 = 0;
			for (int num66 = 0; num66 < node6.edges.Count; num66++)
			{
				num65 += ((node6.edges[num66].islandID != -1) ? 1 : 0);
			}
			_ = islandRadii[node6.posIdx];
			float num67 = 1f;
			if (SRand.Range(0, 100) < 25)
			{
				num67 = -1f;
			}
			int num68 = (int)(islandRadii[node6.posIdx] * 1.1f + 5f);
			int num69 = num68 * num68;
			Vector3 a2 = islandPos[node6.posIdx];
			int num70 = (int)Mathff.Clamp(a2.x - (float)num68, 0f, gridWidth);
			int num71 = (int)Mathff.Clamp(a2.z - (float)num68, 0f, gridHeight);
			int num72 = (int)Mathff.Clamp(a2.x + (float)num68, 0f, gridWidth);
			int num73 = (int)Mathff.Clamp(a2.z + (float)num68, 0f, gridHeight);
			for (int num74 = num70; num74 < num72; num74++)
			{
				for (int num75 = num71; num75 < num73; num75++)
				{
					float num76 = Mathff.DistSqrdXZ(b: new Vector3(num74, 0f, num75), a: a2);
					if (!(num76 < (float)num69))
					{
						continue;
					}
					int num77 = num75 * gridWidth + num74;
					if (waterTiles[num77])
					{
						height[num77] += Mathf.SmoothStep(0f, 1f, 1f - num76 / (float)num69) * (float)num65 * 1f * num67;
						if (height[num77] > TerrainGen.waterHeightShallow)
						{
							height[num77] = TerrainGen.waterHeightShallow;
						}
					}
				}
			}
		}
	}

	public TerrainGen.MountainData.Size GetMountainSizeFromArea(float area)
	{
		if (area >= minCircleArea * 1.75f)
		{
			return TerrainGen.MountainData.Size.Large;
		}
		if (area >= minCircleArea * 1.25f)
		{
			return TerrainGen.MountainData.Size.Medium;
		}
		return TerrainGen.MountainData.Size.Small;
	}

	private int GetMountainDataOfIdx(List<TerrainGen.MountainData> data, int idx)
	{
		for (int i = 0; i < data.Count; i++)
		{
			if (data[i].posIdx == idx)
			{
				return i;
			}
		}
		return -1;
	}

	private void MakeBump(Vector3 pos, float radius, float amount, ref float[] height, bool[] waterTiles)
	{
		float num = radius * radius;
		int num2 = (int)Mathff.Clamp(pos.x - radius, rasterBorder, gridWidth - rasterBorder);
		int num3 = (int)Mathff.Clamp(pos.z - radius, rasterBorder, gridHeight - rasterBorder);
		int num4 = (int)Mathff.Clamp(pos.x + radius, rasterBorder, gridWidth - rasterBorder);
		int num5 = (int)Mathff.Clamp(pos.z + radius, rasterBorder, gridHeight - rasterBorder);
		for (int i = num2; i < num4; i++)
		{
			for (int j = num3; j < num5; j++)
			{
				int num6 = j * gridWidth + i;
				if (!waterTiles[num6])
				{
					float num7 = Mathff.DistSqrdXZ(b: new Vector3(i, 0f, j), a: pos);
					if (num7 < num)
					{
						height[num6] += Mathf.SmoothStep(0f, 1f, 1f - num7 / num) * amount;
					}
				}
			}
		}
	}

	private void DrawCircles()
	{
		for (int i = 0; i < islandPos.Length; i++)
		{
			DebugEx.DrawCircleXZ(islandPos[i], islandRadii[i], Color.red);
		}
		DebugEx.DrawBox(new Vector3(0f, 0f, 0f), new Vector3(gridWidth, 0f, gridHeight), Color.red);
		for (int j = 0; j < nodes.Count; j++)
		{
			Node obj = nodes.data[j];
			Color color = Color.white;
			if (obj.islandID == -1)
			{
				color = Color.clear;
			}
			if (obj.islandID == 0)
			{
				color = Color.blue;
			}
			if (obj.islandID == 1)
			{
				color = Color.green;
			}
			if (obj.islandID == 2)
			{
				color = Color.cyan;
			}
			if (obj.islandID == 3)
			{
				color = Color.magenta;
			}
			if (obj.islandID == 4)
			{
				color = Color.black;
			}
			if (obj.islandID == 5)
			{
				color = Color.gray;
			}
			if (obj.islandID == 6)
			{
				color = new Color(255f, 255f, 125f);
			}
			DebugEx.DrawCircleXZ(islandPos[j], islandRadii[j] * 0.9f, color);
		}
	}
}
