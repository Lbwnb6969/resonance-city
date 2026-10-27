using System;
using UnityEngine;

namespace cakeslice;

public class Outline
{
	public bool formToTerrain;

	public bool clipOnTerrain;

	public int color;

	public int meshIdx = -1;

	[NonSerialized]
	public int effectIndex = -1;

	[HideInInspector]
	public int originalLayer;

	[HideInInspector]
	public Material[] originalMaterials;

	[NonSerialized]
	public Material[] sharedMaterials;

	public Renderer Renderer { get; set; }

	public MeshFilter MeshFilter { get; set; }

	public SkinnedMeshRenderer SkinnedMeshRenderer { get; set; }

	public Matrix4x4 meshMtx { get; set; }

	public Mesh mesh { get; set; }

	public IProceduralOutline proceduralOutline { get; set; }

	public Outline()
	{
	}

	public Outline(Renderer r, MeshFilter mf, SkinnedMeshRenderer smr, bool formToTerrain = false, bool clipOnTerrain = false)
	{
		Renderer = r;
		MeshFilter = mf;
		SkinnedMeshRenderer = smr;
		sharedMaterials = Renderer.sharedMaterials;
		this.formToTerrain = formToTerrain;
		this.clipOnTerrain = clipOnTerrain;
	}

	public Outline(Renderer r)
	{
		Renderer = r;
	}

	public Outline(Mesh m, bool formToTerrain = false, bool clipOnTerrain = false)
	{
		mesh = m;
		this.formToTerrain = formToTerrain;
		this.clipOnTerrain = clipOnTerrain;
	}

	public Outline(IProceduralOutline po, bool formToTerrain = false, bool clipOnTerrain = false)
	{
		proceduralOutline = po;
		this.formToTerrain = formToTerrain;
		this.clipOnTerrain = clipOnTerrain;
	}

	public void Enable()
	{
		OutlineEffect component = Cam.inst.GetComponent<OutlineEffect>();
		if ((0u | ((Renderer != null) ? 1u : 0u) | ((SkinnedMeshRenderer != null) ? 1u : 0u) | ((mesh != null) ? 1u : 0u) | ((proceduralOutline != null) ? 1u : 0u)) != 0)
		{
			component.AddOutline(this);
		}
		else
		{
			component.RemoveOutline(this);
		}
	}

	public void Disable()
	{
		if (Cam.inst != null)
		{
			Cam.inst.GetComponent<OutlineEffect>().RemoveOutline(this);
		}
	}
}
