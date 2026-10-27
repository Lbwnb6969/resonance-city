using UnityEngine;

public class PositionAnimator : MonoBehaviour
{
	private Vector3 origPos;

	public AnimationCurve anim;

	private float t;

	private void Start()
	{
		origPos = transform.localPosition;
	}

	private void Update()
	{
		t += Time.unscaledDeltaTime;
		if (t > 1f)
		{
			t = 0f;
		}
		transform.localPosition = origPos + new Vector3(0f, anim.Evaluate(t), 0f);
	}
}
