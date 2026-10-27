using System;
using System.Collections.Generic;
using UnityEngine;

public class ShipSystem : MonoBehaviour
{
	public delegate void shipArrived(ShipBase b);

	[Serializable]
	public class ShipSystemSaveData : SaveClass<ShipSystem, ShipSystemSaveData>
	{
		private List<ShipBase.ShipData> shipBaseData = new List<ShipBase.ShipData>();

		private List<MerchantShip.ShipData> merchantShipData = new List<MerchantShip.ShipData>();

		private List<Ship.ShipData> transportShipData = new List<Ship.ShipData>();

		private List<TroopTransportShip.ShipData> troopTransportData = new List<TroopTransportShip.ShipData>();

		private List<UnitTransportShip.ShipData> unitTransportData = new List<UnitTransportShip.ShipData>();

		private List<SettlerShip.ShipData> settlerShipData = new List<SettlerShip.ShipData>();

		private List<TransportShip.ShipData> transportShipData2 = new List<TransportShip.ShipData>();

		public float[] merchantSpawnTimers;

		private float merchantSpawnTimer;

		public override ShipSystemSaveData Pack(ShipSystem obj)
		{
			merchantSpawnTimers = new float[obj.merchantSpawnTimers.Length];
			for (int i = 0; i < merchantSpawnTimers.Length; i++)
			{
				merchantSpawnTimers[i] = obj.merchantSpawnTimers[i];
			}
			for (int j = 0; j < obj.ships.Count; j++)
			{
				ShipBase.ShipData data = obj.ships.data[j].GetData();
				shipBaseData.Add(data);
				switch (data.type)
				{
				case ShipBase.ShipType.Transport:
				case ShipBase.ShipType.PlayerMerchant:
					transportShipData2.Add(obj.ships.data[j].GetComponent<TransportShip>().GetShipData());
					break;
				case ShipBase.ShipType.Merchant:
					merchantShipData.Add(obj.ships.data[j].GetComponent<MerchantShip>().GetShipData());
					break;
				case ShipBase.ShipType.TroopTransport:
				case ShipBase.ShipType.VikingTroopTransport:
				case ShipBase.ShipType.OgreTroopTransport:
					unitTransportData.Add(obj.ships.data[j].GetComponent<UnitTransportShip>().GetShipData());
					break;
				case ShipBase.ShipType.SettlerShip:
					settlerShipData.Add(obj.ships.data[j].GetComponent<SettlerShip>().GetShipData());
					break;
				}
			}
			return this;
		}

		public override ShipSystem Unpack(ShipSystem obj)
		{
			obj.Init();
			if (merchantSpawnTimers != null)
			{
				for (int i = 0; i < merchantSpawnTimers.Length; i++)
				{
					obj.merchantSpawnTimers[i] = merchantSpawnTimers[i];
				}
			}
			int num = 0;
			int num2 = 0;
			int num3 = 0;
			int num4 = 0;
			for (int j = 0; j < shipBaseData.Count; j++)
			{
				Transform transform = null;
				switch (shipBaseData[j].type)
				{
				case ShipBase.ShipType.Transport:
					transform = UnityEngine.Object.Instantiate(inst.transportShipPrefab);
					break;
				case ShipBase.ShipType.Merchant:
					transform = UnityEngine.Object.Instantiate(inst.merchantShipPrefab);
					break;
				case ShipBase.ShipType.TroopTransport:
					transform = UnityEngine.Object.Instantiate(inst.playerTransportShip).transform;
					break;
				case ShipBase.ShipType.VikingTroopTransport:
					transform = UnityEngine.Object.Instantiate(inst.raiderTransportShip).transform;
					break;
				case ShipBase.ShipType.OgreTroopTransport:
					transform = UnityEngine.Object.Instantiate(RaiderSystem.inst.ogreTransportShipPrefab).transform;
					break;
				case ShipBase.ShipType.PlayerMerchant:
					transform = UnityEngine.Object.Instantiate(inst.playerMerchantShipPrefab);
					break;
				case ShipBase.ShipType.SeedShip:
					transform = UnityEngine.Object.Instantiate(inst.seedShipPrefab);
					break;
				case ShipBase.ShipType.SettlerShip:
					transform = UnityEngine.Object.Instantiate(inst.settlerShipPrefab);
					break;
				}
				if ((bool)transform)
				{
					transform.GetComponent<ShipBase>().SetFromShipData(shipBaseData[j]);
					switch (shipBaseData[j].type)
					{
					case ShipBase.ShipType.Transport:
						transform.GetComponent<TransportShip>().SetFromShipData(transportShipData2[num++]);
						break;
					case ShipBase.ShipType.Merchant:
						transform.GetComponent<MerchantShip>().SetFromShipData(merchantShipData[num2++]);
						break;
					case ShipBase.ShipType.TroopTransport:
						transform.GetComponent<UnitTransportShip>().SetFromShipData(unitTransportData[num3++]);
						break;
					case ShipBase.ShipType.VikingTroopTransport:
						transform.GetComponent<UnitTransportShip>().SetFromShipData(unitTransportData[num3++]);
						break;
					case ShipBase.ShipType.OgreTroopTransport:
						transform.GetComponent<TroopTransportShip>().SetFromShipData(troopTransportData[num3++]);
						break;
					case ShipBase.ShipType.PlayerMerchant:
						transform.GetComponent<Ship>().SetFromShipData(transportShipData[num++]);
						break;
					case ShipBase.ShipType.SettlerShip:
						transform.GetComponent<SettlerShip>().SetFromShipData(settlerShipData[num4++]);
						break;
					}
				}
			}
			return obj;
		}
	}

	public Transform transportShipPrefab;

	public Transform merchantShipPrefab;

	public Transform troopTransportShipPrefab;

	public Transform fishingShipPrefab;

	public Transform playerMerchantShipPrefab;

	public Transform seedShipPrefab;

	public Transform settlerShipPrefab;

	public UnitTransportShip raiderTransportShip;

	public UnitTransportShip playerTransportShip;

	public static ShipSystem inst;

	public float minMerchantInterval = 420f;

	public float maxMerchantInterval = 540f;

	private ArrayExt<Dock> validatedDocks = new ArrayExt<Dock>(32);

	private List<ShipBase> toDestroy = new List<ShipBase>();

	public float[] merchantSpawnTimers = new float[8];

	public bool[] isMerchantActive = new bool[8];

	public ArrayExt<ShipBase> ships = new ArrayExt<ShipBase>(50);

	public ArrayExt<ShipBase> playerMerchantShips = new ArrayExt<ShipBase>(50);

	private ArrayExt<ShipBase>[] unitPosGrid;

	private ArrayExt<int> clearPosIdx = new ArrayExt<int>(100);

	private int gridRes = 2;

	private int shipGridWidth;

	private int shipGridHeight;

	public event shipArrived onShipArrived;

	private void Start()
	{
		inst = this;
	}

	public void AddHighlights(int minx, int minz, int maxx, int maxz, ref List<ISelectable> highlightedObjs)
	{
		for (int i = 0; i < ships.Count; i++)
		{
			ISelectable component = ships.data[i].GetComponent<ISelectable>();
			if (component != null && component.InsideSelectionBounds(minx, minz, maxx, maxz) && !highlightedObjs.Contains(component))
			{
				highlightedObjs.Add(component);
			}
		}
	}

	public void AddHighlights(Ray ray, ref List<ISelectable> highlightedObjs)
	{
		Vector3 vector = GameUI.inst.GridPointerIntersection();
		int num = (int)Mathff.Clamp(vector.x - 3f, 0f, World.inst.GridWidth - 1);
		int num2 = (int)Mathff.Clamp(vector.x + 3f, 0f, World.inst.GridWidth - 1);
		int num3 = (int)Mathff.Clamp(vector.z - 3f, 0f, World.inst.GridHeight - 1);
		int num4 = (int)Mathff.Clamp(vector.z + 3f, 0f, World.inst.GridHeight - 1);
		int i = 0;
		for (int count = ships.Count; i < count; i++)
		{
			ShipBase shipBase = ships.data[i];
			Vector3 pos = shipBase.GetPos();
			if (pos.x >= (float)num && pos.x <= (float)num2 && pos.z >= (float)num3 && pos.z <= (float)num4 && Mathff.RaySphereIntersect(ray, shipBase.GetPos(), 1.5f) && shipBase.collider.Raycast(ray, out var _, 10000f))
			{
				ISelectable component = shipBase.GetComponent<ISelectable>();
				if (component != null)
				{
					highlightedObjs.Add(component);
				}
			}
		}
	}

	internal void SendArrivedEvent(ShipBase shipBase)
	{
		onShipArrived?.Invoke(shipBase);
	}

	public void AddInView(Plane[] planes, ref List<ISelectable> objs)
	{
		for (int i = 0; i < ships.Count; i++)
		{
			ShipBase shipBase = ships.data[i];
			if (GeometryUtility.TestPlanesAABB(planes, shipBase.GetComponentInChildren<Renderer>().bounds))
			{
				objs.Add(shipBase.GetComponent<ISelectable>());
			}
		}
	}

	public void AddInView(Plane[] planes, int unitType, int teamID, ref ArrayExt<IUnitControllable> objs)
	{
		for (int i = 0; i < ships.Count; i++)
		{
			ShipBase shipBase = ships.data[i];
			if (shipBase is IUnitControllable unitControllable && unitControllable.GetUnitType() == unitType && !UnitControlSystem.inst.IsUnitControllableByTeam(unitControllable, teamID) && GeometryUtility.TestPlanesAABB(planes, shipBase.GetComponentInChildren<Renderer>().bounds))
			{
				objs.Add(unitControllable);
			}
		}
	}

	public void Init()
	{
		shipGridWidth = World.inst.GridWidth / gridRes + 1;
		shipGridHeight = World.inst.GridHeight / gridRes + 1;
		unitPosGrid = new ArrayExt<ShipBase>[shipGridWidth * shipGridHeight];
		for (int i = 0; i < unitPosGrid.Length; i++)
		{
			unitPosGrid[i] = new ArrayExt<ShipBase>(20);
		}
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		Util.Memset(isMerchantActive, 0);
		for (int i = 0; i < ships.Count; i++)
		{
			if (ships.data[i] is MerchantShip merchantShip && merchantShip.GetCurrentDock() != null && (merchantShip.status == MerchantShip.Status.SailingToDock || merchantShip.status == MerchantShip.Status.Waiting))
			{
				isMerchantActive[World.LandMassOwners.IndexOf(merchantShip.GetCurrentDock().bi.GetLandMassOwner())] = true;
			}
		}
		for (int j = 0; j < World.LandMassOwners.Count; j++)
		{
			LandmassOwner landmassOwner = World.LandMassOwners.data[j];
			if (isMerchantActive[j])
			{
				continue;
			}
			ArrayExt<Building> arrayExt = null;
			float num = 1f;
			if (landmassOwner.teamId == 0 && TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_tradingpost") && Dock.isAnyPlayerDockTradingPost)
			{
				arrayExt = Player.inst.GetBuildingListForLandMassOwner(landmassOwner, World.dockHash);
				num = Mathff.Min(1f / (3f / (float)(arrayExt.Count - 1 + 3)), 5f);
			}
			merchantSpawnTimers[j] -= Time.deltaTime * num;
			if (!(merchantSpawnTimers[j] < 0f))
			{
				continue;
			}
			int num2 = 0;
			for (int k = 0; k < landmassOwner.ownedLandMasses.Count; k++)
			{
				num2 += World.inst.GetVillagersForLandMass(landmassOwner.ownedLandMasses.data[k]).Count;
			}
			if (num2 < 50)
			{
				continue;
			}
			if (arrayExt == null)
			{
				arrayExt = Player.inst.GetBuildingListForLandMassOwner(landmassOwner, World.dockHash);
			}
			validatedDocks.ClearFast();
			for (int l = 0; l < arrayExt.Count; l++)
			{
				Building building = arrayExt.data[l];
				if (!building.IsOpen() || !building.IsBuilt())
				{
					continue;
				}
				Dock component = building.GetComponent<Dock>();
				if (!component.disallowForeignMerchants)
				{
					if (component.IsTradingPost())
					{
						validatedDocks.Add(component);
						validatedDocks.Add(component);
					}
					validatedDocks.Add(component);
				}
			}
			if (validatedDocks.Count != 0)
			{
				Dock dock = validatedDocks.RandomElement();
				Transform transform = UnityEngine.Object.Instantiate(merchantShipPrefab);
				Vector3 pos = new Vector3(1f, TerrainGen.waterHeightTestThresold, 1f);
				World.inst.GetRandomPositionOnEdge(ref pos);
				transform.transform.position = pos;
				ShipBase component2 = transform.GetComponent<ShipBase>();
				component2.SetPos(pos);
				component2.Init(-2);
				transform.GetComponent<MerchantShip>().StartSailing(dock.GetComponent<Building>());
				float min = Mathf.Max((float)DifficultyManager.inst.currOption.minMerchantInterval * 0.5f, DifficultyManager.inst.currOption.minMerchantInterval - arrayExt.Count * 10);
				float max = Mathf.Max((float)DifficultyManager.inst.currOption.maxMerchantInterval * 0.5f, DifficultyManager.inst.currOption.maxMerchantInterval - arrayExt.Count * 10);
				merchantSpawnTimers[j] = SRand.Range(min, max);
				if (DifficultyManager.inst.difficulty == 4 && SeasonManager.inst.CurrentYear() > 100)
				{
					merchantSpawnTimers[j] *= 0.85f;
				}
			}
		}
		for (int m = 0; m < clearPosIdx.Count; m++)
		{
			unitPosGrid[clearPosIdx.data[m]].ClearFast();
		}
		clearPosIdx.Clear();
		_ = World.inst.GridWidth;
		toDestroy.Clear();
		for (int n = 0; n < ships.Count; n++)
		{
			if (ships.data[n].type == ShipBase.ShipType.Merchant && ships.data[n].GetComponent<MerchantShip>().status == MerchantShip.Status.Done)
			{
				toDestroy.Add(ships.data[n]);
			}
			Vector3 pos2 = ships.data[n].GetPos();
			int num3 = (int)pos2.x / gridRes;
			int num4 = (int)pos2.z / gridRes * shipGridWidth + num3;
			if (num4 >= 0 && num4 < unitPosGrid.Length)
			{
				unitPosGrid[num4].Add(ships.data[n]);
				clearPosIdx.Add(num4);
			}
		}
		for (int num5 = 0; num5 < toDestroy.Count; num5++)
		{
			UnityEngine.Object.Destroy(toDestroy[num5].gameObject);
		}
		toDestroy.Clear();
	}

	public ArrayExt<ShipBase> GetShipsAt(int x, int z)
	{
		return unitPosGrid[z / gridRes * shipGridWidth + x / gridRes];
	}

	public void Add(ShipBase s)
	{
		ships.Add(s);
		if (s.type == ShipBase.ShipType.PlayerMerchant)
		{
			playerMerchantShips.Add(s);
		}
	}

	public void Remove(ShipBase s)
	{
		ships.RemoveSwap(s);
		if (s.type == ShipBase.ShipType.PlayerMerchant)
		{
			playerMerchantShips.RemoveSwap(s);
		}
		if (unitPosGrid != null)
		{
			Vector3 pos = s.GetPos();
			int num = (int)pos.x / gridRes;
			int num2 = (int)pos.z / gridRes * shipGridWidth + num;
			if (num2 >= 0 && num2 < unitPosGrid.Length)
			{
				unitPosGrid[num2].RemoveSwap(s);
			}
		}
	}

	public void Reset()
	{
		clearPosIdx.Clear();
		unitPosGrid = null;
		toDestroy.Clear();
		for (int i = 0; i < ships.Count; i++)
		{
			toDestroy.Add(ships.data[i]);
		}
		for (int j = 0; j < toDestroy.Count; j++)
		{
			UnityEngine.Object.Destroy(toDestroy[j].gameObject);
		}
		toDestroy.Clear();
		ships.Clear();
		playerMerchantShips.Clear();
	}

	public IProjectileHitable GetClosestShipToAttack(Vector3 pos, int teamId, float range)
	{
		IProjectileHitable result = null;
		float num = float.MaxValue;
		for (int i = 0; i < ships.Count; i++)
		{
			if (World.inst.RelationBetween(teamId, ships.data[i].teamID) != World.Relations.Enemy || ships.data[i].IsInvalid() || ships.data[i].life <= 0f)
			{
				continue;
			}
			IMoveableUnit component = ships.data[i].GetComponent<IMoveableUnit>();
			if (component == null || component.TeamID() != 1 || !component.CanCarry() || component.CarryCount() != 0 || !ships.data[i].arrived)
			{
				float num2 = Mathff.DistSqrdXZ(pos, ships.data[i].GetPos());
				if (num2 < num)
				{
					num = num2;
					result = ships.data[i];
				}
			}
		}
		return result;
	}

	public bool IsForeignMerchantShipDocked()
	{
		for (int i = 0; i < ships.Count; i++)
		{
			MerchantShip component = ships.data[i].GetComponent<MerchantShip>();
			if (ships.data[i].type == ShipBase.ShipType.Merchant && component.status == MerchantShip.Status.Waiting && component.isTargetPlayerDock)
			{
				return true;
			}
		}
		return false;
	}

	public bool HasLogisticShip()
	{
		for (int i = 0; i < ships.Count; i++)
		{
			if (ships.data[i].type == ShipBase.ShipType.Transport)
			{
				return true;
			}
		}
		return false;
	}
}
