using Assets.Code.UI;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SendSave : MonoBehaviour
{
	public TMP_InputField note;

	public SaveLoadOption option;

	public Button sendButton;

	private void Start()
	{
		sendButton.onClick.AddListener(OnClickSend);
	}

	private void OnEnable()
	{
		sendButton.interactable = true;
		GameState.inst.AlphaNumericHotkeysEnabled = false;
	}

	private void OnDisable()
	{
		GameState.inst.AlphaNumericHotkeysEnabled = true;
	}

	public void SetupSendSaveUI()
	{
		LoadSave.WorldSummaryData worldSummaryData = LoadSave.LoadWorldSummaryData(LoadSave.LastLoadDirectory);
		option.SetTitle(worldSummaryData.CityName);
		option.SetYear(worldSummaryData.Year);
		option.SetPopulation(worldSummaryData.Population);
		option.SetDate(worldSummaryData.Date.ToLocalTime());
		option.SetIsAutosave(LoadSave.LastLoadDirectory.Contains("autosave"));
		option.SetImage(LoadSave.LoadTextureFromSave(LoadSave.LastLoadDirectory, "cover"));
		note.text = "";
		sendButton.GetComponentInChildren<TextMeshProUGUI>().text = ScriptLocalization.SendSaveSendSave;
	}

	public void OnClickSend()
	{
	}

	private void SomehowCompleted()
	{
		GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.Menu);
	}
}
