using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;

[Serializable]
[CreateAssetMenu(fileName = "DynamicMeshGroup", menuName = "ScriptableObjects/DynamicMeshGroup")]
public class DynamicMeshGroup : ScriptableObject
{
	public int type;

	public static ValueDropdownList<int> TypeOptions = new ValueDropdownList<int>
	{
		{
			"Bath Library",
			DynamicMesh.BathLibrary
		},
		{
			"Bath Palaestra (Gym)",
			DynamicMesh.BathPalaestra
		},
		{
			"Bath Hot Pool",
			DynamicMesh.BathHotPool
		}
	};

	public List<DynamicMeshEntry> entries;

	[NonSerialized]
	public Dictionary<int, List<DynamicMeshEntry>> entryGroups;

	[NonSerialized]
	public DynamicMeshSize[] sizes;

	[NonSerialized]
	public static ArrayExt<DynamicMeshSize> tempSizes;

	public void Init()
	{
		if (tempSizes == null)
		{
			tempSizes = new ArrayExt<DynamicMeshSize>(DynamicMeshEntry.SizeOptions.Count);
		}
		tempSizes.Clear();
		entryGroups = new Dictionary<int, List<DynamicMeshEntry>>(DynamicMeshEntry.SizeOptions.Count);
		for (int i = 0; i < entries.Count; i++)
		{
			DynamicMeshEntry dynamicMeshEntry = entries[i];
			if (!entryGroups.ContainsKey(dynamicMeshEntry.size))
			{
				entryGroups.Add(dynamicMeshEntry.size, new List<DynamicMeshEntry>(16));
			}
			entryGroups[dynamicMeshEntry.size].Add(dynamicMeshEntry);
			DynamicMeshSize dynamicMeshSize = DynamicMesh.mSizeData[dynamicMeshEntry.size];
			if (!tempSizes.Contains(dynamicMeshSize))
			{
				int j;
				for (j = 0; j < tempSizes.Count && tempSizes.data[j].area <= dynamicMeshSize.area; j++)
				{
				}
				tempSizes.Insert(j, dynamicMeshSize);
			}
		}
		sizes = new DynamicMeshSize[tempSizes.Count];
		for (int k = 0; k < sizes.Length; k++)
		{
			sizes[k] = tempSizes.data[k];
		}
	}
}
