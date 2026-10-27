using System;
using System.Reflection;
using UnityEngine;

public static class ComputeBufferNaming
{
	private static readonly PropertyInfo NameProperty = typeof(ComputeBuffer).GetProperty("name", BindingFlags.Instance | BindingFlags.Public);

	public static void SetName(ComputeBuffer buffer, string name)
	{
		if (buffer == null || string.IsNullOrEmpty(name) || NameProperty == null || !NameProperty.CanWrite)
		{
			return;
		}
		try
		{
			NameProperty.SetValue(buffer, name, null);
		}
		catch (ArgumentException)
		{
		}
		catch (TargetException)
		{
		}
		catch (TargetInvocationException)
		{
		}
	}
}
