using System;
using Assets;
using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;

public class CloudSystem : MonoBehaviour
{
	public struct CloudData
	{
		public float frequency;

		public float scale;

		public float camTouchTime;

		public float localX;

		public float localZ;
	}

	[BurstCompile]
	public struct UpdateClouds : IJob
	{
		public NativeArray<float4x4> matrices;

		public NativeArray<CloudData> data;

		public float dt;

		public float unscaledDt;

		public float totalTime;

		public int width;

		public int height;

		public float ScaleInSpeed;

		public float ScaleOutSpeed;

		public float threshold1;

		public float stormThreshold1;

		public float threshold2;

		public float size2;

		public float stormSize2;

		public float threshold3;

		public float size3;

		public float BaseFreq;

		public float FreqChaos;

		public float MaskFrequencyDiv;

		public float stormScaleSpeed;

		public float stormAlpha;

		public float3 camPos;

		public float3 mousePos;

		public float3 selectedObjPos;

		public float camFadeRadius;

		public float resolutionDivision;

		public float cloudHeight;

		private int index(int x, int z)
		{
			return z * width + x;
		}

		public void Execute()
		{
			float num = dt * 0.35f;
			float num2 = 0.6f;
			float num3 = 2f;
			float num4 = Mathf.Lerp(1f, stormScaleSpeed, stormAlpha);
			float num5 = dt * ScaleOutSpeed * num4;
			float num6 = dt * ScaleInSpeed * num4;
			float num7 = totalTime * 0.5f;
			float num8 = totalTime;
			float num9 = BaseFreq + stormAlpha * 1f;
			float num10 = Mathf.Lerp(threshold1, stormThreshold1, stormAlpha);
			for (int i = 0; i < height; i++)
			{
				float num11 = (float)i / (float)height;
				for (int j = 0; j < width; j++)
				{
					int num12 = index(j, i);
					CloudData value = data[num12];
					float num13 = num9 + value.frequency * FreqChaos;
					float num14 = (float)j / (float)width;
					float num15 = Mathf.PerlinNoise(num7 + num11 * num13 / MaskFrequencyDiv, num8 + num14 * num13 / MaskFrequencyDiv);
					float num16 = 0f;
					if (num15 > 0.5f)
					{
						float num17 = Mathf.PerlinNoise(num7 + num11 * num13, num8 + num14 * num13);
						if (num17 > num10)
						{
							num16 = num3 * num17;
							if (num17 > threshold2)
							{
								num16 = num3 * size2 * num17;
							}
							if (num17 > threshold3)
							{
								num16 = num3 * size3 * num17;
							}
							num16 += value.frequency;
						}
					}
					if (totalTime - value.camTouchTime < 0.1f)
					{
						num16 = 0f;
					}
					if (value.scale > num16)
					{
						value.scale -= num5;
						value.scale = Mathf.Max(num16, value.scale);
					}
					else
					{
						value.scale += num6;
						value.scale = Mathf.Min(num16, value.scale);
					}
					float num18 = 0f;
					float num19 = 0f;
					if (value.scale > 0.001f && value.scale < 1.25f)
					{
						float num20 = 0f;
						float num21 = 0f;
						float scale = value.scale;
						int num22 = -1;
						for (int k = -1; k < 2; k++)
						{
							for (int l = -1; l < 2; l++)
							{
								int num23 = index(k + j, l + i);
								if (num23 > 0 && num23 < width * height && data[num23].scale > scale)
								{
									num22 = num23;
									scale = data[num23].scale;
									num20 = k + j;
									num21 = l + i;
								}
							}
						}
						if (num22 != -1)
						{
							num18 = num20 - (float)j;
							num19 = num21 - (float)i;
						}
					}
					value.localX += (num18 - value.localX) * num;
					value.localZ += (num19 - value.localZ) * num;
					if (value.localX > num2)
					{
						value.localX = num2;
					}
					if (value.localX < 0f - num2)
					{
						value.localX = 0f - num2;
					}
					if (value.localZ > num2)
					{
						value.localZ = num2;
					}
					if (value.localZ < 0f - num2)
					{
						value.localZ = 0f - num2;
					}
					data[num12] = value;
					float num24 = (float)j + 0.5f + value.localX;
					float num25 = (float)i + 0.5f + value.localZ;
					float num26 = value.scale * resolutionDivision;
					float y = cloudHeight + num26 * 0.5f;
					matrices[num12] = float4x4.TRS(new float3(num24 * resolutionDivision, y, num25 * resolutionDivision), quaternion.Euler(matrices[num12].c3.x / 5f + totalTime * 3f, matrices[num12].c3.x / 5f + totalTime * 3f + value.frequency * 180f, matrices[num12].c3.z / 5f + totalTime * 3f), new float3(num26, num26, num26));
				}
			}
			PunchHoleAndRadius(camPos, camFadeRadius, unscaledDt * ScaleOutSpeed * num4);
			PunchHoleAndRadius(mousePos, Mathf.Max(3f, camFadeRadius * 0.65f), unscaledDt * ScaleOutSpeed * num4 * 3f);
			PunchHoleAndRadius(selectedObjPos, Mathf.Max(3f, camFadeRadius * 0.4f), unscaledDt * ScaleOutSpeed * num4);
		}

		private void PunchHoleAndRadius(float3 pos, float radius, float scaleOutDt)
		{
			pos.x /= resolutionDivision;
			pos.z /= resolutionDivision;
			radius /= resolutionDivision;
			int num = Mathf.Clamp((int)(pos.x - radius), 0, width);
			int num2 = Mathf.Clamp((int)(pos.z - radius), 0, height);
			int num3 = Mathf.Clamp((int)(pos.x + radius), 0, width);
			int num4 = Mathf.Clamp((int)(pos.z + radius), 0, height);
			float num5 = radius * radius;
			for (int i = num2; i < num4; i++)
			{
				for (int j = num; j < num3; j++)
				{
					if (Mathff.DistSqrdXZ(pos, new float3((float)j + 0.5f, 0f, (float)i + 0.5f)) <= num5)
					{
						int num6 = index(j, i);
						CloudData value = data[num6];
						value.camTouchTime = totalTime;
						if (value.scale > 0f)
						{
							value.scale -= scaleOutDt * 9f;
							value.scale = Mathf.Max(0f, value.scale);
						}
						data[num6] = value;
					}
				}
			}
		}
	}

	private static readonly int StormAlphaID = Shader.PropertyToID("_StormAlpha");

	private static readonly int TreeWindPhaseTimeID = Shader.PropertyToID("_TreeWindPhaseTime");

	private static readonly int TreeWindStrengthID = Shader.PropertyToID("_TreeWindStrength");

	private const float UnityShaderTimeScale = 0.05f;

	private NativeArray<CloudData> cloudData;

	private NativeArray<float4x4> matrices;

	private int width;

	private int height;

	private bool initied;

	public static CloudSystem inst;

	public AnimationCurve CamFadeRadiusToCamZoomDist;

	[Range(0f, 1f)]
	public float threshold1 = 0.5f;

	[Range(0f, 1f)]
	public float stormThreshold1 = 0.2f;

	[Range(0f, 1f)]
	public float threshold2 = 0.625f;

	public float size2 = 2f;

	public float stormSize2 = 3f;

	[Range(0f, 1f)]
	public float threshold3 = 0.9f;

	public float size3 = 4f;

	public float BaseFreq = 6f;

	[Range(0f, 1f)]
	public float FreqChaos = 0.3f;

	public float MaskFrequencyDiv = 2f;

	public float stormScaleSpeed = 1.5f;

	public float cloudHeight = 12f;

	private DateTime LastTime;

	private int frameCheck;

	private float totalTime;

	public float timeScale = 0.4f;

	public Color CloudColor;

	public Color CloudEmission;

	public Color RainCloudColor;

	public Color RainCloudEmission;

	public float stormAlpha;

	public float resolutionDivision = 1f;

	public float planeOffset = 0.5f;

	public FogAndLightingStack.FogAndLighting weatherSettings;

	private float camFadeRadius = 10f;

	private float locX;

	private float locZ;

	private bool scheduled;

	private JobHandle cloudJob;

	private Vector3 camPos;

	private Vector3 mousePos;

	private Vector3 selectedObjPos;

	public float ScaleInSpeed = 4f;

	public float ScaleOutSpeed = 4f;

	public Mesh mesh;

	public Material materialPrefab;

	private Material material;

	private uint[] args;

	internal ComputeBuffer computeBuffer;

	internal ComputeBuffer computeArgs;

	public void Reset()
	{
		initied = true;
		Dispose();
		width = (int)((float)World.inst.GridWidth / resolutionDivision);
		height = (int)((float)World.inst.GridHeight / resolutionDivision);
		cloudData = new NativeArray<CloudData>(width * height, Allocator.Persistent);
		matrices = new NativeArray<float4x4>(width * height, Allocator.Persistent);
		for (int i = 0; i < height; i++)
		{
			for (int j = 0; j < width; j++)
			{
				matrices[i * width + j] = float4x4.TRS(new float3((float)j + 0.5f, cloudHeight, (float)i + 0.5f), quaternion.Euler(SRand.Range(0, 180), SRand.Range(0, 180), SRand.Range(0, 180)), new float3(1f, 1f, 1f));
				CloudData value = cloudData[i * width + j];
				value.frequency = SRand.value;
				value.scale = 0f;
				value.localX = 0.5f;
				value.localZ = 0.5f;
				value.camTouchTime = -10f;
				cloudData[i * width + j] = value;
			}
		}
		if (!(materialPrefab == null))
		{
			computeBuffer = new ComputeBuffer(matrices.Length, 64);
			ComputeBufferNaming.SetName(computeBuffer, "CloudSystem_MatrixBuffer");
			computeBuffer.SetData(matrices);
			material = UnityEngine.Object.Instantiate(materialPrefab);
			material.SetBuffer("matrixBuffer", computeBuffer);
			args = new uint[5];
			args[0] = ((mesh != null) ? mesh.GetIndexCount(0) : 0u);
			args[1] = (uint)matrices.Length;
			args[2] = ((mesh != null) ? mesh.GetIndexStart(0) : 0u);
			args[3] = ((mesh != null) ? mesh.GetBaseVertex(0) : 0u);
			args[4] = 0u;
			computeArgs = new ComputeBuffer(1, args.Length * 4, ComputeBufferType.DrawIndirect);
			ComputeBufferNaming.SetName(computeArgs, "CloudSystem_ArgsBuffer");
			computeArgs.SetData(args);
			totalTime += 60.000004f * timeScale;
			UpdateClouds jobData = new UpdateClouds
			{
				matrices = matrices,
				data = cloudData,
				dt = 60.000004f,
				unscaledDt = Time.unscaledDeltaTime,
				totalTime = totalTime,
				width = width,
				height = height,
				ScaleInSpeed = ScaleInSpeed,
				ScaleOutSpeed = ScaleOutSpeed,
				threshold1 = threshold1,
				stormThreshold1 = stormThreshold1,
				threshold2 = threshold2,
				size2 = size2,
				stormSize2 = stormSize2,
				threshold3 = threshold3,
				size3 = size3,
				BaseFreq = BaseFreq,
				FreqChaos = FreqChaos,
				MaskFrequencyDiv = MaskFrequencyDiv,
				stormScaleSpeed = stormScaleSpeed,
				stormAlpha = stormAlpha,
				camPos = camPos,
				mousePos = mousePos,
				selectedObjPos = selectedObjPos,
				camFadeRadius = camFadeRadius,
				resolutionDivision = resolutionDivision,
				cloudHeight = cloudHeight
			};
			cloudJob = jobData.Schedule();
			cloudJob.Complete();
		}
	}

	private void Start()
	{
		inst = this;
	}

	private Plane GetCloudPlane()
	{
		return new Plane(new Vector3(0f, 1f, 0f), transform.position + new Vector3(0f, cloudHeight + planeOffset, 0f));
	}

	private void Update()
	{
		if (!initied)
		{
			return;
		}
		if (!Settings.inst.ShowClouds)
		{
			if (scheduled)
			{
				cloudJob.Complete();
				scheduled = false;
			}
			return;
		}
		locX = transform.position.x;
		locZ = transform.position.z;
		Shader.SetGlobalColor("_StormCloudColor", RainCloudColor);
		Shader.SetGlobalColor("_StormCloudEmission", RainCloudEmission);
		Shader.SetGlobalColor("_CloudColor", CloudColor);
		Shader.SetGlobalColor("_CloudEmission", CloudEmission);
		Shader.SetGlobalFloat(StormAlphaID, stormAlpha);
		float num = Time.time * 0.05f;
		Shader.SetGlobalFloat(TreeWindPhaseTimeID, num * Mathf.Lerp(50f, 75f, stormAlpha));
		Shader.SetGlobalFloat(TreeWindStrengthID, Mathf.Lerp(0.02f, 0.05f, stormAlpha));
		float num2 = Time.deltaTime * timeScale;
		totalTime += num2;
		Plane cloudPlane = GetCloudPlane();
		Ray ray = new Ray(Cam.inst.transform.position, Cam.inst.GetDirection());
		cloudPlane.Raycast(ray, out var enter);
		camPos = ray.GetPoint(enter);
		Ray ray2 = PointingSystem.GetRay();
		cloudPlane.Raycast(ray2, out var enter2);
		mousePos = ray2.GetPoint(enter2);
		if (GameUI.inst.GetCellSelected() != null)
		{
			Ray ray3 = new Ray(GameUI.inst.GetCellSelected().Center2D, (Cam.inst.transform.position - GameUI.inst.GetCellSelected().Center2D).normalized);
			cloudPlane.Raycast(ray3, out var enter3);
			selectedObjPos = ray3.GetPoint(enter3);
		}
		Vector3 zero = Vector3.zero;
		Ray ray4 = Cam.inst.cam.ViewportPointToRay(new Vector3(0.5f, 0.15f));
		cloudPlane.Raycast(ray4, out var enter4);
		zero = ray4.GetPoint(enter4);
		ray4 = Cam.inst.cam.ViewportPointToRay(new Vector3(0.15f, 0.05f));
		cloudPlane.Raycast(ray4, out enter4);
		Vector3 point = ray4.GetPoint(enter4);
		camFadeRadius = Mathff.Max(Mathff.Dist(camPos, zero), Mathff.Dist(camPos, point));
		if (camFadeRadius > 60f)
		{
			camFadeRadius = 60f;
		}
		if (camFadeRadius < 15f)
		{
			camFadeRadius = 15f;
		}
		if (scheduled)
		{
			cloudJob.Complete();
			DrawMeshes();
		}
		UpdateClouds jobData = new UpdateClouds
		{
			matrices = matrices,
			data = cloudData,
			dt = Time.deltaTime,
			unscaledDt = Time.unscaledDeltaTime,
			totalTime = totalTime,
			width = width,
			height = height,
			ScaleInSpeed = ScaleInSpeed,
			ScaleOutSpeed = ScaleOutSpeed,
			threshold1 = threshold1,
			stormThreshold1 = stormThreshold1,
			threshold2 = threshold2,
			size2 = size2,
			stormSize2 = stormSize2,
			threshold3 = threshold3,
			size3 = size3,
			BaseFreq = BaseFreq,
			FreqChaos = FreqChaos,
			MaskFrequencyDiv = MaskFrequencyDiv,
			stormScaleSpeed = stormScaleSpeed,
			stormAlpha = stormAlpha,
			camPos = camPos,
			mousePos = mousePos,
			selectedObjPos = selectedObjPos,
			camFadeRadius = camFadeRadius,
			resolutionDivision = resolutionDivision,
			cloudHeight = cloudHeight
		};
		cloudJob = jobData.Schedule();
		scheduled = true;
	}

	private void OnDestroy()
	{
		Dispose();
	}

	internal void Dispose()
	{
		if (cloudJob.IsCompleted)
		{
			cloudJob.Complete();
		}
		if (matrices.IsCreated)
		{
			matrices.Dispose();
		}
		if (computeBuffer != null)
		{
			computeBuffer.Dispose();
			computeBuffer = null;
		}
		if (computeArgs != null)
		{
			computeArgs.Dispose();
			computeArgs = null;
		}
		if (material != null)
		{
			UnityEngine.Object.Destroy(material);
			material = null;
		}
		if (cloudData.IsCreated)
		{
			cloudData.Dispose();
		}
	}

	public void DrawMeshes()
	{
		if (!(material == null))
		{
			computeBuffer.SetData(matrices);
			args[1] = (uint)matrices.Length;
			computeArgs.SetData(args);
			Graphics.DrawMeshInstancedIndirect(bounds: new Bounds(new Vector3(0f, 0f, 0f), new Vector3(500f, 500f, 500f)), mesh: mesh, submeshIndex: 0, material: material, bufferWithArgs: computeArgs, argsOffset: 0, properties: null, castShadows: ShadowCastingMode.On, receiveShadows: false);
		}
	}
}
