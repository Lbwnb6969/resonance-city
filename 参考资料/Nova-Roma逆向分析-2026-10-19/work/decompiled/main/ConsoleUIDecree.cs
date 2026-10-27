using System;
using I2.Loc;
using UnityEngine;

public class ConsoleUIDecree : ConsoleUISelectable
{
	[NonSerialized]
	public RectTransform container;

	private Transform startParentContent;

	[NonSerialized]
	public DragableDecreeItem dragItem;

	[NonSerialized]
	public BuildPriorityItem priorityItem;

	[NonSerialized]
	public RectTransform follower;

	[NonSerialized]
	public ConsoleUIItem input;

	[NonSerialized]
	public ConsoleUIItem toggle;

	[NonSerialized]
	public GameObject xSelection;

	[NonSerialized]
	public GameObject ySelection;

	[NonSerialized]
	public GameObject highlightOverlay;

	[NonSerialized]
	public RectTransform shadow;

	[NonSerialized]
	public ConsoleUIItem siblingItem;

	private void OnEnable()
	{
		siblingItem = GetComponent<ConsoleUIItem>();
		if (startParentContent != null)
		{
			follower.transform.SetParent(startParentContent);
			follower.localScale = new Vector3(0.96f, 0.96f, 0.96f);
			startParentContent = null;
		}
	}

	public override void Reset()
	{
		if (dragItem != null)
		{
			dragItem.isConsoleSelected = false;
			dragItem.CustomSnapPosition = dragItem.SnapFollowerPosition;
		}
		if (startParentContent != null)
		{
			follower.transform.SetParent(startParentContent);
			startParentContent = null;
		}
		xSelection.SetActive(value: false);
		ySelection.SetActive(value: false);
		shadow.gameObject.SetActive(value: false);
		DeactivateInput();
	}

	public override void Hover()
	{
		shadow.gameObject.SetActive(value: true);
	}

	public override void Dehover()
	{
	}

	public override void Submit()
	{
		siblingItem.DeactivateInput();
		ActivateInput();
		dragItem.isConsoleSelected = true;
		dragItem.CustomSnapPosition = SnapFollowerPosition;
		Vector3 position = follower.position;
		position.x += 0.15f;
		follower.position = position;
		if (startParentContent == null)
		{
			startParentContent = follower.parent;
		}
		follower.transform.SetParent(transform.parent.parent.parent, worldPositionStays: true);
		xSelection.SetActive(value: true);
		ySelection.SetActive(value: true);
	}

	public override void Focus()
	{
		siblingItem.DeactivateInput();
		ActivateInput();
	}

	public void Prioritze()
	{
		float y = siblingItem.xRoot.sizeDelta.y;
		float b = Mathf.Abs(transform.localPosition.y) - y;
		int num = (int)(Mathf.Max(0f, b) / y);
		int num2 = 0;
		for (int i = 0; i < container.childCount; i++)
		{
			if (num == 0)
			{
				break;
			}
			if (container.GetChild(i).gameObject.activeInHierarchy)
			{
				num--;
			}
			num2++;
		}
		UpdateItemPosition(num2);
	}

	public void Deprioritze()
	{
		float y = siblingItem.xRoot.sizeDelta.y;
		float b = Mathf.Abs(transform.localPosition.y) + y;
		int num = (int)(Mathf.Max(0f, b) / y);
		int num2 = 0;
		for (int i = 0; i < container.childCount; i++)
		{
			if (num == 0)
			{
				break;
			}
			if (!(container.GetChild(i) == transform))
			{
				if (container.GetChild(i).gameObject.activeInHierarchy)
				{
					num--;
				}
				num2++;
			}
		}
		UpdateItemPosition(num2);
	}

	public void SelectInput()
	{
		DeactivateInput();
		input.parent = siblingItem;
		input.Hover();
	}

	public void Update()
	{
		if (hasActivated)
		{
			Vector3 position = follower.position;
			position.y = Mathf.MoveTowards(position.y, transform.position.y, Time.unscaledDeltaTime * 6f);
			follower.position = position;
		}
		if (siblingItem.isHovered)
		{
			shadow.position = follower.position;
			if (GamepadControl.inst.player.GetButtonDown("Y"))
			{
				toggle.Submit();
			}
		}
	}

	public void Exit()
	{
		dragItem.isConsoleSelected = false;
		dragItem.CustomSnapPosition = dragItem.SnapFollowerPosition;
		follower.transform.SetParent(startParentContent);
		startParentContent = null;
		xSelection.SetActive(value: false);
		ySelection.SetActive(value: false);
		DeactivateInput();
		siblingItem.parent.CollectItems();
		siblingItem.parent.AssignNavigation();
		siblingItem.Hover();
	}

	public void UpdateItemPosition(int idx)
	{
		transform.SetSiblingIndex(idx);
	}

	public override void CustomActivate()
	{
		GamepadControl.inst.UIVerticalInput += Prioritze;
		GamepadControl.inst.UIVerticalNegativeInput += Deprioritze;
		GamepadControl.inst.UIXInput += SelectInput;
		GamepadControl.inst.UISubmitInput += Exit;
		GamepadControl.inst.UICancelInput += Exit;
	}

	public override void CustomDeactivate()
	{
		GamepadControl.inst.UIVerticalInput -= Prioritze;
		GamepadControl.inst.UIVerticalNegativeInput -= Deprioritze;
		GamepadControl.inst.UIXInput -= SelectInput;
		GamepadControl.inst.UISubmitInput -= Exit;
		GamepadControl.inst.UICancelInput -= Exit;
	}

	public void SnapFollowerPosition()
	{
		Vector3 position = follower.position;
		position.y = transform.position.y;
		follower.position = position;
	}

	public override string GetTooltip()
	{
		return LocalizationManager.GetTranslation("ConsolePrioritize");
	}
}
