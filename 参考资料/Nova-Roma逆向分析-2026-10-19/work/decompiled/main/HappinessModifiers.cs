using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "ResidentialTiles", menuName = "ScriptableObjects/ResidentialTiles")]
public class HappinessModifiers : ScriptableObject
{
	public List<HappinessModifierSystem.HappinessModifier> ConsumableModifiers = new List<HappinessModifierSystem.HappinessModifier>();

	public List<HappinessModifierSystem.HappinessModifier> ResidentialTileModifiers = new List<HappinessModifierSystem.HappinessModifier>();
}
