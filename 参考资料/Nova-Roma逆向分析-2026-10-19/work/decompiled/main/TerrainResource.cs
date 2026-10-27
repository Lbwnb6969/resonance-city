using System;
using Assets.Code;
using UnityEngine;
using cakeslice;

public class TerrainResource : MonoBehaviour
{
	public delegate void OnResourceExhausted(Cell c);

	[Serializable]
	public struct MeshSettings
	{
		public float yScale;

		public int resourceAmt;
	}

	[Serializable]
	public class TerrainResourceSaveData : SaveClass<TerrainResource, TerrainResourceSaveData>
	{
		public int x;

		public int z;

		public int sizeX;

		public int sizeZ;

		public int resourceID;

		public int maxResources;

		public int currentHarvestedResources;

		public int rvMeshIdx;

		public SerializableVector3 rvPos;

		public SerializableQuaternion rvRot;

		public SerializableVector3 rvScale;

		public override TerrainResourceSaveData Pack(TerrainResource obj)
		{
			x = (int)obj.transform.position.x;
			z = (int)obj.transform.position.z;
			sizeX = obj.sizeX;
			sizeZ = obj.sizeZ;
			resourceID = obj.resourceID;
			maxResources = obj.maxResources;
			currentHarvestedResources = obj.currentHarvestedResources;
			rvMeshIdx = obj.rvMeshIdx;
			rvPos = obj.rvPos;
			rvRot = obj.rvRot;
			rvScale = obj.rvScale;
			return this;
		}

		public override TerrainResource Unpack(TerrainResource obj)
		{
			obj.didInit = true;
			obj.resourceID = resourceID;
			obj.maxResources = maxResources;
			obj.currentHarvestedResources = currentHarvestedResources;
			obj.x = x;
			obj.z = z;
			obj.position = new Vector3(x, 0f, z);
			obj.transform.position = obj.position;
			obj.sizeX = sizeX;
			obj.sizeZ = sizeZ;
			obj.rvMeshIdx = rvMeshIdx;
			obj.meshFilter.transform.position = (obj.rvPos = rvPos);
			obj.meshFilter.transform.rotation = (obj.rvRot = rvRot);
			obj.meshFilter.transform.localScale = (obj.rvScale = rvScale);
			obj.resourceTooltip.targetPosition = rvPos;
			obj.resourceTooltip.targetOffset = new Vector3(0f, rvScale.y * 0.75f, 0f);
			obj.meshFilter.mesh = obj.meshOptions[rvMeshIdx];
			obj.outline = new Outline(obj.meshOptions[rvMeshIdx])
			{
				color = 1,
				meshMtx = Matrix4x4.TRS(rvPos, rvRot, rvScale)
			};
			for (int i = 0; i < obj.sizeX; i++)
			{
				for (int j = 0; j < obj.sizeZ; j++)
				{
					World.inst.GetCellData(x + i, z + j).terrainResource = obj;
				}
			}
			Add(obj);
			return obj;
		}
	}

	public static OnResourceExhausted onResourceExhausted;

	public static ArrayExt<TerrainResource> terrainResources = new ArrayExt<TerrainResource>(32);

	private static ArrayExt<TerrainResource> deferredDestroy = new ArrayExt<TerrainResource>(16);

	private static GameObject terrainResourceContainer;

	public ResourceTooltipUI resourceTooltip;

	private bool isForcedTooltipVisibility;

	public static Cell[] scratch8Cells = new Cell[8];

	[HideInInspector]
	public int x;

	[HideInInspector]
	public int z;

	[HideInInspector]
	public int sizeX = 1;

	[HideInInspector]
	public int sizeZ = 1;

	[HideInInspector]
	public Vector3 position;

	[Header("Resource Settings")]
	[FreeResourceType]
	public int resourceID;

	public bool doXZRotation = true;

	public bool doYRotation = true;

	[HideInInspector]
	public int maxResources = 1000;

	[NonSerialized]
	public int currentHarvestedResources;

	public Outline outline;

	private int rvMeshIdx;

	private Vector3 rvPos;

	private Quaternion rvRot;

	private Vector3 rvScale;

	private Vector3 dirOffset;

	[Header("Mesh References")]
	public MeshFilter meshFilter;

	public MeshCollider meshCollider;

	[Header("Mesh Settings")]
	public Mesh[] meshOptions;

	public MeshSettings[] meshModifiers;

	public Vector2 XZMinMax = new Vector2(-0.2f, 0.2f);

	public float AreaYSizeModifier = 0.5f;

	private static int sMeshModifierIdx = 0;

	private bool didInit;

	public static void Add(TerrainResource rt)
	{
		if (!terrainResources.Contains(rt))
		{
			terrainResources.Add(rt);
		}
	}

	public static void Remove(TerrainResource rt)
	{
		rt.SetTooltipVisibility(isVisible: false, force: true);
		terrainResources.RemoveSwap(rt);
		UnityEngine.Object.DestroyImmediate(rt.gameObject);
	}

	public static void Reset()
	{
		for (int num = terrainResources.Count - 1; num >= 0; num--)
		{
			UnityEngine.Object.DestroyImmediate(terrainResources.data[num].gameObject);
		}
		terrainResources.ClearFast();
		if (terrainResourceContainer != null)
		{
			for (int num2 = terrainResourceContainer.transform.childCount - 1; num2 >= 0; num2--)
			{
				UnityEngine.Object.DestroyImmediate(terrainResourceContainer.transform.GetChild(num2).gameObject);
			}
		}
	}

	public static TerrainResource GetTracker(int x, int z)
	{
		return World.inst.GetCellData(x, z).terrainResource;
	}

	public static TerrainResource GetTracker(Vector3 targetPos)
	{
		return GetTracker((int)targetPos.x, (int)targetPos.z);
	}

	public static void ShiftMeshes()
	{
		for (int i = 0; i < terrainResources.Count; i++)
		{
			TerrainResource terrainResource = terrainResources.data[i];
			if (terrainResource.sizeX > 2 && terrainResource.sizeZ > 2)
			{
				continue;
			}
			World.inst.GetNeighborCellsExtended(World.inst.GetCellData((int)terrainResource.rvPos.x, (int)terrainResource.rvPos.z), ref scratch8Cells);
			Vector3 zero = Vector3.zero;
			int num = 0;
			for (int j = 0; j < scratch8Cells.Length; j++)
			{
				Cell cell = scratch8Cells[j];
				if (cell.Type == TerrainType.Obstruction || cell.HasTerrainResourceType(terrainResource.resourceID))
				{
					zero += cell.Center2D - terrainResource.rvPos;
					num++;
				}
			}
			if (num > 0)
			{
				zero /= (float)num;
			}
			terrainResource.rvPos.x += zero.x * 0.2f;
			terrainResource.rvPos.z += zero.z * 0.2f;
			Quaternion b = Quaternion.LookRotation(zero, Vector3.up);
			terrainResource.rvRot = Quaternion.Lerp(terrainResource.rvRot, b, 0.2f);
			terrainResource.meshFilter.transform.rotation = terrainResource.rvRot;
			terrainResource.meshFilter.transform.position = terrainResource.rvPos;
			terrainResource.outline.meshMtx = Matrix4x4.TRS(terrainResource.rvPos, terrainResource.rvRot, terrainResource.rvScale);
		}
	}

	public static void ProcessDeferredDestroy()
	{
		for (int i = 0; i < deferredDestroy.Count; i++)
		{
			UnityEngine.Object.DestroyImmediate(deferredDestroy.data[i].gameObject);
		}
		deferredDestroy.ClearFast();
	}

	private static void SetLowestTerrainHeight(Transform t)
	{
		float num = float.MaxValue;
		Bounds localBounds = t.GetComponent<MeshRenderer>().localBounds;
		Vector3[] array = new Vector3[8]
		{
			localBounds.center + new Vector3(0f - localBounds.size.x, 0f - localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
			localBounds.center + new Vector3(localBounds.size.x, 0f - localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
			localBounds.center + new Vector3(localBounds.size.x, 0f - localBounds.size.y, localBounds.size.z) * 0.5f,
			localBounds.center + new Vector3(0f - localBounds.size.x, 0f - localBounds.size.y, localBounds.size.z) * 0.5f,
			localBounds.center + new Vector3(0f - localBounds.size.x, localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
			localBounds.center + new Vector3(localBounds.size.x, localBounds.size.y, 0f - localBounds.size.z) * 0.5f,
			localBounds.center + new Vector3(localBounds.size.x, localBounds.size.y, localBounds.size.z) * 0.5f,
			localBounds.center + new Vector3(0f - localBounds.size.x, localBounds.size.y, localBounds.size.z) * 0.5f
		};
		for (int i = 0; i < array.Length; i++)
		{
			array[i] = t.TransformPoint(array[i] * 0.8f);
			float groundHeight = TerrainGen.inst.GetGroundHeight(array[i].x, array[i].z);
			if (groundHeight < num)
			{
				num = groundHeight;
			}
		}
		Vector3 vector = t.position;
		vector.y = num;
		t.position = vector;
	}

	public static TerrainResource GetClosestTerrainResource(int type, Building b)
	{
		Cell[] array = new Cell[4];
		World.inst.GetNeighborCells(b.GetCell(), ref array);
		for (int i = 0; i < array.Length; i++)
		{
			TerrainResource terrainResource = array[i].terrainResource;
			if (terrainResource != null && terrainResource.resourceID == type)
			{
				Vector3 vector = terrainResource.transform.position;
				vector.y = 0f;
				Vector3 vector2 = b.Center();
				vector2.y = 0f;
				Vector3 lhs = vector - vector2;
				float num = 0f;
				if (b.uniqueNameHash == World.ironMineHash)
				{
					num = Vector3.Dot(lhs, b.GetOffset().forward);
				}
				else if (b.uniqueNameHash == World.quarryHash || b.uniqueNameHash == World.marbleQuarryHash)
				{
					num = Vector3.Dot(lhs, b.GetOffset().right);
				}
				if (num > 0f)
				{
					return terrainResource;
				}
			}
		}
		return null;
	}

	public int GetRemainingResources()
	{
		return maxResources - currentHarvestedResources;
	}

	private void Awake()
	{
		if (terrainResourceContainer == null)
		{
			terrainResourceContainer = new GameObject("Terrain Resources");
		}
		if (resourceTooltip == null)
		{
			resourceTooltip = UnityEngine.Object.Instantiate(World.inst.resourceTooltipPrefab, World.inst.resourceTooltipContainer.transform).GetComponent<ResourceTooltipUI>();
		}
		resourceTooltip.doScaleToCamDist = true;
		FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[resourceID];
		if (resourceDef != null)
		{
			if (resourceDef.ID == 2)
			{
				resourceTooltip.SetTerm("StoneDeposit");
			}
			else if (resourceDef.ID == 14)
			{
				resourceTooltip.SetTerm("MarbleDeposit");
			}
			else
			{
				resourceTooltip.SetTerm(resourceDef.name);
			}
		}
		transform.SetParent(terrainResourceContainer.transform, worldPositionStays: true);
	}

	public void SetTooltipVisibility(bool isVisible, bool force = false)
	{
		if (isVisible)
		{
			RefreshTooltipAnchor();
		}
		if (force)
		{
			isForcedTooltipVisibility = isVisible;
			resourceTooltip.gameObject.SetActive(isVisible);
		}
		else if (!isForcedTooltipVisibility)
		{
			resourceTooltip.gameObject.SetActive(isVisible);
		}
	}

	public void RefreshTooltipAnchor()
	{
		Cell cellData = World.inst.GetCellData((int)position.x, (int)position.z);
		Vector3 targetPosition = rvPos;
		if (cellData != null && cellData.Type != TerrainType.Obstruction)
		{
			targetPosition.y = TerrainGen.inst.GetGroundHeight(rvPos.x, rvPos.z);
		}
		resourceTooltip.targetPosition = targetPosition;
	}

	public void Init(Vector2 tSize, Cell c, Vector3 mOffsetDir = default(Vector3))
	{
		if (didInit)
		{
			return;
		}
		didInit = true;
		sizeX = (int)tSize.x;
		sizeZ = (int)tSize.y;
		rvMeshIdx = SRand.Range(0, meshOptions.Length);
		meshFilter.sharedMesh = meshOptions[rvMeshIdx];
		meshCollider.sharedMesh = meshOptions[rvMeshIdx];
		MeshSettings meshSettings = meshModifiers[sMeshModifierIdx++ % meshModifiers.Length];
		Transform transform = meshFilter.transform;
		Vector3 localScale = new Vector3(sizeX, meshSettings.yScale + ((float)(sizeX * sizeZ) - 1f) * AreaYSizeModifier, sizeZ);
		localScale.x *= SRand.Range(0.9f, 1.1f);
		localScale.y *= SRand.Range(0.9f, 1.1f);
		localScale.z *= SRand.Range(0.9f, 1.1f);
		transform.localScale = localScale;
		if (doXZRotation || doYRotation)
		{
			float y = 0f;
			float num = 0f;
			float num2 = 0f;
			if (doYRotation)
			{
				y = (SRand.CoinFlip() ? 180 : 0) + SRand.Range(-10, 10);
			}
			if (doXZRotation)
			{
				num = SRand.Range(-10, 10);
				num2 = SRand.Range(-10, 10);
			}
			transform.rotation = Quaternion.Euler(num, y, num2);
		}
		maxResources = meshSettings.resourceAmt * (sizeX * sizeZ);
		x = c.x;
		z = c.z;
		position = new Vector3(x, 0f, z);
		base.transform.position = position;
		Vector3 vector = position;
		vector.x += localScale.x / 2f;
		vector.z += localScale.z / 2f;
		transform.position = vector;
		SetLowestTerrainHeight(transform);
		rvPos = transform.position;
		rvRot = transform.rotation;
		rvScale = transform.localScale;
		resourceTooltip.targetPosition = rvPos;
		resourceTooltip.targetOffset = new Vector3(0f, rvScale.y * 0.75f, 0f);
		outline = new Outline(meshFilter.sharedMesh)
		{
			color = 1,
			meshMtx = Matrix4x4.TRS(rvPos, rvRot, rvScale),
			clipOnTerrain = true
		};
		for (int i = 0; i < sizeX; i++)
		{
			for (int j = 0; j < sizeZ; j++)
			{
				Cell cellData = World.inst.GetCellData(x + i, z + j);
				cellData.terrainResource = this;
				cellData.Type = TerrainType.Obstruction;
			}
		}
		Add(this);
	}

	private void OnDestroy()
	{
		for (int i = 0; i < sizeX; i++)
		{
			for (int j = 0; j < sizeZ; j++)
			{
				Cell cellData = World.inst.GetCellData(x + i, z + j);
				if (cellData != null && cellData.terrainResource == this)
				{
					cellData.terrainResource = null;
				}
			}
		}
		if (resourceTooltip != null)
		{
			UnityEngine.Object.Destroy(resourceTooltip.gameObject);
		}
		outline.Disable();
	}

	public bool AddHarvested(int yield)
	{
		if (currentHarvestedResources > maxResources)
		{
			return true;
		}
		currentHarvestedResources += yield;
		bool flag = maxResources <= currentHarvestedResources;
		Cell cellData = World.inst.GetCellData(x, z);
		if (flag)
		{
			onResourceExhausted?.Invoke(cellData);
			rvScale.y = SRand.Range(0.3f, 0.6f);
			meshFilter.transform.localScale = rvScale;
			SetLowestTerrainHeight(meshFilter.transform);
			rvPos = meshFilter.transform.position;
			resourceTooltip.targetOffset.y = rvScale.y * 0.75f;
			outline.meshMtx = Matrix4x4.TRS(rvPos, rvRot, rvScale);
			EffectsMan.inst.RemoveStonePoof.CreateAndPlay(rvPos);
			World.IsAILandmass(cellData.landMassIdx);
		}
		return flag;
	}

	public float GetHeight()
	{
		return rvScale.y;
	}
}
