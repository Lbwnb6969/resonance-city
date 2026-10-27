using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class CrowdinCredits : MonoBehaviour
{
	public TextMeshProUGUI titlePrefab;

	public GameObject layoutPrefab;

	public TextMeshProUGUI creditPrefab;

	public ContentSizeFitter contentSizeFitter;

	public VerticalLayoutGroup layoutGroup;

	public Transform creditsContainer;

	public TMP_FontAsset[] fontsToPickFrom;

	private string[] usernameIgnoreList = new string[3] { "mpeddicord", "pete.angst", "deloquac" };

	private string[] languageWhiteList = new string[15]
	{
		"German", "French", "Chinese Simplified", "Chinese Traditional", "Dutch", "Italian", "Japanese", "Korean", "Norwegian", "Polish",
		"Portuguese, Brazilian", "Romanian", "Russian", "Spanish", "Ukrainian"
	};

	private string[] germanTs = new string[6] { "Alexander Vock", "ANNOFlo", "Katherine Clawson", "Lukas Jahn", "Max Ampere", "Zayne Faulhaber" };

	private string[] frenchTs = new string[2] { "Buche", "Florian Poncabaré" };

	private string[] chineseSTs = new string[2] { "deloquac ( 德拉呱 )", "煙嵐御風" };

	private string[] chineseTTS = new string[2] { "deloquac ( 德拉呱 )", "煙嵐御風" };

	public void Rebuild()
	{
		Dictionary<string, List<string>> dictionary = new Dictionary<string, List<string>>();
		dictionary["German"] = new List<string>();
		string[] array = germanTs;
		foreach (string item in array)
		{
			dictionary["German"].Add(item);
		}
		dictionary["French"] = new List<string>();
		array = frenchTs;
		foreach (string item2 in array)
		{
			dictionary["French"].Add(item2);
		}
		dictionary["Chinese Simplified"] = new List<string>();
		array = chineseSTs;
		foreach (string item3 in array)
		{
			dictionary["Chinese Simplified"].Add(item3);
		}
		dictionary["Chinese Traditional"] = new List<string>();
		array = chineseTTS;
		foreach (string item4 in array)
		{
			dictionary["Chinese Traditional"].Add(item4);
		}
		foreach (string item5 in (Resources.Load("crowdinuserdata") as TextAsset).text.Split('\n').Skip(1))
		{
			if (string.IsNullOrEmpty(item5.Trim()))
			{
				continue;
			}
			string[] array2 = SplitCSV(item5);
			string text = Regex.Replace(array2[0], "\\([^\\)]*\\)", string.Empty).Replace('＠', '@').Trim();
			string value = text;
			Match match = Regex.Match(array2[0], "\\(([^\\)]*)\\)");
			if (match.Groups.Count > 1)
			{
				value = match.Groups[1].Value;
			}
			if (usernameIgnoreList.Contains(value))
			{
				continue;
			}
			array = array2[1].Split(';');
			for (int i = 0; i < array.Length; i++)
			{
				string text2 = array[i].Trim();
				if (languageWhiteList.Contains(text2))
				{
					if (!dictionary.ContainsKey(text2))
					{
						dictionary[text2] = new List<string>();
					}
					dictionary[text2].Add(text);
				}
			}
		}
		foreach (Transform item6 in creditsContainer.Cast<Transform>().ToList())
		{
			Object.DestroyImmediate(item6.gameObject);
		}
		foreach (string key in dictionary.Keys)
		{
			TextMeshProUGUI textMeshProUGUI = Object.Instantiate(titlePrefab);
			textMeshProUGUI.gameObject.SetActive(value: true);
			textMeshProUGUI.GetComponent<Localize>().Term = LangKeyToTerm(key);
			textMeshProUGUI.transform.SetParent(creditsContainer, worldPositionStays: false);
			GameObject gameObject = Object.Instantiate(layoutPrefab);
			gameObject.gameObject.SetActive(value: true);
			gameObject.transform.SetParent(creditsContainer, worldPositionStays: false);
			foreach (string item7 in dictionary[key])
			{
				TextMeshProUGUI textMeshProUGUI2 = Object.Instantiate(creditPrefab);
				textMeshProUGUI2.gameObject.SetActive(value: true);
				textMeshProUGUI2.text = item7;
				textMeshProUGUI2.font = FindBestFont(item7, key);
				textMeshProUGUI2.transform.SetParent(gameObject.transform, worldPositionStays: false);
			}
		}
		layoutGroup.enabled = true;
		contentSizeFitter.enabled = true;
		Invoke("DisableLayoutElements", 1f);
	}

	private TMP_FontAsset FindBestFont(string str, string langCatagory)
	{
		return null;
	}

	private string LangKeyToTerm(string langKey)
	{
		return langKey switch
		{
			"Portuguese, Brazilian" => "LanguageBrazilianPortuguese", 
			"Chinese Simplified" => "LanguageChineseSimplified", 
			"Chinese Traditional" => "LanguageChineseTraditional", 
			_ => "Language" + langKey, 
		};
	}

	private void DisableLayoutElements()
	{
		contentSizeFitter.enabled = false;
		layoutGroup.enabled = false;
	}

	protected virtual string[] SplitCSV(string line)
	{
		RegexOptions options = RegexOptions.IgnoreCase | RegexOptions.Multiline | RegexOptions.IgnorePatternWhitespace;
		MatchCollection matchCollection = new Regex("(?:^|,)(\\\"(?:[^\\\"]+|\\\"\\\")*\\\"|[^,]*)", options).Matches(line);
		string[] array = new string[matchCollection.Count];
		int num = 0;
		foreach (Match item in matchCollection)
		{
			array[num++] = item.Groups[0].Value.Trim('"').Trim(',').Trim('"')
				.Trim();
		}
		return array;
	}

	private void Update()
	{
	}

	public void LayoutComponentsActive(bool active)
	{
		ContentSizeFitter[] componentsInChildren = GetComponentsInChildren<ContentSizeFitter>();
		for (int i = 0; i < componentsInChildren.Length; i++)
		{
			componentsInChildren[i].enabled = active;
		}
		VerticalLayoutGroup[] componentsInChildren2 = GetComponentsInChildren<VerticalLayoutGroup>();
		for (int i = 0; i < componentsInChildren2.Length; i++)
		{
			componentsInChildren2[i].enabled = active;
		}
		HorizontalLayoutGroup[] componentsInChildren3 = GetComponentsInChildren<HorizontalLayoutGroup>();
		for (int i = 0; i < componentsInChildren3.Length; i++)
		{
			componentsInChildren3[i].enabled = active;
		}
		GridLayoutGroup[] componentsInChildren4 = GetComponentsInChildren<GridLayoutGroup>();
		for (int i = 0; i < componentsInChildren4.Length; i++)
		{
			componentsInChildren4[i].enabled = active;
		}
	}
}
