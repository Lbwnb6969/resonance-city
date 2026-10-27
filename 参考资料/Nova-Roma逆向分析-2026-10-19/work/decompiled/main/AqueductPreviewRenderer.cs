using UnityEngine;

public class AqueductPreviewRenderer
{
	public Vector3 UpdateInlineHoverPreview(AqueductLine previewLine, AqueductLine line, RaycastHit hitInfo, Vector3 cursorPoint, float endpointSnapDistance)
	{
		if (line == null || !line.TryGetClosestPoint(hitInfo.point, out var intersection))
		{
			return cursorPoint;
		}
		Vector3 vector = intersection.point;
		int segmentIndex = intersection.segmentIndex;
		Vector3 vector2 = line.waypoints[segmentIndex];
		Vector3 vector3 = line.waypoints[Mathf.Min(segmentIndex + 1, line.waypoints.Length - 1)];
		float num = endpointSnapDistance * endpointSnapDistance;
		if ((intersection.point - line.waypoints[0]).sqrMagnitude <= num)
		{
			vector = line.waypoints[0];
			segmentIndex = 0;
			vector2 = line.waypoints[0];
			vector3 = line.waypoints[1];
		}
		else if ((intersection.point - line.waypoints[^1]).sqrMagnitude <= num)
		{
			vector = line.waypoints[^1];
			segmentIndex = line.waypoints.Length - 2;
			vector2 = line.waypoints[^2];
			vector3 = line.waypoints[^1];
		}
		else
		{
			int num2 = -1;
			float num3 = num;
			for (int i = 1; i < line.waypoints.Length - 1; i++)
			{
				float sqrMagnitude = (intersection.point - line.waypoints[i]).sqrMagnitude;
				if (sqrMagnitude <= num3)
				{
					num3 = sqrMagnitude;
					num2 = i;
				}
			}
			if (num2 >= 0)
			{
				vector = line.waypoints[num2];
				segmentIndex = num2 - 1;
				vector2 = line.waypoints[num2 - 1];
				vector3 = line.waypoints[num2];
			}
		}
		Vector3 rhs = vector3 - vector2;
		rhs.y = 0f;
		if (rhs.sqrMagnitude < 0.0001f)
		{
			rhs = Vector3.forward;
		}
		rhs.Normalize();
		Vector3 vector4 = Vector3.Cross(Vector3.up, rhs).normalized;
		if (vector4.sqrMagnitude < 0.001f)
		{
			vector4 = Vector3.right;
		}
		float num4 = Mathf.Sign(Vector3.Dot((cursorPoint - vector).xz(), vector4.xz()));
		if (Mathf.Abs(num4) < 0.01f)
		{
			if (cursorPoint.z > vector.z)
			{
				num4 = 1f;
			}
			else
			{
				num4 = ((!(cursorPoint.z < vector.z)) ? 1f : (-1f));
			}
		}
		float num5 = 1f;
		Vector3 vector5 = vector + vector4 * num4 * num5;
		previewLine.waypoints = new Vector3[2] { vector, vector5 };
		AqueductLine.GradeWaypoints(ref previewLine.waypoints);
		previewLine.FullBuild();
		return vector;
	}
}
