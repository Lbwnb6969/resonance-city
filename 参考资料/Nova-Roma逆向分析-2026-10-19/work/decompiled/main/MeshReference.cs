using System.Collections.Generic;
using UnityEngine;

public class MeshReference
{
	public List<BlockGraphNode> NodesUsingThisMesh = new List<BlockGraphNode>();

	public MeshDescriptor MeshDescriptor;

	public GameObject MeshInstance;

	public Vector3Int MeshInstanceDimensions;
}
