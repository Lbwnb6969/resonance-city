using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using UnityEngine;
using UnityEngine.Rendering;

public class FreeResourceSystem : MonoBehaviour
{
	[Serializable]
	public class ResourceDef
	{
		public int ID;

		public GameObject prefab;

		internal Mesh cachedMesh;

		internal Mesh cachedCarriedMesh;

		public string name;

		public int carryCapacity;

		public string iconName = "<sprite name=icon_wood>";

		public Sprite texture;

		internal GameObject autoResourceStackPrefab;

		public float autoStackSpacing = 0.08f;

		public float autoStackHeightMul = 1f;

		public bool autoStackAlterateRows;

		public int xStackSize;

		public int zStackSize;

		public ThoughtBubbleSystem.Thought thoughtWhenMissing;

		public bool isSecondary;

		public bool timeExpire;
	}

	public delegate void OnAddResource(ResourceDef def);

	public static FreeResourceSystem inst;

	public static List<DeadVillager> deferredDeadRemoval = new List<DeadVillager>();

	public Dictionary<int, InstanceSystem> instances = new Dictionary<int, InstanceSystem>();

	public Material uniMaterial;

	public GameObject autoStackPrefab;

	public Dictionary<int, ResourceDef> resourceDefMap = new Dictionary<int, ResourceDef>();

	internal List<ResourceDef> resourceDefs = new List<ResourceDef>();

	public static OnAddResource onResourceAdded;

	private Vector3 pos;

	public int GetCarryCapacity(int resourceID)
	{
		return resourceDefMap[resourceID].carryCapacity;
	}

	private void AddResourceDef(ResourceDef def)
	{
		if (!resourceDefMap.ContainsKey(def.ID))
		{
			def.cachedMesh = def.prefab.GetComponent<MeshFilter>().sharedMesh;
			def.prefab.GetComponent<MeshRenderer>().material = World.inst.uniMaterialFog;
			resourceDefMap.Add(def.ID, def);
			GraphicalResourceStack component = autoStackPrefab.GetComponent<GraphicalResourceStack>();
			component.resourceID = def.ID;
			component.spacing = def.autoStackSpacing;
			component.HeightMultiplier = def.autoStackHeightMul;
			component.rowAlternateRotation = def.autoStackAlterateRows;
			def.autoResourceStackPrefab = UnityEngine.Object.Instantiate(autoStackPrefab);
			InstanceSystem instanceSystem = new InstanceSystem();
			instanceSystem.shadowCastingMode = ShadowCastingMode.Off;
			instances.Add(def.ID, instanceSystem);
			resourceDefs.Add(def);
			onResourceAdded?.Invoke(def);
		}
		else
		{
			Debug.LogError("Duplicate resource IDs");
		}
	}

	private void Awake()
	{
		inst = this;
		ResourceDefinitions resourceDefinitions = Resources.Load<ResourceDefinitions>("ResourceDefinitionList");
		for (int i = 0; i < resourceDefinitions.initialResourceDefinitions.Count; i++)
		{
			AddResourceDef(resourceDefinitions.initialResourceDefinitions[i]);
		}
	}

	public void Tick(float dt)
	{
		FreeResource[] data = FreeResource.freeResources.data;
		int count = FreeResource.freeResources.Count;
		for (int i = 0; i < count; i++)
		{
			FreeResource freeResource = data[i];
			freeResource.Tick(dt);
			UpdatePositionAndRotation(freeResource);
		}
		for (int j = 0; j < deferredDeadRemoval.Count; j++)
		{
			deferredDeadRemoval[j].Shutdown();
		}
		deferredDeadRemoval.Clear();
	}

	private void UpdatePositionAndRotation(FreeResource resource)
	{
		Villager holder = resource.Holder;
		if (holder != null)
		{
			pos = holder.GetPosWithOffset();
			Vector3 vector = holder.Rot * resource.offset;
			pos.y += vector.y;
			pos.x += vector.x;
			pos.z += vector.z;
			resource.SetPositionAndRotation(pos, holder.Rot);
		}
	}

	private void LateUpdate()
	{
		foreach (KeyValuePair<int, InstanceSystem> instance in instances)
		{
			Mesh cachedMesh = resourceDefMap[instance.Key].cachedMesh;
			instance.Value.DrawInstances(cachedMesh, uniMaterial);
		}
	}

	public FreeResource AddFreeResource(int resourceID, Vector3 pos, int landMassIdx)
	{
		FreeResource freeResource;
		if (FreeResource.freeResourcePoolCount == FreeResource.freeResourcePool.Count)
		{
			freeResource = new FreeResource();
			FreeResource.freeResourcePool.Add(freeResource);
			freeResource.idxIntoPool = FreeResource.freeResourcePool.Count - 1;
			FreeResource.freeResourcePoolCount++;
		}
		else
		{
			freeResource = FreeResource.freeResourcePool.GetNew();
			freeResource.idxIntoPool = FreeResource.freeResourcePool.Count - 1;
		}
		freeResource.resourceID = resourceID;
		freeResource.Init();
		instances[resourceID].AddInstance(freeResource, pos, Quaternion.identity, Vector3.one);
		freeResource.landMassIdx = landMassIdx;
		freeResource.skipVisibility = Player.inst.LandMassIsAPlayerLandMass(landMassIdx);
		if (freeResource.landMassIdx == -1)
		{
			freeResource.landMassIdx = World.inst.GetCellDataClamped(pos).landMassIdx;
		}
		Mesh cachedMesh = resourceDefMap[resourceID].cachedMesh;
		freeResource.bounds = cachedMesh.bounds.size;
		freeResource.Pos = pos;
		return freeResource;
	}

	public void RemoveFreeResource(FreeResource curr)
	{
		instances[curr.resourceID].ReleaseInstance(curr);
	}

	public void UpdateResourceHeightsForCells(HashSet<int> dirtyCells)
	{
		foreach (int dirtyCell in dirtyCells)
		{
			List<ResourceStackAuto> list = ResourceStackAuto.stackGrid[dirtyCell];
			if (list == null)
			{
				continue;
			}
			for (int i = 0; i < list.Count; i++)
			{
				ResourceStackAuto resourceStackAuto = list[i];
				Vector3 position = resourceStackAuto.transform.position;
				float groundHeight = TerrainGen.inst.GetGroundHeight(position.x, position.z);
				if (Mathf.Abs(position.y - groundHeight) > 0.001f)
				{
					position.y = groundHeight;
					resourceStackAuto.transform.position = position;
					resourceStackAuto.stack.TickOnce();
				}
			}
		}
		FreeResource[] data = FreeResource.freeResources.data;
		int count = FreeResource.freeResources.Count;
		int gridWidth = World.inst.GridWidth;
		for (int j = 0; j < count; j++)
		{
			FreeResource freeResource = data[j];
			if (freeResource.Holder != null)
			{
				continue;
			}
			Vector3 newPos = freeResource.Pos;
			int num = (int)newPos.x;
			int item = (int)newPos.z * gridWidth + num;
			if (dirtyCells.Contains(item))
			{
				float groundHeight2 = TerrainGen.inst.GetGroundHeight(newPos.x, newPos.z);
				if (Mathf.Abs(newPos.y - groundHeight2) > 0.001f)
				{
					newPos.y = groundHeight2;
					freeResource.SetPositionAndRotation(newPos, freeResource.Rot);
				}
			}
		}
	}
}
