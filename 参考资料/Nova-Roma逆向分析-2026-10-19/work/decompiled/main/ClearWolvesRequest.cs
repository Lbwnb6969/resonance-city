using System;
using I2.Loc;

public class ClearWolvesRequest : Mission
{
	[Serializable]
	public class SaveData : MissionSaveData<ClearWolvesRequest, SaveData>
	{
		private int yearsRemain;

		public override SaveData Pack(ClearWolvesRequest j)
		{
			yearsRemain = j.yearsRemain;
			return base.Pack(j);
		}

		public override ClearWolvesRequest Unpack(ClearWolvesRequest j)
		{
			base.Unpack(j);
			j.yearsRemain = yearsRemain;
			return j;
		}
	}

	public int yearsRemain;

	public ClearWolvesRequest(AIKingdom owner)
		: base(owner)
	{
		convo = "ClearWolfRequest";
		World.inst.OnWolfDenCleared += OnWolfDenDestroyed;
	}

	public override void Dispose()
	{
		World.inst.OnWolfDenCleared -= OnWolfDenDestroyed;
		base.Dispose();
	}

	public override void OnNewYear()
	{
		if (status == Status.InProgress)
		{
			yearsRemain--;
			if (yearsRemain == 0)
			{
				status = Status.Failed;
			}
		}
		base.OnNewYear();
	}

	public override string GetDescription()
	{
		return "I2.Loc.ScriptLocalization.MissionWolfRequestDesc";
	}

	public override string GetCondition()
	{
		return string.Format(ScriptLocalization.YearsRemain, yearsRemain);
	}

	private void OnWolfDenDestroyed(int landmassIdx, int teamID)
	{
		if (status == Status.InProgress)
		{
			AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(landmassIdx);
			if (teamID == 0 && ownerKingdom == kingdomByLandmass)
			{
				status = Status.Complete;
			}
		}
	}
}
