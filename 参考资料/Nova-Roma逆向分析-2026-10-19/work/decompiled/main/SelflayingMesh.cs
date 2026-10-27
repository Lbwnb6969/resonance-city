using UnityEngine;

public class SelflayingMesh : MonoBehaviour
{
	public void Lay()
	{
		Vector3 position = transform.position;
		position.y = TerrainGen.inst.GetInterpolatedHeight(position);
		transform.position = position;
	}
}
