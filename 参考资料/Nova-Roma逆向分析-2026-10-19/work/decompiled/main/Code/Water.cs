using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace Code;

public class Water : MonoBehaviour
{
	public class NewDistanceFieldsEvent
	{
		public RenderTexture SDFTexture { get; }

		public NewDistanceFieldsEvent(RenderTexture sdfTexture)
		{
			SDFTexture = sdfTexture;
		}
	}

	public delegate void SampleEventHandler(object sender, NewDistanceFieldsEvent e);

	[BurstCompile]
	public struct BuildBeachParallelJob : IJobParallelFor
	{
		[ReadOnly]
		public NativeArray<Color> Input;

		public NativeArray<bool> IsBeachField;

		public int Width;

		public int MapIndexWorldToMesh(int worldIndex, int worldWidth)
		{
			int num = worldIndex % worldWidth;
			int num2 = worldIndex / worldWidth;
			int num3 = num * 2 + 1;
			return (num2 * 2 + 1) * (worldWidth * 2 + 1) + num3;
		}

		public void Execute(int ind)
		{
			bool flag = false;
			int num = MapIndexWorldToMesh(ind, Width);
			for (int i = -1; i <= 1; i++)
			{
				for (int j = -1; j <= 1; j++)
				{
					int num2 = num + (i + j * (Width * 2 + 1));
					if (num2 >= 0 && num2 < Input.Length)
					{
						flag |= Input[num2].r > 0.9f;
					}
				}
			}
			IsBeachField[ind] = flag;
		}
	}

	private JumpFloodRenderer jumpFloodRenderer = new JumpFloodRenderer();

	public static Water inst;

	public static bool UpdateNeeded;

	public CommandBuffer commandBuffer;

	public Texture2D distanceSDFTexture;

	public bool dynamicDistanceTextureFinished = true;

	public bool dynamicDistanceTextureCopied = true;

	public NativeArray<Color> distanceDynamicWaterTextureFromGPUAsyncData;

	public Texture2D distanceDynamicWaterTextureFinished;

	public Material horizontalSlicer;

	public Material yClip;

	public Material beachAlgorithm;

	public Texture2D beachTexture;

	public Camera OrthoCam;

	public static ArrayExt<MeshRenderer> MeshesInWater;

	public const int DistanceFieldResolution = 5;

	public Material JumpFloodMaterial;

	private int MaskBufferID = Shader.PropertyToID("_MaskBuffer");

	public RenderTexture distanceSDF;

	private bool Inited;

	public RenderTexture beachRT;

	public bool freeMoveWater;

	private int frame;

	private RenderTexture distanceDynamicWaterFieldRT;

	public int waitFrames;

	public event SampleEventHandler NewWaterDistanceField;

	private void Awake()
	{
		inst = this;
	}

	private void Init()
	{
		Inited = true;
		commandBuffer = new CommandBuffer();
		OrthoCam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, commandBuffer);
		OrthoCam.enabled = false;
		yClip.SetTexture("_WaterTexture1", DynamicWater.inst.waterHeightMap1);
		yClip.SetTexture("_WaterTexture2", DynamicWater.inst.waterHeightMap2);
		DynamicWater.inst.NewWaterHeightMap += OnNewWaterHeightMap;
	}

	private void OnNewWaterHeightMap(object sender, DynamicWater.NewWaterHeightMapEvent e)
	{
		yClip.SetTexture("_WaterTexture1", e.Texture1);
		yClip.SetTexture("_WaterTexture2", e.Texture2);
	}

	public void Update()
	{
		if (UpdateNeeded)
		{
			UpdateNeeded = false;
			UpdateCommandBuffer();
		}
		horizontalSlicer.SetFloat("_YSlice", transform.position.y);
		yClip.SetFloat("_YSlice", transform.position.y);
		yClip.SetTexture("_WaterTexture1", DynamicWater.inst.waterHeightMap1);
		yClip.SetTexture("_WaterTexture2", DynamicWater.inst.waterHeightMap2);
		Cam.inst.globalFog.waterHeight = transform.position.y;
	}

	public void MoveWaterForIntro()
	{
		freeMoveWater = true;
		transform.localPosition = new Vector3(-0.4661f, transform.position.y, -0.2339f);
	}

	public void UnMoveWaterForIntro()
	{
		freeMoveWater = false;
		transform.localPosition = new Vector3(0.5f, transform.position.y, 0.5f);
	}

	public void UpdateDistanceFields()
	{
		RenderDistanceFieldsGPU();
		WriteDistanceToTextureBlockingAndExpensive(ref distanceSDFTexture, distanceSDF, "DistanceSDF");
	}

	public void RenderDistanceFieldsGPU()
	{
		RenderTexture renderTexture = distanceSDF;
		RenderTexture dField = null;
		RenderTexture dField2 = null;
		RenderDistanceField(ref dField, water: true);
		RenderDistanceField(ref dField2, water: false);
		int width = dField.width;
		int height = dField.height;
		if (distanceSDF == null || distanceSDF.width != width || distanceSDF.height != height)
		{
			if (distanceSDF != null)
			{
				distanceSDF.Release();
				Object.Destroy(distanceSDF);
			}
			distanceSDF = new RenderTexture(width, height, 0, GraphicsFormat.R16G16B16A16_SFloat);
			distanceSDF.name = "DistanceSDF";
			distanceSDF.wrapMode = TextureWrapMode.Clamp;
			distanceSDF.Create();
		}
		JumpFloodMaterial.SetTexture("_SecondTex", dField2);
		Graphics.Blit(dField, distanceSDF, JumpFloodMaterial, 4);
		RenderTexture.ReleaseTemporary(dField);
		RenderTexture.ReleaseTemporary(dField2);
		if (distanceSDF != renderTexture)
		{
			GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_DistanceField", distanceSDF);
			NewWaterDistanceField?.Invoke(this, new NewDistanceFieldsEvent(distanceSDF));
		}
	}

	public void UpdateCommandBuffer()
	{
		UpdateDistanceFields();
		GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_DistanceField", distanceSDF);
		NewWaterDistanceField?.Invoke(this, new NewDistanceFieldsEvent(distanceSDF));
		if (beachTexture == null || beachTexture.width != World.MeshWidth || beachTexture.height != World.MeshHeight)
		{
			beachTexture = new Texture2D(World.MeshWidth, World.MeshHeight, TextureFormat.RGBAFloat, mipChain: false);
			beachTexture.name = "BeachTexture";
		}
		beachAlgorithm.SetTexture("_TerrainDistanceField", distanceSDF);
		beachAlgorithm.SetTexture("_TerrainHeightMap", TerrainGen.inst.terrainHeightMap);
		beachAlgorithm.SetTexture("_Perlin", Resources.Load<Texture2D>("perlin"));
		beachRT = RenderTexture.GetTemporary(World.MeshWidth, World.MeshHeight, 0, GraphicsFormat.R32_SFloat);
		Graphics.Blit(null, beachRT, beachAlgorithm);
		RenderTexture active = RenderTexture.active;
		RenderTexture.active = beachRT;
		beachTexture.ReadPixels(new Rect(0f, 0f, World.MeshWidth, World.MeshHeight), 0, 0);
		beachTexture.Apply();
		RenderTexture.active = active;
		RenderTexture.ReleaseTemporary(beachRT);
		bool[] array = new bool[World.inst.GridWidth * World.inst.GridHeight];
		NativeArray<bool> isBeachField = new NativeArray<bool>(World.inst.GridWidth * World.inst.GridHeight, Allocator.TempJob);
		IJobParallelForExtensions.Schedule(new BuildBeachParallelJob
		{
			Input = beachTexture.GetRawTextureData<Color>(),
			IsBeachField = isBeachField,
			Width = World.inst.GridWidth
		}, array.Length, 64).Complete();
		isBeachField.CopyTo(array);
		isBeachField.Dispose();
		int num = array.Length;
		for (int i = 0; i < num; i++)
		{
			int x = i % World.inst.GridWidth;
			int z = i / World.inst.GridWidth;
			if (!array[i])
			{
				continue;
			}
			if (MapEditorController.inst != null && MapEditorController.inst.IsOpen)
			{
				int num2 = World.inst.treeSystem.ItemAmount(i);
				int num3 = World.inst.bushesSystem.ItemAmount(i);
				int num4 = World.inst.grassSystem.ItemAmount(i);
				int num5 = World.inst.dryGrassSystem.ItemAmount(i);
				if (num2 + num3 + num4 + num5 > 0)
				{
					TerrainStrokeUndoEntry.RecordBeachDeletion(x, z, num2, num3, num4, num5);
				}
			}
			World.inst.dryGrassSystem.DeleteTreesAt(i);
			World.inst.grassSystem.DeleteTreesAt(i);
			World.inst.treeSystem.DeleteTreesAt(i);
			World.inst.bushesSystem.DeleteTreesAt(i);
		}
		Object.Destroy(beachTexture);
		beachTexture = null;
	}

	public void RenderDistanceField(ref RenderTexture dField, bool water, int resolution = 5)
	{
		if (!Inited)
		{
			Init();
		}
		if (dField != null)
		{
			RenderTexture.ReleaseTemporary(dField);
			dField = null;
		}
		dField = RenderTexture.GetTemporary(World.inst.GridWidth * resolution, World.inst.GridHeight * resolution, 32, GraphicsFormat.R32G32B32A32_SFloat);
		OrthoCam.targetTexture = dField;
		OrthoCam.depthTextureMode |= DepthTextureMode.Depth;
		float num = (float)World.inst.GridWidth / 2f;
		float num2 = (float)World.inst.GridHeight / 2f;
		OrthoCam.orthographicSize = num2;
		OrthoCam.aspect = num / num2;
		if (!freeMoveWater)
		{
			OrthoCam.transform.position = new Vector3(num, 30f, num2);
		}
		OrthoCam.transform.rotation = Quaternion.Euler(90f, 0f, 0f);
		OrthoCam.farClipPlane = 60f;
		commandBuffer.Clear();
		RenderTextureDescriptor desc = new RenderTextureDescriptor
		{
			dimension = TextureDimension.Tex2D,
			graphicsFormat = GraphicsFormat.R8_UNorm,
			width = dField.width,
			height = dField.height,
			msaaSamples = 1,
			depthStencilFormat = GraphicsFormat.D32_SFloat_S8_UInt,
			sRGB = false,
			useMipMap = false,
			autoGenerateMips = false
		};
		commandBuffer.GetTemporaryRT(MaskBufferID, desc);
		commandBuffer.SetRenderTarget(MaskBufferID);
		commandBuffer.ClearRenderTarget(clearDepth: true, clearColor: true, water ? Color.black : Color.white);
		yClip.SetColor("_ForegroundColor", water ? Color.white : Color.black);
		yClip.SetColor("_BackgroundColor", water ? Color.black : Color.white);
		horizontalSlicer.SetColor("_MainColor", water ? Color.white : new Color(0f, 0f, 0f, 1f));
		foreach (TerrainChunk terrainChunk in TerrainGen.inst.terrainChunks)
		{
			commandBuffer.DrawRenderer(terrainChunk.GetComponent<MeshRenderer>(), yClip, 0, 0);
		}
		if (MeshesInWater != null)
		{
			for (int i = 0; i < MeshesInWater.Count; i++)
			{
				MeshRenderer renderer = MeshesInWater.data[i];
				commandBuffer.DrawRenderer(renderer, horizontalSlicer);
			}
		}
		jumpFloodRenderer.AddJumpFloodingCommands(MaskBufferID, ref dField, ref commandBuffer);
		commandBuffer.ReleaseTemporaryRT(MaskBufferID);
		OrthoCam.Render();
	}

	private void WriteDistanceToTextureBlockingAndExpensive(ref Texture2D texture, RenderTexture rTarget, string textureName)
	{
		if (texture == null)
		{
			texture = new Texture2D(rTarget.width, rTarget.height, TextureFormat.RGBAHalf, mipChain: false);
			texture.name = textureName;
		}
		else if (texture.width != rTarget.width || texture.height != rTarget.height)
		{
			texture.Reinitialize(rTarget.width, rTarget.height);
		}
		RenderTexture active = RenderTexture.active;
		RenderTexture.active = rTarget;
		texture.ReadPixels(new Rect(0f, 0f, rTarget.width, rTarget.height), 0, 0);
		texture.Apply();
		RenderTexture.active = active;
	}

	private void WriteDistanceToTextureAsync(ref Texture2D finished, RenderTexture rTarget)
	{
		if (finished == null)
		{
			distanceDynamicWaterTextureFromGPUAsyncData = new NativeArray<Color>(rTarget.width * rTarget.height, Allocator.Persistent);
			finished = new Texture2D(rTarget.width, rTarget.height, TextureFormat.RGBAFloat, mipChain: false);
			finished.name = "DistanceDynamicWaterTexture";
		}
		else if (finished.width != rTarget.width || finished.height != rTarget.height)
		{
			finished.Reinitialize(rTarget.width, rTarget.height);
			if (distanceDynamicWaterTextureFromGPUAsyncData.IsCreated)
			{
				distanceDynamicWaterTextureFromGPUAsyncData.Dispose();
			}
			distanceDynamicWaterTextureFromGPUAsyncData = new NativeArray<Color>(rTarget.width * rTarget.height, Allocator.Persistent);
		}
		AsyncGPUReadback.Request(rTarget, 0, TextureFormat.RGBAFloat, WriteDistanceHasFinished);
	}

	private void WriteDistanceHasFinished(AsyncGPUReadbackRequest request)
	{
		if (request.hasError)
		{
			Debug.Log("GPU readback error detected.");
		}
		dynamicDistanceTextureFinished = true;
		if (!GameState.IsQuitting)
		{
			NativeArray<Color> data = request.GetData<Color>();
			IJobParallelForExtensions.Schedule(new TerrainGen.BurstTextureCopy
			{
				From = data,
				To = distanceDynamicWaterTextureFromGPUAsyncData
			}, data.Length, 64).Complete();
		}
		dynamicDistanceTextureCopied = false;
		RenderTexture.ReleaseTemporary(distanceDynamicWaterFieldRT);
	}

	public void RenderDynamicWaterDistanceField(Texture2D waterTex, bool blocking = false)
	{
		if (!Inited)
		{
			Init();
		}
		if (blocking)
		{
			AsyncGPUReadback.WaitAllRequests();
			dynamicDistanceTextureFinished = true;
			dynamicDistanceTextureCopied = true;
			waitFrames = 0;
		}
		if (dynamicDistanceTextureFinished && dynamicDistanceTextureCopied && waitFrames-- <= 0)
		{
			dynamicDistanceTextureFinished = false;
			_ = RenderTexture.active;
			distanceDynamicWaterFieldRT = RenderTexture.GetTemporary(World.inst.GridWidth, World.inst.GridHeight, 0, GraphicsFormat.R32G32B32A32_SFloat);
			RenderTexture temporary = RenderTexture.GetTemporary(new RenderTextureDescriptor
			{
				dimension = TextureDimension.Tex2D,
				graphicsFormat = GraphicsFormat.R8_UNorm,
				width = distanceDynamicWaterFieldRT.width,
				height = distanceDynamicWaterFieldRT.height,
				msaaSamples = 1,
				depthBufferBits = 0,
				sRGB = false,
				volumeDepth = 1,
				useMipMap = false,
				autoGenerateMips = false
			});
			Graphics.Blit(waterTex, temporary);
			jumpFloodRenderer.JumpFloodImmediate(temporary, ref distanceDynamicWaterFieldRT);
			WriteDistanceToTextureAsync(ref distanceDynamicWaterTextureFinished, distanceDynamicWaterFieldRT);
			RenderTexture.ReleaseTemporary(temporary);
			if (blocking)
			{
				AsyncGPUReadback.WaitAllRequests();
				PublishDynamicDistanceField();
			}
		}
	}

	public void PublishDynamicDistanceField()
	{
		if (dynamicDistanceTextureFinished && !dynamicDistanceTextureCopied)
		{
			TerrainGen.inst.CompleteTerritoryTextureJob();
			IJobParallelForExtensions.Schedule(new TerrainGen.BurstTextureCopy
			{
				From = distanceDynamicWaterTextureFromGPUAsyncData,
				To = distanceDynamicWaterTextureFinished.GetRawTextureData<Color>()
			}, distanceDynamicWaterTextureFromGPUAsyncData.Length, 64).Complete();
			dynamicDistanceTextureCopied = true;
			waitFrames = 10;
		}
	}

	private void OnDestroy()
	{
		if (distanceDynamicWaterTextureFromGPUAsyncData.IsCreated)
		{
			distanceDynamicWaterTextureFromGPUAsyncData.Dispose();
		}
	}

	public static void AddDisplacementMesh(MeshRenderer getComponent)
	{
		if (MeshesInWater == null)
		{
			MeshesInWater = new ArrayExt<MeshRenderer>(20);
		}
		MeshesInWater.Add(getComponent);
		UpdateNeeded = true;
	}

	public static void RemoveDisplacementMesh(MeshRenderer getComponent)
	{
		if (MeshesInWater != null)
		{
			MeshesInWater.RemoveSwap(getComponent);
			UpdateNeeded = true;
		}
	}
}
