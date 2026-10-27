using UnityEngine;

public class WolfSystem : InstanceSystemBehaviour
{
	public static WolfSystem inst;

	public Mesh wolfModel;

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
		DrawInstances(wolfModel, World.inst.uniMaterialFog);
	}
}
