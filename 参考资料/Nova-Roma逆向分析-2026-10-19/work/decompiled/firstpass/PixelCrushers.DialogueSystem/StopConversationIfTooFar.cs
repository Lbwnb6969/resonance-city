using System.Collections;
using UnityEngine;

namespace PixelCrushers.DialogueSystem;

[AddComponentMenu("")]
public class StopConversationIfTooFar : MonoBehaviour
{
	public float maxDistance = 5f;

	public float monitorFrequency = 1f;

	private void OnConversationStart(Transform actor)
	{
		StopAllCoroutines();
		StartCoroutine(MonitorDistance(actor));
	}

	private void OnConversationEnd(Transform actor)
	{
		StopAllCoroutines();
	}

	private void OnDisable()
	{
		StopAllCoroutines();
	}

	private IEnumerator MonitorDistance(Transform actor)
	{
		if (actor != null)
		{
			Transform myTransform = transform;
			do
			{
				yield return StartCoroutine(DialogueTime.WaitForSeconds(monitorFrequency));
			}
			while (!(Vector3.Distance(myTransform.position, actor.position) > maxDistance));
			if (DialogueDebug.logInfo)
			{
				Debug.Log(string.Format("{0}: Stopping conversation. Exceeded max distance {1} between {2} and {3}", "Dialogue System", maxDistance, name, actor.name));
			}
			DialogueManager.StopConversation();
		}
	}
}
