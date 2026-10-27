using System;
using Drawing;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using UnityEngine;

public class AmbientSfx : MonoBehaviour
{
	public class Quadrant
	{
		public int originX;

		public int originZ;

		public int waterCount;

		public int coastCount;

		public int riverCount;

		public int residentialTileCount;

		public int residentialUniqueCount;

		public int residentsCount;

		public int mountainCount;

		public float mountainHeight;

		public int citizenCount;

		public int landCount;

		public float oceanRatio;

		public float coastRatio;

		public float landRatio;

		public float riverRatio;

		public float residentialRatio;

		public float mountainRatio;

		public EventInstance ambEvent;

		public Quadrant()
		{
			ambEvent = RuntimeManager.CreateInstance("event:/SFX ASITP/Ambiences/amb_master");
			ambEvent.start();
		}

		public void Reset()
		{
			waterCount = 0;
			coastCount = 0;
			riverCount = 0;
			residentialTileCount = 0;
			residentialUniqueCount = 0;
			landCount = 0;
			citizenCount = 0;
			mountainCount = 0;
			mountainHeight = 0f;
		}
	}

	public AudioLowPassFilter lowPassFilter;

	public static AmbientSfx inst;

	private int total;

	private int water;

	private int land;

	private int coast;

	private int buildings;

	private int flowingLava;

	private int flowingWater;

	private int residents;

	private int residentDensity;

	private Vector3 waterCenter;

	private Vector3 landCenter;

	private Vector3 coastCenter;

	private Vector3 flowingWaterCenter;

	private Vector3 residentialCenter;

	private int totalSum;

	private int flowingWaterSum;

	private int flowingLavaSum;

	private int waterSum;

	private int landSum;

	private int coastSum;

	private int buildingsSum;

	private int residentialSum;

	private int residentsSum;

	private Vector3 flowingWaterCenterSum;

	private Vector3 waterCenterSum;

	private Vector3 landCenterSum;

	private Vector3 coastCenterSum;

	private Vector3 residentialCenterSum;

	private const int MIN_RESIDENTS_FOR_HIGH = 120;

	private const int MIN_RESIDENTS_FOR_LOW = 10;

	private const int MIN_LOW_RESIDENTS_DENSITY = 8;

	private const int MIN_MEDIUM_RESIDENTS_DENSITY = 15;

	private const int MIN_HIGH_RESIDENTS_DENSITY = 25;

	private EventHandler<SeasonEventData> seasonEventListenEventHandler;

	private EventInstance ambLand;

	private EventInstance ambLandNight;

	private EventInstance ambCoast;

	private EventInstance ambSea;

	private EventInstance ambSky;

	private EventInstance ambResidentialHigh;

	private EventInstance ambResidentialMedium;

	private EventInstance ambResidentialLow;

	private EventInstance ambRiver;

	private PARAMETER_ID distToLandParam;

	private PARAMETER_ID distToLandParamNight;

	private PARAMETER_ID distToCoastParam;

	private PARAMETER_ID distToSeaParam;

	private PARAMETER_ID distToSkyParam;

	private PARAMETER_DESCRIPTION distToLandParamDesc;

	private PARAMETER_DESCRIPTION distToLandParamDescNight;

	private PARAMETER_DESCRIPTION distToCoastParamDesc;

	private PARAMETER_DESCRIPTION distToSeaParamDesc;

	private PARAMETER_DESCRIPTION distToSkyParamDesc;

	private PARAMETER_ID dayNightParam;

	private PARAMETER_ID TwentyFourParam;

	private PARAMETER_ID seasonParam;

	private int layerMask;

	private int[] sfxBuildingCountIgnore = new int[6]
	{
		"stoneroad".GetHashCode(),
		"road".GetHashCode(),
		"gate".GetHashCode(),
		"woodengate".GetHashCode(),
		"castleblock".GetHashCode(),
		"woodcastleblock".GetHashCode()
	};

	private Vector3 startLandSourcePos;

	private Vector3 startCoastSourcePos;

	private Vector3 startSeaSourcePos;

	private Vector3 desiredLandSourcePos;

	private Vector3 desiredCoastSourcePos;

	private Vector3 desiredSeaSourcePos;

	private Vector3 desiredFlowingWaterSourcePos;

	private Vector3 desiredResidentialHighSourcePos;

	private Vector3 desiredResidentialMediumSourcePos;

	private Vector3 desiredResidentialLowSourcePos;

	private float sourceLerp;

	public int ambientMinRadius = 4;

	public int ambientMaxRadius = 10;

	public float ambientRadiusMult = 1f;

	private bool wasDay = true;

	private int tx;

	private int tz;

	public bool debug;

	public bool debugCells;

	public bool debugQuadrant = true;

	public int maxQuadrantSize = 8;

	public int minQuadrantSize = 4;

	public int minCamDist;

	public int maxCamDist = 70;

	[Min(1f)]
	public int quadrantSpacing = 1;

	public AnimationCurve quadrantScaleCurve;

	public int maxCitizens = 100;

	public float citizenWeight = 0.7f;

	public Vector2 mountainHeightThresholds;

	public Quadrant[] quadrants = new Quadrant[4];

	private Color[] debugColors = new Color[4]
	{
		new Color(1f, 0f, 0f, 0.25f),
		new Color(0f, 1f, 0f, 0.25f),
		new Color(0f, 0f, 1f, 0.25f),
		new Color(1f, 0f, 1f, 0.25f)
	};

	private Cell[] neighbors = new Cell[4];

	private ArrayExt<Building> hasVisited = new ArrayExt<Building>(32);

	private void Awake()
	{
		inst = this;
	}

	public void OnSeasonChanged(object sender, SeasonEventData obj)
	{
	}

	public void TryInit()
	{
		layerMask = LayerMask.GetMask("Terrain");
		seasonEventListenEventHandler = Broadcast.SeasonEvent.Listen(OnSeasonChanged);
		ambSky = RuntimeManager.CreateInstance("event:/SFX ASITP/Ambiences/amb_sky");
		ambSky.start();
		ambSky.release();
		RuntimeManager.StudioSystem.getParameterDescriptionByName("parameter:/Ambience/DayNight", out var parameter);
		dayNightParam = parameter.id;
		RuntimeManager.StudioSystem.getParameterDescriptionByName("parameter:/Ambience/Season", out var parameter2);
		seasonParam = parameter2.id;
		RuntimeManager.StudioSystem.getParameterDescriptionByName("parameter:/DistanceToLand", out distToLandParamDesc);
		distToLandParam = distToLandParamDesc.id;
		RuntimeManager.StudioSystem.getParameterDescriptionByName("parameter:/DistanceToCoast", out distToCoastParamDesc);
		distToCoastParam = distToCoastParamDesc.id;
		RuntimeManager.StudioSystem.getParameterDescriptionByName("parameter:/DistanceToSea", out distToSeaParamDesc);
		distToSeaParam = distToSeaParamDesc.id;
		RuntimeManager.StudioSystem.getParameterDescriptionByName("parameter:/DistanceToSky", out distToSkyParamDesc);
		distToSkyParam = distToSkyParamDesc.id;
	}

	private void Update()
	{
		if (!(GameUI.inst == null) && !LoadSave.Loading && !Player.inst.resetting && World.inst.GetCellsData() != null)
		{
			TileProcessor();
		}
	}

	private void UpdateSounds()
	{
		Ray ray = new Ray(Cam.inst.CamPos, Cam.inst.transform.forward);
		float num = 0f;
		if (Physics.Raycast(ray, out var hitInfo, 300f, layerMask))
		{
			num = hitInfo.distance;
			RuntimeManager.StudioSystem.setParameterByID(TwentyFourParam, DayNightManager.inst.GameParameters._24HourTime);
			RuntimeManager.StudioSystem.setParameterByIDWithLabel(seasonParam, SeasonManager.GetCurrentSeason().name);
			if (coast > 0)
			{
				desiredCoastSourcePos = coastCenter;
			}
			if (water > 0)
			{
				desiredSeaSourcePos = waterCenter;
			}
			if (land > 0)
			{
				desiredLandSourcePos = landCenter;
			}
			if (flowingWater > 0)
			{
				desiredFlowingWaterSourcePos = flowingWaterCenter;
			}
			SetEventInstanceState(ambRiver, flowingWater > 0);
			if (residentDensity >= 25)
			{
				desiredResidentialHighSourcePos = residentialCenter;
			}
			else if (residentDensity >= 15)
			{
				desiredResidentialMediumSourcePos = residentialCenter;
			}
			else if (residentDensity >= 8)
			{
				desiredResidentialLowSourcePos = residentialCenter;
			}
			SetEventInstanceState(ambResidentialHigh, residentDensity >= 25);
			SetEventInstanceState(ambResidentialMedium, residentDensity < 25 && residentDensity >= 15);
			SetEventInstanceState(ambResidentialLow, residentDensity < 15 && residentDensity >= 8);
			ambLand.set3DAttributes(desiredLandSourcePos.To3DAttributes());
			ambLandNight.set3DAttributes(desiredLandSourcePos.To3DAttributes());
			ambCoast.set3DAttributes(desiredCoastSourcePos.To3DAttributes());
			ambSea.set3DAttributes(desiredSeaSourcePos.To3DAttributes());
			ambRiver.set3DAttributes(desiredFlowingWaterSourcePos.To3DAttributes());
			ambResidentialHigh.set3DAttributes(desiredResidentialHighSourcePos.To3DAttributes());
			ambResidentialMedium.set3DAttributes(desiredResidentialMediumSourcePos.To3DAttributes());
			ambResidentialLow.set3DAttributes(desiredResidentialLowSourcePos.To3DAttributes());
			RuntimeManager.StudioSystem.setParameterByID(distToSkyParam, distToSkyParamDesc.maximum - num);
		}
	}

	private void TileProcessor()
	{
		hasVisited.ClearFast();
		Vector3 vector = World.inst.SnapToGrid2D(Cam.inst.microphoneT.position);
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		int num = 0;
		for (int i = -1; i <= 1; i++)
		{
			if (i == 0)
			{
				continue;
			}
			for (int j = -1; j <= 1; j++)
			{
				if (j == 0)
				{
					continue;
				}
				if (quadrants[num] == null)
				{
					quadrants[num] = new Quadrant();
				}
				else
				{
					quadrants[num].Reset();
				}
				Quadrant quadrant = quadrants[num];
				Vector3 position = Cam.inst.microphoneT.position;
				float time = (position.y - Mathff.Max(TerrainGen.SeaLevel, TerrainGen.inst.GetGroundHeight(position.x, position.z)) - (float)minCamDist) / (float)(maxCamDist - minCamDist);
				float num2 = quadrantScaleCurve.Evaluate(time);
				int num3 = Mathff.Max(minQuadrantSize, Mathf.CeilToInt(num2 * (float)maxQuadrantSize)) * quadrantSpacing;
				quadrant.originX = (int)vector.x - Mathff.Abs((i - 1) / 2) * num3;
				quadrant.originZ = (int)vector.z - Mathff.Abs((j - 1) / 2) * num3;
				for (int k = 0; k < num3 + 1; k++)
				{
					for (int l = 0; l < num3 + 1; l++)
					{
						if (quadrantSpacing > 1 && (k % quadrantSpacing != 0 || l % quadrantSpacing != 0))
						{
							continue;
						}
						int num4 = quadrant.originX + k;
						int num5 = quadrant.originZ + l;
						if (num4 < 1 || num4 > gridWidth - 2 || num5 < 1 || num5 > gridHeight - 2)
						{
							quadrant.waterCount++;
							continue;
						}
						Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(num4, num5);
						if (cellDataUnsafe.Type != TerrainType.Water)
						{
							quadrant.citizenCount += World.inst.GetVillagersAt(cellDataUnsafe.x, cellDataUnsafe.z).Count;
						}
						if (cellDataUnsafe.Type == TerrainType.Water)
						{
							if ((0u | ((World.inst.GetCellDataUnsafe(num4 + 1, num5).Type != TerrainType.Water) ? 1u : 0u) | ((World.inst.GetCellDataUnsafe(num4 - 1, num5).Type != TerrainType.Water) ? 1u : 0u) | ((World.inst.GetCellDataUnsafe(num4, num5 - 1).Type != TerrainType.Water) ? 1u : 0u) | ((World.inst.GetCellDataUnsafe(num4, num5 - 1).Type != TerrainType.Water) ? 1u : 0u)) != 0)
							{
								quadrant.coastCount++;
							}
							else
							{
								quadrant.waterCount++;
							}
						}
						else if (cellDataUnsafe.Type == TerrainType.Obstruction)
						{
							quadrant.mountainCount++;
							quadrant.mountainHeight += TerrainGen.inst.GetGroundHeight((float)num4 + 0.5f, (float)num5 + 0.5f);
						}
						else if (cellDataUnsafe.BottomStructureIsCategory(World.houseCategoryHash))
						{
							quadrant.residentialTileCount++;
							Building building = cellDataUnsafe.OccupyingStructure[0];
							if (!hasVisited.Contains(building))
							{
								quadrant.residentialUniqueCount++;
								quadrant.residentsCount += building.GetComponent<Home>().Residents.Count;
								hasVisited.Add(building);
							}
						}
						else if (DynamicWater.inst.simplifiedWaterGrid[num4 + num5 * gridWidth] > 0f)
						{
							quadrant.riverCount++;
						}
						else if (cellDataUnsafe.Type != TerrainType.Water)
						{
							quadrant.landCount++;
						}
					}
				}
				Vector3 pos = new Vector3((float)quadrant.originX + ((float)num3 + 1f) * 0.5f, 0f, (float)quadrant.originZ + ((float)num3 + 1f) * 0.5f);
				TerrainGen.inst.GetGroundHeight(ref pos);
				quadrant.ambEvent.set3DAttributes(pos.To3DAttributes());
				float num6 = (num3 + 1) * (num3 + 1);
				quadrant.oceanRatio = (float)quadrant.waterCount / num6;
				quadrant.coastRatio = (float)quadrant.coastCount / num6;
				quadrant.riverRatio = (float)quadrant.riverCount / num6;
				quadrant.landRatio = (float)quadrant.landCount / num6;
				float num7 = Mathff.Clamp01((((quadrant.mountainCount > 0) ? (quadrant.mountainHeight / (float)quadrant.mountainCount) : 0f) - mountainHeightThresholds.x) / (mountainHeightThresholds.y - mountainHeightThresholds.x));
				quadrant.mountainRatio = (float)quadrant.mountainCount / num6 * num7;
				float num8 = Mathff.Lerp(0f, citizenWeight, Mathff.Clamp01((float)quadrant.citizenCount / (float)maxCitizens));
				float num9 = Mathff.Lerp(0f, 1f - citizenWeight, (float)quadrant.residentialTileCount / num6);
				quadrant.residentialRatio = num8 + num9;
				pos.y += 2f;
				quadrant.ambEvent.setParameterByName("parameter:/Ocean", quadrant.oceanRatio);
				quadrant.ambEvent.setParameterByName("parameter:/Coast", quadrant.coastRatio);
				quadrant.ambEvent.setParameterByName("parameter:/River", quadrant.riverRatio);
				quadrant.ambEvent.setParameterByName("parameter:/Land", quadrant.landRatio);
				quadrant.ambEvent.setParameterByName("parameter:/Residential", quadrant.residentialRatio);
				quadrant.ambEvent.setParameterByName("parameter:/Mountain", quadrant.mountainRatio);
				num++;
			}
		}
		Ray ray = new Ray(Cam.inst.CamPos, Cam.inst.transform.forward);
		if (PhotoMode.IsActive())
		{
			Vector3 forward = Cam.inst.transform.forward;
			float maxRadiansDelta = MathF.PI / 3f;
			Vector3 direction = Vector3.RotateTowards(Vector3.down, forward, maxRadiansDelta, 0f);
			ray.direction = direction;
			Draw.Ray(ray.origin, ray.direction * 5f);
		}
		float num10 = 0f;
		if (Physics.Raycast(ray, out var hitInfo, 300f, layerMask))
		{
			num10 = hitInfo.distance;
			RuntimeManager.StudioSystem.setParameterByID(distToSkyParam, distToSkyParamDesc.maximum - num10);
		}
		RuntimeManager.StudioSystem.setParameterByIDWithLabel(seasonParam, SeasonManager.GetCurrentSeason().name);
	}

	private void EvalTile(Cell cell, Vector3 pos)
	{
		totalSum++;
		if (cell.Type == TerrainType.Water)
		{
			if (waterSum == 0)
			{
				waterCenterSum = pos;
			}
			else
			{
				waterCenterSum += pos;
			}
			waterSum++;
		}
		else
		{
			if (landSum == 0)
			{
				landCenterSum = pos;
			}
			else
			{
				landCenterSum += pos;
			}
			landSum++;
		}
		World.inst.GetNeighborCells(cell, ref neighbors);
		if (cell.Type == TerrainType.Water)
		{
			for (int i = 0; i < neighbors.Length; i++)
			{
				if (neighbors[i] != null && neighbors[i].Type != TerrainType.Water)
				{
					if (coastSum == 0)
					{
						coastCenterSum = pos;
					}
					else
					{
						coastCenterSum += pos;
					}
					coastSum++;
					break;
				}
			}
		}
		if (cell.TopMostStructure != null && cell.TopMostStructure.seenByPlayer)
		{
			if (!cell.TopMostStructureIs(sfxBuildingCountIgnore))
			{
				buildingsSum++;
			}
			if (cell.TopMostStructure.categoryHash == World.houseCategoryHash && !hasVisited.Contains(cell.TopMostStructure))
			{
				if (residentialSum == 0)
				{
					residentialCenterSum = pos;
				}
				else
				{
					residentialCenterSum += pos;
				}
				residentialSum++;
				residentsSum += cell.TopMostStructure.GetComponent<Home>().Residents.Count;
				hasVisited.Add(cell.TopMostStructure);
			}
		}
		if (DynamicLava.inst.simplifiedWaterGrid[cell.index] > 0f)
		{
			flowingLavaSum++;
		}
		if (DynamicWater.inst.simplifiedWaterFlowMagnitude[cell.index] > 0f)
		{
			if (flowingWaterSum == 0)
			{
				flowingWaterCenterSum = pos;
			}
			else
			{
				flowingWaterCenterSum += pos;
			}
			flowingWaterSum++;
		}
	}

	private void SetEventInstanceState(EventInstance instance, bool on)
	{
		PLAYBACK_STATE state2;
		if (on)
		{
			if (instance.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.STOPPED)
			{
				instance.start();
			}
		}
		else if (instance.getPlaybackState(out state2) == RESULT.OK && state2 == PLAYBACK_STATE.PLAYING)
		{
			instance.stop(STOP_MODE.ALLOWFADEOUT);
		}
	}
}
