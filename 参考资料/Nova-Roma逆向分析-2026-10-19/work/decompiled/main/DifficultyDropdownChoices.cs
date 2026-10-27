using System.Collections.Generic;
using I2.Loc;
using Sirenix.OdinInspector;

public static class DifficultyDropdownChoices
{
	public static readonly (int id, string term)[] InvasionFrequency = new (int, string)[5]
	{
		(0, "difficultyui_settings_invasion_frequency_0"),
		(1, "difficultyui_settings_invasion_frequency_1"),
		(2, "difficultyui_settings_invasion_frequency_2"),
		(3, "difficultyui_settings_invasion_frequency_3"),
		(4, "difficultyui_settings_invasion_frequency_4")
	};

	public static readonly (int id, string term)[] InvasionIntensity = new (int, string)[4]
	{
		(0, "difficultyui_settings_invasion_intensity_0"),
		(1, "difficultyui_settings_invasion_intensity_1"),
		(2, "difficultyui_settings_invasion_intensity_2"),
		(3, "difficultyui_settings_invasion_intensity_3")
	};

	public static readonly (int id, string term)[] MerchantFrequency = new (int, string)[5]
	{
		(0, "difficultyui_settings_merchant_frequency_0"),
		(1, "difficultyui_settings_merchant_frequency_1"),
		(2, "difficultyui_settings_merchant_frequency_2"),
		(3, "difficultyui_settings_merchant_frequency_3"),
		(4, "difficultyui_settings_merchant_frequency_4")
	};

	public static readonly (int id, string term)[] Frequency = new (int, string)[5]
	{
		(0, "frequency_never"),
		(1, "frequency_low"),
		(2, "frequency_medium"),
		(3, "frequency_high"),
		(4, "frequency_veryhigh")
	};

	public static readonly (int id, string term)[] Magnitude = new (int, string)[5]
	{
		(0, "magnitude_none"),
		(1, "magnitude_low"),
		(2, "magnitude_medium"),
		(3, "magnitude_high"),
		(4, "magnitude_veryhigh")
	};

	public static IEnumerable<ValueDropdownItem<int>> GetDropdownItems((int id, string term)[] source)
	{
		if (source != null)
		{
			for (int i = 0; i < source.Length; i++)
			{
				(int, string) tuple = source[i];
				string text = TryGetTranslation(tuple.Item2);
				yield return new ValueDropdownItem<int>(text, tuple.Item1);
			}
		}
	}

	private static string TryGetTranslation(string term)
	{
		if (string.IsNullOrEmpty(term))
		{
			return term;
		}
		try
		{
			if (LocalizationManager.TryGetTranslation(term, out var Translation))
			{
				return Translation;
			}
		}
		catch
		{
		}
		return term;
	}
}
