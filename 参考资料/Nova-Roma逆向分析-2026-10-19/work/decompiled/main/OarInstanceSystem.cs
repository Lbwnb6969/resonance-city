using UnityEngine;

public class OarInstanceSystem : InstanceSystemBehaviour
{
	public static OarInstanceSystem inst;

	public Mesh mesh;

	private void Awake()
	{
		inst = this;
	}

	private void LateUpdate()
	{
		DrawInstances(mesh, World.inst.romeUnimaterial);
	}
}
