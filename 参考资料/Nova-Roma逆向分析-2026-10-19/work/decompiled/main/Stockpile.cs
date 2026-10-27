using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Stockpile : Tickable, IResourceStorage, IResourceStorageBase, IResourceProvider, IResourceOrderable, IStorageInfo, IOutputInfo, IWorkerUIDisplay
{
	[Serializable]
	public struct ResourceOverFlowCategory
	{
		public int rID;

		public GameObject[] objs;
	}

	[Serializable]
	public class StockpileSaveData : SaveClass<Stockpile, StockpileSaveData>
	{
		public int[] resourceGrid;

		public int[] stackCounts;

		public bool[] playerSet;

		public bool allowCitizensToWithdrawal = true;

		public bool allowCitizensToDeposit = true;

		public bool isToggleDataSet;

		public override StockpileSaveData Pack(Stockpile s)
		{
			resourceGrid = new int[s.resourceGrid.Length];
			for (int i = 0; i < s.resourceGrid.Length; i++)
			{
				resourceGrid[i] = s.resourceGrid[i];
			}
			stackCounts = new int[s.stacks.Length];
			for (int j = 0; j < s.resourceGrid.Length; j++)
			{
				if (s.resourceGrid[j] != -1)
				{
					stackCounts[j] = s.stacks[j].Count();
				}
			}
			playerSet = new bool[s.playerSet.Length];
			for (int k = 0; k < s.resourceGrid.Length; k++)
			{
				playerSet[k] = s.playerSet[k];
			}
			allowCitizensToDeposit = s.allowCitizensToDeposit;
			allowCitizensToWithdrawal = s.allowCitizensToWithdrawal;
			isToggleDataSet = true;
			return this;
		}

		public override Stockpile Unpack(Stockpile s)
		{
			for (int i = 0; i < s.playerSet.Length && i < playerSet.Length; i++)
			{
				s.playerSet[i] = playerSet[i];
			}
			for (int j = 0; j < s.resourceGrid.Length && j < resourceGrid.Length; j++)
			{
				int num = resourceGrid[j];
				if (num != -1)
				{
					s.AddStackToGrid(j, num).Add(stackCounts[j]);
				}
			}
			s.TryDoFullCheck();
			s.SetupCullingGroup();
			if (isToggleDataSet)
			{
				s.allowCitizensToDeposit = allowCitizensToDeposit;
				s.allowCitizensToWithdrawal = allowCitizensToWithdrawal;
			}
			return s;
		}
	}

	public Transform[] stackPositions;

	public Transform DumpLocation;

	public int columnCount = 3;

	public int stackCount = 1;

	public int maxStackCount = 50;

	public bool doNotificationOnFull;

	public bool doOverflowVisuals;

	public bool allowCitizensToWithdrawal = true;

	public bool allowCitizensToDeposit = true;

	public List<ResourceOverFlowCategory> resourceOverflowGroups;

	[Header("Resource Settings")]
	[FreeResourceType]
	public int[] ValidResourceTypes = new int[4] { 2, 1, 5, 14 };

	private int[] GatherTypeOrder;

	private ArrayExt<int> IsTypeGatherable;

	private Dictionary<int, List<Villager>> villagerClaims = new Dictionary<int, List<Villager>>(32);

	public Stack[] stacks;

	public int[] resourceGrid;

	public bool[] playerSet;

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	private Building b;

	private int frameSpread = 50;

	private int updateFrame;

	private static int updateID;

	private ResourceAmount storage = new ResourceAmount();

	private ResourceAmount maxStorage = new ResourceAmount();

	public bool assignJobs = true;

	public GameObject roof;

	public bool showLockNonSurplus;

	public ResourceAmount DesiredResources { get; set; }

	string IOutputInfo.GetError()
	{
		bool flag = true;
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i] == null || stacks[i].Count() < stacks[i].MaxCapacity())
			{
				flag = false;
			}
		}
		if (flag)
		{
			return ScriptLocalization.StorageIsFull;
		}
		return null;
	}

	public void Awake()
	{
		b = GetComponent<Building>();
		if ((bool)roof)
		{
			roof.gameObject.SetActive(value: true);
		}
		GatherTypeOrder = new int[ValidResourceTypes.Length];
		IsTypeGatherable = new ArrayExt<int>(ValidResourceTypes.Length);
		for (int i = 0; i < ValidResourceTypes.Length; i++)
		{
			villagerClaims.Add(ValidResourceTypes[i], new List<Villager>(32));
			GatherTypeOrder[i] = ValidResourceTypes[i];
		}
		stacks = new Stack[stackCount];
		resourceGrid = new int[stackCount];
		playerSet = new bool[stackCount];
		for (int j = 0; j < resourceGrid.Length; j++)
		{
			resourceGrid[j] = -1;
		}
		if (doOverflowVisuals)
		{
			for (int k = 0; k < resourceOverflowGroups.Count; k++)
			{
				ResourceOverFlowCategory resourceOverFlowCategory = resourceOverflowGroups[k];
				for (int l = 0; l < resourceOverFlowCategory.objs.Length; l++)
				{
					Util.SetActive(resourceOverFlowCategory.objs[l], active: false);
				}
			}
		}
		updateFrame = updateID % frameSpread;
		updateID++;
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (updateFrame == currFrame % frameSpread && b.IsBuilt())
		{
			storage.Clear();
			maxStorage.Clear();
			for (int i = 0; i < ValidResourceTypes.Length; i++)
			{
				storage.Set(ValidResourceTypes[i], ((IResourceStorage)this).StoredPublicResources(ValidResourceTypes[i]));
				maxStorage.Set(ValidResourceTypes[i], ((IResourceStorage)this).MaxStorageFor(ValidResourceTypes[i]));
			}
			BuildGatherTypeOrder(LandMass(), IsTypeGatherable, ref GatherTypeOrder, storage, maxStorage, ValidResourceTypes);
		}
	}

	public void OnGridResourceChanged(int rID, int gridIdx)
	{
		if (rID == -1)
		{
			if ((bool)stacks[gridIdx])
			{
				if (stacks[gridIdx].Count() <= 0)
				{
					UnityEngine.Object.Destroy(stacks[gridIdx].gameObject);
					stacks[gridIdx] = null;
					resourceGrid[gridIdx] = -1;
				}
			}
			else
			{
				resourceGrid[gridIdx] = -1;
			}
			playerSet[gridIdx] = false;
			return;
		}
		Stack stack = stacks[gridIdx];
		if (stack != null)
		{
			if (stack.resourceID == rID)
			{
				playerSet[gridIdx] = true;
				return;
			}
			if (stack.Count() == 0)
			{
				UnityEngine.Object.Destroy(stack.gameObject);
				resourceGrid[gridIdx] = -1;
				stacks[gridIdx] = null;
			}
			else
			{
				bool flag = false;
				for (int i = 0; i < resourceGrid.Length; i++)
				{
					if (resourceGrid[i] == -1)
					{
						stacks[i] = stack;
						resourceGrid[i] = stack.resourceID;
						flag = true;
						break;
					}
				}
				if (!flag)
				{
					if (stack.Count() > 0)
					{
						Vector3 position = stack.transform.position;
						position.y = TerrainGen.inst.GetInterpolatedHeight(position);
						FreeResourceManager.inst.AddOrMakeAutoStackFor(stack.resourceID, stack.Count(), position);
					}
					UnityEngine.Object.Destroy(stack.gameObject);
				}
			}
		}
		AddStackToGrid(gridIdx, rID);
		playerSet[gridIdx] = true;
	}

	public void PurgeStockpile()
	{
		for (int i = 0; i < stackCount; i++)
		{
			if (stacks[i] != null)
			{
				if (stacks[i].Count() > 0)
				{
					Vector3 position = stacks[i].transform.position;
					position.y = TerrainGen.inst.GetInterpolatedHeight(position);
					FreeResourceManager.inst.AddOrMakeAutoStackFor(stacks[i].resourceID, stacks[i].Count(), position);
				}
				resourceGrid[i] = -1;
				playerSet[i] = false;
				stacks[i] = null;
			}
		}
	}

	private bool DefaultFilter(IResourceProvider x, int type)
	{
		if (!AcceptsType(type))
		{
			return false;
		}
		if (x.GetOwner() is Market)
		{
			return false;
		}
		if (x.GetType() != typeof(Mason))
		{
			return x.GetType() != typeof(Stockpile);
		}
		return false;
	}

	private void OnAddJobs(Building b)
	{
		if (!assignJobs)
		{
			return;
		}
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b));
			}
			InitJob(b.jobs[i] as FreeResourceGathererJob);
		}
	}

	private void InitJob(FreeResourceGathererJob j)
	{
		j.searchUpdate.SetFrameSpread(30);
		j.filterPrimary = DefaultFilter;
		j.meshType = VillagerSystem.MeshType.HandCart;
		j.bonusCarryCapacity = 3;
		j.typeOrder = GatherTypeOrder;
		j.searchRadius = 25f;
	}

	private void SetupCullingGroup()
	{
		spheres[0] = new BoundingSphere(b.Center(), 2f);
		cullingGroup = new CullingGroup();
		cullingGroup.onStateChanged = StateChangedMethod;
		cullingGroup.SetBoundingSpheres(spheres);
		cullingGroup.SetBoundingSphereCount(1);
		cullingGroup.targetCamera = Cam.inst.cam;
		for (int i = 0; i < stacks.Length; i++)
		{
			if ((object)stacks[i] != null)
			{
				stacks[i].Hide();
			}
		}
	}

	private void OnBuilt()
	{
		if ((bool)roof)
		{
			roof.SetActive(value: true);
		}
		else
		{
			SetupCullingGroup();
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (undo)
		{
			for (int i = 0; i < stacks.Length; i++)
			{
				if ((bool)stacks[i] && stacks[i].Count() > 0)
				{
					FreeResourceManager.inst.AddOrMakeAutoStackFor(stacks[i].resourceID, stacks[i].Count(), stacks[i].transform.position);
				}
			}
		}
		if ((bool)roof && !b.IsBuilt())
		{
			roof.SetActive(value: false);
		}
	}

	private void OnDestroy()
	{
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
	}

	public void OnSelectionChanged()
	{
		if (!roof)
		{
			return;
		}
		if (GameUI.inst.GetBuildingSelected() == b)
		{
			roof.SetActive(value: false);
			for (int i = 0; i < stacks.Length; i++)
			{
				if (stacks[i] != null)
				{
					stacks[i].Show();
				}
			}
			return;
		}
		roof.SetActive(b.IsBuilt());
		for (int j = 0; j < stacks.Length; j++)
		{
			if (stacks[j] != null)
			{
				stacks[j].Hide();
			}
		}
	}

	public void StateChangedMethod(CullingGroupEvent evt)
	{
		if ((object)roof != null && GameUI.inst.GetBuildingSelected() != b && evt.hasBecomeVisible)
		{
			return;
		}
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i] != null)
			{
				stacks[i].StateChangedMethod(evt);
			}
		}
	}

	public Stack AddStackToGrid(int gridIdx, int rID)
	{
		FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[rID];
		Stack component = resourceDef.autoResourceStackPrefab.GetComponent<Stack>();
		GameObject gameObject = new GameObject($"{rID} Stack");
		gameObject.transform.SetParent(stackPositions[gridIdx], worldPositionStays: false);
		gameObject.SetActive(value: false);
		Stack stack = gameObject.AddComponent<Stack>();
		stack.resourceID = rID;
		stack.xStackSize = component.xStackSize;
		stack.zStackSize = component.zStackSize;
		stack.DegreesRotationVariation = component.DegreesRotationVariation;
		stack.spacing = resourceDef.autoStackSpacing;
		stack.HeightMultiplier = resourceDef.autoStackHeightMul;
		stack.rowAlternateRotation = resourceDef.autoStackAlterateRows;
		stack.maxStackCount = maxStackCount;
		gameObject.SetActive(value: true);
		stacks[gridIdx] = stack;
		resourceGrid[gridIdx] = rID;
		if ((bool)roof && GameUI.inst.GetBuildingSelected() != b)
		{
			stacks[gridIdx].Hide();
		}
		return stack;
	}

	public void Deposit(ref ResourceAmount amt)
	{
		for (int i = 0; i < amt.resources.Count; i++)
		{
			Resource resource = amt.resources[i];
			if (resource.Amount <= 0)
			{
				continue;
			}
			if (!IsOrderable(resource.resourceID))
			{
				Debug.LogError("TRYING TO DEPOSIT INVALID RESOURCE TYPE!!!!");
				continue;
			}
			for (int j = 0; j < stacks.Length; j++)
			{
				if (stacks[j] != null && stacks[j].resourceID == resource.resourceID)
				{
					int num = stacks[j].Add(resource.Amount);
					resource.Amount -= num;
				}
				if (resource.Amount == 0)
				{
					break;
				}
			}
			if (resource.Amount <= 0)
			{
				continue;
			}
			for (int k = 0; k < resourceGrid.Length; k++)
			{
				if (resourceGrid[k] == -1)
				{
					int num2 = AddStackToGrid(k, resource.resourceID).Add(resource.Amount);
					resource.Amount -= num2;
					if (resource.Amount <= 0)
					{
						break;
					}
				}
			}
		}
		TryDoFullCheck();
	}

	private void TryDoFullCheck()
	{
		if (!doOverflowVisuals && !doNotificationOnFull)
		{
			return;
		}
		bool flag = true;
		for (int i = 0; i < stacks.Length; i++)
		{
			if (!(stacks[i] != null) || stacks[i].Count() - stacks[i].MaxCapacity() < 0)
			{
				flag = false;
				break;
			}
		}
		if (doOverflowVisuals)
		{
			for (int j = 0; j < resourceOverflowGroups.Count; j++)
			{
				ResourceOverFlowCategory resourceOverFlowCategory = resourceOverflowGroups[j];
				bool flag2 = StoredPublicResources(resourceOverFlowCategory.rID) > 0;
				for (int k = 0; k < resourceOverFlowCategory.objs.Length; k++)
				{
					Util.SetActive(resourceOverFlowCategory.objs[k], flag2 & flag);
				}
			}
		}
		if ((doNotificationOnFull & flag) && Player.inst.TotalWorkers() < 100 && SeasonManager.inst.CurrentYear() < 10 && !LoadSave.Loading)
		{
			NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
			{
				single = LocalizationManager.GetTranslation("notificationui_stockpile_full_" + b.UniqueName)
			};
			NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "stockpilefull", message, NotificationStatus.Warning, 200f, b.Center());
		}
	}

	private void Collect(ResourceAmount amt)
	{
		for (int i = 0; i < amt.resources.Count; i++)
		{
			Resource resource = amt.resources[i];
			if (resource.Amount <= 0)
			{
				continue;
			}
			for (int j = 0; j < stacks.Length; j++)
			{
				if (stacks[j] != null && stacks[j].resourceID == resource.resourceID)
				{
					int num = stacks[j].Remove(resource.Amount);
					resource.Amount -= num;
					if (!playerSet[j] && stacks[j].Count() == 0)
					{
						UnityEngine.Object.Destroy(stacks[j].gameObject);
						stacks[j] = null;
						resourceGrid[j] = -1;
					}
				}
				if (resource.Amount == 0)
				{
					break;
				}
			}
		}
	}

	public int SpaceAvailable(int rID)
	{
		int num = 0;
		for (int i = 0; i < stacks.Length; i++)
		{
			if (resourceGrid[i] != -1 && stacks[i].resourceID == rID)
			{
				num += stacks[i].MaxCapacity() - stacks[i].Count();
			}
			else if (resourceGrid[i] == -1)
			{
				num += maxStackCount;
			}
		}
		return num;
	}

	int IResourceStorage.MaxStorageFor(int rID)
	{
		int num = 0;
		for (int i = 0; i < stacks.Length; i++)
		{
			if (resourceGrid[i] != -1 && stacks[i].resourceID == rID)
			{
				num += stacks[i].MaxCapacity();
			}
			else if (resourceGrid[i] == -1)
			{
				num += maxStackCount;
			}
		}
		return num;
	}

	public int StoredPublicResources(int rID)
	{
		int num = 0;
		for (int i = 0; i < stacks.Length; i++)
		{
			if (resourceGrid[i] != -1 && stacks[i].resourceID == rID)
			{
				num += stacks[i].Count();
			}
		}
		if (villagerClaims.TryGetValue(rID, out var value))
		{
			num -= value.Count;
		}
		return num;
	}

	public bool AcceptsType(int t)
	{
		for (int i = 0; i < ValidResourceTypes.Length; i++)
		{
			if (t == ValidResourceTypes[i])
			{
				return true;
			}
		}
		return false;
	}

	public bool StoresTypePublic(int t)
	{
		return AcceptsType(t);
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		Collect(amount);
	}

	public int LandMass()
	{
		return b.LandMass();
	}

	public object GetOwner()
	{
		return this;
	}

	public Vector3 ResourcePosition(int resourceID)
	{
		for (int i = 0; i < stacks.Length; i++)
		{
			if (resourceGrid[i] != -1 && stacks[i].resourceID == resourceID)
			{
				return stacks[i].xform.position;
			}
		}
		if (b.personPositions.Length == 0)
		{
			return b.Center();
		}
		return b.personPositions[0].position;
	}

	public Vector3 CachingCenter()
	{
		return b.Center();
	}

	public bool Available(int rID)
	{
		if (!allowCitizensToWithdrawal)
		{
			return false;
		}
		return StoredPublicResources(rID) > 0;
	}

	public bool ValidToPickupToStoreElsewhere()
	{
		return allowCitizensToWithdrawal;
	}

	public FreeResource ProvideResource(int rID)
	{
		Collect(ResourceAmount.Make(rID, 1));
		return FreeResourceSystem.inst.AddFreeResource(rID, ResourcePosition(rID), LandMass());
	}

	public Vector3 DropOffLocation(int type)
	{
		return ResourcePosition(type);
	}

	public bool ProvidesType(int rID)
	{
		return AcceptsType(rID);
	}

	bool IResourceProvider.ConsiderAsPrimary(int rID)
	{
		return rID != 0;
	}

	public int MakeClaim(int rID, int count, Villager claimer)
	{
		if (!villagerClaims.ContainsKey(rID))
		{
			return 0;
		}
		int num = 0;
		for (int i = 0; i < stacks.Length; i++)
		{
			if (stacks[i] != null && stacks[i].resourceID == rID)
			{
				num += stacks[i].Count();
			}
		}
		int num2 = Mathff.Min(num - villagerClaims[rID].Count, count);
		for (int j = 0; j < num2; j++)
		{
			villagerClaims[rID].Add(claimer);
		}
		return num2;
	}

	public void ReleaseClaim(int rID, Villager claimer)
	{
		if (!villagerClaims.ContainsKey(rID))
		{
			return;
		}
		for (int i = 0; i < villagerClaims[rID].Count; i++)
		{
			if (villagerClaims[rID][i] == claimer)
			{
				villagerClaims[rID].RemoveAt(i);
				i--;
			}
		}
	}

	public bool IsOrderable(int type)
	{
		for (int i = 0; i < ValidResourceTypes.Length; i++)
		{
			if (type == ValidResourceTypes[i])
			{
				return true;
			}
		}
		return false;
	}

	public bool ShowLockNonSurplus()
	{
		return showLockNonSurplus;
	}

	public bool GetNonSurplusPrivate(int t)
	{
		return false;
	}

	public void SetNonSurplusPrivate(int t, bool val)
	{
	}

	public void GetStoredAndMaxAmount(out int storedAmt, out int maxAmt)
	{
		storedAmt = 0;
		maxAmt = 0;
	}

	public void BuildGatherTypeOrder(int landmass, ArrayExt<int> typeGatherable, ref int[] gatherTypeOrder, ResourceAmount resourcesStored, ResourceAmount resourceStorageMax, int[] validResourceTypes)
	{
		ResourceAmount resourceAmount = Player.inst.resourcesPerLandmass[landmass];
		typeGatherable.Clear();
		for (int i = 0; i < validResourceTypes.Length; i++)
		{
			if (resourceAmount.Get(validResourceTypes[i]) > 0 && AcceptsType(validResourceTypes[i]))
			{
				typeGatherable.Add(validResourceTypes[i]);
			}
		}
		for (int j = 0; j < gatherTypeOrder.Length; j++)
		{
			int num = -1;
			float num2 = 1f;
			for (int k = 0; k < typeGatherable.Count; k++)
			{
				float num3 = (float)resourcesStored.Get(typeGatherable.data[k]) / (float)resourceStorageMax.Get(typeGatherable.data[k]);
				if (num3 < num2)
				{
					num2 = num3;
					num = typeGatherable.data[k];
				}
			}
			gatherTypeOrder[j] = num;
			typeGatherable.RemoveSwap(num);
		}
	}

	public bool DoesStoreResource(int r)
	{
		for (int i = 0; i < ValidResourceTypes.Length; i++)
		{
			if (ValidResourceTypes[i] == r)
			{
				return true;
			}
		}
		return false;
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
