using UnityEngine;

public class BobObject : MonoBehaviour
{
	public float amplitude = 0.1f;

	public float speed = 2f;

	private Vector3 basePos;

	private float phase;

	private void Start()
	{
		basePos = transform.localPosition;
		phase = SRand.Range(0f, 10000f);
	}

	private void Update()
	{
		Vector3 localPosition = basePos;
		localPosition.y += Mathf.Sin((phase + Time.unscaledTime) * speed) * amplitude;
		transform.localPosition = localPosition;
	}
}
