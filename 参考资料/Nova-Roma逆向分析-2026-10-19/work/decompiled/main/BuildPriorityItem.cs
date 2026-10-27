using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildPriorityItem : MonoBehaviour
{
	public TextMeshProUGUI Priority;

	public TextMeshProUGUI Name;

	public TextMeshProUGUI FilledWorkers;

	public TMP_InputField AvailableWorkersInput;

	public TextMeshProUGUI AvailableWorkersText;

	public TextMeshProUGUI MaxAvailableWorkers;

	public TextMeshProUGUI ClosedWorkers;

	public Image UpArrow;

	public Image DownArrow;

	public Toggle DisableToggle;

	public GameObject Increment;

	private bool _IncrementPressed;

	public GameObject Decrement;

	private bool _DecrementPressed;

	public Image[] elementsForColor;

	public readonly Timer ArrowViewTimer = new Timer(3f);

	public bool isHovering;

	private bool MaxAvailableHoverInfoVisible;

	public int MaxAvailableJobs;

	private Color myColor;

	private Timer holdDuration = new Timer(1f);

	private float holdAcceleration = 1f;

	public float holdAccelerationStep = 0.1f;

	public float holdAccelerationMax = 25f;

	public bool isIncrementPressed
	{
		get
		{
			return _IncrementPressed;
		}
		set
		{
			if (_IncrementPressed && !value)
			{
				ResetHoldSettings();
			}
			_IncrementPressed = value;
		}
	}

	public bool isDecrementPressed
	{
		get
		{
			return _DecrementPressed;
		}
		set
		{
			if (_DecrementPressed && !value)
			{
				ResetHoldSettings();
			}
			_DecrementPressed = value;
		}
	}

	private void Start()
	{
	}

	public int GetMax()
	{
		return 0;
	}

	public void UpdateJobFilled(int value)
	{
	}

	public void AddToAvailable(int amount)
	{
	}

	public void SetMaxAvailableWorkerTextVisible(bool v)
	{
		MaxAvailableWorkers.gameObject.SetActive(v);
		if (!v && MaxAvailableHoverInfoVisible)
		{
			MaxAvailableHoverInfoVisible = false;
		}
	}

	public void UpdateAvailableDisplay()
	{
	}

	public void UpdateAvailableArrows()
	{
		if (!isHovering)
		{
			Increment.SetActive(value: false);
			Decrement.SetActive(value: false);
			return;
		}
		bool active = true;
		bool active2 = true;
		Increment.SetActive(active);
		isIncrementPressed = Increment.activeSelf && isIncrementPressed;
		Decrement.SetActive(active2);
		isDecrementPressed = Decrement.activeSelf && isDecrementPressed;
	}

	public void SetToggleState(bool on)
	{
		DisableToggle.onValueChanged.RemoveListener(DisableToggleClicked);
		DisableToggle.isOn = on;
		UpdateEnabledStateVisuals();
		DisableToggle.onValueChanged.AddListener(DisableToggleClicked);
	}

	private void DisableToggleClicked(bool check)
	{
		UpdateEnabledStateVisuals();
		SfxSystem.PlayUiSelect();
	}

	public void UpdateEnabledStateVisuals()
	{
		if (DisableToggle.isOn)
		{
			ChangeColor(myColor);
			ChangeTextColor(Color.white);
		}
		else
		{
			ChangeColor(new Color(0.2f, 0.2f, 0.2f));
			ChangeTextColor(new Color(0.7f, 0.7f, 0.7f));
		}
	}

	public void ClearArrow()
	{
		ArrowViewTimer.Enabled = false;
		UpArrow.enabled = false;
		DownArrow.enabled = false;
	}

	public void UpdateArrow(bool up)
	{
		ArrowViewTimer.Enabled = true;
		ArrowViewTimer.Reset();
		if (up)
		{
			UpArrow.enabled = true;
			DownArrow.enabled = false;
		}
		else
		{
			UpArrow.enabled = false;
			DownArrow.enabled = true;
		}
	}

	public void SetColor(Color color)
	{
		myColor = color;
		ChangeColor(myColor);
	}

	public void ChangeColor(Color color)
	{
		for (int i = 0; i < elementsForColor.Length; i++)
		{
			if (i == 0)
			{
				Color color2 = color;
				color2.r *= 0.8f;
				color2.g *= 0.8f;
				color2.b *= 0.8f;
				elementsForColor[i].color = color2;
			}
			else
			{
				elementsForColor[i].color = color;
			}
		}
	}

	public void ChangeTextColor(Color color)
	{
		Priority.color = color;
		Name.color = color;
		FilledWorkers.color = color;
		AvailableWorkersInput.textComponent.color = color;
		ClosedWorkers.color = color;
	}

	private void ResetHoldSettings()
	{
		holdDuration.ForceExpire();
		holdAcceleration = 1f;
	}

	private void Update()
	{
		if (ArrowViewTimer.Update(Time.unscaledDeltaTime))
		{
			ArrowViewTimer.Enabled = false;
			UpArrow.enabled = false;
			DownArrow.enabled = false;
		}
		if (!isIncrementPressed && !isDecrementPressed)
		{
			return;
		}
		holdAcceleration = Mathf.Clamp(holdAcceleration, 1f, holdAccelerationMax);
		float dt = holdAcceleration * Time.unscaledDeltaTime;
		if (holdDuration.Update(dt))
		{
			if (isIncrementPressed)
			{
				AddToAvailable(1);
			}
			else if (isDecrementPressed)
			{
				AddToAvailable(-1);
			}
		}
		holdAcceleration += holdAccelerationStep;
	}
}
