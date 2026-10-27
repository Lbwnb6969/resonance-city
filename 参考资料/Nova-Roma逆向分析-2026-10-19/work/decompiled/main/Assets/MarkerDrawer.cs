using UnityEngine;
using UnityEngine.Rendering;

namespace Assets;

public class MarkerDrawer : MonoBehaviour
{
	public float markerBounceSpeed = 8f;

	public float markerBounceMagnitude;

	public Mesh personMarkerMesh;

	public Material personMarkerMaterial;

	private Matrix4x4[] points = new Matrix4x4[1023];

	private Vector3[] pointVec = new Vector3[1023];

	private int count;

	public Vector3 scale;

	private float totalTime;

	public static MarkerDrawer inst;

	private void Awake()
	{
		inst = this;
	}

	public void AddPoint(Vector3 position)
	{
		pointVec[count++] = position;
	}

	public void Clear()
	{
		count = 0;
	}

	public void Draw(float distDivder = 50f)
	{
		totalTime += Time.deltaTime;
		float num = Mathf.Max(0.75f, Cam.inst.dist / distDivder);
		Vector3 vector = new Vector3(num * scale.x, num * scale.y, num * scale.z);
		for (int i = 0; i < count; i++)
		{
			Mathff.SetTS(ref points[i], pointVec[i], vector);
		}
		Graphics.DrawMeshInstanced(personMarkerMesh, 0, personMarkerMaterial, points, count, null, ShadowCastingMode.Off);
	}

	public void DrawWithMasking(CommandBuffer buffer, Material mask, float distDivider = 50f)
	{
		totalTime += Time.deltaTime;
		float num = Mathf.Max(0.75f, Cam.inst.dist / distDivider);
		Vector3 vector = new Vector3(num * scale.x, num * scale.y, num * scale.z);
		for (int i = 0; i < count; i++)
		{
			Mathff.SetTS(ref points[i], pointVec[i], vector);
		}
		buffer.DrawMeshInstanced(personMarkerMesh, 0, mask, 1, points, count);
	}
}
