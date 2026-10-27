using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class DecreeUIItem : MonoBehaviour
{
	public Image background;

	public GameObject isClosedBackground;

	public RectTransform rectT;

	public EventTrigger eventTrigger;

	public RectTransform offsetRectT;

	public EventTrigger[] scrollTriggers;

	public TextMeshProUGUI titleTMP;

	public TextMeshProUGUI priorityTMP;

	public GameObject upArrow;

	public GameObject downArrow;

	public TMP_InputField maxWorkerInput;

	public GameObject maxWorkerInputBackground;

	public TextMeshProUGUI maxWorkerTMP;

	public TextMeshProUGUI workerCountTMP;

	public TextMeshProUGUI slashTMP;

	public TextMeshProUGUI closedCountTMP;

	public Toggle closeToggle;

	public GameObject lockIcon;

	public GameObject incrementObj;

	public EventTrigger incrementTrigger;

	public GameObject decrementObj;

	public EventTrigger decrementTrigger;

	public EventTrigger filledTrigger;

	public RawImage isCustomPlayerRI;

	public RawImage wageThoughtBubbleRI;

	[HideInInspector]
	public Timer hideChangeTimer = new Timer(3f);

	[NonSerialized]
	public RectTransform layoutRectT;

	[NonSerialized]
	public bool doShowArrows;

	public int jobCategoryID = -1;
}
