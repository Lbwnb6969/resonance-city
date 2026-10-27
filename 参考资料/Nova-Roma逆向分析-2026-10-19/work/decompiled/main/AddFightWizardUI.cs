using System.Collections.Generic;
using FMODUnity;
using I2.Loc;
using UnityEngine;
using UnityEngine.UI;

public class AddFightWizardUI : MonoBehaviour
{
	public enum State
	{
		GladiatorSelect,
		OpponentSelect
	}

	public class GladiatorEntry
	{
		public GameObject visuals;

		public Gladiator gladiator;

		public BeastTemplate beast;
	}

	[Header("Steps")]
	public GameObject step2_SelectGladiator;

	public GameObject step3_SelectOpponent;

	[Header("Step 2 - Gladiator Selection")]
	public GameObject gladiatorSelectPrefab;

	public Image step2pulse;

	[Header("Step 3 - Opponent Selection")]
	public GameObject opponentGladiatorPanel;

	public GameObject opponentBeastPanel;

	public Image step3pulse;

	[Header("Navigation")]
	public Button backButton;

	public Button confirmButton;

	public Button cancelButton;

	public GladiatorSelectItemUI gladiatorInfo;

	internal Colosseum currentColosseum;

	internal ColosseumEvent currEvent;

	internal int currRoundIdx;

	internal bool roleSelect;

	internal State currentStep;

	internal List<GladiatorEntry> gladiatorVisuals = new List<GladiatorEntry>();

	public GameObject gladiatorPrefab;

	private float totalTime;

	public float gladiatorFramingOffsetZ = -0.75f;

	public float gladiatorFramingOffsetX = 0.5f;

	public GameObject roleSelectContainer;

	private void Awake()
	{
		backButton.onClick.AddListener(OnBackClicked);
		confirmButton.onClick.AddListener(OnConfirmClicked);
		cancelButton.onClick.AddListener(OnCancelClicked);
		step2_SelectGladiator.SetActive(value: false);
		step3_SelectOpponent.SetActive(value: false);
		opponentGladiatorPanel.SetActive(value: false);
		opponentBeastPanel.SetActive(value: false);
		backButton.gameObject.SetActive(value: false);
		confirmButton.gameObject.SetActive(value: false);
		gameObject.SetActive(value: false);
		roleSelect = false;
	}

	public void Show(Colosseum colosseum, ColosseumEvent colosseumEvent, int roundIndex)
	{
		currentColosseum = colosseum;
		currEvent = colosseumEvent;
		currRoundIdx = roundIndex;
		currentColosseum.ClearRound(currRoundIdx);
		gameObject.SetActive(value: true);
		ShowStep(State.GladiatorSelect);
	}

	public void Hide()
	{
		gameObject.SetActive(value: false);
		currentColosseum = null;
		currEvent = null;
		roleSelect = false;
		gladiatorInfo.gameObject.SetActive(value: false);
	}

	public void PopulateGladiatorInfo(GladiatorEntry entry)
	{
		if (entry.gladiator != null)
		{
			gladiatorInfo.SetData(entry.gladiator);
		}
		else if (entry.beast != null)
		{
			gladiatorInfo.SetData(entry.beast);
		}
	}

	public void Update()
	{
		FrameCamera();
		for (int i = 0; i < gladiatorVisuals.Count; i++)
		{
			FaceCamera(gladiatorVisuals[i].visuals);
			if (currEvent.rounds[currRoundIdx].combatant1Id == gladiatorVisuals[i].gladiator?.gladiatorId || currEvent.rounds[currRoundIdx].opponentId == gladiatorVisuals[i].gladiator?.gladiatorId)
			{
				gladiatorVisuals[i].visuals.GetComponent<GladiatorVisual>().highlight.SetOutlineImmediate(1);
			}
		}
		totalTime += Time.unscaledDeltaTime;
		Color color = step2pulse.color;
		if (currentStep == State.GladiatorSelect)
		{
			color.a = Mathf.Lerp(0.2f, 0.5f, (Mathf.Sin(totalTime * 1.5f) + 1f) * 0.5f);
		}
		else
		{
			color.a = 0f;
		}
		step2pulse.color = color;
		Color color2 = step3pulse.color;
		if (currentStep == State.OpponentSelect)
		{
			color2.a = Mathf.Lerp(0.2f, 0.5f, (Mathf.Sin(totalTime * 1.5f) + 1f) * 0.5f);
		}
		else
		{
			color2.a = 0f;
		}
		step3pulse.color = color2;
	}

	private void FrameCamera()
	{
		Vector3 desiredTrackingPos = currentColosseum.GetComponent<Building>().Center();
		float num = 0f;
		for (int i = 1; i < ColosseumPlannerUI.inst.roundSlots.Count; i++)
		{
			if (ColosseumPlannerUI.inst.roundSlots[i].isActiveAndEnabled)
			{
				num += -0.25f;
			}
		}
		desiredTrackingPos += Cam.inst.cam.transform.forward.xz() * (gladiatorFramingOffsetZ + (roleSelect ? (-0.5f) : 0f)) + Cam.inst.cam.transform.right.xz() * (gladiatorFramingOffsetX + num);
		Cam.inst.SetDesiredTrackingPos(desiredTrackingPos);
		float desiredDist = (roleSelect ? 3.9f : 5f);
		Cam.inst.desiredPhi = 65f;
		Cam.inst.desiredDist = desiredDist;
		Vector3 vector = currentColosseum.GetComponent<Building>().GetOffset().right.xz();
		float desiredTheta = Mathf.Atan2(0f - vector.z, vector.x) * 57.29578f;
		Cam.inst.desiredTheta = desiredTheta;
	}

	private static void FaceCamera(GameObject visual)
	{
		visual.transform.rotation = Quaternion.LookRotation((Cam.inst.DesiredCamPos - visual.transform.position).xz());
	}

	private void SetRole(ColosseumRound.Role role)
	{
		for (int i = 0; i < gladiatorVisuals.Count; i++)
		{
			if (gladiatorVisuals[i].gladiator != null)
			{
				if (currentStep == State.GladiatorSelect && gladiatorVisuals[i].gladiator.gladiatorId == currEvent.rounds[currRoundIdx].combatant1Id)
				{
					currEvent.rounds[currRoundIdx].combatant1role = role;
					gladiatorVisuals[i].visuals.GetComponent<GladiatorVisual>().SetRole(role);
				}
				else if (currentStep == State.OpponentSelect && gladiatorVisuals[i].gladiator.gladiatorId == currEvent.rounds[currRoundIdx].opponentId)
				{
					currEvent.rounds[currRoundIdx].opponentrole = role;
					gladiatorVisuals[i].visuals.GetComponent<GladiatorVisual>().SetRole(role);
				}
			}
		}
		gladiatorInfo.SetRole(role);
	}

	public void OnPointerEnterSecutor()
	{
		SetRole(ColosseumRound.Role.Secutor);
	}

	public void OnPointerEnterRetiarus()
	{
		SetRole(ColosseumRound.Role.Retiarus);
	}

	public void OnPointerEnterBestiarus()
	{
		SetRole(ColosseumRound.Role.Bestiarius);
	}

	public void OnPointerExit()
	{
		SetRole(ColosseumRound.Role.None);
	}

	private void ShowStep(State step)
	{
		currentStep = step;
		roleSelect = false;
		roleSelectContainer.SetActive(value: false);
		step2_SelectGladiator.SetActive(step == State.GladiatorSelect);
		step3_SelectOpponent.SetActive(step == State.OpponentSelect);
		gladiatorInfo.gameObject.SetActive(step switch
		{
			State.OpponentSelect => GetFightType() != ColosseumFightType.GladiatorVsBeasts, 
			State.GladiatorSelect => true, 
			_ => false, 
		});
		backButton.gameObject.SetActive(step > State.GladiatorSelect);
		confirmButton.gameObject.SetActive(step == State.OpponentSelect && GetFightType() == ColosseumFightType.GladiatorVsBeasts);
		FrameCamera();
		switch (step)
		{
		case State.GladiatorSelect:
			PopulateGladiators();
			break;
		case State.OpponentSelect:
			opponentGladiatorPanel.SetActive(value: true);
			PopulateBeasts();
			break;
		}
		SetBeastsVisible(step == State.OpponentSelect);
	}

	private void SetBeastsVisible(bool visible)
	{
		for (int i = 0; i < gladiatorVisuals.Count; i++)
		{
			if (gladiatorVisuals[i].beast != null)
			{
				gladiatorVisuals[i].visuals.SetActive(visible);
			}
		}
	}

	private ColosseumFightType GetFightType()
	{
		return currEvent.rounds[currRoundIdx].fightType;
	}

	internal void ClearGladiatorVisuals()
	{
		for (int i = 0; i < gladiatorVisuals.Count; i++)
		{
			Object.Destroy(gladiatorVisuals[i].visuals);
		}
		gladiatorVisuals.Clear();
	}

	private bool HasSpawnedGladiators()
	{
		for (int i = 0; i < gladiatorVisuals.Count; i++)
		{
			if (gladiatorVisuals[i].gladiator != null)
			{
				return true;
			}
		}
		return false;
	}

	private bool HasSpawnedBeasts()
	{
		for (int i = 0; i < gladiatorVisuals.Count; i++)
		{
			if (gladiatorVisuals[i].beast != null)
			{
				return true;
			}
		}
		return false;
	}

	private void PopulateBeasts()
	{
		if (!HasSpawnedBeasts())
		{
			for (int i = 0; i < GladiatorSystem.inst.beastDefs.Count && i < currentColosseum.animalPositionContainer.childCount; i++)
			{
				BeastTemplate beastTemplate = GladiatorSystem.inst.beastDefs[i];
				GameObject gameObject = Object.Instantiate(beastTemplate.mesh, Vector3.zero, Quaternion.identity);
				gameObject.transform.position = currentColosseum.animalPositionContainer.GetChild(i).position;
				FaceCamera(gameObject);
				gladiatorVisuals.Add(new GladiatorEntry
				{
					beast = beastTemplate,
					visuals = gameObject
				});
				EffectsMan.inst.BuildEffectPuffSmall.CreateAndPlay(gameObject.transform.position);
			}
		}
	}

	private void PopulateGladiators()
	{
		if (HasSpawnedGladiators())
		{
			return;
		}
		IEnumerable<Gladiator> enumerable = GladiatorSystem.inst?.GetAllGladiators();
		int num = 0;
		foreach (Gladiator item in enumerable)
		{
			if (num >= currentColosseum.gladiatorPositionContainer.childCount)
			{
				break;
			}
			GameObject gameObject = Object.Instantiate(gladiatorPrefab, currentColosseum.transform);
			gameObject.SetActive(value: true);
			gameObject.transform.position = currentColosseum.gladiatorPositionContainer.GetChild(num).position;
			if (item.visualDef == null)
			{
				item.visualDef = gameObject.GetComponent<GladiatorVisual>().GenerateDef();
			}
			gameObject.GetComponent<GladiatorVisual>().ApplyDef(item.visualDef);
			FaceCamera(gameObject);
			gladiatorVisuals.Add(new GladiatorEntry
			{
				gladiator = item,
				visuals = gameObject
			});
			EffectsMan.inst.BuildEffectPuffSmall.CreateAndPlay(gameObject.transform.position);
			num++;
		}
	}

	public void OnPickedSecutor()
	{
		ConfirmRole();
	}

	private void ConfirmRole()
	{
		RuntimeManager.PlayOneShot("event:/OldSFX/MoveToGeneral");
		roleSelectContainer.SetActive(value: false);
		int num = ((currentStep == State.GladiatorSelect) ? currEvent.rounds[currRoundIdx].combatant1Id : currEvent.rounds[currRoundIdx].opponentId);
		for (int i = 0; i < gladiatorVisuals.Count; i++)
		{
			Gladiator gladiator = gladiatorVisuals[i].gladiator;
			if (gladiator != null && gladiator.gladiatorId == num)
			{
				EffectsMan.inst.ChariotSponsorEffect.CreateAndPlay(gladiatorVisuals[i].visuals.transform.position).UseRealtime = true;
				break;
			}
		}
		if (currentStep == State.GladiatorSelect)
		{
			ShowStep(State.OpponentSelect);
		}
		else if (currentStep == State.OpponentSelect)
		{
			ConfirmFight();
		}
	}

	public void OnPickedRetiarius()
	{
		ConfirmRole();
	}

	public void OnPickedBeastarius()
	{
		ConfirmRole();
	}

	public void OnGladiatorSelected(Gladiator gladiator)
	{
		SfxSystem.PlayUiSelect();
		if (currentStep == State.GladiatorSelect)
		{
			currEvent.rounds[currRoundIdx].combatant1Id = gladiator.gladiatorId;
		}
		else if (currentStep == State.OpponentSelect)
		{
			currEvent.rounds[currRoundIdx].opponentId = gladiator.gladiatorId;
			currEvent.rounds[currRoundIdx].opponentType = OpponentType.School;
		}
		roleSelect = true;
		roleSelectContainer.SetActive(value: true);
		gladiatorInfo.gladiatorRole.SetActive(value: true);
		gladiatorInfo.gladiatorInfo.SetActive(value: false);
		if (currentStep == State.GladiatorSelect)
		{
			step2_SelectGladiator.SetActive(value: false);
		}
		else
		{
			opponentGladiatorPanel.SetActive(value: false);
		}
	}

	public void OnBeastSelected(BeastTemplate beast)
	{
		SfxSystem.PlayUiSelect();
		currEvent.rounds[currRoundIdx].opponentType = OpponentType.Beast;
		currEvent.rounds[currRoundIdx].beastType = beast.templateId;
		currEvent.rounds[currRoundIdx].beastCount = 1;
		ConfirmFight();
	}

	public void OnBackClicked()
	{
		if (roleSelect)
		{
			if (currentStep == State.OpponentSelect)
			{
				currEvent.rounds[currRoundIdx].opponentId = -1;
			}
			if (currentStep == State.GladiatorSelect)
			{
				currEvent.rounds[currRoundIdx].combatant1Id = -1;
			}
			ShowStep(currentStep);
		}
		if (currentStep == State.OpponentSelect)
		{
			SfxSystem.PlayUiSelect();
			currEvent.rounds[currRoundIdx].combatant1Id = -1;
			currEvent.rounds[currRoundIdx].opponentId = -1;
			currEvent.rounds[currRoundIdx].beastCount = 0;
			currEvent.rounds[currRoundIdx].beastType = null;
			currEvent.rounds[currRoundIdx].fightType = ColosseumFightType.GladiatorVsGladiator;
			ShowStep(State.GladiatorSelect);
		}
	}

	private void OnConfirmClicked()
	{
		SfxSystem.PlayUiSelect();
		ConfirmFight();
	}

	private void ConfirmFight()
	{
		if (currEvent.rounds[currRoundIdx].opponentId != -1)
		{
			currEvent.rounds[currRoundIdx].fightType = ColosseumFightType.GladiatorVsGladiator;
		}
		else
		{
			currEvent.rounds[currRoundIdx].fightType = ColosseumFightType.GladiatorVsBeasts;
		}
		currEvent.rounds[currRoundIdx].state = RoundState.Planned;
		currentColosseum.RecalculateAllPreviews();
		gladiatorInfo.gameObject.SetActive(value: false);
		for (int i = 0; i < gladiatorVisuals.Count; i++)
		{
			if (gladiatorVisuals[i].gladiator != null)
			{
				gladiatorVisuals[i].visuals.GetComponent<GladiatorVisual>().SetRole(ColosseumRound.Role.None);
			}
		}
		if (currRoundIdx < 2)
		{
			ColosseumPlannerUI.inst.roundSlots[currRoundIdx + 1].gameObject.SetActive(value: true);
		}
		Hide();
	}

	private void OnCancelClicked()
	{
		SfxSystem.PlayUiSelect();
		Hide();
	}

	internal string GetTitleText()
	{
		if (currentStep == State.GladiatorSelect)
		{
			return LocalizationManager.GetTranslation("fight_wizard_choose_gladiator");
		}
		if (currentStep == State.OpponentSelect)
		{
			if (GetFightType() == ColosseumFightType.GladiatorVsBeasts)
			{
				return LocalizationManager.GetTranslation("fight_wizard_choose_beasts");
			}
			if (GetFightType() == ColosseumFightType.GladiatorVsGladiator)
			{
				return LocalizationManager.GetTranslation("fight_wizard_choose_second");
			}
		}
		return null;
	}

	internal bool IsFighterAlreadyAssigned(int gladiatorId)
	{
		return currEvent.rounds[currRoundIdx].combatant1Id == gladiatorId;
	}
}
