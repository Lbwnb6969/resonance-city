using System;
using System.Collections.Generic;
using Drawing;
using UnityEngine;

public class ChriotTest : MonoBehaviour
{
	[Serializable]
	public class Track
	{
		public float radiusX = 1f;

		public float radiusZ = 0.5f;

		public float varianceX;

		public float varianceZ;

		public float prevVarianceX;

		public float prevVarianceZ;

		public float desiredVarianceX;

		public float desiredVarianceZ;

		public void GenerateVariance(float variance)
		{
			prevVarianceX = varianceX;
			prevVarianceZ = varianceZ;
			desiredVarianceX = SRand.Range(0f - variance, variance);
			desiredVarianceZ = SRand.Range(0f - variance, variance);
		}
	}

	[Serializable]
	public class Graph
	{
		public struct Intersection
		{
			public float t;

			public int type;
		}

		public Vector2[] points = new Vector2[101];

		public GameObject obj;

		public int trackIdx;

		public List<Intersection> intersects = new List<Intersection>();

		public const int Pass = 0;

		public const int Passed = 1;
	}

	public List<Graph> graphs = new List<Graph>(4);

	[NonSerialized]
	public List<Track> tracks = new List<Track>();

	public GameObject[] objs;

	public float radiusX = 1f;

	public float radiusZ = 0.5f;

	public int resolution = 64;

	public float variance = 0.175f;

	private const int STEPS = 100;

	public float accelerationStrength = 0.005f;

	public float damping = 0.95f;

	public float maxVelocity = 0.03f;

	public float minVelocity = 0.003f;

	public float spreadRangeMin = 0.00025f;

	public float spreadRangeMax = 0.0005f;

	public float minPlaceOffset = 0.003f;

	public float maxPlaceOffset = 0.005f;

	public float speedMultiplier = 1f;

	private float t;

	public float speed = 0.1f;

	public static Color[] DebugColors = new Color[4]
	{
		Color.yellow,
		Color.magenta,
		Color.blue,
		Color.orange
	};

	public int randomizeTrackAfterFrame = 25;

	private int frameCount;

	public float offsetAngle;

	private void Start()
	{
		for (int i = 0; i < 6; i++)
		{
			Track track = new Track();
			track.radiusX = radiusX + (float)i * 0.5f;
			track.radiusZ = radiusZ + (float)i * 0.25f;
			track.GenerateVariance(variance);
			tracks.Add(track);
		}
		GenerateSmoothGraph();
	}

	private void GenerateSmoothGraph()
	{
		t = 0f;
		float num = 0f;
		int num2 = SRand.Range(0, graphs.Count);
		for (int i = 0; i < graphs.Count; i++)
		{
			Graph graph = graphs[i];
			float num3 = 0f;
			float num4 = 0f;
			graph.trackIdx = (i + 2) % tracks.Count / 2 * 2;
			float num5 = (num2 + i) % graphs.Count;
			for (int j = 0; j <= 100; j++)
			{
				float x = (float)j / 100f;
				float num6 = (SRand.Range(0f, 1f) * 2f - 1f) * accelerationStrength;
				if (j == 0)
				{
					num4 += ((float)(graphs.Count - 1) - num5) * SRand.Range(spreadRangeMin, spreadRangeMax);
				}
				num4 += num6;
				num4 = Mathff.Max(num4, minVelocity);
				num4 = Mathff.Min(num4 * damping, maxVelocity);
				num3 += num4;
				graph.points[j] = new Vector2(x, num3);
			}
			if (i != 0)
			{
				num += SRand.Range(minPlaceOffset, maxPlaceOffset);
			}
			float num7 = (1f - num) / graph.points[100].y;
			for (int k = 0; k <= 100; k++)
			{
				Vector2 vector = graph.points[k];
				vector.y *= num7;
				graph.points[k] = vector;
			}
		}
		CalculateIntersections();
	}

	private void CalculateIntersections()
	{
		for (int i = 0; i < graphs.Count; i++)
		{
			graphs[i].intersects.Clear();
		}
		for (int j = 1; j <= 100; j++)
		{
			float num = (float)j / 100f;
			_ = (float)(j + 1) / 100f;
			for (int k = 0; k < graphs.Count; k++)
			{
				Graph graph = graphs[k];
				Vector2 vector = graph.points[j - 1];
				Vector2 vector2 = graph.points[j];
				for (int l = 0; l < graphs.Count; l++)
				{
					if (l != k)
					{
						Graph graph2 = graphs[l];
						Vector2 vector3 = graph2.points[j - 1];
						Vector2 vector4 = graph2.points[j];
						float i_x = 0f;
						float i_y = 0f;
						if (Mathff.LineSegmentIntersection2D(vector.x, vector.y, vector2.x, vector2.y, vector3.x, vector3.y, vector4.x, vector4.y, ref i_x, ref i_y) == 1)
						{
							graph2.intersects.Add(new Graph.Intersection
							{
								t = num,
								type = ((!(vector4.y > vector2.y)) ? 1 : 0)
							});
							graph.intersects.Add(new Graph.Intersection
							{
								t = num,
								type = ((vector4.y > vector2.y) ? 1 : 0)
							});
						}
					}
				}
			}
		}
	}

	private void Update()
	{
		frameCount = (frameCount + 1) % randomizeTrackAfterFrame;
		for (int i = 0; i < tracks.Count; i++)
		{
			Track track = tracks[i];
			if (frameCount == 0)
			{
				track.GenerateVariance(variance);
			}
			float num = (float)frameCount / (float)randomizeTrackAfterFrame;
			track.varianceX = Mathf.Lerp(track.prevVarianceX, track.desiredVarianceX, num);
			track.varianceZ = Mathf.Lerp(track.prevVarianceZ, track.desiredVarianceZ, num);
			DebugEx.DrawEllipse(transform, track.radiusX + track.varianceX, track.radiusZ + track.varianceZ, GetDebugColor(i), 32);
		}
		if (Input.GetKeyDown(KeyCode.Alpha1))
		{
			speedMultiplier = 1f;
		}
		else if (Input.GetKeyDown(KeyCode.Alpha2))
		{
			speedMultiplier = 1.75f;
		}
		else if (Input.GetKeyDown(KeyCode.Alpha3))
		{
			speedMultiplier = 2.5f;
		}
		t = (t + speed * speedMultiplier) % 1f;
		for (int j = 0; j < graphs.Count; j++)
		{
			Graph graph = graphs[j];
			float num2 = Evaluate(graph, t) * 5f;
			GetPathPosition(tracks[graph.trackIdx], out var pos, out var dir, num2);
			graph.obj.transform.position = pos;
			graph.obj.transform.rotation = Quaternion.LookRotation(dir);
			for (int k = 1; k < graph.points.Length; k++)
			{
				Vector2 vector = graph.points[k - 1];
				Draw.Line(b: graph.points[k], a: vector, color: GetDebugColor(j));
			}
			for (int l = 0; l < graph.intersects.Count; l++)
			{
				Graph.Intersection intersection = graph.intersects[l];
				float y = Evaluate(graph, intersection.t);
				Vector2 vector2 = new Vector2
				{
					x = intersection.t,
					y = y
				};
			}
		}
	}

	public Color GetDebugColor(int idx)
	{
		return DebugColors[idx % DebugColors.Length];
	}

	public float Evaluate(Graph graph, float t)
	{
		int num = Mathf.FloorToInt(t * 100f);
		float num2 = 0.01f;
		float num3 = (t - (float)num * num2) / num2;
		float y = graph.points[num].y;
		float b = ((num >= graph.points.Length - 1) ? y : graph.points[num + 1].y);
		return Mathff.Lerp(y, b, num3);
	}

	public void GetPathPosition(Track track, out Vector3 pos, out Vector3 dir, float t)
	{
		float f = t * 2f * MathF.PI + offsetAngle * (MathF.PI / 180f);
		float num = track.radiusX + track.varianceX;
		float num2 = track.radiusZ + track.varianceZ;
		float x = (0f - num) * Mathf.Sin(f);
		float z = num2 * Mathf.Cos(f);
		dir = new Vector3(x, 0f, z).normalized;
		pos.x = num * Mathf.Cos(f);
		pos.y = 0f;
		pos.z = num2 * Mathf.Sin(f);
	}
}
