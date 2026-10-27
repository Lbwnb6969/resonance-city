using System;
using Assets;
using UnityEngine;
using cakeslice;

public class LogisticArrow : MonoBehaviour
{
	private static int poolCount = 0;

	private static ArrayExt<LogisticArrow> pool = new ArrayExt<LogisticArrow>(64);

	public static ArrayExt<LogisticArrow> active = new ArrayExt<LogisticArrow>(64);

	private static LogisticArrow prefab;

	private static Transform container;

	public static Color unassignedRouteColor = new Color(1f, 1f, 1f, 0.2f);

	public static Color assignedRouteColor = new Color(0f, 0.83f, 1f, 0.2f);

	public static Color activeRouteColor = new Color(0f, 1f, 0.46f, 0.2f);

	public static Color disabledRouteColor = new Color(0.54f, 0.54f, 0.54f, 0.39f);

	private int idxIntoActiveList = -1;

	private int idxIntoPool;

	private bool isShutdown = true;

	private const float endOfArrowDist = 0.8f;

	public float animSpeed = 25f;

	public float startOffset;

	public float endOffset = 1.5f;

	public Transform arrowT;

	public Transform lineT;

	public LogisticsRouteCanvasUI rCanvasUI;

	internal static Material sharedMaterial;

	private Material instanceMaterial;

	[SerializeField]
	private Renderer[] renderers;

	private ObjectHighlighter highlight;

	private bool isComplete;

	private float dist;

	private float maxDist;

	private Vector3 pos;

	private Vector3 dir;

	[NonSerialized]
	public Building targetBuilding;

	[NonSerialized]
	public Building sourceBuilding;

	public static ArrayExtRef<LogisticArrow> deferShutdown = new ArrayExtRef<LogisticArrow>(256);

	private bool isButtonVisible;

	private Color currColor;

	public static void ReleaseFromPool(int idx, ArrayExt<LogisticArrow> array)
	{
		array.RemoveAtSwapBoth(idx);
		if (array.Count > 0 && idx < array.Count)
		{
			array.data[idx].idxIntoPool = idx;
		}
	}

	public static void ReleaseFromList(int idx, ArrayExt<LogisticArrow> array)
	{
		array.RemoveAtSwap(idx);
		if (array.Count > 0 && idx < array.Count)
		{
			array.data[idx].idxIntoActiveList = idx;
		}
	}

	public static LogisticArrow GetLogisticArrow(Building tBuilding, Building sBuilding)
	{
		if (tBuilding == null || sBuilding == null)
		{
			return null;
		}
		for (int i = 0; i < active.Count; i++)
		{
			LogisticArrow logisticArrow = active.data[i];
			if (logisticArrow.targetBuilding == tBuilding && logisticArrow.sourceBuilding == sBuilding)
			{
				deferShutdown.Remove(logisticArrow);
				return null;
			}
		}
		LogisticArrow logisticArrow2;
		if (poolCount == pool.Count)
		{
			logisticArrow2 = UnityEngine.Object.Instantiate(prefab, container);
			pool.Add(logisticArrow2);
			logisticArrow2.rCanvasUI.addBtn.onClick.AddListener(() =>
			{
				if (GameUI.inst.currCursorMode is LogisticsRouteCursorMode { currVehicle: var currVehicle } && !(currVehicle == null))
				{
					currVehicle.TryAddRoute(tBuilding, sBuilding);
					LogisticsUI.inst.RefreshRouteList();
				}
			});
			logisticArrow2.rCanvasUI.removeBtn.onClick.AddListener(() =>
			{
				if (GameUI.inst.currCursorMode is LogisticsRouteCursorMode { currVehicle: var currVehicle } && !(currVehicle == null))
				{
					currVehicle.TryRemoveRoute(tBuilding, sBuilding);
					LogisticsUI.inst.RefreshRouteList();
				}
			});
			logisticArrow2.idxIntoPool = pool.Count - 1;
			poolCount++;
		}
		else
		{
			logisticArrow2 = pool.GetNew();
			logisticArrow2.idxIntoPool = pool.Count - 1;
		}
		logisticArrow2.Init(tBuilding, sBuilding);
		return logisticArrow2;
	}

	public static void HideArrows()
	{
		for (int num = active.Count - 1; num >= 0; num--)
		{
			active.data[num].Shutdown();
		}
		deferShutdown.ClearFast();
	}

	public static void DeferHideArrows()
	{
		for (int i = 0; i < active.Count; i++)
		{
			if (!deferShutdown.Contains(active.data[i]))
			{
				deferShutdown.Add(active.data[i]);
			}
		}
	}

	public static void Setup()
	{
		if (prefab == null)
		{
			prefab = Resources.Load<LogisticArrow>("LogisticArrow");
		}
		if (container == null)
		{
			container = new GameObject("Logistic Arrow Container").transform;
		}
		if (sharedMaterial == null)
		{
			sharedMaterial = Resources.Load<Material>("LogisticArrowMaterial");
			sharedMaterial.color = unassignedRouteColor;
		}
	}

	public void SetButtonVisibility(bool isVisible, bool hasRoute)
	{
		Util.SetActive(rCanvasUI.addBtn.gameObject, !hasRoute & isVisible);
		Util.SetActive(rCanvasUI.removeBtn.gameObject, hasRoute & isVisible);
		isButtonVisible = isVisible;
	}

	private void Awake()
	{
		highlight = new ObjectHighlighter();
		for (int i = 0; i < renderers.Length; i++)
		{
			highlight.outlines.Add(new Outline(renderers[i]));
		}
		instanceMaterial = new Material(sharedMaterial);
	}

	private Vector3 GetPosRelative(Building start, Building end)
	{
		Vector3 vector = end.Center() - start.Center();
		float a = vector.magnitude - 0.01f;
		return start.Center() + vector.normalized * Mathff.Min(a, Mathf.Max(start.size.x, start.size.z) * 0.75f * 1.4142135f);
	}

	private void Init(Building tBuilding, Building sBuilding)
	{
		if (isShutdown)
		{
			isShutdown = false;
			enabled = true;
			targetBuilding = tBuilding;
			sourceBuilding = sBuilding;
			isComplete = false;
			SetColor(unassignedRouteColor);
			Vector3 posRelative = GetPosRelative(tBuilding, sBuilding);
			Vector3 vector = sBuilding.Center();
			Vector3 vector2 = posRelative - vector;
			dir = vector2.normalized;
			dist = 0f;
			maxDist = Mathf.Max(0f, vector2.magnitude - startOffset);
			float num = startOffset;
			if (maxDist == 0f)
			{
				maxDist = vector2.magnitude;
				num = 0f;
			}
			Vector3 vector3 = dir * num;
			pos = vector + vector3;
			transform.position = pos;
			transform.forward = dir;
			arrowT.position = pos + dir * Mathff.Min(dist, maxDist);
			Vector3 input = dir * (maxDist + 0.8f);
			input.NonAllocateDivide(2f);
			input.NonAllocateAdd(pos);
			rCanvasUI.rectT.position = input;
			arrowT.localScale = new Vector3(1f, 1f, 0f);
			lineT.localScale = new Vector3(1f, 1f, 0f);
			Util.SetActive(gameObject, active: true);
			Util.SetActive(arrowT.gameObject, active: false);
			rCanvasUI.SetVisibility(v: false);
			active.Add(this);
			idxIntoActiveList = active.Count - 1;
		}
	}

	public void Shutdown()
	{
		if (!isShutdown)
		{
			isShutdown = true;
			enabled = false;
			Util.SetActive(gameObject, active: false);
			rCanvasUI.SetVisibility(v: false);
			ReleaseFromPool(idxIntoPool, pool);
			ReleaseFromList(idxIntoActiveList, active);
		}
	}

	public void SetOutlineImmediate(int colorIdx)
	{
		highlight.SetOutlineImmediate(colorIdx);
	}

	public void SetColor(Color color)
	{
		if (!(currColor == color))
		{
			instanceMaterial.color = color;
			for (int i = 0; i < renderers.Length; i++)
			{
				renderers[i].material = ((color == unassignedRouteColor) ? sharedMaterial : instanceMaterial);
			}
			currColor = color;
		}
	}

	private void Update()
	{
		if (!isComplete)
		{
			float unscaledDeltaTime = Time.unscaledDeltaTime;
			dist += (maxDist - dist) * unscaledDeltaTime * animSpeed;
			lineT.localScale = new Vector3(1f, 1f, Mathff.Min(dist, maxDist));
			float num = ((maxDist > 0f) ? Mathff.Clamp01(dist / maxDist) : 1f);
			arrowT.localScale = new Vector3(num, num, num);
			arrowT.position = pos + dir * Mathff.Min(dist, maxDist);
			Util.SetActive(arrowT.gameObject, num > 0f);
			if (num >= 1f)
			{
				isComplete = true;
			}
		}
	}

	public void ForceInstantAnimation()
	{
		dist = maxDist + 0.8f;
	}
}
