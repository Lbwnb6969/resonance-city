using UnityEngine;

public class SetLine
{
	public int lineIndex;

	public string text;

	public Color? color;

	public SetLine(int lineIndex, string text, Color? color = null)
	{
		this.lineIndex = lineIndex;
		this.text = text;
		this.color = color;
	}

	public override string ToString()
	{
		return $"SetLine({lineIndex}, \"{text}\")";
	}
}
