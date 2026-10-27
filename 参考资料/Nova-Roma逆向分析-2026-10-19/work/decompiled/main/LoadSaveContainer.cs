using System;
using System.Runtime.Serialization;
using Assets.Code;

[Serializable]
public class LoadSaveContainer : SaveClass<object, LoadSaveContainer>
{
	public Cam.CamSaveData CameraSaveData;

	public Player.PlayerSaveData PlayerSaveData;

	public World.WorldSaveData WorldSaveData;

	public JobSystem.JobSystemSaveData JobSystemSaveData;

	public FreeResourceManager.FreeResourceManagerSaveData FreeResourceManagerSaveData;

	public Weather.WeatherSaveData WeatherSaveData;

	public FireManager.FireManagerSaveData FireManagerSaveData;

	public DragonSpawn.DragonSpawnSaveData DragonSpawnSaveData;

	public TownNameUI.TownNameSaveData TownNameSaveData;

	public ShipSystem.ShipSystemSaveData ShipSystemSaveData;

	public AIBrainsContainer.SaveData AIBrainsSaveData;

	public RaiderSystem.RaiderSystemSaveData2 RaidSystemSaveData2;

	public SiegeMonster.SiegeMonsterSaveData SiegeMonsterSaveData;

	public OrdersManager.OrdersManagerSaveData OrdersManagerSaveData;

	public FishSystem.FishSystemSaveData FishSystemSaveData;

	public DeadVillagerSystem.DeadVillagerSystemSaveData DeadVillagerSystemSaveData;

	public SerializableDictionary<string, string> CustomSaveData;

	public CartSystem.CartSystemSaveData CartSystemSaveData;

	public SiegeCatapultSystem.SiegeCatapultSystemSaveData SiegeCatapultSystemSaveData;

	public MiniMapUI.MiniMapSaveData MiniMapSaveData;

	public DynamicWater.DynamicWaterSaveData DynamicWaterSaveData;

	public SeasonManager.SeasonManagerSaveData SeasonManagerSaveData;

	public ResourceStatistics.ResourceStatisticsSaveData ResourceStatisticsSaveData;

	public DemoScenario.DemoScenarioSaveData DemoScenarioSaveData;

	public EditTerrainProjectManager.EditTerrainProjectManagerSaveData EditTerrainProjectManagerSaveData;

	public GodManager.GodManagerSaveData GodManagerSaveData;

	[OptionalField(VersionAdded = 1)]
	public DamProjectManager.DamProjectManagerSaveData DamProjectManagerSaveData;

	[OptionalField(VersionAdded = 1)]
	public BuildingCollapseManager.BuildingCollapseManagerSaveData BuildingCollapseManagerSaveData;

	[OptionalField(VersionAdded = 1)]
	public MerchantOrdersManager.MerchantOrdersManagerSaveData MerchantOrdersManagerSaveData;

	[OptionalField(VersionAdded = 1)]
	public MilestoneManager.MilestoneManagerSaveData MilestoneManagerSaveData;

	[OptionalField(VersionAdded = 1)]
	public Creative.CreativeSaveData CreativeSaveData;

	[OptionalField(VersionAdded = 1)]
	public DifficultyManager.DifficultySaveData DifficultySaveData;

	[OptionalField(VersionAdded = 1)]
	public GladiatorSystem.GladiatorSystemSaveData GladiatorSystemSaveData;

	public LogisticsManager.LogisticsManagerSaveData logisticsSaveData;

	public LegionSystem.LegionSystemSaveData LegionSystemSaveData;

	public UnitSystem.UnitSystemSaveData UnitSystemSaveData;

	public override LoadSaveContainer Pack(object obj)
	{
		CameraSaveData = new Cam.CamSaveData().Pack(Cam.inst);
		TownNameSaveData = new TownNameUI.TownNameSaveData().Pack(TownNameUI.inst);
		PlayerSaveData = new Player.PlayerSaveData().Pack(Player.inst);
		WorldSaveData = new World.WorldSaveData().Pack(World.inst);
		FishSystemSaveData = new FishSystem.FishSystemSaveData().Pack(FishSystem.inst);
		DeadVillagerSystemSaveData = new DeadVillagerSystem.DeadVillagerSystemSaveData().Pack(DeadVillagerSystem.inst);
		JobSystemSaveData = new JobSystem.JobSystemSaveData().Pack(JobSystem.inst);
		FreeResourceManagerSaveData = new FreeResourceManager.FreeResourceManagerSaveData().Pack(FreeResourceManager.inst);
		WeatherSaveData = new Weather.WeatherSaveData().Pack(Weather.inst);
		FireManagerSaveData = new FireManager.FireManagerSaveData().Pack(FireManager.inst);
		DragonSpawnSaveData = new DragonSpawn.DragonSpawnSaveData().Pack(DragonSpawn.inst);
		LegionSystemSaveData = new LegionSystem.LegionSystemSaveData().Pack(LegionSystem.Inst);
		RaidSystemSaveData2 = new RaiderSystem.RaiderSystemSaveData2().Pack(RaiderSystem.inst);
		ShipSystemSaveData = new ShipSystem.ShipSystemSaveData().Pack(ShipSystem.inst);
		AIBrainsSaveData = new AIBrainsContainer.SaveData().Pack(AIBrainsContainer.inst);
		SiegeMonsterSaveData = new SiegeMonster.SiegeMonsterSaveData().Pack(null);
		CartSystemSaveData = new CartSystem.CartSystemSaveData().Pack(CartSystem.inst);
		SiegeCatapultSystemSaveData = new SiegeCatapultSystem.SiegeCatapultSystemSaveData().Pack(SiegeCatapultSystem.inst);
		OrdersManagerSaveData = new OrdersManager.OrdersManagerSaveData().Pack(OrdersManager.inst);
		UnitSystemSaveData = new UnitSystem.UnitSystemSaveData().Pack(UnitSystem.inst);
		DynamicWaterSaveData = new DynamicWater.DynamicWaterSaveData().Pack(DynamicWater.inst);
		SeasonManagerSaveData = new SeasonManager.SeasonManagerSaveData().Pack(SeasonManager.inst);
		ResourceStatisticsSaveData = new ResourceStatistics.ResourceStatisticsSaveData().Pack(ResourceStatistics.inst);
		if (World.inst.isDemo)
		{
			DemoScenarioSaveData = new DemoScenario.DemoScenarioSaveData().Pack(DemoScenario.inst);
		}
		EditTerrainProjectManagerSaveData = new EditTerrainProjectManager.EditTerrainProjectManagerSaveData().Pack(EditTerrainProjectManager.inst);
		GodManagerSaveData = new GodManager.GodManagerSaveData().Pack(GodManager.inst);
		DamProjectManagerSaveData = new DamProjectManager.DamProjectManagerSaveData().Pack(DamProjectManager.inst);
		BuildingCollapseManagerSaveData = new BuildingCollapseManager.BuildingCollapseManagerSaveData().Pack(BuildingCollapseManager.inst);
		MerchantOrdersManagerSaveData = new MerchantOrdersManager.MerchantOrdersManagerSaveData().Pack(MerchantOrdersManager.inst);
		MilestoneManagerSaveData = new MilestoneManager.MilestoneManagerSaveData().Pack(MilestoneManager.inst);
		CreativeSaveData = new Creative.CreativeSaveData().Pack(Creative.inst);
		DifficultySaveData = new DifficultyManager.DifficultySaveData().Pack(DifficultyManager.inst);
		if (GladiatorSystem.inst != null)
		{
			GladiatorSystemSaveData = new GladiatorSystem.GladiatorSystemSaveData().Pack(GladiatorSystem.inst);
		}
		logisticsSaveData = new LogisticsManager.LogisticsManagerSaveData().Pack(LogisticsManager.inst);
		CustomSaveData = LoadSave.CustomSaveData_DontAccessDirectly;
		return this;
	}

	public object UnpackThreaded(object obj)
	{
		LoadSave.RunOnMainThreadLater(() =>
		{
			Player.inst.Reset();
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			AIBrainsContainer.inst.ClearAIs();
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_creatingworld");
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			CameraSaveData.Unpack(Cam.inst);
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			WorldSaveData.Unpack(World.inst);
		});
		if (FishSystemSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				FishSystemSaveData.Unpack(FishSystem.inst);
			});
		}
		LoadSave.RunOnMainThreadLater(() =>
		{
			TownNameSaveData.Unpack(TownNameUI.inst);
		});
		if (AIBrainsSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				AIBrainsSaveData.UnpackPrePlayer(AIBrainsContainer.inst);
			});
		}
		if (SeasonManagerSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				SeasonManagerSaveData.Unpack(SeasonManager.inst);
			});
		}
		LoadSave.RunOnMainThreadLater(() =>
		{
			SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_constructingcity");
		});
		if (DynamicWaterSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				DynamicWaterSaveData.doTexturePriming = true;
				DynamicWaterSaveData.Unpack(DynamicWater.inst);
			});
		}
		if (BuildingCollapseManagerSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				BuildingCollapseManagerSaveData.Unpack(BuildingCollapseManager.inst);
			});
		}
		LoadSave.RunOnMainThreadLater(() =>
		{
			PlayerSaveData.Unpack(Player.inst);
		});
		if (LegionSystemSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				LegionSystemSaveData.Unpack(LegionSystem.Inst);
			});
		}
		LoadSave.RunOnMainThreadLater(() =>
		{
			DeadVillagerSystemSaveData.Unpack(DeadVillagerSystem.inst);
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			FreeResourceManagerSaveData.Unpack(FreeResourceManager.inst);
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_loadjobs");
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			JobSystemSaveData.Unpack(JobSystem.inst);
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			WeatherSaveData.Unpack(Weather.inst);
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			FireManagerSaveData.Unpack(FireManager.inst);
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			DragonSpawnSaveData.Unpack(DragonSpawn.inst);
		});
		if (SiegeMonsterSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				SiegeMonsterSaveData.Unpack(null);
			});
		}
		if (ShipSystemSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				ShipSystemSaveData.Unpack(ShipSystem.inst);
			});
		}
		if (RaidSystemSaveData2 != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				RaidSystemSaveData2.Unpack(RaiderSystem.inst);
			});
		}
		if (CartSystemSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				CartSystemSaveData.Unpack(CartSystem.inst);
			});
		}
		if (SiegeCatapultSystemSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				SiegeCatapultSystemSaveData.Unpack(SiegeCatapultSystem.inst);
			});
		}
		if (UnitSystemSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				UnitSystemSaveData.Unpack(UnitSystem.inst);
			});
		}
		if (OrdersManagerSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				OrdersManagerSaveData.Unpack(OrdersManager.inst);
			});
		}
		if (AIBrainsSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				AIBrainsSaveData.Unpack(AIBrainsContainer.inst);
			});
		}
		LoadSave.RunOnMainThreadLater(() =>
		{
			SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_createwater");
		});
		if (CustomSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				LoadSave.CustomSaveData_DontAccessDirectly = CustomSaveData;
			});
		}
		if (ResourceStatisticsSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				ResourceStatisticsSaveData.Unpack(ResourceStatistics.inst);
			});
		}
		LoadSave.RunOnMainThreadLater(() =>
		{
			Player.inst.RefreshVisibility(force: true);
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			for (int i = 0; i < Player.inst.Buildings.Count; i++)
			{
				Player.inst.Buildings.data[i].UpdateMaterialSelection();
			}
		});
		if (DemoScenarioSaveData != null)
		{
			LoadSave.RunOnMainThreadLater(() =>
			{
				DemoScenarioSaveData.Unpack(DemoScenario.inst);
			});
		}
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (EditTerrainProjectManagerSaveData != null)
			{
				EditTerrainProjectManagerSaveData.Unpack(EditTerrainProjectManager.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (GodManagerSaveData != null)
			{
				GodManagerSaveData.Unpack(GodManager.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (DamProjectManagerSaveData != null)
			{
				DamProjectManagerSaveData.Unpack(DamProjectManager.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (MerchantOrdersManagerSaveData != null)
			{
				MerchantOrdersManagerSaveData.Unpack(MerchantOrdersManager.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (MilestoneManagerSaveData != null)
			{
				MilestoneManagerSaveData.Unpack(MilestoneManager.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (CreativeSaveData != null)
			{
				CreativeSaveData.Unpack(Creative.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (DifficultySaveData != null)
			{
				DifficultySaveData.Unpack(DifficultyManager.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (GladiatorSystemSaveData != null && GladiatorSystem.inst != null)
			{
				GladiatorSystemSaveData.Unpack(GladiatorSystem.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			if (logisticsSaveData != null)
			{
				logisticsSaveData.Unpack(LogisticsManager.inst);
			}
		});
		LoadSave.RunOnMainThreadLater(() =>
		{
			Player.inst.loadTickDelay = 1;
			JobSystem.inst.loadTickDelay = 1;
			GameUI.inst.Reset();
		});
		return obj;
	}

	public override object Unpack(object obj)
	{
		Player.inst.Reset();
		AIBrainsContainer.inst.ClearAIs();
		SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_creatingworld");
		CameraSaveData.Unpack(Cam.inst);
		WorldSaveData.Unpack(World.inst);
		if (FishSystemSaveData != null)
		{
			FishSystemSaveData.Unpack(FishSystem.inst);
		}
		TownNameSaveData.Unpack(TownNameUI.inst);
		if (AIBrainsSaveData != null)
		{
			AIBrainsSaveData.UnpackPrePlayer(AIBrainsContainer.inst);
		}
		if (SeasonManagerSaveData != null)
		{
			SeasonManagerSaveData.Unpack(SeasonManager.inst);
		}
		SaveGameLoadingScreen.inst.SetTerm("loadingscreen_status_constructingcity");
		if (BuildingCollapseManagerSaveData != null)
		{
			BuildingCollapseManagerSaveData.Unpack(BuildingCollapseManager.inst);
		}
		PlayerSaveData.Unpack(Player.inst);
		if (LegionSystemSaveData != null)
		{
			LegionSystemSaveData.Unpack(LegionSystem.Inst);
		}
		DeadVillagerSystemSaveData.Unpack(DeadVillagerSystem.inst);
		FreeResourceManagerSaveData.Unpack(FreeResourceManager.inst);
		JobSystemSaveData.Unpack(JobSystem.inst);
		WeatherSaveData.Unpack(Weather.inst);
		FireManagerSaveData.Unpack(FireManager.inst);
		DragonSpawnSaveData.Unpack(DragonSpawn.inst);
		if (SiegeMonsterSaveData != null)
		{
			SiegeMonsterSaveData.Unpack(null);
		}
		if (ShipSystemSaveData != null)
		{
			ShipSystemSaveData.Unpack(ShipSystem.inst);
		}
		if (RaidSystemSaveData2 != null)
		{
			RaidSystemSaveData2.Unpack(RaiderSystem.inst);
		}
		if (CartSystemSaveData != null)
		{
			CartSystemSaveData.Unpack(CartSystem.inst);
		}
		if (SiegeCatapultSystemSaveData != null)
		{
			SiegeCatapultSystemSaveData.Unpack(SiegeCatapultSystem.inst);
		}
		if (UnitSystemSaveData != null)
		{
			UnitSystemSaveData.Unpack(UnitSystem.inst);
		}
		if (OrdersManagerSaveData != null)
		{
			OrdersManagerSaveData.Unpack(OrdersManager.inst);
		}
		if (AIBrainsSaveData != null)
		{
			AIBrainsSaveData.Unpack(AIBrainsContainer.inst);
		}
		if (DynamicWaterSaveData != null)
		{
			DynamicWaterSaveData.Unpack(DynamicWater.inst);
		}
		if (CustomSaveData != null)
		{
			LoadSave.CustomSaveData_DontAccessDirectly = CustomSaveData;
		}
		if (ResourceStatisticsSaveData != null)
		{
			ResourceStatisticsSaveData.Unpack(ResourceStatistics.inst);
		}
		if (EditTerrainProjectManagerSaveData != null)
		{
			EditTerrainProjectManagerSaveData.Unpack(EditTerrainProjectManager.inst);
		}
		if (GodManagerSaveData != null)
		{
			GodManagerSaveData.Unpack(GodManager.inst);
		}
		if (DamProjectManagerSaveData != null)
		{
			DamProjectManagerSaveData.Unpack(DamProjectManager.inst);
		}
		if (MerchantOrdersManagerSaveData != null)
		{
			MerchantOrdersManagerSaveData.Unpack(MerchantOrdersManager.inst);
		}
		if (MilestoneManagerSaveData != null)
		{
			MilestoneManagerSaveData.Unpack(MilestoneManager.inst);
		}
		if (CreativeSaveData != null)
		{
			CreativeSaveData.Unpack(Creative.inst);
		}
		if (DifficultySaveData != null)
		{
			DifficultySaveData.Unpack(DifficultyManager.inst);
		}
		if (GladiatorSystemSaveData != null && GladiatorSystem.inst != null)
		{
			GladiatorSystemSaveData.Unpack(GladiatorSystem.inst);
		}
		if (logisticsSaveData != null)
		{
			logisticsSaveData.Unpack(LogisticsManager.inst);
		}
		Player.inst.RefreshVisibility(force: true);
		for (int i = 0; i < Player.inst.Buildings.Count; i++)
		{
			Player.inst.Buildings.data[i].UpdateMaterialSelection();
		}
		if (DemoScenarioSaveData != null)
		{
			DemoScenarioSaveData.Unpack(DemoScenario.inst);
		}
		Player.inst.loadTickDelay = 1;
		JobSystem.inst.loadTickDelay = 1;
		return obj;
	}
}
