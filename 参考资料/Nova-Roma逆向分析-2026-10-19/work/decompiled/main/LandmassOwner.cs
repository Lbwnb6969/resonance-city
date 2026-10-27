using System;
using System.Collections.Generic;
using Assets.Code;
using UnityEngine;

public class LandmassOwner : MonoBehaviour
{
	public enum Trait
	{
		Suspicious,
		Friendly,
		Hostile
	}

	public enum Standing
	{
		VeryUnfavorable,
		Unfavorable,
		Neutral,
		Favorable,
		VeryFavorable
	}

	public enum Mood
	{
		VeryBad,
		Bad,
		Neutral,
		Good,
		VeryGood
	}

	[Serializable]
	public class LandmassOwnerSaveData : SaveClass<LandmassOwner, LandmassOwnerSaveData>
	{
		public int gold;

		public int maxGold;

		public int[] ownedLandMasses;

		public int teamId;

		public Dictionary<int, Standing> standings;

		public Dictionary<int, int> pointsForNextStanding;

		public List<Player.UpgradeType> upgrades;

		public List<int>[] didTempleBonus;

		public bool hazardPay;

		public int lastStandingChange;

		public override LandmassOwnerSaveData Pack(LandmassOwner v)
		{
			teamId = v.teamId;
			gold = v.Gold;
			maxGold = v.MaxGoldStorage;
			didTempleBonus = new List<int>[v.didTempleBonus.Length];
			for (int i = 0; i < didTempleBonus.Length; i++)
			{
				didTempleBonus[i] = new List<int>();
				for (int j = 0; j < v.didTempleBonus[i].Count; j++)
				{
					didTempleBonus[i].Add(v.didTempleBonus[i][j]);
				}
			}
			standings = v.standings;
			pointsForNextStanding = v.pointsForNextStanding;
			ownedLandMasses = new int[v.ownedLandMasses.Count];
			for (int k = 0; k < v.ownedLandMasses.Count; k++)
			{
				ownedLandMasses[k] = v.ownedLandMasses.data[k];
			}
			upgrades = new List<Player.UpgradeType>();
			for (int l = 0; l < v.upgrades.Count; l++)
			{
				upgrades.Add(v.upgrades[l]);
			}
			hazardPay = v.hazardPay;
			lastStandingChange = v.lastStandingChange;
			return this;
		}

		public override LandmassOwner Unpack(LandmassOwner v)
		{
			v.teamId = teamId;
			v.Gold = gold;
			v.MaxGoldStorage = maxGold;
			v.standings = standings;
			if (v.standings == null)
			{
				v.standings = new Dictionary<int, Standing>();
			}
			v.pointsForNextStanding = pointsForNextStanding;
			if (v.pointsForNextStanding == null)
			{
				v.pointsForNextStanding = new Dictionary<int, int>();
			}
			v.ownedLandMasses = new ArrayExt<int>(ownedLandMasses.Length);
			for (int i = 0; i < ownedLandMasses.Length; i++)
			{
				v.TakeOwnership(ownedLandMasses[i]);
			}
			if (upgrades != null)
			{
				for (int j = 0; j < upgrades.Count; j++)
				{
					v.AddUpgrade(upgrades[j]);
				}
			}
			v.hazardPay = hazardPay;
			v.lastStandingChange = lastStandingChange;
			v.didTempleBonus = new List<int>[GodManager.numGods];
			for (int k = 0; k < v.didTempleBonus.Length; k++)
			{
				v.didTempleBonus[k] = new List<int>();
			}
			if (didTempleBonus != null)
			{
				for (int l = 0; l < v.didTempleBonus.Length && l < didTempleBonus.Length; l++)
				{
					for (int m = 0; m < didTempleBonus[l].Count; m++)
					{
						v.didTempleBonus[l].Add(didTempleBonus[l][m]);
					}
				}
			}
			return v;
		}
	}

	public Trait trait;

	[NonSerialized]
	public Mood mood = Mood.Neutral;

	[NonSerialized]
	public string moodTxtKey = "calm";

	public Dictionary<int, Standing> standings = new Dictionary<int, Standing>();

	public Dictionary<int, int> pointsForNextStanding = new Dictionary<int, int>();

	public List<Player.UpgradeType> upgrades = new List<Player.UpgradeType>();

	public bool hazardPay;

	public int hazardPayMultiplier = 4;

	public Material UniMaterial;

	public Material UniMaterialTerrainForm;

	public Material FlagMaterial;

	public Material BuildingMaterial;

	public Material ArmyMaterial;

	public Material ArmyMaterialUnlit;

	public Material UniMaterialFogClip;

	public Texture BannerTexture;

	[NonSerialized]
	public Material[] UniMaterialsCracked = new Material[3];

	[NonSerialized]
	public Material[] UniMaterialsCrackedWithTerrainForm = new Material[3];

	[NonSerialized]
	public int bannerIdx = -1;

	public int teamId;

	private int gold;

	[HideInInspector]
	public int MaxGoldStorage;

	internal List<int>[] didTempleBonus = new List<int>[GodManager.numGods];

	internal Dictionary<int, ResourceAmount> resourcePayCosts = new Dictionary<int, ResourceAmount>();

	internal Dictionary<int, int> tradeFavor = new Dictionary<int, int>();

	public ArrayExt<int> ownedLandMasses = new ArrayExt<int>(5);

	private ArrayExt<ArrayExt<Building>> buildingArrays = new ArrayExt<ArrayExt<Building>>(10);

	internal ArrayExt<int> angryGods = new ArrayExt<int>(GodManager.numGods);

	internal Player.GodHonorInfo[] godHonor;

	internal int lastStandingChange;

	public int Gold
	{
		get
		{
			return gold;
		}
		set
		{
			if (teamId == 0)
			{
				MilestoneManager.inst.CheckGoldMilestones();
			}
			gold = value;
		}
	}

	public void SetBannerIdx(int bIdx)
	{
		bannerIdx = bIdx;
		FlagMaterial = World.inst.liverySets[bannerIdx].flagMaterial;
		UniMaterial = World.inst.liverySets[bannerIdx].uniMaterial;
		UniMaterialTerrainForm = World.inst.liverySets[bannerIdx].uniMaterialTerrainForm;
		BannerTexture = World.inst.liverySets[bannerIdx].banners;
		BuildingMaterial = World.inst.liverySets[bannerIdx].buildingMaterial;
		ArmyMaterial = World.inst.liverySets[bannerIdx].armyMaterial;
		ArmyMaterialUnlit = World.inst.liverySets[bannerIdx].armyMaterialUnlit;
		UniMaterialFogClip = World.inst.liverySets[bannerIdx].uniMaterialFogClip;
		Material uniMaterialCracked = World.inst.liverySets[bannerIdx].uniMaterialCracked;
		for (int i = 0; i < UniMaterialsCracked.Length; i++)
		{
			UnityEngine.Object.Destroy(UniMaterialsCracked[i]);
			UnityEngine.Object.Destroy(UniMaterialsCrackedWithTerrainForm[i]);
			UniMaterialsCracked[i] = UnityEngine.Object.Instantiate(uniMaterialCracked);
			UniMaterialsCrackedWithTerrainForm[i] = UnityEngine.Object.Instantiate(uniMaterialCracked);
			UniMaterialsCrackedWithTerrainForm[i].SetFloat("_FormToTerrain", 1f);
			if (i == 0)
			{
				UniMaterialsCracked[i].SetFloat("_BreakStrength", 0.2f);
				UniMaterialsCracked[i].SetFloat("_Dim", 0.05f);
				UniMaterialsCrackedWithTerrainForm[i].SetFloat("_BreakStrength", 0.2f);
				UniMaterialsCrackedWithTerrainForm[i].SetFloat("_Dim", 0.05f);
			}
			if (i == 1)
			{
				UniMaterialsCracked[i].SetFloat("_BreakStrength", 0.33f);
				UniMaterialsCracked[i].SetFloat("_Dim", 0.3f);
				UniMaterialsCrackedWithTerrainForm[i].SetFloat("_BreakStrength", 0.33f);
				UniMaterialsCrackedWithTerrainForm[i].SetFloat("_Dim", 0.3f);
			}
			if (i == 2)
			{
				UniMaterialsCracked[i].SetFloat("_BreakStrength", 0.5f);
				UniMaterialsCracked[i].SetFloat("_Dim", 0.5f);
				UniMaterialsCrackedWithTerrainForm[i].SetFloat("_BreakStrength", 0.5f);
				UniMaterialsCrackedWithTerrainForm[i].SetFloat("_Dim", 0.5f);
			}
		}
	}

	public void AddUpgrade(Player.UpgradeType ut)
	{
		if (ut != Player.UpgradeType.None && !upgrades.Contains(ut))
		{
			upgrades.Add(ut);
		}
	}

	public bool HasUpgrade(Player.UpgradeType ut)
	{
		return upgrades.Contains(ut);
	}

	public ResourceAmount GetPayCosts(int sellerTeamID)
	{
		if (sellerTeamID != teamId)
		{
			if (!resourcePayCosts.ContainsKey(sellerTeamID))
			{
				resourcePayCosts.Add(sellerTeamID, Player.inst.defaultPayCost);
			}
			return resourcePayCosts[sellerTeamID];
		}
		return Player.inst.defaultPayCost;
	}

	public void SetPayCosts(int teamID, ResourceAmount amt)
	{
		if (teamID != teamId)
		{
			if (resourcePayCosts.ContainsKey(teamID))
			{
				resourcePayCosts[teamID] = amt;
			}
			else
			{
				resourcePayCosts.Add(teamID, amt);
			}
		}
	}

	public int GetTradeFavor(int vistorTeamId)
	{
		if (vistorTeamId != teamId)
		{
			if (!tradeFavor.ContainsKey(vistorTeamId))
			{
				tradeFavor.Add(vistorTeamId, 0);
			}
			return tradeFavor[vistorTeamId];
		}
		return 0;
	}

	public void CalcMaxGold()
	{
		MaxGoldStorage = 0;
		for (int i = 0; i < ownedLandMasses.Count; i++)
		{
			Player.inst.GetBuildingListsByCategoryForLandMass(ownedLandMasses.data[i], "temple".GetHashCode(), ref buildingArrays);
			int j = 0;
			for (int count = buildingArrays.Count; j < count; j++)
			{
				ArrayExt<Building> arrayExt = buildingArrays.data[j];
				int k = 0;
				for (int count2 = arrayExt.Count; k < count2; k++)
				{
					if (arrayExt.data[k].IsBuilt())
					{
						ThroneRoom component = arrayExt.data[k].GetComponent<ThroneRoom>();
						if ((bool)component)
						{
							MaxGoldStorage += component.MaxGold;
						}
					}
				}
			}
		}
	}

	public bool OwnsLandMass(int landmass)
	{
		for (int i = 0; i < ownedLandMasses.Count; i++)
		{
			if (ownedLandMasses.data[i] == landmass)
			{
				return true;
			}
		}
		return false;
	}

	private void InitStandingIfNecessary(int lmo)
	{
		if (!standings.ContainsKey(lmo))
		{
			if (trait == Trait.Hostile)
			{
				standings.Add(lmo, Standing.Unfavorable);
			}
			else
			{
				standings.Add(lmo, Standing.Neutral);
			}
			pointsForNextStanding.Add(lmo, 50);
		}
	}

	internal Standing GetStandingFor(int teamID)
	{
		InitStandingIfNecessary(teamID);
		return standings[teamID];
	}

	internal int GetPointsStandingFor(int teamID)
	{
		InitStandingIfNecessary(teamID);
		return pointsForNextStanding[teamID];
	}

	internal void ModifyStandingFor(int teamId, int points)
	{
		if (teamId == 0)
		{
			lastStandingChange = points;
		}
		InitStandingIfNecessary(teamId);
		pointsForNextStanding[teamId] += points;
		int num = pointsForNextStanding[teamId] - 100;
		if (num > 0)
		{
			if (standings[teamId] == Standing.VeryFavorable)
			{
				pointsForNextStanding[teamId] = 100;
			}
			else
			{
				standings[teamId]++;
				pointsForNextStanding[teamId] = num;
			}
		}
		if (pointsForNextStanding[teamId] < 0)
		{
			if (standings[teamId] == Standing.VeryUnfavorable)
			{
				pointsForNextStanding[teamId] = 0;
				return;
			}
			standings[teamId]--;
			pointsForNextStanding[teamId] = 100 + pointsForNextStanding[teamId];
		}
	}

	internal void SetStandingFor(int lmo, Standing standing)
	{
		InitStandingIfNecessary(lmo);
		standings[lmo] = standing;
	}

	public void TakeOwnership(int landmass)
	{
		ownedLandMasses.Add(landmass);
		if (World.LandMassOwnerLookup == null)
		{
			World.LandMassOwnerLookup = new LandmassOwner[World.inst.NumLandMasses];
		}
		if (World.LandMassOwnerLookup[landmass] != null)
		{
			World.LandMassOwnerLookup[landmass].ownedLandMasses.RemoveSwap(landmass);
		}
		World.LandMassOwnerLookup[landmass] = this;
	}

	public void ReleaseOwnership()
	{
		ownedLandMasses.Clear();
	}

	public void Reset()
	{
		ReleaseOwnership();
		Gold = 0;
		MaxGoldStorage = 0;
		lastStandingChange = 0;
		upgrades = new List<Player.UpgradeType>();
		standings.Clear();
		pointsForNextStanding.Clear();
		for (int i = 0; i < didTempleBonus.Length; i++)
		{
			didTempleBonus[i] = new List<int>();
		}
		angryGods.Clear();
		godHonor = new Player.GodHonorInfo[GodManager.numGods];
		for (int j = 0; j < godHonor.Length; j++)
		{
			godHonor[j] = new Player.GodHonorInfo();
		}
	}

	private void OnEnable()
	{
		World.LandMassOwners.Add(this);
	}

	private void OnDisable()
	{
		World.LandMassOwners.RemoveSwap(this);
	}

	private void Update()
	{
		Gold = Mathff.Min(Gold, MaxGoldStorage);
		if (bannerIdx != -1)
		{
			float t = Mathff.Clamp01((Cam.inst.dist - 10f) / 50f);
			float value = Mathff.Lerp(1f, 2f, t);
			float value2 = Mathff.Lerp(1f, 1.5f, t);
			ArmyMaterialUnlit.SetFloat("_camScale", value);
			ArmyMaterialUnlit.SetFloat("_colorMul", value2);
			ArmyMaterial.SetFloat("_camScale", value);
			ArmyMaterial.SetFloat("_colorMul", value2);
		}
	}
}
