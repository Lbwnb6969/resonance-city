using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.Events;
using UnityEngine.UI;

namespace Rewired.UI.ControlMapper;

[AddComponentMenu("")]
public class CustomToggle : Toggle, ICustomSelectable, ICancelHandler, IEventSystemHandler
{
	[SerializeField]
	private Sprite _disabledHighlightedSprite;

	[SerializeField]
	private Color _disabledHighlightedColor;

	[SerializeField]
	private string _disabledHighlightedTrigger;

	[SerializeField]
	private bool _autoNavUp = true;

	[SerializeField]
	private bool _autoNavDown = true;

	[SerializeField]
	private bool _autoNavLeft = true;

	[SerializeField]
	private bool _autoNavRight = true;

	private bool isHighlightDisabled;

	public Sprite disabledHighlightedSprite
	{
		get
		{
			return _disabledHighlightedSprite;
		}
		set
		{
			_disabledHighlightedSprite = value;
		}
	}

	public Color disabledHighlightedColor
	{
		get
		{
			return _disabledHighlightedColor;
		}
		set
		{
			_disabledHighlightedColor = value;
		}
	}

	public string disabledHighlightedTrigger
	{
		get
		{
			return _disabledHighlightedTrigger;
		}
		set
		{
			_disabledHighlightedTrigger = value;
		}
	}

	public bool autoNavUp
	{
		get
		{
			return _autoNavUp;
		}
		set
		{
			_autoNavUp = value;
		}
	}

	public bool autoNavDown
	{
		get
		{
			return _autoNavDown;
		}
		set
		{
			_autoNavDown = value;
		}
	}

	public bool autoNavLeft
	{
		get
		{
			return _autoNavLeft;
		}
		set
		{
			_autoNavLeft = value;
		}
	}

	public bool autoNavRight
	{
		get
		{
			return _autoNavRight;
		}
		set
		{
			_autoNavRight = value;
		}
	}

	private bool isDisabled => !IsInteractable();

	private event UnityAction _CancelEvent;

	public event UnityAction CancelEvent
	{
		add
		{
			_CancelEvent += value;
		}
		remove
		{
			_CancelEvent -= value;
		}
	}

	public override Selectable FindSelectableOnLeft()
	{
		if ((navigation.mode & Navigation.Mode.Horizontal) != 0 || _autoNavLeft)
		{
			return UISelectionUtility.FindNextSelectable(this, transform, Vector3.left);
		}
		return base.FindSelectableOnLeft();
	}

	public override Selectable FindSelectableOnRight()
	{
		if ((navigation.mode & Navigation.Mode.Horizontal) != 0 || _autoNavRight)
		{
			return UISelectionUtility.FindNextSelectable(this, transform, Vector3.right);
		}
		return base.FindSelectableOnRight();
	}

	public override Selectable FindSelectableOnUp()
	{
		if ((navigation.mode & Navigation.Mode.Vertical) != 0 || _autoNavUp)
		{
			return UISelectionUtility.FindNextSelectable(this, transform, Vector3.up);
		}
		return base.FindSelectableOnUp();
	}

	public override Selectable FindSelectableOnDown()
	{
		if ((navigation.mode & Navigation.Mode.Vertical) != 0 || _autoNavDown)
		{
			return UISelectionUtility.FindNextSelectable(this, transform, Vector3.down);
		}
		return base.FindSelectableOnDown();
	}

	protected override void OnCanvasGroupChanged()
	{
		base.OnCanvasGroupChanged();
		if (!(EventSystem.current == null))
		{
			EvaluateHightlightDisabled(EventSystem.current.currentSelectedGameObject == gameObject);
		}
	}

	protected override void DoStateTransition(SelectionState state, bool instant)
	{
		if (isHighlightDisabled)
		{
			Color color = _disabledHighlightedColor;
			Sprite newSprite = _disabledHighlightedSprite;
			string triggername = _disabledHighlightedTrigger;
			if (gameObject.activeInHierarchy)
			{
				switch (transition)
				{
				case Transition.ColorTint:
					StartColorTween(color * colors.colorMultiplier, instant);
					break;
				case Transition.SpriteSwap:
					DoSpriteSwap(newSprite);
					break;
				case Transition.Animation:
					TriggerAnimation(triggername);
					break;
				}
			}
		}
		else
		{
			base.DoStateTransition(state, instant);
		}
	}

	private void StartColorTween(Color targetColor, bool instant)
	{
		if (!(targetGraphic == null))
		{
			targetGraphic.CrossFadeColor(targetColor, instant ? 0f : colors.fadeDuration, ignoreTimeScale: true, useAlpha: true);
		}
	}

	private void DoSpriteSwap(Sprite newSprite)
	{
		if (!(image == null))
		{
			image.overrideSprite = newSprite;
		}
	}

	private void TriggerAnimation(string triggername)
	{
		if (!(animator == null) && animator.enabled && animator.isActiveAndEnabled && !(animator.runtimeAnimatorController == null) && !string.IsNullOrEmpty(triggername))
		{
			animator.ResetTrigger(_disabledHighlightedTrigger);
			animator.SetTrigger(triggername);
		}
	}

	public override void OnSelect(BaseEventData eventData)
	{
		base.OnSelect(eventData);
		EvaluateHightlightDisabled(isSelected: true);
	}

	public override void OnDeselect(BaseEventData eventData)
	{
		base.OnDeselect(eventData);
		EvaluateHightlightDisabled(isSelected: false);
	}

	private void EvaluateHightlightDisabled(bool isSelected)
	{
		if (!isSelected)
		{
			if (isHighlightDisabled)
			{
				isHighlightDisabled = false;
				SelectionState state = (isDisabled ? SelectionState.Disabled : currentSelectionState);
				DoStateTransition(state, instant: false);
			}
		}
		else if (isDisabled)
		{
			isHighlightDisabled = true;
			DoStateTransition(SelectionState.Disabled, instant: false);
		}
	}

	public void OnCancel(BaseEventData eventData)
	{
		if (_CancelEvent != null)
		{
			_CancelEvent();
		}
	}
}
