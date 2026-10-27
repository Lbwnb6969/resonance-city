using System.Text;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class InfoBase : MonoBehaviour
{
	protected delegate void ClickExamine();

	public Button ExamineButton;

	protected Timer timer = new Timer(5f);

	public GameObject info;

	protected event ClickExamine clicked;

	private void Start()
	{
		ExamineButton.gameObject.SetActive(value: false);
		info.SetActive(value: false);
	}

	public void OnClickedExamine()
	{
		clicked?.Invoke();
		info.SetActive(value: true);
		timer.ForceExpire();
	}

	public void OnPointerEnter()
	{
		ExamineButton.gameObject.SetActive(value: true);
	}

	public void OnPointerExit()
	{
		ExamineButton.gameObject.SetActive(value: false);
		info.SetActive(value: false);
	}

	public void AppendShippingAndTotal(StringBuilder builder, int shippingTotal, string totalStr)
	{
		builder.Append("\n");
		builder.Append((shippingTotal > 0) ? "+ " : "- ");
		builder.AppendFormat(ScriptLocalization.FromShipping, Mathff.Abs(shippingTotal));
		builder.Append("\n--------------------\n");
		builder.AppendFormat(ScriptLocalization.TotalChangeLastYear, totalStr);
	}

	protected void SetTitle(int curr, int max = -1)
	{
		if (info.gameObject.activeSelf)
		{
			if (max == -1)
			{
				info.transform.GetChild(0).GetChild(0).GetComponent<TextMeshProUGUI>()
					.SetText("{0}", curr);
			}
			else
			{
				info.transform.GetChild(0).GetChild(0).GetComponent<TextMeshProUGUI>()
					.SetText("{0}/{1}", curr, max);
			}
		}
	}
}
