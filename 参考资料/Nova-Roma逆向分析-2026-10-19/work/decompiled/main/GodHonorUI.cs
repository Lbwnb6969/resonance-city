using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GodHonorUI : InfoButton
{
	public GameObject honorDisplayPrefab;

	public GameObject honorDisplayContainer;

	public GameObject unhappyWarning;

	public GameObject veryUnhappyWarning;

	public GameObject warningExclamation;

	public TextMeshProUGUI happinessTextUI;

	public static GodHonorUI inst;

	public Texture[] textures;

	public Color unhappyColor = new Color(1f, 0.93f, 0.19f, 1f);

	public Color veryUnhappyColor = new Color(1f, 0.2f, 0f, 1f);

	private int lastHonorValue = -1;

	public GameObject lockOverlay;

	private void Start()
	{
		inst = this;
		for (int i = 1; i < GodManager.numGods; i++)
		{
			GameObject gameObject = Object.Instantiate(honorDisplayPrefab);
			gameObject.transform.SetParent(honorDisplayContainer.transform, worldPositionStays: true);
			gameObject.transform.localScale = new Vector3(1f, 1f, 1f);
		}
	}

	public Sprite GetTextureForHonor(Player.GodStanding standing)
	{
		return standing switch
		{
			Player.GodStanding.VeryUnhappy => HappinessUI.inst.veryUnhappy, 
			Player.GodStanding.Unhappy => HappinessUI.inst.unhappy, 
			Player.GodStanding.Happy => HappinessUI.inst.happy, 
			Player.GodStanding.VeryHappy => HappinessUI.inst.veryHappy, 
			_ => HappinessUI.inst.neutral, 
		};
	}

	public override void UpdateInternal()
	{
		Player.GodHonorInfo[] godHonor = Player.inst.PlayerLandmassOwner.godHonor;
		if (godHonor != null && Player.inst.FocusedLandMass != -1 && !lockOverlay.activeSelf)
		{
			Player.GodStanding godStanding = Player.GodStanding.Neutral;
			Player.GodStanding godStanding2 = Player.GodStanding.VeryHappy;
			int num = -1;
			float num2 = 0f;
			for (int i = 0; i < godHonor.Length; i++)
			{
				Transform child = honorDisplayContainer.transform.GetChild(i);
				Slider component = child.transform.GetChild(0).GetComponent<Slider>();
				component.value = (float)godHonor[i].honor / (float)Player.inst.GodHonorMax;
				num2 += component.value * 100f;
				Localize component2 = child.transform.GetChild(1).GetComponent<Localize>();
				GodInfoUI component3 = GodUI.inst.godDisplay.gods[i].GetComponent<GodInfoUI>();
				if (component2.Term != component3.GetLocalizedName())
				{
					component2.Term = component3.GetLocalizedName();
				}
				Player.GodStanding standing = godHonor[i].GetStanding(Player.inst.PlayerLandmassOwner);
				child.transform.GetChild(2).GetComponent<Image>().sprite = GetTextureForHonor(standing);
				if (standing < godStanding)
				{
					godStanding = standing;
				}
				if (godHonor[i].templeNotStaffed && standing < godStanding2)
				{
					godStanding2 = standing;
					num = i;
				}
				Util.SetActive(child.transform.GetChild(3), standing == Player.GodStanding.Unhappy || standing == Player.GodStanding.Unhappy);
				if (godStanding == Player.GodStanding.Unhappy)
				{
					child.transform.GetChild(3).GetComponent<Image>().color = unhappyColor;
				}
				else
				{
					child.transform.GetChild(3).GetComponent<Image>().color = veryUnhappyColor;
				}
			}
			num2 /= (float)godHonor.Length;
			if ((int)num2 != lastHonorValue)
			{
				happinessTextUI.text = string.Format("<color={1}>{0}</color>", (int)num2, HappinessUI.GetColor((int)num2));
				UpdateSlider((int)num2);
			}
			lastHonorValue = (int)num2;
			if (num != -1)
			{
				GodInfoUI component4 = GodUI.inst.godDisplay.gods[num].GetComponent<GodInfoUI>();
				unhappyWarning.transform.GetChild(0).GetComponent<TextMeshProUGUI>().SetText(string.Format(ScriptLocalization.godhonorui_templesnotstaffed, LocalizationManager.GetTranslation(component4.GetLocalizedName())));
			}
			Util.SetActive(unhappyWarning, num != -1);
			Util.SetActive(veryUnhappyWarning, godStanding == Player.GodStanding.VeryUnhappy);
			Util.SetActive(warningExclamation, godStanding == Player.GodStanding.VeryUnhappy || godStanding == Player.GodStanding.Unhappy);
			if (godStanding == Player.GodStanding.Unhappy)
			{
				warningExclamation.GetComponent<Image>().color = unhappyColor;
			}
			if (godStanding == Player.GodStanding.VeryUnhappy)
			{
				warningExclamation.GetComponent<Image>().color = veryUnhappyColor;
			}
		}
		else
		{
			enterCount = 0;
		}
	}
}
