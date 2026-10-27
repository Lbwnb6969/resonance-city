using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class CombatantInfoUI : MonoBehaviour
{
	[Header("Identity")]
	public TextMeshProUGUI nameText;

	public GladiatorFame fame;

	[Header("Status")]
	public GladiatorFatigue fatigue;

	[Header("Combat Stats")]
	public GameObject deathContainer;

	public TooltipHook deathTooltip;

	public TextMeshProUGUI riskLevelText;

	public void SetGladiator(Gladiator gladiator, float deathChance, float baseChance = 0f, float skillMod = 0f, float fatigueMod = 0f, int projectedFatigueTier = -1)
	{
		gameObject.SetActive(value: true);
		nameText.text = gladiator.name;
		fame.SetFame(gladiator.fame);
		int num = ((projectedFatigueTier >= 0) ? projectedFatigueTier : gladiator.fatigueTier);
		if (fatigue != null)
		{
			fatigue.SetFatigue(num);
		}
		deathContainer.SetActive(value: true);
		if (deathTooltip != null)
		{
			int num2 = Mathf.RoundToInt(baseChance * 100f);
			int num3 = Mathf.RoundToInt(skillMod * 100f);
			int num4 = Mathf.RoundToInt(fatigueMod * 100f);
			string text = ((num3 >= 0) ? "+" : "");
			deathTooltip.toolTipText = string.Format(LocalizationManager.GetTranslation("combatant_death_breakdown"), num2, text + num3, num4);
		}
		UpdateRiskLevel(deathChance);
	}

	public void SetBeast(string beastType, int count)
	{
		gameObject.SetActive(value: true);
		string localizedName = GladiatorSystem.inst.GetBeastDefByName(beastType).GetLocalizedName();
		nameText.text = ((count > 1) ? string.Format(LocalizationManager.GetTranslation("combatant_beast_plural"), count, localizedName) : string.Format(LocalizationManager.GetTranslation("combatant_beast_singular"), localizedName));
		if (fame != null && fame.stars != null)
		{
			Image[] stars = fame.stars;
			foreach (Image image in stars)
			{
				if (image != null)
				{
					image.gameObject.SetActive(value: false);
				}
			}
		}
		HideFatigue();
		SetAllStatsVisible(v: false);
	}

	public void SetEmpty()
	{
		gameObject.SetActive(value: false);
	}

	public void SetAllStatsVisible(bool v)
	{
		deathContainer.SetActive(v);
		riskLevelText.gameObject.SetActive(v);
	}

	private void HideFatigue()
	{
		if (fatigue == null || fatigue.dots == null)
		{
			return;
		}
		Image[] dots = fatigue.dots;
		foreach (Image image in dots)
		{
			if (image != null)
			{
				image.gameObject.SetActive(value: false);
			}
		}
	}

	private void UpdateRiskLevel(float deathChance)
	{
		if (!(riskLevelText == null))
		{
			riskLevelText.gameObject.SetActive(value: true);
			string translation;
			Color color;
			if (deathChance <= 0.1f)
			{
				translation = LocalizationManager.GetTranslation("magnitude_low");
				color = new Color(0.5f, 0.8f, 0.34f);
			}
			else if (deathChance <= 0.25f)
			{
				translation = LocalizationManager.GetTranslation("magnitude_medium");
				color = new Color(0.9f, 0.7f, 0.2f);
			}
			else
			{
				translation = LocalizationManager.GetTranslation("magnitude_high");
				color = new Color(1f, 0.45f, 0.45f);
			}
			riskLevelText.text = translation;
			riskLevelText.color = color;
		}
	}
}
