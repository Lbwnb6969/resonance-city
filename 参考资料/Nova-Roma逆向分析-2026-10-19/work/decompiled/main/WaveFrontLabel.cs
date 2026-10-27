using TMPro;
using UnityEngine;

public class WaveFrontLabel : MonoBehaviour
{
	[Tooltip("The number text rendered inside the bubble.")]
	public TextMeshPro text;

	[Tooltip("Background bubble sprite that sits behind the text.")]
	public SpriteRenderer background;

	[Tooltip("Child that gets the constant-screen-size scaling (text + bubble live under here). Anything parented to the ROOT instead (e.g. a fixed-size pointer sphere) keeps its authored world size. If unset, the whole root is scaled (old behaviour).")]
	public Transform scaledContent;

	public void Place(Vector3 worldPos, Camera cam, float scale)
	{
		Transform transform = base.transform;
		transform.position = worldPos;
		Transform transform2 = ((scaledContent != null) ? scaledContent : transform);
		transform2.rotation = Quaternion.LookRotation(transform2.position - cam.transform.position, Vector3.up);
		transform2.localScale = new Vector3(scale, scale, scale);
	}

	public void SetText(string value)
	{
		if (text != null)
		{
			text.text = value;
		}
	}
}
