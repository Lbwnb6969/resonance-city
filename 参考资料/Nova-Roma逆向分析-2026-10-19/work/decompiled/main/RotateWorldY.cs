using UnityEngine;

public class RotateWorldY : MonoBehaviour
{
	public float degreesPerSecond = 90f;

	private void Update()
	{
		transform.Rotate(Vector3.up, Time.unscaledDeltaTime * degreesPerSecond, Space.World);
	}
}
