using System;
using System.Collections.Generic;
using Assets.Code.UI;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class TerminalUI : UIWindowBase, IBeginDragHandler, IEventSystemHandler, IDragHandler
{
	[Header("Terminal Components")]
	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	public ScrollRect scrollRect;

	public TextMeshProUGUI outputText;

	public TMP_InputField inputField;

	public RectTransform terminalPanel;

	[Header("Live Buffer Components")]
	public RectTransform liveBufferContainer;

	public TextMeshProUGUI liveBufferText;

	[Header("Resize Components")]
	public RectTransform resizeHandle;

	[Header("Terminal Settings")]
	public int maxOutputLines = 500;

	public Color defaultTextColor = Color.white;

	public Color commandTextColor = Color.cyan;

	public Color errorTextColor = Color.red;

	public Color successTextColor = Color.green;

	public Color warningTextColor = Color.yellow;

	[Header("Extras")]
	public Confirmation cheatConfirmation;

	private List<string> outputLines = new List<string>();

	private List<string> commandHistory = new List<string>();

	private int historyIndex = -1;

	private string currentInput = "";

	private List<string> autoCompleteOptions = new List<string>();

	private int autoCompleteIndex = -1;

	private string autoCompletePrefix = "";

	private TextMeshProUGUI suggestionText;

	public static TerminalUI inst;

	private Vector2 startAnchorMin;

	private Vector2 startAnchorMax;

	private Vector3 startDrag;

	public override void AwakeInternal()
	{
		inst = this;
		SetupTerminal();
	}

	public override void StartInternal()
	{
		SetVisible(v: false);
		PrintWelcomeMessage();
	}

	private void Update()
	{
		HandleInput();
	}

	private void SetupTerminal()
	{
		if (terminalPanel != null)
		{
			terminalPanel.anchorMin = new Vector2(0f, 0.5f);
			terminalPanel.anchorMax = new Vector2(1f, 1f);
			terminalPanel.offsetMin = Vector2.zero;
			terminalPanel.offsetMax = Vector2.zero;
		}
		if (inputField != null)
		{
			inputField.onSubmit.AddListener(OnCommandSubmit);
			inputField.onValueChanged.AddListener(OnInputChanged);
			TextMeshProUGUI textMeshProUGUI = inputField.textComponent as TextMeshProUGUI;
			if (textMeshProUGUI != null)
			{
				GameObject gameObject = UnityEngine.Object.Instantiate(textMeshProUGUI.gameObject, textMeshProUGUI.transform.parent);
				gameObject.name = "SuggestionText";
				suggestionText = gameObject.GetComponent<TextMeshProUGUI>();
				suggestionText.text = "";
				suggestionText.raycastTarget = false;
				suggestionText.richText = true;
				gameObject.transform.SetSiblingIndex(textMeshProUGUI.transform.GetSiblingIndex());
			}
		}
		if (outputText != null)
		{
			outputText.color = defaultTextColor;
			outputText.text = "";
		}
		SetupResizeHandle();
	}

	private void HandleInput()
	{
		if (World.inst.demoMode)
		{
			return;
		}
		if (Input.GetKeyDown(KeyCode.F8))
		{
			if (Visible)
			{
				HideTerminal();
				return;
			}
			ShowTerminal();
		}
		if (Visible)
		{
			if (Input.GetKeyDown(KeyCode.UpArrow))
			{
				NavigateHistory(-1);
			}
			else if (Input.GetKeyDown(KeyCode.DownArrow))
			{
				NavigateHistory(1);
			}
			if (Input.GetKeyDown(KeyCode.Tab))
			{
				HandleAutoComplete();
			}
		}
	}

	public void ShowTerminal()
	{
		SetVisible(v: true);
		if (inputField != null)
		{
			inputField.Select();
			inputField.ActivateInputField();
		}
	}

	public void HideTerminal()
	{
		SetVisible(v: false);
	}

	public override void SetVisible(bool v)
	{
		visible = v;
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		GameState.inst.AlphaNumericHotkeysEnabled = !v;
		if (!v)
		{
			TerminalManager.inst.CancelCheatCommand();
		}
	}

	public void SetInputInteractable(bool interactable)
	{
		if (inputField != null)
		{
			inputField.interactable = interactable;
		}
	}

	private void OnCommandSubmit(string command)
	{
		if (!string.IsNullOrWhiteSpace(command))
		{
			commandHistory.Add(command);
			historyIndex = commandHistory.Count;
			PrintLine("> " + command, commandTextColor);
			ExecuteCommand(command);
			inputField.text = "";
			inputField.Select();
			inputField.ActivateInputField();
			ResetAutoComplete();
			ClearSuggestion();
		}
	}

	private void OnInputChanged(string input)
	{
		currentInput = input.Replace("`", "").Replace("\t", "");
		inputField.SetTextWithoutNotify(currentInput);
		ResetAutoComplete();
		UpdateSuggestionText();
	}

	private void NavigateHistory(int direction)
	{
		if (commandHistory.Count != 0)
		{
			historyIndex += direction;
			historyIndex = Mathf.Clamp(historyIndex, -1, commandHistory.Count - 1);
			if (historyIndex == -1)
			{
				inputField.text = currentInput;
			}
			else
			{
				inputField.text = commandHistory[historyIndex];
			}
			inputField.caretPosition = inputField.text.Length;
		}
	}

	private void HandleAutoComplete()
	{
		string text = inputField.text;
		if (string.IsNullOrEmpty(text))
		{
			return;
		}
		if (autoCompleteOptions.Count == 0)
		{
			autoCompletePrefix = text;
			string[] array = text.Split(' ');
			bool flag = text.EndsWith(" ");
			if (array.Length == 1 && !flag)
			{
				autoCompleteOptions = TerminalManager.inst.GetAutoCompleteOptions(array[0]);
			}
			else
			{
				string commandName = array[0];
				string partialValue = (flag ? "" : array[^1]);
				int parameterIndex = (flag ? (array.Length - 1) : (array.Length - 2));
				autoCompleteOptions = TerminalManager.inst.GetParameterAutoCompleteOptions(commandName, parameterIndex, partialValue);
				if (flag)
				{
					autoCompletePrefix = text;
				}
				else
				{
					autoCompletePrefix = string.Join(" ", array, 0, array.Length - 1) + " ";
				}
			}
			if (autoCompleteOptions.Count == 0)
			{
				if (suggestionText != null && !string.IsNullOrEmpty(suggestionText.text))
				{
					string bestSuggestion = GetBestSuggestion(text);
					if (!string.IsNullOrEmpty(bestSuggestion))
					{
						inputField.SetTextWithoutNotify(bestSuggestion);
						inputField.caretPosition = inputField.text.Length;
						ClearSuggestion();
					}
				}
				return;
			}
			autoCompleteIndex = 0;
			if (autoCompleteOptions.Count > 1)
			{
				string text2 = string.Join("  ", autoCompleteOptions);
				PrintLine("<color=#" + ColorUtility.ToHtmlStringRGB(commandTextColor) + ">" + text2 + "</color>");
			}
		}
		else
		{
			autoCompleteIndex = (autoCompleteIndex + 1) % autoCompleteOptions.Count;
		}
		if (autoCompleteOptions.Count > 0)
		{
			string textWithoutNotify = ((autoCompletePrefix.Split(' ').Length != 1 || autoCompletePrefix.EndsWith(" ")) ? (autoCompletePrefix + autoCompleteOptions[autoCompleteIndex]) : autoCompleteOptions[autoCompleteIndex]);
			inputField.SetTextWithoutNotify(textWithoutNotify);
			inputField.caretPosition = inputField.text.Length;
			UpdateSuggestionText();
		}
	}

	private void ResetAutoComplete()
	{
		autoCompleteOptions.Clear();
		autoCompleteIndex = -1;
		autoCompletePrefix = "";
	}

	private void UpdateSuggestionText()
	{
		if (suggestionText == null)
		{
			return;
		}
		string text = inputField.text;
		if (string.IsNullOrEmpty(text))
		{
			ClearSuggestion();
			return;
		}
		string bestSuggestion = GetBestSuggestion(text);
		if (string.IsNullOrEmpty(bestSuggestion) || bestSuggestion.Equals(text, StringComparison.OrdinalIgnoreCase))
		{
			ClearSuggestion();
			return;
		}
		string text2 = "<color=#00000000>" + bestSuggestion.Substring(0, text.Length) + "</color>";
		string text3 = "<color=#808080>" + bestSuggestion.Substring(text.Length) + "</color>";
		suggestionText.text = text2 + text3;
	}

	private string GetBestSuggestion(string input)
	{
		if (TerminalManager.inst == null || string.IsNullOrEmpty(input))
		{
			return null;
		}
		string[] array = input.Split(' ');
		bool flag = input.EndsWith(" ");
		if (array.Length == 1 && !flag)
		{
			List<string> list = TerminalManager.inst.GetAutoCompleteOptions(array[0]);
			if (list.Count > 0)
			{
				return list[0];
			}
		}
		else
		{
			string commandName = array[0];
			string partialValue = (flag ? "" : array[^1]);
			int parameterIndex = (flag ? (array.Length - 1) : (array.Length - 2));
			List<string> parameterAutoCompleteOptions = TerminalManager.inst.GetParameterAutoCompleteOptions(commandName, parameterIndex, partialValue);
			if (parameterAutoCompleteOptions.Count > 0)
			{
				return (flag ? input : (string.Join(" ", array, 0, array.Length - 1) + " ")) + parameterAutoCompleteOptions[0];
			}
		}
		return null;
	}

	private void ClearSuggestion()
	{
		if (suggestionText != null)
		{
			suggestionText.text = "";
		}
	}

	private void ExecuteCommand(string command)
	{
		if (TerminalManager.inst != null)
		{
			TerminalManager.inst.ExecuteCommand(command);
		}
		else
		{
			PrintError("Terminal manager not initialized!");
		}
	}

	private void PrintWelcomeMessage()
	{
		PrintLine("=== Roma Terminal v1.0 ===", commandTextColor);
		PrintLine("Type 'help' for available commands", defaultTextColor);
		PrintLine("Use Up/Down arrows for command history, Tab for auto-complete", defaultTextColor);
		PrintLine("");
	}

	public void PrintLine(string text, Color? color = null)
	{
		string text2 = ColorUtility.ToHtmlStringRGB(color ?? defaultTextColor);
		outputLines.Add("<color=#" + text2 + ">" + text + "</color>");
		if (outputLines.Count > maxOutputLines)
		{
			outputLines.RemoveAt(0);
		}
		UpdateOutputDisplay();
	}

	public void PrintError(string text)
	{
		PrintLine("ERROR: " + text, errorTextColor);
	}

	public void PrintSuccess(string text)
	{
		PrintLine(text, successTextColor);
	}

	public void PrintWarning(string text)
	{
		PrintLine("WARNING: " + text, warningTextColor);
	}

	private void UpdateOutputDisplay()
	{
		if (outputText != null)
		{
			outputText.text = string.Join("\n", outputLines);
			Canvas.ForceUpdateCanvases();
			if (scrollRect != null)
			{
				scrollRect.verticalNormalizedPosition = 0f;
			}
		}
	}

	public void ClearOutput()
	{
		outputLines.Clear();
		PrintWelcomeMessage();
		UpdateOutputDisplay();
	}

	public void UpdateLiveBuffers(List<TerminalCommandBuffer> activeBuffers)
	{
		if (!(liveBufferText != null) || !(liveBufferContainer != null))
		{
			return;
		}
		if (activeBuffers.Count == 0)
		{
			liveBufferContainer.gameObject.SetActive(value: false);
			return;
		}
		liveBufferContainer.gameObject.SetActive(value: true);
		List<string> list = new List<string>();
		foreach (TerminalCommandBuffer activeBuffer in activeBuffers)
		{
			list.Add($"[{activeBuffer.name}, {activeBuffer.id}]");
			List<string> activeLines = activeBuffer.GetActiveLines();
			if (activeLines.Count > 0)
			{
				list.AddRange(activeLines);
				list.Add("");
			}
		}
		if (list.Count > 0 && string.IsNullOrEmpty(list[list.Count - 1]))
		{
			list.RemoveAt(list.Count - 1);
		}
		liveBufferText.text = string.Join("\n", list);
	}

	private void SetupResizeHandle()
	{
		if (resizeHandle != null)
		{
			resizeHandle.anchorMin = new Vector2(1f, 0f);
			resizeHandle.anchorMax = new Vector2(1f, 0f);
			resizeHandle.anchoredPosition = Vector2.zero;
			resizeHandle.sizeDelta = new Vector2(20f, 20f);
			Image image = resizeHandle.GetComponent<Image>();
			if (image == null)
			{
				image = resizeHandle.gameObject.AddComponent<Image>();
			}
			image.color = new Color(1f, 1f, 1f, 0.3f);
			TerminalResizeHandle terminalResizeHandle = resizeHandle.GetComponent<TerminalResizeHandle>();
			if (terminalResizeHandle == null)
			{
				terminalResizeHandle = resizeHandle.gameObject.AddComponent<TerminalResizeHandle>();
			}
			terminalResizeHandle.terminalUI = this;
		}
	}

	public void OnBeginDrag(PointerEventData eventData)
	{
		Vector3 mousePosition = Input.mousePosition;
		startDrag = Camera.main.ScreenToViewportPoint(mousePosition);
		startAnchorMin = terminalPanel.anchorMin;
		startAnchorMax = terminalPanel.anchorMax;
	}

	public void OnDrag(PointerEventData eventData)
	{
		Vector3 mousePosition = Input.mousePosition;
		Vector3 vector = Camera.main.ScreenToViewportPoint(mousePosition) - startDrag;
		Vector2 anchorMin = startAnchorMin + new Vector2(0f, vector.y);
		Vector2 anchorMax = startAnchorMax + new Vector2(vector.x, 0f);
		anchorMin.y = Mathf.Clamp(anchorMin.y, 0f, 1f);
		anchorMax.x = Mathf.Clamp(anchorMax.x, 0.1f, 1f);
		if (anchorMax.x <= anchorMin.x + 0.1f)
		{
			anchorMax.x = anchorMin.x + 0.1f;
		}
		if (anchorMin.y >= anchorMax.y - 0.2f)
		{
			anchorMin.y = anchorMax.y - 0.2f;
		}
		terminalPanel.anchorMin = anchorMin;
		terminalPanel.anchorMax = anchorMax;
	}
}
