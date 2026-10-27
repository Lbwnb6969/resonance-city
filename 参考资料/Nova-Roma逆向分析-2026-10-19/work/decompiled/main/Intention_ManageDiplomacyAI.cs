using System;

public class Intention_ManageDiplomacyAI : AIIntentionBase
{
	[Serializable]
	public class ManageDiplomacyAISaveData : SaveClass<Intention_ManageDiplomacyAI, ManageDiplomacyAISaveData>
	{
		private Timer objectiveTimer;

		private AItoAIObjectiveType objective;

		private Guid unitObjective;

		private int targetKingdomTeamID;

		public override ManageDiplomacyAISaveData Pack(Intention_ManageDiplomacyAI v)
		{
			objectiveTimer = v.objectiveTimer;
			objective = v.objective;
			targetKingdomTeamID = v.targetKingdomTeamID;
			if (v.currUnitObjective != null)
			{
				unitObjective = v.currUnitObjective.guid;
			}
			return this;
		}

		public override Intention_ManageDiplomacyAI Unpack(Intention_ManageDiplomacyAI v)
		{
			v.objectiveTimer = objectiveTimer;
			v.objective = objective;
			v.targetKingdomTeamID = targetKingdomTeamID;
			_ = unitObjective;
			v.currUnitObjective = v.Kingdom.unitControl.GetObjectiveByGuid(unitObjective);
			return v;
		}
	}

	private AIUnitControlSystem.Objective currUnitObjective;

	[NonSerialized]
	public AItoAIObjectiveType objective;

	private float tradeAgreementWaitPeriod;

	private int nextKingdomIdx;

	private int targetKingdomTeamID;

	[NonSerialized]
	public int bonusPriority;

	private bool wasUnitAssigned;

	private Timer objectiveTimer = new Timer(300f);

	public void Init()
	{
		objective = AItoAIObjectiveType.None;
		Kingdom.unitControl.OnObjectiveCompleted += OnObjectiveComplete;
	}

	private void OnDisable()
	{
		Kingdom.unitControl.OnObjectiveCompleted -= OnObjectiveComplete;
	}

	private bool InitAITradeAgreement()
	{
		AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(targetKingdomTeamID);
		Building building = Player.inst.GetBuildingListForLandMassOwner(kingdomFromTeamId.LandmassOwner, World.keepHash).data[0];
		if ((bool)building)
		{
			AIUnitControlSystem.Objective objective = new AIUnitControlSystem.Objective
			{
				type = AIUnitControlSystem.ObjectiveType.MoveToBuilding,
				target = building,
				exclusive = true
			};
			Kingdom.unitControl.AddObjective(objective);
			currUnitObjective = objective;
			AIUnitControlSystem.Objective child = new AIUnitControlSystem.Objective
			{
				type = AIUnitControlSystem.ObjectiveType.WaitForComplete,
				target = building,
				exclusive = true
			};
			Kingdom.unitControl.AddObjectiveAsDependency(child, objective);
			this.objective = AItoAIObjectiveType.AITradeAgreement;
			return true;
		}
		return false;
	}

	private void OnObjectiveComplete(AIUnitControlSystem.Objective o)
	{
		if (o == currUnitObjective)
		{
			if (currUnitObjective.next != null)
			{
				currUnitObjective = currUnitObjective.next;
				wasUnitAssigned = false;
			}
			else
			{
				currUnitObjective = null;
				wasUnitAssigned = false;
				objective = AItoAIObjectiveType.None;
			}
		}
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(LandMass);
		if (villagersForLandMass.Count < 75)
		{
			return;
		}
		priority = 67;
		if (villagersForLandMass.Count > 150 && Player.inst.GetBuildingListForLandMass(LandMass, World.hallofdiplomacyHash).Count <= 0)
		{
			priority = 90;
		}
		if (currUnitObjective != null)
		{
			if (!currUnitObjective.IsComplete() && currUnitObjective.unitsAssigned.Count == 0 && wasUnitAssigned)
			{
				Kingdom.unitControl.RemoveObjective(currUnitObjective);
				currUnitObjective = null;
				wasUnitAssigned = false;
			}
			if (currUnitObjective != null)
			{
				wasUnitAssigned = currUnitObjective.unitsAssigned.Count > 0;
			}
		}
		ValidateCurrentObjective();
		if (objective == AItoAIObjectiveType.None && objectiveTimer.Update(dt) && AIBrainsContainer.inst.kingdoms.Count >= 2)
		{
			do
			{
				nextKingdomIdx++;
				if (nextKingdomIdx >= AIBrainsContainer.inst.kingdoms.Count)
				{
					nextKingdomIdx = 0;
				}
			}
			while (!(AIBrainsContainer.inst.kingdoms[nextKingdomIdx] != Kingdom));
			targetKingdomTeamID = AIBrainsContainer.inst.kingdoms[nextKingdomIdx].LandmassOwner.teamId;
			AIKingdom aIKingdom = AIBrainsContainer.inst.kingdoms[nextKingdomIdx];
			if (SeasonManager.inst.CurrentYear() >= 35 && !Player.inst.DocksOpen(LandmassOwner, aIKingdom.LandmassOwner))
			{
				objective = AItoAIObjectiveType.AITradeAgreement;
			}
			else
			{
				objective = AItoAIObjectiveType.None;
			}
		}
		if (objective != AItoAIObjectiveType.AITradeAgreement)
		{
			return;
		}
		if (currUnitObjective == null)
		{
			InitAITradeAgreement();
		}
		if (currUnitObjective != null && currUnitObjective.type == AIUnitControlSystem.ObjectiveType.WaitForComplete)
		{
			tradeAgreementWaitPeriod += dt;
			if (tradeAgreementWaitPeriod >= SeasonManager.inst.TimeInYear())
			{
				AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(targetKingdomTeamID);
				LandmassOwner landmassOwner = kingdomFromTeamId.LandmassOwner;
				landmassOwner.SetPayCosts(LandmassOwner.teamId, Player.inst.defaultPayCost);
				LandmassOwner.SetPayCosts(landmassOwner.teamId, Player.inst.defaultPayCost);
				Player.inst.OpenDocks(LandmassOwner, landmassOwner);
				_ = (World.inst.kingdomHeadInfo[Kingdom.headIdx].maleHonorific ? "King" : "Queen") + " " + Kingdom.lastName;
				_ = (World.inst.kingdomHeadInfo[kingdomFromTeamId.headIdx].maleHonorific ? "King" : "Queen") + " " + kingdomFromTeamId.lastName;
				currUnitObjective.Complete();
				tradeAgreementWaitPeriod = 0f;
			}
		}
	}

	private void ValidateCurrentObjective()
	{
		if (objective == AItoAIObjectiveType.AITradeAgreement)
		{
			AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(targetKingdomTeamID);
			if (kingdomFromTeamId == null || Player.inst.DocksOpen(kingdomFromTeamId.LandmassOwner, LandmassOwner))
			{
				ClearDiplomaticUnitObjectives();
				objective = AItoAIObjectiveType.None;
				targetKingdomTeamID = -1;
			}
		}
	}

	private void ClearDiplomaticUnitObjectives()
	{
		if (currUnitObjective != null)
		{
			GameUI.inst.diplomacyNotificationUI.CloseBanner(LandmassOwner.teamId);
			Kingdom.unitControl.RemoveObjective(currUnitObjective);
			currUnitObjective = null;
			wasUnitAssigned = false;
		}
	}
}
