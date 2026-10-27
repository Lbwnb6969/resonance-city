using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildButtonUI : MonoBehaviour
{
	public Image icon;

	public StaticTooltipHook unlockedTooltipHook;

	public StaticTooltipHook lockedTooltipHook;

	public Button btn;

	public GameObject lockOverlay;

	public GameObject unlockedContainer;

	public TextMeshProUGUI unlockedTMP;

	public RawImage isSelectedRawImg;

	private int unlockedCount;

	[NonSerialized]
	public BuildGroupUI group;

	public void OnItemUnlocked()
	{
		unlockedCount++;
		unlockedTMP.text = unlockedCount.ToString();
		unlockedContainer.SetActive(value: true);
	}

	public void HideUnlock()
	{
		unlockedContainer.SetActive(value: false);
		unlockedCount = 0;
		unlockedTMP.text = "0";
	}

	public void Unlock()
	{
		lockOverlay.SetActive(value: false);
	}

	public void Reset()
	{
		lockOverlay.SetActive(value: true);
		unlockedCount = 0;
		unlockedTMP.text = "0";
		unlockedContainer.SetActive(value: false);
		isSelectedRawImg.enabled = false;
	}
}
