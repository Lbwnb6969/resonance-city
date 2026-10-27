using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class ChariotRaceTrackEntryUI : MonoBehaviour
{
	public Image icon;

	public TextMeshProUGUI nameTMP;

	public TextMeshProUGUI oddsTMP;

	public TextMeshProUGUI rewardTMP;

	public TextMeshProUGUI sponserAmtTMP;

	public Button sponsorBtn;

	public StaticTooltipHook sponsorTooltip;

	public EventTrigger eTrigger;
}
