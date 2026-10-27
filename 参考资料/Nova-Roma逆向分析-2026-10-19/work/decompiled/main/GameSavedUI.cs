using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GameSavedUI : MonoBehaviour
{
	public static GameSavedUI inst;

	[SerializeField]
	private bool registerAsInst = true;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private Image backgroundImg;

	[SerializeField]
	private TextMeshProUGUI titleTMP;

	[SerializeField]
	private float speed = 1f;

	[SerializeField]
	private float backgroundAlpha = 0.5f;

	[SerializeField]
	private float textAlpha = 1f;

	[SerializeField]
	private AnimationCurve alphaCurve;

	private float currTime;

	private Color currBackgroundColor;

	private Color currTextColor;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	private void Awake()
	{
		if (registerAsInst)
		{
			inst = this;
		}
		SetVisibility(v: false);
	}

	public void Show(string text)
	{
		titleTMP.text = text;
		SetVisibility(v: true);
	}

	public void SetVisibility(bool v)
	{
		if (v)
		{
			currTime = 0f;
			currBackgroundColor = backgroundImg.color;
			currBackgroundColor.a = backgroundAlpha;
			backgroundImg.color = currBackgroundColor;
			currTextColor = titleTMP.color;
			currTextColor.a = textAlpha;
			titleTMP.color = currTextColor;
		}
		Util.SetEnabled(canvas, v);
		isVisible = v;
	}

	private void Update()
	{
		if (isVisible)
		{
			float num = Time.unscaledDeltaTime * speed;
			currTime += num;
			float num2 = 1f - alphaCurve.Evaluate(currTime / 1f);
			currBackgroundColor.a = backgroundAlpha * num2;
			currTextColor.a = textAlpha * num2;
			backgroundImg.color = currBackgroundColor;
			titleTMP.color = currTextColor;
			if (currTime >= 1f)
			{
				SetVisibility(v: false);
			}
		}
	}
}
