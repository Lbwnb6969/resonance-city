using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GladiatorTrainingModal : MonoBehaviour
{
	[Header("Gladiator Info")]
	public TextMeshProUGUI gladiatorNameText;

	public GladiatorFatigue gladiatorFatigueCurrentUI;

	public GladiatorFame gladiatorFameCurrentUI;

	[Header("Course List")]
	public Transform courseListContent;

	public GameObject courseItemPrefab;

	[Header("Selection Preview")]
	public GladiatorFatigue gladiatorFatigueResultUI;

	public GladiatorFame gladiatorFameResultUI;

	[Header("Buttons")]
	public Button cancelButton;

	private GladiatorSchool currentSchool;

	private Gladiator currentGladiator;

	private TrainingCourse selectedCourse;

	private List<TrainingCourseItemUI> courseItems = new List<TrainingCourseItemUI>();

	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	public static GladiatorTrainingModal inst;

	private bool isVisible;

	private void Awake()
	{
		inst = this;
		if (cancelButton != null)
		{
			cancelButton.onClick.AddListener(OnCancelClicked);
		}
		SetVisible(v: false);
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	private void SetVisible(bool v)
	{
		isVisible = v;
		Util.SetEnabled(canvas, isVisible);
		Util.SetEnabled(gRaycaster, isVisible);
	}

	public void Show(GladiatorSchool school, Gladiator gladiator)
	{
		if (!isVisible)
		{
			SetVisible(v: true);
			GameUI.SetUIForModalHelper(v: false);
			TimeManager.inst.SetLocked(val: true);
		}
		currentSchool = school;
		currentGladiator = gladiator;
		selectedCourse = null;
		GameUI.inst.ClearUIForClick();
		RefreshUI();
		PopulateCourseList();
	}

	public void Hide()
	{
		if (isVisible)
		{
			SetVisible(v: false);
			GameUI.SetUIForModalHelper(v: true);
			GameUI.inst.SetSelectedBuildingNew(currentSchool.GetComponent<Building>(), forceUpdate: true);
			TimeManager.inst.SetLocked(val: false);
		}
		currentSchool = null;
		currentGladiator = null;
		selectedCourse = null;
	}

	private void RefreshUI()
	{
		if (currentGladiator != null)
		{
			gladiatorNameText.text = currentGladiator.name;
			if (gladiatorFatigueCurrentUI != null)
			{
				gladiatorFatigueCurrentUI.SetFatigue(currentGladiator.fatigueTier);
			}
			if (gladiatorFameCurrentUI != null)
			{
				gladiatorFameCurrentUI.SetFame(currentGladiator.fame);
			}
			UpdateSelectionPreview();
		}
	}

	private void UpdateSelectionPreview()
	{
		if (selectedCourse == null)
		{
			if (gladiatorFatigueResultUI != null)
			{
				gladiatorFatigueResultUI.gameObject.SetActive(value: false);
			}
			if (gladiatorFameResultUI != null)
			{
				gladiatorFameResultUI.gameObject.SetActive(value: false);
			}
			return;
		}
		int resultingFatigueTier = selectedCourse.GetResultingFatigueTier(currentGladiator);
		if (gladiatorFatigueResultUI != null)
		{
			gladiatorFatigueResultUI.gameObject.SetActive(value: true);
			gladiatorFatigueResultUI.SetFatigue(resultingFatigueTier);
		}
		if (gladiatorFameResultUI != null)
		{
			gladiatorFameResultUI.gameObject.SetActive(value: true);
			int fame = Mathf.Clamp(currentGladiator.fame + selectedCourse.fameGain, 0, 5);
			gladiatorFameResultUI.SetFame(fame);
		}
	}

	private void PopulateCourseList()
	{
		foreach (TrainingCourseItemUI courseItem in courseItems)
		{
			if (courseItem != null)
			{
				Object.Destroy(courseItem.gameObject);
			}
		}
		courseItems.Clear();
		TrainingCourse[] array = GladiatorSystem.inst?.GetAllTrainingCourses();
		if (array == null || courseItemPrefab == null || courseListContent == null)
		{
			return;
		}
		TrainingCourse[] array2 = array;
		foreach (TrainingCourse course in array2)
		{
			GameObject gameObject = Object.Instantiate(courseItemPrefab, courseListContent);
			gameObject.SetActive(value: true);
			TrainingCourseItemUI component = gameObject.GetComponent<TrainingCourseItemUI>();
			if (component != null)
			{
				component.SetData(course, OnCourseSelected);
				component.selectButton.interactable = currentSchool.CanStartTraining(currentGladiator.gladiatorId, course);
				courseItems.Add(component);
			}
		}
	}

	private void OnCourseSelected(TrainingCourse course)
	{
		selectedCourse = course;
		if (currentSchool != null && currentGladiator != null && selectedCourse != null && currentSchool.StartTraining(currentGladiator.gladiatorId, selectedCourse))
		{
			Hide();
		}
		UpdateSelectionPreview();
	}

	private void OnCancelClicked()
	{
		SfxSystem.PlayUiSelect();
		Hide();
	}
}
