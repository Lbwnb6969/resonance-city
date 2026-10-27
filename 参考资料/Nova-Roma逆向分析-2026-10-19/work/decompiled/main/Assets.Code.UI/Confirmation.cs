using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

namespace Assets.Code.UI;

public class Confirmation : MonoBehaviour
{
	public Button yesButton;

	public Button noButton;

	public void ShowConfirmation(UnityAction onYes, UnityAction onNo)
	{
		yesButton.onClick.RemoveAllListeners();
		noButton.onClick.RemoveAllListeners();
		yesButton.onClick.AddListener(() =>
		{
			try
			{
				onYes?.Invoke();
			}
			finally
			{
				gameObject.SetActive(value: false);
			}
		});
		noButton.onClick.AddListener(() =>
		{
			try
			{
				onNo?.Invoke();
			}
			finally
			{
				gameObject.SetActive(value: false);
			}
		});
		gameObject.SetActive(value: true);
	}

	public void Reset()
	{
		yesButton.onClick.RemoveAllListeners();
		noButton.onClick.RemoveAllListeners();
		gameObject.SetActive(value: false);
	}
}
