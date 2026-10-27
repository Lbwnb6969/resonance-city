using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Interface;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class TransportCart : Tickable, ICamTrackable, ISelectable, IProjectileHitable, ILogisticTransport
{
	public enum State
	{
		None
	}

	[Serializable]
	public class CartData
	{
		public float Life = -1f;

		public int TeamId;

		public bool arrived;

		public Guid guid = Guid.NewGuid();

		public SerializableVector3 pos;

		public SerializableQuaternion rot;

		public ResourceAmount hold;

		public Ship.Behavior behavior;

		public bool paused;

		public string name = "";

		public List<Ship.LogisticsOrder> logisticsOrders = new List<Ship.LogisticsOrder>();

		public int logisticsIdx;

		public int routeEveryYears;

		public int routeCurrentYear;
	}

	private FrameUpdater pathUpdater;

	private static int frameID = 0;

	[NonSerialized]
	protected int _teamID;

	public int landmass;

	public float MaxLife = 1f;

	public float Life = 1f;

	public Guid guid = Guid.NewGuid();

	public ResourceAmount hold;

	public ObjectHighlighter highlighter;

	public UnitIGUI unitGUI;

	public Collider collider;

	public InWorldExclamation issueButtonPrefab;

	public Stockpile stockpile;

	private EventInstance rollingSound;

	[NonSerialized]
	public string cartName = "";

	[NonSerialized]
	public HealthBar healthBar;

	[NonSerialized]
	public InWorldExclamation issueButton;

	public Transform[] wheels;

	public MeshRenderer[] cartRenderers;

	private Vector3 pos;

	private Quaternion rot;

	[NonSerialized]
	public GamePath deferredPath = new GamePath();

	public ArrayExt<Vector3> path = new ArrayExt<Vector3>(32);

	[NonSerialized]
	public IMoveTarget moveTarget;

	private int pathIdx;

	private bool forceUpdatePath;

	public bool arrived = true;

	private bool paused;

	public ParticleSystem wake;

	public float origEmissionRate;

	public List<Ship.LogisticsOrder> logisticsOrders = new List<Ship.LogisticsOrder>();

	[NonSerialized]
	public bool forceRepath;

	public int logisticsIdx;

	public Ship.Behavior behavior;

	public int routeEveryYears;

	public int routeCurrentYear;

	private bool firstUpdate = true;

	private float delayTimer = 5f;

	private float delayTimerMax = 5f;

	public int lastAttackerTeamID = -1;

	private float yAdjust;

	private const float defaultSpeed = 0.9f;

	private float activeSpeed = 1f;

	public float speedBonusMultiplier = 1f;

	public bool debugDraw;

	private bool showPath;

	public State state;

	private EventHandler<SeasonEventData> seasonEventHandler;

	private bool isPlayerSetPaused;

	private static List<Cell> visited = new List<Cell>();

	private static List<Cell> openSet = new List<Cell>();

	private static List<Cell> candidates = new List<Cell>();

	[NonSerialized]
	public float accel = 2.25f;

	[NonSerialized]
	public float drag = 1.8f;

	[NonSerialized]
	public float rotAccel = 1.25f;

	[NonSerialized]
	public float arrivalRad = 0.3f;

	[NonSerialized]
	public Vector3 velocity;

	private Cell lastCell;

	public int teamID
	{
		get
		{
			return _teamID;
		}
		set
		{
			_teamID = value;
		}
	}

	public bool Paused => paused;

	public CartData GetCartData()
	{
		return new CartData
		{
			Life = Life,
			TeamId = teamID,
			arrived = arrived,
			guid = guid,
			pos = pos,
			rot = rot,
			hold = hold,
			behavior = behavior,
			paused = paused,
			name = cartName,
			logisticsOrders = logisticsOrders,
			logisticsIdx = logisticsIdx,
			routeEveryYears = routeEveryYears,
			routeCurrentYear = routeCurrentYear
		};
	}

	public void SetFromCartData(CartData data)
	{
		if (Mathff.IsNaN(data.pos))
		{
			Cell[] cellsData = World.inst.GetCellsData();
			for (int i = 0; i < cellsData.Length; i++)
			{
				if (cellsData[i].Type == TerrainType.None && cellsData[i].OccupyingStructure.Count == 0)
				{
					data.pos = cellsData[i].Center2D;
				}
			}
		}
		transform.position = (pos = data.pos);
		transform.rotation = data.rot;
		arrived = data.arrived;
		teamID = data.TeamId;
		guid = data.guid;
		Life = data.Life;
		paused = data.paused;
		if (Life == -1f)
		{
			Life = MaxLife;
		}
		behavior = data.behavior;
		hold = data.hold;
		cartName = data.name;
		logisticsIdx = data.logisticsIdx;
		logisticsOrders = data.logisticsOrders;
		if (logisticsOrders == null)
		{
			logisticsOrders = new List<Ship.LogisticsOrder>();
		}
		new ResourceAmount();
		_ = hold;
		landmass = World.inst.GetCellData(pos).landMassIdx;
		routeEveryYears = data.routeEveryYears;
		routeCurrentYear = data.routeCurrentYear;
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		CartSystem.inst.carts.Add(this);
		origEmissionRate = wake.emission.rateOverTime.constant;
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		highlighter.Release();
		CartSystem.inst.carts.Remove(this);
	}

	public void Init(int tid)
	{
		teamID = tid;
		pathUpdater = new FrameUpdater(ref frameID, 30);
		List<MeshRenderer> list = new List<MeshRenderer>();
		Transform child = transform.GetChild(0);
		MeshRenderer component = child.GetChild(0).GetComponent<MeshRenderer>();
		if ((bool)component)
		{
			list.Add(component);
		}
		for (int i = 0; i < child.GetChild(0).childCount; i++)
		{
			component = child.GetChild(0).GetChild(i).GetComponent<MeshRenderer>();
			if ((bool)component)
			{
				list.Add(component);
			}
		}
		highlighter = ObjectHighlighter.SetupOutlines(gameObject, list, null);
		healthBar = UnityEngine.Object.Instantiate(Player.inst.healthBarPrefab);
		issueButton = UnityEngine.Object.Instantiate(issueButtonPrefab);
		issueButton.transform.SetParent(transform.GetChild(0));
		issueButton.transform.localPosition = new Vector3(0f, 2.5f, 0f);
		issueButton.transform.localScale = new Vector3(1.3f, 1.3f, 1.3f);
		issueButton.transform.SetSiblingIndex(0);
		issueButton.onClick = () =>
		{
			SendMessage("OnClickedButton", SendMessageOptions.DontRequireReceiver);
		};
		issueButton.gameObject.SetActive(value: false);
		if (unitGUI == null)
		{
			unitGUI = UnityEngine.Object.Instantiate(Player.inst.unitIGUIprefab).GetComponent<UnitIGUI>();
		}
		unitGUI.flagPole.SetActive(value: false);
		unitGUI.Init(teamID, null);
		pos = transform.position;
		landmass = World.inst.GetCellData(pos).landMassIdx;
		SetPause(p: true);
		seasonEventHandler = Broadcast.SeasonEvent.Listen(OnSeasonChange);
	}

	private void OnSeasonChange(object sender, SeasonEventData seasonEvent)
	{
		if (routeEveryYears == 0 || seasonEvent.SeasonDefinition.id != 0)
		{
			return;
		}
		routeCurrentYear++;
		if (routeCurrentYear >= routeEveryYears)
		{
			if (Paused && !isPlayerSetPaused)
			{
				SetPause(p: false);
			}
			routeCurrentYear = 0;
		}
	}

	private void OnClickedButton()
	{
		GameUI.inst.shipLogisticsUI.SetSelectedTransport(this);
		GameUI.inst.shipLogisticsUI.SetVisible(v: true);
		issueButton.gameObject.SetActive(value: false);
		Cam.inst.SetDesiredTrackingPos(transform.position);
		if (Cam.inst.desiredDist > 15f)
		{
			Cam.inst.desiredDist = 15f;
		}
	}

	private void OnDestroy()
	{
		if ((bool)healthBar)
		{
			UnityEngine.Object.Destroy(healthBar.gameObject);
		}
		if ((bool)unitGUI)
		{
			UnityEngine.Object.Destroy(unitGUI.gameObject);
		}
		Broadcast.SeasonEvent.Unlisten(seasonEventHandler);
	}

	public void MoveTo(IMoveTarget target, bool displayPath = true)
	{
		moveTarget = target;
		forceUpdatePath = true;
		arrived = false;
		showPath = displayPath;
		UpdatePathing();
	}

	public bool ValidForOrder(Cell curr)
	{
		if (curr.Type == TerrainType.None)
		{
			if (curr.OccupyingStructure.Count != 0 && !curr.BottomStructureIsCategory(World.pathHash) && !curr.BottomStructureIs(World.farmHash))
			{
				return curr.BottomStructureIs(World.townsquareHash);
			}
			return true;
		}
		return false;
	}

	private void TryInitInitialOrders()
	{
		Vector3 position = transform.position;
		Vector3 vector = transform.position + transform.forward * -1f;
		Vector3 b = transform.position + transform.forward * -3f;
		float num = float.MinValue;
		candidates.Clear();
		visited.Clear();
		openSet.Clear();
		openSet.Add(World.inst.GetCellDataClamped(position));
		while (openSet.Count > 0)
		{
			Cell cell = openSet[0];
			openSet.RemoveAt(0);
			if (ValidForOrder(cell) && !visited.Contains(cell))
			{
				float num2 = Mathff.DistSqrdXZ(cell.Center2D, position);
				if (num2 <= 9f)
				{
					float num3 = Mathff.DistSqrdXZ(cell.Center2D, b);
					float num4 = num2 * 2f + (0f - num3);
					if (num4 > num)
					{
						num = num4;
						vector = cell.Center2D;
					}
					openSet.Add(World.inst.GetCellDataClamped(cell.x + 1, cell.z));
					openSet.Add(World.inst.GetCellDataClamped(cell.x - 1, cell.z));
					openSet.Add(World.inst.GetCellDataClamped(cell.x, cell.z + 1));
					openSet.Add(World.inst.GetCellDataClamped(cell.x, cell.z - 1));
					candidates.Add(cell);
				}
			}
			visited.Add(cell);
		}
		Vector3 vector2 = transform.position + transform.forward * 1f;
		Vector3 b2 = transform.position + transform.forward * 3f;
		num = float.MinValue;
		for (int i = 0; i < candidates.Count; i++)
		{
			Cell cell2 = candidates[i];
			if (ValidForOrder(cell2))
			{
				float num5 = Mathff.DistSqrdXZ(cell2.Center2D, b2);
				float num6 = Mathff.DistSqrdXZ(cell2.Center2D, position) * 2f + (0f - num5);
				if (num6 > num)
				{
					num = num6;
					vector2 = cell2.Center2D;
				}
			}
		}
		Ship.LogisticsOrder logisticsOrder = new Ship.LogisticsOrder();
		logisticsOrder.endPosition = vector;
		logisticsOrder.endType = Ship.LogisticsOrderType.Position;
		logisticsOrders.Add(logisticsOrder);
		logisticsOrder = new Ship.LogisticsOrder();
		logisticsOrder.endPosition = vector2;
		logisticsOrder.endType = Ship.LogisticsOrderType.Position;
		logisticsOrders.Add(logisticsOrder);
	}

	public override void Tick(float dt, int currFrame)
	{
		if (Life <= 0f)
		{
			UnityEngine.Object.Destroy(gameObject);
			return;
		}
		if (logisticsOrders.Count == 0)
		{
			TryInitInitialOrders();
		}
		healthBar.life = Life / MaxLife;
		healthBar.SetPos(transform.GetChild(0).position + new Vector3(0f, 2f, 0f));
		unitGUI.transform.position = pos;
		AdjustY(World.inst.GetCellData(pos), ref yAdjust);
		if (firstUpdate)
		{
			MoveToOrder(GetCurrentOrder());
			for (int i = 0; i < cartRenderers.Length; i++)
			{
				cartRenderers[i].material = World.GetLandmassOwnerByTeamId(teamID).ArmyMaterial;
			}
			issueButton.gameObject.SetActive(paused);
			firstUpdate = false;
		}
		if (state == State.None)
		{
			pos.y = 0f;
			ValidateOrders();
			if (!arrived)
			{
				pathUpdater.Update();
				if (pathUpdater.Trigger() || forceUpdatePath)
				{
					forceUpdatePath = false;
					UpdatePathing();
				}
				if (deferredPath.TryConsume(ref path))
				{
					if (path.Count == 0)
					{
						arrived = true;
					}
					else
					{
						if (path.Count == 0)
						{
							arrived = true;
						}
						if (debugDraw)
						{
							Debug.DrawLine(pos, path.data[path.Count - 1], Color.cyan);
							DebugEx.DrawSphere(path.data[path.Count - 1], 0.45f, Color.cyan, 8f);
						}
					}
					pathIdx = 0;
					if (path.Count > 0)
					{
						if (showPath && teamID == 0)
						{
							CommandPathMarker obj = EffectsMan.inst.PathMarker.Create(Vector3.zero) as CommandPathMarker;
							obj.ShowPath(path);
							obj.Play();
						}
						showPath = false;
					}
				}
			}
			if (path.Count > 0 && !arrived && !paused)
			{
				Vector3 targetPos = GetTargetPos(0);
				if (MoveUpdate(dt, targetPos))
				{
					pathIdx++;
				}
				if (pathIdx == path.Count)
				{
					arrived = true;
				}
			}
		}
		if (!paused)
		{
			if (forceRepath)
			{
				MoveToOrder(GetCurrentOrder());
				forceRepath = false;
			}
			if (logisticsOrders.Count > 0 && arrived)
			{
				if (GetCurrentOrder().endType == Ship.LogisticsOrderType.Position)
				{
					NextOrder();
				}
				else
				{
					Ship.LogisticsOrder currentOrder = GetCurrentOrder();
					Building building = currentOrder.GetBuilding();
					delayTimer -= dt;
					if (delayTimer < 0f)
					{
						delayTimer = delayTimerMax;
						if (building != null)
						{
							IResourceStorage component = building.GetComponent<Stockpile>();
							if (component == null)
							{
								component = building.GetComponent<IResourceStorage>();
							}
							int maxHold = GetMaxHold();
							int num = 0;
							ResourceAmount unloadAtEnd = currentOrder.unloadAtEnd;
							ResourceAmount resourceAmount = new ResourceAmount();
							ResourceAmount resources = new ResourceAmount();
							for (int j = 0; j < unloadAtEnd.resources.Count; j++)
							{
								int resourceID = unloadAtEnd.resources[j].resourceID;
								int amount = unloadAtEnd.resources[j].Amount;
								if (amount > 0)
								{
									int num2 = hold.Get(resourceID);
									int num3 = ((num2 < amount) ? num2 : amount);
									int num4 = num3;
									if (component.AcceptsType(resourceID))
									{
										int a = component.MaxStorageFor(resourceID) - component.StoredPublicResources(resourceID);
										num4 = Mathff.Max(0, Mathff.Min(a, num4));
										resources.Set(resourceID, num4);
										num4 = num3 - num4;
										resourceAmount.Set(resourceID, num4 + resources.Get(resourceID));
									}
									FreeResourceManager.inst.AddOrMakeAutoStackFor(resourceID, num4, component.DropOffLocation(resourceID));
								}
								num += hold.Get(resourceID) - resourceAmount.Get(resourceID);
							}
							RemoveFromHold(resourceAmount);
							component.Deposit(ref resources);
							ResourceAmount resourceAmount2 = new ResourceAmount();
							for (int k = 0; k < currentOrder.loadFromStart.resources.Count; k++)
							{
								int resourceID2 = currentOrder.loadFromStart.resources[k].resourceID;
								if (!component.AcceptsType(resourceID2))
								{
									continue;
								}
								int num5 = currentOrder.loadFromStart.resources[k].Amount - hold.Get(resourceID2);
								if (num5 > 0 && num < maxHold)
								{
									num5 = ((component.StoredPublicResources(resourceID2) < num5) ? component.StoredPublicResources(resourceID2) : num5);
									if (num5 + num > maxHold)
									{
										num5 = maxHold - num;
										resourceAmount2.Set(resourceID2, num5);
										break;
									}
									num += num5;
									resourceAmount2.Set(resourceID2, num5);
								}
							}
							AddToHold(resourceAmount2);
							component.RemoveResources(resourceAmount2);
						}
						NextOrder();
					}
				}
			}
		}
		rollingSound.getPlaybackState(out var pLAYBACK_STATE);
		if (!arrived && !paused)
		{
			if (pLAYBACK_STATE == PLAYBACK_STATE.STOPPED)
			{
				rollingSound = SfxSystem.inst.PlayFromBankIfVisible("TransportCartLoop", transform.position);
			}
			rollingSound.set3DAttributes(transform.position.To3DAttributes());
		}
		else if (pLAYBACK_STATE == PLAYBACK_STATE.PLAYING)
		{
			rollingSound.stop(STOP_MODE.ALLOWFADEOUT);
		}
		ParticleSystem.EmissionModule emission = wake.emission;
		emission.rateOverTime = ((arrived || paused) ? 0f : origEmissionRate);
	}

	public bool MoveUpdate(float timeStep, Vector3 targetPos)
	{
		pos = transform.position;
		pos.y = yAdjust;
		Cell cellData = World.inst.GetCellData(pos);
		if (lastCell == cellData && lastCell != null)
		{
			UpdateSpeed(cellData);
		}
		lastCell = cellData;
		if (timeStep > 0.2f)
		{
			timeStep = 0.2f;
		}
		timeStep *= activeSpeed;
		float num = timeStep;
		Vector3 normalized = new Vector3(targetPos.x - pos.x, 0f, targetPos.z - pos.z).normalized;
		Vector3 vector = normalized * accel;
		pos.x += velocity.x * num;
		pos.z += velocity.z * num;
		Vector3 forward = transform.forward;
		float num2 = num * (float)((Vector3.Dot(normalized, forward) > 0f) ? 1 : 0);
		velocity.x += vector.x * num2;
		velocity.z += vector.z * num2;
		float num3 = drag * num;
		velocity.x += (0f - velocity.x) * num3;
		velocity.z += (0f - velocity.z) * num3;
		transform.rotation = Quaternion.Lerp(transform.rotation, Quaternion.LookRotation(normalized), num * rotAccel);
		if (cartRenderers[0].isVisible && Mathff.DistSqrd(pos, Cam.inst.CamPos) < 400f)
		{
			float xAngle = (transform.position - pos).magnitude / 0.1f * 57.29578f;
			for (int i = 0; i < wheels.Length; i++)
			{
				wheels[i].Rotate(xAngle, 0f, 0f);
			}
		}
		transform.position = pos;
		return ArrivedAt(targetPos);
	}

	public bool ArrivedAt(Vector3 targetPos)
	{
		return Mathff.DistSqrdXZ(targetPos, pos) < arrivalRad * arrivalRad;
	}

	private void UpdatePathing()
	{
		Vector3 position = transform.position;
		Vector3 unoccupiedDestination = moveTarget.GetPos();
		if (unoccupiedDestination.x >= 0f && unoccupiedDestination.x < (float)World.inst.GridWidth && unoccupiedDestination.z >= 0f && unoccupiedDestination.z < (float)World.inst.GridHeight)
		{
			position.x = Mathff.Clamp(position.x, 0f, World.inst.GridWidth - 1);
			position.z = Mathff.Clamp(position.z, 0f, World.inst.GridHeight - 1);
			IMoveableUnit component = GetComponent<IMoveableUnit>();
			if (component != null)
			{
				Cell cellDataClamped = World.inst.GetCellDataClamped(unoccupiedDestination);
				if (cellDataClamped.Type == TerrainType.None && cellDataClamped.TopStructure == null)
				{
					unoccupiedDestination = OrdersManager.inst.GetUnoccupiedDestination(unoccupiedDestination, component, PathCell.GetBlocksFootPathForTransportCart, teamID, ignoreWallConnectivity: true);
				}
			}
			if (Mathff.DistSqrdXZ(transform.position, unoccupiedDestination) > 0.01f)
			{
				deferredPath.start = position;
				deferredPath.teamId = teamID;
				deferredPath.end = unoccupiedDestination;
				deferredPath.pathType = GamePath.PathType.TransportCartPathPostBlock;
				World.inst.threadedPather.RequestPath(deferredPath);
			}
			else
			{
				arrived = true;
			}
		}
		else
		{
			pathIdx = 0;
			path.Add(unoccupiedDestination);
		}
	}

	public Vector3 GetTargetPos(int pathDelta)
	{
		int num = Mathff.Clamp(pathIdx + pathDelta, 0, path.Count - 1);
		if (path.Count > 0)
		{
			float num2 = Mathff.DistXZ(path.data[num], transform.position);
			float t = Mathff.Clamp01(1f - num2);
			Vector3 result = path.data[num];
			if (path.Count >= 2 && num + 1 < path.Count)
			{
				result = Vector3.Lerp(path.data[num], path.data[num + 1], t);
			}
			return result;
		}
		return transform.position;
	}

	private void MoveToOrder(Ship.LogisticsOrder currOrder, Cell failedCell = null)
	{
		if (currOrder.endType == Ship.LogisticsOrderType.Building)
		{
			Building building = currOrder.GetBuilding();
			if (building != null)
			{
				MoveTo(building, displayPath: false);
			}
		}
		else
		{
			failedCell = null;
			MoveTo(World.inst.GetCellDataClamped(currOrder.GetEnd()), displayPath: false);
		}
	}

	private Ship.LogisticsOrder GetCurrentOrder()
	{
		if (logisticsOrders.Count > 0)
		{
			logisticsIdx = Mathff.Clamp(logisticsIdx, 0, logisticsOrders.Count - 1);
			return logisticsOrders[logisticsIdx];
		}
		return null;
	}

	private void NextOrder()
	{
		logisticsIdx++;
		if (logisticsIdx >= logisticsOrders.Count)
		{
			logisticsIdx = 0;
			if (routeEveryYears != 0)
			{
				SetPause(p: true);
				return;
			}
		}
		MoveToOrder(GetCurrentOrder());
	}

	public void SetPause(bool p)
	{
		paused = p;
		if (!paused)
		{
			delayTimer = 0f;
			if (logisticsIdx >= logisticsOrders.Count)
			{
				logisticsIdx = 0;
			}
			MoveToOrder(GetCurrentOrder());
			forceRepath = true;
		}
		issueButton.gameObject.SetActive(p);
	}

	public static void AdjustY(Cell cell, ref float yAdjust)
	{
		if (cell.OccupyingStructure.Count > 0)
		{
			Building building = cell.OccupyingStructure[0];
			if (building.IsBuilt())
			{
				if (building.uniqueNameHash == World.dockHash || building.uniqueNameHash == World.transportShipPortHash)
				{
					yAdjust = 0.06f;
				}
				else if (building.categoryHash == World.pathHash)
				{
					yAdjust = 0.1f;
				}
				else
				{
					yAdjust = 0f;
				}
				return;
			}
		}
		yAdjust = 0f;
	}

	public void UpdateSpeed(Cell cell)
	{
		float speedModifier = cell.speedModifier;
		activeSpeed = 0.9f * speedModifier;
		activeSpeed *= speedBonusMultiplier;
	}

	public void RemoveFromHold(ResourceAmount amt)
	{
		hold.Subtract(in amt);
	}

	public void AddToHold(ResourceAmount amt)
	{
		hold.Add(in amt);
	}

	public int TeamID()
	{
		return teamID;
	}

	public Vector3 GetPos()
	{
		return pos;
	}

	public ResourceAmount GetHold()
	{
		return hold;
	}

	public int GetMaxHold()
	{
		return 0;
	}

	Vector3 ICamTrackable.GetDesiredTrackingPos()
	{
		return pos;
	}

	Vector3 ISelectable.GetPos()
	{
		return transform.GetChild(0).position;
	}

	bool ISelectable.ExclusiveSelect()
	{
		return true;
	}

	bool ISelectable.ValidToSelect()
	{
		return true;
	}

	void ISelectable.SetHighlightImmediate(int colorIdx)
	{
		highlighter.SetOutlineImmediate(colorIdx);
	}

	bool ISelectable.InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		return false;
	}

	bool ISelectable.IntersectsRay(Ray ray, out float hitDist)
	{
		hitDist = float.MaxValue;
		if (Mathff.RaySphereIntersect(ray, transform.position, 1.5f) && collider.Raycast(ray, out var hitInfo, 10000f))
		{
			hitDist = hitInfo.distance;
			return true;
		}
		return false;
	}

	void ISelectable.OnSelected()
	{
		GameUI.inst.ClearUIForClick();
		if (teamID == 0)
		{
			GameUI.inst.shipLogisticsUI.SetSelectedTransport(this);
			GameUI.inst.shipLogisticsUI.SetVisible(v: true);
			SfxSystem.inst.PlayFromBank("TransportCartSelect", transform.position);
		}
		GameUI.inst.ClearCellSelected();
	}

	List<Ship.LogisticsOrder> ILogisticTransport.GetOrders()
	{
		return logisticsOrders;
	}

	string ILogisticTransport.GetErrorText()
	{
		return "";
	}

	bool ILogisticTransport.isErrorVisible()
	{
		return false;
	}

	bool ILogisticTransport.isPaused()
	{
		return Paused;
	}

	void ILogisticTransport.SetPaused(bool paused)
	{
		SetPause(paused);
		isPlayerSetPaused = paused;
	}

	Ship.Behavior ILogisticTransport.GetLogisiticBehavior()
	{
		return behavior;
	}

	void ILogisticTransport.SetLogisiticBehavior(Ship.Behavior behavior)
	{
		this.behavior = behavior;
	}

	void ILogisticTransport.SetMaxYear(int maxYear)
	{
		if (maxYear != routeEveryYears)
		{
			routeEveryYears = maxYear;
			routeCurrentYear = 0;
		}
	}

	int ILogisticTransport.GetMaxCycle()
	{
		return routeEveryYears;
	}

	string ILogisticTransport.GetDescription()
	{
		return "ScriptTerms.CartUIDescription";
	}

	void ILogisticTransport.SetOutlineImmediate(int i)
	{
		highlighter.SetOutlineImmediate(i);
	}

	string ILogisticTransport.GetTransportName()
	{
		if (string.IsNullOrEmpty(cartName))
		{
			return ScriptLocalization.Building_transportcart_FriendlyName;
		}
		return cartName;
	}

	void ILogisticTransport.SetTransportName(string name)
	{
		cartName = name;
	}

	bool ILogisticTransport.ValidForDocking(Building b)
	{
		return World.GetLandmassOwner(b.LandMass()) == Player.inst.PlayerLandmassOwner;
	}

	public void ValidateOrders()
	{
		for (int i = 0; i < logisticsOrders.Count; i++)
		{
			Ship.LogisticsOrder logisticsOrder = logisticsOrders[i];
			if (logisticsOrder.endType == Ship.LogisticsOrderType.Building && logisticsOrder.GetBuilding() == null)
			{
				logisticsOrder.endType = Ship.LogisticsOrderType.Position;
				moveTarget = World.inst.GetCellDataClamped(logisticsOrder.endPosition);
			}
		}
	}

	float IProjectileHitable.GetRadius()
	{
		return 1f;
	}

	Vector3 IProjectileHitable.GetPosition()
	{
		return pos;
	}

	Vector3 IProjectileHitable.GetVelocity()
	{
		return velocity;
	}

	Vector3 IProjectileHitable.GetPredictedPosition(float time)
	{
		return pos + velocity * time;
	}

	HitSfxResult IProjectileHitable.TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int attackerTeamID)
	{
		BroadcastMessage("OnTakeDamage", dmg, SendMessageOptions.DontRequireReceiver);
		lastAttackerTeamID = attackerTeamID;
		if (dmg > 10f)
		{
			OneOffEffect oneOffEffect = EffectsMan.inst.WoodHitEffect.Create(sourcePos);
			oneOffEffect.transform.rotation = Quaternion.LookRotation(-incomingVel);
			oneOffEffect.Play();
		}
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(attackerTeamID);
		if (landmassOwnerByTeamId != null && landmassOwnerByTeamId.hazardPay)
		{
			dmg *= (float)landmassOwnerByTeamId.hazardPayMultiplier;
		}
		Life -= dmg;
		return HitSfxResult.Wood;
	}

	bool IProjectileHitable.IsInvalid()
	{
		return Life <= 0f;
	}
}
