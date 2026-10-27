using System;
using UnityEngine;

public class ChamberOfWar : MonoBehaviour, IWorkerUIDisplay, IOutputInfo
{
	[Serializable]
	public class ChamberOfWarSaveData : SaveClass<ChamberOfWar, ChamberOfWarSaveData>
	{
		public Guid[] heroLoadGuids = new Guid[5];

		public int trainingHeroIdx;

		public bool training;

		public float trainPercent;

		public override ChamberOfWarSaveData Pack(ChamberOfWar obj)
		{
			return this;
		}

		public override ChamberOfWar Unpack(ChamberOfWar obj)
		{
			return obj;
		}
	}

	public Building b;

	private void Start()
	{
		b = GetComponent<Building>();
	}

	private void Update()
	{
		if (!b.IsBuilt() || !(b.GetWorkerPercent() < 0.0001f))
		{
			return;
		}
		LandmassOwner landMassOwner = b.GetLandMassOwner();
		if (landMassOwner.hazardPay)
		{
			if (landMassOwner.teamId == 0)
			{
				Player.inst.ChangeHazardPayActive(active: false, warmup: false);
			}
			else
			{
				landMassOwner.hazardPay = false;
			}
		}
	}

	public bool ShowCustomButton()
	{
		return false;
	}

	public bool CustomButtonInteractable()
	{
		return false;
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public string GetError()
	{
		return null;
	}

	public Vector3 GetPositionForPerson(Villager p)
	{
		return b.Center();
	}

	public bool IsOpen()
	{
		return b.IsOpen();
	}

	public void OnAssigned(Villager p)
	{
	}

	public void OnUnAssigned()
	{
	}

	public string GetUsedSkill()
	{
		return "";
	}

	private void OnDemolished()
	{
		b.GetLandMassOwner().hazardPay = false;
	}

	private void OnWreck()
	{
		b.GetLandMassOwner().hazardPay = false;
	}
}
