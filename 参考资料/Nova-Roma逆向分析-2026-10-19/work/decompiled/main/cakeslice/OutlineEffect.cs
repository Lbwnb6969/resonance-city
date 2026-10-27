using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace cakeslice;

[DisallowMultipleComponent]
[RequireComponent(typeof(Camera))]
public class OutlineEffect : MonoBehaviour
{
	public class BatchOutline
	{
		public Mesh mesh;

		public int count;

		public Matrix4x4[] matrixs = new Matrix4x4[1023];

		public float[] meshIdxs = new float[1023];

		public Vector4[] meshColor = new Vector4[1023];

		public MaterialPropertyBlock mBlock = new MaterialPropertyBlock();

		public void Reset()
		{
			count = 0;
		}
	}

	private static OutlineEffect m_instance;

	private readonly List<Outline> outlines = new List<Outline>();

	private ArrayExt<BatchOutline> batchOutlines = new ArrayExt<BatchOutline>(16);

	[SerializeField]
	private Material batchClippingMaterial;

	[Range(0f, 6f)]
	public float lineThicknessMin = 0.2f;

	[Range(0f, 6f)]
	public float lineThicknessMax = 0.4f;

	[Range(0f, 10f)]
	public float lineIntensity = 0.5f;

	[Range(0f, 1f)]
	public float fillAmount1 = 0.2f;

	[Range(0f, 1f)]
	public float fillAmount2 = 0.2f;

	[Range(0f, 1f)]
	public float fillAmount3 = 0.2f;

	public Color lineColor0 = Color.red;

	public Color lineColor1 = Color.green;

	public Color lineColor2 = Color.blue;

	public bool additiveRendering;

	[Header("Advanced settings")]
	public bool scaleWithScreenSize = true;

	[Range(0.1f, 0.9f)]
	public float alphaCutoff = 0.5f;

	public Camera sourceCamera;

	public Material outline1Material;

	public Material outline2Material;

	public Material outline3Material;

	public Material outline1MaterialClipping;

	public Material outline2MaterialClipping;

	public Material outline3MaterialClipping;

	public Material outline1MaterialTerrainForming;

	public Material outline2MaterialTerrainForming;

	public Material outline3MaterialTerrainForming;

	public Material outline1MaterialTerrainFormingAndClipping;

	public Material outline2MaterialTerrainFormingAndClipping;

	public Material outline3MaterialTerrainFormingAndClipping;

	public Material outlineEraseMaterial;

	private Shader outlineShader;

	private Shader outlineBufferShader;

	public Material outlineShaderMaterial;

	[HideInInspector]
	public RenderTexture renderTexture;

	private CommandBuffer commandBuffer;

	private List<Material> materialBuffer = new List<Material>();

	private int _outlineSourceID;

	public static OutlineEffect Instance
	{
		get
		{
			if (object.Equals(m_instance, null))
			{
				return m_instance = Object.FindAnyObjectByType(typeof(OutlineEffect)) as OutlineEffect;
			}
			return m_instance;
		}
	}

	private OutlineEffect()
	{
	}

	public void AddBatchOutline(Mesh m, int meshIdx, int colorIdx, Matrix4x4 mat)
	{
		BatchOutline batchOutline = null;
		for (int i = 0; i < batchOutlines.Count; i++)
		{
			BatchOutline batchOutline2 = batchOutlines.data[i];
			if (!(batchOutline2.mesh != m) && batchOutline2.count < 1023)
			{
				batchOutline = batchOutline2;
				break;
			}
		}
		if (batchOutline == null)
		{
			batchOutline = new BatchOutline
			{
				mesh = m
			};
			batchOutlines.Add(batchOutline);
		}
		batchOutline.matrixs[batchOutline.count] = mat;
		batchOutline.meshIdxs[batchOutline.count] = meshIdx;
		Color color = Color.clear;
		switch (colorIdx)
		{
		case 0:
			color = Color.red;
			break;
		case 1:
			color = Color.green;
			break;
		case 2:
			color = Color.blue;
			break;
		}
		batchOutline.meshColor[batchOutline.count] = color;
		batchOutline.count++;
	}

	private Material GetMaterial(int meshIdx, int colorID, bool formToTerrain, bool clipOnTerrain)
	{
		return GetMaterialFromID(colorID, formToTerrain, clipOnTerrain);
	}

	private Material GetMaterialFromID(int colorID, bool formToTerrain, bool clipToTerrain)
	{
		if (formToTerrain)
		{
			if (clipToTerrain)
			{
				switch (colorID)
				{
				case 0:
					return outline1MaterialTerrainFormingAndClipping;
				case 1:
					return outline2MaterialTerrainFormingAndClipping;
				case 2:
					return outline3MaterialTerrainFormingAndClipping;
				}
			}
			switch (colorID)
			{
			case 0:
				return outline1MaterialTerrainForming;
			case 1:
				return outline2MaterialTerrainForming;
			case 2:
				return outline3MaterialTerrainForming;
			}
		}
		if (clipToTerrain)
		{
			switch (colorID)
			{
			case 0:
				return outline1MaterialClipping;
			case 1:
				return outline2MaterialClipping;
			case 2:
				return outline3MaterialClipping;
			}
		}
		return colorID switch
		{
			0 => outline1Material, 
			1 => outline2Material, 
			2 => outline3Material, 
			_ => outline1Material, 
		};
	}

	private void Awake()
	{
		_outlineSourceID = Shader.PropertyToID("_OutlineSource");
		m_instance = this;
	}

	private void Start()
	{
		CreateMaterialsIfNeeded();
		UpdateMaterialsPublicProperties();
		if (sourceCamera == null)
		{
			sourceCamera = GetComponent<Camera>();
			if (sourceCamera == null)
			{
				sourceCamera = Camera.main;
			}
		}
		commandBuffer = new CommandBuffer();
		GetComponent<Camera>().AddCommandBuffer(CameraEvent.BeforeImageEffects, commandBuffer);
	}

	public void Update()
	{
		if (commandBuffer == null)
		{
			return;
		}
		UpdateMaterialsPublicProperties();
		commandBuffer.Clear();
		commandBuffer.GetTemporaryRT(_outlineSourceID, sourceCamera.pixelWidth, sourceCamera.pixelHeight, 16, FilterMode.Bilinear);
		commandBuffer.SetRenderTarget(_outlineSourceID);
		commandBuffer.ClearRenderTarget(clearDepth: true, clearColor: true, Color.clear);
		if (outlines != null)
		{
			int i = 0;
			for (int count = outlines.Count; i < count; i++)
			{
				Outline outline = outlines[i];
				LayerMask layerMask = sourceCamera.cullingMask;
				if (outline == null || (int)layerMask != ((int)layerMask | (1 << outline.originalLayer)))
				{
					continue;
				}
				Material material = GetMaterial(outline.meshIdx, outline.color, outline.formToTerrain, outline.clipOnTerrain);
				if ((bool)outline.Renderer)
				{
					Material[] sharedMaterials = outline.Renderer.sharedMaterials;
					for (int j = 0; j < sharedMaterials.Length; j++)
					{
						commandBuffer.DrawRenderer(outline.Renderer, material, 0, 0);
						MeshFilter meshFilter = outline.MeshFilter;
						if ((bool)meshFilter && (bool)meshFilter.sharedMesh)
						{
							for (int k = 1; k < meshFilter.sharedMesh.subMeshCount; k++)
							{
								commandBuffer.DrawRenderer(outline.Renderer, material, k, 0);
							}
						}
						SkinnedMeshRenderer skinnedMeshRenderer = outline.SkinnedMeshRenderer;
						if ((bool)skinnedMeshRenderer && (bool)skinnedMeshRenderer.sharedMesh)
						{
							for (int l = 1; l < skinnedMeshRenderer.sharedMesh.subMeshCount; l++)
							{
								commandBuffer.DrawRenderer(outline.Renderer, material, l, 0);
							}
						}
					}
				}
				if (outline.mesh != null)
				{
					material.SetInt("_MeshIdx", outline.meshIdx);
					commandBuffer.DrawMesh(outline.mesh, outline.meshMtx, material);
				}
				if (outline.proceduralOutline != null)
				{
					material.SetInt("_MeshIdx", outline.meshIdx);
					outline.proceduralOutline.DrawOutline(commandBuffer, material);
				}
			}
		}
		if (batchOutlines == null)
		{
			return;
		}
		for (int m = 0; m < batchOutlines.Count; m++)
		{
			BatchOutline batchOutline = batchOutlines.data[m];
			if (batchOutline.count != 0)
			{
				MaterialPropertyBlock mBlock = batchOutline.mBlock;
				mBlock.SetFloatArray("_MeshIdx", batchOutline.meshIdxs);
				mBlock.SetVectorArray("_MeshColor", batchOutline.meshColor);
				commandBuffer.DrawMeshInstanced(batchOutline.mesh, 0, batchClippingMaterial, 0, batchOutline.matrixs, batchOutline.count, mBlock);
				batchOutline.Reset();
			}
		}
	}

	private void OnEnable()
	{
	}

	private void OnDestroy()
	{
		if (renderTexture != null)
		{
			renderTexture.Release();
		}
		DestroyMaterials();
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		Graphics.Blit(source, destination, outlineShaderMaterial, 1);
	}

	private void CreateMaterialsIfNeeded()
	{
	}

	private void DestroyMaterials()
	{
		foreach (Material item in materialBuffer)
		{
			Object.DestroyImmediate(item);
		}
		materialBuffer.Clear();
	}

	public void UpdateMaterialsPublicProperties()
	{
		if ((bool)outlineShaderMaterial)
		{
			if (scaleWithScreenSize)
			{
				_ = (float)Screen.height / 360f;
			}
			outlineShaderMaterial.SetFloat("_LineThicknessMin", lineThicknessMin);
			outlineShaderMaterial.SetFloat("_LineThicknessMax", lineThicknessMax);
			outlineShaderMaterial.SetFloat("_LineIntensity", lineIntensity);
			outlineShaderMaterial.SetFloat("_FillAmount1", fillAmount1);
			outlineShaderMaterial.SetFloat("_FillAmount2", fillAmount2);
			outlineShaderMaterial.SetFloat("_FillAmount3", fillAmount3);
			outlineShaderMaterial.SetColor("_LineColor1", lineColor0 * lineColor0);
			outlineShaderMaterial.SetColor("_LineColor2", lineColor1 * lineColor1);
			outlineShaderMaterial.SetColor("_LineColor3", lineColor2 * lineColor2);
			new Plane(Vector3.up, Vector3.zero).Raycast(Cam.inst.GetRay(), out var enter);
			outlineShaderMaterial.SetFloat("_DistToGround", enter);
			if (!additiveRendering)
			{
				outlineShaderMaterial.SetInt("_Dark", 1);
			}
			else
			{
				outlineShaderMaterial.SetInt("_Dark", 0);
			}
			Shader.SetGlobalFloat("_OutlineAlphaCutoff", alphaCutoff);
		}
	}

	public void AddOutline(Outline outline)
	{
		if (!IsRegistered(outline))
		{
			outline.effectIndex = outlines.Count;
			outlines.Add(outline);
		}
	}

	public void RemoveOutline(Outline outline)
	{
		if (IsRegistered(outline))
		{
			int effectIndex = outline.effectIndex;
			int index = outlines.Count - 1;
			Outline outline2 = outlines[index];
			outlines[effectIndex] = outline2;
			outline2.effectIndex = effectIndex;
			outlines.RemoveAt(index);
			outline.effectIndex = -1;
		}
	}

	private bool IsRegistered(Outline outline)
	{
		int effectIndex = outline.effectIndex;
		if (effectIndex >= 0 && effectIndex < outlines.Count)
		{
			return outlines[effectIndex] == outline;
		}
		return false;
	}
}
