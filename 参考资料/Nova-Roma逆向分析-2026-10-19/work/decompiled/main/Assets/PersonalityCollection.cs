using System;
using I2.Loc;

namespace Assets;

public static class PersonalityCollection
{
	public static Type[] aiPersonalityTypes = new Type[3]
	{
		typeof(ByTheBookPersonality),
		typeof(XenophobePersonality),
		typeof(HippiePersonality)
	};

	public static string[] aiPersonalityKeys = new string[3] { "bythebook", "xenophobe", "hippie" };

	public static string GetFriendlyName(string key)
	{
		return LocalizationManager.GetTranslation(key + "PersonalityFriendlyName");
	}

	public static string GetFriendlyName(int key)
	{
		return GetFriendlyName(aiPersonalityKeys[key]);
	}

	public static Type GetTypeByKey(string key)
	{
		for (int i = 0; i < aiPersonalityKeys.Length; i++)
		{
			if (aiPersonalityKeys[i] == key)
			{
				return aiPersonalityTypes[i];
			}
		}
		return null;
	}

	public static string GetKeyByType(Type type)
	{
		for (int i = 0; i < aiPersonalityTypes.Length; i++)
		{
			if (aiPersonalityTypes[i] == type)
			{
				return aiPersonalityKeys[i];
			}
		}
		return "";
	}
}
