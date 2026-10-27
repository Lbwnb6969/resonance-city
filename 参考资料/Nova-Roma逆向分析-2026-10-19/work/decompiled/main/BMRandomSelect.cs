using UnityEngine;

public class BMRandomSelect : MonoBehaviour
{
	public int PercentChanceOn = 50;

	private void Start()
	{
		gameObject.SetActive(SRand.Range(0, 100) <= PercentChanceOn);
	}
}
