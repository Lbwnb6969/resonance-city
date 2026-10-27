using UnityEngine;
using UnityEngine.Rendering;

public class RenderInstanceBehaviour : MonoBehaviour
{
	public Mesh mesh;

	public Material material;

	private RenderInstance renderInstance;

	private void Awake()
	{
		bool castShadows = true;
		if (mesh == null)
		{
			mesh = GetComponent<MeshFilter>().sharedMesh;
		}
		if (material == null)
		{
			material = GetComponent<MeshRenderer>().sharedMaterial;
			GetComponent<MeshRenderer>().enabled = false;
			if (GetComponent<MeshRenderer>().shadowCastingMode == ShadowCastingMode.Off)
			{
				castShadows = false;
			}
		}
		renderInstance = new RenderInstance(mesh, material);
		renderInstance.castShadows = castShadows;
	}

	private void OnEnable()
	{
		renderInstance.Visible = true;
	}

	private void OnDisable()
	{
		renderInstance.Visible = false;
	}

	public void OnUpdateTransform()
	{
		MatchUnityTransform();
	}

	public void MatchUnityTransform()
	{
		renderInstance.UpdateMatrix(transform.localToWorldMatrix);
	}

	public void UpdateMatrix(Matrix4x4 matrix)
	{
		renderInstance.UpdateMatrix(matrix);
	}

	public void UpdateTS(Vector3 pos, Vector3 scale)
	{
		renderInstance.UpdateTS(pos, scale);
	}

	public void UpdateTRS(Vector3 pos, Quaternion rot, Vector3 scale)
	{
		renderInstance.UpdateTRS(pos, rot, scale);
	}
}
