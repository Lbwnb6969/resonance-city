using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class MerchantResourceItemUI : MonoBehaviour
{
	public Image resourceIcon;

	public StaticTooltipHook resourceTooltip;

	public TMP_InputField amtInput;

	public TextMeshProUGUI priceTMP;

	public TextMeshProUGUI storageTMP;

	public TextMeshProUGUI costTMP;

	public Image background;

	public EventTrigger tooltipTrigger;

	public Image exclamationIcon;

	[NonSerialized]
	public int rID;

	[NonSerialized]
	public bool isSellAmountOffset;
}
