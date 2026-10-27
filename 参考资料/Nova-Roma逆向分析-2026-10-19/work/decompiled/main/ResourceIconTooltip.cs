using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;

[RequireComponent(typeof(TooltipHook), typeof(TextMeshProUGUI))]
public class ResourceIconTooltip : MonoBehaviour, IPointerEnterHandler, IEventSystemHandler, IPointerExitHandler
{
	private TooltipHook tooltipHook;

	private TMP_Text textTMP;

	private int prevIdx = -1;

	private bool isHovered;

	private void Awake()
	{
		tooltipHook = GetComponent<TooltipHook>();
		textTMP = GetComponent<TMP_Text>();
		tooltipHook.isValid = false;
		tooltipHook.toolTipText = "";
	}

	private void Update()
	{
		if (isHovered)
		{
			TryParseLink();
		}
	}

	public void OnPointerEnter(PointerEventData eventData)
	{
		isHovered = true;
		TryParseLink();
	}

	private void TryParseLink()
	{
		int num = TMP_TextUtilities.FindIntersectingLink(textTMP, Input.mousePosition, GUICamera.inst.cam);
		tooltipHook.isValid = num != -1;
		if (num != -1 && num != prevIdx)
		{
			TMP_LinkInfo tMP_LinkInfo = textTMP.textInfo.linkInfo[num];
			if (int.TryParse(tMP_LinkInfo.GetLinkID(), out var result) && FreeResourceSystem.inst.resourceDefMap.TryGetValue(result, out var value))
			{
				tooltipHook.toolTipText = LocalizationManager.GetTranslation(value.name);
			}
			else
			{
				tooltipHook.isValid = false;
			}
		}
		prevIdx = num;
	}

	public void OnPointerExit(PointerEventData eventData)
	{
		isHovered = false;
		tooltipHook.isValid = false;
		prevIdx = -1;
	}
}
