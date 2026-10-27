using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshRenderer))]
[RequireComponent(typeof(MeshFilter))]
public class QuadMesh : MonoBehaviour
{
	public Transform[] points = new Transform[4];

	private Mesh mesh;

	private void Start()
	{
		UpdateMesh();
	}

	private List<Vector3> GetPoints()
	{
		List<Vector3> list = new List<Vector3>();
		for (int i = 0; i < points.Length; i++)
		{
			list.Add(points[i].localPosition);
		}
		list.Add(points[1].localPosition);
		list.Add(points[0].localPosition);
		list.Add(points[3].localPosition);
		list.Add(points[2].localPosition);
		return list;
	}

	private void UpdateMesh()
	{
		if (points.Length != 4)
		{
			return;
		}
		for (int i = 0; i < points.Length; i++)
		{
			if (points[i] == null)
			{
				return;
			}
		}
		Mesh mesh;
		if (GetComponent<MeshFilter>().sharedMesh == null)
		{
			mesh = new Mesh();
			GetComponent<MeshFilter>().mesh = mesh;
		}
		else
		{
			mesh = GetComponent<MeshFilter>().sharedMesh;
		}
		mesh.Clear();
		mesh.SetVertices(new List<Vector3>(GetPoints()));
		mesh.SetIndices(new int[8] { 0, 1, 2, 3, 4, 5, 6, 7 }, MeshTopology.Quads, 0);
		Vector2[] collection = new Vector2[8]
		{
			new Vector2(0f, 0f),
			new Vector2(1f, 0f),
			new Vector2(1f, 1f),
			new Vector2(0f, 1f),
			new Vector2(0f, 0f),
			new Vector2(1f, 0f),
			new Vector2(1f, 1f),
			new Vector2(0f, 1f)
		};
		mesh.SetUVs(0, new List<Vector2>(collection));
		mesh.RecalculateNormals();
	}

	private void OnRenderObject()
	{
		if (Application.isEditor && !Application.isPlaying)
		{
			UpdateMesh();
		}
	}
}
