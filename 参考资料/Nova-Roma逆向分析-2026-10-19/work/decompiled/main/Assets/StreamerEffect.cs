using System;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Assets;

public abstract class StreamerEffect : MonoBehaviour
{
	protected Image Icon;

	protected Localize NameText;

	protected TextMeshProUGUI TimerText;

	protected Timer Timer = new Timer(0f);

	private bool manualDone;

	private string pendingTerm;

	public static bool PrereqSatisfied()
	{
		return true;
	}

	public static string GetTermSegment()
	{
		return "";
	}

	private void Start()
	{
		Transform transform = base.transform.Find("IconImage");
		Icon = transform.GetComponent<Image>();
		Transform transform2 = base.transform.Find("Name");
		NameText = transform2.GetComponent<Localize>();
		if (!string.IsNullOrEmpty(pendingTerm))
		{
			NameText.Term = pendingTerm;
		}
		Transform transform3 = base.transform.Find("Timer");
		TimerText = transform3.GetComponent<TextMeshProUGUI>();
		OnStart();
	}

	private void OnDestroy()
	{
		OnEnd();
	}

	private void Update()
	{
		if ((Timer != null && Timer.Update(Time.unscaledDeltaTime)) || manualDone)
		{
			UnityEngine.Object.Destroy(gameObject);
			return;
		}
		if (Timer != null)
		{
			TimeSpan timeSpan = TimeSpan.FromSeconds(Timer.Duration - Timer.CurrTime);
			TimerText.SetText("{0:00}:{1:00}", timeSpan.Minutes, timeSpan.Seconds);
		}
		OnUpdate();
	}

	public void Done()
	{
		manualDone = true;
	}

	public float TimeRemaining()
	{
		return Timer.Duration - Timer.CurrTime;
	}

	public void SetTerm(string term)
	{
		if (NameText == null)
		{
			pendingTerm = term;
		}
		else
		{
			NameText.Term = term;
		}
	}

	public abstract void OnStart();

	public abstract void OnEnd();

	public virtual void OnUpdate()
	{
	}
}
