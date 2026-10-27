using System.Reflection;

public static class ReflectionExtensions
{
	public static T GetFieldValue<T>(this object obj, string name)
	{
		BindingFlags bindingAttr = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
		return (T)(obj.GetType().GetField(name, bindingAttr)?.GetValue(obj));
	}
}
