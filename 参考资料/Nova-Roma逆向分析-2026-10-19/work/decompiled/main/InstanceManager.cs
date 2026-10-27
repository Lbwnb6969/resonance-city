using System.Collections.Generic;
using Assets;
using UnityEngine;
using UnityEngine.Rendering;

public class InstanceManager : MonoBehaviour
{
	public int MaxMatrixSize = 1023;

	private List<InstanceSilo> InstanceSilos;

	public static InstanceManager inst;

	private void Awake()
	{
		InstanceSilos = new List<InstanceSilo>(10);
		inst = this;
	}

	public void Add(RenderInstance instance, Matrix4x4 mat = default(Matrix4x4), bool castShadows = true)
	{
		InstanceSilo instanceSilo = instance.silo;
		if (instance.mesh == null)
		{
			Debug.LogError("null mesh");
		}
		if (instanceSilo == null)
		{
			for (int i = 0; i < InstanceSilos.Count; i++)
			{
				if (InstanceSilos[i].sharedMaterial == instance.material && InstanceSilos[i].sharedMesh == instance.mesh)
				{
					instanceSilo = InstanceSilos[i];
					break;
				}
			}
		}
		if (instanceSilo == null)
		{
			instanceSilo = new InstanceSilo
			{
				sharedMesh = instance.mesh,
				sharedMaterial = instance.material,
				instances = new List<ArrayExt<RenderInstance>>(),
				matricies = new List<ArrayExt<Matrix4x4>>()
			};
			InstanceSilos.Add(instanceSilo);
		}
		instanceSilo.castShadows = castShadows;
		int num = -1;
		int num2 = -1;
		for (int j = 0; j <= instanceSilo.instances.Count; j++)
		{
			if (instanceSilo.instances.Count == j)
			{
				instanceSilo.instances.Add(new ArrayExt<RenderInstance>(MaxMatrixSize));
				instanceSilo.matricies.Add(new ArrayExt<Matrix4x4>(MaxMatrixSize));
			}
			if (instanceSilo.instances[j].Count < MaxMatrixSize)
			{
				num = j;
				num2 = instanceSilo.instances[j].AddNoExpand(instance);
				instanceSilo.matricies[j].AddNoExpand(mat);
				instance.UpdateIndex(instanceSilo, num, num2);
				break;
			}
		}
	}

	public void Remove(RenderInstance instance)
	{
		InstanceSilo silo = instance.silo;
		if (silo != null)
		{
			bool flag = instance.arrayIndex == silo.instances[instance.listIndex].Count - 1;
			silo.instances[instance.listIndex].RemoveAtSwap(instance.arrayIndex);
			silo.matricies[instance.listIndex].RemoveAtSwap(instance.arrayIndex);
			if (!flag)
			{
				silo.instances[instance.listIndex].data[instance.arrayIndex].UpdateIndex(silo, instance.listIndex, instance.arrayIndex);
			}
		}
	}

	private void LateUpdate()
	{
		for (int i = 0; i < InstanceSilos.Count; i++)
		{
			for (int j = 0; j < InstanceSilos[i].matricies.Count; j++)
			{
				if (InstanceSilos[i].matricies[j].Count > 0)
				{
					Graphics.DrawMeshInstanced(InstanceSilos[i].sharedMesh, 0, InstanceSilos[i].sharedMaterial, InstanceSilos[i].matricies[j].data, InstanceSilos[i].matricies[j].Count, null, InstanceSilos[i].castShadows ? ShadowCastingMode.On : ShadowCastingMode.Off);
				}
			}
		}
	}

	private void DrawMeshes(Mesh mesh, Material material, ArrayExt<Matrix4x4> matricies)
	{
		for (int i = 0; i < matricies.Count; i++)
		{
			Graphics.DrawMesh(mesh, matricies.data[i], material, 0);
		}
	}

	public void DrawMeshesWithCommandBuffer(CommandBuffer buffer, Material mat, int pass)
	{
		for (int i = 0; i < InstanceSilos.Count; i++)
		{
			for (int j = 0; j < InstanceSilos[i].matricies.Count; j++)
			{
				if (Settings.inst.supportsInstancing)
				{
					buffer.DrawMeshInstanced(InstanceSilos[i].sharedMesh, 0, mat, pass, InstanceSilos[i].matricies[j].data, InstanceSilos[i].matricies.Count);
					continue;
				}
				for (int k = 0; k < InstanceSilos[i].matricies.Count; k++)
				{
					buffer.DrawMesh(InstanceSilos[i].sharedMesh, InstanceSilos[i].matricies[j].data[k], mat, 0, pass);
				}
			}
		}
	}
}
