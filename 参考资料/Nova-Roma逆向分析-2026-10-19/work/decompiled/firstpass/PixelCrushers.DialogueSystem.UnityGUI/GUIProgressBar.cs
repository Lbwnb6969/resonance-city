using UnityEngine;

namespace PixelCrushers.DialogueSystem.UnityGUI;

[AddComponentMenu("")]
public class GUIProgressBar : GUIVisibleControl
{
	public enum Origin
	{
		Top,
		Bottom,
		Left,
		Right,
		HorizontalCenter,
		VerticalCenter
	}

	public Origin origin;

	public Texture2D emptyImage;

	public Texture2D fullImage;

	public float progress;

	public override void DrawSelf(Vector2 relativeMousePosition)
	{
		if (emptyImage != null)
		{
			GUI.DrawTexture(rect, emptyImage);
		}
		float num = Mathf.Clamp(progress, 0f, 1f);
		Rect position;
		Rect texCoords;
		switch (origin)
		{
		case Origin.Top:
		{
			float height = rect.height * num;
			position = new Rect(rect.x, rect.y, rect.width, height);
			texCoords = new Rect(0f, 1f - num, 1f, num);
			break;
		}
		case Origin.Bottom:
		{
			float num5 = rect.height * num;
			position = new Rect(rect.x, rect.yMax - num5, rect.width, num5);
			texCoords = new Rect(0f, 0f, 1f, num);
			break;
		}
		default:
			position = new Rect(rect.x, rect.y, rect.width * num, rect.height);
			texCoords = new Rect(0f, 0f, num, 1f);
			break;
		case Origin.Right:
		{
			float num4 = rect.width * num;
			position = new Rect(rect.xMax - num4, rect.y, num4, rect.height);
			texCoords = new Rect(1f - num, 0f, num, 1f);
			break;
		}
		case Origin.HorizontalCenter:
		{
			float num3 = rect.width * num;
			position = new Rect(rect.x + 0.5f * (rect.width - num3), rect.y, num3, rect.height);
			texCoords = new Rect(0.5f * (1f - num), 0f, num, 1f);
			break;
		}
		case Origin.VerticalCenter:
		{
			float num2 = rect.height * num;
			position = new Rect(rect.x, rect.y + 0.5f * (rect.height - num2), rect.width, num2);
			texCoords = new Rect(0f, 0.5f * (1f - num), 1f, num);
			break;
		}
		}
		if (fullImage != null)
		{
			GUI.DrawTextureWithTexCoords(position, fullImage, texCoords);
		}
	}
}
