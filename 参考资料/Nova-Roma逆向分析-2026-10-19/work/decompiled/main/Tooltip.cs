using I2.Loc;
using TMPro;
using UnityEngine;

public class Tooltip : MonoBehaviour
{
	public Localize localize;

	public TextMeshProUGUI tipText;

	public RectTransform rt;

	private void Start()
	{
		rt = GetComponent<RectTransform>();
	}
}
