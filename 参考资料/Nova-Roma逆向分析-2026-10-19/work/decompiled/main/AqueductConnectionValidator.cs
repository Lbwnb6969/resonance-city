using System.Collections.Generic;
using System.Linq;
using Drawing;
using UnityEngine;

public class AqueductConnectionValidator
{
	private static readonly int[] BuildingIntersectIgnoreList = new int[6]
	{
		World.damblockHash,
		World.spilloverHash,
		World.waterTowerHash,
		World.waterOutletHash,
		World.archerTowerHash,
		World.ballistaTowerHash
	};

	private static readonly int[] BuildingIntersectIgnoreCategoryList = new int[5]
	{
		World.farmHash,
		World.pathHash,
		World.cemeteryHash,
		World.castleblockHash,
		World.gateHash
	};

	private readonly RaycastHit[] raycastBuffer = new RaycastHit[100];

	private const float COINCIDENT_TOLERANCE = 0.22f;

	private const float MIN_OVERLAP_LENGTH = 0.1f;

	private const float PARALLEL_DOT_THRESHOLD = 0.985f;

	private const float DAM_TAP_MIN_APPROACH_DOT = 0.5f;

	public AqueductPlacementError GetBuildError(AqueductBuilding sourceBuilding, AqueductBuilding destinationBuilding, bool sourcePortAvailable, bool destinationPortAvailable, Vector3[] waypoints, AqueductLine previewLine)
	{
		if (sourceBuilding == null)
		{
			return AqueductPlacementError.None;
		}
		if (sourceBuilding is RiverTap { previewInvalid: not false } riverTap)
		{
			return riverTap.previewError;
		}
		if (destinationBuilding is RiverTap { previewInvalid: not false } riverTap2)
		{
			return riverTap2.previewError;
		}
		if (sourceBuilding.onlyIncoming)
		{
			return AqueductPlacementError.UsingSourceAsIncoming;
		}
		if (destinationBuilding.onlyOutgoing)
		{
			return AqueductPlacementError.UsingDestinationAsOutgoing;
		}
		if (!sourcePortAvailable || !destinationPortAvailable)
		{
			return AqueductPlacementError.NoAvailableSlots;
		}
		if (waypoints != null && waypoints.Length >= 2 && (!IsDamTapApproachValid(sourceBuilding, waypoints[0], waypoints[1]) || !IsDamTapApproachValid(destinationBuilding, waypoints[^1], waypoints[^2])))
		{
			return AqueductPlacementError.DamTapApproachTooOblique;
		}
		bool flag = true;
		bool flag2 = true;
		int num = 0;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 start = waypoints[i];
			Vector3 end = waypoints[i + 1];
			flag &= AqueductLine.LineValidAngleNormal(start, end);
			flag2 &= AqueductLine.LineValidAngleHighPressure(start, end);
			num = AqueductLine.LineTypeOfInvalid(start, end);
		}
		if (previewLine != null && previewLine.NumberOfConstructions() < 1)
		{
			return AqueductPlacementError.TooShort;
		}
		if (!flag && !flag2)
		{
			if (num != AqueductLine.INVALID_STAGNATE)
			{
				return AqueductPlacementError.TooSteep;
			}
			return AqueductPlacementError.TooFlat;
		}
		if (!Creative.inst.IsCreativeOptionOn(0) && !Player.inst.FocusedResources.HasCost(previewLine.GetBuildCost()))
		{
			return AqueductPlacementError.NotEnoughResources;
		}
		if (CheckBuildingIntersections(waypoints))
		{
			return AqueductPlacementError.CantIntersectBuilding;
		}
		if (CheckCoincidentWithExistingLines(waypoints, previewLine))
		{
			return AqueductPlacementError.CoincidentWithExistingLine;
		}
		return AqueductPlacementError.None;
	}

	internal static bool IsDamTapApproachValid(AqueductBuilding building, Vector3 endpoint, Vector3 adjacent)
	{
		if (!(building is RiverTap { damMounted: not false } riverTap))
		{
			return true;
		}
		Vector3 vector = adjacent - endpoint;
		vector.y = 0f;
		Vector3 forward = riverTap.transform.forward;
		forward.y = 0f;
		if (vector.sqrMagnitude < 1E-06f || forward.sqrMagnitude < 1E-06f)
		{
			return false;
		}
		return Vector3.Dot(vector.normalized, forward.normalized) >= 0.4999f;
	}

	public bool CheckCoincidentWithExistingLines(Vector3[] waypoints, AqueductLine previewLine)
	{
		if (waypoints == null || waypoints.Length < 2)
		{
			return false;
		}
		bool result = false;
		List<AqueductLine> allLines = AqueductLine.allLines;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 a = waypoints[i];
			Vector3 a2 = waypoints[i + 1];
			for (int j = 0; j < allLines.Count; j++)
			{
				AqueductLine aqueductLine = allLines[j];
				if (aqueductLine == null || aqueductLine == previewLine)
				{
					continue;
				}
				Vector3[] waypoints2 = aqueductLine.waypoints;
				if (waypoints2 == null || waypoints2.Length < 2)
				{
					continue;
				}
				for (int k = 0; k < waypoints2.Length - 1; k++)
				{
					if (Mathff.SegmentsCoincidentXZ(a, a2, waypoints2[k], waypoints2[k + 1], 0.22f, 0.1f, 0.985f, out var overlapStartOnA, out var overlapEndOnA))
					{
						DrawCoincidentOverlap(overlapStartOnA, overlapEndOnA);
						result = true;
					}
				}
			}
			for (int l = i + 1; l < waypoints.Length - 1; l++)
			{
				if (Mathff.SegmentsCoincidentXZ(a, a2, waypoints[l], waypoints[l + 1], 0.22f, 0.1f, 0.985f, out var overlapStartOnA2, out var overlapEndOnA2))
				{
					DrawCoincidentOverlap(overlapStartOnA2, overlapEndOnA2);
					result = true;
				}
			}
		}
		return result;
	}

	private static void DrawCoincidentOverlap(Vector3 overlapStart, Vector3 overlapEnd)
	{
		Vector3 vector = Vector3.up * 0.3f;
		using (Draw.ingame.WithLineWidth(3f))
		{
			Draw.ingame.Line(overlapStart + vector, overlapEnd + vector, Color.red);
		}
		Draw.ingame.SolidCircle(overlapStart + vector, Vector3.up, 0.12f, Color.red);
		Draw.ingame.SolidCircle(overlapEnd + vector, Vector3.up, 0.12f, Color.red);
	}

	public (bool validNormal, bool validHighPressure) ValidateAngles(Vector3[] waypoints)
	{
		bool flag = true;
		bool flag2 = true;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 start = waypoints[i];
			Vector3 end = waypoints[i + 1];
			flag &= AqueductLine.LineValidAngleNormal(start, end);
			flag2 &= AqueductLine.LineValidAngleHighPressure(start, end);
		}
		return (validNormal: flag, validHighPressure: flag2);
	}

	public bool CheckBuildingIntersections(Vector3[] waypoints)
	{
		if (waypoints == null || waypoints.Length < 2)
		{
			return false;
		}
		bool result = false;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 vector = waypoints[i];
			Vector3 vector2 = waypoints[i + 1] - vector;
			Vector3 normalized = vector2.normalized;
			Ray ray = ((i != 0) ? new Ray(vector, normalized) : new Ray(vector + normalized * 1f, normalized));
			float num = vector2.magnitude;
			if (i == 0)
			{
				num--;
			}
			if (i == waypoints.Length - 2)
			{
				num--;
			}
			int num2 = Physics.RaycastNonAlloc(ray, raycastBuffer, num);
			for (int j = 0; j < num2; j++)
			{
				BuildingCollider component = raycastBuffer[j].collider.GetComponent<BuildingCollider>();
				if (component != null && component.Building != null)
				{
					Building buildingAsBuilding = component.BuildingAsBuilding;
					if ((!(buildingAsBuilding != null) || (!BuildingIntersectIgnoreList.Contains(buildingAsBuilding.uniqueNameHash) && !BuildingIntersectIgnoreCategoryList.Contains(buildingAsBuilding.categoryHash))) && !(component.Building is AqueductLine))
					{
						component.Building.SetOutlineImmediate(2);
						result = true;
					}
				}
			}
		}
		return result;
	}

	public string GetErrorString(AqueductPlacementError error)
	{
		return error.GetErrorString();
	}

	public string GetErrorString(int errorCode)
	{
		return ((AqueductPlacementError)errorCode).GetErrorString();
	}
}
