using UnityEngine;

public class AmbientMusic : MonoBehaviour
{
	private AudioSource[] seasonAmbience;

	internal bool Active;

	private void Start()
	{
		seasonAmbience = GetComponents<AudioSource>();
		for (int i = 0; i < seasonAmbience.Length; i++)
		{
			seasonAmbience[i].volume = 0f;
			seasonAmbience[i].Stop();
		}
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		for (int i = 0; i < seasonAmbience.Length; i++)
		{
			if (i == SeasonManager.GetCurrentSeason().id && Active)
			{
				seasonAmbience[i].volume += unscaledDeltaTime * 1f;
				if (seasonAmbience[i].volume > 0f && !seasonAmbience[i].isPlaying)
				{
					seasonAmbience[i].Play();
				}
			}
			else
			{
				seasonAmbience[i].volume -= unscaledDeltaTime * 1f;
				if (seasonAmbience[i].volume <= 0f && seasonAmbience[i].isPlaying)
				{
					seasonAmbience[i].Pause();
				}
			}
		}
	}
}
