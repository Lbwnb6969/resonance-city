using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class InputSearch : MonoBehaviour
{
	public class OnSelectionEvent : UnityEvent<string>
	{
	}

	[SerializeField]
	private Button itemPrefab;

	[SerializeField]
	private Transform container;

	[SerializeField]
	private Transform scrollView;

	private List<string> options = new List<string>(32);

	private List<Button> optionPool = new List<Button>(32);

	public OnSelectionEvent onSelectionEvent = new OnSelectionEvent();

	public Color tintColor;

	public void SetOptions(List<string> newOptions)
	{
		options.Clear();
		for (int i = 0; i < newOptions.Count; i++)
		{
			options.Add(newOptions[i]);
			while (options.Count > optionPool.Count)
			{
				Button button = Object.Instantiate(itemPrefab, container);
				optionPool.Add(button);
				int idx = optionPool.Count - 1;
				ColorBlock colors = button.colors;
				colors.normalColor = (((idx + 1) % 2 == 0) ? colors.normalColor : tintColor);
				button.colors = colors;
				optionPool[idx].onClick.AddListener(() =>
				{
					onSelectionEvent.Invoke(OnOptionSelected(idx));
				});
			}
			optionPool[i].GetComponentInChildren<TextMeshProUGUI>().text = newOptions[i];
			optionPool[i].gameObject.SetActive(value: true);
		}
		for (int num = options.Count; num < optionPool.Count; num++)
		{
			optionPool[num].gameObject.SetActive(value: false);
		}
		TryShow();
	}

	public void TryShow()
	{
		scrollView.gameObject.SetActive(options.Count > 0);
	}

	public void Hide()
	{
		scrollView.gameObject.SetActive(value: false);
	}

	public string OnOptionSelected(int idx)
	{
		return options[idx];
	}
}
