using UnityEngine;

public class TooltipManager : MonoBehaviour
{
	public Canvas canvas;

	private Vector3 lastMousePos;

	private float timeStill;

	public Tooltip toolTip;

	private TooltipHook lastHook;

	private bool wasStill;

	private void Update()
	{
		TooltipHook tooltipHook = null;
		for (int i = 0; i < TooltipHook.hooks.Count; i++)
		{
			if (TooltipHook.hooks[i].isOver && TooltipHook.hooks[i].isValid)
			{
				tooltipHook = TooltipHook.hooks[i];
			}
		}
		Vector3 position = default;
		Vector3 vector = default;
		bool flag = true;
		Vector3 vector2;
		if (GamepadControl.inst.isControllerActive && tooltipHook != null)
		{
			if (tooltipHook.consoleAnchor != null)
			{
				vector2 = tooltipHook.consoleAnchor.position;
				vector2.z = canvas.planeDistance;
				position = vector2;
				vector = canvas.worldCamera.WorldToViewportPoint(vector2);
			}
			else
			{
				flag = false;
				vector2 = Vector3.zero;
			}
		}
		else
		{
			vector2 = Input.mousePosition;
			vector2.z = canvas.planeDistance;
			if ((vector2 - lastMousePos).sqrMagnitude < 1f)
			{
				timeStill += Time.unscaledDeltaTime;
			}
			else
			{
				timeStill = 0f;
			}
			position = canvas.worldCamera.ScreenToWorldPoint(vector2);
			vector = canvas.worldCamera.WorldToViewportPoint(position);
		}
		lastMousePos = vector2;
		bool flag2 = timeStill > 0.1f;
		if (((bool)tooltipHook && (flag2 || tooltipHook == lastHook)) & flag)
		{
			lastHook = tooltipHook;
			Vector2 sizeDelta = canvas.GetComponent<RectTransform>().sizeDelta;
			toolTip.rt.position = position;
			if (!string.IsNullOrEmpty(tooltipHook.tooltipTerm))
			{
				toolTip.localize.Term = tooltipHook.tooltipTerm;
			}
			if (!string.IsNullOrEmpty(tooltipHook.toolTipText))
			{
				toolTip.tipText.text = tooltipHook.toolTipText;
			}
			if (string.IsNullOrEmpty(tooltipHook.tooltipTerm) && string.IsNullOrEmpty(tooltipHook.toolTipText))
			{
				Util.SetActive(toolTip.gameObject, active: false);
				return;
			}
			float num = toolTip.rt.sizeDelta.x / 2f + vector.x * sizeDelta.x;
			float num2 = vector.x * sizeDelta.x - toolTip.rt.sizeDelta.x / 2f;
			float x = 0.5f;
			if (num >= sizeDelta.x)
			{
				float t = (num - sizeDelta.x) / toolTip.rt.sizeDelta.x * 2f;
				x = Mathf.LerpUnclamped(0.5f, 1f, t);
			}
			else if (num2 <= 0f)
			{
				float t2 = num2 / toolTip.rt.sizeDelta.x * -2f;
				x = Mathf.LerpUnclamped(0.5f, 0f, t2);
			}
			float y = -0.25f;
			if (toolTip.rt.sizeDelta.y * 1.5f + vector.y * sizeDelta.y >= sizeDelta.y)
			{
				y = 2f;
			}
			toolTip.rt.pivot = new Vector2(x, y);
			toolTip.gameObject.SetActive(value: true);
		}
		else
		{
			toolTip.gameObject.SetActive(value: false);
		}
	}
}
