using UnityEngine;
using UnityEngine.UI;

public class OnOffElement : MonoBehaviour
{
	public Image yesImage;

	public Image noImage;

	private bool stateOn = true;

	public bool State
	{
		get
		{
			return stateOn;
		}
		set
		{
			stateOn = value;
			yesImage.gameObject.SetActive(stateOn);
			noImage.gameObject.SetActive(!stateOn);
		}
	}
}
