using UnityEngine;

public class Gate : Tickable
{
	public Transform[] doorR;

	public Transform[] doorL;

	private float gateDir = 1f;

	private Vector3 gatePos = Vector3.zero;

	private float gateTime;

	private Building b;

	public float gateSpeed = 2f;

	private const int frameSpread = 20;

	private int updateFrame = SRand.srand.Next(0, 20);

	private void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		if (validationResult != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		if (DynamicWater.inst.IsWater(cellDataClamped.x, cellDataClamped.z))
		{
			validationResult = PlacementValidationResult.CannotBuildOnDynamicWater;
			return;
		}
		bool flag = true;
		for (int i = 0; i < cellDataClamped.OccupyingStructure.Count; i++)
		{
			Building building = cellDataClamped.OccupyingStructure[i];
			if (building.uniqueNameHash != World.rubbleHash && building.categoryHash != World.pathHash && building.uniqueNameHash != World.woodcastleblockHash && building.uniqueNameHash != World.castleblockHash && (b.uniqueNameHash != World.gateHash || building.uniqueNameHash != World.woodengateHash))
			{
				flag = false;
				break;
			}
		}
		if (flag)
		{
			validationResult = PlacementValidationResult.Valid;
		}
	}

	public void OnInit()
	{
		b = GetComponent<Building>();
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b.IsBuilt() && currFrame % 20 == updateFrame)
		{
			Vector3 position = transform.position;
			gateDir = 1f;
			int teamId = 0;
			IMoveTarget component = GetComponent<IMoveTarget>();
			if (component != null)
			{
				teamId = component.TeamID();
			}
			if (UnitSystem.inst.ClosestEnemyUnit(position, 4f, teamId) != null)
			{
				gateDir = -1f;
			}
		}
		gateTime += gateDir * dt * gateSpeed;
		gateTime = Mathf.Clamp01(gateTime);
		if (gateTime > 0.001f && gateTime < 0.999f)
		{
			for (int i = 0; i < doorL.Length; i++)
			{
				doorL[i].localRotation = Quaternion.Euler(0f, Mathff.Lerp(0f, 90f, gateTime), 0f);
				doorR[i].localRotation = Quaternion.Euler(0f, Mathff.Lerp(180f, 90f, gateTime), 0f);
			}
		}
	}

	public void OnBuilt()
	{
		UpdateNeighborBlocks();
	}

	public void OnDemolished()
	{
		UpdateNeighborBlocks();
	}

	public void UpdateNeighborBlocks()
	{
		Vector3 eulerAngles = transform.GetChild(0).rotation.eulerAngles;
		Vector3 position = transform.position;
		Cell c = null;
		Cell c2 = null;
		if ((int)eulerAngles.y == -90 || (int)eulerAngles.y == 90)
		{
			c = World.inst.GetCellData((int)position.x, (int)position.z - 1);
			c2 = World.inst.GetCellData((int)position.x, (int)position.z + 1);
		}
		else if ((int)eulerAngles.y == 0 || (int)eulerAngles.y == -180)
		{
			c = World.inst.GetCellData((int)position.x - 1, (int)position.z);
			c2 = World.inst.GetCellData((int)position.x + 1, (int)position.z);
		}
		BlockBuilding.MarkBlockStackDirty(c);
		BlockBuilding.MarkBlockStackDirty(c2);
	}
}
