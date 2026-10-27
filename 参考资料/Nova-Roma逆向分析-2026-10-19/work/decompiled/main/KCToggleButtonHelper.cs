using UnityEngine;
using UnityEngine.UI;

public class KCToggleButtonHelper : MonoBehaviour
{
	public Vector3 downOffset;

	public Sprite downSprite;

	public Color downColor;

	private Sprite upSprite;

	private Color upColor;

	private bool lastButtonState;

	public Transform targetXform;

	private void Start()
	{
		if (!targetXform)
		{
			targetXform = transform;
		}
		Toggle component = GetComponent<Toggle>();
		component.onValueChanged.AddListener(ToggleChanged);
		upSprite = targetXform.GetComponent<Image>().sprite;
		upColor = targetXform.GetComponent<Image>().color;
		ToggleChanged(component.isOn);
	}

	private void ToggleChanged(bool down)
	{
		if (down != lastButtonState)
		{
			lastButtonState = down;
			Image component = targetXform.GetComponent<Image>();
			if (component != null)
			{
				component.color = (down ? downColor : upColor);
			}
			if (down && downSprite != null)
			{
				targetXform.GetComponent<Image>().sprite = downSprite;
			}
			else
			{
				targetXform.GetComponent<Image>().sprite = upSprite;
			}
		}
	}
}
