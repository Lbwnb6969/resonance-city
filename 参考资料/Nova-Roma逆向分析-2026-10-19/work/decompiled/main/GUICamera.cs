using UnityEngine;

public class GUICamera : MonoBehaviour
{
	public static GUICamera inst;

	public Camera cam;

	private void Awake()
	{
		inst = this;
		cam = GetComponent<Camera>();
	}
}
