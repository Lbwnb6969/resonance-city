using System;
using System.Collections.Generic;

public class Intention_CollectWood : AIIntentionBase
{
	private Intention_BuildPreplannedBuilding buildForesterIntention;

	private List<ClearCutterJob> cutterJobs = new List<ClearCutterJob>();

	private EventHandler<OnBuildingAddRemove> eventHandler;

	private Timer cutterTimer = new Timer(5f);

	private int goalAmount = 300;

	private float timeAtLowWood;

	private float timeToBuildForester = 150f;

	private bool OutOfSpaceForForester;

	public void Init()
	{
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
	}

	private void OnDisable()
	{
		Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() == LandMass && !obj.added && obj.targetBuilding.uniqueNameHash == World.foresterHash)
		{
			OutOfSpaceForForester = false;
			timeAtLowWood = timeToBuildForester;
		}
	}

	public void SetNewGoalAmount(int newGoal)
	{
		goalAmount = 300;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		priority = 90;
		if (Kingdom.CurrentResources.Get(6) > 0)
		{
			Player.inst.SetUseTool(LandMass, Player.ToolUser.Forester, Kingdom.CurrentResources.Get(1) < 1000);
		}
		for (int i = 0; i < cutterJobs.Count; i++)
		{
			if (cutterJobs[i].employer == null)
			{
				cutterJobs.RemoveAt(i);
				i--;
			}
		}
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(LandMass, World.foresterHash);
		ArrayExt<Building> buildingListForLandMass2 = Player.inst.GetBuildingListForLandMass(LandMass, World.quarryHash);
		if (buildForesterIntention == null && Kingdom.AtLowResources(1, 5))
		{
			timeAtLowWood += dt;
		}
		if (buildingListForLandMass.Count < 1 || timeAtLowWood >= timeToBuildForester)
		{
			bool flag = Player.inst.AllBuildingsOfTypeStaffed(LandMass, World.foresterHash);
			if (((!OutOfSpaceForForester && buildForesterIntention == null && buildingListForLandMass2.Count > 0) & flag) && !IsBeingBuilt(World.foresterHash))
			{
				buildForesterIntention = AddSubIntention<Intention_BuildPreplannedBuilding>("build forester");
				buildForesterIntention.doRoads = true;
				buildForesterIntention.InitClosest("forester", Layout.KingdomStart);
			}
			if (Kingdom.CurrentResources.Get(1) < goalAmount && cutterTimer.Update(dt))
			{
				ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[LandMass];
				int num = World.inst.AvailableWorkersOnLandMass(LandMass);
				int num2 = Mathff.Max(1, num);
				if (World.inst.GetVillagersForLandMass(LandMass).Count > 15)
				{
					num2 = (int)Mathff.Max(1f, (float)num * 0.25f);
				}
				int num3 = Mathff.Max(0, num2 - cutterJobs.Count);
				for (int j = 0; j < num3; j++)
				{
					Cell origin = arrayExt.RandomElement();
					Cell cell = World.inst.FindMatchingSurroundingCell(origin, testOrigin: false, 5, (Cell c) =>
					{
						int num4 = 0;
						Cell cellDataClamped = World.inst.GetCellDataClamped(c.x, c.z + 1);
						if (World.inst.treeSystem.ItemAmount(cellDataClamped) > 0 && !cellDataClamped.Busy)
						{
							num4++;
						}
						Cell cellDataClamped2 = World.inst.GetCellDataClamped(c.x, c.z - 1);
						if (World.inst.treeSystem.ItemAmount(cellDataClamped2) > 0 && !cellDataClamped2.Busy)
						{
							num4++;
						}
						Cell cellDataClamped3 = World.inst.GetCellDataClamped(c.x + 1, c.z);
						if (World.inst.treeSystem.ItemAmount(cellDataClamped3) > 0 && !cellDataClamped3.Busy)
						{
							num4++;
						}
						Cell cellDataClamped4 = World.inst.GetCellDataClamped(c.x - 1, c.z);
						if (World.inst.treeSystem.ItemAmount(cellDataClamped4) > 0 && !cellDataClamped4.Busy)
						{
							num4++;
						}
						return World.inst.treeSystem.ItemAmount(c) > 0 && !c.Busy && num4 >= 2;
					});
					if (cell != null)
					{
						ClearCutterJob clearCutterJob = new ClearCutterJob(cell);
						JobSystem.inst.AddNewJob(0, clearCutterJob, 21);
						clearCutterJob.StartClearingAt(cell);
						cutterJobs.Add(clearCutterJob);
					}
				}
			}
		}
		if (buildForesterIntention != null && buildForesterIntention.failType == FailType.LayoutBlockOutOfSpace)
		{
			OutOfSpaceForForester = !Kingdom.avoidPlacingForesterOnLand;
			Kingdom.avoidPlacingForesterOnLand = false;
		}
		if (KillAndNullFinishedIntention(ref buildForesterIntention))
		{
			timeAtLowWood = -300f;
			cutterTimer.ForceExpire();
		}
	}
}
