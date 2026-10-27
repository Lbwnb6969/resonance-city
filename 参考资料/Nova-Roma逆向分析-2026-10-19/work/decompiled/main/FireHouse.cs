using System;
using Assets.Code.Interface;
using UnityEngine;

public class FireHouse : MonoBehaviour, IOutputInfo, IOverlayUser, IWorkerUIDisplay
{
	[Serializable]
	public struct FireEngineEntry
	{
		public Transform anchor;

		[NonSerialized]
		public FireEngine engine;
	}

	[Serializable]
	public class FireHouseSaveData : SaveClass<FireHouse, FireHouseSaveData>
	{
		[Serializable]
		public struct FireEngineData
		{
			public SerializableVector3 pos;

			public SerializableVector3 fwd;
		}

		public FireEngineData[] engineData;

		public override FireHouseSaveData Pack(FireHouse obj)
		{
			engineData = new FireEngineData[obj.engineEntries.Length];
			for (int i = 0; i < obj.engineEntries.Length; i++)
			{
				FireEngine engine = obj.engineEntries[i].engine;
				if (engine != null)
				{
					engineData[i].pos = engine.GetPosition();
					engineData[i].fwd = engine.GetForward();
				}
			}
			return this;
		}

		public override FireHouse Unpack(FireHouse obj)
		{
			if (engineData == null)
			{
				return obj;
			}
			for (int i = 0; i < obj.engineEntries.Length; i++)
			{
				FireEngine engine = obj.engineEntries[i].engine;
				if (engine != null)
				{
					engine.SetPosFwd(engineData[i].pos, engineData[i].fwd);
					engine.SetStatus(FireEngine.Status.HeadingToStation);
				}
			}
			return obj;
		}
	}

	public Building b;

	private WagePayer w;

	public FireEngineEntry[] engineEntries;

	private EventHandler<OnTechnologyTreeUnlock> unlockEventHandler;

	public bool OverlayWhenPlacing => true;

	public bool OverlayWhenSelected => true;

	private void OnInit()
	{
		b = GetComponent<Building>();
		w = GetComponent<WagePayer>();
		unlockEventHandler = Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyTreeUnlock);
	}

	private void OnTechnologyTreeUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		if (TeamID() == 0 && b.IsBuilt() && !(data.unlockKey != "unlockkey_fireengines"))
		{
			for (int i = 0; i < engineEntries.Length; i++)
			{
				Util.SetActive(engineEntries[i].engine.gameObject, active: true);
			}
		}
	}

	private void OnBuilt()
	{
		for (int i = 0; i < engineEntries.Length; i++)
		{
			if (engineEntries[i].engine == null)
			{
				engineEntries[i].engine = FireEngineSystem.inst.SpawnEngine(this, engineEntries[i].anchor.position, engineEntries[i].anchor.rotation);
			}
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (undo || !b.IsBuilt())
		{
			return;
		}
		for (int i = 0; i < engineEntries.Length; i++)
		{
			if (engineEntries[i].engine == null)
			{
				engineEntries[i].engine = FireEngineSystem.inst.SpawnEngine(this, engineEntries[i].anchor.position, engineEntries[i].anchor.rotation);
			}
		}
	}

	private void OnShutdown()
	{
		for (int i = 0; i < engineEntries.Length; i++)
		{
			FireEngineSystem.inst.Remove(engineEntries[i].engine);
		}
		Broadcast.TechnologyTreeUnlockEvent.Unlisten(unlockEventHandler);
	}

	public Transform GetDockingAnchor(FireEngine engine)
	{
		if (engine == null)
		{
			return null;
		}
		for (int i = 0; i < engineEntries.Length; i++)
		{
			if (engineEntries[i].engine == engine)
			{
				return engineEntries[i].anchor;
			}
		}
		return null;
	}

	public Vector3 GetDockingPosition(FireEngine engine)
	{
		if (engine == null)
		{
			return b.Center();
		}
		for (int i = 0; i < engineEntries.Length; i++)
		{
			if (engineEntries[i].engine == engine)
			{
				return engineEntries[i].anchor.position;
			}
		}
		return b.Center();
	}

	public Vector3 GetDockExitPosition(FireEngine engine)
	{
		if (engine == null)
		{
			return b.Center();
		}
		for (int i = 0; i < engineEntries.Length; i++)
		{
			if (engineEntries[i].engine == engine)
			{
				return engineEntries[i].anchor.position + engineEntries[i].anchor.forward;
			}
		}
		return b.Center();
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FireFighterPro)))
			{
				b.SetAndAddJob(i, new FireFighterPro(b));
			}
		}
	}

	public int TeamID()
	{
		return b.TeamID();
	}

	public static float GetProtectionPercentageOfCell(Cell cell)
	{
		return FirehouseManager.inst.GetProtection(cell.x, cell.z);
	}

	public void DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.ClearOverlay(updateToo: false);
		FirehouseManager.inst.DrawOverlay();
		if (GameUI.inst.CurrPlacementMode.IsPlacing() || !b.IsBuilt())
		{
			FirehouseManager.inst.DrawOverlay(GetComponent<FireRiskReduction>());
		}
		TerrainGen.inst.ApplyBuildingOverlayMaterial();
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}

	public bool ShowVillagerList()
	{
		return true;
	}

	string IOutputInfo.GetError()
	{
		return null;
	}
}
