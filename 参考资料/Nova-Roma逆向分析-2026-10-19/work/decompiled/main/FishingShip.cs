using System;
using UnityEngine;

public class FishingShip : ShipBase
{
	public enum Status
	{
		Uninitialized,
		SailingToHut,
		SailingToFish,
		PostFishWait,
		WaitAtHutNoEmployees,
		WaitAtHutStorm,
		WaitAtHutFull,
		WaitAtHutNightTime
	}

	[Serializable]
	public struct FishermanSaveData
	{
		public bool isValid;

		public bool isWorkerFishing;

		public bool isRequiringUnload;
	}

	[Serializable]
	public new class ShipData
	{
		public int fishCount;

		public Status status;

		public float postFishWaitTime;

		public int missCount;

		public FishermanSaveData[] fishermanSaveData;
	}

	[NonSerialized]
	public Status status = Status.WaitAtHutNoEmployees;

	[NonSerialized]
	public bool pathObstructed;

	public int fishCount;

	public int prevFishCount;

	public Transform[] anchors;

	private FishingHut owner;

	private Building ownerBuilding;

	public Transform fishStack;

	private float postFishWaitTime;

	private Cell prevDockCell;

	private float waitTime = 3f;

	private int missCount;

	private FishSystem.FishCell targetCell;

	private Vector3 anchorPos;

	private Vector3 offset;

	private Vector3 tempPos;

	public ShipData GetShipData()
	{
		return new ShipData
		{
			status = status,
			fishCount = fishCount,
			postFishWaitTime = postFishWaitTime,
			missCount = missCount
		};
	}

	public void SetFromShipData(ShipData data)
	{
		missCount = data.missCount;
		fishCount = data.fishCount;
		postFishWaitTime = data.postFishWaitTime;
		SetStatus(data.status);
		for (int i = 0; i < fishCount; i++)
		{
			fishStack.GetChild(i).gameObject.SetActive(value: true);
		}
	}

	public void Init(FishingHut ownerHut)
	{
		Init(ownerHut.GetComponent<Building>().TeamID());
		owner = ownerHut;
		ownerBuilding = ownerHut.GetComponent<Building>();
	}

	private void MoveToHut()
	{
		Cell dockCell = ShipBase.GetDockCell(this, owner.dockPositions, owner.dockPositionPenalties);
		MoveTo(dockCell, displayPath: false);
		prevDockCell = dockCell;
	}

	public void SetStatus(Status newStatus)
	{
		if (newStatus == status)
		{
			return;
		}
		status = newStatus;
		switch (newStatus)
		{
		case Status.PostFishWait:
			postFishWaitTime = 0f;
			break;
		case Status.SailingToHut:
			MoveToHut();
			break;
		case Status.SailingToFish:
			targetCell = owner.GetFishingSpot();
			if (targetCell != null)
			{
				MoveTo(World.inst.GetCellData(targetCell.x, targetCell.z), displayPath: false);
			}
			else
			{
				SetStatus(Status.PostFishWait);
			}
			prevFishCount = fishCount;
			break;
		case Status.WaitAtHutNoEmployees:
			break;
		}
	}

	private void TryDropOffFish()
	{
		if (fishCount > 0)
		{
			owner.AddFish(fishCount);
			fishCount = 0;
			prevFishCount = 0;
			for (int i = 0; i < fishStack.childCount; i++)
			{
				fishStack.GetChild(i).gameObject.SetActive(value: false);
			}
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		pathObstructed = hadTrimmed;
		if (hadTrimmed)
		{
			arrived = false;
		}
		if (pathFailed && prevDockCell != null)
		{
			Cell dockCell = ShipBase.GetDockCell(this, owner.dockPositions, owner.dockPositionPenalties, prevDockCell);
			MoveTo(dockCell, displayPath: false);
			prevDockCell = dockCell;
		}
		if (!owner.HasFisherman())
		{
			if (status != Status.WaitAtHutNoEmployees)
			{
				SetStatus(Status.SailingToHut);
			}
		}
		else
		{
			if (status == Status.Uninitialized || status == Status.WaitAtHutFull || status == Status.WaitAtHutStorm || status == Status.WaitAtHutNightTime)
			{
				status = Status.WaitAtHutNoEmployees;
			}
			if (status == Status.WaitAtHutNoEmployees)
			{
				if (owner.TryBoardingFisherman())
				{
					SetStatus(Status.SailingToFish);
				}
			}
			else if (status == Status.SailingToHut && arrived)
			{
				TryDropOffFish();
				owner.UnloadFisherman();
				SetStatus(Status.WaitAtHutNoEmployees);
			}
		}
		switch (status)
		{
		case Status.SailingToFish:
			if (hadTrimmed)
			{
				SetStatus(Status.PostFishWait);
			}
			else if (arrived)
			{
				bool flag = false;
				if (targetCell.owners.Count > 0 && FishSystem.inst.TryRemoveFish(targetCell))
				{
					flag = true;
					fishCount++;
				}
				fishCount = Mathff.Clamp(fishCount, 0, fishStack.childCount);
				for (int i = 0; i < fishCount && i < fishStack.childCount; i++)
				{
					fishStack.GetChild(i).gameObject.SetActive(value: true);
				}
				if (flag)
				{
					missCount = 0;
					waitTime = 5f;
				}
				else
				{
					missCount++;
					waitTime = 4f;
				}
				SetStatus(Status.PostFishWait);
			}
			break;
		case Status.PostFishWait:
			if (owner.IsFishermanRequiringUnload() || owner.IsFishermanRequiringLoading() || !ownerBuilding.DuringWorkHours(-1f))
			{
				SetStatus(Status.SailingToHut);
				break;
			}
			postFishWaitTime += dt;
			if (postFishWaitTime > waitTime)
			{
				if (fishCount >= fishStack.childCount)
				{
					SetStatus(Status.SailingToHut);
				}
				else
				{
					SetStatus(Status.SailingToFish);
				}
			}
			break;
		}
	}
}
