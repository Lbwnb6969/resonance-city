using UnityEngine;
using UnityEngine.UI;

public class PipShower : MonoBehaviour
{
	private Image pip;

	private void Start()
	{
		pip = transform.Find("Pip").GetComponent<Image>();
	}

	private void Update()
	{
		pip.enabled = GamepadControl.inst.isControllerActive;
	}
}
