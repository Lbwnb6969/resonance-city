using System;
using UnityEngine;

[Serializable]
[ExecuteInEditMode]
public class MeshDescriptor : MonoBehaviour
{
	public Vector3 Size = new Vector3(1f, 1f, 1f);

	public ZXSideToggle CantBlock;

	public ZXSideToggle MustBlock;
}
