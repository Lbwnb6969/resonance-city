using Code;
using UnityEngine;

public class WaterDisplacementMesh : MonoBehaviour
{
	private void OnEnable()
	{
		Water.AddDisplacementMesh(GetComponent<MeshRenderer>());
	}

	private void OnDisable()
	{
		Water.RemoveDisplacementMesh(GetComponent<MeshRenderer>());
	}
}
