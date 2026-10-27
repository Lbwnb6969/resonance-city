using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets.Code;
using UnityEngine;

public class DragonController : MonoBehaviour
{
	public enum DragonType
	{
		Dragon,
		BigDragon
	}

	public enum DragonState
	{
		Uninitialized,
		CircleStatue,
		HarmlessMoveAction,
		BurnMoveAction,
		BurnLineAction,
		GrabPersonAction,
		Retreating,
		Leaving,
		Dead
	}

	public enum GrabPersonActionState
	{
		GettingReady,
		SwoopManeuver
	}

	public enum DeadActionState
	{
		Waiting,
		Sinking
	}

	public enum BurnType
	{
		SingleTarget,
		LeftCenterRight
	}

	[Serializable]
	public class DragonControllerSaveData : SaveClass<DragonController, DragonControllerSaveData>
	{
		public DragonType type;

		private Dragon.DragonSaveData dragonSaveDate;

		private DragonState state;

		private int targetsToBurn;

		private int targetsBurnt;

		private float normalFlySpeed;

		private float retreatFlySpeed;

		private Timer timelyExitInsuranceTimer;

		private Timer lookTimer;

		private Timer hoverTimer;

		private Timer roarTimer;

		[OptionalField(VersionAdded = 2)]
		public BurnType burnType;

		[OptionalField(VersionAdded = 3)]
		public bool justVisiting;

		[OptionalField(VersionAdded = 3)]
		public List<DragonState> actions;

		[OptionalField(VersionAdded = 4)]
		public List<int> visitedLandmasses;

		public override DragonControllerSaveData Pack(DragonController d)
		{
			dragonSaveDate = new Dragon.DragonSaveData().Pack(d.dragon);
			state = d.state;
			actions = d.actions;
			normalFlySpeed = d.normalFlySpeed;
			retreatFlySpeed = d.retreatFlySpeed;
			timelyExitInsuranceTimer = d.timelyExitInsuranceTimer;
			lookTimer = d.lookTimer;
			hoverTimer = d.hoverTimer;
			roarTimer = d.roarTimer;
			type = d.dragonType;
			justVisiting = d.justVisiting;
			visitedLandmasses = d.visitedLandmasses;
			return this;
		}

		public override DragonController Unpack(DragonController d)
		{
			d.dragonType = type;
			dragonSaveDate.Unpack(d.dragon);
			d.normalFlySpeed = normalFlySpeed;
			d.retreatFlySpeed = retreatFlySpeed;
			d.timelyExitInsuranceTimer = timelyExitInsuranceTimer;
			d.lookTimer = lookTimer;
			d.hoverTimer = hoverTimer;
			d.roarTimer = roarTimer;
			d.deathTimer = new Timer(0f);
			if (state == DragonState.GrabPersonAction)
			{
				state = DragonState.HarmlessMoveAction;
			}
			d.justVisiting = justVisiting;
			d.actions = actions;
			d.visitedLandmasses = visitedLandmasses;
			if (d.visitedLandmasses == null)
			{
				d.visitedLandmasses = new List<int>();
			}
			d.ChangeToState(state);
			return d;
		}
	}

	public DragonType dragonType;

	private bool testDrive;

	private const float retreatPercent = 0.2f;

	private const float harmlessHoverDuration = 1f;

	private const float circleDuration = 10f;

	private const float burnHoverDuration = 1f;

	private const float grabActionHoverDuration = 1f;

	private const float deathPreSinkWait = 5f;

	private float deathSinkTime = 5f;

	[NonSerialized]
	public Dragon dragon;

	private DragonState state;

	private GrabPersonActionState grabActionState;

	private DeadActionState deadActionState;

	private bool complete;

	private float normalFlySpeed;

	private float retreatFlySpeed;

	private Timer timelyExitInsuranceTimer;

	private Timer lookTimer;

	private Timer hoverTimer;

	private Timer roarTimer;

	private Timer deathTimer;

	private MonoBehaviour targetOfInterest;

	private List<int> visitedLandmasses;

	private List<DragonState> actions = new List<DragonState>();

	private bool justVisiting;

	private Cell lastCell;

	private float explodeDelayTime;

	private static List<Building> scratch = new List<Building>();

	public static float dragonFlyHeight = 3f;

	private List<Villager> scratchList = new List<Villager>();

	private void Awake()
	{
		dragon = GetComponent<Dragon>();
	}

	public void Init(Vector3 start, float hp, List<DragonState> actions, float timeTillLeave, float flySpeed, float retreatSpeed, float strengthScaler)
	{
		dragon.Create(hp, strengthScaler);
		this.actions = actions;
		normalFlySpeed = flySpeed;
		retreatFlySpeed = retreatSpeed;
		complete = false;
		timelyExitInsuranceTimer = new Timer(timeTillLeave);
		lookTimer = new Timer(0f);
		hoverTimer = new Timer(0f);
		roarTimer = new Timer(0f);
		deathTimer = new Timer(0f);
		transform.position = start;
		dragon.SetFlySpeed(flySpeed);
		ChangeToState(actions[0]);
		justVisiting = true;
		for (int i = 0; i < actions.Count; i++)
		{
			if (actions[i] == DragonState.BurnMoveAction || actions[i] == DragonState.BurnLineAction || actions[i] == DragonState.GrabPersonAction)
			{
				justVisiting = false;
			}
		}
		visitedLandmasses = new List<int>();
	}

	private void Update()
	{
		if (Application.isEditor && Input.GetKey(KeyCode.H))
		{
			dragon.TakeDamage(9999f);
		}
		if (complete)
		{
			return;
		}
		if (state != DragonState.Dead)
		{
			if (state != DragonState.Leaving && timelyExitInsuranceTimer.Update(Time.deltaTime))
			{
				timelyExitInsuranceTimer.Enabled = false;
				state = DragonState.Leaving;
			}
			if (state != DragonState.Retreating && dragon.HP() / dragon.MaxHP() < 0.2f)
			{
				ChangeToState(DragonState.Retreating);
			}
		}
		if (dragon.HP() <= 0f && state != DragonState.Dead)
		{
			ChangeToState(DragonState.Dead);
		}
		if (!TestDrive())
		{
			float deltaTime = Time.deltaTime;
			switch (state)
			{
			case DragonState.BurnLineAction:
				UpdateBurnLineAction();
				break;
			case DragonState.BurnMoveAction:
				UpdateBurnMoveAction();
				break;
			case DragonState.CircleStatue:
				UpdateCircle();
				break;
			case DragonState.HarmlessMoveAction:
				UpdateHarmlessMoveAction();
				break;
			case DragonState.GrabPersonAction:
				UpdateGrabPersonAction();
				break;
			case DragonState.Leaving:
				UpdateLeaving();
				break;
			case DragonState.Retreating:
				UpdateRetreating();
				break;
			case DragonState.Dead:
				UpdateDeadAction(deltaTime);
				break;
			}
		}
	}

	private void ChangeToState(DragonState newState)
	{
		switch (newState)
		{
		case DragonState.CircleStatue:
		{
			ArrayExt<Building> buildingList = Player.inst.GetBuildingList("statue_sam");
			if (buildingList.Count > 0)
			{
				hoverTimer.Duration = 10f;
				targetOfInterest = buildingList.RandomElement();
				dragon.MoveInCircleAround(targetOfInterest.GetComponent<Building>().Center(), 2f);
			}
			else
			{
				ChooseNextAction();
			}
			break;
		}
		case DragonState.HarmlessMoveAction:
			hoverTimer.Duration = 1f;
			dragon.MoveTo(NewWorldPoint());
			break;
		case DragonState.BurnLineAction:
			explodeDelayTime = 0f;
			targetOfInterest = FindSomethingToBurn(newState);
			if ((bool)targetOfInterest)
			{
				dragon.MoveTo((targetOfInterest as Building).Center());
			}
			else
			{
				ChangeToState(DragonState.Leaving);
			}
			break;
		case DragonState.BurnMoveAction:
			hoverTimer.Duration = 1f;
			targetOfInterest = FindSomethingToBurn(newState);
			if ((bool)targetOfInterest)
			{
				Vector3 vector = (targetOfInterest as Building).Center();
				vector.y = dragonFlyHeight;
				Vector3 vector2 = dragon.transform.position - vector;
				vector2.Normalize();
				dragon.MoveTo(vector + vector2 * 1f);
			}
			else
			{
				ChangeToState(DragonState.Leaving);
			}
			break;
		case DragonState.GrabPersonAction:
			hoverTimer.Duration = 1f;
			SetupGrabPersonAction();
			break;
		case DragonState.Leaving:
			dragon.FireBreath(on: false);
			if (justVisiting)
			{
				Player.inst.DragonWarning(visitedLandmasses);
			}
			dragon.MoveTo(NewEntryExitPoint());
			break;
		case DragonState.Retreating:
			dragon.FireBreath(on: false);
			dragon.MoveTo(NewEntryExitPoint());
			break;
		case DragonState.Dead:
			Player.inst.DragonKill(visitedLandmasses);
			dragon.Die();
			deadActionState = DeadActionState.Waiting;
			deathTimer.Duration = 5f;
			break;
		}
		state = newState;
	}

	public DragonState GetState()
	{
		return state;
	}

	public bool IsCompleted()
	{
		return complete;
	}

	private void ChooseNextAction()
	{
		if (actions != null && actions.Count > 1)
		{
			actions.RemoveAt(0);
			ChangeToState(actions[0]);
		}
		else
		{
			ChangeToState(DragonState.Leaving);
		}
	}

	private void UpdateBurnLineAction()
	{
		if (dragon.IsMoving())
		{
			if (!ValidTargetOfInterest())
			{
				ChooseNextAction();
				dragon.FireBreath(on: false);
				return;
			}
			Vector3 vector = dragon.transform.position + dragon.transform.forward * 3f;
			vector.y = 0f;
			dragon.SetLookTarget(vector);
			Vector3 lhs = vector - dragon.transform.position;
			lhs.y = 0f;
			float num = Vector3.Dot(lhs, dragon.transform.forward.xz());
			Cell cellDataClamped = World.inst.GetCellDataClamped(vector);
			float num2 = Mathff.DistSqrdXZ(targetOfInterest.transform.position, dragon.transform.position);
			if (num2 < 81f && num2 >= 4f && cellDataClamped.Type != TerrainType.Water && num > 0.5f)
			{
				explodeDelayTime += Time.deltaTime;
				if (!dragon.JawOpen)
				{
					dragon.FireBreath(on: true);
				}
				else if (explodeDelayTime > 0.4f && cellDataClamped != lastCell)
				{
					StartFiresAtTarget(cellDataClamped);
					lastCell = cellDataClamped;
				}
			}
			else
			{
				if (!(num2 < 4f))
				{
					return;
				}
				if (lastCell != null)
				{
					int landMassIdx = lastCell.landMassIdx;
					if (landMassIdx >= 0 && !visitedLandmasses.Contains(landMassIdx))
					{
						visitedLandmasses.Add(landMassIdx);
					}
				}
				dragon.FireBreath(on: false);
				ChooseNextAction();
			}
		}
		else
		{
			dragon.FireBreath(on: false);
			ChooseNextAction();
		}
	}

	private void UpdateCircle()
	{
		MaybeRoar();
		dragon.SetLookTarget(targetOfInterest);
		if (dragon.IsMoving())
		{
			return;
		}
		if (targetOfInterest != null)
		{
			int landMassIdx = World.inst.GetCellDataClamped(targetOfInterest.transform.position).landMassIdx;
			if (landMassIdx >= 0 && !visitedLandmasses.Contains(landMassIdx))
			{
				visitedLandmasses.Add(landMassIdx);
			}
		}
		ChooseNextAction();
	}

	private void UpdateBurnMoveAction()
	{
		if (dragon.IsMoving())
		{
			MaybeRoar();
			if (ChangeLook())
			{
				if ((double)SRand.Range(0, 1) > 0.5)
				{
					dragon.SetLookTarget(FindSomethingToLookAt(dragon.PredictPosition(3f)));
				}
				else
				{
					dragon.SetLookTarget(targetOfInterest);
				}
			}
			return;
		}
		if (!ValidTargetOfInterest())
		{
			ChooseNextAction();
			dragon.FireBreath(on: false);
			return;
		}
		dragon.SetLookTarget(targetOfInterest);
		if (!hoverTimer.Update(Time.deltaTime))
		{
			return;
		}
		if (!dragon.JawOpen)
		{
			dragon.FireBreath(on: true);
			if (targetOfInterest != null)
			{
				StartFiresAtTarget(World.inst.GetCellDataClamped(targetOfInterest.transform.position));
			}
			return;
		}
		if (targetOfInterest != null)
		{
			int landMassIdx = World.inst.GetCellDataClamped(targetOfInterest.transform.position).landMassIdx;
			if (landMassIdx >= 0 && !visitedLandmasses.Contains(landMassIdx))
			{
				visitedLandmasses.Add(landMassIdx);
			}
		}
		dragon.FireBreath(on: false);
		ChooseNextAction();
	}

	private void UpdateHarmlessMoveAction()
	{
		MaybeRoar();
		if (ChangeLook())
		{
			dragon.SetLookTarget(FindSomethingToLookAt(dragon.PredictPosition(3f)));
		}
		if (!dragon.IsMoving() && hoverTimer.Update(Time.deltaTime))
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(dragon.transform.position);
			if (cellDataClamped != null && cellDataClamped.landMassIdx >= 0 && !visitedLandmasses.Contains(cellDataClamped.landMassIdx))
			{
				visitedLandmasses.Add(cellDataClamped.landMassIdx);
			}
			ChooseNextAction();
		}
	}

	private void SetupGrabPersonAction()
	{
		grabActionState = GrabPersonActionState.GettingReady;
	}

	private void UpdateGrabPersonAction()
	{
		if (grabActionState != GrabPersonActionState.GettingReady)
		{
			_ = 1;
		}
		else if (!dragon.IsMoving() && hoverTimer.Update(Time.deltaTime))
		{
			grabActionState = GrabPersonActionState.SwoopManeuver;
		}
	}

	private void UpdateLeaving()
	{
		MaybeRoar();
		dragon.SetFlySpeed(normalFlySpeed);
		if (dragon.NearEnd())
		{
			if (!justVisiting)
			{
				Player.inst.DragonEscape(visitedLandmasses);
			}
			complete = true;
		}
	}

	private void UpdateRetreating()
	{
		dragon.SetFlySpeed(retreatFlySpeed);
		if (dragon.NearEnd())
		{
			if (!justVisiting)
			{
				Player.inst.DragonAlmostKill(visitedLandmasses);
			}
			complete = true;
		}
	}

	private void UpdateDeadAction(float dt)
	{
		switch (deadActionState)
		{
		case DeadActionState.Waiting:
		{
			if (!deathTimer.Update(dt))
			{
				break;
			}
			deadActionState = DeadActionState.Sinking;
			deathTimer.Duration = deathSinkTime;
			Transform[] componentsInChildren = dragon.GetComponentsInChildren<Transform>();
			foreach (Transform transform in componentsInChildren)
			{
				Cell cellData = World.inst.GetCellData(transform.transform.position);
				if (cellData != null && cellData.landMassIdx != -1 && cellData.Type != TerrainType.Water && (bool)transform.GetComponent<MeshFilter>() && (bool)transform.GetComponent<MeshRenderer>())
				{
					FreeResourceSystem.inst.AddFreeResource(10, transform.transform.position, cellData.landMassIdx).Holder = null;
				}
			}
			break;
		}
		case DeadActionState.Sinking:
			base.transform.position = base.transform.position + Vector3.down * dt / 10f;
			if (deathTimer.Update(dt))
			{
				complete = true;
			}
			break;
		}
	}

	private bool ChangeLook()
	{
		if (lookTimer.Update(Time.deltaTime))
		{
			lookTimer.Duration = SRand.Range(3, 5);
			return true;
		}
		return false;
	}

	private bool MaybeRoar()
	{
		if (roarTimer.Update(Time.deltaTime))
		{
			roarTimer.Duration = SRand.Range(5, 9);
			dragon.Roar();
			return true;
		}
		return false;
	}

	private object FindSomethingToLookAt(Vector3 pos)
	{
		Villager nearestWorker = Player.inst.GetNearestWorker(pos);
		if (nearestWorker != null)
		{
			return nearestWorker.Pos;
		}
		return null;
	}

	private void TryAddPotentialTargets(List<Building> targets, ArrayExt<Building> potentialTargets)
	{
		int i = 0;
		for (int count = potentialTargets.Count; i < count; i++)
		{
			Building building = potentialTargets.data[i];
			if (!World.IsImmuneToFire(building) && !building.IsOnFire())
			{
				targets.Add(building);
			}
		}
	}

	private MonoBehaviour FindSomethingToBurn(DragonState newState)
	{
		scratch.Clear();
		int count = Player.inst.Workers.Count;
		int num = SRand.Range(0, count);
		int num2 = 0;
		int landMass = -1;
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			int count2 = World.inst.GetVillagersForLandMass(i).Count;
			if (num >= num2 && num < num2 + count2)
			{
				landMass = i;
			}
			num2 += count2;
		}
		TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "smallhouse".GetHashCode()));
		TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "largehouse".GetHashCode()));
		TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "manorhouse".GetHashCode()));
		TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "largegranary".GetHashCode()));
		TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "smallgranary".GetHashCode()));
		TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "farm".GetHashCode()));
		TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "orchard".GetHashCode()));
		if (newState == DragonState.BurnMoveAction)
		{
			TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "archer".GetHashCode()));
			TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "ballista".GetHashCode()));
		}
		if (newState == DragonState.BurnLineAction)
		{
			TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "smallstockpile".GetHashCode()));
			TryAddPotentialTargets(scratch, Player.inst.GetBuildingListForLandMass(landMass, "largestockpile".GetHashCode()));
		}
		if (scratch.Count > 0)
		{
			Building building = scratch[SRand.Range(0, scratch.Count)];
			if ((building.UniqueName == "archer" || building.UniqueName == "ballista") && SRand.Range(0, 100) < 75)
			{
				building = scratch[SRand.Range(0, scratch.Count)];
			}
			return building;
		}
		return null;
	}

	private Vector3 NewWorldPoint()
	{
		if (Player.inst.Buildings.Count > 0)
		{
			return Player.inst.Buildings.RandomElement().Center().xz() + new Vector3(SRand.Range(-10f, 10f), dragonFlyHeight, SRand.Range(-10f, 10f));
		}
		return new Vector3(SRand.Range(0, World.inst.GridWidth), dragonFlyHeight, SRand.Range(0, World.inst.GridHeight));
	}

	public static Vector3 NewEntryExitPoint()
	{
		float f = SRand.Range(0f, MathF.PI * 2f);
		return new Vector3(Mathf.Cos(f) * (float)World.inst.GridWidth + (float)(World.inst.GridWidth / 2), dragonFlyHeight, Mathf.Sin(f) * (float)World.inst.GridWidth + (float)(World.inst.GridHeight / 2));
	}

	private bool ValidTargetOfInterest()
	{
		return targetOfInterest != null;
	}

	private void KillVillagersAt(Cell c)
	{
		ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(c.x, c.z);
		for (int i = 0; i < villagersAt.Count; i++)
		{
			scratchList.Add(villagersAt.data[i]);
		}
		for (int j = 0; j < scratchList.Count; j++)
		{
			Vector3 pos = scratchList[j].Pos;
			Player.inst.DestroyPerson(scratchList[j], leaveBehindBody: true);
			DragonSpawn.inst.NotePeasantKilled(pos);
		}
		scratchList.Clear();
	}

	private void StartFiresAtTarget(Cell cell)
	{
		Fire fire = FireManager.inst.StartFireAt(cell);
		if (fire != null)
		{
			KillVillagersAt(cell);
			fire.PostModifyBurnout(0.5f);
		}
		Vector3 pos = cell.Center2D;
		if (cell.TopStructure != null)
		{
			if (cell.TopStructure.size.x <= 1f && cell.TopStructure.size.z <= 1f && cell.TopStructure.UniqueName != "archer" && cell.TopStructure.UniqueName != "ballista")
			{
				BuildingCollapseManager.inst.Collapse(cell.TopStructure, doRubble: true, doAnimation: false);
			}
			pos = cell.TopStructure.transform.position;
		}
		EffectsMan.inst.ExplodeEffect.CreateAndPlay(pos);
		Cell cellData = World.inst.GetCellData(cell.Center2D + new Vector3(1f, 0f, 0f));
		fire = FireManager.inst.StartFireAt(cellData);
		if (fire != null)
		{
			fire.PostModifyBurnout(0.75f);
		}
		Cell cellData2 = World.inst.GetCellData(cell.Center2D - new Vector3(1f, 0f, 0f));
		fire = FireManager.inst.StartFireAt(cellData2);
		if (fire != null)
		{
			fire.PostModifyBurnout(0.75f);
		}
		Cell cellData3 = World.inst.GetCellData(cell.Center2D + new Vector3(0f, 0f, 1f));
		fire = FireManager.inst.StartFireAt(cellData3);
		if (fire != null)
		{
			fire.PostModifyBurnout(0.75f);
		}
		Cell cellData4 = World.inst.GetCellData(cell.Center2D - new Vector3(0f, 0f, 1f));
		fire = FireManager.inst.StartFireAt(cellData4);
		if (fire != null)
		{
			fire.PostModifyBurnout(0.75f);
		}
	}

	public bool TestDrive()
	{
		if (!testDrive)
		{
			return false;
		}
		if (Input.GetMouseButtonDown(0))
		{
			Ray ray = PointingSystem.GetRay();
			new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
			Vector3 point = ray.GetPoint(enter);
			dragon.MoveTo(point.xz() + new Vector3(0f, dragonFlyHeight, 0f));
		}
		if (Input.GetMouseButtonDown(1))
		{
			dragon.Die();
		}
		dragon.FireBreath(Input.GetKey(KeyCode.Space));
		if (Input.GetKeyDown(KeyCode.X))
		{
			dragon.CancelMove();
		}
		dragon.HeadWaggleIntensity(3f);
		return true;
	}
}
