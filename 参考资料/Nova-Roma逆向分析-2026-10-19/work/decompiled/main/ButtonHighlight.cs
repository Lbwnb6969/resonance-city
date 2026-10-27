using UnityEngine;
using UnityEngine.UI;

[ExecuteInEditMode]
public class ButtonHighlight : MonoBehaviour
{
	public float thickness = 0.45f;

	public Image image;

	private float scaler;

	private void Start()
	{
		image = GetComponent<Image>();
		scaler = GetComponentInParent<CanvasScaler>().scaleFactor;
	}

	private void Update()
	{
		image.material.SetFloat("_TextureWidth", GetComponent<RectTransform>().rect.width * scaler);
		image.material.SetFloat("_TextureHeight", GetComponent<RectTransform>().rect.height * scaler);
		image.material.SetFloat("_Thickness", thickness);
	}
}
