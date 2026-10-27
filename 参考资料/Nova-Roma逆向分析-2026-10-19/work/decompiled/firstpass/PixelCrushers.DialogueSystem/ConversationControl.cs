using UnityEngine;

namespace PixelCrushers.DialogueSystem;

[AddComponentMenu("")]
[RequireComponent(typeof(AbstractDialogueUI))]
public class ConversationControl : MonoBehaviour
{
	public bool skipAll;

	private AbstractDialogueUI dialogueUI;

	private void Awake()
	{
		dialogueUI = GetComponent<AbstractDialogueUI>() ?? Object.FindObjectOfType<AbstractDialogueUI>();
	}

	public void ToggleAutoPlay()
	{
		DisplaySettings.SubtitleSettings.ContinueButtonMode continueButtonMode = ((DialogueManager.displaySettings.subtitleSettings.continueButton == DisplaySettings.SubtitleSettings.ContinueButtonMode.Never) ? DisplaySettings.SubtitleSettings.ContinueButtonMode.Always : DisplaySettings.SubtitleSettings.ContinueButtonMode.Never);
		DialogueManager.displaySettings.subtitleSettings.continueButton = continueButtonMode;
		if (continueButtonMode == DisplaySettings.SubtitleSettings.ContinueButtonMode.Never)
		{
			dialogueUI.OnContinueConversation();
		}
	}

	public void SkipAll()
	{
		skipAll = true;
		if (dialogueUI != null)
		{
			dialogueUI.OnContinueConversation();
		}
	}

	public void OnConversationStart(Transform actor)
	{
		skipAll = false;
	}

	public void OnConversationLine(Subtitle subtitle)
	{
		if (skipAll)
		{
			subtitle.sequence = "Continue(); " + subtitle.sequence;
		}
	}

	public void OnConversationResponseMenu(Response[] responses)
	{
		if (skipAll)
		{
			skipAll = false;
			if (dialogueUI != null)
			{
				dialogueUI.ShowSubtitle(DialogueManager.currentConversationState.subtitle);
			}
		}
	}
}
