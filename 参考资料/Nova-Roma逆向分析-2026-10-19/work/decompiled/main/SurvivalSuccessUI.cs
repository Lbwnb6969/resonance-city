using UnityEngine;

public class SurvivalSuccessUI : MonoBehaviour
{
	public ParticleSystem ps1;

	public ParticleSystem ps2;

	private float lastTime;

	private Timer popSoundTimer = new Timer(1f);

	public RectTransform rect;

	public Transform model;

	private float scaleInTime;

	public void Show()
	{
		gameObject.SetActive(value: true);
		rect.localScale = Vector3.zero;
		popSoundTimer.Reset();
		popSoundTimer.CurrTime = 0.2f;
		scaleInTime = 0f;
		ScaleIn();
	}

	private void ScaleIn()
	{
		GameUI.inst.ClearCellSelected();
		lastTime = Time.realtimeSinceStartup;
		ps1.Simulate(0f, withChildren: true, restart: true);
		ps2.Simulate(0f, withChildren: true, restart: true);
	}

	public void OnClickButton()
	{
		SfxSystem.PlayUiSelect();
		gameObject.SetActive(value: false);
		ps1.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
		ps2.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
	}

	private void Update()
	{
		scaleInTime += Time.unscaledDeltaTime * 6f;
		if (scaleInTime > 1f)
		{
			scaleInTime = 1f;
		}
		float num = GameUI.inst.scaleInCurve.Evaluate(scaleInTime);
		rect.localScale = new Vector3(num, num, num);
		if (scaleInTime >= 1f)
		{
			float t = Time.realtimeSinceStartup - lastTime;
			ps1.Simulate(t, withChildren: false, restart: false);
			ps2.Simulate(t, withChildren: false, restart: false);
			lastTime = Time.realtimeSinceStartup;
			if (popSoundTimer.Update(Time.unscaledDeltaTime))
			{
				ps1.Stop();
				ps2.Stop();
			}
		}
		model.Rotate(0f, Time.unscaledDeltaTime * 90f, 0f);
	}
}
