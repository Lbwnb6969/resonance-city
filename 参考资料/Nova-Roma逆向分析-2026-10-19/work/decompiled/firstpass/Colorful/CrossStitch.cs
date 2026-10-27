using UnityEngine;

namespace Colorful;

[HelpURL("http://www.thomashourdel.com/colorful/doc/artistic-effects/cross-stitch.html")]
[ExecuteInEditMode]
[AddComponentMenu("Colorful FX/Artistic Effects/Cross Stitch")]
public class CrossStitch : BaseEffect
{
	[Range(1f, 128f)]
	[Tooltip("Works best with power of two values.")]
	public int Size = 8;

	[Range(0f, 10f)]
	[Tooltip("Brightness adjustment. Cross-stitching tends to lower the overall brightness, use this to compensate.")]
	public float Brightness = 1.5f;

	[Tooltip("Inverts the cross-stiching pattern.")]
	public bool Invert;

	[Tooltip("Should the original render be pixelized ?")]
	public bool Pixelize = true;

	protected override void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		Material.SetInt("_StitchSize", Size);
		Material.SetFloat("_Brightness", Brightness);
		int num = (Invert ? 1 : 0);
		if (Pixelize)
		{
			num += 2;
			Material.SetFloat("_Scale", (float)source.width / (float)Size);
			Material.SetFloat("_Ratio", (float)source.width / (float)source.height);
		}
		Graphics.Blit(source, destination, Material, num);
	}

	protected override string GetShaderName()
	{
		return "Hidden/Colorful/Cross Stitch";
	}
}
