using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UnitTabUI : MonoBehaviour
{
	public Toggle toggle;

	public Image icon;

	public TextMeshProUGUI amtTMP;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(gameObject, v);
		isVisible = v;
	}
}
