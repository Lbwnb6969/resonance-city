using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Code.Jobs;
using Assets.Interface;
using UnityEngine;

public class HallOfDiplomacy : MonoBehaviour, IResourceStorage, IResourceStorageBase
{
	[Serializable]
	public class HallOfDiplomacySaveData : SaveClass<HallOfDiplomacy, HallOfDiplomacySaveData>
	{
		private ResourceAmount giftStored;

		private ResourceAmount giftTarget;

		public override HallOfDiplomacySaveData Pack(HallOfDiplomacy obj)
		{
			giftStored = obj.giftStored;
			giftTarget = obj.giftTarget;
			return this;
		}

		public override HallOfDiplomacy Unpack(HallOfDiplomacy obj)
		{
			obj.giftStored = giftStored;
			obj.giftTarget = giftTarget;
			if (obj.MakingGift())
			{
				obj.UpdateGatherType();
			}
			return obj;
		}
	}

	private int frgCount = 10;

	private int jobStart;

	public int[] gatherTypeOrder;

	internal ResourceAmount giftTarget;

	private ResourceAmount giftStored;

	public GameObject gift;

	public GameObject giftIcon;

	public Building b;

	public bool AcceptsType(int resourceID)
	{
		return true;
	}

	public void Deposit(ref ResourceAmount resources)
	{
		giftStored.Add(in resources);
		resources.Clear();
		ResourceAmount resourceAmount = new ResourceAmount();
		for (int i = 0; i < giftTarget.resources.Count; i++)
		{
			int resourceID = giftTarget.resources[i].resourceID;
			int num = giftTarget.resources[i].Amount - giftStored.Get(resourceID);
			if (num < 0)
			{
				resourceAmount.Set(resourceID, -num);
				giftStored.Set(resourceID, giftTarget.Get(resourceID));
			}
		}
		if (!resourceAmount.IsNone())
		{
			World.DropResources(b.Center() - new Vector3(0f, 0f, 0.25f), resourceAmount);
		}
	}

	public Vector3 DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	public int LandMass()
	{
		return b.LandMass();
	}

	public int MaxStorageFor(int resourceID)
	{
		return giftTarget.Get(resourceID);
	}

	public void RemoveResources(ResourceAmount amount)
	{
		giftStored -= amount;
	}

	private void OnBuildingPlacement(bool undo)
	{
		IEnumerable<Cloth> enumerable = Util.ComponentsInNodeAndAllDescendants<Cloth>(gameObject);
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(b.TeamID());
		foreach (Cloth item in enumerable)
		{
			item.GetComponent<SkinnedMeshRenderer>().material.mainTexture = landmassOwnerByTeamId.BannerTexture;
		}
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Combine(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
		gift.GetComponent<MeshRenderer>().material = landmassOwnerByTeamId.UniMaterialFogClip;
		giftIcon.GetComponent<MeshRenderer>().material = landmassOwnerByTeamId.UniMaterialFogClip;
	}

	public void UpdateBanners()
	{
		IEnumerable<Cloth> enumerable = Util.ComponentsInNodeAndAllDescendants<Cloth>(gameObject);
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(b.TeamID());
		foreach (Cloth item in enumerable)
		{
			item.GetComponent<SkinnedMeshRenderer>().material.mainTexture = landmassOwnerByTeamId.BannerTexture;
		}
	}

	private void OnShutdown()
	{
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Remove(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	public float GiftProgress()
	{
		float num = 0f;
		float num2 = 0f;
		for (int i = 0; i < giftTarget.resources.Count; i++)
		{
			int resourceID = giftTarget.resources[i].resourceID;
			num2 += (float)giftTarget.resources[i].Amount;
			num += (float)giftStored.Get(resourceID);
		}
		if (!(num2 > 0f))
		{
			return 0f;
		}
		return num / num2;
	}

	public void OnAddJobs()
	{
		int jobInitIdx = b.jobInitIdx;
		for (int i = jobInitIdx; i < jobInitIdx + frgCount; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b, _consumeOnPickup: true));
			}
			FreeResourceGathererJob obj = b.jobs[i] as FreeResourceGathererJob;
			obj.typeOrder = gatherTypeOrder;
			obj.bonusCarryCapacity = 2;
			obj.dropoffTargetOverride = this;
			b.jobInitIdx++;
		}
	}

	internal void StartMakingGift(ResourceAmount resourceAmount)
	{
		giftTarget = resourceAmount;
		UpdateGatherType();
		for (int i = jobStart; i < jobStart + frgCount; i++)
		{
			(b.jobs[i] as FreeResourceGathererJob).typeOrder = gatherTypeOrder;
		}
	}

	public void UpdateGatherType()
	{
		int num = 0;
		for (int i = 0; i < giftTarget.resources.Count; i++)
		{
			int resourceID = giftTarget.resources[i].resourceID;
			if (giftTarget.resources[i].Amount > 0 && resourceID != 4)
			{
				num++;
			}
		}
		gatherTypeOrder = new int[num];
		int num2 = 0;
		for (int j = 0; j < giftTarget.resources.Count; j++)
		{
			if (giftTarget.resources[j].Amount > 0 && giftTarget.resources[j].resourceID != 4)
			{
				gatherTypeOrder[num2] = giftTarget.resources[j].resourceID;
				num2++;
			}
		}
	}

	public int SpaceAvailable(int t)
	{
		return giftTarget.Get(t) - giftStored.Get(t);
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		return 0;
	}

	public bool StoresTypePublic(int resourceID)
	{
		return false;
	}

	public void CancelGift()
	{
		World.DropResources(transform.position, giftStored);
		giftStored = new ResourceAmount();
		giftTarget = new ResourceAmount();
	}

	public bool MakingGift()
	{
		if (giftTarget.IsNone())
		{
			return false;
		}
		for (int i = 0; i < giftTarget.resources.Count; i++)
		{
			int resourceID = giftTarget.resources[i].resourceID;
			if (giftStored.Get(resourceID) < giftTarget.resources[i].Amount && giftTarget.resources[i].Amount != 0)
			{
				return true;
			}
		}
		return false;
	}

	public bool HasGift()
	{
		if (giftStored >= giftTarget)
		{
			return !giftTarget.IsNone();
		}
		return false;
	}

	public ResourceAmount TakeGift()
	{
		EffectsMan.inst.BuildPuff.CreateAndPlay(gift.transform.position);
		ResourceAmount result = giftStored;
		giftStored = new ResourceAmount();
		giftTarget = new ResourceAmount();
		return result;
	}

	private void Update()
	{
		giftIcon.transform.Rotate(0f, Time.deltaTime * 60f, 0f);
		if (!giftIcon.activeSelf && HasGift() && b.TeamID() == 0)
		{
			MiniMapUIPing miniMapUIPing = UnityEngine.Object.Instantiate(MiniMapUI.inst.pingPrefab, MiniMapUI.inst.mapPingMarkerContainer);
			miniMapUIPing.maxflashCount = 2;
			miniMapUIPing.color = Color.green;
			miniMapUIPing.pingSpeed = 17f;
			miniMapUIPing.pingOpacityStrength = 0.75f;
			MiniMapUI.inst.PingAtWorldLocation(miniMapUIPing, b.Center());
		}
		gift.SetActive(HasGift());
		giftIcon.SetActive(HasGift());
		if (!TimeManager.inst.IsPaused() && giftStored.Get(4) < giftTarget.Get(4) && giftTarget.Get(4) != 0)
		{
			LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
			if (landmassOwner.Gold > 0)
			{
				landmassOwner.Gold--;
				giftStored.Add(4, 1);
			}
		}
	}
}
