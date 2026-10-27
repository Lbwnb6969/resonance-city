using I2.Loc;
using UnityEngine;

public class StaticTooltipHook : TooltipHook
{
	public delegate string OnLocalize(string key);

	[SerializeField]
	private string localizationKey = "<localization key>";

	public OnLocalize onLocalize;

	private void Start()
	{
		LocalizationManager.OnLocalizeEvent += UpdateText;
		UpdateText();
	}

	public void SetTerm(string term)
	{
		localizationKey = term;
		UpdateText();
	}

	public void UpdateText()
	{
		toolTipText = ((onLocalize != null) ? onLocalize(localizationKey) : LocalizationManager.GetTranslation(localizationKey));
	}
}
