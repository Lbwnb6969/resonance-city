using System;
using System.Reflection;
using Assets;
using UnityEngine;

public class StatusEffectsManager : MonoBehaviour
{
	public Transform activeEffectContainer;

	public GameObject activeEffectPrefab;

	public static StatusEffectsManager inst;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
	}

	private void Update()
	{
		activeEffectContainer.gameObject.SetActive(activeEffectContainer.childCount > 2);
		transform.localScale = (Settings.inst.StreamerMode ? Vector3.one : (Vector3.one * 0.6f));
	}

	public StreamerEffect StartEffect(Type implementation)
	{
		GameObject gameObject = UnityEngine.Object.Instantiate(activeEffectPrefab);
		gameObject.transform.SetParent(activeEffectContainer, worldPositionStays: false);
		gameObject.gameObject.SetActive(value: true);
		gameObject.AddComponent(implementation);
		string text = (string)implementation.GetMethod("GetTermSegment", BindingFlags.Static | BindingFlags.Public | BindingFlags.FlattenHierarchy).Invoke(null, null);
		StreamerEffect component = gameObject.GetComponent<StreamerEffect>();
		component.SetTerm("Votable" + text + "Title");
		return component;
	}

	public void ClearEffects()
	{
		StreamerEffect[] componentsInChildren = activeEffectContainer.GetComponentsInChildren<StreamerEffect>();
		for (int i = 0; i < componentsInChildren.Length; i++)
		{
			UnityEngine.Object.Destroy(componentsInChildren[i].gameObject);
		}
	}
}
