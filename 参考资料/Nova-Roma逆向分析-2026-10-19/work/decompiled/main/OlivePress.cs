using System;
using Assets.Code;
using Assets.Interface;

public class OlivePress : ProductionBuilding, IResourceStorage, IResourceStorageBase, IProductionInfo
{
	[Serializable]
	public class OlivePressSaveData : SaveClass<OlivePress, OlivePressSaveData>
	{
		private int internalOlives;

		private int internalPottery;

		private int stackCount;

		public override OlivePressSaveData Pack(OlivePress obj)
		{
			internalOlives = obj.resourcesStored.Get(18);
			internalPottery = obj.resourcesStored.Get(16);
			stackCount = obj.stack.Count();
			return this;
		}

		public override OlivePress Unpack(OlivePress obj)
		{
			obj.resourcesStored.Set(18, internalOlives);
			obj.resourcesStored.Set(16, internalPottery);
			obj.stack.Add(stackCount);
			return obj;
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (b.IsBuilt())
		{
			b.IsOpen();
		}
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
		ResourceStorageHelper.Deposit(resourcesStored, resourceStorageMax, null, ref resources, b.Center());
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		return null;
	}
}
