using System.Collections.Generic;
using UnityEngine;

public class Stars : MonoBehaviour
{
	private MeshFilter meshFilter;

	private MeshRenderer meshRenderer;

	private Mesh mesh;

	public int starCount = 1000;

	public float starSizeMax = 0.1f;

	public float starSizeMin = 0.05f;

	public float starDistance = 100f;

	public float starSizeMultiplier = 1f;

	public GameObject FollowObject;

	public GameObject RotationObject;

	public static Stars inst;

	public float StarSize
	{
		get
		{
			return starSizeMultiplier;
		}
		set
		{
			starSizeMultiplier = Mathf.Clamp01(value);
			BuildStarMesh();
		}
	}

	private void Start()
	{
		inst = this;
		meshFilter = GetComponent<MeshFilter>();
		meshRenderer = GetComponent<MeshRenderer>();
		FollowObject = GameObject.Find("Main Camera");
		RotationObject = GameObject.Find("Light Container/Sun Light");
		mesh = new Mesh();
		BuildStarMesh();
	}

	public void BuildStarMesh()
	{
		List<Vector3> list = new List<Vector3>();
		List<int> list2 = new List<int>();
		List<Vector3> list3 = new List<Vector3>();
		int num = 0;
		for (int i = 0; i < starCount; i++)
		{
			Quaternion quaternion = Quaternion.Euler(new Vector3(360f * SRand.value, 360f * SRand.value, 360f * SRand.value));
			float num2 = starSizeMultiplier * Mathf.Lerp(starSizeMin, starSizeMax, SRand.value);
			list.Add(quaternion * Vector3.right * num2 + quaternion * Vector3.back * starDistance);
			list3.Add(quaternion * Vector3.forward);
			list2.Add(num++);
			list.Add(quaternion * Vector3.up * num2 + quaternion * Vector3.back * starDistance);
			list3.Add(quaternion * Vector3.forward);
			list2.Add(num++);
			list.Add(quaternion * Vector3.left * num2 + quaternion * Vector3.back * starDistance);
			list3.Add(quaternion * Vector3.forward);
			list2.Add(num++);
			list.Add(quaternion * Vector3.down * num2 + quaternion * Vector3.back * starDistance);
			list3.Add(quaternion * Vector3.forward);
			list2.Add(num++);
		}
		mesh.SetVertices(list);
		mesh.SetIndices(list2.ToArray(), MeshTopology.Quads, 0);
		mesh.SetNormals(list3);
		mesh.RecalculateTangents();
		mesh.RecalculateBounds();
		meshFilter.sharedMesh = mesh;
	}

	public void OnValidate()
	{
		if (mesh != null)
		{
			BuildStarMesh();
		}
	}

	private void LateUpdate()
	{
		transform.position = FollowObject.transform.position;
		transform.rotation = RotationObject.transform.rotation;
	}
}
