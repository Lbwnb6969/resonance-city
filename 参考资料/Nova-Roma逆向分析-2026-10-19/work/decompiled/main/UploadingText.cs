using TMPro;
using UnityEngine;

public class UploadingText : MonoBehaviour
{
	private TextMeshProUGUI text;

	private void Start()
	{
		text = GetComponent<TextMeshProUGUI>();
	}

	private void Update()
	{
		Color color = text.color;
		color.a = Mathf.PingPong(Time.unscaledTime, 0.5f) + 0.5f;
		text.color = color;
	}
}
