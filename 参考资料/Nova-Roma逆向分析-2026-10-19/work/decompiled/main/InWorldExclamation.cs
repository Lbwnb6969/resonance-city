using System;
using System.Collections.Generic;
using Assets;
using UnityEngine;

public class InWorldExclamation : MonoBehaviour
{
	public delegate void OnClickDelegate();

	public static bool hideForCursorMode = false;

	public static bool hideForScreenshots = false;

	[NonSerialized]
	public ObjectHighlighter highlighter;

	public Collider coll;

	public MeshRenderer meshRenderer;

	public AnimationCurve scaleToCamDist;

	private float totalTime;

	public float bounceFreq = 10f;

	public float bounceMag = 0.1f;

	public OnClickDelegate onClick;

	public static List<InWorldExclamation> exclamations = new List<InWorldExclamation>();

	[NonSerialized]
	public static InWorldExclamation hovered = null;

	public bool IsVisible()
	{
		return meshRenderer.isVisible;
	}

	private void Start()
	{
		List<MeshRenderer> list = new List<MeshRenderer>();
		list.Add(meshRenderer);
		highlighter = ObjectHighlighter.SetupOutlines(gameObject, list, null);
	}

	private void Tick(float dt)
	{
		totalTime += dt;
		Vector3 position = Camera.main.transform.position;
		transform.rotation = Quaternion.LookRotation(position - transform.position);
		transform.GetChild(0).Rotate(0f, Time.deltaTime * 90f, 0f);
		Vector3 localPosition = transform.GetChild(0).localPosition;
		localPosition.y = Mathf.Sin(totalTime * bounceFreq) * bounceMag;
		transform.GetChild(0).localPosition = localPosition;
		float time = Mathff.Dist(position, transform.position);
		float num = scaleToCamDist.Evaluate(time);
		transform.GetChild(0).localScale = new Vector3(num, num, num);
		if (hideForScreenshots || hideForCursorMode || GameState.inst.IsMainMenuMode())
		{
			transform.GetChild(0).localScale = new Vector3(0f, 0f, 0f);
		}
	}

	private void OnEnable()
	{
		exclamations.Add(this);
	}

	public void OnDisable()
	{
		exclamations.Remove(this);
	}

	public void OnDestroy()
	{
		if (highlighter != null)
		{
			highlighter.Release();
		}
	}

	public void Click()
	{
		SfxSystem.PlayUiSelect();
		onClick();
	}

	public static void TickAll()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		Ray ray = PointingSystem.GetRay();
		hovered = null;
		float num = float.MaxValue;
		for (int i = 0; i < exclamations.Count; i++)
		{
			if (exclamations[i].IsVisible())
			{
				exclamations[i].Tick(unscaledDeltaTime);
				if (exclamations[i].coll.Raycast(ray, out var hitInfo, 9999f) && hitInfo.distance < num)
				{
					num = hitInfo.distance;
					hovered = exclamations[i];
				}
			}
		}
	}

	public static bool WillClick()
	{
		return hovered;
	}

	public static void DoClick()
	{
		if ((bool)hovered)
		{
			hovered.Click();
		}
	}
}
