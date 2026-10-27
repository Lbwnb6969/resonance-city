using System;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
[CreateAssetMenu(fileName = "ResourceDefinitionList", menuName = "Tools/ResourceDefinitionList", order = 1)]
public class ResourceDefinitions : ScriptableObject
{
	public List<FreeResourceSystem.ResourceDef> initialResourceDefinitions = new List<FreeResourceSystem.ResourceDef>();
}
