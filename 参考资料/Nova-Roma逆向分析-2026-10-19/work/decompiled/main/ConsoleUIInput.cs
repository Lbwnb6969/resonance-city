using I2.Loc;
using TMPro;
using UnityEngine;

public class ConsoleUIInput : ConsoleUISelectable
{
	public delegate int GetBound();

	public TMP_InputField input;

	public float verticalOffset = 10f;

	public float scaleFactor = 1f;

	public RectTransform targetRect;

	public RectTransform root;

	public GameObject upArrow;

	public GameObject downArrow;

	private ConsoleUIItem item;

	public GetBound GetMax = DefaultMax;

	public GetBound GetMin = DefaultMin;

	public int MaxChangeAmount = 15;

	public int ChangeAmountStep = 5;

	private int changeAmount;

	private float timeBetweenLastUpdate;

	private int initialValue;

	private void OnEnable()
	{
	}

	public override void Reset()
	{
		DeactivateInput();
		input.DeactivateInputField();
		input.OnDeselect(null);
		upArrow.SetActive(value: false);
		downArrow.SetActive(value: false);
		if (targetRect != null)
		{
			targetRect.gameObject.SetActive(value: false);
		}
	}

	public static int DefaultMax()
	{
		return int.MaxValue;
	}

	public static int DefaultMin()
	{
		return 0;
	}

	public override void Submit()
	{
		item = GetComponent<ConsoleUIItem>();
		item.DeactivateInput();
		ActivateInput();
		input.ActivateInputField();
		input.OnSelect(null);
		changeAmount = ChangeAmountStep;
		timeBetweenLastUpdate = 0f;
		if (int.TryParse(input.text, out var result))
		{
			upArrow.SetActive(result < GetMax());
			downArrow.SetActive(result > GetMin());
		}
		else
		{
			upArrow.SetActive(value: false);
			downArrow.SetActive(value: false);
		}
		if (targetRect != null && root != null)
		{
			targetRect.gameObject.SetActive(value: true);
			targetRect.position = root.position;
		}
		initialValue = result;
	}

	public void CancelChange()
	{
		item.Focus();
		DeactivateInput();
		input.DeactivateInputField();
		input.OnDeselect(null);
		upArrow.SetActive(value: false);
		downArrow.SetActive(value: false);
		if (targetRect != null)
		{
			targetRect.gameObject.SetActive(value: false);
		}
		input.text = initialValue.ToString();
		input.onSubmit.Invoke(initialValue.ToString());
	}

	public void Increment()
	{
		float diff = Time.unscaledTime - timeBetweenLastUpdate;
		timeBetweenLastUpdate = Time.unscaledTime;
		CalculateChangeAmount(diff);
		if (int.TryParse(input.text, out var result))
		{
			int num = GetMax();
			if (result + changeAmount < num)
			{
				string text = (result + changeAmount).ToString();
				input.text = text;
				input.onSubmit.Invoke(text);
				upArrow.SetActive(result + 1 < num);
			}
			else
			{
				string text2 = num.ToString();
				input.text = text2;
				input.onSubmit.Invoke(text2);
				upArrow.SetActive(value: false);
			}
			downArrow.SetActive(value: true);
		}
	}

	public void Decrement()
	{
		float diff = Time.unscaledTime - timeBetweenLastUpdate;
		timeBetweenLastUpdate = Time.unscaledTime;
		CalculateChangeAmount(diff);
		if (int.TryParse(input.text, out var result))
		{
			int num = GetMin();
			if (result - changeAmount > num)
			{
				string text = (result - changeAmount).ToString();
				input.text = text;
				input.onSubmit.Invoke(text);
				downArrow.SetActive(result - 1 > num);
			}
			else
			{
				string text2 = num.ToString();
				input.text = text2;
				input.onSubmit.Invoke(text2);
				downArrow.SetActive(value: false);
			}
		}
	}

	public void ConfirmChange()
	{
		item.Focus();
		DeactivateInput();
		input.DeactivateInputField();
		input.OnDeselect(null);
		upArrow.SetActive(value: false);
		downArrow.SetActive(value: false);
		if (targetRect != null)
		{
			targetRect.gameObject.SetActive(value: false);
		}
	}

	private void CalculateChangeAmount(float diff)
	{
		int b = MaxChangeAmount / ChangeAmountStep;
		int a = Mathff.Max(1, Mathf.RoundToInt(0.1f / diff));
		changeAmount = ChangeAmountStep * Mathff.Min(a, b);
	}

	public override void CustomActivate()
	{
		GamepadControl.inst.UIVerticalInput += Increment;
		GamepadControl.inst.UIVerticalNegativeInput += Decrement;
		GamepadControl.inst.UISubmitInput += ConfirmChange;
		GamepadControl.inst.UICancelInput += CancelChange;
	}

	public override void CustomDeactivate()
	{
		GamepadControl.inst.UIVerticalInput -= Increment;
		GamepadControl.inst.UIVerticalNegativeInput -= Decrement;
		GamepadControl.inst.UISubmitInput -= ConfirmChange;
		GamepadControl.inst.UICancelInput -= CancelChange;
	}

	public override string GetTooltip()
	{
		return LocalizationManager.GetTranslation("ConsoleSubmit") + "\n" + LocalizationManager.GetTranslation("ConsoleCancel") + "\n" + LocalizationManager.GetTranslation("ConsoleIncrementAndDecrement");
	}
}
