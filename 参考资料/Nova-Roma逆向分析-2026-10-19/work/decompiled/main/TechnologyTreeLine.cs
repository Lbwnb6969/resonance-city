using System.Collections.Generic;
using UnityEngine;

public class TechnologyTreeLine : MonoBehaviour
{
	[SerializeField]
	private RectTransform controlPointContainer;

	[SerializeField]
	public RectTransform node1Mask;

	[SerializeField]
	public RectTransform node2Mask;

	[SerializeField]
	private RectTransform controlPointPrefab;

	public RectTransform demoLock;

	public TechnologyTreeNode start;

	public TechnologyTreeNode end;

	public RectTransform startConnection;

	public RectTransform endConnection;

	public List<RectTransform> controlPoints = new List<RectTransform>(8);

	public LineRenderer backgroundLineRenderer;

	public LineRenderer foregroundLineRenderer;

	public LineRenderer fillForegroundLineRenderer;

	public Vector3[] backgroundPoints;

	public bool isAnimatingForeground;

	private void TryInit()
	{
		if (backgroundPoints == null || backgroundPoints.Length != 2 + controlPoints.Count)
		{
			backgroundPoints = new Vector3[2 + controlPoints.Count];
		}
	}

	private void Start()
	{
		if (Application.isPlaying)
		{
			for (int i = 0; i < controlPoints.Count; i++)
			{
				Util.SetActive(controlPoints[i].gameObject, active: false);
			}
		}
	}

	public void ForceRefresh()
	{
		RefreshVisuals();
	}

	public void TryRemoveSubdivide(RectTransform rectT)
	{
		if (rectT.parent == controlPointContainer)
		{
			controlPoints.Remove(rectT);
			Object.DestroyImmediate(rectT.gameObject);
		}
	}

	public void ClearControlPoints()
	{
		for (int i = 0; i < controlPoints.Count; i++)
		{
			Object.DestroyImmediate(controlPoints[i].gameObject);
		}
		controlPoints.Clear();
	}

	public RectTransform GetControlPointItem()
	{
		return Object.Instantiate(controlPointPrefab, controlPointContainer, worldPositionStays: false);
	}

	public RectTransform AddControlPoint()
	{
		RectTransform rectTransform = Object.Instantiate(controlPointPrefab, controlPointContainer, worldPositionStays: false);
		controlPoints.Add(rectTransform);
		return rectTransform;
	}

	public RectTransform InsertControlPoint(int idx)
	{
		RectTransform rectTransform = Object.Instantiate(controlPointPrefab, controlPointContainer, worldPositionStays: false);
		controlPoints.Insert(idx, rectTransform);
		return rectTransform;
	}

	public void ShowDemoLock(TechnologyTreeNode.LockForVersion type)
	{
		float num = 0f;
		num += Mathff.Dist((controlPoints.Count > 0) ? controlPoints[0].anchoredPosition : endConnection.anchoredPosition, startConnection.anchoredPosition);
		for (int i = 1; i < controlPoints.Count; i++)
		{
			num += Mathff.Dist(controlPoints[i].anchoredPosition, controlPoints[i - 1].anchoredPosition);
		}
		if (controlPoints.Count > 0)
		{
			float num2 = num;
			List<RectTransform> list = controlPoints;
			num = num2 + Mathff.Dist(list[list.Count - 1].anchoredPosition, endConnection.anchoredPosition);
		}
		float num3 = num / 2f;
		int num4 = 0;
		Vector3 vector = startConnection.anchoredPosition;
		Vector3 newPos = vector;
		while (num3 > 0f)
		{
			if (controlPoints.Count == 0)
			{
				Mathff.MoveTowards(vector, endConnection.anchoredPosition, num3, out var actualAmt, out newPos);
				num3 -= actualAmt;
				continue;
			}
			if (Mathff.MoveTowards(vector, controlPoints[num4].anchoredPosition, num3, out var actualAmt2, out newPos))
			{
				vector = newPos;
				num4++;
			}
			num3 -= actualAmt2;
		}
		demoLock.anchoredPosition = newPos;
		TooltipHook component = demoLock.GetComponent<TooltipHook>();
		switch (type)
		{
		case TechnologyTreeNode.LockForVersion.Demo:
			component.tooltipTerm = "technologytree_line_demo_lock_tooltip";
			break;
		case TechnologyTreeNode.LockForVersion.FutureUpdate:
			component.tooltipTerm = "updatelock";
			break;
		}
		Util.SetActive(demoLock.gameObject, active: true);
	}

	public void HideDemoLock()
	{
		Util.SetActive(demoLock.gameObject, active: false);
	}

	public void EditorTick()
	{
		RefreshVisuals();
	}

	public void RefreshVisuals()
	{
		TryInit();
		Util.SetActive(backgroundLineRenderer.gameObject, active: true);
		Util.SetActive(foregroundLineRenderer.gameObject, active: false);
		backgroundPoints[0] = startConnection.anchoredPosition;
		backgroundPoints[^1] = endConnection.anchoredPosition;
		for (int i = 0; i < controlPoints.Count; i++)
		{
			backgroundPoints[i + 1] = controlPoints[i].anchoredPosition;
		}
		backgroundLineRenderer.positionCount = backgroundPoints.Length;
		backgroundLineRenderer.SetPositions(backgroundPoints);
		fillForegroundLineRenderer.positionCount = backgroundPoints.Length;
		fillForegroundLineRenderer.SetPositions(backgroundPoints);
		node1Mask.anchoredPosition = startConnection.anchoredPosition;
		node1Mask.sizeDelta = startConnection.sizeDelta;
		node2Mask.anchoredPosition = endConnection.anchoredPosition;
		node2Mask.sizeDelta = endConnection.sizeDelta;
		for (int j = 0; j < controlPoints.Count; j++)
		{
			Util.SetActive(controlPoints[j].gameObject, active: true);
		}
	}

	public void SetFillForegroundVisibility(bool v)
	{
		Util.SetActive(fillForegroundLineRenderer.gameObject, v);
	}

	public void SetBackgroundLineVisibility(bool v)
	{
		Util.SetActive(backgroundLineRenderer.gameObject, v);
	}

	public void SetForegroundVisibility(bool v)
	{
		if (v && !foregroundLineRenderer.gameObject.activeSelf)
		{
			foregroundLineRenderer.positionCount = backgroundLineRenderer.positionCount;
			foregroundLineRenderer.SetPositions(backgroundPoints);
		}
		Util.SetActive(foregroundLineRenderer.gameObject, v);
	}
}
