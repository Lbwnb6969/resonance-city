using UnityEngine;

public class FaceCamera : MonoBehaviour
{
	public bool ignoreY;

	private static ArrayExt<FaceCamera> components = new ArrayExt<FaceCamera>(50);

	private void OnEnable()
	{
		components.Add(this);
	}

	private void OnDisable()
	{
		components.RemoveSwap(this);
	}

	public static void TickAll()
	{
		Vector3 position = Cam.inst.transform.position;
		Vector3 upwards = Cam.inst.transform.rotation * Vector3.up;
		int i = 0;
		for (int count = components.Count; i < count; i++)
		{
			Vector3 forward = components.data[i].transform.position - position;
			if (components.data[i].ignoreY)
			{
				components.data[i].transform.rotation = Quaternion.LookRotation(components.data[i].transform.position.xz() - position.xz(), Vector3.up);
			}
			else
			{
				components.data[i].transform.rotation = Quaternion.LookRotation(forward, upwards);
			}
		}
	}
}
