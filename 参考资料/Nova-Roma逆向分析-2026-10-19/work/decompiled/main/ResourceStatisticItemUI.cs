using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ResourceStatisticItemUI : MonoBehaviour
{
	public int resourceID = -1;

	public Image icon;

	public TextMeshProUGUI countTMP;

	public GameObject exclamationObj;

	public Toggle toggle;

	public RectTransform rectT;

	[NonSerialized]
	public int currStorage;

	[NonSerialized]
	public int maxStorage;

	[NonSerialized]
	public float prevExclamationTime = float.MinValue;
}
