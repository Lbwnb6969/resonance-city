using Steamworks;
using TMPro;

public class ConsoleUITextInput : ConsoleUISelectable
{
	public TMP_InputField input;

	public ConsoleUIItem deselectionTarget;

	private ConsoleUIItem item;

	public string locTermDesc;

	protected Callback<GamepadTextInputDismissed_t> m_GameOverlayActivated;

	public override void Submit()
	{
		item = GetComponent<ConsoleUIItem>();
		item.DeactivateInput();
		ActivateInput();
		SteamUtils.ShowGamepadTextInput(EGamepadTextInputMode.k_EGamepadTextInputModeNormal, EGamepadTextInputLineMode.k_EGamepadTextInputLineModeSingleLine, (locTermDesc != null) ? locTermDesc : "", 80u, "");
	}

	private void OnEnable()
	{
		m_GameOverlayActivated = Callback<GamepadTextInputDismissed_t>.Create(OnGamepadTextInputDismissedSteam);
	}

	private void OnGamepadTextInputDismissedSteam(GamepadTextInputDismissed_t data)
	{
		if (data.m_bSubmitted)
		{
			SteamUtils.GetEnteredGamepadTextInput(out var pchText, 80u);
			input.text = pchText;
			Close();
		}
	}

	public void Close()
	{
		DeactivateInput();
		item.Dehover();
		deselectionTarget.Hover();
	}

	public override void CustomActivate()
	{
		GamepadControl.inst.UICancelInput += Close;
	}

	public override void CustomDeactivate()
	{
		GamepadControl.inst.UICancelInput -= Close;
	}
}
