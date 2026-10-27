using System;
using System.Collections.Generic;
using Assets;
using UnityEngine;

public class Governor
{
	[Serializable]
	public class TraitInstance
	{
		public int id;

		public float magnitude;

		public bool negative;
	}

	[Serializable]
	public class GovernorSaveData : SaveClass<Governor, GovernorSaveData>
	{
		public List<TraitInstance> traits = new List<TraitInstance>();

		public PersonProfile profile;

		public int reappoints;

		private float timeInOffice;

		public override GovernorSaveData Pack(Governor v)
		{
			traits = v.traits;
			profile = v.profile;
			reappoints = v.reappoints;
			timeInOffice = v.timeInOffice;
			return this;
		}

		public override Governor Unpack(Governor v)
		{
			v.traits = traits;
			for (int i = 0; i < traits.Count; i++)
			{
				v.traitMap[traits[i].id] = traits[i];
			}
			v.profile = profile;
			v.reappoints = reappoints;
			v.timeInOffice = timeInOffice;
			for (int j = 0; j < traits.Count; j++)
			{
				v.traitMap[traits[j].id] = traits[j];
			}
			return v;
		}
	}

	public int FavoredByGods;

	private TraitInstance[] traitMap = new TraitInstance[1000];

	public List<TraitInstance> traits = new List<TraitInstance>();

	public PersonProfile profile;

	public int reappoints;

	private float timeInOffice;

	public void Update(float dt)
	{
		timeInOffice += dt;
	}

	public float GetMagnitude(float baseMag, float variance, bool isPercentage)
	{
		float num = Mathf.CeilToInt((float)Mathf.RoundToInt((baseMag + SRand.Range(0f - variance, variance)) * 100f) / 20f) * 20;
		if (isPercentage)
		{
			return num / 100f;
		}
		return num;
	}

	private int GetUniqueTraitId()
	{
		for (int num = 100; num > 0; num--)
		{
			int id = Traits.inst.traits[SRand.Range(0, Traits.inst.traits.Count)].id;
			bool flag = false;
			for (int i = 0; i < traits.Count; i++)
			{
				if (traits[i].id == id)
				{
					flag = true;
					break;
				}
			}
			if (!flag)
			{
				return id;
			}
		}
		return Traits.BuildingDecay;
	}

	public void Generate(int seed)
	{
		UnityEngine.Random.State state = SRand.GetState();
		SRand.SetSeed(seed);
		profile = PersonProfile.GetRandomProfile(male: true, 0);
		int num = 0;
		for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
		{
			num += World.inst.GetVillagersForLandMass(Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i]).Count;
		}
		float num2 = 0.1f;
		float num3 = 0.05f;
		if (num > 500)
		{
			num2 = 0.15f;
			num3 = 0.05f;
		}
		if (num > 750)
		{
			num2 = 0.2f;
			num3 = 0.1f;
		}
		if (num > 1000)
		{
			num2 = 0.25f;
			num3 = 0.15f;
		}
		if (num > 1500)
		{
			num2 = 0.3f;
			num3 = 0.15f;
		}
		if (num > 2000)
		{
			num2 = 0.35f;
			num3 = 0.2f;
		}
		switch (SRand.Range(0, 3))
		{
		case 0:
			AddTrait(GetUniqueTraitId(), num2 * 0.5f, num3 * 0.5f, negative: false);
			AddTrait(GetUniqueTraitId(), num2, num3, SRand.CoinFlip());
			break;
		case 1:
			AddTrait(GetUniqueTraitId(), num2, num3, negative: true);
			AddTrait(GetUniqueTraitId(), num2 * 0.5f, num3 * 0.5f, negative: false);
			break;
		case 2:
			AddTrait(GetUniqueTraitId(), num2 * 0.5f, num3 * 0.5f, SRand.CoinFlip());
			AddTrait(GetUniqueTraitId(), num2, num3 * 0.5f, SRand.CoinFlip());
			break;
		}
		SRand.SetState(state);
	}

	private void AddTrait(int traitId, float baseMag, float variance, bool negative)
	{
		Traits.Trait def = Traits.inst.GetDef(traitId);
		float magnitude = GetMagnitude(baseMag, variance, def.isPercentage);
		TraitInstance traitInstance = new TraitInstance
		{
			id = traitId,
			magnitude = magnitude,
			negative = negative
		};
		if (!def.isPercentage)
		{
			traitInstance.magnitude /= 2f;
		}
		traits.Add(traitInstance);
		if (traitId < traitMap.Length)
		{
			traitMap[traitId] = traitInstance;
		}
		else
		{
			Debug.LogError("trait id exceeds map range");
		}
	}

	public void Reappoint()
	{
		timeInOffice = 0f;
		for (int i = 0; i < traits.Count; i++)
		{
			if (Traits.inst.GetDef(traits[i].id).isPercentage)
			{
				if (traits[i].negative)
				{
					traits[i].magnitude += 0.1f;
				}
				else
				{
					traits[i].magnitude -= 0.05f;
				}
				traits[i].magnitude = Mathff.Clamp(traits[i].magnitude, 0.05f, 1f);
			}
			else
			{
				if (traits[i].negative)
				{
					traits[i].magnitude += 5f;
				}
				else
				{
					traits[i].magnitude -= 5f;
				}
				traits[i].magnitude = Mathff.Clamp(traits[i].magnitude, 1f, 50f);
			}
		}
		reappoints++;
	}

	internal float GetRemainingTerm()
	{
		return SeasonManager.inst.TimeInYear() * 3f - timeInOffice;
	}

	internal TraitInstance GetTrait(int id)
	{
		return traitMap[id];
	}

	internal bool HasSameTraits(Governor governor)
	{
		int num = 0;
		for (int i = 0; i < traits.Count; i++)
		{
			for (int j = 0; j < governor.traits.Count; j++)
			{
				if (traits[i].id == governor.traits[j].id)
				{
					num++;
				}
			}
		}
		return num == traits.Count;
	}
}
