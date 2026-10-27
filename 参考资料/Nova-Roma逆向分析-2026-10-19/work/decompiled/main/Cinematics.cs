using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class Cinematics : MonoBehaviour
{
	public delegate void cinematicsLineEvent(int line);

	private enum BarState
	{
		Showing,
		Hiding,
		IdleHiding,
		IdleShowing
	}

	private enum FadeState
	{
		Showing,
		Hiding,
		IdleHiding,
		IdleShowing
	}

	public Image fader;

	public static Cinematics inst;

	public RectTransform topBar;

	public RectTransform bottomBar;

	private BarState barState = BarState.IdleHiding;

	public float BarMoveSpeed = 200f;

	private FadeState fadeState = FadeState.IdleHiding;

	public float fadeDelay = 0.5f;

	private float currFadeDelay;

	public float fadeInSpeed = 10f;

	internal int introDialogueIdx;

	private List<string> narrationTerms;

	public TextMeshProUGUI textTMP;

	private float clickToContinueTimer;

	public GameObject clickToContinueTxt;

	public event cinematicsLineEvent OnLineStart;

	private void Awake()
	{
		inst = this;
		fader.gameObject.SetActive(value: false);
	}

	private void MoveBar(RectTransform bar, float dt, float min, float max)
	{
		float y = bar.anchoredPosition.y;
		y += dt * BarMoveSpeed;
		if (y > max)
		{
			y = max;
		}
		if (y < min)
		{
			y = min;
		}
		bar.anchoredPosition = new Vector3(bar.anchoredPosition.x, y);
	}

	public void FadeIn()
	{
		currFadeDelay = fadeDelay;
		fadeState = FadeState.Hiding;
		fader.gameObject.SetActive(value: true);
		fader.color = new Color(0f, 0f, 0f, 1f);
	}

	public void ShowBars(bool show)
	{
		if (show)
		{
			barState = BarState.Showing;
			MiniMapUI.inst.gameObject.SetActive(value: false);
			GameUI.inst.ClearUIForCinematics();
			GameUI.inst.AbortCursorObjPlacement();
		}
		else
		{
			barState = BarState.Hiding;
		}
	}

	public bool IsCinematicRunning()
	{
		if (barState == BarState.IdleHiding)
		{
			return !IsTextDone();
		}
		return true;
	}

	private void Update()
	{
		float num = Time.unscaledDeltaTime;
		if (num > 0.1f)
		{
			num = 0.1f;
		}
		switch (barState)
		{
		case BarState.Showing:
			MoveBar(topBar, 0f - num, 0f, topBar.sizeDelta.y);
			MoveBar(bottomBar, num, 0f - topBar.sizeDelta.y, 0f);
			if (topBar.anchoredPosition.y <= 0f)
			{
				barState = BarState.IdleShowing;
			}
			break;
		case BarState.Hiding:
			MoveBar(topBar, num, 0f, topBar.sizeDelta.y);
			MoveBar(bottomBar, 0f - num, 0f - topBar.sizeDelta.y, 0f);
			if (topBar.anchoredPosition.y >= topBar.sizeDelta.y)
			{
				barState = BarState.IdleHiding;
				MiniMapUI.inst.gameObject.SetActive(value: true);
			}
			break;
		case BarState.IdleShowing:
			if (textTMP.gameObject.activeInHierarchy)
			{
				clickToContinueTimer += num;
				if (clickToContinueTimer > 5f)
				{
					clickToContinueTxt.SetActive(value: true);
				}
			}
			break;
		}
		FadeState fadeState = this.fadeState;
		if (fadeState != FadeState.Hiding)
		{
			_ = 2;
			return;
		}
		currFadeDelay -= num;
		if (currFadeDelay < 0f)
		{
			Color color = fader.color;
			color.a = Mathf.Clamp(color.a - num * fadeInSpeed, 0f, 1f);
			fader.color = color;
			if (color.a <= 0f)
			{
				fader.gameObject.SetActive(value: false);
				this.fadeState = FadeState.IdleHiding;
			}
		}
	}

	public int GetCurrTextIdx()
	{
		return introDialogueIdx;
	}

	internal void SetTextList(List<string> terms)
	{
		narrationTerms = terms;
		introDialogueIdx = 0;
		OnLineStart?.Invoke(introDialogueIdx);
		textTMP.text = LocalizationManager.GetTranslation(narrationTerms[introDialogueIdx]);
		textTMP.transform.parent.gameObject.SetActive(value: true);
		clickToContinueTimer = 0f;
	}

	public bool IsTextDone()
	{
		if (narrationTerms != null)
		{
			return introDialogueIdx >= narrationTerms.Count;
		}
		return true;
	}

	public void OnContinueText()
	{
		clickToContinueTxt.SetActive(value: false);
		clickToContinueTimer = 0f;
		introDialogueIdx++;
		if (introDialogueIdx < narrationTerms.Count)
		{
			OnLineStart?.Invoke(introDialogueIdx);
			textTMP.text = LocalizationManager.GetTranslation(narrationTerms[introDialogueIdx]);
		}
		else
		{
			textTMP.transform.parent.gameObject.SetActive(value: false);
		}
	}
}
