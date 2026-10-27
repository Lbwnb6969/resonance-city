using System;
using Drawing;
using Unity.Mathematics;
using UnityEngine;

[ExecuteInEditMode]
public class AttractionOvalSeatGenerator : MonoBehaviourGizmos
{
	[Serializable]
	public struct OvalEntry
	{
		public float sizeX;

		public float sizeZ;

		public int resolution;

		public Vector3 offset;

		public float angleOffset;

		public Vector2[] range;
	}

	public bool doDebugDraw;

	private ArrayExt<Transform> points = new ArrayExt<Transform>(128);

	private int pCount;

	private ArrayExtRef<Transform> pool = new ArrayExtRef<Transform>(128);

	private Unity.Mathematics.Random rand;

	[SerializeField]
	private Transform ovalContainer;

	[SerializeField]
	private Transform customContainer;

	[SerializeField]
	public OvalEntry[] entries;

	public bool doRandomVariance = true;

	private void OnEnable()
	{
		if (ovalContainer == null)
		{
			GameObject gameObject = new GameObject("Oval Container");
			gameObject.transform.SetParent(transform, worldPositionStays: false);
			ovalContainer = gameObject.transform;
		}
		if (customContainer == null)
		{
			GameObject gameObject2 = new GameObject("Custom Container");
			gameObject2.transform.SetParent(transform, worldPositionStays: false);
			customContainer = gameObject2.transform;
		}
		rand.InitState(12345u);
	}

	private void Update()
	{
		if (!Application.isEditor || Application.isPlaying)
		{
			return;
		}
		Vector3 position = base.transform.position;
		points.ClearFast();
		pCount = 0;
		for (int i = 0; i < entries.Length; i++)
		{
			OvalEntry ovalEntry = entries[i];
			for (int j = 0; j < ovalEntry.resolution; j++)
			{
				float num = (float)j / (float)ovalEntry.resolution;
				int num2 = 0;
				while (true)
				{
					if (num2 < ovalEntry.range.Length)
					{
						Vector2 vector = ovalEntry.range[num2];
						if (num >= vector.x && num <= vector.y)
						{
							break;
						}
						num2++;
						continue;
					}
					float f = num * 2f * MathF.PI + ovalEntry.angleOffset * (MathF.PI / 180f);
					float num3 = (0f - ovalEntry.sizeX) * Mathf.Sin(f);
					float num4 = ovalEntry.sizeZ * Mathf.Cos(f);
					Transform transform = GetTransform();
					transform.localPosition = new Vector3(num3 + ovalEntry.offset.x, ovalEntry.offset.y, num4 + ovalEntry.offset.z);
					transform.rotation = Quaternion.LookRotation(ovalEntry.offset + position - transform.position);
					if (doRandomVariance)
					{
						transform.localPosition += new Vector3(rand.NextFloat(-0.05f, 0.05f), 0f, rand.NextFloat(-0.05f, 0.05f));
						transform.Rotate(Vector3.up, rand.NextFloat(-5f, 5f));
					}
					points.Add(transform);
					break;
				}
			}
		}
		for (int k = 0; k < customContainer.childCount; k++)
		{
			points.Add(customContainer.GetChild(k));
		}
		for (int num5 = pool.Count - 1; num5 >= pCount; num5--)
		{
			UnityEngine.Object.DestroyImmediate(pool.PopLast().gameObject);
		}
	}

	private Transform GetTransform()
	{
		if (pCount >= pool.Count)
		{
			GameObject gameObject = new GameObject();
			gameObject.transform.parent = ovalContainer;
			pool.Add(gameObject.transform);
		}
		return pool.data[pCount++];
	}

	public override void DrawGizmos()
	{
		if (doDebugDraw)
		{
			for (int i = 0; i < points.Count; i++)
			{
				Draw.WireSphere(points.data[i].position, 0.05f);
			}
			for (int j = 0; j < entries.Length; j++)
			{
				OvalEntry ovalEntry = entries[j];
				DebugEx.DrawEllipse(ovalEntry.offset + transform.position, ovalEntry.sizeX, ovalEntry.sizeZ, Color.white, ovalEntry.resolution);
			}
		}
	}

	public void UploadPositionsToBuilding()
	{
		Building componentInParent = GetComponentInParent<Building>();
		if (!(componentInParent == null))
		{
			componentInParent.attractionPositions = new Transform[points.Count];
			Array.Copy(points.data, componentInParent.attractionPositions, points.Count);
		}
	}
}
