using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SaveGameLoadingScreen : MonoBehaviour
{
	private CanvasGroup canvasGroup;

	public TextMeshProUGUI descriptionText;

	public RawImage coverImage;

	public TextMeshProUGUI cityName;

	public TextMeshProUGUI cityPopulation;

	public TextMeshProUGUI cityYear;

	public TextMeshProUGUI cityResources;

	public static SaveGameLoadingScreen inst;

	private bool showing;

	public void Start()
	{
		inst = this;
		gameObject.SetActive(value: false);
	}

	public void Show(bool show, LoadSave.WorldSummaryData worldSummary = null, Texture2D cover = null)
	{
		showing = show;
		if (showing)
		{
			gameObject.SetActive(value: true);
			canvasGroup = GetComponent<CanvasGroup>();
			canvasGroup.alpha = 0f;
			canvasGroup.interactable = false;
			canvasGroup.blocksRaycasts = true;
			if (cover != null)
			{
				coverImage.texture = cover;
			}
			if (worldSummary != null)
			{
				cityName.text = worldSummary.CityName;
				if (cityName.text == string.Empty)
				{
					cityName.text = "A Beautiful City Name";
				}
				cityYear.SetText(ScriptLocalization.SaveLoadYear, worldSummary.Year);
				cityPopulation.SetText(ScriptLocalization.SaveLoadCitizens, worldSummary.Population);
			}
		}
		else if (!LoadSave.loadIntoMapSelect)
		{
			GameState.inst.SetNewMode(GameState.inst.playingMode);
			TimeManager.inst.PauseIfRaidInProgress();
		}
	}

	public void SetTerm(string term)
	{
		descriptionText.GetComponent<Localize>().Term = term;
	}

	private void Update()
	{
		if (showing)
		{
			canvasGroup.alpha = Mathff.Clamp01(canvasGroup.alpha + Time.unscaledDeltaTime * 2f);
		}
		else
		{
			canvasGroup.alpha = Mathff.Clamp01(canvasGroup.alpha + Time.unscaledDeltaTime * 2f * -1f);
		}
		if (!showing && canvasGroup.alpha <= 0f)
		{
			if (coverImage.texture != null && coverImage.texture is Texture2D)
			{
				Object.Destroy(coverImage.texture);
				coverImage.texture = null;
			}
			gameObject.SetActive(value: false);
		}
		if (coverImage != null && coverImage.texture != null)
		{
			float num = Mathf.Max(coverImage.transform.parent.GetComponent<RectTransform>().rect.width / 3840f, coverImage.transform.parent.GetComponent<RectTransform>().rect.height / 2160f);
			coverImage.transform.localScale = num * Vector3.one;
		}
	}
}
