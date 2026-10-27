using System;
using System.Collections.Generic;
using Assets;
using Code;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class MiniMapUI : MonoBehaviour
{
	public enum MiniMapColor
	{
		DeepWater,
		Water,
		VeryFertileLand,
		FertileLand,
		BarrenLand,
		Tree,
		Rock,
		Stone,
		Iron,
		CivicBuilding,
		MilitaryBuilding,
		ResidentialBuilding,
		Road,
		AgricultureBuilding,
		CastleBlock,
		Marble,
		NumOfMiniMapEntries
	}

	public delegate bool PoolFilter<T>(T unit);

	[Serializable]
	public class MiniMapSaveData : SaveClass<MiniMapUI, MiniMapSaveData>
	{
		private float x;

		private float y;

		private float width;

		private float height;

		private bool isCollapsed;

		private bool cardinalLock;

		private bool editLock;

		private SerializableQuaternion rot;

		public override MiniMapSaveData Pack(MiniMapUI obj)
		{
			isCollapsed = obj.isCollapsed;
			cardinalLock = obj.cardinalLock;
			editLock = obj.editLock;
			rot = obj.mapTextureRect.rotation;
			return this;
		}

		public override MiniMapUI Unpack(MiniMapUI obj)
		{
			if (isCollapsed)
			{
				obj.Collapse();
			}
			obj.SetCardinalLock(cardinalLock);
			obj.SetEditLock(editLock);
			obj.mapTextureRect.rotation = rot;
			obj.mapRouteTextureRect.rotation = rot;
			return obj;
		}
	}

	public static MiniMapUI inst;

	public RectTransform rect;

	public Canvas canvas;

	private RectTransform canvasRectT;

	public GraphicRaycaster gRaycaster;

	public CanvasScaler canvasScaler;

	public RectTransform mapTextureRect;

	public RectTransform mapRouteTextureRect;

	public RectTransform mapBackgroundRect;

	public RectTransform expandRect;

	private int shipMarkerPoolCount;

	private List<GameObject> shipMarkerPool = new List<GameObject>(24);

	public GameObject shipMarkerPrefab;

	public RectTransform mapShipMarkerContainer;

	private int dragonMarkerPoolCount;

	private List<GameObject> dragonMarkerPool = new List<GameObject>(4);

	public GameObject dragonMarkerPrefab;

	public RectTransform mapDragonMarkerContainer;

	public GameObject armyMarkerPrefab;

	public RectTransform mapArmyMarkerContainer;

	private int legionMarkerPoolCount;

	private List<GameObject> legionMarkerPool = new List<GameObject>(32);

	public GameObject legionMarkerPrefab;

	public RectTransform mapLegionMarkerContainer;

	private int ogreMarkerPoolCount;

	private List<GameObject> ogreMarkerPool = new List<GameObject>(8);

	public GameObject ogreMarkerPrefab;

	public RectTransform mapOgreMarkerContainer;

	private int catapultMarkerPoolCount;

	private List<GameObject> catapultMarkerPool = new List<GameObject>(32);

	public GameObject catapultMarkerPrefab;

	public RectTransform mapCatapultMarkerContainer;

	private Vector2 markerScale;

	public List<MiniMapUIPing> pings = new List<MiniMapUIPing>(16);

	public MiniMapUIPing pingPrefab;

	public MiniMapUIPing firePingPrefab;

	public MiniMapUIPing plaguePingPrefab;

	public RectTransform mapPingMarkerContainer;

	public CanvasRenderer canvasRenderer;

	public Material cameraFrustrumMaterial;

	private Mesh mesh;

	public float Thickness = 5f;

	public GameObject exclamationIcon;

	public int CellsPerFrame = 32;

	public int maxMapSize = 500;

	public int minMapSize = 64;

	public Color[] colors = new Color[16];

	public RawImage mapImage;

	public RawImage mapRouteImage;

	private Texture2D mapTexture;

	private Texture2D mapRouteTexture;

	public Material fowMaterial;

	public AnimationCurve pingOpacity;

	public AnimationCurve pingScale;

	public GameObject cardinalOnObj;

	public GameObject editOnObj;

	public Vector2 widthOffset;

	public Vector2 heightOffset;

	public float routeThickness = 3f;

	private bool isFindingPath;

	private ArrayExt<ArrayExt<Vector2>> unitRoutes = new ArrayExt<ArrayExt<Vector2>>(32);

	private int unitIdx;

	private ArrayExt<IUnitControllable> units = new ArrayExt<IUnitControllable>(32);

	private float routeFade = float.MaxValue;

	public float routeFadeSpeed = 1f;

	public AnimationCurve routeFadeCurve;

	public Material routeMaterial;

	private Color routeColor = Color.white;

	public Image ringOutline;

	public Color ringColor;

	public Color invasionRingColor;

	public bool useNewMap;

	private Vector3 newMapPos = new Vector3(193f, -20f, 0f);

	private Vector2 newMapSize = new Vector2(150f, 150f);

	private bool isVisible;

	private Camera Camera3D;

	private int width;

	private int height;

	private Color[] mapPixels;

	private Color[] routePixels;

	private bool initilized;

	private Vector3 oldPos;

	private Vector3 oldSize;

	private Vector2 oldAnchorMin;

	private Vector2 oldAnchorMax;

	private Color cellColor;

	private int pixelIdx;

	private int totalSize;

	private Vector2 min;

	private Vector2 max = Vector2.zero;

	private Quaternion rotation;

	private Quaternion identityRot = Quaternion.identity;

	public float referenceMarkerScale = 100f;

	public float dragonScaleMod = 2f;

	private Vector2 rectSizeDelta;

	private Vector3[] verts = new Vector3[12];

	private Vector3[] corners = new Vector3[4];

	private int[] indicies = new int[36]
	{
		0, 2, 1, 0, 1, 3, 1, 5, 3, 3,
		5, 4, 3, 4, 6, 4, 8, 6, 6, 8,
		7, 6, 7, 9, 7, 11, 9, 9, 11, 10,
		9, 10, 0, 10, 2, 0
	};

	private bool skipRouteFrame = true;

	private bool wasRaidInProgress;

	private ArrayExt<Vector3> pathPos = new ArrayExt<Vector3>(64);

	private Vector2 origPos;

	private Vector2 origSize;

	private Vector2 sizeShiftDirection;

	private Vector2 centerOfRect;

	private Vector3 originMousePos;

	private Vector3 windowGrabPositionDifference;

	private bool isResizing;

	private bool isDragging;

	private bool maybeClicking;

	private MiniMapUIPing exclamationPing;

	private int envoyTeamId = -1;

	public GameObject cardinalLockObj;

	public GameObject editLockObj;

	private bool cardinalLock;

	private bool editLock;

	private bool isCollapsed;

	private const int MIN_PERIODIC_PING_TIME = 15;

	private const int MAX_PERIODIC_PING_TIME = 35;

	private float periodicPingTimer;

	private float maxPeriodicPingTimer = 35f;

	private bool doPeriodicPing;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		if (v && !CanDisplayMiniMap())
		{
			v = false;
		}
		Util.SetEnabled(this, v);
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private bool CanDisplayMiniMap()
	{
		if (GameState.inst.CurrMode == GameState.inst.mainMenuMode)
		{
			return GameState.inst.mainMenuMode.GetState() == MainMenuMode.State.NewMap;
		}
		return true;
	}

	public void Awake()
	{
		inst = this;
		canvasRectT = canvas.GetComponent<RectTransform>();
		mesh = new Mesh();
		canvasRenderer.SetMesh(mesh);
		canvasRenderer.materialCount = 1;
		canvasRenderer.SetMaterial(cameraFrustrumMaterial, 0);
	}

	private void Start()
	{
		GameUI gameUI = GameUI.inst;
		gameUI.ResolutionChanged = (Action)Delegate.Combine(gameUI.ResolutionChanged, new Action(OnResolutionChange));
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(OnControllerChanged));
		if (Settings.inst.savedMiniMapData != null)
		{
			Settings.inst.savedMiniMapData.Unpack(this);
		}
	}

	public void OnDestroy()
	{
		GameUI gameUI = GameUI.inst;
		gameUI.ResolutionChanged = (Action)Delegate.Remove(gameUI.ResolutionChanged, new Action(OnResolutionChange));
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(OnControllerChanged));
	}

	private void OnControllerChanged(bool isControllerActive)
	{
		cardinalLockObj.SetActive(!isControllerActive);
		editLockObj.SetActive(!isControllerActive);
	}

	public void Setup(int width, int height)
	{
		if (this.width != width || this.height != height || mapTexture == null)
		{
			this.width = width;
			this.height = height;
			totalSize = width * height;
			if (mapTexture != null)
			{
				UnityEngine.Object.Destroy(mapTexture);
			}
			mapTexture = new Texture2D(width, height, TextureFormat.ARGB32, mipChain: false);
			mapTexture.name = "MiniMapTexture";
			mapTexture.filterMode = FilterMode.Point;
			mapImage.texture = mapTexture;
			if (mapRouteTexture != null)
			{
				UnityEngine.Object.Destroy(mapRouteTexture);
			}
			mapRouteTexture = new Texture2D(width, height, TextureFormat.ARGB32, mipChain: false);
			mapRouteTexture.name = "MiniMapRouteTexture";
			mapRouteTexture.filterMode = FilterMode.Point;
			mapRouteImage.texture = mapRouteTexture;
			mapPixels = new Color[totalSize];
			routePixels = new Color[totalSize];
			ResetVisualRouteLines();
			Camera3D = GameObject.Find("3D GUI Camera").GetComponent<Camera>();
		}
		SetCardinalLock(locked: false);
		SetEditLock(locked: false);
		initilized = false;
		pixelIdx = 0;
	}

	public void SetNewMap(bool isNewMap)
	{
		if (isNewMap)
		{
			if (!useNewMap && rect.anchorMin.y < 1f)
			{
				oldPos = rect.anchoredPosition;
				oldSize = rect.sizeDelta;
				oldAnchorMin = rect.anchorMin;
				oldAnchorMax = rect.anchorMax;
			}
			rect.anchorMin = new Vector2(0f, 1f);
			rect.anchorMax = new Vector2(0f, 1f);
			rect.anchoredPosition = newMapPos;
			rect.sizeDelta = newMapSize;
			cardinalLockObj.SetActive(value: false);
			editLockObj.SetActive(value: false);
		}
		else
		{
			if (useNewMap)
			{
				rect.anchorMin = oldAnchorMin;
				rect.anchorMax = oldAnchorMax;
				rect.anchoredPosition = oldPos;
				rect.sizeDelta = oldSize;
			}
			if (!GamepadControl.inst.isControllerActive)
			{
				cardinalLockObj.SetActive(value: false);
				editLockObj.SetActive(value: false);
			}
		}
		useNewMap = isNewMap;
	}

	public void Update()
	{
		if (LoadSave.Loading || mapTexture == null)
		{
			return;
		}
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		if (pixelIdx == totalSize)
		{
			mapTexture.SetPixels(mapPixels);
			mapTexture.Apply();
			pixelIdx = 0;
			initilized = true;
		}
		bool flag = RaiderSystem.inst.IsRaidInProgress();
		if (flag != wasRaidInProgress)
		{
			ringOutline.color = ringColor;
			if (flag)
			{
				ringOutline.color = invasionRingColor;
			}
		}
		wasRaidInProgress = flag;
		UpdateMapPixels();
		float num = Input.mousePosition.x / (float)Screen.width - 1f;
		float num2 = Input.mousePosition.y / (float)Screen.height - 1f;
		Vector2 vector = new Vector2(num * canvasRectT.sizeDelta.x, num2 * canvasRectT.sizeDelta.y);
		maybeClicking &= Vector3.Distance(vector, originMousePos) < 5f;
		if (maybeClicking && Input.GetMouseButtonUp(0))
		{
			RectTransformUtility.ScreenPointToLocalPointInRectangle(mapTextureRect, Input.mousePosition, Camera3D, out var localPoint);
			MiniMapUIPing miniMapUIPing = UnityEngine.Object.Instantiate(pingPrefab, mapPingMarkerContainer);
			miniMapUIPing.pingSpeed = 2f;
			PingAtMapLocation(miniMapUIPing, localPoint);
			Vector2 vector2 = (localPoint + rect.sizeDelta / 2f) / rect.sizeDelta;
			Vector3 vector3 = new Vector3(vector2.x * (float)World.inst.GridWidth, 0f, vector2.y * (float)World.inst.GridHeight);
			vector3.y = Mathff.Max(Water.inst.transform.position.y, TerrainGen.inst.GetInterpolatedHeight(vector3));
			Cam.inst.SetDesiredTrackingPos(vector3);
			isDragging = false;
			isResizing = false;
		}
		else if (maybeClicking && Input.GetMouseButtonUp(1))
		{
			RectTransformUtility.ScreenPointToLocalPointInRectangle(mapTextureRect, Input.mousePosition, Camera3D, out var localPoint2);
			Vector2 vector4 = (localPoint2 + rect.sizeDelta / 2f) / rect.sizeDelta;
			Cell cellData = World.inst.GetCellData((int)(vector4.x * (float)World.inst.GridWidth), (int)(vector4.y * (float)World.inst.GridHeight));
			if (cellData != null)
			{
				UnitControlSystem.inst.DoPlayerMoveTo(cellData.Center2D, cellData);
				if (units.Count > 0)
				{
					MiniMapUIPing miniMapUIPing2 = UnityEngine.Object.Instantiate(pingPrefab, mapPingMarkerContainer);
					miniMapUIPing2.pingSpeed = 1.25f;
					miniMapUIPing2.color = Color.green;
					PingAtMapLocation(miniMapUIPing2, localPoint2);
				}
			}
			isDragging = false;
			isResizing = false;
		}
		if (!skipRouteFrame && isFindingPath)
		{
			isFindingPath = !TryCollectUnitRoutes();
			if (!isFindingPath)
			{
				DrawRouteLines();
			}
		}
		skipRouteFrame = false;
		if (routeFade < 1f)
		{
			routeFade += unscaledDeltaTime * routeFadeSpeed;
			if (routeFade >= 1f)
			{
				ResetVisualRouteLines();
			}
			else
			{
				Color color = mapRouteImage.color;
				color.a = routeFadeCurve.Evaluate(routeFade);
				mapRouteImage.color = color;
			}
		}
		if (isDragging)
		{
			UpdateDragging();
		}
		else if (isResizing)
		{
			UpdateResizing();
		}
		Vector3 vector5 = Cam.inst.cam.transform.forward.xz2D();
		float num3 = 0f - Mathf.Atan2(vector5.y, vector5.x) + 1.5707f;
		rotation = Quaternion.AngleAxis(num3 * 57.29578f, new Vector3(0f, 0f, 1f));
		if (!cardinalLock)
		{
			mapTextureRect.rotation = rotation;
			mapRouteTextureRect.rotation = rotation;
		}
		_ = useNewMap;
		Vector3 vector6 = new Vector3(rect.sizeDelta.x / referenceMarkerScale, rect.sizeDelta.x / referenceMarkerScale, 1f);
		if (exclamationIcon.activeSelf)
		{
			exclamationIcon.GetComponent<RectTransform>().rotation = identityRot;
		}
		doPeriodicPing = false;
		periodicPingTimer += unscaledDeltaTime;
		if (periodicPingTimer >= 0.15f)
		{
			doPeriodicPing = true;
			periodicPingTimer = 0f;
		}
		rectSizeDelta = rect.sizeDelta;
		PoolGroup(UnitSystem.inst.legionUnits, ref legionMarkerPool, ref legionMarkerPoolCount, legionMarkerPrefab, mapLegionMarkerContainer, vector6, doColor: true, (LegionUnit unit) =>
		{
			if (unit.IsBeingCarried() || unit.IsDead())
			{
				return true;
			}
			Vector3 pos = unit.GetPos();
			return !FogOfWar.inst.IsVisible((int)pos.x, (int)pos.z);
		}, (LegionUnit unit) => unit != null && unit.TeamID() == 1);
		PoolGroup(ShipSystem.inst.ships, ref shipMarkerPool, ref shipMarkerPoolCount, shipMarkerPrefab, mapShipMarkerContainer, vector6, doColor: true, (ShipBase shipBase) => (shipBase != null && shipBase.type == ShipBase.ShipType.Fishing) ? true : false, (ShipBase unit) => unit != null && unit.teamID == 1);
		PoolGroup(SiegeMonster.monsters, ref ogreMarkerPool, ref ogreMarkerPoolCount, ogreMarkerPrefab, mapOgreMarkerContainer, vector6, doColor: true, null, (SiegeMonster unit) => true);
		bool inprogress = DragonSpawn.inst.IsAttackInProgress();
		PoolGroup(DragonSpawn.inst.currentDragons, ref dragonMarkerPool, ref dragonMarkerPoolCount, dragonMarkerPrefab, mapDragonMarkerContainer, vector6 * dragonScaleMod, doColor: false, (Dragon unit) => !inprogress, (Dragon unit) => true);
		PoolGroup(SiegeCatapultSystem.siegeCatapults, ref catapultMarkerPool, ref catapultMarkerPoolCount, catapultMarkerPrefab, mapCatapultMarkerContainer, vector6, doColor: true);
		Ray ray = PointingSystem.GetRay();
		Plane plane = new Plane(Vector3.up, Vector3.zero);
		Vector3 zero = Vector3.zero;
		for (int num4 = 0; num4 < 2; num4++)
		{
			for (int num5 = 0; num5 < 2; num5++)
			{
				ray = Cam.inst.cam.ViewportPointToRay(new Vector3(num5, num4, 0f));
				zero = ((!plane.Raycast(ray, out var enter)) ? ray.GetPoint(300f) : ray.GetPoint(enter));
				num = zero.x / (float)World.inst.GridWidth;
				num2 = zero.z / (float)World.inst.GridHeight;
				zero.x = num * mapTextureRect.rect.size.x;
				zero.y = num2 * mapTextureRect.rect.size.y;
				zero.z = 0f;
				corners[num5 + num4 * 2] = zero;
			}
		}
		verts[0] = corners[0];
		verts[1] = (corners[0] - corners[1]).normalized * Thickness + corners[0];
		verts[2] = (corners[0] - corners[2]).normalized * Thickness + corners[0];
		verts[3] = corners[2];
		verts[4] = (corners[2] - corners[0]).normalized * Thickness + corners[2];
		verts[5] = (corners[2] - corners[3]).normalized * Thickness + corners[2];
		verts[6] = corners[3];
		verts[7] = (corners[3] - corners[2]).normalized * Thickness + corners[3];
		verts[8] = (corners[3] - corners[1]).normalized * Thickness + corners[3];
		verts[9] = corners[1];
		verts[10] = (corners[1] - corners[3]).normalized * Thickness + corners[1];
		verts[11] = (corners[1] - corners[0]).normalized * Thickness + corners[1];
		mesh.vertices = verts;
		mesh.triangles = indicies;
		mesh.RecalculateNormals();
		canvasRenderer.SetMesh(mesh);
		Vector3 localScale = default;
		for (int num6 = 0; num6 < pings.Count; num6++)
		{
			MiniMapUIPing miniMapUIPing3 = pings[num6];
			miniMapUIPing3.rect.rotation = identityRot;
			miniMapUIPing3.duration += unscaledDeltaTime * miniMapUIPing3.pingSpeed;
			if (miniMapUIPing3.animate)
			{
				localScale.x = (localScale.y = (localScale.z = miniMapUIPing3.pingScale.Evaluate(miniMapUIPing3.duration) * miniMapUIPing3.pingScaleStrength));
				miniMapUIPing3.rect.localScale = localScale;
				Color color2 = miniMapUIPing3.image.color;
				color2.a = miniMapUIPing3.pingOpacity.Evaluate(miniMapUIPing3.duration) * miniMapUIPing3.pingOpacityStrength;
				miniMapUIPing3.image.color = color2;
			}
			if (!(miniMapUIPing3.duration >= 1f))
			{
				continue;
			}
			if (!miniMapUIPing3.continues)
			{
				miniMapUIPing3.currFlash++;
				if (miniMapUIPing3.currFlash >= miniMapUIPing3.maxflashCount)
				{
					UnityEngine.Object.Destroy(pings[num6].rect.gameObject);
					pings.RemoveAt(num6);
					num6--;
				}
			}
			miniMapUIPing3.duration = 0f;
		}
	}

	public void DrawRoutes()
	{
		unitIdx = 0;
		units.ClearFast();
		unitRoutes.ClearFast();
		ResetVisualRouteLines();
		UnitControlSystem.inst.GetSelectedUnits(ref units);
		isFindingPath = true;
		skipRouteFrame = true;
	}

	private bool TryCollectUnitRoutes()
	{
		for (int i = unitIdx; i < units.Count; i++)
		{
			IUnitControllable unitControllable = units.data[i];
			ArrayExt<Vector2> arrayExt = new ArrayExt<Vector2>(32);
			pathPos.ClearFast();
			switch (unitControllable.GetUnitType())
			{
			case 0:
				if (unitControllable is LegionUnit legionUnit)
				{
					LegionGroup legionGroup = legionUnit.GetGroup();
					GamePath gamePath = LegionSystem.Inst.deferredPaths[legionUnit.GetGroupID()];
					if (legionGroup.needsPathing || !legionGroup.pathReady || gamePath.status != GamePath.Status.Complete)
					{
						return false;
					}
					pathPos.Add(new Vector3(gamePath.start.x, 0f, gamePath.start.z));
					pathPos.AddRange(gamePath.result);
				}
				break;
			case 3:
			{
				ShipBase shipBase = unitControllable as ShipBase;
				if (shipBase != null)
				{
					if (shipBase.deferredPath.status != GamePath.Status.Uninitialized)
					{
						return false;
					}
					pathPos.Add(new Vector2(shipBase.deferredPath.start.x, shipBase.deferredPath.start.z));
					pathPos.AddRange(shipBase.deferredPath.result);
				}
				break;
			}
			}
			if (pathPos.Count > 1)
			{
				for (int j = 0; j < pathPos.Count; j++)
				{
					if (j <= 0 || !(pathPos.data[j - 1] == pathPos.data[j]))
					{
						arrayExt.Add(new Vector2(pathPos.data[j].x, pathPos.data[j].z));
					}
				}
				if (arrayExt.Count >= 2)
				{
					unitRoutes.Add(arrayExt);
				}
			}
			unitIdx = i;
		}
		return true;
	}

	private void DrawRouteLines()
	{
		ResetVisualRouteLines();
		for (int i = 0; i < unitRoutes.Count; i++)
		{
			ArrayExt<Vector2> arrayExt = unitRoutes.data[i];
			for (int j = 0; j < arrayExt.Count - 1; j++)
			{
				DrawLine(arrayExt.data[j + 1], arrayExt.data[j]);
			}
		}
		mapRouteTexture.SetPixels(routePixels);
		mapRouteTexture.Apply();
		routeFade = 0f;
	}

	private void DrawLine(Vector2 p1, Vector2 p2)
	{
		Vector2 vector = p1;
		float num = 1f / Mathf.Sqrt(Mathff.Sqr(p2.x - p1.x) + Mathff.Sqr(p2.y - p1.y));
		float num2 = 0f;
		while ((int)vector.x != (int)p2.x || (int)vector.y != (int)p2.y)
		{
			vector = Vector2.Lerp(p1, p2, num2);
			num2 += num;
			routePixels[(int)vector.y * width + (int)vector.x] = Color.white;
		}
	}

	private void ResetVisualRouteLines()
	{
		Util.Memset(routePixels, 0);
		mapRouteTexture.SetPixels(routePixels);
		mapRouteTexture.Apply();
	}

	public void OnBeginDrag(BaseEventData eventData)
	{
		float num = Input.mousePosition.x / (float)Screen.width - 1f;
		float num2 = Input.mousePosition.y / (float)Screen.height - 1f;
		originMousePos = new Vector2(num * canvasRectT.sizeDelta.x, num2 * canvasRectT.sizeDelta.y);
		centerOfRect = rect.anchoredPosition - rect.sizeDelta / 2f;
		maybeClicking = true;
		if (!editLock && !useNewMap)
		{
			if (Vector2.Distance(new Vector2(originMousePos.x, originMousePos.y), centerOfRect) / (rect.sizeDelta.x / 2f) > 0.8f)
			{
				origPos = rect.anchoredPosition;
				origSize = rect.sizeDelta;
				sizeShiftDirection.x = Mathf.Sign(centerOfRect.x - originMousePos.x);
				sizeShiftDirection.y = Mathf.Sign(centerOfRect.y - originMousePos.y);
				isResizing = true;
				isDragging = false;
			}
			else
			{
				windowGrabPositionDifference = rect.anchoredPosition - (Vector2)originMousePos;
				isResizing = false;
				isDragging = true;
			}
		}
	}

	public void OnEndDrag(BaseEventData eventData)
	{
		isDragging = false;
		isResizing = false;
	}

	private void CalcMinMax()
	{
		min = new Vector2(rect.sizeDelta.x - canvasRectT.sizeDelta.x + widthOffset.x, rect.sizeDelta.y - canvasRectT.sizeDelta.y + heightOffset.x);
		max = new Vector2(widthOffset.y, heightOffset.y);
	}

	public void OnResolutionChange()
	{
	}

	public void SetupEnvoyExclamation(Vector3 worldPos, int teamId)
	{
		if (exclamationPing == null)
		{
			exclamationPing = UnityEngine.Object.Instantiate(pingPrefab, mapPingMarkerContainer);
			exclamationPing.color = Color.yellow;
			exclamationPing.continues = true;
			exclamationIcon.SetActive(value: true);
			exclamationIcon.GetComponent<RectTransform>().anchoredPosition = PingAtWorldLocation(exclamationPing, worldPos);
			envoyTeamId = teamId;
		}
	}

	public void RemoveEnvoyExclamation(int teamId)
	{
		if (exclamationPing != null && teamId == envoyTeamId)
		{
			pings.Remove(exclamationPing);
			DestroyExclamationPing();
		}
	}

	internal void ResetPings()
	{
		if (exclamationPing != null)
		{
			pings.Remove(exclamationPing);
			DestroyExclamationPing();
		}
		for (int i = 0; i < pings.Count; i++)
		{
			UnityEngine.Object.Destroy(pings[i].gameObject);
		}
		pings.Clear();
	}

	private void DestroyExclamationPing()
	{
		UnityEngine.Object.Destroy(exclamationPing.rect.gameObject);
		exclamationPing = null;
		exclamationIcon.SetActive(value: false);
		envoyTeamId = -1;
	}

	public Vector3 PingAtWorldLocation(MiniMapUIPing ping, Vector3 worldPos)
	{
		float num = worldPos.x / (float)World.inst.GridWidth;
		float num2 = worldPos.z / (float)World.inst.GridHeight;
		Vector3 vector = new Vector3(num * rect.sizeDelta.x - rect.sizeDelta.x / 2f, num2 * rect.sizeDelta.y - rect.sizeDelta.y / 2f, -5f);
		PingAtMapLocation(ping, vector);
		return vector;
	}

	public void PingAtMapLocation(MiniMapUIPing ping, Vector3 mapPos)
	{
		ping.mapPos = mapPos;
		ping.duration = 0f;
		ping.gameObject.SetActive(value: true);
		ping.rect.anchoredPosition = mapPos;
		ping.image.color = ping.color;
		pings.Add(ping);
	}

	public Vector3 WorldToMapPosition(Vector3 worldPos)
	{
		float num = worldPos.x / (float)World.inst.GridWidth;
		float num2 = worldPos.z / (float)World.inst.GridHeight;
		Vector2 sizeDelta = rect.sizeDelta;
		return new Vector3(num * sizeDelta.x - sizeDelta.x / 2f, num2 * sizeDelta.y - sizeDelta.y / 2f, 0f);
	}

	public MiniMapUIPing SetupFirePing(Vector3 worldPos)
	{
		MiniMapUIPing miniMapUIPing = UnityEngine.Object.Instantiate(firePingPrefab, mapPingMarkerContainer);
		miniMapUIPing.color = Color.white;
		miniMapUIPing.continues = true;
		PingAtWorldLocation(miniMapUIPing, worldPos);
		MiniMapUIPing miniMapUIPing2 = UnityEngine.Object.Instantiate(pingPrefab, mapPingMarkerContainer);
		miniMapUIPing2.maxflashCount = 2;
		miniMapUIPing2.color = Color.red;
		miniMapUIPing2.pingSpeed = 0.75f;
		miniMapUIPing2.pingOpacityStrength = 0.5f;
		PingAtWorldLocation(miniMapUIPing2, worldPos);
		return miniMapUIPing;
	}

	public MiniMapUIPing SetupPlaguePing(Vector3 worldPos)
	{
		MiniMapUIPing miniMapUIPing = UnityEngine.Object.Instantiate(plaguePingPrefab, mapPingMarkerContainer);
		miniMapUIPing.color = Color.white;
		miniMapUIPing.duration = 2f;
		PingAtWorldLocation(miniMapUIPing, worldPos);
		MiniMapUIPing miniMapUIPing2 = UnityEngine.Object.Instantiate(pingPrefab, mapPingMarkerContainer);
		miniMapUIPing2.maxflashCount = 2;
		miniMapUIPing2.color = Color.black;
		miniMapUIPing2.pingSpeed = 0.75f;
		miniMapUIPing2.pingOpacityStrength = 0.5f;
		miniMapUIPing2.pingScaleStrength = 2f;
		PingAtWorldLocation(miniMapUIPing2, worldPos);
		return miniMapUIPing;
	}

	public void RemovePing(MiniMapUIPing ping)
	{
		for (int i = 0; i < pings.Count; i++)
		{
			MiniMapUIPing miniMapUIPing = pings[i];
			if (miniMapUIPing == ping)
			{
				pings.RemoveAt(i);
				UnityEngine.Object.Destroy(miniMapUIPing.gameObject);
				break;
			}
		}
	}

	public void OnCardinalLockToggle(BaseEventData eventData)
	{
		SfxSystem.PlayUiSelect();
		SetCardinalLock(!cardinalLock);
	}

	public void SetCardinalLock(bool locked)
	{
		cardinalLock = locked;
		cardinalOnObj.SetActive(!locked);
	}

	public void OnEditLockToggle(BaseEventData eventData)
	{
		SfxSystem.PlayUiSelect();
		SetEditLock(!editLock);
	}

	public void SetEditLock(bool locked)
	{
		editLock = locked;
		editOnObj.SetActive(!locked);
	}

	public Vector3 VerifyMapBounds()
	{
		CalcMinMax();
		Vector3 vector = rect.anchoredPosition;
		if (!isCollapsed)
		{
			if (vector.x < min.x)
			{
				vector.x = min.x;
			}
			if (vector.y < min.y)
			{
				vector.y = min.y;
			}
			if (vector.x > max.x)
			{
				vector.x = max.x;
			}
			if (vector.y > max.y)
			{
				vector.y = max.y;
			}
		}
		else
		{
			float num = expandRect.sizeDelta.x - canvasRectT.sizeDelta.x - widthOffset.x;
			float num2 = expandRect.sizeDelta.x + heightOffset.y - canvasRectT.sizeDelta.y;
			if (vector.x < num)
			{
				vector.x = num;
			}
			if (vector.y < num2)
			{
				vector.y = num2;
			}
			if (vector.x > widthOffset.y)
			{
				vector.x = widthOffset.y;
			}
			if (vector.y > heightOffset.y)
			{
				vector.y = heightOffset.y;
			}
		}
		rect.anchoredPosition = vector;
		return vector;
	}

	public void UpdateDragging()
	{
		if (useNewMap)
		{
			return;
		}
		float num = Input.mousePosition.x / (float)Screen.width - 1f;
		float num2 = Input.mousePosition.y / (float)Screen.height - 1f;
		Vector3 vector = new Vector3(num * canvasRectT.sizeDelta.x, num2 * canvasRectT.sizeDelta.y, 1f);
		vector += windowGrabPositionDifference;
		if (!isCollapsed)
		{
			if (vector.x < min.x)
			{
				vector.x = min.x;
			}
			if (vector.y < min.y)
			{
				vector.y = min.y;
			}
			if (vector.x > max.x)
			{
				vector.x = max.x;
			}
			if (vector.y > max.y)
			{
				vector.y = max.y;
			}
			return;
		}
		float num3 = expandRect.sizeDelta.x - canvasRectT.sizeDelta.x - widthOffset.x;
		float num4 = expandRect.sizeDelta.x + heightOffset.y - canvasRectT.sizeDelta.y;
		if (vector.x < num3)
		{
			vector.x = num3;
		}
		if (vector.y < num4)
		{
			vector.y = num4;
		}
		if (vector.x > widthOffset.y)
		{
			vector.x = widthOffset.y;
		}
		if (vector.y > heightOffset.y)
		{
			vector.y = heightOffset.y;
		}
	}

	public void UpdateResizing()
	{
		if (useNewMap)
		{
			return;
		}
		float num = Input.mousePosition.x / (float)Screen.width - 1f;
		Vector2 vector = new Vector3(y: (Input.mousePosition.y / (float)Screen.height - 1f) * canvasRectT.sizeDelta.y, x: num * canvasRectT.sizeDelta.x);
		Vector2 vector2 = new Vector3(sizeShiftDirection.x, sizeShiftDirection.y, 0f) * origSize + centerOfRect;
		float num2 = Vector3.Distance(vector, vector2) - Vector3.Distance(originMousePos, vector2);
		Vector2 vector3 = origSize + new Vector2(num2, num2);
		float num3 = float.MaxValue;
		float num4 = float.MaxValue;
		if (vector3.x < (float)minMapSize)
		{
			vector3.x = minMapSize;
		}
		if (vector3.y < (float)minMapSize)
		{
			vector3.y = minMapSize;
		}
		if (vector3.x > (float)maxMapSize)
		{
			vector3.x = maxMapSize;
		}
		else if (sizeShiftDirection.x > 0f && rect.anchoredPosition.x < vector3.x - canvasRectT.sizeDelta.x + widthOffset.x)
		{
			num3 = canvasRectT.sizeDelta.x + rect.anchoredPosition.x - widthOffset.x;
		}
		else if (sizeShiftDirection.x < 0f && origPos.x + num2 - widthOffset.y > 0f)
		{
			num3 = origSize.x - origPos.x + widthOffset.y;
		}
		if (vector3.y > (float)maxMapSize)
		{
			vector3.y = maxMapSize;
		}
		else if (sizeShiftDirection.y > 0f && rect.anchoredPosition.y + canvasRectT.sizeDelta.y - heightOffset.x < vector3.y)
		{
			num4 = canvasRectT.sizeDelta.y + rect.anchoredPosition.y - heightOffset.x;
		}
		else if (sizeShiftDirection.y < 0f && origPos.y + num2 - heightOffset.y > 0f)
		{
			num4 = origSize.y - origPos.y + heightOffset.y;
		}
		if (num3 != float.MaxValue || num4 != float.MaxValue)
		{
			if (num3 < num4)
			{
				vector3.x = (vector3.y = num3);
			}
			else
			{
				vector3.x = (vector3.y = num4);
			}
		}
		for (int i = 0; i < pings.Count; i++)
		{
			pings[i].mapPos.x = pings[i].mapPos.x / (rect.sizeDelta.x / 2f) * (vector3.x / 2f);
			pings[i].mapPos.y = pings[i].mapPos.y / (rect.sizeDelta.y / 2f) * (vector3.y / 2f);
			pings[i].rect.anchoredPosition = pings[i].mapPos;
		}
		if (exclamationIcon.gameObject.activeSelf)
		{
			RectTransform component = exclamationIcon.GetComponent<RectTransform>();
			Vector3 vector4 = component.anchoredPosition;
			vector4.x = vector4.x / (rect.sizeDelta.x / 2f) * (vector3.x / 2f);
			vector4.y = vector4.y / (rect.sizeDelta.y / 2f) * (vector3.y / 2f);
			component.anchoredPosition = vector4;
		}
		_ = origSize - vector3;
		min.x = vector3.x - canvasRectT.sizeDelta.x + widthOffset.x;
		min.y = vector3.y - canvasRectT.sizeDelta.y + heightOffset.x;
		Vector2 vector5 = new Vector2(sizeShiftDirection.x, sizeShiftDirection.y);
		if (vector5.x == 1f)
		{
			vector5.x = 0f;
		}
		if (vector5.y == 1f)
		{
			vector5.y = 0f;
		}
	}

	public float remap(float start1, float stop1, float start2, float stop2, float value)
	{
		return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
	}

	public void UpdateMapPixels(bool doAllAndApply = false)
	{
		Cell[] cellsData = World.inst.GetCellsData();
		if (doAllAndApply)
		{
			pixelIdx = 0;
		}
		Color color = mapPixels[pixelIdx];
		int cellsPerFrame = CellsPerFrame;
		if (!initilized | doAllAndApply)
		{
			cellsPerFrame = totalSize;
		}
		for (int i = 0; i < cellsPerFrame; i++)
		{
			Cell cell = cellsData[pixelIdx];
			if (cell.Type == TerrainType.Water)
			{
				color = colors[0];
			}
			else if (DynamicWater.inst.IsWater(cell.x, cell.z))
			{
				color = colors[1];
			}
			else if (cell.Type == TerrainType.Obstruction || cell.Type == TerrainType.EmptyCave || cell.Type == TerrainType.WolfDen)
			{
				color = colors[6];
			}
			else if (cell.HasTerrainResourceType(2))
			{
				color = colors[7];
			}
			else if (cell.HasTerrainResourceType(5))
			{
				color = colors[8];
			}
			else if (cell.HasTerrainResourceType(14))
			{
				color = colors[15];
			}
			else if (World.inst.treeSystem.ItemAmount(cell) > 0)
			{
				color = colors[5];
			}
			else if (cell.OccupyingStructure.Count > 0 && cell.OccupyingStructure[0].IsVisibleForFog())
			{
				if (cell.StructureCompareCategoryNameAll(World.castleblockHash))
				{
					color = colors[14];
				}
				else if ((bool)cell.StructureFind(World.farmHash))
				{
					color = colors[13];
				}
				else
				{
					color = ((!cell.StructureCompareCategoryNameAll(World.pathHash)) ? colors[11] : colors[12]);
				}
			}
			else if (cell.GetFertility() == 0)
			{
				color = colors[4];
			}
			else if (cell.GetFertility() == 1)
			{
				color = colors[3];
			}
			else if (cell.GetFertility() == 2)
			{
				color = colors[2];
			}
			mapPixels[pixelIdx] = color;
			pixelIdx++;
			if (pixelIdx >= totalSize)
			{
				break;
			}
		}
		if (doAllAndApply)
		{
			mapTexture.SetPixels(mapPixels);
			mapTexture.Apply();
			pixelIdx = 0;
		}
	}

	public void Collapse()
	{
		mapBackgroundRect.gameObject.SetActive(value: false);
		mapTextureRect.gameObject.SetActive(value: false);
		expandRect.gameObject.SetActive(value: true);
		canvas.sortingOrder = 5;
		isCollapsed = true;
	}

	public void Expand()
	{
		mapBackgroundRect.gameObject.SetActive(value: true);
		mapTextureRect.gameObject.SetActive(value: true);
		expandRect.gameObject.SetActive(value: false);
		canvas.sortingOrder = 2;
		isCollapsed = false;
	}

	public void PoolGroup<T>(ArrayExt<T> items, ref List<GameObject> pool, ref int poolCount, GameObject markerPrefab, RectTransform rectContainer, Vector3 scale, bool doColor = false, PoolFilter<T> filter = null, PoolFilter<T> periodicPingFilter = null)
	{
		int num = 0;
		for (int i = 0; i < items.Count; i++)
		{
			T val = items.data[i];
			if (filter != null && filter(val))
			{
				continue;
			}
			Vector3 position = (val as IProjectileHitable).GetPosition();
			if (num == poolCount)
			{
				if (poolCount == pool.Count)
				{
					GameObject gameObject = UnityEngine.Object.Instantiate(markerPrefab, rectContainer, worldPositionStays: false);
					gameObject.SetActive(value: true);
					pool.Add(gameObject);
					poolCount++;
				}
				else
				{
					pool[num].SetActive(value: true);
					poolCount++;
				}
			}
			position.x = Mathff.Clamp01(position.x / (float)World.inst.GridWidth) * rectSizeDelta.x - rectSizeDelta.x / 2f;
			position.y = Mathff.Clamp01(position.z / (float)World.inst.GridHeight) * rectSizeDelta.y - rectSizeDelta.y / 2f;
			position.z = -1f;
			RectTransform component = pool[num].GetComponent<RectTransform>();
			component.anchoredPosition = position;
			component.localScale = scale;
			int teamId = 1;
			if (val is ISelectable selectable)
			{
				teamId = selectable.TeamID();
				if (doColor)
				{
					component.GetComponent<Image>().color = GetMarkerColor(teamId);
				}
			}
			if (doPeriodicPing && periodicPingFilter != null && periodicPingFilter(val) && SRand.Range(0, 70) == 0)
			{
				MiniMapUIPing miniMapUIPing = UnityEngine.Object.Instantiate(pingPrefab, component);
				miniMapUIPing.pingSpeed = 0.5f;
				miniMapUIPing.pingScaleStrength = 2f;
				miniMapUIPing.pingOpacityStrength = 1.25f;
				miniMapUIPing.color = GetMarkerColor(teamId);
				miniMapUIPing.image.color = miniMapUIPing.color;
				miniMapUIPing.rect.anchoredPosition = Vector3.zero;
				miniMapUIPing.gameObject.SetActive(value: true);
				pings.Add(miniMapUIPing);
			}
			num++;
		}
		if (num < poolCount)
		{
			int j = num;
			for (int num2 = poolCount; j < num2; j++)
			{
				pool[j].SetActive(value: false);
				poolCount--;
			}
		}
	}

	private Color GetMarkerColor(int teamId)
	{
		switch (teamId)
		{
		case -2:
			return Color.white;
		default:
		{
			int bannerIdx = World.GetLandmassOwnerByTeamId(teamId).bannerIdx;
			return World.inst.liverySets[bannerIdx].bannerColor;
		}
		case 1:
			return Color.red;
		}
	}
}
