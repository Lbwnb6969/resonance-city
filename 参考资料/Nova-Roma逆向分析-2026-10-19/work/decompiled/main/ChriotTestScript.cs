using System;
using System.Collections.Generic;
using Drawing;
using UnityEngine;

public class ChriotTestScript : MonoBehaviour
{
	public class Graph
	{
		public struct Intersection
		{
			public float t;

			public int type;
		}

		public AnimationCurve curve;

		public List<Intersection> intersects = new List<Intersection>();

		public const int Pass = 0;

		public const int Passed = 1;
	}

	public Graph[] graphs;

	public float radiusX = 1f;

	public float radiusZ = 0.5f;

	public float offsetAngle;

	public int resolution = 64;

	private void Start()
	{
		graphs = new Graph[4];
		for (int i = 0; i < graphs.Length; i++)
		{
			Graph obj = graphs[i];
			AnimationCurve animationCurve = new AnimationCurve();
			animationCurve.AddKey(0f, 0f);
			animationCurve.AddKey(0.1f, Mathf.Lerp(0.2f, 0.8f, i / (graphs.Length - 1)));
			animationCurve.AddKey(0f, 1f - (float)i * 0.1f);
			obj.curve = animationCurve;
		}
		for (int j = 0; j < resolution; j++)
		{
			float num = j / resolution;
			float num2 = (j + 1) / resolution;
			for (int k = 0; k < graphs.Length; k++)
			{
				Graph graph = graphs[k];
				Vector2 vector = new Vector2(num, graphs[k].curve.Evaluate(num));
				Vector2 vector2 = new Vector2(num2, graphs[k].curve.Evaluate(num2));
				for (int l = 0; l < graphs.Length; l++)
				{
					if (l != k)
					{
						Graph graph2 = graphs[k];
						Vector2 vector3 = new Vector2(num, graphs[l].curve.Evaluate(num));
						Vector2 vector4 = new Vector2(num2, graphs[l].curve.Evaluate(num2));
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
								type = ((!(vector4.y > vector2.y)) ? 1 : 0)
							});
						}
					}
				}
			}
		}
	}

	private void Update()
	{
		for (int i = 0; i < 2; i++)
		{
			DebugEx.DrawEllipse(transform.GetChild(0), radiusX, radiusZ, Color.white, 32);
		}
		for (int j = 0; j < graphs.Length; j++)
		{
			Graph graph = graphs[j];
			for (int k = 0; k < graph.intersects.Count; k++)
			{
				GetPathPosition(out var pos, out var _, graph.intersects[k].t);
				pos.y = ((graph.intersects[k].type == 0) ? 0f : 0.2f);
				Draw.xz.Circle(pos, 0.5f, (graph.intersects[k].type == 0) ? Color.green : Color.red);
			}
		}
	}

	public void GetPathPosition(out Vector3 pos, out Vector3 dir, float t)
	{
		float f = t * 2f * MathF.PI + offsetAngle * (MathF.PI / 180f);
		float x = (0f - radiusX) * Mathf.Sin(f);
		float z = radiusZ * Mathf.Cos(f);
		dir = new Vector3(x, 0f, z).normalized;
		pos.x = radiusX * Mathf.Cos(f);
		pos.y = 0f;
		pos.z = radiusZ * Mathf.Sin(f);
	}
}
