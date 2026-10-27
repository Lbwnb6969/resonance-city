using UnityEngine;

public class FirstPersonDoorTrigger : MonoBehaviour
{
	[Header("Trigger Settings")]
	public Vector3 triggerSize = new Vector3(2f, 2f, 2f);

	public Color triggerColor = new Color(0f, 1f, 0f, 0.3f);

	private BoxCollider triggerCollider;

	private Keep associatedKeep;

	private void Awake()
	{
		associatedKeep = GetComponentInParent<Keep>();
		SetupTrigger();
	}

	private void SetupTrigger()
	{
		GameObject gameObject = new GameObject("FirstPersonDoorTrigger");
		gameObject.transform.SetParent(transform);
		gameObject.transform.localPosition = Vector3.zero;
		triggerCollider = gameObject.AddComponent<BoxCollider>();
		triggerCollider.isTrigger = true;
		triggerCollider.size = triggerSize;
		FirstPersonDoorTrigger firstPersonDoorTrigger = gameObject.AddComponent<FirstPersonDoorTrigger>();
		firstPersonDoorTrigger.associatedKeep = associatedKeep;
		firstPersonDoorTrigger.triggerSize = triggerSize;
		firstPersonDoorTrigger.triggerColor = triggerColor;
	}

	private void OnTriggerEnter(Collider other)
	{
		if (!(FirstPersonManager.inst == null) && other.GetComponent<FirstPersonController>() != null && FirstPersonManager.inst.IsInFirstPerson())
		{
			ShowExitPrompt();
		}
	}

	private void OnTriggerStay(Collider other)
	{
		if (!(FirstPersonManager.inst == null) && other.GetComponent<FirstPersonController>() != null && FirstPersonManager.inst.IsInFirstPerson() && (Input.GetKeyDown(KeyCode.E) || Input.GetKeyDown(KeyCode.Return)))
		{
			FirstPersonManager.inst.ExitFirstPerson();
		}
	}

	private void ShowExitPrompt()
	{
		Debug.Log("Press E or Enter to exit first person mode");
	}

	private void OnDrawGizmos()
	{
		Gizmos.color = triggerColor;
		Gizmos.DrawCube(transform.position, triggerSize);
		Gizmos.color = new Color(triggerColor.r, triggerColor.g, triggerColor.b, 1f);
		Gizmos.DrawWireCube(transform.position, triggerSize);
	}
}
