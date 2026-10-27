using System;
using System.IO;
using System.Linq;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class CustomBannerUI : MonoBehaviour
{
	public TMP_Dropdown dropDown;

	public RawImage customBannerImage;

	public Button customBannerButton;

	public EventTrigger customBannerEventTrigger;

	public PickNameUI pickNameUI;

	private void Start()
	{
		LocalizationManager.OnLocalizeEvent += LocalizationManagerOnOnLocalizeEvent;
		dropDown.onValueChanged.AddListener(OnValueSelected);
		UpdateOptions();
		EventTrigger.Entry entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerDown
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			UpdateOptions();
		});
		customBannerEventTrigger.triggers.Add(entry);
		customBannerButton.onClick.AddListener(ClickCustomBanner);
	}

	private void ClickCustomBanner()
	{
		pickNameUI.OnUpdateBanner(customBannerImage.texture as Texture2D);
	}

	private void OnValueSelected(int itemSelected)
	{
		if (itemSelected == 0)
		{
			OpenInFileBrowser.Open(Application.persistentDataPath + Player.BannerPath);
			return;
		}
		string text = dropDown.options[itemSelected].text;
		Texture2D texture2D = Util.LoadPNG(Application.persistentDataPath + Player.BannerPath + text);
		customBannerImage.texture = texture2D;
		pickNameUI.OnUpdateBanner(texture2D);
	}

	private void LocalizationManagerOnOnLocalizeEvent()
	{
		UpdateOptions();
	}

	private void UpdateOptions()
	{
		dropDown.options.Clear();
		if (new RuntimePlatform[4]
		{
			RuntimePlatform.WindowsEditor,
			RuntimePlatform.WindowsPlayer,
			RuntimePlatform.OSXEditor,
			RuntimePlatform.OSXPlayer
		}.Contains(Application.platform))
		{
			dropDown.options.Add(new TMP_Dropdown.OptionData(ScriptLocalization.CustomBannerOpenFileLocation));
		}
		string[] files = Directory.GetFiles(Application.persistentDataPath + Player.BannerPath, "*.png", SearchOption.TopDirectoryOnly);
		for (int i = 0; i < files.Length; i++)
		{
			dropDown.options.Add(new TMP_Dropdown.OptionData(files[i].Substring(files[i].LastIndexOf("/", StringComparison.Ordinal) + 1)));
		}
	}
}
