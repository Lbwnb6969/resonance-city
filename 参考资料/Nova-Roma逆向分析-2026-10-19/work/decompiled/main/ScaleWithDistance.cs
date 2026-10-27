using UnityEngine;

public class ScaleWithDistance : MonoBehaviour
{
	private Vector3 startScale;

	private void Start()
	{
		startScale = transform.localScale;
	}

	private void Update()
	{
		transform.localScale = startScale * (Camera.main.transform.position - transform.position).magnitude;
	}
}
