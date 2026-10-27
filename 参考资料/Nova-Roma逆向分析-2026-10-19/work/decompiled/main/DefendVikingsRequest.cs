using System;
using I2.Loc;

public class DefendVikingsRequest : Mission
{
	[Serializable]
	public class SaveData : MissionSaveData<DefendVikingsRequest, SaveData>
	{
		private bool playerDidDamage;

		public override SaveData Pack(DefendVikingsRequest j)
		{
			playerDidDamage = j.playerDidDamage;
			return base.Pack(j);
		}

		public override DefendVikingsRequest Unpack(DefendVikingsRequest j)
		{
			base.Unpack(j);
			j.playerDidDamage = playerDidDamage;
			return j;
		}
	}

	private bool wasInvasionInProgress;

	private bool playerDidDamage;

	public DefendVikingsRequest(AIKingdom owner)
		: base(owner)
	{
		convo = "DefendVikingsRequest";
		OrdersManager.inst.OnUnitMoveTo += Inst_OnUnitMoveTo;
	}

	private void Inst_OnUnitMoveTo(IMoveableUnit mover, IMoveTarget target)
	{
		if (status == Status.InProgress && mover.TeamID() == 0 && target.TeamID() == 1)
		{
			int landMassIdx = World.inst.GetCellDataClamped(mover.GetPos()).landMassIdx;
			if (ownerKingdom.Layout.LandMass == landMassIdx)
			{
				playerDidDamage = true;
			}
		}
	}

	public override void Dispose()
	{
		base.Dispose();
		OrdersManager.inst.OnUnitMoveTo -= Inst_OnUnitMoveTo;
	}

	public override string GetDescription()
	{
		return "I2.Loc.ScriptLocalization.MissionVikingRequestDesc";
	}

	public override string GetCondition()
	{
		if (RaiderSystem.inst.IsRaidInProgress())
		{
			return "I2.Loc.ScriptLocalization.ActualVikingInvading";
		}
		return "I2.Loc.ScriptLocalization.VIKINGS_INVADING" + string.Format(ScriptLocalization.YearsRemain, RaiderSystem.inst.yearsUntilNextAttack);
	}

	public override void OnNewYear()
	{
		if (RaiderSystem.inst.IsRaidInProgress())
		{
			wasInvasionInProgress = true;
		}
		if (wasInvasionInProgress && !RaiderSystem.inst.IsRaidInProgress() && !playerDidDamage && status == Status.InProgress)
		{
			status = Status.Failed;
		}
		base.OnNewYear();
	}

	public override void Update()
	{
		if (playerDidDamage && !RaiderSystem.inst.IsRaidInProgress())
		{
			status = Status.Complete;
		}
		base.Update();
	}
}
