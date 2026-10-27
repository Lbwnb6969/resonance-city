using System.Collections.Generic;
using UnityEngine;

public class TerrainSkirt : MonoBehaviour
{
	private Mesh mesh;

	private MeshFilter meshFilter;

	public float skirtLength = 10f;

	public float skirtHeight = -4f;

	private ArrayExt<Vector3> verts;

	private List<int> tris = new List<int>();

	private int index;

	public void RebuildSkirt()
	{
		if (meshFilter == null)
		{
			meshFilter = GetComponent<MeshFilter>();
		}
		mesh = new Mesh();
		verts = new ArrayExt<Vector3>(100);
		tris = new List<int>();
		index = 0;
		for (int i = 0; i < World.MeshWidth; i++)
		{
			for (int num = 0; num < World.MeshHeight; num = ((i != 0 && i != World.MeshWidth - 1) ? (num + (World.MeshHeight - 1)) : (num + 1)))
			{
				TerrainGen.inst.SetVert(i, num, skirtHeight, bakeDown: true);
			}
		}
		AddPoint(new Vector3(World.inst.GridWidth, skirtHeight, 0f));
		AddPoint(new Vector3(0f - skirtLength, skirtHeight, 0f - skirtLength));
		AddPoint(new Vector3(0f, skirtHeight, 0f));
		AddPoint(new Vector3(0f - skirtLength, skirtHeight, 0f - skirtLength));
		AddPoint(new Vector3(World.inst.GridWidth, skirtHeight, 0f));
		AddPoint(new Vector3((float)World.inst.GridWidth + skirtLength, skirtHeight, 0f - skirtLength));
		AddPoint(new Vector3(0f, skirtHeight, World.inst.GridHeight));
		AddPoint(new Vector3((float)World.inst.GridWidth + skirtLength, skirtHeight, (float)World.inst.GridHeight + skirtLength));
		AddPoint(new Vector3(World.inst.GridWidth, skirtHeight, World.inst.GridHeight));
		AddPoint(new Vector3((float)World.inst.GridWidth + skirtLength, skirtHeight, (float)World.inst.GridHeight + skirtLength));
		AddPoint(new Vector3(0f, skirtHeight, World.inst.GridHeight));
		AddPoint(new Vector3(0f - skirtLength, skirtHeight, (float)World.inst.GridHeight + skirtLength));
		AddPoint(new Vector3(0f - skirtLength, skirtHeight, 0f - skirtLength));
		AddPoint(new Vector3(0f - skirtLength, skirtHeight, (float)World.inst.GridHeight + skirtLength));
		AddPoint(new Vector3(0f, skirtHeight, 0f));
		AddPoint(new Vector3(0f - skirtLength, skirtHeight, (float)World.inst.GridHeight + skirtLength));
		AddPoint(new Vector3(0f, skirtHeight, World.inst.GridHeight));
		AddPoint(new Vector3(0f, skirtHeight, 0f));
		AddPoint(new Vector3((float)World.inst.GridWidth + skirtLength, skirtHeight, (float)World.inst.GridHeight + skirtLength));
		AddPoint(new Vector3((float)World.inst.GridWidth + skirtLength, skirtHeight, 0f - skirtLength));
		AddPoint(new Vector3(World.inst.GridWidth, skirtHeight, World.inst.GridHeight));
		AddPoint(new Vector3((float)World.inst.GridWidth + skirtLength, skirtHeight, 0f - skirtLength));
		AddPoint(new Vector3(World.inst.GridWidth, skirtHeight, 0f));
		AddPoint(new Vector3(World.inst.GridWidth, skirtHeight, World.inst.GridHeight));
		mesh.Clear();
		mesh.SetVertices(verts.data);
		mesh.SetTriangles(tris, 0);
		mesh.RecalculateBounds();
		mesh.RecalculateNormals();
		mesh.RecalculateTangents();
		meshFilter.sharedMesh = mesh;
	}

	public void AddPoint(Vector3 point)
	{
		int i = 0;
		for (int count = verts.Count; i < count; i++)
		{
			if (Mathff.DistSqrd(point, verts.data[i]) < 0.0001f)
			{
				tris.Add(i);
				return;
			}
		}
		verts.Add(point);
		tris.Add(index++);
	}

	private void OnValidate()
	{
		if (Application.isPlaying && World.inst != null)
		{
			RebuildSkirt();
		}
	}
}
