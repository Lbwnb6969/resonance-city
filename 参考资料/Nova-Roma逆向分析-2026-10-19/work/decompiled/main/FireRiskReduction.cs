using UnityEngine;

public class FireRiskReduction : MonoBehaviour
{
	public float strength = 1f;

	public float minProtectionRadius = 4f;

	public float maxProtectionRadius = 7f;

	public Building b;

	private void OnBuilt()
	{
		FirehouseManager.inst.Add(this);
	}

	private void OnFinishedLoad()
	{
		if (b.IsBuilt())
		{
			FirehouseManager.inst.Add(this);
		}
	}

	private void OnShutdown()
	{
		FirehouseManager.inst.Remove(this);
	}
}
