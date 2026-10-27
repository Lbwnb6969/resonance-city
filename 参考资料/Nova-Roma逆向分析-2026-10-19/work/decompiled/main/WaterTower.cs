using System;
using System.Collections.Generic;
using Assets.Code.Interface;
using UnityEngine;

public class WaterTower : AqueductBuilding, IOverlayUser, IWorkerUIDisplay, IOutputInfo
{
	public WaterSupplier waterSupplier;

	private WaterConsumer selfConsumer;

	private EventHandler<OnBuildingOpenClose> openCloseHandler;

	[NonSerialized]
	public static bool doDeferredWaterTowerMapRecreation = false;

	private WaterError waterError;

	private static List<WaterTower> WaterTowers = new List<WaterTower>();

	private static int watertowerHash = "watertower".GetHashCode();

	public bool OverlayWhenPlacing => true;

	public bool OverlayWhenSelected => true;

	private void Awake()
	{
		b.PlacementValidaton = PlacementValidation;
		waterSupplier.SetupChangeCallback(WaterConsumptionChanged);
	}

	private void PlacementValidation(ref PlacementValidationResult result)
	{
		Cell cell = b.GetCell();
		if (result != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		bool flag = false;
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			if (cell.OccupyingStructure[i].categoryHash == World.pathHash)
			{
				flag = true;
				continue;
			}
			flag = false;
			break;
		}
		if (flag)
		{
			result = PlacementValidationResult.Valid;
		}
	}

	public void WaterConsumptionChanged()
	{
		SetConsumption(b.IsOpen() ? waterSupplier.waterLoad : 0f);
	}

	private void EnsureSelfWaterConsumer()
	{
		if (selfConsumer == null)
		{
			selfConsumer = GetComponent<WaterConsumer>();
			if (selfConsumer == null)
			{
				selfConsumer = gameObject.AddComponent<WaterConsumer>();
			}
		}
		selfConsumer.b = b;
		selfConsumer.consumptionRate = 1f;
		waterSupplier.AddConsumer(selfConsumer);
	}

	private void OnFinishedLoad()
	{
		if (b.IsBuilt())
		{
			RegisterWaterTower(this);
			EnsureSelfWaterConsumer();
			SubscribeOpenClose();
		}
	}

	public static void UpdateDeferredWaterTowerMapRecreation()
	{
		if (!doDeferredWaterTowerMapRecreation)
		{
			return;
		}
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if ((buildingSelected != null && buildingSelected.uniqueNameHash == World.waterTowerHash) || GameUI.inst.CurrPlacementMode.heldPrefab?.uniqueNameHash == World.waterTowerHash)
		{
			WaterTower waterTower = GameUI.inst.GetBuildingSelected()?.GetComponent<WaterTower>();
			if (waterTower == null && GameUI.inst.CurrPlacementMode.buildings.Count > 0)
			{
				List<Building> buildings = GameUI.inst.CurrPlacementMode.buildings;
				waterTower = buildings[buildings.Count - 1].GetComponent<WaterTower>();
			}
			RecreateWaterTowerMap(waterTower.Center(), waterTower);
		}
		doDeferredWaterTowerMapRecreation = false;
	}

	private void UpdateState()
	{
		waterError = UpdateWaterErrorState();
		ApplyWaterErrorThought(waterError);
	}

	public override void UpdateWaterFlow()
	{
		base.UpdateWaterFlow();
		UpdateState();
		waterSupplier.AvailableWaterChanged(b.IsOpen() ? waterFlow : 0f);
		if (!LoadSave.Loading)
		{
			doDeferredWaterTowerMapRecreation = true;
		}
	}

	public string GetError()
	{
		return AqueductBuilding.GetErrorString(waterError);
	}

	private static void RegisterWaterTower(WaterTower WaterTower)
	{
		WaterTowers.Add(WaterTower);
	}

	private static void DeregisterWaterTower(WaterTower WaterTower)
	{
		WaterTowers.Remove(WaterTower);
	}

	public static void DrawWaterTowerOverlayForConsumers()
	{
		Color waterTowerHasWaterHighlight = Player.inst.waterTowerHasWaterHighlight;
		TerrainGen.inst.ClearOverlay(updateToo: false);
		for (int i = 0; i < WaterTowers.Count; i++)
		{
			WaterTower waterTower = WaterTowers[i];
			Vector3 center2D = waterTower.b.GetCell().Center2D;
			if (Player.inst.LandMassIsAPlayerLandMass(waterTower.b.LandMass()))
			{
				SetWaterTowerPixels(waterTower, center2D, waterTower.waterSupplier.radiusMax, waterTowerHasWaterHighlight * 0.7f);
			}
		}
		TerrainGen.inst.ApplyBuildingOverlayMaterial();
		TerrainGen.inst.UpdateOverlayTextures();
	}

	public static void SetBuildingColorForConusmer(WaterConsumer consumer)
	{
		if (consumer.availableWaterPercentage <= 0f)
		{
			consumer.b.SetInfoColor(Player.inst.buildingNoWater, apply: false);
		}
		else if (consumer.availableWaterPercentage >= 0.96f)
		{
			consumer.b.SetInfoColor(Player.inst.buildingHasWater, apply: false);
		}
		else
		{
			consumer.b.SetInfoColor(Player.inst.buildingHasWaterPartial, apply: false);
		}
		TerrainGen.inst.AddBuildingToOverlay(consumer.b);
	}

	private static void RecreateWaterTowerMap(Vector3 origin, WaterTower WaterTower)
	{
		Color waterTowerHasWater = Player.inst.waterTowerHasWater;
		Color waterTowerHasWaterHighlight = Player.inst.waterTowerHasWaterHighlight;
		Color waterTowerNoWaterHighlight = Player.inst.waterTowerNoWaterHighlight;
		Color waterTowerNoWater = Player.inst.waterTowerNoWater;
		Color buildingNoWater = Player.inst.buildingNoWater;
		TerrainGen.inst.ClearOverlay(updateToo: false);
		for (int i = 0; i < WaterTowers.Count; i++)
		{
			WaterTower waterTower = WaterTowers[i];
			Vector3 center2D = waterTower.b.GetCell().Center2D;
			if (Player.inst.LandMassIsAPlayerLandMass(waterTower.b.LandMass()) && !waterTower.HasWater())
			{
				SetWaterTowerPixels(waterTower, center2D, waterTower.waterSupplier.radiusMax, waterTowerNoWater);
			}
		}
		if ((bool)WaterTower && !WaterTower.HasWater())
		{
			SetWaterTowerPixels(WaterTower, origin, WaterTower.waterSupplier.radiusMax, waterTowerNoWaterHighlight);
		}
		for (int j = 0; j < WaterTowers.Count; j++)
		{
			WaterTower waterTower2 = WaterTowers[j];
			Vector3 center2D = waterTower2.b.GetCell().Center2D;
			if (Player.inst.LandMassIsAPlayerLandMass(waterTower2.b.LandMass()) && waterTower2.HasWater())
			{
				SetWaterTowerPixels(waterTower2, center2D, waterTower2.waterSupplier.radiusMax, waterTowerHasWater);
			}
		}
		if ((bool)WaterTower && WaterTower.HasWater())
		{
			SetWaterTowerPixels(WaterTower, origin, WaterTower.waterSupplier.radiusMax, waterTowerHasWaterHighlight);
		}
		int num = -1;
		if ((bool)WaterTower)
		{
			num = World.inst.GetCellDataClamped(WaterTower.transform.position).landMassIdx;
		}
		if (num == -1)
		{
			num = Player.inst.FocusedLandMass;
		}
		if (num != -1)
		{
			ArrayExt<WaterConsumer> consumersForLandmass = WaterConsumer.GetConsumersForLandmass(num);
			for (int k = 0; k < consumersForLandmass.Count; k++)
			{
				if (consumersForLandmass.data[k].availableWaterPercentage <= 0f)
				{
					consumersForLandmass.data[k].b.SetInfoColor(buildingNoWater, apply: false);
					TerrainGen.inst.AddBuildingToOverlay(consumersForLandmass.data[k].b);
				}
			}
		}
		for (int l = 0; l < WaterTowers.Count; l++)
		{
			List<WaterConsumer> consumers = WaterTowers[l].waterSupplier.consumers;
			for (int m = 0; m < consumers.Count; m++)
			{
				SetBuildingColorForConusmer(consumers[m]);
			}
		}
		if ((bool)WaterTower)
		{
			List<WaterConsumer> consumers2 = WaterTower.waterSupplier.consumers;
			for (int n = 0; n < consumers2.Count; n++)
			{
				SetBuildingColorForConusmer(consumers2[n]);
			}
		}
		TerrainGen.inst.ApplyBuildingOverlayMaterial();
		TerrainGen.inst.UpdateOverlayTextures();
	}

	private static void SetWaterTowerPixels(WaterTower wt, Vector3 pos, float radius, Color color)
	{
		World.inst.ForEachTileTouchingRadius(pos, radius, (int x, int z, Cell cell) =>
		{
			TerrainGen.inst.SetOverlayTileColor(x, z, color);
		});
	}

	public void DrawOverlay(Vector3 origin)
	{
		RecreateWaterTowerMap(origin, this);
		TerrainGen.inst.FadeOverlay(1f);
	}

	private void OnBuilt()
	{
		UpdateState();
		RegisterWaterTower(this);
		EnsureSelfWaterConsumer();
		SubscribeOpenClose();
	}

	private void OnShutdown()
	{
		DeregisterWaterTower(this);
		if (selfConsumer != null)
		{
			waterSupplier.RemoveConsumer(selfConsumer);
		}
		waterFlow = 0f;
		UnsubscribeOpenClose();
	}

	public override void OnDestroy()
	{
		UnsubscribeOpenClose();
		base.OnDestroy();
	}

	private void SubscribeOpenClose()
	{
		if (openCloseHandler == null)
		{
			openCloseHandler = Broadcast.BuildingOpenClose.Listen(World.waterTowerHash, OnOpenClose);
		}
	}

	private void UnsubscribeOpenClose()
	{
		if (openCloseHandler != null)
		{
			Broadcast.BuildingOpenClose.Unlisten(World.waterTowerHash, openCloseHandler);
			openCloseHandler = null;
		}
	}

	private void OnOpenClose(object sender, OnBuildingOpenClose data)
	{
		if (!(data.targetBuilding != b))
		{
			SetConsumption(data.open ? waterSupplier.waterLoad : 0f);
			waterSupplier.AvailableWaterChanged(data.open ? waterFlow : 0f);
		}
	}

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	internal static bool IsTileInRangeOfTowers(Cell cell)
	{
		int landMassIdx = cell.landMassIdx;
		for (int i = 0; i < WaterTowers.Count; i++)
		{
			if (landMassIdx == WaterTowers[i].GetLandMass() && World.inst.TileTouchingRadius(cell, WaterTowers[i].b.GetCell().Center2D, WaterTowers[i].waterSupplier.radiusMax))
			{
				return true;
			}
		}
		return false;
	}
}
