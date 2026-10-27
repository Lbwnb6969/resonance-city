using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ArcherRangeDisplay : IDisposable
{
	private readonly GameObject rangeObject;

	private readonly MeshFilter meshFilter;

	private readonly MeshRenderer meshRenderer;

	private readonly Material materialInstance;

	private readonly int radialSegments;

	private readonly float ringStep;

	private readonly float launchAngleRad;

	private readonly float gravity;

	private readonly float skirtOffset = 0.05f;

	private float launchSpeed;

	private float maxRange;

	private float startHeight;

	private Vector3 originPosition;

	public GameObject GameObject => rangeObject;

	public float MaxRange => maxRange;

	public float LaunchSpeed => launchSpeed;

	public ArcherRangeDisplay(int radialSegments = 48, Material templateMaterial = null, float ringStep = 1f)
	{
		this.radialSegments = Mathf.Max(8, radialSegments);
		this.ringStep = Mathf.Max(0.1f, ringStep);
		launchAngleRad = MathF.PI / 4f;
		gravity = Mathf.Abs(Physics.gravity.y);
		rangeObject = new GameObject("Archer Range Display");
		meshFilter = rangeObject.AddComponent<MeshFilter>();
		meshRenderer = rangeObject.AddComponent<MeshRenderer>();
		Material material = ((templateMaterial != null) ? templateMaterial : Resources.Load<Material>("RangeDisplay"));
		materialInstance = ((material != null) ? UnityEngine.Object.Instantiate(material) : new Material(Shader.Find("Standard")));
		meshRenderer.material = materialInstance;
		meshRenderer.shadowCastingMode = ShadowCastingMode.Off;
		meshRenderer.receiveShadows = false;
		rangeObject.SetActive(value: false);
	}

	public void SetVisible(bool visible)
	{
		if (rangeObject != null)
		{
			rangeObject.SetActive(visible);
		}
	}

	public void SetOrigin(Vector3 worldPos)
	{
		originPosition = worldPos;
		if (rangeObject != null)
		{
			rangeObject.transform.position = worldPos;
		}
	}

	public void Rebuild(float launchSpeed, float startHeight = 0f)
	{
		this.startHeight = startHeight;
		this.launchSpeed = Mathf.Max(0.01f, launchSpeed);
		maxRange = CalcMaxRangeForSpeed(this.launchSpeed, startHeight);
		Mesh sharedMesh = BuildMesh();
		if (meshFilter.sharedMesh != null)
		{
			UnityEngine.Object.Destroy(meshFilter.sharedMesh);
		}
		meshFilter.sharedMesh = sharedMesh;
	}

	public bool CanHit(Vector3 origin, Vector3 target, float heightTolerance = 0.5f)
	{
		Vector3 vector = target - origin;
		float num = Mathf.Sqrt(vector.x * vector.x + vector.z * vector.z);
		float num2 = HeightAtRange(num);
		Vector3 vector2 = ((num > 0.0001f) ? new Vector3(vector.x / num, 0f, vector.z / num) : Vector3.forward);
		float interpolatedHeight = TerrainGen.inst.GetInterpolatedHeight(origin + vector2 * num);
		if (origin.y + num2 <= interpolatedHeight + skirtOffset)
		{
			return false;
		}
		return vector.y <= num2 + heightTolerance;
	}

	public void Dispose()
	{
		if (rangeObject != null)
		{
			UnityEngine.Object.Destroy(rangeObject);
		}
		if (materialInstance != null)
		{
			UnityEngine.Object.Destroy(materialInstance);
		}
	}

	private float CalcMaxRangeForSpeed(float speed, float startHeight)
	{
		float num = Mathf.Sin(launchAngleRad);
		float num2 = Mathf.Cos(launchAngleRad);
		float num3 = speed * num;
		float num4 = Mathf.Sqrt(num3 * num3 + 2f * gravity * startHeight);
		float num5 = (num3 + num4) / gravity;
		return Mathf.Max(0.01f, speed * num2 * num5);
	}

	private float HeightAtRange(float distance)
	{
		float num = Mathf.Cos(launchAngleRad);
		float num2 = Mathf.Tan(launchAngleRad);
		float num3 = startHeight + distance * num2;
		float num4 = Mathf.Max(launchSpeed, 0.01f);
		return num3 - gravity * distance * distance / (2f * num4 * num4 * num * num);
	}

	private float SlopeAtRange(float distance)
	{
		float num = Mathf.Cos(launchAngleRad);
		float num2 = Mathf.Tan(launchAngleRad);
		float num3 = Mathf.Max(launchSpeed, 0.01f);
		return num2 - gravity * distance / (num3 * num3 * num * num);
	}

	private Mesh BuildMesh()
	{
		int num = radialSegments;
		List<Vector3> list = new List<Vector3>();
		List<Vector3> list2 = new List<Vector3>();
		List<Vector2> list3 = new List<Vector2>();
		bool flag = false;
		int num2 = 0;
		float b = 0f;
		int num3 = 4096;
		while (!flag && num2 < num3)
		{
			float num4 = (float)num2 * ringStep;
			b = num4;
			bool flag2 = true;
			for (int i = 0; i < num; i++)
			{
				float f = (float)i / (float)num * MathF.PI * 2f;
				float num5 = Mathf.Sin(f);
				float num6 = Mathf.Cos(f);
				float num7 = HeightAtRange(num4);
				float y = SlopeAtRange(num4);
				Vector3 p = originPosition + new Vector3(num6 * num4, 0f, num5 * num4);
				float num8 = TerrainGen.inst.GetInterpolatedHeight(p) + skirtOffset;
				bool flag3 = originPosition.y + num7 <= num8;
				flag2 &= flag3;
				_ = list.Count;
				list.Add(new Vector3(num6 * num4, num7, num5 * num4));
				list3.Add(new Vector2((float)i / (float)(num - 1), 0f));
				Vector3 vector = Vector3.Cross(rhs: new Vector3(num6, y, num5), lhs: new Vector3((0f - num5) * num4, 0f, num6 * num4));
				if (vector == Vector3.zero)
				{
					vector = Vector3.up;
				}
				else
				{
					vector.Normalize();
				}
				list2.Add(vector);
			}
			flag = flag2;
			num2++;
		}
		int num9 = num2;
		_ = list.Count;
		Vector3[] vertices = list.ToArray();
		Vector3[] normals = list2.ToArray();
		Vector2[] array = list3.ToArray();
		float num10 = Mathf.Max(ringStep, b);
		for (int j = 0; j < num; j++)
		{
			for (int k = 0; k < num9; k++)
			{
				float num11 = (float)k * ringStep;
				int num12 = k * num + j;
				array[num12] = new Vector2(array[num12].x, Mathf.Clamp01(num11 / num10));
			}
		}
		int[] array2 = new int[(num9 - 1) * num * 6];
		int num13 = 0;
		for (int l = 0; l < num9 - 1; l++)
		{
			int num14 = l * num;
			int num15 = (l + 1) * num;
			for (int m = 0; m < num; m++)
			{
				int num16 = (m + 1) % num;
				array2[num13++] = num14 + m;
				array2[num13++] = num15 + num16;
				array2[num13++] = num15 + m;
				array2[num13++] = num14 + m;
				array2[num13++] = num14 + num16;
				array2[num13++] = num15 + num16;
			}
		}
		Mesh mesh = new Mesh();
		mesh.name = "ArcherRangeMesh";
		mesh.vertices = vertices;
		mesh.normals = normals;
		mesh.uv = array;
		mesh.triangles = array2;
		mesh.RecalculateBounds();
		return mesh;
	}
}
