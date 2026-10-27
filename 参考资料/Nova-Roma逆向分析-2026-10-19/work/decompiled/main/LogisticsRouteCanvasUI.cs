using System;
using UnityEngine;
using UnityEngine.UI;

public class LogisticsRouteCanvasUI : Tickable
{
	public static int poolCount = 0;

	private static ArrayExtRef<LogisticsRouteCanvasUI> pool = new ArrayExtRef<LogisticsRouteCanvasUI>(128);

	public static ArrayExtRef<LogisticsRouteCanvasUI> active = new ArrayExtRef<LogisticsRouteCanvasUI>(128);

	private static LogisticsRouteCanvasUI prefab;

	private static Transform container;

	private int idxIntoActiveList = -1;

	private int idxIntoPool;

	private bool isShutdown = true;

	private Building target;

	public AnimationCurve distCurve;

	public float scaleMultiplier = 1f;

	[NonSerialized]
	public RectTransform rectT;

	private Canvas canvas;

	private GraphicRaycaster gRaycaster;

	private FaceCamera faceCamera;

	public Button addBtn;

	public Button removeBtn;

	private bool isVisible;

	private Vector3 scale;

	private Vector3 toCam;

	private Vector3 pos;

	public static void Setup()
	{
		if (prefab == null)
		{
			prefab = Resources.Load<LogisticsRouteCanvasUI>("LogisticsRouteUI");
		}
		if (container == null)
		{
			container = new GameObject("Logistic Button Container").transform;
		}
	}

	public static void ReleaseFromPool(int idx, ArrayExtRef<LogisticsRouteCanvasUI> array)
	{
		array.RemoveAtSwapBoth(idx);
		if (array.Count > 0 && idx < array.Count)
		{
			array.data[idx].idxIntoPool = idx;
		}
	}

	public static void ReleaseFromList(int idx, ArrayExtRef<LogisticsRouteCanvasUI> array)
	{
		array.RemoveAtSwap(idx);
		if (array.Count > 0 && idx < array.Count)
		{
			array.data[idx].idxIntoActiveList = idx;
		}
	}

	public static LogisticsRouteCanvasUI GetLogisticButtonForBuilding(Building tBuilding)
	{
		if (tBuilding == null)
		{
			return null;
		}
		LogisticsRouteCanvasUI button;
		if (poolCount == pool.Count)
		{
			button = UnityEngine.Object.Instantiate(prefab, container);
			pool.Add(button);
			button.addBtn.onClick.AddListener(() =>
			{
				button.OnAddRoutes();
			});
			button.removeBtn.onClick.AddListener(() =>
			{
				button.OnRemoveRoutes();
			});
			button.idxIntoPool = pool.Count - 1;
			poolCount++;
		}
		else
		{
			button = pool.GetNew();
			button.idxIntoPool = pool.Count - 1;
		}
		button.Init(tBuilding);
		return button;
	}

	private void Init(Building tBuilding)
	{
		if (isShutdown)
		{
			isShutdown = false;
			rectT.position = tBuilding.GetPos();
			target = tBuilding;
			SetVisibility(v: true);
			active.Add(this);
			idxIntoActiveList = active.Count - 1;
		}
	}

	public void Shutdown()
	{
		if (!isShutdown)
		{
			isShutdown = true;
			SetVisibility(v: false);
			ReleaseFromPool(idxIntoPool, pool);
			ReleaseFromList(idxIntoActiveList, active);
		}
	}

	private void OnAddRoutes()
	{
		if (GameUI.inst.currCursorMode is LogisticsRouteCursorMode { currVehicle: var currVehicle } && !(currVehicle == null))
		{
			_ = World.inst.GetCellDataClamped(currVehicle.gameObject.transform.position).landMassIdx;
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(target);
			for (int i = 0; i < logisticsForBuilding.sourceBuildings.Count; i++)
			{
				currVehicle.TryAddRoute(target, logisticsForBuilding.sourceBuildings[i]);
			}
			LogisticsUI.inst.RefreshRouteList();
		}
	}

	private void OnRemoveRoutes()
	{
		if (GameUI.inst.currCursorMode is LogisticsRouteCursorMode { currVehicle: var currVehicle } && !(currVehicle == null))
		{
			LogisticsManager.LogisticsForStorage logisticsForBuilding = LogisticsManager.inst.GetLogisticsForBuilding(target);
			for (int i = 0; i < logisticsForBuilding.sourceBuildings.Count; i++)
			{
				currVehicle.TryRemoveRoute(target, logisticsForBuilding.sourceBuildings[i]);
			}
			LogisticsUI.inst.RefreshRouteList();
		}
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		if (v != isVisible)
		{
			Util.SetEnabled(canvas, v);
			Util.SetEnabled(gRaycaster, v);
			Util.SetEnabled(faceCamera, v);
			isVisible = v;
		}
	}

	private void Awake()
	{
		rectT = GetComponent<RectTransform>();
		canvas = GetComponent<Canvas>();
		gRaycaster = GetComponent<GraphicRaycaster>();
		faceCamera = GetComponent<FaceCamera>();
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (!isShutdown)
		{
			Vector3 camPos = Cam.inst.CamPos;
			pos = rectT.transform.position;
			toCam.x = pos.x - camPos.x;
			toCam.y = pos.y - camPos.y;
			toCam.z = pos.z - camPos.z;
			float time = Mathff.Magnitude(toCam);
			float num = distCurve.Evaluate(time) * scaleMultiplier;
			scale.x = (scale.y = (scale.z = 0.01f * num));
			rectT.transform.localScale = scale;
		}
	}
}
