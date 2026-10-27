using System;
using UnityEngine;

public class FireFighter : Job
{
	protected enum Task
	{
		NotWorried,
		FindWater,
		FightFire
	}

	private bool fighting;

	protected Task currentTask;

	protected int fireContributeCount = 1;

	private bool transitToFire;

	internal Fire fireTarget;

	private Vector3 fireStandPosition;

	[NonSerialized]
	public bool doSuppress;

	private Cell[] scratch4 = new Cell[4];

	private Vector3 waterPosition;

	public static int projectiletopperHash = "projectiletopper".GetHashCode();

	public static int noriaHash = "noria".GetHashCode();

	public static int wellHash = "well".GetHashCode();

	public static int reservoirHash = "reservoir".GetHashCode();

	public static int fountainHash = "fountain".GetHashCode();

	public static int largefountainHash = "largefountain".GetHashCode();

	private float fightFireTime;

	public bool Fighting => fighting;

	public FireFighter(IEmployer e)
		: base(e)
	{
		meshType = VillagerSystem.MeshType.FireFighterEmpty;
	}

	protected void SetCurrTask(Task t)
	{
		Villager villager = Employee;
		if (villager != null)
		{
			switch (t)
			{
			case Task.NotWorried:
				Employee.MeshType = VillagerSystem.MeshType.FireFighterEmpty;
				villager.MoveToDeferred(employer.GetPositionForPerson(villager));
				break;
			case Task.FindWater:
				Employee.MeshType = VillagerSystem.MeshType.FireFighterEmpty;
				break;
			case Task.FightFire:
				if (fireTarget.Cell.OccupyingStructure.Count <= 0)
				{
					fireStandPosition = fireTarget.Cell.Center3D;
				}
				else
				{
					Building bottomStructure = fireTarget.Cell.BottomStructure;
					Vector3 bounds = bottomStructure.GetBounds();
					Vector3 vector = fireTarget.transform.position.xz();
					Bounds bounds2 = new Bounds(vector + bounds / 2f, bounds);
					Ray ray = new Ray(direction: (new Vector3(Mathf.Lerp(bounds2.min.x, bounds2.max.x, SRand.Range(0f, 1f)), 0.1f, Mathf.Lerp(bounds2.min.z, bounds2.max.z, SRand.Range(0f, 1f))) - villager.Pos).normalized, origin: villager.Pos);
					if (!bounds2.IntersectRay(ray, out var distance))
					{
						Debug.LogWarning("The raycast to building can only fail if building's bounding box is less than 0.1f tall");
					}
					_ = bottomStructure.GetCell().Position + new Vector3(0.1f, 0f, 0.1f) + bottomStructure.GetBounds() - new Vector3(0.1f, 0f, 0.1f);
					fireStandPosition = ray.GetPoint(distance).xz();
					fireStandPosition.y = TerrainGen.inst.GetInterpolatedHeight(fireStandPosition);
					Debug.DrawLine(fireTarget.transform.position, fireTarget.transform.position + bounds, Color.cyan, 100f);
				}
				villager.MoveToDeferred(fireStandPosition);
				transitToFire = true;
				fightFireTime = 0f;
				Employee.MeshType = VillagerSystem.MeshType.FireFighter;
				break;
			}
		}
		currentTask = t;
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		if (fireTarget != null && fireTarget.gameObject.activeSelf)
		{
			ManualFreetime = true;
		}
		else
		{
			ManualFreetime = false;
		}
		Vector3 pos = villager.Pos;
		switch (currentTask)
		{
		case Task.NotWorried:
		{
			if (!fireTarget)
			{
				break;
			}
			int lm = fireTarget.LandMass();
			SetCurrTask(Task.FindWater);
			Cell cell = null;
			Cell cellData = World.inst.GetCellData(pos);
			if (cellData != null && cellData.landMassIdx != -1 && cellData.landMassIdx == Employee.landMass)
			{
				cell = World.inst.FindMatchingSurroundingCell(pos, testOrigin: true, int.MaxValue, (Cell c) =>
				{
					if (c.landMassIdx != lm)
					{
						if (c.HasAnyWater())
						{
							return true;
						}
						return false;
					}
					Building building = c.LowestStructureWithUniqueHash(reservoirHash);
					if ((bool)building && building.IsBuilt() && building.GetComponent<Reservoir>().HasWater)
					{
						return true;
					}
					WaterSupplier waterSupplier = null;
					for (int j = 0; j < c.OccupyingStructure.Count; j++)
					{
						WaterSupplier component = c.OccupyingStructure[j].GetComponent<WaterSupplier>();
						if (component != null)
						{
							waterSupplier = component;
						}
					}
					if (waterSupplier != null)
					{
						AqueductBuilding component2 = waterSupplier.GetComponent<AqueductBuilding>();
						if (component2 != null && component2.HasWater())
						{
							return true;
						}
					}
					Building building2 = c.LowestStructureWithUniqueHash(wellHash);
					if ((bool)building2 && building2.IsBuilt())
					{
						return true;
					}
					Building building3 = c.LowestStructureWithUniqueHash(fountainHash);
					if (!building3)
					{
						building3 = c.LowestStructureWithUniqueHash(largefountainHash);
					}
					return ((bool)building3 && building3.IsBuilt() && building3.GetComponent<Fountain>().receievingWater) ? true : false;
				});
			}
			if (cell != null)
			{
				waterPosition = cell.Center3D;
				if (cell.Type == TerrainType.Water)
				{
					World.inst.GetNeighborCells(cell, ref scratch4);
					for (int num = 0; num < 4; num++)
					{
						Cell cell2 = scratch4[num];
						if (cell2 != null && cell2.Type == TerrainType.None)
						{
							waterPosition = cell2.Center3D;
							break;
						}
					}
				}
				villager.MoveToDeferred(waterPosition);
				fighting = true;
			}
			else
			{
				SetCurrTask(Task.NotWorried);
			}
			break;
		}
		case Task.FindWater:
			if (Mathff.Dist(pos, waterPosition) < 0.01f)
			{
				SetCurrTask(Task.FightFire);
			}
			break;
		case Task.FightFire:
			if (transitToFire && Mathff.Dist(pos, fireStandPosition) < 0.01f)
			{
				transitToFire = false;
				Vector3 forward = fireTarget.GetCenter() - villager.Pos;
				forward.Normalize();
				villager.Rot = Quaternion.LookRotation(forward, new Vector3(0f, 1f, 0f));
				forward += new Vector3(0f, 1f, 0f);
				forward.Normalize();
				EffectsMan.inst.HoseEffect.CreateAndPlay(villager.Pos + villager.Rot * new Vector3(0f, 0.25f, 0.25f), Quaternion.LookRotation(forward));
				SfxSystem.inst.PlayFromBankIfVisible("VillagerWaterBucket", villager.Pos);
			}
			if (!transitToFire)
			{
				for (int i = 0; i < fireContributeCount; i++)
				{
					fireTarget.ContributeToExtinguish();
				}
				fireTarget.suppress = doSuppress;
				fightFireTime += dt;
				if (fightFireTime > 1f)
				{
					SetCurrTask(Task.NotWorried);
				}
			}
			break;
		}
		base.UpdateWithEmployee(dt);
	}

	public override void OnEmployeeAssigned()
	{
		Employee.speedBonusMultiplier = 1.2f;
		base.OnEmployeeAssigned();
	}

	public override void OnEmployeeQuit()
	{
		Employee.speedBonusMultiplier = 1f;
		Employee.UpdatePlacement();
		base.OnEmployeeQuit();
	}
}
