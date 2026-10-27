using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class TourismPopup : MonoBehaviour
{
	public TextMeshProUGUI msgText;

	public GameObject codeObj;

	public TextMeshProUGUI codeText;

	public Button codeCopyButon;

	public Button okayButton;

	public void Show(string text)
	{
		gameObject.SetActive(value: true);
		msgText.text = text;
		codeObj.SetActive(value: false);
		okayButton.onClick.RemoveAllListeners();
		okayButton.onClick.AddListener(() =>
		{
			gameObject.SetActive(value: false);
		});
	}

	public void Show(string text, UnityAction onOk)
	{
		gameObject.SetActive(value: true);
		msgText.text = text;
		codeObj.SetActive(value: false);
		okayButton.onClick.RemoveAllListeners();
		okayButton.onClick.AddListener(() =>
		{
			onOk();
			gameObject.SetActive(value: false);
		});
	}

	public void Show(string text, string code, UnityAction onOk)
	{
		gameObject.SetActive(value: true);
		msgText.text = text;
		codeObj.SetActive(value: true);
		codeText.text = code;
		codeCopyButon.onClick.RemoveAllListeners();
		codeCopyButon.onClick.AddListener(() =>
		{
			code.CopyToClipboard();
		});
		okayButton.onClick.RemoveAllListeners();
		okayButton.onClick.AddListener(() =>
		{
			onOk();
			gameObject.SetActive(value: false);
		});
	}
}
