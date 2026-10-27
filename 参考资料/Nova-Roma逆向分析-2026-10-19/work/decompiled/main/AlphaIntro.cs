using UnityEngine;

public class AlphaIntro : MonoBehaviour
{
	private void Start()
	{
		if (Application.isEditor)
		{
			gameObject.SetActive(value: false);
		}
	}

	public void ClickedOk()
	{
		gameObject.SetActive(value: false);
	}
}
