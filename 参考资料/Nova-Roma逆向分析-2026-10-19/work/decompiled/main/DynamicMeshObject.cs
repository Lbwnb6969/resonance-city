using System;
using System.Collections.Generic;
using Assets;
using UnityEngine;

public class DynamicMeshObject : MonoBehaviour
{
	public int idxIntoPool = -1;

	public RectangleFinder.RectangleCoordinates rCoords;

	public MeshFilter mFilter;

	public MeshRenderer mRenderer;

	private bool isShutdown = true;

	[NonSerialized]
	public List<DynamicMesh> targetMeshes = new List<DynamicMesh>(8);

	[NonSerialized]
	public ObjectHighlighter objHiglight;

	public bool IsRectangleIdentical(RectangleFinder.RectangleCoordinates targetRect)
	{
		if (rCoords == null)
		{
			return targetRect == null;
		}
		return rCoords.IsSame(targetRect);
	}

	public void Init()
	{
		isShutdown = false;
		transform.rotation = Quaternion.identity;
		Util.SetActive(gameObject, active: true);
	}

	public void SetMesh(Mesh mesh)
	{
		mFilter.sharedMesh = mesh;
		if (objHiglight != null)
		{
			objHiglight.Release();
			objHiglight = null;
		}
		objHiglight = ObjectHighlighter.SetupOutline(gameObject, mRenderer, null);
	}

	public void CalculateColliders()
	{
		Vector3 size = new Vector3(1f, mFilter.sharedMesh.bounds.size.y, 1f);
		Vector3 center = new Vector3(0f, size.y / 2f, 0f);
		for (int i = 0; i < targetMeshes.Count; i++)
		{
			targetMeshes[i].bCollider.size = size;
			targetMeshes[i].bCollider.center = center;
		}
	}

	public void TrySetIntegrityVisuals()
	{
		float norm = 1f;
		for (int i = 0; i < targetMeshes.Count; i++)
		{
			Building component = targetMeshes[i].GetComponent<Building>();
			if (!(component == null))
			{
				_ = component.Life / component.ModifiedMaxLife;
			}
		}
		mRenderer.sharedMaterial = Building.GetIntegrityMaterial(norm);
	}

	public void SetUniMaterial()
	{
		mRenderer.sharedMaterial = World.inst.romeUnimaterial;
	}

	public void Shutdown()
	{
		if (isShutdown)
		{
			return;
		}
		isShutdown = true;
		if (objHiglight != null)
		{
			objHiglight.Release();
			objHiglight = null;
		}
		for (int i = 0; i < targetMeshes.Count; i++)
		{
			if ((bool)targetMeshes[i].dMeshObject)
			{
				targetMeshes[i].dMeshObject = null;
			}
		}
		targetMeshes.Clear();
		SetUniMaterial();
		DynamicMesh.objPool.RemoveAtSwapBoth(idxIntoPool);
		if (DynamicMesh.objPool.Count > 0 && idxIntoPool < DynamicMesh.objPool.Count)
		{
			DynamicMesh.objPool.data[idxIntoPool].idxIntoPool = idxIntoPool;
		}
		Util.SetActive(gameObject, active: false);
	}

	public static bool operator ==(DynamicMeshObject c1, object c2)
	{
		if ((object)c1 == null)
		{
			return c2 == null;
		}
		if (c1.isShutdown && c2 == null)
		{
			return true;
		}
		return c1.Equals(c2);
	}

	public static bool operator !=(DynamicMeshObject c1, object c2)
	{
		return !(c1 == c2);
	}
}
