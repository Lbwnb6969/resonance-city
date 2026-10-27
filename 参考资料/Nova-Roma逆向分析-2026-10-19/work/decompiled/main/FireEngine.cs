using UnityEngine;

public class FireEngine : Tickable
{
	public enum Status
	{
		WaitingAtStation,
		HeadingToFire,
		FightingFire,
		HeadingToStation
	}

	[SerializeField]
	private Transform horseContainer;

	[SerializeField]
	private Transform engineContainer;

	[SerializeField]
	private Transform horseLeft;

	[SerializeField]
	private Transform horseRight;

	[SerializeField]
	private Transform pistonFront;

	[SerializeField]
	private Transform pistonBack;

	[SerializeField]
	private Transform pistonLever;

	[SerializeField]
	private Transform spout;

	[SerializeField]
	private Transform[] wheels;

	[SerializeField]
	private ParticleSystem[] waterPS;

	private bool hasArrived;

	public GamePath path = new GamePath();

	private CentripetalCatmullRomSpline pathSpline;

	private ArrayExt<Vector3> pathPoints = new ArrayExt<Vector3>(32);

	private Vector3 currEngineFwd;

	private Vector3 currHorseFwd;

	private float horseOffset1;

	private float horseOffset2;

	private int pathIdx;

	private float pathDist;

	private float pathDistTraveled;

	public float pathSpeed = 0.4f;

	public float pathRotSpeed = 0.1f;

	private float animTime;

	public float animSpeed = 1f;

	public Fire targetFire;

	public FireHouse owner;

	public Status status;

	private Vector3 heightTestPos;

	private Ray ray = new Ray(Vector3.zero, Vector3.down);

	public bool debugDraw;

	public void SetStatus(Status s)
	{
		switch (s)
		{
		case Status.HeadingToStation:
			MoveTo(owner.GetDockingPosition(this));
			targetFire = null;
			break;
		case Status.FightingFire:
		{
			for (int i = 0; i < waterPS.Length; i++)
			{
				waterPS[i].Play();
			}
			Vector3 center = targetFire.GetCenter();
			Vector3 position = spout.transform.position;
			Vector3 normalized = (center - position).normalized;
			normalized.y = 0f;
			spout.rotation = Quaternion.LookRotation(normalized);
			break;
		}
		case Status.WaitingAtStation:
		{
			Transform dockingAnchor = owner.GetDockingAnchor(this);
			SetPosFwd(dockingAnchor.position, dockingAnchor.forward);
			break;
		}
		}
		status = s;
	}

	private void Awake()
	{
		pathSpline = new CentripetalCatmullRomSpline();
		pathSpline.isLooped = false;
		pathSpline.resolution = 16;
		currEngineFwd = transform.forward;
		currHorseFwd = transform.forward;
		horseOffset1 = SRand.Range(0, 50);
		horseOffset2 = SRand.Range(50, 100);
	}

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (path.status == GamePath.Status.Complete)
		{
			pathPoints.ClearFast();
			path.TryConsume(ref pathPoints);
			pathPoints.PopLast();
			if (Mathff.DistSqrdXZ(transform.position, owner.GetDockingPosition(this)) > 1f)
			{
				if (pathPoints.Count >= 2)
				{
					Vector3 forward = horseContainer.forward;
					Vector3 normalized = (pathPoints.data[1] - pathPoints.data[0]).normalized;
					if (Vector3.Dot(forward, normalized) < -0.5f)
					{
						pathPoints.Insert(0, transform.position + forward * 1f);
						pathPoints.Insert(1, transform.position + horseContainer.right);
					}
				}
			}
			else
			{
				pathPoints.Insert(0, owner.GetDockExitPosition(this));
			}
			if (status == Status.HeadingToStation && Mathff.DistSqrdXZ(pathPoints.Last(), owner.GetDockExitPosition(this)) < 1f)
			{
				pathPoints.Add(owner.GetDockingPosition(this));
			}
			pathSpline.Reset();
			pathSpline.controlPoints.Add(transform.position);
			pathSpline.controlPoints.Add(transform.position);
			for (int i = 0; i < pathPoints.Count; i++)
			{
				if (i != 0 && i != pathPoints.Count - 1)
				{
					pathPoints.data[i].x += SRand.Range(-0.25f, 0.25f);
					pathPoints.data[i].z += SRand.Range(-0.25f, 0.25f);
				}
				Vector3 vector = pathPoints.data[i];
				float num = TerrainGen.inst.GetInterpolatedHeight(vector);
				Building topStructure = World.inst.GetCellDataUnsafe((int)vector.x, (int)vector.z).TopStructure;
				if (topStructure != null && topStructure.IsBuilt())
				{
					if (topStructure.uniqueNameHash == World.stoneBridgeHash || topStructure.uniqueNameHash == World.woodBridgeHash)
					{
						heightTestPos.x = vector.x;
						heightTestPos.y = 100f;
						heightTestPos.z = vector.z;
						Bridge component = topStructure.GetComponent<Bridge>();
						ray.origin = heightTestPos;
						if (component.walkPlane.Raycast(ray, out var enter))
						{
							Vector3 point = ray.GetPoint(enter);
							if (point.y > num)
							{
								num = point.y;
							}
						}
					}
					else if (topStructure.uniqueNameHash == World.stoneRoadHash)
					{
						num += 0.1f;
					}
				}
				vector.y = num;
				pathPoints.data[i] = vector;
				pathSpline.controlPoints.Add(vector);
			}
			pathSpline.controlPoints.Add(pathPoints.Last());
			pathSpline.controlPoints.Add(pathPoints.Last());
			pathSpline.GenerateSplinePoints();
			pathDist = 0f;
			for (int j = 1; j < pathSpline.splinePoints.Count; j++)
			{
				pathDist += Mathff.Dist(pathSpline.splinePoints[j - 1], pathSpline.splinePoints[j]);
			}
			pathIdx = 0;
			pathDistTraveled = 0f;
		}
		if (debugDraw)
		{
			pathSpline.DebugDraw();
		}
		bool flag = hasArrived;
		if (!hasArrived)
		{
			UpdateMovement(dt);
		}
		bool flag2 = hasArrived && !flag;
		switch (status)
		{
		case Status.HeadingToFire:
			if (!Fire.IsFireAlive(targetFire))
			{
				SetStatus(Status.HeadingToStation);
			}
			else if (flag2)
			{
				SetStatus(Status.FightingFire);
			}
			break;
		case Status.FightingFire:
		{
			if (!Fire.IsFireAlive(targetFire))
			{
				SetStatus(Status.HeadingToStation);
				break;
			}
			targetFire.ContributeToExtinguish();
			targetFire.ContributeToExtinguish();
			targetFire.ContributeToExtinguish();
			animTime += Time.deltaTime * animSpeed;
			float num2 = Mathf.Sin(animTime);
			pistonFront.localScale = new Vector3(1f, Mathf.Lerp(0.75f, 1.25f, (num2 + 1f) / 2f), 1f);
			pistonBack.localScale = new Vector3(1f, Mathf.Lerp(0.75f, 1.25f, (0f - num2 + 1f) / 2f), 1f);
			pistonLever.localRotation = Quaternion.AngleAxis(num2 * 15f, Vector3.forward);
			break;
		}
		case Status.HeadingToStation:
			if (flag2)
			{
				SetStatus(Status.WaitingAtStation);
			}
			break;
		}
	}

	public Cell GetTargetCell()
	{
		if (status != Status.HeadingToFire || status != Status.FightingFire)
		{
			return null;
		}
		return World.inst.GetCellData(path.end);
	}

	public bool IsBusy()
	{
		if (path.status == GamePath.Status.Uninitialized && !(owner.b.GetWorkerPercent() <= 0f) && owner.b.IsOpen() && status != Status.HeadingToFire)
		{
			return status == Status.FightingFire;
		}
		return true;
	}

	public void MoveTo(Vector3 pos)
	{
		if (!(Mathff.DistSqrd(pos, transform.position) <= 0.25f))
		{
			Vector3 start = transform.position;
			Vector3 end = pos;
			Vector3 dockingPosition = owner.GetDockingPosition(this);
			if (Mathff.DistSqrdXZ(dockingPosition, transform.position) <= 1f && Mathff.DistSqrdXZ(dockingPosition, pos) > 1f)
			{
				start = owner.GetDockExitPosition(this);
			}
			else if (Mathff.DistSqrdXZ(pos, dockingPosition) <= 1f && Mathff.DistSqrdXZ(transform.position, pos) > 1f)
			{
				end = owner.GetDockExitPosition(this);
			}
			path.start = start;
			path.teamId = owner.TeamID();
			path.end = end;
			path.pathType = GamePath.PathType.TransportCartPathPostBlock;
			World.inst.threadedPather.RequestPath(path);
			pathPoints.ClearFast();
			pathIdx = 0;
			hasArrived = false;
			for (int i = 0; i < waterPS.Length; i++)
			{
				waterPS[i].Stop();
			}
		}
	}

	public void SetFireTarget(Fire fire, Vector3 pos)
	{
		targetFire = fire;
		SetStatus(Status.HeadingToFire);
		MoveTo(pos);
	}

	private void UpdateMovement(float dt)
	{
		if (pathSpline.splinePoints.Count >= 2)
		{
			float num = dt * pathSpeed;
			_ = pathRotSpeed;
			Vector3 position = transform.position;
			bool flag = TravelPath(num, out var pIdx, out var pos, out var fwd);
			pathDistTraveled = Mathff.Min(pathDist, pathDistTraveled + num);
			transform.position = pos;
			TravelPath(num + 0.25f, out var _, out var _, out var fwd2);
			currHorseFwd = Vector3.MoveTowards(currHorseFwd, fwd2, num * 2.5f);
			horseContainer.rotation = Quaternion.LookRotation(currHorseFwd, Vector3.up);
			currEngineFwd = Vector3.MoveTowards(currEngineFwd, fwd, num * 1.5f);
			engineContainer.rotation = Quaternion.LookRotation(currEngineFwd, Vector3.up);
			float zAngle = Mathff.Dist(position, pos) / 0.1f * 57.29578f;
			for (int i = 0; i < wheels.Length; i++)
			{
				wheels[i].Rotate(0f, 0f, zAngle);
			}
			float time = Time.time;
			float num2 = 3.5f;
			horseLeft.localRotation = Quaternion.Euler(-15f + Mathff.Abs(Mathf.Sin(horseOffset1 + time * num2)) * 30f, 0f, 0f);
			horseRight.localRotation = Quaternion.Euler(-15f + Mathff.Abs(Mathf.Sin(horseOffset2 + time * num2)) * 30f, 0f, 0f);
			pathIdx = pIdx;
			if (flag)
			{
				hasArrived = true;
			}
		}
	}

	private bool TravelPath(float distance, out int pIdx, out Vector3 pos, out Vector3 fwd)
	{
		pIdx = pathIdx;
		pos = transform.position;
		bool flag = false;
		do
		{
			Vector3 next = pathSpline.splinePoints[pIdx + 1];
			if (Mathff.MoveTowards(pos, next, distance, out var actualAmt, out var newPos))
			{
				pIdx++;
				flag = pIdx >= pathSpline.splinePoints.Count - 1;
			}
			distance -= actualAmt;
			pos = newPos;
		}
		while (distance > 0f && !flag);
		pIdx = Mathff.Min(pIdx, pathSpline.splinePoints.Count - 2);
		fwd = pathSpline.splinePoints[pIdx + 1] - pathSpline.splinePoints[pIdx];
		fwd.NonAllocateNormalize();
		return flag;
	}

	public static bool IsBlockingCell(Cell targetC)
	{
		return World.inst.GetPathCell(targetC).blocksTransportCart;
	}

	public Vector3 GetPosition()
	{
		return transform.position;
	}

	public Vector3 GetForward()
	{
		return currHorseFwd;
	}

	public void SetPosFwd(Vector3 pos, Vector3 fwd)
	{
		transform.position = pos;
		currHorseFwd = fwd;
		currEngineFwd = fwd;
		horseContainer.rotation = Quaternion.LookRotation(currHorseFwd, Vector3.up);
		engineContainer.rotation = Quaternion.LookRotation(currHorseFwd, Vector3.up);
	}
}
