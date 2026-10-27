using System.Collections.Generic;
using UnityEngine;

public class TerminalCommandBuffer
{
	public Coroutine owner;

	public List<string> lines;

	public int maxLinesSeen;

	public string name;

	public int id;

	public TerminalCommandBuffer(Coroutine owner, string name, int id)
	{
		this.owner = owner;
		this.name = name;
		this.id = id;
		lines = new List<string>();
		maxLinesSeen = 0;
	}

	public void SetLine(int lineIndex, string text, Color? color = null)
	{
		while (lines.Count <= lineIndex)
		{
			lines.Add("");
		}
		maxLinesSeen = Mathf.Max(maxLinesSeen, lineIndex + 1);
		if (color.HasValue)
		{
			string text2 = ColorUtility.ToHtmlStringRGB(color.Value);
			lines[lineIndex] = "<color=#" + text2 + ">" + text + "</color>";
		}
		else
		{
			lines[lineIndex] = text;
		}
	}

	public List<string> GetActiveLines()
	{
		List<string> list = new List<string>();
		for (int i = 0; i < maxLinesSeen; i++)
		{
			if (i < lines.Count)
			{
				list.Add(lines[i]);
			}
			else
			{
				list.Add("");
			}
		}
		return list;
	}
}
