using System.Collections.Generic;
using Assets;
using UnityEngine;

public class PathDrawer : MonoBehaviour
{
	private struct PathIndex
	{
		public int start;

		public int end;
	}

	public static PathDrawer inst;

	private int currStart;

	private Matrix4x4[] points = new Matrix4x4[1024];

	private Matrix4x4[] marks = new Matrix4x4[1024];

	private List<PathIndex> paths = new List<PathIndex>();

	public Material pathMarkerMat;

	public Mesh pathMesh;

	public Mesh markerMesh;

	public float pathThickness = 0.5f;

	public float markerSize = 1f;

	public float heightOffset = 0.1f;

	private void Awake()
	{
		inst = this;
	}

	public void AddPath(Vector3 person, List<Vector3> path)
	{
		if (path.Count <= 0)
		{
			return;
		}
		PathIndex pathIndex = default;
		pathIndex.start = currStart;
		pathIndex.end = pathIndex.start + path.Count + 1;
		if (pathIndex.end < points.Length)
		{
			Vector3 scale = new Vector3(markerSize, markerSize, markerSize);
			Vector3 forward = path[0] - person;
			Vector3 scale2 = new Vector3(pathThickness, pathThickness, forward.magnitude);
			Quaternion rot = Quaternion.LookRotation(forward, new Vector3(0f, 1f, 0f));
			Mathff.SetTRS(ref points[pathIndex.start], person + new Vector3(0f, heightOffset, 0f), rot, scale2);
			Mathff.SetTRS(ref marks[pathIndex.start], person + new Vector3(0f, heightOffset, 0f), rot, scale);
			for (int i = 0; i < path.Count - 1; i++)
			{
				Vector3 forward2 = path[i + 1] - path[i];
				Vector3 scale3 = new Vector3(pathThickness, pathThickness, forward2.magnitude);
				Quaternion rot2 = Quaternion.LookRotation(forward2, new Vector3(0f, 1f, 0f));
				Mathff.SetTRS(ref points[i + pathIndex.start + 1], path[i] + new Vector3(0f, heightOffset, 0f), rot2, scale3);
				Mathff.SetTRS(ref marks[i + pathIndex.start + 1], path[i] + new Vector3(0f, heightOffset, 0f), rot2, scale);
			}
		}
		currStart = pathIndex.end;
	}

	public void Clear()
	{
		paths.Clear();
		currStart = 0;
	}

	public void Draw()
	{
		if (Settings.inst.supportsInstancing)
		{
			Graphics.DrawMeshInstanced(pathMesh, 0, pathMarkerMat, points, currStart);
			Graphics.DrawMeshInstanced(markerMesh, 0, pathMarkerMat, marks, currStart);
		}
	}
}
