using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SlabUI : MonoBehaviour, IWorkerUIElement
{
	public SlabStatue slabStatue;

	public TMP_InputField text;

	public Button button;

	public GameObject toolbarContainer;

	public Button largeTextButton;

	public Button normalTextButton;

	public Button smallTextButton;

	public Button alignLeftButton;

	public Button alignCenterButton;

	public Button alignRightButton;

	public Button italicsButton;

	private void Start()
	{
		text = transform.Find("Input").GetComponent<TMP_InputField>();
		button = transform.Find("ChiselMessage").GetComponent<Button>();
		text.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
		});
		text.onEndEdit.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = true;
		});
		button.onClick.AddListener(OnClickButton);
		largeTextButton.onClick.AddListener(DoLargeTextAction);
		normalTextButton.onClick.AddListener(DoNormalTextAction);
		smallTextButton.onClick.AddListener(DoSmallTextAction);
		alignLeftButton.onClick.AddListener(DoLeftAlignAction);
		alignCenterButton.onClick.AddListener(DoCenterAlignAction);
		alignRightButton.onClick.AddListener(DoRightAlignAction);
		italicsButton.onClick.AddListener(DoItalicsAction);
	}

	public void AddTags(string selectionStart, string selectionEnd)
	{
		if (this.text.selectionAnchorPosition != this.text.selectionFocusPosition)
		{
			int num = this.text.selectionAnchorPosition;
			int num2 = this.text.selectionFocusPosition;
			if (num > num2)
			{
				int num3 = num;
				num = num2;
				num2 = num3;
			}
			string text = this.text.text;
			text = text.Insert(num2, selectionEnd);
			this.text.text = text.Insert(num, selectionStart);
		}
		else
		{
			string text2 = this.text.text;
			this.text.text = text2.Insert(this.text.selectionAnchorPosition, selectionStart);
		}
	}

	public void DoLargeTextAction()
	{
		AddTags($"<size={slabStatue.tmp.fontSize + 10f}>", "</size>");
	}

	public void DoNormalTextAction()
	{
		AddTags($"<size={slabStatue.tmp.fontSize}>", "</size>");
	}

	public void DoSmallTextAction()
	{
		AddTags($"<size={slabStatue.tmp.fontSize - 10f}>", "</size>");
	}

	public void DoLeftAlignAction()
	{
		AddTags("<align=left>", "</align>");
	}

	public void DoCenterAlignAction()
	{
		AddTags("<align=center>", "</align>");
	}

	public void DoRightAlignAction()
	{
		AddTags("<align=right>", "</align>");
	}

	public void DoItalicsAction()
	{
		AddTags("<i>", "</i>");
	}

	public void OnClickButton()
	{
		GameUI.inst.ClearCellSelected();
	}

	public void OnUpdateText(string text)
	{
		slabStatue.SetPreviewText(SlabStatue.CleanMessage(text));
	}

	public void StartLastSlab()
	{
		if (slabStatue != null)
		{
			string text = SlabStatue.CleanMessage(this.text.text);
			if (text != slabStatue.messageText && text.Length > 0)
			{
				slabStatue.StartChiseling(this.text.text);
			}
		}
		slabStatue = null;
	}

	public void OnDisable()
	{
		StartLastSlab();
	}

	public void UpdateForNewSelection()
	{
		if (GameUI.inst.SelectedBuildingIs(World.statueSlabHash))
		{
			SlabStatue component = GameUI.inst.GetBuildingSelected().GetComponent<SlabStatue>();
			if (component != slabStatue)
			{
				StartLastSlab();
			}
			slabStatue = component;
			text.onValueChanged.RemoveAllListeners();
			text.text = slabStatue.messageText;
			text.onValueChanged.AddListener(OnUpdateText);
		}
	}

	void IWorkerUIElement.TryShow()
	{
		gameObject.SetActive(CanShow());
	}

	public bool CanShow()
	{
		return GameUI.inst.SelectedBuildingIs(World.statueSlabHash);
	}
}
