using UnityEngine;

public class RotateSprite : MonoBehaviour
{
	public float Speed = 1f;

	public bool Clockwise = true;

	public bool Enabled = true;

	private void Update()
	{
		if (Enabled)
		{
			transform.Rotate(Vector3.forward, Time.unscaledDeltaTime * 90f * Speed * (float)((!Clockwise) ? 1 : (-1)));
		}
	}
}
