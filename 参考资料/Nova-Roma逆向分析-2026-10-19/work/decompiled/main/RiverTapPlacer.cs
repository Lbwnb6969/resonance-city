using System;
using UnityEngine;

public class RiverTapPlacer
{
	public class DamFaceHit
	{
		public Cell wallCell;

		public Vector3 dirIntoWall;

		public Vector3 tapPos;

		public float distance;

		public bool hasWaterBehind;

		public AqueductPlacementError error;
	}

	public const float RiverTapUnderwater = 0.25f;

	public const float DamFaceOffset = 0.02f;

	private const float INTAKE_PROBE_INTERVAL = 0.5f;

	private Vector3 probedTapPos;

	private Vector3 probedDir;

	private float probedCapacity;

	private float probedAt = float.NegativeInfinity;

	private readonly RaycastHit[] damRaycastBuffer = new RaycastHit[100];

	private float CachedIntakeCapacity(Vector3 tapPos, Vector3 dirIntoWall, Cell waterCell)
	{
		if (tapPos != probedTapPos || dirIntoWall != probedDir || Time.unscaledTime - probedAt > 0.5f)
		{
			probedTapPos = tapPos;
			probedDir = dirIntoWall;
			probedCapacity = RiverTap.DamIntakeCapacityHuman(tapPos, dirIntoWall, waterCell);
			probedAt = Time.unscaledTime;
		}
		return probedCapacity;
	}

	public bool TryGetDamFaceUnderCursor(Ray ray, out DamFaceHit face)
	{
		face = null;
		float num = float.MaxValue;
		if (Physics.Raycast(ray, out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
		{
			num = hitInfo.distance;
		}
		int num2 = Physics.RaycastNonAlloc(ray, damRaycastBuffer, 1000f);
		float num3 = float.MaxValue;
		Building building = null;
		RaycastHit raycastHit = default;
		for (int i = 0; i < num2; i++)
		{
			Building componentInParent = damRaycastBuffer[i].collider.GetComponentInParent<Building>();
			if (!(componentInParent == null) && componentInParent.uniqueNameHash == World.damHash && componentInParent.IsBuilt())
			{
				float distance = damRaycastBuffer[i].distance;
				if (!(distance >= num - 0.01f) && !(distance >= num3))
				{
					num3 = distance;
					building = componentInParent;
					raycastHit = damRaycastBuffer[i];
				}
			}
		}
		if (building == null)
		{
			return false;
		}
		if (Mathf.Abs(raycastHit.normal.y) > 0.5f)
		{
			return false;
		}
		Cell cell = building.GetCell();
		if (cell == null || DamProjectManager.inst.IsCellPartOfProject(cell, out var _))
		{
			return false;
		}
		if (cell.StructureCompareUniqueNameAll(World.spilloverHash))
		{
			return false;
		}
		float f = Mathf.Round(Mathf.Atan2(raycastHit.normal.x, raycastHit.normal.z) * 57.29578f / 45f) * 45f * (MathF.PI / 180f);
		Vector3 vector = new Vector3(Mathf.Sin(f), 0f, Mathf.Cos(f));
		float num4 = (float)building.StackHeight * 0.25f;
		float y = building.transform.position.y + num4 * 0.5f;
		Vector3 tapPos = new Vector3((float)cell.x + 0.5f, y, (float)cell.z + 0.5f) + vector * 0.52f;
		if (!RiverTap.CellHasBuiltDamAt(cell, y))
		{
			return false;
		}
		bool flag = RiverTap.TryFindWaterCellThroughDam(tapPos, -vector, out var waterCell);
		bool flag2 = flag && CachedIntakeCapacity(tapPos, -vector, waterCell) > 1f;
		face = new DamFaceHit
		{
			wallCell = cell,
			dirIntoWall = -vector,
			tapPos = tapPos,
			distance = num3,
			hasWaterBehind = flag2,
			error = ((!flag2) ? (flag ? AqueductPlacementError.DamWaterTooLow : AqueductPlacementError.DamNoWaterBehindWall) : AqueductPlacementError.None)
		};
		return true;
	}

	public RiverTap CreateDamMountedTap(DamFaceHit face, bool removeColliders = false)
	{
		GameObject gameObject = new GameObject("RiverTap");
		gameObject.transform.position = face.tapPos;
		RiverTap riverTap = gameObject.AddComponent<RiverTap>();
		riverTap.noColliders = removeColliders;
		riverTap.MountOnDam(face.tapPos, face.dirIntoWall);
		riverTap.previewError = face.error;
		if (removeColliders)
		{
			Collider[] componentsInChildren = riverTap.GetComponentsInChildren<Collider>();
			for (int i = 0; i < componentsInChildren.Length; i++)
			{
				UnityEngine.Object.Destroy(componentsInChildren[i]);
			}
		}
		return riverTap;
	}

	public void UpdateDamMount(RiverTap tap, DamFaceHit face)
	{
		if (tap != null)
		{
			tap.MountOnDam(face.tapPos, face.dirIntoWall);
			tap.previewError = face.error;
		}
	}

	public RiverTap CreateRiverTap(Vector3 waterHitPoint, bool removeColliders = false)
	{
		GameObject gameObject = new GameObject("RiverTap");
		gameObject.transform.position = CalculatePosition(waterHitPoint);
		RiverTap riverTap = gameObject.AddComponent<RiverTap>();
		if (removeColliders)
		{
			Collider[] componentsInChildren = riverTap.GetComponentsInChildren<Collider>();
			for (int i = 0; i < componentsInChildren.Length; i++)
			{
				UnityEngine.Object.Destroy(componentsInChildren[i]);
			}
		}
		return riverTap;
	}

	public void UpdatePosition(RiverTap tap, Vector3 waterHitPoint)
	{
		if (tap != null)
		{
			tap.transform.position = CalculatePosition(waterHitPoint);
		}
	}

	private Vector3 CalculatePosition(Vector3 waterHitPoint)
	{
		Vector3 vector = waterHitPoint;
		float interpolatedHeight = TerrainGen.inst.GetInterpolatedHeight(vector);
		vector.y = Mathff.Max(interpolatedHeight, waterHitPoint.y - 0.25f);
		return vector;
	}

	public void CleanupPreviewRiverTap(ref RiverTap tap)
	{
		if (tap != null)
		{
			UnityEngine.Object.Destroy(tap.gameObject);
			tap = null;
		}
	}

	public void CleanupDestinationRiverTap(ref AqueductBuilding tap)
	{
		if (tap != null)
		{
			UnityEngine.Object.Destroy(tap.gameObject);
			tap = null;
		}
	}
}
