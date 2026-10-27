using FMODUnity;
using UnityEngine;

public class WaterfallParticleManager : MonoBehaviour
{
	public PooledWaterfallSystem[] systems;

	private PooledWaterfallParticles[] particles;

	private GameObject particleContainer;

	[Tooltip("Maximum total active waterfall particles across all systems. Set to 0 for unlimited.")]
	public int maxActiveParticles = 300;

	public void Init(int size)
	{
		if (particleContainer == null)
		{
			particleContainer = new GameObject("WaterfallParticles");
			particleContainer.transform.SetParent(transform);
		}
		particles = new PooledWaterfallParticles[size];
		for (int i = 0; i < systems.Length; i++)
		{
			systems[i].Init(i, size, particleContainer);
		}
		if (maxActiveParticles > 0 && systems.Length != 0)
		{
			int num = maxActiveParticles / systems.Length;
			int num2 = maxActiveParticles % systems.Length;
			for (int j = 0; j < systems.Length; j++)
			{
				int count = num + ((j < num2) ? 1 : 0);
				systems[j].PreInstantiate(count);
			}
		}
	}

	public void Update()
	{
		if (particles != null)
		{
			for (int i = 0; i < systems.Length; i++)
			{
				systems[i].Tick();
			}
		}
	}

	private int GetTotalActiveCount()
	{
		int num = 0;
		for (int i = 0; i < systems.Length; i++)
		{
			num += systems[i].ActiveCount;
		}
		return num;
	}

	public void ShowParticles(int id, int type, bool showing)
	{
		if (particles[id] != null && (particles[id].type != type || !showing))
		{
			particles[id].ReadyForRelease();
			particles[id] = null;
		}
		if (showing && particles[id] == null && (maxActiveParticles <= 0 || GetTotalActiveCount() < maxActiveParticles))
		{
			particles[id] = systems[type].GetNewParticle();
		}
	}

	public void UpdateTransform(int id, Vector3 pos, Quaternion rotation)
	{
		if (particles[id] != null)
		{
			particles[id].transform.position = pos;
			particles[id].transform.rotation = rotation;
			particles[id].ambEvent.set3DAttributes(pos.To3DAttributes());
		}
	}

	public void SimulationMode(bool simulationModeOn = true)
	{
		for (int i = 0; i < systems.Length; i++)
		{
			systems[i].SimulationMode(simulationModeOn);
		}
	}
}
