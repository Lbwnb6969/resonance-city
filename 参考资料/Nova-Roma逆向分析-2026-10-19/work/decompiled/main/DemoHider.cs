using UnityEngine;

public class DemoHider : MonoBehaviour
{
	private void Start()
	{
	}

	private void Update()
	{
		if (!World.inst.demoMode)
		{
			gameObject.SetActive(value: false);
		}
	}
}
