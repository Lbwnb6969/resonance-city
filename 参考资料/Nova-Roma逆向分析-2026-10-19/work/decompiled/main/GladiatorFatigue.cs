using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class GladiatorFatigue : MonoBehaviour
{
	public Image[] dots;

	public TooltipHook tooltipHook;

	public void Awake()
	{
		dots = GetComponentsInChildren<Image>();
		tooltipHook = GetComponent<TooltipHook>();
	}

	public void SetFatigue(int level)
	{
		if (dots != null)
		{
			Color color = new Color(0.8f, 0.2f, 0.2f);
			Color color2 = new Color(0.3f, 0.3f, 0.3f);
			for (int i = 0; i < dots.Length; i++)
			{
				if (dots[i] != null)
				{
					dots[i].color = ((i < level) ? color : color2);
				}
			}
		}
		if (tooltipHook != null)
		{
			tooltipHook.tooltipTerm = string.Empty;
			tooltipHook.toolTipText = LocalizationManager.GetTranslation("gladiatorui_fatigue_label") + " " + GetFatigueLabel(level);
		}
	}

	private string GetFatigueLabel(int tier)
	{
		return tier switch
		{
			0 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fatigue_fresh")), 
			1 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fatigue_rested")), 
			2 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fatigue_worn")), 
			3 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fatigue_tired")), 
			4 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fatigue_exhausted")), 
			5 => wrap(tier, LocalizationManager.GetTranslation("gladiator_fatigue_spent")), 
			_ => "", 
		};
		static string wrap(int index, string txt)
		{
			return index switch
			{
				0 => "<color=#5EC45E>" + txt + "</color>", 
				1 => "<color=#8EBF4A>" + txt + "</color>", 
				2 => "<color=#C4B94A>" + txt + "</color>", 
				3 => "<color=#C4884A>" + txt + "</color>", 
				4 => "<color=#C45E3A>" + txt + "</color>", 
				5 => "<color=#C43A3A>" + txt + "</color>", 
				_ => txt, 
			};
		}
	}
}
