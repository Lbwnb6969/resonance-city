using System;

[Serializable]
public struct GladiatorSkills
{
	public int bestiarius;

	public int retiarius;

	public int secutor;

	public int GetSkill(ColosseumRound.Role type)
	{
		return type switch
		{
			ColosseumRound.Role.Bestiarius => bestiarius, 
			ColosseumRound.Role.Retiarus => retiarius, 
			ColosseumRound.Role.Secutor => secutor, 
			_ => 0, 
		};
	}

	public void AddSkill(GladiatorSkillType type, int amount)
	{
		switch (type)
		{
		case GladiatorSkillType.Bestiarius:
			bestiarius += amount;
			break;
		case GladiatorSkillType.Retiarius:
			retiarius += amount;
			break;
		case GladiatorSkillType.Secutor:
			secutor += amount;
			break;
		}
	}

	public static string GetSkillIcon(GladiatorSkillType type)
	{
		return type switch
		{
			GladiatorSkillType.Bestiarius => "<sprite name=icon_console_a>", 
			GladiatorSkillType.Retiarius => "<sprite name=icon_console_b>", 
			GladiatorSkillType.Secutor => "<sprite name=icon_console_y>", 
			_ => "?", 
		};
	}

	public string ToDisplayString()
	{
		return $"{GetSkillIcon(GladiatorSkillType.Bestiarius)} {bestiarius} | {GetSkillIcon(GladiatorSkillType.Retiarius)} {retiarius} | {GetSkillIcon(GladiatorSkillType.Secutor)} {secutor}";
	}

	public int TotalSkillPoints()
	{
		return bestiarius + retiarius + secutor;
	}

	public int GetHighestSkill(out GladiatorSkillType highestType)
	{
		highestType = GladiatorSkillType.Bestiarius;
		int num = bestiarius;
		if (retiarius > num)
		{
			num = retiarius;
			highestType = GladiatorSkillType.Retiarius;
		}
		if (secutor > num)
		{
			num = secutor;
			highestType = GladiatorSkillType.Secutor;
		}
		return num;
	}
}
