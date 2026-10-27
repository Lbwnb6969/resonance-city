using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using FMODUnity;
using I2.Loc;
using TMPro;
using Unity.Collections.LowLevel.Unsafe;
using UnityEngine;
using UnityEngine.UI;

public static class Util
{
	private static readonly List<ScrollRect> scrollRectScratch = new List<ScrollRect>();

	private static Dictionary<Type, bool> IsSubclassOfSaveClassMap = new Dictionary<Type, bool>();

	private static Dictionary<Type, bool> IsSubclassOfJobSaveClassMap = new Dictionary<Type, bool>();

	public static Dictionary<Type, Func<object, object[], object>> packMethodMap = new Dictionary<Type, Func<object, object[], object>>();

	public static Dictionary<Type, Func<object, object[], object>> unpackMethodMap = new Dictionary<Type, Func<object, object[], object>>();

	private static Dictionary<Type, Func<object>> constructorMap = new Dictionary<Type, Func<object>>();

	public static void SetActive(GameObject obj, bool active)
	{
		if (obj.activeSelf != active)
		{
			obj.SetActive(active);
		}
	}

	public static void SetActive(Transform obj, bool active)
	{
		if (obj.gameObject.activeSelf != active)
		{
			obj.gameObject.SetActive(active);
		}
	}

	public static void SetActive(Image obj, bool active)
	{
		if (obj.gameObject.activeSelf != active)
		{
			obj.gameObject.SetActive(active);
		}
	}

	public static bool SetEnabled(Behaviour obj, bool active)
	{
		if (obj.enabled != active)
		{
			obj.enabled = active;
			return true;
		}
		return false;
	}

	public static bool SetEnabled(Canvas canvas, bool active)
	{
		if (canvas.enabled == active)
		{
			return false;
		}
		canvas.enabled = active;
		canvas.GetComponentsInChildren(includeInactive: true, scrollRectScratch);
		for (int i = 0; i < scrollRectScratch.Count; i++)
		{
			ScrollRect scrollRect = scrollRectScratch[i];
			scrollRect.enabled = active && scrollRect.GetComponentInParent<Canvas>(includeInactive: true).enabled;
		}
		scrollRectScratch.Clear();
		return true;
	}

	public static void SetEnabled(Renderer obj, bool active)
	{
		if (obj.enabled != active)
		{
			obj.enabled = active;
		}
	}

	public static void SetParticleEffects(ParticleSystem pSystem, bool active, bool withChildren = true)
	{
		if (!active && pSystem.isPlaying)
		{
			pSystem.Stop(withChildren);
		}
		else if (active && (pSystem.isStopped || pSystem.isPaused))
		{
			pSystem.Play(withChildren);
		}
	}

	public unsafe static void Memset<T>(T[] data, byte val) where T : unmanaged
	{
		UnsafeUtility.MemSet(UnsafeUtility.PinGCArrayAndGetDataAddress(data, out var gcHandle), val, sizeof(T) * data.Length);
		UnsafeUtility.ReleaseGCObject(gcHandle);
	}

	public static string TryEllipse(string str, int length)
	{
		string text = str;
		if (text.Length > length)
		{
			text = text.Substring(0, length - 3);
			text += "...";
		}
		return text;
	}

	public static void SetLayerRecursively(GameObject obj, int layer)
	{
		if (!(obj == null))
		{
			obj.layer = layer;
			for (int i = 0; i < obj.transform.childCount; i++)
			{
				SetLayerRecursively(obj.transform.GetChild(i).gameObject, layer);
			}
		}
	}

	public static int GetChildIndex(Transform child, Transform parent)
	{
		int num = 0;
		for (int i = 0; i < parent.childCount; i++)
		{
			Transform child2 = parent.GetChild(i);
			if (child2 == child)
			{
				return num;
			}
			if (child2.gameObject.activeSelf)
			{
				num++;
			}
		}
		return -1;
	}

	public static Transform GetChildAtIndex(int idx, Transform container)
	{
		if (idx == -1)
		{
			return null;
		}
		int num = -1;
		for (int i = 0; i < container.childCount; i++)
		{
			if (container.GetChild(i).gameObject.activeSelf)
			{
				num++;
			}
			if (idx == num)
			{
				return container.GetChild(i);
			}
		}
		return null;
	}

	public static T[] GetInterfaces<T>(this GameObject gObj)
	{
		if (!typeof(T).IsInterface)
		{
			throw new SystemException("Specified type is not an interface!");
		}
		return (from a in gObj.GetComponents<MonoBehaviour>()
			where a != null && a.GetType().GetInterfaces().Any((Type k) => k == typeof(T))
			select (T)(object)a).ToArray();
	}

	public static T GetInterface<T>(this GameObject gObj)
	{
		if (!typeof(T).IsInterface)
		{
			throw new SystemException("Specified type is not an interface!");
		}
		return gObj.GetInterfaces<T>().FirstOrDefault();
	}

	public static T GetInterfaceInChildren<T>(this GameObject gObj)
	{
		if (!typeof(T).IsInterface)
		{
			throw new SystemException("Specified type is not an interface!");
		}
		return gObj.GetInterfacesInChildren<T>().FirstOrDefault();
	}

	public static T[] GetInterfacesInChildren<T>(this GameObject gObj)
	{
		if (!typeof(T).IsInterface)
		{
			throw new SystemException("Specified type is not an interface!");
		}
		return (from a in gObj.GetComponentsInChildren<MonoBehaviour>()
			where a.GetType().GetInterfaces().Any((Type k) => k == typeof(T))
			select (T)(object)a).ToArray();
	}

	public static void AddKeyAndStringToI2(string key, string value)
	{
	}

	public static void TrySetText(TextMeshProUGUI textUI, string str, int newValue, ref int lastValue)
	{
		if (newValue != lastValue)
		{
			textUI.SetText(str, newValue);
		}
		lastValue = newValue;
	}

	public static void TrySetText(TextMeshProUGUI textUI, string str, float newValue, ref float lastValue)
	{
		if (newValue != lastValue)
		{
			textUI.SetText(str, newValue);
		}
		lastValue = newValue;
	}

	public static string QuantityToWords(int quantity, string singular, string plural)
	{
		if (LocalizationManager.CurrentLanguage == "Japanese")
		{
			return ((quantity == 1) ? singular : plural) + " " + NumberToWord(quantity);
		}
		return NumberToWord(quantity) + " " + ((quantity == 1) ? singular : plural);
	}

	public static string GetSuffixSymbol(int amt)
	{
		if (amt < 0)
		{
			return "";
		}
		return "+";
	}

	public static string PeasantAffectCountString(int affected, string color = "")
	{
		if (color == string.Empty)
		{
			return QuantityToWords(affected, ScriptLocalization.PeasantSingular, ScriptLocalization.PeasantPlural);
		}
		return "<color=" + color + ">" + QuantityToWords(affected, ScriptLocalization.PeasantSingular, ScriptLocalization.PeasantPlural) + "</color>";
	}

	public static Hash128 TextureHash(Texture2D texture)
	{
		return Hash128.Compute(BitConverter.ToString(texture.GetRawTextureData()));
	}

	public static T GetComponentSafe<T>(this GameObject go)
	{
		T component = go.GetComponent<T>();
		if (component != null && !component.Equals(null))
		{
			return component;
		}
		throw new NullReferenceException("GameObject '" + go.name + "' doesn't contain component '" + typeof(T).FullName);
	}

	public static string ColorTextWrap(string ogString, Color color)
	{
		return "<color=#" + ColorUtility.ToHtmlStringRGB(color) + ">" + ogString + "</color>";
	}

	public static float QuadraticEaseOut(float currentTime, float startValue, float changeInValue, float totalTime)
	{
		currentTime /= totalTime / 2f;
		if (currentTime < 1f)
		{
			return changeInValue / 2f * currentTime * currentTime + startValue;
		}
		currentTime--;
		return (0f - changeInValue) / 2f * (currentTime * (currentTime - 2f) - 1f) + startValue;
	}

	public static float EaseOutBounce(float currentTime, float startValue, float changeInValue, float totalTime)
	{
		float num = 7.5625f;
		float num2 = 2.75f;
		float num3 = 1.5f;
		float num4 = 2.25f;
		float num5 = 2.625f;
		float num6 = 0.75f;
		float num7 = 0.9375f;
		float num8 = 63f / 64f;
		if ((currentTime /= totalTime) < 1f / num2)
		{
			return changeInValue * (num * currentTime * currentTime) + startValue;
		}
		if (currentTime < 2f / num2)
		{
			return changeInValue * (num * (currentTime -= num3 / num2) * currentTime + num6) + startValue;
		}
		if ((double)currentTime < 2.5 / (double)num2)
		{
			return changeInValue * (num * (currentTime -= num4 / num2) * currentTime + num7) + startValue;
		}
		return changeInValue * (num * (currentTime -= num5 / num2) * currentTime + num8) + startValue;
	}

	public static float easeOutQuad(float x)
	{
		return 1f - (1f - x) * (1f - x);
	}

	public static float easeInQuad(float x)
	{
		return x * x;
	}

	public static float easeBubble(float t, float n, float k)
	{
		float num = n * (t * t);
		float num2 = 1f - k * ((t - 1f) * (t - 1f));
		return num * (1f - t) + num2 * t;
	}

	public static void SetMesh(Transform self, Transform prefab, Transform colliderPrefab)
	{
		if (prefab == null)
		{
			return;
		}
		MeshFilter componentInChildren = self.GetComponentInChildren<MeshFilter>();
		MeshCollider componentInChildren2 = self.GetComponentInChildren<MeshCollider>();
		componentInChildren.sharedMesh = prefab.GetComponent<MeshFilter>().sharedMesh;
		Mesh mesh = ((!(colliderPrefab != null)) ? componentInChildren.sharedMesh : colliderPrefab.GetComponent<MeshFilter>().sharedMesh);
		if (componentInChildren2 != null)
		{
			if (BlockStackUpdateSystem.inst.SuppressColliderUpdates)
			{
				BlockStackUpdateSystem.inst.QueueColliderUpdate(componentInChildren2, mesh);
			}
			else
			{
				componentInChildren2.sharedMesh = mesh;
			}
		}
	}

	public static void SetCircle(LineRenderer lineRenderer, Vector3 center, float Radius, int segments)
	{
		lineRenderer.startWidth = 0.05f;
		lineRenderer.endWidth = 0.05f;
		lineRenderer.positionCount = segments + 1;
		for (int i = 0; i <= segments; i++)
		{
			float x = Radius * Mathf.Cos((float)i / (float)segments * MathF.PI * 2f);
			float z = Radius * Mathf.Sin((float)i / (float)segments * MathF.PI * 2f);
			Vector3 vector = new Vector3(x, 0f, z);
			lineRenderer.SetPosition(i, vector + center);
		}
	}

	public static Texture2D LoadPNG(string filePath)
	{
		Texture2D texture2D = null;
		if (File.Exists(filePath))
		{
			byte[] data = File.ReadAllBytes(filePath);
			texture2D = new Texture2D(2, 2);
			texture2D.name = "LoadedPNG";
			texture2D.LoadImage(data);
		}
		return texture2D;
	}

	public static IEnumerable<T> ComponentsInNodeAndAllDescendants<T>(GameObject startParent) where T : Component
	{
		if (startParent.transform.childCount > 0)
		{
			foreach (Transform item in startParent.transform)
			{
				foreach (T item2 in ComponentsInNodeAndAllDescendants<T>(item.gameObject))
				{
					if (item2.GetComponent<T>() != null)
					{
						yield return item2.GetComponent<T>();
					}
				}
			}
		}
		if (startParent.GetComponent<T>() != null)
		{
			yield return startParent.GetComponent<T>();
		}
	}

	public static T FindInParents<T>(GameObject go) where T : Component
	{
		if (go == null)
		{
			return null;
		}
		T component = go.GetComponent<T>();
		if (component != null)
		{
			return component;
		}
		Transform parent = go.transform.parent;
		while (parent != null && component == null)
		{
			component = parent.gameObject.GetComponent<T>();
			parent = parent.parent;
		}
		return component;
	}

	public static string NumberToWord(int number)
	{
		return number switch
		{
			0 => ScriptLocalization.Number0, 
			1 => ScriptLocalization.Number1, 
			2 => ScriptLocalization.Number2, 
			3 => ScriptLocalization.Number3, 
			4 => ScriptLocalization.Number4, 
			5 => ScriptLocalization.Number5, 
			6 => ScriptLocalization.Number6, 
			7 => ScriptLocalization.Number7, 
			8 => ScriptLocalization.Number8, 
			9 => ScriptLocalization.Number9, 
			_ => number.ToString(), 
		};
	}

	public static void SetAbbreviateLargeNumber(int val, TextMeshProUGUI text)
	{
		if (val > 1000000 || val < -1000000)
		{
			float arg = (float)(int)((float)val / 100000f) / 10f;
			text.SetText("{0}M", arg);
		}
		else if (val > 1000 || val < -1000)
		{
			float arg2 = (float)(int)((float)val / 100f) / 10f;
			text.SetText("{0}K", arg2);
		}
		else
		{
			text.SetText("{0}", val);
		}
	}

	public static string GetGameObjectPath(Transform transform)
	{
		string text = transform.name;
		while (transform.parent != null)
		{
			transform = transform.parent;
			text = transform.name + "/" + text;
		}
		return text;
	}

	public static T DeepCopy<T>(T other)
	{
		return SaveSerializer.DeepCopy(other);
	}

	public static bool IsSubclassOfSaveClass(Type toCheck)
	{
		bool value = false;
		if (!IsSubclassOfSaveClassMap.TryGetValue(toCheck, out value))
		{
			value = IsSubclassOfRawGeneric(typeof(SaveClass<, >), toCheck);
			IsSubclassOfSaveClassMap.Add(toCheck, value);
		}
		return value;
	}

	public static bool IsSubclassOfJobSaveClass(Type toCheck)
	{
		bool value = false;
		if (!IsSubclassOfJobSaveClassMap.TryGetValue(toCheck, out value))
		{
			value = IsSubclassOfRawGeneric(typeof(Job.JobSaveData<, >), toCheck);
			IsSubclassOfJobSaveClassMap.Add(toCheck, value);
		}
		return value;
	}

	public static Func<object, object[], object> GetPackMethod(Type t)
	{
		Func<object, object[], object> value = null;
		if (!packMethodMap.TryGetValue(t, out value))
		{
			value = CreateUnboundDelegate(t.GetMethod("Pack"));
			packMethodMap.Add(t, value);
		}
		return value;
	}

	public static Func<object, object[], object> GetUnpackMethod(Type t)
	{
		Func<object, object[], object> value = null;
		if (!unpackMethodMap.TryGetValue(t, out value))
		{
			value = CreateUnboundDelegate(t.GetMethod("Unpack"));
			unpackMethodMap.Add(t, value);
		}
		return value;
	}

	public static bool IsSubclassOfRawGeneric(Type generic, Type toCheck)
	{
		while (toCheck != null && toCheck != typeof(object))
		{
			Type type = (toCheck.IsGenericType ? toCheck.GetGenericTypeDefinition() : toCheck);
			if (generic == type)
			{
				return true;
			}
			toCheck = toCheck.BaseType;
		}
		return false;
	}

	public static Func<object, object[], object> CreateUnboundDelegate(MethodInfo method)
	{
		ParameterExpression parameterExpression = Expression.Parameter(typeof(object), "instance");
		ParameterExpression parameterExpression2 = Expression.Parameter(typeof(object[]), "args");
		UnaryExpression instance = Expression.Convert(parameterExpression, method.DeclaringType);
		ParameterInfo[] parameters = method.GetParameters();
		Expression[] array = new Expression[parameters.Length];
		for (int i = 0; i < parameters.Length; i++)
		{
			array[i] = Expression.Convert(Expression.ArrayIndex(parameterExpression2, Expression.Constant(i)), parameters[i].ParameterType);
		}
		return Expression.Lambda<Func<object, object[], object>>(Expression.Convert(Expression.Call(instance, method, array), typeof(object)), new ParameterExpression[2] { parameterExpression, parameterExpression2 }).Compile();
	}

	public static void CopyToClipboard(this string str)
	{
		GUIUtility.systemCopyBuffer = str;
	}

	internal static object CreateInstance(Type nestedType)
	{
		Func<object> value = null;
		if (!constructorMap.TryGetValue(nestedType, out value))
		{
			value = Expression.Lambda<Func<object>>(Expression.New(nestedType.GetConstructor(Type.EmptyTypes)), Array.Empty<ParameterExpression>()).Compile();
			constructorMap.Add(nestedType, value);
		}
		return value();
	}

	internal static void SFXPlayOneShotDistCheck(string v, Vector3 pos, float maxDist = 50f)
	{
		if (Mathff.DistSqrd(pos, Cam.inst.CamPos) <= maxDist * maxDist)
		{
			RuntimeManager.PlayOneShot(v, pos);
		}
	}
}
