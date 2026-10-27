using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class LogisticsRouteEntryUI : MonoBehaviour
{
	public Button focusSourceBtn;

	public Button focusTargetBtn;

	public Button deleteBtn;

	public Image sourceImg;

	public Image targetImg;

	public TextMeshProUGUI statusTxt;

	public TextMeshProUGUI resourceTxt;

	public TextMeshProUGUI targetNameTMP;

	public TextMeshProUGUI sourceNameTMP;

	public Image cart;

	public RectTransform path;

	public Image arrowHead;

	public Image arrowBody;

	public Color active;

	public Color neutral;

	public GameObject activeFrame;

	public void SetCartProgress(float t)
	{
		cart.GetComponent<RectTransform>().anchoredPosition = path.anchoredPosition + path.sizeDelta * new Vector3(t, 1f, 1f);
	}

	internal void UpdateArrowColor(bool activeRoute)
	{
		arrowHead.color = (activeRoute ? active : neutral);
		arrowBody.color = (activeRoute ? active : neutral);
	}
}
