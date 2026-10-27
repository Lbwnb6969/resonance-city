using System;
using Drawing;
using UnityEngine;

public class LegionTopology : MonoBehaviour
{
	private static LegionTopology inst;

	public MeshFilter plane;

	public float elevationScale;

	public float modSize = 0.5f;

	public float sampleScale = 0.1f;

	public float pointSize = 0.25f;

	public Vector3 minCorner;

	public Vector3 maxCorner;

	public int resolution;

	public int res = 2048;

	public Vector3 drawOffset;

	public float seaStartDistance = 5f;

	public float seaFalloff = 0.1f;

	public float zoom = 1f;

	public Vector3[] spawnPoints;

	private Color[] tolopologyColors = new Color[2]
	{
		Color.blue,
		Color.red
	};

	public Color low = new Color(0.4f, 0.8f, 0.4f);

	public Color high = new Color(0.8f, 0.4f, 0.4f);

	public static LegionTopology Inst
	{
		get
		{
			if (inst == null)
			{
				inst = UnityEngine.Object.FindAnyObjectByType<LegionTopology>();
			}
			return inst;
		}
	}

	public void Start()
	{
		GenerateSpawnPoints();
		CreateBackground();
	}

	public void CreateBackground()
	{
		Material sharedMaterial = plane.GetComponent<MeshRenderer>().sharedMaterial;
		Color[] array = new Color[res * res];
		for (int i = 0; i < res; i++)
		{
			for (int j = 0; j < res; j++)
			{
				float t = (float)i / (float)res;
				float t2 = (float)j / (float)res;
				float x = Mathf.Lerp(plane.mesh.bounds.min.x * plane.transform.localScale.x, plane.mesh.bounds.max.x * plane.transform.localScale.x, t);
				float z = Mathf.Lerp(plane.mesh.bounds.min.z * plane.transform.localScale.z, plane.mesh.bounds.max.z * plane.transform.localScale.z, t2);
				Vector3 pos = new Vector3(x, 0f, z);
				float num = ElevationAt(pos);
				array[i + j * res] = GetColor(num);
				if (num % modSize > sampleScale)
				{
					array[i + j * res] = Color.black;
				}
			}
		}
		Texture2D texture2D = new Texture2D(res, res, TextureFormat.RGBA32, mipChain: false);
		texture2D.name = "LegionTopologyMap";
		texture2D.filterMode = FilterMode.Point;
		texture2D.wrapMode = TextureWrapMode.Clamp;
		texture2D.SetPixels(array);
		texture2D.Apply();
		sharedMaterial.mainTexture = texture2D;
	}

	private void GenerateSpawnPoints()
	{
		int num = 8;
		float maxDistanceDelta = 0.5f;
		spawnPoints = new Vector3[num];
		for (int i = 0; i < num; i++)
		{
			Vector3 vector = new Vector3(Mathf.Cos((float)i * MathF.PI * 2f / (float)num) * 20f, 0f, Mathf.Sin((float)i * MathF.PI * 2f / (float)num) * 20f);
			while (true)
			{
				if ((double)ElevationAt(vector) >= 0.1)
				{
					spawnPoints[i] = vector;
					break;
				}
				vector = Vector3.MoveTowards(vector, Vector3.zero, maxDistanceDelta);
				if ((double)Vector3.Distance(vector, Vector3.zero) < 0.5)
				{
					spawnPoints[i] = Vector3.zero;
					break;
				}
			}
		}
	}

	public float ElevationAt(Vector3 pos)
	{
		Vector3 vector = pos + new Vector3(1000f, 0f, 1000f);
		return Mathf.PerlinNoise(vector.x * elevationScale, vector.z * elevationScale) - Mathf.Max(0f, pos.magnitude * seaFalloff - seaStartDistance);
	}

	public Color GetColor(float elevation)
	{
		if (elevation < 0.1f)
		{
			return new Color(0.3f, 0.6f, 1f);
		}
		return Color.LerpUnclamped(low, high, elevation);
	}

	public void Draw()
	{
		for (int i = 0; i < spawnPoints.Length; i++)
		{
			Drawing.Draw.ingame.SolidCircle(spawnPoints[i], Vector3.up, 0.5f, Color.green);
		}
	}
}
