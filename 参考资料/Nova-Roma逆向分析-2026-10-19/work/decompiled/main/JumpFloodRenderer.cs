using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class JumpFloodRenderer
{
	private int UVBufferID = Shader.PropertyToID("_UVShaderBuffer");

	private int FloodBufferID1 = Shader.PropertyToID("_FloodBuffer1");

	private int FloodBufferID2 = Shader.PropertyToID("_FloodBuffer2");

	private int stepLengthID = Shader.PropertyToID("_StepLength");

	private Material JumpFloodMaterial;

	public void CreateJumpFloodMaterial()
	{
		JumpFloodMaterial = Resources.Load<Material>("JumpFloodShader");
	}

	public void AddJumpFloodingCommands(int sourceBufferId, ref RenderTexture destination, ref CommandBuffer commandBuffer)
	{
		if (JumpFloodMaterial == null)
		{
			CreateJumpFloodMaterial();
		}
		RenderTextureDescriptor desc = new RenderTextureDescriptor
		{
			dimension = TextureDimension.Tex2D,
			graphicsFormat = GraphicsFormat.R32G32B32A32_SFloat,
			width = destination.width,
			height = destination.height,
			msaaSamples = 1,
			depthBufferBits = 0,
			sRGB = false,
			useMipMap = false,
			autoGenerateMips = false
		};
		commandBuffer.GetTemporaryRT(UVBufferID, desc);
		commandBuffer.Blit(sourceBufferId, UVBufferID, JumpFloodMaterial, 0);
		commandBuffer.GetTemporaryRT(FloodBufferID1, desc, FilterMode.Point);
		commandBuffer.GetTemporaryRT(FloodBufferID2, desc, FilterMode.Point);
		int num = Mathf.CeilToInt(Mathf.Log(destination.width, 2f));
		int num2 = ((num % 2 == 0) ? FloodBufferID2 : FloodBufferID1);
		commandBuffer.Blit(UVBufferID, num2, JumpFloodMaterial, 1);
		for (int num3 = num; num3 >= 0; num3--)
		{
			commandBuffer.SetGlobalFloat(stepLengthID, Mathf.Pow(2f, num3) + 0.5f);
			if (num3 % 2 == 1)
			{
				commandBuffer.Blit(FloodBufferID1, FloodBufferID2, JumpFloodMaterial, 2);
			}
			else
			{
				commandBuffer.Blit(FloodBufferID2, FloodBufferID1, JumpFloodMaterial, 2);
			}
		}
		commandBuffer.Blit(FloodBufferID1, destination, JumpFloodMaterial, 3);
		commandBuffer.ReleaseTemporaryRT(UVBufferID);
		commandBuffer.ReleaseTemporaryRT(FloodBufferID1);
		commandBuffer.ReleaseTemporaryRT(FloodBufferID2);
	}

	public void JumpFloodImmediate(Texture sourceBufferTexture, ref RenderTexture destination)
	{
		if (JumpFloodMaterial == null)
		{
			CreateJumpFloodMaterial();
		}
		RenderTextureDescriptor desc = new RenderTextureDescriptor
		{
			dimension = TextureDimension.Tex2D,
			graphicsFormat = GraphicsFormat.R32G32B32A32_SFloat,
			width = destination.width,
			height = destination.height,
			msaaSamples = 1,
			depthBufferBits = 0,
			sRGB = false,
			volumeDepth = 1,
			useMipMap = false,
			autoGenerateMips = false
		};
		RenderTexture temporary = RenderTexture.GetTemporary(desc);
		Graphics.Blit(sourceBufferTexture, temporary, JumpFloodMaterial, 0);
		RenderTexture temporary2 = RenderTexture.GetTemporary(desc);
		RenderTexture temporary3 = RenderTexture.GetTemporary(desc);
		int num = Mathf.CeilToInt(Mathf.Log(destination.width, 2f));
		RenderTexture dest = ((num % 2 == 0) ? temporary3 : temporary2);
		Graphics.Blit(temporary, dest, JumpFloodMaterial, 1);
		for (int num2 = num; num2 >= 0; num2--)
		{
			Shader.SetGlobalFloat(stepLengthID, Mathf.Pow(2f, num2) + 0.5f);
			if (num2 % 2 == 1)
			{
				Graphics.Blit(temporary2, temporary3, JumpFloodMaterial, 2);
			}
			else
			{
				Graphics.Blit(temporary3, temporary2, JumpFloodMaterial, 2);
			}
		}
		Graphics.Blit(temporary2, destination, JumpFloodMaterial, 3);
		RenderTexture.ReleaseTemporary(temporary);
		RenderTexture.ReleaseTemporary(temporary2);
		RenderTexture.ReleaseTemporary(temporary3);
	}
}
