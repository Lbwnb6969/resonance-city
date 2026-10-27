using System;
using System.Runtime.Serialization;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class Colosseum : Tickable, IWorkerUIDisplay, IOutputInfo
{
	private class DownedCombatantState
	{
		public CombatantOutcome outcome;

		public Gladiator gladiator;
	}

	[Serializable]
	public class ColosseumSaveData : SaveClass<Colosseum, ColosseumSaveData>
	{
		public float volatilityValue;

		public ColosseumState state;

		public override ColosseumSaveData Pack(Colosseum obj)
		{
			volatilityValue = obj.volatilityValue;
			return this;
		}

		public override Colosseum Unpack(Colosseum obj)
		{
			obj.volatilityValue = volatilityValue;
			return obj;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			volatilityValue = 2f;
			state = ColosseumState.Idle;
		}
	}

	public Building b;

	private RadiusBonus radiusBonus;

	[SerializeField]
	private GameObject animObj;

	[Header("Event Settings")]
	[SerializeField]
	private int minRounds = 3;

	[SerializeField]
	private int maxRounds = 5;

	[Header("Presentation Timing")]
	[SerializeField]
	private float fightPresentationDuration = 2.5f;

	public Transform gladiatorPositionContainer;

	public Transform animalPositionContainer;

	public Transform foreignFighterPosition;

	private float presentationTimer;

	private float volatilityValue = 2f;

	private EventInstance eStateMusic;

	private ColosseumState state;

	private Cam.TransformCapture oldCam;

	private Vector3 ThumbsCamDir;

	private ColosseumEvent currentEvent;

	private ColosseumRound currentRound;

	private GladiatorFightResolver.FightResolutionResultSymmetric pendingSymmetricResult;

	private DownedCombatantState currentDownedCombatant;

	public ArenaFightManager arenaFightManager;

	private ColosseumCursorMode cursorMode;

	private Vector3 ThumbsCamPos;

	private Quaternion ThumbsCamRot;

	public float thumbsDecisionCamXZ = 1f;

	public float thumbsDecisionCamY = 1f;

	public float thumbsLookOffsetY = 0.5f;

	private float currThumbsDecisionCamY;

	private static string StateMusicPath(ColosseumState s)
	{
		switch (s)
		{
		case ColosseumState.Planning:
			return "event:/Music/Music_Coloseeum_Planning";
		case ColosseumState.Presenting:
			return "event:/Music/Music_Coloseeum_Presentation";
		case ColosseumState.FightAnimating:
			return "event:/Music/Music_Coloseeum_Battle";
		case ColosseumState.ThumbsDecision:
		case ColosseumState.RoundResult:
			return "event:/Music/Music_Coloseeum_Results";
		case ColosseumState.Summary:
			return "event:/Music/Music_Coloseeum_Conclusion";
		default:
			return null;
		}
	}

	private void SetState(ColosseumState newState)
	{
		bool flag = state == ColosseumState.Idle;
		bool flag2 = newState == ColosseumState.Idle;
		ColosseumState colosseumState = state;
		state = newState;
		if (flag != flag2)
		{
			if (animObj != null)
			{
				Util.SetActive(animObj, flag2);
			}
			if (!flag2)
			{
				GameUI.inst.SetCursorMode(GetCursorMode());
				MusicSystem.inst.StopMusic();
				oldCam = Cam.inst.CaptureCameraTransform();
			}
			else
			{
				GameUI.inst.ReturnToDefaultCursorMode();
				GameUI.SetUIForModalHelper(v: true);
				BespokeCelebratingCitizens.inst.Shutdown();
				Cam.inst.ApplyTransformCapture(oldCam);
			}
			Cam.inst.disableDrag = !flag2;
			Cam.inst.disableZoom = !flag2;
		}
		if (colosseumState == newState)
		{
			return;
		}
		if (newState == ColosseumState.Presenting && !BespokeCelebratingCitizens.inst.IsActive())
		{
			BespokeCelebratingCitizens.inst.Init(b);
		}
		string text = StateMusicPath(newState);
		if (text != StateMusicPath(colosseumState))
		{
			if (eStateMusic.isValid())
			{
				eStateMusic.stop(flag2 ? STOP_MODE.IMMEDIATE : STOP_MODE.ALLOWFADEOUT);
			}
			if (text != null)
			{
				eStateMusic = RuntimeManager.CreateInstance(text);
				eStateMusic.start();
				eStateMusic.release();
			}
		}
		if (newState == ColosseumState.FightAnimating)
		{
			ColosseumUI.inst.fightUI.ShowFight();
			Cinematics.inst.ShowBars(show: true);
			Cam.inst.desiredDist = 8f;
		}
		else if (colosseumState == ColosseumState.FightAnimating)
		{
			ColosseumUI.inst.fightUI.EndFight();
			Cinematics.inst.ShowBars(show: false);
		}
		if (colosseumState == ColosseumState.FightAnimating && (newState == ColosseumState.ThumbsDecision || newState == ColosseumState.RoundResult))
		{
			Vector3 averagePos = arenaFightManager.GetAveragePos();
			ThumbsCamDir = (Cam.inst.transform.position - averagePos).xz().normalized;
			if (Mathff.Dist(averagePos + ThumbsCamDir * thumbsDecisionCamXZ, b.Center()) > arenaFightManager.arenaRadius + 0.5f)
			{
				ThumbsCamDir *= -1f;
			}
			currThumbsDecisionCamY = thumbsDecisionCamY;
			Cam.inst.enabled = false;
		}
		if (colosseumState == ColosseumState.RoundResult)
		{
			Cam.inst.enabled = true;
		}
	}

	private ColosseumCursorMode GetCursorMode()
	{
		if (cursorMode == null)
		{
			cursorMode = new ColosseumCursorMode();
		}
		return cursorMode;
	}

	private void Awake()
	{
		arenaFightManager = GetComponent<ArenaFightManager>();
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		radiusBonus = GetComponent<RadiusBonus>();
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.Celebrate));
			}
		}
	}

	private void OnBuilt()
	{
		Util.SetActive(animObj, active: true);
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (undo)
		{
			Util.SetActive(animObj, active: false);
			if (!LoadSave.Loading)
			{
				CancelEvent();
			}
		}
		else if (b.IsBuilt())
		{
			Util.SetActive(animObj, active: true);
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (!b.IsBuilt() || !b.IsOpen())
		{
			return;
		}
		float num = Mathff.Clamp(Time.unscaledDeltaTime, 0f, 0.1f);
		if (state == ColosseumState.Presenting)
		{
			Cam.inst.desiredDist = 5f;
			Cam.inst.desiredPhi = 65f;
			Cam.inst.SetDesiredTrackingPos(b.Center());
			presentationTimer -= num;
			if (presentationTimer <= 0f)
			{
				arenaFightManager.StartFight(currentRound);
				SetState(ColosseumState.FightAnimating);
			}
		}
		else if (state == ColosseumState.FightAnimating)
		{
			Cam.inst.desiredDist -= num * 0.05f;
			if (Cam.inst.desiredDist < 5f)
			{
				Cam.inst.desiredDist = 5f;
			}
			Cam.inst.SetDesiredTrackingPos((arenaFightManager.GetAveragePos() + b.Center()) * 0.5f);
			arenaFightManager.TickFight(num);
			if (arenaFightManager.phase == ArenaFightManager.FightPhase.WaitingForThumbs)
			{
				OnFightAnimationComplete();
			}
		}
		else if (state == ColosseumState.ThumbsDecision || state == ColosseumState.RoundResult)
		{
			arenaFightManager.TickFight(num);
			Vector3 averagePos = arenaFightManager.GetAveragePos();
			currThumbsDecisionCamY += num * 0.05f;
			if (currThumbsDecisionCamY > 5f)
			{
				currThumbsDecisionCamY = 5f;
			}
			ThumbsCamPos = averagePos + ThumbsCamDir * thumbsDecisionCamXZ + new Vector3(0f, 1f, 0f) * currThumbsDecisionCamY;
			Vector3 vector = averagePos + new Vector3(0f, thumbsLookOffsetY, 0f);
			ThumbsCamRot = Quaternion.LookRotation(vector - ThumbsCamPos, Vector3.up);
			Cam.inst.transform.position = ThumbsCamPos;
			Cam.inst.transform.rotation = ThumbsCamRot;
		}
	}

	public int GetVolatilityTier()
	{
		if (volatilityValue <= 2f)
		{
			return 0;
		}
		if (volatilityValue <= 5f)
		{
			return 1;
		}
		if (volatilityValue <= 8f)
		{
			return 2;
		}
		return 3;
	}

	public string GetVolatilityLabel()
	{
		return GetVolatilityTier() switch
		{
			0 => LocalizationManager.GetTranslation("colosseum_volatility_calm"), 
			1 => LocalizationManager.GetTranslation("colosseum_volatility_agitated"), 
			2 => LocalizationManager.GetTranslation("colosseum_volatility_frenzied"), 
			3 => LocalizationManager.GetTranslation("colosseum_volatility_unhinged"), 
			_ => LocalizationManager.GetTranslation("colosseum_volatility_unknown"), 
		};
	}

	public void AddVolatility(float amount, string reason = null)
	{
		volatilityValue = Mathf.Clamp(volatilityValue + amount, 0f, 10f);
	}

	public void CoolVolatility(float amount, string reason = null)
	{
		volatilityValue = Mathf.Clamp(volatilityValue - amount, 0f, 10f);
	}

	public ColosseumState GetState()
	{
		return state;
	}

	public bool CanStartNewEvent()
	{
		if (b.IsBuilt() && b.IsOpen() && state == ColosseumState.Idle && GladiatorSystem.inst != null)
		{
			return GladiatorSystem.inst.GetGladiatorCount() > 0;
		}
		return false;
	}

	public ColosseumEvent StartNewEvent(int numRounds = 3)
	{
		if (!CanStartNewEvent())
		{
			return null;
		}
		numRounds = Mathf.Clamp(numRounds, minRounds, maxRounds);
		currentEvent = new ColosseumEvent(numRounds)
		{
			volatilityValue = volatilityValue
		};
		SetState(ColosseumState.Planning);
		return currentEvent;
	}

	private int CalculateProjectedFatigueGain(int gladiatorId, int upToRoundIndex)
	{
		if (currentEvent == null)
		{
			return 0;
		}
		int num = 0;
		for (int i = 0; i < upToRoundIndex && i < currentEvent.rounds.Count; i++)
		{
			ColosseumRound colosseumRound = currentEvent.rounds[i];
			if (colosseumRound.state == RoundState.Planned)
			{
				if (colosseumRound.combatant1Id == gladiatorId)
				{
					num++;
				}
				if (colosseumRound.opponentType == OpponentType.School && colosseumRound.opponentId == gladiatorId)
				{
					num++;
				}
			}
		}
		return num;
	}

	public void RecalculateAllPreviews()
	{
		if (currentEvent == null)
		{
			return;
		}
		for (int i = 0; i < currentEvent.rounds.Count; i++)
		{
			ColosseumRound round = currentEvent.rounds[i];
			if (round.state != RoundState.Planned)
			{
				continue;
			}
			Gladiator gladiator = GladiatorSystem.inst?.GetGladiator(round.combatant1Id);
			if (gladiator != null)
			{
				int projectedFatigueGain = CalculateProjectedFatigueGain(round.combatant1Id, i);
				int projectedFatigueGain2 = 0;
				Gladiator opponentGladiator = null;
				if (round.opponentType == OpponentType.School && round.opponentId >= 0)
				{
					opponentGladiator = GladiatorSystem.inst?.GetGladiator(round.opponentId);
					projectedFatigueGain2 = CalculateProjectedFatigueGain(round.opponentId, i);
				}
				ColosseumRound colosseumRound = currentEvent.rounds.FindLast((ColosseumRound r) => r.roundIndex < round.roundIndex && r.state != RoundState.Empty);
				bool isRematch = colosseumRound != null && GladiatorFightResolver.IsSameMatchup(colosseumRound, round);
				GladiatorFightResolver.CalculateRoundPreview(round, gladiator, opponentGladiator, projectedFatigueGain, projectedFatigueGain2, isRematch);
			}
		}
	}

	public bool ClearRound(int roundIndex)
	{
		if (currentEvent == null || roundIndex < 0 || roundIndex >= currentEvent.rounds.Count)
		{
			return false;
		}
		ColosseumRound colosseumRound = currentEvent.rounds[roundIndex];
		if (!colosseumRound.CanEdit())
		{
			return false;
		}
		colosseumRound.state = RoundState.Empty;
		colosseumRound.combatant1Id = -1;
		colosseumRound.opponentType = OpponentType.School;
		colosseumRound.opponentId = -1;
		colosseumRound.beastType = null;
		colosseumRound.beastCount = 1;
		colosseumRound.fightType = ColosseumFightType.GladiatorVsGladiator;
		RecalculateAllPreviews();
		return true;
	}

	public bool CanStartGames()
	{
		if (currentEvent != null && state == ColosseumState.Planning)
		{
			return currentEvent.CanStart();
		}
		return false;
	}

	public LandmassOwner GetLandmassOwner()
	{
		return World.GetLandmassOwner(b.LandMass());
	}

	public bool StartGames()
	{
		if (!CanStartGames())
		{
			return false;
		}
		int totalCost = currentEvent.GetTotalCost();
		LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
		if (landmassOwner != null && totalCost > 0)
		{
			landmassOwner.Gold -= totalCost;
			ResourceStatistics.AddConsumption(b.LandMass(), "gold_colosseum_games", 4, totalCost);
		}
		currentEvent.isActive = true;
		StartNextRound();
		return true;
	}

	public void CancelEvent()
	{
		if (state == ColosseumState.FightAnimating)
		{
			arenaFightManager.SkipFight();
		}
		else if (state == ColosseumState.ThumbsDecision || state == ColosseumState.RoundResult)
		{
			arenaFightManager.CleanupArena();
		}
		currentEvent = null;
		currentRound = null;
		currentDownedCombatant = null;
		presentationTimer = 0f;
		ColosseumUI.inst.fightUI.Hide();
		SetState(ColosseumState.Idle);
	}

	public void AcknowledgeRoundResult()
	{
		if (pendingSymmetricResult.combatant1.type != OutcomeType.Alive && pendingSymmetricResult.combatant1.fighter.gladiator != null)
		{
			GladiatorSystem.inst?.RemoveGladiator(pendingSymmetricResult.combatant1.fighter.gladiator.gladiatorId);
		}
		if (pendingSymmetricResult.combatant2.type != OutcomeType.Alive && pendingSymmetricResult.combatant2.fighter.gladiator != null)
		{
			GladiatorSystem.inst?.RemoveGladiator(pendingSymmetricResult.combatant2.fighter.gladiator.gladiatorId);
		}
		currentEvent.totalSpectacle += pendingSymmetricResult.spectacleEarned;
		arenaFightManager.CleanupArena();
		StartNextRound();
	}

	public void SkipRound()
	{
		arenaFightManager.SkipToResult();
	}

	private void StartNextRound()
	{
		ColosseumUI.inst.fightUI.Hide();
		currentRound = currentEvent.GetNextPlannedRound();
		if (currentRound == null)
		{
			currentEvent.isActive = false;
			SetState(ColosseumState.Summary);
			ColosseumUI.inst.summaryUI.Show(this, currentEvent);
			return;
		}
		string text = "";
		foreach (RoundOutcome outcome in currentEvent.outcomes)
		{
			if (outcome.combatant1Outcome.fighter.gladiator != null && outcome.combatant1Outcome.type != OutcomeType.Alive)
			{
				text = outcome.combatant1Outcome.fighter.DisplayName;
			}
			if (outcome.combatant2Outcome.fighter.gladiator != null && outcome.combatant2Outcome.type != OutcomeType.Alive)
			{
				text = outcome.combatant2Outcome.fighter.DisplayName;
			}
		}
		if (text != "")
		{
			currentRound.state = RoundState.Resolved;
			currentRound = null;
			SetState(ColosseumState.RoundResult);
			ColosseumUI.inst.roundResultUI.ShowResult(this, 0f, string.Format(LocalizationManager.GetTranslation("colosseum_round_skipped_dead"), text), "");
		}
		else
		{
			currentRound.state = RoundState.InProgress;
			ColosseumUI.inst.fightUI.Show(this, currentRound);
			SetState(ColosseumState.Presenting);
			presentationTimer = fightPresentationDuration;
		}
	}

	private void ResolveFight()
	{
		GladiatorFightResolver.FightResolutionResultSymmetric fightResolutionResultSymmetric = default;
		ArenaFighter f = arenaFightManager.team1[0];
		arenaFightManager.GetWinnerResults();
		fightResolutionResultSymmetric.combatant1 = new CombatantOutcome(f, arenaFightManager.IsWinningTeam(f));
		ArenaFighter arenaFighter = arenaFightManager.team2[0];
		fightResolutionResultSymmetric.combatant2 = new CombatantOutcome(arenaFighter, arenaFightManager.IsWinningTeam(arenaFighter));
		fightResolutionResultSymmetric.thumbsRequired = true;
		if (arenaFightManager.Team1Lost())
		{
			if (UnityEngine.Random.value < currentRound.combatant1DeathChanceFinal)
			{
				fightResolutionResultSymmetric.combatant1.type = OutcomeType.TragicAccident;
				fightResolutionResultSymmetric.thumbsRequired = false;
			}
		}
		else if (arenaFighter.gladiator != null)
		{
			if (UnityEngine.Random.value < currentRound.combatant2DeathChanceFinal)
			{
				fightResolutionResultSymmetric.combatant2.type = OutcomeType.TragicAccident;
				fightResolutionResultSymmetric.thumbsRequired = false;
			}
		}
		else
		{
			fightResolutionResultSymmetric.combatant2.type = OutcomeType.Execution;
			fightResolutionResultSymmetric.thumbsRequired = false;
		}
		fightResolutionResultSymmetric.spectacleEarned = ColosseumUI.inst.fightUI.Spectacle;
		if (fightResolutionResultSymmetric.combatant1.type == OutcomeType.TragicAccident || fightResolutionResultSymmetric.combatant2.type == OutcomeType.TragicAccident)
		{
			RuntimeManager.PlayOneShot("event:/SFX ASITP/Ambiences/ambScatter_crowdReact_cheer", b.Center());
			RuntimeManager.PlayOneShot("event:/SFX ASITP/Ambiences/ambScatter_crowdReact_shock", b.Center());
			fightResolutionResultSymmetric.volatilityDelta++;
			float num = currentRound.spectacleFinal * 0.5f;
			fightResolutionResultSymmetric.spectacleEarned += num;
			ColosseumUI.inst.fightUI.AddPostFightSpectacle(num);
		}
		pendingSymmetricResult = fightResolutionResultSymmetric;
	}

	private void OnFightAnimationComplete()
	{
		if (currentRound != null)
		{
			ResolveFight();
			Gladiator playerGladiator = GladiatorSystem.inst?.GetGladiator(currentRound.combatant1Id);
			Gladiator opponentGladiator = null;
			if (currentRound.opponentType == OpponentType.School && currentRound.opponentId >= 0)
			{
				opponentGladiator = GladiatorSystem.inst?.GetGladiator(currentRound.opponentId);
			}
			if (pendingSymmetricResult.thumbsRequired)
			{
				SetupThumbsDecision(playerGladiator, opponentGladiator);
			}
			else
			{
				CompleteRound(playerGladiator, opponentGladiator);
			}
		}
	}

	private void SetupThumbsDecision(Gladiator playerGladiator, Gladiator opponentGladiator)
	{
		Gladiator gladiator = null;
		CombatantOutcome outcome;
		if (arenaFightManager.Team1Lost())
		{
			outcome = pendingSymmetricResult.combatant1;
			gladiator = playerGladiator;
		}
		else
		{
			outcome = pendingSymmetricResult.combatant2;
			gladiator = opponentGladiator;
		}
		ThumbsScores thumbsScores = GladiatorFightResolver.CalculateThumbsScoresSymmetric(gladiator, volatilityValue, arenaFightManager.GetWinnerHpFraction());
		currentDownedCombatant = new DownedCombatantState
		{
			outcome = outcome,
			gladiator = gladiator
		};
		SetState(ColosseumState.ThumbsDecision);
		arenaFightManager.PlayLoserKneel();
		ColosseumUI.inst.roundResultUI.ShowWithThumbsDecision(this, thumbsScores.bias);
	}

	public void MakeThumbsDecision(bool chooseMercy)
	{
		if (chooseMercy)
		{
			currentDownedCombatant.outcome.type = OutcomeType.Alive;
			pendingSymmetricResult.volatilityDelta = -1f;
			currentDownedCombatant.gladiator.crowdFavor = Mathf.Clamp01(currentDownedCombatant.gladiator.crowdFavor + 0.1f);
		}
		else
		{
			currentDownedCombatant.outcome.type = OutcomeType.Execution;
			float num = GladiatorFightResolver.CalculateExecutionBonus(currentDownedCombatant.gladiator);
			pendingSymmetricResult.spectacleEarned += num;
			ColosseumUI.inst.fightUI.AddPostFightSpectacle(num);
			pendingSymmetricResult.volatilityDelta = 1f;
			pendingSymmetricResult.volatilityDelta += currentDownedCombatant.gladiator.fame;
		}
		if (arenaFightManager.Team1Lost())
		{
			pendingSymmetricResult.combatant1 = currentDownedCombatant.outcome;
		}
		else
		{
			pendingSymmetricResult.combatant2 = currentDownedCombatant.outcome;
		}
		volatilityValue += pendingSymmetricResult.volatilityDelta;
		volatilityValue = Mathf.Clamp(volatilityValue, 0f, 10f);
		ThumbsResult thumbsResult = (chooseMercy ? ThumbsResult.Mercy : ThumbsResult.Execution);
		ThumbsDecision item = new ThumbsDecision(currentDownedCombatant.outcome, thumbsResult);
		currentRound.thumbsDecisions.Add(item);
		arenaFightManager.PlayPostThumbsAnimation(chooseMercy);
		Gladiator playerGladiator = GladiatorSystem.inst?.GetGladiator(currentRound.combatant1Id);
		Gladiator opponentGladiator = null;
		if (currentRound.opponentType == OpponentType.School && currentRound.opponentId >= 0)
		{
			opponentGladiator = GladiatorSystem.inst?.GetGladiator(currentRound.opponentId);
		}
		CompleteRound(playerGladiator, opponentGladiator);
	}

	private void CompleteRound(Gladiator playerGladiator, Gladiator opponentGladiator)
	{
		if (currentRound != null)
		{
			currentRound.state = RoundState.Resolved;
			RoundOutcome item = new RoundOutcome
			{
				combatant1Outcome = pendingSymmetricResult.combatant1,
				combatant2Outcome = pendingSymmetricResult.combatant2,
				spectacleEarned = pendingSymmetricResult.spectacleEarned
			};
			currentEvent.outcomes.Add(item);
			currentEvent.volatilityChange += pendingSymmetricResult.volatilityDelta;
			SetState(ColosseumState.RoundResult);
			ColosseumUI.inst.roundResultUI.ShowOutcome(this, pendingSymmetricResult, currentRound.thumbsDecisions);
			currentDownedCombatant = null;
			currentRound = null;
		}
	}

	public void AcknowledgeSummary()
	{
		if (state == ColosseumState.Summary)
		{
			currentEvent = null;
			arenaFightManager.UnloadDebrisScene();
			SetState(ColosseumState.Idle);
		}
	}

	public string GetError()
	{
		if (GladiatorSystem.inst == null || GladiatorSystem.inst.GetGladiatorCount() == 0)
		{
			return LocalizationManager.GetTranslation("colosseum_error_no_gladiators");
		}
		return null;
	}

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	internal void SetGladiatorForRound(int currentRoundIndex, int selectedGladiatorId)
	{
		throw new NotImplementedException();
	}
}
