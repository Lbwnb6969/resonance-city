using System;
using Assets;
using UnityEngine;

public class Ballista : WagePayer, IOutputInfo
{
	private enum State
	{
		PullBack,
		Firing
	}

	public GameObject flag;

	public Transform RotateParent;

	public Transform ArmR;

	public Transform ArmL;

	public Transform StringR;

	public Transform StringL;

	public Transform Bolt;

	public ProjectileDefense pd;

	public Building b;

	private float fullAttackTime;

	public float LongestAttackTime = 6f;

	private MeshRenderer parentRenderer;

	private float pullbackAngle = 25f;

	private State state;

	private float pullbackTime;

	private float fireTime;

	private int updateFrame;

	private int frameCount;

	private int frameSpread = 15;

	public Transform veteranDecor;

	public float MinTargetAngleForFiring = 15f;

	public float RotateSpeed = 10f;

	private float workerPercent;

	private bool firstUpdate = true;

	private Quaternion rotOffset = Quaternion.Euler(0f, 90f, 0f);

	string IOutputInfo.GetError()
	{
		if (b.GetWorkerPercent() <= 0f)
		{
			return "ScriptLocalization.ArcherNotManning";
		}
		return null;
	}

	public void PlacementValidation(ref PlacementValidationResult result)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		result = PlacementValidationResult.Valid;
		if (!cellDataClamped.StructureMatch(false, Cell.StructureType.SurfaceStructure, World.rubbleHash, World.castleblockHash) && !cellDataClamped.StructureMatch(false, Cell.StructureType.SurfaceStructure, World.castleblockHash) && !cellDataClamped.StructureMatch(false, Cell.StructureType.SurfaceStructure, World.rubbleHash, World.woodcastleblockHash) && !cellDataClamped.StructureMatch(false, Cell.StructureType.SurfaceStructure, World.woodcastleblockHash))
		{
			result = PlacementValidationResult.OnlyStackOnCastleBlocks;
		}
	}

	private void OnInit()
	{
		b = GetComponent<Building>();
		fullAttackTime = pd.AttackTime;
		useHazardPay = true;
		b.visibilityChanged += B_visibilityChanged;
		updateFrame = SRand.Range(0, frameSpread);
		parentRenderer = RotateParent.GetComponent<MeshRenderer>();
		b.PlacementValidaton = PlacementValidation;
	}

	private void B_visibilityChanged(bool v)
	{
		flag.GetComponent<MeshRenderer>().enabled = v;
		veteranDecor.GetComponent<MeshRenderer>().enabled = v;
	}

	private void OnShutdown()
	{
		b.visibilityChanged -= B_visibilityChanged;
	}

	private float GetTimeBetweenShots()
	{
		float num = 0.3f * b.GetAvgSkill();
		float num2 = b.GetWorkerPercent();
		float result = Mathf.Lerp(LongestAttackTime, fullAttackTime * (1f - num), num2);
		if (num2 == 0f)
		{
			result = float.MaxValue;
		}
		return result;
	}

	private void OnBuildingPlacement(bool undo)
	{
		Vector3 position = GetComponent<Building>().transform.position;
		int num = (int)position.x;
		int num2 = (int)position.z;
		World.inst.ForEachTile(num - 7, num2 - 7, num + 7, num2 + 7, (int x, int z, Cell cell) =>
		{
			cell.Danger += ((!undo) ? 1 : (-1));
		});
		Material uniMaterialFor = World.GetUniMaterialFor(b.LandMass());
		parentRenderer.material = uniMaterialFor;
		Bolt.GetComponent<MeshRenderer>().material = uniMaterialFor;
		StringR.GetComponent<MeshRenderer>().material = uniMaterialFor;
		StringL.GetComponent<MeshRenderer>().material = uniMaterialFor;
		ArmL.GetComponentInChildren<MeshRenderer>().material = uniMaterialFor;
		ArmR.GetComponentInChildren<MeshRenderer>().material = uniMaterialFor;
		veteranDecor.GetComponent<MeshRenderer>().material = uniMaterialFor;
		BlockBuilding.MarkBlockStackDirty(b.GetCell());
	}

	private void SetRotationY(Transform t, float y)
	{
		if (parentRenderer.isVisible)
		{
			Quaternion localRotation = t.localRotation;
			Vector3 eulerAngles = localRotation.eulerAngles;
			eulerAngles.y = y;
			localRotation.eulerAngles = eulerAngles;
			t.localRotation = localRotation;
		}
	}

	private void FireProjectile()
	{
		if (state == State.PullBack && pullbackTime >= 0.999f)
		{
			state = State.Firing;
			pullbackTime = 1f;
			fireTime = 0f;
			SfxSystem.inst.PlayFromBankIfVisibleOneShot("BallistaFireBolt", transform.position);
			Bolt.gameObject.SetActive(value: false);
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (StreamerEffects.Flag_FasterAttackSpeed)
		{
			dt *= 2f;
		}
		frameCount++;
		if (frameCount % frameSpread == updateFrame || firstUpdate)
		{
			firstUpdate = false;
			veteranDecor.gameObject.SetActive(b.GetAvgSkill() > 0.5f);
			workerPercent = b.GetWorkerPercent() * (float)(b.AreWorkersNear(b.jobs.Count) ? 1 : 0);
			flag.SetActive(workerPercent > 0f);
		}
		if (!b.IsBuilt() || workerPercent <= 0f)
		{
			pd.suppressFiring = true;
			return;
		}
		IProjectileHitable projectileHitable = pd.attackTarget;
		if (projectileHitable == null || projectileHitable.Equals(null))
		{
			projectileHitable = pd.trackingTarget;
		}
		if (projectileHitable != null && !projectileHitable.Equals(null))
		{
			Vector3 forward = RotateParent.position - projectileHitable.GetPredictedPosition(1f);
			Quaternion to = Quaternion.LookRotation(forward);
			float num = Vector3.Dot(forward.normalized, RotateParent.forward);
			pd.suppressFiring = num < Mathf.Cos(MathF.PI / 180f * MinTargetAngleForFiring);
			RotateParent.rotation = Quaternion.RotateTowards(RotateParent.rotation, to, Time.deltaTime * RotateSpeed);
		}
		if (state == State.PullBack)
		{
			pullbackTime += dt;
			if (pullbackTime > 1f)
			{
				pullbackTime = 1f;
			}
			else
			{
				UpdateString(StringL, ArmL);
				UpdateString(StringR, ArmR);
			}
			float t = Mathf.SmoothStep(0f, 1f, pullbackTime);
			SetRotationY(ArmL, Mathff.Lerp(0f, 0f - pullbackAngle, t));
			SetRotationY(ArmR, Mathff.Lerp(0f, pullbackAngle, t));
			Vector3 localPosition = Bolt.localPosition;
			localPosition.z = Mathf.Lerp(-0.15f, 0.15f, t);
			Bolt.localPosition = localPosition;
		}
		else if (state == State.Firing)
		{
			fireTime += dt * 5f;
			if (fireTime > 1f)
			{
				fireTime = 1f;
				state = State.PullBack;
				pullbackTime = 0f;
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("BallistaPullBack", transform.position);
				Bolt.gameObject.SetActive(value: true);
				Vector3 localPosition2 = Bolt.localPosition;
				localPosition2.z = 0f;
				Bolt.localPosition = localPosition2;
			}
			else
			{
				UpdateString(StringL, ArmL);
				UpdateString(StringR, ArmR);
			}
			float t2 = Mathf.SmoothStep(0f, 1f, fireTime);
			SetRotationY(ArmL, Mathff.Lerp(0f - pullbackAngle, 0f, t2));
			SetRotationY(ArmR, Mathff.Lerp(pullbackAngle, 0f, t2));
		}
	}

	private void UpdateString(Transform Xform, Transform arm)
	{
		if (parentRenderer.isVisible)
		{
			Vector3 position = Bolt.GetChild(0).transform.position;
			Vector3 position2 = arm.GetChild(0).GetChild(0).position;
			Xform.position = (position + position2) * 0.5f;
			Xform.rotation = Quaternion.LookRotation(position2 - position) * rotOffset;
			Vector3 localScale = Xform.localScale;
			localScale.x = (position - position2).magnitude * (2f / 3f);
			Xform.localScale = localScale;
		}
	}
}
