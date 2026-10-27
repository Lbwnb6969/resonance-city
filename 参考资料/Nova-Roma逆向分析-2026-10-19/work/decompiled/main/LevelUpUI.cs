using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class LevelUpUI : MonoBehaviour
{
	public TextMeshProUGUI yourCity;

	public TextMeshProUGUI title;

	public TextMeshProUGUI description;

	public Button button;

	public ParticleSystem ps1;

	public ParticleSystem ps2;

	public ConsoleUIItem consoleEntry;

	private float lastTime;

	private Timer showUITimer = new Timer(1.9f);

	private Timer popSoundTimer = new Timer(1f);

	private RectTransform rect;

	private bool showing;

	private float scaleInTime;

	private void Start()
	{
		button.onClick.AddListener(OnClickButton);
	}

	public void Show(string cityName, string title, string description)
	{
		gameObject.SetActive(value: true);
		rect = GetComponent<RectTransform>();
		rect.localScale = Vector3.zero;
		showing = false;
		yourCity.text = string.Format("ScriptLocalization.LevelupUICityIsNow", cityName);
		this.title.text = title;
		this.description.text = description;
		MusicSystem.inst.PlayLevelUpMotif();
		popSoundTimer.Reset();
		popSoundTimer.CurrTime = 0.2f;
		showUITimer.Enabled = true;
		showUITimer.Reset();
		scaleInTime = 0f;
	}

	public void OutpostShow()
	{
		Show("", "ScriptLocalization.OutpostCongratulations", "ScriptLocalization.OutpostCongratulations2");
		yourCity.text = "";
	}

	private void ScaleIn()
	{
		GameUI.inst.ClearCellSelected();
		lastTime = Time.realtimeSinceStartup;
		showing = true;
		ps1.Simulate(0f, withChildren: true, restart: true);
		ps2.Simulate(0f, withChildren: true, restart: true);
		if (GamepadControl.inst.isControllerActive)
		{
			consoleEntry.Hover();
		}
	}

	private void OnClickButton()
	{
		SfxSystem.PlayUiSelect();
		gameObject.SetActive(value: false);
		ps1.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
		ps2.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
		showing = false;
	}

	private void Update()
	{
		if (!showing)
		{
			if (showUITimer.Update(Time.unscaledDeltaTime))
			{
				ScaleIn();
			}
			return;
		}
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
			popSoundTimer.Update(Time.unscaledDeltaTime);
		}
	}
}
