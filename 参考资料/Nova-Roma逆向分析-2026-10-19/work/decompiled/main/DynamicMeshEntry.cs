using System;
using Sirenix.OdinInspector;
using UnityEngine;

[Serializable]
public class DynamicMeshEntry
{
	public int size;

	public Mesh mesh;

	public static ValueDropdownList<int> SizeOptions = new ValueDropdownList<int>
	{
		{
			"1x1",
			DynamicMesh._1x1
		},
		{
			"1x2",
			DynamicMesh._1x2
		},
		{
			"1x3",
			DynamicMesh._1x3
		},
		{
			"2x2",
			DynamicMesh._2x2
		},
		{
			"2x3",
			DynamicMesh._2x3
		}
	};
}
