using System.Collections.Generic;
using Assets;
using UnityEngine;

public class GodInfoUI : MonoBehaviour
{
	public string nameId;

	public string LocName;

	public string LocDescription;

	public MeshRenderer highlightMesh;

	public SkinnedMeshRenderer highlightSkinnedMesh;

	public Collider highlightCollider;

	internal ObjectHighlighter highlight;

	public bool disabled;

	public string GetLocalizedName()
	{
		return LocName;
	}

	public string GetLocalizedDescription()
	{
		if (!disabled)
		{
			return LocDescription;
		}
		return "newfeature_comingsoon";
	}

	private void Start()
	{
		List<MeshRenderer> list = new List<MeshRenderer>();
		if ((bool)highlightMesh)
		{
			list.Add(highlightMesh);
		}
		List<SkinnedMeshRenderer> list2 = new List<SkinnedMeshRenderer>();
		if ((bool)highlightSkinnedMesh)
		{
			list2.Add(highlightSkinnedMesh);
		}
		highlight = ObjectHighlighter.SetupOutlines(gameObject, list, list2);
		if (GodManager.inst.tasks[transform.GetSiblingIndex()].Count <= 0)
		{
			disabled = true;
			GetComponent<GodShaderDriver>().SetDisabled(v: true);
		}
	}

	public bool Raycast(Ray ray, out RaycastHit hit)
	{
		return highlightCollider.Raycast(ray, out hit, 100f);
	}
}
