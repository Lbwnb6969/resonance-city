using UnityEngine;

public class LightFade : MonoBehaviour
{
	public Light lightToFade;

	public float intensity;

	public float fadeRate = 1f;

	public void OnEnable()
	{
		lightToFade.intensity = intensity;
	}

	private void Update()
	{
		lightToFade.intensity -= fadeRate * Time.deltaTime;
	}
}
