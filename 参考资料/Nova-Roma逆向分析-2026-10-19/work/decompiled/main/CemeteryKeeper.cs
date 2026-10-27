using System;
using System.Collections.Generic;
using Assets.Code.Jobs;
using I2.Loc;
using UnityEngine;

public class CemeteryKeeper : Tickable, IOutputInfo, IWorkerUIDisplay
{
	public class PathToCemetery
	{
		public GamePath path;

		public bool distanceCalculated;

		public float distance;

		public void CheckPaths()
		{
			if (!distanceCalculated && path.status == GamePath.Status.Complete)
			{
				distanceCalculated = true;
				distance = 0f;
				int i = 0;
				for (int count = path.result.Count; i < count - 1; i++)
				{
					distance += Mathff.Dist(path.result.data[i], path.result.data[i + 1]);
				}
			}
		}

		public bool Ready()
		{
			if (!distanceCalculated)
			{
				CheckPaths();
			}
			return distanceCalculated;
		}
	}

	public ParticleSystem torch;

	public ParticleSystem chimney;

	public Building b;

	private EventHandler<OnBuildingAddRemove> onAddBuildingRemoveHandler;

	private Dictionary<Building, PathToCemetery> pathsToCemeteries = new Dictionary<Building, PathToCemetery>();

	private ArrayExt<Building> scratchRemove = new ArrayExt<Building>(32);

	private ArrayExt<ArrayExt<Building>> scratchArray = new ArrayExt<ArrayExt<Building>>(10);

	private bool doRebuild;

	private int rebuildFrame = SRand.srand.Next(0, 30);

	private int frameSpread = 30;

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	private void OnInit()
	{
		onAddBuildingRemoveHandler = Broadcast.BuildingAddRemove.ListenAny(OnBuildingAddRemove);
	}

	private void OnDestroy()
	{
		if (onAddBuildingRemoveHandler != null)
		{
			Broadcast.BuildingAddRemove.UnlistenAny(onAddBuildingRemoveHandler);
		}
	}

	public void OnFinishedLoad()
	{
		if (b.IsBuilt())
		{
			UpdateChimney();
		}
	}

	private void OnBuildingAddRemove(object sender, OnBuildingAddRemove data)
	{
		if (data.targetBuilding.categoryHash == World.cemeteryHash && data.targetBuilding.LandMass() == b.LandMass())
		{
			PruneDeadCemeteries(data.targetBuilding);
			doRebuild = true;
		}
	}

	private void PruneDeadCemeteries(Building toRemove)
	{
		scratchRemove.Clear();
		foreach (KeyValuePair<Building, PathToCemetery> pathsToCemetery in pathsToCemeteries)
		{
			if (pathsToCemetery.Key == null || pathsToCemetery.Key == toRemove)
			{
				scratchRemove.Add(pathsToCemetery.Key);
			}
		}
		for (int i = 0; i < scratchRemove.Count; i++)
		{
			pathsToCemeteries.Remove(scratchRemove.data[i]);
		}
		scratchRemove.Clear();
	}

	public void RebuildPathData()
	{
		Player.inst.GetBuildingListsByCategoryForLandMass(b.LandMass(), World.cemeteryHash, ref scratchArray);
		Vector3 start = b.Center();
		for (int i = 0; i < scratchArray.Count; i++)
		{
			ArrayExt<Building> arrayExt = scratchArray.data[i];
			for (int j = 0; j < arrayExt.Count; j++)
			{
				if (pathsToCemeteries.TryGetValue(arrayExt.data[j], out var value))
				{
					World.inst.threadedPather.RequestPath(value.path);
					continue;
				}
				GamePath gamePath = new GamePath();
				gamePath.start = start;
				gamePath.end = arrayExt.data[j].Center();
				gamePath.pathType = GamePath.PathType.VillagerPath;
				World.inst.threadedPather.RequestPath(gamePath);
				pathsToCemeteries.Add(arrayExt.data[j], new PathToCemetery
				{
					path = gamePath
				});
			}
		}
	}

	public bool TryGetCemeteryDistance(Building cemetery, out float distance)
	{
		distance = 0f;
		if (!pathsToCemeteries.ContainsKey(cemetery))
		{
			return false;
		}
		PathToCemetery pathToCemetery = pathsToCemeteries[cemetery];
		bool result = pathToCemetery.Ready();
		distance = pathToCemetery.distance;
		if (pathToCemetery.path.status == GamePath.Status.Finding)
		{
			distance = Mathff.DistXZ(b.cachedPos, cemetery.cachedPos);
			result = true;
		}
		return result;
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (!undo && !LoadSave.Loading)
		{
			PruneDeadCemeteries(null);
			RebuildPathData();
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(GraveWorkerJob)))
			{
				b.SetAndAddJob(i, new GraveWorkerJob(b));
			}
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (doRebuild && currFrame % frameSpread == rebuildFrame)
		{
			RebuildPathData();
			doRebuild = false;
		}
		if (b.IsBuilt() && b.IsPlaced())
		{
			if (Cemetery.CemeteriesForLandMass(b.LandMass()).Count <= 0)
			{
				b.thought.thought = ThoughtBubbleSystem.Thought.GeneralError;
				b.thought.visible = true;
			}
			else
			{
				bool flag = false;
				for (int i = 0; i < b.jobs.Count; i++)
				{
					if (b.jobs[i] is GraveWorkerJob graveWorkerJob && graveWorkerJob.NoNearbyStorage())
					{
						flag = true;
						break;
					}
				}
				if (flag)
				{
					b.thought.thought = ThoughtBubbleSystem.Thought.GeneralError;
					b.thought.visible = true;
				}
				else
				{
					b.thought.visible = false;
				}
			}
		}
		UpdateChimney();
	}

	public void UpdateChimney()
	{
	}

	string IOutputInfo.GetError()
	{
		if (Cemetery.CemeteriesForLandMass(b.LandMass()).Count <= 0)
		{
			return LocalizationManager.GetTranslation("workerui_nocemeteries");
		}
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is GraveWorkerJob graveWorkerJob && graveWorkerJob.NoNearbyStorage())
			{
				return LocalizationManager.GetTranslation("workerui_nocemeteriesnearby");
			}
		}
		return null;
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
