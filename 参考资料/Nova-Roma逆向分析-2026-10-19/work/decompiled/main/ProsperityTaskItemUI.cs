using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.UI;

public class ProsperityTaskItemUI : MonoBehaviour
{
	public TextMeshProUGUI descriptionTMP;

	public TextMeshProUGUI godNameTMP;

	public Localize godNameLocalize;

	[FormerlySerializedAs("priceTMP")]
	public TextMeshProUGUI rewardTMP;

	public GameObject newObj;

	public Slider progressSlider;

	public GameObject completionIcon;

	public Button completeBtn;

	public Localize completeLocalize;

	public GameObject angerContainer;

	public GameObject disableContainer;

	public TextMeshProUGUI disableTxt;
}
