using System;
using UnityEngine;

public class Library : Tickable, IOutputInfo
{
	[Serializable]
	public class LibrarySaveData : SaveClass<Library, LibrarySaveData>
	{
		private int knowledge;

		public override LibrarySaveData Pack(Library obj)
		{
			knowledge = obj.knowledge;
			return this;
		}

		public override Library Unpack(Library obj)
		{
			obj.knowledge = knowledge;
			return obj;
		}
	}

	private bool touchingGreatLibrary;

	[NonSerialized]
	public int knowledge = 1;

	private RadiusBonus radBonus;

	private WagePayer w;

	private Building b;

	private EventHandler<OnBuildingAddRemove> listenEventHandler;

	private bool firstUpdate = true;

	private Timer knowledgeGain = new Timer(100f);

	private float refreshTime = -1f;

	public int maxKnowledge
	{
		get
		{
			if (!touchingGreatLibrary)
			{
				return 12;
			}
			return 15;
		}
	}

	string IOutputInfo.GetError()
	{
		return null;
	}

	private int GetHappiness()
	{
		return (int)(b.GetWorkerPercent() * (float)knowledge);
	}

	public override void OnEnableInternal()
	{
		radBonus = GetComponent<RadiusBonus>();
		radBonus.happinessFunc = GetHappiness;
		w = GetComponent<WagePayer>();
		b = GetComponent<Building>();
		base.OnEnableInternal();
		listenEventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		Broadcast.BuildingAddRemove.UnlistenAny(listenEventHandler);
	}

	public void OnFinishedLoad()
	{
		RefreshMaxHappiness();
	}

	public void OnBuilt()
	{
		RefreshMaxHappiness();
	}

	public override void Tick(float dt, int currFrame)
	{
		if (firstUpdate)
		{
			RefreshMaxHappiness();
			firstUpdate = false;
		}
		if (refreshTime != -1f)
		{
			refreshTime -= dt;
			if (refreshTime < 0f)
			{
				RefreshMaxHappiness();
				refreshTime = -1f;
			}
		}
		if (b.IsOpen() && b.IsBuilt() && b.GetWorkerPercent() > 0f && knowledgeGain.Update(dt))
		{
			knowledge++;
			knowledge = Mathf.Clamp(knowledge, 1, maxKnowledge);
		}
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.uniqueNameHash == World.greatLibraryHash)
		{
			refreshTime = SRand.value;
		}
	}

	private void RefreshMaxHappiness()
	{
		touchingGreatLibrary = false;
		Cell cell = b.GetCell();
		CellInfluence cellInfluenceDataClamped = World.inst.GetCellInfluenceDataClamped(cell.x, cell.z);
		for (int i = 0; i < cellInfluenceDataClamped.radiusBonuses.Count; i++)
		{
			if (cellInfluenceDataClamped.radiusBonuses.data[i].residentialTileID == 211)
			{
				touchingGreatLibrary = true;
				break;
			}
		}
	}
}
