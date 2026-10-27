using FMOD;
using FMOD.Studio;
using FMODUnity;
using UnityEngine;

public class PooledWaterfallParticles : MonoBehaviour
{
	public int type;

	public ParticleSystem splashParticles;

	public ParticleSystem mistParticles;

	public bool readyToRelease;

	public EventInstance ambEvent;

	private static string smallAmbPath = "event:/SFX ASITP/Ambiences/ambSpot_waterfall_small";

	private static string largeAmbPath = "event:/SFX ASITP/Ambiences/ambSpot_waterfall_large";

	public void Init(int type)
	{
		this.type = type;
		readyToRelease = false;
		splashParticles.Play(withChildren: false);
		mistParticles.Play(withChildren: false);
		int ambientType = GetAmbientType();
		if (ambientType != -1 && ambientType != type)
		{
			ambEvent.stop(STOP_MODE.IMMEDIATE);
			ambEvent.release();
			ambEvent = RuntimeManager.CreateInstance((type == 0) ? smallAmbPath : largeAmbPath);
		}
		else if (ambientType == -1)
		{
			ambEvent = RuntimeManager.CreateInstance((type == 0) ? smallAmbPath : largeAmbPath);
		}
		ambEvent.start();
		ambEvent.release();
	}

	private int GetAmbientType()
	{
		if (!ambEvent.isValid())
		{
			return -1;
		}
		if (ambEvent.getDescription(out var description) == RESULT.OK && description.getPath(out var path) == RESULT.OK)
		{
			if (path == smallAmbPath)
			{
				return 0;
			}
			if (path == largeAmbPath)
			{
				return 1;
			}
		}
		return -1;
	}

	public void ReadyForRelease()
	{
		readyToRelease = true;
		splashParticles.Stop(withChildren: false, ParticleSystemStopBehavior.StopEmitting);
		mistParticles.Stop(withChildren: false, ParticleSystemStopBehavior.StopEmitting);
		if (ambEvent.isValid() && ambEvent.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			ambEvent.stop(STOP_MODE.ALLOWFADEOUT);
		}
	}

	public bool Stopped()
	{
		if (splashParticles.particleCount == 0)
		{
			return mistParticles.particleCount == 0;
		}
		return false;
	}
}
