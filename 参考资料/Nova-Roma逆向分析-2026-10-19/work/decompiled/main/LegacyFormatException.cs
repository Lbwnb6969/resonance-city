using System;

public class LegacyFormatException : InvalidOperationException
{
	public LegacyFormatException(string message)
		: base(message)
	{
	}
}
