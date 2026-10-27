using UnityEngine;

public class RotateObject : MonoBehaviour
{
	public bool Enabled { get; set; }

	private void Start()
	{
		Enabled = true;
	}

	private void Update()
	{
		if (Enabled)
		{
			transform.Rotate(Vector3.up, Time.unscaledDeltaTime * 90f);
		}
	}
}
