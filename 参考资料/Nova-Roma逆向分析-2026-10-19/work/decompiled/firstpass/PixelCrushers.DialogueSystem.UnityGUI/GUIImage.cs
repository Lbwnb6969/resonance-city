using UnityEngine;

namespace PixelCrushers.DialogueSystem.UnityGUI;

[AddComponentMenu("")]
public class GUIImage : GUIVisibleControl
{
	public GUIImageParams image = new GUIImageParams();

	public ImageAnimation imageAnimation = new ImageAnimation();

	public override void DrawSelf(Vector2 relativeMousePosition)
	{
		if (image != null)
		{
			if (imageAnimation.animate)
			{
				imageAnimation.DrawAnimation(rect, image.texture);
			}
			else
			{
				image.Draw(rect, HasAlpha, Alpha);
			}
		}
	}

	public override void Refresh()
	{
		base.Refresh();
		if (imageAnimation.animate)
		{
			imageAnimation.RefreshAnimation(image.texture);
		}
	}
}
