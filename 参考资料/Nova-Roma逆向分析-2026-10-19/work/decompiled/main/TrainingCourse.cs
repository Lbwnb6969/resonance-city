using UnityEngine;

[CreateAssetMenu(fileName = "NewTrainingCourse", menuName = "Gladiator/Training Course")]
public class TrainingCourse : ScriptableObject
{
	[Header("Identity")]
	public string courseId;

	public string nameKey;

	public string descriptionKey;

	public Sprite icon;

	[Header("Cost & Duration")]
	[Tooltip("Duration in seasons")]
	public int durationSeasons = 1;

	public int goldCost = 100;

	[Header("Skill Training")]
	[Tooltip("Which skills this course targets")]
	public GladiatorSkillType[] skillTargets;

	[Tooltip("Skill gains for each target (parallel arrays)")]
	public int[] skillGains;

	[Header("Side Effects")]
	[Range(0f, 5f)]
	[Tooltip("Fatigue added upon completion")]
	public int fatigueGain = 1;

	[Tooltip("Alignment shift: negative = toward Hero, positive = toward Heel")]
	[Range(-1f, 1f)]
	public float alignmentShift;

	[Tooltip("Chance of injury during training (0-1)")]
	[Range(0f, 1f)]
	public float injuryRisk;

	[Tooltip("Fame gained upon completion")]
	public int fameGain;

	public float GetDurationInGameTime()
	{
		return (float)durationSeasons * 112f;
	}

	public int GetResultingFatigueTier(Gladiator gladiator)
	{
		return Mathf.Min(5, gladiator.fatigueTier + fatigueGain);
	}
}
