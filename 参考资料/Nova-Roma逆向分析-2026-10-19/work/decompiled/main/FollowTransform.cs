using UnityEngine;

public class FollowTransform : MonoBehaviour
{
	public bool followPosition;

	public bool followRotation;

	public Transform target;

	private void LateUpdate()
	{
		if (target != null)
		{
			if (followRotation)
			{
				transform.rotation = target.rotation;
			}
			if (followPosition)
			{
				transform.position = target.position;
			}
		}
	}
}
