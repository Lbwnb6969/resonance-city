using System;
using System.Collections.Generic;
using FMOD.Studio;
using FMODUnity;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;

public class BespokeCelebratingCitizens : MonoBehaviour
{
	[Serializable]
	public struct Group
	{
		[NonSerialized]
		public NativeArray<ChariotRaceTrack.FanEntry> entries;

		[NonSerialized]
		public NativeArray<float4> headColors;

		[NonSerialized]
		public NativeArray<float4> hairColors;

		[NonSerialized]
		public NativeArray<float4> bodyColors;

		[NonSerialized]
		public ComputeBuffer headBuffer;

		[NonSerialized]
		public ComputeBuffer hairBuffer;

		[NonSerialized]
		public ComputeBuffer bodyBuffer;

		[NonSerialized]
		public NativeArray<float4x4> matrixes;

		[NonSerialized]
		public ComputeBuffer matrixBuffer;

		[NonSerialized]
		public uint[] args;

		[NonSerialized]
		public ComputeBuffer argsBuffer;

		[NonSerialized]
		public Material mat;

		public Mesh mesh;

		[NonSerialized]
		public int count;
	}

	public struct UpdateGroupAnimations : IJobParallelFor
	{
		public NativeArray<float4x4> matrixes;

		public NativeArray<ChariotRaceTrack.FanEntry> entries;

		[ReadOnly]
		public float udt;

		[ReadOnly]
		public float jumpHeight;

		[ReadOnly]
		public float jumpSpeed;

		[ReadOnly]
		public Matrix4x4 offsetMatrix;

		[ReadOnly]
		public uint seed;

		public void Execute(int index)
		{
			ChariotRaceTrack.FanEntry value = entries[index];
			value.jumpTime -= udt;
			if (value.jumpTime <= 0f)
			{
				value.animTime += udt * jumpSpeed;
				value.pos.x = value.origPos.x;
				value.pos.z = value.origPos.z;
				value.pos.y = value.origPos.y + Mathf.PingPong(value.animTime, 0.5f) * jumpHeight;
				if (value.animTime >= 1f)
				{
					value.jumpTime = Unity.Mathematics.Random.CreateFromIndex(seed + (uint)index).NextFloat(1f, 7f);
					value.animTime = 0f;
				}
			}
			Vector3 vector = offsetMatrix.MultiplyPoint3x4(value.pos);
			Quaternion quaternion2 = Quaternion.Euler(offsetMatrix.MultiplyVector(value.dir));
			matrixes[index] = float4x4.TRS(vector, quaternion2, Vector3.one);
			entries[index] = value;
		}
	}

	public static BespokeCelebratingCitizens inst;

	public List<Group> groups;

	public Material materialPrefab;

	private static Bounds bounds = new Bounds(new Vector3(0f, 0f, 0f), new Vector3(500f, 500f, 500f));

	private Unity.Mathematics.Random rand;

	private float4x4 localToWorldMatrix;

	private int totalCount;

	private bool isActive;

	private Building targetB;

	private EventInstance eCrowdAmb;

	public bool IsActive()
	{
		return isActive;
	}

	private void Awake()
	{
		inst = this;
	}

	public void Init(Building b)
	{
		if (b == null)
		{
			return;
		}
		targetB = b;
		isActive = true;
		if (eCrowdAmb.isValid())
		{
			eCrowdAmb.stop(STOP_MODE.IMMEDIATE);
		}
		eCrowdAmb = RuntimeManager.CreateInstance("event:/SFX ASITP/Ambiences/ambBed_crowd_stadium");
		eCrowdAmb.set3DAttributes(b.Center().To3DAttributes());
		eCrowdAmb.start();
		eCrowdAmb.release();
		rand.InitState((uint)World.inst.seed);
		for (int i = 0; i < groups.Count; i++)
		{
			Group value = groups[i];
			if (i == 0)
			{
				value.count = targetB.attractionPositions.Length / 2 + targetB.attractionPositions.Length % 2;
			}
			else
			{
				value.count = targetB.attractionPositions.Length / 2;
			}
			if (!value.entries.IsCreated || value.entries.Length != value.count)
			{
				if (value.entries.IsCreated)
				{
					value.entries.Dispose();
				}
				value.entries = new NativeArray<ChariotRaceTrack.FanEntry>(value.count, Allocator.Persistent);
			}
			for (int j = 0; j < targetB.attractionPositions.Length; j++)
			{
				if ((i != 0 || j % 2 == 0) && (i != 1 || j % 2 == 1))
				{
					int num = j / 2;
					if (num < value.count)
					{
						ChariotRaceTrack.FanEntry value2 = value.entries[num];
						value2.jumpTime = SRand.Range(1f, 5f);
						value2.animTime = 0f;
						Transform transform = targetB.attractionPositions[j];
						value2.origPos = transform.localPosition;
						value2.pos = value2.origPos;
						value2.dir = transform.eulerAngles;
						value.entries[num] = value2;
					}
				}
			}
			if (!value.headColors.IsCreated || value.headColors.Length != value.count)
			{
				if (value.headColors.IsCreated)
				{
					value.headColors.Dispose();
				}
				value.headColors = new NativeArray<float4>(value.count, Allocator.Persistent);
			}
			if (!value.hairColors.IsCreated || value.hairColors.Length != value.count)
			{
				if (value.hairColors.IsCreated)
				{
					value.hairColors.Dispose();
				}
				value.hairColors = new NativeArray<float4>(value.count, Allocator.Persistent);
			}
			if (!value.bodyColors.IsCreated || value.bodyColors.Length != value.count)
			{
				if (value.bodyColors.IsCreated)
				{
					value.bodyColors.Dispose();
				}
				value.bodyColors = new NativeArray<float4>(value.count, Allocator.Persistent);
			}
			for (int k = 0; k < value.count; k++)
			{
				Color color = VillagerSystem.inst.headColors[SRand.Range(0, VillagerSystem.inst.headColors.Length)];
				Color color2 = VillagerSystem.inst.hairColors[SRand.Range(0, VillagerSystem.inst.hairColors.Length)];
				Color color3 = VillagerSystem.inst.bodyColors[SRand.Range(0, VillagerSystem.inst.bodyColors.Length)];
				value.headColors[k] = new float4(color.r, color.g, color.b, color.a);
				value.hairColors[k] = new float4(color2.r, color2.g, color2.b, color2.a);
				value.bodyColors[k] = new float4(color3.r, color3.g, color3.b, color3.a);
			}
			if (value.headBuffer == null || value.headBuffer.count != value.count)
			{
				if (value.headBuffer != null)
				{
					value.headBuffer.Dispose();
				}
				value.headBuffer = new ComputeBuffer(value.count, 16);
				ComputeBufferNaming.SetName(value.headBuffer, $"BespokeCelebratingCitizens_Group{i}_HeadBuffer");
			}
			value.headBuffer.SetData(value.headColors);
			if (value.hairBuffer == null || value.hairBuffer.count != value.count)
			{
				if (value.hairBuffer != null)
				{
					value.hairBuffer.Dispose();
				}
				value.hairBuffer = new ComputeBuffer(value.count, 16);
				ComputeBufferNaming.SetName(value.hairBuffer, $"BespokeCelebratingCitizens_Group{i}_HairBuffer");
			}
			value.hairBuffer.SetData(value.hairColors);
			if (value.bodyBuffer == null || value.bodyBuffer.count != value.count)
			{
				if (value.bodyBuffer != null)
				{
					value.bodyBuffer.Dispose();
				}
				value.bodyBuffer = new ComputeBuffer(value.count, 16);
				ComputeBufferNaming.SetName(value.bodyBuffer, $"BespokeCelebratingCitizens_Group{i}_BodyBuffer");
			}
			value.bodyBuffer.SetData(value.bodyColors);
			if (!value.matrixes.IsCreated || value.matrixes.Length != value.count)
			{
				if (value.matrixes.IsCreated)
				{
					value.matrixes.Dispose();
				}
				value.matrixes = new NativeArray<float4x4>(value.count, Allocator.Persistent);
			}
			if (value.matrixBuffer == null || value.matrixBuffer.count != value.count)
			{
				if (value.matrixBuffer != null)
				{
					value.matrixBuffer.Dispose();
				}
				value.matrixBuffer = new ComputeBuffer(value.count, 64);
				ComputeBufferNaming.SetName(value.matrixBuffer, $"BespokeCelebratingCitizens_Group{i}_MatrixBuffer");
			}
			value.matrixBuffer.SetData(value.matrixes);
			if (value.mat == null)
			{
				value.mat = UnityEngine.Object.Instantiate(materialPrefab);
			}
			value.mat.SetBuffer("matrixBuffer", value.matrixBuffer);
			value.mat.SetBuffer("headBuffer", value.headBuffer);
			value.mat.SetBuffer("group.hairBuffer", value.hairBuffer);
			value.mat.SetBuffer("bodyBuffer", value.bodyBuffer);
			if (value.args == null)
			{
				value.args = new uint[5];
			}
			value.args[0] = ((value.mesh != null) ? value.mesh.GetIndexCount(0) : 0u);
			value.args[1] = (uint)value.matrixes.Length;
			value.args[2] = ((value.mesh != null) ? value.mesh.GetIndexStart(0) : 0u);
			value.args[3] = ((value.mesh != null) ? value.mesh.GetBaseVertex(0) : 0u);
			value.args[4] = 0u;
			if (value.argsBuffer == null)
			{
				value.argsBuffer = new ComputeBuffer(1, value.args.Length * 4, ComputeBufferType.DrawIndirect);
				ComputeBufferNaming.SetName(value.argsBuffer, $"BespokeCelebratingCitizens_Group{i}_ArgsBuffer");
			}
			value.argsBuffer.SetData(value.args);
			groups[i] = value;
		}
	}

	public void Shutdown()
	{
		isActive = false;
		if (eCrowdAmb.isValid())
		{
			eCrowdAmb.stop(STOP_MODE.IMMEDIATE);
		}
		for (int i = 0; i < groups.Count; i++)
		{
			Group value = groups[i];
			if (value.matrixes.IsCreated)
			{
				value.matrixes.Dispose();
			}
			if (value.matrixBuffer != null)
			{
				value.matrixBuffer.Dispose();
				value.matrixBuffer = null;
			}
			if (value.argsBuffer != null)
			{
				value.argsBuffer.Dispose();
				value.argsBuffer = null;
			}
			if (value.entries.IsCreated)
			{
				value.entries.Dispose();
			}
			if (value.headColors.IsCreated)
			{
				value.headColors.Dispose();
			}
			if (value.hairColors.IsCreated)
			{
				value.hairColors.Dispose();
			}
			if (value.bodyColors.IsCreated)
			{
				value.bodyColors.Dispose();
			}
			if (value.headBuffer != null)
			{
				value.headBuffer.Dispose();
				value.headBuffer = null;
			}
			if (value.hairBuffer != null)
			{
				value.hairBuffer.Dispose();
				value.hairBuffer = null;
			}
			if (value.bodyBuffer != null)
			{
				value.bodyBuffer.Dispose();
				value.bodyBuffer = null;
			}
			groups[i] = value;
		}
	}

	private void LateUpdate()
	{
		if (isActive)
		{
			for (int i = 0; i < groups.Count; i++)
			{
				IJobParallelForExtensions.Schedule(new UpdateGroupAnimations
				{
					matrixes = groups[i].matrixes,
					entries = groups[i].entries,
					udt = Time.unscaledDeltaTime,
					jumpHeight = 0.3f,
					jumpSpeed = 2f,
					offsetMatrix = targetB.GetOffset().localToWorldMatrix,
					seed = rand.NextUInt()
				}, groups[i].count, 0).Complete();
				groups[i].matrixBuffer.SetData(groups[i].matrixes, 0, 0, groups[i].count);
				Graphics.DrawMeshInstancedIndirect(groups[i].mesh, 0, groups[i].mat, bounds, groups[i].argsBuffer);
			}
		}
	}
}
