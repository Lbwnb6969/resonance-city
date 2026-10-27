using UnityEngine;

public class PigSystem : InstanceSystemBehaviour
{
	public static PigSystem inst;

	public Mesh pigModel;

	private void Start()
	{
		inst = this;
	}

	public void Reset()
	{
		ResetInstances();
	}

	private void LateUpdate()
	{
		DrawInstances(pigModel, World.inst.uniMaterialNoFog);
	}
}
