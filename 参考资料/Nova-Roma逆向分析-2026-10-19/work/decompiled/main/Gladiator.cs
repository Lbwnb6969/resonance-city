using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using I2.Loc;

[Serializable]
public class Gladiator
{
	[Serializable]
	public class GladiatorSaveData : SaveClass<Gladiator, GladiatorSaveData>
	{
		public int gladiatorId;

		public string name;

		public bool isNameCustom;

		public int fame;

		public GladiatorAlignment alignment;

		public GladiatorSkills skills;

		public GladiatorSkillType primarySkill;

		public int fatigueTier;

		public int titleId;

		public List<int> titleHistory;

		public float bravery;

		public float crowdFavor;

		public int fightsWon;

		public int fightsLost;

		public int killCount;

		public Guid ownerSchoolBuildingId;

		public float fatigueTimer;

		public GladiatorVisual.Def visualDef;

		public override GladiatorSaveData Pack(Gladiator obj)
		{
			gladiatorId = obj.gladiatorId;
			name = obj.name;
			isNameCustom = obj.isNameCustom;
			fame = obj.fame;
			alignment = obj.alignment;
			skills = obj.skills;
			primarySkill = obj.primarySkill;
			fatigueTier = obj.fatigueTier;
			titleId = obj.titleId;
			titleHistory = new List<int>(obj.titleHistory);
			bravery = obj.bravery;
			crowdFavor = obj.crowdFavor;
			fightsWon = obj.fightsWon;
			fightsLost = obj.fightsLost;
			killCount = obj.killCount;
			ownerSchoolBuildingId = obj.ownerSchoolBuildingId;
			fatigueTimer = obj.fatigueTimer;
			visualDef = obj.visualDef;
			return this;
		}

		public override Gladiator Unpack(Gladiator obj)
		{
			if (obj == null)
			{
				obj = new Gladiator();
			}
			obj.gladiatorId = gladiatorId;
			obj.name = name;
			obj.isNameCustom = isNameCustom;
			obj.fame = fame;
			obj.alignment = alignment;
			obj.skills = skills;
			obj.primarySkill = primarySkill;
			obj.fatigueTier = fatigueTier;
			obj.titleId = titleId;
			obj.titleHistory = ((titleHistory != null) ? new List<int>(titleHistory) : new List<int>());
			obj.bravery = bravery;
			obj.crowdFavor = crowdFavor;
			obj.fightsWon = fightsWon;
			obj.fightsLost = fightsLost;
			obj.killCount = killCount;
			obj.ownerSchoolBuildingId = ownerSchoolBuildingId;
			obj.fatigueTimer = fatigueTimer;
			obj.visualDef = visualDef;
			return obj;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			titleId = -1;
			titleHistory = new List<int>();
			bravery = 0.5f;
			crowdFavor = 0.5f;
			ownerSchoolBuildingId = Guid.Empty;
		}
	}

	public int gladiatorId;

	public string name;

	public bool isNameCustom;

	public int fame;

	public GladiatorAlignment alignment;

	public GladiatorSkills skills;

	public GladiatorSkillType primarySkill;

	public int fatigueTier;

	public int titleId = -1;

	public List<int> titleHistory = new List<int>();

	public float bravery = 0.5f;

	public float crowdFavor = 0.5f;

	public int fightsWon;

	public int fightsLost;

	public int killCount;

	public GladiatorVisual.Def visualDef;

	public Guid ownerSchoolBuildingId = Guid.Empty;

	public float fatigueTimer;

	public static float GetFatigueDeathAdd(int fatigueTier)
	{
		return fatigueTier switch
		{
			0 => 0f, 
			1 => 0.02f, 
			2 => 0.05f, 
			3 => 0.09f, 
			4 => 0.14f, 
			5 => 0.2f, 
			_ => 0.2f, 
		};
	}

	public bool CanTrain()
	{
		return fatigueTier < 5;
	}

	public bool CanRetire()
	{
		return fame >= 4;
	}

	public string GetFatigueLabel()
	{
		return fatigueTier switch
		{
			0 => LocalizationManager.GetTranslation("gladiator_fatigue_fresh"), 
			1 => LocalizationManager.GetTranslation("gladiator_fatigue_rested"), 
			2 => LocalizationManager.GetTranslation("gladiator_fatigue_worn"), 
			3 => LocalizationManager.GetTranslation("gladiator_fatigue_tired"), 
			4 => LocalizationManager.GetTranslation("gladiator_fatigue_exhausted"), 
			5 => LocalizationManager.GetTranslation("gladiator_fatigue_spent"), 
			_ => "", 
		};
	}
}
