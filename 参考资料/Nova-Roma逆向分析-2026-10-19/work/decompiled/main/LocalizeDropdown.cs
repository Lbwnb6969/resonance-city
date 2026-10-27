using System;
using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class LocalizeDropdown : MonoBehaviour
{
	[Serializable]
	public struct Entry
	{
		public string term;

		public Sprite sprite;
	}

	public List<Entry> _Entries = new List<Entry>();

	public void Start()
	{
		LocalizationManager.OnLocalizeEvent += OnLocalize;
		OnLocalize();
	}

	public void OnDestroy()
	{
		LocalizationManager.OnLocalizeEvent -= OnLocalize;
	}

	private void OnEnable()
	{
		if (_Entries.Count == 0)
		{
			FillValues();
		}
		OnLocalize();
	}

	public void OnLocalize()
	{
		if (enabled && !(gameObject == null) && gameObject.activeInHierarchy && !string.IsNullOrEmpty(LocalizationManager.CurrentLanguage))
		{
			UpdateLocalization();
		}
	}

	private void FillValues()
	{
		Dropdown component = GetComponent<Dropdown>();
		if (component == null && I2Utils.IsPlaying())
		{
			FillValuesTMPro();
			return;
		}
		foreach (Dropdown.OptionData option in component.options)
		{
			_Entries.Add(new Entry
			{
				term = option.text,
				sprite = option.image
			});
		}
	}

	public void UpdateLocalization()
	{
		Dropdown component = GetComponent<Dropdown>();
		if (component == null)
		{
			UpdateLocalizationTMPro();
			return;
		}
		component.options.Clear();
		foreach (Entry entry in _Entries)
		{
			string translation = LocalizationManager.GetTranslation(entry.term);
			component.options.Add(new Dropdown.OptionData(translation, entry.sprite));
		}
		component.RefreshShownValue();
	}

	public void UpdateLocalizationTMPro()
	{
		TMP_Dropdown component = GetComponent<TMP_Dropdown>();
		if (component == null)
		{
			return;
		}
		component.options.Clear();
		foreach (Entry entry in _Entries)
		{
			string translation = LocalizationManager.GetTranslation(entry.term);
			component.options.Add(new TMP_Dropdown.OptionData(translation, entry.sprite, Color.white));
		}
		component.RefreshShownValue();
	}

	private void FillValuesTMPro()
	{
		TMP_Dropdown component = GetComponent<TMP_Dropdown>();
		if (component == null)
		{
			return;
		}
		foreach (TMP_Dropdown.OptionData option in component.options)
		{
			_Entries.Add(new Entry
			{
				term = option.text,
				sprite = option.image
			});
		}
	}
}
