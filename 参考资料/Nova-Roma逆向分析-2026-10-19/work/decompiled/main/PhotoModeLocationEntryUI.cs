using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class PhotoModeLocationEntryUI : MonoBehaviour
{
	public Button captureBtn;

	public Button focusBtn;

	public Button removeBtn;

	public TextMeshProUGUI nameTMP;

	public EventTrigger eTrigger;

	public GameObject disabledObj;

	[NonSerialized]
	public RectTransform layoutRectT;

	public RectTransform rectT;

	[NonSerialized]
	public int doPositionInstant;
}
