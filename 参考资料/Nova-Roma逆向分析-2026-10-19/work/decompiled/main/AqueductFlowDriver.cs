using UnityEngine;

public class AqueductFlowDriver : MonoBehaviour
{
	public static AqueductFlowDriver inst;

	private void Awake()
	{
		inst = this;
	}

	private void OnDestroy()
	{
		if (inst == this)
		{
			inst = null;
		}
	}

	private void LateUpdate()
	{
		AqueductFlowController.SolveIfDirtyAndFlush();
	}
}
