using UnityEngine;

namespace Colorful;

[HelpURL("http://www.thomashourdel.com/colorful/doc/blur-effects/bilateral-gaussian-blur.html")]
[ExecuteInEditMode]
[AddComponentMenu("Colorful FX/Blur Effects/Bilateral Gaussian Blur")]
public class BilateralGaussianBlur : BaseEffect
{
	[Range(0f, 10f)]
	[Tooltip("Add more passes to get a smoother blur. Beware that each pass will slow down the effect.")]
	public int Passes = 1;

	[Range(0.04f, 1f)]
	[Tooltip("Adjusts the blur \"sharpness\" around edges")]
	public float Threshold = 0.05f;

	[Range(0f, 1f)]
	[Tooltip("Blending factor.")]
	public float Amount = 1f;

	protected override void Start()
	{
		base.Start();
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}

	protected override void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		Material.SetFloat("_Threshold", Threshold / 10000f);
		if (Passes == 0 || Amount == 0f)
		{
			Graphics.Blit(source, destination);
		}
		else if (Amount < 1f)
		{
			RenderTexture temporary = RenderTexture.GetTemporary(source.width, source.height);
			if (Passes == 1)
			{
				OnePassBlur(source, temporary);
			}
			else
			{
				MultiPassBlur(source, temporary);
			}
			Material.SetTexture("_Blurred", temporary);
			Material.SetFloat("_Amount", Amount);
			Graphics.Blit(source, destination, Material, 1);
			RenderTexture.ReleaseTemporary(temporary);
		}
		else if (Passes == 1)
		{
			OnePassBlur(source, destination);
		}
		else
		{
			MultiPassBlur(source, destination);
		}
	}

	protected virtual void OnePassBlur(RenderTexture source, RenderTexture destination)
	{
		RenderTexture temporary = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
		Material.SetVector("_Direction", new Vector2(1f / (float)source.width, 0f));
		Graphics.Blit(source, temporary, Material, 0);
		Material.SetVector("_Direction", new Vector2(0f, 1f / (float)source.height));
		Graphics.Blit(temporary, destination, Material, 0);
		RenderTexture.ReleaseTemporary(temporary);
	}

	protected virtual void MultiPassBlur(RenderTexture source, RenderTexture destination)
	{
		Vector2 vector = new Vector2(1f / (float)source.width, 0f);
		Vector2 vector2 = new Vector2(0f, 1f / (float)source.height);
		RenderTexture temporary = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
		RenderTexture temporary2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
		Material.SetVector("_Direction", vector);
		Graphics.Blit(source, temporary, Material, 0);
		Material.SetVector("_Direction", vector2);
		Graphics.Blit(temporary, temporary2, Material, 0);
		temporary.DiscardContents();
		for (int i = 1; i < Passes; i++)
		{
			Material.SetVector("_Direction", vector);
			Graphics.Blit(temporary2, temporary, Material, 0);
			temporary2.DiscardContents();
			Material.SetVector("_Direction", vector2);
			Graphics.Blit(temporary, temporary2, Material, 0);
			temporary.DiscardContents();
		}
		Graphics.Blit(temporary2, destination);
		RenderTexture.ReleaseTemporary(temporary);
		RenderTexture.ReleaseTemporary(temporary2);
	}

	protected override string GetShaderName()
	{
		return "Hidden/Colorful/Bilateral Gaussian Blur";
	}
}
