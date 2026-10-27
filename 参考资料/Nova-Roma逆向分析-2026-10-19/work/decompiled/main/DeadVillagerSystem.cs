using System;
using System.Collections.Generic;
using UnityEngine;

public class DeadVillagerSystem : MonoBehaviour
{
	[Serializable]
	public class DeadVillagerSystemSaveData : SaveClass<DeadVillagerSystem, DeadVillagerSystemSaveData>
	{
		private List<DeadVillager.DeadVillagerSaveData> saveData = new List<DeadVillager.DeadVillagerSaveData>();

		public override DeadVillagerSystemSaveData Pack(DeadVillagerSystem obj)
		{
			for (int i = 0; i < obj.villagers.Count; i++)
			{
				DeadVillager.DeadVillagerSaveData deadVillagerSaveData = new DeadVillager.DeadVillagerSaveData();
				deadVillagerSaveData.Pack(obj.villagers.data[i]);
				saveData.Add(deadVillagerSaveData);
			}
			return this;
		}

		public override DeadVillagerSystem Unpack(DeadVillagerSystem obj)
		{
			for (int i = 0; i < saveData.Count; i++)
			{
				DeadVillager.DeadVillagerSaveData deadVillagerSaveData = saveData[i];
				DeadVillager obj2 = new DeadVillager();
				deadVillagerSaveData.Unpack(obj2);
			}
			return obj;
		}
	}

	internal InstanceSystem deadVillagers;

	internal InstanceSystem deadLadyVillagers;

	public static DeadVillagerSystem inst;

	internal ArrayExt<DeadVillager> villagers = new ArrayExt<DeadVillager>(100);

	private ArrayExt<DeadVillager> deferredRemoval = new ArrayExt<DeadVillager>(100);

	public Mesh deadVillagerModel;

	public Mesh deadLadyVillagerModel;

	private void Start()
	{
		deadVillagers = new InstanceSystem();
		deadLadyVillagers = new InstanceSystem();
		inst = this;
	}

	public void Reset()
	{
		for (int num = villagers.Count - 1; num >= 0; num--)
		{
			villagers.data[num].Shutdown();
		}
		deadVillagers.ResetInstances();
		deadLadyVillagers.ResetInstances();
		deferredRemoval.Clear();
		villagers.Clear();
	}

	public void Update()
	{
		float deltaTime = Time.deltaTime;
		for (int i = 0; i < deferredRemoval.Count; i++)
		{
			villagers.RemoveSwap(deferredRemoval.data[i]);
		}
		deferredRemoval.ClearFast();
		for (int j = 0; j < villagers.Count; j++)
		{
			villagers.data[j].Tick(deltaTime);
		}
	}

	private void LateUpdate()
	{
		deadVillagers.DrawInstances(deadVillagerModel, World.inst.uniMaterialNoFog);
		deadLadyVillagers.DrawInstances(deadLadyVillagerModel, World.inst.uniMaterialNoFog);
	}

	internal void Remove(DeadVillager v)
	{
		deferredRemoval.Add(v);
		if (v.useLadyMesh)
		{
			deadLadyVillagers.ReleaseInstance(v);
		}
		else
		{
			deadVillagers.ReleaseInstance(v);
		}
	}

	internal void Add(DeadVillager deadVillager, Vector3 pos, Quaternion rot, Vector3 scale)
	{
		villagers.Add(deadVillager);
		if (deadVillager.useLadyMesh)
		{
			deadLadyVillagers.AddInstance(deadVillager, pos, rot, scale);
		}
		else
		{
			deadVillagers.AddInstance(deadVillager, pos, rot, scale);
		}
	}
}
