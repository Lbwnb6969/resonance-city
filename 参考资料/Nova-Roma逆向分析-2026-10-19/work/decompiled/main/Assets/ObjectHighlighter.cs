using System.Collections.Generic;
using UnityEngine;
using cakeslice;

namespace Assets;

public class ObjectHighlighter
{
	public GameObject go;

	public ArrayExt<Outline> outlines = new ArrayExt<Outline>(5);

	private int nextOutlineColor = -1;

	private int currOutlineColor = -1;

	private bool queued;

	private static readonly ArrayExt<ObjectHighlighter> highlightedObjects = new ArrayExt<ObjectHighlighter>(50);

	public void SetOutlineImmediate(int color)
	{
		if (color != -1 && currOutlineColor == -1)
		{
			Add(this);
		}
		nextOutlineColor = color;
	}

	public static ObjectHighlighter SetupOutlines(GameObject go, List<MeshRenderer> renderers, List<SkinnedMeshRenderer> meshRenderers, bool formToTerrain = false, bool clipOnTerrain = false)
	{
		ObjectHighlighter objectHighlighter = new ObjectHighlighter
		{
			go = go
		};
		if (renderers != null)
		{
			for (int i = 0; i < renderers.Count; i++)
			{
				Outline item = new Outline(renderers[i], renderers[i].GetComponent<MeshFilter>(), null, formToTerrain, clipOnTerrain);
				objectHighlighter.outlines.Add(item);
			}
		}
		if (meshRenderers != null)
		{
			for (int j = 0; j < meshRenderers.Count; j++)
			{
				Outline item2 = new Outline(meshRenderers[j], meshRenderers[j].GetComponent<MeshFilter>(), meshRenderers[j], formToTerrain, clipOnTerrain);
				objectHighlighter.outlines.Add(item2);
			}
		}
		return objectHighlighter;
	}

	public static ObjectHighlighter SetupOutline(GameObject go, Renderer renderer, SkinnedMeshRenderer meshRenderer, bool formToTerrain = false, bool clipOnTerrain = false)
	{
		ObjectHighlighter objectHighlighter = new ObjectHighlighter
		{
			go = go
		};
		if (renderer != null)
		{
			Outline item = new Outline(renderer, renderer.GetComponent<MeshFilter>(), null, formToTerrain, clipOnTerrain);
			objectHighlighter.outlines.Add(item);
		}
		if (meshRenderer != null)
		{
			Outline item2 = new Outline(meshRenderer, meshRenderer.GetComponent<MeshFilter>(), meshRenderer, formToTerrain, clipOnTerrain);
			objectHighlighter.outlines.Add(item2);
		}
		return objectHighlighter;
	}

	public static ObjectHighlighter SetupOutline(GameObject go, IProceduralOutline proceduralOutline, bool formToTerrain = false, bool clipOnTerrain = false)
	{
		ObjectHighlighter objectHighlighter = new ObjectHighlighter
		{
			go = go
		};
		if (proceduralOutline != null)
		{
			Outline item = new Outline(proceduralOutline, formToTerrain, clipOnTerrain);
			objectHighlighter.outlines.Add(item);
		}
		return objectHighlighter;
	}

	public void Release()
	{
		for (int i = 0; i < outlines.Count; i++)
		{
			outlines.data[i].Disable();
		}
		outlines.Clear();
	}

	private static void Add(ObjectHighlighter oh)
	{
		if (!oh.queued)
		{
			oh.queued = true;
			highlightedObjects.Add(oh);
		}
	}

	private static void RemoveAt(int i)
	{
		highlightedObjects.data[i].queued = false;
		highlightedObjects.RemoveAtSwap(i);
	}

	public static void Update()
	{
		for (int i = 0; i < highlightedObjects.Count; i++)
		{
			if (UpdateOutlines(highlightedObjects.data[i], i))
			{
				i--;
			}
		}
	}

	private static bool UpdateOutlines(ObjectHighlighter oh, int index)
	{
		if (oh.go == null)
		{
			RemoveAt(index);
			oh.currOutlineColor = -1;
			oh.nextOutlineColor = -1;
			return true;
		}
		if (oh.nextOutlineColor == -1)
		{
			for (int i = 0; i < oh.outlines.Count; i++)
			{
				oh.outlines.data[i].Disable();
			}
			RemoveAt(index);
			oh.currOutlineColor = -1;
			return true;
		}
		for (int j = 0; j < oh.outlines.Count; j++)
		{
			oh.outlines.data[j].Enable();
			oh.outlines.data[j].color = oh.nextOutlineColor;
		}
		oh.currOutlineColor = oh.nextOutlineColor;
		oh.nextOutlineColor = -1;
		return false;
	}
}
