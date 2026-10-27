using System;
using UnityEngine;

[Serializable]
[ExecuteInEditMode]
public class PathEdge : MonoBehaviour
{
	public enum Direction
	{
		BiDirectional,
		Directional
	}

	public PathVertex a;

	public PathVertex b;

	public float weight;

	public Direction direction;

	public LineRenderer line;

	public void FlipDirection()
	{
		PathVertex pathVertex = b;
		PathVertex pathVertex2 = a;
		a = pathVertex;
		b = pathVertex2;
	}

	private bool IsDirectional()
	{
		return direction == Direction.Directional;
	}

	public void Update()
	{
		if (!(a == null) && !(b == null) && !(a.transform == null) && !(b.transform == null))
		{
			transform.position = Vector3.Lerp(a.transform.position, b.transform.position, 0.5f);
			line.SetPositions(new Vector3[2]
			{
				a.transform.position,
				b.transform.position
			});
			weight = Vector3.Distance(a.transform.position, b.transform.position);
		}
	}
}
