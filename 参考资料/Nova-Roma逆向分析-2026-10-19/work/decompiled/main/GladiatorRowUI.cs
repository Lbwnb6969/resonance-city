using System;
using Assets.Code.UI;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GladiatorRowUI : MonoBehaviour
{
	[Header("Identity")]
	public RawImage portrait;

	public TextMeshProUGUI nameText;

	public TextMeshProUGUI titleText;

	[Header("Fame")]
	public GladiatorFame fame;

	[Header("Alignment")]
	public Image alignmentBadge;

	public Sprite heroSprite;

	public Sprite neutralSprite;

	public Sprite heelSprite;

	[Header("Skills")]
	public TextMeshProUGUI bestiariusSkillTxt;

	[Header("Skills")]
	public TextMeshProUGUI retiariusSkillTxt;

	[Header("Skills")]
	public TextMeshProUGUI secutorSkillTxt;

	[Header("Fatigue")]
	public GladiatorFatigue fatigue;

	[Header("Training")]
	public GameObject trainingContainer;

	public Slider trainingProgressBar;

	public TextMeshProUGUI trainingTimeText;

	public TextMeshProUGUI trainingNameText;

	[Header("Actions")]
	public Button trainButton;

	public Button fireButton;

	public Confirmation fireConfirmation;

	private Gladiator currentGladiator;

	private Action<Gladiator> onTrainCallback;

	private Action<Gladiator> onFireCallback;

	private void Awake()
	{
		if (trainButton != null)
		{
			trainButton.onClick.AddListener(OnTrainClicked);
		}
		if (fireButton != null)
		{
			fireButton.onClick.AddListener(OnFireClicked);
		}
	}

	public void SetData(Gladiator gladiator, TrainingAssignment training, Action<Gladiator> onTrain, Action<Gladiator> onFire, GladiatorSchool school)
	{
		currentGladiator = gladiator;
		onTrainCallback = onTrain;
		onFireCallback = onFire;
		if (nameText != null)
		{
			nameText.text = gladiator.name;
		}
		if (titleText != null)
		{
			if (gladiator.titleId >= 0)
			{
				titleText.text = "";
				titleText.gameObject.SetActive(value: false);
			}
			else
			{
				titleText.gameObject.SetActive(value: false);
			}
		}
		if (fame != null)
		{
			fame.SetFame(gladiator.fame);
		}
		UpdateAlignmentBadge(gladiator.alignment);
		secutorSkillTxt.SetText("{0}", gladiator.skills.secutor);
		retiariusSkillTxt.SetText("{0}", gladiator.skills.retiarius);
		bestiariusSkillTxt.SetText("{0}", gladiator.skills.bestiarius);
		if (fatigue != null)
		{
			fatigue.SetFatigue(gladiator.fatigueTier);
		}
		bool flag = training != null && !training.IsComplete();
		if (trainingContainer != null)
		{
			trainingContainer.SetActive(flag);
		}
		if (flag)
		{
			trainingProgressBar.value = training.GetProgress();
			int seasonsRemaining = training.GetSeasonsRemaining();
			if (seasonsRemaining <= 0)
			{
				trainingTimeText.text = ScriptLocalization.Completed;
			}
			if (seasonsRemaining == 1)
			{
				trainingTimeText.SetText(LocalizationManager.GetTranslation("training_duration_season"), seasonsRemaining);
			}
			else
			{
				trainingTimeText.SetText(LocalizationManager.GetTranslation("training_duration_seasons"), seasonsRemaining);
			}
			if (trainingNameText != null)
			{
				TrainingCourse trainingCourse = GladiatorSystem.inst.GetTrainingCourse(training.courseId);
				trainingNameText.text = ((trainingCourse != null) ? LocalizationManager.GetTranslation(trainingCourse.nameKey) : "");
			}
		}
		trainButton.gameObject.SetActive(!flag);
		trainButton.interactable = gladiator.CanTrain() && school.GetComponent<Building>().GetWorkerPercent() > 0.95f;
		fireButton.gameObject.SetActive(!flag);
	}

	private void UpdateAlignmentBadge(GladiatorAlignment alignment)
	{
		if (!(alignmentBadge == null))
		{
			switch (alignment)
			{
			case GladiatorAlignment.Hero:
				alignmentBadge.sprite = heroSprite;
				break;
			case GladiatorAlignment.Neutral:
				alignmentBadge.sprite = neutralSprite;
				break;
			case GladiatorAlignment.Heel:
				alignmentBadge.sprite = heelSprite;
				break;
			}
			alignmentBadge.gameObject.SetActive(alignmentBadge.sprite != null);
		}
	}

	private void OnTrainClicked()
	{
		SfxSystem.PlayUiSelect();
		onTrainCallback?.Invoke(currentGladiator);
	}

	private void OnFireClicked()
	{
		SfxSystem.PlayUiSelect();
		if (currentGladiator == null || onFireCallback == null)
		{
			return;
		}
		if (fireConfirmation != null)
		{
			fireConfirmation.ShowConfirmation(() =>
			{
				onFireCallback(currentGladiator);
			}, null);
		}
		else
		{
			onFireCallback(currentGladiator);
		}
	}
}
