using System;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class TownNameUI : MonoBehaviour
{
	[Serializable]
	public class TownNameSaveData : SaveClass<TownNameUI, TownNameSaveData>
	{
		public int highestPopulation;

		public string townName;

		public string townTitle;

		public override TownNameSaveData Pack(TownNameUI obj)
		{
			highestPopulation = obj.highestPopulation;
			townName = obj.townName;
			townTitle = obj.citySizeLabel.text;
			return this;
		}

		public override TownNameUI Unpack(TownNameUI obj)
		{
			if ((bool)obj)
			{
				obj.highestPopulation = highestPopulation;
				obj.townName = townName;
				obj.cityNameInput.text = townName;
				obj.citySizeLabel.text = obj.GetSizeString(obj.highestPopulation);
			}
			return obj;
		}
	}

	public TextMeshProUGUI citySizeLabel;

	public TMP_InputField cityNameInput;

	private TownSizeThresolds[] townSizes = new TownSizeThresolds[10]
	{
		new TownSizeThresolds
		{
			name = "UnpopulatedLand",
			peopleRequired = 0
		},
		new TownSizeThresolds
		{
			name = "QuietHamlet",
			peopleRequired = 1
		},
		new TownSizeThresolds
		{
			name = "SmallVillage",
			peopleRequired = 25
		},
		new TownSizeThresolds
		{
			name = "BurgeoningTown",
			peopleRequired = 100
		},
		new TownSizeThresolds
		{
			name = "BustlingCity",
			peopleRequired = 250
		},
		new TownSizeThresolds
		{
			name = "HumbleKingdom",
			peopleRequired = 1000
		},
		new TownSizeThresolds
		{
			name = "ThrivingKingdom",
			peopleRequired = 1500
		},
		new TownSizeThresolds
		{
			name = "DignifiedKingdom",
			peopleRequired = 2000
		},
		new TownSizeThresolds
		{
			name = "MagnificentKingdom",
			peopleRequired = 3500
		},
		new TownSizeThresolds
		{
			name = "KingdomOfTheGods",
			peopleRequired = 5000
		}
	};

	public static TownNameUI inst;

	private int highestPopulation;

	public string townName;

	public Button editButton;

	private bool deferCityNameInteractableFalse;

	private string GetSizeString(int population)
	{
		string key = "";
		for (int i = 0; i < townSizes.Length; i++)
		{
			if (townSizes[i].peopleRequired <= population)
			{
				key = townSizes[i].name;
			}
		}
		return GetTownUIName(key);
	}

	private void Awake()
	{
		inst = this;
		cityNameInput.onSelect.AddListener((string val) =>
		{
			DisableHotkeys();
		});
		cityNameInput.onEndEdit.AddListener((string val) =>
		{
			EnableHotkeys();
			if (val != townName)
			{
				SetTownName(val.Trim());
			}
			deferCityNameInteractableFalse = true;
		});
		editButton.onClick.AddListener(() =>
		{
			cityNameInput.interactable = !cityNameInput.interactable;
			if (cityNameInput.interactable)
			{
				cityNameInput.ActivateInputField();
			}
			else
			{
				cityNameInput.DeactivateInputField();
			}
		});
		Reset();
	}

	public void Reset()
	{
		highestPopulation = 0;
		cityNameInput.text = townName;
		citySizeLabel.text = GetTownUIName(townSizes[0].name);
	}

	public string GetTownUIName(string key)
	{
		return LocalizationManager.GetTranslation("CityNamesTownUI" + key);
	}

	public string GetDescription(string key)
	{
		return LocalizationManager.GetTranslation("CityNamesDescription" + key);
	}

	public string GetDecreeName(string key)
	{
		return LocalizationManager.GetTranslation("CityNamesDecree" + key);
	}

	private void EnableHotkeys()
	{
		GameState.inst.AlphaNumericHotkeysEnabled = true;
	}

	private void DisableHotkeys()
	{
		GameState.inst.AlphaNumericHotkeysEnabled = false;
	}

	public void SetTownNameQuiet(string newName)
	{
		townName = newName;
		cityNameInput.text = townName;
	}

	public void SetTownName(string newName)
	{
		if (!string.IsNullOrEmpty(townName))
		{
			_ = "<color=#00FFFF>" + townName + "</color>";
		}
		SetTownNameQuiet(newName);
		SfxSystem.inst.PlayFromBank("RenameThing", Camera.main.transform.position);
	}

	private static string UppercaseFirst(string s)
	{
		if (string.IsNullOrEmpty(s))
		{
			return string.Empty;
		}
		char[] array = s.ToCharArray();
		array[0] = char.ToUpper(array[0]);
		return new string(array);
	}
}
