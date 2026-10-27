using System;
using Code;
using Unity.Jobs;
using UnityEngine;

[Unity.Jobs.DOTSCompilerGenerated]
internal class __JobReflectionRegistrationOutput__1221673671587648887
{
	public static void CreateJobReflectionData()
	{
		try
		{
			IJobParallelForExtensions.EarlyJobInit<BespokeCelebratingCitizens.UpdateGroupAnimations>();
			IJobExtensions.EarlyJobInit<CloudSystem.UpdateClouds>();
			IJobParallelForExtensions.EarlyJobInit<DynamicLava.UpdateFluxParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicLava.UpdateWaterHeightParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicLava.UpdateTextureParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicLava.BuildSimplifiedGridParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicLava.InitWaterParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.UpdateFluxParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.UpdateWaterHeightParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.AddWaterParallelJob>();
			IJobExtensions.EarlyJobInit<DynamicWater.SumWaterParallelJob>();
			IJobExtensions.EarlyJobInit<DynamicWater.ExtractWaterJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.UpdateTextureParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.AverageWaterFallParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.ExtractWaterFlowParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.UpdateWaterTopMovementParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.BuildSimplifiedGridParallelJob>();
			IJobExtensions.EarlyJobInit<DynamicWater.CompressWaterTileChangedJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.InitWaterParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.FilterWaterfallsArrayJob>();
			IJobExtensions.EarlyJobInit<DynamicWater.CompressWaterfallDataJob>();
			IJobParallelForExtensions.EarlyJobInit<DynamicWater.RaycastWaterJob>();
			IJobExtensions.EarlyJobInit<LegionSystem.UpdateRenderData>();
			IJobExtensions.EarlyJobInit<LegionSystem.UpdateGroups>();
			IJobExtensions.EarlyJobInit<FieldSystem.UpdateFields>();
			IJobExtensions.EarlyJobInit<FieldSystem.UpdateFruits>();
			IJobExtensions.EarlyJobInit<FishSystem.UpdateFish>();
			IJobParallelForExtensions.EarlyJobInit<TerrainGen.BurstTextureCopy>();
			IJobForExtensions.EarlyJobInit<TerrainGen.LandmassHeightDistanceJob>();
			IJobForExtensions.EarlyJobInit<TerrainGen.AggregateFertilityInformationJob>();
			IJobForExtensions.EarlyJobInit<TerrainGen.FertilityJob>();
			IJobParallelForExtensions.EarlyJobInit<TerrainGen.TerritoryTextureJob>();
			IJobParallelForExtensions.EarlyJobInit<TerrainGen.CreateMeshesParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<TerrainGen.UpdateTextureParallelJob>();
			IJobExtensions.EarlyJobInit<TerrainGen.SmoothYLessThanWaterTestThresholdParallelJob>();
			IJobExtensions.EarlyJobInit<TerrainGen.SmoothYGreaterThanWaterTestThresholdParallelJob>();
			IJobExtensions.EarlyJobInit<TerrainGen.SmoothYGreaterThanWaterHeightParallelJob>();
			IJobParallelForExtensions.EarlyJobInit<TerrainGen.PopulateRaycastCommandsJob>();
			IJobParallelForExtensions.EarlyJobInit<TerrainGen.BuildObstructionMapJob>();
			IJobParallelForExtensions.EarlyJobInit<Water.BuildBeachParallelJob>();
		}
		catch (Exception ex)
		{
			EarlyInitHelpers.JobReflectionDataCreationFailed(ex);
		}
	}

	[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterAssembliesLoaded)]
	public static void EarlyInit()
	{
		CreateJobReflectionData();
	}
}
