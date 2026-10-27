using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using I2.Loc;

namespace Assets;

[Serializable]
public class PersonProfile
{
	private static bool inited;

	private static int numOfPraenomenM;

	private static int numOfPraenomenF;

	private static int numOfNomenM;

	private static int numOfNomenF;

	private static int numOfCognomen;

	private static int numOfSlave;

	public int Type;

	[OptionalField(VersionAdded = 2)]
	private bool male;

	[OptionalField(VersionAdded = 2)]
	private int cognomen;

	[OptionalField(VersionAdded = 2)]
	private int nomen;

	[OptionalField(VersionAdded = 2)]
	private int praenomen;

	[OptionalField(VersionAdded = 2)]
	private int slave;

	[OptionalField(VersionAdded = 2)]
	public int version;

	public string Name
	{
		get
		{
			Init();
			return Type switch
			{
				0 => PraenomenById(praenomen, male) + " " + NomenById(nomen, male) + " " + CognomenById(cognomen), 
				1 => PraenomenById(praenomen, male) + " " + NomenById(nomen, male), 
				2 => NomenById(nomen, male) + " " + SlaveById(slave), 
				3 => SlaveById(slave), 
				_ => "Wanderer", 
			};
		}
	}

	public static string PraenomenById(int id, bool male)
	{
		return LocalizationManager.GetTermTranslation(string.Format("Names/Praenomen{0}_{1}", male ? "M" : "F", id));
	}

	public static string NomenById(int id, bool male)
	{
		return LocalizationManager.GetTermTranslation(string.Format("Names/Nomen{0}_{1}", male ? "M" : "F", id));
	}

	public static string CognomenById(int id)
	{
		return LocalizationManager.GetTermTranslation($"Names/Cognomen_{id}");
	}

	public static string SlaveById(int id)
	{
		return LocalizationManager.GetTermTranslation($"Names/Slave_{id}");
	}

	private static void Init()
	{
		if (inited)
		{
			return;
		}
		inited = true;
		List<string> termsList = LocalizationManager.GetTermsList("Names");
		for (int i = 0; i < termsList.Count; i++)
		{
			string text = termsList[i];
			if (text.Contains("PraenomenM"))
			{
				numOfPraenomenM++;
			}
			if (text.Contains("PraenomenF"))
			{
				numOfPraenomenF++;
			}
			if (text.Contains("NomenM"))
			{
				numOfNomenM++;
			}
			if (text.Contains("NomenF"))
			{
				numOfNomenF++;
			}
			if (text.Contains("Cognomen"))
			{
				numOfCognomen++;
			}
			if (text.Contains("Slave"))
			{
				numOfSlave++;
			}
		}
	}

	public string GetTitleTerm()
	{
		if (Type == 0)
		{
			return "personui_persontitle_elite";
		}
		if (Type == 1)
		{
			return "personui_persontitle_plebeian";
		}
		if (Type == 2)
		{
			return "personui_persontitle_freedman";
		}
		if (Type == 3)
		{
			return "personui_persontitle_formerslave";
		}
		return string.Empty;
	}

	public static PersonProfile GetRandomProfile(bool male = true, int type = -1)
	{
		Init();
		PersonProfile personProfile = new PersonProfile();
		if (type == -1)
		{
			personProfile.Type = SRand.Range(0, 4);
		}
		else
		{
			personProfile.Type = type;
		}
		personProfile.male = male;
		personProfile.praenomen = SRand.Range(0, personProfile.male ? numOfPraenomenM : numOfPraenomenF);
		personProfile.nomen = SRand.Range(0, personProfile.male ? numOfNomenM : numOfNomenF);
		personProfile.cognomen = SRand.Range(0, numOfCognomen);
		personProfile.slave = SRand.Range(0, numOfSlave);
		personProfile.version = 1;
		return personProfile;
	}

	public static string GetDockName(string dockString)
	{
		return dockString + " " + NomenById(SRand.Range(0, numOfNomenM), male: true);
	}
}
