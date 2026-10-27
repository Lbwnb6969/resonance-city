using I2.Loc;
using PixelCrushers.DialogueSystem.I2Support;
using UnityEngine;

public class MakeDialogueSystemSwitchLanguageDuringRuntime : MonoBehaviour
{
	private DialogueSystemUseI2Language dsui2l;

	private void Start()
	{
		dsui2l = GetComponent<DialogueSystemUseI2Language>();
		LocalizationManager.OnLocalizeEvent += LocalizationManager_OnLocalizeEvent;
	}

	private void LocalizationManager_OnLocalizeEvent()
	{
		dsui2l.UseCurrentI2Language();
	}
}
