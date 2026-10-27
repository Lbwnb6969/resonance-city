using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;

public class FieldSystem
{
	public class Owner
	{
		public int s;

		public int idx;
	}

	public struct FieldData
	{
		public Vector3 pos;

		public Quaternion rot;
	}

	[BurstCompile]
	public struct UpdateFields : IJob
	{
		[ReadOnly]
		public NativeArray<FieldData> fieldData;

		[ReadOnly]
		public NativeArray<float> timeData;

		[ReadOnly]
		public Vector3 scaleMod;

		[ReadOnly]
		public int count;

		[ReadOnly]
		public int chunkSize;

		[WriteOnly]
		public NativeArray<float4x4> matrix;

		public void Execute()
		{
			Vector3 vector = default;
			for (int i = 0; i < count; i++)
			{
				FieldData fieldData = this.fieldData[i];
				if (i % chunkSize == 0)
				{
					float num = timeData[i];
					vector = new Vector3(Mathff.Max(scaleMod.x, 1E-05f), Mathff.Max(scaleMod.y * num, 1E-05f), Mathff.Max(scaleMod.z * num, 1E-05f));
				}
				matrix[i] = float4x4.TRS(fieldData.pos, fieldData.rot, vector);
			}
		}
	}

	[BurstCompile]
	public struct UpdateFruits : IJob
	{
		[ReadOnly]
		public NativeArray<FieldData> fieldData;

		[ReadOnly]
		public NativeArray<float> timeData;

		[ReadOnly]
		public Vector3 scaleMod;

		[ReadOnly]
		public int count;

		[ReadOnly]
		public int chunkSize;

		[WriteOnly]
		public NativeArray<float4x4> matrix;

		public void Execute()
		{
			Vector3 vector = default;
			for (int i = 0; i < count; i++)
			{
				FieldData fieldData = this.fieldData[i];
				if (i % chunkSize == 0)
				{
					float num = timeData[i];
					vector = new Vector3(scaleMod.x * num, scaleMod.y * num, scaleMod.z * num);
				}
				matrix[i] = float4x4.TRS(fieldData.pos, fieldData.rot, vector);
			}
		}
	}

	private int count;

	private const int siloSize = 10000;

	public int chunkSize = 4;

	public int type;

	public const int TYPE_FIELD = 0;

	public const int TYPE_FRUIT = 1;

	public Vector3 scaleMod = Vector3.one;

	public Material material;

	public Mesh mesh;

	public string debugName;

	private ArrayExt<Owner[]> owners;

	private ArrayExt<NativeArray<FieldData>> fieldData;

	private ArrayExt<NativeArray<float>> timeData;

	private ArrayExt<NativeArray<float4x4>> siloMatrix;

	private ArrayExt<ComputeBuffer> computeBuffers;

	private ArrayExt<ComputeBuffer> computeArgs;

	private ArrayExt<Material> materials;

	private ArrayExt<uint[]> arguments;

	private bool isShutdown;

	private Bounds bounds = new Bounds(new Vector3(0f, 0f, 0f), new Vector3(500f, 500f, 500f));

	private int added;

	private bool adding;

	public void Init()
	{
		siloMatrix = new ArrayExt<NativeArray<float4x4>>(5);
		owners = new ArrayExt<Owner[]>(5);
		fieldData = new ArrayExt<NativeArray<FieldData>>(5);
		timeData = new ArrayExt<NativeArray<float>>(5);
		computeBuffers = new ArrayExt<ComputeBuffer>(5);
		computeArgs = new ArrayExt<ComputeBuffer>(5);
		materials = new ArrayExt<Material>(5);
		arguments = new ArrayExt<uint[]>(5);
		AddBucket();
	}

	public void Shutdown()
	{
		isShutdown = true;
		for (int i = 0; i < siloMatrix.Count; i++)
		{
			if (siloMatrix.data[i].IsCreated)
			{
				siloMatrix.data[i].Dispose();
			}
			if (fieldData.data[i].IsCreated)
			{
				fieldData.data[i].Dispose();
			}
			if (timeData.data[i].IsCreated)
			{
				timeData.data[i].Dispose();
			}
			if (computeBuffers.data[i] != null)
			{
				computeBuffers.data[i].Dispose();
				computeBuffers.data[i] = null;
			}
			if (computeArgs.data[i] != null)
			{
				computeArgs.data[i].Dispose();
				computeArgs.data[i] = null;
			}
			if (materials.data[i] != null)
			{
				Object.Destroy(materials.data[i]);
				materials.data[i] = null;
			}
		}
	}

	public void Tick()
	{
		if (isShutdown)
		{
			return;
		}
		for (int i = 0; i < siloMatrix.Count; i++)
		{
			int num = Mathff.Clamp(count - i * 10000, 0, 10000);
			if (type == 0)
			{
				new UpdateFields
				{
					matrix = siloMatrix.data[i],
					fieldData = fieldData.data[i],
					timeData = timeData.data[i],
					scaleMod = scaleMod,
					count = num,
					chunkSize = chunkSize
				}.Schedule().Complete();
			}
			else
			{
				new UpdateFruits
				{
					matrix = siloMatrix.data[i],
					fieldData = fieldData.data[i],
					timeData = timeData.data[i],
					scaleMod = scaleMod,
					count = num,
					chunkSize = chunkSize
				}.Schedule().Complete();
			}
			ComputeBuffer computeBuffer = computeBuffers.data[i];
			ComputeBuffer computeBuffer2 = computeArgs.data[i];
			uint[] array = arguments.data[i];
			Material material = materials.data[i];
			NativeArray<float4x4> data = siloMatrix.data[i];
			array[1] = (uint)num;
			if (num > 0)
			{
				computeBuffer.SetData(data, 0, 0, num);
			}
			computeBuffer2.SetData(array);
			Graphics.DrawMeshInstancedIndirect(mesh, 0, material, bounds, computeBuffer2, 0, null, ShadowCastingMode.Off);
		}
	}

	public void Clear()
	{
		count = 0;
	}

	private void AddBucket()
	{
		int num = siloMatrix.Count;
		NativeArray<float4x4> nativeArray = new NativeArray<float4x4>(10000, Allocator.Persistent);
		siloMatrix.Add(nativeArray);
		NativeArray<FieldData> item = new NativeArray<FieldData>(10000, Allocator.Persistent);
		fieldData.Add(item);
		NativeArray<float> item2 = new NativeArray<float>(10000, Allocator.Persistent);
		timeData.Add(item2);
		Owner[] item3 = new Owner[10000];
		owners.Add(item3);
		ComputeBuffer computeBuffer = new ComputeBuffer(10000, 64);
		string arg = (string.IsNullOrEmpty(debugName) ? $"FieldSystem_{type}" : debugName);
		ComputeBufferNaming.SetName(computeBuffer, $"{arg}_Bucket{num}_MatrixBuffer");
		computeBuffer.SetData(nativeArray);
		computeBuffers.Add(computeBuffer);
		Material material = Object.Instantiate(this.material);
		material.SetBuffer("matrixBuffer", computeBuffer);
		materials.Add(material);
		uint[] array = new uint[5]
		{
			(mesh != null) ? mesh.GetIndexCount(0) : 0u,
			(uint)nativeArray.Length,
			(mesh != null) ? mesh.GetIndexStart(0) : 0u,
			(mesh != null) ? mesh.GetBaseVertex(0) : 0u,
			0u
		};
		arguments.Add(array);
		ComputeBuffer computeBuffer2 = new ComputeBuffer(1, array.Length * 4, ComputeBufferType.DrawIndirect);
		ComputeBufferNaming.SetName(computeBuffer2, $"{arg}_Bucket{num}_ArgsBuffer");
		computeBuffer2.SetData(array);
		computeArgs.Add(computeBuffer2);
	}

	public void AddInstance(Owner owner, Vector3 pos, Quaternion rot, Vector3 scale)
	{
		int num = count % 10000;
		int num2 = count / 10000;
		if (num2 > siloMatrix.Count - 1)
		{
			AddBucket();
		}
		siloMatrix.data[num2][num] = float4x4.TRS(pos, rot, scale);
		FieldData value = new FieldData
		{
			pos = pos,
			rot = rot
		};
		fieldData.data[num2][num] = value;
		owner.s = num2;
		owner.idx = num;
		owners.data[num2][num] = owner;
		count++;
		added++;
	}

	public void RemoveInstance(Owner owner)
	{
		if (!isShutdown && count > 0)
		{
			int num = (count - 1) / 10000;
			int num2 = count - num * 10000 - 1;
			Owner obj = owners.data[num][num2];
			obj.s = owner.s;
			obj.idx = owner.idx;
			owners.data[owner.s][owner.idx] = owners.data[num][num2];
			fieldData.data[owner.s][owner.idx] = fieldData.data[num][num2];
			timeData.data[owner.s][owner.idx] = timeData.data[num][num2];
			siloMatrix.data[owner.s][owner.idx] = siloMatrix.data[num][num2];
			owners.data[num][num2] = null;
			count--;
		}
	}

	public void BeginAdd()
	{
		adding = true;
		added = 0;
	}

	public void EndAdd()
	{
		adding = false;
		added = 0;
	}

	public void SetTime(Owner owner, float time)
	{
		timeData.data[owner.s][owner.idx] = time;
	}
}
