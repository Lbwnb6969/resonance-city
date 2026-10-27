using System;
using System.Globalization;
using UnityEngine;

namespace PixelCrushers.DialogueSystem;

public static class SequencerTools
{
	public static Transform GetSubject(string specifier, Transform speaker, Transform listener, Transform defaultSubject = null)
	{
		if (string.IsNullOrEmpty(specifier))
		{
			return defaultSubject ?? speaker;
		}
		if (string.Compare(specifier, "speaker", StringComparison.OrdinalIgnoreCase) == 0)
		{
			return speaker;
		}
		if (string.Compare(specifier, "listener", StringComparison.OrdinalIgnoreCase) == 0)
		{
			return listener;
		}
		GameObject gameObject = FindSpecifier(specifier);
		if (!(gameObject != null))
		{
			return defaultSubject;
		}
		return gameObject.transform;
	}

	public static bool SpecifierSpecifiesTag(string specifier)
	{
		if (!string.IsNullOrEmpty(specifier))
		{
			return specifier.StartsWith("tag=", StringComparison.OrdinalIgnoreCase);
		}
		return false;
	}

	public static string GetSpecifiedTag(string specifier)
	{
		return specifier.Substring("tag=".Length);
	}

	public static GameObject FindSpecifier(string specifier, bool onlyActiveInScene = false)
	{
		if (string.IsNullOrEmpty(specifier))
		{
			return null;
		}
		if (SpecifierSpecifiesTag(specifier))
		{
			string specifiedTag = GetSpecifiedTag(specifier);
			GameObject gameObject = GameObject.FindGameObjectWithTag(specifiedTag);
			if (gameObject != null)
			{
				return gameObject;
			}
			GameObject[] array = Tools.FindGameObjectsWithTagHard(specifiedTag);
			if (array.Length == 0)
			{
				return null;
			}
			return array[0];
		}
		Transform registeredActorTransform = CharacterInfo.GetRegisteredActorTransform(specifier);
		if (registeredActorTransform != null)
		{
			return registeredActorTransform.gameObject;
		}
		GameObject gameObject2 = GameObject.Find(specifier);
		if (gameObject2 != null)
		{
			return gameObject2;
		}
		if (onlyActiveInScene)
		{
			return null;
		}
		gameObject2 = Tools.GameObjectHardFind(specifier);
		if (gameObject2 != null)
		{
			return gameObject2;
		}
		GameObject[] array2 = Resources.FindObjectsOfTypeAll(typeof(GameObject)) as GameObject[];
		foreach (GameObject gameObject3 in array2)
		{
			if (string.Compare(specifier, gameObject3.name, StringComparison.OrdinalIgnoreCase) == 0)
			{
				return gameObject3;
			}
		}
		return null;
	}

	public static string GetDefaultCameraAngle(Transform subject)
	{
		DefaultCameraAngle defaultCameraAngle = ((subject != null) ? subject.GetComponentInChildren<DefaultCameraAngle>() : null);
		if (!(defaultCameraAngle != null))
		{
			return "Closeup";
		}
		return defaultCameraAngle.cameraAngle;
	}

	public static string GetParameter(string[] parameters, int i, string defaultValue = null)
	{
		if (parameters == null || i >= parameters.Length)
		{
			return defaultValue;
		}
		return parameters[i];
	}

	public static T GetParameterAs<T>(string[] parameters, int i, T defaultValue)
	{
		try
		{
			return (parameters != null && i < parameters.Length) ? ((T)Convert.ChangeType(parameters[i], typeof(T), CultureInfo.InvariantCulture)) : defaultValue;
		}
		catch (Exception)
		{
			return defaultValue;
		}
	}

	public static float GetParameterAsFloat(string[] parameters, int i, float defaultValue = 0f)
	{
		return GetParameterAs(parameters, i, defaultValue);
	}

	public static int GetParameterAsInt(string[] parameters, int i, int defaultValue = 0)
	{
		return GetParameterAs(parameters, i, defaultValue);
	}

	public static bool GetParameterAsBool(string[] parameters, int i, bool defaultValue = false)
	{
		return GetParameterAs(parameters, i, defaultValue);
	}

	public static AudioSource GetAudioSource(Transform subject)
	{
		GameObject gameObject = ((subject != null) ? subject.gameObject : DialogueManager.instance.gameObject);
		AudioSource audioSource = gameObject.GetComponentInChildren<AudioSource>();
		if (audioSource == null)
		{
			audioSource = gameObject.AddComponent<AudioSource>();
			audioSource.playOnAwake = false;
			audioSource.loop = false;
		}
		return audioSource;
	}

	public static bool IsAudioMuted()
	{
		return DialogueLua.GetVariable("Mute").asBool;
	}
}
