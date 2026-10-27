using Assets;
using UnityEngine;
using UnityEngine.Rendering;

public class FruitSystem
{
	public Material material;

	public Mesh mesh;

	private const int siloSize = 1023;

	private ArrayExt<Orchard[]> owners = new ArrayExt<Orchard[]>(10);

	private ArrayExt<Matrix4x4[]> silos = new ArrayExt<Matrix4x4[]>(10);

	private int count;

	private int added;

	private bool adding;

	private const int FruitsPerBlock = 24;

	private int orchardHash = "orchard".GetHashCode();

	public void Reset()
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

	public void CleanUp(Orchard owner)
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
					owners.data[num][num2] = null;
					count--;
					j--;
				}
			}
		}
	}

	public void BeginAdd()
	{
		adding = true;
		added = 0;
	}

	public void AddFruit(Orchard owner, Vector3 initPos, Vector3 initScale)
	{
		int num = count % 1023;
		int num2 = count / 1023;
		if (num2 >= silos.Count)
		{
			silos.Add(new Matrix4x4[1023]);
			owners.Add(new Orchard[1023]);
		}
		Mathff.SetTS(ref silos.data[num2][num], initPos, initScale);
		owners.data[num2][num] = owner;
		added++;
		count++;
	}

	public void EndAdd()
	{
		adding = false;
		added = 0;
	}

	public void Tick()
	{
		UpdateFruits();
		DrawFruit();
	}

	private void UpdateFruits()
	{
		for (int i = 0; i < count; i++)
		{
			int num = i % 1023;
			int num2 = i / 1023;
			float fruitScale = owners.data[num2][num].fruitScale;
			Mathff.UpdateS(ref silos.data[num2][num], fruitScale);
		}
	}

	private void DrawFruit()
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
				Graphics.DrawMeshInstanced(mesh, 0, material, silos.data[i], num);
				continue;
			}
			for (int j = 0; j < num; j++)
			{
				Graphics.DrawMesh(mesh, silos.data[i][j], material, 0);
			}
		}
	}

	public void DrawFruitWithCommandBuffer(CommandBuffer buffer, Material mat, int pass)
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
				buffer.DrawMeshInstanced(mesh, 0, material, pass, silos.data[i], num);
				continue;
			}
			for (int j = 0; j < num; j++)
			{
				buffer.DrawMesh(mesh, silos.data[i][j], material, 0, pass);
			}
		}
	}
}
