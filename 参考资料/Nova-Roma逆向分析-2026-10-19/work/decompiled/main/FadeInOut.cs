using UnityEngine;
using UnityEngine.UI;

public class FadeInOut : MonoBehaviour
{
	public Image image;

	public AnimationCurve curve;

	private bool m_pause;

	private float totalTime;

	public float speed = 1f;

	[SerializeField]
	public bool pause
	{
		get
		{
			return m_pause;
		}
		set
		{
			SetPause(value);
		}
	}

	private void Awake()
	{
		if (image == null)
		{
			image = GetComponent<Image>();
		}
	}

	private void Update()
	{
		if (image != null && !m_pause)
		{
			if (totalTime < 1f)
			{
				totalTime += Time.unscaledDeltaTime * speed;
				float a = curve.Evaluate(totalTime);
				Color color = image.color;
				color.a = a;
				image.color = color;
			}
			else
			{
				totalTime = 0f;
			}
		}
	}

	public void SetPause(bool paused)
	{
		m_pause = paused;
		if (paused)
		{
			totalTime = 1f;
			Color color = image.color;
			color.a = 1f;
			image.color = color;
		}
	}
}
