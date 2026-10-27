using UnityEngine;

[ExecuteInEditMode]
public class TourismAspectHolder : MonoBehaviour
{
	public float aspect = 1.7777778f;

	public RectTransform p;

	public RectTransform r;

	private void Start()
	{
		p = transform.parent.GetComponent<RectTransform>();
		r = GetComponent<RectTransform>();
	}

	private void LateUpdate()
	{
		float x = p.rect.size.x;
		float y = p.rect.size.y;
		if (x / y > aspect)
		{
			float x2 = y * aspect;
			r.sizeDelta = new Vector2(x2, y);
		}
		else
		{
			float y2 = x / aspect;
			r.sizeDelta = new Vector2(x, y2);
		}
	}
}
