using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class GladiatorFame : MonoBehaviour
{
	public Image[] stars;

	public TooltipHook tooltipHook;

	public void Awake()
	{
		stars = GetComponentsInChildren<Image>();
		tooltipHook = GetComponent<TooltipHook>();
	}

	public void SetFame(int level)
	{
		if (stars != null)
		{
			Color yellow = Color.yellow;
			Color color = new Color(0.3f, 0.3f, 0.3f);
			for (int i = 0; i < stars.Length; i++)
			{
				if (stars[i] != null)
				{
					stars[i].color = ((i < level) ? yellow : color);
				}
			}
		}
		if (tooltipHook != null)
		{
			tooltipHook.tooltipTerm = string.Empty;
			tooltipHook.toolTipText = LocalizationManager.GetTranslation("gladiatorui_fame_label") + " " + GetFameLabel(level);
		}
	}

	private string GetFameLabel(int tier)
	{
		return tier switch
		{
			0 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fame_unknown")), 
			1 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fame_novice")), 
			2 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fame_rising")), 
			3 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fame_famous")), 
			4 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fame_renowned")), 
			5 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fame_legendary")), 
			_ => "", 
		};
		static string wrap(int index, string txt)
		{
			return index switch
			{
				0 => "<color=#808080>" + txt + "</color>", 
				1 => "<color=#A0825A>" + txt + "</color>", 
				2 => "<color=#C4A24A>" + txt + "</color>", 
				3 => "<color=#D4AF37>" + txt + "</color>", 
				4 => "<color=#FFD700>" + txt + "</color>", 
				5 => "<color=#FFE44D>" + txt + "</color>", 
				_ => txt, 
			};
		}
	}
}
