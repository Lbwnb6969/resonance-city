using System.Collections.Generic;
using UnityEngine;

public class ClothTimescaleFix : MonoBehaviour
{
	private SkinnedMeshRenderer smrenderer;

	public Building building;

	private Cloth cloth;

	private static List<ClothTimescaleFix> fixes = new List<ClothTimescaleFix>();

	public static void CheckCloth()
	{
		if (Time.timeScale <= 0.01f)
		{
			for (int i = 0; i < fixes.Count; i++)
			{
				fixes[i].cloth.enabled = false;
			}
		}
		else
		{
			for (int j = 0; j < fixes.Count; j++)
			{
				fixes[j].cloth.enabled = true;
			}
		}
	}

	private void Start()
	{
		cloth = GetComponent<Cloth>();
		smrenderer = GetComponent<SkinnedMeshRenderer>();
		if ((bool)building)
		{
			smrenderer.enabled = building.IsPlaced() && building.IsBuilt() && building.seenByPlayer;
		}
		fixes.Add(this);
	}

	private void OnDestroy()
	{
		fixes.Remove(this);
	}

	private void Update()
	{
		if ((bool)building)
		{
			smrenderer.enabled = building.IsPlaced() && building.IsBuilt() && building.seenByPlayer;
			if (smrenderer.enabled)
			{
				enabled = false;
			}
		}
	}
}
