using System;
using System.Diagnostics;
using Sirenix.OdinInspector;

[DontApplyToListElements]
[AttributeUsage(AttributeTargets.All)]
[Conditional("UNITY_EDITOR")]
public class OnSceneGUIAttribute : ShowInInspectorAttribute
{
	public string Action;

	public OnSceneGUIAttribute(string action = null)
	{
		Action = action;
	}
}
