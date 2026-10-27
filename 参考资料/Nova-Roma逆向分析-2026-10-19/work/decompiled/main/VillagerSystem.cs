using Assets;
using UnityEngine;
using UnityEngine.Rendering;
using cakeslice;

public class VillagerSystem : MonoBehaviour
{
	public enum MeshType
	{
		Default,
		Axeman,
		Builder,
		Healer,
		FireFighter,
		Farmer,
		HandCart,
		Carrying,
		FireFighterEmpty,
		NumType
	}

	public class VillagerInstanceSystem : InstanceSystem
	{
		public ArrayExt<Vector4[]> headColors = new ArrayExt<Vector4[]>(1023);

		public ArrayExt<Vector4[]> bodyColors = new ArrayExt<Vector4[]>(1023);

		public ArrayExt<Vector4[]> hairColors = new ArrayExt<Vector4[]>(1023);

		public override void ReleaseInstanceInternal(int i, int k, int endS, int endIdx)
		{
			headColors.data[i][k] = headColors.data[endS][endIdx];
			bodyColors.data[i][k] = bodyColors.data[endS][endIdx];
			hairColors.data[i][k] = hairColors.data[endS][endIdx];
		}

		public override void AddInstanceInternal()
		{
			headColors.Add(new Vector4[1023]);
			bodyColors.Add(new Vector4[1023]);
			hairColors.Add(new Vector4[1023]);
		}

		public override void DrawInstances(Mesh model, Material mat)
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
					prop.SetVectorArray("_HeadColor", headColors.data[i]);
					prop.SetVectorArray("_BodyColor", bodyColors.data[i]);
					prop.SetVectorArray("_HairColor", hairColors.data[i]);
					Graphics.DrawMeshInstanced(model, 0, mat, silos.data[i], num, prop, shadowCastingMode);
					continue;
				}
				for (int j = 0; j < num; j++)
				{
					prop.SetVector("_HeadColor", headColors.data[i][j]);
					prop.SetVector("_BodyColor", bodyColors.data[i][j]);
					prop.SetVector("_HairColor", hairColors.data[i][j]);
					Graphics.DrawMesh(model, silos.data[i][j], mat, 0, Cam.inst.cam, 0, prop, shadowCastingMode);
				}
			}
		}
	}

	public static VillagerSystem inst;

	public Outline outline;

	public Material uniMaterial;

	public Color[] headColors;

	public Color[] bodyColors;

	public Color[] hairColors;

	public Mesh[] villagerMeshs;

	public Mesh[] ladyVillagerMeshs;

	internal ArrayExt<VillagerInstanceSystem> instances;

	internal ArrayExt<VillagerInstanceSystem> ladyInstances;

	private void Start()
	{
		inst = this;
		outline = new Outline(villagerMeshs[0]);
		instances = new ArrayExt<VillagerInstanceSystem>(9);
		ladyInstances = new ArrayExt<VillagerInstanceSystem>(9);
		for (int i = 0; i < 9; i++)
		{
			VillagerInstanceSystem villagerInstanceSystem = new VillagerInstanceSystem();
			villagerInstanceSystem.shadowCastingMode = ShadowCastingMode.Off;
			instances.data[i] = villagerInstanceSystem;
			VillagerInstanceSystem villagerInstanceSystem2 = new VillagerInstanceSystem();
			villagerInstanceSystem2.shadowCastingMode = ShadowCastingMode.Off;
			ladyInstances.data[i] = villagerInstanceSystem2;
		}
	}

	private void LateUpdate()
	{
		if (!GameUI.inst.IsChariotRaceModeActive())
		{
			for (int i = 0; i < 9; i++)
			{
				instances.data[i].DrawInstances(villagerMeshs[i], uniMaterial);
			}
			for (int j = 0; j < 9; j++)
			{
				ladyInstances.data[j].DrawInstances(ladyVillagerMeshs[j], uniMaterial);
			}
		}
	}

	public Villager AddVillager(Vector3 pos, bool useLadyMesh)
	{
		Villager villager = null;
		if (Villager.villagerPoolCount == Villager.villagers.Count)
		{
			villager = new Villager();
			Villager.villagerPool.Add(villager);
			villager.idxIntoPool = Villager.villagerPool.Count - 1;
			Villager.villagerPoolCount++;
		}
		else
		{
			villager = Villager.villagerPool.GetNew();
			villager.idxIntoPool = Villager.villagerPool.Count - 1;
		}
		villager.InitMesh(MeshType.Default);
		villager.headColor = headColors[SRand.Range(0, headColors.Length)];
		villager.bodyColor = bodyColors[SRand.Range(0, bodyColors.Length)];
		villager.hairColor = hairColors[SRand.Range(0, hairColors.Length)];
		VillagerInstanceSystem villagerInstanceSystem = instances.data[0];
		villager.instancesRef = instances;
		villager.useLadyMesh = useLadyMesh;
		if (villager.useLadyMesh)
		{
			villagerInstanceSystem = ladyInstances.data[0];
			villager.instancesRef = ladyInstances;
		}
		villagerInstanceSystem.AddInstance(villager, pos, Quaternion.identity, Vector3.one);
		villagerInstanceSystem.headColors.data[villager.s][villager.idx] = villager.headColor;
		villagerInstanceSystem.bodyColors.data[villager.s][villager.idx] = villager.bodyColor;
		villagerInstanceSystem.hairColors.data[villager.s][villager.idx] = villager.hairColor;
		villager.Init();
		villager.Pos = pos;
		villager.Rot = Quaternion.identity;
		return villager;
	}

	public void RemoveVillager(Villager curr)
	{
		if (curr.useLadyMesh)
		{
			ladyInstances.data[(int)curr.MeshType].ReleaseInstance(curr);
		}
		else
		{
			instances.data[(int)curr.MeshType].ReleaseInstance(curr);
		}
	}
}
