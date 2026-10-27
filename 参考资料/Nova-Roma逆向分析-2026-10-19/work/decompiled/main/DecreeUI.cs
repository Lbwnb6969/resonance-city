using System;
using System.Collections.Generic;
using FMODUnity;
using I2.Loc;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class DecreeUI : MonoBehaviour
{
	public static DecreeUI inst;

	[SerializeField]
	private Canvas mainCanvas;

	[SerializeField]
	private Canvas subCanvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private RectTransform rootRectT;

	[SerializeField]
	private Button exitBtn;

	[SerializeField]
	private DecreeUIItem itemPrefab;

	[SerializeField]
	private ScrollRect scrollRect;

	[SerializeField]
	private RectTransform scrollViewRectT;

	[SerializeField]
	private RectTransform itemContainerRectT;

	[SerializeField]
	private RectTransform layoutContainerRectT;

	[SerializeField]
	private RectTransform scrollContainerRectT;

	[SerializeField]
	private RectTransform manualJobContainerRectT;

	[SerializeField]
	private RectTransform adjustArrowsRectT;

	[SerializeField]
	private EventTrigger incrementTrigger;

	[SerializeField]
	private EventTrigger decrementTrigger;

	[SerializeField]
	private GameObject focusOverLandObj;

	private Dictionary<int, DecreeUIItem> priorityItems = new Dictionary<int, DecreeUIItem>();

	private bool isVisible;

	private int landmass = -1;

	private int prevLandmass = -1;

	private bool isDragging;

	private DecreeUIItem dragItem;

	private Vector2 dragOffset;

	private int originalIdx;

	private float edgeScrolling;

	private readonly float edgeScrollSpeed = 2f;

	private readonly float animateSpeed = 10f;

	private DecreeUIItem hoverItem;

	private Timer holdDuration = new Timer(1f);

	private float holdAcceleration = 1f;

	private readonly float holdAccelerationStep = 0.1f;

	private readonly float holdAccelerationMax = 25f;

	private bool incrementPressed;

	private bool decrementPressed;

	private bool isAdjustArrowsHovered;

	private bool doItemsUpdateThisFrame;

	public Vector2 onHoverOffset;

	public bool IsVisible()
	{
		return isVisible;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		ArrayExt<JobSystem.JobCategory> jobCategories = JobSystem.jobCategories;
		for (int i = 0; i < jobCategories.Count; i++)
		{
			AddPriorityItem(jobCategories.data[i]);
		}
		exitBtn.onClick.AddListener(() =>
		{
			SfxSystem.PlayUiSelect();
			SetVisibility(v: false);
		});
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(UpdateConsoleUI));
		JobSystem jobSystem = JobSystem.inst;
		jobSystem.onJobCategoryAdded = (JobSystem.OnJobCategoryAdded)Delegate.Combine(jobSystem.onJobCategoryAdded, new JobSystem.OnJobCategoryAdded(AddPriorityItem));
		SetVisibility(v: false);
		Util.SetActive(adjustArrowsRectT.gameObject, active: false);
		EventTrigger.Entry entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerEnter
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			isAdjustArrowsHovered = true;
		});
		incrementTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerExit
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			isAdjustArrowsHovered = false;
			incrementPressed = false;
			ResetHoldSettings();
		});
		incrementTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerEnter
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			isAdjustArrowsHovered = true;
		});
		decrementTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerExit
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			isAdjustArrowsHovered = false;
			decrementPressed = false;
			ResetHoldSettings();
		});
		decrementTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerDown
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnPointerClick(isDown: true, ref incrementPressed);
		});
		incrementTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerDown
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnPointerClick(isDown: true, ref decrementPressed);
		});
		decrementTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerUp
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnPointerClick(isDown: false, ref incrementPressed);
		});
		incrementTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry
		{
			eventID = EventTriggerType.PointerUp
		};
		entry.callback.AddListener((BaseEventData data) =>
		{
			OnPointerClick(isDown: false, ref decrementPressed);
		});
		decrementTrigger.triggers.Add(entry);
	}

	private void OnDestroy()
	{
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(UpdateConsoleUI));
		JobSystem jobSystem = JobSystem.inst;
		jobSystem.onJobCategoryAdded = (JobSystem.OnJobCategoryAdded)Delegate.Remove(jobSystem.onJobCategoryAdded, new JobSystem.OnJobCategoryAdded(AddPriorityItem));
	}

	public void ToggleVisibility()
	{
		if (!isVisible)
		{
			GameUI.inst.ClearCellSelected();
		}
		if (isVisible || Player.inst.DoesAnyBuildingHaveCategoryOnPlayerLandmass("temple", mustBeBuilt: true))
		{
			SetVisibility(!isVisible);
		}
	}

	public void SetVisibility(bool v)
	{
		if (v)
		{
			landmass = Player.inst.FocusedLandMass;
			BuildUI.inst.HideGroups();
			doItemsUpdateThisFrame = true;
		}
		if ((isVisible != v) & v)
		{
			SfxSystem.PlayUiOpen();
		}
		Util.SetEnabled(mainCanvas, v);
		Util.SetEnabled(subCanvas, v);
		gRaycaster.enabled = v;
		enabled = v;
		isVisible = v;
	}

	private void AddPriorityItem(JobSystem.JobCategory jCategory)
	{
		if (jCategory.id == 64)
		{
			return;
		}
		if (!priorityItems.ContainsKey(jCategory.id))
		{
			DecreeUIItem item = UnityEngine.Object.Instantiate(itemPrefab, jCategory.isManualJob ? manualJobContainerRectT : itemContainerRectT, worldPositionStays: false);
			item.name = "Content_" + jCategory.name;
			item.jobCategoryID = jCategory.id;
			item.background.color = jCategory.color;
			item.titleTMP.GetComponent<Localize>().SetTerm("JobCategory" + jCategory.name);
			if (!jCategory.isManualJob)
			{
				RectTransform rectTransform = new GameObject("Layout_" + jCategory.name).AddComponent<RectTransform>();
				rectTransform.gameObject.AddComponent<LayoutElement>().minHeight = 32f;
				rectTransform.SetParent(layoutContainerRectT, worldPositionStays: false);
				item.layoutRectT = rectTransform;
				item.rectT.anchoredPosition = rectTransform.anchoredPosition;
				EventTrigger.Entry entry = new EventTrigger.Entry
				{
					eventID = EventTriggerType.BeginDrag
				};
				entry.callback.AddListener((BaseEventData data) =>
				{
					OnBeginDrag((PointerEventData)data, item, jCategory);
				});
				item.eventTrigger.triggers.Add(entry);
				entry = new EventTrigger.Entry
				{
					eventID = EventTriggerType.Drag
				};
				entry.callback.AddListener((BaseEventData data) =>
				{
					OnDrag((PointerEventData)data, item, jCategory);
				});
				item.eventTrigger.triggers.Add(entry);
				entry = new EventTrigger.Entry
				{
					eventID = EventTriggerType.EndDrag
				};
				entry.callback.AddListener((BaseEventData data) =>
				{
					OnEndDrag((PointerEventData)data, item, jCategory);
				});
				item.eventTrigger.triggers.Add(entry);
				if (item.scrollTriggers != null)
				{
					for (int num = 0; num < item.scrollTriggers.Length; num++)
					{
						entry = new EventTrigger.Entry
						{
							eventID = EventTriggerType.Scroll
						};
						entry.callback.AddListener((BaseEventData data) =>
						{
							OnScroll((PointerEventData)data);
						});
						item.scrollTriggers[num].triggers.Add(entry);
					}
				}
				item.closeToggle.onValueChanged.AddListener((bool isOn) =>
				{
					if (landmass != -1)
					{
						if (isOn)
						{
							SfxSystem.PlayUiCancel();
						}
						else
						{
							SfxSystem.PlayUiCancel();
						}
						jCategory.isOpen[landmass] = isOn;
						item.isClosedBackground.gameObject.SetActive(!isOn);
						item.titleTMP.color = (isOn ? Color.white : Color.gray);
					}
				});
				item.maxWorkerInput.onSubmit.AddListener((string val) =>
				{
					if (landmass != -1 && int.TryParse(val, out var result) && result >= 0)
					{
						jCategory.isCustomJobsAvailableEnabled[landmass] = result != jCategory.jobsAvailable[landmass] && (result <= jCategory.jobsAvailable[landmass] || jCategory.isMaxInfinite);
						jCategory.customJobsAvailable[landmass] = result;
					}
				});
				item.maxWorkerInput.onSelect.AddListener((string val) =>
				{
					GameState.inst.AlphaNumericHotkeysEnabled = false;
				});
				item.maxWorkerInput.onDeselect.AddListener((string val) =>
				{
					if (landmass != -1)
					{
						if (int.TryParse(val, out var result))
						{
							if (result < 0)
							{
								return;
							}
							jCategory.isCustomJobsAvailableEnabled[landmass] = result != jCategory.jobsAvailable[landmass] && (result <= jCategory.jobsAvailable[landmass] || jCategory.isMaxInfinite);
							jCategory.customJobsAvailable[landmass] = result;
						}
						GameState.inst.AlphaNumericHotkeysEnabled = true;
					}
				});
				entry = new EventTrigger.Entry
				{
					eventID = EventTriggerType.PointerEnter
				};
				entry.callback.AddListener((BaseEventData data) =>
				{
					OnPointerEnter((PointerEventData)data, item, jCategory);
				});
				item.eventTrigger.triggers.Add(entry);
				entry = new EventTrigger.Entry
				{
					eventID = EventTriggerType.PointerExit
				};
				entry.callback.AddListener((BaseEventData data) =>
				{
					OnPointerExit((PointerEventData)data, item, jCategory);
				});
				item.eventTrigger.triggers.Add(entry);
			}
			else
			{
				item.maxWorkerInputBackground.SetActive(value: false);
				item.maxWorkerInput.interactable = false;
				item.priorityTMP.gameObject.SetActive(value: false);
				item.closeToggle.gameObject.SetActive(value: false);
				item.closedCountTMP.gameObject.SetActive(value: false);
				item.maxWorkerTMP.gameObject.SetActive(value: false);
				item.titleTMP.color = Color.white;
				item.maxWorkerInput.gameObject.SetActive(value: false);
				item.slashTMP.gameObject.SetActive(value: false);
				RectTransform component = item.workerCountTMP.GetComponent<RectTransform>();
				Vector2 anchoredPosition = component.anchoredPosition;
				anchoredPosition.x = 43f;
				component.anchoredPosition = anchoredPosition;
				item.lockIcon.SetActive(value: true);
				item.rectT.gameObject.SetActive(jCategory.id != 13);
			}
			priorityItems.Add(jCategory.id, item);
		}
		else
		{
			Debug.Log("Tried to add duplicated category: " + jCategory.name);
		}
	}

	private void Update()
	{
		landmass = Player.inst.FocusedLandMass;
		if ((doItemsUpdateThisFrame || landmass != prevLandmass) && landmass != -1)
		{
			ForceItemUpdates();
			doItemsUpdateThisFrame = false;
		}
		if (landmass == -1 && isDragging && dragItem != null)
		{
			dragItem.layoutRectT.SetSiblingIndex(originalIdx);
			dragItem = null;
			isDragging = false;
		}
		Util.SetActive(focusOverLandObj, landmass == -1);
		Util.SetActive(itemContainerRectT.gameObject, landmass != -1);
		Util.SetActive(manualJobContainerRectT.gameObject, landmass != -1);
		if (!isVisible || landmass == -1)
		{
			return;
		}
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		if (isDragging && Mathff.Abs(edgeScrolling) > 0.0001f)
		{
			scrollRect.verticalNormalizedPosition = Mathff.Clamp01(scrollRect.verticalNormalizedPosition + edgeScrolling);
		}
		for (int i = 0; i < JobSystem.priorityJobCategories.data[landmass].Count; i++)
		{
			JobSystem.JobCategory jobCategory = JobSystem.priorityJobCategories.data[landmass].data[i];
			if (!priorityItems.TryGetValue(jobCategory.id, out var value) || value.Equals(dragItem))
			{
				continue;
			}
			if (!jobCategory.isManualJob)
			{
				bool flag = (jobCategory.jobsAvailable[landmass] + jobCategory.jobsClosed[landmass] > 0 || jobCategory.id == 1 || jobCategory.id == 21) && jobCategory.id != 37;
				value.rectT.gameObject.SetActive(flag);
				value.layoutRectT.gameObject.SetActive(flag);
				if (!flag)
				{
					continue;
				}
				ArrayExtRef<Job> arrayExtRef = jobCategory.jobs.data[landmass];
				bool flag2 = true;
				for (int j = 0; j < arrayExtRef.Count; j++)
				{
					if (!arrayExtRef.data[j].passesWageReq)
					{
						flag2 = false;
						break;
					}
				}
				Util.SetEnabled(value.wageThoughtBubbleRI, !flag2);
				value.priorityTMP.text = GetSiblingIndex(value.layoutRectT).ToString();
				value.maxWorkerTMP.text = $"({jobCategory.jobsAvailable[landmass]})";
				value.maxWorkerTMP.gameObject.SetActive(jobCategory.isCustomJobsAvailableEnabled[landmass]);
				if (!value.maxWorkerInput.isFocused)
				{
					value.maxWorkerInput.SetTextWithoutNotify(jobCategory.isCustomJobsAvailableEnabled[landmass] ? jobCategory.customJobsAvailable[landmass].ToString() : jobCategory.jobsAvailable[landmass].ToString());
				}
				value.isCustomPlayerRI.enabled = jobCategory.isCustomJobsAvailableEnabled[landmass];
				value.closedCountTMP.text = jobCategory.jobsClosed[landmass].ToString();
				if (value.closeToggle.isOn != jobCategory.isOpen[landmass])
				{
					value.closeToggle.SetIsOnWithoutNotify(jobCategory.isOpen[landmass]);
				}
				value.titleTMP.color = (value.closeToggle.isOn ? Color.white : Color.gray);
				Vector3 b = value.layoutRectT.anchoredPosition;
				Vector3 zero = Vector3.zero;
				if (value == hoverItem)
				{
					zero.x += onHoverOffset.x;
					zero.y += onHoverOffset.y;
				}
				value.rectT.anchoredPosition = Vector3.Lerp(value.rectT.anchoredPosition, b, unscaledDeltaTime * animateSpeed);
				value.offsetRectT.anchoredPosition = Vector3.Lerp(value.offsetRectT.anchoredPosition, zero, unscaledDeltaTime * animateSpeed);
			}
			else
			{
				value.maxWorkerInput.SetTextWithoutNotify(jobCategory.jobsAvailable[landmass].ToString());
			}
			value.workerCountTMP.text = jobCategory.jobsFilled[landmass].ToString();
			if (value.hideChangeTimer.Update(unscaledDeltaTime))
			{
				value.upArrow.SetActive(value: false);
				value.downArrow.SetActive(value: false);
				value.hideChangeTimer.Enabled = false;
			}
		}
		if ((bool)hoverItem)
		{
			JobSystem.jobCategoriesMap.TryGetValue(hoverItem.jobCategoryID, out var value2);
			if (incrementPressed || decrementPressed)
			{
				holdAcceleration = Mathf.Clamp(holdAcceleration, 1f, holdAccelerationMax);
				float dt = holdAcceleration * Time.unscaledDeltaTime;
				if (holdDuration.Update(dt))
				{
					if (incrementPressed)
					{
						AddToCustomMaxAvailable(value2, 1);
					}
					else if (decrementPressed)
					{
						AddToCustomMaxAvailable(value2, -1);
					}
				}
				holdAcceleration += holdAccelerationStep;
			}
			adjustArrowsRectT.position = hoverItem.maxWorkerInput.transform.position;
			Util.SetActive(incrementTrigger.gameObject, !isDragging && (value2.isMaxInfinite || value2.isCustomJobsAvailableEnabled[landmass]));
			Util.SetActive(decrementTrigger.gameObject, !isDragging && ((!value2.isCustomJobsAvailableEnabled[landmass] && value2.jobsAvailable[landmass] > 0) || (value2.isCustomJobsAvailableEnabled[landmass] && value2.customJobsAvailable[landmass] > 0)));
		}
		Util.SetActive(adjustArrowsRectT.gameObject, hoverItem != null);
		prevLandmass = landmass;
	}

	private void OnBeginDrag(PointerEventData pData, DecreeUIItem item, JobSystem.JobCategory jCategory)
	{
		if (!isDragging && landmass != -1)
		{
			RuntimeManager.PlayOneShot("event:/OldSFX/ui_pickup");
			item.rectT.SetAsLastSibling();
			RectTransformUtility.ScreenPointToLocalPointInRectangle(item.rectT, pData.position, pData.pressEventCamera, out dragOffset);
			originalIdx = item.layoutRectT.GetSiblingIndex();
			dragItem = item;
			isDragging = true;
		}
	}

	private void OnDrag(PointerEventData pData, DecreeUIItem item, JobSystem.JobCategory jCategory)
	{
		if (RectTransformUtility.ScreenPointToWorldPointInRectangle(itemContainerRectT, pData.position - dragOffset, pData.pressEventCamera, out var worldPoint))
		{
			item.rectT.position = worldPoint;
		}
		if (RectTransformUtility.RectangleContainsScreenPoint(scrollViewRectT, pData.position, pData.pressEventCamera))
		{
			RectTransformUtility.ScreenPointToLocalPointInRectangle(scrollContainerRectT, pData.position, pData.pressEventCamera, out var localPoint);
			int idx = (int)(Mathf.Abs(localPoint.y) / Mathf.Abs(item.layoutRectT.sizeDelta.y));
			item.layoutRectT.SetSiblingIndex(GetSiblingIndex(idx));
			edgeScrolling = 0f;
			return;
		}
		RectTransformUtility.ScreenPointToLocalPointInRectangle(scrollViewRectT, pData.position, pData.pressEventCamera, out var localPoint2);
		if (localPoint2.y + scrollViewRectT.rect.y > 0f)
		{
			edgeScrolling = Time.unscaledDeltaTime * Mathff.Clamp01((localPoint2.y + scrollViewRectT.rect.y) / (item.layoutRectT.sizeDelta.y * 1.5f)) * edgeScrollSpeed;
		}
		else if (localPoint2.y < scrollViewRectT.rect.y)
		{
			edgeScrolling = Time.unscaledDeltaTime * Mathff.Clamp01((scrollViewRectT.rect.y - localPoint2.y) / (item.layoutRectT.sizeDelta.y * 1.5f)) * (0f - edgeScrollSpeed);
		}
		if (edgeScrolling > 0f)
		{
			item.layoutRectT.SetSiblingIndex(GetSiblingIndex(0));
		}
		if (edgeScrolling < 0f)
		{
			item.layoutRectT.SetSiblingIndex(GetSiblingIndex(GetActiveChildren(layoutContainerRectT)));
		}
	}

	private void OnEndDrag(PointerEventData pData, DecreeUIItem item, JobSystem.JobCategory jCategory)
	{
		if (!isDragging || item != dragItem || pData == null)
		{
			return;
		}
		if (landmass == -1)
		{
			item.layoutRectT.SetSiblingIndex(originalIdx);
			return;
		}
		RuntimeManager.PlayOneShot("event:/OldSFX/ui_drop");
		foreach (KeyValuePair<int, DecreeUIItem> priorityItem in priorityItems)
		{
			JobSystem.jobCategoriesMap.TryGetValue(priorityItem.Key, out var value);
			if (value != null && !value.isManualJob)
			{
				JobSystem.jobCategoriesMap[priorityItem.Key].priorityIdx[landmass] = priorityItem.Value.layoutRectT.GetSiblingIndex();
			}
		}
		JobSystem.inst.UpdatePriority(landmass);
		dragItem = null;
		isDragging = false;
	}

	private void OnScroll(PointerEventData pData)
	{
		scrollRect.OnScroll(pData);
	}

	private void OnPointerEnter(PointerEventData pData, DecreeUIItem item, JobSystem.JobCategory jCategory)
	{
		incrementPressed = false;
		decrementPressed = false;
		hoverItem = item;
	}

	private void OnPointerExit(PointerEventData pData, DecreeUIItem item, JobSystem.JobCategory jCategory)
	{
		if (hoverItem != null && hoverItem == item && !isAdjustArrowsHovered)
		{
			incrementPressed = false;
			decrementPressed = false;
			hoverItem = null;
		}
	}

	private void OnPointerClick(bool isDown, ref bool isPressedValue)
	{
		if (hoverItem != null)
		{
			isPressedValue = isDown;
		}
		ResetHoldSettings();
	}

	private void AddToCustomMaxAvailable(JobSystem.JobCategory jCategory, int val)
	{
		if (landmass == -1 || jCategory.id == 37)
		{
			return;
		}
		if (!jCategory.isCustomJobsAvailableEnabled[landmass])
		{
			jCategory.customJobsAvailable[landmass] = jCategory.jobsAvailable[landmass];
		}
		int num = jCategory.customJobsAvailable[landmass] + val;
		if (num < 0)
		{
			return;
		}
		if (num >= jCategory.jobsAvailable[landmass])
		{
			if (jCategory.isMaxInfinite)
			{
				jCategory.isCustomJobsAvailableEnabled[landmass] = jCategory.jobsAvailable[landmass] != num;
				jCategory.customJobsAvailable[landmass] = num;
			}
			else
			{
				jCategory.isCustomJobsAvailableEnabled[landmass] = false;
				jCategory.customJobsAvailable[landmass] = jCategory.jobsAvailable[landmass];
			}
		}
		else
		{
			jCategory.customJobsAvailable[landmass] = num;
			jCategory.isCustomJobsAvailableEnabled[landmass] = true;
		}
	}

	private void ResetHoldSettings()
	{
		holdDuration.ForceExpire();
		holdAcceleration = 1f;
	}

	private void ForceItemUpdates()
	{
		if (isDragging && dragItem != null)
		{
			dragItem.layoutRectT.SetSiblingIndex(originalIdx);
			dragItem = null;
			isDragging = false;
		}
		if ((bool)hoverItem && !hoverItem.gameObject.activeSelf)
		{
			hoverItem.incrementObj.SetActive(value: false);
			hoverItem.decrementObj.SetActive(value: false);
			hoverItem = null;
		}
		for (int i = 0; i < JobSystem.priorityJobCategories.data[landmass].Count; i++)
		{
			JobSystem.JobCategory jobCategory = JobSystem.priorityJobCategories.data[landmass].data[i];
			if (priorityItems.TryGetValue(jobCategory.id, out var value) && !jobCategory.isManualJob)
			{
				value.layoutRectT.SetSiblingIndex(jobCategory.priorityIdx[landmass]);
				bool active = landmass != -1 && (jobCategory.jobsAvailable[landmass] > 0 || jobCategory.id == 1 || jobCategory.id == 21);
				value.gameObject.SetActive(active);
				value.layoutRectT.gameObject.SetActive(active);
				value.rectT.anchoredPosition = value.layoutRectT.anchoredPosition;
				value.titleTMP.color = (value.closeToggle.isOn ? Color.white : Color.gray);
			}
		}
	}

	public void UpdateConsoleUI(bool isControllerActive)
	{
	}

	public void UpdateCategoryWithChange(int landmass, int jobCategoryID, bool positive)
	{
		if (landmass != -1 && priorityItems.TryGetValue(jobCategoryID, out var value))
		{
			value.hideChangeTimer.Enabled = true;
			value.hideChangeTimer.Reset();
			value.upArrow.SetActive(positive);
			value.downArrow.SetActive(!positive);
		}
	}

	private int GetSiblingIndex(int idx)
	{
		int result = idx;
		int num = 0;
		for (int i = 0; i < layoutContainerRectT.childCount; i++)
		{
			if (layoutContainerRectT.GetChild(i).gameObject.activeSelf)
			{
				num++;
				result = i;
			}
			if (num == idx + 1)
			{
				break;
			}
		}
		return result;
	}

	private int GetSiblingIndex(RectTransform target)
	{
		int num = 0;
		for (int i = 0; i < layoutContainerRectT.childCount; i++)
		{
			Transform child = layoutContainerRectT.GetChild(i);
			if (child.gameObject.activeSelf)
			{
				num++;
			}
			if (child == target)
			{
				break;
			}
		}
		return num;
	}

	private int GetActiveChildren(Transform parent)
	{
		int num = 0;
		for (int i = 0; i < parent.childCount; i++)
		{
			if (parent.GetChild(i).gameObject.activeSelf)
			{
				num++;
			}
		}
		return num;
	}
}
