using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Placer : MonoBehaviour
{
	private class PlacerConfiguration
	{
		public Vector3 BlockSize = new Vector3(1f, 0.5f, 1f);

		public bool Place2OnGround = true;
	}

	private struct CuboidResult
	{
		public int XPosExtent;

		public int XNegExtent;

		public int YPosExtent;

		public int YNegExtent;

		public int ZPosExtent;

		public int ZNegExtent;

		public BlockGraphNode OriginNode;

		private List<BlockGraphNode> _nodeList;

		private BlockGraphNode[][][] _nodes3D;

		public CuboidResult(CuboidResult copyFrom)
		{
			this = default;
			XPosExtent = copyFrom.XPosExtent;
			XNegExtent = copyFrom.XNegExtent;
			YPosExtent = copyFrom.YPosExtent;
			YNegExtent = copyFrom.YNegExtent;
			ZPosExtent = copyFrom.ZPosExtent;
			ZNegExtent = copyFrom.ZNegExtent;
			OriginNode = copyFrom.OriginNode;
		}

		public int GetSpreadX()
		{
			return XNegExtent + 1 + XPosExtent;
		}

		public int GetSpreadY()
		{
			return YNegExtent + 1 + YPosExtent;
		}

		public int GetSpreadZ()
		{
			return ZNegExtent + 1 + ZPosExtent;
		}

		public CuboidResult AddXPos()
		{
			XPosExtent++;
			return this;
		}

		public CuboidResult AddXNeg()
		{
			XNegExtent++;
			return this;
		}

		public CuboidResult AddYPos()
		{
			YPosExtent++;
			return this;
		}

		public CuboidResult AddYNeg()
		{
			YNegExtent++;
			return this;
		}

		public CuboidResult AddZPos()
		{
			ZPosExtent++;
			return this;
		}

		public CuboidResult AddZNeg()
		{
			ZNegExtent++;
			return this;
		}

		public int GetVolume()
		{
			return (XPosExtent + Mathf.Abs(XNegExtent + 1)) * (YPosExtent + Mathf.Abs(YNegExtent + 1)) * (ZPosExtent + Mathf.Abs(ZNegExtent + 1));
		}

		public BlockGraphNode[][][] GetNodesArray()
		{
			if (_nodes3D == null)
			{
				CrunchNodeData();
			}
			return _nodes3D;
		}

		public List<BlockGraphNode> GetNodes()
		{
			if (_nodeList == null)
			{
				CrunchNodeData();
			}
			return _nodeList;
		}

		public void CrunchNodeData()
		{
			_nodeList = new List<BlockGraphNode>();
			_nodes3D = new BlockGraphNode[GetSpreadX()][][];
			BlockGraphNode blockGraphNode = OriginNode;
			for (int i = 0; i < XNegExtent; i++)
			{
				blockGraphNode = blockGraphNode.XNeg;
			}
			for (int j = 0; j < YNegExtent; j++)
			{
				blockGraphNode = blockGraphNode.YNeg;
			}
			for (int k = 0; k < ZNegExtent; k++)
			{
				blockGraphNode = blockGraphNode.ZNeg;
			}
			BlockGraphNode blockGraphNode2 = blockGraphNode;
			BlockGraphNode blockGraphNode3 = blockGraphNode;
			BlockGraphNode blockGraphNode4 = blockGraphNode;
			for (int l = -XNegExtent; l <= XPosExtent; l++)
			{
				_nodes3D[l + XNegExtent] = new BlockGraphNode[GetSpreadY()][];
				for (int m = -YNegExtent; m <= YPosExtent; m++)
				{
					_nodes3D[l + XNegExtent][m + YNegExtent] = new BlockGraphNode[GetSpreadZ()];
					for (int n = -ZNegExtent; n <= ZPosExtent; n++)
					{
						_nodeList.Add(blockGraphNode4);
						_nodes3D[l + XNegExtent][m + YNegExtent][n + ZNegExtent] = blockGraphNode4;
						blockGraphNode4 = blockGraphNode4.ZPos;
					}
					blockGraphNode3 = blockGraphNode3.YPos;
					blockGraphNode4 = blockGraphNode3;
				}
				blockGraphNode2 = blockGraphNode2.XPos;
				blockGraphNode3 = blockGraphNode2;
				blockGraphNode4 = blockGraphNode3;
			}
		}

		public BlockGraphNode FindMinNode()
		{
			BlockGraphNode blockGraphNode = OriginNode;
			while (blockGraphNode.XNeg != null)
			{
				blockGraphNode = blockGraphNode.XNeg;
			}
			while (blockGraphNode.YNeg != null)
			{
				blockGraphNode = blockGraphNode.YNeg;
			}
			while (blockGraphNode.ZNeg != null)
			{
				blockGraphNode = blockGraphNode.ZNeg;
			}
			return blockGraphNode;
		}

		public void GetMinMax(out Vector3 min, out Vector3 max)
		{
			min = Min();
			max = Max();
		}

		public Vector3 Min()
		{
			return new Vector3(-XNegExtent, (float)(-YNegExtent) / 2f, -ZNegExtent) + new Vector3(-0.5f, -0.25f, -0.5f) + OriginNode.transform.position;
		}

		public Vector3 Max()
		{
			return new Vector3(XPosExtent, (float)YPosExtent / 2f, ZPosExtent) + new Vector3(0.5f, 0.25f, 0.5f) + OriginNode.transform.position;
		}

		public Vector3 GetSize()
		{
			GetMinMax(out var min, out var max);
			return max - min;
		}

		public Vector3Int GetDimensions()
		{
			return new Vector3Int(GetSpreadX(), GetSpreadY(), GetSpreadZ());
		}
	}

	private class MeshScore
	{
		public MeshDescriptor mesh;

		public float score;

		public bool rotated;
	}

	public MeshDescriptor[] meshCollection;

	public GameObject blockPrefab;

	public BoxCollider boxCollider;

	public ColliderCollector colliderCollector;

	public Collider worldPlaneCollider;

	public LayerMask layerMask;

	private bool groundPlacement;

	private GameObject _holding;

	private RaycastHit _hit;

	private PlacerConfiguration _placerConfiguration = new PlacerConfiguration();

	private Vector3 maxMeshSize = Vector3.zero;

	private Material sharedMat;

	private Vector3[] boxSides = new Vector3[1] { Vector3.up / 2f };

	private CuboidResult largestCuboid;

	private Queue<CuboidResult> _queue = new Queue<CuboidResult>();

	private void Start()
	{
		boxCollider = GetComponent<BoxCollider>();
		colliderCollector = GetComponent<ColliderCollector>();
	}

	private void ScanMeshesForMaxSizes()
	{
		for (int i = 0; i < meshCollection.Length; i++)
		{
			Vector3 size = meshCollection[i].Size;
			Vector3 vector = new Vector3(size.z, size.y, size.x);
			if (size.x > maxMeshSize.x)
			{
				maxMeshSize.x = size.x;
			}
			if (size.y > maxMeshSize.y)
			{
				maxMeshSize.y = size.y;
			}
			if (size.z > maxMeshSize.z)
			{
				maxMeshSize.z = size.z;
			}
			if (vector.x > maxMeshSize.x)
			{
				maxMeshSize.x = vector.x;
			}
			if (vector.y > maxMeshSize.y)
			{
				maxMeshSize.y = vector.y;
			}
			if (vector.z > maxMeshSize.z)
			{
				maxMeshSize.z = vector.z;
			}
		}
		maxMeshSize.x = (float)Math.Ceiling(maxMeshSize.x);
		maxMeshSize.y = (float)Math.Ceiling(maxMeshSize.y);
		maxMeshSize.z = (float)Math.Ceiling(maxMeshSize.z);
	}

	private void Update()
	{
		if (_holding == null)
		{
			_holding = UnityEngine.Object.Instantiate(blockPrefab);
			_holding.GetComponent<BoxCollider>().enabled = false;
			sharedMat = _holding.GetComponentInChildren<MeshRenderer>().sharedMaterial;
		}
		Ray ray = PointingSystem.GetRay();
		if (!Physics.Raycast(ray, out _hit, 100f, layerMask))
		{
			return;
		}
		Vector3 vector = (transform.position = ray.GetPoint(_hit.distance - 0.01f));
		sharedMat.SetVector("Cursor", vector);
		Vector3 vector2 = Vector3.zero;
		float num = float.MaxValue;
		Collider collider = _hit.collider;
		List<Collider> colliders = colliderCollector.GetColliders();
		for (int i = 0; i < colliders.Count; i++)
		{
			Collider collider2 = colliders[i];
			for (int j = 0; j < boxSides.Length; j++)
			{
				Vector3 vector3 = boxSides[j] + collider2.transform.position;
				float num2 = Vector3.Distance(vector3, vector);
				if (num2 < num)
				{
					num = num2;
					vector2 = vector3;
					collider = collider2;
				}
			}
		}
		Physics.Simulate(0f);
		Vector3 zero = Vector3.zero;
		if (_hit.collider.gameObject.layer == 11 && _hit.collider == collider)
		{
			_holding.transform.position = vector2;
			Vector3 vector4 = _holding.transform.localScale / 2f;
			vector = new Vector3(Mathf.Floor(vector.x) + vector4.x, Mathf.Round(vector.y) + vector4.y, Mathf.Floor(vector.z) + vector4.z);
			zero = vector;
		}
		else
		{
			zero = vector2;
		}
		bool flag = true;
		List<Collider> colliders2 = colliderCollector.GetColliders();
		for (int k = 0; k < colliders2.Count; k++)
		{
			if (Vector3.Distance(colliders2[k].transform.position, zero) < 0.1f)
			{
				flag = false;
				break;
			}
		}
		if (flag)
		{
			_holding.transform.position = zero;
			groundPlacement = zero.y < 0.6f;
		}
		if (Input.GetMouseButtonDown(0))
		{
			BlockGraphNode blockGraphNode = _holding.GetComponent<BlockGraphNode>();
			_holding.GetComponent<BoxCollider>().enabled = true;
			ConnectToBlockGrid(blockGraphNode);
			if (groundPlacement && _placerConfiguration.Place2OnGround)
			{
				BlockGraphNode component = UnityEngine.Object.Instantiate(blockPrefab).GetComponent<BlockGraphNode>();
				component.transform.position = blockGraphNode.transform.position + boxSides[0];
				ConnectToBlockGrid(component);
				blockGraphNode = component;
			}
			largestCuboid = FindNodesOfLargestCuboid(blockGraphNode);
			CleanAndPlaceNewMesh(largestCuboid);
			_holding = null;
		}
	}

	private void ConnectToBlockGrid(BlockGraphNode newBlockNode)
	{
		List<BlockGraphNode> list = (from x in Physics.BoxCastAll(newBlockNode.transform.position, new Vector3(0.6f, 0.3f, 0.6f), Vector3.up, Quaternion.identity, 0f, layerMask)
			select x.collider.GetComponent<BlockGraphNode>()).ToList();
		for (int num = 0; num < list.Count; num++)
		{
			BlockGraphNode blockGraphNode = list[num];
			if (!(blockGraphNode == null) && !(blockGraphNode == newBlockNode))
			{
				Vector3 normalized = (blockGraphNode.transform.position - newBlockNode.transform.position).normalized;
				if (Vector3.Dot(normalized, Vector3.up * 2f) >= 0.99f)
				{
					newBlockNode.YPos = blockGraphNode;
					blockGraphNode.YNeg = newBlockNode;
				}
				else if (Vector3.Dot(normalized, Vector3.down * 2f) >= 0.99f)
				{
					newBlockNode.YNeg = blockGraphNode;
					blockGraphNode.YPos = newBlockNode;
				}
				else if (Vector3.Dot(normalized, Vector3.forward) >= 0.99f)
				{
					newBlockNode.ZPos = blockGraphNode;
					blockGraphNode.ZNeg = newBlockNode;
				}
				else if (Vector3.Dot(normalized, Vector3.back) >= 0.99f)
				{
					newBlockNode.ZNeg = blockGraphNode;
					blockGraphNode.ZPos = newBlockNode;
				}
				else if (Vector3.Dot(normalized, Vector3.right) >= 0.99f)
				{
					newBlockNode.XPos = blockGraphNode;
					blockGraphNode.XNeg = newBlockNode;
				}
				else if (Vector3.Dot(normalized, Vector3.left) >= 0.99f)
				{
					newBlockNode.XNeg = blockGraphNode;
					blockGraphNode.XPos = newBlockNode;
				}
			}
		}
	}

	private void OnDrawGizmos()
	{
		if (!(largestCuboid.OriginNode == null))
		{
			largestCuboid.GetMinMax(out var min, out var max);
			Gizmos.DrawLine(min, max);
			Gizmos.DrawWireCube((max - min) / 2f + min, max - min);
		}
	}

	private CuboidResult FindNodesOfLargestCuboid(BlockGraphNode startNode)
	{
		CuboidResult cuboidResult = new CuboidResult
		{
			OriginNode = startNode
		};
		CuboidResult result = cuboidResult;
		_queue.Enqueue(cuboidResult);
		while (_queue.Count > 0)
		{
			CuboidResult cuboidResult2 = _queue.Dequeue();
			bool flag = true;
			for (int i = -cuboidResult2.XNegExtent; i <= cuboidResult2.XPosExtent; i++)
			{
				for (int j = -cuboidResult2.YNegExtent; j <= cuboidResult2.YPosExtent; j++)
				{
					for (int k = -cuboidResult2.ZNegExtent; k <= cuboidResult2.ZPosExtent; k++)
					{
						flag &= TestExtent(startNode, i, j, k);
						if (!flag)
						{
							goto end_IL_0091;
						}
					}
				}
				continue;
				end_IL_0091:
				break;
			}
			if (flag)
			{
				if (cuboidResult2.GetVolume() > result.GetVolume())
				{
					result = cuboidResult2;
				}
				_queue.Enqueue(new CuboidResult(cuboidResult2).AddXPos());
				_queue.Enqueue(new CuboidResult(cuboidResult2).AddXNeg());
				_queue.Enqueue(new CuboidResult(cuboidResult2).AddYPos());
				_queue.Enqueue(new CuboidResult(cuboidResult2).AddYNeg());
				_queue.Enqueue(new CuboidResult(cuboidResult2).AddZPos());
				_queue.Enqueue(new CuboidResult(cuboidResult2).AddZNeg());
			}
		}
		return result;
	}

	private bool TestExtent(BlockGraphNode startNode, int x, int y, int z)
	{
		BlockGraphNode blockGraphNode = startNode;
		if (x > 0)
		{
			for (int i = 0; i < x; i++)
			{
				if (blockGraphNode.XPos == null)
				{
					return false;
				}
				blockGraphNode = blockGraphNode.XPos;
			}
		}
		else if (x < 0)
		{
			for (int j = 0; j < -x; j++)
			{
				if (blockGraphNode.XNeg == null)
				{
					return false;
				}
				blockGraphNode = blockGraphNode.XNeg;
			}
		}
		if (y > 0)
		{
			for (int k = 0; k < y; k++)
			{
				if (blockGraphNode.YPos == null)
				{
					return false;
				}
				blockGraphNode = blockGraphNode.YPos;
			}
		}
		else if (y < 0)
		{
			for (int l = 0; l < -y; l++)
			{
				if (blockGraphNode.YNeg == null)
				{
					return false;
				}
				blockGraphNode = blockGraphNode.YNeg;
			}
		}
		if (z > 0)
		{
			for (int m = 0; m < z; m++)
			{
				if (blockGraphNode.ZPos == null)
				{
					return false;
				}
				blockGraphNode = blockGraphNode.ZPos;
			}
		}
		else if (z < 0)
		{
			for (int n = 0; n < -z; n++)
			{
				if (blockGraphNode.ZNeg == null)
				{
					return false;
				}
				blockGraphNode = blockGraphNode.ZNeg;
			}
		}
		return true;
	}

	private void CleanAndPlaceNewMesh(CuboidResult cuboid)
	{
		List<BlockGraphNode> nodes = cuboid.GetNodes();
		List<BlockGraphNode> list = new List<BlockGraphNode>();
		List<MeshReference> list2 = new List<MeshReference>();
		foreach (BlockGraphNode item in nodes)
		{
			foreach (MeshReference meshReference in item.MeshReferences)
			{
				if (!list2.Contains(meshReference))
				{
					list2.Add(meshReference);
				}
			}
		}
		foreach (MeshReference item2 in list2)
		{
			foreach (BlockGraphNode item3 in item2.NodesUsingThisMesh)
			{
				if (!list.Contains(item3))
				{
					list.Add(item3);
				}
			}
		}
		foreach (BlockGraphNode item4 in nodes)
		{
			list.Remove(item4);
		}
		foreach (BlockGraphNode item5 in list)
		{
			foreach (MeshReference meshReference2 in item5.MeshReferences)
			{
				list2.Remove(meshReference2);
			}
		}
		foreach (MeshReference item6 in list2)
		{
			UnityEngine.Object.Destroy(item6.MeshInstance);
		}
		list2.Clear();
		List<MeshReference> meshes = new List<MeshReference>();
		GetMeshesThatFitsCuboid(cuboid, default, ref meshes);
	}

	private void GetLargestMeshThatFits(Vector3Int size, ZXSideToggle sideStatues, ref MeshReference mesh)
	{
		List<MeshScore> list = new List<MeshScore>();
		for (int i = 0; i < meshCollection.Length; i++)
		{
			Vector3 size2 = meshCollection[i].Size;
			Vector3 vector = new Vector3(size2.z, size2.y, size2.x);
			if (size2.x <= (float)size.x && size2.y <= (float)size.y && size2.z <= (float)size.z)
			{
				list.Add(new MeshScore
				{
					mesh = meshCollection[i],
					score = Mathf.Abs(size2.x - (float)size.x) + Mathf.Abs(size2.y - (float)size.y) + Mathf.Abs(size2.z - (float)size.z)
				});
			}
			if (vector.x <= (float)size.x && vector.y <= (float)size.y && vector.z <= (float)size.z)
			{
				list.Add(new MeshScore
				{
					mesh = meshCollection[i],
					score = Mathf.Abs(vector.x - (float)size.x) + Mathf.Abs(vector.y - (float)size.y) + Mathf.Abs(vector.z - (float)size.z),
					rotated = true
				});
			}
		}
		list.Sort((MeshScore x, MeshScore y) => (x != y) ? ((int)Mathf.Sign(x.score - y.score)) : 0);
		if (list.Count == 0)
		{
			Debug.Log("Debug");
		}
		mesh.MeshDescriptor = list[0].mesh;
		mesh.MeshInstance = UnityEngine.Object.Instantiate(mesh.MeshDescriptor.gameObject);
		if (list[0].rotated)
		{
			mesh.MeshInstance.transform.Rotate(0f, 90f, 0f);
			mesh.MeshInstanceDimensions = new Vector3Int((int)mesh.MeshDescriptor.Size.z, (int)mesh.MeshDescriptor.Size.y, (int)mesh.MeshDescriptor.Size.x);
		}
		else
		{
			mesh.MeshInstanceDimensions = new Vector3Int((int)mesh.MeshDescriptor.Size.x, (int)mesh.MeshDescriptor.Size.y, (int)mesh.MeshDescriptor.Size.z);
		}
	}

	private void GetMeshesThatFitsCuboid(CuboidResult cuboid, ZXSideToggle sideStatues, ref List<MeshReference> meshes)
	{
		Vector3Int size = cuboid.GetDimensions();
		Vector3 vector = cuboid.Min();
		BlockGraphNode[][][] nodesArray = cuboid.GetNodesArray();
		bool[] filledArray = new bool[size.x * size.y * size.z];
		for (int i = 0; i < size.y; i++)
		{
			for (int j = 0; j < size.x; j++)
			{
				for (int k = 0; k < size.z; k++)
				{
					if (IsFilled(j, i, k))
					{
						continue;
					}
					Vector3Int size2 = new Vector3Int(size.x - j, size.y - i, size.z - k);
					MeshReference mesh = new MeshReference();
					GetLargestMeshThatFits(size2, sideStatues, ref mesh);
					Vector3Int meshInstanceDimensions = mesh.MeshInstanceDimensions;
					List<BlockGraphNode> list = new List<BlockGraphNode>();
					for (int l = 0; l < meshInstanceDimensions.x; l++)
					{
						for (int m = 0; m < meshInstanceDimensions.y; m++)
						{
							for (int n = 0; n < meshInstanceDimensions.z; n++)
							{
								FillGrid(j + l, i + m, k + n);
								list.Add(nodesArray[j + l][i + m][k + n]);
							}
						}
					}
					mesh.NodesUsingThisMesh.AddRange(list);
					foreach (BlockGraphNode item in list)
					{
						item.MeshReferences.Add(mesh);
					}
					Vector3 blockSize = _placerConfiguration.BlockSize;
					Vector3 vector2 = vector + new Vector3((float)j * blockSize.x, (float)i * blockSize.y, (float)k * blockSize.z);
					Vector3 vector3 = vector2 + new Vector3((float)meshInstanceDimensions.x * blockSize.x, (float)meshInstanceDimensions.y * blockSize.y, (float)meshInstanceDimensions.z * blockSize.z);
					GameObject meshInstance = mesh.MeshInstance;
					float x = (vector3.x - vector2.x) / 2f + vector2.x;
					float y = vector2.y;
					float z = (vector3.z - vector2.z) / 2f + vector2.z;
					meshInstance.transform.position = new Vector3(x, y, z);
					meshes.Add(mesh);
				}
			}
		}
		void FillGrid(int num, int num2, int num3)
		{
			filledArray[num + num2 * size.x + num3 * size.x * size.y] = true;
		}
		bool IsFilled(int num, int num2, int num3)
		{
			return filledArray[num + num2 * size.x + num3 * size.x * size.y];
		}
	}
}
