using UnityEngine;
using UnityEngine.UI;

public class BatchMaterial : MonoBehaviour
{
	public Image[] images;

	public Material material;

	private void Start()
	{
		for (int i = 0; i < images.Length; i++)
		{
			Color color = images[i].color;
			images[i].material = Object.Instantiate(material);
			images[i].material.SetColor("_Color", color);
		}
	}

	public void SetFloat(string name, float value)
	{
		for (int i = 0; i < images.Length; i++)
		{
			images[i].material.SetFloat(name, value);
		}
	}
}
