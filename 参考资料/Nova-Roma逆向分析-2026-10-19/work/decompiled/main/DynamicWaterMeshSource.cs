using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class DynamicWaterMeshSource : MonoBehaviour
{
	[SerializeField]
	private Collider sampleCollider;

	[SerializeField]
	private LayerMask raycastMask;

	[SerializeField]
	private float raycastHeightOffset = 2f;

	[SerializeField]
	private float raycastExtraDistance = 10f;

	[SerializeField]
	private bool alwaysApplyForwardVelocity;

	[SerializeField]
	private float forwardVelocityScale;

	private Vector3 lastPosition;

	private Vector3 linearVelocity;

	private bool hasPreviousFrame;

	private void Reset()
	{
		sampleCollider = GetComponent<Collider>();
		if ((int)raycastMask == 0)
		{
			raycastMask = 1 << gameObject.layer;
		}
	}

	private void Awake()
	{
		if (sampleCollider == null)
		{
			sampleCollider = GetComponent<Collider>();
		}
		if ((int)raycastMask == 0)
		{
			raycastMask = 1 << gameObject.layer;
		}
	}

	private void OnEnable()
	{
		hasPreviousFrame = false;
		CacheTransform();
		RegisterWithDynamicWater();
	}

	private void Start()
	{
		RegisterWithDynamicWater();
	}

	private void OnDisable()
	{
		if (DynamicWater.inst != null)
		{
			DynamicWater.inst.UnregisterMeshSource(this);
		}
	}

	private void RegisterWithDynamicWater()
	{
		if (DynamicWater.inst != null)
		{
			DynamicWater.inst.RegisterMeshSource(this);
		}
	}

	private void CacheTransform()
	{
		lastPosition = transform.position;
		linearVelocity = Vector3.zero;
	}

	public void SyncVelocity(float deltaTime)
	{
		if (deltaTime <= Mathf.Epsilon || !hasPreviousFrame)
		{
			CacheTransform();
			hasPreviousFrame = true;
		}
		else
		{
			Vector3 position = transform.position;
			linearVelocity = (position - lastPosition) / deltaTime;
			lastPosition = position;
		}
	}

	public void CollectSamples(List<DynamicWater.MeshRaycastSample> samples, float cellSize, int meshWidth, int meshHeight)
	{
		if (sampleCollider == null)
		{
			return;
		}
		Bounds bounds = sampleCollider.bounds;
		if (bounds.size.sqrMagnitude <= Mathf.Epsilon)
		{
			return;
		}
		float x = bounds.min.x;
		float x2 = bounds.max.x;
		float z = bounds.min.z;
		float z2 = bounds.max.z;
		int num = Mathf.Clamp(Mathf.FloorToInt(x / cellSize), 0, meshWidth - 1);
		int num2 = Mathf.Clamp(Mathf.CeilToInt(x2 / cellSize), 0, meshWidth - 1);
		int num3 = Mathf.Clamp(Mathf.FloorToInt(z / cellSize), 0, meshHeight - 1);
		int num4 = Mathf.Clamp(Mathf.CeilToInt(z2 / cellSize), 0, meshHeight - 1);
		float y = bounds.max.y + raycastHeightOffset;
		float maxDistance = Mathf.Max(bounds.size.y + raycastExtraDistance + raycastHeightOffset, 1f);
		Vector3 vector = Vector3.zero;
		if (alwaysApplyForwardVelocity && forwardVelocityScale != 0f)
		{
			vector = transform.forward * forwardVelocityScale;
		}
		Vector3 vector2 = linearVelocity + vector;
		Vector2 velocity = new Vector2(vector2.x, vector2.z);
		int value = raycastMask.value;
		for (int i = num3; i <= num4; i++)
		{
			float z3 = (float)i * cellSize;
			for (int j = num; j <= num2; j++)
			{
				float x3 = (float)j * cellSize;
				int cellIndex = j + i * meshWidth;
				samples.Add(new DynamicWater.MeshRaycastSample
				{
					cellIndex = cellIndex,
					origin = new Vector3(x3, y, z3),
					maxDistance = maxDistance,
					layerMask = value,
					velocity = velocity
				});
			}
		}
	}
}
