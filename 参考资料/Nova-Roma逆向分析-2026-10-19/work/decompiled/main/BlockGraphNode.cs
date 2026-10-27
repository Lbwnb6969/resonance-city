using System.Collections.Generic;
using UnityEngine;

public class BlockGraphNode : MonoBehaviour
{
	public BlockGraphNode YPos;

	public BlockGraphNode YNeg;

	public BlockGraphNode XPos;

	public BlockGraphNode XNeg;

	public BlockGraphNode ZPos;

	public BlockGraphNode ZNeg;

	public List<MeshReference> MeshReferences = new List<MeshReference>();

	public float X => transform.position.x;

	public float Y => transform.position.y;

	public float Z => transform.position.z;
}
