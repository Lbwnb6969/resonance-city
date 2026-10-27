using System;
using System.Collections.Generic;
using Assets.Code;
using I2.Loc;

public class BuildingResourceRequest : Mission
{
	[Serializable]
	public class SaveData : MissionSaveData<BuildingResourceRequest, SaveData>
	{
		private int yearsRemain;

		private ResourceAmount request;

		private int buildingHash;

		private string friendlyName;

		public override SaveData Pack(BuildingResourceRequest j)
		{
			yearsRemain = j.yearsRemain;
			request = j.request;
			friendlyName = j.friendlyName;
			return base.Pack(j);
		}

		public override BuildingResourceRequest Unpack(BuildingResourceRequest j)
		{
			base.Unpack(j);
			j.yearsRemain = yearsRemain;
			j.request = request;
			j.friendlyName = friendlyName;
			return j;
		}
	}

	public ResourceAmount request;

	public int yearsRemain;

	internal string friendlyName;

	public BuildingResourceRequest(AIKingdom owner)
		: base(owner)
	{
		convo = "ResourceRequestBuilding";
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
		return string.Format("I2.Loc.ScriptLocalization.MissionBuildingRequestDesc", friendlyName, request.ToString());
	}

	public override string GetCondition()
	{
		if (status != Status.Failed)
		{
			return string.Format(ScriptLocalization.YearsRemain, yearsRemain);
		}
		return ScriptLocalization.TimeExpired;
	}

	public override bool TryCompleteWithGift(ResourceAmount giftAmount)
	{
		bool flag = true;
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		int i = 0;
		for (int count = resourceDefs.Count; i < count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			if (giftAmount.Get(resourceDef.ID) < request.Get(resourceDef.ID))
			{
				flag = false;
				break;
			}
		}
		if (flag)
		{
			status = Status.Complete;
		}
		return flag;
	}
}
