using System;
using FMOD.Studio;
using UnityEngine;

[Serializable]
public class PooledWaterfallSystem : MonoBehaviour
{
	public PooledWaterfallParticles waterfallParticlePrefab;

	private GameObject container;

	private bool simulationMode;

	private ParticleSystem.MinMaxGradient nonSimColor = new ParticleSystem.MinMaxGradient(new Color(1f, 1f, 1f, 0.4f));

	private ParticleSystem.MinMaxGradient simColor = new ParticleSystem.MinMaxGradient(new Color(1f, 1f, 1f, 0.1f));

	private ArrayExt<PooledWaterfallParticles> particlesInUse;

	private ArrayExt<PooledWaterfallParticles> particlesFree;

	public int type { get; private set; }

	public int ActiveCount => particlesInUse?.Count ?? 0;

	public void Init(int id, int size, GameObject container)
	{
		type = id;
		this.container = container;
		if (particlesInUse != null)
		{
			for (int i = 0; i < particlesInUse.Count; i++)
			{
				PooledWaterfallParticles pooledWaterfallParticles = particlesInUse.data[i];
				if (pooledWaterfallParticles != null)
				{
					pooledWaterfallParticles.readyToRelease = false;
					pooledWaterfallParticles.splashParticles.Stop(withChildren: false, ParticleSystemStopBehavior.StopEmittingAndClear);
					pooledWaterfallParticles.mistParticles.Stop(withChildren: false, ParticleSystemStopBehavior.StopEmittingAndClear);
					if (pooledWaterfallParticles.ambEvent.isValid())
					{
						pooledWaterfallParticles.ambEvent.stop(STOP_MODE.IMMEDIATE);
					}
					pooledWaterfallParticles.gameObject.SetActive(value: false);
					particlesFree.Add(pooledWaterfallParticles);
				}
			}
		}
		ArrayExt<PooledWaterfallParticles> arrayExt = particlesFree;
		particlesInUse = new ArrayExt<PooledWaterfallParticles>(size);
		particlesFree = new ArrayExt<PooledWaterfallParticles>(size);
		if (arrayExt != null)
		{
			particlesFree.AddRange(arrayExt);
		}
	}

	public void PreInstantiate(int count)
	{
		while (particlesFree.Count < count)
		{
			PooledWaterfallParticles pooledWaterfallParticles = UnityEngine.Object.Instantiate(waterfallParticlePrefab);
			pooledWaterfallParticles.transform.SetParent(container.transform);
			pooledWaterfallParticles.gameObject.SetActive(value: false);
			particlesFree.Add(pooledWaterfallParticles);
		}
	}

	public void Tick()
	{
		for (int i = 0; i < particlesInUse.Count; i++)
		{
			PooledWaterfallParticles pooledWaterfallParticles = particlesInUse.data[i];
			if (pooledWaterfallParticles != null && pooledWaterfallParticles.readyToRelease && pooledWaterfallParticles.Stopped())
			{
				particlesInUse.RemoveAtSwap(i);
				particlesFree.Add(pooledWaterfallParticles);
				pooledWaterfallParticles.gameObject.SetActive(value: false);
				i--;
			}
		}
	}

	public PooledWaterfallParticles GetNewParticle()
	{
		PooledWaterfallParticles pooledWaterfallParticles;
		if (particlesFree.Count > 0)
		{
			pooledWaterfallParticles = particlesFree.PopFirst();
			pooledWaterfallParticles.transform.position = Vector3.zero;
			pooledWaterfallParticles.transform.rotation = Quaternion.identity;
			pooledWaterfallParticles.Init(type);
			pooledWaterfallParticles.gameObject.SetActive(value: true);
			ApplyChangesToParticles(pooledWaterfallParticles);
			particlesInUse.Add(pooledWaterfallParticles);
		}
		else
		{
			pooledWaterfallParticles = UnityEngine.Object.Instantiate(waterfallParticlePrefab);
			pooledWaterfallParticles.transform.SetParent(container.transform);
			pooledWaterfallParticles.transform.position = Vector3.zero;
			pooledWaterfallParticles.transform.rotation = Quaternion.identity;
			pooledWaterfallParticles.Init(type);
			ApplyChangesToParticles(pooledWaterfallParticles);
			particlesInUse.Add(pooledWaterfallParticles);
		}
		return pooledWaterfallParticles;
	}

	public void SimulationMode(bool simulationModeOn = true)
	{
		simulationMode = simulationModeOn;
		for (int i = 0; i < particlesInUse.Count; i++)
		{
			PooledWaterfallParticles pooledWaterfallParticles = particlesInUse.data[i];
			if (pooledWaterfallParticles != null)
			{
				ApplyChangesToParticles(pooledWaterfallParticles);
			}
		}
	}

	private void ApplyChangesToParticles(PooledWaterfallParticles system)
	{
		ParticleSystem.MainModule main = system.splashParticles.main;
		main.useUnscaledTime = simulationMode;
		main.startColor = (simulationMode ? simColor : nonSimColor);
		ParticleSystem.MainModule main2 = system.mistParticles.main;
		main2.useUnscaledTime = simulationMode;
		main2.startColor = (simulationMode ? simColor : nonSimColor);
	}
}
