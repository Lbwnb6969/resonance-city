using UnityEngine;
using UnityEngine.UI;

public class WorkshopImage : MonoBehaviour
{
	public RawImage image;

	private void Start()
	{
		image = GetComponent<RawImage>();
	}

	private void Update()
	{
		if (image.texture == null)
		{
			image.color = Color.clear;
		}
		else
		{
			image.color = Color.white;
		}
	}
}
