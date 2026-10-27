using UnityEngine;

[CreateAssetMenu(fileName = "NewGladiatorTitle", menuName = "Gladiator/Title")]
public class GladiatorTitle : ScriptableObject
{
	public int titleId;

	public string nameKey;

	public string descriptionKey;

	public int fameRequired;

	public int killsRequired;

	public GladiatorSkillType? skillRequired;

	public int skillLevelRequired;
}
