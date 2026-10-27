using System;
using UnityEngine;

public class UIScaleBump : MonoBehaviour
{
	public float bumpLengthSeconds;

	public Vector3 magnitude;

	private RectTransform r;

	private Vector3 startMag;

	private float bump;

	public void Activate()
	{
		if (enabled)
		{
			r.localScale = startMag;
		}
		enabled = true;
		bump = 0f;
		r = GetComponent<RectTransform>();
		startMag = r.localScale;
	}

	private void Update()
	{
		bump += Time.unscaledDeltaTime / bumpLengthSeconds;
		if (bump >= 1f)
		{
			bump = 1f;
			enabled = false;
		}
		r.transform.localScale = Vector3.Lerp(startMag, magnitude, Mathf.Sin(bump * MathF.PI));
	}
}
