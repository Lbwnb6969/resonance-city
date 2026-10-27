using I2.Loc;
using TMPro;
using UnityEngine;

public class AdvisorUI : MonoBehaviour
{
	public enum Status
	{
		SelectingGovernor,
		ConfirmSelection,
		GovernorInfo
	}

	internal Status status;

	public static AdvisorUI inst;

	public GameObject message;

	public TextMeshProUGUI messageTxt;

	public TextMeshProUGUI termTxt;

	public GameObject reappointWarning;

	public ConsoleUIItem consoleItem;

	public GameObject consoleClose;

	public GameObject consoleControls;

	public GameObject defaultClose;

	private string[] messages = new string[3];

	public GameObject governorPrefab;

	public Transform governorContainer;

	internal Governor[] governors = new Governor[3];

	public GameObject dedicateContainer;

	public GameObject governorInfoContainer;

	public Transform appointedGovernor;

	private int oldSpeed;

	public float selectedLightIntensity = 1f;

	public float lightSpeed = 2f;

	private int selectedGovernor = -1;

	private void Awake()
	{
		inst = this;
		transform.GetChild(0).gameObject.SetActive(value: false);
		for (int i = 0; i < messages.Length; i++)
		{
			messages[i] = "ScriptLocalization.AdvisorGoodDaySire";
		}
		for (int j = 0; j < 3; j++)
		{
			GovernorEntryUI component = Object.Instantiate(governorPrefab).GetComponent<GovernorEntryUI>();
			component.transform.SetParent(governorContainer);
			component.transform.localScale = new Vector3(1f, 1f, 1f);
			component.idx = j;
			Vector3 localPosition = component.transform.localPosition;
			localPosition.z = 0f;
			component.transform.localPosition = localPosition;
		}
		GovernorEntryUI component2 = Object.Instantiate(governorPrefab).GetComponent<GovernorEntryUI>();
		component2.transform.SetParent(appointedGovernor);
		component2.transform.localScale = new Vector3(1f, 1f, 1f);
		component2.idx = -1;
		component2.ignoreClick = true;
		component2.transform.localPosition = Vector3.zero;
		component2.detailDimmer.SetActive(value: false);
	}

	public static void SetAdvisorMessage(int idx, string message, string sound, string anim = null, bool force = false)
	{
	}

	public bool IsVisible()
	{
		return transform.GetChild(0).gameObject.activeSelf;
	}

	public void OnClickedConfirmAppoint()
	{
		if (governors[selectedGovernor] == Player.inst.FocusedGovenor)
		{
			Util.SetActive(reappointWarning, active: true);
			return;
		}
		AppointGovernor();
		SetStatus(Status.GovernorInfo);
	}

	private void AppointGovernor()
	{
		int focusedLandMass = Player.inst.FocusedLandMass;
		Governor focusedGovenor = Player.inst.FocusedGovenor;
		if (focusedGovenor == governors[selectedGovernor])
		{
			focusedGovenor.Reappoint();
		}
		Player.inst.governors[focusedLandMass] = governors[selectedGovernor];
		SetStatus(Status.GovernorInfo);
		GovernorUI.inst.forceUpdate = true;
	}

	public void OnClickedConfirmReappoint()
	{
		AppointGovernor();
		SetStatus(Status.GovernorInfo);
	}

	public void OnClickedCancelReappoint()
	{
		Util.SetActive(reappointWarning, active: false);
	}

	public void OnClickedCancelAppoint()
	{
		SetStatus(Status.SelectingGovernor);
	}

	public void Show()
	{
		GameUI.inst.ClearUIForClick();
		oldSpeed = TimeManager.inst.speedInUse;
		TimeManager.inst.SetPaused(skipSfx: true);
		selectedGovernor = -1;
		Governor focusedGovenor = Player.inst.FocusedGovenor;
		if (focusedGovenor == null)
		{
			SetStatus(Status.SelectingGovernor);
		}
		else if (focusedGovenor.GetRemainingTerm() < 0f)
		{
			SetStatus(Status.SelectingGovernor);
		}
		else
		{
			SetStatus(Status.GovernorInfo);
		}
		if (!transform.GetChild(0).gameObject.activeSelf)
		{
			SfxSystem.inst.PlayFromBank("AdvisorUIOpen", Camera.main.transform.position);
		}
		if (!IsVisible())
		{
			GameUI.SetUIForModalHelper(v: false);
		}
		transform.GetChild(0).gameObject.SetActive(value: true);
		message.SetActive(value: false);
		GenerateGovenorOptions();
		UpdateConsoleUI(GamepadControl.inst.isControllerActive);
		if (GamepadControl.inst.isControllerActive)
		{
			consoleItem.Hover();
		}
	}

	public void GenerateGovenorOptions()
	{
		Governor focusedGovenor = Player.inst.FocusedGovenor;
		for (int i = 0; i < 3; i++)
		{
			if (i == 1 && focusedGovenor != null)
			{
				governors[i] = focusedGovenor;
				governorContainer.GetChild(i).GetComponent<GovernorEntryUI>().SetGovernor(governors[i], current: true);
				continue;
			}
			governors[i] = new Governor();
			int num = World.inst.seed + SeasonManager.inst.CurrentYear() * 10000 + Player.inst.FocusedLandMass * 1000 + i * 100;
			governors[i].Generate(num);
			for (int num2 = 20; num2 > 0; num2--)
			{
				bool flag = false;
				for (int j = 0; j < i; j++)
				{
					if (governors[j].HasSameTraits(governors[i]))
					{
						flag = true;
					}
				}
				if (!flag)
				{
					break;
				}
				governors[i] = new Governor();
				governors[i].Generate(num + num2);
			}
			governorContainer.GetChild(i).GetComponent<GovernorEntryUI>().SetGovernor(governors[i], current: false);
		}
	}

	public void UpdateConsoleUI(bool isControllerActive)
	{
		consoleControls.SetActive(isControllerActive);
		consoleClose.SetActive(isControllerActive);
		defaultClose.SetActive(!isControllerActive);
	}

	public void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		for (int i = 0; i < governorContainer.childCount; i++)
		{
			GovernorEntryUI component = governorContainer.GetChild(i).GetComponent<GovernorEntryUI>();
			if (status == Status.SelectingGovernor)
			{
				if (component.lightOn || i == selectedGovernor)
				{
					component.light.intensity += unscaledDeltaTime * lightSpeed;
				}
				else
				{
					component.light.intensity -= unscaledDeltaTime * lightSpeed;
				}
				component.light.intensity = Mathff.Clamp(component.light.intensity, 0f, selectedLightIntensity);
				Util.SetActive(component.detailDimmer, active: false);
			}
			else if (status == Status.ConfirmSelection)
			{
				if (i == selectedGovernor)
				{
					component.light.intensity += unscaledDeltaTime * lightSpeed;
				}
				else
				{
					component.light.intensity -= unscaledDeltaTime * lightSpeed;
				}
				component.light.intensity = Mathff.Clamp(component.light.intensity, 0f, selectedLightIntensity * 1.5f);
				Util.SetActive(component.detailDimmer, i != selectedGovernor);
			}
			if (component.animTime > 0f && component.animTime - unscaledDeltaTime <= 0f && component.animator != null && component.animator.isActiveAndEnabled)
			{
				component.animator.CrossFadeInFixedTime("neutral", 0.25f);
			}
			component.animTime -= unscaledDeltaTime;
			component.confirmContainer.SetActive(i == selectedGovernor);
		}
		if (status == Status.GovernorInfo)
		{
			appointedGovernor.GetComponentInChildren<GovernorEntryUI>().light.intensity = selectedLightIntensity * 1.25f;
		}
	}

	public void Hide()
	{
		for (int i = 0; i < governorContainer.childCount; i++)
		{
			governorContainer.GetChild(i).GetComponent<GovernorEntryUI>().lightOn = false;
		}
		message.SetActive(value: false);
		if (transform.GetChild(0).gameObject.activeSelf)
		{
			SfxSystem.inst.PlayFromBank("AdvisorUIClose", Camera.main.transform.position);
			if (oldSpeed != -1)
			{
				TimeManager.inst.SetSpeed(oldSpeed, skipSfx: true);
			}
		}
		if (IsVisible())
		{
			GameUI.SetUIForModalHelper(v: true);
		}
		transform.GetChild(0).gameObject.SetActive(value: false);
	}

	internal void OnSelectedGovernor(int idx)
	{
		selectedGovernor = idx;
		SetStatus(Status.ConfirmSelection);
	}

	private void SetStatus(Status newStatus)
	{
		status = newStatus;
		Util.SetActive(reappointWarning, active: false);
		Util.SetActive(dedicateContainer, active: false);
		Util.SetActive(governorInfoContainer, active: false);
		if (status == Status.SelectingGovernor)
		{
			selectedGovernor = -1;
			Util.SetActive(dedicateContainer, active: true);
		}
		else if (status == Status.ConfirmSelection)
		{
			Util.SetActive(dedicateContainer, active: true);
		}
		else if (status == Status.GovernorInfo)
		{
			termTxt.text = GetTermTxt(Player.inst.FocusedGovenor);
			Util.SetActive(governorInfoContainer, active: true);
			int focusedLandMass = Player.inst.FocusedLandMass;
			appointedGovernor.GetComponentInChildren<GovernorEntryUI>().SetGovernor(Player.inst.governors[focusedLandMass], current: true);
		}
	}

	public static string GetTermTxt(Governor gov)
	{
		float num = gov.GetRemainingTerm() / SeasonManager.inst.TimeInYear();
		if (num <= 0f)
		{
			num = 0f;
		}
		if (num < 1f)
		{
			if (num > 0.6f)
			{
				return string.Format(LocalizationManager.GetTranslation("advisorui_termremaining"), "3/4");
			}
			if (num > 0.4f)
			{
				return string.Format(LocalizationManager.GetTranslation("advisorui_termremaining"), "1/2");
			}
			return string.Format(LocalizationManager.GetTranslation("advisorui_termremaining"), "1/4");
		}
		return string.Format(LocalizationManager.GetTranslation("advisorui_termremaining"), Mathf.RoundToInt(num));
	}
}
