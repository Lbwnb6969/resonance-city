using UnityEngine;
using UnityEngine.UI;

public class GlueCameraToUI : MonoBehaviour
{
	public Camera cam;

	public int width = 500;

	public int height = 500;

	public FilterMode filterMode;

	private RenderTexture rTexture;

	private void Awake()
	{
		rTexture = new RenderTexture(width, height, 16, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
		rTexture.useMipMap = false;
		rTexture.filterMode = filterMode;
		cam.targetTexture = rTexture;
		GetComponent<RawImage>().texture = rTexture;
	}

	private void Update()
	{
		cam.Render();
	}
}
