using UnityEngine;

public class InlineSelectionManager
{
	public const float EndpointSnapDistance = 0.35f;

	public const float DirectionSnapDistance = 0.35f;

	public bool WouldCreateShortLine(InlineAqueductSelection selection, InlineAqueductSelection otherSelection)
	{
		if (selection == null || selection.isEndpointConnection || selection.line == null)
		{
			return false;
		}
		AqueductLine line = selection.line;
		Vector3[] waypoints = line.waypoints;
		if (!HasConstructionBetween(line, waypoints[0], 1, selection.segmentIndex, selection.worldPoint) || !HasConstructionBetween(line, selection.worldPoint, selection.segmentIndex + 1, waypoints.Length - 2, waypoints[^1]))
		{
			return true;
		}
		if (otherSelection == null || otherSelection.isEndpointConnection || otherSelection.line != line)
		{
			return false;
		}
		InlineAqueductSelection inlineAqueductSelection = ((selection.normalizedT <= otherSelection.normalizedT) ? selection : otherSelection);
		InlineAqueductSelection inlineAqueductSelection2 = ((inlineAqueductSelection == selection) ? otherSelection : selection);
		return !HasConstructionBetween(line, inlineAqueductSelection.worldPoint, inlineAqueductSelection.segmentIndex + 1, inlineAqueductSelection2.segmentIndex, inlineAqueductSelection2.worldPoint);
	}

	private static bool HasConstructionBetween(AqueductLine line, Vector3 start, int firstWaypoint, int lastWaypoint, Vector3 end)
	{
		for (int i = firstWaypoint; i <= lastWaypoint; i++)
		{
			if ((line.waypoints[i] - start).sqrMagnitude > 0.0001f && (line.waypoints[i] - end).sqrMagnitude > 0.0001f)
			{
				return true;
			}
		}
		return Mathff.Dist(start, end) >= line.aqueductStraight.bounds.size.z;
	}

	public bool TryResolveLineTarget(AqueductLine line, RaycastHit hitInfo, ref InlineAqueductSelection selection, out AqueductBuilding building, out AqueductLine.AqueductLineIntersection resolvedIntersection, Ray? directionSnap = null)
	{
		building = null;
		resolvedIntersection = default;
		if (line == null || !line.fullyConstructed || line.waypoints == null || line.waypoints.Length < 2)
		{
			return false;
		}
		if (!line.TryGetClosestPoint(hitInfo.point, out var intersection))
		{
			return false;
		}
		if (directionSnap.HasValue && TryGetDirectionIntersection(line, directionSnap.Value, intersection.point, out var result) && (result.point - intersection.point).sqrMagnitude <= 0.122499995f)
		{
			intersection = result;
		}
		Vector3 vector = line.waypoints[0];
		Vector3 vector2 = line.waypoints[^1];
		float num = 0.122499995f;
		if ((intersection.point - vector).sqrMagnitude <= num)
		{
			return TryEndpointSnap(line, vector, atStart: true, ref selection, out building);
		}
		if ((intersection.point - vector2).sqrMagnitude <= num)
		{
			return TryEndpointSnap(line, vector2, atStart: false, ref selection, out building);
		}
		int num2 = -1;
		float num3 = num;
		for (int i = 1; i < line.waypoints.Length - 1; i++)
		{
			if (!((line.waypoints[i] - vector).sqrMagnitude <= num) && !((line.waypoints[i] - vector2).sqrMagnitude <= num))
			{
				float sqrMagnitude = (intersection.point - line.waypoints[i]).sqrMagnitude;
				if (sqrMagnitude <= num3)
				{
					num3 = sqrMagnitude;
					num2 = i;
				}
			}
		}
		if (num2 >= 0)
		{
			intersection = WaypointIntersection(line, num2);
		}
		if (selection == null || selection.junction == null)
		{
			selection = new InlineAqueductSelection
			{
				junction = AqueductJunction.Create(intersection.point, preview: true)
			};
		}
		selection.isEndpointConnection = false;
		selection.Update(intersection);
		HeightMarker.Show(selection.worldPoint);
		building = selection.junction;
		resolvedIntersection = intersection;
		return true;
	}

	public bool TryGetDirectionIntersection(AqueductLine line, Ray ray, Vector3 nearPoint, out AqueductLine.AqueductLineIntersection result)
	{
		result = default;
		if (line == null || line.waypoints == null || line.waypoints.Length < 2)
		{
			return false;
		}
		Vector2 vector = new Vector2(ray.origin.x, ray.origin.z);
		Vector2 vector2 = new Vector2(ray.direction.x, ray.direction.z);
		if (vector2.sqrMagnitude < 1E-08f)
		{
			return false;
		}
		float num = 0f;
		for (int i = 0; i < line.waypoints.Length - 1; i++)
		{
			num += Vector3.Distance(line.waypoints[i], line.waypoints[i + 1]);
		}
		if (num < 1E-05f)
		{
			return false;
		}
		bool result2 = false;
		float num2 = float.MaxValue;
		float num3 = 0f;
		for (int j = 0; j < line.waypoints.Length - 1; j++)
		{
			Vector3 a = line.waypoints[j];
			Vector3 b = line.waypoints[j + 1];
			float num4 = Vector3.Distance(a, b);
			Vector2 vector3 = new Vector2(a.x, a.z);
			Vector2 vector4 = new Vector2(b.x - a.x, b.z - a.z);
			float num5 = vector2.x * vector4.y - vector2.y * vector4.x;
			if (Mathf.Abs(num5) > 1E-06f)
			{
				Vector2 vector5 = vector3 - vector;
				float num6 = (vector5.x * vector4.y - vector5.y * vector4.x) / num5;
				float num7 = (vector5.x * vector2.y - vector5.y * vector2.x) / num5;
				if (num6 > 0.001f && num7 >= 0f && num7 <= 1f)
				{
					Vector3 vector6 = Vector3.Lerp(a, b, num7);
					float sqrMagnitude = (vector6 - nearPoint).sqrMagnitude;
					if (sqrMagnitude < num2)
					{
						num2 = sqrMagnitude;
						result = new AqueductLine.AqueductLineIntersection
						{
							line = line,
							segmentIndex = j,
							segmentT = num7,
							normalizedT = (num3 + num7 * num4) / num,
							point = vector6
						};
						result2 = true;
					}
				}
			}
			num3 += num4;
		}
		return result2;
	}

	private static AqueductLine.AqueductLineIntersection WaypointIntersection(AqueductLine line, int w)
	{
		float num = 0f;
		float num2 = 0f;
		for (int i = 0; i < line.waypoints.Length - 1; i++)
		{
			float num3 = Vector3.Distance(line.waypoints[i], line.waypoints[i + 1]);
			if (i < w)
			{
				num2 += num3;
			}
			num += num3;
		}
		return new AqueductLine.AqueductLineIntersection
		{
			line = line,
			segmentIndex = w - 1,
			segmentT = 1f,
			normalizedT = ((num > 1E-05f) ? (num2 / num) : 0f),
			point = line.waypoints[w]
		};
	}

	private bool TryEndpointSnap(AqueductLine line, Vector3 snapPoint, bool atStart, ref InlineAqueductSelection selection, out AqueductBuilding building)
	{
		building = null;
		AqueductBuilding aqueductBuilding = (atStart ? line.GetStartBuilding() : line.GetEndBuilding());
		if (aqueductBuilding != null)
		{
			building = aqueductBuilding;
			ClearInlineSelection(ref selection);
			return true;
		}
		if (atStart ? line.IsStartOpen : line.IsEndOpen)
		{
			building = SetupEndpointConnection(ref selection, line, snapPoint, atStart);
			return building != null;
		}
		ClearInlineSelection(ref selection);
		return false;
	}

	private AqueductBuilding SetupEndpointConnection(ref InlineAqueductSelection selection, AqueductLine line, Vector3 endpoint, bool atStart)
	{
		if (selection == null || selection.junction == null)
		{
			selection = new InlineAqueductSelection
			{
				junction = AqueductJunction.Create(endpoint, preview: true)
			};
		}
		selection.line = line;
		selection.worldPoint = endpoint;
		selection.normalizedT = (atStart ? 0f : 1f);
		selection.isEndpointConnection = true;
		selection.endpointIsStart = atStart;
		selection.junction.transform.position = endpoint;
		selection.junction.RefreshRenderInstances();
		HeightMarker.Show(endpoint);
		return selection.junction;
	}

	public void ClearInlineSelection(ref InlineAqueductSelection selection)
	{
		if (selection != null && selection.junction != null)
		{
			Object.Destroy(selection.junction.gameObject);
		}
		selection = null;
	}

	public InlineSplitResult? FinalizeInlineSelection(ref InlineAqueductSelection selection)
	{
		if (selection == null || selection.junction == null)
		{
			return null;
		}
		AqueductLine line = selection.line;
		selection.junction.FinalizePlacement();
		if (selection.isEndpointConnection)
		{
			line?.CloseOpenEnd(selection.junction, selection.endpointIsStart);
			selection = null;
			return null;
		}
		InlineSplitResult? result = null;
		if (line != null)
		{
			AqueductLine.AqueductLineIntersection intersection = new AqueductLine.AqueductLineIntersection
			{
				line = line,
				segmentIndex = selection.segmentIndex,
				segmentT = selection.segmentT,
				point = selection.worldPoint,
				normalizedT = selection.normalizedT
			};
			(AqueductLine, AqueductLine) tuple = AqueductLine.SplitLineAt(line, selection.junction, intersection);
			if (tuple.Item1 != null && tuple.Item2 != null)
			{
				result = new InlineSplitResult
				{
					originalLine = line,
					upstreamLine = tuple.Item1,
					downstreamLine = tuple.Item2,
					splitNormalizedT = selection.normalizedT
				};
			}
		}
		selection = null;
		return result;
	}

	public void AdjustSelectionForSplit(InlineAqueductSelection selection, InlineSplitResult splitResult)
	{
		if (selection == null || (object)splitResult.originalLine == null || (object)selection.line != splitResult.originalLine)
		{
			return;
		}
		if (selection.isEndpointConnection)
		{
			selection.line = (selection.endpointIsStart ? splitResult.upstreamLine : splitResult.downstreamLine);
			return;
		}
		AqueductLine aqueductLine = ((selection.normalizedT <= splitResult.splitNormalizedT) ? splitResult.upstreamLine : splitResult.downstreamLine);
		AqueductLine line = ((aqueductLine == splitResult.upstreamLine) ? splitResult.downstreamLine : splitResult.upstreamLine);
		AqueductLine.AqueductLineIntersection? aqueductLineIntersection = TryGetIntersectionOnLine(aqueductLine, selection.worldPoint);
		AqueductLine.AqueductLineIntersection? aqueductLineIntersection2 = TryGetIntersectionOnLine(line, selection.worldPoint);
		AqueductLine.AqueductLineIntersection? aqueductLineIntersection3 = null;
		if (aqueductLineIntersection.HasValue && aqueductLineIntersection2.HasValue)
		{
			float sqrMagnitude = (aqueductLineIntersection.Value.point - selection.worldPoint).sqrMagnitude;
			float sqrMagnitude2 = (aqueductLineIntersection2.Value.point - selection.worldPoint).sqrMagnitude;
			aqueductLineIntersection3 = ((sqrMagnitude <= sqrMagnitude2) ? aqueductLineIntersection : aqueductLineIntersection2);
		}
		else
		{
			aqueductLineIntersection3 = aqueductLineIntersection ?? aqueductLineIntersection2;
		}
		if (aqueductLineIntersection3.HasValue)
		{
			selection.Update(aqueductLineIntersection3.Value);
		}
		else
		{
			selection.line = null;
		}
	}

	public bool AreSelectionsParallel(InlineAqueductSelection startSelection, AqueductLine.AqueductLineIntersection destination)
	{
		if (startSelection == null || destination.line == null)
		{
			return false;
		}
		return (startSelection.worldPoint - destination.point).sqrMagnitude < 0.0001f;
	}

	public static Vector3 GetSegmentDirection(AqueductLine line, int segmentIndex)
	{
		if (line == null || line.waypoints == null || line.waypoints.Length < 2)
		{
			return Vector3.forward;
		}
		int num = Mathf.Clamp(segmentIndex, 0, line.waypoints.Length - 2);
		Vector3 vector = line.waypoints[num];
		Vector3 vector2 = line.waypoints[num + 1] - vector;
		vector2.y = 0f;
		if (vector2.sqrMagnitude < 0.0001f)
		{
			return Vector3.forward;
		}
		return vector2.normalized;
	}

	public AqueductLine.AqueductLineIntersection? TryGetIntersectionOnLine(AqueductLine line, Vector3 worldPoint)
	{
		if (line != null && line.TryGetClosestPoint(worldPoint, out var intersection))
		{
			return intersection;
		}
		return null;
	}
}
