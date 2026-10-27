using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[CreateAssetMenu(fileName = "TerrainSkin", menuName = "Tools/TerrainSkinConfiguration", order = 1)]
public class TerrainSkinConfiguration : ScriptableObject
{
	[Serializable]
	public class TextureAndScale
	{
		public Texture2D Texture;

		public float Scale = 1f;
	}

	public bool EditorUpdated;

	public TextureAndScale[] TexturesAndScales;

	protected Texture2DArray BuiltTextureArray;

	public float[] Scales;

	public Texture2DArray TextureArray
	{
		get
		{
			if (EditorUpdated || BuiltTextureArray == null)
			{
				Build2DTextureArray();
			}
			return BuiltTextureArray;
		}
	}

	public void OnValidate()
	{
		Build2DTextureArray();
	}

	private void Build2DTextureArray()
	{
		if (TexturesAndScales.Length == 0)
		{
			return;
		}
		for (int i = 0; i < TexturesAndScales.Length; i++)
		{
			if (TexturesAndScales[i].Texture == null)
			{
				return;
			}
		}
		Texture2D texture = TexturesAndScales[0].Texture;
		if (BuiltTextureArray != null)
		{
			UnityEngine.Object.Destroy(BuiltTextureArray);
		}
		BuiltTextureArray = new Texture2DArray(texture.width, texture.height, TexturesAndScales.Length, texture.graphicsFormat, TextureCreationFlags.MipChain);
		BuiltTextureArray.name = "TerrainSkinArray";
		Scales = new float[TexturesAndScales.Length];
		for (int j = 0; j < TexturesAndScales.Length; j++)
		{
			Scales[j] = TexturesAndScales[j].Scale;
			for (int k = 0; k < texture.mipmapCount; k++)
			{
				Graphics.CopyTexture(TexturesAndScales[j].Texture, 0, BuiltTextureArray, j);
			}
		}
		EditorUpdated = false;
	}
}
