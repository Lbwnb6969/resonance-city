using System;
using UnityEngine;

public class FlagMaterialUpdater : MonoBehaviour
{
	private void Start()
	{
	}

	private void OnDisable()
	{
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Remove(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	private void OnEnable()
	{
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Combine(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
		UpdateBanners();
	}

	public void UpdateBanners()
	{
		Vector3 position = transform.position;
		Cell cellDataClamped = World.inst.GetCellDataClamped(position);
		if (cellDataClamped != null)
		{
			LandmassOwner landmassOwner = World.GetLandmassOwner(cellDataClamped.landMassIdx);
			if (landmassOwner == null)
			{
				landmassOwner = Player.inst.PlayerLandmassOwner;
			}
			GetComponent<MeshRenderer>().material = landmassOwner.FlagMaterial;
		}
	}
}
