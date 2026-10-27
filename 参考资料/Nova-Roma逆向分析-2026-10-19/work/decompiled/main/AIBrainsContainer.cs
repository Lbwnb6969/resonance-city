using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using UnityEngine;

public class AIBrainsContainer : MonoBehaviour
{
	[Serializable]
	public class PreStartAIConfig
	{
		[Serializable]
		public class AIStartData
		{
			public int landmass;

			public int bioCode;

			public string personalityKey;

			public AIKingdom.SkillLevel skillLevel = AIKingdom.SkillLevel.Medium;
		}

		public AIStartData[] startData;
	}

	[Serializable]
	public class SaveData : SaveClass<AIBrainsContainer, SaveData>
	{
		private AIKingdom.AIKingdomSaveData[] aiKingdoms;

		[OptionalField(VersionAdded = 2)]
		private PreStartAIConfig aiStartInfo;

		public override SaveData Pack(AIBrainsContainer v)
		{
			aiKingdoms = new AIKingdom.AIKingdomSaveData[v.transform.childCount];
			aiStartInfo = v.aiStartInfo;
			for (int i = 0; i < v.kingdoms.Count; i++)
			{
				aiKingdoms[i] = new AIKingdom.AIKingdomSaveData().Pack(v.kingdoms[i]);
			}
			return this;
		}

		public override AIBrainsContainer Unpack(AIBrainsContainer v)
		{
			v.aiStartInfo = aiStartInfo;
			for (int i = 0; i < v.kingdoms.Count; i++)
			{
				aiKingdoms[i].Unpack(v.kingdoms[i]);
			}
			return v;
		}

		internal AIBrainsContainer UnpackPrePlayer(AIBrainsContainer v)
		{
			for (int i = 0; i < aiKingdoms.Length; i++)
			{
				if (aiKingdoms[i] != null)
				{
					AIKingdom component = v.MakeAIKingdom().GetComponent<AIKingdom>();
					aiKingdoms[i].UnpackPrePlayer(component);
				}
			}
			v.aiStartInfo = aiStartInfo;
			return v;
		}
	}

	public static AIBrainsContainer inst;

	public PreStartAIConfig aiStartInfo;

	public string[] AIKingdomNamePool;

	public string[] AIKingdomFlavorTextPool;

	public GameObject AiKingdomPrefab;

	private int uid;

	[NonSerialized]
	public List<AIKingdom> kingdoms = new List<AIKingdom>();

	private void Awake()
	{
		inst = this;
	}

	public void ClearAIs()
	{
		List<AIKingdom> list = new List<AIKingdom>();
		for (int i = 0; i < kingdoms.Count; i++)
		{
			list.Add(kingdoms[i]);
		}
		for (int j = 0; j < list.Count; j++)
		{
			list[j].ShutdownKingdom();
			UnityEngine.Object.Destroy(list[j].gameObject);
		}
		kingdoms.Clear();
		AIKingdom.ClearLandmassMap();
	}

	public void SpawnAIKingdom(int landmass, int bannerIdx, AIPersonality personality, AIKingdom.SkillLevel skill)
	{
		GameObject gameObject = UnityEngine.Object.Instantiate(AiKingdomPrefab);
		gameObject.transform.SetParent(transform);
		int num = ++uid;
		gameObject.name = "AI Kingdom " + num;
		AIKingdom component = gameObject.GetComponent<AIKingdom>();
		component.skillLevel = skill;
		int teamId = kingdoms.Count + 2;
		component.SetupBase(landmass, bannerIdx, personality, teamId);
		Player.inst.LandMassNames[landmass] = AIKingdomNamePool[bannerIdx];
		kingdoms.Add(component);
	}

	private GameObject MakeAIKingdom()
	{
		GameObject gameObject = UnityEngine.Object.Instantiate(AiKingdomPrefab);
		gameObject.transform.SetParent(transform);
		int num = ++uid;
		gameObject.name = "AI Kingdom " + num;
		kingdoms.Add(gameObject.GetComponent<AIKingdom>());
		return gameObject;
	}

	public void BeginBaseBuilding()
	{
		for (int i = 0; i < kingdoms.Count; i++)
		{
			kingdoms[i].BeginBase();
		}
	}

	public void TakeOverIsland(int landmass)
	{
		if (!Player.inst.PlayerLandmassOwner.OwnsLandMass(landmass) || Player.inst.keep.LandMass() == landmass || landmass == -1)
		{
			return;
		}
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(landmass, World.outpostHash);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			World.inst.DemolishBuilding(buildingListForLandMass.data[i], reclaimResources: false);
		}
		int num = aiStartInfo.startData.Length + 1;
		PreStartAIConfig.AIStartData[] array = new PreStartAIConfig.AIStartData[num];
		PreStartAIConfig.AIStartData aIStartData = new PreStartAIConfig.AIStartData();
		for (int j = 0; j < aiStartInfo.startData.Length; j++)
		{
			array[j] = aiStartInfo.startData[j];
		}
		aIStartData.landmass = landmass;
		aIStartData.bioCode = 3;
		aIStartData.personalityKey = PersonalityCollection.aiPersonalityKeys[0];
		aIStartData.skillLevel = AIKingdom.SkillLevel.Medium;
		array[num - 1] = aIStartData;
		Type typeByKey = PersonalityCollection.GetTypeByKey(aIStartData.personalityKey);
		SpawnAIKingdom(landmass, 3, (AIPersonality)Activator.CreateInstance(typeByKey), aIStartData.skillLevel);
		kingdoms[kingdoms.Count - 1].BeginBase();
		Player.inst.RefreshVisibilityFor(landmass, force: true);
		Player.inst.updateBanner?.Invoke();
		ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(landmass);
		for (int k = 0; k < buildingListForLandMass2.Count; k++)
		{
			buildingListForLandMass2.data[k].UpdateMaterialSelection();
			buildingListForLandMass2.data[k].Open = true;
		}
		ArrayExt<ArmySystem.Army> armies = ArmySystem.inst.armies;
		for (int l = 0; l < armies.Count; l++)
		{
			ArmySystem.Army army = armies.data[l];
			if (army.teamId == 0 && World.inst.GetCellData(army.generalPos).landMassIdx == landmass)
			{
				if (army.locked)
				{
					OrdersManager.inst.DestroyUnit(army);
				}
				else
				{
					army.Disband();
				}
				l--;
			}
		}
	}

	public AIKingdom GetKingdomFromLandmassOwner(LandmassOwner landmassOwner)
	{
		for (int i = 0; i < kingdoms.Count; i++)
		{
			if (kingdoms[i].LandmassOwner == landmassOwner)
			{
				return kingdoms[i];
			}
		}
		return null;
	}

	public AIKingdom GetKingdomFromTeamId(int teamId)
	{
		for (int i = 0; i < kingdoms.Count; i++)
		{
			if (kingdoms[i].LandmassOwner.teamId == teamId)
			{
				return kingdoms[i];
			}
		}
		return null;
	}
}
