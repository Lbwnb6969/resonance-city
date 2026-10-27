using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using FMOD.Studio;
using FMODUnity;
using UnityEngine;

public class ShipBase : Tickable, ICamTrackable, IProjectileHitable
{
	public enum ShipType
	{
		Transport,
		Merchant,
		Fishing,
		TroopTransport,
		VikingTroopTransport,
		OgreTroopTransport,
		PlayerMerchant,
		SeedShip,
		SettlerShip
	}

	public enum State
	{
		Sailing,
		Sinking
	}

	[Serializable]
	public class ShipData
	{
		public ShipType type;

		public SerializableVector3 pos;

		public SerializableQuaternion rot;

		public bool arrived = true;

		[OptionalField(VersionAdded = 2)]
		public int teamId;

		[OptionalField(VersionAdded = 2)]
		public Guid guid = Guid.NewGuid();

		[OptionalField(VersionAdded = 2)]
		public float life = -1f;

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			life = -1f;
			teamId = 0;
			guid = Guid.NewGuid();
		}
	}

	[NonSerialized]
	protected int _teamID;

	public InWorldExclamation issueButtonPrefab;

	[NonSerialized]
	public InWorldExclamation issueButton;

	public Transform wake;

	public ParticleSystem prowfx;

	private Transform xform;

	private FrameUpdater pathUpdater;

	public Collider collider;

	private static int frameID;

	public ObjectHighlighter highlighter;

	[NonSerialized]
	public State state;

	[NonSerialized]
	public Guid guid = Guid.NewGuid();

	public ShipType type;

	private Vector3 pos;

	private Quaternion rot;

	public bool arrived = true;

	public bool lastArrived = true;

	public bool pathFailed;

	public bool hadTrimmed;

	public MeshRenderer[] meshes;

	[NonSerialized]
	public ArrayExt<Vector3> path = new ArrayExt<Vector3>(24);

	public int pathIdx;

	public float offsetY = -0.05f;

	private bool forceUpdatePath;

	[NonSerialized]
	public IMoveTarget moveTarget;

	private bool showPath;

	public ShipDynamicData dynamics;

	public List<MeshRenderer> meshRenderersNeedingOutline = new List<MeshRenderer>();

	private EventInstance sailingSound;

	[NonSerialized]
	public GamePath deferredPath = new GamePath();

	public bool debugDraw;

	private bool doFirstUpdate = true;

	[NonSerialized]
	public float life = 50f;

	public float maxLife = 50f;

	private int lastAttackerTeamID = -1;

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

	public ShipData GetData()
	{
		return new ShipData
		{
			type = type,
			pos = pos,
			rot = rot,
			arrived = arrived,
			guid = guid,
			teamId = teamID,
			life = life
		};
	}

	public void SetFromShipData(ShipData data)
	{
		if (Mathff.IsNaN(data.pos))
		{
			Cell[] cellsData = World.inst.GetCellsData();
			for (int i = 0; i < cellsData.Length; i++)
			{
				if (cellsData[i].Type == TerrainType.Water)
				{
					data.pos = cellsData[i].Center2D;
				}
			}
		}
		xform.position = (pos = (dynamics.Pos = data.pos));
		xform.rotation = (rot = data.rot);
		arrived = data.arrived;
		lastArrived = arrived;
		type = data.type;
		Init(data.teamId);
		guid = data.guid;
		life = data.life;
		if (life == -1f)
		{
			life = maxLife;
		}
		if (life <= 0f)
		{
			SetState(State.Sinking);
		}
	}

	public bool IntersectsRay(Ray ray, out float hitDist)
	{
		hitDist = float.MaxValue;
		if (Mathff.RaySphereIntersect(ray, dynamics.Pos, 1.5f) && collider.Raycast(ray, out var hitInfo, 10000f))
		{
			hitDist = hitInfo.distance;
			return true;
		}
		return false;
	}

	public void SetPos(Vector3 p)
	{
		xform.position = (pos = (dynamics.Pos = p));
	}

	public virtual void Init(int tId)
	{
		_teamID = tId;
		IUnitControllable component = GetComponent<IUnitControllable>();
		if (component != null)
		{
			UnitSystem.inst.TryAddUnit(component);
		}
	}

	public void UpdateMaterial()
	{
		if (_teamID >= 0)
		{
			for (int i = 0; i < meshes.Length; i++)
			{
				meshes[i].material = World.GetLandmassOwnerByTeamId(_teamID).UniMaterialFogClip;
			}
		}
	}

	public Vector3 GetPos()
	{
		return pos;
	}

	public Quaternion GetRot()
	{
		return rot;
	}

	public void MoveTo(IMoveTarget target, bool displayPath = true)
	{
		moveTarget = target;
		forceUpdatePath = true;
		arrived = false;
		lastArrived = false;
		pathFailed = false;
		showPath = displayPath;
		UpdatePathing();
	}

	private int GetTeamIdForPos(Vector3 end)
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(World.inst.GetCellDataClamped(end).landMassIdx);
		int num = 0;
		if (landmassOwner != null)
		{
			num = landmassOwner.teamId;
			if (num < 0)
			{
				num = 0;
			}
		}
		return num;
	}

	private void UpdatePathing()
	{
		if (moveTarget != null && !moveTarget.Equals(null))
		{
			Vector3 outPos = pos;
			if (teamID > 0 && PathCell.GetBlocksWaterPath(World.inst.GetPathCellClamped(outPos), teamID))
			{
				ShipDynamicData.GetClosestPointToBlockedCell(outPos, out outPos, teamID);
			}
			Vector3 unoccupiedDestination = moveTarget.GetPos();
			if (unoccupiedDestination.x >= 0f && unoccupiedDestination.x < (float)World.inst.GridWidth && unoccupiedDestination.z >= 0f && unoccupiedDestination.z < (float)World.inst.GridHeight)
			{
				outPos.x = Mathff.Clamp(outPos.x, 0f, World.inst.GridWidth - 1);
				outPos.z = Mathff.Clamp(outPos.z, 0f, World.inst.GridHeight - 1);
				IMoveableUnit component = GetComponent<IMoveableUnit>();
				if (component != null)
				{
					Cell cellDataClamped = World.inst.GetCellDataClamped(unoccupiedDestination);
					if (cellDataClamped.Type == TerrainType.Water && cellDataClamped.TopStructure == null)
					{
						unoccupiedDestination = OrdersManager.inst.GetUnoccupiedDestination(unoccupiedDestination, component, PathCell.GetBlocksWaterPath, teamID, ignoreWallConnectivity: true);
					}
				}
				if (!dynamics.ArrivedAt(unoccupiedDestination))
				{
					deferredPath.start = outPos;
					if (teamID == -2)
					{
						deferredPath.teamId = GetTeamIdForPos(unoccupiedDestination);
					}
					else
					{
						deferredPath.teamId = teamID;
					}
					deferredPath.end = unoccupiedDestination;
					deferredPath.pathType = GamePath.PathType.BoatPathPostBlock;
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
		else
		{
			moveTarget = null;
		}
	}

	public override void OnEnableInternal()
	{
		base.OnEnableInternal();
		ShipSystem.inst.Add(this);
		issueButton = UnityEngine.Object.Instantiate(issueButtonPrefab);
		issueButton.transform.SetParent(transform);
		issueButton.transform.localPosition = new Vector3(0f, 2.5f, 0f);
		issueButton.transform.localScale = new Vector3(1.3f, 1.3f, 1.3f);
		issueButton.transform.SetSiblingIndex(0);
		issueButton.onClick = () =>
		{
			SendMessage("OnClickedButton", SendMessageOptions.DontRequireReceiver);
		};
		issueButton.gameObject.SetActive(value: false);
		pathUpdater = new FrameUpdater(ref frameID, 30);
		xform = transform;
		for (int num = 0; num < transform.childCount; num++)
		{
			MeshRenderer component = transform.GetChild(num).GetComponent<MeshRenderer>();
			if ((bool)component)
			{
				meshRenderersNeedingOutline.Add(component);
			}
		}
		highlighter = ObjectHighlighter.SetupOutlines(gameObject, meshRenderersNeedingOutline, null);
		life = maxLife;
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		ShipSystem.inst.Remove(this);
		if (highlighter != null)
		{
			highlighter.Release();
			highlighter = null;
		}
		if ((bool)issueButton)
		{
			UnityEngine.Object.Destroy(issueButton.gameObject);
			issueButton = null;
		}
	}

	private void SetState(State newState)
	{
		if (newState == State.Sinking && state != State.Sinking)
		{
			SfxSystem.inst.PlayFromBankIfVisible("VikingShipSink", transform.position);
			IUnitControllable component = GetComponent<IUnitControllable>();
			if (component != null)
			{
				UnitSystem.inst.NotifyUnitKilled(component, lastAttackerTeamID);
			}
			sailingSound.stop(STOP_MODE.ALLOWFADEOUT);
		}
		state = newState;
	}

	public override void Tick(float dt, int currFrame)
	{
		if (doFirstUpdate)
		{
			sailingSound = SfxSystem.inst.PlayFromBankIfVisible("VikingShipSail_LP", transform.position);
			Vector3 position = wake.position;
			wake.position = position;
			Vector3 position2 = prowfx.transform.position;
			prowfx.transform.position = position2;
			if (dynamics.isMoving)
			{
				if (!prowfx.isPlaying)
				{
					prowfx.Play();
				}
			}
			else if (prowfx.isPlaying)
			{
				prowfx.Stop();
			}
			doFirstUpdate = false;
		}
		if (arrived && !lastArrived)
		{
			ShipSystem.inst.SendArrivedEvent(this);
		}
		lastArrived = arrived;
		dynamics.isMoving = state == State.Sailing && !arrived;
		dynamics.radMul += (float)(dynamics.isMoving ? 1 : (-2)) * dt * 0.5f;
		dynamics.radMul = Mathff.Clamp01(dynamics.radMul);
		if (life <= 0f)
		{
			SetState(State.Sinking);
		}
		switch (state)
		{
		case State.Sinking:
		{
			Vector3 position3 = xform.position;
			position3.y -= dt * 0.6f;
			xform.position = position3;
			if (position3.y < -2f)
			{
				BroadcastMessage("OnSunk", SendMessageOptions.DontRequireReceiver);
				IUnitControllable component = GetComponent<IUnitControllable>();
				if (component != null)
				{
					UnitSystem.inst.DestroyUnit(component);
				}
				return;
			}
			break;
		}
		case State.Sailing:
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
						pathFailed = true;
					}
					else
					{
						pathFailed = false;
						int teamIdForPos = teamID;
						if (teamID == -2)
						{
							teamIdForPos = GetTeamIdForPos(deferredPath.end);
						}
						hadTrimmed = World.inst.TrimPathForBlockedCells(ref path, PathCell.GetBlocksWaterPath, teamIdForPos);
						if (path.Count == 0)
						{
							arrived = true;
						}
						if (debugDraw && path.Count > 0)
						{
							Debug.DrawLine(pos, path.data[path.Count - 1], Color.cyan);
							DebugEx.DrawSphere(path.data[path.Count - 1], 0.45f, Color.cyan, 8f);
							deferredPath.DrawDebug(pos, Color.green);
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
			if (path.Count > 0 && !arrived && deferredPath.status != GamePath.Status.Finding)
			{
				Vector3 targetPos = GetTargetPos(0);
				int teamIdForPos2 = teamID;
				if (teamID == -2)
				{
					teamIdForPos2 = GetTeamIdForPos(targetPos);
				}
				if (dynamics.MoveUpdate(dt, targetPos, teamIdForPos2, transform))
				{
					pathIdx++;
				}
				if (pathIdx == path.Count)
				{
					arrived = true;
					path.Clear();
					pathIdx = 0;
				}
			}
			sailingSound.set3DAttributes(dynamics.Pos.To3DAttributes());
			break;
		}
		rot = xform.rotation;
		pos = dynamics.Pos;
	}

	public Vector3 GetTargetPos(int pathDelta)
	{
		int num = Mathff.Clamp(pathIdx + pathDelta, 0, path.Count - 1);
		if (path.Count > 0)
		{
			float num2 = Mathff.DistXZ(path.data[num], xform.position);
			float t = Mathff.Clamp01(1f - num2);
			Vector3 result = path.data[num];
			if (path.Count >= 2 && num + 1 < path.Count)
			{
				result = Vector3.Lerp(path.data[num], path.data[num + 1], t);
			}
			return result;
		}
		return xform.position;
	}

	public static Cell GetDockCell(ShipBase ship, List<Cell> dockPositions, List<int> dockPositionPenalties, Cell prevCell = null)
	{
		Cell result = null;
		float num = float.MaxValue;
		while (dockPositionPenalties.Count < dockPositions.Count)
		{
			dockPositionPenalties.Add(0);
		}
		for (int i = 0; i < dockPositions.Count; i++)
		{
			Vector3 center2D = dockPositions[i].Center2D;
			if (prevCell == dockPositions[i])
			{
				dockPositionPenalties[i] += 16;
			}
			Building topMostStructure = dockPositions[i].TopMostStructure;
			if ((bool)topMostStructure && topMostStructure.uniqueNameHash != World.drawBridgeHash && topMostStructure.uniqueNameHash != World.noriaHash && topMostStructure.uniqueNameHash != World.moatHash)
			{
				continue;
			}
			float num2 = Mathff.DistXZ(ship.xform.position, center2D);
			num2 += (float)dockPositionPenalties[i];
			for (int j = 0; j < ShipSystem.inst.ships.Count; j++)
			{
				if (!(ShipSystem.inst.ships.data[j] == ship) && Mathff.DistSqrdXZ(ShipSystem.inst.ships.data[j].pos, center2D) < 4f)
				{
					num2 *= 2f;
				}
			}
			if (num2 < num)
			{
				result = dockPositions[i];
				num = num2;
			}
		}
		for (int k = 0; k < dockPositionPenalties.Count; k++)
		{
			dockPositionPenalties[k]--;
		}
		return result;
	}

	public Vector3 GetDesiredTrackingPos()
	{
		return xform.position;
	}

	public float GetRadius()
	{
		return 1f;
	}

	public Vector3 GetPosition()
	{
		return pos;
	}

	public Vector3 GetVelocity()
	{
		return dynamics.velocity;
	}

	public Vector3 GetPredictedPosition(float time)
	{
		if (!dynamics.isMoving)
		{
			return pos;
		}
		return pos + dynamics.velocity * time;
	}

	public HitSfxResult TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int attackerTeamID)
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
		life -= dmg;
		return HitSfxResult.Wood;
	}

	public bool IsInvalid()
	{
		return state != State.Sailing;
	}

	private static void TestCellForWater(Cell cell, Cell testCell, ref Cell waterCell, ref float minDist)
	{
		if (testCell != null && testCell.Type == TerrainType.Water)
		{
			float num = Mathff.DistSqrdXZ(testCell.Center2D, cell.Center2D);
			if (num < minDist)
			{
				minDist = num;
				waterCell = testCell;
			}
		}
	}

	public static Cell FindClosestWaterTile(Cell cell)
	{
		Cell waterCell = null;
		float minDist = float.MaxValue;
		int num = 0;
		for (int i = 1; i <= 5; i++)
		{
			num = i;
			int num2 = cell.x - num;
			int num3 = cell.z - num;
			int num4 = cell.x + num;
			int num5 = cell.z + num;
			for (int j = num2; j <= num4; j++)
			{
				Cell cellData = World.inst.GetCellData(j, num3);
				TestCellForWater(cell, cellData, ref waterCell, ref minDist);
			}
			for (int k = num2; k <= num4; k++)
			{
				Cell cellData2 = World.inst.GetCellData(k, num5);
				TestCellForWater(cell, cellData2, ref waterCell, ref minDist);
			}
			for (int l = num3; l <= num5; l++)
			{
				Cell cellData3 = World.inst.GetCellData(num2, l);
				TestCellForWater(cell, cellData3, ref waterCell, ref minDist);
			}
			for (int m = num3; m <= num5; m++)
			{
				Cell cellData4 = World.inst.GetCellData(num4, m);
				TestCellForWater(cell, cellData4, ref waterCell, ref minDist);
			}
		}
		return waterCell;
	}
}
