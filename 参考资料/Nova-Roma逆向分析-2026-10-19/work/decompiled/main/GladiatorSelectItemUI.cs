using TMPro;
using UnityEngine;

public class GladiatorSelectItemUI : MonoBehaviour
{
	public TextMeshProUGUI nameText;

	public GladiatorFame fame;

	public GladiatorFatigue fatigue;

	public TextMeshProUGUI beastSkillsText;

	public TextMeshProUGUI secutorSkillsText;

	public TextMeshProUGUI retiariusSkillsText;

	public TextMeshProUGUI roleBeastSkillsText;

	public TextMeshProUGUI roleSecutorSkillsText;

	public TextMeshProUGUI roleRetiariusSkillsText;

	public GladiatorVisual gladiatorVisual;

	public GameObject beastVisual;

	public GameObject gladiatorInfo;

	public GameObject gladiatorRole;

	public TextMeshProUGUI instructions;

	private void Awake()
	{
	}

	public void SetData(Gladiator gladiator)
	{
		gladiatorInfo.SetActive(value: true);
		instructions.gameObject.SetActive(value: false);
		beastVisual.SetActive(value: false);
		if (gladiator.visualDef == null)
		{
			gladiator.visualDef = gladiatorVisual.GenerateDef();
		}
		gladiatorVisual.ApplyDef(gladiator.visualDef);
		gladiatorVisual.transform.localScale *= 500f;
		gladiatorVisual.gameObject.SetActive(value: true);
		nameText.text = gladiator.name;
		fame.SetFame(gladiator.fame);
		fatigue.SetFatigue(gladiator.fatigueTier);
		beastSkillsText.SetText("{0}", gladiator.skills.bestiarius);
		secutorSkillsText.SetText("{0}", gladiator.skills.secutor);
		retiariusSkillsText.SetText("{0}", gladiator.skills.retiarius);
		roleBeastSkillsText.SetText("{0}", gladiator.skills.bestiarius);
		roleSecutorSkillsText.SetText("{0}", gladiator.skills.secutor);
		roleRetiariusSkillsText.SetText("{0}", gladiator.skills.retiarius);
		SetSelected(selected: false);
	}

	public void SetData(BeastTemplate beast)
	{
		gladiatorInfo.SetActive(value: false);
		instructions.gameObject.SetActive(value: false);
		gladiatorVisual.gameObject.SetActive(value: false);
		beastVisual.SetActive(value: false);
		nameText.text = beast.GetLocalizedName();
		fame.SetFame(beast.tier);
		fatigue.SetFatigue(0);
		beastSkillsText.SetText("");
		secutorSkillsText.SetText("");
		retiariusSkillsText.SetText("");
	}

	public void ShowInstructions()
	{
		gladiatorInfo.SetActive(value: false);
		instructions.gameObject.SetActive(value: true);
		gladiatorVisual.gameObject.SetActive(value: false);
		beastVisual.SetActive(value: false);
		nameText.text = "Select From Arena";
		fame.SetFame(0);
		fatigue.SetFatigue(0);
		beastSkillsText.SetText("");
		secutorSkillsText.SetText("");
		retiariusSkillsText.SetText("");
	}

	public void SetSelected(bool selected)
	{
	}

	internal void SetRole(ColosseumRound.Role role)
	{
		gladiatorVisual.SetRole(role);
	}
}
