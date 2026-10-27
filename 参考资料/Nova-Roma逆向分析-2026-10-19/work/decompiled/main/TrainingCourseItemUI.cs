using System;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class TrainingCourseItemUI : MonoBehaviour
{
	public Image iconImage;

	public TextMeshProUGUI nameText;

	public TextMeshProUGUI descriptionText;

	public TextMeshProUGUI beastSkillTxt;

	public TextMeshProUGUI retariusSkillTxt;

	public TextMeshProUGUI secutorSkillTxt;

	public GameObject beastSkill;

	public GameObject retariusSkill;

	public GameObject secutorSkill;

	public TextMeshProUGUI fatigueGainText;

	public TextMeshProUGUI fameGainText;

	public GameObject fameGainContainer;

	public TextMeshProUGUI warningText;

	public TextMeshProUGUI costText;

	public TextMeshProUGUI durationText;

	public Button selectButton;

	private Action<TrainingCourse> onSelected;

	public TrainingCourse Course { get; private set; }

	private void Awake()
	{
		if (selectButton != null)
		{
			selectButton.onClick.AddListener(OnClicked);
		}
	}

	public void SetData(TrainingCourse course, Action<TrainingCourse> onSelect)
	{
		Course = course;
		onSelected = onSelect;
		iconImage.sprite = course.icon;
		iconImage.gameObject.SetActive(course.icon != null);
		nameText.text = LocalizationManager.GetTranslation(course.nameKey);
		descriptionText.text = LocalizationManager.GetTranslation(course.descriptionKey);
		beastSkill.gameObject.SetActive(value: false);
		retariusSkill.gameObject.SetActive(value: false);
		secutorSkill.gameObject.SetActive(value: false);
		for (int i = 0; i < course.skillTargets.Length; i++)
		{
			if (course.skillTargets[i] == GladiatorSkillType.Bestiarius)
			{
				beastSkill.gameObject.SetActive(value: true);
				beastSkillTxt.SetText("+{0}", course.skillGains[i]);
			}
			if (course.skillTargets[i] == GladiatorSkillType.Retiarius)
			{
				retariusSkill.gameObject.SetActive(value: true);
				retariusSkillTxt.SetText("+{0}", course.skillGains[i]);
			}
			if (course.skillTargets[i] == GladiatorSkillType.Secutor)
			{
				secutorSkill.gameObject.SetActive(value: true);
				secutorSkillTxt.SetText("+{0}", course.skillGains[i]);
			}
		}
		costText.SetText("<sprite name=icon_gold>{0}", course.goldCost);
		string term = ((course.durationSeasons == 1) ? "training_duration_season" : "training_duration_seasons");
		durationText.text = string.Format(LocalizationManager.GetTranslation(term), course.durationSeasons);
		fatigueGainText.text = string.Format(LocalizationManager.GetTranslation("training_fatigue_gain"), course.fatigueGain);
		if (course.fameGain != 0)
		{
			fameGainText.SetText(LocalizationManager.GetTranslation("training_fame_gain"), course.fameGain);
			fameGainContainer.gameObject.SetActive(value: true);
		}
		else
		{
			fameGainContainer.gameObject.SetActive(value: false);
		}
		if (warningText != null)
		{
			if (course.injuryRisk > 0f)
			{
				warningText.text = LocalizationManager.GetTranslation("training_injury_risk");
				warningText.gameObject.SetActive(value: true);
			}
			else
			{
				warningText.gameObject.SetActive(value: false);
			}
		}
	}

	private void OnClicked()
	{
		SfxSystem.PlayUiSelect();
		onSelected?.Invoke(Course);
	}
}
