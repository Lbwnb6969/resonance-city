using System.Collections.Generic;
using UnityEngine;
using cakeslice;

public class LineTracker : MonoBehaviour
{
	protected int lineTrackingCount;

	protected int outlineTrackingCount;

	protected List<LineRenderer> lineRenderers = new List<LineRenderer>(32);

	protected List<Outline> outlines = new List<Outline>(32);

	[Header("Asset References")]
	public LineRenderer lineRendererPrefab;

	[Header("Curve Settings")]
	public float curveYOffset = 3f;

	public float curveXZOffset = 0.5f;

	public int curveSegments = 10;

	public float curveThickness = 0.25f;

	protected float startOffsetRadius = 1f;

	public float endOffsetRadius = 1f;

	public float MAX_DIST = 100f;

	protected Vector3[] points;

	protected ArrayExt<Vector3> filteredPoints;

	private void Start()
	{
		TryInit();
	}

	public void TryInit()
	{
		if (points == null || points.Length != curveSegments + 2)
		{
			points = new Vector3[curveSegments + 2];
		}
		if (filteredPoints == null)
		{
			filteredPoints = new ArrayExt<Vector3>(curveSegments + 2);
		}
	}

	private void LateUpdate()
	{
		for (int num = lineRenderers.Count - 1; num >= lineTrackingCount; num--)
		{
			if (lineTrackingCount <= num)
			{
				Util.SetActive(lineRenderers[num].gameObject, active: false);
			}
		}
		for (int num2 = outlines.Count - 1; num2 >= outlineTrackingCount; num2--)
		{
			if (outlineTrackingCount <= num2)
			{
				outlines[num2].Disable();
			}
		}
		lineTrackingCount = 0;
		outlineTrackingCount = 0;
	}

	public bool IntersectsRay(Vector3 origin, float radius, Ray ray, out float hitDist)
	{
		hitDist = float.MaxValue;
		return Mathff.RaySphereIntersect(ray, origin, radius, out hitDist);
	}

	protected LineRenderer GetLineRenderer()
	{
		if (lineTrackingCount == lineRenderers.Count)
		{
			LineRenderer lineRenderer = Object.Instantiate(lineRendererPrefab, transform, worldPositionStays: false);
			lineRenderer.gameObject.name = $"Villager Curve Tracker: {lineRenderers.Count}";
			lineRenderers.Add(lineRenderer);
		}
		LineRenderer lineRenderer2 = lineRenderers[lineTrackingCount++];
		Util.SetActive(lineRenderer2.gameObject, active: true);
		return lineRenderer2;
	}

	protected Outline GetOutline(Mesh mesh)
	{
		if (outlineTrackingCount == outlines.Count)
		{
			Outline item = new Outline();
			outlines.Add(item);
		}
		Outline outline = outlines[outlineTrackingCount++];
		outline.mesh = mesh;
		return outline;
	}

	protected Vector3 DeCasteljauCurve(float t, Vector3[] points)
	{
		float num = 1f - t;
		for (int i = 1; i < points.Length; i++)
		{
			for (int j = 0; j < points.Length - i; j++)
			{
				points[j].x = points[j].x * num + points[j + 1].x * t;
				points[j].y = points[j].y * num + points[j + 1].y * t;
				points[j].z = points[j].z * num + points[j + 1].z * t;
			}
		}
		return points[0];
	}

	protected void DisplayOutline(Mesh mesh, Vector3 pos, Quaternion rot, Vector3 scale)
	{
		Outline outline = GetOutline(mesh);
		outline.meshMtx = Matrix4x4.TRS(pos, rot, scale);
		outline.Enable();
	}

	protected void DisplayLine(Vector3 startPoint, Vector3 endPoint, Color color)
	{
		LineRenderer lineRenderer = GetLineRenderer();
		Color startColor = (lineRenderer.endColor = color);
		lineRenderer.startColor = startColor;
		lineRenderer.widthMultiplier = curveThickness * 0.1f;
		Vector3 vector = Vector3.Lerp(startPoint, endPoint, curveXZOffset);
		float num = Mathff.Min(MAX_DIST, Mathff.Dist(startPoint, endPoint));
		vector.y += num * curveYOffset;
		points[0] = startPoint;
		points[points.Length - 1] = endPoint;
		float num2 = 1f / (float)(curveSegments + 1);
		for (int i = 1; i <= curveSegments + 1; i++)
		{
			points[i] = DeCasteljauCurve(num2 * (float)i, new Vector3[3] { startPoint, vector, endPoint });
		}
		filteredPoints.ClearFast();
		for (int j = 0; j < points.Length; j++)
		{
			if (Mathff.DistSqrd(points[j], startPoint) < startOffsetRadius * startOffsetRadius)
			{
				if (j == points.Length - 1)
				{
					break;
				}
				if (Mathff.DistSqrd(points[j + 1], startPoint) > startOffsetRadius * startOffsetRadius)
				{
					float hitDist = 0f;
					Ray ray = new Ray(points[j], points[j + 1] - points[j]);
					if (IntersectsRay(startPoint, startOffsetRadius, ray, out hitDist))
					{
						filteredPoints.Add(ray.GetPoint(hitDist));
					}
				}
			}
			else
			{
				filteredPoints.Add(points[j]);
			}
		}
		int num3 = filteredPoints.Count - 1;
		while (num3 > 0 && filteredPoints.Count != 0 && Mathff.DistSqrd(filteredPoints.data[num3], endPoint) < endOffsetRadius * endOffsetRadius)
		{
			Vector3 vector2 = filteredPoints.data[num3];
			filteredPoints.RemoveAt(num3);
			if (Mathff.DistSqrd(filteredPoints.data[num3 - 1], endPoint) > endOffsetRadius * endOffsetRadius)
			{
				float hitDist2 = 0f;
				Ray ray2 = new Ray(vector2, filteredPoints.data[num3 - 1] - vector2);
				if (IntersectsRay(endPoint, endOffsetRadius, ray2, out hitDist2))
				{
					filteredPoints.Add(ray2.GetPoint(hitDist2));
					break;
				}
			}
			num3--;
		}
		lineRenderer.positionCount = filteredPoints.Count;
		lineRenderer.SetPositions(filteredPoints.data);
	}
}
