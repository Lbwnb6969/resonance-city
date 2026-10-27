using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Interface;
using Code;
using I2.Loc;
using UnityEngine;

public class FishingHut : Tickable, IResourceStorage, IResourceStorageBase, IOutputInfo, IResourceProviderContainer, IOverlayUser, IProductionInfo, IWorkerUIDisplay
{
	[Serializable]
	public class FishingHutSaveData : SaveClass<FishingHut, FishingHutSaveData>
	{
		private int fishStored;

		private SerializableVector3 shipPos;

		private FishingShip.ShipData shipData;

		private int lastYearCatch;

		private int currYearCatch;

		public override FishingHutSaveData Pack(FishingHut obj)
		{
			currYearCatch = obj.currYearCatch;
			lastYearCatch = obj.lastYearCatch;
			fishStored = obj.stack.Count();
			if (obj.b.IsBuilt())
			{
				shipPos = obj.ship.GetComponent<ShipBase>().GetPos();
				shipData = obj.fishingShip.GetShipData();
			}
			return this;
		}

		public override FishingHut Unpack(FishingHut obj)
		{
			obj.currYearCatch = currYearCatch;
			obj.lastYearCatch = lastYearCatch;
			obj.stack.Add(fishStored);
			obj.RefreshFishCells();
			if (obj.b.IsBuilt())
			{
				obj.InitBoat();
				obj.ship.GetComponent<ShipBase>().SetPos(shipPos);
				shipData.status = FishingShip.Status.WaitAtHutNoEmployees;
				obj.fishingShip.SetFromShipData(shipData);
			}
			return obj;
		}
	}

	public Sprite fishIcon;

	private ResourceAmount yResult = new ResourceAmount();

	private BuildingProductionUI.CustomProductionItem[] customProductionItems = new BuildingProductionUI.CustomProductionItem[1];

	private bool halted;

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	[NonSerialized]
	public GraphicalResourceStack stack;

	private Building b;

	private EventHandler<SeasonEventData> eventHandler;

	public GraphicalResourceStack stackVariant1;

	public GraphicalResourceStack stackVariant2;

	private int validPositions;

	[NonSerialized]
	public List<int> dockPositionPenalties = new List<int>();

	[NonSerialized]
	public List<Cell> dockPositions = new List<Cell>();

	private const int frameSpread = 30;

	private int checkDockPosFrame = SRand.srand.Next(0, 30);

	public int Radius = 8;

	private GameObject ship;

	private FishingShip fishingShip;

	private bool noValidPositions;

	private int lastYearCatch;

	private int currYearCatch;

	private ArrayExt<FishSystem.FishCell> fishCells = new ArrayExt<FishSystem.FishCell>(100);

	private static ArrayExt<Cell> openset = new ArrayExt<Cell>(100);

	private static bool[] hasVisited = null;

	public bool OverlayWhenPlacing => true;

	public bool OverlayWhenSelected => true;

	private void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
	}

	private void OnDestroy()
	{
		if (ship != null)
		{
			UnityEngine.Object.Destroy(ship);
		}
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
		Broadcast.SeasonEvent.Unlisten(eventHandler);
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		bool foundFish = false;
		World.inst.ForEachTileTouchingRadius(b.Center(), Radius, (int subx, int subz, Cell c) =>
		{
			foundFish |= FishSystem.inst.fishCells[subz * World.inst.GridWidth + subx].owners.Count > 0;
		});
		if (!foundFish)
		{
			validationResult = PlacementValidationResult.NotNearFish;
		}
		Vector3 worldPos = b.Center() + b.transform.GetChild(0).forward;
		if (World.inst.GetCellDataClamped(worldPos).Type != TerrainType.Water)
		{
			validationResult = PlacementValidationResult.TooFarFromWater;
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b.IsBuilt() && b.IsOpen())
		{
			if (currFrame % 30 == checkDockPosFrame)
			{
				ValidateDockPositions();
			}
			noValidPositions = validPositions <= 0;
			CheckProductionPipeline();
		}
	}

	private void OnInit()
	{
		customProductionItems[0] = new BuildingProductionUI.CustomProductionItem
		{
			icon = fishIcon,
			type = BuildingProductionUI.CustomProductionItem.CustomType.Infinite,
			locTerm = "custom_production_cost_fishinghut",
			hideBottom = true
		};
		if (b.selectedVariant == 1 || b.selectedVariant == 2)
		{
			UnityEngine.Object.Destroy(stackVariant1.gameObject);
			stack = stackVariant2;
		}
		else
		{
			UnityEngine.Object.Destroy(stackVariant2.gameObject);
			stack = stackVariant1;
		}
		cullingGroup = new CullingGroup();
		cullingGroup.onStateChanged = OnStateChanged;
		cullingGroup.SetBoundingSpheres(spheres);
		cullingGroup.SetBoundingSphereCount(1);
		cullingGroup.targetCamera = Cam.inst.cam;
		eventHandler = Broadcast.SeasonEvent.Listen(Inst_OnSeasonChange);
	}

	private void OnStateChanged(CullingGroupEvent evt)
	{
		stack.StateChangedMethod(evt);
	}

	private void Inst_OnSeasonChange(object sender, SeasonEventData e)
	{
		if (e.SeasonDefinition.id == 3)
		{
			lastYearCatch = currYearCatch;
			currYearCatch = 0;
		}
	}

	private void OnBuilt()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
		RefreshFishCells();
		Vector3 vector = b.Center();
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		int num = Mathff.Clamp(minX - Radius, 0, World.inst.GridWidth - 1);
		int num2 = Mathff.Clamp(maxX + Radius, 0, World.inst.GridWidth - 1);
		int num3 = Mathff.Clamp(minZ - Radius, 0, World.inst.GridHeight - 1);
		int num4 = Mathff.Clamp(maxZ + Radius, 0, World.inst.GridHeight - 1);
		Cell[] cells = new Cell[12];
		Cell cell = null;
		int num5 = -1;
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num; j <= num2; j++)
			{
				int num6 = 0;
				Cell cellData = World.inst.GetCellData(j, i);
				if (cellData.Type != TerrainType.Water)
				{
					continue;
				}
				World.inst.GetNeighborCellsExtendedPlus(cellData, ref cells);
				for (int k = 0; k < cells.Length; k++)
				{
					if (cells[k] != null && cells[k].Type == TerrainType.Water)
					{
						num6++;
						if (cells[k].deepWater)
						{
							num6 += 2;
						}
					}
				}
				num6 += (int)((float)Radius - Mathff.DistXZ(cellData.Center2D, vector)) * 4;
				if (num6 > num5)
				{
					cell = cellData;
					num5 = num6;
				}
			}
		}
		if (cell != null)
		{
			InitBoat();
			Vector3 center2D = cell.Center2D;
			center2D.y = Water.inst.transform.position.y;
			ship.GetComponent<ShipBase>().SetPos(center2D);
			fishingShip.SetStatus(FishingShip.Status.WaitAtHutNoEmployees);
		}
	}

	private void RefreshFishCells()
	{
		Vector3 a = b.Center();
		int radius = Radius;
		openset.ClearFast();
		fishCells.ClearFast();
		int num = World.inst.GridWidth * World.inst.GridHeight;
		if (hasVisited == null || hasVisited.Length != num)
		{
			hasVisited = new bool[num];
		}
		else
		{
			Util.Memset(hasVisited, 0);
		}
		int gridWidth = World.inst.GridWidth;
		int num2 = radius * radius;
		Cell cell = b.GetCell();
		AddCardinalToOpenset(ref openset, cell);
		while (openset.Count > 0)
		{
			Cell cell2 = openset.PopLast();
			if (cell2 != null && !hasVisited[cell2.index])
			{
				hasVisited[cell2.index] = true;
				Vector3 center2D = cell2.Center2D;
				if (!(Mathff.DistSqrdXZ(a, center2D) > (float)num2) && ValidCell(cell2))
				{
					fishCells.Add(FishSystem.inst.fishCells[cell2.z * gridWidth + cell2.x]);
					AddCardinalToOpenset(ref openset, cell2);
				}
			}
		}
	}

	private void AddCardinalToOpenset(ref ArrayExt<Cell> openset, Cell currCell)
	{
		openset.Add(World.inst.GetCellData(currCell.x + 1, currCell.z));
		openset.Add(World.inst.GetCellData(currCell.x, currCell.z + 1));
		openset.Add(World.inst.GetCellData(currCell.x - 1, currCell.z));
		openset.Add(World.inst.GetCellData(currCell.x, currCell.z - 1));
	}

	private void OnFinishedLoad()
	{
		spheres[0] = new BoundingSphere(b.Center(), 1.5f);
	}

	private void OnDemolished()
	{
		if (stack.Count() > 0)
		{
			FreeResourceManager.inst.GetAutoStackFor(stack.resourceID, stack.Count(), b.GetCell().Position);
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < 2; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FishermanJob)))
			{
				b.SetAndAddJob(i, new FishermanJob(b, fishingShip, fishingShip.anchors[i]));
			}
			b.jobs[i].ManualFreetime = true;
		}
		if (!b.VerifyJobIs(2, typeof(DeliveryJob)))
		{
			b.SetAndAddJob(2, new DeliveryJob(b, stack));
		}
		(b.jobs[2] as DeliveryJob).provider = stack;
	}

	public bool HasFisherman()
	{
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i].HasEmployee())
			{
				return true;
			}
		}
		return false;
	}

	public bool TryBoardingFisherman()
	{
		if (!HasSpaceForFish())
		{
			return false;
		}
		bool result = false;
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is FishermanJob fishermanJob && !(fishermanJob.Employee == null) && fishermanJob.IsFisherReadyForBoarding())
			{
				fishermanJob.BoardFishingShip();
				result = true;
			}
		}
		return result;
	}

	public void UnloadFisherman()
	{
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is FishermanJob fishermanJob && fishermanJob.HasEmployee() && fishermanJob.status == FishermanJob.Status.Fishing)
			{
				fishermanJob.UnboardFishingShip();
			}
		}
	}

	public bool IsFishermanRequiringUnload()
	{
		if (b.DuringWorkHours(0f) || !b.isDemolishing)
		{
			return false;
		}
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is FishermanJob fishermanJob && fishermanJob.HasEmployee() && fishermanJob.status == FishermanJob.Status.Fishing)
			{
				return true;
			}
		}
		return false;
	}

	public bool IsFishermanRequiringLoading()
	{
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is FishermanJob fishermanJob && fishermanJob.HasEmployee() && fishermanJob.status == FishermanJob.Status.WaitingToLoad)
			{
				return true;
			}
		}
		return false;
	}

	private void InitDeliveryJob(DeliveryJob j)
	{
		j.provider = stack;
	}

	public void CheckProductionPipeline()
	{
		halted = stack.Count() >= stack.MaxCapacity();
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			Dock.FillDockPositions(b, dockPositions);
			b.thought.pos = b.Center();
			ValidateDockPositions();
		}
	}

	public void AddFish(int count)
	{
		int x = (int)b.Center().x;
		int z = (int)b.Center().z;
		int num = 0;
		CellProductionInfluence cellProductionInfluenceDataClamped = World.inst.GetCellProductionInfluenceDataClamped(x, z);
		for (int i = 0; i < cellProductionInfluenceDataClamped.radiusBonusesBuilding.Count; i++)
		{
			if (cellProductionInfluenceDataClamped.radiusBonusesBuilding[i].GetBonus() > num)
			{
				num = cellProductionInfluenceDataClamped.radiusBonusesBuilding[i].GetBonus();
			}
		}
		count += num;
		ResourceTextStackManager.inst.ShowResourceAmount(this, b.Center(), 8, count);
		stack.Add(count);
		ResourceStatistics.AddProduction(LandMass(), b.UniqueName, 8, count);
		currYearCatch += count;
	}

	private void InitBoat()
	{
		ship = UnityEngine.Object.Instantiate(ShipSystem.inst.fishingShipPrefab).gameObject;
		fishingShip = ship.GetComponent<FishingShip>();
		fishingShip.Init(this);
	}

	public bool HasSpaceForFish()
	{
		return stack.Count() < stack.MaxCapacity();
	}

	private void ValidateDockPositions()
	{
		int landmass = b.LandMass();
		validPositions = 0;
		for (int i = 0; i < dockPositions.Count; i++)
		{
			LandmassOwner landmassOwner = World.GetLandmassOwner(landmass);
			if (!PathCell.GetBlocksWaterPath(World.inst.GetPathCell(dockPositions[i]), landmassOwner.teamId))
			{
				validPositions++;
			}
		}
	}

	void IResourceStorageBase.Deposit(ref ResourceAmount resources)
	{
	}

	int IResourceStorageBase.SpaceAvailable(int resourceID)
	{
		return 0;
	}

	Vector3 IResourceStorageBase.DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	int IResourceStorage.MaxStorageFor(int resourceID)
	{
		return stackVariant1.MaxCapacity();
	}

	int IResourceStorage.StoredPublicResources(int resourceID)
	{
		if (resourceID != stack.resourceID)
		{
			return 0;
		}
		return stack.AvailableAmount();
	}

	bool IResourceStorage.AcceptsType(int resourceID)
	{
		return false;
	}

	bool IResourceStorage.StoresTypePublic(int resourceID)
	{
		return resourceID == 8;
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		stack.Remove(amount.Get(stack.resourceID));
	}

	public int LandMass()
	{
		return b.LandMass();
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		FreeResourceManager.inst.AddResourceProviderChecked(stack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(stack);
	}

	ResourceAmount IProductionInfo.GetCost()
	{
		return null;
	}

	int IProductionInfo.GetResult(int rID)
	{
		if (rID != 8)
		{
			return 0;
		}
		if (!(fishingShip == null))
		{
			return fishingShip.fishStack.childCount;
		}
		return 1;
	}

	bool IProductionInfo.ShowResultStorage()
	{
		return true;
	}

	int IProductionInfo.GetOutputStorage(int rID)
	{
		if (rID != stack.resourceID)
		{
			return 0;
		}
		return stack.Count();
	}

	int IProductionInfo.GetOutputMaxStorage(int rID)
	{
		if (rID != stack.resourceID)
		{
			return 0;
		}
		return stack.MaxCapacity();
	}

	public int GetInputMaxStorage(int rID)
	{
		return 0;
	}

	public int GetInputStorage(int rID)
	{
		return 0;
	}

	public BuildingProductionUI.CustomProductionItem[] GetCustomCost()
	{
		return customProductionItems;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomResult()
	{
		return null;
	}

	float IProductionInfo.GetProgress()
	{
		return (float)fishingShip.fishCount / (float)fishingShip.fishStack.childCount;
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		return string.Format(ScriptLocalization.workerui_productionui_customtext_currentyear, currYearCatch) + Environment.NewLine + string.Format(ScriptLocalization.workerui_productionui_customtext_previousyear, lastYearCatch);
	}

	string IOutputInfo.GetError()
	{
		if (fishingShip.pathObstructed)
		{
			return ScriptLocalization.FishingPathObstructed;
		}
		if (!HasSpaceForFish())
		{
			return ScriptLocalization.FishHutNoMoreRoom;
		}
		if (noValidPositions)
		{
			return ScriptLocalization.DockNoPositionsError;
		}
		return null;
	}

	public void DrawOverlay(Vector3 origin)
	{
		Color col = new Color(0.3f, 0.3f, 1f, 0.2f);
		TerrainGen.inst.ClearOverlay(updateToo: false);
		int num = (int)Mathf.Max(Mathf.Floor(origin.x - (float)Radius), 0f);
		int num2 = (int)Mathf.Max(Mathf.Floor(origin.z - (float)Radius), 0f);
		int num3 = (int)Mathf.Min(Mathf.Ceil(origin.x + (float)Radius), World.inst.GridWidth - 1);
		int num4 = (int)Mathf.Min(Mathf.Ceil(origin.z + (float)Radius), World.inst.GridHeight - 1);
		for (int i = num; i <= num3; i++)
		{
			for (int j = num2; j <= num4; j++)
			{
				Cell cellData = World.inst.GetCellData(i, j);
				if (cellData.Type == TerrainType.Water && cellData != null && World.inst.TileTouchingRadius(cellData, origin, Radius))
				{
					TerrainGen.inst.SetOverlayTileColor(i, j, col);
				}
			}
		}
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	public FishSystem.FishCell GetFishingSpot()
	{
		if (fishCells.Count == 0)
		{
			return null;
		}
		FishSystem.FishCell fishCell = null;
		int num = 10;
		do
		{
			fishCell = fishCells.RandomElement();
			num--;
		}
		while ((fishCell.owners.Count == 0 || !ValidCell(fishCell.x, fishCell.z)) && num > 0);
		return fishCell;
	}

	public static bool ValidCell(Cell cell)
	{
		if (cell.Type == TerrainType.Water && cell.SubStructure.Count == 0)
		{
			return cell.OccupyingStructure.Count == 0;
		}
		return false;
	}

	public static bool ValidCell(int x, int z)
	{
		return ValidCell(World.inst.GetCellData(x, z));
	}

	internal string GetPlacementInfo(out int okLevel)
	{
		int num = 0;
		int num2 = 0;
		RefreshFishCells();
		for (int i = 0; i < fishCells.Count; i++)
		{
			if (fishCells.data[i].baseProbability > 0f)
			{
				num++;
			}
			num += fishCells.data[i].owners.Count;
			num2 += 3;
		}
		float num3 = (float)num / (float)num2;
		if (num3 > 0.5f)
		{
			okLevel = 2;
			return ScriptLocalization.PVRGoodFishingYield;
		}
		if (num3 > 0.2f)
		{
			okLevel = 1;
			return ScriptLocalization.PVRFairFishingYield;
		}
		okLevel = 0;
		return ScriptLocalization.PVRPoorFishingYield;
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
