using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using UnityEngine;

public class TerminalManager : MonoBehaviour
{
	private class TerminalCommandInfo
	{
		public MethodInfo method;

		public object target;

		public TerminalCommandAttribute attribute;

		public ParameterInfo[] parameters;

		public Dictionary<string, string[]> parameterHints = new Dictionary<string, string[]>();
	}

	public static TerminalManager inst;

	private Dictionary<string, TerminalCommandInfo> commands = new Dictionary<string, TerminalCommandInfo>();

	private List<Coroutine> runningCommands = new List<Coroutine>();

	private List<TerminalCommandBuffer> commandBuffers = new List<TerminalCommandBuffer>();

	private int nextCommandId = 1;

	private string pendingCheatCommandLine;

	private void Awake()
	{
		inst = this;
		StartCoroutine(RegisterCommandsAsync());
	}

	private IEnumerator RegisterCommandsAsync()
	{
		Debug.Log("Terminal: Starting command registration...");
		Type[] types = Assembly.GetAssembly(typeof(TerminalManager)).GetTypes();
		int processedTypes = 0;
		Type[] array = types;
		foreach (Type type in array)
		{
			MethodInfo[] methods = type.GetMethods(BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
			foreach (MethodInfo methodInfo in methods)
			{
				TerminalCommandAttribute customAttribute = methodInfo.GetCustomAttribute<TerminalCommandAttribute>();
				if (customAttribute != null)
				{
					RegisterCommand(customAttribute.commandName, methodInfo, null, customAttribute);
				}
			}
			methods = type.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
			foreach (MethodInfo methodInfo2 in methods)
			{
				TerminalCommandAttribute customAttribute2 = methodInfo2.GetCustomAttribute<TerminalCommandAttribute>();
				if (customAttribute2 != null)
				{
					object singletonInstance = GetSingletonInstance(type);
					if (singletonInstance != null)
					{
						RegisterCommand(customAttribute2.commandName, methodInfo2, singletonInstance, customAttribute2);
					}
				}
			}
			processedTypes++;
			if (processedTypes % 50 == 0)
			{
				yield return null;
			}
		}
		Debug.Log($"Terminal: Registered {commands.Count} commands from main assembly ({processedTypes} types processed)");
	}

	private object GetSingletonInstance(Type type)
	{
		FieldInfo field = type.GetField("inst", BindingFlags.Static | BindingFlags.Public);
		if (field != null)
		{
			return field.GetValue(null);
		}
		FieldInfo field2 = type.GetField("instance", BindingFlags.Static | BindingFlags.Public);
		if (field2 != null)
		{
			return field2.GetValue(null);
		}
		PropertyInfo property = type.GetProperty("inst", BindingFlags.Static | BindingFlags.Public);
		if (property != null)
		{
			return property.GetValue(null);
		}
		PropertyInfo property2 = type.GetProperty("instance", BindingFlags.Static | BindingFlags.Public);
		if (property2 != null)
		{
			return property2.GetValue(null);
		}
		return null;
	}

	private void RegisterCommand(string commandName, MethodInfo method, object target, TerminalCommandAttribute attribute)
	{
		if (commands.ContainsKey(commandName))
		{
			Debug.LogWarning("Terminal: Command '" + commandName + "' already registered, skipping duplicate");
			return;
		}
		TerminalCommandInfo terminalCommandInfo = new TerminalCommandInfo
		{
			method = method,
			target = target,
			attribute = attribute,
			parameters = method.GetParameters()
		};
		foreach (TerminalParameterHintsAttribute customAttribute in method.GetCustomAttributes<TerminalParameterHintsAttribute>())
		{
			terminalCommandInfo.parameterHints[customAttribute.parameterName] = customAttribute.hints;
		}
		commands[commandName] = terminalCommandInfo;
	}

	public void ExecuteCommand(string commandLine)
	{
		if (string.IsNullOrWhiteSpace(commandLine))
		{
			return;
		}
		string[] array = ParseCommandLine(commandLine);
		if (array.Length == 0)
		{
			return;
		}
		string text = array[0].ToLower();
		string[] args = array.Skip(1).ToArray();
		if (!commands.ContainsKey(text))
		{
			TerminalUI.inst.PrintError("Unknown command: " + text);
			return;
		}
		TerminalCommandInfo terminalCommandInfo = commands[text];
		if (terminalCommandInfo.attribute.isCheat && !Player.inst.CheatsEnabled)
		{
			pendingCheatCommandLine = commandLine;
			TerminalUI.inst.SetInputInteractable(interactable: false);
			TerminalUI.inst.cheatConfirmation.ShowConfirmation(ConfirmCheatCommand, CancelCheatCommand);
			return;
		}
		try
		{
			object[] parameters = ConvertArguments(args, terminalCommandInfo.parameters);
			object obj = terminalCommandInfo.method.Invoke(terminalCommandInfo.target, parameters);
			if (obj != null && terminalCommandInfo.method.ReturnType != typeof(void))
			{
				if (obj is IEnumerable progressiveOutput && !(obj is string))
				{
					Coroutine item = StartCoroutine(ExecuteProgressiveCommand(progressiveOutput, text));
					runningCommands.Add(item);
				}
				else
				{
					TerminalUI.inst.PrintLine(obj.ToString());
				}
			}
		}
		catch (Exception ex)
		{
			TerminalUI.inst.PrintError("Command execution failed: " + ex.Message);
			Debug.LogException(ex);
		}
	}

	private IEnumerator ExecuteProgressiveCommand(IEnumerable progressiveOutput, string commandName)
	{
		TerminalCommandBuffer commandBuffer = null;
		foreach (object item in progressiveOutput)
		{
			if (item is string text)
			{
				if (!string.IsNullOrEmpty(text))
				{
					TerminalUI.inst.PrintLine(text);
				}
			}
			else if (item is SetLine setLine)
			{
				if (commandBuffer == null)
				{
					commandBuffer = new TerminalCommandBuffer(null, commandName, nextCommandId++);
					commandBuffers.Add(commandBuffer);
				}
				commandBuffer.SetLine(setLine.lineIndex, setLine.text, setLine.color);
				UpdateLiveBufferDisplay();
			}
			yield return null;
		}
		if (commandBuffer != null)
		{
			commandBuffers.Remove(commandBuffer);
			UpdateLiveBufferDisplay();
		}
	}

	private void UpdateLiveBufferDisplay()
	{
		if (TerminalUI.inst != null)
		{
			TerminalUI.inst.UpdateLiveBuffers(commandBuffers);
		}
	}

	public void StopAllRunningCommands()
	{
		foreach (Coroutine runningCommand in runningCommands)
		{
			if (runningCommand != null)
			{
				StopCoroutine(runningCommand);
			}
		}
		runningCommands.Clear();
		commandBuffers.Clear();
		UpdateLiveBufferDisplay();
	}

	public bool StopCommandById(int id)
	{
		TerminalCommandBuffer terminalCommandBuffer = null;
		foreach (TerminalCommandBuffer commandBuffer in commandBuffers)
		{
			if (commandBuffer.id == id)
			{
				terminalCommandBuffer = commandBuffer;
				break;
			}
		}
		if (terminalCommandBuffer == null)
		{
			return false;
		}
		if (terminalCommandBuffer.owner != null)
		{
			StopCoroutine(terminalCommandBuffer.owner);
			runningCommands.Remove(terminalCommandBuffer.owner);
		}
		commandBuffers.Remove(terminalCommandBuffer);
		UpdateLiveBufferDisplay();
		return true;
	}

	private string[] ParseCommandLine(string commandLine)
	{
		List<string> list = new List<string>();
		bool flag = false;
		string text = "";
		for (int i = 0; i < commandLine.Length; i++)
		{
			char c = commandLine[i];
			switch (c)
			{
			case '"':
				flag = !flag;
				continue;
			case ' ':
				if (!flag)
				{
					if (!string.IsNullOrEmpty(text))
					{
						list.Add(text);
						text = "";
					}
					continue;
				}
				break;
			}
			text += c;
		}
		if (!string.IsNullOrEmpty(text))
		{
			list.Add(text);
		}
		return list.ToArray();
	}

	private object[] ConvertArguments(string[] args, ParameterInfo[] parameters)
	{
		object[] array = new object[parameters.Length];
		for (int i = 0; i < parameters.Length; i++)
		{
			ParameterInfo parameterInfo = parameters[i];
			if (i == parameters.Length - 1 && parameterInfo.ParameterType.IsArray && parameterInfo.GetCustomAttributes(typeof(ParamArrayAttribute), inherit: false).Length != 0)
			{
				Type elementType = parameterInfo.ParameterType.GetElementType();
				int num = Math.Max(0, args.Length - i);
				if (elementType == typeof(string))
				{
					string[] array2 = new string[num];
					Array.Copy(args, i, array2, 0, num);
					array[i] = array2;
					break;
				}
				Array array3 = Array.CreateInstance(elementType, num);
				for (int j = 0; j < num; j++)
				{
					object value = ConvertArgument(args[i + j], elementType);
					array3.SetValue(value, j);
				}
				array[i] = array3;
				break;
			}
			if (i >= args.Length)
			{
				if (!parameterInfo.HasDefaultValue)
				{
					throw new ArgumentException("Missing required parameter: " + parameterInfo.Name);
				}
				array[i] = parameterInfo.DefaultValue;
			}
			else
			{
				array[i] = ConvertArgument(args[i], parameterInfo.ParameterType);
			}
		}
		return array;
	}

	private object ConvertArgument(string arg, Type targetType)
	{
		if (targetType == typeof(string))
		{
			return arg;
		}
		if (targetType == typeof(int))
		{
			return int.Parse(arg);
		}
		if (targetType == typeof(float))
		{
			return float.Parse(arg);
		}
		if (targetType == typeof(bool))
		{
			if (arg.Equals("0", StringComparison.OrdinalIgnoreCase))
			{
				arg = "false";
			}
			if (arg.Equals("1", StringComparison.OrdinalIgnoreCase))
			{
				arg = "true";
			}
			if (arg.Equals("on", StringComparison.OrdinalIgnoreCase))
			{
				arg = "true";
			}
			if (arg.Equals("off", StringComparison.OrdinalIgnoreCase))
			{
				arg = "false";
			}
			return bool.Parse(arg);
		}
		if (targetType == typeof(double))
		{
			return double.Parse(arg);
		}
		if (targetType == typeof(long))
		{
			return long.Parse(arg);
		}
		if (targetType.IsEnum)
		{
			return Enum.Parse(targetType, arg, ignoreCase: true);
		}
		return Convert.ChangeType(arg, targetType);
	}

	public List<string> GetAutoCompleteOptions(string prefix)
	{
		List<string> list = new List<string>();
		foreach (string key in commands.Keys)
		{
			if (key.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
			{
				list.Add(key);
			}
		}
		return list.OrderBy((string x) => x).ToList();
	}

	public List<string> GetCommandNames()
	{
		return commands.Keys.OrderBy((string x) => x).ToList();
	}

	public List<string> GetParameterAutoCompleteOptions(string commandName, int parameterIndex, string partialValue)
	{
		commandName = commandName.ToLower();
		if (commandName == "help" && parameterIndex == 0)
		{
			return GetAutoCompleteOptions(partialValue);
		}
		if (!commands.ContainsKey(commandName))
		{
			return new List<string>();
		}
		TerminalCommandInfo terminalCommandInfo = commands[commandName];
		if (terminalCommandInfo.parameters.Length == 0)
		{
			return new List<string>();
		}
		bool flag = false;
		ParameterInfo parameterInfo;
		if (parameterIndex < terminalCommandInfo.parameters.Length)
		{
			parameterInfo = terminalCommandInfo.parameters[parameterIndex];
		}
		else
		{
			ParameterInfo parameterInfo2 = terminalCommandInfo.parameters[terminalCommandInfo.parameters.Length - 1];
			if (parameterInfo2.GetCustomAttributes(typeof(ParamArrayAttribute), inherit: false).Length == 0)
			{
				return new List<string>();
			}
			parameterInfo = parameterInfo2;
			flag = true;
		}
		List<string> list = new List<string>();
		Type type = (flag ? parameterInfo.ParameterType.GetElementType() : parameterInfo.ParameterType);
		if (type == typeof(bool))
		{
			list.AddRange(new string[4] { "true", "false", "on", "off" });
		}
		else if (type.IsEnum)
		{
			list.AddRange(from n in Enum.GetNames(type)
				select n.ToLower());
		}
		else if (terminalCommandInfo.parameterHints.ContainsKey(parameterInfo.Name))
		{
			list.AddRange(terminalCommandInfo.parameterHints[parameterInfo.Name]);
		}
		if (!string.IsNullOrEmpty(partialValue))
		{
			list = list.Where((string o) => o.StartsWith(partialValue, StringComparison.OrdinalIgnoreCase)).ToList();
		}
		return list.OrderBy((string x) => x).ToList();
	}

	public void ConfirmCheatCommand()
	{
		Player.inst.CheatsEnabled = true;
		TerminalUI.inst.SetInputInteractable(interactable: true);
		if (pendingCheatCommandLine != null)
		{
			string commandLine = pendingCheatCommandLine;
			pendingCheatCommandLine = null;
			ExecuteCommand(commandLine);
		}
	}

	public void CancelCheatCommand()
	{
		pendingCheatCommandLine = null;
		TerminalUI.inst.SetInputInteractable(interactable: true);
	}

	public void PrintHelp(string commandName = null)
	{
		if (string.IsNullOrEmpty(commandName))
		{
			TerminalUI.inst.PrintLine("Available commands:", TerminalUI.inst.commandTextColor);
			List<KeyValuePair<string, TerminalCommandInfo>> list = commands.OrderBy((KeyValuePair<string, TerminalCommandInfo> x) => x.Key).ToList();
			int totalWidth = list.Max((KeyValuePair<string, TerminalCommandInfo> x) => x.Key.Length);
			using List<KeyValuePair<string, TerminalCommandInfo>>.Enumerator enumerator = list.GetEnumerator();
			Color color2;
			Color color;
			string text3;
			int num;
			string text2;
			string text;
			for (; enumerator.MoveNext(); color2 = color, text3 = ((num != 0) ? " (procedure)" : ""), TerminalUI.inst.PrintLine("  <color=#" + ColorUtility.ToHtmlStringRGB(color2) + ">" + text2 + "</color> - " + text + text3))
			{
				KeyValuePair<string, TerminalCommandInfo> current = enumerator.Current;
				TerminalCommandInfo value = current.Value;
				text = (string.IsNullOrEmpty(value.attribute.description) ? "No description" : value.attribute.description);
				text2 = current.Key.PadRight(totalWidth);
				if (value.method.ReturnType != typeof(void) && value.method.ReturnType != typeof(string))
				{
					num = (typeof(IEnumerable).IsAssignableFrom(value.method.ReturnType) ? 1 : 0);
					if (num != 0)
					{
						color = TerminalUI.inst.warningTextColor;
						continue;
					}
				}
				else
				{
					num = 0;
				}
				color = TerminalUI.inst.commandTextColor;
			}
			return;
		}
		TerminalCommandInfo terminalCommandInfo;
		int num2;
		Color color3;
		if (commands.ContainsKey(commandName.ToLower()))
		{
			terminalCommandInfo = commands[commandName.ToLower()];
			if (terminalCommandInfo.method.ReturnType != typeof(void) && terminalCommandInfo.method.ReturnType != typeof(string))
			{
				num2 = (typeof(IEnumerable).IsAssignableFrom(terminalCommandInfo.method.ReturnType) ? 1 : 0);
				if (num2 != 0)
				{
					color3 = TerminalUI.inst.warningTextColor;
					goto IL_0257;
				}
			}
			else
			{
				num2 = 0;
			}
			color3 = TerminalUI.inst.commandTextColor;
			goto IL_0257;
		}
		TerminalUI.inst.PrintError("Unknown command: " + commandName);
		return;
		IL_0257:
		Color value2 = color3;
		string text4 = ((num2 != 0) ? " (procedure)" : "");
		TerminalUI.inst.PrintLine("Command: " + commandName + text4, value2);
		TerminalUI.inst.PrintLine("Description: " + terminalCommandInfo.attribute.description);
		if (terminalCommandInfo.parameters.Length == 0)
		{
			return;
		}
		TerminalUI.inst.PrintLine("Parameters:");
		ParameterInfo[] parameters = terminalCommandInfo.parameters;
		foreach (ParameterInfo parameterInfo in parameters)
		{
			string text5 = "  " + parameterInfo.Name + " (" + parameterInfo.ParameterType.Name + ")";
			if (parameterInfo.HasDefaultValue)
			{
				text5 += $" = {parameterInfo.DefaultValue}";
			}
			TerminalUI.inst.PrintLine(text5);
		}
	}
}
