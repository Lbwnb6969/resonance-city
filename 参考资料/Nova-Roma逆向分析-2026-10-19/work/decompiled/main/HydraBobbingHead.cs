using UnityEngine;

public class HydraBobbingHead : MonoBehaviour
{
	public Vector3 axisSpeed = new Vector3(1f, 1f, 1f);

	public Vector3 axisDistance = new Vector3(0.05f, 0.05f, 0.05f);

	private float offset;

	private void Start()
	{
		offset = SRand.Range(0, 10000);
	}

	private void Update()
	{
		transform.localPosition = new Vector3(Mathf.Sin((offset + Time.time) * axisSpeed.x) * axisDistance.x, Mathf.Sin((offset + Time.time) * axisSpeed.y) * axisDistance.y, Mathf.Sin((offset + Time.time) * axisSpeed.z) * axisDistance.z);
	}
}
