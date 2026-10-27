using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GroupOptionUI : MonoBehaviour
{
	public RawImage overlay;

	public RawImage pictureRaw;

	public RawImage loadingRaw;

	public TextMeshProUGUI titleTMP;

	public TextMeshProUGUI dateTMP;

	public TextMeshProUGUI citizenTMP;

	public Button confirmBtn;

	public TextMeshProUGUI confirmTMP;

	public Button trashBtn;

	public RectTransform itemContainer;

	public ScrollRect itemScrollRect;

	public RectTransform itemScrollRectT;

	public ToggleGroup toggleGroup;

	public GameObject autoSaveContainer;

	public Button infoBtn;

	public GameObject hoverOverlay;

	public void OnPointerEnter()
	{
		Util.SetActive(hoverOverlay, active: false);
	}

	public void OnPointerExit()
	{
		Util.SetActive(hoverOverlay, active: true);
	}
}
