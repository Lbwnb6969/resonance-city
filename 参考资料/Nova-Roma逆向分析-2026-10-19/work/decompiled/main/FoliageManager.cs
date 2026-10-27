using System;
using UnityEngine;

public class FoliageManager : MonoBehaviour
{
	[Serializable]
	public class FoliageColorSet
	{
		public Color color1;

		public Color color2;

		public Color color3;

		public Color color4;

		public static void Lerp(ref FoliageColorSet result, FoliageColorSet first, FoliageColorSet second, float t)
		{
			result.color1 = Color.Lerp(first.color1, second.color1, t);
			result.color2 = Color.Lerp(first.color2, second.color2, t);
			result.color3 = Color.Lerp(first.color3, second.color3, t);
			result.color4 = Color.Lerp(first.color4, second.color4, t);
		}
	}

	public static FoliageManager inst;

	public Material treeMaterial;

	private float blend;

	private float blendDuration;

	private bool doBlend;

	private FoliageColorSet currentTreeColorSet;

	private FoliageColorSet nextTreeColorSet;

	private FoliageColorSet lerpedResultTemp = new FoliageColorSet();

	private void Awake()
	{
		inst = this;
	}

	public void BlendInNextColorSet(float duration)
	{
		blend = 0f;
		blendDuration = duration;
		doBlend = true;
	}

	public void SetTreeColorSet(FoliageColorSet colorSet)
	{
		currentTreeColorSet = colorSet;
	}

	public void SetNextTreeColorSet(FoliageColorSet colorSet)
	{
		nextTreeColorSet = colorSet;
	}

	public void SetColorSet(Material material, FoliageColorSet colorSet)
	{
		Shader.SetGlobalColor("_TreeColor1", colorSet.color1.linear);
		Shader.SetGlobalColor("_TreeColor2", colorSet.color2.linear);
		Shader.SetGlobalColor("_TreeColor3", colorSet.color3.linear);
		Shader.SetGlobalColor("_TreeColor", colorSet.color4.linear);
	}

	public void ApplyColorSet()
	{
		doBlend = false;
		blend = 1f;
		blendDuration = 1f;
		Shader.SetGlobalColor("_TreeColor1", currentTreeColorSet.color1.linear);
		Shader.SetGlobalColor("_TreeColor2", currentTreeColorSet.color2.linear);
		Shader.SetGlobalColor("_TreeColor3", currentTreeColorSet.color3.linear);
		Shader.SetGlobalColor("_TreeColor", currentTreeColorSet.color4.linear);
	}

	private void Update()
	{
		if (doBlend)
		{
			blend = Mathf.Clamp01(blend + Time.deltaTime / blendDuration);
			FoliageColorSet.Lerp(ref lerpedResultTemp, currentTreeColorSet, nextTreeColorSet, blend);
			SetColorSet(treeMaterial, lerpedResultTemp);
			if (blend >= 1f)
			{
				doBlend = false;
				currentTreeColorSet = nextTreeColorSet;
			}
		}
	}
}
