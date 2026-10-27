using UnityEngine;

public class RadiusDisplay : MonoBehaviour
{
	public Vector3 middle = new Vector3(0.5f, 0.25f, 0.5f);

	private LineRenderer lineRenderer;

	public float Radius = 5f;

	private Building b;

	private void Start()
	{
		lineRenderer = GetComponent<LineRenderer>();
		lineRenderer.useWorldSpace = false;
		UpdateRadius();
		lineRenderer.enabled = false;
	}

	public void UpdateRadius()
	{
		if (!lineRenderer)
		{
			lineRenderer = GetComponent<LineRenderer>();
		}
		Util.SetCircle(lineRenderer, middle, Radius, 32);
	}

	private void SetupReferences()
	{
		if (!b)
		{
			b = GetComponent<Building>();
		}
		if (!lineRenderer)
		{
			lineRenderer = GetComponent<LineRenderer>();
		}
	}

	private void OnSelectionChanged()
	{
		SetupReferences();
	}

	public bool InRadius(Vector3 pos, float r)
	{
		return Vector3.Distance(transform.position + middle, pos) < r + Radius;
	}
}
