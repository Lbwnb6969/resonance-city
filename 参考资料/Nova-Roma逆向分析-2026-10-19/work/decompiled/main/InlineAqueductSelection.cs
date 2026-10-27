using UnityEngine;

public class InlineAqueductSelection
{
	public AqueductLine line;

	public AqueductJunction junction;

	public int segmentIndex;

	public float segmentT;

	public Vector3 worldPoint;

	public float normalizedT;

	public bool isEndpointConnection;

	public bool endpointIsStart;

	public void Update(AqueductLine.AqueductLineIntersection intersection)
	{
		line = intersection.line;
		segmentIndex = intersection.segmentIndex;
		segmentT = intersection.segmentT;
		worldPoint = intersection.point;
		normalizedT = intersection.normalizedT;
		if (junction != null)
		{
			junction.transform.position = worldPoint;
			junction.RefreshRenderInstances();
		}
	}

	public AqueductLine.AqueductLineIntersection ToIntersection()
	{
		return new AqueductLine.AqueductLineIntersection
		{
			line = line,
			segmentIndex = segmentIndex,
			segmentT = segmentT,
			point = worldPoint,
			normalizedT = normalizedT
		};
	}
}
