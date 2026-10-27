using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Runtime.Serialization;
using Assets;
using Assets.Code;
using Assets.Interface;
using Code;
using FMODUnity;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class World : MonoBehaviour
{
	public delegate void wolfDenClear(int landmassIdx, int teamID);

	public delegate List<Cell> PathingFunction(Cell start, Cell end);

	[Serializable]
	public class Livery
	{
		public Texture banners;

		public Material bannerMaterial;

		public Color bannerColor;

		public Color mapColor;

		public Material uniMaterial;

		public Material uniMaterialTerrainForm;

		public Material buildingMaterial;

		public Material armyMaterial;

		public Material armyMaterialUnlit;

		public Material buildUIMaterial;

		public Material flagMaterial;

		public Material uniMaterialCracked;

		public Material uniMaterialFogClip;

		public Material[] headMaterials;

		public Sprite knightSprite;

		public Sprite archerSprite;

		public Sprite catapultSprite;

		public Sprite settlerSprite;

		public Sprite transportSprite;

		public Sprite seedSprite;

		public Sprite envoySprite;
	}

	public enum MapSize
	{
		Small,
		Medium,
		Large,
		Random
	}

	[Serializable]
	public struct MapSizeDef
	{
		public int GridMin;

		public int GridMax;

		public int DesiredTiles;
	}

	[Serializable]
	public class WaterGenSettings
	{
		public float waterFreqSmall = 5f;

		public float waterFreqMedium = 5f;

		public float waterFreqLarge = 5f;

		public float waterThresholdSmall = 0.3f;

		public float waterThresholdMedium = 0.3f;

		public float waterThresholdLarge = 0.3f;

		public int borderGrowth = 3;
	}

	public enum MapBias
	{
		Land,
		Island,
		Random
	}

	public enum MapRiverAmount
	{
		Normal,
		High,
		VeryHigh
	}

	public enum MapResourceAmount
	{
		Low,
		Normal,
		High
	}

	[Serializable]
	public class IslandSignature
	{
		public int stone;

		public int largeStone;

		public List<TreeGrowth.TreeSplotData> treeSplots;

		public List<FishSystem.FishSplotData> fishSplots;
	}

	[Serializable]
	public struct ResourceAmountCounts
	{
		public int low;

		public int normal;

		public int high;

		public int Get(MapResourceAmount amount)
		{
			return amount switch
			{
				MapResourceAmount.High => high, 
				MapResourceAmount.Low => low, 
				_ => normal, 
			};
		}
	}

	[Serializable]
	public struct SizeToDepostsInfo
	{
		public ResourceAmountCounts numIronLand;

		public ResourceAmountCounts numIronIsland;

		public ResourceAmountCounts numStoneLand;

		public ResourceAmountCounts numStoneIsland;

		public ResourceAmountCounts numMarbleLand;

		public ResourceAmountCounts numMarbleIsland;

		public int numLargeStone;
	}

	[Serializable]
	public class KingdomHeadInfo
	{
		public GameObject headPrefabs;

		public bool maleHonorific;
	}

	private class LandmassStartInfo
	{
		public int numTreeTiles;

		public int numFertileTiles;

		public int numStones;

		public int numIrons;

		public int size;

		public int landmass;
	}

	public class DemolishPending
	{
		public Building building;

		public bool doEffects;

		public ResourceAmount refundAmt = new ResourceAmount();
	}

	public delegate void EvaluateCell(int x, int z, Cell cell);

	public delegate bool EvaluateIsValidCell(int x, int z, Cell cell);

	public delegate void EvaluateBoundsCell(Vector3 originPos, int x, int z, Cell cell);

	public struct LandmassCenter
	{
		public Vector3 center;

		public int xTotal;

		public int zTotal;

		public int count;
	}

	public enum Relations
	{
		Neutral,
		Allies,
		Enemy
	}

	[Serializable]
	public class WorldSaveData : SaveClass<World, WorldSaveData>
	{
		[Serializable]
		public struct MountainData
		{
			public int mountainGroupID;

			public int rockIdx;

			public SerializableVector3 pos;

			public SerializableQuaternion rot;

			public SerializableVector3 scale;
		}

		[OptionalField(VersionAdded = 2)]
		public int seed;

		public int generatedMapBias;

		public int generatedMapSize;

		public int generatedRiverLakes;

		public int generatedResourceAmount;

		public SerializableGuid guid;

		public int gridWidth;

		public int gridHeight;

		public Cell.CellSaveData[] cellSaveData;

		public int[][] landmassCells;

		public int numOfLandmasses;

		[OptionalField(VersionAdded = 3)]
		public List<WolfDen.WolfDenSaveData> wolfDens = new List<WolfDen.WolfDenSaveData>();

		[OptionalField(VersionAdded = 4)]
		public bool placedCavesWitches;

		[OptionalField(VersionAdded = 5)]
		public bool placedFish;

		[OptionalField(VersionAdded = 5)]
		public bool inFirstPlacementPhase;

		public List<TerrainResource.TerrainResourceSaveData> terrainResources = new List<TerrainResource.TerrainResourceSaveData>();

		[OptionalField(VersionAdded = 6)]
		private Relations[,] hostility;

		[OptionalField(VersionAdded = 8)]
		private float[] heightCache;

		[OptionalField(VersionAdded = 13)]
		private float[] originalHeightCache;

		[OptionalField(VersionAdded = 11)]
		private byte[] tempEffectData;

		[OptionalField(VersionAdded = 11)]
		private byte[] currFertilityData;

		[OptionalField(VersionAdded = 11)]
		private float tempEffectTimeCode;

		[OptionalField(VersionAdded = 11)]
		private float fertilityUnscaledTime;

		[OptionalField(VersionAdded = 12)]
		private byte[] grassVisibilityData;

		[OptionalField(VersionAdded = 12)]
		private float grassVisibilityTimeCode;

		[OptionalField(VersionAdded = 8)]
		private int[] treeAmount;

		[OptionalField(VersionAdded = 8)]
		private int[] dryGrassAmount;

		[OptionalField(VersionAdded = 8)]
		private int[] grassAmount;

		[OptionalField(VersionAdded = 8)]
		private int[] rockAmount;

		[OptionalField(VersionAdded = 8)]
		private List<MountainData> mountainData;

		[OptionalField(VersionAdded = 9)]
		private float[] obstructionCache;

		[OptionalField(VersionAdded = 10)]
		private bool isDemo;

		[OptionalField(VersionAdded = 10)]
		private int[] bushesAmount;

		public float[] fertilityNoise;

		public int[] fertility;

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			wolfDens = new List<WolfDen.WolfDenSaveData>();
			placedCavesWitches = false;
			placedFish = false;
			terrainResources = new List<TerrainResource.TerrainResourceSaveData>();
			guid = Guid.Empty;
			generatedResourceAmount = 1;
		}

		public override WorldSaveData Pack(World w)
		{
			gridWidth = w.GridWidth;
			gridHeight = w.GridHeight;
			seed = w.seed;
			generatedMapBias = (int)w.generatedMapsBias;
			generatedMapSize = (int)w.generatedMapSize;
			generatedRiverLakes = (int)w.generatedRiverLakes;
			generatedResourceAmount = (int)w.generatedResourceAmount;
			guid = w.guid;
			cellSaveData = new Cell.CellSaveData[gridWidth * gridHeight];
			for (int i = 0; i < cellSaveData.Length; i++)
			{
				cellSaveData[i] = new Cell.CellSaveData();
				cellSaveData[i].CopyFrom(w.cellData[i]);
			}
			numOfLandmasses = w.numLandMasses;
			treeAmount = new int[gridWidth * gridHeight];
			for (int j = 0; j < treeAmount.Length; j++)
			{
				treeAmount[j] = w.treeSystem.ItemAmount(j);
			}
			rockAmount = new int[gridWidth * gridHeight];
			for (int k = 0; k < rockAmount.Length; k++)
			{
				rockAmount[k] = w.rockScatterSystem.ItemAmount(k);
			}
			bushesAmount = new int[gridWidth * gridHeight];
			for (int l = 0; l < bushesAmount.Length; l++)
			{
				bushesAmount[l] = w.bushesSystem.ItemAmount(l);
			}
			landmassCells = new int[w.cellsToLandmass.Length][];
			for (int m = 0; m < w.cellsToLandmass.Length; m++)
			{
				ArrayExt<Cell> arrayExt = w.cellsToLandmass[m];
				landmassCells[m] = new int[arrayExt.Count];
				int n = 0;
				for (int count = arrayExt.Count; n < count; n++)
				{
					landmassCells[m][n] = arrayExt.data[n].index;
				}
			}
			heightCache = new float[TerrainGen.inst.heightCache.Length];
			float[] array = TerrainGen.inst.heightCache;
			Buffer.BlockCopy(array, 0, heightCache, 0, 4 * array.Length);
			if (TerrainGen.inst.originalHeightCache != null)
			{
				originalHeightCache = new float[TerrainGen.inst.originalHeightCache.Length];
				Buffer.BlockCopy(TerrainGen.inst.originalHeightCache, 0, originalHeightCache, 0, 4 * array.Length);
			}
			tempEffectData = TerrainGen.inst.temporaryTerrainEffectsTexture.GetRawTextureData();
			tempEffectTimeCode = TerrainGen.inst.tempEffectTimeCode;
			currFertilityData = TerrainGen.inst.currFertilityTexture.GetRawTextureData();
			fertilityUnscaledTime = TerrainGen.inst.FertilityBlendTime;
			grassVisibilityData = TerrainGen.inst.grassVisibilityTexture.GetRawTextureData();
			grassVisibilityTimeCode = TerrainGen.inst.grassEffectTimeCode;
			mountainData = new List<MountainData>(32);
			for (int num = 0; num < TerrainGen.inst.mountainRocks.Count; num++)
			{
				Transform transform = TerrainGen.inst.mountainRocks[num].transform;
				MountainPlacer component = transform.GetComponent<MountainPlacer>();
				Transform transform2 = ((component != null) ? component.RocksContainer : transform);
				for (int num2 = 0; num2 < transform2.childCount; num2++)
				{
					Transform child = transform2.GetChild(num2);
					if (!child.gameObject.activeSelf)
					{
						continue;
					}
					MountainData item = new MountainData
					{
						pos = child.position,
						rot = child.rotation,
						scale = child.localScale,
						mountainGroupID = num
					};
					MeshFilter component2 = child.GetComponent<MeshFilter>();
					if (component2 == null)
					{
						continue;
					}
					for (int num3 = 0; num3 < TerrainGen.inst.mountainRockMeshes.Count; num3++)
					{
						if (!(component2.sharedMesh != TerrainGen.inst.mountainRockMeshes[num3]))
						{
							item.rockIdx = num3;
							break;
						}
					}
					mountainData.Add(item);
				}
			}
			for (int num4 = 0; num4 < w.caveContainer.transform.childCount; num4++)
			{
				WolfDen component3 = w.caveContainer.transform.GetChild(num4).GetComponent<WolfDen>();
				if (component3 != null)
				{
					WolfDen.WolfDenSaveData item2 = new WolfDen.WolfDenSaveData().Pack(component3);
					wolfDens.Add(item2);
				}
			}
			for (int num5 = 0; num5 < TerrainResource.terrainResources.Count; num5++)
			{
				TerrainResource terrainResource = TerrainResource.terrainResources.data[num5];
				if (terrainResource != null)
				{
					TerrainResource.TerrainResourceSaveData item3 = new TerrainResource.TerrainResourceSaveData().Pack(terrainResource);
					terrainResources.Add(item3);
				}
			}
			placedCavesWitches = w.placedCavesWitches;
			placedFish = w.placedFish;
			inFirstPlacementPhase = w.inFirstPlacementPhase;
			hostility = w.hostility;
			float[] rawFertilityNoise = TerrainGen.inst.RawFertilityNoise;
			fertilityNoise = new float[rawFertilityNoise.Length];
			Buffer.BlockCopy(rawFertilityNoise, 0, fertilityNoise, 0, fertilityNoise.Length * 4);
			int[] array2 = TerrainGen.inst.Fertility;
			fertility = new int[array2.Length];
			Buffer.BlockCopy(array2, 0, fertility, 0, array2.Length * 4);
			isDemo = w.isDemo;
			return this;
		}

		public override World Unpack(World w)
		{
			w.seed = seed;
			w.Setup(gridWidth, gridHeight);
			TerrainGen.inst.tempEffectTimeCode = tempEffectTimeCode;
			TerrainGen.inst.FertilityBlendTime = fertilityUnscaledTime;
			if (tempEffectData != null)
			{
				TerrainGen.inst.temporaryTerrainEffectsTexture.LoadRawTextureData(tempEffectData);
				TerrainGen.inst.temporaryTerrainEffectsTexture.Apply();
			}
			if (currFertilityData != null)
			{
				TerrainGen.inst.currFertilityTexture.LoadRawTextureData(currFertilityData);
				TerrainGen.inst.currFertilityTexture.Apply();
			}
			TerrainGen.inst.grassEffectTimeCode = grassVisibilityTimeCode;
			if (grassVisibilityData != null)
			{
				TerrainGen.inst.grassVisibilityTexture.LoadRawTextureData(grassVisibilityData);
				TerrainGen.inst.grassVisibilityTexture.Apply();
			}
			float[] dst = TerrainGen.inst.heightCache;
			Buffer.BlockCopy(heightCache, 0, dst, 0, 4 * heightCache.Length);
			if (originalHeightCache != null)
			{
				TerrainGen.inst.originalHeightCache = new float[originalHeightCache.Length];
				Array.Copy(originalHeightCache, TerrainGen.inst.originalHeightCache, originalHeightCache.Length);
			}
			else
			{
				TerrainGen.inst.CaptureOriginalHeights();
			}
			TerrainGen.inst.terrainSkirt.RebuildSkirt();
			TerrainGen.inst.SetTerrainHighestY();
			Transform transform = TerrainGen.inst.mountainContainer;
			if (transform == null)
			{
				transform = new GameObject("Mountain Container").transform;
				TerrainGen.inst.mountainContainer = transform;
			}
			int num = -1;
			Transform transform2 = transform;
			for (int i = 0; i < this.mountainData.Count; i++)
			{
				MountainData mountainData = this.mountainData[i];
				if (num != mountainData.mountainGroupID)
				{
					num = mountainData.mountainGroupID;
					Transform transform3 = new GameObject("Mountain Group: " + mountainData.mountainGroupID).transform;
					transform3.SetParent(transform);
					transform2 = transform3;
					TerrainGen.inst.mountainRocks.Add(transform2.gameObject);
				}
				GameObject gameObject = new GameObject("Mountain Rock: " + i);
				gameObject.layer = LayerMask.NameToLayer("Terrain");
				gameObject.transform.SetParent(transform2, worldPositionStays: true);
				MeshFilter meshFilter = gameObject.AddComponent<MeshFilter>();
				MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
				MeshCollider meshCollider = gameObject.AddComponent<MeshCollider>();
				gameObject.AddComponent<WaterDisplacementMesh>();
				meshFilter.mesh = TerrainGen.inst.mountainRockMeshes[mountainData.rockIdx];
				meshRenderer.material = w.romeMountainUnimaterial;
				meshCollider.sharedMesh = meshFilter.sharedMesh;
				gameObject.transform.position = mountainData.pos;
				gameObject.transform.rotation = mountainData.rot;
				gameObject.transform.localScale = mountainData.scale;
			}
			w.generatedMapsBias = (MapBias)generatedMapBias;
			w.generatedMapSize = (MapSize)generatedMapSize;
			w.generatedRiverLakes = (MapRiverAmount)generatedRiverLakes;
			w.generatedResourceAmount = (MapResourceAmount)generatedResourceAmount;
			w.guid = guid;
			w.numLandMasses = numOfLandmasses;
			if (bushesAmount == null)
			{
				bushesAmount = new int[w.GridWidth * w.GridHeight];
			}
			for (int j = 0; j < w.cellData.Length; j++)
			{
				Cell cell = w.cellData[j];
				int x = j % w.GridWidth;
				int z = j / w.GridWidth;
				cellSaveData[j].CopyTo(ref cell);
				if (cellSaveData[j].type == TerrainType.EmptyCave)
				{
					w.AddEmptyCave(x, z);
				}
				else
				{
					_ = cellSaveData[j].type;
					_ = 4;
				}
				int num2 = treeAmount[j];
				for (int k = 0; k < num2; k++)
				{
					w.treeSystem.PlaceItem(cell);
				}
				int num3 = rockAmount[j];
				for (int l = 0; l < num3; l++)
				{
					w.rockScatterSystem.PlaceItem(cell);
				}
				int num4 = bushesAmount[j];
				for (int m = 0; m < num4; m++)
				{
					w.bushesSystem.PlaceItem(cell);
				}
				cell.StorePostGenerationType();
			}
			if (landmassCells != null)
			{
				w.cellsToLandmass = new ArrayExt<Cell>[landmassCells.Length];
				for (int n = 0; n < landmassCells.Length; n++)
				{
					w.cellsToLandmass[n] = new ArrayExt<Cell>(landmassCells[n].Length);
					for (int num5 = 0; num5 < landmassCells[n].Length; num5++)
					{
						w.cellsToLandmass[n].Add(w.cellData[landmassCells[n][num5]]);
					}
				}
			}
			w.villagersPerLandMass.Clear();
			for (int num6 = 0; num6 < numOfLandmasses; num6++)
			{
				w.villagersPerLandMass.Add(new ArrayExt<Villager>(200));
			}
			for (int num7 = 0; num7 < wolfDens.Count; num7++)
			{
				WolfDen obj = w.AddWolfDen(wolfDens[num7].x, wolfDens[num7].z);
				wolfDens[num7].Unpack(obj);
			}
			TerrainResource.Reset();
			for (int num8 = 0; num8 < terrainResources.Count; num8++)
			{
				TerrainResource obj2 = UnityEngine.Object.Instantiate(TerrainGen.inst.GetTerrainResourcePrefabOfType(terrainResources[num8].resourceID));
				obj2 = terrainResources[num8].Unpack(obj2);
			}
			w.placedCavesWitches = placedCavesWitches;
			w.placedFish = placedFish;
			w.inFirstPlacementPhase = inFirstPlacementPhase;
			if (inFirstPlacementPhase)
			{
				w.ShowResourceGroupTooltipUIs(-1, doShowFish: true);
			}
			TerrainGen.inst.FinalizeChanges();
			w.regenRimCells = true;
			w.hostility = hostility;
			if (w.hostility == null)
			{
				w.ClearHostility();
			}
			TerrainGen.inst.SetupTerrainGenCells(w.cellData);
			if (fertilityNoise != null)
			{
				float[] rawFertilityNoise = TerrainGen.inst.RawFertilityNoise;
				Array.Copy(fertilityNoise, rawFertilityNoise, fertilityNoise.Length);
				TerrainGen.inst.isFertilityNoiseDirty = true;
			}
			if (fertility != null)
			{
				int[] destinationArray = TerrainGen.inst.Fertility;
				Array.Copy(fertility, destinationArray, fertility.Length);
			}
			if (currFertilityData != null)
			{
				if (TerrainGen.inst.RebuildBlendWeightTexturesFromCurrFertility())
				{
					TerrainGen.DoFertilityUpdate = (TerrainGen.DoFertilityInstantBlend = true);
				}
			}
			else
			{
				TerrainGen.inst.UpdateFertility(doInstantBlend: true);
			}
			TerrainGen.inst.UpdateTextures();
			w.FindValidStartLandmasses();
			Water.UpdateNeeded = true;
			w.isDemo = isDemo;
			if (!isDemo)
			{
				MusicSystem.inst.StartDefaultMusic();
			}
			ForcePhysicsSimulationUpdate();
			TerrainGen.inst.BuildNatureObstructionField();
			TerrainGen.inst.CalcAveragedWorldCenter();
			w.PlaceGrass();
			return w;
		}
	}

	public TMP_Dropdown mapSizeDropdown;

	public TMP_Dropdown mapTypeDropdown;

	public Button editMapButton;

	public Mesh scaffoldMesh;

	public AnimationCurve scaffoldCurve;

	public InWorldExclamation issuePrefab;

	public GameObject foundationPrefab;

	public Material romeUnimaterial;

	public Material romeUnimaterialNoSnow;

	public Material romeUnimaterialEarthBender;

	public Material romeMountainUnimaterial;

	public bool isDemo;

	public bool skipGrassClearing;

	public SerializableGuid guid = Guid.Empty;

	private const int MAX_DROP_AMOUNT = 30;

	public Villager personModel;

	public Material uniMaterialFog;

	public Material uniMaterialNoFog;

	public Material uniMaterialNoFogNoSnow;

	public Material mountainMaterial;

	private CellInfluence[] cellInfluenceData;

	private CellWaterSuppliers[] cellWaterSupplyData;

	private CellProductionInfluence[] cellProductionInfluenceData;

	private Cell[] cellData;

	private PathCell[] pathCellData;

	[NonSerialized]
	public VillagerGrid[] villagerGrid;

	public List<Texture2D> screenshotTextures;

	private int gridWidth;

	private int gridHeight;

	public static int MeshWidth;

	public static int MeshHeight;

	[HideInInspector]
	public GameObject resourceContainer;

	[HideInInspector]
	public GameObject caveContainer;

	public GameObject Table;

	public int seed;

	public bool Inited;

	public static World inst;

	public static string aqueductName = "aqueduct";

	public static string aqueductDummyName = "aqueductDummyBuilding";

	public static string archerSchoolName = "archerschool";

	public static string archerTowerName = "archer";

	public static string bakerName = "baker";

	public static string largeBakerName = "largebaker";

	public static string ballistaTowerName = "ballista";

	public static string barracksName = "barracks";

	public static string bathhouseName = "bathhouse";

	public static string blacksmithName = "blacksmith";

	public static string bridgeName = "bridge";

	public static string butcherName = "butcher";

	public static string castleblockName = "castleblock";

	public static string castlestairsName = "castlestairs";

	public static string cathedralName = "cathedral";

	public static string cemetery3x3Name = "cemetery";

	public static string cemeteryDummyName = "cemeterydummy";

	public static string parkDummyName = "parkdummy";

	public static string cemetery4x4Name = "cemetery44";

	public static string cemeteryCircleName = "cemeterycircle";

	public static string cemeteryDiamondName = "cemeterydiamond";

	public static string cemeteryKeeperName = "cemeterykeeper";

	public static string chamberOfWarName = "chamberofwar";

	public static string charcoalMakerName = "charcoalmaker";

	public static string churchName = "church";

	public static string clinicName = "clinic";

	public static string coppiceName = "coppice";

	public static string statueDummyName = "statuedummy";

	public static string stoneRemovalName = "destructioncrew";

	public static string dockName = "dock";

	public static string drawBridgeName = "drawbridge";

	public static string farmName = "farm";

	public static string fireHouseName = "firehouse";

	public static string largeFireHouseName = "largefirehouse";

	public static string firehouseCategoryName = "firehouse";

	public static string fishinghutName = "fishinghut";

	public static string fishMongerName = "fishsaltingworkshop";

	public static string foresterName = "forester";

	public static string forumName = "forum";

	public static string forumDummyName = "forumdummy";

	public static string forumGateName = "forumgate";

	public static string forumTileName = "forumtile";

	public static string fountainName = "fountain";

	public static string gardenName = "garden";

	public static string gateName = "gate";

	public static string granaryName = "largegranary";

	public static string greatHallName = "greathall";

	public static string greatLibraryName = "greatlibrary";

	public static string hospitalName = "hospital";

	public static string smallHouseName = "smallhouse";

	public static string ironMineName = "ironmine";

	public static string ironOreMillName = "ironoremill";

	public static string joustingArenaName = "joustingarena";

	public static string keepName = "keep";

	public static string largefountainName = "largefountain";

	public static string largeHouseName = "largehouse";

	public static string libraryName = "library";

	public static string manorHouseName = "manorhouse";

	public static string marketName = "market";

	public static string masonName = "mason";

	public static string moatName = "moat";

	public static string moundName = "mound";

	public static string noriaName = "noria";

	public static string orchardName = "orchard";

	public static string outpostName = "outpost";

	public static string parkName = "park";

	public static string pathName = "path";

	public static string pierName = "pier";

	public static string produceStandName = "producestand";

	public static string projectileTopper = "projectiletopper";

	public static string quarryName = "quarry";

	public static string marbleQuarryName = "marblequarry";

	public static string reservoirName = "reservoir";

	public static string roadName = "road";

	public static string rubbleName = "rubble";

	public static string smallGranaryName = "smallgranary";

	public static string largeGranaryName = "largegranary";

	public static string smallMarketName = "smallmarket";

	public static string stockpileName = "stockpile";

	public static string smallstockpileName = "smallstockpile";

	public static string statueBarbaraName = "statue_barbara";

	public static string statueLeviName = "statue_levi";

	public static string statueSamName = "statue_sam";

	public static string statueName = "statue";

	public static string largeStockpileName = "largestockpile";

	public static string seaGate = "seagate";

	public static string seedShipName = "seedship";

	public static string siegeWorkshopName = "siegeworkshop";

	public static string stoneBridgeName = "stonebridge";

	public static string stoneRoadName = "stoneroad";

	public static string swineherdName = "swineherd";

	public static string tavernName = "tavern";

	public static string throneRoomName = "throneroom";

	public static string hallOfDiplomacyName = "hallofdiplomacy";

	public static string theaterName = "theater";

	public static string transportCartName = "transportcart";

	public static string townsquareName = "townsquare";

	public static string transportShipName = "transportship";

	public static string troopTransportShipName = "trooptransportship";

	public static string playerMerchantShipName = "playermerchant";

	public static string warehouseName = "warehouse";

	public static string wellName = "well";

	public static string wineryName = "winery";

	public static string woodcastleblockName = "woodcastleblock";

	public static string woodengateName = "woodengate";

	public static string foreignMinistryName = "hallofdiplomacy";

	public static string houseCategoryName = "house";

	public static string uHouseName = "uhouse";

	public static string statueSlabName = "statue_slab";

	public static string castellumaquaeName = "castellumaquae";

	public static string waterTowerName = "watertower";

	public static string waterOutletName = "wateroutlet";

	public static string aqueductConnectorName = "aqueductconnector";

	public static string chariotRaceTrackName = "chariotracetrack";

	public static string damName = "damblock";

	public static string spilloverName = "spilloverblock";

	public static string aqueductLineName = "aqueductline";

	public static string romanOutpostName = "romanoutpost";

	public static string romanOutpostNewIslandName = "romanoutpostnewisland";

	public static string editTerrainZoneName = "editterrainzone";

	public static string weaponsmithName = "weaponsmith";

	public static string toolsmithName = "toolsmith";

	public static string claypitName = "claypit";

	public static string taxofficeName = "taxoffice";

	public static string templeName = "temple";

	public static string smallestTemple = "smallestTemple";

	public static string woodBridgeName = "woodbridge";

	public static string bathReservoirName = "bathreservoir";

	public static string bathdummyName = "bathdummy";

	public static string bathCategoryName = "bath";

	public static string bathColdPoolName = "bathcoldpool";

	public static string bathHotPoolName = "bathhotpool";

	public static string bathFurnaceName = "bathfurnace";

	public static string bathPalaestraName = "bathpalaestra";

	public static string bathLibraryName = "bathlibrary";

	public static string bathGardenName = "bathgarden";

	public static string shopName = "shop";

	public static string olivepressName = "olivepress";

	public static string damPlanningProjectName = "damplanningproject";

	public static string largePotteryWorkshopName = "largePotteryWorkshop";

	public static string potteryWorkshopName = "potteryworkshop";

	public static string colosseumName = "colosseum";

	public static string pantheonName = "pantheon";

	public static string barracksDummyName = "militarydummy";

	public static string damCategoryName = "dam";

	public static string damblockName = "damblock";

	public static string statueSmallArch = "statue_smallarch";

	public static string statueArch = "statue_arch";

	public static string villarusticaName = "farmvilla";

	public static string logisticsDepotCategoryName = "logisticdepot";

	public static string transportCartDepotName = "transportcartdepot";

	public static string transportShipPortName = "transportshipport";

	public static string publictoiletsName = "publictoilets";

	public static int statueSmallArchHash = statueSmallArch.GetHashCode();

	public static int statueArchHash = statueArch.GetHashCode();

	public static int damCategoryHash = damCategoryName.GetHashCode();

	public static int damblockHash = damblockName.GetHashCode();

	public static int charcoalmakerHash = charcoalMakerName.GetHashCode();

	public static int manorhouseHash = manorHouseName.GetHashCode();

	public static int smallHouseHash = smallHouseName.GetHashCode();

	public static int largehouseHash = largeHouseName.GetHashCode();

	public static int keepHash = keepName.GetHashCode();

	public static int farmHash = farmName.GetHashCode();

	public static int firehouseHash = fireHouseName.GetHashCode();

	public static int largeFirehouseHash = largeFireHouseName.GetHashCode();

	public static int orchardHash = orchardName.GetHashCode();

	public static int castleblockHash = castleblockName.GetHashCode();

	public static int woodcastleblockHash = woodcastleblockName.GetHashCode();

	public static int castlestairsHash = castlestairsName.GetHashCode();

	public static int pathHash = pathName.GetHashCode();

	public static int projectileTopperHash = projectileTopper.GetHashCode();

	public static int townsquareHash = townsquareName.GetHashCode();

	public static int pierHash = pierName.GetHashCode();

	public static int stoneBridgeHash = stoneBridgeName.GetHashCode();

	public static int woodBridgeHash = woodBridgeName.GetHashCode();

	public static int moatHash = moatName.GetHashCode();

	public static int gateHash = gateName.GetHashCode();

	public static int woodengateHash = woodengateName.GetHashCode();

	public static int rubbleHash = rubbleName.GetHashCode();

	public static int statueLeviHash = statueLeviName.GetHashCode();

	public static int noriaHash = noriaName.GetHashCode();

	public static int aqueductHash = aqueductName.GetHashCode();

	public static int roadHash = roadName.GetHashCode();

	public static int stoneRoadHash = stoneRoadName.GetHashCode();

	public static int gardenHash = gardenName.GetHashCode();

	public static int reservoirHash = reservoirName.GetHashCode();

	public static int throneRoomHash = throneRoomName.GetHashCode();

	public static int statueHash = statueName.GetHashCode();

	public static int wellHash = wellName.GetHashCode();

	public static int dockHash = dockName.GetHashCode();

	public static int drawBridgeHash = drawBridgeName.GetHashCode();

	public static int fishinghutHash = fishinghutName.GetHashCode();

	public static int outpostHash = outpostName.GetHashCode();

	public static int romanOutpostHash = romanOutpostName.GetHashCode();

	public static int romanOutpostHashNewIsland = romanOutpostNewIslandName.GetHashCode();

	public static int cemeteryHash = cemetery3x3Name.GetHashCode();

	public static int cemeteryKeeperHash = cemeteryKeeperName.GetHashCode();

	public static int fountainHash = fountainName.GetHashCode();

	public static int largefountainHash = largefountainName.GetHashCode();

	public static int foresterHash = foresterName.GetHashCode();

	public static int quarryHash = quarryName.GetHashCode();

	public static int clinicHash = clinicName.GetHashCode();

	public static int hospitalHash = hospitalName.GetHashCode();

	public static int tavernHash = tavernName.GetHashCode();

	public static int churchHash = churchName.GetHashCode();

	public static int stockpileHash = stockpileName.GetHashCode();

	public static int smallstockpileHash = smallstockpileName.GetHashCode();

	public static int largeStockpileHash = largeStockpileName.GetHashCode();

	public static int swineherdHash = swineherdName.GetHashCode();

	public static int archerTowerHash = archerTowerName.GetHashCode();

	public static int ballistaTowerHash = ballistaTowerName.GetHashCode();

	public static int ironMineHash = ironMineName.GetHashCode();

	public static int ironOreMillHash = ironOreMillName.GetHashCode();

	public static int joustingArenaHash = joustingArenaName.GetHashCode();

	public static int hallofdiplomacyHash = hallOfDiplomacyName.GetHashCode();

	public static int theaterHash = theaterName.GetHashCode();

	public static int bathhouseHash = bathhouseName.GetHashCode();

	public static int transportCartHash = transportCartName.GetHashCode();

	public static int blacksmithHash = blacksmithName.GetHashCode();

	public static int marketHash = marketName.GetHashCode();

	public static int produceStandHash = produceStandName.GetHashCode();

	public static int libraryHash = libraryName.GetHashCode();

	public static int fishMongerHash = fishMongerName.GetHashCode();

	public static int barracksHash = barracksName.GetHashCode();

	public static int archerSchoolHash = archerSchoolName.GetHashCode();

	public static int chamberOfWarHash = chamberOfWarName.GetHashCode();

	public static int foreignMinistryHash = foreignMinistryName.GetHashCode();

	public static int smallGranaryHash = smallGranaryName.GetHashCode();

	public static int largeGranaryHash = largeGranaryName.GetHashCode();

	public static int granaryHash = granaryName.GetHashCode();

	public static int granaryCategoryHash = "granary".GetHashCode();

	public static int masonHash = masonName.GetHashCode();

	public static int butcherHash = butcherName.GetHashCode();

	public static int cathedralHash = cathedralName.GetHashCode();

	public static int greatLibraryHash = greatLibraryName.GetHashCode();

	public static int houseCategoryHash = houseCategoryName.GetHashCode();

	public static int smallMarketHash = smallMarketName.GetHashCode();

	public static int transportShipHash = transportShipName.GetHashCode();

	public static int playerMerchantShipHash = playerMerchantShipName.GetHashCode();

	public static int troopTransportShipHash = troopTransportShipName.GetHashCode();

	public static int uHouseHash = uHouseName.GetHashCode();

	public static int bakerHash = bakerName.GetHashCode();

	public static int statueSlabHash = statueSlabName.GetHashCode();

	public static int greatHallHash = greatHallName.GetHashCode();

	public static int stoneRemovalHash = stoneRemovalName.GetHashCode();

	public static int siegeWorkshopHash = siegeWorkshopName.GetHashCode();

	public static int parkHash = parkName.GetHashCode();

	public static int forumTileHash = forumTileName.GetHashCode();

	public static int forumGateHash = forumGateName.GetHashCode();

	public static int forumHash = forumName.GetHashCode();

	public static int forumDummyHash = forumDummyName.GetHashCode();

	public static int wineryHash = wineryName.GetHashCode();

	public static int coppiceHash = coppiceName.GetHashCode();

	public static int warehouseHash = warehouseName.GetHashCode();

	public static int castellumaquaeHash = castellumaquaeName.GetHashCode();

	public static int waterTowerHash = waterTowerName.GetHashCode();

	public static int waterOutletHash = waterOutletName.GetHashCode();

	public static int aqueductConnectorHash = aqueductConnectorName.GetHashCode();

	public static int chariotRaceTrackHash = chariotRaceTrackName.GetHashCode();

	public static int damHash = damName.GetHashCode();

	public static int spilloverHash = spilloverName.GetHashCode();

	public static int moundHash = moundName.GetHashCode();

	public static int aqueductLineHash = aqueductLineName.GetHashCode();

	public static int editTerrainZoneHash = editTerrainZoneName.GetHashCode();

	public static int weaponsmithHash = weaponsmithName.GetHashCode();

	public static int toolsmithHash = toolsmithName.GetHashCode();

	public static int claypitHash = claypitName.GetHashCode();

	public static int taxOfficeHash = taxofficeName.GetHashCode();

	public static int marbleQuarryHash = marbleQuarryName.GetHashCode();

	public static int templeHash = templeName.GetHashCode();

	public static int seagateHash = "seagate".GetHashCode();

	public static int shipHash = "ship".GetHashCode();

	public static int bathReservoirHash = bathReservoirName.GetHashCode();

	public static int bathCategoryHash = bathCategoryName.GetHashCode();

	public static int bathColdPoolHash = bathColdPoolName.GetHashCode();

	public static int bathHotPoolHash = bathHotPoolName.GetHashCode();

	public static int bathFurnaceHash = bathFurnaceName.GetHashCode();

	public static int bathPalaestraHash = bathPalaestraName.GetHashCode();

	public static int bathLibraryHash = bathLibraryName.GetHashCode();

	public static int bathGardenHash = bathGardenName.GetHashCode();

	public static int shopHash = shopName.GetHashCode();

	public static int charcoalCategoryHash = "charcoal".GetHashCode();

	public static int miningCategoryHash = "mining".GetHashCode();

	public static int olivepressHash = olivepressName.GetHashCode();

	public static int damPlanningProjectHash = damPlanningProjectName.GetHashCode();

	public static int largePotteryWorkshopHash = largePotteryWorkshopName.GetHashCode();

	public static int colosseumHash = colosseumName.GetHashCode();

	public static int pantheonHash = pantheonName.GetHashCode();

	public static int villarusticaHash = villarusticaName.GetHashCode();

	public static int logisticsDepotCategoryHash = logisticsDepotCategoryName.GetHashCode();

	public static int transportCartDepotHash = transportCartDepotName.GetHashCode();

	public static int transportShipPortHash = transportShipPortName.GetHashCode();

	public static int publictoiletsHash = publictoiletsName.GetHashCode();

	public List<Livery> liverySets;

	public Sprite icon_viking;

	public Sprite icon_ogre;

	public Sprite icon_troopTransportShip_vikings;

	public Sprite icon_troopTransportShip_ogre;

	private System.Random randomStoneState;

	public TreeSystem treeSystem;

	public TreeSystem coppiceTreeSystem;

	public TreeSystem grassSystem;

	public TreeSystem dryGrassSystem;

	public TreeSystem rockScatterSystem;

	public TreeSystem bushesSystem;

	public Whale whale;

	internal Pathfinder pather;

	internal ThreadedPathing threadedPather = new ThreadedPathing();

	public EditTerrainProjectManager editTerrainProjectManager;

	private int frameToWaitBeforeSeen = 5;

	private int framesAfterGenerate;

	public bool inFirstPlacementPhase;

	public GameObject resourceTooltipPrefab;

	public GameObject resourceTooltipContainer;

	private int fishTooltipCount;

	private List<ResourceTooltipUI> fishTooltipPool = new List<ResourceTooltipUI>();

	private bool[] hasVisited;

	private ArrayExt<int> openset = new ArrayExt<int>(32);

	private ArrayExt<Vector3> tempPos = new ArrayExt<Vector3>(32);

	[NonSerialized]
	public MapSize generatedMapSize = MapSize.Random;

	[NonSerialized]
	public MapSize mapSize = MapSize.Medium;

	public List<MapSizeDef> mapSizeDefs = new List<MapSizeDef>();

	public WaterGenSettings[] settings = new WaterGenSettings[2];

	public MapBias generatedMapsBias = MapBias.Random;

	public MapBias mapBias = MapBias.Random;

	public MapRiverAmount generatedRiverLakes = MapRiverAmount.VeryHigh;

	public MapRiverAmount mapRiverAmount = MapRiverAmount.VeryHigh;

	public MapResourceAmount generatedResourceAmount = MapResourceAmount.Normal;

	public MapResourceAmount mapResourceAmount = MapResourceAmount.Normal;

	public float[] resourceDensity = new float[3] { 0.6f, 0.95f, 1.15f };

	public List<IslandSignature> smallIslandSignatures = new List<IslandSignature>();

	public List<IslandSignature> islandSignatures = new List<IslandSignature>();

	public List<IslandSignature> largeIslandSignatures = new List<IslandSignature>();

	public List<IslandSignature> baseDensities = new List<IslandSignature>();

	internal Vector3[] offsets = new Vector3[4]
	{
		new Vector3(-1f, 0f, 0f),
		new Vector3(1f, 0f, 0f),
		new Vector3(0f, 0f, -1f),
		new Vector3(0f, 0f, 1f)
	};

	public SizeToDepostsInfo smallMapDepositInfo;

	public SizeToDepostsInfo mediumMapDepositInfo;

	public SizeToDepostsInfo largeMapDepositInfo;

	[NonSerialized]
	public ArrayExt<Cell>[] cellsToLandmass;

	public bool DebugDrawLandmassCells;

	public int minDistForRandomFeatures = 7;

	public float randomRockScatter = 0.05f;

	public KingdomHeadInfo[] kingdomHeadInfo;

	public KingdomHeadInfo[] godHeadInfo;

	public UnityEvent worldGenerationComplete;

	[NonSerialized]
	public bool placedFish;

	private bool placedCavesWitches;

	public GameObject emptyCavePrefab;

	public GameObject wolfDenPrefab;

	public GameObject witchHutPrefab;

	public int caveSpawnTreeNeighborThreshold = 4;

	private List<LandmassStartInfo> landmassStartInfo = new List<LandmassStartInfo>();

	[NonSerialized]
	public int validStartLandmassCount;

	[NonSerialized]
	public int validStartLandmassForAICount;

	public Vector3 bigRockSizeMin = new Vector3(0.35f, 0.35f, 0.35f);

	public Vector3 bigRockSizeMax = new Vector3(1.35f, 1.35f, 1.35f);

	public static ArrayExt<LandmassOwner> LandMassOwners = new ArrayExt<LandmassOwner>(5);

	public static LandmassOwner[] LandMassOwnerLookup;

	public Cell[] rimCells;

	private ArrayExt<Villager> emptyVillagerList = new ArrayExt<Villager>(0);

	private ArrayExt<ArrayExt<Villager>> villagersPerLandMass = new ArrayExt<ArrayExt<Villager>>(10);

	private bool regenRimCells;

	private Color[] colors = new Color[5]
	{
		Color.green,
		Color.red,
		Color.blue,
		Color.magenta,
		Color.yellow
	};

	public List<Cell> rebakeCells = new List<Cell>();

	[NonSerialized]
	public int pathGridId;

	private Cell[] scratch4 = new Cell[4];

	public int RoadBuildRadius = 2;

	public int PierBuildRadius = 1;

	public int BuildingCount;

	public Vector3[] cardinalOffsets = new Vector3[4]
	{
		new Vector3(1f, 0f, 0f),
		new Vector3(-1f, 0f, 0f),
		new Vector3(0f, 0f, 1f),
		new Vector3(0f, 0f, -1f)
	};

	public List<DemolishPending> buildingsToDemolish = new List<DemolishPending>();

	public ArrayExtRef<Villager> peopleInBuilding = new ArrayExtRef<Villager>(50);

	private Cell[] scratchNeighbors = new Cell[8];

	public float timeLastPlaced = -999f;

	public GameObject BuildDockCutscenePrefab;

	private Vector3[] cellBoundOffsets = new Vector3[4]
	{
		new Vector3(-0.499f, 0f, -0.499f),
		new Vector3(-0.499f, 0f, 0.499f),
		new Vector3(0.499f, 0f, -0.499f),
		new Vector3(0.499f, 0f, 0.499f)
	};

	private TreeGrowth treeGrowth;

	private int numLandMasses;

	public ArrayExt<LandmassCenter> landmassCenters = new ArrayExt<LandmassCenter>(8);

	public bool triedQuittingAlready;

	internal Dictionary<Type, Type[]> jobTypeMap = new Dictionary<Type, Type[]>();

	internal Dictionary<Type, Type[]> buildingTypeMap = new Dictionary<Type, Type[]>();

	private Relations[,] hostility = new Relations[5, 5];

	public bool demoMode => false;

	public int ScreenshotWidth => 800;

	public int ScreenshotHeight => ScreenshotWidth / 4 * 3;

	public int GridWidth => gridWidth;

	public int GridHeight => gridHeight;

	public int NumLandMasses => numLandMasses;

	public event wolfDenClear OnWolfDenCleared;

	public static event Action<int> OnInlandOceanFilled;

	public static event Action<int> OnSmallIslandSunk;

	public void SetGrassEnabled(bool e)
	{
		inst.grassSystem.enabled = e;
		inst.dryGrassSystem.enabled = e;
		inst.bushesSystem.enabled = e;
	}

	public void WolfDenCleared(int landmassIdx, int teamID)
	{
		OnWolfDenCleared?.Invoke(landmassIdx, teamID);
	}

	public static void DropResources(Vector3 pos, ResourceAmount r)
	{
		Cell cellDataClamped = inst.GetCellDataClamped(pos);
		int landMassIdx = cellDataClamped.landMassIdx;
		int num = Mathf.CeilToInt(Mathf.Sqrt(5f));
		int num2 = 0;
		int num3 = 0;
		for (int i = 0; i < r.resources.Count; i++)
		{
			int resourceID = r.resources[i].resourceID;
			if (resourceID == 4)
			{
				GetLandmassOwner(landMassIdx).Gold += r.Get(resourceID);
			}
			else
			{
				if (r.Get(resourceID) <= 0)
				{
					continue;
				}
				while (r.Get(resourceID) > 0)
				{
					int num4 = 30 - r.Get(resourceID);
					num4 = ((num4 <= 0) ? 30 : (30 - num4));
					r.Add(resourceID, -num4);
					FreeResourceManager.inst.GetAutoStackFor(resourceID, num4, cellDataClamped.Position + new Vector3(-0.5f + (float)num2 * (1f / (float)num), 0f, -0.5f + (float)num3 * (1f / (float)num)));
					num2++;
					if (num2 > num)
					{
						num3++;
						num2 = 0;
					}
				}
			}
		}
	}

	public Vector3 SnapToGrid2D(Vector3 pos)
	{
		float x = Mathf.Floor(pos.x);
		float y = pos.y;
		float z = Mathf.Floor(pos.z);
		return new Vector3(x, y, z);
	}

	public Vector3 SnapToGrid2DR(Vector3 pos)
	{
		float x = Mathf.Round(pos.x);
		float y = pos.y;
		float z = Mathf.Round(pos.z);
		return new Vector3(x, y, z);
	}

	public Cell[] GetCellsData()
	{
		return cellData;
	}

	public PathCell[] GetPathCellsData()
	{
		return pathCellData;
	}

	public Vector3 GridCenter()
	{
		return new Vector3((float)gridWidth / 2f, 0f, (float)gridHeight / 2f);
	}

	public void ToGridCoord(Vector3 worldPos, out int x, out int z)
	{
		Vector3 vector = SnapToGrid2D(worldPos);
		x = (int)vector.x;
		z = (int)vector.z;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public Cell GetCellDataUnsafe(int i)
	{
		return cellData[i];
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public Cell GetCellData(int x, int z)
	{
		int num = z * gridWidth + x;
		if (!cellData.IsNull() && x >= 0 && x < gridWidth && z >= 0 && z < gridHeight)
		{
			return cellData[num];
		}
		return null;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public Cell GetCellDataUnsafe(int x, int z)
	{
		int num = z * gridWidth + x;
		return cellData[num];
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public Cell GetCellData(Vector3 worldPos)
	{
		return GetCellData((int)worldPos.x, (int)worldPos.z);
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public Cell GetCellData(PathCell pc)
	{
		return cellData[pc.z * gridWidth + pc.x];
	}

	public Cell GetCellDataClamped(Vector3 worldPos)
	{
		int num = (int)worldPos.x;
		int num2 = (int)worldPos.z;
		if (num < 0)
		{
			num = 0;
		}
		else if (num >= gridWidth)
		{
			num = gridWidth - 1;
		}
		if (num2 < 0)
		{
			num2 = 0;
		}
		else if (num2 >= gridHeight)
		{
			num2 = gridHeight - 1;
		}
		return cellData[num2 * gridWidth + num];
	}

	public Cell GetCellDataClamped(int x, int z)
	{
		if (x < 0)
		{
			x = 0;
		}
		else if (x >= gridWidth)
		{
			x = gridWidth - 1;
		}
		if (z < 0)
		{
			z = 0;
		}
		else if (z >= gridHeight)
		{
			z = gridHeight - 1;
		}
		return cellData[z * gridWidth + x];
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public PathCell GetPathCell(int index)
	{
		return pathCellData[index];
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public PathCell GetPathCell(Cell c)
	{
		return pathCellData[c.z * gridWidth + c.x];
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public PathCell GetPathCell(int x, int z)
	{
		if (z >= 0 && x >= 0 && z < gridHeight && x < gridWidth)
		{
			return pathCellData[z * gridWidth + x];
		}
		return null;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public PathCell GetPathCell(Vector3 worldPos)
	{
		int num = (int)worldPos.z * gridWidth + (int)worldPos.x;
		return pathCellData[num];
	}

	public PathCell GetPathCellClamped(Vector3 worldPos)
	{
		int num = (int)worldPos.x;
		int num2 = (int)worldPos.z;
		if (num < 0)
		{
			num = 0;
		}
		else if (num >= gridWidth)
		{
			num = gridWidth - 1;
		}
		if (num2 < 0)
		{
			num2 = 0;
		}
		else if (num2 >= gridHeight)
		{
			num2 = gridHeight - 1;
		}
		return pathCellData[num2 * gridWidth + num];
	}

	public PathCell GetPathCellClamped(int x, int z)
	{
		if (x < 0)
		{
			x = 0;
		}
		else if (x >= gridWidth)
		{
			x = gridWidth - 1;
		}
		if (z < 0)
		{
			z = 0;
		}
		else if (z >= gridHeight)
		{
			z = gridHeight - 1;
		}
		return pathCellData[z * gridWidth + x];
	}

	public CellProductionInfluence GetCellProductionInfluenceDataClamped(Vector3 pos)
	{
		return GetCellProductionInfluenceDataClamped((int)pos.x, (int)pos.z);
	}

	public CellProductionInfluence GetCellProductionInfluenceDataClamped(int x, int z)
	{
		if (x < 0)
		{
			x = 0;
		}
		else if (x >= gridWidth)
		{
			x = gridWidth - 1;
		}
		if (z < 0)
		{
			z = 0;
		}
		else if (z >= gridHeight)
		{
			z = gridHeight - 1;
		}
		return cellProductionInfluenceData[z * gridWidth + x];
	}

	public CellInfluence GetCellInfluenceDataClamped(int x, int z)
	{
		if (x < 0)
		{
			x = 0;
		}
		else if (x >= gridWidth)
		{
			x = gridWidth - 1;
		}
		if (z < 0)
		{
			z = 0;
		}
		else if (z >= gridHeight)
		{
			z = gridHeight - 1;
		}
		return cellInfluenceData[z * gridWidth + x];
	}

	public CellWaterSuppliers GetCellWaterSupplyDataClamped(int x, int z)
	{
		if (x < 0)
		{
			x = 0;
		}
		else if (x >= gridWidth)
		{
			x = gridWidth - 1;
		}
		if (z < 0)
		{
			z = 0;
		}
		else if (z >= gridHeight)
		{
			z = gridHeight - 1;
		}
		return cellWaterSupplyData[z * gridWidth + x];
	}

	public Cell GetCardinalAdjacentResource(int x, int z, int rID)
	{
		Cell cell = GetCellData(x + 1, z);
		if (cell != null && cell.HasAccessibleTerrainResourceType(rID))
		{
			return cell;
		}
		cell = GetCellData(x - 1, z);
		if (cell != null && cell.HasAccessibleTerrainResourceType(rID))
		{
			return cell;
		}
		cell = GetCellData(x, z + 1);
		if (cell != null && cell.HasAccessibleTerrainResourceType(rID))
		{
			return cell;
		}
		cell = GetCellData(x, z - 1);
		if (cell != null && cell.HasAccessibleTerrainResourceType(rID))
		{
			return cell;
		}
		return null;
	}

	public bool HasCardinalAdjacentCoveredResource(int x, int z, int rID)
	{
		Cell cell = GetCellData(x + 1, z);
		if (cell != null && cell.HasTerrainResourceType(rID) && !cell.HasAccessibleTerrainResourceType(rID))
		{
			return true;
		}
		cell = GetCellData(x - 1, z);
		if (cell != null && cell.HasTerrainResourceType(rID) && !cell.HasAccessibleTerrainResourceType(rID))
		{
			return true;
		}
		cell = GetCellData(x, z + 1);
		if (cell != null && cell.HasTerrainResourceType(rID) && !cell.HasAccessibleTerrainResourceType(rID))
		{
			return true;
		}
		cell = GetCellData(x, z - 1);
		if (cell != null && cell.HasTerrainResourceType(rID) && !cell.HasAccessibleTerrainResourceType(rID))
		{
			return true;
		}
		return false;
	}

	public bool HasCardinalAdjacentBuriedResource(int x, int z, int rID)
	{
		Cell cell = GetCellData(x + 1, z);
		if (cell != null && cell.HasTerrainResourceType(rID) && cell.Type != TerrainType.Obstruction)
		{
			return true;
		}
		cell = GetCellData(x - 1, z);
		if (cell != null && cell.HasTerrainResourceType(rID) && cell.Type != TerrainType.Obstruction)
		{
			return true;
		}
		cell = GetCellData(x, z + 1);
		if (cell != null && cell.HasTerrainResourceType(rID) && cell.Type != TerrainType.Obstruction)
		{
			return true;
		}
		cell = GetCellData(x, z - 1);
		if (cell != null && cell.HasTerrainResourceType(rID) && cell.Type != TerrainType.Obstruction)
		{
			return true;
		}
		return false;
	}

	public Cell GetCardinalAdjacentType(int x, int z, TerrainType ttype)
	{
		Cell cell = GetCellData(x + 1, z);
		if (cell != null && cell.Type == ttype)
		{
			return cell;
		}
		cell = GetCellData(x - 1, z);
		if (cell != null && cell.Type == ttype)
		{
			return cell;
		}
		cell = GetCellData(x, z + 1);
		if (cell != null && cell.Type == ttype)
		{
			return cell;
		}
		cell = GetCellData(x, z - 1);
		if (cell != null && cell.Type == ttype)
		{
			return cell;
		}
		return null;
	}

	public void GetNeighborCells(Cell cell, ref Cell[] array)
	{
		array[0] = GetCellData(cell.x + 1, cell.z);
		array[1] = GetCellData(cell.x, cell.z + 1);
		array[2] = GetCellData(cell.x - 1, cell.z);
		array[3] = GetCellData(cell.x, cell.z - 1);
	}

	public void GetNeighborCellsExtended(Cell cell, ref Cell[] cells)
	{
		cells[0] = GetCellData(cell.x + 1, cell.z);
		cells[1] = GetCellData(cell.x + 1, cell.z + 1);
		cells[2] = GetCellData(cell.x, cell.z + 1);
		cells[3] = GetCellData(cell.x - 1, cell.z + 1);
		cells[4] = GetCellData(cell.x - 1, cell.z);
		cells[5] = GetCellData(cell.x - 1, cell.z - 1);
		cells[6] = GetCellData(cell.x, cell.z - 1);
		cells[7] = GetCellData(cell.x + 1, cell.z - 1);
	}

	public void GetNeighborDiagonalCells(Cell cell, ref Cell[] cells)
	{
		cells[0] = GetCellData(cell.x + 1, cell.z + 1);
		cells[1] = GetCellData(cell.x - 1, cell.z + 1);
		cells[2] = GetCellData(cell.x - 1, cell.z - 1);
		cells[3] = GetCellData(cell.x + 1, cell.z - 1);
	}

	public void GetNeighborCellsExtendedPlus(Cell cell, ref Cell[] cells)
	{
		cells[0] = GetCellData(cell.x + 1, cell.z);
		cells[1] = GetCellData(cell.x + 1, cell.z + 1);
		cells[2] = GetCellData(cell.x, cell.z + 1);
		cells[3] = GetCellData(cell.x - 1, cell.z + 1);
		cells[4] = GetCellData(cell.x - 1, cell.z);
		cells[5] = GetCellData(cell.x - 1, cell.z - 1);
		cells[6] = GetCellData(cell.x, cell.z - 1);
		cells[7] = GetCellData(cell.x + 1, cell.z - 1);
		cells[8] = GetCellData(cell.x + 2, cell.z);
		cells[9] = GetCellData(cell.x - 2, cell.z);
		cells[10] = GetCellData(cell.x, cell.z + 2);
		cells[11] = GetCellData(cell.x, cell.z - 2);
	}

	public Cell FindMatchingSurroundingCell(Cell origin, bool testOrigin, int maxRadius, Predicate<Cell> match)
	{
		if (origin == null)
		{
			return null;
		}
		if (testOrigin && match(origin))
		{
			return origin;
		}
		if (maxRadius > 100)
		{
			maxRadius = 100;
		}
		for (int i = 1; i <= maxRadius; i++)
		{
			int num = 0;
			int num2 = -i;
			do
			{
				bool flag = num >= 0 && (num != 0 || num2 <= 0);
				bool flag2 = num2 < 0 || (num2 == 0 && num < 0);
				num += (flag2 ? 1 : (-1));
				num2 += (flag ? 1 : (-1));
				Cell cell = GetCellData(origin.Center2D + new Vector3(num, 0f, num2));
				if (cell != null && match(cell))
				{
					return cell;
				}
			}
			while (num != 0 || num2 != -i);
		}
		return null;
	}

	public Cell FindMatchingSurroundingCell(Vector3 origin, bool testOrigin, int maxRadius, Predicate<Cell> match)
	{
		Cell cell = GetCellData(origin);
		if (cell == null)
		{
			return null;
		}
		return FindMatchingSurroundingCell(cell, testOrigin, maxRadius, match);
	}

	public int LineTestAccumFootpathCost(Cell a, Cell b, int teamId)
	{
		int num = a.x;
		int num2 = a.z;
		int x = b.x;
		int z = b.z;
		int num3 = Mathf.Abs(x - num);
		int num4 = ((num < x) ? 1 : (-1));
		int num5 = Mathf.Abs(z - num2);
		int num6 = ((num2 < z) ? 1 : (-1));
		int num7 = num3 - num5;
		int num8 = 0;
		while (true)
		{
			num8 += PathCell.GetFootPathCost(pathCellData[num2 * gridWidth + num], teamId);
			int num9 = num7;
			if (2 * num9 >= -num3)
			{
				if (num == x)
				{
					break;
				}
				num7 -= num5;
				num += num4;
			}
			if (2 * num9 <= num5)
			{
				if (num2 == z)
				{
					break;
				}
				num7 += num3;
				num2 += num6;
			}
		}
		return num8;
	}

	public Cell LineTestForFirstLand(Cell a, Cell b)
	{
		int num = a.x;
		int num2 = a.z;
		int x = b.x;
		int z = b.z;
		int num3 = Mathf.Abs(x - num);
		int num4 = ((num < x) ? 1 : (-1));
		int num5 = Mathf.Abs(z - num2);
		int num6 = ((num2 < z) ? 1 : (-1));
		int num7 = num3 - num5;
		while (true)
		{
			if (cellData[num2 * gridWidth + num].Type != TerrainType.Water)
			{
				return cellData[num2 * gridWidth + num];
			}
			int num8 = num7;
			if (2 * num8 >= -num3)
			{
				if (num == x)
				{
					break;
				}
				num7 -= num5;
				num += num4;
			}
			if (2 * num8 <= num5)
			{
				if (num2 == z)
				{
					break;
				}
				num7 += num3;
				num2 += num6;
			}
		}
		return null;
	}

	public void GetRandomPositionOnEdge(ref Vector3 pos)
	{
		switch (SRand.Range(0, 4))
		{
		case 0:
			pos.z = SRand.Range(1, inst.GridHeight);
			break;
		case 1:
			pos.x = SRand.Range(1, inst.GridWidth);
			break;
		case 2:
			pos.z = SRand.Range(1, inst.GridHeight);
			pos.x = inst.GridWidth - 1;
			break;
		case 3:
			pos.x = SRand.Range(1, inst.GridWidth);
			pos.z = inst.GridHeight - 1;
			break;
		}
	}

	private static bool IsLowerTierOnCell(Building PendingObj, Cell cell)
	{
		if (cell.OccupyingStructure.Count == 1)
		{
			return PendingObj.IsLowerTier(cell.BottomStructure);
		}
		return false;
	}

	public static bool IsBurnable(Building b)
	{
		if (IsImmuneToFire(b))
		{
			return false;
		}
		return !(b.GetMaxVigilesCoverage() >= 0.99f);
	}

	public static bool IsImmuneToFire(Building b)
	{
		return b.fireChance <= 0f;
	}

	public bool TrimPathForBlockedCells(ref ArrayExt<Vector3> path, Pathfinder.blocksPathTest blockTest, int teamId)
	{
		for (int i = 0; i < path.Count; i++)
		{
			PathCell pathCell = GetPathCell(path.data[i]);
			if (blockTest(pathCell, teamId))
			{
				path.RemoveRange(i, path.Count - i);
				return true;
			}
		}
		return false;
	}

	public void FindPath(Cell startCell, Cell endCell, ref ArrayExt<Vector3> path, Pathfinder.blocksPathTest bt, Pathfinder.blocksPathTest btStringPull, Pathfinder.applyExtraCost ec, int teamId, bool doDiagonal = true, bool useUpperPathGrid = true)
	{
		pather.FindPath(startCell.Center2D, startUseUpperGrid: false, endCell.Center2D, endUseUpperGrid: false, ref path, bt, btStringPull, ec, teamId, doDiagonal, doTrimming: false, useUpperPathGrid);
	}

	public bool IsValidStartLandmass(int landMass)
	{
		if (landMass >= 0 && landMass < landmassStartInfo.Count)
		{
			if (Creative.inst.IsEnabled())
			{
				return true;
			}
			if (landmassStartInfo[landMass].numFertileTiles > 10 && landmassStartInfo[landMass].numStones >= 1 && landmassStartInfo[landMass].numTreeTiles >= 36 && landmassStartInfo[landMass].size > 100)
			{
				return true;
			}
		}
		return false;
	}

	public bool IsValidStartLandmassForAI(int landMass)
	{
		if (landMass >= 0 && landMass < landmassStartInfo.Count && landmassStartInfo[landMass].numFertileTiles > 10 && landmassStartInfo[landMass].numStones >= 1 && landmassStartInfo[landMass].numTreeTiles >= 36 && landmassStartInfo[landMass].numIrons >= 1 && landmassStartInfo[landMass].size > 100)
		{
			return true;
		}
		return false;
	}

	private void Awake()
	{
		inst = this;
		gridWidth = 55;
		gridHeight = 55;
		editTerrainProjectManager = gameObject.AddComponent<EditTerrainProjectManager>();
	}

	private void Setup(int width, int height)
	{
		rebakeCells.Clear();
		LandMassOwnerLookup = null;
		for (int i = 0; i < LandMassOwners.Count; i++)
		{
			LandMassOwners.data[i].Reset();
		}
		TerrainGen.inst.ClearMountains();
		Resources.UnloadUnusedAssets();
		UnityEngine.Object.Destroy(resourceContainer);
		JobSystem.inst.Reset();
		GameUI.inst.AbortCursorObjPlacement(refund: false);
		TownNameUI.inst.Reset();
		Cam.inst.ClearTrack();
		MusicSystem.inst.Reset();
		treeSystem.Reset();
		coppiceTreeSystem.Reset();
		grassSystem.Reset();
		dryGrassSystem.Reset();
		rockScatterSystem.Reset();
		bushesSystem.Reset();
		OrdersManager.inst.Reset();
		PigSystem.inst.Reset();
		DeadVillagerSystem.inst.Reset();
		WolfSystem.inst.Reset();
		SfxSystem.inst.Reset();
		if ((bool)Player.inst)
		{
			Player.inst.Buildings.Clear();
		}
		randomStoneState = new System.Random(1234567);
		caveContainer = new GameObject();
		caveContainer.name = "Caves";
		resourceContainer = new GameObject();
		resourceContainer.name = "Generated Resources";
		TerrainResource.Reset();
		if (villagerGrid != null)
		{
			for (int j = 0; j < villagerGrid.Length; j++)
			{
				villagerGrid[j].villagers.Clear();
			}
		}
		bool num = cellData != null && gridWidth == width && gridHeight == height;
		gridWidth = width;
		gridHeight = height;
		MeshWidth = width * 2 + 1;
		MeshHeight = height * 2 + 1;
		if (!num)
		{
			cellData = new Cell[gridWidth * gridHeight];
			pathCellData = new PathCell[width * gridHeight];
			villagerGrid = new VillagerGrid[gridWidth * gridHeight];
			cellInfluenceData = new CellInfluence[gridWidth * gridHeight];
			cellWaterSupplyData = new CellWaterSuppliers[gridWidth * gridHeight];
			cellProductionInfluenceData = new CellProductionInfluence[gridWidth * gridHeight];
			for (int k = 0; k < gridHeight; k++)
			{
				for (int l = 0; l < gridWidth; l++)
				{
					int num2 = k * gridWidth + l;
					cellData[num2] = new Cell(l, k, num2);
				}
			}
			for (int m = 0; m < gridHeight; m++)
			{
				for (int n = 0; n < gridWidth; n++)
				{
					int num3 = m * gridWidth + n;
					pathCellData[num3] = new PathCell(n, m);
				}
			}
			for (int num4 = 0; num4 < gridHeight; num4++)
			{
				for (int num5 = 0; num5 < gridWidth; num5++)
				{
					int num6 = num4 * gridWidth + num5;
					villagerGrid[num6] = new VillagerGrid();
				}
			}
			for (int num7 = 0; num7 < gridHeight; num7++)
			{
				for (int num8 = 0; num8 < gridWidth; num8++)
				{
					int num9 = num7 * gridWidth + num8;
					cellInfluenceData[num9] = new CellInfluence();
					cellInfluenceData[num9].radiusBonuses = new ArrayExtRef<RadiusBonus>(5);
					cellInfluenceData[num9].radiusHealthBonuses = new ArrayExtRef<RadiusBonusHealth>(5);
				}
			}
			for (int num10 = 0; num10 < gridHeight; num10++)
			{
				for (int num11 = 0; num11 < gridWidth; num11++)
				{
					int num12 = num10 * gridWidth + num11;
					cellProductionInfluenceData[num12] = new CellProductionInfluence();
					cellProductionInfluenceData[num12].radiusBonuses = new List<RadiusBonusProduction>();
					cellProductionInfluenceData[num12].radiusBonusesBuilding = new List<RadiusBonusBuildingProduction>();
				}
			}
			for (int num13 = 0; num13 < gridHeight; num13++)
			{
				for (int num14 = 0; num14 < gridWidth; num14++)
				{
					int num15 = num13 * gridWidth + num14;
					cellWaterSupplyData[num15] = new CellWaterSuppliers();
					cellWaterSupplyData[num15].waterSuppliers = new List<WaterSupplier>();
				}
			}
		}
		else
		{
			for (int num16 = 0; num16 < cellData.Length; num16++)
			{
				cellData[num16].Reset();
			}
			for (int num17 = 0; num17 < villagerGrid.Length; num17++)
			{
				villagerGrid[num17].villagers.Clear();
			}
			for (int num18 = 0; num18 < cellInfluenceData.Length; num18++)
			{
				cellInfluenceData[num18].radiusBonuses.Clear();
			}
			for (int num19 = 0; num19 < cellProductionInfluenceData.Length; num19++)
			{
				cellProductionInfluenceData[num19].radiusBonuses.Clear();
				cellProductionInfluenceData[num19].radiusBonusesBuilding.Clear();
			}
			for (int num20 = 0; num20 < cellWaterSupplyData.Length; num20++)
			{
				cellWaterSupplyData[num20].waterSuppliers.Clear();
			}
		}
		regenRimCells = true;
		TerrainGen.inst.InitializeTerrainMeshes(gridWidth, gridHeight);
		if (LegionSystem.Inst != null)
		{
			LegionSystem.Inst.Reset();
		}
		DynamicWater.inst.Reset();
		DynamicLava.inst.Reset();
		UnitSystem.inst.Reset();
		Table.transform.localScale = new Vector3(gridWidth, 1f, gridHeight);
		if ((bool)DragonSpawn.inst)
		{
			DragonSpawn.inst.Reset();
		}
		if ((bool)GameUI.inst)
		{
			GameUI.inst.Reset();
		}
		pather.InitGrid(gridWidth, gridHeight);
		threadedPather.Reset(gridWidth, gridHeight);
		OrdersManager.inst.Init(gridWidth, gridHeight);
		FishSystem.inst.Init();
		ResourceStackAuto.InitGrid();
		treeSystem.TryInit();
		coppiceTreeSystem.TryInit();
		grassSystem.TryInit();
		dryGrassSystem.TryInit();
		rockScatterSystem.TryInit();
		bushesSystem.TryInit();
		TerrainGen.inst.ClearOverlay(updateToo: true);
		GameUI.inst.CurrPlacementMode.Setup();
		WellManager.inst.Init();
		PublicToiletManager.inst.Init();
		FirehouseManager.inst.Init();
		BuildingCollapseManager.inst.Init();
		BathManager.inst.Reset();
		DynamicMesh.Reset();
		EditTerrainProjectManager.inst.Reset();
		MerchantOrdersManager.inst.Reset();
		LogisticsManager.inst.Reset();
		BirdSystem.inst.Reset();
		CloserHomeFinder.inst.Reset();
		TaxOfficeManager.inst.Reset();
		ClearHostility();
		whale.Init();
		AqueductLine.Clear();
		AqueductJunction.ClearAll();
		Player.inst.hasUsedCheats = KCModHelper.ModLoader.localModsLoadedAtStartup.Count > 0;
		isDemo = false;
		MiniMapUI.inst.Setup(width, height);
		CloudSystem.inst.Reset();
		Inited = true;
	}

	private void Start()
	{
		treeGrowth = GetComponent<TreeGrowth>();
		pather = new Pathfinder();
		Debug.developerConsoleEnabled = false;
	}

	private void OnDestroy()
	{
		threadedPather.Shutdown();
		threadedPather = null;
		pather.Shutdown();
		pather = null;
		cellData = null;
		cellInfluenceData = null;
		cellProductionInfluenceData = null;
		cellWaterSupplyData = null;
	}

	public string GetTextSeed()
	{
		string text = "";
		if (generatedMapsBias == MapBias.Island)
		{
			text += "I";
		}
		if (generatedMapsBias == MapBias.Land)
		{
			text += "L";
		}
		if (generatedMapSize == MapSize.Small)
		{
			text += "S";
		}
		if (generatedMapSize == MapSize.Medium)
		{
			text += "M";
		}
		if (generatedMapSize == MapSize.Large)
		{
			text += "L";
		}
		if (generatedRiverLakes == MapRiverAmount.Normal)
		{
			text += "N";
		}
		if (generatedRiverLakes == MapRiverAmount.High)
		{
			text += "H";
		}
		if (generatedRiverLakes == MapRiverAmount.VeryHigh)
		{
			text += "V";
		}
		if (generatedResourceAmount != MapResourceAmount.Normal)
		{
			text += ResourceAmountSeedChar(generatedResourceAmount);
		}
		return text + seed;
	}

	public bool HasSeed()
	{
		return seed != 0;
	}

	public bool ReadyToBeSeen()
	{
		return framesAfterGenerate >= frameToWaitBeforeSeen;
	}

	public void HideResourceTooltipUIs()
	{
		for (int i = 0; i < TerrainResource.terrainResources.Count; i++)
		{
			TerrainResource.terrainResources.data[i].SetTooltipVisibility(isVisible: false, force: true);
		}
		HideFishResourceTooltips();
	}

	public void ShowResourceTooltipsUIs()
	{
		for (int i = 0; i < TerrainResource.terrainResources.Count; i++)
		{
			TerrainResource.terrainResources.data[i].SetTooltipVisibility(isVisible: true, force: true);
		}
		ShowFishResourceGroupTooltips();
	}

	public void ShowResourceGroupTooltipUIs(int resourceID = -1, bool doShowFish = false)
	{
		FloodFillCrawler floodCrawler = new FloodFillCrawler
		{
			cellsPerFrame = int.MaxValue,
			visited = new bool[gridWidth * gridHeight]
		};
		for (int i = 0; i < TerrainResource.terrainResources.Count; i++)
		{
			TerrainResource terrainResource = TerrainResource.terrainResources.data[i];
			Cell cell = GetCellData(terrainResource.position);
			if (!(terrainResource != null))
			{
				continue;
			}
			if (resourceID != -1 && terrainResource.resourceID != resourceID)
			{
				terrainResource.SetTooltipVisibility(isVisible: false);
				continue;
			}
			Vector3 pos = Vector3.zero;
			int rID = terrainResource.resourceID;
			int rCount = 0;
			Cell prevCell = cell;
			floodCrawler.AddCellToOpenSet(cell);
			floodCrawler.Tick(cell.Position, delegate(Cell cell4, ref List<Cell> set)
			{
				if (!cell4.HasTerrainResourceType(rID))
				{
					return true;
				}
				rCount++;
				pos += cell4.Center2D;
				floodCrawler.AddAllCardinalToOpenSet(cell4);
				prevCell = cell4;
				return true;
			});
			if (rCount > 0)
			{
				pos /= (float)rCount;
				Cell cell2 = GetCellData(pos);
				TerrainResource terrainResource2 = null;
				if (cell2.HasTerrainResourceType(rID))
				{
					terrainResource2 = cell2.terrainResource;
				}
				else
				{
					GetNeighborCells(cell2, ref scratch4);
					for (int num = 0; num < 4; num++)
					{
						Cell cell3 = scratch4[num];
						if (cell3.HasTerrainResourceType(rID))
						{
							terrainResource2 = cell3.terrainResource;
							break;
						}
					}
				}
				if (terrainResource2 != null)
				{
					terrainResource2.SetTooltipVisibility(isVisible: true, force: true);
				}
			}
			floodCrawler.Reset();
		}
		if (doShowFish)
		{
			ShowFishResourceGroupTooltips();
		}
		else
		{
			HideFishResourceTooltips();
		}
	}

	public void ShowFishResourceGroupTooltips()
	{
		fishTooltipCount = 0;
		if (hasVisited == null || hasVisited.Length != gridWidth * gridHeight)
		{
			hasVisited = new bool[gridWidth * gridHeight];
		}
		else
		{
			Util.Memset(hasVisited, 0);
		}
		openset.Clear();
		FishSystem.FishCell[] fishCells = FishSystem.inst.fishCells;
		for (int i = 0; i < fishCells.Length; i++)
		{
			if (hasVisited[i])
			{
				continue;
			}
			if (fishCells[i].owners.Count <= 0)
			{
				hasVisited[i] = true;
				continue;
			}
			int num = 0;
			Vector3 zero = Vector3.zero;
			tempPos.ClearFast();
			openset.Add(i);
			while (openset.Count > 0)
			{
				int num2 = openset.PopFirst();
				if (!hasVisited[num2])
				{
					hasVisited[num2] = true;
					if (fishCells[num2].owners.Count > 0)
					{
						int num3 = num2 % gridWidth;
						int num4 = num2 / gridWidth;
						zero.x += num3;
						zero.z += num4;
						num++;
						tempPos.Add(new Vector3(num3, 0f, num4));
						AddExtendedCellsIndexToOpenset(num3, num4, ref openset);
					}
				}
			}
			if (num <= 0)
			{
				continue;
			}
			zero.x /= num;
			zero.z /= num;
			Vector3 targetPosition = zero;
			float num5 = float.MaxValue;
			for (int j = 0; j < tempPos.Count; j++)
			{
				float num6 = Mathff.DistSqrdXZ(zero, tempPos.data[j]);
				if (num6 < num5)
				{
					targetPosition = tempPos.data[j];
					num5 = num6;
				}
			}
			targetPosition.y = TerrainGen.SeaLevel + 0.15f;
			ResourceTooltipUI fishTooltip = GetFishTooltip();
			fishTooltip.targetPosition = targetPosition;
			Util.SetActive(fishTooltip.gameObject, active: true);
		}
		for (int k = fishTooltipCount; k < fishTooltipPool.Count; k++)
		{
			Util.SetActive(fishTooltipPool[k].gameObject, active: false);
		}
	}

	private void AddExtendedCellsIndexToOpenset(int x, int z, ref ArrayExt<int> openset)
	{
		for (int i = -3; i < 3; i++)
		{
			int num = x + i;
			if (num < 0 || num >= gridWidth)
			{
				continue;
			}
			for (int j = -3; j < 3; j++)
			{
				int num2 = z + j;
				if (num2 >= 0 && num2 < gridHeight)
				{
					openset.Add(num + num2 * gridWidth);
				}
			}
		}
	}

	public void HideFishResourceTooltips()
	{
		for (int i = 0; i < fishTooltipPool.Count; i++)
		{
			Util.SetActive(fishTooltipPool[i].gameObject, active: false);
		}
	}

	private ResourceTooltipUI GetFishTooltip()
	{
		if (fishTooltipCount == fishTooltipPool.Count)
		{
			ResourceTooltipUI component = UnityEngine.Object.Instantiate(resourceTooltipPrefab, resourceTooltipContainer.transform).GetComponent<ResourceTooltipUI>();
			component.doScaleToCamDist = true;
			component.SetTerm("fish");
			fishTooltipPool.Add(component);
		}
		return fishTooltipPool[fishTooltipCount++];
	}

	public void ShowResourceGroupTooltipUIs(int[] resourceIDs, bool doShowFish = false)
	{
		FloodFillCrawler floodCrawler = new FloodFillCrawler
		{
			cellsPerFrame = int.MaxValue,
			visited = new bool[gridWidth * gridHeight]
		};
		for (int i = 0; i < TerrainResource.terrainResources.Count; i++)
		{
			TerrainResource terrainResource = TerrainResource.terrainResources.data[i];
			Cell cell = GetCellData(terrainResource.position);
			if (!(terrainResource != null))
			{
				continue;
			}
			bool flag = false;
			for (int j = 0; j < resourceIDs.Length; j++)
			{
				if (resourceIDs[j] != -1 && terrainResource.resourceID == resourceIDs[j])
				{
					flag = true;
				}
			}
			if (!flag)
			{
				terrainResource.SetTooltipVisibility(isVisible: false);
				continue;
			}
			Vector3 pos = Vector3.zero;
			int rID = terrainResource.resourceID;
			int rCount = 0;
			Cell prevCell = cell;
			floodCrawler.AddCellToOpenSet(cell);
			floodCrawler.Tick(cell.Position, delegate(Cell cell2, ref List<Cell> set)
			{
				if (!cell2.HasTerrainResourceType(rID))
				{
					return true;
				}
				rCount++;
				pos += cell2.Center2D;
				floodCrawler.AddAllCardinalToOpenSet(cell2);
				prevCell = cell2;
				return true;
			});
			if (rCount > 0)
			{
				pos /= (float)rCount;
				terrainResource = GetCellData(pos).terrainResource;
				if ((bool)terrainResource)
				{
					terrainResource.SetTooltipVisibility(isVisible: true, force: true);
				}
				else
				{
					prevCell?.terrainResource.SetTooltipVisibility(isVisible: true, force: true);
				}
			}
			floodCrawler.Reset();
		}
		if (doShowFish)
		{
			ShowFishResourceGroupTooltips();
		}
		else
		{
			HideFishResourceTooltips();
		}
	}

	public void Generate(int _seed = 0, bool useLastSettings = false)
	{
		guid = Guid.NewGuid();
		if ((bool)Player.inst)
		{
			Player.inst.Reset();
		}
		BlockStackUpdateSystem.inst.Reset();
		if (!useLastSettings)
		{
			generatedMapSize = mapSize;
			if (generatedMapSize == MapSize.Random)
			{
				generatedMapSize = (MapSize)SRand.Range(0, 3);
			}
			generatedMapsBias = mapBias;
			if (generatedMapsBias == MapBias.Random)
			{
				generatedMapsBias = (MapBias)SRand.Range(0, 2);
			}
			generatedRiverLakes = mapRiverAmount;
			generatedResourceAmount = mapResourceAmount;
		}
		if (demoMode)
		{
			generatedMapsBias = MapBias.Land;
			generatedMapSize = MapSize.Small;
			mapSizeDropdown.value = 0;
			mapSizeDropdown.interactable = false;
			if (mapSizeDropdown.GetComponent<StaticTooltipHook>() == null)
			{
				mapSizeDropdown.gameObject.AddComponent<StaticTooltipHook>();
			}
			mapSizeDropdown.GetComponent<StaticTooltipHook>().SetTerm("demo_newmap_size_locked");
			mapTypeDropdown.value = 0;
			mapTypeDropdown.interactable = false;
			if (mapTypeDropdown.GetComponent<StaticTooltipHook>() == null)
			{
				mapTypeDropdown.gameObject.AddComponent<StaticTooltipHook>();
			}
			mapTypeDropdown.GetComponent<StaticTooltipHook>().SetTerm("demo_newmap_type_locked");
			if (editMapButton.GetComponent<StaticTooltipHook>() == null)
			{
				editMapButton.gameObject.AddComponent<StaticTooltipHook>();
			}
			editMapButton.interactable = false;
			editMapButton.GetComponent<StaticTooltipHook>().SetTerm("demo_newmap_editmap_locked");
		}
		seed = _seed;
		if (seed == 0)
		{
			seed = SRand.Range(1, int.MaxValue);
		}
		GameState.inst.mainMenuMode.mapEditUI.GetComponent<MapEdit>().dirty = false;
		LoadSave.currentMapName = null;
		AIBrainsContainer.inst.ClearAIs();
		SRand.SetSeed(seed);
		GenLand();
		ShowResourceGroupTooltipUIs(-1, doShowFish: true);
		if (SeedButtonUI.inst != null)
		{
			SeedButtonUI.inst.SetSeed(seed);
		}
		for (int i = 0; i < cellData.Length; i++)
		{
			cellData[i].StorePostGenerationType();
		}
		SetupInitialPathCosts();
		framesAfterGenerate = 0;
		RivalKingdomSettingsUI.inst?.UpdateSlotAvailability();
		MiniMapUI.inst.UpdateMapPixels(doAllAndApply: true);
		TerrainGen.inst.CaptureOriginalHeights();
		if (MapEditorController.inst != null)
		{
			MapEditorController.inst.ResetForRegeneratedWorld();
		}
	}

	internal void ReplaceItems(int x, int z)
	{
		grassSystem.ReplaceItems(x, z, gridWidth);
		dryGrassSystem.ReplaceItems(x, z, gridWidth);
		rockScatterSystem.ReplaceItems(x, z, gridWidth);
		treeSystem.ReplaceItems(x, z, gridWidth);
		coppiceTreeSystem.ReplaceItems(x, z, gridWidth);
		bushesSystem.ReplaceItems(x, z, gridWidth);
	}

	public static char ResourceAmountSeedChar(MapResourceAmount amount)
	{
		if (amount != MapResourceAmount.Low)
		{
			return 'H';
		}
		return 'L';
	}

	public static bool TryParseResourceAmountSeedChar(char c, out MapResourceAmount amount)
	{
		amount = c switch
		{
			'H' => MapResourceAmount.High, 
			'L' => MapResourceAmount.Low, 
			_ => MapResourceAmount.Normal, 
		};
		return amount != MapResourceAmount.Normal;
	}

	private void ScatterRocks(Cell cell)
	{
		if (cell.Type == TerrainType.Water)
		{
			return;
		}
		GetNeighborCells(cell, ref scratch4);
		for (int i = 0; i < 4; i++)
		{
			if (scratch4[i] != null && scratch4[i].Type == TerrainType.Water)
			{
				return;
			}
		}
		rockScatterSystem.PlaceItem(cell);
	}

	public void DrawLandmassCircleAt(Vector3 center, int idx, float r = 0.5f, float duration = 10f)
	{
		Color color = Color.yellow;
		if (idx == 1)
		{
			color = Color.red;
		}
		if (idx == 2)
		{
			color = Color.magenta;
		}
		if (idx == 3)
		{
			color = Color.blue;
		}
		if (idx == 4)
		{
			color = Color.green;
		}
		if (idx == 5)
		{
			color = Color.cyan;
		}
		if (idx != -1)
		{
			DebugEx.DrawCircle(center, r, color, new Vector3(0f, 1f, 0f), new Vector3(1f, 0f, 0f), 4f, duration);
		}
	}

	public void InitLandmassData(int n)
	{
		numLandMasses = n;
		villagersPerLandMass.Clear();
		for (int i = 0; i < numLandMasses; i++)
		{
			villagersPerLandMass.Add(new ArrayExt<Villager>(200));
		}
	}

	public static void ForcePhysicsSimulationUpdate()
	{
		SimulationMode simulationMode = Physics.simulationMode;
		Physics.simulationMode = SimulationMode.Script;
		Physics.Simulate(Time.fixedDeltaTime);
		Physics.simulationMode = simulationMode;
	}

	private void SetupWaterTilesBasedOnTileHeight()
	{
		int i = 0;
		for (int num = cellData.Length; i < num; i++)
		{
			Cell cell = cellData[i];
			float groundHeight = TerrainGen.inst.GetGroundHeight((float)cell.x + 0.5f, (float)cell.z + 0.5f);
			if (cell.Type != TerrainType.Obstruction)
			{
				if (cell.Type != TerrainType.Water && groundHeight < TerrainGen.waterHeightTestThresold)
				{
					TerrainGen.inst.SetWaterTile(cell.x, cell.z, modifyHeight: false);
				}
				else if (cell.Type != TerrainType.None && groundHeight > TerrainGen.waterHeightTestThresold)
				{
					cell.Type = TerrainType.None;
				}
			}
		}
	}

	private void GenLand()
	{
		bool flag = false;
		while (true)
		{
			int index = (int)generatedMapSize;
			int num = 0;
			if (generatedMapsBias == MapBias.Island)
			{
				num = 7;
			}
			int width = SRand.Range(mapSizeDefs[index].GridMin + num, mapSizeDefs[index].GridMax + num);
			int height = SRand.Range(mapSizeDefs[index].GridMin + num, mapSizeDefs[index].GridMax + num);
			Setup(width, height);
			TerrainGen.inst.GenerateWater(generatedMapSize);
			for (int i = 0; i < cellData.Length; i++)
			{
				cellData[i].deepWater = cellData[i].Type == TerrainType.Water;
			}
			int j = 0;
			for (int num2 = gridWidth * gridHeight; j < num2; j++)
			{
				cellData[j].landMassIdx = -1;
			}
			TerrainGen.inst.SmoothRadiusYLessThanWaterTestThreshold(4, float.MinValue, TerrainGen.waterHeightTestThresold - 0.01f);
			for (int k = 0; k < 4; k++)
			{
				TerrainGen.inst.SmoothRadiusYLessThanWaterTestThreshold(2, float.MinValue, TerrainGen.waterHeightTestThresold - 0.01f);
			}
			for (int l = 0; l < inst.GridHeight; l += TerrainGen.inst.bumpStepSize)
			{
				for (int m = 0; m < inst.GridWidth; m += TerrainGen.inst.bumpStepSize)
				{
					float num3 = (float)TerrainGen.inst.bumpStepSize * 0.5f;
					int cx = m + (int)SRand.Range(0f - num3, num3);
					int cz = l + (int)SRand.Range(0f - num3, num3);
					int bumpRadius = TerrainGen.inst.bumpRadius;
					float depth = TerrainGen.inst.bumpDepth * (float)((SRand.Range(0, 100) <= 50) ? 1 : (-1));
					TerrainGen.inst.MakeBump(cx, cz, bumpRadius, depth);
				}
			}
			for (int n = 0; n < 2; n++)
			{
				TerrainGen.inst.SmoothRadiusFunctionYGreaterThanWaterHeight(1);
			}
			SetupWaterTilesBasedOnTileHeight();
			TerrainGen.inst.AddNoise();
			TerrainGen.inst.FinalizeChanges();
			ForcePhysicsSimulationUpdate();
			TerrainGen.inst.BuildNatureObstructionField();
			bool[] array = new bool[9];
			for (int num4 = 0; num4 < gridWidth; num4++)
			{
				for (int num5 = 0; num5 < gridHeight; num5++)
				{
					int num6 = num4 + num5 * gridWidth;
					Cell cell = cellData[num6];
					int num7 = 0;
					int num8 = 0;
					double num9 = Math.Round(((float)cell.x + 0.5f) * 2f) / 2.0;
					double num10 = Math.Round(((float)cell.z + 0.5f) * 2f) / 2.0;
					int num11 = (int)(num9 * 2.0) + (int)(num10 * 2.0) * MeshWidth;
					for (int num12 = -1; num12 <= 1; num12++)
					{
						for (int num13 = -1; num13 <= 1; num13++)
						{
							int num14 = num11 + num12 + MeshWidth * num13;
							_ = num14 % MeshWidth;
							_ = num14 / MeshWidth;
							if (TerrainGen.inst.mountainObstructionField[num14] > MountainPlacer.MESH_TO_TERRAIN_THRESHOLD)
							{
								array[num7] = true;
								num8++;
							}
							else
							{
								array[num7] = false;
							}
							num7++;
						}
					}
					if (array[4] || num8 > 2)
					{
						cell.Type = TerrainType.Obstruction;
					}
				}
			}
			ForcePhysicsSimulationUpdate();
			TerrainGen.inst.BuildNatureObstructionField();
			DynamicWater.inst.CutRivers();
			TerrainGen.inst.UpdateTerrainDeformations();
			DynamicWater.inst.Simulate(50);
			SetupWaterTilesBasedOnTileHeight();
			GenerateLandMassIds(fillInlandOceans: true, applyCleanup: true, notifyFill: false);
			SizeToDepostsInfo sizeToDepostsInfo;
			if (generatedMapSize != MapSize.Small)
			{
				sizeToDepostsInfo = ((generatedMapSize == MapSize.Large) ? largeMapDepositInfo : mediumMapDepositInfo);
			}
			else
			{
				sizeToDepostsInfo = smallMapDepositInfo;
			}
			bool flag2 = generatedMapsBias == MapBias.Island;
			MountainPlacerResource.DesiredStone = (flag2 ? sizeToDepostsInfo.numStoneIsland : sizeToDepostsInfo.numStoneLand).Get(generatedResourceAmount);
			MountainPlacerResource.DesiredMarble = (flag2 ? sizeToDepostsInfo.numMarbleIsland : sizeToDepostsInfo.numMarbleLand).Get(generatedResourceAmount);
			MountainPlacerResource.DesiredIron = (flag2 ? sizeToDepostsInfo.numIronIsland : sizeToDepostsInfo.numIronLand).Get(generatedResourceAmount);
			MountainPlacerResource.Density = resourceDensity[(int)generatedResourceAmount];
			List<GameObject> list = new List<GameObject>(TerrainGen.inst.mountainRocks);
			for (int num15 = TerrainGen.inst.centerMountainsStart - 1; num15 > 0; num15--)
			{
				int num16 = SRand.Range(0, num15 + 1);
				List<GameObject> list2 = list;
				int index2 = num15;
				List<GameObject> list3 = list;
				int index3 = num16;
				GameObject gameObject = list[num16];
				GameObject gameObject2 = list[num15];
				GameObject gameObject3 = (list2[index2] = gameObject);
				gameObject3 = (list3[index3] = gameObject2);
			}
			MountainPlacer.PlaceResources(list, TerrainGen.inst.centerMountainsStart);
			ArrayExt<Cell>[] array2 = new ArrayExt<Cell>[NumLandMasses];
			for (int num17 = 0; num17 < NumLandMasses; num17++)
			{
				array2[num17] = new ArrayExt<Cell>(cellData.Length);
				for (int num18 = 0; num18 < cellsToLandmass[num17].Count; num18++)
				{
					Cell cell2 = cellsToLandmass[num17].data[num18];
					int num19 = cellData.Length;
					int num20 = cell2.x + 1 + cell2.z * gridWidth;
					if (num20 >= 0 && num20 < num19 && cellData[num20].Type == TerrainType.Water)
					{
						array2[num17].Add(cell2);
						continue;
					}
					num20 = cell2.x - 1 + cell2.z * gridWidth;
					if (num20 >= 0 && num20 < num19 && cellData[num20].Type == TerrainType.Water)
					{
						array2[num17].Add(cell2);
						continue;
					}
					num20 = cell2.x + (cell2.z + 1) * gridWidth;
					if (num20 >= 0 && num20 < num19 && cellData[num20].Type == TerrainType.Water)
					{
						array2[num17].Add(cell2);
						continue;
					}
					num20 = cell2.x + (cell2.z - 1) * gridWidth;
					if (num20 >= 0 && num20 < num19 && cellData[num20].Type == TerrainType.Water)
					{
						array2[num17].Add(cell2);
					}
				}
			}
			Water.UpdateNeeded = true;
			GetComponent<TreeGrowth>().GenerateTrees();
			int index4 = 0;
			for (int num21 = 0; num21 < NumLandMasses; num21++)
			{
				GetComponent<TreeGrowth>().PlaceSplots(num21, baseDensities[index4].treeSplots);
				FishSystem.inst.PlaceSplots(num21, baseDensities[index4].fishSplots, array2[num21]);
			}
			TerrainGen.inst.grassEffectTimeCode = 0f;
			TerrainGen.inst.tempEffectTimeCode = 0f;
			TerrainGen.inst.FertilityBlendTime = 0f;
			int num22 = 0;
			int num23 = 0;
			List<IslandSignature> list4 = islandSignatures;
			if (generatedMapSize == MapSize.Small)
			{
				list4 = smallIslandSignatures;
			}
			else if (generatedMapSize == MapSize.Large)
			{
				list4 = largeIslandSignatures;
			}
			for (int num24 = 0; num24 < list4.Count; num24++)
			{
				IslandSignature islandSignature = list4[num23 % list4.Count];
				num23++;
				GetComponent<TreeGrowth>().PlaceSplots(num22, islandSignature.treeSplots);
				FishSystem.inst.PlaceSplots(num22, islandSignature.fishSplots, array2[num22]);
				num22++;
				num22 %= NumLandMasses;
			}
			bool placedWitchHut = false;
			int numWolfCaves = GetDefaultWolfCaves();
			for (int num25 = 0; num25 < cellsToLandmass.Length; num25++)
			{
				if (cellsToLandmass[num25].Count >= 200)
				{
					for (int num26 = 0; num26 < cellsToLandmass[num25].Count; num26++)
					{
						Cell cell3 = cellsToLandmass[num25].data[num26];
						DoPlaceCave(cell3, ref numWolfCaves, ref placedWitchHut);
					}
				}
			}
			Water.inst.UpdateDistanceFields();
			FishSystem.inst.AddInitialFish();
			TerrainGen.inst.SetupTerrainGenCells(cellData);
			TerrainGen.inst.UpdateFertility(doInstantBlend: true);
			if (FindValidStartLandmasses() || flag)
			{
				break;
			}
			flag = true;
		}
		TerrainGen.inst.ClearOverlay(updateToo: false);
		for (int num27 = 0; num27 < gridWidth * gridHeight; num27++)
		{
			AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(GetCellDataUnsafe(num27).landMassIdx);
			if (kingdomByLandmass != null)
			{
				TerrainGen.inst.SetOverlayTileColor(num27 % gridWidth, num27 / gridWidth, kingdomByLandmass.GetColor());
			}
		}
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
		Player.inst.ResetPerLandMassData();
		ShipSystem.inst.Init();
		PlaceGrass();
		for (int num28 = 0; num28 < TerrainGen.inst.mountainRocks.Count; num28++)
		{
			Vector3 position = TerrainGen.inst.mountainRocks[num28].transform.position;
			int num29 = 5;
			int num30 = (int)Mathf.Clamp(position.x - (float)num29, 0f, gridWidth - 1);
			int num31 = (int)Mathf.Clamp(position.z - (float)num29, 0f, gridHeight - 1);
			int num32 = (int)Mathf.Clamp(position.x + (float)num29, 0f, gridWidth - 1);
			int num33 = (int)Mathf.Clamp(position.z + (float)num29, 0f, gridHeight - 1);
			for (int num34 = num31; num34 <= num33; num34++)
			{
				for (int num35 = num30; num35 <= num32; num35++)
				{
					float num36 = Mathff.DistXZ(position, new Vector3(num35, 0f, num34));
					float num37 = 1f - num36 / (float)num29;
					if (SRand.value < num37 * num37)
					{
						int num38 = SRand.Range(0, rockScatterSystem.itemsPerCell);
						for (int num39 = 0; num39 < num38; num39++)
						{
							rockScatterSystem.PlaceItem(cellData[num34 * gridWidth + num35], ignoreWater: true);
						}
					}
				}
			}
		}
		for (int num40 = 1; num40 < gridHeight - 1; num40++)
		{
			for (int num41 = 1; num41 < gridWidth - 1; num41++)
			{
				if (SRand.value < 0.1f)
				{
					treeSystem.PlaceItem(cellData[num40 * gridWidth + num41]);
					if (SRand.value < 0.4f)
					{
						treeSystem.PlaceItem(cellData[num40 * gridWidth + num41]);
					}
				}
				if (SRand.value < 0.1f)
				{
					bushesSystem.PlaceItem(cellData[num40 * gridWidth + num41]);
					if (SRand.value < 0.6f)
					{
						bushesSystem.PlaceItem(cellData[num40 * gridWidth + num41]);
					}
					if (SRand.value < 0.6f)
					{
						bushesSystem.PlaceItem(cellData[num40 * gridWidth + num41]);
					}
				}
			}
		}
		for (int num42 = 1; num42 < gridHeight - 1; num42++)
		{
			for (int num43 = 1; num43 < gridWidth - 1; num43++)
			{
				bool flag3 = false;
				if (SRand.value < randomRockScatter && treeSystem.ItemAmount(cellData[num42 * gridWidth + num43]) <= 0)
				{
					flag3 = true;
					ScatterRocks(cellData[num42 * gridWidth + num43]);
					if ((double)SRand.value < 0.2)
					{
						ScatterRocks(cellData[num42 * gridWidth + num43]);
					}
				}
				if (!flag3)
				{
					int num44 = treeSystem.ItemAmount(num42 * gridWidth + num43);
					for (int num45 = 0; num45 < offsets.Length; num45++)
					{
						num44 += treeSystem.ItemAmount((num42 + (int)offsets[num45].z) * gridWidth + (num43 + (int)offsets[num45].x));
					}
					for (int num46 = 0; num46 < num44 && num46 < bushesSystem.itemsPerCell; num46++)
					{
						bushesSystem.PlaceItem(cellData[num42 * gridWidth + num43]);
					}
					int num47 = 0;
					if (cellData[num42 * gridWidth + num43].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					if (cellData[(num42 + 1) * gridWidth + num43].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					if (cellData[(num42 - 1) * gridWidth + num43].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					if (cellData[num42 * gridWidth + (num43 + 1)].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					if (cellData[num42 * gridWidth + (num43 - 1)].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					if (cellData[(num42 + 1) * gridWidth + (num43 + 1)].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					if (cellData[(num42 - 1) * gridWidth + (num43 + 1)].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					if (cellData[(num42 + 1) * gridWidth + (num43 - 1)].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					if (cellData[(num42 - 1) * gridWidth + (num43 - 1)].Type == TerrainType.Obstruction)
					{
						num47++;
					}
					for (int num48 = 0; num48 < num47 && num48 < bushesSystem.itemsPerCell; num48++)
					{
						bushesSystem.PlaceItem(cellData[num42 * gridWidth + num43], ignoreWater: false, allowOnMountains: true);
					}
				}
			}
		}
		TerrainGen.inst.terrainSkirt.RebuildSkirt();
		TerrainGen.inst.ResetPatchMap();
		TerrainGen.inst.SetTerrainHighestY();
		TerrainGen.inst.UpdateTextures();
		ForcePhysicsSimulationUpdate();
		TerrainGen.inst.BuildNatureObstructionField();
		TerrainGen.inst.CalcAveragedWorldCenter();
		worldGenerationComplete?.Invoke();
	}

	private void DoPlaceCave(Cell cell, ref int numWolfCaves, ref bool placedWitchHut)
	{
		if (cell.Type != TerrainType.None || treeSystem.ItemAmount(cell) > 0)
		{
			return;
		}
		int x = cell.x;
		int z = cell.z;
		int num = 0;
		int num2 = Mathff.Clamp(x - 1, 0, gridWidth - 1);
		int num3 = Mathff.Clamp(z - 1, 0, gridHeight - 1);
		int num4 = Mathff.Clamp(x + 1, 0, gridWidth - 1);
		int num5 = Mathff.Clamp(z + 1, 0, gridHeight - 1);
		for (int i = num3; i <= num5; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				Cell cellToChop = cellData[i * gridWidth + j];
				if (treeSystem.ItemAmount(cellToChop) > 0)
				{
					num++;
				}
			}
		}
		bool flag = false;
		int territory = WolfDen.territory;
		int num6 = Mathff.Clamp(x - territory, 0, gridWidth - 1);
		int num7 = Mathff.Clamp(z - territory, 0, gridHeight - 1);
		int num8 = Mathff.Clamp(x + territory, 0, gridWidth - 1);
		int num9 = Mathff.Clamp(z + territory, 0, gridHeight - 1);
		for (int k = num7; k <= num9; k++)
		{
			int num10 = num6;
			while (num10 <= num8)
			{
				if (!(cellData[k * gridWidth + num10].terrainResource != null))
				{
					num10++;
					continue;
				}
				goto IL_0146;
			}
			continue;
			IL_0146:
			flag = true;
			break;
		}
		int num11 = WolfDen.territory * 2 + 1;
		int num12 = Mathff.Clamp(x - num11, 0, gridWidth - 1);
		int num13 = Mathff.Clamp(z - num11, 0, gridHeight - 1);
		int num14 = Mathff.Clamp(x + num11, 0, gridWidth - 1);
		int num15 = Mathff.Clamp(z + num11, 0, gridHeight - 1);
		bool flag2 = false;
		for (int l = num13; l <= num15; l++)
		{
			int num16 = num12;
			while (num16 <= num14)
			{
				Cell cell2 = cellData[l * gridWidth + num16];
				if (cell2.Type != TerrainType.EmptyCave && cell2.OccupyingStructure.Count <= 0)
				{
					num16++;
					continue;
				}
				goto IL_01fa;
			}
			continue;
			IL_01fa:
			flag2 = true;
			break;
		}
		if (!flag2 && num >= caveSpawnTreeNeighborThreshold && !flag)
		{
			_ = 0;
		}
	}

	private int GetDefaultWolfCaves()
	{
		return gridWidth * gridHeight / 300;
	}

	private void PlaceCavesWitches()
	{
		placedCavesWitches = true;
		bool placedWitchHut = false;
		int numWolfCaves = GetDefaultWolfCaves();
		for (int i = 2; i < gridWidth; i++)
		{
			for (int j = 2; j < gridHeight; j++)
			{
				Cell cellDataUnsafe = GetCellDataUnsafe(i, j);
				DoPlaceCave(cellDataUnsafe, ref numWolfCaves, ref placedWitchHut);
			}
		}
	}

	public bool FindValidStartLandmasses()
	{
		this.landmassStartInfo.Clear();
		for (int i = 0; i < NumLandMasses; i++)
		{
			this.landmassStartInfo.Add(new LandmassStartInfo
			{
				landmass = i
			});
		}
		for (int j = 0; j < cellData.Length; j++)
		{
			Cell cell = cellData[j];
			if (cell.landMassIdx != -1)
			{
				LandmassStartInfo landmassStartInfo = this.landmassStartInfo[cell.landMassIdx];
				landmassStartInfo.size++;
				if (treeSystem.ItemAmount(cell) > 0)
				{
					landmassStartInfo.numTreeTiles++;
				}
				if (cell.GetFertility() > 0)
				{
					landmassStartInfo.numFertileTiles++;
				}
				if (cell.HasTerrainResourceType(2))
				{
					landmassStartInfo.numStones++;
				}
				if (cell.HasTerrainResourceType(5))
				{
					landmassStartInfo.numIrons++;
				}
			}
		}
		validStartLandmassForAICount = 0;
		validStartLandmassCount = 0;
		for (int k = 0; k < this.landmassStartInfo.Count; k++)
		{
			if (IsValidStartLandmass(k))
			{
				validStartLandmassCount++;
			}
			if (IsValidStartLandmassForAI(k))
			{
				validStartLandmassForAICount++;
			}
		}
		return validStartLandmassCount > 0;
	}

	public static Material GetUniMaterialFor(int landmass)
	{
		return GetLandmassOwner(landmass).UniMaterial;
	}

	public static Material GetUniMaterialTerrainFormFor(int landmass)
	{
		return GetLandmassOwner(landmass).UniMaterialTerrainForm;
	}

	public static LandmassOwner GetLandmassOwner(int landmass)
	{
		if (LandMassOwnerLookup != null && landmass >= 0 && landmass < LandMassOwnerLookup.Length)
		{
			return LandMassOwnerLookup[landmass];
		}
		return null;
	}

	public static LandmassOwner GetLandmassOwnerByTeamId(int teamId)
	{
		for (int i = 0; i < LandMassOwners.Count; i++)
		{
			if (LandMassOwners.data[i].teamId == teamId)
			{
				return LandMassOwners.data[i];
			}
		}
		return null;
	}

	public static LandmassOwner GetLandmassOwnerByBannerIdx(int bannerIdx)
	{
		for (int i = 0; i < LandMassOwners.Count; i++)
		{
			if (LandMassOwners.data[i].bannerIdx == bannerIdx)
			{
				return LandMassOwners.data[i];
			}
		}
		return null;
	}

	public static bool IsAILandmass(int landmass)
	{
		LandmassOwner landmassOwner = GetLandmassOwner(landmass);
		if (landmassOwner != null)
		{
			return landmassOwner != Player.inst.PlayerLandmassOwner;
		}
		return false;
	}

	public ArrayExt<Villager> GetVillagersForLandMass(int idx)
	{
		if (idx >= 0 && idx < villagersPerLandMass.Count)
		{
			return villagersPerLandMass.data[idx];
		}
		return emptyVillagerList;
	}

	public int GetVillagerCountForLandmass(int idx)
	{
		if (idx >= 0 && idx < villagersPerLandMass.Count)
		{
			return villagersPerLandMass.data[idx].Count;
		}
		return 0;
	}

	public void AddVillagerToLandmass(int landMassIdx, Villager villager)
	{
		villager.landMass = landMassIdx;
		if (landMassIdx >= 0 && landMassIdx < villagersPerLandMass.Count)
		{
			villagersPerLandMass.data[landMassIdx].Add(villager);
		}
	}

	public void RemoveVillagerFromLandmass(Villager villager)
	{
		int landMass = villager.landMass;
		if (landMass >= 0 && landMass < villagersPerLandMass.Count)
		{
			villagersPerLandMass.data[landMass].RemoveSwap(villager);
		}
	}

	public void ResetVillagersToLandmasses()
	{
		for (int i = 0; i < villagersPerLandMass.Count; i++)
		{
			villagersPerLandMass.data[i].ClearFast();
		}
	}

	public void RebuildVillagerGrid()
	{
		if (villagerGrid != null)
		{
			for (int i = 0; i < villagerGrid.Length; i++)
			{
				villagerGrid[i].villagers.ClearFast();
			}
			ArrayExt<Villager> workers = Player.inst.Workers;
			_ = villagerGrid.Length;
			int j = 0;
			for (int count = workers.Count; j < count; j++)
			{
				Villager v = workers.data[j];
				AddToVillagerGrid(v);
			}
		}
	}

	public void AddToVillagerGrid(Villager v)
	{
		int num = (int)v.Pos.x;
		int num2 = (int)v.Pos.z;
		int num3 = num2 * gridWidth + num;
		if (num3 >= 0 && num3 < villagerGrid.Length)
		{
			villagerGrid[num3].villagers.Add(v);
			v.lastCell = GetCellData(num, num2);
		}
	}

	public void RemoveFromVillagerGrid(Villager v, ref Cell lastCell)
	{
		if (lastCell != null)
		{
			int x = lastCell.x;
			int num = lastCell.z * gridWidth + x;
			if (num >= 0 && num < villagerGrid.Length)
			{
				villagerGrid[num].villagers.RemoveSwap(v);
			}
		}
		lastCell = null;
	}

	public int AvailableWorkersOnLandMass(int landMass, bool includeIdleJobs = true)
	{
		ArrayExt<Villager> villagersForLandMass = GetVillagersForLandMass(landMass);
		int num = 0;
		int i = 0;
		for (int count = villagersForLandMass.Count; i < count; i++)
		{
			if (villagersForLandMass.data[i].job == null || (includeIdleJobs && villagersForLandMass.data[i].job.idleJob))
			{
				num++;
			}
		}
		return num;
	}

	public float FindClosestNeighborHeight(int cx, int cz, Building building)
	{
		float tileHeight = TerrainGen.inst.GetTileHeight(cx, cz);
		int minX = cx;
		int maxX = cx;
		int minZ = cz;
		int maxZ = cz;
		int p = 0;
		float totalY = 0f;
		building.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			int num8 = x * 2 + 1;
			int num9 = z * 2 + 1;
			for (int i = num8 - 1; i <= num8 + 1; i++)
			{
				for (int j = num9 - 1; j <= num9 + 1; j++)
				{
					totalY += TerrainGen.inst.GetVertY(i, j);
					p++;
				}
			}
			if (x < minX)
			{
				minX = x;
			}
			if (x > maxX)
			{
				maxX = x;
			}
			if (z < minZ)
			{
				minZ = z;
			}
			if (z > maxZ)
			{
				maxZ = z;
			}
		});
		tileHeight = ((p > 0) ? (totalY /= p) : tileHeight);
		float num = float.MaxValue;
		float result = tileHeight;
		minX--;
		minZ--;
		maxX++;
		maxZ++;
		minX = Mathf.Clamp(minX, 0, gridWidth - 1);
		maxX = Mathf.Clamp(maxX, 0, gridWidth - 1);
		minZ = Mathf.Clamp(minZ, 0, gridHeight - 1);
		maxZ = Mathf.Clamp(maxZ, 0, gridHeight - 1);
		bool flag = false;
		for (int num2 = minX; num2 <= maxX; num2++)
		{
			for (int num3 = minZ; num3 <= maxZ; num3++)
			{
				if ((num2 != minX && num2 != maxX && num3 != minZ && num3 != maxZ) || (num2 == minX && num3 == minZ) || (num2 == maxX && num3 == minZ) || (num2 == maxX && num3 == maxZ) || (num2 == minX && num3 == maxZ))
				{
					continue;
				}
				Building building2 = GetCellData(num2, num3).StructureFindByCategory(building.categoryHash);
				if (!(building2 == null))
				{
					flag = true;
					float y = building2.transform.position.y;
					float num4 = Mathff.Abs(tileHeight - y);
					if (num4 < num)
					{
						result = y;
						num = num4;
					}
				}
			}
		}
		if (!flag)
		{
			for (int num5 = minX; num5 <= maxX; num5++)
			{
				for (int num6 = minZ; num6 <= maxZ; num6++)
				{
					if ((num5 != minX || num6 != minZ) && (num5 != maxX || num6 != minZ) && (num5 != maxX || num6 != maxZ) && (num5 != minX || num6 != maxZ))
					{
						continue;
					}
					Building building3 = GetCellData(num5, num6).StructureFindByCategory(building.categoryHash);
					if (!(building3 == null))
					{
						float y2 = building3.transform.position.y;
						float num7 = Mathff.Abs(tileHeight - y2);
						if (num7 < num)
						{
							result = y2;
							num = num7;
						}
					}
				}
			}
		}
		return result;
	}

	public static Vector3 GetCellHeightPos(Cell cell)
	{
		Vector3 pos = cell.Center3D;
		TerrainGen.inst.GetGroundHeight(ref pos);
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (building.IsBuilt())
			{
				if (building.uniqueNameHash == castlestairsHash)
				{
					pos.y += 0.5f;
				}
				else
				{
					pos.y += (building.Stackable ? ((float)building.StackHeight * 0.25f) : 0f);
				}
			}
		}
		return pos;
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		_ = Time.deltaTime;
		if (regenRimCells)
		{
			rimCells = (from cell2 in inst.GetCellsData()
				where cell2.Position.x == 0f || cell2.Position.x == (float)(gridWidth - 1) || cell2.Position.z == 0f || cell2.Position.z == (float)(gridHeight - 1)
				select cell2).ToArray();
			regenRimCells = false;
		}
		if (cellsToLandmass != null && DebugDrawLandmassCells)
		{
			for (int num = 0; num < cellsToLandmass.Length; num++)
			{
				Color color = colors[num % colors.Length];
				for (int num2 = 0; num2 < cellsToLandmass[num].Count; num2++)
				{
					Cell cell = cellsToLandmass[num].data[num2];
					DebugEx.DrawBoxXZ(cell.x, cell.x + 1, cell.z, cell.z + 1, 1f, color);
				}
			}
		}
		TerrainGen.inst.RenderTerrainColors();
		for (int num3 = 0; num3 < TreeSystem.systems.Count; num3++)
		{
			TreeSystem treeSystem = TreeSystem.systems[num3];
			if (treeSystem.type == 1 && treeSystem.chunks != null)
			{
				for (int num4 = 0; num4 < treeSystem.chunks.Length; num4++)
				{
					treeSystem.chunks[num4].mat?.SetTexture("_TerrainTex", TerrainGen.inst.terrainColorRenderTexture);
				}
				treeSystem.animMaterial.SetTexture("_TerrainTex", TerrainGen.inst.terrainColorRenderTexture);
			}
		}
		mountainMaterial.SetTexture("_TerrainTex", TerrainGen.inst.terrainColorRenderTexture);
		mountainMaterial.SetFloat("_WorldWidth", gridWidth);
		mountainMaterial.SetFloat("_WorldHeight", gridHeight);
		pather.Update();
		for (int num5 = 0; num5 < rebakeCells.Count; num5++)
		{
			BakeCell(rebakeCells[num5]);
			LegionSystem.Inst.UpdateObstructionForCell(rebakeCells[num5]);
		}
		if (rebakeCells.Count > 0)
		{
			pathGridId++;
			BakeWolfPathingCosts();
		}
		rebakeCells.Clear();
		threadedPather.WaitForThread();
		if (framesAfterGenerate < frameToWaitBeforeSeen)
		{
			framesAfterGenerate++;
		}
	}

	private void BakeWolfPathingCosts()
	{
		if (!(caveContainer != null))
		{
			return;
		}
		Transform transform = caveContainer.transform;
		for (int i = 0; i < transform.childCount; i++)
		{
			Transform child = transform.GetChild(i);
			if (!child.GetComponent<WolfDen>())
			{
				continue;
			}
			Cell cell = inst.GetCellData(child.transform.position);
			int num = Mathff.Clamp(cell.x - 1, 0, gridWidth - 1);
			int num2 = Mathff.Clamp(cell.x + 1, 0, gridWidth - 1);
			int num3 = Mathff.Clamp(cell.z - 1, 0, gridHeight - 1);
			int num4 = Mathff.Clamp(cell.z + 1, 0, gridHeight - 1);
			for (int j = num; j <= num2; j++)
			{
				for (int k = num3; k <= num4; k++)
				{
					pathCellData[k * gridWidth + j].wolfVikingFootPathPenalty = 25;
				}
			}
			int num5 = Mathff.Clamp(cell.x - WolfDen.territory, 0, gridWidth - 1);
			int num6 = Mathff.Clamp(cell.x + WolfDen.territory, 0, gridWidth - 1);
			int num7 = Mathff.Clamp(cell.z - WolfDen.territory, 0, gridHeight - 1);
			int num8 = Mathff.Clamp(cell.z + WolfDen.territory, 0, gridHeight - 1);
			for (int l = num5; l <= num6; l++)
			{
				for (int m = num7; m <= num8; m++)
				{
					pathCellData[m * gridWidth + l].wolfFootPathPenalty = 25;
				}
			}
		}
	}

	public void VerifyVillagerGrid()
	{
		if (villagerGrid == null)
		{
			return;
		}
		for (int i = 0; i < gridHeight; i++)
		{
			for (int j = 0; j < gridWidth; j++)
			{
				ArrayExtRef<Villager> villagersAt = GetVillagersAt(j, i);
				for (int k = 0; k < villagersAt.Count; k++)
				{
					if ((int)villagersAt.data[k].Pos.x != j || (int)villagersAt.data[k].Pos.z != i)
					{
						Debug.DrawLine(villagersAt.data[k].Pos, new Vector3((float)j + 0.5f, 0f, (float)i + 0.5f), Color.red, 1f);
						DebugEx.DrawSphere(new Vector3((float)j + 0.5f, 0f, (float)i + 0.5f), 0.25f, Color.red, 8f, 1f);
					}
				}
			}
		}
	}

	public void BakeCell(Cell c)
	{
		Cell.BakeSpeedModifierForCell(c);
		PathCell.BakePathingCostsForCell(c);
	}

	public void RebakeCellsForLandmass(int l)
	{
		ArrayExt<Cell> arrayExt = cellsToLandmass[l];
		for (int i = 0; i < arrayExt.Count; i++)
		{
			BakeCell(arrayExt.data[i]);
		}
	}

	public void SetupInitialPathCosts()
	{
		pathGridId = 0;
		int num = gridWidth * gridHeight;
		for (int i = 0; i < num; i++)
		{
			BakeCell(cellData[i]);
		}
		BakeWolfPathingCosts();
		if (LegionSystem.Inst != null)
		{
			LegionSystem.Inst.RebuildObstructionMap();
		}
	}

	public static bool IsLandRoad(Building b)
	{
		if ((bool)b)
		{
			if (b.uniqueNameHash != roadHash && b.uniqueNameHash != stoneRoadHash)
			{
				return b.uniqueNameHash == gardenHash;
			}
			return true;
		}
		return false;
	}

	public static bool IsTerrainEditableRoad(Building b)
	{
		if ((bool)b && b.IsBuilt())
		{
			if (b.uniqueNameHash != roadHash)
			{
				return b.uniqueNameHash == stoneRoadHash;
			}
			return true;
		}
		return false;
	}

	public static bool CellBlocksTerrainEdit(Cell c)
	{
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (!IsTerrainEditableRoad(c.OccupyingStructure[i]))
			{
				return true;
			}
		}
		return false;
	}

	public static void CheckForForumPlacement(Building b, ref PlacementValidationResult result)
	{
		if (result != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		bool isValid = true;
		bool isEntirelyForum = true;
		bool isOneForum = false;
		float currY = b.transform.position.y;
		bool isSingleCell = b.size.x * b.size.z == 1f;
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			bool flag = false;
			for (int i = 0; i < cell.OccupyingStructure.Count; i++)
			{
				Building building = cell.OccupyingStructure[i];
				bool flag2 = building.categoryHash == forumHash;
				flag |= flag2;
				if (!flag2)
				{
					isValid = false;
					break;
				}
				if (b.categoryHash == forumHash && b.uniqueNameHash == building.uniqueNameHash)
				{
					isValid = false;
					return;
				}
				if (!isSingleCell)
				{
					float num = currY - building.transform.position.y;
					Debug.Log(num);
					if (num < 0f || num >= 0.075f)
					{
						isValid = false;
					}
				}
			}
			if (flag)
			{
				isOneForum = true;
			}
			else
			{
				isEntirelyForum = false;
			}
		});
		if (isValid)
		{
			if (isOneForum && !isEntirelyForum)
			{
				result = PlacementValidationResult.MustBeOnOrOffForumEntirely;
			}
			else
			{
				result = PlacementValidationResult.Valid;
			}
		}
	}

	public PlacementValidationResult CanPlace(Building PendingObj, bool ignoreLandMassChecks = false, bool allowBuildOverForest = false, bool ai = false)
	{
		bool touchingCorrectLandMass = true;
		bool touchingUnclaimedLandMass = false;
		bool touchingOthersPlannedLand = false;
		bool atLeastOneCellTouchingFocusedIsland = false;
		bool moatUnderConstruction = false;
		PendingObj.ForEachTileInBounds((int x, int z, Cell cell2) =>
		{
			touchingCorrectLandMass &= Player.inst.FocusedLandMass == cell2.landMassIdx || cell2.landMassIdx == -1 || (Player.inst.FocusedLandMass == -1 && cell2.landMassIdx != -1);
			if (cell2.landMassIdx != -1)
			{
				touchingUnclaimedLandMass |= !Player.inst.PlayerLandmassOwner.OwnsLandMass(cell2.landMassIdx);
			}
			if (cell2.landMassIdx == Player.inst.FocusedLandMass && cell2.landMassIdx != -1)
			{
				atLeastOneCellTouchingFocusedIsland = true;
			}
			if (AIBrainsContainer.inst?.aiStartInfo?.startData != null)
			{
				for (int i = 0; i < AIBrainsContainer.inst.aiStartInfo.startData.Length; i++)
				{
					touchingOthersPlannedLand |= cell2.landMassIdx == AIBrainsContainer.inst.aiStartInfo.startData[i].landmass && cell2.landMassIdx != -1;
				}
			}
			Building topMostStructure = cell2.TopMostStructure;
			if (topMostStructure != null && topMostStructure.uniqueNameHash == moatHash && PendingObj.uniqueNameHash != pierHash)
			{
				moatUnderConstruction |= !topMostStructure.IsBuilt();
			}
		});
		if (!PendingObj.ignoreRoadCoverageForPlacement && !Creative.inst.IsCreativeOptionOn(8))
		{
			bool touchingTerritory = true;
			if (!ignoreLandMassChecks)
			{
				PendingObj.ForEachTileInBounds((int x, int z, Cell cell2) =>
				{
					touchingTerritory &= cell2.GetRoadCoverage() > 0;
				});
			}
			if (!touchingTerritory)
			{
				return PlacementValidationResult.OutsideOfTerritory;
			}
		}
		if (moatUnderConstruction)
		{
			return PlacementValidationResult.CannotBuildOnWater;
		}
		PlacementValidationResult validationResult = PlacementValidationResult.Valid;
		float angleLimit = PendingObj.GetCosMaxPlacementAngle();
		Vector3 up = Vector3.up;
		PendingObj.ForEachTileInBounds((int x, int z, Cell cell2) =>
		{
			if (validationResult == PlacementValidationResult.Valid && cell2.Type != TerrainType.None)
			{
				validationResult = PlacementValidationResult.MustBeOnFlatLand;
			}
			if (validationResult == PlacementValidationResult.Valid && DynamicWater.inst.IsWater(cell2.x, cell2.z))
			{
				validationResult = PlacementValidationResult.CannotBuildOnDynamicWater;
			}
			if (cell2.OccupyingStructure.Count > 0)
			{
				bool num2 = (bool)cell2.TopMostStructure && cell2.TopMostStructure.uniqueNameHash == rubbleHash;
				bool flag2 = (bool)cell2.BottomStructure && cell2.BottomStructure.uniqueNameHash == rubbleHash;
				bool flag3 = cell2.BottomStructure.uniqueNameHash == aqueductHash && cell2.OccupyingStructure.Count == 1 && PendingObj.allowOverAndUnderAqueducts;
				bool flag4 = cell2.StructureCompareUniqueNameAll(PendingObj.uniqueNameHash);
				if (!(num2 & flag2) && (!flag3 || flag4) && !IsLowerTierOnCell(PendingObj, cell2))
				{
					validationResult = PlacementValidationResult.ExistingStructure;
				}
			}
			if (cell2.OccupyingStructure.Count == 0 && PendingObj.uniqueNameHash == bathColdPoolHash && PendingObj.categoryHash != forumHash && IsTooSteep(angleLimit, cell2, up))
			{
				validationResult = PlacementValidationResult.GroundTooSteep;
			}
			if (EditTerrainProjectManager.inst.IsCellPartOfProject(cell2, out var _))
			{
				validationResult = PlacementValidationResult.TerrainProjectInSpace;
			}
		});
		if (!atLeastOneCellTouchingFocusedIsland)
		{
			touchingCorrectLandMass = false;
		}
		if (PendingObj.allowPlacementOnForum)
		{
			CheckForForumPlacement(PendingObj, ref validationResult);
		}
		PendingObj.PlacementValidaton?.Invoke(ref validationResult);
		if (PendingObj.snapBuildingTarget != "")
		{
			if (validationResult == PlacementValidationResult.ExistingStructure)
			{
				bool flag = false;
				Cell cell = GetCellData(PendingObj.transform.position);
				for (int num = 0; num < cell.OccupyingStructure.Count; num++)
				{
					if (PendingObj.CanSnapInside(cell.OccupyingStructure[num]))
					{
						flag = true;
						break;
					}
				}
				if (flag)
				{
					if (cell.OccupyingStructure.Count == 1)
					{
						validationResult = PlacementValidationResult.Valid;
					}
				}
				else
				{
					validationResult = PlacementValidationResult.ShopMustBeInApartment;
				}
			}
			else
			{
				validationResult = PlacementValidationResult.ShopMustBeInApartment;
			}
		}
		if (!ignoreLandMassChecks)
		{
			if (touchingUnclaimedLandMass && PendingObj.uniqueNameHash != romanOutpostHash && PendingObj.uniqueNameHash != romanOutpostHashNewIsland && PendingObj.uniqueNameHash != keepHash)
			{
				return PlacementValidationResult.BuildAnOutpostOnUnclaimedLand;
			}
			if (!touchingCorrectLandMass && validationResult == PlacementValidationResult.Valid)
			{
				return PlacementValidationResult.MustBeOnCorrectLandMass;
			}
		}
		return validationResult;
	}

	public bool IsTooSteep(float cosAngleLimit, Cell cell, Vector3 up)
	{
		Vector3 center3D = cell.Center3D;
		Vector3 normal = TerrainGen.inst.GetNormal(center3D.x, center3D.z);
		for (int i = 0; i < offsets.Length; i++)
		{
			normal += TerrainGen.inst.GetNormal(center3D.x + offsets[i].x * 0.25f, center3D.z + offsets[i].z * 0.5f);
		}
		normal /= 5f;
		if (Vector3.Dot(normal, up) < cosAngleLimit)
		{
			return true;
		}
		return false;
	}

	public ArrayExtRef<Villager> GetVillagersAt(int x, int z)
	{
		return villagerGrid[z * GridWidth + x].villagers;
	}

	public bool DemolishBuildingByAI(Building building)
	{
		if (building != null && building.CanDemolishBuilding())
		{
			EffectsMan.inst.BuildPuff.CreateAndPlay(building.Center());
			DemolishBuilding(building);
			TryClearRelatedRubbles(building);
			return true;
		}
		return false;
	}

	public void MovePeopleInsideToGround(Building building)
	{
		peopleInBuilding.Clear();
		building.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				ArrayExtRef<Villager> villagersAt = GetVillagersAt(j, i);
				peopleInBuilding.AddRange(villagersAt);
			}
		}
		maxX++;
		maxZ++;
		for (int k = 0; k < peopleInBuilding.Count; k++)
		{
			Villager villager = peopleInBuilding.data[k];
			Vector3 pos = villager.Pos;
			if (pos.x >= (float)minX && pos.x <= (float)maxX && pos.z >= (float)minZ && pos.z <= (float)maxZ)
			{
				villager.TeleportTo(pos);
			}
		}
		peopleInBuilding.Clear();
	}

	public ResourceAmount GetDemolishCollectionAmount(ref ResourceAmount amt, ISelectableBuilding sBuilding)
	{
		if (amt == null)
		{
			amt = new ResourceAmount();
		}
		else
		{
			amt.Clear();
		}
		Building building = sBuilding as Building;
		if (building != null)
		{
			if (building.IsBuilt())
			{
				amt.Add(building.GetCost(building.LandMass()) * 0.5f);
				amt.Set(4, 0);
			}
			else
			{
				amt.Add(building.ConstructionForeman.GetCollectedResources());
			}
		}
		else if (sBuilding is AqueductLine aqueductLine)
		{
			aqueductLine.CalculateRefundAmounts();
			for (int i = 0; i < aqueductLine.refundStoneAmounts.Length; i++)
			{
				amt.Add(2, aqueductLine.refundStoneAmounts[i]);
			}
		}
		else if (sBuilding is DamPlanningProject damPlanningProject)
		{
			for (int j = 0; j < damPlanningProject.damsToAdd.Count; j++)
			{
				Building building2 = DamPlannerUI.FindBuilding(damPlanningProject.damsToAdd[j]);
				if (building2.ConstructionForeman.ConstructionProgress > 0f)
				{
					amt.Add(building2.ConstructionForeman.GetCollectedResources());
				}
			}
		}
		return amt;
	}

	public void DemolishBuildingByPlayer(Building building, bool doEffects = true)
	{
		if (building == null || !building.CanDemolishBuilding() || building.isDemolishing)
		{
			return;
		}
		TryClearRelatedRubbles(building);
		if (building.uniqueNameHash == rubbleHash)
		{
			return;
		}
		float num = 0.5f;
		if (building.uniqueNameHash == dockHash || !building.IsBuilt())
		{
			num = 1f;
		}
		DemolishPending demolishPending = new DemolishPending
		{
			building = building,
			doEffects = doEffects,
			refundAmt = (building.IsBuilt() ? building.GetCost(building.LandMass()) : building.ConstructionForeman.GetCollectedResources()) * num
		};
		_ = building.jobs;
		_ = building.attractionJobs;
		Home component = building.GetComponent<Home>();
		if (component != null)
		{
			List<Villager> residents = component.GetResidents();
			component.MaxResidents = 0;
			for (int i = 0; i < residents.Count; i++)
			{
				residents[i].Residence = null;
				Player.inst.Homeless.Add(residents[i]);
			}
			residents.Clear();
		}
		bool flag = false;
		for (int j = 0; j < buildingsToDemolish.Count; j++)
		{
			if (!(buildingsToDemolish[j].building != demolishPending.building))
			{
				Debug.LogError(demolishPending.building.UniqueName + " to be demolished attempted to be added multiple times!");
				flag = true;
				break;
			}
		}
		if (!flag)
		{
			if (building.categoryHash == castleblockHash)
			{
				DemolishBuilding(building);
			}
			else
			{
				DemolishBuildingByPlayer_Impl(demolishPending.building, demolishPending.refundAmt, demolishPending.doEffects);
			}
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_build_damblock_complete", building.Center());
		}
		if (doEffects)
		{
			demolishPending.building.ForEachTileInBounds((int x, int z, Cell cell) =>
			{
				EffectsMan.inst.DemolishEffectPuff.CreateAndPlay(cell.Center3D);
			});
		}
		if (GameUI.inst.GetBuildingSelected() == building)
		{
			GameUI.inst.ClearCellSelected();
		}
	}

	public void DemolishBuildingByPlayer_Impl(Building building, ResourceAmount refund, bool doEffects = true)
	{
		if (building == null || !building.CanDemolishBuilding())
		{
			return;
		}
		Cell cell = building.GetCell();
		TryClearRelatedRubbles(building);
		if (building.uniqueNameHash != rubbleHash)
		{
			if (building.CanCollectResources())
			{
				ReclaimResources(building, refund);
			}
			building.SendMessage("OnDemolished", SendMessageOptions.DontRequireReceiver);
			BuildingCollapseManager.inst.Collapse(building);
			if (building.CategoryName == castleblockName)
			{
				BlockBuilding.MarkBlockStackDirty(cell);
			}
		}
	}

	public void DemolishSelectedBuildingByPlayer()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		if (buildingSelected != null && buildingSelected.TeamID() == 0)
		{
			if (buildingSelected.uniqueNameHash == stoneBridgeHash || buildingSelected.uniqueNameHash == woodBridgeHash)
			{
				Bridge component = buildingSelected.GetComponent<Bridge>();
				for (int i = 0; i < component.bridgePath.Count; i++)
				{
					Building building = GetCellData(component.bridgePath.data[i]).StructureFind(buildingSelected.uniqueNameHash);
					if (building != null)
					{
						DemolishBuildingByPlayer(building);
					}
				}
			}
			else
			{
				DemolishBuildingByPlayer(GameUI.inst.GetBuildingSelected());
			}
		}
		else
		{
			ISelectableBuilding genericBuildingSelected = GameUI.inst.GetGenericBuildingSelected();
			if (genericBuildingSelected != null && genericBuildingSelected.TeamID() == 0)
			{
				genericBuildingSelected.DemolishBuilding();
			}
		}
	}

	public void TryClearRelatedRubbles(Building building)
	{
		if (building.uniqueNameHash == rubbleHash)
		{
			BuildingCollapseManager.ClearRubble(building.GetCell());
		}
	}

	public void DemolishBuilding(Building b, bool reclaimResources = true)
	{
		if (!b)
		{
			return;
		}
		if (b.IsBuilt() & reclaimResources)
		{
			if (b.CanCollectResources())
			{
				inst.ReclaimResources(b, b.ConstructionForeman.GetCollectedResources() * 0.5f);
				GetLandmassOwner(b.LandMass()).Gold += (int)((float)b.GetCost(b.LandMass()).Get(4) * 0.5f);
			}
		}
		else if (((b.UniqueName != "destructioncrew") & reclaimResources) && b.CanCollectResources())
		{
			inst.ReclaimResources(b, b.ConstructionForeman.GetCollectedResources());
			GetLandmassOwner(b.LandMass()).Gold += b.GetCost(b.LandMass()).Get(4);
		}
		b.SendMessage("OnDemolished", SendMessageOptions.DontRequireReceiver);
		inst.Unplace(b);
	}

	public void VanishBuilding(Building b)
	{
		Unplace(b);
	}

	public Cell Unplace(Building building)
	{
		Cell cell = building.GetCell();
		if (cell == null)
		{
			return null;
		}
		Cell cellSelected = GameUI.inst.GetCellSelected();
		if (cellSelected != null && cell != null && cellSelected == cell)
		{
			TerrainGen.inst.ClearOverlay(updateToo: true);
			GameUI.inst.ClearCellSelected();
		}
		if (cell.SubStructure.Contains(building))
		{
			int index = cell.SubStructure.IndexOf(building);
			Building building2 = cell.SubStructure[index];
			PlaceInternal(cell.SubStructure[index], undo: true, fromLoad: false, byAi: false);
			UnityEngine.Object.Destroy(building2.gameObject);
			return cell;
		}
		if (cell.OccupyingStructure.Contains(building))
		{
			int index2 = cell.OccupyingStructure.IndexOf(building);
			Building building3 = cell.OccupyingStructure[index2];
			PlaceInternal(cell.OccupyingStructure[index2], undo: true, fromLoad: false, byAi: false);
			UnityEngine.Object.Destroy(building3.gameObject);
			return cell;
		}
		return null;
	}

	public Cell Place(Building PendingObj)
	{
		return PlaceInternal(PendingObj, undo: false, fromLoad: false, byAi: false);
	}

	public Cell PlaceByAI(Building PendingObj)
	{
		return PlaceInternal(PendingObj, undo: false, fromLoad: false, byAi: true);
	}

	public Cell PlaceFromLoad(Building PendingObj)
	{
		return PlaceInternal(PendingObj, undo: false, fromLoad: true, byAi: false);
	}

	private Cell PlaceInternal(Building PendingObj, bool undo, bool fromLoad, bool byAi)
	{
		if (!undo && !byAi)
		{
			timeLastPlaced = Time.time;
		}
		Vector3 position = PendingObj.transform.position;
		int num = (int)position.x;
		int num2 = (int)position.z;
		_ = PendingObj.uniqueNameHash;
		if (!undo)
		{
			PendingObj.RefreshCachedValues();
		}
		if (!fromLoad)
		{
			if (undo)
			{
				Player.inst.RemoveBuilding(PendingObj);
			}
			else
			{
				Player.inst.AddBuilding(PendingObj);
			}
		}
		PendingObj.ForEachTileInBounds((int x, int z, Cell cell4) =>
		{
			DoPlacementOnCell(PendingObj, cell4, undo);
		});
		if (!GetCellData(num, num2).buildingAccess)
		{
			List<Cell> list = new List<Cell>();
			list.Add(GetCellData(num, num2));
			while (list.Count > 0)
			{
				Cell cell = list[list.Count - 1];
				list.RemoveAt(list.Count - 1);
				cell.buildingAccess = true;
				Cell cell2 = GetCellData(cell.x, cell.z + 1);
				if (cell2 != null && !cell2.buildingAccess && cell2.Type != TerrainType.Water)
				{
					list.Add(cell2);
				}
				cell2 = GetCellData(cell.x, cell.z - 1);
				if (cell2 != null && !cell2.buildingAccess && cell2.Type != TerrainType.Water)
				{
					list.Add(cell2);
				}
				cell2 = GetCellData(cell.x + 1, cell.z);
				if (cell2 != null && !cell2.buildingAccess && cell2.Type != TerrainType.Water)
				{
					list.Add(cell2);
				}
				cell2 = GetCellData(cell.x - 1, cell.z);
				if (cell2 != null && !cell2.buildingAccess && cell2.Type != TerrainType.Water)
				{
					list.Add(cell2);
				}
			}
		}
		if (!undo)
		{
			PendingObj.transform.parent = Player.inst.buildingContainer.transform;
			PendingObj.OnPlacement(byAi);
			if (!fromLoad && !byAi && PendingObj.uniqueNameHash != rubbleHash)
			{
				Cam.inst.Shake(new Vector3(0f, -1f * Mathf.Max(2f, PendingObj.size.x * PendingObj.size.x * 0.75f), 0f));
			}
		}
		else
		{
			if (!IsTerrainEditableRoad(PendingObj) && editTerrainProjectManager.IsCellPartOfProject(PendingObj.cachedCell, out var project))
			{
				project.Cancel();
			}
			if (PendingObj.uniqueNameHash == damHash && PendingObj.cachedCell.OccupyingStructure.Count == 1)
			{
				Building building = PendingObj.cachedCell.StructureFind(spilloverHash);
				if (building != null)
				{
					VanishBuilding(building);
				}
			}
		}
		PendingObj.BroadcastMessage("OnBuildingPlacement", undo, SendMessageOptions.DontRequireReceiver);
		PendingObj.SetVisibleForFog(PendingObj.IsVisibleForFog());
		if (!fromLoad)
		{
			PendingObj.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
			for (int num3 = minZ; num3 <= maxZ; num3++)
			{
				for (int num4 = minX; num4 <= maxX; num4++)
				{
					Cell cellDataClamped = GetCellDataClamped(num4, num3);
					BakeCell(cellDataClamped);
					LegionSystem.Inst.UpdateObstructionForCell(cellDataClamped);
				}
			}
			pathGridId++;
			Broadcast.BuildingAddRemove.Broadcast(PendingObj, new OnBuildingAddRemove
			{
				added = !undo,
				targetBuilding = PendingObj
			});
			for (int num5 = minZ - 1; num5 <= maxZ + 1; num5++)
			{
				for (int num6 = minX - 1; num6 <= maxX + 1; num6++)
				{
					if (num5 == minZ - 1 || num5 == maxZ + 1 || num6 == minX - 1 || num6 == maxX + 1)
					{
						Cell cell3 = GetCellData(num6, num5);
						for (int num7 = 0; num7 < cell3.OccupyingStructure.Count; num7++)
						{
							cell3.OccupyingStructure[num7].BroadcastMessage("OnAdjacentAddRemovedBuilding", undo, SendMessageOptions.DontRequireReceiver);
						}
					}
				}
			}
			if (!undo)
			{
				_ = PendingObj.UniqueName == "temple";
			}
		}
		if (!undo && !byAi && !fromLoad)
		{
			PendingObj.SendMessage("OnPlayerPlacement", SendMessageOptions.DontRequireReceiver);
			inFirstPlacementPhase = false;
		}
		if (!undo && !fromLoad && Creative.inst.IsCreativeOptionOn(11))
		{
			PendingObj.ForceCompleteBuild();
		}
		return GetCellData(new Vector3(num, 0f, num2));
	}

	public void DoPlacementOnCell(Building PendingObj, Cell cell, bool undo)
	{
		if ((bool)cell.TopMostStructure && cell.TopMostStructure.uniqueNameHash == rubbleHash && !undo)
		{
			Building topMostStructure = cell.TopMostStructure;
			DemolishBuilding(topMostStructure);
			TryClearRelatedRubbles(topMostStructure);
		}
		if (cell.OccupyingStructure.Count == 0 && !LoadSave.Loading && PendingObj.categoryHash != pathHash && !skipGrassClearing)
		{
			TerrainGen.inst.SetTempEffectTile(cell, 1, 250f);
		}
		if (undo)
		{
			cell.SubStructure.Remove(PendingObj);
			cell.OccupyingStructure.Remove(PendingObj);
			if (cell.OccupyingStructure.Count == 0 && !skipGrassClearing)
			{
				TerrainGen.inst.ResetGrassTile(cell, 30f);
				if (!LoadSave.Loading && PendingObj.categoryHash != pathHash)
				{
					TerrainGen.inst.SetTempEffectTile(cell, 1, 250f);
				}
			}
			else if (!skipGrassClearing)
			{
				TerrainGen.inst.ClearGrassTile(cell);
			}
			return;
		}
		if (PendingObj.SubStructure)
		{
			cell.SubStructure.Add(PendingObj);
		}
		else if ((PendingObj.CategoryName == "farm" || PendingObj.UniqueName == "road" || PendingObj.UniqueName == "stoneroad" || PendingObj.UniqueName == "garden" || PendingObj.UniqueName == "well") && (cell.StructureCompareUniqueNameAll(aqueductHash) || cell.StructureCompareCategoryNameAll(gateHash) || cell.StructureCompareUniqueNameAll(castlestairsHash)))
		{
			if (IsLandRoad(PendingObj) && IsLandRoad(cell.BottomStructure))
			{
				inst.Unplace(cell.BottomStructure);
			}
			cell.OccupyingStructure.Insert(0, PendingObj);
		}
		else if (PendingObj.UniqueName == "smallhouse" && cell.StructureCompareUniqueNameAll(aqueductHash))
		{
			cell.OccupyingStructure.Insert(0, PendingObj);
		}
		else if (PendingObj.categoryHash == stockpileHash || PendingObj.categoryHash == granaryCategoryHash)
		{
			if (!LoadSave.Loading)
			{
				LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(PendingObj);
				Stockpile component = PendingObj.GetComponent<Stockpile>();
				for (int i = 0; i < cell.OccupyingStructure.Count; i++)
				{
					Building building = cell.OccupyingStructure[i];
					if (building.categoryHash != stockpileHash && building.categoryHash != granaryCategoryHash)
					{
						continue;
					}
					Stockpile component2 = building.GetComponent<Stockpile>();
					LogisticsManager.LogisticsForStorage logisticsForBuilding2 = LogisticsManager.inst.GetLogisticsForBuilding(building);
					foreach (KeyValuePair<Guid, LogisticsManager.LogisticsForStorage> logistic in LogisticsManager.inst.logistics)
					{
						for (int j = 0; j < logistic.Value.sourceBuildings.Count; j++)
						{
							if (logistic.Value.sourceBuildings[j].guid == building.guid)
							{
								logistic.Value.sourceBuildings[j] = PendingObj;
							}
						}
					}
					for (int k = 0; k < logisticsForBuilding2.sourceBuildings.Count; k++)
					{
						if (!logisticsForBuilding.sourceBuildings.Contains(logisticsForBuilding2.sourceBuildings[k]))
						{
							logisticsForBuilding.sourceBuildings.Add(logisticsForBuilding2.sourceBuildings[k]);
						}
					}
					for (int l = 0; l < LogisticsManager.vehicles.Count; l++)
					{
						LogisticsVehicle logisticsVehicle = LogisticsManager.vehicles[l];
						for (int m = 0; m < logisticsVehicle.routes.Count; m++)
						{
							LogisticRoute logisticRoute = logisticsVehicle.routes[m];
							if (logisticRoute.targetBuilding == building)
							{
								logisticsVehicle.TryRemoveRoute(building, logisticRoute.sourceBuilding);
								logisticsVehicle.TryAddRoute(PendingObj, logisticRoute.sourceBuilding);
							}
							else if (logisticRoute.sourceBuilding == building)
							{
								logisticsVehicle.TryRemoveRoute(logisticRoute.targetBuilding, building);
								logisticsVehicle.TryAddRoute(logisticRoute.targetBuilding, PendingObj);
							}
						}
					}
					ResourceAmount amt = new ResourceAmount();
					for (int n = 0; n < FreeResourceSystem.inst.resourceDefs.Count; n++)
					{
						FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[n];
						int num = component2.StoredPublicResources(resourceDef.ID);
						if (num > 0)
						{
							amt.Set(resourceDef.ID, num);
							component.Deposit(ref amt);
							int num2 = amt.Get(resourceDef.ID);
							amt.Set(resourceDef.ID, num - num2);
							((IResourceStorage)component2).RemoveResources(amt);
						}
					}
				}
				for (int num3 = 0; num3 < cell.OccupyingStructure.Count; num3++)
				{
					inst.Unplace(cell.OccupyingStructure[num3]);
				}
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if ((PendingObj.UniqueName == stoneRoadName || PendingObj.UniqueName == gardenName) && IsLandRoad(cell.BottomStructure))
		{
			inst.Unplace(cell.BottomStructure);
			cell.OccupyingStructure.Insert(0, PendingObj);
		}
		else if (PendingObj.uniqueNameHash == stoneBridgeHash || PendingObj.uniqueNameHash == woodBridgeHash)
		{
			if (!LoadSave.Loading)
			{
				if (!PendingObj.GetComponent<Bridge>().isEndPiece && IsLandRoad(cell.BottomStructure))
				{
					Unplace(cell.BottomStructure);
				}
				if (cell.BottomStructure != null && cell.BottomStructure.uniqueNameHash == woodBridgeHash)
				{
					Bridge component3 = cell.BottomStructure.GetComponent<Bridge>();
					for (int num4 = 0; num4 < component3.bridgePath.Count; num4++)
					{
						Building building2 = GetCellData(component3.bridgePath.data[num4]).StructureFind(woodBridgeHash);
						if (building2 != null)
						{
							Unplace(building2);
						}
					}
				}
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (PendingObj.uniqueNameHash == cemeteryKeeperHash)
		{
			if ((bool)cell.BottomStructure)
			{
				inst.Unplace(cell.BottomStructure);
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (PendingObj.UniqueName == "aqueduct" && cell.BottomStructureIsCategory(castleblockHash))
		{
			cell.OccupyingStructure.Insert(0, PendingObj);
		}
		else if (PendingObj.uniqueNameHash == damHash && cell.TopStructureIs(spilloverHash))
		{
			cell.OccupyingStructure.Insert(cell.OccupyingStructure.Count - 1, PendingObj);
			cell.TopStructure.GetComponent<Spillover>().updateNeeded = true;
		}
		else if (cell.BottomStructureIs(aqueductHash) && cell.TopStructureIs(woodcastleblockHash) && PendingObj.uniqueNameHash == castleblockHash)
		{
			for (int num5 = cell.OccupyingStructure.Count - 1; num5 >= 0; num5--)
			{
				if (cell.OccupyingStructure[num5].uniqueNameHash == woodcastleblockHash)
				{
					inst.DemolishBuilding(cell.OccupyingStructure[num5]);
				}
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (cell.TopStructureCategoryIs(projectileTopperHash) && PendingObj.CategoryName == castleblockName)
		{
			Building item = cell.OccupyingStructure[cell.OccupyingStructure.Count - 1];
			cell.OccupyingStructure.Remove(item);
			if (cell.StructureCompareUniqueNameAll(woodcastleblockHash) && PendingObj.uniqueNameHash == castleblockHash)
			{
				for (int num6 = cell.OccupyingStructure.Count - 1; num6 >= 0; num6--)
				{
					if (cell.OccupyingStructure[num6].categoryHash == castleblockHash)
					{
						DemolishBuilding(cell.OccupyingStructure[num6]);
					}
				}
			}
			cell.OccupyingStructure.Add(PendingObj);
			cell.OccupyingStructure.Add(item);
		}
		else if (PendingObj.uniqueNameHash == castleblockHash && cell.StructureCompareUniqueNameAll(woodcastleblockHash))
		{
			for (int num7 = cell.OccupyingStructure.Count - 1; num7 >= 0; num7--)
			{
				if (cell.OccupyingStructure[num7].categoryHash == castleblockHash)
				{
					inst.DemolishBuilding(cell.OccupyingStructure[num7]);
				}
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (PendingObj.uniqueNameHash == gateHash && cell.StructureCompareUniqueNameAll(woodengateHash))
		{
			inst.DemolishBuilding(cell.StructureFind(woodengateHash));
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (PendingObj.categoryHash == gateHash)
		{
			for (int num8 = 0; num8 < cell.OccupyingStructure.Count; num8++)
			{
				Building building3 = cell.OccupyingStructure[num8];
				if (building3.categoryHash != pathHash)
				{
					inst.DemolishBuilding(building3);
				}
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (PendingObj.uniqueNameHash != smallHouseHash && PendingObj.categoryHash == houseCategoryHash)
		{
			Building bottomStructure = cell.BottomStructure;
			if (bottomStructure != null && bottomStructure.uniqueNameHash == smallHouseHash)
			{
				inst.DemolishBuilding(cell.BottomStructure);
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (PendingObj.categoryHash == forumHash)
		{
			for (int num9 = 0; num9 < cell.OccupyingStructure.Count; num9++)
			{
				if (cell.OccupyingStructure[num9].categoryHash == forumHash)
				{
					DemolishBuilding(cell.OccupyingStructure[num9], reclaimResources: false);
					break;
				}
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (PendingObj.categoryHash == templeHash)
		{
			for (int num10 = 0; num10 < cell.OccupyingStructure.Count; num10++)
			{
				if (cell.OccupyingStructure[num10].categoryHash != forumHash)
				{
					DemolishBuilding(cell.OccupyingStructure[num10], reclaimResources: false);
				}
			}
			cell.OccupyingStructure.Add(PendingObj);
		}
		else if (IsLowerTierOnCell(PendingObj, cell))
		{
			DemolishBuilding(cell.BottomStructure);
			cell.OccupyingStructure.Add(PendingObj);
		}
		else
		{
			cell.OccupyingStructure.Add(PendingObj);
		}
		if (!skipGrassClearing)
		{
			TerrainGen.inst.ClearGrassTile(cell);
		}
	}

	public void ReclaimResources(Building b, ResourceAmount collected)
	{
		for (int i = 0; i < collected.resources.Count; i++)
		{
			int rAmt = collected.resources[i].Amount;
			if (rAmt <= 0)
			{
				continue;
			}
			int rID = collected.resources[i].resourceID;
			if (rID == 4)
			{
				LandmassOwner landmassOwner = GetLandmassOwner(b.LandMass());
				if (landmassOwner != null && !b.IsBuilt())
				{
					landmassOwner.Gold += rAmt;
				}
				continue;
			}
			int amt = Mathf.CeilToInt((float)rAmt / (b.size.x * b.size.z));
			b.ForEachTileInBounds((int x, int z, Cell c) =>
			{
				int num = Mathff.Min(amt, rAmt);
				if (num > 0)
				{
					FreeResourceManager.inst.AddOrMakeAutoStackFor(rID, num, c.Center3D);
					rAmt -= num;
				}
			});
		}
	}

	public void ForEachTileInRadius(int sx, int sz, int radius, EvaluateCell Func)
	{
		int num = radius * radius;
		int num2 = Mathf.Max(sx - radius, 0);
		int num3 = Mathf.Max(sz - radius, 0);
		int num4 = Mathf.Min(sx + radius, gridWidth - 1);
		int num5 = Mathf.Min(sz + radius, gridHeight - 1);
		for (int i = num2; i <= num4; i++)
		{
			for (int j = num3; j <= num5; j++)
			{
				Cell cell = GetCellData(i, j);
				if (cell != null && (i - sx) * (i - sx) + (j - sz) * (j - sz) <= num)
				{
					Func(i, j, cell);
				}
			}
		}
	}

	public void ForEachTileInRadiusOrDone(int sx, int sz, int radius, EvaluateIsValidCell Func)
	{
		int num = radius * radius;
		int num2 = Mathf.Max(sx - radius, 0);
		int num3 = Mathf.Max(sz - radius, 0);
		int num4 = Mathf.Min(sx + radius, gridWidth - 1);
		int num5 = Mathf.Min(sz + radius, gridHeight - 1);
		for (int i = num2; i <= num4; i++)
		{
			for (int j = num3; j <= num5; j++)
			{
				Cell cell = GetCellData(i, j);
				if (cell != null && (i - sx) * (i - sx) + (j - sz) * (j - sz) <= num && Func(i, j, cell))
				{
					return;
				}
			}
		}
	}

	public bool ReclassifyLandWaterFromHeights(int minX, int minZ, int maxX, int maxZ)
	{
		minX = Mathf.Clamp(minX, 0, gridWidth - 1);
		maxX = Mathf.Clamp(maxX, 0, gridWidth - 1);
		minZ = Mathf.Clamp(minZ, 0, gridHeight - 1);
		maxZ = Mathf.Clamp(maxZ, 0, gridHeight - 1);
		bool result = false;
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				Cell cell = cellData[j + i * gridWidth];
				if (cell.Type == TerrainType.EmptyCave)
				{
					continue;
				}
				float groundHeight = TerrainGen.inst.GetGroundHeight((float)j + 0.5f, (float)i + 0.5f);
				TerrainResource terrainResource = cell.terrainResource;
				if (terrainResource != null && groundHeight < TerrainGen.waterHeightTestThresold)
				{
					if (SculptCasualtyLog.armed)
					{
						SculptCasualtyLog.deposits.Add(new SculptCasualtyLog.DrownedDeposit
						{
							x = terrainResource.x,
							z = terrainResource.z,
							sizeX = terrainResource.sizeX,
							sizeZ = terrainResource.sizeZ,
							resourceID = terrainResource.resourceID
						});
					}
					for (int k = 0; k < terrainResource.sizeX; k++)
					{
						for (int l = 0; l < terrainResource.sizeZ; l++)
						{
							Cell cell2 = GetCellData(terrainResource.x + k, terrainResource.z + l);
							if (cell2 != null && cell2.Type == TerrainType.Obstruction)
							{
								cell2.Type = TerrainType.None;
							}
						}
					}
					TerrainResource.Remove(terrainResource);
					result = true;
				}
				if (cell.Type == TerrainType.Obstruction)
				{
					if (groundHeight < TerrainGen.waterHeightTestThresold)
					{
						cell.landMassIdx = -1;
					}
					continue;
				}
				if (cell.Type != TerrainType.Water && groundHeight < TerrainGen.waterHeightTestThresold)
				{
					treeSystem.DeleteTreesAt(cell);
					rockScatterSystem.DeleteTreesAt(cell);
					TerrainGen.inst.SetWaterTile(j, i, modifyHeight: false);
					cell.deepWater = false;
				}
				else if (cell.Type != TerrainType.None && groundHeight > TerrainGen.waterHeightTestThresold)
				{
					cell.Type = TerrainType.None;
					cell.deepWater = false;
					cell.partOfOcean = false;
					FishSystem.inst.ForceClearFish(j, i);
				}
				if (cell.Type == TerrainType.Water)
				{
					cell.landMassIdx = -1;
				}
				cell.StorePostGenerationType();
			}
		}
		TerrainGen.inst.UpdateTextures();
		return result;
	}

	public void SinkOrphanVerts(int minVX, int minVZ, int maxVX, int maxVZ)
	{
		minVX = Mathf.Max(0, minVX);
		minVZ = Mathf.Max(0, minVZ);
		maxVX = Mathf.Min(MeshWidth - 1, maxVX);
		maxVZ = Mathf.Min(MeshHeight - 1, maxVZ);
		for (int i = minVZ; i <= maxVZ; i++)
		{
			for (int j = minVX; j <= maxVX; j++)
			{
				if (!(TerrainGen.inst.GetVertY(j, i) <= TerrainGen.waterHeightTestThresold) && !VertTouchesLand(j, i))
				{
					TerrainGen.inst.SetVert(j, i, TerrainGen.waterHeightShallow, bakeDown: true);
				}
			}
		}
	}

	private bool VertTouchesLand(int vx, int vz)
	{
		for (int i = (vz - 1) / 2; i <= vz / 2; i++)
		{
			for (int j = (vx - 1) / 2; j <= vx / 2; j++)
			{
				Cell cell = GetCellData(j, i);
				if (cell != null && cell.Type != TerrainType.Water && cell.landMassIdx != -1)
				{
					return true;
				}
			}
		}
		return false;
	}

	private bool VertTouchesOtherTerrain(int vx, int vz, int landMassIdx)
	{
		for (int i = (vz - 1) / 2; i <= vz / 2; i++)
		{
			for (int j = (vx - 1) / 2; j <= vx / 2; j++)
			{
				Cell cell = GetCellData(j, i);
				if (cell != null && (cell.Type == TerrainType.Water || cell.landMassIdx != landMassIdx))
				{
					return true;
				}
			}
		}
		return false;
	}

	public void ClearRocksDuringEdit(Cell c)
	{
		GameObject caveAt = inst.GetCaveAt(c);
		if (caveAt != null)
		{
			UnityEngine.Object.Destroy(caveAt);
		}
		if (c.terrainResource != null)
		{
			TerrainResource.Remove(c.terrainResource);
		}
	}

	public bool TileTouchingRadius(Cell cell, Vector3 s, float radius)
	{
		return TileTouchingRadius(cell.x, cell.z, s, radius);
	}

	public bool TileTouchingRadius(int x, int z, Vector3 s, float radius)
	{
		float num = radius * radius;
		int i = 0;
		for (int num2 = cellBoundOffsets.Length; i < num2; i++)
		{
			Vector3 vector = cellBoundOffsets[i];
			float num3 = (float)x + 0.5f + vector.x;
			float num4 = (float)z + 0.5f + vector.z;
			if ((num3 - s.x) * (num3 - s.x) + (num4 - s.z) * (num4 - s.z) <= num)
			{
				return true;
			}
		}
		return false;
	}

	public EmptyCave AddEmptyCave(int x, int z)
	{
		Cell cell = inst.GetCellData(x, z);
		cell.Type = TerrainType.EmptyCave;
		cell.StorePostGenerationType();
		GameObject gameObject = UnityEngine.Object.Instantiate(inst.emptyCavePrefab);
		gameObject.transform.position = new Vector3(cell.Position.x, TerrainGen.inst.GetTileHeight(cell), cell.Position.z);
		gameObject.transform.SetParent(inst.caveContainer.transform, worldPositionStays: true);
		return gameObject.GetComponent<EmptyCave>();
	}

	public WolfDen AddWolfDen(int x, int z)
	{
		Cell cell = inst.GetCellData(x, z);
		cell.Type = TerrainType.WolfDen;
		cell.StorePostGenerationType();
		GameObject gameObject = UnityEngine.Object.Instantiate(inst.wolfDenPrefab);
		gameObject.transform.position = new Vector3(cell.Position.x, TerrainGen.inst.GetTileHeight(cell), cell.Position.z);
		gameObject.transform.SetParent(inst.caveContainer.transform, worldPositionStays: true);
		return gameObject.GetComponent<WolfDen>();
	}

	public GameObject GetCaveAt(Cell cell)
	{
		for (int i = 0; i < caveContainer.transform.childCount; i++)
		{
			Vector3 position = caveContainer.transform.GetChild(i).position;
			int num = (int)position.x;
			int num2 = (int)position.z;
			if (cell.x == num && cell.z == num2)
			{
				return caveContainer.transform.GetChild(i).gameObject;
			}
		}
		return null;
	}

	public void ForEachTileTouchingRadiusInBounds(int minX, int maxX, int minZ, int maxZ, float radius, EvaluateBoundsCell Func)
	{
		int num = minX;
		int num2 = maxX;
		int num3 = minZ;
		int num4 = maxZ;
		int num5 = 0;
		Vector3[] array = new Vector3[(1 + maxX - minX) * (1 + maxZ - minZ)];
		for (int i = minX; i <= maxX; i++)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				array[num5++] = new Vector3((float)i + 0.5f, 0f, (float)j + 0.5f);
				int num6 = (int)Mathf.Max(Mathf.Floor((float)i + 0.5f - radius), 0f);
				int num7 = (int)Mathf.Max(Mathf.Floor((float)j + 0.5f - radius), 0f);
				int num8 = (int)Mathf.Min(Mathf.Ceil((float)i + 0.5f + radius), gridWidth - 1);
				int num9 = (int)Mathf.Min(Mathf.Ceil((float)j + 0.5f + radius), gridHeight - 1);
				if (num6 < num)
				{
					num = num6;
				}
				if (num8 > num2)
				{
					num2 = num8;
				}
				if (num7 < num3)
				{
					num3 = num7;
				}
				if (num9 > num4)
				{
					num4 = num9;
				}
			}
		}
		for (int k = num; k <= num2; k++)
		{
			for (int l = num3; l <= num4; l++)
			{
				Cell cell = GetCellData(k, l);
				Vector3 b = new Vector3((float)k + 0.5f, 0f, (float)l + 0.5f);
				bool flag = false;
				Vector3 originPos = Vector3.zero;
				float num10 = float.MaxValue;
				for (int m = 0; m < array.Length; m++)
				{
					_ = ref array[m];
					if (cell != null && TileTouchingRadius(cell, array[m], radius))
					{
						flag = true;
						float num11 = Mathff.DistSqrdXZ(array[m], b);
						if (num11 < num10)
						{
							num10 = num11;
							originPos = array[m];
						}
					}
				}
				if (flag)
				{
					Func(originPos, k, l, cell);
				}
			}
		}
	}

	public void ForEachTileTouchingRadius(Vector3 s, float radius, EvaluateCell Func)
	{
		int num = (int)Mathf.Max(Mathf.Floor(s.x - radius), 0f);
		int num2 = (int)Mathf.Max(Mathf.Floor(s.z - radius), 0f);
		int num3 = (int)Mathf.Min(Mathf.Ceil(s.x + radius), gridWidth - 1);
		int num4 = (int)Mathf.Min(Mathf.Ceil(s.z + radius), gridHeight - 1);
		for (int i = num; i <= num3; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				Cell cell = GetCellData(i, j);
				if (cell != null && TileTouchingRadius(cell, s, radius))
				{
					Func(i, j, cell);
				}
			}
		}
	}

	public void ForEachTile(int sx, int sz, int ex, int ez, EvaluateCell Func)
	{
		int num = Mathf.Max(sx, 0);
		int num2 = Mathf.Max(sz, 0);
		int num3 = Mathf.Min(ex, gridWidth - 1);
		int num4 = Mathf.Min(ez, gridHeight - 1);
		for (int i = num; i <= num3; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				Cell cell = GetCellData(i, j);
				Func(i, j, cell);
			}
		}
	}

	private void TryAddToLandMassOpenSet(ArrayExt<Cell> openSet, Cell c)
	{
		if (c != null && c.Type != TerrainType.Water && !c.deepWater && c.landMassIdx == -1)
		{
			openSet.Add(c);
		}
	}

	private void AddNonWaterToOpenSet(ArrayExt<Cell> openSet, Cell c)
	{
		if (c == null)
		{
			return;
		}
		Cell cell = null;
		int num = cellData.Length;
		int num2 = c.x + 1 + c.z * gridWidth;
		if (num2 >= 0 && num2 < num)
		{
			cell = cellData[num2];
			if (cell.Type != TerrainType.Water)
			{
				openSet.Add(cell);
			}
		}
		num2 = c.x - 1 + c.z * gridWidth;
		if (num2 >= 0 && num2 < num)
		{
			cell = cellData[num2];
			if (cell.Type != TerrainType.Water)
			{
				openSet.Add(cell);
			}
		}
		num2 = c.x + (c.z + 1) * gridWidth;
		if (num2 >= 0 && num2 < num)
		{
			cell = cellData[num2];
			if (cell.Type != TerrainType.Water)
			{
				openSet.Add(cell);
			}
		}
		num2 = c.x + (c.z - 1) * gridWidth;
		if (num2 >= 0 && num2 < num)
		{
			cell = cellData[num2];
			if (cell.Type != TerrainType.Water)
			{
				openSet.Add(cell);
			}
		}
	}

	private void AddCardinalAndDiagonalToOpenSet(ArrayExt<Cell> openSet, Cell c)
	{
		if (c == null)
		{
			return;
		}
		for (int i = -1; i <= 1; i++)
		{
			for (int j = -1; j <= 1; j++)
			{
				if (j != 0 || i != 0)
				{
					int num = c.x + j;
					int num2 = c.z + i;
					if (num >= 0 && num2 >= 0 && num < gridWidth && num2 < gridHeight)
					{
						openSet.Add(cellData[num + num2 * gridWidth]);
					}
				}
			}
		}
	}

	private void AddCardinalLandmassToOpenSet(ArrayExt<Cell> openSet, Cell c, int landmass, ref bool isConnectedToWater)
	{
		if (c == null)
		{
			return;
		}
		Cell cell = null;
		int num = c.x + 1 + c.z * gridWidth;
		if (c.x + 1 < gridWidth)
		{
			cell = cellData[num];
			isConnectedToWater |= cell.Type == TerrainType.Water;
			if (cell.landMassIdx == landmass && cell.Type == TerrainType.None)
			{
				openSet.Add(cell);
			}
		}
		num = c.x - 1 + c.z * gridWidth;
		if (c.x - 1 >= 0)
		{
			cell = cellData[num];
			isConnectedToWater |= cell.Type == TerrainType.Water;
			if (cell.landMassIdx == landmass && cell.Type == TerrainType.None)
			{
				openSet.Add(cell);
			}
		}
		num = c.x + (c.z + 1) * gridWidth;
		if (c.z + 1 < gridHeight)
		{
			cell = cellData[num];
			isConnectedToWater |= cell.Type == TerrainType.Water;
			if (cell.landMassIdx == landmass && cell.Type == TerrainType.None)
			{
				openSet.Add(cell);
			}
		}
		num = c.x + (c.z - 1) * gridWidth;
		if (c.z - 1 >= 0)
		{
			cell = cellData[num];
			isConnectedToWater |= cell.Type == TerrainType.Water;
			if (cell.landMassIdx == landmass && cell.Type == TerrainType.None)
			{
				openSet.Add(cell);
			}
		}
	}

	public int FloodFillLandmassId(Cell startCell, int id)
	{
		int num = 0;
		ArrayExt<Cell> arrayExt = new ArrayExt<Cell>(cellData.Length);
		arrayExt.Add(startCell);
		while (arrayExt.Count > 0)
		{
			Cell cell = arrayExt.data[0];
			cell.landMassIdx = id;
			num++;
			Cell c = GetCellData(cell.x, cell.z + 1);
			TryAddToLandMassOpenSet(arrayExt, c);
			Cell c2 = GetCellData(cell.x, cell.z - 1);
			TryAddToLandMassOpenSet(arrayExt, c2);
			Cell c3 = GetCellData(cell.x - 1, cell.z);
			TryAddToLandMassOpenSet(arrayExt, c3);
			Cell c4 = GetCellData(cell.x + 1, cell.z);
			TryAddToLandMassOpenSet(arrayExt, c4);
			arrayExt.RemoveAtSwap(0);
		}
		return num;
	}

	private void SinkCell(Cell c, float jitter, Color debug)
	{
		c.landMassIdx = -1;
		c.deepWater = true;
		c.Type = TerrainType.Water;
		c.partOfOcean = true;
		TerrainGen.inst.SetBakedTileHeight(c.x, c.z, TerrainGen.waterHeightShallow + SRand.Range(0f - jitter, jitter));
		TerrainGen.inst.AddNoise(c);
	}

	private bool CellIsUnderwater(Cell c)
	{
		return TerrainGen.inst.GetVertY(c.x * 2 + 1, c.z * 2 + 1) < TerrainGen.waterHeightTestThresold;
	}

	public void GenerateLandMassIds(bool fillInlandOceans = true, bool applyCleanup = true, bool notifyFill = true)
	{
		int num = 0;
		int num2 = 0;
		landmassCenters.ClearFast();
		bool[] array = new bool[gridWidth * gridHeight];
		ArrayExt<Cell> arrayExt = new ArrayExt<Cell>(cellData.Length);
		ArrayExt<Cell> arrayExt2 = new ArrayExt<Cell>(cellData.Length);
		ArrayExt<ArrayExt<Cell>> arrayExt3 = new ArrayExt<ArrayExt<Cell>>(8);
		for (int i = 0; i < cellData.Length; i++)
		{
			Cell cell = cellData[i];
			if (array[i])
			{
				continue;
			}
			array[i] = true;
			if (cell.Type == TerrainType.Water)
			{
				cell.partOfOcean = true;
				continue;
			}
			if (CellIsUnderwater(cell))
			{
				cell.landMassIdx = -1;
				continue;
			}
			arrayExt2.ClearFast();
			arrayExt2.Add(cell);
			AddNonWaterToOpenSet(arrayExt, cell);
			while (arrayExt.Count > 0)
			{
				Cell cell2 = arrayExt.PopLast();
				int num3 = cell2.x + cell2.z * gridWidth;
				if (!array[num3])
				{
					array[num3] = true;
					if (cell2.Type == TerrainType.Water)
					{
						cell2.partOfOcean = true;
						continue;
					}
					if (CellIsUnderwater(cell2))
					{
						cell2.landMassIdx = -1;
						continue;
					}
					arrayExt2.Add(cell2);
					AddNonWaterToOpenSet(arrayExt, cell2);
				}
			}
			if (applyCleanup && arrayExt2.Count < 25)
			{
				num2 += arrayExt2.Count;
				for (int j = 0; j < arrayExt2.Count; j++)
				{
					SinkCell(arrayExt2.data[j], 0.2f, Color.cyan);
				}
				continue;
			}
			int count = arrayExt3.Count;
			arrayExt3.Add(new ArrayExt<Cell>(arrayExt2));
			int num4 = 0;
			int num5 = 0;
			for (int k = 0; k < arrayExt3.data[count].Count; k++)
			{
				Cell cell3 = arrayExt3.data[count].data[k];
				cell3.landMassIdx = count;
				num4 += cell3.x;
				num5 += cell3.z;
			}
			LandmassCenter item = default;
			item.xTotal = num4;
			item.zTotal = num5;
			item.count = arrayExt3.data[count].Count;
			item.center = new Vector3(num4 / item.count, 0f, num5 / item.count);
			landmassCenters.Add(item);
		}
		Util.Memset(array, 0);
		ArrayExt<Cell> arrayExt4 = new ArrayExt<Cell>(64);
		for (int l = 0; l < cellData.Length; l++)
		{
			Cell cell4 = cellData[l];
			if (array[l])
			{
				continue;
			}
			array[l] = true;
			if (cell4.Type != TerrainType.Water)
			{
				continue;
			}
			arrayExt2.ClearFast();
			arrayExt4.ClearFast();
			arrayExt2.Add(cell4);
			AddCardinalAndDiagonalToOpenSet(arrayExt, cell4);
			int num6 = -1;
			bool flag = false;
			while (arrayExt.Count > 0)
			{
				Cell cell5 = arrayExt.PopLast();
				int num7 = cell5.x + cell5.z * gridWidth;
				if (array[num7])
				{
					continue;
				}
				array[num7] = true;
				if (cell5.x == 0 || cell5.z == 0 || cell5.x == gridWidth - 1 || cell5.z == gridHeight - 1)
				{
					flag = true;
				}
				if (cell5.Type != TerrainType.Water)
				{
					if (CellIsUnderwater(cell5))
					{
						if (cell5.Type == TerrainType.None)
						{
							arrayExt4.Add(cell5);
						}
						AddCardinalAndDiagonalToOpenSet(arrayExt, cell5);
					}
					else if (cell5.landMassIdx != -1)
					{
						num6 = cell5.landMassIdx;
					}
				}
				else
				{
					arrayExt2.Add(cell5);
					AddCardinalAndDiagonalToOpenSet(arrayExt, cell5);
				}
			}
			if (!(applyCleanup & fillInlandOceans) || flag || num6 == -1)
			{
				continue;
			}
			num += arrayExt2.Count;
			LandmassCenter landmassCenter = landmassCenters.data[num6];
			for (int m = 0; m < arrayExt2.Count; m++)
			{
				Cell cell6 = arrayExt2.data[m];
				cell6.landMassIdx = num6;
				cell6.Type = TerrainType.None;
				cell6.deepWater = false;
				cell6.partOfOcean = false;
				landmassCenter.xTotal += cell6.x;
				landmassCenter.zTotal += cell6.z;
				float highestHeightInCell = TerrainGen.inst.GetHighestHeightInCell(cell6.x + 1, cell6.z);
				float highestHeightInCell2 = TerrainGen.inst.GetHighestHeightInCell(cell6.x - 1, cell6.z);
				float highestHeightInCell3 = TerrainGen.inst.GetHighestHeightInCell(cell6.x, cell6.z - 1);
				float highestHeightInCell4 = TerrainGen.inst.GetHighestHeightInCell(cell6.x, cell6.z + 1);
				float height = (highestHeightInCell + highestHeightInCell2 + highestHeightInCell3 + highestHeightInCell4) / 4f;
				TerrainGen.inst.SetBakedTileHeight(cell6.x, cell6.z, height);
				for (int n = cell6.x - 2; n < cell6.x + 2; n++)
				{
					for (int num8 = cell6.z - 2; num8 < cell6.z + 2; num8++)
					{
						if (n != cell6.x || num8 != cell6.z)
						{
							TerrainGen.inst.SetAverageTileHeight(n, num8, 0.5f);
						}
					}
				}
				arrayExt3.data[num6].Add(cell6);
			}
			for (int num9 = 0; num9 < arrayExt4.Count; num9++)
			{
				Cell cell7 = arrayExt4.data[num9];
				cell7.landMassIdx = num6;
				cell7.deepWater = false;
				cell7.partOfOcean = false;
				landmassCenter.xTotal += cell7.x;
				landmassCenter.zTotal += cell7.z;
				TerrainGen.inst.SetLandTile(cell7.x, cell7.z);
				arrayExt3.data[num6].Add(cell7);
			}
			num += arrayExt4.Count;
			for (int num10 = 0; num10 < arrayExt2.Count + arrayExt4.Count; num10++)
			{
				Cell cell8 = ((num10 < arrayExt2.Count) ? arrayExt2.data[num10] : arrayExt4.data[num10 - arrayExt2.Count]);
				for (int num11 = cell8.x - 2; num11 < cell8.x + 2; num11++)
				{
					for (int num12 = cell8.z - 2; num12 < cell8.z + 2; num12++)
					{
						Cell cell9 = GetCellData(num11, num12);
						if (cell9 == null || cell9.Type == TerrainType.Water || cell9.landMassIdx != num6 || !CellIsUnderwater(cell9))
						{
							continue;
						}
						for (int num13 = num12 * 2; num13 <= num12 * 2 + 2; num13++)
						{
							for (int num14 = num11 * 2; num14 <= num11 * 2 + 2; num14++)
							{
								if (TerrainGen.inst.GetVertY(num14, num13) < 0f && !VertTouchesOtherTerrain(num14, num13, num6))
								{
									TerrainGen.inst.SetVert(num14, num13, 0f, bakeDown: true);
								}
							}
						}
					}
				}
			}
			landmassCenter.count += arrayExt2.Count + arrayExt4.Count;
			landmassCenter.center = new Vector3(landmassCenter.xTotal / landmassCenter.count, 0f, landmassCenter.zTotal / landmassCenter.count);
			landmassCenters.data[num6] = landmassCenter;
		}
		if (notifyFill && num > 0)
		{
			OnInlandOceanFilled?.Invoke(num);
		}
		Util.Memset(array, 0);
		for (int num15 = 0; num15 < arrayExt3.Count; num15++)
		{
			ArrayExt<Cell> arrayExt5 = arrayExt3.data[num15];
			int num16 = num2;
			for (int num17 = 0; num17 < arrayExt5.Count; num17++)
			{
				Cell cell10 = arrayExt5.data[num17];
				int num18 = cell10.x + cell10.z * gridWidth;
				if (array[num18])
				{
					continue;
				}
				array[num18] = true;
				if (cell10.Type != TerrainType.None)
				{
					continue;
				}
				bool isConnectedToWater = false;
				arrayExt2.ClearFast();
				arrayExt2.Add(cell10);
				AddCardinalLandmassToOpenSet(arrayExt, cell10, num15, ref isConnectedToWater);
				while (arrayExt.Count > 0)
				{
					Cell cell11 = arrayExt.PopLast();
					num18 = cell11.x + cell11.z * gridWidth;
					if (!array[num18])
					{
						array[num18] = true;
						if (cell11.Type == TerrainType.None)
						{
							arrayExt2.Add(cell11);
							AddCardinalLandmassToOpenSet(arrayExt, cell11, num15, ref isConnectedToWater);
						}
					}
				}
				if (!applyCleanup || arrayExt2.Count >= 25)
				{
					continue;
				}
				if (isConnectedToWater)
				{
					num2 += arrayExt2.Count;
					for (int num19 = 0; num19 < arrayExt2.Count; num19++)
					{
						SinkCell(arrayExt2.data[num19], 0.1f, Color.magenta);
					}
				}
				else
				{
					for (int num20 = 0; num20 < arrayExt2.Count; num20++)
					{
						arrayExt2.data[num20].Type = TerrainType.Obstruction;
					}
				}
			}
			if (num2 == num16)
			{
				continue;
			}
			int num21 = 0;
			for (int num22 = 0; num22 < arrayExt5.Count; num22++)
			{
				if (arrayExt5.data[num22].landMassIdx == num15)
				{
					arrayExt5.data[num21++] = arrayExt5.data[num22];
				}
			}
			if (num21 < arrayExt5.Count)
			{
				arrayExt5.RemoveRange(num21, arrayExt5.Count - num21);
			}
			if (arrayExt5.Count < 25)
			{
				num2 += arrayExt5.Count;
				for (int num23 = 0; num23 < arrayExt5.Count; num23++)
				{
					SinkCell(arrayExt5.data[num23], 0.2f, Color.cyan);
				}
				arrayExt5.ClearFast();
			}
		}
		int num24 = 0;
		for (int num25 = 0; num25 < arrayExt3.Count; num25++)
		{
			ArrayExt<Cell> arrayExt6 = arrayExt3.data[num25];
			if (arrayExt6.Count == 0)
			{
				continue;
			}
			if (num24 != num25)
			{
				for (int num26 = 0; num26 < arrayExt6.Count; num26++)
				{
					arrayExt6.data[num26].landMassIdx = num24;
				}
				arrayExt3.data[num24] = arrayExt6;
				landmassCenters.data[num24] = landmassCenters.data[num25];
			}
			num24++;
		}
		if (num24 < arrayExt3.Count)
		{
			arrayExt3.RemoveRange(num24, arrayExt3.Count - num24);
			landmassCenters.RemoveRange(num24, landmassCenters.Count - num24);
		}
		if (notifyFill && num2 > 0)
		{
			OnSmallIslandSunk?.Invoke(num2);
		}
		numLandMasses = arrayExt3.Count;
		cellsToLandmass = new ArrayExt<Cell>[numLandMasses];
		for (int num27 = 0; num27 < arrayExt3.Count; num27++)
		{
			cellsToLandmass[num27] = new ArrayExt<Cell>(arrayExt3.data[num27]);
		}
		villagersPerLandMass.Clear();
		for (int num28 = 0; num28 < numLandMasses; num28++)
		{
			villagersPerLandMass.Add(new ArrayExt<Villager>(200));
		}
	}

	private void OnApplicationQuit()
	{
		LegionSystem.Inst.CompleteJobs();
	}

	public int GetWolfDenCountPerLandmass(int lm)
	{
		int num = 0;
		for (int i = 0; i < caveContainer.transform.childCount; i++)
		{
			WolfDen component = caveContainer.transform.GetChild(i).GetComponent<WolfDen>();
			if (component != null && inst.GetCellData((int)component.transform.position.x, (int)component.transform.position.z).landMassIdx == lm)
			{
				num++;
			}
		}
		return num;
	}

	public void PlaceAIs(int playersLandmass)
	{
		FindValidStartLandmasses();
		List<LandmassStartInfo> list = landmassStartInfo.OrderByDescending((LandmassStartInfo f) => f.size).ToList();
		list.RemoveAll((LandmassStartInfo lm) => lm.landmass == playersLandmass);
		AIBrainsContainer.PreStartAIConfig aiStartInfo = AIBrainsContainer.inst.aiStartInfo;
		List<AIBrainsContainer.PreStartAIConfig.AIStartData> items = aiStartInfo.startData.ToList();
		int i;
		for (i = 0; i < items.Count; i++)
		{
			if (items[i].landmass == -1 || items[i].landmass == playersLandmass)
			{
				continue;
			}
			Type typeByKey = PersonalityCollection.GetTypeByKey(items[i].personalityKey);
			if (typeByKey != null)
			{
				AIBrainsContainer.inst.SpawnAIKingdom(items[i].landmass, items[i].bioCode, (AIPersonality)Activator.CreateInstance(typeByKey), items[i].skillLevel);
				list.RemoveAll((LandmassStartInfo info) => info.landmass == items[i].landmass);
			}
			items.Remove(items[i]);
			i--;
		}
		list.RemoveAll((LandmassStartInfo lm) => !IsValidStartLandmassForAI(lm.landmass));
		for (int num = 0; num < list.Count && num < items.Count; num++)
		{
			Type typeByKey2 = PersonalityCollection.GetTypeByKey(items[num].personalityKey);
			if (typeByKey2 != null)
			{
				AIBrainsContainer.inst.SpawnAIKingdom(list[num].landmass, items[num].bioCode, (AIPersonality)Activator.CreateInstance(typeByKey2), items[num].skillLevel);
			}
		}
		AIBrainsContainer.inst.BeginBaseBuilding();
	}

	public Relations RelationBetween(int teamIDA, int teamIDB)
	{
		if (teamIDA == teamIDB)
		{
			return Relations.Allies;
		}
		if (teamIDA == 1 || teamIDB == 1)
		{
			return Relations.Enemy;
		}
		if (teamIDA == -1 || teamIDB == -1)
		{
			return Relations.Enemy;
		}
		if (teamIDA == -2 || teamIDB == -2)
		{
			return Relations.Neutral;
		}
		if (teamIDA >= 0 && teamIDA < 5 && teamIDB >= 0 && teamIDB < 5)
		{
			return hostility[teamIDA, teamIDB];
		}
		return Relations.Neutral;
	}

	public void SetRelations(int teamIDA, int teamIDB, Relations r)
	{
		hostility[teamIDA, teamIDB] = r;
		hostility[teamIDB, teamIDA] = r;
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(gateHash);
		for (int i = 0; i < buildingList.Count; i++)
		{
			buildingList.data[i].BakePathing();
		}
		buildingList = Player.inst.GetBuildingList(woodengateHash);
		for (int j = 0; j < buildingList.Count; j++)
		{
			buildingList.data[j].BakePathing();
		}
		buildingList = Player.inst.GetBuildingList(seagateHash);
		for (int k = 0; k < buildingList.Count; k++)
		{
			buildingList.data[k].BakePathing();
		}
		AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(teamIDA);
		if (kingdomFromTeamId == null)
		{
			kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(teamIDB);
		}
		if (r == Relations.Enemy)
		{
			if (kingdomFromTeamId != null && (teamIDB == 0 || teamIDA == 0))
			{
				kingdomFromTeamId.manageDiplomacyIntention.OnDeclaredWar();
				kingdomFromTeamId.ClearMission();
			}
			LandmassOwner landmassOwnerByTeamId = GetLandmassOwnerByTeamId(teamIDA);
			LandmassOwner landmassOwnerByTeamId2 = GetLandmassOwnerByTeamId(teamIDB);
			if (landmassOwnerByTeamId.GetStandingFor(landmassOwnerByTeamId2.teamId) >= LandmassOwner.Standing.Neutral)
			{
				landmassOwnerByTeamId.SetStandingFor(landmassOwnerByTeamId2.teamId, LandmassOwner.Standing.Unfavorable);
			}
			if (landmassOwnerByTeamId2.GetStandingFor(landmassOwnerByTeamId.teamId) >= LandmassOwner.Standing.Neutral)
			{
				landmassOwnerByTeamId2.SetStandingFor(landmassOwnerByTeamId.teamId, LandmassOwner.Standing.Unfavorable);
			}
			Player.inst.CloseDocks(landmassOwnerByTeamId, landmassOwnerByTeamId2);
		}
		else
		{
			kingdomFromTeamId.enemyPoints = 0;
		}
		if (r == Relations.Allies)
		{
			if (kingdomFromTeamId != null && (teamIDB == 0 || teamIDA == 0))
			{
				FogOfWar.inst.RefreshVisible(kingdomFromTeamId.Layout.LandMass, visible: true);
			}
		}
		else if (kingdomFromTeamId != null && (teamIDB == 0 || teamIDA == 0))
		{
			FogOfWar.inst.RefreshVisible(kingdomFromTeamId.Layout.LandMass, visible: false);
		}
	}

	public void ClearHostility()
	{
		hostility = new Relations[5, 5];
	}

	private void PlaceGrass()
	{
		for (int i = 0; i < gridHeight; i++)
		{
			for (int j = 0; j < gridWidth; j++)
			{
				Cell cell = cellData[i * gridWidth + j];
				if (cell.GetFertility() > 0)
				{
					for (int k = 0; k < grassSystem.itemsPerCell; k++)
					{
						grassSystem.PlaceItem(cell);
					}
				}
				else
				{
					for (int l = 0; l < dryGrassSystem.itemsPerCell; l++)
					{
						dryGrassSystem.PlaceItem(cell);
					}
				}
			}
		}
	}
}
