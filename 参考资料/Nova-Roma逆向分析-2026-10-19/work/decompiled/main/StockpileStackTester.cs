using UnityEngine;

public class StockpileStackTester : MonoBehaviour
{
	private Timer timer = new Timer(1f);

	private bool increment = true;

	private void Update()
	{
		Stack component = GetComponent<Stack>();
		if (increment)
		{
			component.Add(1);
		}
		else
		{
			component.Remove(1);
		}
	}
}
