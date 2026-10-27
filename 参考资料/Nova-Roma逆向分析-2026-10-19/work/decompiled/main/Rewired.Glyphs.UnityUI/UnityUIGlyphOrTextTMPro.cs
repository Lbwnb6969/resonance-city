using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Rewired.Glyphs.UnityUI;

public class UnityUIGlyphOrTextTMPro : GlyphOrTextBase<Image, Sprite, TMP_Text>
{
	protected override string textString
	{
		get
		{
			if (!(textComponent != null))
			{
				return string.Empty;
			}
			return textComponent.text;
		}
		set
		{
			if (!(textComponent == null))
			{
				textComponent.text = value;
			}
		}
	}

	protected override Sprite glyphGraphic
	{
		get
		{
			if (!(glyphComponent != null))
			{
				return null;
			}
			return glyphComponent.sprite;
		}
		set
		{
			if (!(glyphComponent == null))
			{
				glyphComponent.sprite = value;
			}
		}
	}
}
