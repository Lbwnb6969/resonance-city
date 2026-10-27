using UnityEngine;
using UnityEngine.UI;

public class ConsoleUIIndexSlider : ConsoleUISelectable
{
	public Slider slider;

	public override void Hover()
	{
		int num = 0;
		int childCount = transform.parent.childCount;
		for (int i = 0; i < childCount; i++)
		{
			if (transform.parent.GetChild(i).gameObject.activeSelf)
			{
				num++;
			}
		}
		slider.maxValue = num - 1;
		slider.value = transform.GetSiblingIndex();
		float num2 = slider.GetComponent<RectTransform>().rect.width / (float)(num - 1);
		slider.handleRect.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, num2);
		RectTransform component = slider.handleRect.parent.GetComponent<RectTransform>();
		component.offsetMax = new Vector2((0f - num2) / 2f, 0f);
		component.offsetMin = new Vector2(num2 / 2f, 0f);
	}
}
