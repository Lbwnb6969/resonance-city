using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;

public class HoverHide : MonoBehaviour, IPointerEnterHandler, IEventSystemHandler, IPointerExitHandler
{
	public Transform toHide;

	public TMP_InputField inputField;

	private bool pointerOver;

	private void Awake()
	{
		inputField.onEndEdit.AddListener((string val) =>
		{
		});
		inputField.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = !inputField.interactable;
		});
	}

	public void OnClickImage()
	{
		inputField.Select();
	}

	private void Update()
	{
		toHide.gameObject.SetActive((!pointerOver && !(inputField.text != "0") && !inputField.isFocused) || !inputField.interactable);
		if (inputField.text == "")
		{
			inputField.text = "0";
		}
	}

	public void OnPointerEnter(PointerEventData eventData)
	{
		pointerOver = true;
	}

	public void OnPointerExit(PointerEventData eventData)
	{
		pointerOver = false;
	}
}
