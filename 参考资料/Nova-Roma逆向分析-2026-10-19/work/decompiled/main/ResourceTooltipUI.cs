using System;
using I2.Loc;
using TMPro;
using UnityEngine;

public class ResourceTooltipUI : Tickable
{
	[Header("Component References")]
	public TextMeshProUGUI text;

	public Localize localize;

	[Header("General Settings")]
	public bool doScaleToCamDist;

	public bool doAnimation = true;

	[Header("Animation Settings")]
	public float frequency = 3f;

	public float amplitude = 0.1f;

	public AnimationCurve ScaleToCamDist;

	[NonSerialized]
	public Vector3 targetPosition;

	public Vector3 targetOffset;

	public Guid id;

	public float scaleMod = 1f;

	public void SetText(string text)
	{
		this.text.text = text;
	}

	public void SetTerm(string term)
	{
		localize.Term = term;
	}

	public void EnableTextAutoSizing()
	{
	}

	public override void Tick(float dt, int currFrame)
	{
		Vector3 vector = targetPosition + targetOffset;
		if (doAnimation)
		{
			vector.y += Mathf.Sin(Time.unscaledTime * frequency) * amplitude;
			transform.position = vector;
		}
		if (doScaleToCamDist)
		{
			Vector3 position = Cam.inst.transform.position;
			float magnitude = (vector - position).magnitude;
			float num = ScaleToCamDist.Evaluate(magnitude) * scaleMod;
			transform.localScale = new Vector3(num, num, num);
		}
	}
}
