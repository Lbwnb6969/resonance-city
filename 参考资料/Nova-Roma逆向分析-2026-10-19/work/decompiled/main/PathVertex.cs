using System;
using UnityEngine;

[Serializable]
[ExecuteInEditMode]
public class PathVertex : MonoBehaviour
{
	[HideInInspector]
	public short pathingId;

	public bool internalNode;

	public bool externalNode;

	public bool personPositionNode;
}
