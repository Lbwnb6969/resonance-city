using UnityEngine;

public class StartIntoMusicEarly : MonoBehaviour
{
	private void Update()
	{
		if (MusicSystem.inst != null)
		{
			MusicSystem.inst.StartMainMenuMusic();
			Object.Destroy(this);
		}
	}
}
