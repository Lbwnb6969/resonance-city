using UnityEngine;

namespace PixelCrushers.DialogueSystem.UnityGUI;

[AddComponentMenu("")]
public class GUIVisibleControl : GUIControl
{
	public LocalizedTextTable localizedText;

	public string text;

	public string guiStyleName;

	private FormattedText formattingToApply;

	private bool isFormattingApplied;

	private GUIStyle guiStyle;

	private Color originalGUIColor = Color.white;

	private float alpha = 1f;

	private string originalTextValue = string.Empty;

	public float Alpha
	{
		get
		{
			return alpha;
		}
		set
		{
			alpha = value;
		}
	}

	public bool HasAlpha
	{
		get
		{
			if (Alpha < 0.999f)
			{
				return Application.isPlaying;
			}
			return false;
		}
	}

	protected virtual GUIStyle DefaultGUIStyle => GUI.skin.label;

	protected GUIStyle GuiStyle
	{
		get
		{
			return guiStyle;
		}
		set
		{
			guiStyle = value;
		}
	}

	public override void Awake()
	{
		base.Awake();
		originalTextValue = text;
	}

	public virtual void Start()
	{
		if (localizedText != null)
		{
			UseLocalizedText(localizedText);
		}
	}

	public void UseLocalizedText(LocalizedTextTable localizedText)
	{
		this.localizedText = localizedText;
		if (localizedText != null && localizedText.ContainsField(originalTextValue))
		{
			text = localizedText[originalTextValue];
		}
	}

	public void ApplyAlphaToGUIColor()
	{
		if (HasAlpha)
		{
			originalGUIColor = GUI.color;
			GUI.color = UnityGUITools.ColorWithAlpha(GUI.color, Alpha);
		}
	}

	public void RestoreGUIColor()
	{
		if (HasAlpha)
		{
			GUI.color = originalGUIColor;
		}
	}

	public virtual void SetFormattedText(FormattedText formattedText)
	{
		text = formattedText.text;
		formattingToApply = formattedText;
		isFormattingApplied = false;
		GuiStyle = null;
		NeedToUpdateLayout = true;
	}

	public void SetUnformattedText(string text)
	{
		this.text = text;
		formattingToApply = null;
		guiStyle = null;
		NeedToUpdateLayout = true;
	}

	public override void UpdateLayoutSelf()
	{
		guiStyle = null;
		isFormattingApplied = false;
		ApplyFormatting();
		base.UpdateLayoutSelf();
	}

	protected void SetGUIStyle()
	{
		if (guiStyle == null)
		{
			guiStyle = UnityGUITools.GetGUIStyle(guiStyleName, DefaultGUIStyle);
		}
	}

	protected void ApplyFormatting()
	{
		SetGUIStyle();
		if (!isFormattingApplied && formattingToApply != null)
		{
			text = formattingToApply.text;
			guiStyle = UnityGUITools.ApplyFormatting(formattingToApply, guiStyle);
			isFormattingApplied = true;
		}
	}

	public override void AutoSizeSelf()
	{
		ApplyFormatting();
		if (autoSize.autoSizeWidth)
		{
			float value = new GUIStyle(guiStyle)
			{
				padding = new RectOffset(0, 0, 0, 0)
			}.CalcSize(new GUIContent(text)).x + (float)guiStyle.padding.left + (float)guiStyle.padding.right;
			value = Mathf.Clamp(value, scaledRect.minPixelWidth, autoSize.maxWidth.GetPixelValue(WindowSize.x));
			value += (float)(autoSize.padding.left + autoSize.padding.right);
			rect = new Rect(GetAutoSizeX(value), rect.y, value, rect.height);
		}
		if (autoSize.autoSizeHeight)
		{
			float value2 = guiStyle.CalcHeight(new GUIContent(text), rect.width);
			value2 = Mathf.Clamp(value2, scaledRect.minPixelHeight, autoSize.maxHeight.GetPixelValue(WindowSize.y));
			value2 += (float)(autoSize.padding.top + autoSize.padding.bottom);
			rect = new Rect(rect.x, GetAutoSizeY(value2), rect.width, value2);
		}
	}

	private float GetAutoSizeX(float width)
	{
		switch (scaledRect.alignment)
		{
		case ScaledRectAlignment.TopLeft:
		case ScaledRectAlignment.MiddleLeft:
		case ScaledRectAlignment.BottomLeft:
			return rect.x;
		case ScaledRectAlignment.TopCenter:
		case ScaledRectAlignment.MiddleCenter:
		case ScaledRectAlignment.BottomCenter:
			return rect.x + 0.5f * (rect.width - width);
		case ScaledRectAlignment.TopRight:
		case ScaledRectAlignment.MiddleRight:
		case ScaledRectAlignment.BottomRight:
			return rect.x + (rect.width - width);
		default:
			return rect.x;
		}
	}

	private float GetAutoSizeY(float height)
	{
		switch (scaledRect.alignment)
		{
		case ScaledRectAlignment.TopLeft:
		case ScaledRectAlignment.TopCenter:
		case ScaledRectAlignment.TopRight:
			return rect.y;
		case ScaledRectAlignment.MiddleLeft:
		case ScaledRectAlignment.MiddleCenter:
		case ScaledRectAlignment.MiddleRight:
			return rect.y + 0.5f * (rect.height - height);
		case ScaledRectAlignment.BottomLeft:
		case ScaledRectAlignment.BottomCenter:
		case ScaledRectAlignment.BottomRight:
			return rect.y + (rect.height - height);
		default:
			return rect.y;
		}
	}

	public void PlaySound(AudioClip audioClip)
	{
		if (audioClip != null && Camera.main != null)
		{
			AudioSource audioSource = Camera.main.GetComponent<AudioSource>();
			if (audioSource == null)
			{
				audioSource = Camera.main.gameObject.AddComponent<AudioSource>();
			}
			audioSource.PlayOneShot(audioClip);
		}
	}
}
