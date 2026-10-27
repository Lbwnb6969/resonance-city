using System;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

namespace Assets.Code.UI;

public class SaveLoadOption : MonoBehaviour
{
	public TextMeshProUGUI title;

	public TextMeshProUGUI date;

	public TextMeshProUGUI time;

	public TextMeshProUGUI population;

	public TextMeshProUGUI year;

	public TextMeshProUGUI resources;

	public TextMeshProUGUI resources2;

	public GameObject autosave;

	public RawImage coverImage;

	public Button clickable;

	public Button deleteButton;

	public GameObject cloud;

	public TMP_InputField cloudCode;

	private string path = string.Empty;

	public GameObject consoleSelectContainer;

	public GameObject consoleDeleteContainer;

	public Button selectBtn;

	public Button expandBtn;

	public void SetPath(string loadPath)
	{
		path = loadPath;
	}

	public void SetTitle(string title)
	{
		this.title.text = title;
	}

	public void SetDate(DateTime date)
	{
		time.text = date.ToShortTimeString();
		this.date.text = date.ToShortDateString();
	}

	public void SetPopulation(int population)
	{
		this.population.SetText(ScriptLocalization.SaveLoadCitizens, population);
	}

	public void SetYear(int year)
	{
		this.year.SetText(ScriptLocalization.SaveLoadYear, year);
	}

	public void SetNewSaveUI()
	{
		SetTitle(ScriptLocalization.SaveLoadUIMakeNewSave);
		year.gameObject.SetActive(value: false);
		population.gameObject.SetActive(value: false);
		time.gameObject.SetActive(value: false);
		date.gameObject.SetActive(value: false);
		resources.gameObject.SetActive(value: false);
		resources2.gameObject.SetActive(value: false);
		SetIsAutosave(show: false);
		cloud.gameObject.SetActive(value: false);
		deleteButton.gameObject.SetActive(value: false);
	}

	public void SetResources(ResourceAmount amount)
	{
		resources.text = string.Empty;
		resources2.text = string.Empty;
		string[] array = amount.ToString(Environment.NewLine).Split(new string[1] { Environment.NewLine }, StringSplitOptions.None);
		int i;
		for (i = 0; i < 4 && i < array.Length; i++)
		{
			TextMeshProUGUI textMeshProUGUI = resources;
			textMeshProUGUI.text = textMeshProUGUI.text + array[i] + Environment.NewLine;
		}
		for (; i < array.Length; i++)
		{
			TextMeshProUGUI textMeshProUGUI2 = resources2;
			textMeshProUGUI2.text = textMeshProUGUI2.text + array[i] + Environment.NewLine;
		}
	}

	public void SetCode(string code)
	{
		cloud.SetActive(!string.IsNullOrEmpty(code));
		cloudCode.text = code;
	}

	public void OnClick(UnityAction action)
	{
		clickable.onClick.AddListener(action);
	}

	public void OnDelete(UnityAction action)
	{
		deleteButton.gameObject.SetActive(value: true);
		deleteButton.onClick.AddListener(action);
	}

	public void SetImage(Texture texture)
	{
		coverImage.texture = texture;
	}

	public void SetIsAutosave(bool show)
	{
		autosave.SetActive(show);
	}
}
