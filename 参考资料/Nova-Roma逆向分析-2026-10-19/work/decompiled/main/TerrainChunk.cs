using System;
using UnityEngine;

public class TerrainChunk : MonoBehaviour
{
	[NonSerialized]
	public int x;

	[NonSerialized]
	public int z;

	private int xSize;

	private int zSize;

	private int meshSizeX;

	private int meshSizeZ;

	private Mesh mesh;

	public MeshRenderer meshRenderer;

	public Vector3[] verticies;

	public bool dirtyVerts;

	private Vector2 UvStart;

	private Vector2 UvEnd;

	public int worldToChunk;

	private MeshCollider meshCollider;

	public int SizeX
	{
		get
		{
			return xSize;
		}
		set
		{
			xSize = value;
		}
	}

	public int SizeZ
	{
		get
		{
			return zSize;
		}
		set
		{
			zSize = value;
		}
	}

	public int MeshSizeX => meshSizeX;

	public int MeshSizeZ => meshSizeZ;

	public void Init(int posX, int posZ, int xSize, int zSize, Vector2 UvStart, Vector2 UvEnd)
	{
		x = posX;
		z = posZ;
		this.UvStart = UvStart;
		this.UvEnd = UvEnd;
		this.xSize = xSize;
		this.zSize = zSize;
		meshSizeX = xSize * 2 + 1;
		meshSizeZ = zSize * 2 + 1;
		worldToChunk = x + z * World.MeshWidth;
		mesh = GetComponent<MeshFilter>().mesh;
		meshRenderer = GetComponent<MeshRenderer>();
		meshCollider = GetComponent<MeshCollider>();
	}

	public void UpdateCPUVerts()
	{
		verticies = mesh.vertices;
	}

	public void FinalizeChanges()
	{
		mesh.vertices = verticies;
		mesh.RecalculateNormals();
		mesh.RecalculateBounds();
		meshCollider = GetComponent<MeshCollider>();
		meshCollider.cookingOptions = MeshColliderCookingOptions.UseFastMidphase;
		meshCollider.sharedMesh = mesh;
	}

	public bool Raycast(Ray ray, out RaycastHit hitInfo)
	{
		return GetComponent<MeshCollider>().Raycast(ray, out hitInfo, 10000f);
	}
}
