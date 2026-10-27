using System;

[AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
public class TerminalParameterHintsAttribute : Attribute
{
	public string parameterName;

	public string[] hints;

	public TerminalParameterHintsAttribute(string parameterName, params string[] hints)
	{
		this.parameterName = parameterName;
		this.hints = hints;
	}
}
