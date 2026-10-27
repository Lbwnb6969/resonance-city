using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class WorkshopConsole : MonoBehaviour
{
	public GameObject consoleLinePrefab;

	public GameObject lineContainer;

	public void Writeline(string text)
	{
		GameObject gameObject = Object.Instantiate(consoleLinePrefab);
		gameObject.transform.SetParent(lineContainer.transform);
		gameObject.transform.localScale = new Vector3(1f, 1f, 1f);
		gameObject.GetComponentInChildren<TextMeshProUGUI>().text = text;
		Invoke("ScrollToBottom", 0f);
	}

	private void ScrollToBottom()
	{
		GetComponent<ScrollRect>().verticalNormalizedPosition = 0f;
	}

	private void Start()
	{
	}

	private void Update()
	{
	}
}
