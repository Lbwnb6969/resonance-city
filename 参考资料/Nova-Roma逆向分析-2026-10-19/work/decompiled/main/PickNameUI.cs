using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class PickNameUI : MonoBehaviour
{
	[SerializeField]
	public ChooseBannerUI bannerUI;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private TMP_InputField cityNameInput;

	[SerializeField]
	private Button backBtn;

	[SerializeField]
	private Button acceptBtn;

	[SerializeField]
	private RawImage bigBanner;

	public Sprite[] bannerTex;

	private bool isVisible;

	private string prevTitle = "";

	private void Start()
	{
		cityNameInput.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
			prevTitle = val;
		});
		cityNameInput.onEndEdit.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = true;
			string text = val.Trim();
			if (string.IsNullOrEmpty(text))
			{
				TownNameUI.inst.townName = prevTitle;
				cityNameInput.SetTextWithoutNotify(prevTitle);
			}
			else
			{
				TownNameUI.inst.townName = text;
				cityNameInput.SetTextWithoutNotify(text);
			}
		});
		backBtn.onClick.AddListener(() =>
		{
			DifficultyUI.inst.SetState(1);
			DifficultyUI.inst.SetReturnFunc(() =>
			{
				GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.NameAndBanner);
			});
			DifficultyUI.inst.SetExitFunc(null);
			GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.ChooseDifficulty);
		});
		acceptBtn.onClick.AddListener(() =>
		{
			GameState.inst.mainMenuMode.OnClickedAcceptNameBanner();
		});
	}

	public void SetVisibility(bool visible)
	{
		if (!isVisible & visible)
		{
			cityNameInput.text = LocalizationManager.GetTranslation("CityNamePreset" + SRand.Range(1, 19));
			if (TownNameUI.inst != null)
			{
				TownNameUI.inst.SetTownNameQuiet(cityNameInput.text);
			}
			OnUpdateBanner(bannerTex[0].texture);
			Player.inst.SetIndexedBanner(0);
		}
		if (isVisible != visible)
		{
			Util.SetEnabled(canvas, visible);
			gRaycaster.enabled = visible;
		}
		isVisible = visible;
	}

	public void ClickBanner()
	{
		bannerUI.Show(GetComponent<ConsoleUIItem>());
	}

	public void OnUpdateBanner(Texture2D bannerTexture)
	{
		bigBanner.texture = bannerTexture;
	}
}
