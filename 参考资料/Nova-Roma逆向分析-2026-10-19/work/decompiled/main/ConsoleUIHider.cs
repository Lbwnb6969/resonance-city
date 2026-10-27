using UnityEngine;

public class ConsoleUIHider : MonoBehaviour
{
	private void Start()
	{
	}

	private void Update()
	{
		gameObject.SetActive(!GameUI.IsOnConsole());
	}
}
