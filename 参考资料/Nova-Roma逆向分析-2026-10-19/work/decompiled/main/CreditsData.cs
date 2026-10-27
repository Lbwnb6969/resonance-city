using UnityEngine;

[CreateAssetMenu(fileName = "CreditsData", menuName = "ScriptableObjects/CreditsData")]
public class CreditsData : ScriptableObject
{
	public CreditEntry[] entries;
}
