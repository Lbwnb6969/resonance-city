using System.Collections.Generic;
using UnityEngine;

public class InstanceSilo
{
	public Mesh sharedMesh;

	public Material sharedMaterial;

	public List<ArrayExt<RenderInstance>> instances;

	public List<ArrayExt<Matrix4x4>> matricies;

	public bool castShadows = true;
}
