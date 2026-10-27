using System;

[AttributeUsage(AttributeTargets.Method, AllowMultiple = false)]
public class TerminalCommandAttribute : Attribute
{
	public string commandName;

	public string description;

	public string category;

	public bool isCheat;

	public TerminalCommandAttribute(string commandName, string description = "", string category = "General", bool isCheat = false)
	{
		this.commandName = commandName.ToLower();
		this.description = description;
		this.category = category;
		this.isCheat = isCheat;
	}
}
