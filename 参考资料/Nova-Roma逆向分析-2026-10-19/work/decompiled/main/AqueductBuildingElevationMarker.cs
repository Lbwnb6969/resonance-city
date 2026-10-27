using Drawing;
using TMPro;
using UnityEngine;

public class AqueductBuildingElevationMarker : MonoBehaviour
{
	public const float heightOffset = 0.7f;

	public TextMeshPro text;

	public Vector3 textOffset = Vector3.up * 0.7f;

	private void LateUpdate()
	{
		if (!gameObject.activeSelf)
		{
			return;
		}
		Draw.ingame.DashedLine(transform.position + textOffset, transform.position, 0.1f, 0.1f, Color.white);
		using (Draw.ingame.WithLineWidth(2f))
		{
			float num = 0.15f;
			float num2 = 0.06f;
			int num3 = 2;
			for (int i = 0; i < num3; i++)
			{
				Draw.ingame.Circle(transform.position, Vector3.up, num, Color.white);
				num -= num2;
			}
		}
		Draw.ingame.SolidCircle(transform.position, Vector3.up, 0.03f, Color.white);
		UpdateText();
	}

	private void UpdateText()
	{
		Vector3 position = Cam.inst.cam.transform.position;
		Vector3 forward = transform.position - position;
		transform.rotation = Quaternion.LookRotation(forward, Vector3.up);
		text.transform.position = transform.position + textOffset;
		text.text = $"<size=3.5>{transform.position.y * 10f:F1}m";
	}
}
