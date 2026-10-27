using UnityEngine;

public class Catapult : MonoBehaviour
{
	public enum Status
	{
		Idle,
		Firing,
		PullingBack
	}

	public delegate bool ShouldIgnore(Building b);

	public CatapultProjectile catapultProjectile;

	public Transform arm;

	public Transform projectileXform;

	public int teamID = 1;

	private Status status;

	internal IMoveTarget target;

	public float pullbackSpeed = 1f;

	public float fireSpeed = 10f;

	public int range = 6;

	private float rotation;

	public bool autoRotate = true;

	public bool manned = true;

	private static int gateHash = "gateHash".GetHashCode();

	private static int castleblockHash = "castleblock".GetHashCode();

	private static int woodcastleblockHash = "woodcastleblock".GetHashCode();

	public bool TargetInRange()
	{
		if (target != null && !target.Equals(null) && (transform.position - target.GetPos()).magnitude <= (float)range)
		{
			return true;
		}
		return false;
	}

	public bool IsTargetValid()
	{
		if (target != null && !target.Equals(null))
		{
			return !(target as IProjectileHitable).IsInvalid();
		}
		return false;
	}

	public Status GetStatus()
	{
		return status;
	}

	public void SetTarget(IMoveTarget newTarget)
	{
		target = newTarget;
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		if (IsTargetValid() && autoRotate)
		{
			Vector3 vector = target.GetPos() - transform.position;
			float num = 0f - Mathf.Atan2(vector.z, vector.x);
			transform.rotation = Quaternion.Euler(0f, (num + 90f) * 57.29578f, 0f);
		}
		switch (status)
		{
		case Status.Idle:
			if (manned && IsTargetValid() && TargetInRange())
			{
				status = Status.Firing;
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("CatapultProjectile", transform.position);
			}
			break;
		case Status.PullingBack:
			projectileXform.gameObject.SetActive(value: false);
			rotation -= deltaTime * pullbackSpeed;
			arm.localRotation = Quaternion.Euler(rotation, 0f, 0f);
			if (rotation <= 0f)
			{
				projectileXform.gameObject.SetActive(value: true);
				status = Status.Idle;
			}
			break;
		case Status.Firing:
			rotation += deltaTime * fireSpeed;
			arm.localRotation = Quaternion.Euler(rotation, 0f, 0f);
			if (rotation >= 90f)
			{
				status = Status.PullingBack;
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("CatapultArm", transform.position);
				if (IsTargetValid())
				{
					catapultProjectile.Create(projectileXform.position, projectileXform.rotation, target as IProjectileHitable, teamID);
				}
			}
			break;
		}
	}

	public static bool DefaultShouldIgnore(Building b)
	{
		if (b.categoryHash != gateHash && b.uniqueNameHash != castleblockHash)
		{
			return b.uniqueNameHash != woodcastleblockHash;
		}
		return false;
	}

	public static bool VikingShouldIgnore(Building b)
	{
		if (b.categoryHash == World.pathHash || b.uniqueNameHash == World.rubbleHash || b.uniqueNameHash == World.moatHash || b.uniqueNameHash == World.pierHash || b.categoryHash == World.cemeteryHash)
		{
			return true;
		}
		if (Player.inst.difficulty != Player.Difficulty.Survival && b.uniqueNameHash == World.keepHash)
		{
			return true;
		}
		return false;
	}

	public static Building FindTarget(Catapult catapult, ShouldIgnore ignoreFunc, Vector3 preferredTarget)
	{
		Vector3 position = catapult.transform.position;
		int num = catapult.range;
		int num2 = Mathff.Clamp((int)position.x - num, 0, World.inst.GridWidth - 1);
		int num3 = Mathff.Clamp((int)position.z - num, 0, World.inst.GridHeight - 1);
		int num4 = Mathff.Clamp((int)position.x + num, 0, World.inst.GridWidth - 1);
		int num5 = Mathff.Clamp((int)position.z + num, 0, World.inst.GridHeight - 1);
		Building result = null;
		float num6 = float.MaxValue;
		for (int i = num2; i <= num4; i++)
		{
			for (int j = num3; j <= num5; j++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i, j);
				Building building = cellDataUnsafe.GetTopMostCastlePiece();
				if (building == null)
				{
					building = cellDataUnsafe.TopStructure;
				}
				if ((bool)building && !ignoreFunc(building))
				{
					float num7 = Mathff.DistSqrdXZ(building.Center(), position);
					if (Mathff.DistSqrdXZ(building.Center(), preferredTarget) < 0.25f)
					{
						num7 = 0f;
					}
					if (num7 < num6 && num7 < (float)(num * num))
					{
						num6 = num7;
						result = building;
					}
				}
			}
		}
		return result;
	}
}
