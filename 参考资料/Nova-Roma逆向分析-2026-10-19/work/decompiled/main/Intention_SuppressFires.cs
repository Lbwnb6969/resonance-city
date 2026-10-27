using System;
using UnityEngine;

public class Intention_SuppressFires : AIIntentionBase
{
	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Intention_BuildBuilding buildWellIntention;

	private Timer timer = new Timer(5f);

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() != LandMass || !obj.added || !(buildWellIntention == null))
		{
			return;
		}
		Cell cell = obj.targetBuilding.GetCell();
		if (!IgnoreBuilding(obj.targetBuilding) && !World.IsImmuneToFire(obj.targetBuilding) && FirehouseManager.inst.GetProtection(cell.x, cell.z) < 0.1f && !IsBeingBuilt(World.wellHash))
		{
			Vector3 position = cell.Position;
			AICell aICell = Layout.GetAICell((int)position.x, (int)position.z);
			if (aICell != null && aICell.buildingMeta != null)
			{
				position.x = aICell.buildingMeta.parentPosX;
				position.z = aICell.buildingMeta.parentPosZ;
			}
			buildWellIntention = AddSubIntention<Intention_BuildBuilding>("build new well");
			buildWellIntention.PlaceNewBlockIfNeeded = false;
			buildWellIntention.Init("well", AIBuildingBlockType.Any, position, 1);
		}
	}

	private bool IgnoreBuilding(Building b)
	{
		if (b.uniqueNameHash != World.foresterHash && b.categoryHash != World.castleblockHash)
		{
			return b.categoryHash == World.projectileTopperHash;
		}
		return true;
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 100;
		KillAndNullFinishedIntention(ref buildWellIntention);
	}
}
