using UnityEngine;

public class SelflayingMeshGroup : MonoBehaviour
{
	public SelflayingMesh[] meshes;

	public void Lay()
	{
		SelflayingMesh[] array = meshes;
		for (int i = 0; i < array.Length; i++)
		{
			array[i].Lay();
		}
	}
}
