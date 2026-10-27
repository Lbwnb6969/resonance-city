using System;
using UnityEngine;

public class ConsoleUIItem : ConsoleUI
{
	public enum NavigationBehavior
	{
		Explicit,
		Automatic,
		None
	}

	public enum NavigationDirection
	{
		Vertical,
		Horizontal,
		Both
	}

	public enum HighlightType
	{
		Section,
		Item,
		None
	}

	public RectTransform xRoot;

	public bool isHovered;

	public bool AutoNavigate;

	public bool AutoSelect;

	public bool AutoDeselect;

	public bool IgnoreCollection;

	public bool IgnoreAutoNavigation;

	public bool ResetOnControllerChange = true;

	public NavigationBehavior behavior;

	public NavigationDirection direction;

	public int columnSize = 1;

	public bool WrapNavigation;

	public HighlightType highlightType = HighlightType.Item;

	public GameObject hightlightGameObject;

	public ConsoleUIItem parent;

	public Transform target;

	public ConsoleUIItem top;

	public ConsoleUIItem right;

	public ConsoleUIItem bottom;

	public ConsoleUIItem left;

	public bool KeepTrackOfSelected;

	public bool ResetTrackedSelectedOnAutoNavigation = true;

	public bool ResetTrackedSelectedOnDisabled;

	public bool ResetTrackedSelectedOnGamepadUpdate;

	public ConsoleUIItem lastChildSelected;

	public ArrayExt<ConsoleUIItem> items = new ArrayExt<ConsoleUIItem>(16);

	public bool HoverOnEnable;

	public bool DehoverOnSubmit;

	public bool hasTooltip;

	public bool trimAutoNavItems;

	public bool DisableCancelInput;

	public ConsoleUIItem selectOnDisable;

	public ConsoleUIItem customSelectItem;

	public bool DisableAutoNavigationTreeSearch;

	private static ArrayExt<ConsoleUIItem> backTrackItems = new ArrayExt<ConsoleUIItem>(8);

	public bool isFocusable = true;

	private void Awake()
	{
		xRoot = GetComponent<RectTransform>();
		if (parent == null)
		{
			Transform transform = base.transform.parent;
			while (transform != null)
			{
				if ((bool)transform.GetComponent<ConsoleUIItem>())
				{
					parent = transform.GetComponent<ConsoleUIItem>();
					break;
				}
				transform = transform.parent;
			}
		}
		CollectItems();
		AssignNavigation();
	}

	private void Start()
	{
		if (ResetOnControllerChange)
		{
			GamepadControl inst = GamepadControl.inst;
			inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(inst.controllerUpdate, new GamepadControl.ControllerActivity(UpdateConsoleUI));
		}
	}

	private void OnDestroy()
	{
		if (ResetOnControllerChange)
		{
			GamepadControl inst = GamepadControl.inst;
			inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(inst.controllerUpdate, new GamepadControl.ControllerActivity(UpdateConsoleUI));
		}
		OnDisable();
		DeactivateInput();
	}

	private void OnEnable()
	{
		if (parent != null)
		{
			if (parent.parent != null && parent.parent.trimAutoNavItems)
			{
				parent.parent.CollectItems();
				parent.parent.AssignNavigation();
			}
			parent.CollectItems();
			parent.AssignNavigation();
		}
		CollectItems();
		AssignNavigation();
		if (HoverOnEnable && GamepadControl.inst.isControllerActive && gameObject.activeInHierarchy)
		{
			Hover();
		}
	}

	private void OnDisable()
	{
		if (ResetTrackedSelectedOnDisabled)
		{
			lastChildSelected = null;
		}
		if (parent != null)
		{
			if (parent.parent != null && parent.parent.gameObject.activeInHierarchy && parent.parent.trimAutoNavItems)
			{
				parent.parent.CollectItems();
				parent.parent.AssignNavigation();
			}
			if (parent.gameObject.activeInHierarchy)
			{
				parent.CollectItems();
				parent.AssignNavigation();
			}
		}
		if (!isHovered)
		{
			return;
		}
		Reset();
		if ((bool)selectOnDisable)
		{
			selectOnDisable.Hover();
			return;
		}
		ConsoleUIItem consoleUIItem = parent;
		while (consoleUIItem != null && (!consoleUIItem.IsItemAutoSelectable() || !consoleUIItem.gameObject.activeInHierarchy))
		{
			consoleUIItem = consoleUIItem.parent;
		}
		if (consoleUIItem != null && consoleUIItem.gameObject.activeInHierarchy)
		{
			consoleUIItem.Hover();
		}
	}

	public void UpdateConsoleUI(bool isControllerActive)
	{
		Reset();
		if (ResetTrackedSelectedOnGamepadUpdate)
		{
			lastChildSelected = null;
		}
	}

	public override void Reset()
	{
		DeactivateInput();
		ResetChildren();
		if (isHovered)
		{
			ConsoleUISelectable[] components = GetComponents<ConsoleUISelectable>();
			for (int i = 0; i < components.Length; i++)
			{
				components[i].Reset();
			}
			if (hightlightGameObject != null && hightlightGameObject.activeSelf)
			{
				hightlightGameObject.SetActive(value: false);
			}
			if (GamepadControl.inst.nextSelected == ((target == null) ? gameObject : target.gameObject))
			{
				GamepadControl.inst.nextSelected = null;
			}
		}
		isHovered = false;
	}

	public void ResetChildren()
	{
		for (int i = 0; i < items.Count; i++)
		{
			items.data[i].Reset();
		}
	}

	public void NavigateUp()
	{
		ConsoleUIItem consoleUIItem = null;
		if (parent != null && top == null)
		{
			ConsoleUIItem consoleUIItem2 = parent;
			ConsoleUIItem consoleUIItem3 = null;
			while (consoleUIItem2 != null && !consoleUIItem2.DisableAutoNavigationTreeSearch && consoleUIItem == null)
			{
				if (consoleUIItem2.isHovered)
				{
					backTrackItems.Add(consoleUIItem2);
				}
				if (consoleUIItem2.top != null)
				{
					if (!consoleUIItem2.top.IsItemAutoSelectable())
					{
						consoleUIItem2 = consoleUIItem2.top;
						continue;
					}
					consoleUIItem = consoleUIItem2.top;
					consoleUIItem3 = consoleUIItem;
				}
				if (consoleUIItem3 != null && consoleUIItem2.parent != null && consoleUIItem2.parent.KeepTrackOfSelected && consoleUIItem2.parent.IsItemAutoSelectable())
				{
					consoleUIItem2.parent.lastChildSelected = consoleUIItem3;
				}
				consoleUIItem2 = consoleUIItem2.parent;
			}
		}
		NavigateTo(top, consoleUIItem);
	}

	public void NavigateDown()
	{
		ConsoleUIItem consoleUIItem = null;
		if (parent != null && bottom == null)
		{
			ConsoleUIItem consoleUIItem2 = parent;
			ConsoleUIItem consoleUIItem3 = consoleUIItem2;
			while (consoleUIItem2 != null && !consoleUIItem2.DisableAutoNavigationTreeSearch && consoleUIItem == null)
			{
				if (consoleUIItem2.isHovered)
				{
					backTrackItems.Add(consoleUIItem2);
				}
				if (consoleUIItem2.bottom != null)
				{
					if (!consoleUIItem2.bottom.IsItemAutoSelectable())
					{
						consoleUIItem2 = consoleUIItem2.bottom;
						continue;
					}
					consoleUIItem = consoleUIItem2.bottom;
					consoleUIItem3 = consoleUIItem;
				}
				if (consoleUIItem3 != null && consoleUIItem2.parent != null && consoleUIItem2.parent.KeepTrackOfSelected && consoleUIItem2.parent.IsItemAutoSelectable())
				{
					consoleUIItem2.parent.lastChildSelected = consoleUIItem3;
				}
				consoleUIItem2 = consoleUIItem2.parent;
			}
		}
		NavigateTo(bottom, consoleUIItem);
	}

	public void NavigateRight()
	{
		ConsoleUIItem consoleUIItem = null;
		if (parent != null && right == null)
		{
			ConsoleUIItem consoleUIItem2 = parent;
			ConsoleUIItem consoleUIItem3 = null;
			while (consoleUIItem2 != null && !consoleUIItem2.DisableAutoNavigationTreeSearch && consoleUIItem == null)
			{
				if (consoleUIItem2.isHovered)
				{
					backTrackItems.Add(consoleUIItem2);
				}
				if (consoleUIItem2.right != null)
				{
					if (!consoleUIItem2.right.IsItemAutoSelectable())
					{
						consoleUIItem2 = consoleUIItem2.right;
						continue;
					}
					consoleUIItem = consoleUIItem2.right;
					consoleUIItem3 = consoleUIItem;
				}
				if (consoleUIItem3 != null && consoleUIItem2.parent != null && consoleUIItem2.parent.KeepTrackOfSelected && consoleUIItem2.parent.IsItemAutoSelectable())
				{
					consoleUIItem2.parent.lastChildSelected = consoleUIItem3;
				}
				consoleUIItem2 = consoleUIItem2.parent;
			}
		}
		NavigateTo(right, consoleUIItem);
	}

	public void NavigateLeft()
	{
		ConsoleUIItem consoleUIItem = null;
		if (parent != null && left == null)
		{
			ConsoleUIItem consoleUIItem2 = parent;
			ConsoleUIItem consoleUIItem3 = null;
			while (consoleUIItem2 != null && !consoleUIItem2.DisableAutoNavigationTreeSearch && consoleUIItem == null)
			{
				if (consoleUIItem2.isHovered)
				{
					backTrackItems.Add(consoleUIItem2);
				}
				if (consoleUIItem2.left != null)
				{
					if (!consoleUIItem2.left.IsItemAutoSelectable())
					{
						consoleUIItem2 = consoleUIItem2.left;
						continue;
					}
					consoleUIItem = consoleUIItem2.left;
					consoleUIItem3 = consoleUIItem;
				}
				if (consoleUIItem3 != null && consoleUIItem2.parent != null && consoleUIItem2.parent.KeepTrackOfSelected && consoleUIItem2.parent.IsItemAutoSelectable())
				{
					consoleUIItem2.parent.lastChildSelected = consoleUIItem3;
				}
				consoleUIItem2 = consoleUIItem2.parent;
			}
		}
		NavigateTo(left, consoleUIItem);
	}

	public void NavigateTo(ConsoleUIItem item, ConsoleUIItem parentItem)
	{
		if (item != null && item.gameObject.activeInHierarchy)
		{
			if (item.IsItemAutoSelectable())
			{
				Dehover();
				if (parent != null && parent.KeepTrackOfSelected)
				{
					parent.lastChildSelected = item;
				}
				item.Hover();
			}
		}
		else if (AutoNavigate && parentItem != null)
		{
			Dehover();
			if (parent.KeepTrackOfSelected && parent.ResetTrackedSelectedOnAutoNavigation)
			{
				parent.lastChildSelected = null;
			}
			for (int i = 0; i < backTrackItems.Count; i++)
			{
				backTrackItems.data[i].Dehover();
			}
			parentItem.Hover();
		}
		backTrackItems.ClearFast();
	}

	public bool IsItemAutoSelectable()
	{
		if (!AutoSelect || behavior == NavigationBehavior.None)
		{
			return true;
		}
		CollectItems();
		if (items.Count > 0)
		{
			return true;
		}
		return false;
	}

	public override void Hover()
	{
		if (xRoot == null)
		{
			xRoot = GetComponent<RectTransform>();
		}
		GamepadControl.inst.nextSelected = ((target == null) ? gameObject : target.gameObject);
		isHovered = true;
		ActivateInput();
		ConsoleUISelectable[] components = GetComponents<ConsoleUISelectable>();
		for (int i = 0; i < components.Length; i++)
		{
			components[i].Hover();
		}
		if (hightlightGameObject != null)
		{
			hightlightGameObject.SetActive(value: true);
		}
		if (AutoSelect)
		{
			Submit();
		}
	}

	public override void Dehover()
	{
		ConsoleUISelectable[] components = GetComponents<ConsoleUISelectable>();
		for (int i = 0; i < components.Length; i++)
		{
			components[i].Dehover();
		}
		if (hightlightGameObject != null)
		{
			hightlightGameObject.SetActive(value: false);
		}
		isHovered = false;
		DeactivateInput();
	}

	public override void Submit()
	{
		ConsoleUISelectable[] components = GetComponents<ConsoleUISelectable>();
		for (int i = 0; i < components.Length; i++)
		{
			components[i].Submit();
		}
		CollectItems();
		if (customSelectItem != null)
		{
			DeactivateInput();
			customSelectItem.parent = this;
			customSelectItem.Hover();
		}
		else if (behavior != NavigationBehavior.None)
		{
			if (lastChildSelected != null && lastChildSelected.gameObject.activeInHierarchy)
			{
				lastChildSelected.Hover();
				DeactivateInput();
			}
			else
			{
				for (int j = 0; j < items.Count; j++)
				{
					if (items.data[j].IsItemAutoSelectable())
					{
						items.data[j].Hover();
						DeactivateInput();
						break;
					}
				}
			}
		}
		if (DehoverOnSubmit)
		{
			Dehover();
		}
	}

	public override void Cancel()
	{
		if (!DisableCancelInput)
		{
			ConsoleUISelectable[] components = GetComponents<ConsoleUISelectable>();
			for (int i = 0; i < components.Length; i++)
			{
				components[i].Cancel();
			}
			Dehover();
			if (parent != null)
			{
				parent.Focus();
			}
		}
	}

	public override void Focus()
	{
		ConsoleUISelectable[] components = GetComponents<ConsoleUISelectable>();
		for (int i = 0; i < components.Length; i++)
		{
			components[i].Focus();
		}
		if (isFocusable)
		{
			if (AutoDeselect && parent != null)
			{
				Dehover();
				parent.Focus();
			}
			else
			{
				Hover();
			}
		}
	}

	public override void CustomActivate()
	{
		GamepadControl.inst.UIVerticalInput += NavigateUp;
		GamepadControl.inst.UIVerticalNegativeInput += NavigateDown;
		GamepadControl.inst.UIHorizontalInput += NavigateRight;
		GamepadControl.inst.UIHorizontalNegativeInput += NavigateLeft;
		GamepadControl.inst.UISubmitInput += Submit;
		GamepadControl.inst.UICancelInput += Cancel;
	}

	public override void CustomDeactivate()
	{
		GamepadControl.inst.UIVerticalInput -= NavigateUp;
		GamepadControl.inst.UIVerticalNegativeInput -= NavigateDown;
		GamepadControl.inst.UIHorizontalInput -= NavigateRight;
		GamepadControl.inst.UIHorizontalNegativeInput -= NavigateLeft;
		GamepadControl.inst.UISubmitInput -= Submit;
		GamepadControl.inst.UICancelInput -= Cancel;
	}

	public void CollectItems()
	{
		items.Clear();
		Transform current = ((target == null) ? transform : target);
		items = SearchForItems(items, current);
	}

	public void AssignNavigation()
	{
		if (behavior == NavigationBehavior.Automatic)
		{
			ConsoleUIItem consoleUIItem = null;
			for (int i = 0; i < items.Count; i++)
			{
				ConsoleUIItem consoleUIItem2 = items.data[i];
				if (!consoleUIItem2.IgnoreAutoNavigation)
				{
					if (direction == NavigationDirection.Vertical)
					{
						consoleUIItem2.bottom = null;
						consoleUIItem2.top = consoleUIItem;
						if (consoleUIItem != null)
						{
							consoleUIItem.bottom = consoleUIItem2;
						}
					}
					else if (direction == NavigationDirection.Horizontal)
					{
						consoleUIItem2.right = null;
						consoleUIItem2.left = consoleUIItem;
						if (consoleUIItem != null)
						{
							consoleUIItem.right = consoleUIItem2;
						}
					}
					else if (direction == NavigationDirection.Both)
					{
						consoleUIItem2.top = null;
						consoleUIItem2.bottom = null;
						consoleUIItem2.right = null;
						consoleUIItem2.left = consoleUIItem;
						if (consoleUIItem != null)
						{
							consoleUIItem.right = consoleUIItem2;
						}
						if (items.Count >= i - columnSize && i - columnSize >= 0)
						{
							items.data[i - columnSize].bottom = consoleUIItem2;
							consoleUIItem2.top = items.data[i - columnSize];
							if (i == items.Count - 1 && items.Count % columnSize != 0)
							{
								int num = i - columnSize;
								int num2 = columnSize - 1 - num % columnSize;
								for (int j = 1; j <= num2; j++)
								{
									items.data[num + j].bottom = consoleUIItem2;
								}
							}
						}
					}
				}
				consoleUIItem = consoleUIItem2;
			}
		}
		if (WrapNavigation && items.Count >= 2)
		{
			if (direction == NavigationDirection.Vertical)
			{
				items.data[0].top = items.data[items.Count - 1];
				items.data[items.Count - 1].bottom = items.data[0];
			}
			if (direction == NavigationDirection.Horizontal || direction == NavigationDirection.Both)
			{
				items.data[0].left = items.data[items.Count - 1];
				items.data[items.Count - 1].right = items.data[0];
			}
		}
	}

	public ArrayExt<ConsoleUIItem> SearchForItems(ArrayExt<ConsoleUIItem> items, Transform current)
	{
		Transform transform = null;
		ConsoleUIItem consoleUIItem = null;
		for (int i = 0; i < current.childCount; i++)
		{
			transform = current.GetChild(i);
			consoleUIItem = transform.GetComponent<ConsoleUIItem>();
			if (consoleUIItem != null)
			{
				if (!transform.gameObject.activeInHierarchy || consoleUIItem.IgnoreCollection)
				{
					continue;
				}
				if (trimAutoNavItems && consoleUIItem.AutoSelect)
				{
					if (consoleUIItem.IsItemAutoSelectable())
					{
						items.Add(consoleUIItem);
					}
				}
				else
				{
					items.Add(consoleUIItem);
				}
			}
			else
			{
				items = SearchForItems(items, transform);
			}
		}
		return items;
	}
}
