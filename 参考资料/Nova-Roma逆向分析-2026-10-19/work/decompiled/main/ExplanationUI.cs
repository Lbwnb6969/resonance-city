using TMPro;
using UnityEngine;

public class ExplanationUI : MonoBehaviour
{
	public delegate string GetExplanationTxt();

	public GetExplanationTxt explanationDelegate;

	private int enterCount;

	public TextMeshProUGUI explanationText;

	public RectTransform explanationUI;

	private Timer updateExplanationTimer = new Timer(1f);

	private void Start()
	{
	}

	private void OnEnable()
	{
		enterCount = 0;
		if ((bool)Player.inst && World.inst.Inited)
		{
			explanationText.text = explanationDelegate();
		}
	}

	public void PointerEnter()
	{
		enterCount = 1;
		updateExplanationTimer.ForceExpire();
	}

	public void PointerExit()
	{
		enterCount = 0;
	}

	private void Update()
	{
		if (LoadSave.Loading || Player.inst.FocusedLandMass == -1)
		{
			return;
		}
		if (enterCount > 0)
		{
			if (updateExplanationTimer.Update(Time.unscaledDeltaTime))
			{
				explanationText.text = explanationDelegate();
			}
			if (!explanationUI.gameObject.activeSelf)
			{
				explanationUI.gameObject.SetActive(value: true);
			}
		}
		else if (explanationUI.gameObject.activeSelf)
		{
			explanationUI.gameObject.SetActive(value: false);
		}
	}
}
