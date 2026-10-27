using Assets.Code.Interface;
using UnityEngine;

public class Well : MonoBehaviour, IOverlayUser, IWorkerUIDisplay
{
	private Building b;

	[SerializeField]
	private bool isProvidingWater = true;

	public float minProtectionRadius = 4f;

	public float maxProtectionRadius = 7f;

	public float waterSupplyAvailable = 10f;

	public bool showWaterTowerRanges;

	public bool OverlayWhenPlacing => true;

	public bool OverlayWhenSelected => true;

	public void SetWaterAccess(bool isWater)
	{
		if (isWater)
		{
			WellManager.inst.AddWell(this);
		}
		else
		{
			WellManager.inst.RemoveWell(this);
		}
		isProvidingWater = isWater;
	}

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	private void OnBuilt()
	{
		if (isProvidingWater)
		{
			WellManager.inst.AddWell(this);
		}
	}

	private void OnFinishedLoad()
	{
		if (b.IsBuilt() && isProvidingWater)
		{
			WellManager.inst.AddWell(this);
		}
	}

	private void OnShutdown()
	{
		if (isProvidingWater)
		{
			WellManager.inst.RemoveWell(this);
		}
	}

	public void DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.ClearOverlay(updateToo: false);
		if (showWaterTowerRanges && (GameUI.inst.CurrPlacementMode.IsPlacing() || (!b.IsBuilt() && isProvidingWater)))
		{
			WaterTower.DrawWaterTowerOverlayForConsumers();
		}
		WellManager.inst.DrawOverlay();
		if (GameUI.inst.CurrPlacementMode.IsPlacing() || (!b.IsBuilt() && isProvidingWater))
		{
			WellManager.inst.DrawWellOverlay(this);
		}
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return false;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}

	public bool ShowVillagerList()
	{
		return true;
	}
}
