using UnityEngine;

public class KCEditorAssistant : MonoBehaviour
{
	public int labelRadius;

	private void Start()
	{
		transform.hideFlags = HideFlags.HideInInspector;
	}
}
