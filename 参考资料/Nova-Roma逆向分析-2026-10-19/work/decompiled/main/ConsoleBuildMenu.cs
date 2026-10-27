using System.Collections.Generic;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class ConsoleBuildMenu : MonoBehaviour
{
	public enum Status
	{
		Collapsing,
		Expanding,
		Showing,
		Hiding,
		None
	}

	public static ConsoleBuildMenu inst;

	public RectTransform xRoot;

	public Transform buttonContainer;

	public List<Button> tabs;

	public Sprite defaultBtnIcon;

	public Sprite highlightBtnIcon;

	public RectTransform background;

	public RectTransform shadow;

	public RectTransform tabButtonHighlight;

	public Localize tabTitle;

	public int previousPositionSelected;

	private bool isActive;

	[SerializeField]
	private Status status = Status.None;

	[SerializeField]
	private float hidePos = -30f;

	[SerializeField]
	private float showPos = 30f;

	private bool updatePositions;

	private List<Vector3> cachedPositions;

	private int tabIdx = 5;

	private Transform selectorTarget;

	private bool inputActivated;

	public bool Active => isActive;

	private void Awake()
	{
		inst = this;
		cachedPositions = new List<Vector3>(buttonContainer.childCount);
	}

	private void OnEnable()
	{
		Reset();
	}

	public void UICancelInput()
	{
	}

	public void UIVerticalInput()
	{
		MoveItemUp();
	}

	public void UIVerticalNegativeInput()
	{
		MoveItemDown();
	}

	public void SetStatus(Status s)
	{
		status = s;
	}

	private void Update()
	{
		if (isActive)
		{
			if (selectorTarget != null)
			{
				shadow.position = selectorTarget.position;
			}
			else if (shadow.gameObject.activeSelf)
			{
				HideSelectorVisuals();
			}
		}
		switch (status)
		{
		case Status.Showing:
		{
			Vector3 vector2 = default;
			vector2.x = xRoot.anchoredPosition.x;
			vector2.y = xRoot.anchoredPosition.y;
			vector2.x = Mathf.Lerp(vector2.x, showPos, Time.unscaledDeltaTime * 10f);
			xRoot.anchoredPosition = vector2;
			if (Mathff.Abs(vector2.x - showPos) < 0.05f)
			{
				status = Status.None;
			}
			break;
		}
		case Status.Hiding:
		{
			Vector3 vector = default;
			vector.x = xRoot.anchoredPosition.x;
			vector.y = xRoot.anchoredPosition.y;
			vector.x = Mathf.Lerp(vector.x, hidePos, Time.unscaledDeltaTime * 20f);
			xRoot.anchoredPosition = vector;
			break;
		}
		}
		if (!updatePositions)
		{
			return;
		}
		bool flag = true;
		for (int i = 0; i < cachedPositions.Count; i++)
		{
			Vector3 localPosition = buttonContainer.GetChild(i).localPosition;
			localPosition.y = Mathf.Lerp(localPosition.y, cachedPositions[i].y, Time.unscaledDeltaTime * 15f);
			if (Mathff.DistSqrd(localPosition, cachedPositions[i]) > 0.001f)
			{
				flag = false;
			}
			buttonContainer.GetChild(i).localPosition = localPosition;
		}
		if (flag)
		{
			updatePositions = false;
		}
	}

	public void MoveItemDown()
	{
		DeselectBuildItem();
		if (tabIdx >= buttonContainer.childCount - 1)
		{
			tabIdx = 0;
		}
		else
		{
			tabIdx++;
		}
		SelectBuildItem();
	}

	public void MoveItemUp()
	{
		DeselectBuildItem();
		if (tabIdx <= 0)
		{
			tabIdx = buttonContainer.childCount - 1;
		}
		else
		{
			tabIdx--;
		}
		SelectBuildItem();
	}

	public void DeselectBuildItem()
	{
		tabs[tabIdx].image.sprite = defaultBtnIcon;
		tabs[tabIdx].transform.localScale = new Vector3(0.9f, 0.9f, 0.9f);
	}

	public void SelectBuildItem()
	{
		if ((bool)selectorTarget && isActive)
		{
			previousPositionSelected = 0;
		}
		Transform child = buttonContainer.GetChild(tabIdx);
		tabs[tabIdx].image.sprite = highlightBtnIcon;
		tabs[tabIdx].transform.localScale = new Vector3(1.25f, 1.25f, 1.25f);
		string term = child.name;
		tabTitle.Term = term;
	}

	public void SelectMenu()
	{
		ActivateInput();
		if (!Active)
		{
			SetStatus(Status.Showing);
			SelectBuildItem();
			ConsoleTileUI.inst.SetVisible(v: false);
			GameUI.inst.islandInfoUI.UpdateConsoleUI(isControllerActive: false);
			isActive = true;
		}
	}

	public void CloseMenu()
	{
		DeactivateInput();
		if (Active)
		{
			SetStatus(Status.Hiding);
			HideSelectorVisuals();
			BuildUI.inst.HideGroups();
			GamepadControl.inst.nextSelected = null;
			if (!GameUI.inst.CurrPlacementMode.IsPlacing())
			{
				ConsoleCursorMenu.inst.SetConsoleMode();
			}
			GameUI.inst.islandInfoUI.UpdateConsoleUI(GamepadControl.inst.isControllerActive);
			isActive = false;
		}
	}

	public void SetSelectorVisuals(Transform transform)
	{
		if (transform == null)
		{
			HideSelectorVisuals();
			selectorTarget = null;
		}
		else
		{
			selectorTarget = transform;
			shadow.position = selectorTarget.position;
			shadow.gameObject.SetActive(value: true);
		}
	}

	public void HideSelectorVisuals()
	{
		shadow.gameObject.SetActive(value: false);
	}

	public void PrepForGamepad()
	{
		BuildUI.inst.HideGroups();
	}

	public void PrepForKeyboard()
	{
		if (Active)
		{
			CloseMenu();
		}
		HideSelectorVisuals();
	}

	public void Reset()
	{
		previousPositionSelected = 0;
	}

	public void OnBuildOptionSelected(int siblingIdx)
	{
		previousPositionSelected = siblingIdx;
	}

	public void ActivateInput()
	{
		if (!inputActivated)
		{
			GamepadControl.inst.UICancelInput += UICancelInput;
			GamepadControl.inst.UIVerticalInput += UIVerticalInput;
			GamepadControl.inst.UIVerticalNegativeInput += UIVerticalNegativeInput;
			inputActivated = true;
		}
	}

	public void DeactivateInput()
	{
		if (inputActivated)
		{
			GamepadControl.inst.UICancelInput -= UICancelInput;
			GamepadControl.inst.UIVerticalInput -= UIVerticalInput;
			GamepadControl.inst.UIVerticalNegativeInput -= UIVerticalNegativeInput;
			inputActivated = false;
		}
	}
}
