using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ChangeLanguage : MonoBehaviour
{
	public TextMeshProUGUI languageButtonText;

	public Button languageButton;

	public const string EnglishI2Name = "English";

	public const string GermanI2Name = "German";

	public const string FrenchI2Name = "French";

	public const string SChineseI2Name = "Simplified Chinese";

	public const string TChineseI2Name = "Traditional Chinese";

	public const string JapeneseI2Name = "Japanese";

	public const string RussianI2Name = "Russian";

	public const string SpanishLatamI2Name = "Spanish (Latin Americas)";

	public const string SpanishSpainI2Name = "Spanish (Spain)";

	public const string KoreanI2Name = "Korean";

	public const string PolishI2Name = "Polish";

	public const string BrazilianPortugueseI2Name = "Portuguese (Brazil)";

	public const string PortuguesePortugalI2Name = "Portuguese (Portugal)";

	public const string ItalianI2Name = "Italian";

	public const string UkrainianI2Name = "Ukrainian";

	public const string TurkishI2Name = "Turkish";

	public const string CzechI2Name = "Czech";

	public const string HungarianI2Name = "Hungarian";

	public Button englishButton;

	public Button germanButton;

	public Button frenchButton;

	public Button sChineseButton;

	public Button tChineseButton;

	public Button japeneseButton;

	public Button russianButton;

	public Button spanishLatamButton;

	public Button spanishSpainButton;

	public Button koreanButton;

	public Button polishButton;

	public Button brazilianPortugueseButton;

	public Button portuguesePortugalButton;

	public Button italianButton;

	public Button ukrainianButton;

	public Button turkishButton;

	public Button czechButton;

	public Button hungarianButton;

	public TextMeshProUGUI englishName;

	public TextMeshProUGUI germanName;

	public TextMeshProUGUI frenchName;

	public TextMeshProUGUI sChineseName;

	public TextMeshProUGUI tChineseName;

	public TextMeshProUGUI japeneseName;

	public TextMeshProUGUI russianName;

	public TextMeshProUGUI spanishLatamName;

	public TextMeshProUGUI spanishSpainName;

	public TextMeshProUGUI koreanName;

	public TextMeshProUGUI polishName;

	public TextMeshProUGUI brazilianPortugueseName;

	public TextMeshProUGUI portuguesePortugalName;

	public TextMeshProUGUI italianName;

	public TextMeshProUGUI ukrainianName;

	public TextMeshProUGUI turkishName;

	public TextMeshProUGUI czechName;

	public TextMeshProUGUI hungarianName;

	public Image flagImage;

	public GameObject dropdownList;

	public Button clickCatcher;

	private void Start()
	{
		languageButton.onClick.AddListener(() =>
		{
			dropdownList.SetActive(value: true);
			SfxSystem.PlayUiSelect();
		});
		englishButton.onClick.AddListener(EnglishMode);
		germanButton.onClick.AddListener(GermanMode);
		frenchButton.onClick.AddListener(FrenchMode);
		sChineseButton.onClick.AddListener(sChineseMode);
		tChineseButton.onClick.AddListener(tChineseMode);
		japeneseButton.onClick.AddListener(JapaneseMode);
		russianButton.onClick.AddListener(RussianMode);
		spanishLatamButton.onClick.AddListener(SpanishLatamMode);
		spanishSpainButton.onClick.AddListener(SpanishSpainMode);
		koreanButton.onClick.AddListener(KoreanMode);
		polishButton.onClick.AddListener(PolishMode);
		brazilianPortugueseButton.onClick.AddListener(BrazilianPortugueseMode);
		portuguesePortugalButton.onClick.AddListener(PortuguesePortugalMode);
		italianButton.onClick.AddListener(ItalianMode);
		ukrainianButton.onClick.AddListener(UkrainianMode);
		turkishButton.onClick.AddListener(TurkishMode);
		czechButton.onClick.AddListener(CzechMode);
		hungarianButton.onClick.AddListener(HungarianMode);
		englishButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		germanButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		frenchButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		sChineseButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		tChineseButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		japeneseButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		russianButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		spanishLatamButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		spanishSpainButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		koreanButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		polishButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		brazilianPortugueseButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		portuguesePortugalButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		italianButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		ukrainianButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		turkishButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		czechButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		hungarianButton.onClick.AddListener(SfxSystem.PlayUiSelect);
		clickCatcher.onClick.AddListener(() =>
		{
			dropdownList.SetActive(value: false);
		});
		if (LocalizationManager.CurrentLanguage == "English")
		{
			EnglishMode();
		}
		if (LocalizationManager.CurrentLanguage == "German")
		{
			GermanMode();
		}
		if (LocalizationManager.CurrentLanguage == "French")
		{
			FrenchMode();
		}
		if (LocalizationManager.CurrentLanguage == "Simplified Chinese")
		{
			sChineseMode();
		}
		if (LocalizationManager.CurrentLanguage == "Traditional Chinese")
		{
			tChineseMode();
		}
		if (LocalizationManager.CurrentLanguage == "Japanese")
		{
			JapaneseMode();
		}
		if (LocalizationManager.CurrentLanguage == "Russian")
		{
			RussianMode();
		}
		if (LocalizationManager.CurrentLanguage == "Spanish (Latin Americas)")
		{
			SpanishLatamMode();
		}
		if (LocalizationManager.CurrentLanguage == "Spanish (Spain)")
		{
			SpanishSpainMode();
		}
		if (LocalizationManager.CurrentLanguage == "Korean")
		{
			KoreanMode();
		}
		if (LocalizationManager.CurrentLanguage == "Polish")
		{
			PolishMode();
		}
		if (LocalizationManager.CurrentLanguage == "Portuguese (Brazil)")
		{
			BrazilianPortugueseMode();
		}
		if (LocalizationManager.CurrentLanguage == "Portuguese (Portugal)")
		{
			PortuguesePortugalMode();
		}
		if (LocalizationManager.CurrentLanguage == "Italian")
		{
			ItalianMode();
		}
		if (LocalizationManager.CurrentLanguage == "Ukrainian")
		{
			UkrainianMode();
		}
		if (LocalizationManager.CurrentLanguage == "Turkish")
		{
			TurkishMode();
		}
		if (LocalizationManager.CurrentLanguage == "Czech")
		{
			CzechMode();
		}
		if (LocalizationManager.CurrentLanguage == "Hungarian")
		{
			HungarianMode();
		}
	}

	public void EnglishMode()
	{
		LocalizationManager.CurrentLanguage = "English";
		dropdownList.SetActive(value: false);
		languageButtonText.text = englishName.text;
	}

	public void GermanMode()
	{
		LocalizationManager.CurrentLanguage = "German";
		dropdownList.SetActive(value: false);
		languageButtonText.text = germanName.text;
	}

	public void FrenchMode()
	{
		LocalizationManager.CurrentLanguage = "French";
		dropdownList.SetActive(value: false);
		languageButtonText.text = frenchName.text;
	}

	public void sChineseMode()
	{
		LocalizationManager.CurrentLanguage = "Simplified Chinese";
		dropdownList.SetActive(value: false);
		languageButtonText.text = sChineseName.text;
	}

	public void tChineseMode()
	{
		LocalizationManager.CurrentLanguage = "Traditional Chinese";
		dropdownList.SetActive(value: false);
		languageButtonText.text = tChineseName.text;
	}

	public void JapaneseMode()
	{
		LocalizationManager.CurrentLanguage = "Japanese";
		dropdownList.SetActive(value: false);
		languageButtonText.text = japeneseName.text;
	}

	public void RussianMode()
	{
		LocalizationManager.CurrentLanguage = "Russian";
		dropdownList.SetActive(value: false);
		languageButtonText.text = russianName.text;
	}

	public void SpanishLatamMode()
	{
		LocalizationManager.CurrentLanguage = "Spanish (Latin Americas)";
		dropdownList.SetActive(value: false);
		languageButtonText.text = spanishLatamName.text;
	}

	public void SpanishSpainMode()
	{
		LocalizationManager.CurrentLanguage = "Spanish (Spain)";
		dropdownList.SetActive(value: false);
		languageButtonText.text = spanishSpainName.text;
	}

	public void KoreanMode()
	{
		LocalizationManager.CurrentLanguage = "Korean";
		dropdownList.SetActive(value: false);
		languageButtonText.text = koreanName.text;
	}

	public void PolishMode()
	{
		LocalizationManager.CurrentLanguage = "Polish";
		dropdownList.SetActive(value: false);
		languageButtonText.text = polishName.text;
	}

	public void BrazilianPortugueseMode()
	{
		LocalizationManager.CurrentLanguage = "Portuguese (Brazil)";
		dropdownList.SetActive(value: false);
		languageButtonText.text = brazilianPortugueseName.text;
	}

	public void PortuguesePortugalMode()
	{
		LocalizationManager.CurrentLanguage = "Portuguese (Portugal)";
		dropdownList.SetActive(value: false);
		languageButtonText.text = portuguesePortugalName.text;
	}

	public void ItalianMode()
	{
		LocalizationManager.CurrentLanguage = "Italian";
		dropdownList.SetActive(value: false);
		languageButtonText.text = italianName.text;
	}

	public void UkrainianMode()
	{
		LocalizationManager.CurrentLanguage = "Ukrainian";
		dropdownList.SetActive(value: false);
		languageButtonText.text = ukrainianName.text;
	}

	public void TurkishMode()
	{
		LocalizationManager.CurrentLanguage = "Turkish";
		dropdownList.SetActive(value: false);
		languageButtonText.text = turkishName.text;
	}

	public void CzechMode()
	{
		LocalizationManager.CurrentLanguage = "Czech";
		dropdownList.SetActive(value: false);
		languageButtonText.text = czechName.text;
	}

	public void HungarianMode()
	{
		LocalizationManager.CurrentLanguage = "Hungarian";
		dropdownList.SetActive(value: false);
		languageButtonText.text = hungarianName.text;
	}
}
