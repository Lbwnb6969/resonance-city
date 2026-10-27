using System;
using Assets;
using UnityEngine;

public class InstanceSystemBehaviour : MonoBehaviour
{
	public class Owner
	{
		public int s;

		public int idx;
	}

	private const int siloSize = 1023;

	private ArrayExt<Owner[]> owners = new ArrayExt<Owner[]>(10);

	[NonSerialized]
	public ArrayExt<Matrix4x4[]> silos = new ArrayExt<Matrix4x4[]>(10);

	private int count;

	public void ResetInstances()
	{
		count = 0;
		for (int i = 0; i < owners.Count; i++)
		{
			for (int j = 0; j < owners.data[i].Length; j++)
			{
				owners.data[i][j] = null;
			}
		}
	}

	public void ReleaseInstance(Owner owner)
	{
		for (int i = 0; i < owners.Count; i++)
		{
			for (int j = 0; j < owners.data[i].Length; j++)
			{
				if (owners.data[i][j] == owner)
				{
					int num = (count - 1) / 1023;
					int num2 = count - num * 1023 - 1;
					owners.data[i][j] = owners.data[num][num2];
					silos.data[i][j] = silos.data[num][num2];
					owners.data[i][j].s = i;
					owners.data[i][j].idx = j;
					owners.data[num][num2] = null;
					count--;
					j--;
				}
			}
		}
	}

	public void AddInstance(Owner owner, Vector3 initPos, Quaternion initRot, Vector3 initScale)
	{
		int num = count % 1023;
		int num2 = count / 1023;
		if (num2 >= silos.Count)
		{
			silos.Add(new Matrix4x4[1023]);
			owners.Add(new Owner[1023]);
		}
		Mathff.SetTRS(ref silos.data[num2][num], initPos, initRot, initScale);
		owners.data[num2][num] = owner;
		owner.s = num2;
		owner.idx = num;
		count++;
	}

	public void DrawInstances(Mesh model, Material mat)
	{
		for (int i = 0; i < silos.Count; i++)
		{
			int num = Mathff.Clamp(count - i * 1023, 0, 1023);
			if (num <= 0)
			{
				continue;
			}
			if (Settings.inst.supportsInstancing)
			{
				Graphics.DrawMeshInstanced(model, 0, mat, silos.data[i], num);
				continue;
			}
			for (int j = 0; j < num; j++)
			{
				Graphics.DrawMesh(model, silos.data[i][j], mat, 0);
			}
		}
	}
}
