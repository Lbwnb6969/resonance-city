using UnityEngine;

public class FirstPersonIntegration : MonoBehaviour
{
	private FirstPersonManager fpManager;

	private void Start()
	{
		if (FirstPersonManager.inst == null)
		{
			GameObject gameObject = new GameObject("FirstPersonManager");
			fpManager = gameObject.AddComponent<FirstPersonManager>();
		}
		AddDoorTriggersToExistingOutposts();
	}

	private void AddDoorTriggersToExistingOutposts()
	{
		Keep[] array = Object.FindObjectsByType<Keep>(FindObjectsSortMode.None);
		foreach (Keep keep in array)
		{
			if (keep.GetComponentInChildren<FirstPersonDoorTrigger>() == null)
			{
				GameObject gameObject = new GameObject("DoorTrigger");
				gameObject.transform.SetParent(keep.transform);
				Vector3 vector = Vector3.one;
				Building component = keep.GetComponent<Building>();
				if (component != null && component.size != Vector3.zero)
				{
					vector = component.size;
				}
				gameObject.transform.localPosition = new Vector3(0f, 0f, vector.z * 0.5f + 1f);
				gameObject.AddComponent<FirstPersonDoorTrigger>();
			}
		}
	}

	private void Update()
	{
		if (FirstPersonManager.inst != null && FirstPersonManager.inst.IsInFirstPerson())
		{
			ShowFirstPersonHUD();
		}
	}

	private void ShowFirstPersonHUD()
	{
		GUILayout.BeginArea(new Rect(10f, 10f, 300f, 200f));
		GUILayout.Label("First Person Mode Active");
		GUILayout.Label("WASD: Move");
		GUILayout.Label("Mouse: Look");
		GUILayout.Label("Shift: Run");
		GUILayout.Label("Space: Jump");
		GUILayout.Label("F: Toggle First Person");
		GUILayout.Label("Escape: Exit First Person");
		GUILayout.Label("E/Enter: Exit at Roman Outpost door");
		if (FirstPersonManager.inst.GetController() != null && FirstPersonManager.inst.GetController().IsInWater())
		{
			GUILayout.Label("In Water - Slow Movement");
		}
		GUILayout.EndArea();
	}
}
