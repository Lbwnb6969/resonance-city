using UnityEngine;

namespace PixelCrushers.DialogueSystem.UnityGUI;

[AddComponentMenu("")]
public class GUIButton : GUIVisibleControl
{
	public bool clickable = true;

	public GUIImageParams disabled;

	public GUIImageParams normal;

	public GUIImageParams hover;

	public GUIImageParams pressed;

	public AudioClip hoverSound;

	public AudioClip clickSound;

	public InputTrigger trigger;

	public string message = "OnClick";

	public string parameter;

	public Transform target;

	public object data;

	private bool isHovered;

	protected override GUIStyle DefaultGUIStyle => GUI.skin.button;

	public override void DrawSelf(Vector2 relativeMousePosition)
	{
		if (clickable)
		{
			DrawClickable(relativeMousePosition);
		}
		else
		{
			DrawUnclickable();
		}
	}

	private void DrawClickable(Vector2 relativeMousePosition)
	{
		if (rect.Contains(relativeMousePosition))
		{
			if (Input.GetMouseButton(0))
			{
				if (pressed != null)
				{
					pressed.Draw(rect);
				}
			}
			else
			{
				if (!isHovered)
				{
					isHovered = true;
					PlaySound(hoverSound);
				}
				if (hover != null)
				{
					hover.Draw(rect);
				}
			}
		}
		else
		{
			if (isHovered)
			{
				isHovered = false;
			}
			if (normal != null)
			{
				normal.Draw(rect);
			}
		}
		if (GUI.Button(rect, text, GuiStyle))
		{
			Click();
		}
	}

	private void DrawUnclickable()
	{
		if (disabled.texture != null)
		{
			if (disabled != null)
			{
				disabled.Draw(rect);
			}
		}
		else if (!string.IsNullOrEmpty(text))
		{
			GUI.enabled = false;
			GUI.Button(rect, text, GuiStyle);
			GUI.enabled = true;
		}
	}

	public override void Update()
	{
		base.Update();
		if (clickable && trigger.isDown)
		{
			Click();
		}
	}

	public void Click()
	{
		PlaySound(clickSound);
		Transform transform = Tools.Select(target, base.transform);
		object obj = null;
		transform.SendMessage(value: (data != null) ? data : (string.IsNullOrEmpty(parameter) ? ((object)this) : ((object)parameter)), methodName: message, options: SendMessageOptions.DontRequireReceiver);
	}
}
