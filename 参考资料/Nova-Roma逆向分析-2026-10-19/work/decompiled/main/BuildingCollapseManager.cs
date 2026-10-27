using System;
using System.Collections.Generic;
using Assets.Code;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using UnityEngine;

public class BuildingCollapseManager : MonoBehaviour
{
	public struct RubbleGroup
	{
		public int x;

		public int z;

		public float y;

		public int sizeX;

		public int sizeZ;

		public Guid guid;

		public string uniqueName;

		public Vector3 offsetPos;

		public Quaternion offsetRot;

		public int variant;

		public LogisticsManager.LogisticsManagerSaveData.LogisticsForStorageData logisticSaveData;

		public List<Guid> sourcingLogisticBuildings;

		public SerializableDictionary<Guid, List<LogisticsVehicle.LogisticsVehicleSaveData.RouteData>> cartRoutes;

		public bool isSquare;

		public List<object> settings;
	}

	public class CollapseEntry
	{
		public Building b;

		public float velocity;

		public float maxHeight;

		public float minHeight;

		public EventInstance eInstance;
	}

	[Serializable]
	public class BuildingCollapseManagerSaveData : SaveClass<BuildingCollapseManager, BuildingCollapseManagerSaveData>
	{
		[Serializable]
		public class BuildingRubbleSaveData
		{
			public int x;

			public int z;

			public float y;

			public int sizeX;

			public int sizeZ;

			public SerializableGuid guid;

			public string uniqueName;

			public SerializableVector3 offsetPos;

			public SerializableQuaternion offsetRot;

			public int variant;

			public bool isSquare;

			public LogisticsManager.LogisticsManagerSaveData.LogisticsForStorageData logisticSaveData;

			public List<Guid> sourcingLogisticBuildings;

			public SerializableDictionary<Guid, List<LogisticsVehicle.LogisticsVehicleSaveData.RouteData>> cartRoutes;

			public List<object> settings;
		}

		public List<BuildingRubbleSaveData>[] groupCells;

		public override BuildingCollapseManagerSaveData Pack(BuildingCollapseManager obj)
		{
			groupCells = new List<BuildingRubbleSaveData>[obj.groupCells.Length];
			for (int i = 0; i < groupCells.Length; i++)
			{
				ArrayExt<RubbleGroup> arrayExt = obj.groupCells[i];
				if (arrayExt != null)
				{
					groupCells[i] = new List<BuildingRubbleSaveData>(arrayExt.Count);
					for (int j = 0; j < arrayExt.Count; j++)
					{
						RubbleGroup rubbleGroup = arrayExt.data[j];
						BuildingRubbleSaveData item = new BuildingRubbleSaveData
						{
							guid = rubbleGroup.guid,
							x = rubbleGroup.x,
							z = rubbleGroup.z,
							y = rubbleGroup.y,
							sizeX = rubbleGroup.sizeX,
							sizeZ = rubbleGroup.sizeZ,
							uniqueName = rubbleGroup.uniqueName,
							offsetPos = rubbleGroup.offsetPos,
							offsetRot = rubbleGroup.offsetRot,
							variant = rubbleGroup.variant,
							isSquare = rubbleGroup.isSquare,
							logisticSaveData = rubbleGroup.logisticSaveData,
							sourcingLogisticBuildings = rubbleGroup.sourcingLogisticBuildings,
							cartRoutes = rubbleGroup.cartRoutes,
							settings = rubbleGroup.settings
						};
						groupCells[i].Add(item);
					}
				}
			}
			return this;
		}

		public override BuildingCollapseManager Unpack(BuildingCollapseManager obj)
		{
			if (groupCells != null)
			{
				for (int i = 0; i < groupCells.Length; i++)
				{
					List<BuildingRubbleSaveData> list = groupCells[i];
					if (list != null)
					{
						ArrayExt<RubbleGroup>[] array = obj.groupCells;
						int num = i;
						if (array[num] == null)
						{
							array[num] = new ArrayExt<RubbleGroup>(list.Count);
						}
						for (int j = 0; j < list.Count; j++)
						{
							BuildingRubbleSaveData buildingRubbleSaveData = list[j];
							RubbleGroup item = new RubbleGroup
							{
								guid = buildingRubbleSaveData.guid,
								x = buildingRubbleSaveData.x,
								z = buildingRubbleSaveData.z,
								y = buildingRubbleSaveData.y,
								sizeX = buildingRubbleSaveData.sizeX,
								sizeZ = buildingRubbleSaveData.sizeZ,
								uniqueName = buildingRubbleSaveData.uniqueName,
								offsetPos = buildingRubbleSaveData.offsetPos,
								offsetRot = buildingRubbleSaveData.offsetRot,
								variant = buildingRubbleSaveData.variant,
								isSquare = buildingRubbleSaveData.isSquare,
								logisticSaveData = buildingRubbleSaveData.logisticSaveData,
								sourcingLogisticBuildings = buildingRubbleSaveData.sourcingLogisticBuildings,
								cartRoutes = buildingRubbleSaveData.cartRoutes,
								settings = buildingRubbleSaveData.settings
							};
							obj.groupCells[i].Add(item);
						}
					}
				}
			}
			return obj;
		}
	}

	public static BuildingCollapseManager inst;

	public bool debug;

	public float gravity = 1.2f;

	[NonSerialized]
	public Rubble rPrefab;

	public ArrayExt<RubbleGroup>[] groupCells;

	public ArrayExt<CollapseEntry> toCollapse = new ArrayExt<CollapseEntry>(32);

	private ArrayExt<Cell> toDemolish = new ArrayExt<Cell>(32);

	private static List<Cell> tempCells = new List<Cell>(32);

	private static bool[] hasVisited;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		rPrefab = GameState.inst.GetPlaceableByUniqueName(World.rubbleName).GetComponent<Rubble>();
	}

	public void Init()
	{
		int num = World.inst.GridWidth * World.inst.GridHeight;
		if (groupCells == null || groupCells.Length != num)
		{
			groupCells = new ArrayExt<RubbleGroup>[num];
		}
		else
		{
			for (int i = 0; i < num; i++)
			{
				if (groupCells[i] != null)
				{
					groupCells[i].ClearFast();
				}
			}
		}
		if (hasVisited == null || hasVisited.Length != num)
		{
			hasVisited = new bool[num];
		}
		else
		{
			Util.Memset(hasVisited, 0);
		}
		for (int j = 0; j < toCollapse.Count; j++)
		{
			toCollapse.data[j].eInstance.stop(STOP_MODE.IMMEDIATE);
			toCollapse.data[j].eInstance.release();
		}
		toCollapse.Clear();
	}

	public void Collapse(Building b, bool doRubble = false, bool doAnimation = true)
	{
		CollapseInternal(b, -1, doRubble, doAnimation);
		if (b.categoryHash != World.houseCategoryHash)
		{
			return;
		}
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			for (int num = cell.OccupyingStructure.Count - 1; num >= 0; num--)
			{
				if (cell.OccupyingStructure[num].CanSnapInside(b))
				{
					CollapseInternal(cell.OccupyingStructure[num], Mathff.Max(1, num), doRubble, doAnimation);
				}
			}
		});
	}

	private void CollapseInternal(Building b, int idx = -1, bool doRubble = false, bool doAnimation = true)
	{
		if (b.isDemolishing || b.uniqueNameHash == World.rubbleHash)
		{
			return;
		}
		World.inst.MovePeopleInsideToGround(b);
		if (doRubble)
		{
			if (b.uniqueNameHash != World.damHash && b.uniqueNameHash != World.spilloverHash && b.uniqueNameHash != World.stoneBridgeHash && b.uniqueNameHash != World.woodBridgeHash)
			{
				Vector3 position = b.transform.position;
				Transform offset = b.GetOffset();
				RubbleGroup rGroup = default;
				rGroup.guid = b.guid;
				if (LogisticsManager.inst.logistics.TryGetValue(b.guid, out var value))
				{
					LogisticsManager.LogisticsManagerSaveData.LogisticsForStorageData logisticsForStorageData = new LogisticsManager.LogisticsManagerSaveData.LogisticsForStorageData();
					logisticsForStorageData.requestAmt = new SerializableDictionary<int, int>(value.requestAmt);
					logisticsForStorageData.targetBuildingGuid = value.targetBuilding.guid;
					logisticsForStorageData.sourceBuildingGuids = new Guid[value.sourceBuildings.Count];
					for (int i = 0; i < value.sourceBuildings.Count; i++)
					{
						logisticsForStorageData.sourceBuildingGuids[i] = value.sourceBuildings[i].guid;
					}
					rGroup.logisticSaveData = logisticsForStorageData;
					rGroup.sourcingLogisticBuildings = new List<Guid>(16);
					foreach (KeyValuePair<Guid, LogisticsManager.LogisticsForStorage> logistic in LogisticsManager.inst.logistics)
					{
						for (int j = 0; j < logistic.Value.sourceBuildings.Count; j++)
						{
							if (logistic.Value.sourceBuildings[j].guid == b.guid)
							{
								rGroup.sourcingLogisticBuildings.Add(logistic.Value.targetBuilding.guid);
								break;
							}
						}
					}
					rGroup.cartRoutes = new SerializableDictionary<Guid, List<LogisticsVehicle.LogisticsVehicleSaveData.RouteData>>();
					for (int k = 0; k < LogisticsManager.inst.logisticCarts.Count; k++)
					{
						LogisticsVehicle component = LogisticsManager.inst.logisticCarts.data[k].GetComponent<LogisticsVehicle>();
						for (int l = 0; l < component.routes.Count; l++)
						{
							LogisticRoute logisticRoute = component.routes[l];
							if (logisticRoute.sourceBuilding == b || logisticRoute.targetBuilding == b)
							{
								if (!rGroup.cartRoutes.ContainsKey(component.guid))
								{
									rGroup.cartRoutes.Add(component.guid, new List<LogisticsVehicle.LogisticsVehicleSaveData.RouteData>());
								}
								rGroup.cartRoutes[component.guid].Add(new LogisticsVehicle.LogisticsVehicleSaveData.RouteData
								{
									source = logisticRoute.sourceBuilding.guid,
									target = logisticRoute.targetBuilding.guid
								});
							}
						}
					}
					for (int m = 0; m < ShipSystem.inst.ships.Count; m++)
					{
						ShipBase shipBase = ShipSystem.inst.ships.data[m];
						if (shipBase.type != ShipBase.ShipType.Transport)
						{
							continue;
						}
						LogisticsVehicle component2 = shipBase.GetComponent<LogisticsVehicle>();
						for (int n = 0; n < component2.routes.Count; n++)
						{
							LogisticRoute logisticRoute2 = component2.routes[n];
							if (logisticRoute2.sourceBuilding == b || logisticRoute2.targetBuilding == b)
							{
								if (!rGroup.cartRoutes.ContainsKey(component2.guid))
								{
									rGroup.cartRoutes.Add(component2.guid, new List<LogisticsVehicle.LogisticsVehicleSaveData.RouteData>());
								}
								rGroup.cartRoutes[component2.guid].Add(new LogisticsVehicle.LogisticsVehicleSaveData.RouteData
								{
									source = logisticRoute2.sourceBuilding.guid,
									target = logisticRoute2.targetBuilding.guid
								});
							}
						}
					}
				}
				rGroup.x = Mathf.RoundToInt(position.x);
				rGroup.z = Mathf.RoundToInt(position.z);
				rGroup.y = position.y;
				rGroup.sizeX = (int)b.size.x;
				rGroup.sizeZ = (int)b.size.z;
				rGroup.uniqueName = b.UniqueName;
				rGroup.offsetPos = offset.position;
				rGroup.offsetRot = offset.rotation;
				rGroup.variant = ((b.variants == null) ? (-1) : b.selectedVariant);
				rGroup.isSquare = rGroup.sizeX == rGroup.sizeZ;
				rGroup.settings = Building.BuildingSaveData.PackComponents(b, (Component c) => c is IRubbleSettings);
				b.ForEachTileInBounds((int x, int z, Cell cell) =>
				{
					ArrayExt<RubbleGroup>[] array = groupCells;
					int index = cell.index;
					if (array[index] == null)
					{
						array[index] = new ArrayExt<RubbleGroup>(8);
					}
					if (idx == -1)
					{
						groupCells[cell.index].Add(rGroup);
					}
					else
					{
						groupCells[cell.index].Insert(idx, rGroup);
					}
					Building building = TryAddRubble(cell, doAnimation);
					if (building != null)
					{
						Util.SetActive(building.GetOffset(), !doAnimation);
					}
				});
			}
			else
			{
				b.ForEachTileInBounds((int x, int z, Cell cell) =>
				{
					Building building = TryAddRubble(cell, doAnimation);
					if (building != null)
					{
						Util.SetActive(building.GetOffset(), !doAnimation);
					}
				});
			}
			b.GruesomeVillagerDeath();
		}
		if (doAnimation)
		{
			b.GetRenderersYMinMax(out var minY, out var maxY);
			EventInstance eventInstance = RuntimeManager.CreateInstance(b.onBuildingDestroyedHeadEvent);
			EventInstance eInstance = RuntimeManager.CreateInstance(b.onBuildingDestroyedTailEvent);
			ATTRIBUTES_3D attributes = b.Center().To3DAttributes();
			eventInstance.set3DAttributes(attributes);
			eventInstance.start();
			eInstance.set3DAttributes(attributes);
			eInstance.start();
			toCollapse.Add(new CollapseEntry
			{
				b = b,
				velocity = 0f,
				maxHeight = maxY,
				minHeight = minY,
				eInstance = eInstance
			});
			Home component3 = b.GetComponent<Home>();
			if (component3 != null)
			{
				component3.ClearResidence();
			}
		}
		else
		{
			World.inst.Unplace(b);
		}
		b.isDemolishing = true;
	}

	public void CollapseCell(Cell c, bool doRubble = true, bool doAnimation = true)
	{
		if (c == null)
		{
			return;
		}
		toDemolish.ClearFast();
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			Building building = c.OccupyingStructure[i];
			if (building.uniqueNameHash == World.rubbleHash || building.uniqueNameHash == World.stoneBridgeHash || building.uniqueNameHash == World.woodBridgeHash)
			{
				continue;
			}
			building.ForEachTileInBounds((int x, int z, Cell item) =>
			{
				if (!toDemolish.Contains(item))
				{
					toDemolish.Add(item);
				}
			});
		}
		for (int num = 0; num < toDemolish.Count; num++)
		{
			Cell cell = toDemolish.data[num];
			for (int num2 = 0; num2 < cell.OccupyingStructure.Count; num2++)
			{
				Building building2 = cell.OccupyingStructure[num2];
				if (building2.uniqueNameHash != World.rubbleHash && building2.uniqueNameHash != World.stoneBridgeHash && building2.uniqueNameHash != World.woodBridgeHash)
				{
					CollapseInternal(cell.OccupyingStructure[num2], num2, doRubble, doAnimation);
				}
			}
		}
	}

	private Building TryAddRubble(Cell c, bool doHideRubble)
	{
		if (c.landMassIdx == -1)
		{
			return null;
		}
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (c.OccupyingStructure[i].uniqueNameHash == World.rubbleHash)
			{
				return null;
			}
		}
		Rubble rubble = UnityEngine.Object.Instantiate(rPrefab);
		Vector3 position = c.Position;
		for (int j = 0; j < c.OccupyingStructure.Count; j++)
		{
			Building building = c.OccupyingStructure[j];
			if (building.uniqueNameHash == World.stoneBridgeHash || building.uniqueNameHash == World.woodBridgeHash)
			{
				float y = building.GetComponent<Bridge>().walkPlaneT.position.y;
				if (position.y < y)
				{
					position.y = y;
				}
			}
		}
		rubble.transform.position = c.Position;
		Building component = rubble.GetComponent<Building>();
		component.Init();
		World.inst.Place(component);
		return component;
	}

	public void CancelCollapse(Building b)
	{
		for (int i = 0; i < toCollapse.Count; i++)
		{
			if (toCollapse.data[i].b == b)
			{
				toCollapse.data[i].eInstance.stop(STOP_MODE.IMMEDIATE);
				toCollapse.data[i].eInstance.release();
				toCollapse.RemoveAt(i);
				break;
			}
		}
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		float deltaTime = Time.deltaTime;
		bool paused = TimeManager.inst.IsPaused();
		for (int num = toCollapse.Count - 1; num >= 0; num--)
		{
			CollapseEntry collapseEntry = toCollapse.data[num];
			collapseEntry.eInstance.setPaused(paused);
			if (collapseEntry.b == null)
			{
				UnityEngine.Debug.LogError("Building Is Null But In ToCollapse Animation!");
			}
			else
			{
				collapseEntry.velocity += gravity * deltaTime;
				Transform offset = collapseEntry.b.GetOffset();
				Vector3 position = collapseEntry.b.transform.position;
				Vector3 position2 = offset.position;
				float interpolatedHeight = TerrainGen.inst.GetInterpolatedHeight(position2);
				int num2 = Mathf.FloorToInt(position.y - position2.y);
				position2.y -= collapseEntry.velocity * deltaTime;
				int num3 = Mathf.FloorToInt(position.y - position2.y);
				if (num2 != num3)
				{
					collapseEntry.velocity *= 0.25f;
					collapseEntry.b.ForEachTileInBounds((int x, int z, Cell cell) =>
					{
						EffectsMan.inst.BuildingCollapseExplode.CreateAndPlay(cell.Center3D);
					});
				}
				offset.position = position2;
				if (position2.y + (collapseEntry.maxHeight - collapseEntry.minHeight) < interpolatedHeight + 0.1f)
				{
					collapseEntry.b.ForEachTileInBounds((int x, int z, Cell cell) =>
					{
						EffectsMan.inst.BuildPuff.CreateAndPlay(cell.Center3D);
						Building building = cell.StructureFind(World.rubbleHash);
						if (building != null)
						{
							Util.SetActive(building.GetOffset(), active: true);
						}
					});
					if (collapseEntry.b.UniqueName == World.woodcastleblockName)
					{
						EffectsMan.inst.WoodBuildingCollapseExplode.CreateAndPlay(collapseEntry.b.Center());
					}
					else
					{
						EffectsMan.inst.BuildingCollapseExplode.CreateAndPlay(collapseEntry.b.Center());
					}
					collapseEntry.eInstance.setParameterByName("parameter:/BuildingDestroyFinished", 0f);
					World.inst.Unplace(collapseEntry.b);
					toCollapse.RemoveAt(num);
				}
				else if (position2.y + (collapseEntry.maxHeight - collapseEntry.minHeight) < interpolatedHeight + 0.35f)
				{
					collapseEntry.eInstance.setParameterByName("parameter:/BuildingDestroyFinished", 0f);
				}
			}
		}
	}

	public static void ClearRubble(Cell c)
	{
		if (c == null)
		{
			return;
		}
		ArrayExt<RubbleGroup> arrayExt = inst.groupCells[c.index];
		if (arrayExt == null || arrayExt.Count == 0)
		{
			Building building = c.StructureFind(World.rubbleHash);
			if (building != null)
			{
				World.inst.VanishBuilding(building);
			}
			return;
		}
		RecurseGroups(arrayExt, tempCells);
		for (int i = 0; i < tempCells.Count; i++)
		{
			Cell cell = tempCells[i];
			if (cell != null)
			{
				inst.groupCells[cell.index].ClearFast();
				Building building2 = cell.StructureFind(World.rubbleHash);
				if (building2 != null)
				{
					World.inst.VanishBuilding(building2);
				}
			}
		}
		tempCells.Clear();
		Util.Memset(hasVisited, 0);
	}

	private static void RecurseGroups(ArrayExt<RubbleGroup> rGroups, List<Cell> cells)
	{
		for (int i = 0; i < rGroups.Count; i++)
		{
			RubbleGroup rubbleGroup = rGroups.data[i];
			Vector3 vector = default;
			for (int j = 0; j < rubbleGroup.sizeX; j++)
			{
				for (int k = 0; k < rubbleGroup.sizeZ; k++)
				{
					vector.x = j;
					vector.z = k;
					if (!rubbleGroup.isSquare)
					{
						vector = rubbleGroup.offsetRot * vector;
					}
					int x = Mathf.RoundToInt((float)rubbleGroup.x + vector.x);
					int z = Mathf.RoundToInt((float)rubbleGroup.z + vector.z);
					Cell cellData = World.inst.GetCellData(x, z);
					if (cellData != null && !hasVisited[cellData.index])
					{
						hasVisited[cellData.index] = true;
						cells.Add(cellData);
						RecurseGroups(inst.groupCells[cellData.index], cells);
					}
				}
			}
		}
	}

	public static bool CollectGroups(Cell c, ref List<RubbleGroup> totalGroups, ref Dictionary<string, int> map, ref List<Building> totalRubble)
	{
		if (c == null || inst.groupCells[c.index] == null || inst.groupCells[c.index].Count == 0)
		{
			return false;
		}
		Util.Memset(hasVisited, 0);
		RecurseGroups(inst.groupCells[c.index], ref totalGroups, ref map, ref totalRubble);
		Util.Memset(hasVisited, 0);
		return true;
	}

	private static void RecurseGroups(ArrayExt<RubbleGroup> currGroups, ref List<RubbleGroup> totalGroups, ref Dictionary<string, int> map, ref List<Building> totalRubble)
	{
		for (int i = 0; i < currGroups.Count; i++)
		{
			RubbleGroup item = currGroups.data[i];
			if (totalGroups.Contains(item))
			{
				continue;
			}
			totalGroups.Add(item);
			if (!map.TryAdd(item.uniqueName, 1))
			{
				map[item.uniqueName]++;
			}
			Vector3 vector = default;
			for (int j = 0; j < item.sizeX; j++)
			{
				for (int k = 0; k < item.sizeZ; k++)
				{
					vector.x = j;
					vector.z = k;
					if (!item.isSquare)
					{
						vector = item.offsetRot * vector;
					}
					int x = Mathf.RoundToInt((float)item.x + vector.x);
					int z = Mathf.RoundToInt((float)item.z + vector.z);
					Cell cellData = World.inst.GetCellData(x, z);
					if (cellData != null && !hasVisited[cellData.index])
					{
						hasVisited[cellData.index] = true;
						Building building = cellData.StructureFind(World.rubbleHash);
						if (building != null)
						{
							totalRubble.Add(building);
						}
						RecurseGroups(inst.groupCells[cellData.index], ref totalGroups, ref map, ref totalRubble);
					}
				}
			}
		}
	}

	public static Building RebuildGroups(List<RubbleGroup> rGroups)
	{
		Building building = null;
		for (int i = 0; i < rGroups.Count; i++)
		{
			RubbleGroup rubbleGroup = rGroups[i];
			building = UnityEngine.Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(rubbleGroup.uniqueName));
			building.transform.position = new Vector3(rubbleGroup.x, rubbleGroup.y, rubbleGroup.z);
			building.Init();
			building.guid = rubbleGroup.guid;
			if (rubbleGroup.variant != -1)
			{
				building.SetVariant(rubbleGroup.variant);
			}
			Transform offset = building.GetOffset();
			offset.position = rubbleGroup.offsetPos;
			if (!rubbleGroup.isSquare || building.RotateRandomY == 0f)
			{
				offset.rotation = rubbleGroup.offsetRot;
			}
			if (!Creative.inst.IsCreativeOptionOn(11))
			{
				RuntimeManager.PlayOneShot(building.onBuildingPlacedEvent, building.Center());
			}
			World.inst.Place(building);
			if (rubbleGroup.settings != null)
			{
				Building.BuildingSaveData.ApplyComponentSaveData(building, rubbleGroup.settings);
			}
			if (rubbleGroup.logisticSaveData == null)
			{
				continue;
			}
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(building);
			logisticsForBuilding.requestAmt = rubbleGroup.logisticSaveData.requestAmt;
			logisticsForBuilding.targetBuilding = building;
			for (int j = 0; j < rubbleGroup.logisticSaveData.sourceBuildingGuids.Length; j++)
			{
				Building building2 = Player.inst.GetBuilding(rubbleGroup.logisticSaveData.sourceBuildingGuids[j]);
				if (building2 != null)
				{
					logisticsForBuilding.sourceBuildings.Add(building2);
				}
			}
			for (int k = 0; k < rubbleGroup.sourcingLogisticBuildings.Count; k++)
			{
				Building building3 = Player.inst.GetBuilding(rubbleGroup.sourcingLogisticBuildings[k]);
				if (!(building3 == null))
				{
					LogisticsManager.inst.GetLogisticsForBuilding(building3).sourceBuildings.Add(building);
				}
			}
			foreach (KeyValuePair<Guid, List<LogisticsVehicle.LogisticsVehicleSaveData.RouteData>> cartRoute in rubbleGroup.cartRoutes)
			{
				_ = cartRoute.Value;
				LogisticsVehicle logisticVehicleByGuid = LogisticsManager.inst.GetLogisticVehicleByGuid(cartRoute.Key);
				if (logisticVehicleByGuid == null)
				{
					continue;
				}
				for (int l = 0; l < cartRoute.Value.Count; l++)
				{
					LogisticsVehicle.LogisticsVehicleSaveData.RouteData routeData = cartRoute.Value[l];
					Building building4 = Player.inst.GetBuilding(routeData.target);
					if (!(building4 == null))
					{
						Building building5 = Player.inst.GetBuilding(routeData.source);
						if (!(building5 == null))
						{
							logisticVehicleByGuid.AddRoute(building4, building5);
						}
					}
				}
			}
		}
		return building;
	}

	public static ResourceAmount GetTotalCost(int landmass, ref Dictionary<string, int> map)
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		foreach (KeyValuePair<string, int> item in map)
		{
			Building placeableByUniqueName = GameState.inst.GetPlaceableByUniqueName(item.Key);
			resourceAmount.Add(placeableByUniqueName.GetCost(landmass) * item.Value);
		}
		return resourceAmount;
	}
}
