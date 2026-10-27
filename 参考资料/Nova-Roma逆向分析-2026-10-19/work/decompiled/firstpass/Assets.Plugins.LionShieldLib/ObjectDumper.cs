using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Text;

namespace Assets.Plugins.LionShieldLib;

public class ObjectDumper
{
	private int _level;

	private readonly int _indentSize;

	private readonly StringBuilder _stringBuilder;

	private readonly List<int> _hashListOfFoundElements;

	private ObjectDumper(int indentSize)
	{
		_indentSize = indentSize;
		_stringBuilder = new StringBuilder();
		_hashListOfFoundElements = new List<int>();
	}

	public static string Dump(object element)
	{
		return Dump(element, 2);
	}

	public static string Dump(object element, int indentSize)
	{
		return new ObjectDumper(indentSize).DumpElement(element);
	}

	private string DumpElement(object element)
	{
		if (element == null || element is ValueType || element is string)
		{
			Write(FormatValue(element));
		}
		else
		{
			Type type = element.GetType();
			if (!typeof(IEnumerable).IsAssignableFrom(type))
			{
				Write("{{{0}}}", type.FullName);
				_hashListOfFoundElements.Add(element.GetHashCode());
				_level++;
			}
			if (element is IEnumerable enumerable)
			{
				foreach (object item in enumerable)
				{
					if (item is IEnumerable && !(item is string))
					{
						_level++;
						DumpElement(item);
						_level--;
					}
					else if (!AlreadyTouched(item))
					{
						DumpElement(item);
					}
					else
					{
						Write("{{{0}}} <-- bidirectional reference found", item.GetType().FullName);
					}
				}
			}
			else
			{
				MemberInfo[] members = element.GetType().GetMembers(BindingFlags.Instance | BindingFlags.Public);
				foreach (MemberInfo memberInfo in members)
				{
					FieldInfo fieldInfo = memberInfo as FieldInfo;
					PropertyInfo propertyInfo = memberInfo as PropertyInfo;
					if (fieldInfo == null && propertyInfo == null)
					{
						continue;
					}
					Type type2 = ((fieldInfo != null) ? fieldInfo.FieldType : propertyInfo.PropertyType);
					object obj = ((fieldInfo != null) ? fieldInfo.GetValue(element) : propertyInfo.GetValue(element, null));
					if (type2.IsValueType || type2 == typeof(string))
					{
						Write("{0}: {1}", memberInfo.Name, FormatValue(obj));
						continue;
					}
					bool flag = typeof(IEnumerable).IsAssignableFrom(type2);
					Write("{0}: {1}", memberInfo.Name, flag ? "..." : "{ }");
					bool num = !flag && AlreadyTouched(obj);
					_level++;
					if (!num)
					{
						DumpElement(obj);
					}
					else
					{
						Write("{{{0}}} <-- bidirectional reference found", obj.GetType().FullName);
					}
					_level--;
				}
			}
			if (!typeof(IEnumerable).IsAssignableFrom(type))
			{
				_level--;
			}
		}
		return _stringBuilder.ToString();
	}

	private bool AlreadyTouched(object value)
	{
		if (value == null)
		{
			return false;
		}
		int hashCode = value.GetHashCode();
		for (int i = 0; i < _hashListOfFoundElements.Count; i++)
		{
			if (_hashListOfFoundElements[i] == hashCode)
			{
				return true;
			}
		}
		return false;
	}

	private void Write(string value, params object[] args)
	{
		string text = new string(' ', _level * _indentSize);
		if (args != null)
		{
			value = string.Format(value, args);
		}
		_stringBuilder.AppendLine(text + value);
	}

	private string FormatValue(object o)
	{
		if (o == null)
		{
			return "null";
		}
		if (o is DateTime dateTime)
		{
			return dateTime.ToShortDateString();
		}
		if (o is string)
		{
			return $"\"{o}\"";
		}
		if (o is char && (char)o == '\0')
		{
			return string.Empty;
		}
		if (o is ValueType)
		{
			return o.ToString();
		}
		if (o is IEnumerable)
		{
			return "...";
		}
		return "{ }";
	}
}
