using System;
using System.Collections.Generic;
using Assets;
using Drawing;
using UnityEngine;

public class LogisticCart : Tickable, ISelectable
{
	[SerializeField]
	private Collider collider;

	private ObjectHighlighter objHighlight;

	public InWorldExclamation issueButtonPrefab;

	[NonSerialized]
	public InWorldExclamation issueButton;

	private GamePath path = new GamePath();

	private ArrayExt<Vector3> pathPoints = new ArrayExt<Vector3>(32);

	private int pathIdx;

	private float pathDist;

	private float pathDistTraveled;

	public float pathSpeed = 0.4f;

	public float pathRotSpeed = 0.1f;

	private bool doDebugDraw;

	private CentripetalCatmullRomSpline cSpline = new CentripetalCatmullRomSpline();

	public Transform cartT;

	public Transform horseT;

	public Transform[] cartWheels;

	public List<MeshRenderer> mRenderers;

	public LogisticsVehicle vehicle;

	public bool drawDebug;

	public Vector3 stackOffset;

	private Vector3 heightTestPos;

	private Ray ray = new Ray(Vector3.zero, Vector3.down);

	private int teamID;

	private void Awake()
	{
		cSpline.isLooped = false;
		vehicle.RequestPathTo = RequestPathTo;
		mRenderers = new List<MeshRenderer>(GetComponentsInChildren<MeshRenderer>());
		objHighlight = ObjectHighlighter.SetupOutlines(gameObject, mRenderers, null);
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		LogisticsManager.inst.logisticCarts.Add(this);
		issueButton = UnityEngine.Object.Instantiate(issueButtonPrefab);
		issueButton.transform.SetParent(transform);
		issueButton.transform.localPosition = new Vector3(0f, 1f, 0f);
		issueButton.transform.localScale = new Vector3(1.2f, 1.2f, 1.2f);
		issueButton.transform.SetSiblingIndex(0);
		issueButton.onClick = () =>
		{
			OnSelected();
		};
		issueButton.gameObject.SetActive(value: false);
	}

	public override void OnDisableInternal()
	{
		base.OnEnableInternal();
		LogisticsManager.inst.logisticCarts.RemoveSwap(this);
		if ((bool)issueButton)
		{
			UnityEngine.Object.Destroy(issueButton.gameObject);
			issueButton = null;
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		Util.SetActive(issueButton.gameObject, vehicle.routes.Count == 0 && !(GameUI.inst.currCursorMode is LogisticsRouteCursorMode));
		TryConsumePath();
		switch (vehicle.GetStatus())
		{
		case 2:
			if (UpdateMovement(dt))
			{
				vehicle.SetStatus(3);
			}
			break;
		case 4:
			if (UpdateMovement(dt))
			{
				vehicle.SetStatus(5);
			}
			break;
		}
	}

	public float GetPathPercentComplete()
	{
		if (pathDist <= 0f)
		{
			return 0f;
		}
		return Mathff.Clamp01(pathDistTraveled / pathDist);
	}

	private bool UpdateMovement(float dt)
	{
		if (cSpline.splinePoints.Count < 2)
		{
			return true;
		}
		float num = dt * pathSpeed;
		Vector3 position = transform.position;
		bool result = TravelPath(num, out var pIdx, out var pos, out var fwd);
		pathDistTraveled = Mathff.Min(pathDist, pathDistTraveled + num);
		transform.position = pos;
		float t = dt * pathRotSpeed;
		transform.rotation = Quaternion.Lerp(transform.rotation, Quaternion.LookRotation(fwd, Vector3.up), t);
		TravelPath(num * 10f, out var _, out var pos2, out var fwd2);
		horseT.rotation = Quaternion.Lerp(horseT.rotation, Quaternion.LookRotation(fwd2, Vector3.up), t);
		if (drawDebug)
		{
			Draw.WireSphere(position, 0.1f, Color.white);
			Draw.WireSphere(pos, 0.1f, Color.yellow);
			Draw.WireSphere(pos2, 0.1f, Color.blue);
			Draw.Arrow(pos, pos + fwd, Color.magenta);
			Draw.Arrow(pos2, pos2 + fwd2, Color.red);
		}
		float xAngle = Mathff.Dist(position, pos) / 0.1f * 57.29578f;
		for (int i = 0; i < cartWheels.Length; i++)
		{
			cartWheels[i].Rotate(xAngle, 0f, 0f);
		}
		pathIdx = pIdx;
		vehicle.UpdateStacks(position + cartT.rotation * stackOffset, cartT.rotation);
		return result;
	}

	private bool TravelPath(float distance, out int pIdx, out Vector3 pos, out Vector3 fwd)
	{
		pIdx = pathIdx;
		pos = transform.position;
		bool flag = false;
		do
		{
			Vector3 next = cSpline.splinePoints[pIdx + 1];
			if (Mathff.MoveTowards(pos, next, distance, out var actualAmt, out var newPos))
			{
				pIdx++;
				flag = pIdx >= cSpline.splinePoints.Count - 1;
			}
			distance -= actualAmt;
			pos = newPos;
		}
		while (distance > 0f && !flag);
		pIdx = Mathff.Min(pIdx, cSpline.splinePoints.Count - 2);
		fwd = cSpline.splinePoints[pIdx + 1] - cSpline.splinePoints[pIdx];
		fwd.NonAllocateNormalize();
		return flag;
	}

	public void TryConsumePath()
	{
		if (path.status != GamePath.Status.Complete)
		{
			return;
		}
		cSpline.Reset();
		pathIdx = 0;
		pathDistTraveled = 0f;
		pathPoints.Clear();
		path.TryConsume(ref pathPoints);
		Renderer component = ((vehicle.GetStatus() == 2) ? vehicle.routes[vehicle.routeIdx].sourceBuilding : vehicle.routes[vehicle.routeIdx].targetBuilding).GetOffset().GetChild(0).GetComponent<Renderer>();
		if (component != null)
		{
			Bounds bounds = component.bounds;
			Vector3 min = bounds.min;
			Vector3 max = bounds.max;
			min.y = (max.y = 0f);
			bounds.SetMinMax(min, max);
			int num = pathPoints.Count - 1;
			while (num >= 0 && bounds.Contains(pathPoints.data[num]))
			{
				num--;
			}
			if (num < pathPoints.Count - 1 && num >= 0)
			{
				Ray ray = new Ray(pathPoints.data[num + 1], pathPoints.data[num + 1] - pathPoints.data[num]);
				if (bounds.IntersectRay(ray, out var distance))
				{
					for (int num2 = pathPoints.Count - 1; num2 > num; num2--)
					{
						pathPoints.RemoveAt(num2);
					}
					Vector3 point = ray.GetPoint(distance);
					if (Mathff.Dist(pathPoints.data[num], point) > 0.075f)
					{
						pathPoints.Add(point);
					}
				}
			}
		}
		cSpline.controlPoints.Add(transform.position);
		cSpline.controlPoints.Add(transform.position);
		for (int i = 0; i < pathPoints.Count; i++)
		{
			Vector3 vector = pathPoints.data[i];
			float num3 = TerrainGen.inst.GetInterpolatedHeight(vector);
			Building topStructure = World.inst.GetCellDataUnsafe((int)vector.x, (int)vector.z).TopStructure;
			if (topStructure != null && topStructure.IsBuilt())
			{
				if (topStructure.uniqueNameHash == World.stoneBridgeHash || topStructure.uniqueNameHash == World.woodBridgeHash)
				{
					heightTestPos.x = vector.x;
					heightTestPos.y = 100f;
					heightTestPos.z = vector.z;
					Bridge component2 = topStructure.GetComponent<Bridge>();
					this.ray.origin = heightTestPos;
					component2.walkPlane.Raycast(this.ray, out var enter);
					Vector3 point2 = this.ray.GetPoint(enter);
					if (point2.y > num3)
					{
						num3 = point2.y - 0.075f;
					}
				}
				else if (topStructure.uniqueNameHash == World.stoneRoadHash)
				{
					num3 += 0.1f;
				}
			}
			vector.y = num3;
			pathPoints.data[i] = vector;
			cSpline.controlPoints.Add(vector);
		}
		cSpline.controlPoints.Add(pathPoints.Last());
		cSpline.controlPoints.Add(pathPoints.Last());
		cSpline.GenerateSplinePoints();
		pathDist = 0f;
		for (int j = 1; j < cSpline.splinePoints.Count; j++)
		{
			pathDist += Mathff.Dist(cSpline.splinePoints[j - 1], cSpline.splinePoints[j]);
		}
	}

	private void RequestPathTo(Vector3 pos)
	{
		path.start = transform.position;
		path.teamId = TeamID();
		path.end = pos;
		path.pathType = GamePath.PathType.TransportCartPathPostBlock;
		World.inst.threadedPather.RequestPath(path);
		pathPoints.Clear();
		pathIdx = 0;
		pathDist = 0f;
	}

	public Vector3 GetPos()
	{
		return transform.position;
	}

	public bool ExclusiveSelect()
	{
		return true;
	}

	public bool ValidToSelect()
	{
		return true;
	}

	public void SetHighlightImmediate(int colorIdx)
	{
		objHighlight.SetOutlineImmediate(colorIdx);
	}

	public void OnSelected()
	{
		GameUI.inst.ClearCellSelected();
		GameUI.inst.ClearUIForClick();
		GameUI.inst.routeLogisticsCursorMode.currVehicle = vehicle;
		GameUI.inst.SetCursorModeLogisticsRoute();
	}

	public bool InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		Vector3 pos = GetPos();
		if ((float)minx <= pos.x && pos.x <= (float)maxx && (float)minz <= pos.z)
		{
			return pos.z <= (float)maxz;
		}
		return false;
	}

	public bool IntersectsRay(Ray ray, out float hitDist)
	{
		hitDist = float.MaxValue;
		if (Mathff.RaySphereIntersect(ray, transform.position, 1.5f) && collider.Raycast(ray, out var hitInfo, 10000f))
		{
			hitDist = hitInfo.distance;
			return true;
		}
		return false;
	}

	public void SetTeamID(int tID)
	{
		teamID = tID;
	}

	public int TeamID()
	{
		return teamID;
	}
}
